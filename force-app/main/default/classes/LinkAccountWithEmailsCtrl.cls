/**
 * @name         LinkAccountWithEmailsCtrl
 * @author       Neha Dabas
 * @date         12/11/2019
 * @description  Controller for LinkAccountWithEmails page
 * @revisions    Date ------------ Name ------------ Comments
 **/
public without sharing class LinkAccountWithEmailsCtrl {
	public Order objOrd { get; set; } // To show date filter and Account Lookup
	public List<EmailWrapper> lst_EmailsWrap { get; private set; }
	public Map<Id, EmailWrapper> map_EmailsWrapper { get; private set; }
	public Email_Message__c emailMessageRecord { get; set; }

	public List<SelectOption> lstInboxType { get; set; } // unselected inbox type values in search filter
	public List<string> lstSelectedInboxType { get; set; } // to get selected inbox type
	public String str_SubSearch { get; set; }
	public Set<String> set_InboxType { get; set; }
	public Integer intSelectedEmail { get; set; }
	public Id idSelectedEmail { get; set; }
	public Date dtStartDate { get; set; }
	public Date dtEndDate { get; set; }
	public EmailWrapper objEmailToLink { get; set; }
	public boolean bool_ShowEmailLinkSection { get; set; }
	public list<Case> lstCasesWithCarrier { get; set; }
	public list<Case> lstCasesMemberFulfilment { get; set; }
	public Boolean blnIsSearchByAccount { get; set; }
	public Id accIdToBeDeLink { get; set; }

	public Id idSelectedCase { get; set; }

	public Id idSelectedAccount { get; set; } // used to identify the account for which the New Case button is clicked
	public Case objExistingCase { get; set; }

	public Boolean isError { get; private set; }
	private Integer intEmailPageNumber; // used to keep track of the last page number for the emails

	public map<String, Boolean> map_CaseToStdEmail { get; set; }

	// Pagination variables
	public static Integer QUERY_LIMIT { get; set; }
	public static Integer PAGE_SIZE { get; set; }
	public Boolean boolGetArchivedEmails { get; set; }
	public Boolean blnGetSecuredEmails { get; set; }
	public String strSortBy { get; set; }
	public String strPrevSortBy { get; set; }
	public String strOrderAs { get; set; }
	public static String ORDER_BY_ASC = 'ASC';
	public static String ORDER_BY_DESC = 'DESC';
	public Set<Id> set_SelectedIds = new Set<Id>();
	public Set<Id> set_SelectedSecureIds = new Set<Id>();
	public Integer intSelectedRecordCount { get; set; }
	public Integer intSelectedSecureRecordCount { get; set; }
	public Set<Id> set_SelectedUnSecureIds = new Set<Id>();
	public Integer intSelectedUnSecureRecordCount { get; set; }

	public EmailWrapper objEmailMsgWrapper {
		get {
			if (null != lst_EmailsWrap && intSelectedEmail > -1 && intSelectedEmail < lst_EmailsWrap.size()) {
				return lst_EmailsWrap.get(intSelectedEmail);
			}

			return null;
		}
		private set;
	}

	//Conditionally add fields for the query when calling from link account button to reduce page size.
	public String formQuery(Id idEmailMessage) {
		String strEmailQuery = 'SELECT';
		String strFromFields = ' Id, Name, Inbox_Type__c, CC_Address__c, Linked_Accounts__c, To_Addresses__c, Account_List__c, From_Addresses__c, Subject__c, Archived__c, Possible_Match__c, CreatedDate,(SELECT Id, Name FROM Attachments), Secure_Email__c, Secured_Email_Date_Time__c, Parent_Case__c';
		String strFromClause = ' FROM Email_Message__c';

		// If Link Account is not clicked then this condition is satisfied.
		if (idEmailMessage == null) {
			if (String.isNotBlank(strFromFields)) {
				strEmailQuery += strFromFields;
			}
			if (String.isNotBlank(strFromClause)) {
				strEmailQuery += strFromClause;
			}
			String strwhereClause = ' WHERE Inbox_Type__c != null AND Subject__c != null AND Ignore_from_Search__c = false';
			if (dtStartDate != null) {
				strwhereClause += ' AND DAY_ONLY(convertTimezone(CreatedDate)) >= :dtStartDate';
			}
			if (dtEndDate != null) {
				strwhereClause += ' AND DAY_ONLY(convertTimezone(CreatedDate)) <= :dtEndDate';
			}
			if (set_InboxType != null && set_InboxType.size() > 0) {
				strwhereClause += ' AND Inbox_Type__c IN :lstSelectedInboxType';
			}
			if (String.isNotBlank(str_SubSearch)) {
				str_SubSearch = String.escapeSingleQuotes(str_SubSearch);
				strwhereClause += '  AND ( Subject__c LIKE \'%' + str_SubSearch + '%\'';
				strwhereClause += '  OR  To_Address__c LIKE \'%' + str_SubSearch + '%\'';
				strwhereClause += '  OR  From_Addresses__c LIKE \'%' + str_SubSearch + '%\'';
				strwhereClause += '  OR  Text_Body_Chunk_1__c LIKE \'%' + str_SubSearch + '%\')';
			}

			if (!boolGetArchivedEmails)
				strwhereClause += ' AND Archived__c = :boolGetArchivedEmails ';

			if (blnGetSecuredEmails) {
				strwhereClause += ' AND Secure_Email__c =: blnGetSecuredEmails ';
			}

			if (String.isNotBlank(strwhereClause)) {
				strEmailQuery += strwhereClause;
			}
			strEmailQuery += ' ORDER BY ' + strSortBy + ' ' + strOrderAs;

			strEmailQuery += ' LIMIT :QUERY_LIMIT ';
		} else if (idEmailMessage != null) {
			strFromFields += ',Parent_Case__r.Origin';
			strFromFields += ',EmailID__c,Email_Attached_Date__c,Parent_Case__r.CaseNumber,Parent_Case__r.AccountId,(SELECT Case__c,Standard_Email__c FROM Emails_Attached_To_Case__r)';
			if (String.isNotBlank(strFromFields)) {
				strEmailQuery += strFromFields;
			}
			if (String.isNotBlank(strFromClause)) {
				strEmailQuery += strFromClause;
			}
			String strwhereClause = ' WHERE Id = :idEmailMessage';
			if (String.isNotBlank(strwhereClause)) {
				strEmailQuery += strwhereClause;
			}
		}
		return strEmailQuery;
	}

	public ApexPages.StandardSetController setCon {
		get {
			// Getting configuration settings initialized.
			Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
			QUERY_LIMIT = objConfigSettings?.Universal_Inbox_Query_Limit__c != null ? Integer.valueOf(objConfigSettings.Universal_Inbox_Query_Limit__c) : 10000;
			PAGE_SIZE = objConfigSettings?.Universal_Inbox_Page_Size__c != null ? Integer.valueOf(objConfigSettings.Universal_Inbox_Page_Size__c) : 50;

			if (setCon == null) {
				if (String.isNotBlank(str_SubSearch) && str_SubSearch.length() < 4) {
					apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'For performance reasons, search string must be atleast 4 characters long'));
					return setCon;
				}
				String str_EmailQuery = formQuery(null);
				setCon = new ApexPages.StandardSetController(Database.getQueryLocator(str_EmailQuery));
				setCon.setPageSize(PAGE_SIZE);
			}
			return setCon;
		}
		set;
	}

	/*
	 * Constructor
	 */
	public LinkAccountWithEmailsCtrl() {
		lst_EmailsWrap = new List<EmailWrapper>();
		strSortBy = 'CreatedDate';
		strOrderAs = ORDER_BY_ASC;
		strPrevSortBy = strSortBy;
		initData();
		fetchEmails();
	}
	/*
	 * Initialize data
	 */
	@TestVisible
	private void initData() {
		// By Default, assume the search is by Account.
		blnIsSearchByAccount = true;
		//set default date range for Search
		objOrd = new Order();

		// start date
		if (dtStartDate == null) {
			dtStartDate = system.today().addDays(-1);
		}
		// end date
		if (dtEndDate == null) {
			dtEndDate = system.today();
		}

		lstInboxType = new List<SelectOption>();
		lstSelectedInboxType = new List<String>();

		Schema.DescribeSObjectResult sobject_describe = Email_Message__c.getSObjectType().getDescribe();
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
		List<Schema.PicklistEntry> pick_list_values = field_map.get('Inbox_Type__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			SelectOption so = new selectOption(a.getValue().trim(), a.getLabel().trim());
			lstInboxType.add(so);
			lstSelectedInboxType.add(so.getValue());
		}
		if (lstSelectedInboxType != null && lstSelectedInboxType.size() > 0) {
			set_InboxType = new Set<String>(lstSelectedInboxType);
		}
		boolGetArchivedEmails = false;
		blnGetSecuredEmails = false;
		bool_ShowEmailLinkSection = false;
	}
	/*
	 * Refresh Emails by resetting the pagination & search keyword
	 */
	public void refreshEmails() {
		setCon = null;
		set_SelectedIds = new Set<Id>();
		set_SelectedSecureIds = new Set<Id>();
		intSelectedRecordCount = 0;
		intSelectedSecureRecordCount = 0;
		set_SelectedUnSecureIds = new Set<Id>();
		intSelectedUnSecureRecordCount = 0;
		constructEmailWrapper(null);
	}
	/*
	 * Fetch Emails using search params by resetting the pagination
	 */
	public void fetchEmails() {
		resetSelectedEmailSet();
		setCon = null;
		idSelectedEmail = Apexpages.currentPage().getParameters().get('mId');
		constructEmailWrapper(idSelectedEmail);
	}
	/*
	 * Construct email wrapper
	 */
	@TestVisible
	private void constructEmailWrapper(Id idEmailMessage) {
		map_EmailsWrapper = new Map<Id, EmailWrapper>();
		lst_EmailsWrap = new List<EmailWrapper>();
		if (null == setCon)
			return;
		List<Email_Message__c> lst_EmailMessages;
		if (idEmailMessage == null) {
			lst_EmailMessages = (List<Email_Message__c>) setCon.getRecords();
		} else {
			String str_EmailQuery = formQuery(idEmailMessage);
			lst_EmailMessages = Database.query(str_EmailQuery);
		}

		if (null == lst_EmailMessages || lst_EmailMessages.size() == 0) {
			return;
		}

		//Get All account Ids to get Account Name

		List<String> list_AccountIds = new List<String>();
		for (Email_Message__c msg : lst_EmailMessages) {
			if (String.isNotBlank(msg.Linked_Accounts__c)) {
				list_AccountIds.addAll(msg.Linked_Accounts__c.split(';'));
			}
			if (null != msg.Account_List__c && String.isNotBlank(msg.Account_List__c)) {
				list_AccountIds.addAll(msg.Account_List__c.split(';'));
			}
		}
		Set<String> set_AccountIds;
		//Fetch Account details for possible matches
		Map<Id, Account> map_AccountDetails;
		if (list_AccountIds.size() > 0) {
			set_AccountIds = new Set<String>(list_AccountIds);

			map_AccountDetails = new Map<Id, Account>(
				[SELECT Joined_Date_Panda__c, Name, OwnerId, Owner.Name, ZP_Company_Overall_Status__c, ZP_Company_ID__c FROM Account WHERE Id IN :set_AccountIds]
			);
		}

		//Construct the email wrapper
		Integer indx = 0;
		for (Email_Message__c msg : lst_EmailMessages) {
			List<String> lst_PossibleMatchAccIds;
			if (null != msg.Account_List__c && String.isNotBlank(msg.Account_List__c)) {
				lst_PossibleMatchAccIds = new List<String>(msg.Account_List__c.split(';'));
			}

			EmailWrapper eWrap = new EmailWrapper(msg, map_AccountDetails, lst_PossibleMatchAccIds, indx);

			lst_EmailsWrap.add(eWrap);
			map_EmailsWrapper.put(msg.Id, eWrap);

			indx++;
			if (set_SelectedIds.contains(msg.Id)) {
				set_SelectedIds.remove(msg.Id);
				eWrap.blnSelect = true;
			}

			if (set_SelectedSecureIds.contains(msg.Id)) {
				set_SelectedSecureIds.remove(msg.Id);
				eWrap.blnSelect = true;
			}

			if (set_SelectedUnSecureIds.contains(msg.Id)) {
				set_SelectedUnSecureIds.remove(msg.Id);
				eWrap.blnSelect = true;
			}

			intSelectedRecordCount = set_SelectedIds.size();
			intSelectedSecureRecordCount = set_SelectedSecureIds.size();
			intSelectedUnSecureRecordCount = set_SelectedUnSecureIds.size();
		}
	}

	//indicates whether there are more records after the current page set.
	public Boolean hasNext {
		get {
			if (null != setcon)
				return setCon.getHasNext();
			return null;
		}
		set;
	}

	//indicates whether there are more records before the current page set.
	public Boolean hasPrevious {
		get {
			if (null != setcon)
				return setCon.getHasPrevious();

			return null;
		}
		set;
	}

	//returns the page number of the current page set
	public Integer pageNumber {
		get {
			if (null != setcon)
				return setCon.getPageNumber();
			else
				return 0;
		}
		set;
	}

	//return total number of pages for page set
	public Integer getTotalPages() {
		if (null != setcon) {
			Decimal totalSize = setCon.getResultSize();
			Decimal pageSize = setCon.getPageSize();
			Decimal pages = totalSize / pageSize;
			return (Integer) pages.round(System.RoundingMode.CEILING);
		}
		return 0;
	}

	//returns the first page of the page set
	public void first() {
		saveSetControler();
		resetSelectedEmailSet();
		setCon.first();
		constructEmailWrapper(null);
	}

	//returns the last page of the page set
	public void last() {
		saveSetControler();
		resetSelectedEmailSet();
		setCon.last();
		constructEmailWrapper(null);
	}

	//returns the previous page of the page set
	public void previous() {
		saveSetControler();
		resetSelectedEmailSet();
		setCon.previous();
		constructEmailWrapper(null);
	}

	//returns the next page of the page set
	public void next() {
		saveSetControler();
		resetSelectedEmailSet();
		setCon.next();
		constructEmailWrapper(null);
	}

	public void showSelectedEmail() {
		emailMessageRecord = new Email_Message__c();
		if (lst_EmailsWrap.size() > 0 && intSelectedEmail != null) {
			EmailWrapper wrap = lst_EmailsWrap.get(intSelectedEmail);
			Id idEM = wrap.obj_Message.Id;
			if (idEM != null) {
				for (Email_Message__c objEmailMessage : [SELECT Id, Text_Body__c FROM Email_Message__c WHERE Id = :idEM]) {
					emailMessageRecord.Text_Body__c = objEmailMessage.Text_Body__c;
				}
			}
		}
	}
	//To mark selected email as archived
	public void archiveSelectedEmail() {
		if (null != lst_EmailsWrap && intSelectedEmail > -1 && intSelectedEmail < lst_EmailsWrap.size()) {
			EmailWrapper wrap = lst_EmailsWrap.get(intSelectedEmail);
			wrap.obj_Message.Archived__c = true;
			wrap.obj_Message.Email_Archived_by__c = UserInfo.getUserId();

			update wrap.obj_Message;
		}
	}

	public void secureSelectedEmail() {
		if (null != lst_EmailsWrap && intSelectedEmail > -1 && intSelectedEmail < lst_EmailsWrap.size()) {
			EmailWrapper wrap = lst_EmailsWrap.get(intSelectedEmail);
			wrap.obj_Message.Secure_Email__c = true;
			wrap.obj_Message.Secured_Email_Date_Time__c = Datetime.now();

			update wrap.obj_Message;
		}
	}

	public void unSecureSelectedEmail() {
		if (null != lst_EmailsWrap && intSelectedEmail > -1 && intSelectedEmail < lst_EmailsWrap.size()) {
			EmailWrapper wrap = lst_EmailsWrap.get(intSelectedEmail);
			wrap.obj_Message.Secure_Email__c = false;
			wrap.obj_Message.Secured_Email_Date_Time__c = null;

			update wrap.obj_Message;
		}
	}

	//show email section
	public void showAllEmails() {
		bool_ShowEmailLinkSection = false;
		fetchEmails();

		if (intEmailPageNumber > -1 && intEmailPageNumber <= getTotalPages()) {
			if (intEmailPageNumber == 1) {
				// go to first
				first();
			} else if (intEmailPageNumber == getTotalPages()) {
				// go to last
				last();
			} else {
				while (pageNumber != intEmailPageNumber) {
					//go to page number
					next();
				}
			}

			intEmailPageNumber = -1;
		}
	}

	//Show link email section
	public void linkSelectedEmail() {
		//reinitialize case lists
		lstCasesWithCarrier = new List<Case>();
		lstCasesMemberFulfilment = new List<Case>();
		idSelectedEmail = Apexpages.currentPage().getParameters().get('mId');

		// Moved Link Account section to new page. Now we will need to get the wrapper instance using the Email Message Id.
		if (idSelectedEmail != null && map_EmailsWrapper != null && map_EmailsWrapper.containsKey(idSelectedEmail)) {
			objEmailToLink = map_EmailsWrapper.get(idSelectedEmail);
			Id idEM = objEmailToLink.obj_Message.Id;
			if (idEM != null) {
				List<Email_Message__c> list_EM = [SELECT Id, Text_Body__c FROM Email_Message__c WHERE Id = :idEM];
				objEmailToLink.obj_Message.Text_Body__c = list_EM[0].Text_Body__c;
			}
			// set this to true to manage the visibility of sections on page
			bool_ShowEmailLinkSection = true;
			map_CaseToStdEmail = new Map<String, Boolean>();

			// if there are any linked accounts for current email then fetch case information
			if (String.isNotBlank(objEmailToLink.obj_Message.Linked_Accounts__c)) {
				fetchCaseDetailsWithCO();
				fetchMemberFulfillmentCases(null);
			}
		}
		intEmailPageNumber = pageNumber;
	}

	/*
	 * Fetch Carrier Order Cases associated with linked accounts
	 */
	public void fetchCaseDetailsWithCO() {
		if (String.isBlank(objEmailToLink.obj_Message.Linked_Accounts__c)) {
			return;
		}

		Set<String> setAccIds = new Set<String>(objEmailToLink.obj_Message.Linked_Accounts__c.split(';'));
		// Case record types which need to be fetched
		Set<String> setCaseRecTypeWithCO = new Set<String>{ 'Benefits Renewal Case', 'Benefits New Plan Case', 'Benefits Change Case' };
		// Case statuses which need to be excluded from query
		Set<String> setOrderStatusToExclude = new Set<String>{ 'Canceled', 'Closed Admin', 'Closed Lost' };
		// Case Statuses to include/exclude
		Set<String> setCaseStatus = new Set<String>{ 'Cancelled', 'Closed' };
		// CO Implementage Stages to exclude from query
		Set<String> setCOOrderStagesToExclude = new Set<String>{ 'Canceled', 'Closed Admin' };

		// SJay - 03/20/2020 - Added Dynamic SOQL to conditionally get closed or not closed cases based on Search by Account or Contact.
		if (setAccIds.size() > 0) {
			String strEmailQuery = 'SELECT Carrier_Order__c,Carrier_Order__r.Benefit_Order__c,Carrier_Order__r.Benefit_Order__r.Coverage_Effective_Date__c,Opportunity__c,Related_Case__c,Requires_Action__c,';
			strEmailQuery += ' Carrier_Order__r.Benefit_Order__r.Name,Carrier_Order__r.Effective_Date__c,Carrier_Order__r.Carrier__r.Name,Carrier_Order__r.Name,Carrier_Order__r.Implementation_Stage__c,';
			strEmailQuery += ' CaseNumber,AccountId,Type,Status,Subject,OwnerId';
			String strFromQuery = ' FROM Case';
			String strwhereClause = ' WHERE Carrier_Order__r.Implementation_Stage__c NOT IN :setCOOrderStagesToExclude';
			strwhereClause += ' AND RecordType.Name IN :setCaseRecTypeWithCO AND Carrier_Order__c != null';
			strwhereClause += ' AND Carrier_Order__r.Benefit_Order__r.Coverage_Effective_Date__c >= LAST_N_MONTHS:3';
			strwhereClause += ' AND Carrier_Order__r.Benefit_Order__r.Order_Status__c NOT IN :setOrderStatusToExclude';
			strwhereClause += ' AND AccountId IN :setAccIds';
			if (blnIsSearchByAccount) {
				strwhereClause += ' AND Status NOT IN :setCaseStatus';
			}
			strEmailQuery += strFromQuery + strwhereClause;
			lstCasesWithCarrier = database.query(strEmailQuery);
		}

		for (Case objCase : lstCasesWithCarrier) {
			if (null != objEmailToLink.map_AttachedCaseEmails && objEmailToLink.map_AttachedCaseEmails.containsKey(objCase.Id)) {
				map_CaseToStdEmail.put(objCase.Id, true);
			} else
				map_CaseToStdEmail.put(objCase.Id, false);
		}
	}
	/*
	 * Fetch Member Fulfilment Cases associated with linked accounts
	 */
	public void fetchMemberFulfillmentCases(List<Contact> list_Contact) {
		// Case Statuses to include/exclude
		Set<String> setCaseStatus = new Set<String>{ 'Cancelled', 'Closed' };
		// SJay - 03/20/2020 - Removed 'MF Audit' from eligible record types for MF cases.
		// Case record types which need to be fetched
		Set<String> setCaseRecTypeMF = new Set<String>{ 'MF Group Updates', 'MF Member/Group Updates', 'MF NHE', 'MF QLE', 'MF Termination', 'MF Viking Master', 'Member Fulfillment Emails' };

		if (String.isBlank(objEmailToLink.obj_Message.Linked_Accounts__c)) {
			return;
		}
		Set<String> setAccIds = new Set<String>(objEmailToLink.obj_Message.Linked_Accounts__c.split(';'));

		// SJay - 03/13/2020 - Removed MF Complete Owner criteria and Status != Closed. Changed Limit to 50
		// SJay - 03/20/2020 - Added dynamic SOQL to handle Search by Account and Search by Contact.
		String strEmailQuery = 'SELECT Related_Case__c,Requires_Action__c,CaseNumber,Type,Status,Subject,AccountId';
		String strFromQuery = ' FROM Case';
		String strwhereClause = ' WHERE RecordType.Name IN :setCaseRecTypeMF AND AccountId IN :setAccIds';
		if (blnIsSearchByAccount) {
			strwhereClause += ' AND Status NOT IN :setCaseStatus';
		} else if (!blnIsSearchByAccount && list_Contact != null && !list_Contact.isEmpty()) {
			strwhereClause += ' AND ContactId IN :list_Contact';
		}
		strEmailQuery += strFromQuery + strwhereClause;
		strEmailQuery += ' ORDER BY CreatedDate DESC LIMIT 50';
		lstCasesMemberFulfilment = database.query(strEmailQuery);

		for (Case objCase : lstCasesMemberFulfilment) {
			if (null != objEmailToLink.map_AttachedCaseEmails && objEmailToLink.map_AttachedCaseEmails.containsKey(objCase.Id)) {
				map_CaseToStdEmail.put(objCase.Id, true);
			} else
				map_CaseToStdEmail.put(objCase.Id, false);
		}
	}
	/*
	 * De-link selected account from Email Message
	 */
	public void delinkAccount() {
		try {
			//Email is not null and account which needs to deLinked is selected
			if (null != objEmailToLink && null != accIdToBeDeLink && objEmailToLink.map_LinkedAccounts.containsKey(accIdToBeDeLink)) {
				//remove selected account from Linked Account Map
				objEmailToLink.map_LinkedAccounts.remove(accIdToBeDeLink);

				//remove from Linked_Accounts field on Email Message
				if (objEmailToLink.obj_Message.Linked_Accounts__c.contains(accIdToBeDeLink)) {
					objEmailToLink.obj_Message.Linked_Accounts__c = objEmailToLink.obj_Message.Linked_Accounts__c.replace(accIdToBeDeLink + ';', '');
				}
				//If it was a possible match, then set the Selected MAp value to false
				if (null != objEmailToLink.map_SelectedAccounts && objEmailToLink.map_SelectedAccounts.containsKey(accIdToBeDeLink)) {
					objEmailToLink.map_SelectedAccounts.put(accIdToBeDeLink, false);
				}

				update objEmailToLink.obj_Message;

				//reinitialize case lists
				lstCasesWithCarrier = new List<Case>();
				lstCasesMemberFulfilment = new List<Case>();
				//fetch cases based on new value of Linked Accounts
				fetchCaseDetailsWithCO();
				fetchMemberFulfillmentCases(null);
			}
			accIdToBeDeLink = null; // reinit selected Account variable
		} catch (Exception ex) {
			ApexPages.AddMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage() + '  ' + ex.getStacktraceString()));
			ExceptionLogUtil.logException('LinkAccountWithEmailsCtrl', 'delinkAccount', ex.getMessage(), ex.getStackTraceString());
		}
	}

	/*
	 * Link new selected account with Email Message
	 */
	public void linkNewAccount() {
		try {
			Account objNewLinkedAcc = new Account();
			List<Account> list_NewLinkedAccounts = new List<Account>();

			// Select Account section:
			// If an account is entered into the input box then an account is searched for and the related cases are shown
			if (null != objOrd.AccountId) {
				//fetch account details for the selected account
				list_NewLinkedAccounts = [
					SELECT Joined_Date_Panda__c, Name, OwnerId, Owner.Name, ZP_Company_Overall_Status__c, ZP_Company_ID__c
					FROM Account
					WHERE Id = :objOrd.AccountId
				];
				if (list_NewLinkedAccounts.size() > 0) {
					objNewLinkedAcc = list_NewLinkedAccounts.get(0);
				}
				if (objNewLinkedAcc != null) {
					blnIsSearchByAccount = true;
					linkAccountAndGetCases(objNewLinkedAcc, null);
				}
			}
			// Select Contact section:
			// If a contact name is entered into the input box then the contact's related cases are queried and MF cases are shown in the UI
			else if (objOrd.CustomerAuthorizedById != null) {
				// SJay - 03/20/2020 - Removed 'MF Audit' from eligible record types for MF cases.
				Set<String> setCaseRecTypeMF = new Set<String>{ 'MF Group Updates', 'MF Member/Group Updates', 'MF NHE', 'MF QLE', 'MF Termination', 'MF Viking Master', 'Member Fulfillment Emails' };

				List<Contact> list_SearchedContact = [
					SELECT ID, AccountId
					FROM Contact
					WHERE ID = :objOrd.CustomerAuthorizedById
				];
				if (list_SearchedContact.size() > 0) {
					//fetch account details for the selected contact
					list_NewLinkedAccounts = [
						SELECT Joined_Date_Panda__c, Name, OwnerId, Owner.Name, ZP_Company_Overall_Status__c, ZP_Company_ID__c
						FROM Account
						WHERE ID = :list_SearchedContact.get(0).AccountId
					];
					if (list_NewLinkedAccounts.size() > 0) {
						objNewLinkedAcc = list_NewLinkedAccounts.get(0);
					}
					if (objNewLinkedAcc != null) {
						blnIsSearchByAccount = false;
						linkAccountAndGetCases(objNewLinkedAcc, list_SearchedContact);
					}
				}
			} else {
				ApexPages.AddMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Please select an account or a contact which is to be linked.'));
			}
			objOrd.AccountId = null;
			objOrd.CustomerAuthorizedById = null;
		} catch (Exception ex) {
			ApexPages.AddMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			ExceptionLogUtil.logException('LinkAccountWithEmailsCtrl', 'linkNewAccount', ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void linkAccountAndGetCases(Account objNewLinkedAcc, List<Contact> list_Contact) {
		//add account to map_LinkedAccounts
		if (objEmailToLink.map_LinkedAccounts == null) {
			objEmailToLink.map_LinkedAccounts = new Map<Id, Account>();
		}
		objEmailToLink.map_LinkedAccounts.put(objNewLinkedAcc.Id, objNewLinkedAcc);

		//update email Message's LinkedAccounts field
		if (objEmailToLink.obj_Message.Linked_Accounts__c == null) {
			objEmailToLink.obj_Message.Linked_Accounts__c = '';
		}
		if (objNewLinkedAcc.Id != null) {
			objEmailToLink.obj_Message.Linked_Accounts__c += objNewLinkedAcc.Id + ';';
		}

		update objEmailToLink.obj_Message;

		//reinitialize case lists
		lstCasesWithCarrier = new List<Case>();
		lstCasesMemberFulfilment = new List<Case>();
		if (blnIsSearchByAccount) {
			fetchCaseDetailsWithCO();
			fetchMemberFulfillmentCases(null);
		} else {
			fetchMemberFulfillmentCases(list_Contact);
		}
	}

	/*
	 * Link selected account which is also a possible match with Email Message
	 */
	public void linkPossibleMatchAccount() {
		try {
			if (null != objEmailToLink && null != accIdToBeDeLink) {
				Boolean isLinked = objEmailToLink.map_SelectedAccounts.get(accIdToBeDeLink);

				if (isLinked) {
					//link
					Account objNewLinkedAcc = objEmailToLink.map_Accounts.get(accIdToBeDeLink);

					if (null == objEmailToLink.map_LinkedAccounts) {
						objEmailToLink.map_LinkedAccounts = new Map<Id, Account>();
					}
					objEmailToLink.map_LinkedAccounts.put(objNewLinkedAcc.Id, objNewLinkedAcc);
					if (null == objEmailToLink.obj_Message.Linked_Accounts__c) {
						objEmailToLink.obj_Message.Linked_Accounts__c = '';
					}
					if (objNewLinkedAcc.Id != null) {
						objEmailToLink.obj_Message.Linked_Accounts__c += objNewLinkedAcc.Id + ';';
					}

					update objEmailToLink.obj_Message;

					//reinitialize case lists
					lstCasesWithCarrier = new List<Case>();
					lstCasesMemberFulfilment = new List<Case>();

					fetchCaseDetailsWithCO();
					fetchMemberFulfillmentCases(null);
				} else {
					// deLink
					delinkAccount();
				}
			}
		} catch (Exception ex) {
			ApexPages.AddMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			ExceptionLogUtil.logException('LinkAccountWithEmailsCtrl', 'linkPossibleMatchAccount', ex.getMessage(), ex.getStackTraceString());
		}
	}
	/*
	 * Attach Email Message to selected case
	 */
	@TestVisible
	private void createCaseFeed() {
		//Insert new Email Message
		// SJay - 09-17-2020 - Addedd Status as Read, Incoming as true, FromName same as From Address.
		EmailMessage objNewEmail = new EmailMessage(
			ParentId = idSelectedCase,
			FromAddress = objEmailToLink.obj_Message.From_Addresses__c,
			ToAddress = objEmailToLink.obj_Message.To_Addresses__c,
			TextBody = objEmailToLink.obj_Message.Text_Body__c,
			CCAddress = objEmailToLink.obj_Message.CC_Address__c,
			Subject = objEmailToLink.obj_Message.Subject__c,
			Status = '1',
			Incoming = true,
			FromName = objEmailToLink.obj_Message.From_Addresses__c
		);

		//Chaitanya Kurra - 09-16-2020 - Skip Email Trigger for CaseFeed - Universal MailBox Issue
		Boolean blnIsSkipEmailMessageTrigger;
		blnIsSkipEmailMessageTrigger = EmailMessageTriggerHelper.skipTrigger;
		EmailMessageTriggerHelper.skipTrigger = true;
		insert objNewEmail;
		EmailMessageTriggerHelper.skipTrigger = blnIsSkipEmailMessageTrigger;

		//create child object to keep track of the new email meesgage created for case
		Email_Attached_To_Case__c emailToCase = new Email_Attached_To_Case__c(Case__c = idSelectedCase, Email_Message__c = objEmailToLink.obj_Message.Id, Standard_Email__c = objNewEmail.Id);

		insert emailToCase;

		if (null == objEmailToLink.map_AttachedCaseEmails) {
			objEmailToLink.map_AttachedCaseEmails = new Map<Id, Id>();
		}

		objEmailToLink.map_AttachedCaseEmails.put(idSelectedCase, objNewEmail.Id);
		map_CaseToStdEmail.put(idSelectedCase, true);

		//if there are any attachments on current email then attach the same on newly created case email
		if (null != objEmailToLink.obj_Message.Attachments && objEmailToLink.obj_Message.Attachments.size() > 0) {
			//Fetch attachment details
			Set<Id> setAttchmentId = new Set<Id>();
			for (Attachment objAtt : objEmailToLink.obj_Message.Attachments) {
				setAttchmentId.add(objAtt.Id);
			}

			List<Attachment> lstAttachments = [SELECT Body, ContentType, NAme FROM Attachment WHERE Id IN :setAttchmentId];

			List<Attachment> lstAttToInsert = new List<Attachment>();

			for (Attachment objAtt : lstAttachments) {
				lstAttToInsert.add(new Attachment(Name = objAtt.Name, Body = objAtt.Body, ContentType = objAtt.ContentType, ParentId = objNewEmail.Id));
			}

			if (lstAttToInsert.size() > 0) {
				insert lstAttToInsert;
			}
		}
	}
	/*
	 * Attach Email Message to the case created by Email-to-Case feature and if there is no existing case, then create one
	 */
	public void attachEmailToExistingCase() {
		try {
			isError = false;
			if (null != idSelectedAccount && null != objEmailToLink) {
				Account objAcc = objEmailToLink.map_LinkedAccounts.get(idSelectedAccount);

				objExistingCase = new Case();
				//if There is an exsisting case present on Email Message, then update that case
				if (objEmailToLink.obj_Message.Parent_Case__c != null) {
					objExistingCase.Id = objEmailToLink.obj_Message.Parent_Case__c;
				} else {
					// create a new case and set its subject to Email's Subject
					objExistingCase.Subject = objEmailToLink.obj_Message.Subject__c;
				}

				objExistingCase.AccountId = idSelectedAccount;
				objExistingCase.Requires_Action__c = true;
				upsert objExistingCase; // upsert the case record

				// update email message
				objEmailToLink.obj_Message.Archived__c = true;
				objEmailToLink.obj_Message.Email_Archived_by__c = UserInfo.getUserId();
				update objEmailToLink.obj_Message;

				//fetch case info of the case that is linked in order to open the record in another subTab/window
				objExistingCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :objExistingCase.Id];
			}
		} catch (Exception ex) {
			ApexPages.AddMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			ExceptionLogUtil.logException('LinkAccountWithEmailsCtrl', 'attachEmailToExistingCase', ex.getMessage(), ex.getStackTraceString());
			isError = true; // to make sure that subtab is not openned in case of an exception
		}
	}
	/*
	 * Attach Email Message to selected case
	 */
	public void attachEmailToCase() {
		try {
			isError = false;
			if (null != idSelectedCase && null != objEmailToLink) {
				Map<Id, Case> mapCOCases = new Map<Id, Case>(lstCasesWithCarrier);
				Map<Id, Case> mapMFCases = new Map<Id, Case>(lstCasesMemberFulfilment);

				// Insert feed for case
				// Insert only if the selected case is not the same as the custom email's case
				if (objEmailToLink.obj_Message != null && objEmailToLink.obj_Message.Parent_Case__c != idSelectedCase) {
					createCaseFeed();
				} else if (objEmailToLink.obj_Message != null && objEmailToLink.obj_Message.Parent_Case__c == null) {
					createCaseFeed();
				}

				//Update Case, Carrier Order and Email
				List<Carrier_Order__c> list_CarrierOrderToUpdate = new List<Carrier_Order__c>();
				List<Case> list_CaseToUpdate = new List<Case>();
				List<Email_Message__c> list_EmailMessageToUpdate = new List<Email_Message__c>();
				Case obj_SelectedCase;
				Boolean boolISCOCase = false;
				String strMFQueueId = Label.MF_FollowUp_QueueId;
				if (mapCOCases.containsKey(idSelectedCase)) {
					obj_SelectedCase = mapCOCases.get(idSelectedCase);

					boolISCOCase = true;
				} else if (mapMFCases.containsKey(idSelectedCase)) {
					obj_SelectedCase = mapMFCases.get(idSelectedCase);
				}
				if (null != obj_SelectedCase) {
					//set requires action on Case
					obj_SelectedCase.Requires_Action__c = true;
					Carrier_Order__c objCO;

					//Set requires action on Carrier Order
					if (obj_SelectedCase.Carrier_Order__c != null) {
						objCO = new Carrier_Order__c(CO_Requires_Action__c = true, id = obj_SelectedCase.Carrier_Order__c);
						//lstRecordsToUpdate.add(objCO);
					}

					// For Carrier Ops Emails
					if (objEmailToLink.obj_Message.Parent_Case__c == null) {
						// Date/Time the email message gets attached to the case selected by the user on this page.
						objEmailToLink.obj_Message.Email_Attached_Date__c = system.now();
						objEmailToLink.obj_Message.Email_Attached_By__c = UserInfo.getUserId();

						// SJay - 03/13/2020 - Removed CO Stage criteria to update Follow Up date and Email Attached Date.
						// If CO is Ready for Confirmation change follow up date to today and push to play mode.
						if (boolISCOCase && objCO != null) {
							// SJay - 06/18/2020 - Added condition to set follow up only if stage is not in pending confirmation.
							if (objCO.Implementation_Stage__c != 'Pending Confirmation')
								objCO.Follow_Up_Date__c = date.today();
							objCO.Email_Attached_Date__c = system.now();
							if (obj_SelectedCase.Status == 'Closed')
								obj_SelectedCase.Status = 'Open';
							obj_SelectedCase.Follow_Up_Date__c = date.today();
							obj_SelectedCase.Email_Attached_Date__c = system.now();
							list_CarrierOrderToUpdate.add(objCO);
						}
						// SJay - 03/20/2020 - Removed Case Status 'Submitted' & Owner as MF Queue criteria to update Follow Up date and Email Attached Date.
						// If MF Case is Submitted and owner is MF Followup then change follow up date to today.
						if (!boolISCOCase) {
							obj_SelectedCase.Follow_Up_Date__c = date.today();
							obj_SelectedCase.Email_Attached_Date__c = system.now();
						}

						// For email groups other than carrier ops which all have email-to-case setup
					} else if (null != objEmailToLink.obj_Message.Parent_Case__c) {
						//Attach original email to current Case

						//set relatedCase field on the case that user is attaching the email to
						if (objEmailToLink.obj_Message.Parent_Case__c != obj_SelectedCase.Id) {
							obj_SelectedCase.Related_Case__c = objEmailToLink.obj_Message.Parent_Case__c;
						} else {
							obj_SelectedCase.Follow_Up_Date__c = date.today();
							obj_SelectedCase.Email_Attached_Date__c = system.now();
						}

						// Date/Time the email message gets attached to the case selected by the user on this page.
						objEmailToLink.obj_Message.Email_Attached_Date__c = system.now();
						objEmailToLink.obj_Message.Email_Attached_By__c = UserInfo.getUserId();

						// SJay - Removed Parent case null check for custom email message
						Case objEmailToCase = new Case(Id = objEmailToLink.obj_Message.Parent_Case__c, AccountId = obj_SelectedCase.AccountId);
						String strRelatedCaseOrigin = objEmailToLink.obj_Message.Parent_Case__r.Origin;
						if (String.isNotBlank(strRelatedCaseOrigin) && strRelatedCaseOrigin == CaseUtils.ORIGIN_EMAIL) {
							objEmailToCase.Status = CaseUtils.STATUS_CLOSED;
						}

						if (boolISCOCase) {
							objEmailToCase.Benefit_Order__c = obj_SelectedCase.Carrier_Order__r.Benefit_Order__c;
							objEmailToCase.Carrier_Order__c = obj_SelectedCase.Carrier_Order__c;
							objEmailToCase.Opportunity__c = obj_SelectedCase.Opportunity__c;

							// SJay - 03/13/2020 - Removed CO Stage criteria to update Follow Up date and Email Attached Date.
							// If CO is Ready for Confirmation change follow up date to today and set Forced_Play_Mode__c.
							if (objCO != null) {
								// SJay - 06/18/2020 - Added condition to set follow up only if stage is not in pending confirmation.
								if (objCO.Implementation_Stage__c != 'Pending Confirmation')
									objCO.Follow_Up_Date__c = date.today();
								objCO.Email_Attached_Date__c = system.now();
								obj_SelectedCase.Email_Attached_Date__c = system.now();
								obj_SelectedCase.Follow_Up_Date__c = date.today();
								if (obj_SelectedCase.Status == 'Closed')
									obj_SelectedCase.Status = 'Open';
								list_CarrierOrderToUpdate.add(objCO);
							}
						}
						// SJay - 03/20/2020 - Removed Case Status 'Submitted' & Owner as MF Queue criteria to update Follow Up date and Email Attached Date.
						// If MF Case is Submitted and owner is MF Followup then change follow up date to today.
						if (!boolISCOCase) {
							obj_SelectedCase.Follow_Up_Date__c = date.today();
							obj_SelectedCase.Email_Attached_Date__c = system.now();
						}
						// SJay - 3/24/2020 - Added check to only add for unique IDs to avoid duplicate IDs in list.
						if (objEmailToLink.obj_Message.Parent_Case__c != obj_SelectedCase.Id) {
							list_CaseToUpdate.add(objEmailToCase);
						}
					}
					list_CaseToUpdate.add(obj_SelectedCase);
				}

				//update Email record as Archive
				objEmailToLink.obj_Message.Archived__c = true;
				objEmailToLink.obj_Message.Email_Archived_by__c = UserInfo.getUserId();
				list_EmailMessageToUpdate.add(objEmailToLink.obj_Message);

				if (list_EmailMessageToUpdate.size() > 0) {
					List<Database.SaveResult> list_UpdateResults = Database.update(list_EmailMessageToUpdate, false);

					Utils.processSaveRecords(list_UpdateResults, list_EmailMessageToUpdate, 'Id', true, 'LinkAccountWithEmailsCtrl', 'attachEmailToCase');
				}

				if (list_CaseToUpdate.size() > 0) {
					Boolean isSkipCaseTrigger;
					isSkipCaseTrigger = CaseTriggerHelper.skipTrigger;
					CaseTriggerHelper.skipTrigger = true;
					List<Database.SaveResult> list_UpdateResults = Database.update(list_CaseToUpdate, false);
					CaseTriggerHelper.skipTrigger = isSkipCaseTrigger;
					Utils.processSaveRecords(list_UpdateResults, list_CaseToUpdate, 'Id', true, 'LinkAccountWithEmailsCtrl', 'attachEmailToCase');
				}

				if (list_CarrierOrderToUpdate.size() > 0) {
					CarrierOrderTriggerHelper.blnUpdateOwner = false;
					List<Database.SaveResult> list_UpdateResults = Database.update(list_CarrierOrderToUpdate, false);
					CarrierOrderTriggerHelper.blnUpdateOwner = true;
					Utils.processSaveRecords(list_UpdateResults, list_CarrierOrderToUpdate, 'Id', true, 'LinkAccountWithEmailsCtrl', 'attachEmailToCase');
				}
			}
		} catch (Exception ex) {
			ApexPages.AddMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			isError = true;
		}
	}
	public class EmailWrapper {
		public Boolean blnSelect { get; set; }
		public Integer indx { get; private set; } // for Archive functionality
		public Email_Message__c obj_Message { get; private set; } // Email Message
		public Map<Id, Account> map_Accounts { get; private set; } // Possible match accounts
		public Map<Id, Account> map_LinkedAccounts { get; private set; } // Linked accounts
		public Map<Id, Boolean> map_SelectedAccounts { get; private set; } // to identify which accounts are linked and which are not linked out of possible match accounts for a particular email
		public String createdDateTime { get; private set; } // formatted DateTime for createdDate of email
		public List<String> lst_ToAddresses { get; private set; } // list of multiple To_Addresses for Email
		public List<String> lst_CCAddresses { get; private set; } // list of multiple CC_Addresses for Email
		public Map<Id, Id> map_AttachedCaseEmails { get; private set; } // Key is the case Id and value is standard email message id which was created to attach email to case
		//Constructor
		public EmailWrapper() {
		}
		//Constructor
		public EmailWrapper(Email_Message__c msg, map<Id, Account> map_Acc, List<String> lst_PossibleMatchAccIds, Integer index) {
			this.blnSelect = false;
			this.indx = index;

			obj_Message = msg;

			//if this email has already been attached, then populate the map
			map_AttachedCaseEmails = new Map<Id, Id>();
			if (obj_Message.Emails_Attached_To_Case__r != null && obj_Message.Emails_Attached_To_Case__r.size() > 0) {
				for (Email_Attached_To_Case__c objEmailCase : obj_Message.Emails_Attached_To_Case__r) {
					map_AttachedCaseEmails.put(objEmailCase.Case__c, objEmailCase.Standard_Email__c);
				}
			}

			//format DateTime
			createdDateTime = msg.CreatedDate.format();
			if (msg.CreatedDate.date() == system.today()) {
				createdDateTime = createdDateTime.substring(createdDateTime.indexOf(' ') + 1);
			}
			//populate To_Addresses list
			lst_ToAddresses = new List<String>();
			lst_CCAddresses = new List<String>();
			if (obj_Message.To_Addresses__c != null) {
				lst_ToAddresses = obj_Message.To_Addresses__c.split(';');
			}
			if (obj_Message.CC_Address__c != null) {
				lst_CCAddresses = obj_Message.CC_Address__c.split(';');
			}

			//populate all possible match account maps
			if (null != map_Acc && map_Acc.size() > 0) {
				if (null != lst_PossibleMatchAccIds && lst_PossibleMatchAccIds.size() > 0) {
					map_Accounts = new Map<Id, Account>();
					map_SelectedAccounts = new Map<Id, Boolean>();
					for (String strAccId : lst_PossibleMatchAccIds) {
						if (map_Acc.containsKey(strAccId)) {
							map_Accounts.put(strAccId, map_Acc.get(strAccId));
							if (null == obj_Message.Linked_Accounts__c || !obj_Message.Linked_Accounts__c.contains(strAccId)) {
								map_SelectedAccounts.put(strAccId, false);
							} else
								map_SelectedAccounts.put(strAccId, true);
						}
					}
				}
				//populate linked account map
				if (String.isNotBlank(obj_Message.Linked_Accounts__c)) {
					map_LinkedAccounts = new Map<Id, Account>();
					List<String> lstLinkedAcc = new List<String>(obj_Message.Linked_Accounts__c.split(';'));
					for (String strAccId : lstLinkedAcc) {
						if (String.isNotBlank(strAccId) && map_Acc.containsKey(strAccId)) {
							map_LinkedAccounts.put(strAccId, map_Acc.get(strAccId));
						}
					}
				}
			}
		}
	}
	//This method is used to save the state of the standered set controller when ever DML is performed
	public PageReference saveSetControler() {
		try {
			if (null != setcon) {
				Integer intCurrentPageNumber = pageNumber;
				setCon.save();
				//maintain the current page number of standerd set controller
				if (intCurrentPageNumber != 1) {
					setCon.setPageNumber(intCurrentPageNumber - 1);
					setCon.next();
				}
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
		}
		return null;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Sort Email Message list
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public void sortEmailList() {
		set_SelectedIds = new Set<Id>();
		set_SelectedSecureIds = new Set<Id>();
		set_SelectedUnSecureIds = new Set<Id>();
		setSortingFilter();
		refreshEmails();
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : set sort filter
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public void setSortingFilter() {
		if (strSortBy != strPrevSortBy) {
			strOrderAs = ORDER_BY_ASC;
			strPrevSortBy = strSortBy;
		} else {
			if (ORDER_BY_ASC == strOrderAs) {
				strOrderAs = ORDER_BY_DESC;
			} else {
				strOrderAs = ORDER_BY_ASC;
			}
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : reset selcted email list.
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public void resetSelectedEmailSet() {
		for (EmailWrapper objEM : lst_EmailsWrap) {
			if (objEM.blnSelect) {
				if (!objEM.obj_Message.Archived__c) {
					set_SelectedIds.add(objEM.obj_Message.Id);
				}
				if (!objEM.obj_Message.Secure_Email__c) {
					set_SelectedSecureIds.add(objEM.obj_Message.Id);
				}
				if (objEM.obj_Message.Secure_Email__c) {
					set_SelectedUnSecureIds.add(objEM.obj_Message.Id);
				}
			}
		}
		intSelectedRecordCount = set_SelectedIds.size();
		intSelectedSecureRecordCount = set_SelectedSecureIds.size();
		intSelectedUnSecureRecordCount = set_SelectedUnSecureIds.size();
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Archive Mass Email
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public void archiveMassEmail() {
		List<Email_Message__c> list_EM = new List<Email_Message__c>();
		for (EmailWrapper objEM : lst_EmailsWrap) {
			if (objEM.blnSelect && !objEM.obj_Message.Archived__c) {
				objEM.obj_Message.Archived__c = true;
				objEM.obj_Message.Email_Archived_by__c = UserInfo.getUserId();
				list_EM.add(objEM.obj_Message);
			}
		}

		for (Id idObj : set_SelectedIds) {
			list_EM.add(new Email_Message__c(Id = idObj, Archived__c = true, Email_Archived_by__c = UserInfo.getUserId()));
		}

		if (list_EM.size() > 0) {
			Utils.processUpsertResult(Database.upsert(list_EM, false), list_EM, 'Id', true, 'LinkAccountWithEmailsCtrl-archiveEmail');
		}

		set_SelectedIds = new Set<Id>();
		set_SelectedSecureIds = new Set<Id>();

		refreshEmails();
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Secure Mass Email
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public void secureMassEmail() {
		List<Email_Message__c> list_EM = new List<Email_Message__c>();
		for (EmailWrapper objEM : lst_EmailsWrap) {
			if (objEM.blnSelect && objEM.obj_Message.Secure_Email__c == false) {
				objEM.obj_Message.Secure_Email__c = true;
				objEM.obj_Message.Secured_Email_Date_Time__c = Datetime.now();

				list_EM.add(objEM.obj_Message);
			}
		}

		for (Id idObj : set_SelectedSecureIds) {
			list_EM.add(new Email_Message__c(Id = idObj, Secure_Email__c = true, Secured_Email_Date_Time__c = Datetime.now()));
		}

		if (list_EM.size() > 0) {
			Utils.processUpsertResult(Database.upsert(list_EM, false), list_EM, 'Id', true, 'LinkAccountWithEmailsCtrl-secureEmail');
		}

		set_SelectedIds = new Set<Id>();
		set_SelectedSecureIds = new Set<Id>();

		refreshEmails();
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Un-Secure Mass Email
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public void unSecureMassEmail() {
		List<Email_Message__c> list_EM = new List<Email_Message__c>();
		for (EmailWrapper objEM : lst_EmailsWrap) {
			if (objEM.blnSelect && objEM.obj_Message.Secure_Email__c == true) {
				objEM.obj_Message.Secure_Email__c = false;
				objEM.obj_Message.Secured_Email_Date_Time__c = null;

				list_EM.add(objEM.obj_Message);
			}
		}

		for (Id idObj : set_SelectedUnSecureIds) {
			list_EM.add(new Email_Message__c(Id = idObj, Secure_Email__c = false, Secured_Email_Date_Time__c = null));
		}

		if (list_EM.size() > 0) {
			Utils.processUpsertResult(Database.upsert(list_EM, false), list_EM, 'Id', true, 'LinkAccountWithEmailsCtrl-secureEmail');
		}

		set_SelectedIds = new Set<Id>();
		set_SelectedUnSecureIds = new Set<Id>();

		refreshEmails();
	}
}