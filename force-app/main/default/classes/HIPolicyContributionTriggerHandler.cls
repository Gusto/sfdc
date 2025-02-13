/*
 * @name         : HIPolicyContributionTriggerHandler
 * @author       : Rushi Ravisaheb
 * @date         : 12-22-2021
 * @description  : HI_Policy_Contribution__c Trigger Logic
 * @test classes : HIPolicyContributionTriggerHandlerTest
 */
public class HIPolicyContributionTriggerHandler extends TriggerHandler {
	public static Boolean skipTrigger = false;

	public override void afterInsert() {
		reprocessHIPolicy((Map<ID, HI_Policy_Contribution__c>) Trigger.newMap);
	}

	/*
	* @author      	: Rushi Ravisaheb
	* @description  : This method will look for any matching Id__c on HI_Policy__c 
                      that has Contribution_Scheme_Type__c set to blank
                      with Policy_Id__c on HI_Policy_Contribution__c and reprocess them.
	*/
	public void reprocessHIPolicy(Map<ID, HI_Policy_Contribution__c> map_HIPolicyContributions) {
		Set<String> set_PolicyId = new Set<String>();
		List<HI_Policy__c> list_HIPoliciesToReprocess = new List<HI_Policy__c>();

		for (HI_Policy_Contribution__c objHIPolicyContribution : map_HIPolicyContributions.values()) {
			if (objHIPolicyContribution.Company_Contribution_Id__c != null) {
				set_PolicyId.add(objHIPolicyContribution.Policy_Id__c);
			}
		}
		if (set_PolicyId.isEmpty()) {
			return;
		}

		for (Policy__c objPolicy : [SELECT Id__c FROM Policy__c WHERE Id__c IN :set_PolicyId AND Contribution_Scheme_Type__c != NULL]) {
			set_PolicyId.remove(objPolicy.Id__c);
		}
		if (set_PolicyId.isEmpty()) {
			return;
		}

		for (HI_Policy__c objHIPolicy : [SELECT Id, Processing_State__c FROM HI_Policy__c WHERE Id__c IN :set_PolicyId]) {
			objHIPolicy.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			list_HIPoliciesToReprocess.add(objHIPolicy);
		}

		try {
			if (list_HIPoliciesToReprocess.size() > 0) {
				Database.update(list_HIPoliciesToReprocess);
			}

			if (Test.isRunningTest() && HIPolicyContributionTriggerHandlerTest.blnRunCatchTest == true) {
				throw new DMLException('DML Exception occurred during testing');
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('HIPolicyContributionTriggerHelperTest', 'reprocessHIPolicy', objEx.getMessage() + ' On Line ' + objEx.getLineNumber(), objEx.getStackTraceString());
		}
	}
}