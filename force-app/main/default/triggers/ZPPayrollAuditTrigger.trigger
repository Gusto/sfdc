trigger ZPPayrollAuditTrigger on ZP_Payroll_Audit__c(before insert, before update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || ZPPayrollAuditTriggerHelper.skipTrigger) {
		return;
	}

	new ZPPayrollAuditTriggerHandler().run();
}