/*
 * @name         : HIPolicyContributionTrigger
 * @author       : Rushi Ravisaheb
 * @date         : 12-22-2021
 * @description  : Trigger on HI_Policy_Contribution__c (after insert)
 * @handler      : HIPolicyContributionTriggerHandler
 * @test classes : HIPolicyContributionTriggerHandlerTest
 */
trigger HIPolicyContributionTrigger on HI_Policy_Contribution__c(after insert) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || HIPolicyContributionTriggerHandler.skipTrigger) {
		return;
	}

	new HIPolicyContributionTriggerHandler().run();
}