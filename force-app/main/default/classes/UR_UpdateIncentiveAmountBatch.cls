public class UR_UpdateIncentiveAmountBatch implements Database.Batchable<sObject>, Database.Stateful {
	public string projectId;
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery = 'select Id, Gift_card_swag_sent__c,Proposed_Incentive__c, Incentive__c, Applicable_for_Incentive__c, Incentive_Apporved_by_UXR_Admin__c from Research_Project_Detail__c where Research_Project_Master__c=:projectId and Research_Participant_Status__c=\'Attended\' and Applicable_for_Incentive__c=true and Proposed_Incentive__c>0 ';
		return Database.getQueryLocator(strQuery);
	}
	public void execute(Database.BatchableContext bc, List<Research_Project_Detail__c> scope) {
		try {
			List<Research_Project_Detail__c> lstProjectDetail = new List<Research_Project_Detail__c>();
			for (Research_Project_Detail__c rpd : scope) {
				rpd.Incentive_Date__c = Date.today();
				if (rpd.Incentive__c == null) {
					rpd.Incentive__c = rpd.Proposed_Incentive__c;
				} else {
					rpd.Incentive__c = rpd.Incentive__c + rpd.Proposed_Incentive__c;
				}
				rpd.Gift_card_swag_sent__c = true;
				rpd.Incentive_Apporved_by_UXR_Admin__c = true;
				//Rest Proposed incentive fields.
				rpd.Proposed_Incentive__c = null;
				rpd.Applicable_for_Incentive__c = false;
				lstProjectDetail.add(rpd);
			}

			if (lstProjectDetail.size() > 0) {
				UR_ResearchProjectDetailTriggerHelper.skipTrigger = true;
				update lstProjectDetail;
				UR_ResearchProjectDetailTriggerHelper.skipTrigger = false;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_UpdateIncentiveAmountBatch', 'execute', ex.getMessage(), ex.getStackTraceString());
		}
	}
	public void finish(Database.BatchableContext bc) {
	}
}