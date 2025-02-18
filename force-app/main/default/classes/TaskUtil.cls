public class TaskUtil {
	// RecordTypeId:
	public final static Id TASK_EMAIL_RT_ID = Cache.getRecordTypeId('Task', 'Email');
	public final static Id TASK_STANDARD_RT_ID = Cache.getRecordTypeId('Task', 'Standard');
	public final static Id TASK_DEMO_RT_ID = Cache.getRecordTypeId('Task', 'Demo/Pitch');
	public final static Id TASK_DEMO_PITCH_RT_ID = Cache.getRecordTypeId('Task', 'Demo/Pitch');
	public final static Id TASK_CALL_RT_ID = Cache.getRecordTypeId('Task', 'Call');
	public static final Id TASK_CHAT_RT_ID = Cache.getRecordTypeId('Task', 'Chat');
	public static final Id TASK_ADVISING_CALL_RT_ID = Cache.getRecordTypeId('Task', 'Advising Call');
	public static final String TASK_BENEFIT_FULFILLMENT_RT_ID = Cache.getRecordTypeIdFromDeveloperName('Task', 'Benefits_Fulfillment');
	public final static Id ARDIUS_TICKET_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius');

	// Status:
	public final static String TASK_STATUS_CONNECT = 'Connect';
	public final static String TASK_STATUS_COMPLETE = 'Completed';
	public static final String TASK_STATUS_IN_PROGRESS = 'In Progress';
	public static final String TASK_STATUS_NOT_STARTED = 'Not Started';
	public final static String TASK_STATUS_OPEN = 'Open';
	public static final String TASK_STATUS_DETAIL_REOPENED = 'Reopened';
	public final static String TASK_STATUS_VOICEMAIL = 'Voicemail';
	public final static String TASK_STATUS_EMAIL_SENT = 'Sent';

	// Type:
	public final static String TASK_TYPE_EMAIL = 'Email';
	public final static String TASK_TYPE_CALL = 'Call';
	public static final String TASK_TYPE_PRESENTATION_VIEWED = 'Presentation Viewed';
	public static final String TASK_TYPE_DEMO = 'Demo';
	public static final String TASK_TYPE_PITCH_W_O_DEMO = 'Pitch w/o Demo';
	public static final String TASK_TYPE_PITCH = 'Pitch';
	public static final String TASK_TYPE_AUTOMATED_MAIL = 'Automated Email';
	public static final String TASK_TYPE_INBOUND_CALL = 'Inbound Call';
	public static final String TASK_TYPE_OUTBOUND_CALL = 'Outbound Call';
	public static final String TASK_TYPE_OUTBOUND = 'Outbound';
	public static final String TASK_TYPE_INBOUND = 'Inbound';
	public static final String TASK_TYPE_FOLLOW_UP = 'Follow Up';
	public static final String TASK_TYPE_CARRIER_COMMUNICATION = 'Carrier Communication';

	// Priority:
	public static final String TASK_PRIORITY_LOW = 'Low';
	public static final String TASK_PRIORITY_NORMAL = 'Normal';

	public static final String TASK_DESCRIPTION_READ_MORE_AT = 'Read more at ';
	public static final String TASK_SUBJECT_CALLBACK = 'Callback';

	public static final String COMMA = ',';
	public static final String SEMI_COLON = ':';
	public static final String SQUARE_BRACKET_OPEN = '[';
	public static final String SQUARE_BRACKET_CLOSE = ']';

	// User:
	public static final String USER_TYPE_STANDARD = 'Standard';
	public static final String USER_ROLE_EXEC = 'exec';

	// Subject
	public static final String TASK_SUBJECT_FILLED_OUT_FORM = 'Filled Out Form';
	public static final String TASK_SUBJECT_REQUESTED = 'Customer Requested Revisions-';
	public static final String TASK_SUBJECT_DECLARATION_DRAFT = 'Declaration Draft';
	public static final String TASK_SUBJECT_EXECUTIVE_DOCUMENTATION = 'Executive Documentation';
	public static final String TASK_SUBJECT_LEAD_REVIEW = 'Lead Review';
	public static final String TASK_SUBJECT_PEER_REVIEW = 'Peer Review';
	public static final String TASK_SUBJECT_REVISION_NEEDED = 'Revisions';
	public static final String TASK_SUBJECT_APPROVAL_CALL = 'Approval Call - ';
	public static final String TASK_FEATURE_REQUEST = 'TSK_Approval_Call';
	public static final String TASK_RD_EVALUATION_CALL = 'R&D Evaluation Call';

	public static final String USER_PROFILE_NAME_BENEFITS_CARE = 'Benefits Care';
	public static final String USER_PROFILE_NAME_PAYROLL_CARE = 'Payroll Care';
	public static final String USER_PROFILE_NAME_TAX_RES = 'Tax Res';
	public static final String USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR = 'ZP System Administrator';
	public static final String USER_PROFILE_NAME_GUSTO_INTEGRATION_PROFILE = 'Gusto Integration Profile';
	public static final String USER_PROFILE_NAME_GUSTO_DIRECT_MDR = 'Gusto Direct MDR';
	public static final String USER_PROFILE_PARTNER_AE = '_del_ZP Partner AE';
	public static final String USER_PROFILE_SDR = '_del_ZP SDR';
	public static final String USER_PERMISSION_SET_TASK_RECORD_TYPE_UPDATE = 'TaskRecordTypeUpdate';

	public static final String USER_NAME_MARKETO = 'marketo';
	public static final String USER_ROLE_SALES = 'sales';
	public final static String USER_ROLE_NAME_SALES_BDR_XX_XX = 'sales_bdr_xx_xx';
	public static final String USER_ROLE_NAME_SALES_MDR_XX_XX = 'sales_mdr_xx_xx';
	public final static String USER_ROLE_NAME_SALES_SDR_MM_MGR_XX = 'sales_sdr_mm_mgr_xx';
	public final static String USER_ROLE_NAME_SALES_SDR_MM_XX = 'sales_sdr_mm_xx';
	public final static String USER_ROLE_NAME_SALES_SDR_PARTNER_MGR_XX = 'sales_sdr_partner_mgr_xx';
	public final static String USER_ROLE_NAME_SALES_SDR_PARTNER_XX = 'sales_sdr_partner_xx';
	public static final String USER_ROLE_NAME_SALES_SB_IB_XX = 'sales_sb_ib_xx';
	public static final String USER_ROLE_NAME_SALES_SB_OB_XX = 'sales_sb_ob_xx';
	public static final String USER_ROLE_NAME_SALES_SB_IB_SME = 'sales_sb_ib_sme';
	public static final String USER_ROLE_NAME_SALES_SB_OB_SME = 'sales_sb_ob_sme';
	public static final String USER_ROLE_NAME_SALES_BD_PR_XX = 'sales_bd_pr_xx';
	public static final String USER_ROLE_DEVELOPER_NAME_SALES_MM_PR_XX = 'sales_mm_pr_xx';
	public static final String USER_ROLE_PARTNER = 'partner';
	public static final String USER_ROLE_MDR = 'mdr';

	public static final String USER_ROLE_ID_PARTNER_MGR = '00E16000000z1oi';
	public static final String USER_ROLE_ID_SMALL_BIZ_INBOUND = '00E16000000zG1H';
	public static final String USER_ROLE_ID_SALES_MM_PR_XX = '00E16000000zG1R';
	public static final String USER_ROLE_ID_EXEC = '00E16000001EBXm';

	public static final String GENSYS_ANI_INTERNAL = 'Internal';
	public static final String TASK_SUBJECT_BUYERZONE_BLIND_FORM_SUBMIT = 'Buyerzoneblindformsubmit';
	public static final String DELETE_FAILED_MESSAGE = 'You dont have permission to Delete MDR or SDR tasks';
	public static final String FEED_ITEM_TYPE_TEXTPOST = 'TextPost';
	public static final String FEED_ITEM_VISIBILITY_ALLUSERS = 'AllUsers';

	// Object Prefix
	public static final String OPPORTUNITY_PREFIX = Opportunity.sObjectType.getDescribe().getKeyPrefix();
	public static final String LEAD_PREFIX = Lead.sObjectType.getDescribe().getKeyPrefix();
	public static final String CASE_PREFIX = Case.sObjectType.getDescribe().getKeyPrefix();
	public static final String CONTACT_PREFIX = Contact.sObjectType.getDescribe().getKeyPrefix();
	public static final String ACCOUNT_PREFIX = Account.sObjectType.getDescribe().getKeyPrefix();
	public static final String TICKET_PREFIX = Ticket__c.sObjectType.getDescribe().getKeyPrefix();
	public static final String USER_PREFIX = User.sObjectType.getDescribe().getKeyPrefix();

	//Strings
	public static final String DELETE_EXCEPTION = 'Deleting Tasks is not allowed';
	public static final String OUTREACH_APPLICATION = 'Outreach Application';

	public static final String ARDIUS_TASK_TEMPLATE = 'Ardius Task';
	public static final String NICE_CXONE_CLASSIC = 'NICE CXone Classic';//Added by Sujan for BPO-1990

	public final static Set<String> set_MDRTaskRecTypes {
		get {
			if (set_MDRTaskRecTypes == null) {
				Set<String> set_Result = new Set<String>{ TASK_DEMO_RT_ID, TASK_CALL_RT_ID };
				return set_Result;
			}
			return set_MDRTaskRecTypes;
		}
	}

	public final static Set<String> set_TaskStatusLeadRelatedTracking = new Set<String>{ 'Attempt', 'Voicemail', 'Connect' };

	public final static Set<String> set_TaskClosureStatus = new Set<String>{ 'Completed', 'Omitted', 'No Show', 'Sent', 'Attempt', 'Voicemail', 'Connect' };

	public final static List<String> list_ContactPhoneFields = new List<String>{ 'Normalized_Phone__c', 'Normalized_Other_Phone__c', 'Normalized_Mobile_Phone__c', 'ZP_Phone__c' };

	public final static Map<String, String> monthMap = new Map<String, String>{
		'Jan' => '01',
		'Feb' => '02',
		'Mar' => '03',
		'Apr' => '04',
		'May' => '05',
		'Jun' => '06',
		'Jul' => '07',
		'Aug' => '08',
		'Sep' => '09',
		'Oct' => '10',
		'Nov' => '11',
		'Dec' => '12'
	};

	public final static Set<String> set_LeadCreationOffers = new Set<String>{ 'List Upload', 'Sales Generated', 'Added by client', 'Event', 'BD Lead pass', '3rd party integration', 'Inbound Phone' };

	public final static Set<String> set_ValidationErrorsToIgnoreLogging = new Set<String>{ 'The owner cannot be changed once an opportunity is closed', '\'Lead Status Detail\' is required' };
	public final static String PARENT_CARRIER_CASE_CLOSED_TASK_DESCRIPTION = 'A response was received on the carrier communications case associated to this Carrier Order. Please review the carrier response and determine if action needs to be taken.';

	private static Set<Id> set_CoreCsRnDGustieIds_backup = null;
	/**
	 * @description Get Core CSM Users for Ardius
	 * @return      Set<Id>
	 */
	public static Set<Id> getCoreCSRnDGusties() {
		if (set_CoreCsRnDGustieIds_backup != null) {
			return set_CoreCsRnDGustieIds_backup;
		}

		Ardius_Configuration__c objArdiusConfiguration = Ardius_Configuration__c.getInstance();
		Set<Id> set_CoreCsRnDGustieIds = new Set<Id>();
		if (objArdiusConfiguration.Core_CS_RnD_Gustie__c != null) {
			for (String strUserId : objArdiusConfiguration.Core_CS_RnD_Gustie__c.split(';')) {
				set_CoreCsRnDGustieIds.add(strUserId);
			}
		}
		set_CoreCsRnDGustieIds_backup = set_CoreCsRnDGustieIds;
		return set_CoreCsRnDGustieIds;
	}
}