/**
    Created by : Anand Singh
    Created Date : 20/10/2021
    Description: Trigger on Region_POD_mapping__c
**/
trigger RegionPODMappingTrigger on Region_POD_mapping__c(before insert, after insert, before update, after update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || RegionPODMappingTriggerHelper.blnSkipTrigger) {
		return;
	}
	new RegionPODMappingTriggerHandler().run();
}