@isTest
private class FWRoleSetupCtrlTest {
	@TestSetup
	static void setupData() {
	}

	static testMethod void roleSetup() {
		FWRoleSetupCtrl roleSetupObj = new FWRoleSetupCtrl();
		roleSetupObj.SaveSetup();
		roleSetupObj.objRegionPOD.Team__c = 'Qualification';
		roleSetupObj.SaveSetup();
		roleSetupObj.strSkillType = 'Core';
		roleSetupObj.SaveSetup();
		roleSetupObj.list_SelectedSetupCriteria.add(new SelectOption('Region', 'Region'));
		roleSetupObj.list_SelectedSetupCriteria.add(new SelectOption('State', 'State'));
		roleSetupObj.list_SelectedSetupCriteria.add(new SelectOption('Carrier POD', 'Carrier POD'));
		roleSetupObj.list_SelectedSetupCriteria.add(new SelectOption('Order Type', 'Order Type'));
		roleSetupObj.list_SelectedSetupCriteria.add(new SelectOption('Tier', 'Tier'));
		roleSetupObj.list_SelectedSetupCriteria.add(new SelectOption('Partner', 'Partner'));
		roleSetupObj.list_SelectedSetupCriteria.add(new SelectOption('Tada', 'Tada'));
		roleSetupObj.SaveSetup();

		List<Skill_Criteria_Setup__c> lstSetup = [SELECT id FROM Skill_Criteria_Setup__c LIMIT 1];
		if (lstSetup.size() > 0) {
			ApexPages.currentPage().getParameters().put('setupId', lstSetup[0].Id);
			roleSetupObj.list_SelectedSetupCriteria.add(new SelectOption('Tada', 'Tada'));
			roleSetupObj.updateSetup();
			roleSetupObj.deleteSetup();
		}
	}
}