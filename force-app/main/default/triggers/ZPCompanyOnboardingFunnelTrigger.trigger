/**
 * @description  Trigger on ZP Company Onboarding Funnel
 * @author       Praveen Sethu
 * @date         01-19-2022
 * @see          ZPCompanyOnboardingTriggerHelperTest
**/
trigger ZPCompanyOnboardingFunnelTrigger on ZP_Company_Onboarding_Funnel__c(before insert, after insert, before update, after update) {
	if (!UtilitiesFactory.isOverride('ZPCompanyOnboardingFunnelTrigger')) {
		ZPCompanyOnboardingFunnelTriggerHelper handler = new ZPCompanyOnboardingFunnelTriggerHelper();

		if (ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger == false) {
			if (Trigger.isInsert && Trigger.isBefore) {
				handler.OnBeforeInsert(Trigger.new);
			} else if (Trigger.isInsert && Trigger.isAfter) {
				handler.OnAfterInsert(Trigger.newMap);
			} else if (Trigger.isUpdate && Trigger.isBefore) {
				handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
			} else if (Trigger.isUpdate && Trigger.isAfter) {
				handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
			}
		}
	}
}