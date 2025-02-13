@isTest
public class BenefitOrderHelperFunctionTest {
	//This method skip required triggers.
	static void skipTrigger(Boolean blnFlag) {
		AccounttriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		CarrierOrderTriggerHelper.SkipTrigger = blnFlag;
		HIBorTransferTriggerHelper.skipTrigger = blnFlag;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = blnFlag;
	}

	@isTest
	static void testIntegrationQueCreation() {
		skipTrigger(true);
		HI_BOR_Transfer__c bor = new HI_BOR_Transfer__c(
			Id__c = '1123',
			Status__c = 'form_created',
			Benefit_Types__c = '["dca", "vision", "short_term_disability", "long_term_disability", "medical", "dental", "fsa", "hsa", "hra", "commuter", "life"]',
			Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "dca"=>"Zenefits", "commuter"=>"Wage Works", "hsa"=>"Zenefits"}, ' +
				'"title"=>"President", "effective_month"=>6, "effective_month_same_as_medical"=>"no", "effective_month_fsa"=>5, "effective_month_dca"=>5}'
		);
		insert bor;

		Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
		opp1.Id__c = '1123';
		opp1.Source_Id__c = '1123';
		opp1.Id_And_Source_Id__c = 'Id__c=>1123,Source_Id__c=>1123';
		update opp1;

		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('Benefits BoR', opp1.Id, 'Test Benefit Order', false);
		benefitOrdr1.BoR_Id__c = '1123';
		benefitOrdr1.Type__c = 'BOR';
		benefitOrdr1.Order_Status__c = 'Ready for Qualification';
		benefitOrdr1.UW_Owner__c = UserInfo.getUserId();
		insert benefitOrdr1;

		Carrier__c objCarrier = TestUtility.Carrier();
		Carrier_Order__c carOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder.Name = 'TEST CARRIER ORDER';
		carOrder.Carrier__c = objCarrier.Id;
		carOrder.Benefit_Order__c = benefitOrdr1.Id;
		carOrder.Order_Type__c = 'Qualification';
		carOrder.RecordTypeId = cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		carOrder.OwnerId = UserInfo.getUserId();
		insert carOrder;
		skipTrigger(false);

		Test.startTest();
		Map<Id, Account> map_Accounts = BenefitOrderHelperFunctions.getAccountsByAccountId(new Set<Id>{ opp1.AccountId });
		System.assert(map_Accounts.containsKey(opp1.AccountId), 'Incorrect Result');

		Map<Id, Carrier_Order__c> map_CarrierOrders = BenefitOrderHelperFunctions.getCarrierOrderMap(new Set<Id>{ benefitOrdr1.Id });
		System.assert(map_CarrierOrders.containsKey(carOrder.Id), 'Incorrect Result');

		Map<Id, Opportunity> map_Opportunities = BenefitOrderHelperFunctions.getOppsByOppId(new Set<Id>{ opp1.Id });
		System.assert(map_Opportunities.containsKey(opp1.Id), 'Incorrect Result');

		Map<String, Id> map_Queues = BenefitOrderHelperFunctions.getQueuesByName();
		System.assert(!map_Queues.isEmpty(), 'Incorrect Result');
		Test.stopTest();
	}

	@isTest
	static void testCreateBenefitOrder() {
		skipTrigger(true);

		test.startTest();
		Id idTTFBoRRecordTypeId = TransitiontoFulfilmentUtil.strBenBorRecTypeId;

		list<Account> list_Account = new List<Account>();
		//Parent Account
		Account accRec = new Account(Name = 'Parent Company', ZP_Company_Overall_Status__c = 'Active', ZP_Company_Id__c = 'zpMainAccount1234', Joined_Date_Panda__c = system.today());
		list_Account.add(accRec);

		//Child Account
		Account accRec1 = new Account(Name = 'Child Company', ZP_Company_Overall_Status__c = 'Active', ZP_Company_Id__c = 'zpChildAccount2345', Joined_Date_Panda__c = system.today());
		list_Account.add(accRec1);
		insert list_Account;

		accRec1.ParentId = accRec.Id;
		update accRec1;

		List<Opportunity> list_Opportunity = new List<Opportunity>();
		//Parent Opportunity
		Opportunity oppRec = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits BoR'))
			.setName('TEST OPPORTUNITY')
			.setAccountId(accRec.Id)
			.setStage('Raw')
			.setCloseDate(Date.newInstance(2019, 7, 1))
			.setId('HIBORTRANSFER123421')
			.setSourceID('HIBORTRANSFER123421')
			.setOrderGenerated(false)
			.setMaestro(false)
			.build();

		list_Opportunity.add(oppRec);

		//Child Opportunity
		Opportunity oppRec1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits BoR'))
			.setName('TEST OPPORTUNITY')
			.setAccountId(accRec1.Id)
			.setStage('Raw')
			.setCloseDate(Date.newInstance(2019, 7, 1))
			.setId('HIBORTRANSFERzpEIN6789012')
			.setSourceID('HIBORTRANSFERzpEIN6789012')
			.setOrderGenerated(false)
			.setMaestro(false)
			.build();

		list_Opportunity.add(oppRec1);
		insert list_Opportunity;

		oppRec.stageName = 'Closed Won';
		oppRec.CloseDate = Date.newInstance(2019, 7, 1);
		update oppRec;

		oppRec1.stageName = 'Closed Won';
		oppRec1.CloseDate = Date.newInstance(2019, 7, 1);
		update oppRec1;

		List<Opportunity> list_IsWonOpp = [
			SELECT Id, RecordTypeId, stageName, Id__c, AccountId, Source_Id__c, Name, Order_Generated__c, IsWon, Renewal_Date__c, Maestro__c
			FROM Opportunity
			WHERE IsWon = TRUE
		];

		List<Transition_to_Fulfillment__c> list_TTF = new List<Transition_to_Fulfillment__c>();
		Transition_to_Fulfillment__c objTTFRecord = new Transition_to_Fulfillment__c(
			Opportunity__c = oppRec1.Id,
			Account__c = oppRec1.AccountId,
			HSA_Renewal_Date__c = System.today(),
			FSA_Renewal_Date__c = System.today(),
			DCA_Renewal_Date__c = System.today(),
			Type_of_TADA_s__c = 'Flexible Spending Account - Dependent Care;Commuter',
			Multi_EIN__c = 'Y',
			Send_Order__c = true,
			RecordTypeId = idTTFBoRRecordTypeId
		);
		list_TTF.add(objTTFRecord);

		Transition_to_Fulfillment__c objTTFRecord1 = new Transition_to_Fulfillment__c(
			Opportunity__c = oppRec.Id,
			Account__c = oppRec.AccountId,
			HSA_Renewal_Date__c = System.today(),
			FSA_Renewal_Date__c = System.today(),
			DCA_Renewal_Date__c = System.today(),
			Type_of_TADA_s__c = 'Flexible Spending Account - Dependent Care;Commuter',
			Multi_EIN__c = 'Y',
			Send_Order__c = true,
			RecordTypeId = idTTFBoRRecordTypeId
		);
		list_TTF.add(objTTFRecord1);
		insert list_TTF;

		Map<Id, Opportunity> map_Opp = new Map<Id, Opportunity>();
		map_Opp.put(oppRec.Id, oppRec);
		map_Opp.put(oppRec1.Id, oppRec1);

		BenefitOrderHelperFunctions objClass = new BenefitOrderHelperFunctions();
		objClass.createBenefitOrder(list_IsWonOpp, map_Opp, null, new Map<Id, Benefit_Order__c>());

		objClass.createBOForAffiliates(new List<Opportunity>{ oppRec }, new Map<string, Opportunity>{ oppRec1.Id => oppRec1 });
		Test.stopTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE Opportunity__c = :oppRec.Id];
		System.assert(objBO != null, 'Object Cannot be Null');
	}

	@isTest
	static void testRenewalAlignement() {
		skipTrigger(true);

		Test.startTest();
		Account account = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('56465453434')
			.build();
		insert account;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits Renewal'))
			.setName('Test')
			.setAccountId(account.Id)
			.setStage('ER Confirm')
			.setCloseDate(Date.newInstance(2019, 7, 1))
			.setId('HIBORTRANSFER123421')
			.setSourceID('HIBORTRANSFER123421')
			.setTouchType('HI EBBP Creation')
			.setOrderGenerated(false)
			.setMaestro(true)
			.build();
		objOpportunity.Async_Renewal__c = true;
		insert objOpportunity;

		skipTrigger(false);

		BenefitOrderHelperFunctions objClass = new BenefitOrderHelperFunctions();
		objClass.createBenefitOrder(new List<Opportunity>{ objOpportunity }, null, null, new Map<Id, Benefit_Order__c>());
		Test.stopTest();

		Benefit_Order__c objBO = [SELECT Id, Maestro__c FROM Benefit_Order__c WHERE Opportunity__c = :objOpportunity.Id];
		System.assert(objBO != null, 'Benefit Order should be created');
		System.assertEquals(true, objBO.Maestro__c, 'Maestro value should be copied from Oppty');
	}

	@isTest
	static void testUserWhoHaveBORRec() {
		skipTrigger(true);

		test.startTest();
		UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		insert r;
		Profile pf1 = [SELECT Id FROM profile WHERE Name = 'System Administrator'];

		// Generating a Unique Name
		String orgId = UserInfo.getOrganizationId();
		String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
		String uniqueName = orgId + dateString + randomInt;

		User user1 = new User(
			FirstName = 'Test1',
			LastName = 'User1',
			UserRoleId = r.Id,
			ProfileId = pf1.Id,
			Benefits_Class__c = 'Class 1',
			Class_Queue__c = 'Class 1',
			alias = uniqueName.substring(18, 23),
			email = 'usr' + uniqueName + '@test' + orgId + '.org',
			username = 'usr' + uniqueName + '@test' + orgId + '.org',
			TimeZoneSidKey = 'GMT',
			LanguageLocaleKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LocaleSidKey = 'en_US'
		);

		System.runAs(user1) {
			Opportunity objOppty = TestUtility.BenefitsBoROpportunity();
			Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('Benefits BoR', objOppty.Id, 'Test BO', false);
			objBO.OwnerId = UserInfo.getUserId();
			objBO.Initial_Owner__c = user1.Id;
			insert objBO;

			List<Role__c> RoleList = new List<Role__c>();
			Role__c BARole = new Role__c(Name = 'Benefit Transfer Advocate');
			RoleList.add(BARole);

			Role__c BF1Role = new Role__c(Name = 'Benefit Transfer Facilitator 1');
			RoleList.add(BF1Role);
			insert (RoleList);

			List<Skill__c> lstSkill = new List<Skill__c>();
			lstSkill.add(new Skill__c(Role__c = BARole.Id));
			lstSkill.add(new Skill__c(Role__c = BF1Role.Id));
			insert lstSkill;

			User_Role__c userRoleObj = new User_Role__c();
			userRoleObj.User__c = user1.Id;
			insert userRoleObj;

			List<User_Skill__c> list_UserSkill = new List<User_Skill__c>();
			list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[0].Id, User_Role__c = userRoleObj.Id, Skill_Role_Name__c = 'Benefit transfer Advocate'));
			list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[1].Id, User_Role__c = userRoleObj.Id, Skill_Role_Name__c = 'Benefit transfer Facilitator 1'));
			insert list_UserSkill;
		}
		BenefitOrderHelperFunctions.reAssignBOtoInitialAdvocateOnReturnToOffice(new Set<string>{ user1.Id });
		Test.stopTest();

		Benefit_Order__c objBO = [SELECT Id, OwnerId, Initial_Owner__c FROM Benefit_Order__c LIMIT 1];
		System.assertEquals(objBO.OwnerId, objBO.Initial_Owner__c, 'Incorrect Result');
	}

	@isTest
	static void testCaseOnInsert() {
		skipTrigger(true);
		Id ttfId;
		Test.startTest();
		Opportunity testOpp = TestUtility.BenefitsNewPlanOpportunity();
		List<Opportunity> list_opptyToCreateQASheet = new List<Opportunity>();
		list_opptyToCreateQASheet.add(testOpp);
		QASheetHelper.createOrUpdateQASheet(list_opptyToCreateQASheet);
        
		if (testOpp != null) {
			Id conRTId = Cache.getRecordTypeId('Contact', 'Company');
			Contact bpOfContactTest = new Contact(RecordTypeId = conRTId, FirstName = 'fName', lastName = 'lName', Email = 'abc@gmail.com');
			insert bpOfContactTest;

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };

			Transition_to_Fulfillment__c rec = new Transition_to_Fulfillment__c(
				Contact__c = bpOfContactTest.Id,
				Benefits_Point_of_Contact__c = 'Test',
				Opportunity__c = testOpp.Id,
				Account__c = testOpp.AccountId,
				Renewal_Exception__c = 'Yes',
				Renewal_Date__c = Date.today(),
				Medical_New_Carrier__c = 'aa',
				Dental_Carrier__c = 'aa',
				Vision_Carrier__c = 'aa',
				LiDi_Carrier__c = 'aa',
				FSA_HSA_401K__c = 'aa',
				Contact_Preference__c = 'Call',
				RecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan'),
				Send_Order__c = true
			);
			insert rec;

			map<Id, Transition_to_Fulfillment__c> newTTFforTTFCompleted = new Map<Id, Transition_to_Fulfillment__c>();
			newTTFforTTFCompleted.put(rec.Id, rec);
			ttfId = rec.Id;

			BenefitOrderHelperFunctions objBOCreationUtil = new BenefitOrderHelperFunctions();
			objBOCreationUtil.createBenefitOrder(null, null, newTTFforTTFCompleted, null);
		}
		Test.stopTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE Transition_to_Fulfillment__c = :ttfId];
		System.assert(objBO != null, 'Object Cannot be null');
	}

	/**
	 * @description This is a test method for testing the creation of Benefit Order on Benefits Renewal.
	 * @author Nigam Goyal | 10-03-2023
	 **/
	@isTest
	static void testBOCreationOnBenefitsRenewal() {
		skipTrigger(true);
		Id idttfId;
		Test.startTest();
		Account account = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('56465453434').build();
		insert account;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits Renewal'))
			.setName('Test')
			.setAccountId(account.Id)
			.setStage('ER Confirm')
			.setCloseDate(Date.newInstance(2019, 7, 1))
			.setId('HIBORTRANSFER123421')
			.setSourceID('HIBORTRANSFER123421')
			.setTouchType('HI EBBP Creation')
			.setOrderGenerated(false)
			.setMaestro(true)
			.setReasonForAdvising('Auto-renewed')
			.build();
		insert objOpportunity;
		List<Opportunity> list_opptyToCreateQASheet = new List<Opportunity>();
		list_opptyToCreateQASheet.add(objOpportunity);
		QASheetHelper.createOrUpdateQASheet(list_opptyToCreateQASheet);

		if (objOpportunity != null) {
			Contact objContact = new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(objOpportunity.AccountId)
				.setEmail('testuer@abccompany.com')
				.setInferFitScore('D')
				.setLastName('Test')
				.build();
			insert objContact;

			NewTransitionToFulfillmentController.BO_order_type = new List<String>{ 'Carrier Switch' };
			Transition_to_Fulfillment__c objTTFRecord = new TestDataFactory.TransitionToFulfillmentBuilder()
				.setAccountId(objOpportunity.AccountId)
				.setContactId(objContact.Id)
				.setOpportunityId(objOpportunity.Id)
				.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal'))
				.setBenefitsPointOfContact('Test')
				.setSendOrder(true)
				.build();
			insert objTTFRecord;
			Map<Id, Transition_to_Fulfillment__c> newTTFforTTFCompleted = new Map<Id, Transition_to_Fulfillment__c>();
			newTTFforTTFCompleted.put(objTTFRecord.Id, objTTFRecord);
			idttfId = objTTFRecord.Id;

			BenefitOrderHelperFunctions objBOCreationUtil = new BenefitOrderHelperFunctions();
			objBOCreationUtil.createBenefitOrder(null, null, newTTFforTTFCompleted, null);
		}
		Test.stopTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE Transition_to_Fulfillment__c = :idttfId];
		System.assert(objBO != null, 'Object Cannot be null');
	}

	@isTest
	static void testsetBenefitOrderfields() {
		Test.startTest();
		Opportunity objOppty = TestUtility.BenefitsBoROpportunity();
		Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('Benefits BoR', objOppty.Id, 'Test BO', false);
		objBO.OwnerId = UserInfo.getUserId();
		objBO.Order_Status__c = 'Ready for Qualification';
		insert objBO;

		BenefitOrderHelperFunctions objBOCreationUtil = new BenefitOrderHelperFunctions();
		objBOCreationUtil.setBenefitOrderFields('Benefits BoR', new List<Benefit_Order__c>{ objBO }, true, UserInfo.getUserId(), BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID);
		Test.stopTest();

		Benefit_Order__c objBO1 = [SELECT Id, Order_Status__c, UW_Owner__c FROM Benefit_Order__c WHERE Id = :objBO.Id];
		System.assertEquals('Qualification', objBO1.Order_Status__c, 'Incorrect Order Status');
		System.assertEquals(UserInfo.getUserId(), objBO1.UW_Owner__c, 'Owner Id not as expected');
	}

	@isTest
	static void testRenewalBYOB() {
		Test.startTest();
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(Cache.getRecordTypeId('Account', 'Company')).setZPCompanyId('12121212121212').setName('Test').build();
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits BYOB'))
			.setName('Test')
			.setAccountId(objAccount.Id)
			.setStage('ER Confirm')
			.setCloseDate(Date.newInstance(2019, 7, 1))
			.setNumberOfEE(30)
			.setZPCompanyId('12121212121212')
			.setSourceID('12121212121212')
			.setTouchType('HI EBBP Creation')
			.build();
		objOpportunity.Async_Renewal__c = true;
		objOpportunity.Renewal_Date__c = Date.newInstance(2030, 12, 31);
		objOpportunity.Benefits_Current_Setup_Step__c = 'Completed';
		objOpportunity.Order_Generated__c = FALSE;
		insert objOpportunity;

		BenefitOrderHelperFunctions objClass = new BenefitOrderHelperFunctions();
		objClass.createBenefitOrder(new List<Opportunity>{ objOpportunity }, null, null, new Map<Id, Benefit_Order__c>());
		Test.stopTest();

		Benefit_Order__c objBO = [SELECT Id, Type__c, Prioritized_Customer__c FROM Benefit_Order__c LIMIT 1];
		System.assert(objBO != null, 'Object cannot be null');
		System.assertEquals('BYB Renewal', objBO.Type__c, 'Type should be "BYB Renewal');
		System.assertEquals(true, objBO.Prioritized_Customer__c, 'Field has to be true');

		Case objCase = [SELECT Id, Type, Benefit_Order__c FROM Case LIMIT 1];
		System.assert(objCase != null, 'Object cannot be null');
		System.assertEquals('BYOB', objCase.Type, 'Incorrect Type');
		System.assertEquals(objBO.Id, objCase.Benefit_Order__c, 'Incorrect Id');

		Opportunity objOpp = [SELECT Id, Order_Generated__c, StageName FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(true, objOpp.Order_Generated__c, 'Field has to be true');
		System.assertEquals('Closed Won', objOpp.StageName, 'Incorrect StageName');
	}
}