/****************************************************************************
    @author       :   David (Dato) Tsamalashvili
    @createdDate  :   10/06/2020
    @desc         :   Lead Util for Lead Trigger Handler/ Lead Trigger Helper
****************************************************************************/
public with sharing class LeadUtil {
	//Trigger Context static data

	//final variables
	public final static Id COMPANY_LEAD_RT_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();
	public final static Id RESELLER_LEAD_RT_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Reseller').getRecordTypeId();
	public final static String LEAD_STATUS_AQL = 'AQL';
	public final static String LEAD_STATUS_RAW = 'Raw';
	public final static String LEAD_STATUS_MQL = 'MQL';
	public final static String LEAD_STATUS_UNQ = 'Unqualified';
	public final static String LEAD_STATUS_SAL = 'SAL';
	public final static String LEAD_STATUS_CONVERTED = Config.LeadConversion.CONVERTED_LEAD_STATUS;
	public final static String LEAD_STATUS_DET_TEST = 'Test/Junk Record';
	public final static String LEAD_STATUS_BACK_TO_NURT = 'Back to Nurture';
	public final static String LEAD_STATUS_FUT_OPP = 'Future Opportunity';
	public final static String LEAD_STATUS_ATT_CONTACT = 'Attempting Contact';
	public final static String LEAD_STATUS_DISC_CALL_SCH = 'Discovery Call Scheduled';
	public final static String LEAD_STATUS_DET_ACC_BKR = 'Accountant/Bookkeeper';
	public final static String LEAD_STATUS_DET_NOT_ACC = 'Not an accountant';
	public final static DateTime LEAD_CREATE_DATE = DateTime.newInstance(2019, 10, 27, 1, 1, 1);
	public final static DateTime CURRENT_DATE_TIME = System.now().addMinutes(-1);
	public final static Date LAST_7_DAYS = System.today().addDays(-7);
	public final static String G2_CROWD_LABEL = 'g2 crowd';
	public final static String LEADSOURCE_ABC = 'Added by Client';
	public final static String LEADSOURCE_SRC_ERROR = 'Sourcing Error';
	public final static String LEADSOURCE_OUTBOUND = 'Outbound';
	public final static String LEADSOURCE_IB_CHAT = 'inbound chat';
	public final static String LEADSOURCE_LIVE_CHAT = 'Live Chat';
	public final static String LEADSOURCE_IB_PHONE = 'inbound phone';
	public final static String LEADSOURCE_FT_SB = 'fitsmallbusiness';
	public final static String LEADSOURCE_PR = 'partner referral';
	public final static String LEADSOURCE_API = '_api';
	public final static String LEADSOURCE_CR = 'Customer Referral';
	public final static String LEADSOURCE_P2P = 'P2P Referral';
	public final static String LEADSOURCE_LEGALZOOM = 'legalzoom';
	public final static String LEADSOURCE_XERO_PART = 'xero_partnership';
	public final static String LEADSOURCE_XERO_MIGRATION_SMB = 'xero_migration_smb';
	public final static String LEADSOURCE_BKK_EXPRESS = 'bookkeeping express';
	public final static String LEADSOURCE_BKK_360 = 'bookkeeper 360';
	public final static String LEADSOURCE_BKK_LEAD_PASS = 'bookkeeper360_lead_pass';
	public final static String LEADSOURCE_BKK_EXP_LEAD_PASS = 'bookkeepingexpress_lead_pass';
	public final static String LEADSOURCE_CLARUS = 'clarus';
	public static final String LEADSOURCE_WEB = 'web';
	public static String RINGLEAD_ROUTING_PROCESSED = 'sf_processed';

	public final static String LABEL_INTEGRATION = 'integration';
	public final static String LABEL_ADMIN = 'admin';
	public final static Id ID_CURRENT_USER = UserInfo.getUserId();
	public final static Id ID_INTEGRATION_USERS_ROLE = Id.ValueOf(Label.Integration_Users_Role_Id);
	public final static Id ID_ZP_SYSTEM_ADMINISTRATOR = '00eG0000001ItJjIAK';
	public final static String ID_MARKETO = '00516000006bBtV';
	public final static String LABEL_LEAD_CAMP_OTHER = 'Other';
	public final static String STRING_N_A = 'N/A';
	// This is needed because leads are created from ZP Company and set first name as NA
	public final static String STRING_NA = 'NA';
	public final static String STRING_UNKNOWN = 'Unknown';
	public final static String MQL_REASON_IB_CHAT = 'Inbound Chat';
	public final static String MQL_REASON_SALES_GEN = 'Sales Generated';
	public final static String MQL_REASON_SAL = 'SAL';
	public final static String MQL_REASON_IN_APP_JOIN_REQ = 'In-App Join Request';
	public final static String MQL_REASON_SIGN_UP_RAMP_INTENT = 'Sign-Up Ramp Intent';
	public final static String MQL_REASON_SIGN_UP_INT = 'Sign-up program interest';
	public final static String TRUE_AS_STRING = 'true';
	public final static String LEADCREATION_OFFER_CHAT = 'Chat';
	public final static String LEADCREATION_OFFER_IB_PHONE = 'Inbound Phone';
	public final static String LEADCREATION_OFFER_ABC = 'Added by Client';
	public final static String LEADCREATION_OFFER_G2 = 'G2 crowd';
	public final static String LEADCREATION_OFFER_3RD_PARTY = '3rd Party Integration';
	public final static String LEADCREATION_OFFER_INTR_DEMO = 'Interactive Demo';
	public final static String LEADCREATION_OFFER_PR = 'Partner Referral';
	public final static String LEADCREATION_OFFER_CR = 'Customer Referral';
	public final static String LEADCREATION_OFFER_P2P = 'P2P Referral';
	public final static String LEADCREATION_OFFER_API_PR = 'API Provisioning';
	public final static String LEADCREATION_OFFER_SALES_GNR = 'Sales Generated';
	public final static String LEADCREATION_OFFER_PROD_GEN = 'Product Registration';
	public final static String LEADCREATION_OFFER_LIST_UPL = 'List Upload';
	public final static String LEADCREATION_OFFER_PROACTIVE_CHAT = 'Proactive Chat';
	public final static String REFERRAL_TYPE_UR = 'userrole';
	public final static String REFERRAL_TYPE_US = 'user';
	public final static String REFERRAL_TYPE_PRU = 'partnerreferraluser';
	public final static String SALES_ROLE = 'sales';
	public final static String MDR_ROLE = 'mdr';
	public final static String SDR_ROLE = 'sdr';
	public final static String SB_ROLE = 'sb';
	public final static String PREFIX_QUEUE = '00G';
	public final static String LABEL_COMPANY = 'Company';
	public final static String LABEL_RESELLER = 'Reseller';
	public final static String COLAB_TYPE_EXT_ACC = 'External Accountant'; //Collaborator Type
	public final static String COLAB_TYPE_PAY_ADM = 'Payroll Admin'; //Collaborator Type
	public final static String LABEL_INV_PHONE_EXC = 'Invalid Phone Number Exception';
	public final static String LABEL_MDR_USR_ROLE = 'sales_mdr_xx_xx';
	public final static String LABEL_BDR_USR_ROLE = 'sales_bdr_xx_xx';
	public final static String LABEL_SDR_MM_MGR_USR_ROLE = 'sales_sdr_mm_mgr_xx';
	public final static String LABEL_SDR_MM_USR_ROLE = 'sales_sdr_mm_xx';
	public final static String LABEL_SDR_PARTNER_MGR_USR_ROLE = 'sales_sdr_partner_mgr_xx';
	public final static String LABEL_SDR_PARTNER_USR_ROLE = 'sales_sdr_partner_xx';
	public final static String LABEL_PARTNER_AE_USR_ROLE = 'sales_partner_ae_xx';
	public final static String LABEL_TEST_GRP = 'Test';
	public final static String LABEL_CONTROL_GRP = 'Control';
	public final static String A_B_TEST_NAME = 'FY21Q2 EE Split';
	public final static String SLACK_CHANNEL_MDR = 'MDR';
	public final static String SLACK_CHANNEL_SDR = 'SDR';
	public final static String SLACK_CHANNEL_PARTNER = 'Partner';
	public final static String SLACK_CHANNEL_SB = 'SB';
	public final static String LABEL_A_B_6_TEST = 'Direct_6_Test';
	public final static String LABEL_LEAD_ROUTER_ACC_MDR = 'Accountant MDR Rotator [Lead Routing]';
	public final static String LABEL_LEAD_ROUTER_MDR = 'MDR Rotator [Lead Routing]';
	public final static String LABEL_LEAD_ROUTER_SB = 'SB Rotator [Lead Routing]';
	public final static String LABEL_LEAD_ROUTER_XERO_AE = 'Xero AE Rotator [Lead Routing]';
	public final static String LABEL_LEAD_ROUTER_PARTNER_AE = 'Partner AE [Lead Routing]';
	public final static String MQL_FLAG_YES = 'Yes';
	public final static String MQL_FLAG_NO = 'No';
	public final static String LEAD_SRC_DET_AFFILIATES = 'Affiliates';
	public final static String LABEL_YES = 'Yes';
	public final static String PHONE_PREFIX = '+1';
	public final static String LEAD_HOLD_OUT = 'Held Out';
	public final static String LEAD_EXPOSED = 'Exposed';
	public final static String LEAD_ONBOARDING_FLOW = 'In-app';
	public final static String PARTNER_ROLE = 'partner';
	public final static String LEADSOURCE_ARDIUS_API = 'ardius_api';
	public final static String LEADSOURCE_XENDOO = 'xendoo';
	public final static String LEADSOURCE_XERO_MIGRATION_PARTNER = 'xero_migration_partner';
	public final static String LEADSOURCE_XERO_PROVISIONING_PARTNER = 'xero_provisioning_partners';
	public final static String LEADSOURCE_SOFTWARE_SUGGEST = 'Software Suggest';
	public final static String LEADSOURCE_SOFTWARESUGGEST = 'softwaresuggest';
	public final static String LEADSOURCE_EDUCATION = 'Education';
	public final static String ADDED_CLIENT = 'Added Client';
	public final static String COUNT_ALIAS = 'cnt';
	public final static String TYPE_ALIAS = 'type';
	public final static String REF_TYPE_USER_ROLE = 'UserRole';
	public final static String REF_TYPE_PARTNER_REF_USER = 'PartnerReferralUser';
	public static final String MARKETING_CHANNEL_BD = 'BD';
	public static final String EMBEDDED_CON_EXIST_ERR_MESSAGE = 'Embedded Company Contact Exists with same Email. Please Select a different Email';
	public static final String INTEGRATION_USERS = System.Label.Integration_Users;
	public static final String CHILIPIPER_USER = 'ChiliPiper';
	public static final String PLATFORM_INTEGRATION_USER = 'Platform Integration User';
	public static final String PLATFORM_INTEGRATION_USER_ID = System.Label.Platform_Integration_User_Id;

	// No of days a Lead has been Dormant
	public static final Integer NO_OF_LEAD_DORMANT_DAYS = Integer.valueOf(Label.No_Of_Lead_Dormant_Days);

	//final sets/maps - from query
	public static Map<Id, User> map_UserIdToUserMap {
		get {
			if (map_UserIdToUserMap == null) {
				map_UserIdToUserMap = GlobalQueryHelper.queryActiveUsers();
			}
			return map_UserIdToUserMap;
		}
		private set;
	}
	public static final List<BusinessHours> list_BusinessHours = GlobalQueryHelper.getAllBusinessHoursList(); //--- TO DO

	//final sets/maps
	public final static Map<String, Integer> map_G2CrowdLabelToEE {
		get {
			if (map_G2CrowdLabelToEE == null) {
				Map<String, Integer> map_Result = new Map<String, Integer>{
					'Myself Only' => 1,
					'2-10 Employees' => 2,
					'11-50 Employees' => 11,
					'51-200 Employees' => 51,
					'201-500 Employees' => 201,
					'501-1000 Employees' => 501,
					'1001-5000 Employees' => 1000,
					'5001-10,000 Employees' => 5000,
					'10,001+ Employees' => 5000
				};
				return map_Result;
			}
			return map_G2CrowdLabelToEE;
		}
	}

	//Status order for Company Leads
	public final static Map<String, Integer> map_CompLeadStatusOrder {
		get {
			if (map_CompLeadStatusOrder == null) {
				Map<String, Integer> map_Result = new Map<String, Integer>{
					'Raw' => 1,
					'AQL' => 2,
					'MQL' => 3,
					'Attempting Contact' => 4,
					'Engaged' => 5,
					'Discovery Call Scheduled' => 6,
					'Discovery' => 7,
					'Qualified' => 8,
					'Commit' => 9,
					'SAL' => 10,
					'Future Opportunity' => 11,
					'Unqualified' => 12,
					'Back to Nurture' => 13
				};

				return map_Result;
			}
			return map_CompLeadStatusOrder;
		}
	}

	//Status order for Reseller Leads
	public final static Map<String, Integer> map_ResLeadStatusOrder {
		get {
			if (map_ResLeadStatusOrder == null) {
				Map<String, Integer> map_Result = new Map<String, Integer>{
					'Raw' => 1,
					'AQL' => 2,
					'MQL' => 3,
					'Attempting Contact' => 4,
					'Engaged' => 5,
					'Discovery Call Scheduled' => 6,
					'Discovery' => 7,
					'Qualified' => 8,
					'Commit' => 9,
					'SAL' => 10,
					'Future Opportunity' => 11,
					'Unqualified' => 12
				};

				return map_Result;
			}
			return map_ResLeadStatusOrder;
		}
	}

	// Number of Clients Bucket (Range) to Number of Clients
	public final static Map<String, Integer> map_ClientsBucketRangeToNoOfClients {
		get {
			if (map_ClientsBucketRangeToNoOfClients == null) {
				Map<String, Integer> map_Result = new Map<String, Integer>{ '0-2' => 1, '3-9' => 6, '10-24' => 17, '25-49' => 37, '50-249' => 150, '250+' => 250 };

				return map_Result;
			}
			return map_ClientsBucketRangeToNoOfClients;
		}
	}

	public final static Set<String> set_FakeEmails {
		get {
			if (set_FakeEmails == null) {
				Set<String> set_Result = new Set<String>{ 'test@gusto.com', 'tenable.com' };
				return set_Result;
			}
			return set_FakeEmails;
		}
	}

	public final static Set<String> set_ExcludeStatusRevert {
		get {
			if (set_ExcludeStatusRevert == null) {
				Set<String> set_Result = new Set<String>{ 'Future Opportunity', 'Unqualified', 'Back to Nurture' };
				return set_Result;
			}
			return set_ExcludeStatusRevert;
		}
	}

	public final static Set<String> set_ExcludeRouting {
		get {
			if (set_ExcludeRouting == null) {
				Set<String> set_Result = new Set<String>{ 'Future Opportunity', 'Unqualified', 'Back to Nurture', 'Raw', 'AQL' };
				return set_Result;
			}
			return set_ExcludeRouting;
		}
	}

	public final static Set<String> set_ReMQLStatusCheck {
		get {
			if (set_ReMQLStatusCheck == null) {
				Set<String> set_Result = new Set<String>{ 'Future Opportunity', 'AQL', 'Back to Nurture' };
				return set_Result;
			}
			return set_ReMQLStatusCheck;
		}
	}

	//Record Type Id to Name map
	public final static Map<Id, String> map_RecordTypeToId {
		get {
			if (map_RecordTypeToId == null) {
				Map<Id, String> map_Result = new Map<Id, String>{ COMPANY_LEAD_RT_ID => 'Company', RESELLER_LEAD_RT_ID => 'Reseller' };

				return map_Result;
			}
			return map_RecordTypeToId;
		}
	}

	//used for Lead Routing Entry Criteria
	public final static Set<String> set_LeadQualificationStatuses {
		get {
			if (set_LeadQualificationStatuses == null) {
				Set<String> set_Result = new Set<String>{ 'MQL', 'Attempting Contact', 'Engaged', 'Discovery Call Scheduled', 'Discovery', 'Qualified', 'Commit', 'SAL' };
				return set_Result;
			}
			return set_LeadQualificationStatuses;
		}
	}

	public final static Set<String> set_TestCompanies {
		get {
			if (set_TestCompanies == null) {
				Set<String> set_Result = new Set<String>{ 'test' };
				return set_Result;
			}
			return set_TestCompanies;
		}
	}

	//currently it's only Herko - but considered if any eddition
	public final static Set<Id> set_LeadCreationUsers {
		get {
			if (set_LeadCreationUsers == null) {
				Set<Id> set_Result = new Set<Id>{ Id.ValueOf('00516000005BehJ') };
				return set_Result;
			}
			return set_LeadCreationUsers;
		}
	}

	// Role Id - Integration Users
	public final static Set<Id> set_LeadCreationUserRoles {
		get {
			return set_LeadCreationUserRoles == null ? new Set<Id>{ ID_INTEGRATION_USERS_ROLE } : set_LeadCreationUserRoles;
		}
	}

	public final static Set<String> set_LdCreationOffer {
		get {
			if (set_LdCreationOffer == null) {
				Set<String> set_Results = new Set<String>{ 'List Upload', 'Sales Generated', 'Added by client', 'Event', 'BD Lead pass', '3rd party integration', 'Inbound Phone' };
				return set_Results;
			}
			return set_LdCreationOffer;
		}
	}

	public final static Set<String> set_Exclude_EmailDomains {
		get {
			if (set_Exclude_EmailDomains == null) {
				Set<String> set_Result = new Set<String>{
					'gmail.com',
					'cox.net',
					'comcast.net',
					'aol.com',
					'hotmail.com',
					'earthlink.com',
					'outlook.com',
					'me.com',
					'mac.com',
					'verizon.net',
					'yahoo.com',
					'bellsouth.net',
					'mail.com',
					'att.net',
					'msn.com',
					'charter.net',
					'earthlink.net',
					'icloud.com',
					'sbcglobal.net',
					'@bench',
					'@indinero'
				};
				return set_Result;
			}
			return set_Exclude_EmailDomains;
		}
	}

	public final static List<String> list_AllowStatus {
		get {
			if (list_AllowStatus == null) {
				List<String> list_Results = new List<String>{ '', 'Raw', 'AQL' };
				return list_Results;
			}
			return list_AllowStatus;
		}
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

	public final static List<String> list_AllowStatusFalseSAL {
		get {
			if (list_AllowStatusFalseSAL == null) {
				List<String> list_Results = new List<String>{ '', 'Raw', 'AQL', 'MQL', 'SAL', 'Future Opportunity', 'Back to Nurture' };
				return list_Results;
			}
			return list_AllowStatusFalseSAL;
		}
	}

	public static final String CAMPAIGN_TYPE_WEBINAR = 'Webinar';
	public static final String CAMPAIGN_TYPE_EVENT = 'Event';
	public static final String CAMPAIGN_TYPE_GATED_CONTENT = 'Gated Content';
	public static final String CAMPAIGN_TYPE_3RD_PARTY_WEBINAR = '3rd Party Webinar';
	public static final String CAMPAIGN_TYPE_TRAINING = 'Training';
	public static final String CAMPAIGN_TYPE_WEBSITE = 'Website';
	public static final String CAMPAIGN_TYPE_SUBSCRIPTION = 'Subscription';

	public static final Set<String> set_RecentSourceCampaignTypes = new Set<String>{
		CAMPAIGN_TYPE_WEBINAR,
		CAMPAIGN_TYPE_EVENT,
		CAMPAIGN_TYPE_GATED_CONTENT,
		CAMPAIGN_TYPE_3RD_PARTY_WEBINAR,
		CAMPAIGN_TYPE_TRAINING,
		CAMPAIGN_TYPE_WEBSITE,
		CAMPAIGN_TYPE_SUBSCRIPTION
	};
}