trigger BenefitOrderTrigger on Benefit_Order__c (before insert, after insert,before update, after update) {

    if (BenefitOrderHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new BenefitOrderHelper().run();
}