/**
 * @description  Trigger on Campaign SOject
 * @author       Veeresh Kumar
 * @date         04-18-2022
 * @see          CampaignTriggerTest
 **/
trigger CampaignTrigger on Campaign(before insert, after insert, before update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || CampaignTriggerHelper.blnSkipTrigger) {
		return;
	}
	new CampaignTriggerHandler().run();
}