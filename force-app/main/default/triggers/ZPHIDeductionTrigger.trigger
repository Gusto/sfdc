/***************************************************
Test Classes : ZPHIDeductionTriggerHelperTest  
****************************************************/
trigger ZPHIDeductionTrigger on ZP_HI_Deduction__c (before delete, before insert, before update) {

    if (ZPHIDeductionTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }
    
    new ZPHIDeductionTriggerHelper().run(); 
}