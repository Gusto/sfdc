/***
    Created by : Deepika Saini
    Created Date : 03/15/2021
    Description: Benefit Order related Utilities for reuse
**/
public class CarrierOrderUtil { 
	
	public static final String BEFORE_MONTH = 'Before Month';
	public static final String AFTER_MONTH = 'After Month';
	public static final String BEFORE_DAYS = 'Before Days';
	public static final String AFTER_DAYS = 'After Days';
	public static final String Name_BASIC = 'BASIC';
	public static final String BEFORE_EVENT = 'Before';
	public static final String AFTER_EVENT = 'After';
	public static final String SAME_EVENT = 'Same';
	public static final String PARTNER_TYPE_TADA = 'TAdA';
	
	public static final String CO_STATUS_APPROVED_PENDING_EE_AUDIT = 'Approved Pending EE Audit';
	public static final String CO_STATUS_READY_FOR_CONFIRMATION = 'Ready for Confirmation';
	public static final String IMPLEMENTATION_STAGE_READY_FOR_QUALIFICATION = 'Ready For Qualification';
	public static final String IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION = 'Ready for Early Submission';
	public static final String IMPLEMENTATION_STAGE_EARLY_SUBMISSION = 'Early Submission';
	public static final String IMPLEMENTATION_STAGE_PENDING_ER = 'Pending ER Signature';
	public static final String CO_APPROVED_PENDING_TERMINATION = 'Approved Pending Carrier Termination';

	public static final String CO_ORDER_TYPE_TADA_PRE_OE_SETUP = 'TAdA: Pre OE Setup';
	public static final String CO_STATUS_APPROVED = 'Approved';
	public static final String CO_STATUS_READY_FOR_SUBMISSION_PREP = 'Ready for Submission Prep';
	public static final String CO_STATUS_READY_FOR_OE_PREP = 'Ready for OE Prep';
	public static final String CO_STAGE_DETAIL_READY_FOR_TADA_SETUP = 'Ready for TAdA Setup';
	public static final String STAGE_PENDING_CONFIRMATION = 'Pending Confirmation';
	public static final String STAGE_SUBMISSION_PREP = 'Submission Prep';
	public static final String STAGE_CANCELLED = 'Canceled';
	public static final String STAGE_CLOSED_ADMIN = 'Closed Admin';
	public static final String CO_STAGE_DETAIL_TADA_SETUP_PENDING = 'TAdA Setup Pending';
	public static final String CO_STAGE_DETAIL_TADA_SETUP_COMPLETE = 'TAdA Setup Complete';

	public static final String ORDER_TYPE_TADA_NO_PRE_OE = 'TAdA: No Pre OE Setup';
	public static final String OPP_BENEFITS_RENEWAL = 'Benefits Renewal';
	public static final String ORDER_TYPE_NEW_TO_GUSTO = 'New to Gusto';
	public static final String ORDER_TYPE_CARRIER_SWITCH = 'Carrier Switch';	
	public static final String ORDER_TYPE_TERMINATED_ORDER = 'Terminated Order';
	public static final String ORDER_TYPE_NEW_LINE_OF_COVERAGE = 'New line of Coverage';
	public static final String ORDER_TYPE_SAME_CARRIER_PLAN_GROUP_LEVEL_CHANGES = 'Same carrier, plan/group level changes';
	public static final String ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES = 'Same carrier, NO plan/group level changes';

	public static final String TADA_BEN_TYPE_FSA_MEDICAL = 'Flexible Spending Account - Medical';
	public static final String TADA_BEN_TYPE_FSA_DEPENDENT_CARE = 'Flexible Spending Account - Dependent Care';
	public static final String TADA_BEN_TYPE_HSA = 'HSA';
	public static final String TADA_BEN_TYPE_COMMUTER = 'Commuter';

	public static final String RECTYPE_NAME_NEW_PLAN = 'New Plan';
	public static final String RECTYPE_NAME_RENEWAL = 'Renewal';
	public static final String RECTYPE_NAME_BENEFIT_CHANGE = 'Benefit Change';

	public static final Id RECTYPE_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', RECTYPE_NAME_NEW_PLAN);
	public static final Id RECTYPE_RENEWAL = Cache.getRecordTypeId('Carrier_Order__c', RECTYPE_NAME_RENEWAL);
	public static final Id RECTYPE_CHANGE = Cache.getRecordTypeId('Carrier_Order__c', RECTYPE_NAME_BENEFIT_CHANGE);

	public static final String TYPE_CARRIER_ADDED = 'Carrier Added';
	public static final String POLICY_BENEFIT_TYPE_MEDICAL = 'Medical';

	public static final String AUTOMATION_STATUS_FAILED = 'Failed';
	public static final String AUTOMATION_STATUS_COMPLETED = 'Completed';
	public static final String AUTOMATION_STATUS_SUBMITTED = 'Submitted';
	public static final String AUTOMATION_STATUS_UNABLE_TO_AUTOMATE = 'unable_to_automate';
	public static final String HI_SUBMISSION_AUTOMATION_STATUS_SUCCESS = 'Success';
	public static final String STATUS_UNABLE_TO_AUDIT = 'Unable to audit';

	public static final String DEFAULT_STATUS = (String) Schema.Benefit_Order__c.Order_Status__c.getDescribe()
		.getDefaultValue();
	public static Id REC_TYPE_BOR = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
	public static Id TTF_BC_RT_ID = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
	public static Id TTF_BR_RT_ID = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
	public static Id TTF_BN_RT_ID = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
	public static Set<String> set_TTFRecordTypes = new Set<String>{ TTF_BC_RT_ID, TTF_BR_RT_ID, TTF_BN_RT_ID };

	public static set<string> set_COExcludeStages = new Set<string>{
		STAGE_CANCELLED,
		STAGE_CLOSED_ADMIN
	};

	public static set<string> set_COExcludeStagesForClosed = new Set<string>{
		CO_APPROVED_PENDING_TERMINATION,
		CO_STATUS_APPROVED_PENDING_EE_AUDIT,
		CO_STATUS_APPROVED,
		STAGE_CANCELLED,
		STAGE_CLOSED_ADMIN
	};

	public static Set<String> set_EarlySubmissionImplementationStages = new Set<String>{
	  IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION,
	  IMPLEMENTATION_STAGE_EARLY_SUBMISSION
	};
	
	public static String CO_SUBMISSION_AUTOMATED_VIA_HI = 'HI Submission';
	public static String CO_SUBMISSION_AUTOMATED_VIA_BOT = 'Bot Submission';
	public static String CO_SUBMISSION_AUTOMATED_VIA_HI_AND_BOT = 'HI/Bot Submission';
	public static String CARRIER_IMPLEMENTATION_QUEUE = 'Carrier Implementation Queue';
	
	public static String ACTIVE = 'Active';
	public static String AUTOMATION_QUEUE = 'Automation Queue';
	public static String YES = 'Yes';
	public static String NO = 'No';
	public static String PICKLIST_VALUE_YES = 'Y';
	public static String PICKLIST_VALUE_NO = 'N';
	public static String CARRIER_ORDER_QUEUE = 'Carrier Operations';

	public static String NEW_PLAN_VARIATION_NUM_1='New_Plan_Variation_Num1__c';
	
	/*
	* @author:         Anurag Gautam
	* @description:    Populate Benefit Type changes
	* @parm:           NA
	* @return:         NA
	*/
	public static List<Carrier_Order__c> getCarrierOrders(Set<Id> set_CarrierOrderIds) {
		return [
			SELECT
				Name,
				Implementation_Stage__c,
				Stage_Detail__c,
				Order_Assignment__c,
				Carrier__r.Carrier_Id__c,
				Carrier__r.State__c,
				Carrier__r.Id__c,
				Submitted_Completed_Datetime__c,
				Days_Until_Effective_Date__c,
				Group_Number__c,
				Eligible_for_Submission_Automation__c,
				Sent_to_HI_for_Submission__c,
				Benefit_Order__r.Parent_Benefit_Order__c,
				Benefit_Order__r.Is_Multi_EIN__c,
				Benefit_Order__c,
				Effective_Date__c,
				Follow_Up_Date__c,
				Parent_Carrier_Order__c,
				Is_Multi_EIN__c,
				Is_Order_Eligible_For_Sub_Automation__c,
				Benefit_Types__c, 
				HI_Carrier_Id__c, 
				Order_Playable_Date__c,
				Submission_Deadline_Date__c,
				Waiting_Period_Change__c,
				Contribution_Change__c,
				Plan_Change__c,
				No_Of_Submission_Automation_Attempts__c,
				OwnerId,
				(SELECT Id FROM Policies__r),
				(SELECT Id,Contribution_Change__c,Carrier_Order__c, Benefits_selected_Carrier__r.Id__c, Lines_Of_Coverage__c FROM QA_Lines_Of_Coverage__r),
				Benefit_Order__r.Transition_To_Fulfillment__r.Do_they_have_affiliates__c
			FROM Carrier_Order__c
			WHERE Id IN :set_CarrierOrderIds
		];
	}
}