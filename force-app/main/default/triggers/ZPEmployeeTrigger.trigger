trigger ZPEmployeeTrigger on ZP_Employee__c (before insert, before update,after insert, after update){
    if(FeatureManagement.checkPermission('Bypass_Triggers') || ZPEmployeeTriggerHelper.skipTrigger) {
        return;
    }
        
    new ZPEmployeeTriggerHandler().run();
}