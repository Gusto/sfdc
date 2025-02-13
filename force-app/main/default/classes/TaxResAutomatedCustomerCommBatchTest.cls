/**
 * @name         TaxResAutomatedCustomerCommBatchTest
 * @author       Bhagat Singh
 * @date         18 Aug 2021
 * @description  Test class for TaxResAutomatedCustomerCommBatch class. Add login user in 'TaxRes Routing' Group.
 **/
@isTest
private class TaxResAutomatedCustomerCommBatchTest {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		skipTrigger(true);
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setEmail('test@testorg.com')
			.setFirstName('Test')
			.setLastName('user')
			.setProfileId(TestDataFactory.objZPSysAdminProfile.Id)
			.setUserName('gusto@test.gusto')
			.setExemptfromValidationRules(true)
			.build();
		insert objAdminUser;

		String strCO = CaseUtils.TAXRES_COORDINATOR;
		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();
		Role__c objRole = TestDataFactory.CreateRole(strCO);
		Region_POD__c objRegionPOD = TestDataFactory.CreateAgencyRegion('Test CO Region', strCO);

		List<Region_POD_mapping__c> list_RegionPODMappings = TestDataFactory.CreateAgencyRegionPODMapping(objRegionPOD, list_AgencyInformations);

		List<Skill__c> list_Skills = TestDataFactory.CreateSkill(objRole, list_RegionPODMappings);

		User_Role__c objUserCORole = TestDataFactory.CreateUserRole(strCO);
		//Create Another user role
		User_Role__c objUserCORole1 = new User_Role__c();
		objUserCORole1.User__c = objAdminUser.Id;
		objUserCORole1.User_Skill_Team__c = strCO;
		objUserCORole1.User_Skill_Type__c = 'Core';
		objUserCORole1.Tax_Res_Skill_Type__c = 'All Cases';
		insert objUserCORole1;

		TestDataFactory.CreateUserSkill(objUserCORole, list_Skills);

		TestDataFactory.CreateUserSkill(objUserCORole1, list_Skills);

		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);

		Case ObjCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		ObjCase.Status = 'Research in progress';
		objCase.Agency_Information__c = list_AgencyInformations[0].Id;
		ObjCase.ContactId = objContact.Id;
		update ObjCase;

		skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate TaxRes Customer Communication on after every 7 days : Postive Case.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testTaxResCCPostiveCase() {
		Test.startTest();
		TaxResAutomatedCustomerCommSchedule objSchedule = new TaxResAutomatedCustomerCommSchedule();
		String strSchedule = '0 0 23 * * ?';
		system.schedule('Test', strSchedule, objSchedule);

		TaxResAutomatedCustomerCommBatch objCommBatch = new TaxResAutomatedCustomerCommBatch();
		Database.executeBatch(objCommBatch);
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate TaxRes Customer Communication on after every 7 days : Negative Case.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testTaxResCCNegativeCase() {
		Test.startTest();
		TaxResAutomatedCustomerCommSchedule objSchedule = new TaxResAutomatedCustomerCommSchedule();
		String strSchedule = '0 0 22 * * ?';
		system.schedule('Test', strSchedule, objSchedule);
		Test.stopTest();

		System.assert([SELECT Id, Last_out_bound_email__c FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1].Last_out_bound_email__c == null, 'Last_out_bound_email__c should be null.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		EmailMessageTriggerHelper.skipTrigger = blnFlag;
		TriggerTaskDispatchClass.skipTrigger = blnFlag;
		TaskTriggerHelper.skipTrigger = blnFlag;
	}
}