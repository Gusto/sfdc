trigger GFTicketTrigger on GF_Ticket__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || GFTicketTriggerHelper.skipTrigger) {
		return;
	}
    new GFTicketTriggerHandler().run();
}