trigger EmailMessageTrigger on EmailMessage (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	if (
		EmailMessageTriggerHelper.skipTrigger ||
		FeatureManagement.checkPermission('Bypass_Triggers')
	) {
		return;
	}
	
	new EmailMessageTriggerHandler().run();
}