/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<UR_ManageContactCtrl_Test>>
 * Description...........: <<This class is used to add/Release contact record as a participants in UXR Scout project.>>
 *-------------------------------------------------------------------------------*/
public with sharing class UR_ManageContactCtrl {
	public String currentRecordId { get; set; }
	public Research_Project_Master__c objProject { get; set; }
	public string strName { get; set; }
	public string strCompanyName { get; set; }
	public string strCity { get; set; }
	public string strState { get; set; }
	public string strCaseNumber { get; set; }
	public string strDaySinceCont { get; set; }
	public string strEmail { get; set; }
	public Account searchAccount { get; set; }
	public Account searchAccount1 { get; set; }
	public string strNPSScore { get; set; }
	public string strNPSScore1 { get; set; }

	public List<ContactRole> includeContactRoleList { get; set; }
	public List<ContactRole> excludeContactRoleList { get; set; }
	public List<CompanyState> includeCompanyStateList { get; set; }
	public List<selectOption> selInclude { get; set; }
	public List<selectOption> selExclude { get; set; }
	public String selIncludeStr { get; set; }
	public String selExcludeStr { get; set; }
	public List<selectOption> selIncludeState { get; set; }
	public String selIncludeStateStr { get; set; }

	public List<UserReportedIndustry> userReportedIndustryList { get; set; }
	public List<selectOption> selIndustry { get; set; }
	public String selIndustryStr { get; set; }

	public List<selectOption> selSoldThrough { get; set; }
	public string searchSoldThrough { get; set; }
	public List<selectOption> selTierList { get; set; }
	public string searchTier { get; set; }
	public List<selectOption> selCountryList { get; set; }
	public string searchCountry { get; set; }
	public list<ContactWrapper> lstMainContactWrapper { get; set; }
	public list<ContactWrapper> lstSelectedContactWrapper { get; set; }
	private set<Id> setSelectedContactId;
	public Research_Configuration__c objResearch { get; set; }
	public string extraNOP { get; set; }
	public boolean searchReseller { get; set; }
	public List<Contact> lstExistingContactList { get; set; }
	public Boolean showHide { get; set; }
	public Boolean showHideAddtionalFilter { get; set; }
	public string rightPanelStyle { get; set; }
	public string filterLabel { get; set; }
	public string strNameFilter { get; set; }
	public string strCompanyNameFilter { get; set; }
	public string strCityFilter { get; set; }
	public string strJoinDateFilter { get; set; }
	public string strfirstConPaymentDateFilter { get; set; }
	public string hasMedical { get; set; }
	public string hasActivePolicy { get; set; }
	public List<selectOption> yesNoOption { get; set; }
	public Map<String, List<Selectoption>> searchMap { get; set; }
	public string activeEmployeeFrom { get; set; }
	public string activeEmployeeTo { get; set; }
	public string activeContractorFrom { get; set; }
	public string activeContractorTo { get; set; }
	public string noClientFrom { get; set; }
	public string noClientTo { get; set; }
	public string participantComments { get; set; }
	public boolean excludeCompany { get; set; }
	public boolean isEditable { get; set; }
	public List<selectOption> companyStatus { get; set; }
	public String overAllCompanyStatus { get; set; }
	public boolean isAccountantSelected { get; set; }
	public boolean isReserveBtnClick { get; set; }
	private integer noOfParticipant;
	public boolean underApproval { get; set; }
	public static final Integer PAGE_SIZE = UR_UtilityCtrl.maxCSVRows;
	public ApexPages.StandardSetController setCon { get; set; }
	public Integer totalSelecedParticipant { get; set; }

	public Integer randomOffSet { get; set; }
	public String sortbyFieldAPIName { get; set; }
	public String prevSortbyFieldAPIName { get; set; }
	public String orderAs { get; set; }
	public String selSortbyFieldAPIName { get; set; }
	public String selPrevSortbyFieldAPIName { get; set; }
	public String selOrderAs { get; set; }
	public List<String> orderByList = new List<String>();
	public Set<Id> searchContactId { get; set; }
	public Integer totalSearchContact { get; set; }
	public List<selectOption> selPageResultList { get; set; }
	public String selPageResultStr { get; set; }
	public ApexPages.StandardSetController setSearchCon { get; set; }
	public Integer INT_MAX_INCENTIVE { get; set; }

	//Constructor
	public UR_ManageContactCtrl(ApexPages.StandardController st) {
		totalSearchContact = 0;
		isReserveBtnClick = false;
		noOfParticipant = 0;
		randomOffSet = 0;
		searchContactId = new Set<Id>();

		orderAs = ApexPages.CurrentPage().getparameters().get('orderas');
		if (String.isBlank(orderAs)) {
			orderAs = 'asc';
		}
		sortbyFieldAPIName = ApexPages.CurrentPage().getparameters().get('sortby');
		if (String.isBlank(sortbyFieldAPIName)) {
			sortbyFieldAPIName = 'Name';
		}
		sortbyFieldAPIName = sortbyFieldAPIName + ' ' + orderAs;
		prevSortbyFieldAPIName = sortbyFieldAPIName;

		selOrderAs = ApexPages.CurrentPage().getparameters().get('selorderas');
		if (String.isBlank(selOrderAs)) {
			selOrderAs = 'asc';
		}
		selSortbyFieldAPIName = ApexPages.CurrentPage().getparameters().get('selsortby');
		if (String.isBlank(selSortbyFieldAPIName)) {
			selSortbyFieldAPIName = 'Contact__r.Name';
		}
		selPrevSortbyFieldAPIName = selSortbyFieldAPIName;
		orderByList = new List<String>{ 'Id Asc', 'Id Desc', 'ZP_User_Id__c Asc', 'ZP_User_Id__c Desc', 'LastModifiedDate Asc', 'LastModifiedDate Desc', 'CreatedDate Asc', 'CreatedDate Desc' };
		selPageResultList = new List<selectOption>();
		selPageResultList.add(new selectOption('10', '10'));
		selPageResultList.add(new selectOption('25', '25'));
		selPageResultList.add(new selectOption('50', '50'));
		selPageResultList.add(new selectOption('100', '100'));
		selPageResultStr = '50';
		setSearchCon = new ApexPages.StandardSetController(new List<Contact>());

		searchMap = UR_UtilityCtrl.searchMap;
		isAccountantSelected = false;
		lstExistingContactList = new List<Contact>();
		setSelectedContactId = new Set<Id>();
		extraNOP = null;
		lstMainContactWrapper = new List<ContactWrapper>();
		lstSelectedContactWrapper = new List<ContactWrapper>();
		searchAccount = new Account();
		//Set Default Value
		searchAccount.ZP_Company_Overall_Status__c = 'Active';

		//As per danielle comment default should be 'Direct'
		//https://app.asana.com/0/954183500822396/1127706853024623/f
		searchSoldThrough = 'Direct - Came to Gusto on their own';

		searchAccount1 = new Account();
		currentRecordId = ApexPages.CurrentPage().getparameters().get('projectId');
		isEditable = UR_UtilityCtrl.IsEditAccess(currentRecordId);
		RetriveProjectConfiguration();
		RetriveProjectRecord();

		//Populate Contact Role
		populateConactRole();
		populateUserReportedIndustry();

		//Populate Sold through Partner
		populateSoldThroughPartner();
		populateTier();

		//Populate selcted Contact
		populateSelectedparticipant(true);
		showHide = true;
		showHideAddtionalFilter = false;
		rightPanelStyle = 'slds-large-size_8-of-12';
		filterLabel = '<< Hide Filters';
		yesNoOption = UR_UtilityCtrl.yesNoOption;
		excludeCompany = true;

		companyStatus = new List<selectOption>();
		companyStatus.add(new selectOption('Active', 'Active'));
		underApproval = false;
	}

	//This method show/hide search filter section from search contact screen.
	public void HideFilter() {
		if (showHide == true) {
			rightPanelStyle = 'slds-large-size_12-of-12';
			showHide = false;
			filterLabel = 'Show Filters >>';
		} else {
			rightPanelStyle = 'slds-large-size_8-of-12';
			showHide = true;
			filterLabel = '<< Hide Filters';
		}
	}

	//This method show/hide Additional search filter section from search contact screen.
	public void hideAddtionalFilter() {
		if (showHideAddtionalFilter == true) {
			showHideAddtionalFilter = false;
		} else {
			showHideAddtionalFilter = true;
		}
	}

	//This method fetch "Research Configuration (custom setting)" infomation.
	public void RetriveProjectConfiguration() {
		objResearch = new Research_Configuration__c();
		objResearch = UR_UtilityCtrl.RetriveResearchConfiguration();
		INT_MAX_INCENTIVE = 0;
		if (objResearch.Max_Incentive_of_Current_Year__c != null) {
			INT_MAX_INCENTIVE = Integer.valueOf(objResearch.Max_Incentive_of_Current_Year__c);
		}
		selCountryList = new List<selectOption>();
		selCountryList.add(new selectOption('', '--None--'));
		if (objResearch != null && objResearch.States__c != null) {
			for (String strValue : objResearch.States__c.split(',')) {
				if (String.isNotBlank(strValue)) {
					selCountryList.add(new selectOption(strValue.trim(), strValue.trim()));
				}
			}
		}
		if (objResearch != null && objResearch.Days_Since_Last_Contact_High_Limit__c != null) {
			strDaySinceCont = objResearch.Days_Since_Last_Contact_High_Limit__c + '';
		} else {
			strDaySinceCont = '90';
		}
	}

	//This method fetch UXR Scout project information.
	private void RetriveProjectRecord() {
		objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> lstReProject = [
			SELECT
				Project_Id__c,
				NDA_URL__c,
				Calendly_EventId__c,
				CreatedDate,
				Customer_Types__c,
				Description__c,
				Id,
				Name,
				Number_of_Participants_to_Add_to_Project__c,
				Number_of_Allowed_Participant__c,
				Survey_Id__c,
				Primary_calendly_URL__c,
				Product_Area__c,
				Project_End_Date__c,
				Incentive_Amount__c,
				Project_Start_Date__c,
				Project_Status__c,
				Researcher_Name__c,
				Screener_URL__c,
				Type_of_Research__c
			FROM Research_Project_Master__c
			WHERE Id = :currentRecordId
		];
		if (lstReProject != null && lstReProject.size() > 0) {
			objProject = lstReProject[0];
		}

		if (objProject.Id == null) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_InvalidProjectDetail));
		}
	}

	//This method populate contact role filter option.
	private void populateConactRole() {
		selInclude = new List<selectOption>();
		selInclude.add(new selectOption('OR', 'Include Any (OR)'));
		selInclude.add(new selectOption('AND', 'Include All (AND)'));

		selExclude = new List<selectOption>();
		selExclude.add(new selectOption('OR', 'Exclude Any (OR)'));
		selExclude.add(new selectOption('AND', 'Exclude All (AND)'));

		includeContactRoleList = new List<ContactRole>();
		excludeContactRoleList = new List<ContactRole>();
		for (Schema.PicklistEntry f : Contact.ZP_User_Role__c.getDescribe().getPicklistValues()) {
			includeContactRoleList.add(new ContactRole(false, f.getLabel()));
			excludeContactRoleList.add(new ContactRole(false, f.getLabel()));
		}

		selIncludeState = new List<selectOption>();
		selIncludeState.add(new selectOption('OR', 'Include Any (OR)'));
		selIncludeState.add(new selectOption('AND', 'Include All (AND)'));
		selIncludeState.add(new selectOption('Multiple', 'Multiple State'));
		includeCompanyStateList = new List<CompanyState>();
		for (Schema.PicklistEntry f : Account.States__c.getDescribe().getPicklistValues()) {
			if ('PLACEHOLDER' != f.getLabel()) {
				includeCompanyStateList.add(new CompanyState(false, f.getLabel()));
			}
		}
	}

	//This method populate "User Reported Industry" filter option.
	private void populateUserReportedIndustry() {
		selIndustry = new List<selectOption>();
		selIndustry.add(new selectOption('Include', 'Include'));
		selIndustry.add(new selectOption('Exclude', 'Exclude'));

		userReportedIndustryList = new List<UserReportedIndustry>();
		for (Schema.PicklistEntry f : Account.Industry.getDescribe().getPicklistValues()) {
			userReportedIndustryList.add(new UserReportedIndustry(false, f.getLabel()));
		}
	}

	//This method populate "Sold Through Partner" filter option.
	private void populateSoldThroughPartner() {
		selSoldThrough = new List<selectOption>();
		selSoldThrough.add(new selectOption('', '  --Any--'));
		selSoldThrough.add(new selectOption('Direct - Came to Gusto on their own', 'Direct - Came to Gusto on their own'));
		selSoldThrough.add(new selectOption('Partner - Came to Gusto through Accountant', 'Partner - Came to Gusto through Accountant'));
	}

	//This method populate "Tier" filter option.
	private void populateTier() {
		selTierList = new List<selectOption>();
		selTierList.add(new selectOption('', '  --Any--'));
		selTierList.addAll(UR_UtilityCtrl.getPickValues(new Account(), 'Tier__c'));
	}

	//This methoed will execute once we click search button.
	public PageReference SearchContactList() {
		sortbyFieldAPIName = '';
		PageReference pageRef = SearchContact();
		return pageRef;
	}

	//This methoed will execute once we click search button.
	public PageReference SearchContact() {
		try {
			isAccountantSelected = false;
			lstMainContactWrapper = new List<ContactWrapper>();
			boolean useSearchFilter = false;
			boolean isNumericValue = true;
			String searchParam = '';
			//Main Query
			string qryContact = '';
			string startContactQuery = 'select id,Email,Name,AccountId,Account.Name,Account.Number_of_Active_Employees__c,MailingCity, MailingState, Account.BillingCity, Account.BillingState, Current_Year_Incentive__c, ';
			startContactQuery =
				startContactQuery +
				' ZP_User_Role__c, ZP_User_Id__c,Account.Joined_Date_Panda__c,(Select Id, Comment__c,Blacklist__c,Reason__c,Incentive__c, Name,LastModifiedDate, Research_Participant_Status__c,';
			startContactQuery =
				startContactQuery + ' Research_Project_Master__r.Project_Status__c , Research_Project_Master__c,Research_Project_Master__r.Type_of_Research__c, Research_Project_Master__r.Name';
			startContactQuery = startContactQuery + ' From Research_Project_Details__r where Research_Project_Master__c!=:currentRecordId ';
			startContactQuery = startContactQuery + ' ), UR_Recent_Project_Completion_date__c from Contact where Email!=null and Name!=null ';

			if (objResearch.Include_Marketing_Optout__c == false) {
				//if this is checked(true) then condition will be removed else condition will be added
				qryContact = qryContact + ' and HasOptedOutOfEmail=false and Salesloft_Email_Opt_Out__c=false ';
			}

			qryContact =
				qryContact + ' and UXResearch_Opt_Out__c=false and UXResearch_Blacklist__c=false and UXResearch_Exclude_Domain__c=false and Is_UX_Active_Formula__c=true and Disable_Email__c=false ';
			qryContact = qryContact + ' and Account.ZP_Company_Approval_Status__c!=\'Rejected for Bank Errors\' and Account.ZP_Company_Approval_Status__c!=\'Rejected\'';
			string strComp = 'Complete';
			qryContact =
				qryContact +
				' and Id not in (select Contact__c from Research_Project_Detail__c where Research_Project_Master__c!=:currentRecordId and Research_Project_Master__r.Project_Status__c!=:strComp)';

			if (string.isNotBlank(strDaySinceCont)) {
				useSearchFilter = true;

				integer daySince = integer.valueof(strDaySinceCont);
				Date modifedDate = Date.today().addDays(-daySince);
				qryContact = qryContact + ' and ( UR_Recent_Project_Completion_date__c=null or  UR_Recent_Project_Completion_date__c <=: modifedDate ) ';
			}

			if (setSelectedContactId != null && setSelectedContactId.size() > 0) {
				qryContact = qryContact + ' and Id not in:setSelectedContactId';
			}

			if (searchAccount.AM_Tier__c != null) {
				useSearchFilter = true;
				string pTier = searchAccount.AM_Tier__c;
				qryContact = qryContact + ' and Account.AM_Tier__c=:pTier';
				searchParam = searchParam + 'Partner Tier : ' + pTier + '\n';
			}

			//Exclude all account contact which has any open cases
			if (excludeCompany == true) {
				qryContact = qryContact + ' and (Account.UR_No_Of_Open_Cases__c=0 or Account.UR_No_Of_Open_Cases__c=null)';
				searchParam = searchParam + 'Exclude Companies with Open Tickets : ' + excludeCompany + '\n';
			}

			if (string.isNotBlank(strName)) {
				useSearchFilter = true;
				qryContact = qryContact + UR_UtilityCtrl.createSearchString('String', strNameFilter, 'Name', strName.trim());
				searchParam = searchParam + 'Name : (' + strNameFilter + ') ' + strName + '\n';
			}

			if (string.isNotBlank(strCompanyName)) {
				useSearchFilter = true;
				qryContact = qryContact + UR_UtilityCtrl.createSearchString('String', strCompanyNameFilter, 'Account.Name', strCompanyName.trim());
				searchParam = searchParam + 'Account.Name : (' + strCompanyNameFilter + ') ' + strCompanyName + '\n';
			}

			if (String.isNotBlank(selIncludeStr)) {
				//include Role
				String roleStr = '';
				List<String> selectRoleList = processRole(includeContactRoleList);
				if (selectRoleList.size() > 0) {
					if (selIncludeStr == 'OR') {
						roleStr = ' Include Any (OR) : ';
						String subQuery = '';
						for (String str : selectRoleList) {
							roleStr = roleStr + str + '; ';
							if ('Secondary Admin' == str) {
								str = 'Payroll Admin';
							}
							subQuery = subQuery + 'or ZP_User_Role_Text__c like \'%' + str.trim() + '%\' ';
						}
						if (String.isNotBlank(subQuery)) {
							subQuery = subQuery.trim();
							subQuery = subQuery.subString(2, subQuery.length());
							qryContact = qryContact + ' and (' + subQuery + ') ';
						}
						if (String.isNotBlank(roleStr)) {
							roleStr = roleStr.trim();
							roleStr = roleStr.subString(0, roleStr.length() - 1);
						}
					} else if (selIncludeStr == 'AND') {
						String subQuery = '';
						roleStr = ' Include All (AND) : ';
						for (String str : selectRoleList) {
							roleStr = roleStr + str + '; ';
							if ('Secondary Admin' == str) {
								str = 'Payroll Admin';
							}
							subQuery = subQuery + 'and ZP_User_Role_Text__c like \'%' + str.trim() + '%\' ';
						}
						if (String.isNotBlank(subQuery)) {
							subQuery = subQuery.trim();
							subQuery = subQuery.subString(3, subQuery.length());

							qryContact = qryContact + ' and (' + subQuery + ') ';
						}
						if (String.isNotBlank(roleStr)) {
							roleStr = roleStr.trim();
							roleStr = roleStr.subString(0, roleStr.length() - 1);
						}
					}
					searchParam = searchParam + 'Roles to include : ' + roleStr + '\n';
				}
			}

			if (String.isNotBlank(selExcludeStr)) {
				//Exclude Role
				List<String> selectRoleList = processRole(excludeContactRoleList);
				String roleStr = '';
				if (selectRoleList.size() > 0) {
					if (String.isNotBlank(selExcludeStr)) {
						//if(selExcludeStr=='OR'){
						String subQuery = '';
						if (selExcludeStr == 'OR') {
							roleStr = ' Exclude Any (OR) : ';
						} else {
							roleStr = ' Exclude All (AND) : ';
						}
						for (String str : selectRoleList) {
							roleStr = roleStr + str + '; ';
							if ('Secondary Admin' == str) {
								str = 'Payroll Admin';
							}
							subQuery = subQuery + 'and (NOT ZP_User_Role_Text__c like \'%' + str.trim() + '%\') ';
						}
						if (String.isNotBlank(subQuery)) {
							subQuery = subQuery.trim();
							subQuery = subQuery.subString(3, subQuery.length());
							qryContact = qryContact + ' and ' + subQuery + ' ';
						}
						if (String.isNotBlank(roleStr)) {
							roleStr = roleStr.trim();
							roleStr = roleStr.subString(0, roleStr.length() - 1);
						}
					}
					searchParam = searchParam + 'Roles to exclude : ' + roleStr + '\n';
				}
			}

			if (string.isNotBlank(strCity)) {
				useSearchFilter = true;
				qryContact = qryContact + UR_UtilityCtrl.createSearchString('String', strCityFilter, 'Account.BillingCity', strCity.trim());
				searchParam = searchParam + 'City : (' + strCityFilter + ') ' + strCity + '\n';
			}
			if (string.isNotBlank(strState)) {
				useSearchFilter = true;
				qryContact = qryContact + ' and Account.BillingState =: strState ';
				searchParam = searchParam + 'State : ' + strState + '\n';
			}
			if (string.isNotBlank(strCaseNumber)) {
				useSearchFilter = true;
				List<String> strCaseNumberSet = strCaseNumber.split(',');
				Set<String> caseContactIdSet = new Set<String>();
				for (Case lstCase : [SELECT CaseNumber, ContactId FROM Case WHERE CaseNumber IN :strCaseNumberSet]) {
					if (lstCase.ContactId != null) {
						caseContactIdSet.add(lstCase.ContactId);
					}
				}
				if (caseContactIdSet != null && caseContactIdSet.size() > 0) {
					qryContact = qryContact + ' and Id IN : caseContactIdSet';
				}
				searchParam = searchParam + 'Care Ticket : ' + strCaseNumber + '\n';
			}

			if (searchAccount.Joined_Date_Panda__c != null) {
				useSearchFilter = true;
				Date dtFromJoined = searchAccount.Joined_Date_Panda__c;
				Date dtToJoined = searchAccount1.Joined_Date_Panda__c;
				qryContact = qryContact + UR_UtilityCtrl.createSearchString('Date', strJoinDateFilter, 'Account.Joined_Date_Panda__c', dtFromJoined, dtToJoined);
				searchParam = searchParam + 'First Payroll / Join date : (' + strJoinDateFilter + ') ' + dtFromJoined + ' - ' + dtToJoined + '\n';
			}
			if (searchAccount.First_Contractor_Payment_Date__c != null) {
				useSearchFilter = true;
				Date dtFromJoined = searchAccount.First_Contractor_Payment_Date__c;
				Date dtToJoined = searchAccount1.First_Contractor_Payment_Date__c;
				qryContact = qryContact + UR_UtilityCtrl.createSearchString('Date', strfirstConPaymentDateFilter, 'Account.First_Contractor_Payment_Date__c', dtFromJoined, dtToJoined);
				searchParam = searchParam + 'First Contractor Payment date : (' + strfirstConPaymentDateFilter + ') ' + dtFromJoined + ' - ' + dtToJoined + '\n';
			}
			if (String.isNotBlank(hasMedical)) {
				boolean hasMedicalDeductions = false;
				if (hasMedical == 'Yes') {
					hasMedicalDeductions = true;
				}
				qryContact = qryContact + ' and Account.Medical_Deductions__c=:hasMedicalDeductions';
				searchParam = searchParam + 'Has Medical deductions? : ' + hasMedical + '\n';
			}
			if (String.isNotBlank(hasActivePolicy)) {
				boolean hasPolicy = false;
				if (hasActivePolicy == 'Yes') {
					hasPolicy = true;
				}
				qryContact = qryContact + ' and Account.Has_Active_WC_Policy__c=:hasPolicy';
				searchParam = searchParam + 'Has Active WC Policy? : ' + hasActivePolicy + '\n';
			}

			if (String.isNotBlank(overAllCompanyStatus)) {
				useSearchFilter = true;
				qryContact = qryContact + ' and Account.ZP_Company_Overall_Status__c=:overAllCompanyStatus ';
				searchParam = searchParam + 'Overall Company Status : ' + overAllCompanyStatus + '\n';
			}

			if (isAccountantSelected == false) {
				// If isAccountant selected then we will search all the Account record.
				// Else we will search, the account records related to "Company" record-type only.
				useSearchFilter = true;
				qryContact = qryContact + ' and Account.RecordType.DeveloperName=\'Company\' ';
			}

			if (searchAccount.HI_Active_Benefits__c != null && searchAccount.HI_Active_Benefits__c == true) {
				useSearchFilter = true;
				boolean hasBenefits = searchAccount.HI_Active_Benefits__c;
				qryContact = qryContact + ' and Account.HI_Active_Benefits__c=:hasBenefits';
				searchParam = searchParam + 'Has Gusto HI : ' + searchAccount.HI_Active_Benefits__c + '\n';
			}

			if (string.isNotBlank(strNPSScore) || string.isNotBlank(strNPSScore1)) {
				isNumericValue = checkNumericOrBlankValue(strNPSScore, strNPSScore1);
				if (isNumericValue) {
					useSearchFilter = true;
					Decimal decNPSScore = 0;
					Decimal decNPSScore1 = 0;
					
					//Based on user id get contact detail from contact
					set<string> strUserid = new Set<string>();
					// set<string> strContactId=new Set<string>();
					qryContact = qryContact + ' and ZP_User_Id__c in :strUserid';
					searchParam = searchParam + '# NPS Score : ' + decNPSScore + ' - ' + strNPSScore1 + '\n';
				}
			}

			if (String.isNotBlank(searchTier)) {
				useSearchFilter = true;
				qryContact = qryContact + ' and Account.Tier__c=:searchTier';
				searchParam = searchParam + 'Company Tier : ' + searchTier + '\n';
			}

			if (String.isNotBlank(selIndustryStr)) {
				useSearchFilter = true;
				String subQuery = '';
				String industryStr = '';
				for (UserReportedIndustry industryObj : userReportedIndustryList) {
					if (industryObj.isChecked) {
						if ('Include' == selIndustryStr) {
							subQuery = subQuery + 'or Account.Industry = \'' + industryObj.industryName + '\' ';
						} else {
							subQuery = subQuery + ' and Account.Industry != \'' + industryObj.industryName + '\' ';
						}
						industryStr = industryStr + industryObj.industryName + '; ';
					}
				}
				if (string.isNotBlank(subQuery)) {
					subQuery = subQuery.trim();
					if ('Include' == selIndustryStr) {
						subQuery = subQuery.subString(2, subQuery.length());
						subQuery = ' and (' + subQuery + ') ';
						qryContact = qryContact + subQuery;
					} else {
						qryContact = qryContact + ' ' + subQuery;
					}
				}
				if (String.isNotBlank(industryStr)) {
					industryStr = industryStr.trim();
					industryStr = industryStr.subString(0, industryStr.length() - 1);
					searchParam = searchParam + 'User Reported Industry : (' + selIndustryStr + ') ' + industryStr + '\n';
				}
			}

			if (string.isNotBlank(activeEmployeeFrom) || string.isNotBlank(activeEmployeeTo)) {
				useSearchFilter = true;
				decimal minVal = 0;
				decimal maxVal = 1000;
				if (string.isNotBlank(activeEmployeeFrom)) {
					minVal = decimal.valueof(activeEmployeeFrom.trim());
				}
				if (string.isNotBlank(activeEmployeeTo)) {
					maxVal = decimal.valueof(activeEmployeeTo.trim());
				}
				qryContact = qryContact + ' and (Account.Number_of_Active_Employees__c>=' + minVal + ' and Account.Number_of_Active_Employees__c<=' + maxVal + ')';
				searchParam = searchParam + '# Active Employees : ' + activeEmployeeFrom + ' - ' + activeEmployeeTo + '\n';
			}

			if (string.isNotBlank(activeContractorFrom) || string.isNotBlank(activeContractorTo)) {
				useSearchFilter = true;
				decimal minVal = 0;
				decimal maxVal = 1000;
				if (string.isNotBlank(activeContractorFrom)) {
					minVal = decimal.valueof(activeContractorFrom.trim());
				}
				if (string.isNotBlank(activeContractorTo)) {
					maxVal = decimal.valueof(activeContractorTo.trim());
				}
				qryContact = qryContact + ' and (Account.Number_of_Active_Contractors__c>=' + minVal + ' and Account.Number_of_Active_Contractors__c<=' + maxVal + ')';
				searchParam = searchParam + '# Active Contractors : ' + activeContractorFrom + ' - ' + activeContractorTo + '\n';
			}

			if (string.isNotBlank(noClientFrom) || string.isNotBlank(noClientTo)) {
				useSearchFilter = true;
				decimal minVal = 0;
				decimal maxVal = 1000;
				if (string.isNotBlank(noClientFrom)) {
					minVal = decimal.valueof(noClientFrom.trim());
				}
				if (string.isNotBlank(noClientTo)) {
					maxVal = decimal.valueof(noClientTo.trim());
				}
				qryContact = qryContact + ' and (Account.No_Clients_Total__c>=' + minVal + ' and Account.No_Clients_Total__c<=' + maxVal + ')';
				searchParam = searchParam + 'If partner - number of clients (total) : ' + noClientFrom + ' - ' + noClientTo + '\n';
			}

			if (string.isNotBlank(searchSoldThrough)) {
				useSearchFilter = true;
				//get All Account where Sold_By__c has some value
				//if(searchSoldThrough == 'Direct - Came to Gusto on their own')
				//Changes on 8th May 2019 as discussed with Ashveej on 7th may
				if (searchSoldThrough == 'Partner - Came to Gusto through Accountant') {
					qryContact = qryContact + ' and Account.Sold_by_Account_Type__c = \'Reseller\'';
				}
				searchParam = searchParam + 'Sold through Partner : ' + searchSoldThrough + '\n';
			}
			if (string.isNotBlank(strEmail)) {
				useSearchFilter = true;
				String subQueryEmailFilter = '';
				for (String strEmail : strEmail.split(',')) {
					if (string.isNotBlank(strEmail)) {
						strEmail = '\'%' + strEmail.trim() + '%\'';
						subQueryEmailFilter = subQueryEmailFilter + 'or Email Like ' + strEmail + ' ';
					}
				}
				if (string.isNotBlank(subQueryEmailFilter)) {
					subQueryEmailFilter = subQueryEmailFilter.subString(2, subQueryEmailFilter.length());
					subQueryEmailFilter = ' and (' + subQueryEmailFilter + ') ';
					qryContact = qryContact + subQueryEmailFilter;
				}
				searchParam = searchParam + 'Email : ' + strEmail + '\n';
			}

			if (String.isNotBlank(selIncludeStateStr)) {
				//include Role
				String stateStr = '';
				List<String> selectStateList = processCompanyState(includeCompanyStateList);
				if (selectStateList.size() > 0) {
					if (selIncludeStateStr == 'OR') {
						stateStr = ' Include Any (OR) : ';
						String subQuery = '';
						for (String str : selectStateList) {
							stateStr = stateStr + str + '; ';
							subQuery = subQuery + '\'' + str.trim() + '\',';
						}
						if (String.isNotBlank(subQuery)) {
							subQuery = subQuery.trim();
							subQuery = subQuery.subString(0, subQuery.length() - 1);
							qryContact = qryContact + ' and  Account.States__c includes (' + subQuery + ') ';
						}
						if (String.isNotBlank(stateStr)) {
							stateStr = stateStr.trim();
							stateStr = stateStr.subString(0, stateStr.length() - 1);
						}
					} else if (selIncludeStateStr == 'AND') {
						String subQuery = '';
						stateStr = ' Include All (AND) : ';
						for (String str : selectStateList) {
							stateStr = stateStr + str + '; ';
							subQuery = subQuery + str.trim() + ';';
						}
						if (String.isNotBlank(subQuery)) {
							subQuery = subQuery.trim();
							subQuery = subQuery.subString(0, subQuery.length() - 1);

							qryContact = qryContact + ' and Account.States__c includes (\'' + subQuery + '\') ';
						}
						if (String.isNotBlank(stateStr)) {
							stateStr = stateStr.trim();
							stateStr = stateStr.subString(0, stateStr.length() - 1);
						}
					}
				}
				if (selIncludeStateStr == 'Multiple') {
					String subQuery = '';
					stateStr = 'Multiple State : ';
					qryContact = qryContact + ' and Account.Number_of_States__c > 1 ';
				}
				searchParam = searchParam + 'Company State to include : ' + stateStr + '\n';
			}

			if (useSearchFilter = false) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_UseFilters));
				return null;
			}

			String finalQueryString = startContactQuery;
			if (String.isBlank(sortbyFieldAPIName)) {
				//Randomize search result.
				String searchCountQuery = 'select count() from Contact where Email!=null and Name!=null ' + qryContact;
				Integer totalFilterContact = database.countQuery(searchCountQuery);
				Integer countContact = 0;
				if (totalFilterContact > 1000) {
					countContact = 1000;
				} else {
					countContact = totalFilterContact;
				}

				//Set offset filter
				if (totalFilterContact <= 500) {
					randomOffSet = 0; //If search result less then 500 then no need to set offset filter.
				} else {
					randomOffSet = Math.floor(Math.random() * countContact).intValue();
					//Reset offset filter. Because "search output record is less then 500" or "offset value not lies between [0-2000]"
					Integer checkMaxOffsetLimit = totalFilterContact - randomOffSet;
					if (checkMaxOffsetLimit < 500) {
						randomOffSet = totalFilterContact - 400 - Math.floor(Math.random() * 100).intValue();
					}
					if (randomOffSet < 0 || randomOffSet >= 2000) {
						randomOffSet = Math.floor(Math.random() * 100).intValue();
					}
				}

				//On the basis of offset, get "Orderby" operator value.
				sortbyFieldAPIName = orderByList.get(Math.mod(randomOffSet, orderByList.size()));
				String endContactQuery = ' order by ' + sortbyFieldAPIName + ' NULLS LAST';
				endContactQuery = endContactQuery + ' Limit 500 OFFSET ' + randomOffSet;
				finalQueryString = finalQueryString + qryContact + endContactQuery;
			} else {
				if (searchContactId.size() > 0) {
					finalQueryString = finalQueryString + qryContact + ' and Id IN : searchContactId order by ' + sortbyFieldAPIName + ' limit 500';
				} else {
					finalQueryString = finalQueryString + qryContact + ' order by ' + sortbyFieldAPIName + ' limit 500';
				}
			}

			if (Test.isRunningTest()) {
				finalQueryString = startContactQuery;
			}

			List<Contact> lstSearchContact = new List<Contact>();

			setSearchCon = new ApexPages.StandardSetController(Database.query(finalQueryString));
			setSearchCon.setPageSize(500); //set default page size.
			for (Contact conObj : (List<Contact>) setSearchCon.getRecords()) {
				lstSearchContact.add(conObj);
			}

			if (String.isNotBlank(searchParam)) {
				UR_UtilityCtrl.createUXRSearchingRecord(searchParam, objProject.Id, 'SFDC Search', lstSearchContact.size(), '');
			}

			Set<string> strUserId = new Set<string>();
			searchContactId = new Set<Id>();
			for (Contact ct : lstSearchContact) {
				searchContactId.add(ct.Id); //Maintain search contact list.
				if (string.isNotBlank(ct.ZP_User_Id__c)) {
					strUserId.add(ct.ZP_User_Id__c);
				}
			}
			totalSearchContact = searchContactId.size();

			//Reset search page size.
			setSearchCon.setPageSize(Integer.valueOf(selPageResultStr));
			lstSearchContact.clear();
			for (Contact conObj : (List<Contact>) setSearchCon.getRecords()) {
				lstSearchContact.add(conObj);
			}
			parseSearchContactList(lstSearchContact);
			lstSearchContact.clear();
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		isReserveBtnClick = false;
		return null;
	}

	public void parseSearchContactList(List<Contact> lstSearchContact) {
		lstMainContactWrapper = new List<ContactWrapper>();
		if (!lstSearchContact.isEmpty()) {
			for (Contact ct : lstSearchContact) {
				List<Research_Project_Detail__c> lstProjectdetail = ct.Research_Project_Details__r;
				integer noOfQuant = 0;
				integer noOfQual = 0;
				List<RelatedUXRProject> surveyDetails = new List<RelatedUXRProject>();
				List<RelatedUXRProject> studyDetails = new List<RelatedUXRProject>();
				//List<Research_Project_Detail__c> lstFiltered=new List<Research_Project_Detail__c>();
				//get six month before date
				DateTime SixMonthBefore = DateTime.Now().addMonths(-6);
				for (Research_Project_Detail__c rpd : lstProjectdetail) {
					if (rpd.Research_Project_Master__r.Type_of_Research__c != null && rpd.LastModifiedDate >= SixMonthBefore) {
						if (rpd.Research_Project_Master__r.Type_of_Research__c == UR_NewEditProjectCtrl.UNMODERATED_SURVEY) {
							noOfQual = noOfQual + 1;
							surveyDetails.add(new RelatedUXRProject(rpd.Research_Project_Master__r.Name, rpd.Research_Project_Master__c));
						} else {
							noOfQuant = noOfQuant + 1;
							studyDetails.add(new RelatedUXRProject(rpd.Research_Project_Master__r.Name, rpd.Research_Project_Master__c));
						}
					}
				}

				ContactWrapper cw = new ContactWrapper();
				cw.objCon = ct;
				cw.selContact = false;
				cw.noOfStudies = noOfQuant;
				cw.noOfSurveys = noOfQual;
				cw.noOfSurveyDetails = surveyDetails;
				cw.noOfStudyDetails = studyDetails;
				if (ct.Current_Year_Incentive__c == null) {
					cw.intCurrentYearIncentive = 0;
				} else {
					cw.intCurrentYearIncentive = Integer.valueOf(ct.Current_Year_Incentive__c);
				}
				cw.intNewIncentive = cw.intCurrentYearIncentive;
				if (objProject.Incentive_Amount__c != null) {
					cw.intNewIncentive = cw.intNewIncentive + Integer.valueOf(objProject.Incentive_Amount__c);
				}
				lstMainContactWrapper.add(cw);
				lstProjectdetail = new List<Research_Project_Detail__c>();
			}
		} else {
			if (isReserveBtnClick == false) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_ContactNotFound));
			}
		}

		if (lstSearchContact != null && lstSearchContact.size() > 0 && lstMainContactWrapper.size() == 0 && isReserveBtnClick == false) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_ContactNotFound));
		}
	}

	//Create common method to save data which we can caal from multi places
	private PageReference SaveParticipants() {
		decimal MaximumNumber = 0;
		decimal minimumNumber = 0;
		if (objResearch != null && objResearch.Max_Number_Of_Participants_High_Limit__c != null) {
			MaximumNumber = objResearch.Max_Number_Of_Participants_High_Limit__c;
		}
		if (objResearch != null && objResearch.Min_Number_Of_Participants_Low_Limit__c != null) {
			minimumNumber = objResearch.Min_Number_Of_Participants_Low_Limit__c;
		}
		//Update maximum value from project level
		if (objProject != null && objProject.Number_of_Allowed_Participant__c != null) {
			MaximumNumber = objProject.Number_of_Allowed_Participant__c;
		}

		List<Research_Project_Detail__c> lstProjectDetail = new List<Research_Project_Detail__c>();
		if (lstMainContactWrapper != null && lstMainContactWrapper.size() > 0) {
			for (ContactWrapper ctw : lstMainContactWrapper) {
				if (ctw.selContact == true) {
					Research_Project_Detail__c prd = new Research_Project_Detail__c();
					prd.Research_Project_Master__c = objProject.Id;
					prd.Comment__c = participantComments;
					prd.Contact__c = ctw.objCon.Id;
					prd.Research_Participant_Status__c = 'Reserved';
					prd.Added_by_CSV__c = false;
					lstProjectDetail.add(prd);
				}
			}
			integer totalNum = totalSelecedParticipant + lstProjectDetail.size();

			if (lstProjectDetail != null && lstProjectDetail.size() > 0) {
				//Check final added value of participant in from project configuration
				if (totalNum >= minimumNumber && totalNum <= MaximumNumber) {
					noOfParticipant = noOfParticipant + lstProjectDetail.size();
					insert lstProjectDetail;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Info, lstProjectDetail.size() + ' participants successfully added to your project!'));
				} else {
					participantComments = '';
					ApexPages.addmessage(
						new ApexPages.message(ApexPages.severity.Error, Label.UR_YouCanAddParticipant1 + ' ' + minimumNumber + ' to ' + MaximumNumber + ' ' + Label.UR_YouCanAddParticipant2)
					);
					return null;
				}
			} else {
				participantComments = '';
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_SelectContactforParticipant));
				return null;
			}
		}

		if (lstProjectDetail != null && lstProjectDetail.size() > 0) {
			populateSelectedparticipant(true);
			if (searchContactId.size() > 0) {
				SearchContact();
			}
		}
		return null;
	}
	// This method will execute once we click save & continue button on manage contact screen.
	public PageReference SaveContact() {
		try {
			//Update All Select participants comments
			if (lstSelectedContactWrapper != null && lstSelectedContactWrapper.size() > 0) {
				List<Research_Project_Detail__c> lstProjectDetail = new List<Research_Project_Detail__c>();
				for (ContactWrapper ctw : lstSelectedContactWrapper) {
					Research_Project_Detail__c prd = new Research_Project_Detail__c();
					prd.id = ctw.projectPartId;
					prd.Comment__c = ctw.strComment;
					lstProjectDetail.add(prd);
				}
				//Insert Project detail
				if (lstProjectDetail != null && lstProjectDetail.size() > 0) {
					update lstProjectDetail;
				}

				PageReference pageRef = new PageReference('/apex/UR_ManageParticipant?id=' + objProject.Id);
				return pageRef;
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}
		return null;
	}

	// This method will execute once we "reserve selected contact" as Participants.
	public PageReference AddContact() {
		isReserveBtnClick = true;
		return SaveParticipants();
	}

	//Remove Contact from selected Table
	public PageReference RemoveContact() {
		boolean selectedItem = false;
		if (lstSelectedContactWrapper != null) {
			List<ContactWrapper> lstTempWrapper = new List<ContactWrapper>();
			lstTempWrapper = lstSelectedContactWrapper;
			lstSelectedContactWrapper = new List<ContactWrapper>();
			set<string> projectDetailId = new Set<string>();

			for (ContactWrapper cw : lstTempWrapper) {
				//Ignore all contact which is selected from selcted tabled
				if (cw.selContact == false) {
					lstSelectedContactWrapper.add(cw);
				} else {
					selectedItem = true;
					setSelectedContactId.Remove(cw.objCon.id);
				}
				if (cw.selContact == true && cw.projectPartId != null) {
					projectDetailId.add(cw.projectPartId);
					selectedItem = true;
				}
			}

			if (projectDetailId != null && projectDetailId.size() > 0) {
				noOfParticipant = noOfParticipant - projectDetailId.size();
				delete [SELECT Id FROM Research_Project_Detail_Data_Info__c WHERE Research_Project_Detail__c IN :projectDetailId];
				delete [SELECT Id FROM Research_Project_Detail__c WHERE id IN :projectDetailId];
			}
			lstTempWrapper = new List<ContactWrapper>();
		}

		if (selectedItem == false) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_SelectParticipantToRemove));
			return null;
		} else {
			populateSelectedparticipant(true);
			if (searchContactId.size() > 0) {
				SearchContact();
			}
		}
		return null;
	}

	public void populateSelectedparticipant(Boolean isQueried) {
		lstSelectedContactWrapper.clear();
		Id projectId = objProject.id;
		if (isQueried) {
			setSelectedContactId.clear();
			totalSelecedParticipant = 0;
			List<Research_Project_Detail__c> tempProjectDetailList = [SELECT id, Contact__c FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId];
			for (Research_Project_Detail__c rpd : tempProjectDetailList) {
				setSelectedContactId.add(rpd.Contact__c);
				totalSelecedParticipant = totalSelecedParticipant + 1;
			}
			tempProjectDetailList.clear();

			String strQuery =
				'SELECT Id,Research_Project_Master__c,NDA_Send__c,Blacklist__c, ' +
				'Opt_Out__c,Reason__c,Incentive__c,Unread_Email__c, ' +
				'Project_Name__c,Project_Id__c,Screener_URL__c,Contact__c,' +
				'Contact__r.AccountId,Contact__r.Account.Name, Contact__r.Account.ZP_Company_ID__c, ' +
				'Contact__r.ZP_User_Id__c, Contact__r.Employee_Id__c,' +
				'Contact__r.Email,Contact__r.Name, Comment__c,' +
				'Research_Participant_Status__c, Researcher_Name__c, Calendly_URL__c, Company_Name__c, ' +
				'Date_of_Attended__c, Incentive_Amount__c, Length_of_Interview__c,  Locked__c, NDA_URL__c, ' +
				'Research_Participant_Status_Number__c, Study_End_Date__c, Study_Start_Date__c,Sort_Comment__c, ' +
				'Participant_Email__c FROM Research_Project_Detail__c where Research_Project_Master__c=:projectId ' +
				' order by ' +
				selSortbyFieldAPIName +
				' ' +
				selOrderAs +
				' NULLS LAST';

			setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strQuery));
			setCon.setPageSize(PAGE_SIZE);
		}

		for (Research_Project_Detail__c rpd : (List<Research_Project_Detail__c>) setCon.getRecords()) {
			ContactWrapper cw = new ContactWrapper();
			cw.objCon = new Contact(Id = rpd.Contact__c, AccountId = rpd.Contact__r.AccountId, Email = rpd.Contact__r.Email);
			cw.selContact = false;
			cw.chkDisabled = false;
			//In case of research
			if (rpd.Research_Participant_Status__c != null && rpd.Research_Participant_Status__c != 'Reserved') {
				cw.chkDisabled = true;
			}
			cw.strComment = rpd.Comment__c;
			cw.strPartStatus = rpd.Research_Participant_Status__c;
			cw.projectPartId = rpd.Id;
			cw.accountName = rpd.Company_Name__c;
			cw.contactName = rpd.Contact__r.Name;
			lstSelectedContactWrapper.add(cw);
		}
	}

	// This method will execute, once we click "Request approval for more" link.
	public PageReference SendApprovalRequest() {
		PageReference pageRef = null;
		try {
			if (string.isNotBlank(extraNOP)) {
				//get number of selected participant detail
				integer partCount = [SELECT COUNT() FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];
				integer exNop = integer.valueof(extraNOP);
				if (exNop <= 0) {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_ApprovalMsg));
					return null;
				}
				//Total number of participant
				exNop = integer.valueof(objProject.Number_of_Allowed_Participant__c) + exNop;
				if (exNop > partCount) {
					objProject.Number_of_Expected_Participant__c = integer.valueof(extraNOP);
					objProject.Additional_Participant_Status__c = 'In progress';
					update objProject;
					underApproval = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Approval request successfully submitted.'));
				}
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_NoOfParticipants));
				return null;
			}

			return pageRef;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}
	}

	public PageReference RedirectToUploadCSV() {
		PageReference pageRef = new PageReference('/apex/UR_UploadCSV?projectId=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	//This method called from back button
	public PageReference BackToManageContact() {
		PageReference pageRef = new PageReference(
			'/apex/UR_ManageContact?projectId=' +
			objProject.Id +
			'&orderas=' +
			orderAs +
			'&sortby=' +
			sortbyFieldAPIName +
			'&selorderas=' +
			selOrderAs +
			'&selsortby=' +
			selSortbyFieldAPIName
		);
		pageRef.setRedirect(true);
		return pageRef;
	}

	//This method called from back button
	public PageReference BackToProjectVF() {
		PageReference pageRef = null;
		Boolean isParticipantExist = UR_UtilityCtrl.participantExistInProject(objProject.Id);
		if (isParticipantExist) {
			pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + objProject.Id);
		} else {
			pageRef = new PageReference('/apex/UR_AddParticipants?projectId=' + objProject.Id);
		}
		pageRef.setRedirect(true);
		return pageRef;
	}

	//Wrapper class to show search contact on VF page.
	public class ContactWrapper {
		public Contact objCon { get; set; }
		public boolean selContact { get; set; }
		public integer noOfSurveys { get; set; }
		public integer noOfStudies { get; set; }
		public List<RelatedUXRProject> noOfSurveyDetails { get; set; }
		public List<RelatedUXRProject> noOfStudyDetails { get; set; }
		public string npsScore { get; set; }
		public string strComment { get; set; }
		public string strPartStatus { get; set; }
		public string projectPartId { get; set; }
		public boolean chkDisabled { get; set; }
		public string accountName { get; set; }
		public string contactName { get; set; }
		public integer intCurrentYearIncentive { get; set; }
		public integer intNewIncentive { get; set; }
	}

	public class RelatedUXRProject {
		public String Name { get; set; }
		public Id relProjectId { get; set; }
		public RelatedUXRProject(String Name, Id relProjectId) {
			this.Name = Name;
			this.relProjectId = relProjectId;
		}
	}
	//This method reset all serch filter.
	public void resetAll() {
		strName = '';
		strCompanyName = '';
		strCity = '';
		strState = '';
		strCaseNumber = '';
		searchAccount.Joined_Date_Panda__c = null;
		searchAccount1.Joined_Date_Panda__c = null;
		searchAccount.First_Contractor_Payment_Date__c = null;
		searchAccount1.First_Contractor_Payment_Date__c = null;
		searchAccount.HI_Active_Benefits__c = false;
		strNPSScore = '';
		strNPSScore1 = '';
		hasMedical = '';
		hasActivePolicy = '';
		activeEmployeeFrom = '';
		activeEmployeeTo = '';
		activeContractorFrom = '';
		activeContractorTo = '';
		noClientFrom = '';
		noClientTo = '';
		searchAccount.AM_Tier__c = '';
		searchAccount.Tier__c = '';
		searchSoldThrough = '';
		strEmail = '';
		searchTier = '';
		selIncludeStr = null;
		selExcludeStr = null;
		populateConactRole();
		populateUserReportedIndustry();
	}

	//Wrapper class, for "Contact Role" search filter.
	public class ContactRole {
		public boolean isChecked { get; set; }
		public String roleName { get; set; }
		public ContactRole(boolean isChecked, String roleName) {
			this.isChecked = isChecked;
			if ('Payroll Admin' == roleName) {
				this.roleName = 'Secondary Admin';
			} else {
				this.roleName = roleName;
			}
		}
	}

	//Wrapper class, for "Account/Company State" search filter.
	public class CompanyState {
		public boolean isChecked { get; set; }
		public String strStateName { get; set; }
		public CompanyState(boolean isChecked, String strStateName) {
			this.isChecked = isChecked;
			this.strStateName = strStateName;
		}
	}

	//Wrapper class, for "User Reported Industry" search filter.
	public class UserReportedIndustry {
		public boolean isChecked { get; set; }
		public String industryName { get; set; }
		public UserReportedIndustry(boolean isChecked, String industryName) {
			this.isChecked = isChecked;
			this.industryName = industryName;
		}
	}

	//Check if Accountant role has been selected or not
	public List<String> processRole(List<ContactRole> roleList) {
		List<String> selectRoleList = new List<String>();
		for (ContactRole roleObj : roleList) {
			if (roleObj.isChecked) {
				if (roleObj.roleName == 'Accountant') {
					isAccountantSelected = true;
				}
				selectRoleList.add(roleObj.roleName);
			}
		}
		return selectRoleList;
	}

	//Check if Accountant role has been selected or not
	public List<String> processCompanyState(List<CompanyState> stateList) {
		List<String> selectStateList = new List<String>();
		for (CompanyState stateObj : stateList) {
			if (stateObj.isChecked) {
				selectStateList.add(stateObj.strStateName);
			}
		}
		return selectStateList;
	}

	/** indicates whether there are more records after the current page set.*/
	public Boolean hasNext {
		get {
			return setCon.getHasNext();
		}
		set;
	}

	/** indicates whether there are more records before the current page set.*/
	public Boolean hasPrevious {
		get {
			return setCon.getHasPrevious();
		}
		set;
	}

	/** returns the page number of the current page set*/
	public Integer pageNumber {
		get {
			return setCon.getPageNumber();
		}
		set;
	}

	public Integer getTotalRecord() {
		Decimal totalSize = 0;
		if (setCon != null) {
			totalSize = setCon.getResultSize();
		}
		return (Integer) totalSize.round(System.RoundingMode.CEILING);
	}

	/** return total number of pages for page set*/
	public Integer getTotalPages() {
		Decimal totalSize = setCon.getResultSize();
		Decimal pageSize = setCon.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(System.RoundingMode.CEILING);
	}

	/** returns the first page of the page set*/
	public void first() {
		setCon.first();
		populateSelectedparticipant(false);
	}

	/** returns the last page of the page set*/
	public void last() {
		setCon.last();
		populateSelectedparticipant(false);
	}

	/** returns the previous page of the page set*/
	public void previous() {
		setCon.previous();
		populateSelectedparticipant(false);
	}

	/** returns the next page of the page set*/
	public void next() {
		setCon.next();
		populateSelectedparticipant(false);
	}

	/** indicates whether there are more records after the current page set.*/
	public Boolean hasSearchNext {
		get {
			return setSearchCon.getHasNext();
		}
		set;
	}

	/** indicates whether there are more records before the current page set.*/
	public Boolean hasSearchPrevious {
		get {
			return setSearchCon.getHasPrevious();
		}
		set;
	}

	/** returns the page number of the current page set*/
	public Integer searchPageNumber {
		get {
			return setSearchCon.getPageNumber();
		}
		set;
	}

	public Integer getSearchTotalRecord() {
		Decimal totalSize = 0;
		if (setSearchCon != null) {
			totalSize = setSearchCon.getResultSize();
		}
		return (Integer) totalSize.round(System.RoundingMode.CEILING);
	}

	/** return total number of pages for page set*/
	public Integer getSearchTotalPages() {
		Decimal totalSize = setSearchCon.getResultSize();
		Decimal pageSize = setSearchCon.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(System.RoundingMode.CEILING);
	}

	/** returns the first page of the page set*/
	public void firstSearch() {
		setSearchCon.first();
		resetSearchList();
	}

	/** returns the last page of the page set*/
	public void lastSearch() {
		setSearchCon.last();
		resetSearchList();
	}

	/** returns the previous page of the page set*/
	public void previousSearch() {
		setSearchCon.previous();
		resetSearchList();
	}

	/** returns the next page of the page set*/
	public void nextSearch() {
		setSearchCon.next();
		resetSearchList();
	}

	public void resetSearchList() {
		List<Contact> lstSearchContact = new List<Contact>();
		for (Contact conObj : (List<Contact>) setSearchCon.getRecords()) {
			lstSearchContact.add(conObj);
		}
		parseSearchContactList(lstSearchContact);
		lstSearchContact.clear();
	}

	public void sortSearchContactList() {
		setSortingFilter();
		prevSortbyFieldAPIName = sortbyFieldAPIName;
		sortbyFieldAPIName = sortbyFieldAPIName + ' ' + orderAs;
		if (lstMainContactWrapper.size() > 0) {
			SearchContact();
		}
	}

	public void setSortingFilter() {
		if (sortbyFieldAPIName != prevSortbyFieldAPIName) {
			orderAs = 'asc';
		} else {
			if ('asc' == orderAs) {
				orderAs = 'desc';
			} else {
				orderAs = 'asc';
			}
		}
	}

	public void selSortManageContactList() {
		selSetSortingFilter();
		selPrevSortbyFieldAPIName = selSortbyFieldAPIName;
		populateSelectedparticipant(true);
		if (lstMainContactWrapper.size() > 0) {
			SearchContactList();
		}
	}

	public void resetSearchContactList() {
		populateSelectedparticipant(true);
		if (lstMainContactWrapper.size() > 0) {
			SearchContact();
		}
	}

	public void selSetSortingFilter() {
		if (selSortbyFieldAPIName != selPrevSortbyFieldAPIName) {
			selOrderAs = 'asc';
		} else {
			if ('asc' == selOrderAs) {
				selOrderAs = 'desc';
			} else {
				selOrderAs = 'asc';
			}
		}
	}

	public boolean checkNumericOrBlankValue(String fromValue, String toValue) {
		boolean isNumericValue = true;
		if (string.isNotBlank(fromValue)) {
			if (fromValue.isNumeric()) {
				isNumericValue = true;
			} else {
				isNumericValue = false;
			}
		}

		if (isNumericValue == true && string.isNotBlank(toValue)) {
			if (toValue.isNumeric()) {
				isNumericValue = true;
			} else {
				isNumericValue = false;
			}
		}
		return isNumericValue;
	}
}