/**
 * @name         TaxResPlayModeUtilTest
 * @author       Anand Singh
 * @date         10 June 2021
 * @description  Test class for TaxResPlayModeUtil class.
 **/

@isTest
public class TaxResPlayModeUtilTest {
	static String strUserEmail = 'taxResRoundRobin000@testGusto.com';
	static String MANUAL_INDEXING = 'Manual Indexing';
	static String ACCOUNT_SPECIALIST = 'Account Specialist';

	//skill pattern for reference
	//agency|agencyComplexity|NoticeType|FNComplexity|Debit|Threshold|Tier|PTier|Multi

	@TestSetup
	static void makeData() {
		List<User> list_Users = new List<User>();
		User objUser = new TestDataFactory.UserBuilder()
			.setProfileId([SELECT Id FROM Profile WHERE Name = 'Tax Res'].Id)
			.setAlias('tRRR000')
			.setEmail(strUserEmail)
			.setLastName('last')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName(strUserEmail + System.currentTimeMillis())
			.setIsActive(true)
			.build();
		objUser.CompanyName = 'TEST';
		objUser.Title = 'tRRR000';
		objUser.TimeZoneSidKey = 'America/Los_Angeles';
		list_Users.add(objUser);

		User objUser1 = new TestDataFactory.UserBuilder()
			.setProfileId([SELECT Id FROM Profile WHERE Name = 'Tax Res'].Id)
			.setAlias('tRRR001')
			.setEmail('taxResRoundRobin001@testGusto.com')
			.setLastName('lastNew')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('taxResRoundRobin001@testGusto.com' + System.currentTimeMillis())
			.setIsActive(true)
			.build();
		objUser1.CompanyName = 'TEST';
		objUser1.Title = 'tRRR001';
		objUser1.TimeZoneSidKey = 'America/Los_Angeles';
		objUser1.Out_Of_Office__c = true;
		list_Users.add(objUser1);

		insert list_Users;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Retrive user role data : Postive case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void RetriveUserRoleTestPositiveMethod() {
		Test.startTest();
		User_Role__c objUserNoticeSpecialistRole = TestDataFactory.CreateUserRole('Account Specialist');
		TaxResPlayModeUtil.RetriveUserRoleData();
		Test.stopTest();
		List<User_Role__c> list_UserRoles = [
			SELECT Id, User_Skill_Team__c, Tax_Res_Skill_Type__c
			FROM User_Role__c
			WHERE User__c = :UserInfo.getUserId() AND User_Skill_Team__c = 'Account Specialist'
		];

		System.assert(list_UserRoles.size() > 0, 'size greater then 0');
		System.assertEquals('All Cases', list_UserRoles[0].Tax_Res_Skill_Type__c, 'tax res skill type should equals to All Cases');
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Retrive user role data : Negative case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void RetriveUserRoleTestNegativeMethod() {
		Test.startTest();
		TaxResPlayModeUtil.RetriveUserRoleData();
		Test.stopTest();
		List<User_Role__c> list_UserRoles = [
			SELECT Id, User_Skill_Team__c, Tax_Res_Skill_Type__c
			FROM User_Role__c
			WHERE User__c = :UserInfo.getUserId() AND User_Skill_Team__c = 'Account Specialist'
		];

		System.assertEquals(0, list_UserRoles.size(), 'Should not have any user role records');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Account Specialist Round Robin assignment: positive scenario
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void specialistRoundRobinPositiveMethod() {
		//create data
		specialistUserRoleSkillsSetup();

		//verifying that initially cases where not assigned to any users
		List<Case> list_Cases = [SELECT Id, OwnerId, Skill_Pattern__c FROM Case WHERE Subject = 'Case 1' OR Subject = 'Case 2'];
		System.assert(String.valueOf(list_Cases[0].OwnerId).startsWith('00G'), 'User is owned by a queue');

		Test.startTest();
		TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id, list_Cases[1].Id });
		List<Case> list_TempCases = [SELECT Id, Skill_Pattern__c, OwnerId, Status FROM Case WHERE Id = :list_Cases[0].Id];
		System.assert(list_TempCases[0].Status == CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, 'Case1 ready for assignment');
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Account Specialist Round Robin assignment: positive scenario by directly calling the method
	 * 					and skipping the CaseTriggerHelper
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void specialistRoundRobinPositiveWithDMLMethod() {
		//create data
		specialistUserRoleSkillsSetup();
		//ATHENSOH|L|940|H|D|1500|Concierge|NA|Y
		//verifying that initially cases where not assigned to any users
		List<Case> list_Cases = [SELECT Id, OwnerId, Skill_Pattern__c, Account_Specialist__c, Error_Message__c FROM Case WHERE Subject = 'Case 1' OR Subject = 'Case 2'];
		System.assert(String.valueOf(list_Cases[0].OwnerId).startsWith('00G'), 'User is owned by a queue');

		for (Case objCase : list_Cases) {
			objCase.Skill_Pattern__c = 'ATHENSOH|L|940|L|D|1500|Concierge|NA|Y';
		}

		CaseTriggerHelper.skipTrigger = true;
		update list_Cases;
		CaseTriggerHelper.skipTrigger = false;

		List<User_Skill__c> list_Skills = [SELECT Id, User_Skill_Hash__c FROM User_Skill__c];

		Test.startTest();
		TaxResPlayModeUtil objController = new TaxResPlayModeUtil();
		objController.runIRSpecialistAssignment(list_Cases, true);
		List<Case> list_TempCases = [SELECT Id, Skill_Pattern__c, OwnerId FROM Case WHERE Id = :list_Cases[0].Id];
		System.assert(list_TempCases[0].OwnerId != null, 'Case1 gets assigned to user');

		for (Case objCase : list_Cases) {
			objCase.Skill_Pattern__c = 'ATHENSOH|L|940|L|D|10000|Concierge|NA|Y';
		}
		objController.runIRSpecialistAssignment(list_Cases, true);

		//3rd Case
		Case objNewCase = new Case(OwnerId = list_TempCases[0].OwnerId, Skill_Pattern__c = 'ATHENSOH|L|940|L|D|1500|Concierge|NA|Y');
		objController.runIRSpecialistAssignment(new List<Case>{ objNewCase }, true);

		//4th Case
		objNewCase = new Case(OwnerId = list_TempCases[0].OwnerId, Skill_Pattern__c = 'ATHENSOH|L|940|L|D|10000|Concierge|NA|Y');
		objController.runIRSpecialistAssignment(new List<Case>{ objNewCase }, true);

		//5th Case
		objNewCase = new Case(OwnerId = list_TempCases[0].OwnerId, Skill_Pattern__c = 'ATHENSOH|L|941|L|D|10000+|Concierge|NA|Y');
		objController.runIRSpecialistAssignment(new List<Case>{ objNewCase }, true);

		//no user present error message check
		delete [SELECT Id FROM User_Role__c];
		objController.runIRSpecialistAssignment(list_Cases, true);
		list_TempCases = [SELECT Id, Skill_Pattern__c, Error_Message__c FROM Case WHERE Id = :list_Cases[0].Id];
		System.assert(list_TempCases[0].Error_Message__c != null, 'Should have error message');

		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Account Specialist Round Robin assignment: positive scenario
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void specialistRoundRobinNegativeMethod() {
		//create data
		specialistUserRoleSkillsSetup();
		TaxResPlayModeUtil objController = new TaxResPlayModeUtil();

		//Missing Form Number test
		List<Case> list_Cases = [SELECT Id, OwnerId, Skill_Pattern__c, RecordTypeId, Account_Specialist__c, Error_Message__c FROM Case WHERE Subject = 'Case 3'];
		System.assert(String.valueOf(list_Cases[0].OwnerId).startsWith('00G'), 'User is owned by a queue');

		Test.startTest();
		TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });
		List<Case> list_TempCases = [SELECT Id, Skill_Pattern__c, OwnerId FROM Case WHERE Id = :list_Cases[0].Id];
		System.assert(String.valueOf(list_TempCases[0].OwnerId).startsWith('00G'), 'Case3 gets assigned to a queue');
		System.assert(list_TempCases[0].OwnerId != list_Cases[0].OwnerId, 'Case3 get assigned to a different queue');

		list_Cases[0].Skill_Pattern__c = 'ATHENSOH|H|940|M|D|0|Core|NA|Y';
		objController.runIRSpecialistAssignment(list_Cases, false);

		list_Cases[0].Skill_Pattern__c = 'ATHENSOH|M|940|H|D|50|Core|NA|Y';
		objController.runIRSpecialistAssignment(list_Cases, false);

		list_Cases[0].Skill_Pattern__c = 'ATHENSOH|M|940|H|D|10000|Core|NA|Y';
		objController.runIRSpecialistAssignment(list_Cases, false);

		list_Cases[0].Skill_Pattern__c = 'ATHENSOH|M|940|H|D|10000+|Core|NA|Y';
		objController.runIRSpecialistAssignment(list_Cases, false);

		list_Cases[0].Skill_Pattern__c = 'ATHENSOH|M|940||D|10000+|Core|NA|Y';
		objController.runIRSpecialistAssignment(list_Cases, false);

		Test.stopTest();

		System.assert(![SELECT Id FROM Case_Audit_Log__c].isEmpty(), 'For mismatching Skills logs should be created');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : All the extra empty methods
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void extraEmptyMethod() {
		Test.startTest();
		TaxResPlayModeUtil objController = new TaxResPlayModeUtil();
		objController.runIRSpecialistAssignment(new List<Case>(), false);

		Set<String> set_EligibleUsers = objController.getUsersWithLeastCaseCount(new Set<String>(), new Map<String, Integer>());
		System.assert(set_EligibleUsers.isEmpty(), 'Without a parameter, return should be empty');

		set_EligibleUsers = objController.getUsersWithLeastCaseCount(new Set<String>{ 'Test' }, new Map<String, Integer>());
		System.assert(!set_EligibleUsers.isEmpty(), 'With a parameter, return should not be empty');
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Creating Users, UserRoles, Skills, Assignment & UserSkills
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static void specialistUserRoleSkillsSetup() {
		List<Case> list_Cases = new List<Case>();
		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();
		List<User_Skill__c> list_Skills = new List<User_Skill__c>();
		List<Tax_Notice_Index__c> list_TaxNoticeIndexes = new List<Tax_Notice_Index__c>();
		List<Tax_Form_Number__c> list_FormNumbers = new List<Tax_Form_Number__c>();
		List<User_Role__c> list_UserRoles = new List<User_Role__c>();
		Id idTNDCRecType = Schema.SObjectType.Tax_Notice_Index__c.getRecordTypeInfosByName().get(MANUAL_INDEXING).getRecordTypeId();

		//tax form number creation
		Tax_Form_Number__c objForm = new TestDataFactory.TaxFormNumber()
		.setFNComplexity('H')
		.setFormNumber('NOFORMNUMBER')
		.setAgencyInfo(list_AgencyInformations[0].Id)
		.build();
		list_FormNumbers.add(objForm);

		Tax_Form_Number__c objForm2 = new TestDataFactory.TaxFormNumber()
		.setFNComplexity('L')
		.setFormNumber('1234')
		.setAgencyInfo(list_AgencyInformations[0].Id)
		.build();
		list_FormNumbers.add(objForm2);

		insert list_FormNumbers;

		//UserRole creation
		UserRoleTriggerHelper.skipTrigger = true;
		User_Role__c objSpecialistRole = new TestDataFactory.UserRoleBuilder()
		.setUserId([SELECT Id FROM User WHERE Email = :strUserEmail].Id)
		.setUserTeam(ACCOUNT_SPECIALIST)
		.build();
		list_UserRoles.add(objSpecialistRole);

		User_Role__c objSpecialistRole2 = new TestDataFactory.UserRoleBuilder()
		.setUserId(UserInfo.getUserId())
		.setUserTeam(ACCOUNT_SPECIALIST)
		.build();
		list_UserRoles.add(objSpecialistRole2);

		User_Role__c objSpecialistRole3 = new TestDataFactory.UserRoleBuilder()
		.setUserId([SELECT Id FROM User WHERE Email = 'taxResRoundRobin001@testGusto.com'].Id)
		.setUserTeam(ACCOUNT_SPECIALIST)
		.build();
		list_UserRoles.add(objSpecialistRole3);

		insert list_UserRoles;
		UserRoleTriggerHelper.skipTrigger = false;

		//user skill creation
		User_Skill__c objSkill = new TestDataFactory.UserSkillBuilder()
			.setUserRoleId(objSpecialistRole.Id)
			.setAgencyId(list_AgencyInformations[0].Id)
			.setFNComplexity('H')
			.setDebitCredit('D')
			.setMultiYr('Y')
			.setTier('Concierge')
			.setPartnerTier('NA')
			.setThreshold('1500')
			.setActive(true)
			.setTaxNoticeType('940')
			.build();
		list_Skills.add(objSkill);

		User_Skill__c objSkillInactive = new TestDataFactory.UserSkillBuilder()
			.setUserRoleId(objSpecialistRole2.Id)
			.setAgencyId(list_AgencyInformations[0].Id)
			.setFNComplexity('L')
			.setDebitCredit('D')
			.setMultiYr('Y')
			.setTier('Concierge')
			.setPartnerTier('NA')
			.setThreshold('10000+')
			.setActive(true)
			.setTaxNoticeType('940')
			.build();
		list_Skills.add(objSkillInactive);

		User_Skill__c objSkill3 = new TestDataFactory.UserSkillBuilder()
			.setUserRoleId(objSpecialistRole3.Id)
			.setAgencyId(list_AgencyInformations[0].Id)
			.setFNComplexity('L')
			.setDebitCredit('D')
			.setMultiYr('Y')
			.setTier('Concierge')
			.setPartnerTier('NA')
			.setThreshold('10000+')
			.setActive(true)
			.setTaxNoticeType('941')
			.build();
		objSkill3.Backup_Resource__c = objSpecialistRole.Id;
		list_Skills.add(objSkill3);

		insert list_Skills;

		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);
		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Case 1')
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.setOwnerId(CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE)
			.build();
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Case 2')
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.setOwnerId(CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE)
			.build();
		list_Cases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Case 3')
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.setOwnerId(CaseUtils.ID_TAX_RES_DATA_CAPTURE_QUEUE)
			.build();
		list_Cases.add(objCase3);

		CaseTriggerHelper.skipTrigger = true;
		insert list_Cases;
		CaseTriggerHelper.skipTrigger = false;

		//Tax Notice Index : Manual
		Tax_Notice_Index__c objNoticeIndex = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(idTNDCRecType)
			.setCaseId(list_Cases[0].Id)
			.setTaxNoticeFormNumber('NOFORMNUMBER')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('940')
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(45)
			.setTaxNoticeAmountTotal(56)
			.setAgencyAssigned('546ASD')
			.setSuiRateEffectiveDate(System.Today())
			.setYearQuarter('Q2 2023')
			.setMultiYr('Y')
			.build();
		list_TaxNoticeIndexes.add(objNoticeIndex);

		Tax_Notice_Index__c objNoticeIndex2 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(idTNDCRecType)
			.setCaseId(list_Cases[1].Id)
			.setTaxNoticeFormNumber('1234')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('940')
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(45)
			.setTaxNoticeAmountTotal(56)
			.setAgencyAssigned('546ASD')
			.setSuiRateEffectiveDate(System.Today())
			.setYearQuarter('Q2 2023')
			.setMultiYr('Y')
			.build();
		list_TaxNoticeIndexes.add(objNoticeIndex2);

		Tax_Notice_Index__c objNoticeIndex3 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(idTNDCRecType)
			.setCaseId(list_Cases[2].Id)
			.setTaxNoticeFormNumber('365')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('941')
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(45)
			.setTaxNoticeAmountTotal(56)
			.setAgencyAssigned('546ASD')
			.setSuiRateEffectiveDate(System.Today())
			.setYearQuarter('Q2 2023')
			.setMultiYr('Y')
			.build();
		list_TaxNoticeIndexes.add(objNoticeIndex3);

		insert list_TaxNoticeIndexes;
	}
}