/**
 * @author Praveen Sethu
 * @description Trigger on ZP Benefits SObject
 * @since 11/26/2020
 */
trigger ZPBenefitTrigger on ZP_Benefit__c(before insert, before update, after insert, after update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	/* prettier-ignore */
	if(FeatureManagement.checkPermission('Bypass_Triggers')){ return; }
    else {
        new ZPBenefitTriggerHandler().run();
    }
}