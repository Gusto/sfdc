public class opportunityNewExtension {
	public Opportunity oppRec { get; set; }
	public Boolean showEmployee { get; set; }
	public Boolean showFilingState { get; set; }
	public Boolean blnAccountRequired { get; set; }
	public Id idCustomerSuccessRecordType { get; set; }
	public Boolean blnIsTaxCreditRecordTypeOpp {
		get {
			return oppRec != null && (oppRec.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID);
		}
	}

	public static final string PRIMARY_PAYROLL_ADMIN = Label.Primary_Payroll_Admin;
	public static final string PAYROLL_ADMIN = Label.Payroll_Admin;
	public Boolean bol_isNewPlanORBor { get; set; } //Yuvraj : 17-06-2020
	public static final String CUSTOMER_SUCCESS_ROLES_GROUP_NAME = 'Customer Success Roles';
	public static final String ARDIUS_ROLES_GROUP_NAME = 'Ardius Roles';
	private Map<Id, Account> map_Accounts = new Map<Id, Account>();
	public static final String TAXCREDITS_TYPE_NEW_BUSINESS = 'New Business';
	public static final String TAXCREDITS_TYPE_PARTNERSHIP = 'Partnership';
	public static final String TAXCREDITS_PREFIX_RD = 'R&D';

	public opportunityNewExtension(ApexPages.StandardController sc) {
		oppRec = (Opportunity) sc.getRecord();
		showEmployee = false;
		showFilingState = false;
		bol_isNewPlanORBor = false;
		blnAccountRequired = false;
		string accId = apexPages.currentPage().getParameters().get('accid');
		idCustomerSuccessRecordType = Cache.getRecordTypeId('Opportunity', 'Customer Success');

		if (accId != null) {
			oppRec.AccountId = accId;
		}
		//Setting the Customer Success record type as default if user is Customer Success
		if (GlobalQueryHelper.getLoggedUserOrRoleGroupMember(CUSTOMER_SUCCESS_ROLES_GROUP_NAME)) {
			oppRec.RecordTypeId = idCustomerSuccessRecordType;
		}

		//Setting the Tax Credits record type as default if user is Ardius
		if (GlobalQueryHelper.getLoggedUserOrRoleGroupMember(ARDIUS_ROLES_GROUP_NAME)) {
			oppRec.RecordTypeId = OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID;
		}

		prepopulateUpsellOpportunity();
	}

	public void prepopulateUpsellOpportunity() {
		oppRec.Name = '';
		oppRec.CloseDate = null;

		if (
			oppRec.RecordTypeId == Cache.getRecordTypeId('Opportunity', 'Benefits BoR') ||
			oppRec.RecordTypeId == Cache.getRecordTypeId('Opportunity', 'Benefits New Plan') ||
			oppRec.RecordTypeId == Cache.getRecordTypeId('Opportunity', 'Benefits BYOB')
		) {
			oppRec.StageName = 'Raw';
			List<Account> accList = [SELECT Id, Name, Number_of_Active_Employees__c, BillingState FROM Account WHERE Id = :oppRec.AccountId];

			if (accList.size() > 0) {
				oppRec.NumberOfEmployees__c = accList.get(0).Number_of_Active_Employees__c;
			}

			//check if account billing state exists in HI Opportunity Assignment states
			Schema.DescribeFieldResult fieldResult = Opportunity.HI_Opportunity_Assignment_State__c.getDescribe();
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			Set<String> supportedStatesSet = new Set<String>();

			for (Schema.PicklistEntry pl : ple) {
				supportedStatesSet.add(pl.getValue());
			}

			if (accList.size() > 0 && supportedStatesSet.contains(accList.get(0).BillingState)) {
				oppRec.HI_Opportunity_Assignment_State__c = accList.get(0).BillingState;
			}

			String str_RecordTypeName = Cache.getRecordTypeName('Opportunity', oppRec.RecordTypeId);
			bol_isNewPlanORBor = true;
			if (accList.size() > 0) {
				oppRec.Name = accList.get(0).Name + ' - ' + str_RecordTypeName;
			}

			Integer numberOfDays = Date.daysInMonth(date.today().year(), date.today().month());
			Date lastDayOfMonth = Date.newInstance(date.today().year(), date.today().month(), numberOfDays);
			oppRec.CloseDate = lastDayOfMonth;
			showEmployee = true;
			showFilingState = true;
			showFilingState = true;
		} else {
			bol_isNewPlanORBor = false; //Yuvraj : 17-06-2020
			showEmployee = false;
			showFilingState = false;
		}

		string upsellRecTypeId = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
		if (oppRec.RecordTypeId == upsellRecTypeId) {
			list<Account> accList = [SELECT id, Name, Number_of_Active_Employees__c, tier__c, Sold_By__c FROM Account WHERE id = :oppRec.AccountId];

			if (accList != null) {
				oppRec.Name = accList.get(0).Name + ' Tier Upsell';
				oppRec.NumberOfEmployees__c = accList.get(0).Number_of_Active_Employees__c;
				oppRec.Current_tier__c = accList.get(0).tier__c;
				oppRec.Sold_By__c = accList.get(0).Sold_By__c;
			}

			oppRec.CloseDate = system.today().addDays(60);
			oppRec.Type = 'Tier Upsell';
			oppRec.StageName = 'Engaged';
			oppRec.Amount = 0.0;
			bol_isNewPlanORBor = false; //Yuvraj : 17-06-2020
		}

		// Handle Tax Credits Opportunity
		if (blnIsTaxCreditRecordTypeOpp) {
			//Default Tax year
			if (oppRec.Tax_Year__c == null) {
				oppRec.Tax_Year__c = String.ValueOf(calculateTaxYear(System.today()));
			}

			//Calculate Tax Credits Opp Name
			oppRec.Name = getTaxCreditsOpportunityName();

			//Calculate Close Date
			Date dtToday = System.today();
			Integer intNumberOfDays = Date.daysInMonth(dtToday.year(), dtToday.month());
			Date dtLastDayOfMonth = Date.newInstance(dtToday.year(), dtToday.month(), intNumberOfDays);

			oppRec.CloseDate = dtLastDayOfMonth;
		}
	}

	public pageReference saveRec() {
		Set<String> npRestricEEroles = new Set<String>();

		string upsellRecTypeId = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
		if (oppRec.RecordTypeId == upsellRecTypeId) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, 'Upsell Tier is required when creating a Cross-Sell and Upsell Opportunity.'));
			return null;
			
		}

		// If its an Ardius Opportunity and have an Invalid Tax year value, then show an error message & block the Save operation
		if (blnIsTaxCreditRecordTypeOpp && !validateTaxYear(oppRec.Tax_Year__c)) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, 'Invalid Tax Year, Please enter a valid year value.'));
			return null;
		}

		try {
			insert oppRec;
			createContactRoles(oppRec.Id);
		} catch (exception ex) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, 'Error occurred while creating the record.' + ex.getMessage()));
			return null;
		}

		return new pageReference('/' + oppRec.id);
	}

	/**
	 * @description Calculate Tax Credits Opp name from Account & Type & Tax year values
	 *
	 * @return      `String` format: [Account Name] - R&D [Type] [Tax Year]
	 */
	private String getTaxCreditsOpportunityName() {
		if (oppRec.AccountId == null) {
			return '';
		}
		String type = String.isBlank(oppRec.Type) ? '' : oppRec.Type;
		String oppName = '';
		Account objAccount = getAccount(oppRec.AccountId);
		switch on oppRec.Type {
			when 'Existing Business' {
				oppName = objAccount?.Name + ' ' + '-' + ' ' + 'R&D Existing Business ' + oppRec.Tax_Year__c;
			}
			when 'Expansion' {
				oppName = objAccount?.Name + ' ' + '-' + ' ' + 'R&D Expansion ' + oppRec.Tax_Year__c;
			}
			when 'New Business' {
				oppName = objAccount?.Name + ' ' + '-' + ' ' + TAXCREDITS_PREFIX_RD + ' ' + TAXCREDITS_TYPE_NEW_BUSINESS + ' ' + oppRec.Tax_Year__c;
			}
			when 'Partnership' {
				oppName = objAccount?.Name + ' ' + '-' + ' ' + TAXCREDITS_PREFIX_RD + ' ' + TAXCREDITS_TYPE_PARTNERSHIP + ' ' + oppRec.Tax_Year__c;
			}
			when else {
				oppName = objAccount?.Name + ' ' + '-' + ' ' + 'R&D ' + type;
			}
		}
		return oppName;
	}

	/**
	 * @description       Query, backup and return Account requested.
	 *
	 * @param idAccountId Account Id
	 * @return            `Account`
	 */
	private Account getAccount(Id idAccountId) {
		Account objAccount = map_Accounts.get(idAccountId);
		if (objAccount != null) {
			return objAccount;
		}

		map_Accounts.putAll([SELECT Id, Name FROM Account WHERE Id = :idAccountId]);
		return map_Accounts.get(idAccountId);
	}

	/**
	 * @description      Validates Tax year
	 *
	 * @param strTaxYear Tax year value in String type
	 * @return           `Boolean`
	 */
	@TestVisible
	public static Boolean validateTaxYear(String strTaxYear) {
		if (String.isNotBlank(strTaxYear)) {
			try {
				Integer intTaxYear = Integer.valueOf(strTaxYear);
				return intTaxYear >= 2000 && intTaxYear <= 9999;
			} catch (Exception ex) {
				return false;
			}
		}
		return false;
	}

	/**
	 * @description Populate Tax Year based on current date
	 * @author      Jayesh Gawande
	 * @return      Method to calculate the tax year based on the current date.
	 */
	@TestVisible
	public static Integer calculateTaxYear(Date dtTodaysDate) {
		Date dtCurrentDate = dtTodaysDate;
		Integer intCurrentYear = dtCurrentDate.year();

		// Value from Custom Label with format : Month <> Day :- Opportunity_Tax_Year_Calulation.
		String strOppTaxYearCustomLabel = System.Label.Opportunity_Tax_Year_Calulation;

		List<String> list_SplitCustomLabel = strOppTaxYearCustomLabel.split('<>');

		// Retrieve the custom label values for month and day
		Integer intMonthForCheckingTaxYear = Integer.ValueOf(list_SplitCustomLabel[0]);
		Integer intDayForCheckingTaxYear = Integer.ValueOf(list_SplitCustomLabel[1]);

		// Check if the current date is before Custom Label Date
		if (dtCurrentDate.month() < intMonthForCheckingTaxYear || (dtCurrentDate.month() == intMonthForCheckingTaxYear && dtCurrentDate.day() < intDayForCheckingTaxYear)) {
			return intCurrentYear - 1;
		} else {
			return intCurrentYear;
		}
	}

	/**
	 * @Description : Create Opportunity Contact Roles if they have not been created by opportunity trigger
	 * @Param        : idRecord - Opportunity Id record
	 **/
	public static void createContactRoles(Id idRecord) {
		// Create Contact Roles
		// map_ContactRolesToIgnore - list of contact roles to ignore if they have already been created by trigger
		Map<Id, List<String>> map_ContactRolesToIgnore = new Map<Id, List<String>>();
		List<OpportunityContactRole> list_ContactRolesToInsert = new List<OpportunityContactRole>();
		Opportunity objOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE Id = :idRecord];

		// Query existing contact roles from opportunity
		for (OpportunityContactRole objContactRole : [SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :objOpportunity.Id]) {
			List<String> list_Roles = new List<String>();

			if (map_ContactRolesToIgnore.containsKey(objContactRole.ContactId)) {
				list_Roles = map_ContactRolesToIgnore.get(objContactRole.ContactId);
			}
			// Map of existing contact Id & list fo roles
			list_Roles.add(objContactRole.Role);
			map_ContactRolesToIgnore.put(objContactRole.ContactId, list_Roles);
		}
		// Query from Metadata list of allowed roles to create
		Set<string> set_AllowedRoles = Utils.getRolesSet('Company', 'OpportunityNewExtension');
		// Qyer
		for (ZP_User_Role__c objUserRole : [
			SELECT Company_Account__c, Accounting_Firm_Account__c, Contact__c, Type__c, Deleted_At__c, Is_Primary__c, Role_Name__c
			FROM ZP_User_Role__c
			WHERE
				(Company_Account__c = :objOpportunity.AccountId
				OR Accounting_Firm_Account__c = :objOpportunity.AccountId)
				AND Role_Name__c IN :set_AllowedRoles
				AND Contact__c != NULL
				AND Deleted_At__c = NULL
		]) {
			Set<String> set_ContactIdPayrollAdmin = new Set<String>();
			Set<String> set_setContactIdPrimaryPayrollAdmi = new Set<String>();
			OpportunityContactRole objContactRole = new OpportunityContactRole();
			//Do not create contact role if contact with this role is already created
			if (!(map_ContactRolesToIgnore.containsKey(objUserRole.Contact__c) && map_ContactRolesToIgnore.get(objUserRole.Contact__c).contains(objUserRole.Role_Name__c))) {
				if (objUserRole.Role_Name__c == PAYROLL_ADMIN && !set_ContactIdPayrollAdmin.contains(objUserRole.Contact__c + 'PayrollAdmin')) {
					objContactRole = new OpportunityContactRole();
					objContactRole.OpportunityId = objOpportunity.Id;
					objContactRole.ContactId = objUserRole.Contact__c;
					objContactRole.Role = PAYROLL_ADMIN;
					list_ContactRolesToInsert.add(objContactRole);
					set_ContactIdPayrollAdmin.add(objUserRole.Contact__c + 'PayrollAdmin');
				}

				if (objUserRole.Role_Name__c == PRIMARY_PAYROLL_ADMIN && !set_setContactIdPrimaryPayrollAdmi.contains(objUserRole.Contact__c + 'PrimaryPayrollAdmin')) {
					// to avoid duplicate
					objContactRole = new OpportunityContactRole();
					objContactRole.OpportunityId = objOpportunity.Id;
					objContactRole.ContactId = objUserRole.Contact__c;
					objContactRole.Role = PRIMARY_PAYROLL_ADMIN;
					list_ContactRolesToInsert.add(objContactRole);
					set_setContactIdPrimaryPayrollAdmi.add(objUserRole.Contact__c + 'PrimaryPayrollAdmin');
				}
			}
		}
		if (list_ContactRolesToInsert != null && list_ContactRolesToInsert.size() > 0) {
			insert list_ContactRolesToInsert;
		}
	}
}