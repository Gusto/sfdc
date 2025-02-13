trigger PayrollAuditTrigger on Payroll_Audit__c(before insert, before update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || PayrollAuditTriggerHelper.skipTrigger)
		return;
	else
		new PayrollAuditTriggerHandler().run();
}