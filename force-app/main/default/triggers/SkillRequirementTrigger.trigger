trigger SkillRequirementTrigger on SkillRequirement (before insert, after insert) {
	if (
		SkillRequirementTriggerHelper.blnSkipTrigger ||
		FeatureManagement.checkPermission('Bypass_Triggers')
	) {
		return;
	}
	
	new SkillRequirementTriggerHandler().run();
}