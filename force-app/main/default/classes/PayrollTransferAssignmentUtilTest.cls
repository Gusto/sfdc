/*****************************************************************************************************************************
 * Info : PayrollTransferAssignmentUtilTest is used to cover PayrollTransferAssignmentUtil
 *        which is related with 'Transition to Fulfillment', Account, Contact, Opportunity, PriceBook, Product, PricebookEntry,
 *        Policy Objects.
 *
 * Created by : Lirik on 10/11/2019
 ******************************************************************************************************************************/

@isTest
private class PayrollTransferAssignmentUtilTest {
	static final String TTF_RT_PAYROLLTRANSFER = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
	static final Id ORDER_RT_COMPANYMIGRATION = Cache.getRecordTypeId('Order', 'Company Migration');

	@TestSetup
	static void setupData() {
		List<User> lst_users = new List<User>();
		List<Profile> lst_userProfiles = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User'];

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		//========User Creation=================
		User adminUser = new TestDataFactory.UserBuilder()
			.setEmail('testAdv1@testorg.com')
			.setFirstName('Implementation')
			.setLastName('Advocate1')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setUserName('Implementation.Advocate1@test.Implementation')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.setOOO(false)
			.setBackInOfficeDateTime(System.now())
			.build();
		lst_users.add(adminUser);

		User adminUser12 = new TestDataFactory.UserBuilder()
			.setEmail('testAdv2@testorg.com')
			.setFirstName('Implementation')
			.setLastName('Advocate2')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setUserName('Implementation.Advocate2@test.Implementation')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.setOOO(false)
			.build();
		lst_users.add(adminUser12);

		User adminUser2 = new TestDataFactory.UserBuilder()
			.setEmail('testfacilitator1@testorg.com')
			.setFirstName('Implementation')
			.setLastName('facilitator1')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setUserName('Implementation.facilitator1@test.Implementation')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.setOOO(false)
			.build();
		lst_users.add(adminUser2);

		User adminUser21 = new TestDataFactory.UserBuilder()
			.setEmail('testfacilitator2@testorg.com')
			.setFirstName('Implementation')
			.setLastName('facilitator2')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setUserName('Implementation.facilitator2@test.Implementation')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.setOOO(false)
			.build();
		lst_users.add(adminUser21);

		User adminUserNew = new TestDataFactory.UserBuilder()
			.setEmail('testAdv@testorg.com')
			.setFirstName('Test')
			.setLastName('AdvUser')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setUserName('Implementation.AdvocateNew@test.Implementation')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.build();
		adminUserNew.Out_Of_Office__c = false;
		adminUserNew.Back_In_Office_Date_Time__c = System.now();
		lst_users.add(adminUserNew);

		insert lst_users;

		//======Role Creation=============
		List<Role__c> roleList = new List<Role__c>();
		Role__c roleObj1 = new TestDataFactory.RoleBuilder().setName('Payroll Transfer Advocate').setSkillType('Core').setTeam('Payroll Transfer Advocate').build();
		roleList.add(roleObj1);
		Role__c roleObj2 = new TestDataFactory.RoleBuilder().setName('Payroll Transfer Facilitator').setSkillType('Core').setTeam('Payroll Transfer Facilitator').build();
		roleList.add(roleObj2);

		//===========Skills Creation=============
		List<Skill__c> lstSkill = new List<Skill__c>();
		lstSkill.add(new TestDataFactory.SkillBuilder().setRoleId(roleList[0].Id).setPTSkills('Bulk Order').build());
		lstSkill.add(new TestDataFactory.SkillBuilder().setRoleId(roleList[0].Id).setPTSkills('Direct Order').build());
		lstSkill.add(new TestDataFactory.SkillBuilder().setRoleId(roleList[0].Id).setPTSkills('BigDesk Order').build());
		lstSkill.add(new TestDataFactory.SkillBuilder().setRoleId(roleList[0].Id).setPTSkills('Direct Order').setPartnerTier('Gold').build());
		lstSkill.add(new TestDataFactory.SkillBuilder().setRoleId(roleList[1].Id).setPTSkills('Bulk Order').build());
		lstSkill.add(new TestDataFactory.SkillBuilder().setRoleId(roleList[1].Id).setPTSkills('Direct Order').build());
		lstSkill.add(new TestDataFactory.SkillBuilder().setRoleId(roleList[1].Id).setPTSkills('Direct Order').setPartnerTier('Gold').build());
		insert lstSkill;

		List<User_Role__c> lst_userRoles = new List<User_Role__c>();
		lst_userRoles.add(new TestDataFactory.UserRoleBuilder().setUserId(adminUser.Id).setUserTeam('Payroll Transfer Advocate').setUserSkillType('Core').build());
		lst_userRoles.add(new TestDataFactory.UserRoleBuilder().setUserId(adminUser2.Id).setUserTeam('Payroll Transfer Facilitator').setUserSkillType('Core').build());
		lst_userRoles.add(new TestDataFactory.UserRoleBuilder().setUserId(adminUser12.Id).setUserTeam('Payroll Transfer Advocate').setUserSkillType('Core').build());
		lst_userRoles.add(new TestDataFactory.UserRoleBuilder().setUserId(adminUser21.Id).setUserTeam('Payroll Transfer Facilitator').setUserSkillType('Core').build());
		lst_userRoles.add(new TestDataFactory.UserRoleBuilder().setUserId(adminUserNew.Id).setUserTeam('Payroll Transfer Advocate').setUserSkillType('Core').build());

		insert lst_userRoles;

		List<User_Skill__c> lst_userSkills = new List<User_Skill__c>();
		User_Skill__c userSkillObj = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[0].Id)
			.setUserRoleId(lst_userRoles[0].Id)
			.setSkillRoleName('Payroll Transfer Advocate')
			.setActive(true)
			.build();
		lst_userSkills.add(userSkillObj);

		User_Skill__c userSkillObj1 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[1].Id)
			.setUserRoleId(lst_userRoles[0].Id)
			.setSkillRoleName('Payroll Transfer Advocate')
			.setActive(true)
			.build();
		lst_userSkills.add(userSkillObj1);

		User_Skill__c objUserSkill12 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[2].Id)
			.setUserRoleId(lst_userRoles[0].Id)
			.setSkillRoleName('Payroll Transfer Advocate')
			.setActive(true)
			.build();
		lst_userSkills.add(objUserSkill12);

		User_Skill__c userSkillObj2 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[4].Id)
			.setUserRoleId(lst_userRoles[1].Id)
			.setSkillRoleName('Payroll Transfer Facilitator')
			.setActive(true)
			.build();
		lst_userSkills.add(userSkillObj2);

		User_Skill__c userSkillObj3 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[5].Id)
			.setUserRoleId(lst_userRoles[1].Id)
			.setSkillRoleName('Payroll Transfer Facilitator')
			.setActive(true)
			.build();
		lst_userSkills.add(userSkillObj3);

		User_Skill__c userSkillObj4 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[1].Id)
			.setUserRoleId(lst_userRoles[2].Id)
			.setSkillRoleName('Payroll Transfer Advocate')
			.setActive(true)
			.build();
		lst_userSkills.add(userSkillObj4);

		User_Skill__c objUserSkill5 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[3].Id)
			.setUserRoleId(lst_userRoles[4].Id)
			.setSkillRoleName('Payroll Transfer Advocate')
			.setActive(true)
			.build();
		lst_userSkills.add(objUserSkill5);

		User_Skill__c userSkillObj6 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[5].Id)
			.setUserRoleId(lst_userRoles[3].Id)
			.setSkillRoleName('Payroll Transfer Facilitator')
			.setActive(true)
			.build();
		lst_userSkills.add(userSkillObj6);

		User_Skill__c userSkillObj7 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(lstSkill[6].Id)
			.setUserRoleId(lst_userRoles[1].Id)
			.setSkillRoleName('Payroll Transfer Facilitator')
			.setActive(true)
			.build();
		lst_userSkills.add(userSkillObj7);

		insert lst_userSkills;

		//=================opp - acc=================
		PriceBook2 bk = new PriceBook2(Name = objTierConfig.New_Price_1__c, IsActive = true);
		insert bk;

		List<Product2> prodList = new List<Product2>();
		prodList.add(TestUtility.createTestProduct('Medical', 'Benefit', false));
		prodList.add(TestUtility.createTestProduct('Dental', 'Employee', false));
		prodList.add(TestUtility.createTestProduct('Vision', 'Employee', false));
		prodList.add(TestUtility.createTestProduct('Life', 'Employee', false));
		insert prodList;

		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[0].Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[1].Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[2].Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[3].Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[0].Id, 5, bk.Id, false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[1].Id, 5, bk.Id, false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[2].Id, 5, bk.Id, false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[3].Id, 5, bk.Id, false));
		insert pbeList;

		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').setPricing(objTierConfig.New_Price_1__c).build();
		insert objAccount1;

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company Account2')
			.setPricing(objTierConfig.New_Price_1__c)
			.setParentAccount(objAccount1.Id)
			.build();
		insert objAccount;

		Account resellerAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Test Reseller Account')
			.setPricing(objTierConfig.New_Price_1__c)
			.setAMTier('Gold')
			.build();
		insert resellerAccount;

		Account objNewAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test New Company Account')
			.setPricing(objTierConfig.New_Price_1__c)
			.setSoldBy(resellerAccount.Id)
			.build();
		insert objNewAccount;

		Contact cntct = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('fName')
			.setLastName('lName')
			.setEmail('testAddress@domain.com')
			.build();
		insert cntct;

		List<Opportunity> testOpportunities = new List<Opportunity>();
		Opportunity opp1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(objAccount.Id)
			.setPriceBookId(bk.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(12)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		testOpportunities.add(opp1);

		Opportunity opp2 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp2')
			.setAccountId(objAccount.Id)
			.setPriceBookId(bk.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(17)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		testOpportunities.add(opp2);

		Opportunity objOpp3 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp3')
			.setAccountId(objAccount.Id)
			.setPriceBookId(bk.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(105)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		testOpportunities.add(objOpp3);

		Opportunity objOpp4 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp4')
			.setAccountId(objNewAccount.Id)
			.setPriceBookId(bk.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(105)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		testOpportunities.add(objOpp4);

		OpportunityTriggerHelper.skipTrigger = true;
		insert testOpportunities;

		List<Transition_to_Fulfillment__c> lst_transitionRecords = new List<Transition_to_Fulfillment__c>();
		Transition_To_Fulfillment__c rec = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(testOpportunities[0].Id)
			.setRecordTypeId(TTF_RT_PAYROLLTRANSFER)
			.setContactId(cntct.Id)
			.setAccountId(testOpportunities[0].AccountId)
			.setBulkDeal('N')
			.setDemoCompleted('No')
			.setExceptionRequest('No')
			.setPhysicalAddAccurate('N')
			.setHForEEEligible('222')
			.setOutOfStateEEState('N')
			.setOutgoingAddress('test1')
			.build();

		rec.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		rec.Previous_Payroll_Provider__c = 'Other';
		rec.Contractors_paid_on_first_pay_date__c = 'No';
		rec.RecordTypeId = TTF_RT_PAYROLLTRANSFER;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		lst_transitionRecords.add(rec);

		Transition_To_Fulfillment__c rec2 = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(opp2.Id)
			.setRecordTypeId(TTF_RT_PAYROLLTRANSFER)
			.setContactId(cntct.Id)
			.setAccountId(opp2.AccountId)
			.setBulkDeal('N')
			.setDemoCompleted('No')
			.setExceptionRequest('No')
			.setPhysicalAddAccurate('N')
			.setHForEEEligible('222')
			.setOutOfStateEEState('N')
			.setOutgoingAddress('test2')
			.build();

		//rec2.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		rec2.Previous_Payroll_Provider__c = 'Other';
		rec2.Contractors_paid_on_first_pay_date__c = 'No';
		rec2.RecordTypeId = TTF_RT_PAYROLLTRANSFER;
		lst_transitionRecords.add(rec2);

		Transition_To_Fulfillment__c rec3 = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(opp2.Id)
			.setRecordTypeId(TTF_RT_PAYROLLTRANSFER)
			.setContactId(cntct.Id)
			.setAccountId(opp2.AccountId)
			.setBulkDeal('Y')
			.setDemoCompleted('No')
			.setExceptionRequest('No')
			.setPhysicalAddAccurate('N')
			.setHForEEEligible('222')
			.setOutOfStateEEState('N')
			.setOutgoingAddress('test3')
			.build();

		rec3.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		rec3.Previous_Payroll_Provider__c = 'Other';
		rec3.Contractors_paid_on_first_pay_date__c = 'No';
		rec3.RecordTypeId = TTF_RT_PAYROLLTRANSFER;
		rec3.Link_to_Spreadsheet__c = 'google.com';
		lst_transitionRecords.add(rec3);

		Transition_To_Fulfillment__c objTTFRecord4 = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpp3.Id)
			.setRecordTypeId(TTF_RT_PAYROLLTRANSFER)
			.setContactId(cntct.Id)
			.setAccountId(objOpp3.AccountId)
			.setBulkDeal('Y')
			.setDemoCompleted('No')
			.setExceptionRequest('No')
			.setPhysicalAddAccurate('N')
			.setHForEEEligible('222')
			.setOutOfStateEEState('N')
			.setOutgoingAddress('test4')
			.build();
		objTTFRecord4.Previous_Payroll_Provider__c = 'Sage';
		objTTFRecord4.Contractors_paid_on_first_pay_date__c = 'No';
		objTTFRecord4.RecordTypeId = TTF_RT_PAYROLLTRANSFER;
		lst_transitionRecords.add(objTTFRecord4);

		Transition_To_Fulfillment__c objTTFRecord5 = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpp4.Id)
			.setRecordTypeId(TTF_RT_PAYROLLTRANSFER)
			.setContactId(cntct.Id)
			.setAccountId(objOpp4.AccountId)
			.setBulkDeal('N')
			.setDemoCompleted('No')
			.setExceptionRequest('No')
			.setPhysicalAddAccurate('N')
			.setHForEEEligible('222')
			.setOutOfStateEEState('N')
			.setOutgoingAddress('test5')
			.build();
		//rec2.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		objTTFRecord5.Previous_Payroll_Provider__c = 'Toast';
		objTTFRecord5.Contractors_paid_on_first_pay_date__c = 'No';
		lst_transitionRecords.add(objTTFRecord5);

		insert lst_transitionRecords;

		Bulk_Migration_Request__c bmrRec = new TestDataFactory.BulkMigrationRequestBuilder()
			.setRequestedById(adminUser.Id)
			.setTransitionToFulfillment(rec3.Id)
			.setResellerAccount(objAccount1.Id)
			.build();
		BulkMigrationRequestTriggerHelper.SkipTrigger = true;
		insert bmrRec;

		List<Group> lst_queue = [SELECT Id, Name FROM GROUP WHERE Type = 'Queue' AND Name = 'Company Migration - Unassigned Orders'];

		List<Order> list_toInsertOrders = new List<Order>();
		Order ord = new TestDataFactory.OrderBuilder()
			.setAccountId(objAccount1.Id)
			.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
			.setStatus('Drafted')
			.setOwnerId(lst_queue.get(0).Id)
			.setFirstCheckDate(date.newInstance(2019, 10, 1))
			.setEffectiveDate(date.newInstance(2019, 9, 28))
			.setTTFId(lst_transitionRecords[0].Id)
			.setActiveEECount(10)
			.setContactorCount(2)
			.setInactiveEECount(5)
			.setStates('CA')
			.build();
		list_toInsertOrders.add(ord);

		Order ord2 = new TestDataFactory.OrderBuilder()
			.setAccountId(objAccount1.Id)
			.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
			.setStatus('Drafted')
			.setOwnerId(lst_queue.get(0).Id)
			.setFirstCheckDate(date.newInstance(2019, 10, 3))
			.setEffectiveDate(date.newInstance(2019, 9, 28))
			.setTTFId(lst_transitionRecords[1].Id)
			.setActiveEECount(12)
			.setContactorCount(1)
			.setInactiveEECount(2)
			.setStates('CO')
			.build();
		list_toInsertOrders.add(ord2);

		Order ord3 = new TestDataFactory.OrderBuilder()
			.setAccountId(objAccount1.Id)
			.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
			.setStatus('Drafted')
			.setOwnerId(lst_queue.get(0).Id)
			.setFirstCheckDate(date.newInstance(2019, 10, 3))
			.setEffectiveDate(date.newInstance(2019, 9, 28))
			.setTTFId(lst_transitionRecords[2].Id)
			.setActiveEECount(17)
			.setContactorCount(3)
			.setInactiveEECount(4)
			.setStates('AR')
			.build();
		ord3.Bulk_Migration__c = bmrRec.Id;
		list_toInsertOrders.add(ord3);

		Order objOrder4 = new TestDataFactory.OrderBuilder()
			.setAccountId(objAccount1.Id)
			.setOpportunityId(testOpportunities[2].Id)
			.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
			.setStatus('Drafted')
			.setOwnerId(lst_queue.get(0).Id)
			.setFirstCheckDate(date.newInstance(2019, 10, 3))
			.setEffectiveDate(date.newInstance(2019, 9, 28))
			.setTTFId(lst_transitionRecords[3].Id)
			.setActiveEECount(90)
			.setContactorCount(10)
			.setInactiveEECount(10)
			.setStates('AR')
			.build();
		list_toInsertOrders.add(objOrder4);

		Order objOrder5 = new TestDataFactory.OrderBuilder()
			.setAccountId(objNewAccount.Id)
			.setOpportunityId(testOpportunities[3].Id)
			.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
			.setStatus('Drafted')
			.setOwnerId(lst_queue.get(0).Id)
			.setFirstCheckDate(date.newInstance(2019, 10, 3))
			.setEffectiveDate(date.newInstance(2019, 9, 28))
			.setTTFId(lst_transitionRecords[4].Id)
			.setActiveEECount(4)
			.setContactorCount(2)
			.setInactiveEECount(1)
			.setStates('AR')
			.build();
		list_toInsertOrders.add(objOrder5);

		OrderTriggerHelper.skipTrigger = true;
		insert list_toInsertOrders;
		OrderTriggerHelper.skipTrigger = false;

		//==================forecast====================
		// insert Payroll Transfer FBOS Forecast record
		List<Payroll_Transfer_FBOS_Forecast__c> lst_forecast = new List<Payroll_Transfer_FBOS_Forecast__c>();
		Payroll_Transfer_FBOS_Forecast__c ptfForecast1 = new Payroll_Transfer_FBOS_Forecast__c(
			FBOS_Forecast__c = 1200,
			Fifth_Week_Cap__c = 295,
			First_week_cap__c = 285,
			Forecast_Multiplier__c = 100,
			Fourth_Week_Cap__c = 285,
			Month__c = 'October',
			Second_week_cap__c = 285,
			Third_week_cap__c = 285,
			Year__c = '2019',
			RecordTypeId = Cache.getrecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Advocate')
		);
		lst_forecast.add(ptfForecast1);

		Payroll_Transfer_FBOS_Forecast__c ptfForecast2 = new Payroll_Transfer_FBOS_Forecast__c(
			FBOS_Forecast__c = 1200,
			Fifth_Week_Cap__c = 295,
			First_week_cap__c = 285,
			Forecast_Multiplier__c = 100,
			Fourth_Week_Cap__c = 285,
			Month__c = 'October',
			Second_week_cap__c = 285,
			Third_week_cap__c = 285,
			Year__c = '2019',
			RecordTypeId = Cache.getrecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Facilitator')
		);
		lst_forecast.add(ptfForecast2);

		insert lst_forecast;

		List<Benefit_Order_Allocation__c> lst_boa = new List<Benefit_Order_Allocation__c>();
		Benefit_Order_Allocation__c benOrdAlloc = new TestDataFactory.BenefitOrderAllocationBuilder()
			.setRoleType('Advocate')
			.setMaxBO(285)
			.setMonth(10)
			.setWeekOrderCapacity(12)
			.setWorkingDays(5)
			.setWeekStartDate(Date.newInstance(2019, 10, 1))
			.setWeekEndDate(Date.newInstance(2019, 10, 4))
			.setUserRole(lst_userRoles[0].Id)
			.setUser(adminUser.Id)
			.setPTFBOS(ptfForecast1.Id)
			.setYear(2019)
			.build();
		lst_boa.add(benOrdAlloc);

		Benefit_Order_Allocation__c benOrdAlloc2 = new TestDataFactory.BenefitOrderAllocationBuilder()
			.setRoleType('Facilitator')
			.setMaxBO(285)
			.setMonth(10)
			.setWeekOrderCapacity(12)
			.setWorkingDays(5)
			.setWeekStartDate(Date.newInstance(2019, 10, 1))
			.setWeekEndDate(Date.newInstance(2019, 10, 4))
			.setUserRole(lst_userRoles[1].Id)
			.setUser(adminUser2.Id)
			.setPTFBOS(ptfForecast2.Id)
			.setYear(2019)
			.build();
		lst_boa.add(benOrdAlloc2);

		Benefit_Order_Allocation__c benOrdAlloc3 = new TestDataFactory.BenefitOrderAllocationBuilder()
			.setRoleType('Advocate')
			.setMaxBO(285)
			.setMonth(10)
			.setWeekOrderCapacity(12)
			.setWorkingDays(5)
			.setWeekStartDate(Date.newInstance(2019, 10, 1))
			.setWeekEndDate(Date.newInstance(2019, 10, 4))
			.setUserRole(lst_userRoles[2].Id)
			.setUser(adminUser12.Id)
			.setPTFBOS(ptfForecast1.Id)
			.setYear(2019)
			.build();
		lst_boa.add(benOrdAlloc3);

		Benefit_Order_Allocation__c objBenOrder4 = new TestDataFactory.BenefitOrderAllocationBuilder()
			.setRoleType('Facilitator')
			.setMaxBO(285)
			.setMonth(10)
			.setWeekOrderCapacity(12)
			.setWorkingDays(5)
			.setWeekStartDate(Date.newInstance(2019, 10, 1))
			.setWeekEndDate(Date.newInstance(2019, 10, 4))
			.setUserRole(lst_userRoles[3].Id)
			.setUser(adminUser21.Id)
			.setPTFBOS(ptfForecast2.Id)
			.setYear(2019)
			.build();
		lst_boa.add(objBenOrder4);

		Benefit_Order_Allocation__c objBenOrder5 = new TestDataFactory.BenefitOrderAllocationBuilder()
			.setRoleType('Advocate')
			.setMaxBO(285)
			.setMonth(10)
			.setWeekOrderCapacity(12)
			.setWorkingDays(5)
			.setWeekStartDate(Date.newInstance(2019, 10, 1))
			.setWeekEndDate(Date.newInstance(2019, 10, 4))
			.setUserRole(lst_userRoles[4].Id)
			.setUser(adminUserNew.Id)
			.setPTFBOS(ptfForecast1.Id)
			.setYear(2019)
			.build();
		lst_boa.add(objBenOrder5);

		insert lst_boa;
	}

	@isTest
	static void advocateAssignmentTestMethod() {
		Test.startTest();
		List<Transition_to_Fulfillment__c> list_ttfRecs = [
			SELECT Id, TTF_Status__c
			FROM Transition_to_Fulfillment__c
			WHERE Reason_for_exception_request__c != NULL AND Previous_Payroll_Provider__c != 'Sage'
			LIMIT 2
		];
		list_ttfRecs.get(0).TTF_Status__c = 'PT Approved';
		list_ttfRecs.get(1).TTF_Status__c = 'PT Approved';
		OrderTriggerHelper.skipTrigger = true;
		update list_ttfRecs;
		Test.stopTest();

		List<Order> lst_Ordertemp = [SELECT Id, ownerId FROM Order WHERE Transition_to_Fulfillment__c = :list_ttfRecs.get(0).Id LIMIT 1];
		System.assert(string.valueOf(lst_Ordertemp.get(0).OwnerId).startsWith('005'), 'Owner Id should start with 005.');
	}

	@isTest
	static void advocateAssignmentTestNegative() {
		Test.startTest();
		List<User_Skill__c> list_Skills = [SELECT Id FROM User_Skill__c];
		delete list_Skills;
		List<Transition_to_Fulfillment__c> list_ttfRecs = [
			SELECT Id, TTF_Status__c
			FROM Transition_to_Fulfillment__c
			WHERE TTF_Status__c != 'PT Approved' AND Previous_Payroll_Provider__c != 'Sage'
			LIMIT 1
		];
		list_ttfRecs.get(0).TTF_Status__c = 'PT Approved';
		OrderTriggerHelper.skipTrigger = true;
		update list_ttfRecs;
		Test.stopTest();

		List<Order> lst_Ordertemp = [SELECT Id, Assignment_Error_Message__c FROM Order WHERE Transition_to_Fulfillment__c = :list_ttfRecs.get(0).Id LIMIT 1];
		System.assert(lst_Ordertemp.get(0).Assignment_Error_Message__c != null, 'Assignment_Error_Message__c should not be null.');
		PayrollTransferAssignmentUtil objPayrollTrans = new PayrollTransferAssignmentUtil();
		Date dt = Date.newInstance(2019, 10, 1);
		objPayrollTrans.getFacilitatorBOADetails(new Set<date>{ dt });
	}

	@isTest
	static void bigDeskAdvocateAssignment() {
		Test.startTest();
		List<Transition_to_Fulfillment__c> list_TTFRecords = [
			SELECT Id, TTF_Status__c
			FROM Transition_to_Fulfillment__c
			WHERE TTF_Status__c != 'PT Approved' AND Previous_Payroll_Provider__c = 'Sage'
			LIMIT 1
		];

		List<Order> list_Orders = [SELECT Id, Contractor_Count__c FROM Order WHERE Transition_to_Fulfillment__c = :list_TTFRecords[0].Id];
		//Update to run the
		list_Orders[0].Contractor_Count__c = 12;
		update list_Orders;

		list_TTFRecords.get(0).TTF_Status__c = 'PT Approved';
		OrderTriggerHelper.skipTrigger = true;
		update list_TTFRecords;
		Test.stopTest();

		list_Orders = [SELECT Id, Big_Desk_Sandbox_Type__c, OwnerId FROM Order WHERE Transition_to_Fulfillment__c = :list_TTFRecords[0].Id];
		System.assert(list_Orders.size() > 0, 'There should be at least one Order record.');
		System.assert(list_Orders[0].Big_Desk_Sandbox_Type__c != null, 'Big_Desk_Sandbox_Type__c should not be null.');
		System.assert(String.valueOf(list_Orders.get(0).OwnerId).startsWith('005'), 'Owner Id should start with 005.');
	}

	@isTest
	static void bigDeskAdvocateAssignmentNegative() {
		Test.startTest();
		List<User_Skill__c> list_Skills = [SELECT Id FROM User_Skill__c];

		if (list_Skills.size() > 0) {
			delete list_Skills;
		}

		List<Transition_to_Fulfillment__c> list_TTFRecords = [
			SELECT Id, TTF_Status__c
			FROM Transition_to_Fulfillment__c
			WHERE TTF_Status__c != 'PT Approved' AND Previous_Payroll_Provider__c = 'Sage'
			LIMIT 1
		];

		List<Order> list_Orders = [SELECT Id, Contractor_Count__c FROM Order WHERE Transition_to_Fulfillment__c = :list_TTFRecords[0].Id];
		//Update to run the
		list_Orders[0].Contractor_Count__c = 12;
		update list_Orders;

		list_TTFRecords.get(0).TTF_Status__c = 'PT Approved';
		OrderTriggerHelper.skipTrigger = true;
		update list_TTFRecords;
		Test.stopTest();

		list_Orders = [SELECT Id, Big_Desk_Sandbox_Type__c, OwnerId, Assignment_Error_Message__c FROM Order WHERE Transition_to_Fulfillment__c = :list_TTFRecords[0].Id];
		System.assert(list_Orders.size() > 0, 'There should be at least one Order record.');
		System.assert(list_Orders[0].Big_Desk_Sandbox_Type__c != null, 'Big_Desk_Sandbox_Type__c should not be null.');
		System.assert(list_Orders.get(0).Assignment_Error_Message__c != null, 'Assignment_Error_Message__c should not be null.');
		System.assert(String.valueOf(list_Orders.get(0).OwnerId).startsWith('00G'), 'Owner Id should start with 00G.');
	}

	/**
	 * @author      Debasmita Rawooth
	 * Test Method to verify Payroll Advocate is assigned to Gold Order when TTF is approved
	 * @param   NA
	 * @return 	NA
	 **/
	@isTest
	static void goldAdvocateAssignment() {
		Test.startTest();
		List<Transition_to_Fulfillment__c> list_TTFRecords = [
			SELECT Id, TTF_Status__c, Previous_Payroll_Provider__c
			FROM Transition_to_Fulfillment__c
			WHERE TTF_Status__c != 'PT Approved' AND Previous_Payroll_Provider__c = 'Toast'
			LIMIT 1
		];
		List<Order> list_Orders = [SELECT Id, Big_Desk_Sandbox_Type__c, Contractor_Count__c, Account.Sold_By_Partner_Tier__c FROM Order WHERE Transition_to_Fulfillment__c = :list_TTFRecords[0].Id];
		//Update to run the
		list_Orders[0].Big_Desk_Sandbox_Type__c = null;
		list_Orders[0].Contractor_Count__c = 1;
		update list_Orders;
		list_TTFRecords.get(0).TTF_Status__c = 'PT Approved';
		OrderTriggerHelper.skipTrigger = true;
		update list_TTFRecords;
		Test.stopTest();
		list_Orders = [SELECT Id, Account.Sold_By_Partner_Tier__c, OwnerId FROM Order WHERE Transition_to_Fulfillment__c = :list_TTFRecords[0].Id];
		System.assert(list_Orders.size() > 0, 'There should be at least one Order record.');
		System.assert(list_Orders[0].Account.Sold_By_Partner_Tier__c == 'Gold', 'Sold_By_Partner_Tier__c should be Gold.');
		System.assert(String.valueOf(list_Orders.get(0).OwnerId).startsWith('005'), 'Owner Id should start with 005.');
	}
}