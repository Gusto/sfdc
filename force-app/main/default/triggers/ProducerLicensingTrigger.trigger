/**
 * @description  Trigger on AgentSync Producer Licensing Object
 * @author       Praveen Sethu
 * @date         03-16-2023
 * @see          ProducerLicensingTriggerHelperTest
**/
trigger ProducerLicensingTrigger on agentsync__Producer_Licensing__c (after insert, after update) {

    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || ProducerLicensingTriggerHandler.blnSkipTrigger) {return;}

	new ProducerLicensingTriggerHandler().run();
}