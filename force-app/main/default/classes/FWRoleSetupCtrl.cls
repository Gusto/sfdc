/**
 * @name         FWRoleSetupCtrl
 * @author       Anand Singh
 * @date         06/01/2020
 * @description  Build Logic to Store all filter criteria by team wise and role wise
 * @test class   FWRoleSetupCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/

public class FWRoleSetupCtrl {
	public list<RoleSetupWrapper> list_RoleSetupWrapper { get; set; }
	public string strSkillType { get; set; }
	public list<System.SelectOption> list_UnselectedSetupCriteria { get; set; }
	public List<System.SelectOption> list_SelectedSetupCriteria { get; set; }
	public List<System.SelectOption> list_SkillType { get; set; }
	public Region_POD__c objRegionPOD { get; set; }
	public Skill_Criteria_Setup__c objSkillSetup { get; set; }
	public FWRoleSetupCtrl() {
		objSkillSetup = new Skill_Criteria_Setup__c();
		objRegionPOD = new Region_POD__c();
		list_UnselectedSetupCriteria = new List<System.SelectOption>();
		list_SelectedSetupCriteria = new List<System.SelectOption>();
		list_SkillType = new List<System.SelectOption>();
		list_SkillType = UtilitiesFactory.RetriveSkillType();
		list_UnselectedSetupCriteria = UtilitiesFactory.RetriveSkillSetupCriteria();
		RetriveAllSetupCriteria();
	}

	private void RetriveAllSetupCriteria() {
		list_RoleSetupWrapper = new List<RoleSetupWrapper>();
		List<Skill_Criteria_Setup__c> list_RoleSetup = Skill_Criteria_Setup__c.getall().values();
		if (list_RoleSetup != null && list_RoleSetup.size() > 0) {
			for (Skill_Criteria_Setup__c srs : list_RoleSetup) {
				RoleSetupWrapper rw = new RoleSetupWrapper();
				rw.objSkillRollSetup = srs;
				list_RoleSetupWrapper.add(rw);
			}
		}
	}

	public PageReference SaveSetup() {
		Savepoint sp = Database.setSavepoint();
		try {
			if (objRegionPOD.Team__c == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select team'));
				return null;
			}
			if (string.isBlank(strSkillType)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select skill type'));
				return null;
			}

			if (list_SelectedSetupCriteria.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select filter criteria'));
				return null;
			}
			string strSetupCriteria = null;
			if (list_SelectedSetupCriteria.size() > 0) {
				for (SelectOption sOption : list_SelectedSetupCriteria) {
					if (strSetupCriteria == null) {
						strSetupCriteria = sOption.getValue();
					} else {
						strSetupCriteria = strSetupCriteria + ';' + sOption.getValue();
					}
				}
			}
			//Save Data
			objSkillSetup.Name = objRegionPOD.Team__c + '-' + strSkillType;
			objSkillSetup.Team__c = objRegionPOD.Team__c;
			objSkillSetup.Skill_Type__c = strSkillType;
			objSkillSetup.Filter_Criteria__c = string.valueof(strSetupCriteria);
			upsert objSkillSetup;

			strSetupCriteria = null;
			ResetValue();
			RetriveAllSetupCriteria();
		} catch (Exception ex) {
			Database.RollBack(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
		return null;
	}

	public PageReference updateSetup() {
		string strSetUpId = ApexPages.currentPage().getParameters().get('setupId');
		if (string.isNotBlank(strSetUpId)) {
			objSkillSetup = [SELECT id, Name, Team__c, Filter_Criteria__c, Skill_Type__c FROM Skill_Criteria_Setup__c WHERE id = :strSetUpId LIMIT 1];
			if (objSkillSetup != null) {
				strSkillType = objSkillSetup.Skill_Type__c;
				objRegionPOD.Team__c = objSkillSetup.Team__c;
				list_SelectedSetupCriteria = new List<System.SelectOption>();
				list_UnselectedSetupCriteria = new List<System.SelectOption>();
				if (objSkillSetup.Filter_Criteria__c != null) {
					//Populated Selected value
					Set<string> set_ExcludeFromUnselected = new Set<string>();
					for (string str : objSkillSetup.Filter_Criteria__c.split(';')) {
						list_SelectedSetupCriteria.add(new SelectOption(str, str));
						set_ExcludeFromUnselected.add(str.trim());
					}
					//get original value
					list<System.SelectOption> list_SelectTempOption = UtilitiesFactory.RetriveSkillSetupCriteria();
					//Populated remaining value in Unselected Picklist
					for (SelectOption sOption : UtilitiesFactory.RetriveSkillSetupCriteria()) {
						string strVal = sOption.getValue();
						if (set_ExcludeFromUnselected.contains(strVal) == false) {
							list_UnselectedSetupCriteria.add(new SelectOption(strVal, strVal));
						}
					}
				}
			}
		}

		return null;
	}

	public PageReference deleteSetup() {
		string strSetUpId = ApexPages.currentPage().getParameters().get('setupId');
		if (string.isNotBlank(strSetUpId)) {
			delete [SELECT id, Name, Team__c, Filter_Criteria__c FROM Skill_Criteria_Setup__c WHERE id = :strSetUpId LIMIT 1];
			ResetValue();
			RetriveAllSetupCriteria();
		}

		return null;
	}
	public void ResetValue() {
		strSkillType = null;
		objRegionPOD.Team__c = null;
		objSkillSetup = new Skill_Criteria_Setup__c();
		list_SelectedSetupCriteria = new List<System.SelectOption>();
		list_UnselectedSetupCriteria = UtilitiesFactory.RetriveSkillSetupCriteria();
	}
	public class RoleSetupWrapper {
		public Skill_Criteria_Setup__c objSkillRollSetup { get; set; }
	}
}