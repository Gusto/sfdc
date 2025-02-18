/**
 * @description The utility class for EmailMessageTriggerHelper
 * @author      Ankit CS
 * @date        02/03/2022
 * @see         EmailMessageTriggerHelperTest
 */
public class EmailMessageUtil {
	//Advising Email Template Names, added to filter out status update for below email templates
	public static final Set<String> ADVISING_EMAIL_TEMPLATE_SET = new Set<String>{'Advising_Intro_Email', 'Advising_Followup_Email', 'Advising_Auto_Renewal_Email', 'Advising_Final_Reminder_Email', 'Advising_Intro_Email_Scorp', 'Advising_Intro_Email_Scorp_Tadas', 'Advising_Intro_Email_Tadas', 'Level_Funded_Auto_Renewal_Advising_Email', 'Level_Funded_Transition_Advising_Check_In_Email', 'Level_Funded_Transition_Advising_Intro_Email'};

	//Case Statuses
	public static final String CASE_STATUS_NEW = 'New';

	public static final String CASE_TYPE_BYOB = 'BYOB';

	public static final String BO_STATUS_FULFILLED = 'Fulfilled';

	//Case Priority
	public static final String CASE_PRIORTY_MEDIUM = 'Medium';

	//Case Directions
	public static final String CASE_DIRECTION_INBOUND = 'Inbound';
	public static final String CASE_DIRECTION_OUTBOUND = 'Outbound';

	//Case Types
	public static final String CASE_TYPE_ONBOARDING_STATE_TAX_AUDIT = 'Onboarding State Tax Audit';
	public static final String CASE_TYPE_GARNISHMENTS_SHORT = 'garn';
	public static final String CASE_TYPE_PAYROLL_OPS_TAX_SHORT = 'ptserr';
	public static final String CASE_TYPE_UNDERWRITING_SHORT = 'underwriting';
	public static final String CASE_TYPE_GARNISHMENTS = 'Garnishments';
	public static final String CASE_TYPE_PAYROLL_OPS_TAX = 'Payroll Ops Task';
	public static final String CASE_TYPE_UNDERWRITING = 'Underwriting';
	public static final String CASE_TYPE_SPOT_CHK_CLOSE = 'EOY Spot Check - Close';
	public static final String CASE_TYPE_EOY_SPOT_CHK = 'EOY Spot Check';

	public static final String CASE_TYPE_DOC_MAPPING = 'Document Mapping';
	public static final String CASE_TYPE_COBRA = 'Cobra';

	//Case Record Types
	public static final String CASE_RT_PAYROLLOPS_AUDIT_READ_ONLY = 'PayrollOps Audit - Read Only';
	public static final String CASE_RT_PAYROLLOPS_AUDIT = 'PayrollOps Audit';
	public static final String CASE_RT_TAX_OPS = 'Tax Ops';
	public static final String CASE_RT_TAX_OPS_READ_ONLY = 'Tax Ops - Read Only';
	public static final String CASE_RT_RISK_ASSURANCE = 'Risk Assurance';
	public static final String CASE_RT_RISK_ASSURANCE_READ_ONLY = 'Risk Assurance - Read Only';
	public static final String CASE_RT_BENEFITS_CARE = 'Benefits Care';
	public static final String CASE_RT_BENEFITS_CARE_READ_ONLY = 'Benefits Care - Read Only';
	public static final String CASE_RT_BENEFITS_COMPLIANCE = 'Benefits Compliance';
	public static final String CASE_RT_PAYROLL_CARE = 'Payroll Care';
	public static final String CASE_RT_PAYROLL_CARE_READ_ONLY = 'Payroll Care - Read Only';
	public static final String CASE_RT_TAX_RES = 'Tax Res';
	public static final String CASE_RT_TAX_RES_READ_ONLY = 'Tax Res - Read Only';
	public static final String CASE_RT_PAYROLL_COMPLIANCE = 'Payroll Compliance';
	public static final String CASE_RT_PAYROLL_COMPLIANCE_READ_ONLY = 'Payroll Compliance - Read Only';
	public static final String CASE_RT_SALES_CASES = 'Sales Cases';
	public static final String CASE_RT_SALES_CASES_CLOSED = 'Sales Cases - Closed';
	public static final String CASE_RT_MODERN_BANK = 'Modern Bank';
	public static final String CASE_RT_MODERN_BANK_READ_ONLY = 'Modern Bank - Read Only';
	public static final String CASE_RT_RECOVERY_CASES = 'Recovery Cases';
	public static final String CASE_RT_PAYROLL_TRANSFER_CASE = 'Payroll Transfer Case';
	public static final String CASE_RT_BENEFITS_NEW_PLAN = 'Benefits New Plan Case';
	public static final String CASE_RT_BENEFITS_RENEWAL = 'Benefits Renewal Case';
	public static final String CASE_RT_BENEFITS_CHANGE = 'Benefits Change Case';
	public static final String CASE_RT_BENEFITS_BOR = 'Benefits BoR';
	public static final String CASE_RT_BENEFITS_BYB = 'Benefits BYB';
	public static final String CASE_RT_GEP_CX = 'GEP CX';
	public static final String CASE_RT_ENGAGEMENT = 'Engagement';

	//Record Type Ids
	public static final Id RECTYPE_BENEFITS_CARE = Cache.getRecordTypeId('Case', 'Benefits Care');
	public static final Id RECTYPE_PAYROLL_CARE = Cache.getRecordTypeId('Case', 'Payroll Care');
	public static final Id RECTYPE_BENEFITS_COMPLIANCE = Cache.getRecordTypeId('Case', 'Benefits Compliance');
	public static final Id RECTYPE_PAYROLL_COMPLIANCE = Cache.getRecordTypeId('Case', 'Payroll Compliance');
	public static final Id RECTYPE_NEW_PLAN = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
	public static final Id RECTYPE_RENEWAL = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
	public static final Id RECTYPE_CHANGE = Cache.getRecordTypeId('Case', 'Benefits Change Case');
	public static final Id RECTYPE_BOR = Cache.getRecordTypeId('Case', 'Benefits BoR');
	public static final Id RECTYPE_BYB = Cache.getRecordTypeId('Case', 'Benefits BYB');
	public static final Id RECTYPE_MF_QLE = Cache.getRecordTypeId('Case', 'MF QLE');
	public static final Id RECTYPE_SALES_CASES_CLOSED = Cache.getRecordTypeId('Case', 'Sales Cases - Closed');
	public static final Id RECTYPE_SALES_CASES = Cache.getRecordTypeId('Case', 'Sales Cases');
	public static final Id RECTYPE_RECOVERY = Cache.getRecordTypeId('Case', 'Recovery Cases');
	public static final Id RECTYPE_TAXRES = Cache.getRecordTypeId('Case', 'Tax Res');
	public static final Id RECTYPE_TAXRES_READ_ONLY = Cache.getRecordTypeId('Case', 'Tax Res - Read Only');
	public static final Id RECTYPE_GEP_CX = Cache.getRecordTypeId('Case', 'GEP CX');
	public static final Id RECTYPE_PAYROLL_TRANSFER_CASE = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
	public static final Id RECTYPE_TAX_OPS = Cache.getRecordTypeId('Case', 'Tax Ops');
	public static final Id RECTYPE_MODERN_BANK = Cache.getRecordTypeId('Case', 'Modern Bank');
	public static final Id RECTYPE_RISK_ASSURANCE = Cache.getRecordTypeId('Case', 'Risk Assurance');
	public static final Id RECTYPE_PAYROLLOPS_AUDIT = Cache.getRecordTypeId('Case', 'PayrollOps Audit');
	public static final Id RECTYPE_ENGAGEMENT = Cache.getRecordTypeId('Case', 'Engagement');
	public static final Id RECTYPE_R_D_TAX_CREDITS = Cache.getRecordTypeId('Case', 'R&D Tax Credits');
	public static final Id RECTYPE_CLIENT_RELATIONS = Cache.getRecordTypeId('Case', 'Client Relations'); 

	//Queue Names
	public static final String PAYROLL_CARE_AUTO_CLOSE_QUEUE = 'Payroll_Care_Auto_Close';
	public static final String PAYROLL_OPS_AUDIT_QUEUE = 'PayrollOps_Audit_Queue';
	public static final String ASSURANCE_QUEUE = 'Assurance_Queue';
	public static final String AUTO_SOLVE_QUEUE = 'Auto_Solve_Queue';
	public static final String ENGAGEMENT_CASES_QUEUE = 'Engagement_Cases';
	public static final String DEFAULT_ROUTING_QUEUE = 'Default_Routing_Queue';
	public static final String CLIENT_RELATIONS_QUEUE = 'Client_Relations_Cases';


	//Email Names
	public static final String GUSTO_SUPPORT_EMAIL = 'support@gusto.com';
	public static final String RENEWAL_CARRIER_EMAIL = 'renewalcarriercomms@gusto.com';
	public static final String ZP_CARRIER_OPS_EMAIL = 'carrierops@zenpayroll.com';
	public static final String GUSTO_CARRIER_OPS_EMAIL = 'carrierops@gusto.com';
	public static final String RENEWALS_EMAIL = 'renewals@gusto.com';
	public static final String NEW_PLANS_EMAIL = 'newplans@gusto.com';
	public static final String MEMBER_FULFILLMENT_EMAIL = 'memberfulfillment@gusto.com';
	public static final String BoR_TRANSFER_EMAIL = 'bor-transfer@gusto.com';
	public static final String DEVELOPER_EMAIL = Label.Developer_Email_Alias; //For developer Email-to-Case
	public static final String COBRA_EMAIL = 'cobra@gusto.com';
	public static final String RECOVERY_CASE_INBOUND_EMAIL_FILTER = '@gusto.com';

	//Integration messages
	public static final String INFO_PROCESSED = 'Information is successfully processed';

	//Reminder Email Alerts
	public static final String TAXRES_OPENCASE_FIRST_REMINDER = 'Tax_Res_Open_Case_First_Reminder';
	public static final String TAXRES_OPENCASE_SECOND_REMINDER = 'Tax_Res_Open_Case_Second_Reminder';
	public static final String TAXRES_OPENCASE_FINAL_REMINDER = 'Tax_Res_Open_Case_Final_Reminder';

	public static final String CONNECT_BROKER_QUEUE_NAME = 'Connect_Broker';

	//Ignored error messages
	public static final String INVALIDEMAILERROR = 'invalid email address';
	public static final String CLOSED_CASE_VAL_RULE = 'Cannot edit case in closed status';

	public static final String AGATHA_USER = 'Agatha Answers';

	//Pattern_Matching__mdt record developernames
	public static final String AUTO_RESPONSE_SUBJECT = 'Auto_Response_Subject';
	public static final String THANK_YOU = 'Thank_You';
	
	//Send Partner Email - Engagement 
	public static final String DEFAULT_PARTNER_TYPE = 'Default';
	public static final String EMAIL_DELIMITER = '--------------- original message ---------------';
	public static final String CHAT_STARTED = 'Chat Started';
	
	/*
	 * @author:         Ankit CS
	 * @description:    Process and return DML error messages if any
	 * @params: 		list_SaveResults- list of results, strOperationType- type of DML
	 * @return:         List<String> - list of error messages
	 */
	public static List<String> processDMLErrors(List<Database.SaveResult> list_SaveResults, String strOperationType) {
		List<String> list_Errors = new List<String>();
		for (Database.SaveResult objSaveResult : list_SaveResults) {
			if (!objSaveResult.isSuccess()) {
				for (Database.Error objError : objSaveResult.getErrors()) {
					String strErrorMessage = strOperationType + ' failed for ' + objSaveResult.getId() + '. Error: ' + objError.getMessage() + '  ';
					list_Errors.add(strErrorMessage);
				}
			}
		}

		return list_Errors;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Get Benefit Operations Email Handling Metadata
	 * @Parm        : NA
	 * @Return      : List of Benefit Operations Email Handling, meta data records
	 */
	public static List<Benefit_Operations_Email_Handling__mdt> getBenefitOpsMetadata() {
		return [SELECT Id, Process_Email_for_Universal_Inbox__c, Skip_Email_for_Universal_Inbox__c FROM Benefit_Operations_Email_Handling__mdt];
	}

	/*
	 * @author:         Ankit C
	 * @description:    Query Pattern_Matching__mdt records by record type
	 * @params:         strRecordType- Record type name
	 * @return:         Map<String, Pattern_Matching__mdt> - Map of Pattern_Matching__mdt by DeveloperName
	 */
	public static Map<String, Pattern_Matching__mdt> getPatternMatchingByRecordtype(String strRecordType) {
		Map<String, Pattern_Matching__mdt> map_PatternMatchingByName = new Map<String, Pattern_Matching__mdt>();
		for (Pattern_Matching__mdt objPatterMatching : [
			SELECT 
			Id, DeveloperName, Common_Subjects__c, Type__c, Common_Body_Patterns__c, 
			Email_Domains__c, Ignored_Subjects__c, Common_Regex__c, Max_Char_for_Email_Body__c
			FROM Pattern_Matching__mdt 
			WHERE Record_Type__c = :strRecordType AND 
			Is_Active__c = true
		]) {
			map_PatternMatchingByName.put(objPatterMatching.DeveloperName, objPatterMatching);
		}

		return map_PatternMatchingByName;
	}
}