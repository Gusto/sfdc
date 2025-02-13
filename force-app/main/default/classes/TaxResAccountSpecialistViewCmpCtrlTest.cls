/**
 * @name         TaxResAccountSpecialistViewCmpCtrlTest
 * @author       Anand Singh
 * @date         20th Oct 2021
 * @description  Test class for TaxResAccountSpecialistViewCmpCtrl class.
 **/
@isTest
private class TaxResAccountSpecialistViewCmpCtrlTest {
	/**
	 * @Author      :  Anand Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		skipTrigger(true);
		//Create data
		List<Role__c> list_Roles = new List<Role__c>();
		list_Roles.add(new Role__c(Name = 'Account Specialist', Team__c = 'Account Specialist'));
		insert list_Roles;

		Agency_Information__c objAgency = new Agency_Information__c(
			Name = 'Federal Unemployment',
			Active__c = true,
			State__c = 'Federal',
			Priority__c = 'Medium',
			Tax_Type__c = 'Unemployment',
			Routing_Queue__c = 'C-Queue',
			Agency_Ext_id__c = 'Agency_FED0000-001'
		);
		insert objAgency;

		Region_POD__c objCOPod = new Region_POD__c(Name = 'Pod 1 coordinator', Skill_Type__c = 'Core', Type__c = 'Agency', Team__c = 'Coordinator');
		insert objCOPod;
		Region_POD_mapping__c objPodMapping = new Region_POD_mapping__c(Agency__c = objAgency.Id, Region_POD__c = objCOPod.Id, State__c = '');
		insert objPodMapping;

		Skill__c objSkill = new TestDataFactory.SkillBuilder().setRoleId(list_Roles[0].Id).setRegionPOD(objCOPod.Id).build();
		insert objSkill;

		User objUser = new User(Id = UserInfo.getUserId());
		objUser.Out_Of_Office__c = false;
		objUser.isActive = true;
		update objUser;

		List<User> list_TaxResUser = TestUtility.createUsers('Tax Res', 1);
		list_TaxResUser[0].isActive = true;
		list_TaxResUser[0].Out_Of_Office__c = false;
		insert list_TaxResUser;

		List<User_Role__c> list_UserRoles = new List<User_Role__c>();
		list_UserRoles.add(new User_Role__c(User__c = objUser.Id, User_Skill_Type__c = 'Core', User_Skill_Team__c = 'Account Specialist'));
		list_UserRoles.add(new User_Role__c(User__c = list_TaxResUser[0].Id, User_Skill_Type__c = 'Core', User_Skill_Team__c = 'Account Specialist'));
		insert list_UserRoles;

		List<User_Skill__c> list_UserSkills = new List<User_Skill__c>();
		list_UserSkills.add(new User_Skill__c(Skill__c = objSkill.Id, User_Role__c = list_UserRoles[0].Id, Skill_Role_Name__c = 'Account Specialist', Active__c = true));
		list_UserSkills.add(new User_Skill__c(Skill__c = objSkill.Id, User_Role__c = list_UserRoles[1].Id, Skill_Role_Name__c = 'Account Specialist', Active__c = true));
		insert list_UserSkills;

		Account objAccount = TestUtility.CompanyAccount();
		List<Case> list_Cases = new List<Case>();
		list_Cases.add(TestUtility.createCase(objAccount.Id, null, 'Tax Res'));
		list_Cases.add(TestUtility.createCase(objAccount.Id, null, 'Tax Res'));
		list_Cases.add(TestUtility.createCase(objAccount.Id, null, 'Tax Res'));
		list_Cases.add(TestUtility.createCase(objAccount.Id, null, 'Tax Res'));
		list_Cases.add(TestUtility.createCase(objAccount.Id, null, 'Tax Res'));

		//Shelved Cases
		list_Cases[0].Status = 'Shelved';
		list_Cases[0].Shelved_Reason__c = 'Waiting for POA processing';
		list_Cases[0].Ownerid = objUser.Id;
		list_Cases[0].Follow_Up_Date__c = Date.today().addDays(3);
		list_Cases[0].Account_Specialist__c = objUser.Id;
		list_Cases[0].Agency_Information__c = objAgency.Id;

		list_Cases[1].Status = 'Shelved';
		list_Cases[1].Shelved_Reason__c = 'Waiting for agency confirmation';
		list_Cases[1].Ownerid = objUser.Id;
		list_Cases[1].Follow_Up_Date__c = Date.today().addDays(2);
		list_Cases[1].Account_Specialist__c = objUser.Id;
		list_Cases[1].Agency_Information__c = objAgency.Id;

		//Action Required cases
		list_Cases[2].Status = 'Ready for Research';
		list_Cases[2].Ownerid = objUser.Id;
		list_Cases[2].Account_Specialist__c = objUser.Id;
		list_Cases[2].Agency_Information__c = objAgency.Id;

		list_Cases[3].Status = 'Shelved';
		list_Cases[3].Shelved_Reason__c = 'Customer is OOO';
		list_Cases[3].Ownerid = objUser.Id;
		list_Cases[3].Follow_Up_Date__c = Date.today();
		list_Cases[3].Account_Specialist__c = objUser.Id;
		list_Cases[3].Agency_Information__c = objAgency.Id;

		list_Cases[4].Status = 'Shelved';
		list_Cases[4].Shelved_Reason__c = 'Waiting for LSI resolution';
		list_Cases[4].Ownerid = objUser.Id;
		list_Cases[4].Follow_Up_Date__c = Date.today().addDays(-1);
		list_Cases[4].Account_Specialist__c = objUser.Id;
		list_Cases[4].Agency_Information__c = objAgency.Id;
		insert list_Cases;

		skipTrigger(false);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Validate Account Specialist Positive view.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testValidateAccountSpecialistViewPositive() {
		Test.startTest();
		User_Role__c objUser = TaxResAccountSpecialistViewCmpCtrl.retrieveUserRoleData();
		TaxResAccountSpecialistViewCmpCtrl.getCustomSettings();
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_CASE_NUMBER);
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_ACCOUNT_NAME);
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_EMAIL_STATUS);
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_CASE_STATUS);
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_AGENCY_INFORMATION);
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_FOLLOWUP_DATE);
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_PARTNER_TIER);
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_CUSTOMER_TIER);
		TaxResAccountSpecialistViewCmpCtrl.sortingBy(TaxResAccountSpecialistViewCmpCtrl.SORT_BY_AGE);

		List<TaxResAccountSpecialistViewCmpCtrl.CaseWrapper> list_ActionRequiredNewCases = TaxResAccountSpecialistViewCmpCtrl.getAccountSpecialistCases(
			10,
			0,
			TaxResAccountSpecialistViewCmpCtrl.SORT_BY_CASE_NUMBER,
			'Asc',
			TaxResAccountSpecialistViewCmpCtrl.QUERY_AS_ACTION_REQUIRED_NEW_CASES
		);

		List<TaxResAccountSpecialistViewCmpCtrl.CaseWrapper> list_ActionRequiredInProgressCases = TaxResAccountSpecialistViewCmpCtrl.getAccountSpecialistCases(
			10,
			0,
			TaxResAccountSpecialistViewCmpCtrl.SORT_BY_CASE_NUMBER,
			'Asc',
			TaxResAccountSpecialistViewCmpCtrl.QUERY_AS_ACTION_REQUIRED_INPROGRESS_CASES
		);

		List<TaxResAccountSpecialistViewCmpCtrl.CaseWrapper> list_ShelvedCases = TaxResAccountSpecialistViewCmpCtrl.getAccountSpecialistCases(
			10,
			0,
			TaxResAccountSpecialistViewCmpCtrl.SORT_BY_CASE_NUMBER,
			'Asc',
			TaxResAccountSpecialistViewCmpCtrl.QUERY_AS_SHELVED_CASES
		);
		Test.stopTest();
		System.assert(list_ActionRequiredNewCases.size() == 1, 'There should be 1 record in list.');
		//System.assert(list_ActionRequiredInProgressCases.size() == 2);
		//System.assert(list_ShelvedCases.size() == 2);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Validate Account Specialist Negative view.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testValidateAccountSpecialistViewNegative() {
		Test.startTest();
		User_Role__c objUser = TaxResAccountSpecialistViewCmpCtrl.retrieveUserRoleData();

		List<TaxResAccountSpecialistViewCmpCtrl.CaseWrapper> list_ActionRequiredCases = TaxResAccountSpecialistViewCmpCtrl.getAccountSpecialistCases(
			10,
			20,
			TaxResAccountSpecialistViewCmpCtrl.SORT_BY_CASE_NUMBER,
			'Asc',
			null
		);
		Test.stopTest();
		System.assert(list_ActionRequiredCases.size() == 0, 'There should be 0 record in list.');
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
	}
}