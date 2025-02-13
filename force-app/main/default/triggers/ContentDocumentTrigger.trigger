trigger ContentDocumentTrigger on ContentDocument (before delete) {

    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || ContentDocumentTriggerHelper.skipTrigger || TriggerBypass__c.getInstance().ContentDocumentTrigger__c ) {return;}

	new ContentDocumentTgrHandler().run();
}