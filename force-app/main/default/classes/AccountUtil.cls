/**
 * @author Aurobind Ravichandran
 * @since 10/01/2020
 **/
public with sharing class AccountUtil {
	public final static Id RESELLER_ACCOUNT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Reseller');
	public final static Id COMPANY_ACCOUNT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Company');
	public final static Id EMBEDDED_COMPANY_ACCOUNT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Embedded_Company');
	public final static Id PARTNER_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Partner');

	public final static String RESELLER_ACCOUNT_TYPE = 'Reseller';
	public final static String COMPANY_ACCOUNT_TYPE = 'Company';
	public final static String EMBEDDED_PARTNER_TYPE = 'Embedded Partner';
	public final static String EMBEDDED_COMPANY_TYPE = 'Embedded Company';

	public final static String SALES_ACTION_TRACKER_ACTION_TYPE = 'Account Stage Tracking';
	public final static STRING ACCOUNT_OBJ_PREFIX = '001';

	//Partner status
	public final static String PARTNER_STATUS_POTENTIAL_PARTNER = 'Potential Partner';
	public final static String PARTNER_STATUS_ACTIVE_PARTNER = 'Active Partner';
	public final static String PARTNER_STATUS_INACTIVE_PARTNER = 'Inactive Partner';

	public final static String ZP_COMP_APPROVAL_STATUS_APPROVED = 'Approved';
	public final static String ZP_COMP_APPROVAL_STATUS_REQ_FOR_INFO = 'Request for Information';
	public final static String REF_TYPE_USER_ROLE = 'UserRole';
	public final static String REF_TYPE_PARTNER_REF_USER = 'PartnerReferralUser';

	public final static String TAX_PAYER_AUDIT = 'taxPayerAudit';
	public final static String JUST_GOT_APPROVED = 'Just got approved';
	public final static Integer DEFAULT_COHORT_DAYS = 90;

	public final static String ORDER_STATUS_CLO_CANCELED = 'Closed: Canceled';
	public final static String ORDER_STATUS_CLO_PAYROLL_RUN = 'Closed: Payroll Run';
	public final static String ORDER_STATUS_PAYROLL_SUBMIT = 'Payroll Submitted';
	public final static String ORDER_STATUS_ONB_1_6 = 'Onboarding Steps 1 - 6';
	public final static String ORDER_STATUS_ONB_7 = 'Onboarding Step 7';
	public final static String ORDER_STATUS_ONB_8_9 = 'Onboarding Steps 8 - 9';
	public final static String ORDER_STATUS_ONB_10 = 'Onboarding Step 10';
	public final static String ORDER_STATUS_READY_APPROVAL = 'Ready for Approval';
	public final static String ORDER_STATUS_ACC_APPROVED = 'Account Approved';
	public final static String ORDER_STAUS_ASSURANCE_RFI = 'Assurance RFI';

	public final static String PAYROLL_PROCC_STATUS_FUNDED = 'Funded';
	public final static String PAYROLL_PROCC_STATUS_PAID = 'Paid';
	public final static String PAYROLL_PROCC_STATUS_PROCESSED = 'Processed';
	public final static String LEAD_HOLD_OUT = 'Held Out';
	public final static String LEAD_EXPOSED = 'Exposed';

	public final static String ACCOUNT_OVERALL_STATUS_SUSPENDED = 'Suspended';
	public final static String ACCOUNT_OVERALL_STATUS_NEW = 'New';
	public final static String ACCOUNT_OVERALL_STATUS_ACTIVE = 'Active';
	public final static String LABEL_ACCOUNT_ROUTER_PARTNER_AE = 'Partner AE [Account Routing]';
	public final static String ONBOARDING_FLOW_IN_APP = 'In-App';
	public final static String PARTNER_AM_ROLE_NAME = '_am_';

	public final static String ROE_EXCEPTION_REQUESTED = 'Requested';
	public final static String ROE_EXCEPTION_APPROVED = 'Approved';

	// Sales Engagement Status Values
	public final static String SALES_ENGMNT_STATUS_GROW = 'Grow';
	public final static String SALES_ENGMNT_STATUS_RAMP = 'Ramp';
	public final static String SALES_ENGMNT_STATUS_FALSE_SAL = 'False SAL';
	public final static String SALES_ENGMNT_STATUS_NURTURE = 'Nurture';
	public final static String SALES_ENGMNT_STATUS_WORKING_SAL = 'Working SAL';
	public final static String SALES_ENGMNT_STATUS_UNQUALIFIED = 'Unqualified';
	public final static String SALES_ENGMNT_STATUS_PROSPECTIVE = 'Prospective';
	public final static String SALES_ENGMNT_STATUS_ACTIVE = 'Active';
	public final static String SALES_ENGMNT_STATUS_CHURNED = 'Churned';

	// Sales Engagement Status Detail Values
	public final static String SALES_ENGMNT_STATUS_DETAIL_FIRM_ONBOARDING = 'Firm/Accountant Onboarding';
	public final static String SALES_ENGMNT_STATUS_DETAIL_MDR_ATMPT_CNTCT = 'MDR Attempting Contact';
	public final static String SALES_ENGMNT_STATUS_DETAIL_UNRESPONSIVE = 'Unresponsive';
	public final static String SALES_ENGMNT_STATUS_DETAIL_NVR_ADDED_CLIENT = 'Never added 1st client';
	public final static String SALES_ENGMNT_STATUS_DETAIL_NO_RECENT_CLIENTS = 'No Recent Clients';
	public final static String SALES_ENGMNT_STATUS_DETAIL_MDR_TO_CNTCT = 'MDR To Contact';
	public final static String SALES_ENGMNT_STATUS_DETAIL_PRE_MDR = 'Pre-MDR';
	public final static String SALES_ENGMNT_STATUS_DETAIL_DISCOVERY_DUPE = 'Duplicate';
	public final static String SALES_ENGMNT_STATUS_DETAIL_DISCOVERY_CALL_SCHD = 'Discovery Call Scheduled';
	public final static String ACC_SALES_ENGMNT_DETAIL_ADD_DISCUSSION_NEEDED = 'Additional Discussions Needed';

	// Qualified Status Values
	public final static String QUALIFIED_STATUS_UNQUALIFIED = 'Unqualified';

	// Qualified Status Detail Values
	public final static String QUALIFIED_STATUS_DETAIL_DELETED_ACCOUNT = 'Deleted Account';

	//Partner Tiers
	public final static String AM_TIER_GOLD = 'Gold';
	public final static String AM_TIER_SILVER = 'Silver';
	public final static String AM_TIER_BRONZE = 'Bronze';
	public final static String AM_TIER_STARTER = 'Starter';

	//Partner Tier Disounts
	public final static Decimal AM_TIER_GOLD_DISCOUNT = 20;
	public final static Decimal AM_TIER_SILVER_DISCOUNT = 15;
	public final static Decimal AM_TIER_BRONZE_DISCOUNT = 10;
	public final static Decimal AM_TIER_STARTER_DISCOUNT = 0;

	//Account Priority
	public final static String ACCOUNT_PRIORITY_5 = '5';

	public final static Map<String, Decimal> map_PartnerTier = new Map<String, Decimal>{
		AccountUtil.AM_TIER_GOLD => AccountUtil.AM_TIER_GOLD_DISCOUNT,
		AccountUtil.AM_TIER_SILVER => AccountUtil.AM_TIER_SILVER_DISCOUNT,
		AccountUtil.AM_TIER_BRONZE => AccountUtil.AM_TIER_BRONZE_DISCOUNT,
		AccountUtil.AM_TIER_STARTER => AccountUtil.AM_TIER_STARTER_DISCOUNT
	};

	public final static String SIMPLE_TIER = 'simple';
	public final static String WHOLESALE_TIER = 'wholesale';
	public final static String CORE_TIER = 'core';
	public final static String COMPLETE_TIER = 'complete';
	public final static String PLUS_TIER = 'plus';
	public final static String CONCEIRGE_TIER = 'concierge';
	public final static String PLUS_PRIORITY_SUPPORT = 'plus with priority support';
	public final static String PREMIUM_TIER = 'premium';
	public final static String LEGACY_PREMIUM_TIER = 'Legacy Premium';
	public final static String CRB_PREMIUM_TIER = 'Premium CRB';
	public final static String MULTI_EIN_PREMIUM_TIER = 'Premium Multi-EIN';
	public final static String SELECT_TIER = 'select';
	public final static String CONTRACTOR_TIER = 'contractor only';
	public final static String CONTRACTOR_ONLY_TIER = 'contractor_only';
	public final static String TASK_STATUS_CONNECT = 'Connect';
	public final static String SIMPLE_AND_GUSTO_GLOBAL = 'simple and gusto global';
	public final static String WHOLESALE_AND_GUSTO_GLOBAL = 'wholesale and gusto global';
	public final static String PLUS_AND_GUSTO_GLOBAL = 'plus and gusto global';
	public final static String PLUS_PRIORITY_SUPPORT_AND_GUSTO_GLOBAL = 'plus with priority support and gusto global';
	public final static String CORE_AND_GUSTO_GLOBAL = 'core and gusto global';
	public final static String COMPLETE_AND_GUSTO_GLOBAL = 'complete and gusto global';
	public final static String CONCEIRGE_AND_GUSTO_GLOBAL = 'concierge and gusto global';
	public final static String PREMIUM_AND_GUSTO_GLOBAL = 'premium and gusto global';

	public static final String ADD_SERVICES_PRIORITY_SUPPORT = 'Priority Support and HR Services';
	public static final String ADD_SERVICES_INTERNATIONAL_CONTRACTOR = 'International Contractor Service';
	public static Boolean blnHIOwnerRouting = false;
	public static final String MANUAL_HI_OWNER_ROUTING = 'Manual Request for Routing';
	public static final String PRIORITY_SUPPORT = 'Priority Support';
	public static final String INTERNATIONAL_PAYROLL = 'International Payroll';
	public static final String EMPLOYER_OF_RECORD = 'Employer of Record';
	public static final String PROD_INTEREST_INTERNATIONAL_PAYROLL = 'international_payroll';
	public static final String ACCOUNTANT_DISCOUNT = 'accountant';
	public static final String PREMIUM_TIER_DISCOUNT = 'premium_tier_discount';

	//Route To Market values
	public final static String RTM_ACCOUNTANT = 'Accountant';

	public final static Map<String, Decimal> map_TierPriority = new Map<String, Decimal>{
		CONTRACTOR_TIER => 1,
		CONTRACTOR_ONLY_TIER => 1,
		SIMPLE_TIER => 2,
		WHOLESALE_TIER => 2,
		CORE_TIER => 2,
		SIMPLE_AND_GUSTO_GLOBAL => 3,
		WHOLESALE_AND_GUSTO_GLOBAL => 3,
		CORE_AND_GUSTO_GLOBAL => 3,
		COMPLETE_TIER => 4,
		PLUS_TIER => 4,
		COMPLETE_AND_GUSTO_GLOBAL => 5,
		PLUS_AND_GUSTO_GLOBAL => 5,
		CONCEIRGE_TIER => 5,
		PLUS_PRIORITY_SUPPORT => 5,
		CONCEIRGE_AND_GUSTO_GLOBAL => 6,
		PLUS_PRIORITY_SUPPORT_AND_GUSTO_GLOBAL => 6,
		PREMIUM_TIER => 7,
		LEGACY_PREMIUM_TIER => 7,
		CRB_PREMIUM_TIER => 7,
		MULTI_EIN_PREMIUM_TIER => 7,
		PREMIUM_AND_GUSTO_GLOBAL => 8
	};

	public final static Map<String, String> map_UpsellTierLabelAndAPI = new Map<String, String>{
		SIMPLE_AND_GUSTO_GLOBAL => 'Simple and ' + EMPLOYER_OF_RECORD,
		WHOLESALE_AND_GUSTO_GLOBAL => 'Wholesale and ' + EMPLOYER_OF_RECORD,
		PLUS_AND_GUSTO_GLOBAL => 'Plus and ' + EMPLOYER_OF_RECORD,
		CORE_AND_GUSTO_GLOBAL => 'Core and ' + EMPLOYER_OF_RECORD,
		COMPLETE_AND_GUSTO_GLOBAL => 'Complete and ' + EMPLOYER_OF_RECORD,
		CONCEIRGE_AND_GUSTO_GLOBAL => 'Concierge and ' + EMPLOYER_OF_RECORD,
		PREMIUM_AND_GUSTO_GLOBAL => 'Premium and ' + EMPLOYER_OF_RECORD,
		PLUS_PRIORITY_SUPPORT_AND_GUSTO_GLOBAL => 'Plus with Priority Support and ' + EMPLOYER_OF_RECORD,
		SIMPLE_TIER => 'Simple',
		PLUS_TIER => 'Plus',
		PLUS_PRIORITY_SUPPORT => 'Plus with Priority Support',
		PREMIUM_TIER => 'Premium',
		WHOLESALE_TIER => 'Wholesale'
	};

	public static Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
	public final static String SIMPLE_PAYMENT_PLAN = objTierConfig.New_Price_1__c;
	public final static String PLUS_PAYMENT_PLAN = objTierConfig.New_Price_2__c;
	public final static String PREMIUM_PAYMENT_PLAN = objTierConfig.New_Price_4__c;
	public final static String LEGACY_PREMIUM_PAYMENT_PLAN = objTierConfig.New_Price_3__c;
	public final static String CRB_PREMIUM_PAYMENT_PLAN = objTierConfig.New_Price_5__c;
	public final static String MULTI_EIN_PREMIUM_PAYMENT_PLAN = objTierConfig.New_Price_6__c;
	public final static String CONTRACTOR_PAYMENT_PLAN = '$0 Base, $6: 1+';

	public final static Set<String> PAYROLL_PROCESSING_STATES = new Set<String>{ 'Paid', 'Processed', 'Funded' };

	public final static Map<String, String> map_TierPaymentPlan = new Map<String, String>{
		SIMPLE_TIER => SIMPLE_PAYMENT_PLAN,
		PLUS_TIER => PLUS_PAYMENT_PLAN,
		PREMIUM_TIER => PREMIUM_PAYMENT_PLAN,
		LEGACY_PREMIUM_TIER => LEGACY_PREMIUM_PAYMENT_PLAN,
		CRB_PREMIUM_TIER => CRB_PREMIUM_PAYMENT_PLAN,
		MULTI_EIN_PREMIUM_TIER => MULTI_EIN_PREMIUM_PAYMENT_PLAN,
		CONTRACTOR_TIER => CONTRACTOR_PAYMENT_PLAN,
		CONTRACTOR_ONLY_TIER => CONTRACTOR_PAYMENT_PLAN,
		objTierConfig.Old_Tier_1__c?.toLowerCase() => objTierConfig.Old_Price_1__c,
		objTierConfig.Old_Tier_2__c?.toLowerCase() => objTierConfig.Old_Price_2__c,
		objTierConfig.Old_Tier_3__c?.toLowerCase() => objTierConfig.Old_Price_3__c,
		objTierConfig.Old_Tier_4__c?.toLowerCase() => PREMIUM_PAYMENT_PLAN
	};
	// User Roles
	public final static String SALES_ROLE = 'sales';
	public final static String PARTNER_ROLE = 'partner';
	public final static String SBIZ_ROLE = 'sb';
	public final static String MDR_ROLE = 'mdr';

	//User Roles Full Name
	public final static String SALES_PARTNER_MANAGER_ROLE = 'sales_partner_xx_xx_mgr';
	public final static String SALES_PARTNER_AE_ROLE = 'sales_partner_ae_xx';
	public final static String SALES_PARTNER_AM_ROLE = 'sales_partner_am_xx';
	public final static String SALES_PARTNER_SAM_ROLE = 'sales_partner_sam_xx';
	public final static String SALES_MM_PR_ROLE = 'sales_mm_pr_xx';
	public final static String SALES_MM_DEN_PR_ROLE = 'sales_mm_den_pr_mgr';
	public final static String SALES_BD_PR_ROLE = 'sales_bd_pr_xx';
	public final static String SALES_BD_PR_MGR_ROLE = 'sales_bd_pr_mgr';
	public final static String SALES_SBIZ_MGR_ROLE = 'sales_sb_xx_xx_mgr';
	public final static Set<String> set_PartnerRoles = new Set<String>{ SALES_PARTNER_SAM_ROLE, SALES_PARTNER_AM_ROLE, SALES_PARTNER_AE_ROLE };
	public final static Set<String> set_ExcludePartnerRoles = new Set<String>{ SALES_MM_PR_ROLE, SALES_MM_DEN_PR_ROLE, SALES_BD_PR_ROLE, SALES_SBIZ_MGR_ROLE };
	public final static String SALES_MDR_MGR_ROLE = 'sales_sdr_partner_mgr_xx';

	// Reseller Type
	public final static String RESELLER_TYPE_STRATEGIC_ACCOUNT = 'Strategic Account';

	// PROFILES:
	public final static String USER_PROFILE_NAME_GUSTO_INTEGRATION_PROFILE = 'Gusto Integration Profile';
	public final static String USER_PROFILE_NAME_CX_USER = 'CX User';

	public static Map<String, String> map_tier;

	public static Map<Id, Partner_Program_Company_Data__c> map_AccountPartnerProgramCompanyData;
	public static Map<String, Partner_Program_Company_Data__c> map_CompanyIdPartnerProgramCompanyData;
	public static Map<String, ZP_HI_Deduction__c> map_CompanyIdZPHIDeductions;
	public static Map<Id, Partnership_Interest__c> map_PartnershipInterests;
	public static Map<String, ZP_Company_Onboarding_Funnel__c> map_CompanyOnboardingFunnel;
	public static Map<String, Order> map_Orders;
	public static Map<Id, Account_Related_Tracking__c> map_accountIdToAccRelTracking;

	//Strings
	public static final String DELETE_EXCEPTION = 'Deleting Account is not allowed';
	//Email Pattern
	public static final String EMAIL_PATTERN = '[a-zA-Z0-9._-]+@[a-zA-Z]+.[a-zA-Z]{2,4}[.]{0,1}[a-zA-Z]{0,2}';

	public static String RINGLEAD_ROUTING_PROCESSED = 'sf_processed';
	public static final String INTEGRATION_USERS = System.Label.Integration_Users;

	//Recalculate metric Tracker
	public static final String TRACKER_FIRM_MRR = 'Firm MRR';

	// Configuration_Settings__c Object
	public static Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();

	// Account Team Roles
	public static String HI_NEW_PLAN_REP = 'HI New Plan Rep';
	public static String HI_BROKER_REP = 'HI Broker Rep';
	public static final String HI_SALES_ALL_ROLES = Test.isRunningTest() ? 'Integration Users' : System.Label.Benefits_Roles;
	public static final string ACCOUNT_TEAM_MEMBER_CSM_ROLE = 'Client Success Manager';

	// Type of HI
	public static final String HI_TYPE_BROKER = 'Broker';
	public static final String HI_TYPE_NEW_PLAN = 'New Plan';
	public static final List<String> LIST_ADMIN_ROLES = new List<String>{ ZPUserRoleUtil.PRIMARY_PAYROLL_ADMIN, ZPUserRoleUtil.PAYROLL_ADMIN };

	// Product Interests
	public static final String PROD_INTEREST_INTL_CONT_PAID = 'international_contractor_payment_paid';

	// Product Interest
	public static final String PROD_INTEREST_INTERNATIONAL_CONTRACTOR_PAYMENT_ONBOARDED = 'international_contractor_payment_onboarded'; // International Contractor Payment Onboarded

	// Additional Services
	public static final String ADD_SERVICES_INTL_CONTRACTOR_PAID = 'International Contractor Payment';

	//EOR Product Interest list
	public static final List<String> EOR_PRODUCT_INTEREST = new List<String>{
		'international_payroll_add_iee',
		'international_payroll_landing_page',
		'international_payroll_landing_page_consent',
		'international_payroll_logacall',
		'international_payroll_onboarding'
	};

	//ICP Product Interest list
	public static final List<String> ICP_PRODUCT_INTEREST = new List<String>{
		'international_contractor_payment_onboarding',
		'international_contractor_payment_landing_page',
		'international_contractor_payment_onboarded',
		'international_contractor_payment_add_IC',
		'international_contractor_payment_paid',
		'international_contractor_payment_logacall'
	};

	// Premium Tier product interest
	public static final String PREMIUM_TIER_LOGACALL = 'premium_tier_logacall';

	// Cross sell type
	public static final String CROSS_SELL = 'Cross Sell';

	// ICP Opp prefix
	public static final String ICP_OPP_SUFFIX = ' - Cross Sell ICP';

	// Additional Services
	public static final String INTERNATIONAL_CONTRACTOR_PAYMENT = 'International Contractor Payment';

	/**** get next payroll run date ****/
	public static Date getNextPayrollRunDate(Date dtFirstCheckDate, string strAchType) {
		BusinessHours objBusinessHour = GlobalQueryHelper.getDefaultBusinessHour();
		//defaul is 2 days
		integer intDaysBeforeRunDate = 2;

		if (String.isNotBlank(strAchType)) {
			if (strAchType == 'Next day') {
				intDaysBeforeRunDate = 1;
			}
		}

		if (objBusinessHour != null) {
			Long lngDaysInMiliSeconds = intDaysBeforeRunDate * 8 * 60 * 60 * 1000;
			DateTime dtDaysEarlierDT = BusinessHours.add(objBusinessHour.Id, dtFirstCheckDate, -lngDaysInMiliSeconds);
			if (dtDaysEarlierDT != null) {
				return dtDaysEarlierDT.date();
			}
		} else {
			return dtFirstCheckDate.addDays(-intDaysBeforeRunDate);
		}

		return null;
	}

	public final static List<String> list_RoutingReferralTypes {
		get {
			if (list_RoutingReferralTypes == null) {
				List<String> list_Results = new List<String>{ 'partnerreferraluser', 'userrole' };
				return list_Results;
			}
			return list_RoutingReferralTypes;
		}
	}

	/**** Get Hi Deductions by Company Id ****/
	public static Map<String, ZP_HI_Deduction__c> getCompanyHIDeductions(Set<String> set_ZpComppanyIds) {
		if (map_CompanyIdZPHIDeductions == null) {
			map_CompanyIdZPHIDeductions = queryCompanyHIDeductions(set_ZpComppanyIds);
		}
		return map_CompanyIdZPHIDeductions;
	}

	/**** Query HI Deductions by AccountId ****/
	public static Map<String, ZP_HI_Deduction__c> queryCompanyHIDeductions(Set<String> set_ZpComppanyIds) {
		map_CompanyIdZPHIDeductions = new Map<String, ZP_HI_Deduction__c>();
		for (ZP_HI_Deduction__c obj_ZPHiDeduction : [SELECT Id, Company_ID__c FROM ZP_HI_Deduction__c WHERE Company_ID__c IN :set_ZpComppanyIds]) {
			map_CompanyIdZPHIDeductions.put(obj_ZPHiDeduction.Company_ID__c, obj_ZPHiDeduction);
		}
		return map_CompanyIdZPHIDeductions;
	}

	/**** Get PartnershipInterests by Company Id ****/
	public static Map<Id, Partnership_Interest__c> getCompanyPartnershipInterest(Set<Id> set_AccountIds) {
		if (map_PartnershipInterests == null) {
			map_PartnershipInterests = queryPartnershipInterst(set_AccountIds);
		}
		return map_PartnershipInterests;
	}

	/**** Query Partnership Interests ****/
	public static Map<Id, Partnership_Interest__c> queryPartnershipInterst(Set<Id> set_AccountIds) {
		map_PartnershipInterests = new Map<Id, Partnership_Interest__c>();
		DateTime daysLimit = System.now().adddays(-60);

		List<Partnership_Interest__c> list_PartnershipInterests = [
			SELECT Id, Current_Tier__c, Date_Tier_Changed__c, Account__c
			FROM Partnership_Interest__c
			WHERE Account__c IN :set_AccountIds AND CreatedDate > :daysLimit
		];

		for (Partnership_Interest__c objPartnershipInterest : list_PartnershipInterests) {
			map_PartnershipInterests.put(objPartnershipInterest.Account__c, objPartnershipInterest);
		}
		return map_PartnershipInterests;
	}

	/**** Get PartnershipInterests by Company Id ****/
	public static Map<String, ZP_Company_Onboarding_Funnel__c> getCompanyOnboardingFunnel(Set<String> set_ZpComppanyIds) {
		if (map_CompanyOnboardingFunnel == null) {
			map_CompanyOnboardingFunnel = queryCompanyOnboardingFunnel(set_ZpComppanyIds);
		}
		return map_CompanyOnboardingFunnel;
	}

	/**** Query Company Onboarding Funnel by companyId ****/
	public static Map<String, ZP_Company_Onboarding_Funnel__c> queryCompanyOnboardingFunnel(Set<String> set_ZpComppanyIds) {
		map_CompanyOnboardingFunnel = new Map<string, ZP_Company_Onboarding_Funnel__c>();
		for (ZP_Company_Onboarding_Funnel__c objOnboardingFunnel : [
			SELECT
				Add_Addresses_Completed_At__c,
				Add_Addresses_Completed__c,
				Add_Addresses_Started_At__c,
				Add_Bank_Info_Completed_At__c,
				Add_Bank_Info_Completed__c,
				Add_Bank_Info_Started_At__c,
				Add_Contractors_Started_At__c,
				Add_Employees_Completed_At__c,
				Add_Employees_Completed__c,
				Add_Employees_Started_At__c,
				Add_Signatory_Completed_At__c,
				Add_Signatory_Completed__c,
				Add_Signatory_Started_At__c,
				Company_Id__c,
				CreatedById,
				CreatedDate,
				Create_User_Account_Completed_At__c,
				Create_User_Account_Completed__c,
				Deleted_At__c,
				External_Key__c,
				Federal_Tax_Setup_Completed_At__c,
				Federal_Tax_Setup_Completed__c,
				Federal_Tax_Setup_Started_At__c,
				Historical_Liabilities_Completed_At__c,
				Historical_Liabilities_Completed__c,
				Historical_Liabilities_Started_At__c,
				Id,
				ID__c,
				IsDeleted,
				LastReferencedDate,
				LastViewedDate,
				Last_Processed__c,
				Message__c,
				Name,
				onboarding_completed_at__c,
				OwnerId,
				payroll_schedule_completed_at__c,
				Payroll_Schedule_Completed__c,
				Payroll_Schedule_Started_At__c,
				Previous_Paystubs_Completed_At__c,
				Previous_Paystubs_Completed__c,
				Previous_Paystubs_Started_At__c,
				Processing_State__c,
				Ran_Payroll_At__c,
				Ran_Payroll__c,
				Setup_Benefits_Started_At__c,
				Setup_wc_Started_At__c,
				Sign_All_Forms_Completed_At__c,
				Sign_All_Forms_Completed__c,
				Sign_All_Forms_Started_At__c,
				Sign__c,
				State_Setup_Completed_At__c,
				State_Setup_Completed__c,
				State_Setup_Started_At__c,
				SystemModstamp,
				Verify_Bank_Info_Completed_At__c,
				Verify_Bank_Info_Completed__c,
				Verify_Bank_Info_Started_At__c
			FROM ZP_Company_Onboarding_Funnel__c
			WHERE Company_Id__c IN :set_ZpComppanyIds
		]) {
			map_CompanyOnboardingFunnel.put(objOnboardingFunnel.Company_Id__c, objOnboardingFunnel);
		}
		return map_CompanyOnboardingFunnel;
	}

	/**** Get Orders by Company Id ****/
	public static Map<String, Order> getOrders(Set<String> set_ZpComppanyIds) {
		if (map_Orders == null) {
			map_Orders = queryOrders(set_ZpComppanyIds);
		}
		return map_Orders;
	}

	/**** Query Orders by companyId ****/
	public static Map<String, Order> queryOrders(Set<String> set_ZpComppanyIds) {
		map_Orders = new Map<string, Order>();
		for (Order objOrder : [
			SELECT
				Id,
				Status,
				AccountId,
				First_Check_Date__c,
				Total_Checklists_Count__c,
				RecordTypeId,
				Account.Payroll_Processing_Status__c,
				OpportunityId,
				Opportunity.Account.Previous_Payroll__c,
				Opportunity.Is_Historical__c,
				Opportunity.Account.ZP_Company_ID__c,
				Account.ZP_Company_Approval_Status__c
			FROM Order
			WHERE OpportunityId != NULL AND Opportunity.RecordType.DeveloperName = 'Company_Opportunity' AND Opportunity.Account.ZP_Company_ID__c IN :set_ZpComppanyIds
			ORDER BY LastModifiedDate ASC
		]) {
			map_Orders.put(objOrder.Opportunity.Account.ZP_Company_ID__c, objOrder);
		}
		return map_Orders;
	}

	/**** get account related trackings ****/
	public static Map<Id, Account_Related_Tracking__c> getAccountRelatedTracking(Set<Id> set_AccountIds) {
		if (map_accountIdToAccRelTracking == null) {
			map_accountIdToAccRelTracking = queryAccountRelatedTracking(set_AccountIds);
		}
		return map_accountIdToAccRelTracking;
	}

	/**** query account related tracking ****/
	public static Map<Id, Account_Related_Tracking__c> queryAccountRelatedTracking(Set<Id> set_AccountIds) {
		Map<Id, Account_Related_Tracking__c> map_accountIdToAccRelTrackingRec = new Map<Id, Account_Related_Tracking__c>();
		for (Account_Related_Tracking__c objAccRelTracking : [
			SELECT
				Id,
				Account__c,
				Unique_Account_Id__c,
				No_Of_Change_in_Account_Priority__c,
				No_Of_Change_No_Of_Clients__c,
				No_of_adds_current_Q__c,
				No_of_adds_last_Q__c,
				No_of_total_adds_in_current_FY__c,
				Q_Changed__c,
				Q_Tracking__c
			FROM Account_Related_Tracking__c
			WHERE Account__c IN :set_AccountIds AND Unique_Account_Id__c != NULL
		]) {
			map_accountIdToAccRelTrackingRec.put(objAccRelTracking.Account__c, objAccRelTracking);
		}
		return map_accountIdToAccRelTrackingRec;
	}

	/**
	 * @author       Lalitha Kasturi
	 * @description  This method will populate survey date for any given contact
	 * @param        objCon Required to find the random date for survey date or any date field
	 * @return       returns random date
	 */
	public static Date populateSurveyRandomDate(Contact objCon) {
		Date dtSurveyInitialDate;
		if (objCon.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
			dtSurveyInitialDate = objCon.Account.Joined_Date_Panda__c;
		} else if (objCon.Account.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
			dtSurveyInitialDate = objCon.Account.Cohort_Date__c;
		}

		return dtSurveyInitialDate.addDays(90 + Utils.generateRandomFromRange(1, 30));
	}

	/**
	 * @author       Swati Arya
	 * @description  Method to return the Workato Integration User Id
	 * @param       null
	 * @return       returns workato integration user id
	 */
	public static Id getWorkatoIntegrationUserId() {
		return [SELECT Id, UserName FROM User WHERE Username LIKE 'workato.integration@gusto.com%' LIMIT 1].Id;
	}

	/**
	 * @Description : Queueable method to send account for HI Owner Routing
	 * @Param       : Id - Id of the account to route HI Owner
	 **/
	public static void sendAccountForHIOwnerRouting(Id idAccount) {
		if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
			System.enqueueJob(new HIRoutingQueueable(idAccount));
		} else {
			sendAccountForHIOwnerRoutingFuture(idAccount);
		}
	}

	/**
	 * @Description : Future method to send account for HI Owner Routing
	 * @Param       : Id - Id of the account to route HI Owner
	 **/
	@future(callout=true)
	public static void sendAccountForHIOwnerRoutingFuture(Id idAccount) {
		// create parameter and set account id
		Map<String, Object> map_Params = new Map<String, Object>();
		map_Params.put('Account_Id', idAccount);
		// start the flow
		new Flow.Interview.Send_Account_For_HI_Owner_Routing(map_Params).start();
	}

	/**
	 * @author         Praveen Sethu
	 * @description    Query Account Teams on User record (Used for HI Sales Routing)
	 * @return         List of User Account Team members
	 */
	public static List<UserAccountTeamMember> queryUserAccountTeamMembers(Set<Id> set_UserIds) {
		List<String> list_HIRoles = HI_SALES_ALL_ROLES.split(',');
		return [
			SELECT Id, OwnerId, UserId, TeamMemberRole, User.UserRole.Name
			FROM UserAccountTeamMember
			WHERE OwnerId IN :set_UserIds AND User.IsActive = TRUE AND User.UserRole.Name IN :list_HIRoles
			ORDER BY CreatedDate ASC
		];
	}
	/**
	 * @description    Query Account Team Members
	 * @return         List of User Account Team members
	 */
	public static List<AccountTeamMember> queryAccountTeamMembers(Set<Id> set_AccountIds) {
		return [SELECT Id, AccountId, TeamMemberRole, UserId, User.UserRole.Name FROM AccountTeamMember WHERE AccountId IN :set_AccountIds AND TeamMemberRole = :ACCOUNT_TEAM_MEMBER_CSM_ROLE];
	}
}