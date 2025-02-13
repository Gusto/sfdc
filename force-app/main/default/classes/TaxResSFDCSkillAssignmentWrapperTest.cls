/**
 * @name         TaxResSFDCSkillAssignmentWrapperTest
 * @author       Pravesh Rana
 * @date         7 June 2023
 * @description  handle code coverage logic for TaxResSFDCSkillAssignmentWrapper.cls
 **/
@isTest
public with sharing class TaxResSFDCSkillAssignmentWrapperTest {
	static String strSampleJSON = '[{"strUniqueId":"8.570960668741112","strAgentName":"AGENTID","strAgencyName":"AGENCYID","strAgencyComplexity":"L","strNoticeType":"941","strFormNumberComplexity":"L","strDebitCredit":"D","strThreshold":"50","strTier":"Simple","strPartnerTier":"NA","strMultiYear":"Yes"}]';

	@TestSetup
	static void setupTestData() {
		List<User_Skill__c> list_Skills = new List<User_Skill__c>();

		Agency_Information__c objAgency = new Agency_Information__c(Name = 'CA-EDD', Agency_Complexity__c = 'L', Agency_Abbreviation__c = 'CAEDD');
		insert objAgency;

		Tax_Form_Number__c objForm = new TestDataFactory.TaxFormNumber().setFNComplexity('H').setFormNumber('NOFORMNUMBER').setAgencyInfo(objAgency.Id).build();
		insert objForm;

		User_Role__c objUserRole = new User_Role__c(User__c = UserInfo.getUserId(), User_Skill_team__c = 'Account Specialist');
		insert objUserRole;

		User_Skill__c objSkill = new TestDataFactory.UserSkillBuilder()
			.setUserRoleId(objUserRole.Id)
			.setAgencyId(objAgency.Id)
			.setFNComplexity('H')
			.setDebitCredit('D')
			.setMultiYr('Y')
			.setTier('Simple')
			.setPartnerTier('NA')
			.setThreshold('1500')
			.setActive(true)
			.build();
		list_Skills.add(objSkill);

		User_Skill__c objSkillInactive = new TestDataFactory.UserSkillBuilder()
			.setUserRoleId(objUserRole.Id)
			.setAgencyId(objAgency.Id)
			.setFNComplexity('H')
			.setDebitCredit('D')
			.setMultiYr('Y')
			.setTier('Core')
			.setPartnerTier('NA')
			.setThreshold('1500')
			.setActive(false)
			.build();
		list_Skills.add(objSkillInactive);

		insert list_Skills;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : testing fetchUserSkills method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void fetchUserSkillsPositiveTest() {
		TaxResSFDCSkillAssignmentWrapper.OnPageLoadDataWrapperClass objWrapper;
		List<Agency_Information__c> list_Agencies = [SELECT Id FROM Agency_Information__c WHERE Agency_Abbreviation__c = 'CAEDD'];

		Test.startTest();
		//on page load
		objWrapper = TaxResSFDCSkillAssignmentWrapper.fetchUserSkills('', '', '', '', 5, 0, '', '');
		System.assert(objWrapper != null, 'By default method should return all the UserSkill records of the org.');

		//Resource filter
		objWrapper = TaxResSFDCSkillAssignmentWrapper.fetchUserSkills(UserInfo.getUserId(), '', '', '', 5, 0, '', '');
		System.assertEquals(1, objWrapper.list_UserSkillWrapper.size(), 'should only be one row a user and agency combination');

		//Agency filter
		objWrapper = TaxResSFDCSkillAssignmentWrapper.fetchUserSkills('', list_Agencies.get(0).Id, '', '', 5, 0, '', '');
		System.assertEquals(1, objWrapper.list_UserSkillWrapper.size(), 'should only be one row a user and agency combination');

        //DebitCredit filter
		objWrapper = TaxResSFDCSkillAssignmentWrapper.fetchUserSkills('', '', '', '', 5, 0, 'D', '');
		System.assertEquals(1, objWrapper.list_UserSkillWrapper.size(), 'should only be one row a user and agency combination');

        //Tier filter
		objWrapper = TaxResSFDCSkillAssignmentWrapper.fetchUserSkills('', '', '', '', 5, 0, '', 'Simple');
		System.assertEquals(1, objWrapper.list_UserSkillWrapper.size(), 'should only be one row a user and agency combination');

		//Order by
		objWrapper = TaxResSFDCSkillAssignmentWrapper.fetchUserSkills('', '', 'strAgentName', 'ASC', 5, 0, '', '');
		System.assertEquals(1, objWrapper.list_UserSkillWrapper.size(), 'should only be one row a user and agency combination');

		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : testing getAllSkillsForUserRoleAgency method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getAllSkillsForUserRoleAgencyTest() {
		List<User_Role__c> list_UserRole = [SELECT Id FROM User_Role__c];
		List<Agency_Information__c> list_Agencies = [SELECT Id FROM Agency_Information__c];
		String strKey = list_UserRole[0].Id + TaxResSFDCSkillAssignmentWrapper.INDENTIFIER_JOINT + list_Agencies[0].Id;
		Test.startTest();
		List<TaxResSFDCSkillAssignmentWrapper.TaxResSFDCSkillAssignmentWrapperClass> list_ObjTestWrapper = TaxResSFDCSkillAssignmentWrapper.getAllSkillsForUserRoleAgency(strKey, '');
		System.assertEquals(2, list_ObjTestWrapper.size(), 'org should have total of two user skill records');

		list_ObjTestWrapper = TaxResSFDCSkillAssignmentWrapper.getAllSkillsForUserRoleAgency(strKey, 'test');
		System.assertEquals(1, list_ObjTestWrapper.size(), 'should have one row as we are grouping skills based on user + agency + multi year');
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : testing dmlOnUserSkills method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void dmlOnUserSkillsPositiveTest() {
		List<Agency_Information__c> list_Agencies = [SELECT Id FROM Agency_Information__c];
		TaxResSFDCSkillAssignmentWrapper.TaxResSFDCSkillAssignmentWrapperClass objTestWrapper = new TaxResSFDCSkillAssignmentWrapper.TaxResSFDCSkillAssignmentWrapperClass();
		objTestWrapper.strUniqueId = '5.50';
		objTestWrapper.strAgencyName = list_Agencies[0].Id;
		objTestWrapper.strAgencyComplexity = 'L';
		objTestWrapper.strNoticeType = 'SUI';
		objTestWrapper.strFormNumberComplexity = 'L';
		objTestWrapper.strDebitCredit = 'D';
		objTestWrapper.strThreshold = '50';
		objTestWrapper.strTier = 'Core';
		objTestWrapper.strPartnerTier = 'NA';
		objTestWrapper.strMultiYear = 'Y';
		objTestWrapper.strAgentName = UserInfo.getUserId();
		objTestWrapper.strBAgentName = UserInfo.getUserId();
		objTestWrapper.blnIsActive = true;

		String strJSON = strSampleJSON.replace('AGENTID', UserInfo.getUserId()).replace('AGENCYID', list_Agencies[0].Id);

		List<TaxResSFDCSkillAssignmentWrapper.TaxResSFDCSkillAssignmentWrapperClass> list_testWrapper = new List<TaxResSFDCSkillAssignmentWrapper.TaxResSFDCSkillAssignmentWrapperClass>();
		list_testWrapper.add(objTestWrapper);

		Test.startTest();
		//insert skill
		String strMessage = TaxResSFDCSkillAssignmentWrapper.dmlOnUserSkills(list_testWrapper, '', '', '', '');
		List<User_Skill__c> list_Skills = [SELECT Id FROM User_Skill__c WHERE User_Role__r.User__c = :UserInfo.getUserId() AND Active__c = TRUE];
		System.assertEquals(2, list_Skills.size(), 'user should have two active skills');

		//deactivate skill
		TaxResSFDCSkillAssignmentWrapper.dmlOnUserSkills(null, '', '', list_Skills.get(0).Id, '');
		List<User_Skill__c> list_TempSkills = [SELECT Id FROM User_Skill__c WHERE User_Role__r.User__c = :UserInfo.getUserId() AND Active__c = TRUE];
		System.assertEquals(1, list_TempSkills.size(), 'after deactivation user should have only one active skill');

		//activate skill
		TaxResSFDCSkillAssignmentWrapper.dmlOnUserSkills(null, '', list_Skills.get(0).Id, '', '');
		list_TempSkills = [SELECT Id FROM User_Skill__c WHERE User_Role__r.User__c = :UserInfo.getUserId() AND Active__c = TRUE];
		System.assertEquals(2, list_TempSkills.size(), 'after activation user should have two active skill');

		//delete skill
		TaxResSFDCSkillAssignmentWrapper.dmlOnUserSkills(null, list_Skills.get(0).Id, '', '', '');
		list_TempSkills = [SELECT Id FROM User_Skill__c WHERE User_Role__r.User__c = :UserInfo.getUserId() AND Active__c = TRUE];
		System.assertEquals(1, list_TempSkills.size(), 'after deleting one active skill user should have only one active skill');

		Test.stopTest();
	}
}