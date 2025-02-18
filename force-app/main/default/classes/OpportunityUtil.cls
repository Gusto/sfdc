/**
 *  @author Sourav Mitra
 *  @since 10/06/2020
 *  @description Opportunity related Utilities for reuse
 */
public without sharing class OpportunityUtil {
	public static final String FIELD_SOURCE_ID = 'Source_ID__c';
	public static final String FIELD_ID = 'Id__c';
	public static final String ACCIDENTAL_DIRECT_SIGN_UP = 'Accidental Direct Sign up';
	public static final String PARTNER_HOUSE_ACCOUNT = 'Partner House Account';

	// Stage Names
	public final static String SAL_STAGE = 'SAL';
	public final static String MQL_STAGE = 'MQL';
	public final static String DEFAULT_HI_SALES_STAGE = 'Raw';
	public final static String ALIGNMENT_SALES_STAGE = 'Alignment In Progress';
	public static final String ALIGNMENT_COMPLETE_STAGE = 'Alignment Complete';
	public static final String OPP_READY_FOR_DEFAULT_STAGE = 'Ready for Default';
	public static final String ALIGNMENT_IN_PROGESS_PC_STAGE = 'Alignment In Progress (PC)';
	public final static String PENDING_PR_STAGE = 'Pending PR';
	public final static String CLOSED_WON_STAGE = 'Closed Won';
	public final static String ONBOARDING_COMPLETED_STAGE = 'Onboarding Completed';
	public final static String CLOSED_LOST_STAGE = 'Closed Lost';
	public final static String CLOSED_ADMIN_STAGE = 'Closed Admin';
	public final static String ORDER_LOST_STAGE = 'Order Lost';
	public final static String ER_CONFIRM_STAGE = 'ER Confirm';
	public final static String RECOMMENDATION_SENT_STAGE = 'Recommendation Sent';
	public final static String ENGAGED_STAGE = 'Engaged';
	public static final String BLOCKED_STAGE = 'Blocked';
	public static final String READY_FOR_DEFAULT_STAGE = 'Ready for Default Package';
	public static final String QUALIFIED_STAGE = 'Qualified';
	public static final String NEW_STAGE = 'New';
	public static final String COMMIT_STAGE = 'Commit';
	public static final String DISCOVERY_CALL_SCHEDULED_STAGE = 'Discovery Call Scheduled';
	// Stage Detail Name
	public static final String TIMING_STAGE = 'Timing';
	public static final String PRICE_STAGE = 'Price';
	public static final String PAYMENT_PLAN_OPTIONS_STAGE = 'Payment plan options';
	public static final String FUTURE_OPPORTUNITY = 'Future Opportunity';

	// Lead Source Values
	public static final String INSURANCE_QUOTE = 'Insurance Quote';
	public static final String CLIENT_BDO = 'Client BDO';
	public static final String EMPLOYER_BDO = 'Employer BDO';

	//Benefit Current Step field values
	public static final String FORMSSIGNED_BENEFITSCURRENTSTEP = 'Forms Signed';
	public static final String COMPLETED_BENEFITSCURRENTSTEP = 'Completed';
	public static final String COMPLETE_BENEFITSCURRENTSTEP = 'Complete';
	public static final String VERIFYINGELIGIBILITY_BENEFITSCURRENTSTEP = 'Verifying Eligibility';
	public static final String LEVEL_FUNDED_TYPE = 'Level funded';
	public static final String LEVEL_FUNDED_BOR = 'Level-funded BOR';
	public static final String FULLY_FUNDED_TYPE = 'Fully funded';
	public static final String FULLY_INSURED_TYPE = 'Fully Insured';

	public final static Integer DEFAULT_CLOSEDAYS = 30;
	public final static Integer BIZDEV_CLOSEDAYS = 80;
	public final static Integer QUALIFY_PROBABILITY = 40;
	public final static Integer COMMIT_PROBABILITY = 90;

	public static final String MSG_COVERAGE_EFFECTIVE_DATE_IS_MISSING = 'ERROR: Coverage Effective Date is Missing';
	public static final String MSG_UW_STATE_PY_IS_MISSING = 'ERROR: UW State previous year is Missing';
	public static final String MSG_USERS_CAPACITY_IS_FULL = 'ERROR: All eligible users at capacity';
	public static final String MSG_ASSIGNEMENT_PROCESSED_AS_PER_SKILLS = 'SUCCESS: Advising Assignment Processed as per Skills';
	public static final String MSG_BIGDESK_OPP_ASSIGNED_TO_NON_BIGDESK_USER = 'SUCCESS: BigDesk Opportunity Assigned to non BigDesk Advising User';
	public static final String MSG_NO_ADVISING_ASSIGNMENT_USER_ELIGIBLE = 'Error: No Advisor with matching skills found';
	public static final String BIG_DESK_ADVISOR_ASSIGNMENT = 'Big Desk (25+ EEs)';
	public final static String DISMISSED_SETUP_STEP = 'Dismissed';
	public final static String DISMISSED_STAGE_DETAIL = 'Benefit Application Dismissed';
	public final static String UNQUALIFIED_STAGE_DETAIL = '[Unqualified] Suspended or not a Gusto PR Customer';
	public final static String QSEHRA_STAGE_DETAIL = '[Unqualified] Suspended or not a Gusto PR Customer';

	// Lead Sources
	public final static String ADDED_BY_ACCOUNTANT = 'Added by Accountant';
	public final static String ADDED_BY_CLIENT = 'Added by Client';
	public final static String APP_GENERATED = 'App-Generated';
	public final static String MANUAL = 'Manual';
	public final static String BOR_LOST_REASON = 'BoR Lost Reason';
	public final static String BENEFITS_BYOB_STAGE_DETAIL = 'Unworkable Opportunity';
	public final static String BENEFITS_BYOB_STAGE_DETAIL2 = 'bring your own broker';

	//Additional Reasons Lost
	public final static String ADDITIONAL_REASONS_LOST_DUPLICATE_TEST_ACCOUNT = 'Duplicate or Test Account';

	//Touch Type
	public final static String HI_BAT_CREATION = 'HI BAT Creation';
	public final static String HI_EBBP_CREATION = 'HI EBBP Creation';

	// Products
	public final static String COMPANY_PROD = 'Company';
	public final static String ACTIVE_EMPLOYEE_PROD = 'Active Employee';
	public final static String CONTRACTOR_PROD = 'Contractor';
	public final static String PRIORITY_SUPPORT = 'Priority Support and HR Services';
	public final static String PRIORITY_SUPPORT_EMPLOYEE = Tier_Config__c.getOrgDefaults() != null
		? Tier_Config__c.getOrgDefaults().Priority_Support_Employee_Line_Item__c
		: 'Priority Support and HR Services - Employee';
	public final static String PRIORITY_SUPPORT_CONTRACTOR = Tier_Config__c.getOrgDefaults() != null
		? Tier_Config__c.getOrgDefaults().Priority_Support_Contractor_Line_Item__c
		: 'Priority Support and HR Services - Contractor';
	public final static String BENEFITS_DEFAULT_PROD = Label.Benefits_Default_Prod;

	// Product Types
	public final static String PRODUCT_TYPE_MONTHLY = 'Monthly';
	public final static String PRODUCT_TYPE_EMPLOYEES = 'Employees';
	public final static String PRODUCT_TYPE_CONTRACTORS = 'Contractors';
	public final static String PRODUCT_TYPE_INTERNATIONAL_CONTRACTORS = 'International Contractors';
	public final static String PRODUCT_TYPE_INTERNATIONAL_EMPLOYESS = 'International Employees';

	// Product Category
	public final static String PRODUCT_CATEGORY_PAYROLL = 'Payroll';
	public final static String TIER_UPSELL_OPPORTUNITY_RT_NAME = 'Tier_Upsell_Opportunity';

	// RecordTypes
	public final static Id COMPANY_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
	public final static Id TIER_UPSELL_OPPTY_RT_ID = Cache.getRecordTypeIdFromDeveloperName('Opportunity', TIER_UPSELL_OPPORTUNITY_RT_NAME);
	public final static Id BENEFITS_NEW_PLAN_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
	public final static Id BENEFITS_BOR_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');
	public final static Id BENEFITS_CHANGE_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits Change');
	public final static Id BENEFITS_RENEWAL_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
	public final static Id BIZDEV_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'BizDev Opportunity');
	public final static Id CUSTOMER_SUCCESS_RT_ID = Cache.getRecordTypeId('Opportunity', 'Customer Success');
	public final static Id BENEFITS_BYOB_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Benefits BYOB');
	public final static Id R_D_TAX_CREDITS_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Tax Credits');
	public final static Id EMBEDDED_COMPANY_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Embedded Company Opportunity');
	public final static Id GROWTH_EXPANSION_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Growth/Expansion');
	public final static Id ACQUISITION_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Acquisition');
	public final static Set<Id> set_BenefitRTChangeEmployees = new Set<Id>{ BENEFITS_NEW_PLAN_OPPTY_RT_ID, BENEFITS_BOR_OPPTY_RT_ID, BENEFITS_BYOB_OPPTY_RT_ID };
	public final static Set<Id> set_BenefitRTUpdateStage = new Set<Id>{ BENEFITS_NEW_PLAN_OPPTY_RT_ID, BENEFITS_RENEWAL_OPPTY_RT_ID, BENEFITS_CHANGE_OPPTY_RT_ID };
	public final static Set<Id> set_ArdiusRecordTypeIds = new Set<Id>{ R_D_TAX_CREDITS_OPPTY_RT_ID };
	public final static Set<Id> set_ArdiusExtendedRecordTypeIds = new Set<Id>{
		R_D_TAX_CREDITS_OPPTY_RT_ID
	};

	public final static Set<Id> set_NewPlanRenewalBenefitRT = new Set<Id>{ BENEFITS_NEW_PLAN_OPPTY_RT_ID, BENEFITS_RENEWAL_OPPTY_RT_ID };
	// To Be Moved
	public final static String HIPPO_ORIGIN = 'Hippo';
	public final static Id BENEFITS_CHANGE_CASE_RT_ID = Cache.getRecordTypeId('Case', 'Benefits Change Case');
	public final static Id BENEFITS_RENEWAL_CASE_RT_ID = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
	public final static Id BENEFITS_NEWPLAN_CASE_RT_ID = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
	public final static Id BENEFITS_BOR_CASE_RT_ID = Cache.getRecordTypeId('Case', 'Benefits BoR');
	public final static String INELIGIBLE_SAL_GREETERS_PLAYMODE = 'Ineligible for SAL Greeters Call 1';
	public final static String HOLD_OUT = 'Held Out';

	// Role
	public final static String MANAGER_ROLE = 'mgr';
	public final static String SALES_PARTNER_MGR = 'sales_partner_xx_xx_mgr';
	public final static String ZP_SYS_ADMIN_PROFILE = 'ZP System Administrator';
	public static final String HI_SALES_CS_ROLES = System.Label.SmallBusiness_RoleName;

	public static final String HI_LEAD_PASS_STAGES = System.Label.HI_Lead_Pass_Stages;

	public final static String PENDING_RECERT = 'Pending recert';

	public final static String strLoggedInUserLoginName = UserInfo.getUserName();
	public final static String strWorkatoIntegrationUserName = 'workato.integration@gusto.com';
	//Outbound PRE Result
	public final static String OUTBOUND_PRE_COMPLETE = 'Complete';

	//Ardius Contract Types
	public final static String ARD_AUTO_RENEWAL = 'Auto-Renewal';
	public final static String ARD_MULTI_YEAR = 'Multi Year';

	//Custom setting values
	public static final Boolean SKIP_BIG_DESK_ASSIGNMENT = Configuration_Settings__c.getOrgDefaults().Skip_BigDesk_Assignment__c;

	// Specific lead source Referred Accounts
	private static Boolean didBenchQuery = false;

	public final static Integer MMPR_EE_SIZE = 25;
	public final static Integer MMPR_SET_UP_STEPS = 80;

	public final static String PARTNER_ROLE = 'partner';

	// Slack notifications
	public final static String SLACK_NOTIFY_PARTNER = 'Partner';
	public final static String SLACK_NOTIFY_MDR = 'MDR';

	public final static String CHOICE_YES = 'Yes';
	public static final String ADD_SERVICES_PRIORITY_SUPPORT = 'Priority Support and HR Services';
	public static final String ADD_SERVICES_INTERNATIONAL_CONTRACTOR = 'International Contractor Service';
	public static final String INTERNATIONAL_CONTRACTOR_ADD_ON_PRODUCT = 'International Contractor Add-On';

	public static final String INTERNATIONAL_CONTRACTOR_PAYMENT = 'International Contractor Payment';
	// Dedicated CSM and Core CSM Role Ids
	public static final Set<Id> CSM_ROLE_IDS = new Set<Id>{ '00E8Y000001nusnUAA', '00E8Y000001nussUAA' };

	//Opportunity Split Type
	public final static String SPLIT_TYPE_REVENUE = 'Revenue';

	// Opportunity Types
	public final static String OPPTY_TYPE_RENEWAL_BYB = 'Renewal BYB';
	public final static String OPPTY_TYPE_EXISTING_BUSINESS = 'Existing Business';

	//Gusto Global
	public final static String TIER_UPSELL = 'Tier Upsell';
	public final static String INTERNATIONAL_PAYROLL_AND_TIER_UPSELL = 'Employer of Record and Tier Upsell';
	public static final String ACCOUNT_TIER_PREMIUM = 'Premium';
	public final static String UPSELL_TIER_INTERNATIONNAL_PAYROLL = 'Employer of Record';
	public final static String TYPE_UPSELL_CROSS_SELL = 'Upsell/Cross-Sell';

	//Pricebook types
	public final static String PRICE_BOOK_RD_PREMIUM = 'R&D Tax Credits - Gusto Premium Order Form';
	public final static String PRICE_BOOK_RD_STANDARD = 'R&D Tax Credits - Gusto Standard';

	// Opportunity types
	public final static String OPPTY_TYPE_NEW_BUSINESS = 'New Business';

	public static Boolean blnIsLoggedInUserWorkatoIntUser() {
		return (strLoggedInUserLoginName.startsWith(strWorkatoIntegrationUserName));
	}

	/**
	 * @description Memoize the recordId for a top reseller account to remove need for hardcoding custom label
	 * @author David Schach
	 * @return   Bench Account Id
	 */
	public static Id benchAccountId {
		get {
			if (benchAccountId == null && !didBenchQuery) {
				List<Account> benchList = [SELECT Id, Name FROM Account WHERE RecordTypeId = :RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Reseller') AND Name = 'Bench'];
				if (!benchList.isEmpty()) {
					benchAccountId = benchList[0].Id;
				}
			}
			return benchAccountId;
		}
		private set;
	}

	private static Boolean didClarusQuery = false;
	/**
	 * @description Memoize the recordId for a top reseller account to remove need for hardcoding custom label
	 * @author David Schach
	 * @return   Clarus Account Id
	 */
	public static Id clarusAccountId {
		get {
			if (clarusAccountId == null && !didClarusQuery) {
				List<Account> clarusList = [SELECT Id, Name FROM Account WHERE RecordTypeId = :RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Reseller') AND Name = 'Clarus'];
				if (!clarusList.isEmpty()) {
					clarusAccountId = clarusList[0].Id;
				}
			}
			return clarusAccountId;
		}
		private set;
	}

	public final static Set<String> set_ClosedOpportunityStage = new Set<String>{ CLOSED_WON_STAGE, CLOSED_LOST_STAGE, CLOSED_ADMIN_STAGE, ORDER_LOST_STAGE };

	public final static Set<String> set_HIOpportunityStageForLeadPass = new Set<String>{ QUALIFIED_STAGE, COMMIT_STAGE, ER_CONFIRM_STAGE, PENDING_PR_STAGE, CLOSED_WON_STAGE };

	public final static Map<String, List<String>> map_OpptyRTToDefaultValues = new Map<String, List<String>>{
		OpportunityUtil.COMPANY_OPPTY_RT_ID => new List<String>{ 'Direct Payroll', 'Partner Payroll', 'Payroll' },
		OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID => new List<String>{ 'Direct BOR', '', 'Benefits BoR' },
		OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID => new List<String>{ 'Direct New Plan', '', 'Benefits New Plan' },
		OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID => new List<String>{ 'Direct Renewal', '', 'Benefits Renewal' },
		OpportunityUtil.BIZDEV_OPPTY_RT_ID => new List<String>{ 'Business Development', '', 'BizDev' },
		OpportunityUtil.CUSTOMER_SUCCESS_RT_ID => new List<String>{ 'Customer Success', '', 'Customer Success' },
		OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID => new List<String>{ 'Direct BYB', '', 'Benefits BYB' },
		OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID => new List<String>{ 'Benefits Change', '', 'Benefits Change' },
		OpportunityUtil.BIZDEV_OPPTY_RT_ID => new List<String>{ 'BizDev Opportunity', '', 'BizDev Opportunity' },
		OpportunityUtil.EMBEDDED_COMPANY_OPPTY_RT_ID => new List<String>{ 'Embedded Company', '', 'Embedded Company' }
	};

	public final static Map<String, String> map_StageSandlerMapping = new Map<String, String>{
		'MQL' => 'Bonding & Rapport',
		'Attempting Contact' => 'Bonding & Rapport',
		'Engaged' => 'Bonding & Rapport',
		'Discovery Call Scheduled' => 'Bonding & Rapport',
		'SAL' => 'Upfront Contract',
		'Discovery' => 'Upfront Contract',
		'Qualified' => 'Pain Step',
		'Commit' => 'Budget & Decision',
		'Pending PR' => 'Budget & Decision',
		'Closed Won' => 'Fulfillment',
		'Closed Lost' => 'Fulfillment'
	};

	private static Map<String, PriceBook2> map_PricebookName;
	private static Map<Id, PriceBook2> map_PricebookId;

	//By AKS Dated 5th Jan 2021
	private static List<Region_Setting__mdt> list_RegionSettings;
	private static Map<String, String> map_StateNameAbbreviations;
	private static Map<String, Id> map_SplitTypeId;
	public static final String STATE_CALIFORNIA = 'California';
	private static Map<Integer, Advising_Email_Automation_Follow_Up__mdt> map_AdvisingEmailAutomationFollowUp;
	public static final String CANCELLED_STAGE = 'Cancelled';
	public static Set<String> set_OppCloseStageName = new Set<String>{ CLOSED_LOST_STAGE, CANCELLED_STAGE, CLOSED_ADMIN_STAGE };

	//BY PR, businessHour object
	public static final BusinessHours objDefaultBuinessHourRec = GlobalQueryHelper.getDefaultBusinessHour();

	//By AKS Dated 5th Jan 2021 to get State Name to abbreviations Mapping
	public static Map<String, String> getStateNameAbbreviations() {
		if (map_StateNameAbbreviations == null) {
			fetchStateNameAbbreviations();
		}
		return map_StateNameAbbreviations;
	}

	private static void fetchStateNameAbbreviations() {
		map_StateNameAbbreviations = new Map<String, String>();
		for (State_Name_to_abbreviations_Mapping__c st : State_Name_to_abbreviations_Mapping__c.getall().values()) {
			map_StateNameAbbreviations.put(st.State_Name__c, st.State_Abbreviation__c);
		}
	}

	//By AKS Dated 5th Jan 2021 to get collection of Region,Calendly and State
	public static List<Region_Setting__mdt> getRegionSettings() {
		if (list_RegionSettings == null) {
			fetchRegionSettings();
		}
		return list_RegionSettings;
	}

	private static void fetchRegionSettings() {
		list_RegionSettings = new List<Region_Setting__mdt>();
		// Query all State from custom setting
		list_RegionSettings = [SELECT Id, Calendly_Link__c, Region_Name__c, States__c FROM Region_Setting__mdt];
	}

	private static void fetchAdvisingEmailAutomationFollowUp() {
		map_AdvisingEmailAutomationFollowUp = new Map<Integer, Advising_Email_Automation_Follow_Up__mdt>();
		for (Advising_Email_Automation_Follow_Up__mdt ae : [SELECT Id, MasterLabel, DeveloperName, First_Follow_Up__c, Second_Follow_Up__c FROM Advising_Email_Automation_Follow_Up__mdt]) {
			map_AdvisingEmailAutomationFollowUp.put(integer.valueOf(ae.MasterLabel), ae);
		}
	}

	/**** Populate Current Fiscal Quarter and Year  ****/
	private static void fetchPricebooks() {
		map_PricebookName = new Map<String, PriceBook2>();
		map_PricebookId = new Map<Id, PriceBook2>();
		for (PriceBook2 objPB : [
			SELECT
				Id,
				Name,
				(SELECT Id, UnitPrice, Product2.Name, Product2.Product_Type__c, toLabel(Product2.Product_Category__c), Product2.Discounts_Available__c,Base_Price__c FROM PriceBookEntries WHERE UnitPrice > 0)
			FROM PriceBook2
			WHERE IsActive = TRUE
		]) {
			map_PricebookName.put(objPB.Name, objPB);
			map_PricebookId.put(objPB.Id, objPB);
		}
	}

	public static PriceBook2 getPriceBookByName(String strParam) {
		if (map_PricebookName == null) {
			fetchPricebooks();
		}

		return map_PricebookName.get(strParam);
	}

	public static PriceBook2 getPriceBookById(Id idParam) {
		if (map_PricebookId == null) {
			fetchPricebooks();
		}

		return map_PricebookId.get(idParam);
	}

	// Current Fiscal Quarter and Year
	public static Period objCurrentFQ;
	public static Period objCurrentFY;

	/**** Populate Current Fiscal Quarter and Year  ****/
	public static void fetchFiscalPeriods() {
		for (Period objPeriod : [
			SELECT Number, Type, StartDate, EndDate
			FROM Period
			WHERE (Type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER) OR (Type = 'Year' AND StartDate = THIS_FISCAL_YEAR)
		]) {
			if (objPeriod.Type == 'Quarter') {
				objCurrentFQ = objPeriod;
			} else {
				objCurrentFY = objPeriod;
			}
		}
	}

	/**** Is date in current FQ ****/
	public static Boolean isCurrentFQ(Date dtParam) {
		if (dtParam == null) {
			return false;
		}

		if (objCurrentFQ == null) {
			fetchFiscalPeriods();
		}

		if (dtParam >= objCurrentFQ.StartDate && dtParam <= objCurrentFQ.EndDate) {
			return true;
		}

		return false;
	}

	/**** Is date in current FY ****/
	public static Boolean isCurrentFY(Date dtParam) {
		if (dtParam == null) {
			return false;
		}

		if (objCurrentFY == null) {
			fetchFiscalPeriods();
		}

		if (dtParam >= objCurrentFY.StartDate && dtParam <= objCurrentFY.EndDate) {
			return true;
		}

		return false;
	}

	/**** Check for Sales Opportunity RecordTypes ****/
	public static Boolean isSales(Opportunity objOppty) {
		if (objOppty == null) {
			return false;
		}

		if (
			objOppty.RecordTypeId == COMPANY_OPPTY_RT_ID ||
			objOppty.RecordTypeId == BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
			objOppty.RecordTypeId == BENEFITS_BOR_OPPTY_RT_ID ||
			objOppty.RecordTypeId == ACQUISITION_OPPTY_RT_ID
		) {
			return true;
		}

		return false;
	}

	/**** Check for Benefits Opportunity RecordTypes ****/
	public static Boolean isBenefits(Opportunity objOppty) {
		if (objOppty == null) {
			return false;
		}

		if (
			objOppty.RecordTypeId == BENEFITS_CHANGE_OPPTY_RT_ID ||
			objOppty.RecordTypeId == BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
			objOppty.RecordTypeId == BENEFITS_BOR_OPPTY_RT_ID ||
			objOppty.RecordTypeId == BENEFITS_RENEWAL_OPPTY_RT_ID ||
			objOppty.RecordTypeId == BENEFITS_BYOB_OPPTY_RT_ID
		) {
			return true;
		}
		return false;
	}

	/**** Returns Opportunity Benefits record type to default Benefits product mapping ****/
	public static Map<String, List<String>> getBenefitsDefaultProductsMetadata() {
		Map<String, List<String>> map_OppRectypeProducts = new Map<String, List<String>>();
		for (Benefits_Default_Products__mdt defProdMdt : Benefits_Default_Products__mdt.getAll()?.values()) {
			map_OppRectypeProducts.put(defProdMdt.MasterLabel, defProdMdt.Product_Names__c?.split(','));
		}
		return map_OppRectypeProducts;
	}

	/**** Returns last date of Gusto's relevant financial quarter for any date ****/
	public static Date quarterLastDay(Date dtParam) {
		if (dtParam == null) {
			return null;
		}

		switch on dtParam.Month() {
			when 1 {
				return Date.newInstance(dtParam.year(), 2, 1).addDays(-1);
			}
			when 2, 3, 4 {
				return Date.newInstance(dtParam.year(), 5, 1).addDays(-1);
			}
			when 5, 6, 7 {
				return Date.newInstance(dtParam.year(), 8, 1).addDays(-1);
			}
			when 8, 9, 10 {
				return Date.newInstance(dtParam.year(), 11, 1).addDays(-1);
			}
			when 11, 12 {
				return Date.newInstance(dtParam.year() + 1, 2, 1).addDays(-1);
			}
		}

		return null;
	}

	/**** Returns a list of Opportunity Benefits Record Type Ids ****/
	public static Set<Id> getBenefitRecordTypeIds() {
		Set<Id> set_benefitRecTypeIds = new Set<Id>{ BENEFITS_NEW_PLAN_OPPTY_RT_ID, BENEFITS_BOR_OPPTY_RT_ID, BENEFITS_CHANGE_OPPTY_RT_ID, BENEFITS_RENEWAL_OPPTY_RT_ID, BENEFITS_BYOB_OPPTY_RT_ID };
		return set_benefitRecTypeIds;
	}

	/**** Set Effective Date to Week Day ****/
	public static Date checkWeekendDate(Date dtEffectiveDate) {
		String strDay = DateTime.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), dtEffectiveDate.day()).format('EEEE');

		if (String.isNotBlank(strDay) && strDay.equalsIgnoreCase('Sunday')) {
			dtEffectiveDate = dtEffectiveDate.addDays(-2);
		}

		if (String.isNotBlank(strDay) && strDay.equalsIgnoreCase('Saturday')) {
			dtEffectiveDate = dtEffectiveDate.addDays(-1);
		}

		return dtEffectiveDate;
	}

	/**** Returns greater of the two datetime values  ****/
	public static dateTime greaterTime(DateTime dtTimestamp, DateTime dtmParam) {
		if (dtTimestamp == null && dtmParam == null) {
			return null;
		}

		if (dtmParam != null) {
			if (dtTimestamp == null || dtmParam > dtTimestamp) {
				return dtmParam;
			}

			return dtTimestamp;
		}

		return dtTimestamp;
	}

	/**** Check forCustomer Success Opportunity RecordType ****/
	public static Boolean isCustomerSuccess(Opportunity objOppty) {
		if (objOppty == null) {
			return false;
		}

		if (objOppty.RecordTypeId == CUSTOMER_SUCCESS_RT_ID) {
			return true;
		}

		return false;
	}

	/**
	 * @author        Deepika Saini
	 * @description   Check Whether Opportunity should undergo Assignment Logic
	 * @param         objOppty New Opportunity record
	 * @param         objOldOppty Old Opportunity record
	 * @return        `Boolean` Is this Opportunity eligible for Advisor assignment?
	 **/
	public static Boolean isEligibleForAdvisorAssignment(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty.RecordTypeId == BENEFITS_RENEWAL_OPPTY_RT_ID) {
			if (String.isNotBlank(objOppty.Owner_Role_Name__c) && !FWManageRoleUtil.set_AdvisorRoles.isEmpty() && FWManageRoleUtil.set_AdvisorRoles.contains(objOppty.Owner_Role_Name__c)) {
				return false;
			}

			if (objOppty.Big_Desk_BenOps__c && SKIP_BIG_DESK_ASSIGNMENT && objOppty.Advisor_Assignment__c == BIG_DESK_ADVISOR_ASSIGNMENT) {
				return false;
			}

			if (!objOppty.Big_Desk_BenOps__c && objOppty.Advisor_Assignment__c == BIG_DESK_ADVISOR_ASSIGNMENT) {
				return false;
			}

			if (
				(objOldOppty == null && objOppty.Big_Desk_BenOps__c && objOppty.Advisor_Assignment__c == BIG_DESK_ADVISOR_ASSIGNMENT) ||
				(objOldOppty != null &&
				objOldOppty.Advisor_Assignment__c == null &&
				objOppty.Advisor_Assignment__c != null)
			) {
				return true;
			}
		}

		return false;
	}

	/**
	 * @description   Dynamic calculation of MRR based on EE counts and Additional Services
	 * @param         intEE - Number of domestic employees
	 * @param         intContractors - Number of domestic contractors
	 * @param         intInternationalEmployee - Number of international employees
	 * @param         intInternationalEmployee - Number of international intInternationalContractors
	 * @param         strAdditionalServices - Any additional services (add-ons)
	 * @param         decAccountantDiscount - Accountant Discount
	 * @param         decPremiumDiscount - Premium Discount
	 **/
	public static Decimal calculateMRROppNew(
		Decimal intEE,
		Decimal intContractors,
		Decimal intInternationalEmployee,
		Decimal intInternationalContractors,
		String strAdditionalServices,
		Decimal decAccountantDiscount,
		Decimal decPremiumTierDiscount,
		String strPriceBookName
	) {
		Decimal decSalePrice = 0;
		// Get pricebook along with pricebook entires
		Pricebook2 objPricebook = getPriceBookByName(strPriceBookName);
		// Replace null values with 0
		intEE = intEE != null ? intEE : 0;
		intContractors = intContractors != null ? intContractors : 0;
		intInternationalEmployee = intInternationalEmployee != null ? intInternationalEmployee : 0;
		intInternationalContractors = intInternationalContractors != null ? intInternationalContractors : 0;
		decAccountantDiscount = decAccountantDiscount != null ? decAccountantDiscount : 0;
		decPremiumTierDiscount = decPremiumTierDiscount != null ? decPremiumTierDiscount : 0;
		List<String> list_AdditionalServices = String.isNotBlank(strAdditionalServices) ? strAdditionalServices.split(';') : new List<String>();
		boolean blnProductCategoryInternationalPayroll = false;
		// Employer of Record additional services check
		if (list_AdditionalServices.contains(AccountUtil.EMPLOYER_OF_RECORD)) {
			blnProductCategoryInternationalPayroll = true;
		}
		// Check if pricebook is not null
		if (objPricebook != null) {
			// Iterate over all pricebook entries
			for (PricebookEntry objPBE : objPricebook.PricebookEntries) {
				Decimal decTotalDiscount = 0;
				// Initialize variables from product
				String strProdName = objPBE.Product2?.Name;
				String strProductType = objPBE.Product2?.Product_Type__c;
				String strProductCategory = objPBE.Product2?.Product_Category__c;
				String strDiscountsAvailable = objPBE.Product2?.Discounts_Available__c;

				// calculate total discount percentage if product has discounts available
				if (String.isNotBlank(strDiscountsAvailable)) {
					for (String strDiscountType : strDiscountsAvailable.split(';')) {
						// add to total discount if product should deduct accountant discount & accountant discount is greater than 0
						if (strDiscountType.equalsIgnoreCase(AccountUtil.ACCOUNTANT_DISCOUNT) && decAccountantDiscount > 0) {
							decTotalDiscount = decTotalDiscount + decAccountantDiscount;
						} else if (strDiscountType.equalsIgnoreCase(AccountUtil.PREMIUM_TIER_DISCOUNT) && decPremiumTierDiscount > 0) {
							// add to total discount if product should deduct premium tier discount & premium tier discount is greater than 0
							decTotalDiscount = decTotalDiscount + decPremiumTierDiscount;
						}
					}
				}

				if (String.isNotBlank(strProdName) && String.isNotBlank(strProductType)) {
					// if category is payroll or opp contains additional services
					if (strProductCategory == OpportunityUtil.PRODUCT_CATEGORY_PAYROLL || (String.isNotBlank(strProductCategory) && list_AdditionalServices.contains(strProductCategory))) {
						// apply discounts at each line item instead of calculating discount for the whole amount
						// if product type is monthly, use quantity as 1 and calculate sale price with discount
						if (strProductType == OpportunityUtil.PRODUCT_TYPE_MONTHLY && !blnProductCategoryInternationalPayroll) {
							decSalePrice = decSalePrice + objPBE.UnitPrice - (objPBE.UnitPrice * decTotalDiscount) / 100;
						}
						if (strProductType == OpportunityUtil.PRODUCT_TYPE_EMPLOYEES && !blnProductCategoryInternationalPayroll) {
							// if product type is employee, use quantity as EE count and calculate sale price with discount
							decSalePrice = decSalePrice + (objPBE.UnitPrice * intEE) - ((objPBE.UnitPrice * intEE) * decTotalDiscount) / 100;
						} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_CONTRACTORS && !blnProductCategoryInternationalPayroll) {
							// if product type is contractor, use quantity as contractor count and calculate sale price with discount
							decSalePrice = decSalePrice + (objPBE.UnitPrice * intContractors) - ((objPBE.UnitPrice * intContractors) * decTotalDiscount) / 100;
						} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_INTERNATIONAL_CONTRACTORS && !blnProductCategoryInternationalPayroll) {
							// if product type is international contractor, use quantity as international contractor count and calculate sale price with discount
							decSalePrice = decSalePrice + (objPBE.UnitPrice * intInternationalContractors) - ((objPBE.UnitPrice * intInternationalContractors) * decTotalDiscount) / 100;
						} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_INTERNATIONAL_EMPLOYESS && blnProductCategoryInternationalPayroll) {
							// if product type is international employee, use quantity as international employee count and calculate sale price with discount
							decSalePrice = decSalePrice + (objPBE.UnitPrice * intInternationalEmployee) - ((objPBE.UnitPrice * intInternationalEmployee) * decTotalDiscount) / 100;
						}
					}
				}
			}
		}
		// return the calculated amount
		return decSalePrice;
	}

	/**** Check for Cross-Sell and Upsell Opportunity RecordType ****/
	public static Boolean isTierUpsell(Opportunity objOppty) {
		if (objOppty?.RecordTypeId == TIER_UPSELL_OPPTY_RT_ID) {
			return true;
		}

		return false;
	}

	/**
	 * @description Get Split Type Id from Opportunity Split name
	 * @return   OpportunitySplitTypeId
	 */
	public static Id getSplitType(String strType) {
		if (map_SplitTypeId == null) {
			fetchSplitType();
		}
		if (map_SplitTypeId.containsKey(strType)) {
			return map_SplitTypeId.get(strType);
		} else {
			return null;
		}
	}

	/**
	 * @description Query OpportunitySplitType records
	 */
	private static void fetchSplitType() {
		map_SplitTypeId = new Map<String, Id>();
		for (OpportunitySplitType objType : [SELECT Id, DeveloperName FROM OpportunitySplitType]) {
			map_SplitTypeId.put(objType.DeveloperName, objType.Id);
		}
	}

	//Tier mapping tracker variables.
	private static Map<Id, Map<String, Tier_To_Pricebook_Mapping__mdt>> map_OppRecordTypeIdToTierMapping = null;
	private static final String DEFAULT_TIER = 'DEFAULT';

	/**
	 * @description Fetch All Tier mapping and convert into map for easy processing.
	 * @return      `Map<Id, Map<String, Tier_To_Pricebook_Mapping__mdt>>`
	 */
	private static Map<Id, Map<String, Tier_To_Pricebook_Mapping__mdt>> getAllTierMapping() {
		Map<Id, Map<String, Tier_To_Pricebook_Mapping__mdt>> map_OppRecordTypeIdToTierMapping = new Map<Id, Map<String, Tier_To_Pricebook_Mapping__mdt>>();
		Map<String, Id> map_OppRecordTypeToId = RecordTypes.getRecordTypeDevNameIdMap('Opportunity');

		for (Tier_To_Pricebook_Mapping__mdt objMapping : Tier_To_Pricebook_Mapping__mdt.getAll().values()) {
			Id idOppRecordType = map_OppRecordTypeToId.get(objMapping.Opportunity_Record_Type__c);
			Map<String, Tier_To_Pricebook_Mapping__mdt> map_TierToMapping = map_OppRecordTypeIdToTierMapping.get(idOppRecordType);

			if (map_TierToMapping == null) {
				map_TierToMapping = new Map<String, Tier_To_Pricebook_Mapping__mdt>();
				map_OppRecordTypeIdToTierMapping.put(idOppRecordType, map_TierToMapping);
			}

			map_TierToMapping.put(objMapping.Tier__c, objMapping);
		}

		OpportunityUtil.map_OppRecordTypeIdToTierMapping = map_OppRecordTypeIdToTierMapping;
		return map_OppRecordTypeIdToTierMapping;
	}

	/**
	 * @description               Calculate Pricebook2Id from Opportunity record type Id and Tier values
	 * @param idOppRecordTypeId   Opportunity Record type Id
	 * @param strTier             Tier Value
	 * @param blnRetDefaultIfNone calculate default if no specific value for Record type and Tier.
	 * @return                    `Id`
	 */
	public static Id getTierPricebookId(Id idOppRecordTypeId, String strTier, Boolean blnRetDefaultIfNone) {
		if (OpportunityUtil.map_OppRecordTypeIdToTierMapping == null) {
			getAllTierMapping();
		}

		Tier_To_Pricebook_Mapping__mdt objMapping = OpportunityUtil.map_OppRecordTypeIdToTierMapping.get(idOppRecordTypeId)?.get(strTier);
		if (objMapping == null && blnRetDefaultIfNone) {
			objMapping = OpportunityUtil.map_OppRecordTypeIdToTierMapping.get(idOppRecordTypeId)?.get(DEFAULT_TIER);
		}

		return objMapping == null ? null : getPriceBookByName(objMapping.Pricebook_Name__c)?.Id;
	}
}