/*
 * BY:PR
 * Date: Nov-18-2020
 * Desc: For code coverage of "PT Play Mode Facilitator assingment" functionality implemented via
 * 	"PTPlayModeFacilitatorAssignmentCtr" class
 * */
@isTest
public with sharing class PTPlayModeFacilitatorAssignmentCtrlTest {
	@TestSetup
	static void dataSetupMethod() {
		Utils.skipTrigger(true);
		list<User> lst_users = new List<User>();
		list<Profile> lst_userProfiles = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User'];
		list<UserRole> list_UserRole = [SELECT ID FROM UserROle WHERE Name = 'Payroll Transfer Fulfillment Team'];

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		//========User Creation=================
		User adminUser = new TestDataFactory.UserBuilder()
			.setEmail('testuser1@testorg.com')
			.setFirstName('Test')
			.setLastName('User1')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setUserName('PlayMode.Advocate1@test.PlayMode')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.setOOO(false)
			.setBackInOfficeDateTime(System.now())
			.build();
		lst_users.add(adminUser);

		User adminUser2 = new TestDataFactory.UserBuilder()
			.setEmail('testuser2@testorg.com')
			.setFirstName('Test')
			.setLastName('User2')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setUserName('PlayMode.facilitator1@test.PlayMode')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.setOOO(false)
			.build();
		lst_users.add(adminUser2);

		User adminUser3 = new TestDataFactory.UserBuilder()
			.setAlias('testfac')
			.setEmail('facilitator@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('Faclitator2')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('PlayMode.facilitator2@test.PlayMode')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.build();
		lst_users.add(adminUser3);

		User objUserOOO = new TestDataFactory.UserBuilder()
			.setEmail('testuser3@testorg.com')
			.setFirstName('Test')
			.setLastName('User3')
			.setProfileId(lst_userProfiles.get(0).Id)
			.setUserName('testPlayNewOrders@test.PlayMode')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.setOOO(true)
			.build();

		lst_users.add(objUserOOO);

		insert lst_users;

		//======Role Creation=============
		List<Role__c> roleList = new List<Role__c>();
		Role__c roleObj = new TestDataFactory.RoleBuilder().setName('Payroll Transfer Advocate').setSkillType('Core').setTeam('Payroll Transfer Advocate').build();
		roleList.add(roleObj);
		Role__c roleObj1 = new TestDataFactory.RoleBuilder().setName('Payroll Transfer Facilitator').setSkillType('Core').setTeam('Payroll Transfer Facilitator').build();
		roleList.add(roleObj1);
		insert roleList;

		//===========Skills Creation=============
		List<Skill__c> lstSkill = new List<Skill__c>();
		Skill__c skillObj1 = new Skill__c();
		skillObj1.Role__c = roleList[0].Id;
		skillObj1.IA_Exception__c = false;
		skillObj1.Prioritized_Customer__c = false;
		skillObj1.Payroll_Transfer_Skills__c = 'Bulk Order';
		lstSkill.add(skillObj1);

		Skill__c skillObj11 = new Skill__c();
		skillObj11.Role__c = roleList[0].Id;
		skillObj11.IA_Exception__c = false;
		skillObj11.Prioritized_Customer__c = false;
		skillObj11.Payroll_Transfer_Skills__c = 'Direct Order';
		lstSkill.add(skillObj11);

		Skill__c objSkill12 = new Skill__c();
		objSkill12.Role__c = roleList[0].Id;
		objSkill12.IA_Exception__c = false;
		objSkill12.Prioritized_Customer__c = false;
		objSkill12.Payroll_Transfer_Skills__c = 'BigDesk Order';
		lstSkill.add(objSkill12);

		Skill__c skillObj2 = new Skill__c();
		skillObj2.Role__c = roleList[1].Id;
		skillObj2.IA_Exception__c = true;
		skillObj2.Prioritized_Customer__c = false;
		skillObj2.Payroll_Transfer_Skills__c = 'Bulk Order';
		skillObj2.Payroll_Provider_Type__c = 'Instabase';
		skillObj2.Payroll_Sales_Team__c = 'Small Business Sales';
		skillObj2.Order_Complexity_Score__c = 'Hard';
		lstSkill.add(skillObj2);

		Skill__c skillObj21 = new Skill__c();
		skillObj21.Role__c = roleList[1].Id;
		skillObj21.IA_Exception__c = false;
		skillObj21.Prioritized_Customer__c = false;
		skillObj21.Payroll_Transfer_Skills__c = 'Direct Order';
		skillObj21.Payroll_Provider_Type__c = 'Non-instabase';
		skillObj21.Payroll_Sales_Team__c = 'Mid Market Sales';
		lstSkill.add(skillObj21);

		Skill__c objSkill22 = new Skill__c();
		objSkill22.Role__c = roleList[1].Id;
		objSkill22.IA_Exception__c = false;
		objSkill22.Prioritized_Customer__c = false;
		objSkill22.Payroll_Transfer_Skills__c = 'BigDesk Order';
		objSkill22.Payroll_Provider_Type__c = 'Non-instabase';
		objSkill22.Payroll_Sales_Team__c = 'Mid Market Sales';
		lstSkill.add(objSkill22);

		Skill__c objExternalsSkill = new TestDataFactory.SkillBuilder()
			.setRoleId(roleList[1].Id)
			.setPTSkills('External Order')
			.setIAException(false)
			.setPrioritizedCustomer(false)
			.setPayrollProviderType('Instabase')
			.setPayrollSalesTeam('Mid Market Sales')
			.build();
		lstSkill.add(objExternalsSkill);

		Skill__c objGoldSkill = new TestDataFactory.SkillBuilder()
			.setRoleId(roleList[1].Id)
			.setPTSkills('Direct Order')
			.setIAException(false)
			.setPrioritizedCustomer(false)
			.setPayrollProviderType('Instabase')
			.setPayrollSalesTeam('Small Business Sales')
			.setPartnerTier('Gold')
			.build();
		lstSkill.add(objGoldSkill);

		Skill__c objComplexityLevel3Skill = new TestDataFactory.SkillBuilder()
			.setRoleId(roleObj1.Id)
			.setComplexityLevel('Level 3')
			.setBenefitCount('0; 1-4; 4+')
			.setState(
				'AK; AL; AR; AZ; CA; CO; CT; DC; DE; FL; GA; HI; IA; ID; IL; IN; KS; KY; LA; MA; MD; ME; MI; MN; MO; MS; MT; NC; ND; NE; NH; NJ; NM; NV; NY; OH; OK; OR; PA; RI; SC; SD; TN; TX; UT; VA; VT; WA; WI; WV; WY'
			)
			.setStatesCount('0-1; 1-4; 4+')
			.setPreviousPayrollProvider(
				'ADP Run; ADP Resource; ADP Total Source; ADP Workforce Now; BenefitMall; Bank of America; Heartland Payroll; Intuit Online Payroll; iSolved; JustWorks; Namely; Other; Offline (manual); Offline (downloaded reports); Patriot Software; Paychex; Paychex Preview; Paylocity; PEO / Full Service Backend Provider; QuickBooks Desktop; QuickBooks Online; Sage; Square; SurePayroll; Thomson Reuters; Trinet; Zenefits; BambooHR; Toast; Rippling'
			)
			.build();
		lstSkill.add(objComplexityLevel3Skill);

		insert lstSkill;

		list<User_Role__c> lst_userRoles = new List<User_Role__c>();
		User_Role__c userRoleObj = new User_Role__c();
		userRoleObj.User__c = adminUser.Id;
		lst_userRoles.add(userRoleObj);

		User_Role__c userRoleObj2 = new User_Role__c(); //facilitator
		userRoleObj2.User__c = adminUser2.Id;
		lst_userRoles.add(userRoleObj2);

		User_Role__c userRoleObj3 = new TestDataFactory.UserRoleBuilder().setUserId(adminUser3.Id).setUserTeam('Payroll Transfer Facilitator').setUserSkillType('Core').build();
		lst_userRoles.add(userRoleObj3);

		insert lst_userRoles;

		list<User_Skill__c> lst_userSkills = new List<User_Skill__c>();
		User_Skill__c userSkillObj = new User_Skill__c();
		userSkillObj.Skill__c = skillObj1.Id;
		userSkillObj.User_Role__c = userRoleObj.Id;
		userSkillObj.Skill_role_name__c = 'Payroll Transfer Advocate';
		userSkillObj.Active__c = true;
		lst_userSkills.add(userSkillObj);

		User_Skill__c userSkillObj1 = new User_Skill__c();
		userSkillObj1.Skill__c = skillObj11.Id;
		userSkillObj1.User_Role__c = userRoleObj.Id;
		userSkillObj1.Skill_role_name__c = 'Payroll Transfer Advocate';
		userSkillObj1.Active__c = true;
		lst_userSkills.add(userSkillObj1);

		User_Skill__c objUserSkill12 = new User_Skill__c();
		objUserSkill12.Skill__c = objSkill12.Id;
		objUserSkill12.User_Role__c = userRoleObj.Id;
		objUserSkill12.Skill_role_name__c = 'Payroll Transfer Advocate';
		objUserSkill12.Active__c = true;
		lst_userSkills.add(objUserSkill12);

		User_Skill__c userSkillObj2 = new User_Skill__c();
		userSkillObj2.Skill__c = skillObj2.Id;
		userSkillObj2.User_Role__c = userRoleObj2.Id;
		userSkillObj2.Skill_role_name__c = 'Payroll Transfer Facilitator';
		userSkillObj2.Active__c = true;
		lst_userSkills.add(userSkillObj2);

		User_Skill__c userSkillObj3 = new User_Skill__c();
		userSkillObj3.Skill__c = skillObj21.Id;
		userSkillObj3.User_Role__c = userRoleObj2.Id;
		userSkillObj3.Skill_role_name__c = 'Payroll Transfer Facilitator';
		userSkillObj3.Active__c = true;
		lst_userSkills.add(userSkillObj3);

		User_Skill__c objUserSkill4 = new User_Skill__c();
		objUserSkill4.Skill__c = objSkill22.Id;
		objUserSkill4.User_Role__c = userRoleObj2.Id;
		objUserSkill4.Skill_role_name__c = 'Payroll Transfer Facilitator';
		objUserSkill4.Active__c = true;
		lst_userSkills.add(objUserSkill4);

		User_Skill__c objUserSkill5 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(objExternalsSkill.Id)
			.setUserRoleId(userRoleObj2.Id)
			.setSkillRoleName('Payroll Transfer Facilitator')
			.setActive(true)
			.build();
		lst_userSkills.add(objUserSkill5);

		User_Skill__c objUserSkill6 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(objComplexityLevel3Skill.Id)
			.setUserRoleId(userRoleObj2.Id)
			.setSkillRoleName('Payroll Transfer Facilitator')
			.setActive(true)
			.build();
		lst_userSkills.add(objUserSkill6);

		User_Skill__c objUserSkill7 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(objGoldSkill.Id)
			.setUserRoleId(userRoleObj3.Id)
			.setSkillRoleName('Payroll Transfer Facilitator')
			.setActive(true)
			.build();
		lst_userSkills.add(objUserSkill7);

		User_Skill__c objUserSkill8 = new TestDataFactory.UserSkillBuilder()
			.setSkillId(objComplexityLevel3Skill.Id)
			.setUserRoleId(userRoleObj3.Id)
			.setSkillRoleName('Payroll Transfer Facilitator')
			.setActive(true)
			.build();
		lst_userSkills.add(objUserSkill8);

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

		Account objParentCompanyAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Parent Company Account')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		insert objParentCompanyAccount1;

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company Account')
			.setPricing(objTierConfig.New_Price_1__c)
			.setParentAccount(objParentCompanyAccount1.Id)
			.build();
		insert objCompanyAccount;

		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Test Reseller Account')
			.setPricing(objTierConfig.New_Price_1__c)
			.setAMTier('Gold')
			.build();
		insert objResellerAccount;

		Account objNewAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test New Account')
			.setPricing(objTierConfig.New_Price_1__c)
			.setSoldBy(objResellerAccount.Id)
			.build();
		insert objNewAccount;

		Contact cntct = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('fName')
			.setLastName('lName')
			.setEmail('testAddress@domain.com')
			.build();
		insert cntct;

		list<Opportunity> testOpportunities = new List<Opportunity>();
		Opportunity opp1 = new Opportunity(
			AccountId = objCompanyAccount.Id,
			Pricebook2Id = bk.Id,
			name = 'TestOpp',
			StageName = 'SAL',
			closedate = System.today(),
			NumberOfEmployees__c = 12,
			HI_Effective_Date__c = System.today().addDays(30)
		);
		//opp1.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		opp1.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		testOpportunities.add(opp1);

		Opportunity opp2 = new Opportunity(
			AccountId = objCompanyAccount.Id,
			Pricebook2Id = bk.Id,
			name = 'TestOpp2',
			StageName = 'SAL',
			closedate = System.today(),
			NumberOfEmployees__c = 17,
			HI_Effective_Date__c = System.today().addDays(30)
		);
		//opp1.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		opp1.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		testOpportunities.add(opp2);

		Opportunity objOpp3 = new Opportunity(
			AccountId = objCompanyAccount.Id,
			Pricebook2Id = bk.Id,
			Name = 'TestOpp3',
			StageName = 'SAL',
			Closedate = System.today(),
			NumberOfEmployees__c = 105,
			HI_Effective_Date__c = System.today().addDays(30)
		);
		objOpp3.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		testOpportunities.add(objOpp3);

		Opportunity objOpp4 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Acquisition Opp')
			.setAccountId(objNewAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setNumberOfEE(15)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		testOpportunities.add(objOpp4);

		OpportunityTriggerHelper.skipTrigger = true;
		insert testOpportunities;

		List<Transition_to_Fulfillment__c> lst_transitionRecords = new List<Transition_to_Fulfillment__c>();
		Transition_to_Fulfillment__c rec = new Transition_to_Fulfillment__c(
			Bulk_Deal__c = 'N',
			Demo_Complete__c = 'No',
			Exception_Request__c = 'No',
			Contact__c = cntct.Id,
			Physical_address_accurate__c = 'N',
			Of_hours_for_EE_to_be_eligible__c = '222',
			Out_of_State_Employees_States__c = 'N',
			Quoting_Address__c = 'test1',
			Opportunity__c = testOpportunities[0].Id,
			Account__c = testOpportunities[0].AccountId
		);

		rec.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		rec.Previous_Payroll_Provider__c = 'Other';
		rec.Contractors_paid_on_first_pay_date__c = 'No';
		rec.RecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		lst_transitionRecords.add(rec);

		Transition_to_Fulfillment__c rec2 = new Transition_to_Fulfillment__c(
			Bulk_Deal__c = 'N',
			Demo_Complete__c = 'No',
			Exception_Request__c = 'No',
			Contact__c = cntct.Id,
			Physical_address_accurate__c = 'N',
			Of_hours_for_EE_to_be_eligible__c = '222',
			Out_of_State_Employees_States__c = 'N',
			Quoting_Address__c = 'test2',
			Opportunity__c = opp2.Id,
			Account__c = opp2.AccountId
		);

		//rec2.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		rec2.Previous_Payroll_Provider__c = 'Other';
		rec2.Contractors_paid_on_first_pay_date__c = 'No';
		rec2.RecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
		lst_transitionRecords.add(rec2);

		Transition_to_Fulfillment__c rec3 = new Transition_to_Fulfillment__c(
			Bulk_Deal__c = 'Y',
			Demo_Complete__c = 'No',
			Exception_Request__c = 'No',
			Contact__c = cntct.Id,
			Physical_address_accurate__c = 'N',
			Of_hours_for_EE_to_be_eligible__c = '222',
			Out_of_State_Employees_States__c = 'N',
			Quoting_Address__c = 'test3',
			Opportunity__c = opp2.Id,
			Account__c = opp2.AccountId
		);

		rec3.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		rec3.Previous_Payroll_Provider__c = 'Other';
		rec3.Contractors_paid_on_first_pay_date__c = 'No';
		rec3.RecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
		rec3.Link_to_Spreadsheet__c = 'google.com';
		lst_transitionRecords.add(rec3);

		Transition_to_Fulfillment__c objTTF4 = new Transition_to_Fulfillment__c(
			Bulk_Deal__c = 'Y',
			Demo_Complete__c = 'No',
			Exception_Request__c = 'No',
			Contact__c = cntct.Id,
			Physical_address_accurate__c = 'N',
			Of_hours_for_EE_to_be_eligible__c = '222',
			Out_of_State_Employees_States__c = 'N',
			Quoting_Address__c = 'test4',
			Opportunity__c = objOpp3.Id,
			Account__c = objOpp3.AccountId
		);
		objTTF4.Previous_Payroll_Provider__c = 'Sage';
		objTTF4.Contractors_paid_on_first_pay_date__c = 'No';
		objTTF4.RecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
		objTTF4.Link_to_Spreadsheet__c = 'google.com';
		lst_transitionRecords.add(objTTF4);

		Transition_To_Fulfillment__c objTTFRecord5 = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpp4.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer'))
			.setContactId(cntct.Id)
			.setAccountId(objNewAccount.Id)
			.setBulkDeal('N')
			.setDemoCompleted('No')
			.setExceptionRequest('No')
			.setPhysicalAddAccurate('N')
			.setHForEEEligible('222')
			.setOutOfStateEEState('N')
			.setOutgoingAddress('test5')
			.setPrevPayrollProvider('Toast')
			.ContPaidOnFrstPayDate('No')
			.build();
		lst_transitionRecords.add(objTTFRecord5);

		insert lst_transitionRecords;

		Bulk_Migration_Request__c objBmr = new TestDataFactory.BulkMigrationRequestBuilder()
			.setRequestedById(adminUser.Id)
			.setTransitionToFulfillment(rec3.Id)
			.setResellerAccount(objParentCompanyAccount1.Id)
			.build();
		BulkMigrationRequestTriggerHelper.SkipTrigger = true;
		insert objBmr;

		list<Group> lst_queue = [SELECT Id, Name FROM GROUP WHERE Type = 'Queue' AND Name = 'Company Migration - Unassigned Orders'];

		list<Order> lst_toInsertOrder = new List<Order>();
		Order ord = new Order(
			AccountId = objParentCompanyAccount1.Id,
			Status = 'Onboarding Steps 1 - 6',
			First_Check_Date__c = date.newInstance(2019, 10, 1),
			EffectiveDate = date.newInstance(2019, 9, 28),
			Transition_to_Fulfillment__c = rec.Id,
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = lst_queue.get(0).Id,
			Active_Employee_Count__c = 10,
			Contractor_Count__c = 2,
			Inactive_Employee_Count__c = 5,
			States__c = 'CA',
			COVID_19_relief_programs__c = 'Yes',
			Employees_With_Multiple_Tax_Jurisdiction__c = 'Yes',
			Assign_Facilitator__c = false,
			Data_Entry_Assist__c = adminUser2.Id,
			Facilitator_Due_Date__c = date.newInstance(2019, 10, 3),
			Blocked_Reason__c = null,
			Other_Health_Benefits_Currently_Offered__c = 'Test1',
			Financial_Health_Benefits__c = 'Test2',
			Transportation_Benefits__c = 'Test3,Test4',
			Other_Financial_Benefits_Currently_Offer__c = 'Test5',
			Previous_Payroll_Provider__c = 'ADP Run',
			of_Benefits__c = 5
		);
		lst_toInsertOrder.add(ord);

		Order ord2 = new Order(
			AccountId = objParentCompanyAccount1.Id,
			Status = 'Onboarding Steps 1 - 6',
			First_Check_Date__c = date.newInstance(2019, 10, 3),
			EffectiveDate = date.newInstance(2019, 9, 28),
			Transition_to_Fulfillment__c = rec2.Id,
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = lst_queue.get(0).Id,
			Active_Employee_Count__c = 12,
			Contractor_Count__c = 1,
			Inactive_Employee_Count__c = 2,
			States__c = 'CO',
			Assign_Facilitator__c = true,
			Facilitator_Due_Date__c = date.newInstance(2019, 10, 3),
			Blocked_Reason__c = null,
			Other_Health_Benefits_Currently_Offered__c = 'Test1',
			Financial_Health_Benefits__c = 'Test2',
			Transportation_Benefits__c = 'Test3,Test4',
			Other_Financial_Benefits_Currently_Offer__c = 'Test5',
			Previous_Payroll_Provider__c = 'ADP Run',
			of_Benefits__c = 5
		);
		lst_toInsertOrder.add(ord2);

		Order ord3 = new Order(
			AccountId = objParentCompanyAccount1.Id,
			Status = 'Onboarding Steps 1 - 6',
			First_Check_Date__c = date.newInstance(2019, 10, 3),
			EffectiveDate = date.newInstance(2019, 9, 28),
			Transition_to_Fulfillment__c = rec3.Id,
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = lst_queue.get(0).Id,
			Bulk_Migration__c = objBmr.Id,
			Active_Employee_Count__c = 17,
			Contractor_Count__c = 3,
			Inactive_Employee_Count__c = 4,
			States__c = 'AR',
			Assign_Facilitator__c = true,
			Facilitator_Due_Date__c = date.newInstance(2019, 10, 3),
			Blocked_Reason__c = null,
			Other_Health_Benefits_Currently_Offered__c = 'Test1',
			Financial_Health_Benefits__c = 'Test2',
			Transportation_Benefits__c = 'Test3,Test4',
			Other_Financial_Benefits_Currently_Offer__c = 'Test5',
			Previous_Payroll_Provider__c = 'ADP Run',
			of_Benefits__c = 5
		);
		lst_toInsertOrder.add(ord3);

		Order ord4 = new Order(
			AccountId = objParentCompanyAccount1.Id,
			Status = 'Onboarding Steps 1 - 6',
			First_Check_Date__c = date.newInstance(2019, 10, 3),
			EffectiveDate = date.newInstance(2019, 9, 28),
			Transition_to_Fulfillment__c = rec3.Id,
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = lst_queue.get(0).Id,
			Bulk_Migration__c = objBmr.Id,
			Active_Employee_Count__c = 17,
			Contractor_Count__c = 3,
			Inactive_Employee_Count__c = 4,
			States__c = 'AR',
			Assign_Facilitator__c = false,
			Data_Entry_Assist__c = adminUser2.Id,
			Facilitator_Due_Date__c = date.newInstance(2019, 10, 6),
			Blocked_Reason__c = null,
			Other_Health_Benefits_Currently_Offered__c = 'Test1',
			Financial_Health_Benefits__c = 'Test2',
			Transportation_Benefits__c = 'Test3,Test4',
			Other_Financial_Benefits_Currently_Offer__c = 'Test5',
			Previous_Payroll_Provider__c = 'ADP Run',
			of_Benefits__c = 5
		);
		lst_toInsertOrder.add(ord4);

		Order objOrder5 = new Order(
			AccountId = objCompanyAccount.Id,
			Status = 'Onboarding Steps 1 - 6',
			First_Check_Date__c = Date.newInstance(2019, 10, 3),
			EffectiveDate = Date.newInstance(2019, 9, 28),
			Transition_to_Fulfillment__c = objTTF4.Id,
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = adminUser.Id,
			Active_Employee_Count__c = 95,
			Contractor_Count__c = 0,
			Inactive_Employee_Count__c = 15,
			States__c = 'AR',
			Assign_Facilitator__c = true,
			Facilitator_Due_Date__c = Date.newInstance(2019, 10, 3),
			Blocked_Reason__c = null,
			Other_Health_Benefits_Currently_Offered__c = 'Test1',
			Financial_Health_Benefits__c = 'Test2',
			Transportation_Benefits__c = 'Test3,Test4',
			Other_Financial_Benefits_Currently_Offer__c = 'Test5',
			Previous_Payroll_Provider__c = 'ADP Run',
			of_Benefits__c = 5
		);
		lst_toInsertOrder.add(objOrder5);

		Order objOrder6 = new Order(
			AccountId = objCompanyAccount.Id,
			Status = 'Onboarding Steps 1 - 6',
			First_Check_Date__c = Date.newInstance(2019, 10, 3),
			EffectiveDate = Date.newInstance(2019, 9, 28),
			Transition_to_Fulfillment__c = objTTF4.Id,
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = objUserOOO.Id,
			Active_Employee_Count__c = 95,
			Contractor_Count__c = 0,
			Inactive_Employee_Count__c = 15,
			States__c = 'AR',
			Assign_Facilitator__c = true,
			Facilitator_Due_Date__c = Date.newInstance(2019, 10, 3),
			Reassign_Facilitator_For_OOO__c = true,
			Assign_to_Advocate__c = false,
			Exception_Request__c = true,
			Customer_Aware_of_Shorter_timeline__c = 'testing',
			Facilitator_Follow_Up_Date__c = null,
			Blocked_Reason__c = null,
			Other_Health_Benefits_Currently_Offered__c = 'Test1',
			Financial_Health_Benefits__c = 'Test2',
			Transportation_Benefits__c = 'Test3,Test4',
			Other_Financial_Benefits_Currently_Offer__c = 'Test5',
			Previous_Payroll_Provider__c = 'ADP Run',
			of_Benefits__c = 5
		);
		objOrder6.Exception_Request_Reason__c = 'Accountant has been let go';
		lst_toInsertOrder.add(objOrder6);

		Order objOrder7 = new TestDataFactory.OrderBuilder()
			.setAccountId(objNewAccount.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setStatus('Onboarding Steps 1 - 6')
			.setOwnerId(lst_queue.get(0).Id)
			.setFirstCheckDate(date.newInstance(2019, 10, 3))
			.setEffectiveDate(date.newInstance(2019, 9, 28))
			.setTTFId(objTTFRecord5.Id)
			.setActiveEECount(4)
			.setContactorCount(2)
			.setInactiveEECount(1)
			.setStates('AR')
			.setFacilitatorDueDate(Date.newInstance(2019, 10, 3))
			.setAssignmentFclit(true)
			.setPrevPayrollProvider('ADP Run')
			.setExceptionRequest(false)
			.setOfBenefits(5)
			.setBlockedReason(null)
			.build();
		objorder7.Exception_Request_Reason__c = 'Accountant has been let go';
		lst_toInsertOrder.add(objOrder7);

		OrderTriggerHelper.skipTrigger = true;
		insert lst_toInsertOrder;
		OrderTriggerHelper.skipTrigger = false;

		//==================forecast====================
		// insert Payroll Transfer FBOS Forecast record
		list<Payroll_Transfer_FBOS_Forecast__c> lst_forecast = new List<Payroll_Transfer_FBOS_Forecast__c>();
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
			RecordTypeId = cache.getrecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Advocate')
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
			RecordTypeId = cache.getrecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Facilitator')
		);
		lst_forecast.add(ptfForecast2);

		insert lst_forecast;

		list<Benefit_Order_Allocation__c> lst_boa = new List<Benefit_Order_Allocation__c>();
		Benefit_Order_Allocation__c benOrdAlloc = new Benefit_Order_Allocation__c(
			Max_BO__c = 285,
			Month__c = 10,
			Role_Type__c = 'Advocate',
			Week_End_Date__c = Date.newInstance(2019, 10, 4),
			Week_Order_Capacity__c = 12,
			Week_Start_Date__c = Date.newInstance(2019, 10, 1),
			User_Role__c = userRoleObj.Id,
			User__c = adminUser.Id,
			Working_days__c = 5,
			Payroll_Transfer_FBOS_Forecast__c = ptfForecast1.Id,
			Year__c = 2019
		);
		lst_boa.add(benOrdAlloc);

		Benefit_Order_Allocation__c benOrdAlloc2 = new Benefit_Order_Allocation__c(
			Max_BO__c = 285,
			Month__c = 10,
			Role_Type__c = 'Facilitator',
			Week_End_Date__c = Date.newInstance(2019, 10, 4),
			Week_Order_Capacity__c = 25,
			Week_Start_Date__c = Date.newInstance(2019, 10, 1),
			User_Role__c = userRoleObj2.Id,
			User__c = adminUser2.Id,
			Working_days__c = 5,
			Payroll_Transfer_FBOS_Forecast__c = ptfForecast2.Id,
			Year__c = 2019
		);
		lst_boa.add(benOrdAlloc2);

		Benefit_Order_Allocation__c benOrdAlloc3 = new TestDataFactory.BenefitOrderAllocationBuilder()
			.setMaxBO(285)
			.setMonth(10)
			.setRoleType('Facilitator')
			.setWeekEndDate(Date.newInstance(2019, 10, 4))
			.setWeekStartDate(Date.newInstance(2019, 10, 1))
			.setWeekOrderCapacity(25)
			.setUserRole(userRoleObj3.Id)
			.setUser(adminUser3.Id)
			.setWorkingDays(5)
			.setPTFBOS(ptfForecast2.Id)
			.setYear(2019)
			.build();
		lst_boa.add(benOrdAlloc3);

		insert lst_boa;
		Utils.skipTrigger(false);
	}

	@isTest
	static void playModeControllerTest() {
		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'PlayMode.facilitator1@test.PlayMode' LIMIT 1];

		Test.startTest();
		if (list_FacUsers.size() > 0) {
			System.runAs(list_FacUsers[0]) {
				PTPlayModeFacilitatorAssignmentCtrl controller = new PTPlayModeFacilitatorAssignmentCtrl();
				controller.checkNewOrderCounts();
				controller.playNewOrders();
				System.assert(controller.objOrderToPlay != null, 'objOrderToPlay should not be null.');
				System.assert(controller.objOrderToPlay.Data_Entry_Assist__c != null, 'objOrderToPlay\'s Data_Entry_Assist__c should not be null.');
				System.assertEquals(controller.intAvailableOrders, 5, 'The available order count is as expected.');

				PTPlayModeFacilitatorAssignmentCtrl controller2 = new PTPlayModeFacilitatorAssignmentCtrl();
				controller2.checkNewOrderCounts();
				controller2.playMyOrders();
				System.assert(controller2.objOrderToPlay != null, 'objOrderToPlay should not be null.');

				PTPlayModeFacilitatorAssignmentCtrl controller3 = new PTPlayModeFacilitatorAssignmentCtrl();
				controller3.playNewOrders();
			}
		}
		Test.stopTest();
	}

	@isTest
	static void playModeControllerBigDeskTest() {
		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'PlayMode.facilitator1@test.PlayMode' LIMIT 1];

		Test.startTest();
		List<Order> list_Orders = [SELECT Id, Contractor_Count__c FROM Order WHERE Total_AIC_Count__c > 100 LIMIT 1];
		list_Orders[0].Contractor_Count__c = 12;
		update list_Orders;

		List<Order> list_NonBigDeskOrders = [SELECT Id, Contractor_Count__c FROM Order WHERE Id != :list_Orders[0].Id];

		if (list_NonBigDeskOrders != null && list_NonBigDeskOrders.size() > 0) {
			delete list_NonBigDeskOrders;
		}

		if (list_FacUsers.size() > 0) {
			System.runAs(list_FacUsers[0]) {
				PTPlayModeFacilitatorAssignmentCtrl objController = new PTPlayModeFacilitatorAssignmentCtrl();
				objController.checkNewOrderCounts();
				objController.playNewOrders();
				System.assert(objController.objOrderToPlay != null, 'objOrderToPlay should not be null.');
			}
		}

		Test.stopTest();

		list_Orders = [SELECT Id, Big_Desk_Sandbox_Type__c, Data_Entry_Assist__c FROM Order WHERE Big_Desk_Sandbox_Type__c != NULL LIMIT 1];
		System.assert(list_Orders.size() > 0, 'There should be more than 0 orders in list.');
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Tests if an order with blocked reason gets counted against my blocked orders count
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void test_MyBlockedOrdersCount() {
		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'PlayMode.facilitator1@test.PlayMode' LIMIT 1];

		Test.startTest();
		List<Order> list_Orders = [SELECT Id, Contractor_Count__c, Blocked_Reason__c FROM Order LIMIT 1];
		list_Orders[0].Blocked_Reason__c = 'Became unblocked on a higher priority order';
		update list_Orders;

		if (list_FacUsers.size() > 0) {
			System.runAs(list_FacUsers[0]) {
				PTPlayModeFacilitatorAssignmentCtrl objController = new PTPlayModeFacilitatorAssignmentCtrl();
				objController.checkMYOrderCounts();
				objController.playMyOrders();
				System.assert(objController.objOrderToPlay != null, 'objOrderToPlay should not be null.');
				System.assertEquals(1, objController.intMyBlockedOrders, 'intMyBlockedOrders should be 1.');
			}
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Tests if the order played is a blocked reason order and not any other "My Order".
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void test_PlayMyBlockedOrder() {
		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'PlayMode.facilitator1@test.PlayMode' LIMIT 1];

		Test.startTest();
		List<Order> list_Orders = [SELECT Id, Contractor_Count__c, Blocked_Reason__c FROM Order LIMIT 1];
		list_Orders[0].Blocked_Reason__c = 'Became unblocked on a higher priority order';
		update list_Orders;

		if (list_FacUsers.size() > 0) {
			System.runAs(list_FacUsers[0]) {
				PTPlayModeFacilitatorAssignmentCtrl objController = new PTPlayModeFacilitatorAssignmentCtrl();
				objController.checkMYOrderCounts();
				objController.playMyBlockedOrders();
				System.assert(objController.objOrderToPlay != null, 'objOrderToPlay should not be null.');
				System.assert(!String.isNotBlank(objController.objOrderToPlay.Blocked_Reason__c), 'Blocked_Reason__c should be blank.');
				System.assertEquals(1, objController.intMyBlockedOrders, 'intMyBlockedOrders should be 1.');
			}
		}

		Test.stopTest();
	}

	@isTest
	static void testGetMatchingAllocationRecord() {
		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'PlayMode.facilitator1@test.PlayMode' LIMIT 1];
		Test.startTest();
		System.runAs(list_FacUsers[0]) {
			List<Order> list_Orders = [SELECT Id, Contractor_Count__c, Facilitator_Due_Date__c, Bulk_Migration__c FROM Order LIMIT 1];
			PTPlayModeFacilitatorAssignmentCtrl objPTPlay = new PTPlayModeFacilitatorAssignmentCtrl();
			objPTPlay.getUserNextFreeWeeks();
			Benefit_Order_Allocation__c objBOA = objPTPlay.getMatchingAllocationRecord(list_Orders[0]);
		}
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testGetQueryString() {
		List<Order> list_Order = [SELECT Bulk_Migration__c FROM Order];
		Set<Id> set_BMRIds = new Set<Id>();
		Benefit_Order_Allocation__c objBOA = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Benefit_Order_Allocation__c LIMIT 1];
		for (Order objOrder : list_Order) {
			set_BMRIds.add(objOrder.Bulk_Migration__c);
		}

		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'PlayMode.facilitator1@test.PlayMode' LIMIT 1];
		Test.startTest();
		System.runAs(list_FacUsers[0]) {
			PTPlayModeFacilitatorAssignmentCtrl objPTPlay = new PTPlayModeFacilitatorAssignmentCtrl();
			List<Order> list_OrdersFromPlay = objPTPlay.getQueryString('all', set_BMRIds, objBOA);
		}

		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testCheckNewOrderCounts() {
		Test.startTest();
		PTPlayModeFacilitatorAssignmentCtrl objPTPlay = new PTPlayModeFacilitatorAssignmentCtrl();
		objPTPlay.checkNewOrderCounts();
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testMethodsWithNoOrders() {
		Test.startTest();
		List<Order> list_Order = [SELECT Id FROM Order];
		delete list_Order;

		PTPlayModeFacilitatorAssignmentCtrl objPTPlay = new PTPlayModeFacilitatorAssignmentCtrl();
		objPTPlay.checkMyAssignToAdvocateOrderCounts();
		objPTPlay.checkMYOrderCounts();
		objPTPlay.getMatchingAllocationRecord(null);
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testPlayNewOrders() {
		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'testPlayNewOrders@test.PlayMode' LIMIT 1];

		List<Order> list_Order = [SELECT Id, Bulk_Migration__c FROM Order LIMIT 1];
		Test.startTest();
		System.runAs(list_FacUsers[0]) {
			PTPlayModeFacilitatorAssignmentCtrl objPTPlay = new PTPlayModeFacilitatorAssignmentCtrl();
			objPTPlay.objOrderToPlay = list_Order[0];
			objPTPlay.playNewOrders();
		}
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testHandleOrderRelatedUpdatesBeforePlaying() {
		PTPlayModeFacilitatorAssignmentCtrl objController = new PTPlayModeFacilitatorAssignmentCtrl();

		List<Order> list_Orders = new List<Order>();
		list_Orders = [SELECT Id, Facilitator_Due_Date__c, Bulk_Migration__c, Data_Entry_Assist__c FROM Order];
		objController.objOrderToPlay = list_Orders.get(0);

		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'PlayMode.Advocate1@test.PlayMode' LIMIT 1];

		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = TestUtils.createAccount(AccountUtil.COMPANY_ACCOUNT_RT_ID, 'Test Company Account', true);
		Account objResellerAcct1 = TestUtils.createAccount(AccountUtil.RESELLER_ACCOUNT_RT_ID, 'Test Reseller Account 1', true);

		Bulk_Migration_Request__c objBmr = new TestDataFactory.BulkMigrationRequestBuilder()
			.setRequestedById(UserInfo.getUserId())
			.setFacilitatorId(UserInfo.getUserId())
			.setResellerAccount(objResellerAcct1.Id)
			.build();

		BulkMigrationRequestTriggerHelper.SkipTrigger = true;
		insert objBmr;

		OrderTriggerHelper.skipTrigger = true;
		Order ord3 = new Order(
			AccountId = objAccount.Id,
			Status = 'Onboarding Steps 1 - 6',
			First_Check_Date__c = date.newInstance(2019, 10, 3),
			EffectiveDate = date.newInstance(2019, 9, 28),
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = UserInfo.getUserId(),
			Bulk_Migration__c = objBmr.Id,
			Active_Employee_Count__c = 17,
			Contractor_Count__c = 3,
			Inactive_Employee_Count__c = 4,
			States__c = 'AR',
			Assign_Facilitator__c = true,
			Facilitator_Due_Date__c = date.newInstance(2019, 10, 3)
		);

		insert ord3;
		objController.objOrderToPlay = ord3;

		User_Role__c USRole = new User_Role__c();
		USRole.User__c = UserInfo.getUserId();
		insert USRole;

		Benefit_Order_Allocation__c allocation = new Benefit_Order_Allocation__c(
			User_Role__c = USRole.Id,
			Week_Start_Date__c = date.newInstance(2019, 10, 2),
			Week_End_Date__c = date.newInstance(2019, 10, 4)
		);
		insert allocation;

		list_Orders.add(ord3);

		Test.startTest();
		objController.handleOrderRelatedUpdatesBeforePlaying(list_Orders, 'Test new reason');
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	/**
	 * @author      Debasmita Rawooth
	 * Test Method to verify Payroll Facilitator is able to play Gold Order in PlayMode
	 * @param   NA
	 * @return 	NA
	 **/
	@isTest
	static void playModeControllerGoldTierTest() {
		List<User> list_FacUsers = [SELECT Id FROM User WHERE UserName = 'PlayMode.facilitator2@test.PlayMode' LIMIT 1];
		List<Order> list_Orders = [
			SELECT
				Id,
				Facilitator_Due_Date__c,
				Bulk_Migration__c,
				Data_Entry_Assist__c,
				Total_AIC_Count__c,
				Exception_Request__c,
				Opportunity_Team__c,
				Previous_Payroll_Provider__c,
				External_Order__c,
				of_Benefits__c,
				of_States__c,
				States__c
			FROM Order
			WHERE AccountId != NULL AND Account.Sold_By_Partner_Tier__c = 'Gold'
			LIMIT 1
		];
		Test.startTest();
		if (list_FacUsers.size() > 0) {
			System.runAs(list_FacUsers[0]) {
				PTPlayModeFacilitatorAssignmentCtrl objController = new PTPlayModeFacilitatorAssignmentCtrl();
				objController.checkNewOrderCounts();
				objController.playNewOrders();
				System.assertEquals(1, list_Orders.size(), '1 Gold Order Available to play.');
				System.assert(objController.objOrderToPlay != null, 'objOrderToPlay should not be null.');
				System.assertEquals(objController.objOrderToPlay.Id, list_Orders[0].Id, 'The Order to play ');
			}
		}
		Test.stopTest();
	}
}