/***************************************************
Purpose : We are using this class as a Post-deployment script. This class will execute only from Anonymous window. 
Create Skill on the basis of combination
(Role Type:-IA, Submission, Qualification)
Written By : Deepika Saini
//Updated by AKS Dated 23rd Oct 2020
Purpose : Create Skill for Payroll Facilitator 
****************************************************/
public with sharing class CreateSkillRecordsCtrl {
	public String strRoleName;
	public List<String> list_PayrollTransferSkill;
	public List<String> list_PayrollComplexityScore;
	public List<Boolean> list_ExceptionRequest;
	public List<String> list_PayrollProviderType;
	public List<String> list_PayrollSalesTeam;
	public static final String STR_TADA_NO_PRE_OE_SETUP = 'TAdA: No Pre OE Setup';
	public static final String STR_TADA_PRE_OE_SETUP = 'TAdA: Pre OE Setup';

	public CreateSkillRecordsCtrl(String roleName) {
		strRoleName = roleName;
		//Initialize picklist and add values
		list_PayrollTransferSkill = new List<String>();
		list_PayrollTransferSkill = getPickListValues('Skill__c', 'Payroll_Transfer_Skills__c');

		list_PayrollComplexityScore = new List<String>();
		list_PayrollComplexityScore = getPickListValues('Skill__c', 'Order_Complexity_Score__c');

		list_ExceptionRequest = new List<Boolean>{ true, false };

		list_PayrollProviderType = new List<String>();
		list_PayrollProviderType = getPickListValues('Skill__c', 'Payroll_Provider_Type__c');

		list_PayrollSalesTeam = new List<String>();
		list_PayrollSalesTeam = getPickListValues('Skill__c', 'Payroll_Sales_Team__c');
	}

	public void CreatePayrollFacilitatorRoleAndSkill() {
		//Delete Existing Skill
		List<Skill__c> list_SkillToDelete = [SELECT Id FROM Skill__c WHERE Role__r.Name = :strRoleName];

		if (list_SkillToDelete != null && list_SkillToDelete.size() > 0) {
			delete list_SkillToDelete;
		}

		//Delete Existing Role
		List<Role__c> list_RoleToDelete = [SELECT Id FROM Role__c WHERE Name = :strRoleName];
		if (list_RoleToDelete != null && list_RoleToDelete.size() > 0) {
			delete list_RoleToDelete;
		}

		//Create Role
		Role__c objRole = new Role__c();
		objRole.Name = strRoleName;
		objRole.Skill_Type__c = 'Core';
		objRole.Team__c = strRoleName;
		insert objRole;

		//Create Skill for role
		List<Skill__c> list_Skills = new List<Skill__c>();
		//Loop on Payroll Transfer
		for (String strPTType : list_PayrollTransferSkill) {
			list_Skills.addAll(getSkillsListBasedForPTSkill(strPTType, objRole));
		}
		if (list_Skills != null && list_Skills.size() > 0) {
			insert list_Skills;
		}
	}

	// get the values of the picklist used in the Skill Object
	public List<String> getPickListValues(String Objectname, String FieldName) {
		List<String> pickListValues = new List<String>();
		Schema.DescribeSObjectResult sobject_describe = Schema.getGlobalDescribe().get(ObjectName).getDescribe(); //describe the sobject
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
		List<Schema.PicklistEntry> pick_list_values = field_map.get(FieldName).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
		for (Schema.PicklistEntry a : pick_list_values) {
			//for all values in the picklist list
			if (STR_TADA_NO_PRE_OE_SETUP != a.getValue() && STR_TADA_PRE_OE_SETUP != a.getValue()) {
				pickListValues.add(a.getValue()); //add the value  to our final list
			}
		}
		return pickListValues;
	}

	public List<Skill__c> getSkillsListBasedForPTSkill(String strPTSkillType, Role__c objRole) {
		List<Skill__c> list_Skills = new List<Skill__c>();

		//Loop on Complexity Score
		for (String strScore : list_PayrollComplexityScore) {
			//Loop on Exception Request
			for (Boolean blnExceptionRequest : list_ExceptionRequest) {
				//Loop on Payroll Provider
				for (String strPTProvider : list_PayrollProviderType) {
					//Loop on Payroll Sales Team
					for (String strPTSalesTeam : list_PayrollSalesTeam) {
						Skill__c objSkill = new Skill__c();
						objSkill.Role__c = objRole.Id;
						objSkill.Payroll_Transfer_Skills__c = strPTSkillType;
						objSkill.Order_Complexity_Score__c = strScore;
						objSkill.Exception__c = blnExceptionRequest;
						objSkill.Payroll_Provider_Type__c = strPTProvider;
						objSkill.Payroll_Sales_Team__c = strPTSalesTeam;
						list_Skills.add(objSkill);
					}
				}
			}
		}

		return list_Skills;
	}
}