trigger ZPCompanyMigrationTrigger on ZP_Company_Migration__c(
	after delete,
	after insert,
	after undelete,
	after update,
	before delete,
	before insert,
	before update
) {
	if (!UtilitiesFactory.isOverride('ZPCompanyMigrationTrigger')) {
		// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
		if (FeatureManagement.checkPermission('Bypass_Triggers') || ZPCompanyMigrationTriggerHelper.skipTrigger) {
			return;
		}
		new ZPCompanyMigrationTriggerHandler().run();
	}
}