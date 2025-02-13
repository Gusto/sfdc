/**
    Created by : David (Dato) Tsamalashvili
    Created Date : 11/24/2021
    Description: Onboarding Opportunity Creation related Utilities for reuse
**/
public class OnboardingHIOppCreationUtil {
	//HI Reasons - not to process creation
	public final static String HI_REASON_ACCOUNT_NOT_FOUND = 'Account not found';
	public final static String HI_REASON_HAS_HI_OPP = 'Account Already has benefits oppty';
	public final static String HI_REASON_NO_BILLING_STATE = 'Account has no billing state';
	public final static String HI_REASON_STATE_NOT_SUPPORTED = 'Non HI Supported state';
	public final static String HI_REASON_EE_NOT_SUPPORTED = 'Number of EE not supported for HI';
	public final static String HI_REASON_TIMEPERIOD_NOT_SUPPORTED = 'Company create over 90 days ago';
	public final static String HI_REASON_OPP_ROLE = 'Opportunity Role';
	public final static String HI_REASON_BOR_CREATED = 'BoR Opportunity Created';
	public final static String HI_REASON_BYB_CREATED = 'BYB Opportunity Created';
	public final static String HI_REASON_NP_CREATED = 'NP Opportunity Created';
	public final static String HI_REASON_NO_CONDITION_MET = 'No Condition met for NP or BoR Creation';
	public final static String HI_REASON_PAY_OPP_CL = 'Payroll Opportunity is Closed Lost';
	public final static String HI_REASON_NO_LOGIN_TIME = 'No Login info on Account';
	public final static String HI_REASON_NO_LOGIN_TIME_60_DAYS = 'No Login for over 60 days';
	public final static String ACCOUNT_ALREADY_HAS = 'Account already has ';
	public final static String OPPORTUNITY = ' Opportunity';
	//Opportunity Record Types
	public final static String HI_OPP_REC_TYPE_BOR = 'Benefits BoR';
	public final static String HI_OPP_REC_TYPE_NP = 'Benefits New Plan';
	public final static String HI_OPP_REC_TYPE_BYB = 'Benefits BYOB';
	//Opportunity Types
	public final static String HI_OPP_TYPE_BOR = 'Direct BoR';
	public final static String HI_OPP_TYPE_NP = 'Direct New Plan';
	//Onboarding Survey Interested Benefit Opt
	public static final String SMALL_GROUP_HEALTH_INSURANCE = 'SMALL_GROUP_HEALTH_INSURANCE';
	public static final String LEARNING_MORE = 'LEARNING_MORE';
	//Lead Source
	public static final String LEAD_SOURCE_BENEFITS_DURING_ONB = 'Employer BDO';
	//Stage Name
	public static final String STAGE_NAME_RAW = 'Raw';
	public final static String CLOSED_LOST_STAGE = 'Closed Lost';

	//get all record types on Opportunity
	public static Map<String, Id> getOpportunityRecordTypes() {
		Map<String, Id> map_RecordTypeNameToId;

		if (map_RecordTypeNameToId == null) {
			map_RecordTypeNameToId = new Map<String, Id>();
			//get Opportunity Describe
			Schema.DescribeSObjectResult sobjectResult = Utils.getSObjectDescribe('Opportunity');
			List<Schema.RecordTypeInfo> list_RecordTypeInfo = sobjectResult.getRecordTypeInfos();

			for (Schema.RecordTypeInfo objInfo : list_RecordTypeInfo) {
				map_RecordTypeNameToId.put(objInfo.getName(), objInfo.getRecordTypeId());
			}
		}

		return map_RecordTypeNameToId;
	}
}