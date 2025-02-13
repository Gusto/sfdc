trigger HIBenefitsSignatoryTrigger on HI_Benefits_Signatory__c (after insert, after update, before insert, before update) {

    if (HIBenefitSignatoryTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new HIBenefitSignatoryTriggerHelper().run();
}