public with sharing class CreateEditPayrollTransferTTFCtrl {
	public Transition_to_Fulfillment__c ttfRecord { get; set; }
	/*Payroll Transfer Changes*/
	private Id idTTF, idOppty;
	private Opportunity objOppty;
	public List<OpportunityContactRole> lstOpptyContactRole { get; set; }
	public List<POCWrapper> lstPOCWrapper { get; set; }
	private Id idOldPrimaryPOC;
	private String strOldTTFStatus, strOldPrevPayrollProvider;
	public Id idPrimaryRole { get; set; }
	public Id idSecRole { get; set; }

	public Boolean bool_IsExceptionRequest { get; private set; }
	public Boolean bool_ExceptionOverride { get; private set; }

	private List<BusinessHours> lstbh;
	private Long milliSecIn6Days = 6 * 8 * 60 * 60 * 1000; // milliseconds in 6 days
	public Order objTTFOrder { get; set; }
	Set<String> set_TTFTextAreaFields = new Set<String>{
		'Customer_Aware_of_Shorter_timeline__c',
		'Provide_Partial_Migration_Steps__c',
		'how_will_the_handle_moving_forward__c',
		'Link_to_Spreadsheet__c',
		'Notes_for_implementation__c',
		'Sales_Follow_Up__c'
	};
	//Key is ObjName and value is Map<FieldAPINAme,Rowcount>
	public Map<String, Map<String, Integer>> map_RowCountTextArea { get; set; }

	public String strTypeBulkDealSelected { get; set; } // to hold current user selection for Multi-EIN,Bulk Deal and Same Login
	private Case objCase; // Case associated with TTF
	public Id idAcccountToBeRemoved { get; set; }
	/* AccountsWrapper Section */
	public Map<Id, AccountWrapper> mapSelectedAccounts { get; set; }
	public List<AccountWrapper> lstAccWrapper { get; set; }
	Bulk_Migration_Request__c objBMR;
	Map<Id, Account> mapSelectedAffiliations;
	public String strAccName { get; set; } // to search accounts by name
	public String strZPCompanyId { get; set; } // to search accounts by ZPCompanyId
	public Integer size { get; set; }
	public Integer noOfRecords { get; set; }
	//public List<SelectOption> paginationSizeOptions{get;set;}
	public static final Integer QUERY_LIMIT = 10000;
	public static final Integer PAGE_SIZE = 10;

	public Integer selectedCompanyIndx { get; set; } // to add or remove selected companies

	public Boolean blnRenderTTFBlock { get; set; } //Chaitanya 09-23-2020 render pageblock
	public Boolean blnDisableSave { get; set; } //Chaitanya 09-25-2020
	static Id idFbos_RTId_Advocate = Cache.getRecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Advocate');
	static Integer TTF_SUBMISSION_SLA = Utils.ORG_WIDE_CONFIG_SETTINGS?.PT_TTF_Submission_SLA__c != null ? Integer.valueOf(Utils.ORG_WIDE_CONFIG_SETTINGS.PT_TTF_Submission_SLA__c) : 7;
	public static final String STR_RESERVE = 'Reserve';

	public CreateEditPayrollTransferTTFCtrl(ApexPages.StandardController stdController) {
		//Chaitanya 09-23-2020 TTF Issue
		blnRenderTTFBlock = true;
		blnDisableSave = false;

		//get page parameters
		if (ApexPages.currentPage().getParameters().containsKey('ttfId')) {
			idTTF = ApexPages.currentPage().getParameters().get('ttfId');
		} else if (ApexPages.currentPage().getParameters().containsKey('oppId')) {
			idOppty = ApexPages.currentPage().getParameters().get('oppId');
		}
		initializePTTTFData();
	}
	/*
	 * Fetch Accounts based on search criteria
	 */
	public void searchAccounts() {
		setCon = null;
		initializeAccountWrapper();
	}
	//StandardSetController to fetch accounts
	public ApexPages.StandardSetController setCon {
		get {
			if (setCon == null) {
				//get only those accounts which have orders associated with them
				Set<String> setOrderStatusToExclude = new Set<String>{ 'Closed: Payroll Run', 'Closed: Canceled' };

				String strAccountQuery = 'SELECT Id,Name,Bulk_Migration__c,ParentId,(SELECT Id,Transition_to_Fulfillment__c,Bulk_Migration__c,First_Check_Date__c,First_Check_Date_Week_Number__c,Closed_Owner_Division__c FROM Orders WHERE RecordType.NAme =\'Company Migration\')';
				strAccountQuery +=
					',(SELECT Id,Bulk_Migration__c,Source_ID__c,ZP_Company_ID_from_Account__c, Owner_Division__c FROM Opportunities WHERE REcordType.Name=\'Acquisition\' AND IsCLosed = false) FROM Account WHERE RecordType.Name =\'Company\' AND Id IN (SELECT AccountId FROM Order WHERE RecordType.NAme =\'Company Migration\' AND Status NOT IN: setOrderStatusToExclude) AND ZP_Company_Id__c != null AND Id != \'' +
					ttfREcord.Account__c +
					'\'';

				if (String.isNotBlank(strAccName)) {
					strAccountQuery += ' AND  Name Like \'%' + strAccName + '%\'';
				}
				if (String.isNotBlank(strZPCompanyId)) {
					strAccountQuery += ' AND ZP_Company_ID__c Like \'%' + strZPCompanyId + '%\'';
				}

				strAccountQuery += 'LIMIT :QUERY_LIMIT ';
				setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strAccountQuery));

				// sets the number of records to show in each page view
				setCon.setPageSize(PAGE_SIZE);
			}
			return setCon;
		}
		set;
	}

	//indicates whether there are more records after the current page set.
	public Boolean hasNext {
		get {
			return setCon.getHasNext();
		}
		set;
	}

	//indicates whether there are more records before the current page set.
	public Boolean hasPrevious {
		get {
			return setCon.getHasPrevious();
		}
		set;
	}

	//returns the page number of the current page set
	public Integer pageNumber {
		get {
			return setCon.getPageNumber();
		}
		set;
	}

	//return total number of pages for page set
	public Integer getTotalPages() {
		Decimal totalSize = setCon.getResultSize();
		Decimal pageSize = setCon.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(RoundingMode.CEILING);
	}

	//returns the first page of the page set
	public void first() {
		setCon.first();
		initializeAccountWrapper();
	}

	//returns the last page of the page set
	public void last() {
		setCon.last();
		initializeAccountWrapper();
	}

	//returns the previous page of the page set
	public void previous() {
		setCon.previous();
		initializeAccountWrapper();
	}

	//returns the next page of the page set
	public void next() {
		setCon.next();
		initializeAccountWrapper();
	}
	//init accounts
	public void initializeAccountWrapper() {
		lstAccWrapper = new List<AccountWrapper>();

		Integer indx = 0;

		for (Account acc : (List<Account>) setCon.getRecords()) {
			if (mapSelectedAccounts != null && mapSelectedAccounts.containsKey(acc.id)) {
				lstAccWrapper.add(new AccountWrapper(acc, true, indx));
			} else {
				lstAccWrapper.add(new AccountWrapper(acc, false, indx));
			}
			indx++;
		}
	}
	// to add selected companies to mapSelectedAccounts
	public void selectCompany() {
		if (null != lstAccWrapper && lstAccWrapper.size() > selectedCompanyIndx) {
			AccountWrapper objSelectedAcc = lstAccWrapper[selectedCompanyIndx];

			//deselect account
			if (!objSelectedAcc.isSelected && mapSelectedAccounts.containsKey(objSelectedAcc.objAccount.Id)) {
				mapSelectedAccounts.remove(objSelectedAcc.objAccount.Id);
			} else if (objSelectedAcc.isSelected) {
				//select account
				if (null == mapSelectedAccounts)
					mapSelectedAccounts = new Map<Id, AccountWrapper>();
				mapSelectedAccounts.put(objSelectedAcc.objAccount.Id, objSelectedAcc);
			}
		}
	}
	/*
	 * To make sure that only one of the three is selected out of Multi-EIN, Bulk Deal and Same Login
	 */
	public void validateMultiEINSameLoginBulkDeal() {
		if (String.isNotBlank(strTypeBulkDealSelected)) {
			if ('Bulk Migration'.equalsIgnoreCase(strTypeBulkDealSelected) && ttfRecord.Bulk_Deal__c == 'Y') {
				ttfRecord.Multi_EIN__c = 'N';
				ttfRecord.Same_Login__c = 'N';
			} else if ('Multi-EIN'.equalsIgnoreCase(strTypeBulkDealSelected) && ttfRecord.Multi_EIN__c == 'Y') {
				ttfRecord.Bulk_Deal__c = 'N';
				ttfRecord.Same_Login__c = 'N';
			} else if ('Same Login'.equalsIgnoreCase(strTypeBulkDealSelected) && ttfRecord.Same_Login__c == 'Y') {
				ttfRecord.Bulk_Deal__c = 'N';
				ttfRecord.Multi_EIN__c = 'N';
			}
		}
	}
	/*
	 * REmove selected account from map
	 */
	public void removeAccount() {
		if (null != idAcccountToBeRemoved && null != mapSelectedAccounts && mapSelectedAccounts.containsKey(idAcccountToBeRemoved)) {
			mapSelectedAccounts.remove(idAcccountToBeRemoved);
			initializeAccountWrapper();
		}
	}
	/*
	 * Select Primary Contact Role
	 */
	public void selectPrimary() {
		if (null != idPrimaryRole) {
			Boolean boolPrimarySet = false;

			for (POCWrapper poc : lstPOCWrapper) {
				if (poc.boolChkPrimary && poc.objContactRole.Id == idPrimaryRole) {
					poc.objContactRole.Check_Additional_POC__c = false; //Uncheck the additional POC field on Primary POC
					ttfRecord.Contact__c = poc.objContactRole.ContactId;
					boolPrimarySet = true;
				} else {
					poc.boolChkPrimary = false; // Uncheck all other roles set as primary POC
				}
				if (!boolPrimarySet) {
					ttfRecord.Contact__c = null;
				}
			}
			idPrimaryRole = null;
		}
	}

	/*
	 * Select Secondary Contact Role
	 */
	public void selectSecondary() {
		if (null != idSecRole) {
			for (POCWrapper poc : lstPOCWrapper) {
				if (poc.objContactRole.Id == idSecRole && poc.boolChkPrimary && poc.objContactRole.Check_Additional_POC__c) {
					poc.boolChkPrimary = false; //Uncheck the additional POC field on Primary POC
					ttfRecord.Contact__c = null;
				}
			}
		}
	}

	/*
	 * Initialize Payroll Transfer Data
	 */
	private void initializePTTTFData() {
		// Get business hour record to calculate no. of business hours till payroll run date
		String strBHourQuery = 'SELECT Id FROM BusinessHours WHERE Name = \'Gusto - Denver\' LIMIT 1';
		lstbh = Database.query(strBHourQuery);

		List<SelectOption> lstExcepReasonValues = Cache.getFieldPickListValues('Transition_to_Fulfillment__c', 'Reason_for_exception_request__c');
		bool_IsExceptionRequest = false;

		//check if logged in user is a part of Payroll Transfer Exception Override Group
		Id loggedInUser = userInfo.getUserId();
		List<GroupMember> members = [
			SELECT Id, UserOrGroupId
			FROM GroupMember
			WHERE GroupId IN (SELECT id FROM Group WHERE DeveloperName = 'Payroll_Transfer_Exception_Override') AND UserOrGroupId = :loggedInUser
		];
		bool_ExceptionOverride = false;
		if (null != members && members.size() > 0) {
			bool_ExceptionOverride = true;
		}

		if (null != idTTF) {
			//Edit Mode
			//fetch existing TTF record
			String whereClause = ' WHERE Id = :idTTF';
			List<String> fields = new List<String>(Transition_to_Fulfillment__c.SObjectType.getDescribe().fields.getMap().keySet());
			String ttfSOQL =
				'Select Opportunity__r.OwnerId,Opportunity__r.Order__c,Opportunity__r.Order__r.Payroll_Run_Date__c,Opportunity__r.Order__r.First_Check_Date__c,Opportunity__r.AccountId,Opportunity__r.Account.ParentId, Opportunity__r.Name,RecordType.Name,Opportunity__r.StageName,Opportunity__r.Benefits_Current_Setup_Step__c, ' +
				String.join(fields, ',') +
				' FROM Transition_to_Fulfillment__c' +
				whereClause;
			list<Transition_to_Fulfillment__c> ttfs = Database.query(ttfSOQL);

			if (null != ttfs && ttfs.size() > 0) {
				ttfRecord = ttfs[0];

				// Save current PrimaryPOC and STatus values for TTF
				idOldPrimaryPOC = ttfRecord.Contact__c;
				strOldTTFStatus = ttfRecord.TTF_Status__c;
				strOldPrevPayrollProvider = ttfRecord.Previous_Payroll_Provider__c;

				//Assign Opporunity Order if TTF Order is null
				if (null == ttfREcord.Order__c && null != ttfRecord.Opportunity__r.Order__c) {
					ttfREcord.Order__c = ttfRecord.Opportunity__r.Order__c;
				}

				//check if there is a BMR record or not
				Set<String> setBMRType = new Set<String>{ 'Multi-EIN', 'Same Login', 'Bulk Migration' };
				String strBMRQuery = 'SELECT Id,Requested_By__c,Transition_To_Fulfillment__c,Type__c,Bulk_Case__c FROM Bulk_Migration_Request__c WHERE Transition_To_Fulfillment__c =:idTTF AND Type__c IN :setBMRType';

				List<Bulk_Migration_Request__c> lstBulkMigration = Database.query(strBMRQuery);

				if (null != lstBulkMigration && lstBulkMigration.size() > 0) {
					objBMR = lstBulkMigration[0];

					//fetch accounts related to BMR
					String strAccQuery = 'SELECT Id,Name,Bulk_Migration__c,ParentId,(SELECT Id,Transition_to_Fulfillment__c,Bulk_Migration__c,First_Check_Date__c,First_Check_Date_Week_Number__c,Closed_Owner_Division__c  FROM Orders WHERE RecordType.NAme =\'Company Migration\')';
					strAccQuery += ',(SELECT Id,Bulk_Migration__c,Source_ID__c,ZP_Company_ID_from_Account__c FROM Opportunities WHERE REcordType.Name=\'Acquisition\' AND IsClosed = False)';
					strAccQuery +=
						' FROM Account WHERE RecordType.Name =\'Company\' AND Id IN (SELECT AccountId FROM Order WHERE RecordType.NAme =\'Company Migration\') AND Id != \'' +
						ttfREcord.Account__c +
						'\' AND Bulk_Migration__c = \'' +
						objBMR.Id +
						'\'';
					List<Account> lstAcc = Database.query(strAccQuery);

					if (null != lstAcc && lstAcc.size() > 0) {
						mapSelectedAffiliations = new Map<Id, Account>();
						mapSelectedAccounts = new Map<Id, AccountWrapper>();
						Integer indx = 0;

						for (Account acc : lstAcc) {
							mapSelectedAffiliations.put(acc.Id, acc);
							mapSelectedAccounts.put(acc.Id, new AccountWrapper(acc, true, indx));

							indx++;
						}
					}
				}
			}
		} else {
			//new ttf record
			if (null != idOppty) {
				//Fetch opportunity record
				String strQuery =
					'SELECT OwnerId, AccountId, Account.ParentId, Order__c, Order__r.Payroll_Run_Date__c, Name, ' +
					'Order__r.Contractor_Countries__c, Order__r.Contractor_Payment_Method__c, Order__r.Direct_Deposit_Speed__c, ' +
					'Order__r.Employee_Payment_Method__c, Order__r.Employees_With_Multiple_Tax_Jurisdiction__c, ' +
					'Order__r.Has_Remote_Employees__c, Order__r.Number_Of_Pay_Schedules__c, Order__r.Invite_Contractors_Via_Email__c,' +
					'Order__r.Invite_Dismissed_Employees_Via_Email__c, Order__r.Invite_Employees_Via_Email__c, ' +
					'Order__r.Last_Expected_Pay_Date__c, Order__r.New_Health_Benefits__c, ' +
					'Order__r.Pay_Contractors_With_Payroll_Provider__c, Order__r.Pay_International_Contractors__c, ' +
					'Order__r.Registered_As_Employer_In_Work_States__c, Order__r.Time_Off_Offered__c, ' +
					'Order__r.Track_PTO_Policies__c, Order__r.Employees_With_Tax_Exemptions__c ' +
					'FROM Opportunity ' +
					'WHERE Id = :idOppty';

				List<Opportunity> list_Opp = Database.query(strQuery);

				if (list_Opp != null && list_Opp.size() > 0) {
					Opportunity objOppty = list_Opp[0];

					//Create TTF with preset fields
					ttfRecord = new Transition_To_Fulfillment__c(
						Opportunity__c = objOppty.Id,
						Account__c = objOppty.AccountId,
						Order__c = objOppty.Order__c,
						RecordTypeId = Schema.SObjectType.Transition_to_Fulfillment__c.getRecordTypeInfosByName().get('Payroll Transfer').getRecordTypeId()
					);

					ttfRecord = processOrderAdditionalData(ttfRecord, objOppty);
					// Save current PrimaryPOC and STatus values for TTF
					idOldPrimaryPOC = null;
					strOldTTFStatus = '';
				}
			} else {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please create Transition to Fulfillment record from opportunity detail page.'));
			}
		}

		if (null != ttfRecord.Order__c) {
			String strOrderQuery =
				'SELECT Id,Name,OrderNumber,Payroll_Run_Date__c,First_Check_Date__c,OpportunityId,Transition_To_Fulfillment__c,Fast_ACH__c,Opportunity.Owner.UserRole.DeveloperName,Opportunity.Owner_Division__c,First_Check_Date_Week_Number__c,Closed_Owner_Division__c FROM Order WHERE Id = \'' +
				ttfREcord.Order__c +
				'\'';
			List<Order> lstOrders = Database.query(strOrderQuery);

			if (null != lstOrders && lstOrders.size() > 0) {
				objTTFOrder = lstOrders[0];

				// Check if Order is an Exception or not
				checkExceptionRequest();

				//Chaitanya Kurra 09-22-2020
				if (objTTFOrder.First_Check_Date__c == null) {
					blnRenderTTFBlock = false;
				}
			}
		} else if (null == ttfRecord.Order__c) {
			//Chaitanya 09-23-2020 TTF Issue
			blnDisableSave = true;
			string strWarningMsg = 'The following TTF is not having an order attached, please create an order and then submit the TTF on this opportunity';
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.WARNING, strWarningMsg));
		}

		initializeSecondaryPOCData(); // get opportunity contact role data based on

		//dynamic row count
		map_RowCountTextArea = new Map<String, Map<String, Integer>>();
		map_RowCountTextArea = OrderUtils.setRowCountForTextArea(new List<Transition_to_Fulfillment__c>{ ttfRecord }, set_TTFTextAreaFields, map_RowCountTextArea);

		//Get Accounts for Multi-EIN/SameLogin
		lstAccWrapper = new List<AccountWrapper>();
		initializeAccountWrapper();
	}

	/*
	 * To check if it is an exception request based on Order.PayrollRunDate
	 */
	private void checkExceptionRequest() {
		//Check for exception condition
		if (!bool_ExceptionOverride && null != objTTFOrder.Payroll_Run_Date__c && null != lstbh && lstbh.size() > 0) {
			Long countMilisec = BusinessHours.diff(lstbh[0].id, System.now(), DateTime.newInstance(objTTFOrder.Payroll_Run_Date__c, Time.newInstance(0, 0, 0, 0)));
			//if payroll run date lies within 7 business days from now then Exception request is set to yes

			if ((countMilisec / (8 * 3600 * 1000)) + 1 < TTF_SUBMISSION_SLA) {
				ttfRecord.Exception_Request__c = 'Yes';
				bool_IsExceptionRequest = true;
			} else {
				ttfRecord.Exception_Request__c = 'No';
				bool_IsExceptionRequest = false;
			}
		}
	}
	/*
	 * Save TTF Record for Payroll Transfer
	 */
	public PageReference savePayrollTTF() {
		PageReference pageRef;
		try {
			//Re-init lstOpptyContactRole and get primary contact if any
			lstOpptyContactRole = new List<OpportunityContactRole>();
			if (null != lstPOCWrapper) {
				for (POCWrapper poc : lstPOCWrapper) {
					lstOpptyContactRole.add(poc.objContactRole);
				}
			}

			//validate TTF
			if (validatePayrollTTF() && validateWeeklyCap()) {
				//save record

				if (ttfRecord.TTF_Status__c != strOldTTFStatus && 'Sales Submitted'.equalsIgnoreCase(ttfRecord.TTF_Status__c)) {
					ttfRecord.PT_Sales_Submitted_Datetime__c = system.now();
				}

				Database.upsert(new List<Transition_To_Fulfillment__c>{ ttfRecord });

				//SJay - Commented out this instantiation since it is losing all context.
				//Order objOrder = new Order(Id=ttfRecord.Order__c);
				Order objOrder = new Order(
					Id = objTTFOrder.Id,
					Payroll_Run_Date__c = objTTFOrder.Payroll_Run_Date__c,
					First_Check_Date__c = objTTFOrder.First_Check_Date__c,
					Opportunity = objTTFOrder.Opportunity
				);

				//Copy Previous Payroll Provider to Order when it is changed
				if (null != ttfRecord.Order__c && strOldPrevPayrollProvider != ttfRecord.Previous_Payroll_Provider__c) {
					objOrder.Previous_Payroll_Provider__c = ttfRecord.Previous_Payroll_Provider__c;
				}
				//Copy Exception Request on Order
				if ('Yes'.equalsIgnoreCase(ttfRecord.Exception_Request__c)) {
					objOrder.Exception_Request__c = true;
				} else {
					objOrder.Exception_Request__c = false;
				}

				if (objOrder != null && objOrder.Id != null) {
					OrderTriggerHelper.skipTrigger = true;
					update objOrder;
					OrderTriggerHelper.skipTrigger = false;
				}

				if (null != lstOpptyContactRole && lstOpptyContactRole.size() > 0)
					Database.update(lstOpptyContactRole);

				updateCaseContactAndTeamForPayrollTTF();

				//If MULTI-EIN or Same Login is Selected as Yes then create BMR and Update Accounts
				createBMRAndSetOnAccounts();

				pageRef = new PageReference('/' + ttfRecord.Id);
				pageRef.setRedirect(true);
			}
		} catch (Exception objExcep) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExcep.getMessage()));
			if (!objExcep.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
				ExceptionLogUtil.logException('CreateEditPayrollTransferTTFCtrl', 'savePayrollTTF', objExcep.getMessage(), objExcep.getStackTraceString());
			}
		}
		return pageRef;
	}
	/*
	 * Cancel user operation and redirect to return URL
	 */
	public PageReference cancelPayrollTTF() {
		PageReference pageRef;
		String retURL;
		if (ApexPages.currentPage().getParameters().containsKey('retURL')) {
			retURL = ApexPages.currentPage().getParameters().get('retURL');

			pageRef = new PageReference(retURL);
		} else
			pageRef = new PageReference('/' + idOppty);

		pageRef.setRedirect(true);
		return pageRef;
	}
	/*
	 * Validate TTF Record for Payroll Transfer
	 */
	private Boolean validatePayrollTTF() {
		Boolean boolNoError = true;
		// Required field check
		if (null == ttfRecord.Previous_Payroll_Provider__c) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for Previous Payroll Provider'));
			boolNoError = false;
		}
		if (null == ttfRecord.Demo_Complete__c) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for Is Demo Complete?'));
			boolNoError = false;
		}
		if (null == ttfRecord.Contact__c) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select Primary Point of Contact for this Opportunity.'));
			boolNoError = false;
		} else if (null != lstPOCWrapper && !lstPOCWrapper.isEmpty()) {
			for (POCWrapper poc : lstPOCWrapper) {
				if (ttfRecord.Contact__c == poc.objContactRole.ContactId && poc.objContactRole.Check_Additional_POC__c) {
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Primary POC is also selected as Secondary POC. Please review your selections.'));
					boolNoError = false;
				}
			}
		}
		//if Exception Request is Yes then check Mandatory fields
		if ('Yes'.equalsIgnoreCase(ttfRecord.Exception_Request__c)) {
			if (null == ttfRecord.Reason_for_exception_request__c) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for Reason for Exception Request.'));
				boolNoError = false;
			}
			if (null == ttfRecord.Customer_aware_of_shorter_timeline__c) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for Customer aware of shorter timeline.'));
				boolNoError = false;
			}
			if (null == ttfRecord.Doesnot_require_2_factor_Authentication__c) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for Doesnot require 2 factor Authentication.'));
				boolNoError = false;
			}
			if (null == ttfRecord.No_contractors_paid_on_first_check_date__c) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for No contractors paid on first check date.'));
				boolNoError = false;
			}
			if (null == ttfRecord.Payroll_provider_not_ADP_WrkFrc_Paychex__c) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for Companies denied based on the payroll provider.'));
				boolNoError = false;
			}
			if (null == ttfRecord.Payroll_Transfer_not_accept_the_excep__c) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for Payroll Transfers will not accept the exception request.'));
				boolNoError = false;
			}
			if (null == ttfRecord.Requires_Reverse_Wire_to_be_setup__c) {
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a response for First Payroll is under $150,000'));
				boolNoError = false;
			}
		}
		return boolNoError;
	}

	/**
	 * @Author      : Sandeep Golla
	 * @Description : Validate whether the weekly capacity of orders are over exceeded or under capacity by closed owner division.
	 * @Parm        : N/A
	 * @Return      : Boolean
	 **/
	public Boolean validateWeeklyCap() {
		Boolean boolNoError = true;
		if (
			ttfRecord.TTF_Status__c != strOldTTFStatus &&
			(ttfRecord.TTF_Status__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.TTF_STATUS_SALES_SUBMITTED) ||
			ttfRecord.TTF_Status__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.TTF_STATUS_PT_APPROVED))
		) {
			Date dtStartDateOfMonth;
			Date dtEndDateOfMonth;
			List<Date> lst_OrderFirstCheckDates = new List<Date>();
			Set<String> set_OrderFirstCheckDateYears = new Set<String>();
			Set<Integer> set_WeekNumbers = new Set<Integer>();
			Set<String> set_TTFStatus = new Set<String>{ TransitiontoFulfilmentUtil.TTF_STATUS_SALES_SUBMITTED, TransitiontoFulfilmentUtil.TTF_STATUS_PT_APPROVED };
			List<Order> lst_Orders = new List<Order>();
			Map<String, Payroll_Transfer_FBOS_Forecast__c> map_FBOSForecastCap = new Map<String, Payroll_Transfer_FBOS_Forecast__c>();
			Map<String, Integer> map_FBOSForecastClosedDivCap = new Map<String, Integer>();
			Map<String, Map<String, Integer>> map_OrdersWeeklyCap = new Map<String, Map<String, Integer>>();
			Map<Integer, String> map_WeekNumber = new Map<Integer, String>{
				1 => 'First_week_cap__c',
				2 => 'Second_week_cap__c',
				3 => 'Third_week_cap__c',
				4 => 'Fourth_Week_Cap__c',
				5 => 'Fifth_Week_Cap__c'
			};

			if (mapSelectedAccounts != null && mapSelectedAccounts.size() > 0) {
				for (AccountWrapper accountWrap : mapSelectedAccounts.values()) {
					for (Order orderObj : accountWrap.objAccount.Orders) {
						if (orderObj.First_Check_Date_Week_Number__c != null && orderObj.First_Check_Date__c != null) {
							set_WeekNumbers.add(Integer.valueof(orderObj.First_Check_Date_Week_Number__c));
							set_OrderFirstCheckDateYears.add(string.valueof(orderObj.First_Check_Date__c.year()));
							lst_OrderFirstCheckDates.add(orderObj.First_Check_Date__c);
							lst_Orders.add(orderObj);
						}
					}
				}
			}

			if (objTTFOrder.First_Check_Date__c != null && objTTFOrder.First_Check_Date_Week_Number__c != null) {
				set_WeekNumbers.add(Integer.valueof(objTTFOrder.First_Check_Date_Week_Number__c));
				set_OrderFirstCheckDateYears.add(string.valueof(objTTFOrder.First_Check_Date__c.year()));
				lst_OrderFirstCheckDates.add(objTTFOrder.First_Check_Date__c);
				lst_Orders.add(objTTFOrder);
			}

			if (!set_WeekNumbers.isEmpty() && !lst_OrderFirstCheckDates.isEmpty()) {
				lst_OrderFirstCheckDates.sort();
				Date dtFirstDate = lst_OrderFirstCheckDates.get(0);
				Date dtLastDate = lst_OrderFirstCheckDates.get(lst_OrderFirstCheckDates.size() - 1);
				// First Day of the month
				Date dtFirstDay = Date.newInstance(dtFirstDate.year(), dtFirstDate.month(), 1);
				dtStartDateOfMonth = dtFirstDay;
				// Last Day of the month
				Integer intDaysInMon = Date.daysInMonth(dtLastDate.year(), dtLastDate.month());
				Date dtLastDay = Date.newInstance(dtLastDate.year(), dtLastDate.month(), intDaysInMon);
				dtEndDateOfMonth = dtLastDay;

				//Query Payroll_Transfer_FBOS_Forecast_Cap__mdt records and create a map
				List<Payroll_Transfer_FBOS_Forecast_Cap__mdt> lst_PayrollForecastCaps = [
					SELECT Id, MasterLabel, DeveloperName, Maximum_cap__c, Owner_Division__c
					FROM Payroll_Transfer_FBOS_Forecast_Cap__mdt
				];
				for (Payroll_Transfer_FBOS_Forecast_Cap__mdt objFBOSForecastCap : lst_PayrollForecastCaps) {
					map_FBOSForecastClosedDivCap.put(objFBOSForecastCap.Owner_Division__c, Integer.valueOf(objFBOSForecastCap.Maximum_cap__c));
				}

				//Query Payroll_Transfer_FBOS_Forecast__c records and create a map
				List<Payroll_Transfer_FBOS_Forecast__c> lst_ForeCasts = [
					SELECT
						Id,
						FBOS_Forecast__c,
						Fifth_Week_Cap__c,
						First_week_cap__c,
						Forecast_Multiplier__c,
						Fourth_Week_Cap__c,
						Month__c,
						Second_week_cap__c,
						Third_week_cap__c,
						Total_Month_Cap__c,
						Year__c,
						RecordType.Name,
						RecordTypeId
					FROM Payroll_Transfer_FBOS_Forecast__c
					WHERE Year__c = :set_OrderFirstCheckDateYears AND RecordTypeId = :idFbos_RTId_Advocate
					ORDER BY Month__c ASC
				];

				if (lst_ForeCasts != null && lst_ForeCasts.size() > 0) {
					for (Payroll_Transfer_FBOS_Forecast__c objFBOSForecast : lst_ForeCasts) {
						map_FBOSForecastCap.put(objFBOSForecast.Year__c + '-' + objFBOSForecast.Month__c, objFBOSForecast);
					}
				}

				//Query orders with TTF status as Sales Submitted and PT Approved as per date range and create a map
				Map<Id, Order> map_Orders = new Map<Id, Order>(
					[
						SELECT id, Name, First_Check_Date__c, OwnerId, First_Check_Date_Week_Number__c, Closed_Owner_Division__c, Transition_to_Fulfillment__c, TTF_Status__c
						FROM Order
						WHERE
							TTF_Status__c = :set_TTFStatus
							AND First_Check_Date__c >= :dtStartDateOfMonth
							AND First_Check_Date__c <= :dtEndDateOfMonth
							AND First_Check_Date_Week_Number__c = :set_WeekNumbers
							AND Closed_Owner_Division__c != NULL
					]
				);

				// Add the current TTF order into the map and create a map to calculate weekly capacity by closed owner division
				map_Orders.putAll(lst_Orders);

				if (map_Orders != null && map_Orders.size() > 0) {
					for (Order orderRec : map_Orders.values()) {
						DateTime fdDateTime = DateTime.newInstance(orderRec.First_Check_Date__c, Time.newInstance(0, 0, 0, 0));
						String strMonth = fdDateTime.format('MMMM');

						if (!map_OrdersWeeklyCap.containsKey(strMonth + '-' + orderRec.First_Check_Date_Week_Number__c)) {
							map_OrdersWeeklyCap.put(strMonth + '-' + orderRec.First_Check_Date_Week_Number__c, new Map<String, Integer>{ orderRec.Closed_Owner_Division__c => 1 });
						} else {
							Map<String, Integer> map_ClosedOwnerDivisionCount = map_OrdersWeeklyCap.get(strMonth + '-' + orderRec.First_Check_Date_Week_Number__c);
							if (map_ClosedOwnerDivisionCount.containsKey(orderRec.Closed_Owner_Division__c)) {
								Integer intCount = map_ClosedOwnerDivisionCount.get(orderRec.Closed_Owner_Division__c);
								intCount++;
								map_ClosedOwnerDivisionCount.put(orderRec.Closed_Owner_Division__c, intCount);
							} else {
								map_ClosedOwnerDivisionCount.put(orderRec.Closed_Owner_Division__c, 1);
							}
							map_OrdersWeeklyCap.put(strMonth + '-' + orderRec.First_Check_Date_Week_Number__c, map_ClosedOwnerDivisionCount);
						}
					}
				}

				if (lst_Orders != null && lst_Orders.size() > 0) {
					String strErrorMessageDetails = '';
					for (Order objNewOrder : lst_Orders) {
						DateTime fdDateTime = DateTime.newInstance(objNewOrder.First_Check_Date__c, Time.newInstance(0, 0, 0, 0));
						String strMonth = fdDateTime.format('MMMM');

						if (
							map_OrdersWeeklyCap.containsKey(strMonth + '-' + objNewOrder.First_Check_Date_Week_Number__c) &&
							map_OrdersWeeklyCap.get(strMonth + '-' + objNewOrder.First_Check_Date_Week_Number__c).containsKey(objNewOrder.Closed_Owner_Division__c) &&
							map_FBOSForecastCap.containsKey(Integer.valueOf(objNewOrder.First_Check_Date__c.year()) + '-' + strMonth) &&
							map_FBOSForecastClosedDivCap.containsKey(objNewOrder.Closed_Owner_Division__c)
						) {
							Decimal intOrdersCount = map_OrdersWeeklyCap.get(strMonth + '-' + objNewOrder.First_Check_Date_Week_Number__c).get(objNewOrder.Closed_Owner_Division__c);
							Decimal intFBOSForecastClosedDivCap = map_FBOSForecastClosedDivCap.get(objNewOrder.Closed_Owner_Division__c);
							Decimal decFBOSForecastReserveCap = map_FBOSForecastClosedDivCap.get(STR_RESERVE);
							Payroll_Transfer_FBOS_Forecast__c obj = map_FBOSForecastCap.get(Integer.valueOf(objNewOrder.First_Check_Date__c.year()) + '-' + strMonth);
							Decimal intFBOSForecastCap = Integer.valueof(obj.get(map_WeekNumber.get(Integer.valueof(objNewOrder.First_Check_Date_Week_Number__c))));
							Decimal decFinalCapacity = intFBOSForecastClosedDivCap == null || intFBOSForecastCap == null ? 0 : ((intFBOSForecastClosedDivCap / 100) * intFBOSForecastCap);
							decFinalCapacity = decFinalCapacity.round(RoundingMode.HALF_UP);
							Decimal decReserveCapacity = decFBOSForecastReserveCap == null || intFBOSForecastCap == null ? 0 : ((decFBOSForecastReserveCap / 100) * intFBOSForecastCap);
							decReserveCapacity = decReserveCapacity.round(RoundingMode.HALF_UP);
							Decimal decOrdersAssignedFromReserveCount = 0;
							//Logic for current remaining capacity calculation. Inner loop will always have five iterations (values from FBOS forecast cap metadata). Needed since its a map if a map.
							//If orders allocated to a current team is more than the weekly final capacity then it has been from the weekly reserve.
							for (String strClosedOwnerDivision : map_OrdersWeeklyCap.get(strMonth + '-' + objNewOrder.First_Check_Date_Week_Number__c).keySet()) {
								Decimal decFBOSForecastClosedDivCap = map_FBOSForecastClosedDivCap.get(strClosedOwnerDivision);
								Decimal decFinalCapacityClosedDiv = decFBOSForecastClosedDivCap == null || intFBOSForecastCap == null ? 0 : ((decFBOSForecastClosedDivCap / 100) * intFBOSForecastCap);
								decFinalCapacityClosedDiv = decFinalCapacityClosedDiv.round(RoundingMode.HALF_UP);
								Decimal decOrdersCountClosedDiv = map_OrdersWeeklyCap.get(strMonth + '-' + objNewOrder.First_Check_Date_Week_Number__c).get(strClosedOwnerDivision);
								if (decOrdersCountClosedDiv > decFinalCapacityClosedDiv) {
									decOrdersAssignedFromReserveCount += decOrdersCountClosedDiv - decFinalCapacityClosedDiv;
								}
							}
							//If order being allocated to current team is more than the weekly final capacity and the orders already assigned from reserve is greater than the reserve capacity then show error.
							if (intOrdersCount > decFinalCapacity && decOrdersAssignedFromReserveCount >= decReserveCapacity) {
								strErrorMessageDetails =
									'The current order count for ' +
									objNewOrder.Closed_Owner_Division__c +
									' Sales is ' +
									intOrdersCount +
									'. Orders remaining in the reserve capacity are: 0';
								ApexPages.AddMessage(
									new ApexPages.Message(
										ApexPages.Severity.ERROR,
										'This TTF cannot be accepted due to full capacity this chosen week. Please find a new check date for your customer. Refer to the Sales Capacity Dashboard for open availability.\n Error Details: ' +
										strErrorMessageDetails
									)
								);
								boolNoError = false;
								break;
							}
						}
					}
				}
			}
			return boolNoError;
		} else {
			return boolNoError;
		}
	}

	/**/
	/*
	 * Initialize Secondary Point of Contact Data
	 */
	private void initializeSecondaryPOCData() {
		if (null != ttfRecord && null != ttfRecord.Opportunity__c) {
			//Get Opportunity Contact Roles
			Id idopportunity = ttfRecord.Opportunity__c; //Check_Additional_POC__c
			String strOpptyCRoleQuery = 'SELECT OpportunityId,Contact.FirstName,Contact.LastName,Role,Check_Additional_POC__c FROM OpportunityContactRole WHERE OpportunityId = :idopportunity';

			lstOpptyContactRole = Database.query(strOpptyCRoleQuery);

			if (null != lstOpptyContactRole) {
				//Check for duplicate contacts
				Map<Id, OpportunityContactRole> mapContactRole = new Map<Id, OpportunityContactRole>();

				for (OpportunityContactRole cRole : lstOpptyContactRole) {
					if (!mapContactRole.containsKey(cRole.ContactId) || 'Primary Payroll Admin'.equalsIgnoreCase(cRole.Role)) {
						mapContactRole.put(cRole.ContactId, cRole);
					}
				}
				lstPOCWrapper = new List<POCWrapper>();
				//Construct Wrapper for unique contacts
				for (OpportunityContactRole cRole : mapContactRole.values()) {
					lstPOCWrapper.add(new POCWrapper(cRole, ttfRecord.Contact__c));
				}
			}
		}
	}

	/*
	 * 1) Update Contact on Case when Primary POC Changes on TTF
	 * 2) Update case contact roles when There are opportunity contact roles marked as Secondary POC and TTF status changes to PT Approved
	 */
	private void updateCaseContactAndTeamForPayrollTTF() {
		String strCaseQuery = '';
		Id idTTFRec = ttfRecord.Id;
		// If it is bulk deal then get case from BMR
		if ('Y'.equalsIgnoreCase(ttfRecord.Bulk_Deal__c)) {
			strCaseQuery = 'SELECT Id,ContactId FROM Case WHERE Bulk_Migration__r.Transition_To_Fulfillment__c = :idTTFRec';
		} else {
			// If it is not a bulk deal then get case from Order
			if (idTTFRec != null)
				strCaseQuery = 'SELECT Id,ContactId FROM Case WHERE Order__r.Transition_To_Fulfillment__c = :idTTFRec';
		}
		List<Case> lstCase = Database.Query(strCaseQuery);
		if (!lstCase.isEmpty()) {
			objCase = lstCase[0];

			//Update Contact lookup on case with Primary POC value
			objCase.ContactId = ttfRecord.Contact__c;
			objCase.TTF_Point_Of_Contact__c = ttfRecord.Contact__c;
			CaseTriggerHelper.skipTrigger = true;
			TaskTriggerHelper.skipTrigger = true;
			update objCase;
			CaseTriggerHelper.skipTrigger = false;
			TaskTriggerHelper.skipTrigger = false;

			Set<Id> setContactIds;

			if (null != lstOpptyContactRole && lstOpptyContactRole.size() > 0) {
				for (OpportunityContactRole opptyCRole : lstOpptyContactRole) {
					//Get contacts for which Additional POC is checked
					if (opptyCRole.Check_Additional_POC__c) {
						if (null == setContactIds)
							setContactIds = new Set<Id>();

						setContactIds.add(opptyCRole.ContactId);
					}
				}

				if (null != setContactIds && setContactIds.size() > 0) {
					Id idObjCase = objCase.Id;
					//get existing caseteam members
					List<CaseTeamMember> lstCaseTeamMembers = Database.Query('SELECT Id,MemberId FROM CaseTeamMember WHERE ParentId =:idObjCase');

					List<CaseTeamMember> lstCaseTeamMembersToInsert = new List<CaseTeamMember>();
					//check if teammember record exists for selected contacts
					if (!lstCaseTeamMembers.isEmpty()) {
						for (CaseTeamMember member : lstCaseTeamMembers) {
							if (setContactIds.contains(member.MemberId))
								setContactIds.remove(member.MemberId);
						}
					}
					//Fetch case team role
					List<CaseTeamRole> lstCaseTeamRole = Database.query('SELECT Id FROM CaseTeamRole WHERE Name = \'Customer Contact\'');
					Id idCaseTRole;
					if (null != lstCaseTeamRole && lstCaseTeamRole.size() > 0)
						idCaseTRole = lstCaseTeamRole[0].Id;

					//Create case team members for each contact
					for (Id idContact : setContactIds) {
						lstCaseTeamMembersToInsert.add(new CaseTeamMember(ParentId = idObjCase, TeamRoleId = idCaseTRole, MemberId = idContact));
					}
					Database.Insert(lstCaseTeamMembersToInsert);
				}
			}
		}
	}

	/*
	 *1) Create BMR if it doesnot exist
	 *2) Update Accounts with BMR
	 */
	private void createBMRAndSetOnAccounts() {
		if (ttfRecord.Multi_EIN__c == 'Y') {
			strTypeBulkDealSelected = 'Multi-EIN';
		} else if (ttfRecord.Same_Login__c == 'Y') {
			strTypeBulkDealSelected = 'Same Login';
		} else if (ttfRecord.Bulk_Deal__c == 'Y') {
			strTypeBulkDealSelected = 'Bulk Migration';
		}

		if (null != ttfRecord.Id) {
			List<sObject> lstCaseBMRToUpdate = new List<sObject>();
			Case objRelatedCase;

			idTTF = ttfRecord.Id;
			String strCaseQuery = 'SELECT Id,Bulk_Migration__c FROM Case WHERE (Bulk_Migration__r.Transition_To_Fulfillment__c = :idTTF OR Order__r.Transition_To_Fulfillment__c = :idTTF)';
			strCaseQuery += ' AND Status != \'Closed\' AND RecordType.Name = \'Payroll Transfer Case\'';

			List<Case> lstRelatedCase = new List<Case>();
			lstRelatedCase = Database.query(strCaseQuery);

			if (lstRelatedCase != null && lstRelatedCase.size() > 0) {
				objRelatedCase = lstRelatedCase[0];
			}

			List<SObject> lstObjectsToUpdate = new List<SObject>();
			List<SObject> lst_AccountToUpdate = new List<SObject>();

			Set<Id> setAccDeleteBMR, setAccAddBMR; // to identify accounts for which lookups are to be set or removed based on cuurent selection

			if ((ttfRecord.Multi_EIN__c == 'Y' || ttfRecord.Same_Login__c == 'Y' || ttfRecord.Bulk_Deal__c == 'Y')) {
				if (null != objBMR) {
					//Update type of BMR in case it is changed
					if (objBMR.Type__c != strTypeBulkDealSelected) {
						// check is BMR is present for same condition or not
						objBMR.Type__c = strTypeBulkDealSelected;
					}
					//Update Bulk Case on BMR if there is a case related to ttfRec
					if (null == objBMR.Bulk_Case__c && null != objRelatedCase)
						objBMR.Bulk_Case__c = objRelatedCase.Id;

					//Update requested by field on BMR if it is blank
					if (null == objBMR.Requested_By__c) {
						if (null == objOppty)
							objBMR.Requested_By__c = ttfRecord.Opportunity__r.OwnerId;
						else
							objBMR.Requested_By__c = objOppty.OwnerId;
					}
					lstCaseBMRToUpdate.add(objBMR);
				} else {
					//create BMR
					objBMR = new Bulk_Migration_Request__c(
						Transition_To_Fulfillment__c = ttfREcord.Id,
						Type__c = strTypeBulkDealSelected,
						Primary_Point_of_Contact__c = ttfRecord.Contact__c,
						Bulk_Migration_Status__c = 'New'
					);
					//Set requested by field on BMR
					if (null == objOppty)
						objBMR.Requested_By__c = ttfRecord.Opportunity__r.OwnerId;
					else
						objBMR.Requested_By__c = objOppty.OwnerId;
					//Set Case field on BMR
					if (null != objRelatedCase)
						objBMR.Bulk_Case__c = objRelatedCase.Id;
					if (null != ttfRecord.Opportunity__r.Order__c)
						objBMR.Requested_First_Check_Date__c = ttfREcord.Opportunity__r.Order__r.First_Check_Date__c;

					insert objBMR;
				}
				//if Bulk Migration is not set on case then update it
				if (null != objRelatedCase && null == objRelatedCase.Bulk_Migration__c && null != objBMR) {
					objRelatedCase.Bulk_Migration__c = objBMR.Id;
					lstCaseBMRToUpdate.add(objRelatedCase);
				}

				Boolean boolCaseTrgr = CaseTriggerHelper.skipTrigger;
				CaseTriggerHelper.skipTrigger = true;

				if (lstCaseBMRToUpdate.size() > 0)
					Database.update(lstCaseBMRToUpdate);

				CaseTRiggerHelper.skipTrigger = boolCaseTrgr;

				//BMR Inserted/Updated successfully
				if (null != objBMR.Id) {
					if (null != mapSelectedAccounts && mapSelectedAccounts.size() > 0) {
						setAccAddBMR = new Set<Id>(mapSelectedAccounts.keySet());

						if (null != mapSelectedAffiliations && mapSelectedAffiliations.size() > 0) {
							setAccDeleteBMR = new Set<Id>();

							for (Id idAcc : mapSelectedAffiliations.keySet()) {
								//if an account was previously selected and is not a prt of current selection then we have to remove all the lookups to BMR and TTF
								if (null == mapSelectedAccounts || !mapSelectedAccounts.containsKey(idAcc)) {
									setAccDeleteBMR.add(idAcc);
								}
							}
						}

						if (null != setAccAddBMR && setAccAddBMR.size() > 0) {
							for (Id idAcc : setAccAddBMR) {
								Account accountRec = mapSelectedAccounts.get(idAcc).objAccount;

								// if multi ein is selected then update parent account lookup on selected accounts as ttf.Account__c
								if ('Multi-EIN'.equalsIgnoreCase(strTypeBulkDealSelected)) {
									accountRec.ParentId = ttfRecord.Account__c;
								} else {
									// if same login is selected then make account.parentId as null
									accountRec.ParentId = null;
								}
								lst_AccountToUpdate.add(accountRec);

								//loop over orders and set TTF, bulk case and BMR on them
								for (Order orderRec : accountRec.Orders) {
									orderRec.Transition_To_Fulfillment__c = ttfREcord.Id;
									orderRec.Bulk_Migration__c = objBMR.Id;

									if (null != objRelatedCase) {
										orderRec.Bulk_Case__c = objRelatedCase.Id;
									}

									lstObjectsToUpdate.add(orderRec);
								}
							}
						}

						// update parent account, order and opportunity with BMR and bulk case

						if (null != ttfRecord.Opportunity__c && null != ttfRecord.Opportunity__r.Order__c) {
							Order objOrderToUpdate = new Order(Id = ttfRecord.Opportunity__r.Order__c, Bulk_Migration__c = objBMR.Id, Transition_To_Fulfillment__c = ttfRecord.Id);

							if (null != objRelatedCase) {
								objOrderToUpdate.Bulk_Case__c = objRelatedCase.Id;
							}
							lstObjectsToUpdate.add(objOrderToUpdate);
						}
					} else if (null != mapSelectedAffiliations && mapSelectedAffiliations.size() > 0) {
						// no account has been selected and there was some previous selection, then remove all references
						//as no accounts are selected and there were previous selections then delete all the references for them
						setAccDeleteBMR = new Set<Id>(mapSelectedAffiliations.keySet());

						// update parent account, order and opportunity with BMR as null
						if (null != ttfRecord.Opportunity__c && null != ttfRecord.Opportunity__r.Order__c)
							lstObjectsToUpdate.add(new Order(Id = ttfRecord.Opportunity__r.Order__c, Bulk_Migration__c = null, Bulk_Case__c = null));
					}
				}
			} else if (null != mapSelectedAffiliations && mapSelectedAffiliations.size() > 0) {
				// no account has been selected and there was some previous selection, then remove all references
				//as no accounts are selected and there were previous selections then delete all the references for them
				setAccDeleteBMR = new Set<Id>(mapSelectedAffiliations.keySet());

				// update parent account, order and opportunity with BMR as null
				if (null != ttfRecord.Opportunity__c && null != ttfRecord.Opportunity__r.Order__c)
					lstObjectsToUpdate.add(new Order(Id = ttfRecord.Opportunity__r.Order__c, Bulk_Migration__c = null, Bulk_Case__c = null));
			}

			// for accounts which were earlier selected and now not selected, we need to delete the BMR, Bulk Case  and TTF references
			if (null != setAccDeleteBMR && setAccDeleteBMR.size() > 0) {
				for (Id idAcc : setAccDeleteBMR) {
					Account accountRec = mapSelectedAffiliations.get(idAcc);

					accountRec.ParentId = null;
					accountRec.Bulk_Migration__c = null;

					lst_AccountToUpdate.add(accountRec);

					//remove TTF, Bulk Case and BMR lookup on Orders
					for (Order orderRec : accountRec.Orders) {
						orderRec.Transition_To_Fulfillment__c = null;
						orderRec.Bulk_Migration__c = null;
						orderRec.Bulk_Case__c = null;
						lstObjectsToUpdate.add(orderRec);
					}
				}
			}
			if (lst_AccountToUpdate.size() > 0) {
				lstObjectsToUpdate.addAll(lst_AccountToUpdate);
			}
			//when no accounts are selected then update case and BMR to remove lookups of each other
			if ((null == mapSelectedAccounts || mapSelectedAccounts.size() == 0) && null != objRelatedCase) {
				//If case exists, set Case.Bulk_Migration to null
				objRelatedCase.Bulk_Migration__c = null;
				lstObjectsToUpdate.add(objRelatedCase);
				if (objBMR != null && objBMR.Bulk_Case__c != null) {
					objBMR.Bulk_Case__c = null;
					lstObjectsToUpdate.add(objBMR);
				}
			}

			if (lstObjectsToUpdate.size() > 0) {
				Boolean boolAccTrigger = AccountTriggerHelper.skipTrigger;
				AccountTriggerHelper.skipTRigger = true;

				Boolean boolCaseTrigger = CaseTriggerHelper.skipTrigger;
				CaseTriggerHelper.skipTrigger = true;

				update lstObjectsToUpdate;

				CaseTriggerHelper.skipTrigger = boolCaseTrigger;
				AccountTriggerHelper.skipTrigger = boolAccTrigger;
			}
		}
	}

	/*
	 * WRapper for Point of contacts on TTF
	 */
	public class POCWrapper {
		public OpportunityContactRole objContactRole { get; set; }
		public Boolean boolChkPrimary { get; set; }

		public POCWrapper(OpportunityContactRole oppContactRole, Id idPContact) {
			objContactRole = oppContactRole;
			if (idPContact == oppContactRole.ContactId) {
				boolChkPrimary = true;
			} else
				boolChkPrimary = false;
		}
	}
	/*
	 * WRapper for showing Accounts on TTF if it is a multi-ein or same login
	 */
	public class AccountWrapper {
		public Account objAccount { get; set; }
		public Boolean isSelected { get; set; }
		public Integer intIndex { get; private set; }

		public AccountWrapper(Account objAcc, Boolean isSelect, Integer indx) {
			objAccount = objAcc;
			isSelected = isSelect;
			intIndex = indx;
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Process Opportunity.Order__c Additional infomation and copy information to TTF records.
	 * @Parm        : Object of Transition_To_Fulfillment__c record.
	 				: Object of Opportunity record.
	 * @Return      : Object of Transition_To_Fulfillment__c record.
	 **/
	public static Transition_To_Fulfillment__c processOrderAdditionalData(Transition_To_Fulfillment__c objTTFRecord, Opportunity objOppty) {
		if (objOppty.Order__c != null) {
			objTTFRecord.Number_Of_Pay_Schedules__c = objOppty.Order__r.Number_Of_Pay_Schedules__c;
			objTTFRecord.Last_Expected_Pay_Date__c = objOppty.Order__r.Last_Expected_Pay_Date__c;
			objTTFRecord.Direct_Deposit_Speed__c = objOppty.Order__r.Direct_Deposit_Speed__c;
			objTTFRecord.Has_Remote_Employees__c = objOppty.Order__r.Has_Remote_Employees__c;
			objTTFRecord.Registered_As_Employer_In_Work_States__c = objOppty.Order__r.Registered_As_Employer_In_Work_States__c;
			objTTFRecord.Employee_Payment_Method__c = objOppty.Order__r.Employee_Payment_Method__c;
			objTTFRecord.Employees_With_Multiple_Tax_Jurisdiction__c = objOppty.Order__r.Employees_With_Multiple_Tax_Jurisdiction__c;
			objTTFRecord.Invite_Employees_Via_Email__c = objOppty.Order__r.Invite_Employees_Via_Email__c;
			objTTFRecord.Invite_Dismissed_Employees_Via_Email__c = objOppty.Order__r.Invite_Dismissed_Employees_Via_Email__c;
			objTTFRecord.Pay_Contractors_With_Payroll_Provider__c = objOppty.Order__r.Pay_Contractors_With_Payroll_Provider__c;
			objTTFRecord.Contractor_Payment_Method__c = objOppty.Order__r.Contractor_Payment_Method__c;
			objTTFRecord.Pay_International_Contractors__c = objOppty.Order__r.Pay_International_Contractors__c;
			objTTFRecord.Contractor_Countries__c = objOppty.Order__r.Contractor_Countries__c;
			objTTFRecord.Invite_Contractors_Via_Email__c = objOppty.Order__r.Invite_Contractors_Via_Email__c;
			objTTFRecord.Time_Off_Offered__c = objOppty.Order__r.Time_Off_Offered__c;
			objTTFRecord.Track_PTO_Policies__c = objOppty.Order__r.Track_PTO_Policies__c;
			objTTFRecord.New_Health_Benefits__c = objOppty.Order__r.New_Health_Benefits__c;
			objTTFRecord.Employees_With_Tax_Exemptions__c = objOppty.Order__r.Employees_With_Tax_Exemptions__c;
		}

		return objTTFRecord;
	}
}