trigger TaxComplianceTrigger on Tax_Compliance__c(after insert, after update) {

    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to True
    if (FeatureManagement.checkPermission('Bypass_Triggers') || TaxComplianceTriggerHelper.blnSkipTrigger || TriggerBypass__c.getInstance().TaxComplianceTrigger__c) {
        return;
    }
    new TaxComplianceTriggerHandler().run();
}