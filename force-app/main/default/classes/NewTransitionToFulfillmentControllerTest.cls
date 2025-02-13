@isTest
private class NewTransitionToFulfillmentControllerTest {
	@TestSetup
	static void setupData() {
		Utils.skipTrigger(true);
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		PriceBook2 objPriceBook = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPriceBook;

		List<Product2> list_Products = new List<Product2>();
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Medical').setFamily('Benefit').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Dental').setFamily('Employee').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Vision').setFamily('Employee').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Life').setFamily('Employee').build());
		insert list_Products;

		List<PricebookEntry> list_PBEntry = new List<PricebookEntry>();
		list_PBEntry.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, Test.getStandardPriceBookId(), false));
		list_PBEntry.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, Test.getStandardPriceBookId(), false));
		list_PBEntry.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, Test.getStandardPriceBookId(), false));
		list_PBEntry.add(TestUtility.createTestPriceBookEntry(list_Products[3].Id, 5, Test.getStandardPriceBookId(), false));
		list_PBEntry.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, objPriceBook.Id, false));
		list_PBEntry.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, objPriceBook.Id, false));
		list_PBEntry.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, objPriceBook.Id, false));
		list_PBEntry.add(TestUtility.createTestPriceBookEntry(list_Products[3].Id, 5, objPriceBook.Id, false));
		insert list_PBEntry;

		Account objParentAccount = new TestDataFactory.AccountBuilder().setName('Test Company Account').setRecordTypeId('Company').setPricing(objTierConfig.New_Price_1__c).build();
		insert objParentAccount;

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Company Account')
			.setRecordTypeId('Company')
			.setPricing(objTierConfig.New_Price_1__c)
			.setParentAccount(objParentAccount.Id)
			.setZPCompanyId('100989002')
			.build();
		insert objAccount;

		Account objOtherAccount = new TestDataFactory.AccountBuilder().setName('Test Company Account').setRecordTypeId('Company').setPricing(objTierConfig.New_Price_1__c).build();
		insert objOtherAccount;

		List<Contact> list_Contacts = new List<Contact>();
		list_Contacts.add(
			new TestDataFactory.ContactBuilder().setFirstName('James').setLastName('Butt').setEmail('Jamesbuttt11@gusto.com').setAccountId(objParentAccount.Id).setRecordTypeId('Company').build()
		);
		list_Contacts.add(
			new TestDataFactory.ContactBuilder().setFirstName('Art').setLastName('Venere').setEmail('ArtVenere11@gusto.com').setAccountId(objOtherAccount.Id).setRecordTypeId('Company').build()
		);
		list_Contacts.add(
			new TestDataFactory.ContactBuilder().setFirstName('Mitsue').setLastName('Tollner').setEmail('MitsueTollner11@gusto.com').setAccountId(objAccount.Id).setRecordTypeId('Company').build()
		);
		insert list_Contacts;

		list<Opportunity> list_Opps = new List<Opportunity>();
		list_Opps.add(
			new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setName('Test Opp Renewal')
				.setAccountId(objAccount.Id)
				.setPriceBookId(objPriceBook.Id)
				.setStage('SAL')
				.setCloseDate(System.today())
				.setNumberOfEE(12)
				.setHIEffectiveDate(System.today().addDays(30))
				.setOrderGenerated(false)
				.setId('HIRENEWAL19875')
				.build()
		);
		list_Opps.add(
			new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setName('Test Opp Renewal 2')
				.setAccountId(objAccount.Id)
				.setPriceBookId(objPriceBook.Id)
				.setStage('SAL')
				.setCloseDate(System.today())
				.setNumberOfEE(12)
				.setHIEffectiveDate(System.today().addDays(30))
				.setOrderGenerated(false)
				.setId('HIRENEWAL19876')
				.build()
		);
		list_Opps.add(
			new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setName('Test Opp New Plan')
				.setAccountId(objParentAccount.Id)
				.setPriceBookId(objPriceBook.Id)
				.setStage('SAL')
				.setCloseDate(System.today())
				.setNumberOfEE(12)
				.setHIEffectiveDate(System.today().addDays(30))
				.setOrderGenerated(false)
				.setSourceID('4971')
				.build()
		);
		list_Opps.add(
			new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
				.setName('Test Opp Company')
				.setAccountId(objAccount.Id)
				.setPriceBookId(objPriceBook.Id)
				.setStage('SAL')
				.setCloseDate(System.today())
				.setNumberOfEE(12)
				.setHIEffectiveDate(System.today().addDays(30))
				.setOrderGenerated(false)
				.build()
		);
		list_Opps.add(
			new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
				.setName('Test Opp Bor')
				.setAccountId(objAccount.Id)
				.setPriceBookId(objPriceBook.Id)
				.setStage('SAL')
				.setCloseDate(System.today())
				.setNumberOfEE(12)
				.setHIEffectiveDate(System.today().addDays(30))
				.setOrderGenerated(false)
				.build()
		);
		insert list_Opps;

		HIGroupEvent__c objHIGENewPlan = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO)
			.setProcessingState('Queued')
			.setEventInfo(HIGroupEventQASheetHandlerTest.STR_JSON)
			.setApplicationId('4971')
			.setCompanyId('100989002')
			.build();
		insert objHIGENewPlan;

		HIGroupEvent__c objHIGERenewal = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c12')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO)
			.setProcessingState('Queued')
			.setEventInfo(HIGroupEventQASheetHandlerTest.STR_JSON_Renewal)
			.setApplicationId('4971')
			.setCompanyId('100989002')
			.build();
		insert objHIGERenewal;

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ list_Opps[0], list_Opps[1], list_Opps[2] });

		List<OpportunityContactRole> list_OpptyRole = new List<OpportunityContactRole>();
		list_OpptyRole.add(new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(list_Opps[0].Id).setContactId(list_Contacts[0].Id).setRole('Benefits Admin').build());
		list_OpptyRole.add(new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(list_Opps[0].Id).setContactId(list_Contacts[1].Id).setRole('Benefits Signatory').build());
		list_OpptyRole.add(new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(list_Opps[2].Id).setContactId(list_Contacts[0].Id).setRole('Benefits Admin').build());
		list_OpptyRole.add(new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(list_Opps[2].Id).setContactId(list_Contacts[1].Id).setRole('Benefits Signatory').build());
		insert list_OpptyRole;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		list_Carriers.add(TestUtility.createTestCarrier('Carrier', 'CA', true));
		list_Carriers.add(TestUtility.createTestCarrier('Carrier', 'FA', true));

		List<Policy__c> list_Policy = new List<Policy__c>();
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[2].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('Medical Policy')
				.setBenefitType('Medical')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[2].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('Dental Policy')
				.setBenefitType('Dental')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[2].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('Vision Policy')
				.setBenefitType('Vision')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[2].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('Life Policy')
				.setBenefitType('Life')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[2].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('Long Term Disability Policy')
				.setBenefitType('Long Term Disability')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[2].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('Short Term Disability Policy')
				.setBenefitType('Short Term Disability')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objOtherAccount.Id)
				.setIdOpprtunity(list_Opps[0].Id)
				.setIdCarrier(list_Carriers[1].Id)
				.setIsSelected(true)
				.setName('Medical Policy')
				.setBenefitType('Medical')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objOtherAccount.Id)
				.setIdOpprtunity(list_Opps[0].Id)
				.setIdCarrier(list_Carriers[1].Id)
				.setIsSelected(true)
				.setName('Dental Policy')
				.setBenefitType('Dental')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objOtherAccount.Id)
				.setIdOpprtunity(list_Opps[0].Id)
				.setIdCarrier(list_Carriers[1].Id)
				.setIsSelected(true)
				.setName('Vision Policy')
				.setBenefitType('Vision')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objOtherAccount.Id)
				.setIdOpprtunity(list_Opps[0].Id)
				.setIdCarrier(list_Carriers[1].Id)
				.setIsSelected(true)
				.setName('Life Policy')
				.setBenefitType('Life')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objOtherAccount.Id)
				.setIdOpprtunity(list_Opps[0].Id)
				.setIdCarrier(list_Carriers[1].Id)
				.setIsSelected(true)
				.setName('Long Term Disability Policy')
				.setBenefitType('Long Term Disability')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objOtherAccount.Id)
				.setIdOpprtunity(list_Opps[0].Id)
				.setIdCarrier(list_Carriers[1].Id)
				.setIsSelected(true)
				.setName('Short Term Disability Policy')
				.setBenefitType('Short Term Disability')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[0].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('Dependent Care')
				.setBenefitType('Flexible Spending Account - Dependent Care')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[0].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('HSA')
				.setBenefitType('HSA')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[2].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('Dependent Care')
				.setBenefitType('Flexible Spending Account - Dependent Care')
				.setIsBase(true)
				.build()
		);
		list_Policy.add(
			new TestDataFactory.PolicyBuilder()
				.setIdAccount(objParentAccount.Id)
				.setIdOpprtunity(list_Opps[2].Id)
				.setIdCarrier(list_Carriers[0].Id)
				.setIsSelected(true)
				.setName('HSA')
				.setBenefitType('HSA')
				.setIsBase(true)
				.build()
		);
		insert list_Policy;

		Utils.skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Method to submit TTQ for New Plan Opportunity.
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void submitTTQForNewPlanOpportunity() {
		Set<String> set_RTName = new Set<String>{ 'Benefits New Plan', 'Company Opportunity' };
		Opportunity objOppNewPlan = new Opportunity();
		Opportunity objOppCompany = new Opportunity();
		for (Opportunity objOpp : [SELECT Id, AccountId, RecordType.Name FROM Opportunity WHERE RecordType.Name = :set_RTName]) {
			if (objOpp.RecordType.Name == 'Benefits New Plan') {
				objOppNewPlan = objOpp;
			} else if (objOpp.RecordType.Name == 'Company Opportunity') {
				objOppCompany = objOpp;
			}
		}

		Contact objContact = [SELECT Id FROM Contact WHERE AccountId = :objOppNewPlan.AccountId LIMIT 1];
		Test.startTest();
		Transition_to_Fulfillment__c objTTF = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOppNewPlan.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan'))
			.setContactId(objContact.Id)
			.setAccountId(objOppNewPlan.AccountId)
			.setSendOrder(false)
			.build();
		insert objTTF;

		ApexPages.Standardcontroller objSC = new ApexPages.Standardcontroller(objTTF);
		ApexPages.currentPage().getParameters().put('Id', objOppNewPlan.Id);
		NewTransitionToFulfillmentController objController = new NewTransitionToFulfillmentController(objSC);
		objController.initData();
		objController.processAcknowledgement();
		objController.cancelAction();
		objController.doesHaveAffliate();
		objController.addAffliate();
		Apexpages.currentPage().getParameters().put('indx', '0');
		objController.removeAffliate();
		objController.doesHaveAffliate();
		Apexpages.currentPage().getParameters().put('indx', '0');

		objController.idSecRole = objController.list_OpptyContactRole[0].Id;
		objController.selectSecondary();
		objController.IdPrimaryRole = objController.list_OpptyContactRole[0].Id;
		objController.list_OpptyContactRole[0].IsPrimary = true;
		objController.selectPrimary();

		objController.list_Affliates = new List<NewTransitionToFulfillmentController.AffliateWrapper>();
		objController.list_Affliates.add(new NewTransitionToFulfillmentController.AffliateWrapper());
		objController.list_Affliates[0].ttf.InternalAccount__c = objOppCompany.AccountId;

		objController.ttfRecord.Contact__c = objContact.Id;
		objController.ttfRecord.Send_Order__c = true;
		objController.disableSendOrder = false;
		objController.calculateOrderType();

		Test.stopTest();

		List<Benefit_Order__c> list_BOs = [SELECT Id FROM Benefit_Order__c WHERE Opportunity__c = :objOppNewPlan.Id];
		System.assert(list_BOs[0].Id != null, 'Benefit Order is not created for new plan Opportunity.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Method to submit TTQ for Renewal Opportunity.
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void submitTTQForRenewalOpportunity() {
		List<Opportunity> list_Opps = [SELECT Id, AccountId, RecordType.Name FROM Opportunity WHERE RecordType.Name = 'Benefits Renewal' AND Id__c = 'HIRENEWAL19875' LIMIT 1];
		OpportunityTriggerHelper.skipTrigger = true;
		list_Opps[0].Reason_for_Advising__c = 'BDC';
		list_Opps[0].Benefits_Current_Setup_Step__c = 'Completed';
		list_Opps[0].StageName = 'ER Confirm';
		update list_Opps[0];
		OpportunityTriggerHelper.skipTrigger = false;

		Contact objContact = [SELECT Id FROM Contact WHERE AccountId = :list_Opps[0].AccountId LIMIT 1];
		Test.startTest();
		Transition_to_Fulfillment__c objTTF = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(list_Opps[0].Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal'))
			.setContactId(objContact.Id)
			.setSendOrder(false)
			.build();
		insert objTTF;

		ApexPages.Standardcontroller objSC = new ApexPages.Standardcontroller(objTTF);
		ApexPages.currentPage().getParameters().put('id', objTTF.Id);
		NewTransitionToFulfillmentController objController = new NewTransitionToFulfillmentController(objSC);
		objController.initData();
		objController.ttfRecord.Contact__c = objContact.Id;
		objController.ttfRecord.Send_Order__c = true;
		objController.calculateOrderType();

		Test.stopTest();

		List<Benefit_Order__c> list_BOs = [SELECT Id FROM Benefit_Order__c WHERE Opportunity__c = :list_Opps[0].Id];
		System.assert(list_BOs[0].Id != null, 'Benefit Order is not created for renewal Opportunity.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Method to save as draft TTQ for Renewal Opportunity.
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void draftTTQForRenewalOpportunity() {
		List<Opportunity> list_Opps = [SELECT Id, AccountId, RecordType.Name FROM Opportunity WHERE RecordType.Name = 'Benefits Renewal' AND Id__c = 'HIRENEWAL19875' LIMIT 1];
		OpportunityTriggerHelper.skipTrigger = true;
		list_Opps[0].Reason_for_Advising__c = 'BDC';
		list_Opps[0].Benefits_Current_Setup_Step__c = 'Completed';
		list_Opps[0].StageName = 'ER Confirm';
		update list_Opps[0];
		OpportunityTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = true;

		Contact objContact = [SELECT Id FROM Contact WHERE AccountId = :list_Opps[0].AccountId LIMIT 1];
		Test.startTest();
		Transition_to_Fulfillment__c objTTF = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(list_Opps[0].Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal'))
			.setContactId(objContact.Id)
			.setSendOrder(false)
			.build();

		ApexPages.Standardcontroller objSC = new ApexPages.Standardcontroller(objTTF);
		ApexPages.currentPage().getParameters().put('id', list_Opps[0].Id);
		NewTransitionToFulfillmentController objController = new NewTransitionToFulfillmentController(objSC);
		objController.initData();

		objController.list_OpptyContactRole[0].Check_Additional_POC__c = true;
		objController.ttfRecord.Contact__c = objContact.Id;
		objController.ttfRecord.Send_Order__c = true;
		objController.disableSendOrder = false;
		objController.SaveTTFRecord();

		objController.list_OpptyContactRole[0].IsPrimary = true;
		objController.selectSecondary();
		Test.stopTest();

		List<Benefit_Order__c> list_BOs = [SELECT Id FROM Benefit_Order__c WHERE Opportunity__c = :list_Opps[0].Id];
		System.assert(list_BOs[0].Id != null, 'Benefit Order is not created for renewal Opportunity.');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Method to submit TTQ for Company Opportunity.
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void submitTTQForCompanyOpportunity() {
		Opportunity objOppty = [SELECT Id, AccountId FROM Opportunity WHERE RecordType.Name = 'Company Opportunity' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];

		Test.startTest();
		Transition_to_Fulfillment__c objTransition = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOppty.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer'))
			.setContactId(objContact.Id)
			.setSendOrder(false)
			.setOutgoingAddress('Test')
			.setPhysicalAddAccurate('N')
			.build();
		insert objTransition;

		ApexPages.Standardcontroller objStandardController = new ApexPages.Standardcontroller(objTransition);
		NewTransitionToFulfillmentController objNewTransition = new NewTransitionToFulfillmentController(objStandardController);
		ApexPages.currentPage().getParameters().put('Id', objTransition.Id);
		PageReference objPage = objNewTransition.initData();

		Test.stopTest();

		System.assert(objPage != null, 'TTF for Oppty should be initiated');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, to open Payroll Transition Page
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testNewTransitionPayroll() {
		Opportunity objOppty = [SELECT Id, AccountId FROM Opportunity WHERE RecordType.Name = 'Company Opportunity' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];

		Test.startTest();
		//objTransition.Medical_Switch_New_Carriers__c = objTransition.Medical_New_carriers__c = objTransition.Medical_New_carriers__c = objContact.Id;

		Transition_to_Fulfillment__c objTransition = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOppty.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer'))
			.setContactId(objContact.Id)
			.setSendOrder(false)
			.setOutgoingAddress('Test')
			.setPhysicalAddAccurate('N')
			.build();
		//insert objTransition;

		ApexPages.Standardcontroller objStandardController = new ApexPages.Standardcontroller(objTransition);
		NewTransitionToFulfillmentController objNewTransition = new NewTransitionToFulfillmentController(objStandardController);
		ApexPages.currentPage().getParameters().put('Id', objOppty.Id);
		ApexPages.currentPage().getParameters().put('CF00N1600000FDl7b_lkid', objOppty.Id);
		PageReference objPage = objNewTransition.initData();
		Test.stopTest();

		System.assert(objPage != null, 'TTF for Oppty should be initiated');
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Method to check, error while update TTF of dismissed opportunity
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testTransitionDismissed() {
		Opportunity objOppty = [SELECT Id, AccountId FROM Opportunity WHERE RecordType.Name = 'Benefits New Plan' LIMIT 1];

		OpportunityTriggerHelper.skipTrigger = true;
		objOppty.Benefits_Current_Setup_Step__c = 'Dismissed';
		update objOppty;
		OpportunityTriggerHelper.skipTrigger = false;

		Test.startTest();
		ApexPages.Standardcontroller objStandardController = new ApexPages.Standardcontroller(new Transition_to_Fulfillment__c());
		NewTransitionToFulfillmentController objNewTransition = new NewTransitionToFulfillmentController(objStandardController);
		ApexPages.currentPage().getParameters().put('Id', objOppty.Id);
		ApexPages.currentPage().getParameters().put('CF00N1600000FDl7b_lkid', objOppty.Id);
		objNewTransition.initData();
		Test.stopTest();

		ApexPages.Message[] objPageMessages = ApexPages.getMessages();
		Boolean blnMessageFound = false;
		for (ApexPages.Message objMessage : objPageMessages) {
			if (objMessage.getSummary().startsWith('The following opportunity is dismissed in Hippo') && objMessage.getSeverity() == ApexPages.Severity.Warning) {
				blnMessageFound = true;
			}
		}

		System.assert(blnMessageFound, 'Opportunity is dismissed in hippo error should exist');
	}

	/**
	 * @Author      : Deepika SAini
	 * @Description : Test Method to set Primary When Contact Role has Benefit Admin
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testSetPrimaryonTTQ() {
		List<Opportunity> list_Opps = [SELECT Id, AccountId, RecordType.Name FROM Opportunity WHERE RecordType.Name = 'Benefits Renewal' AND Id__c = 'HIRENEWAL19875' LIMIT 1];
		OpportunityTriggerHelper.skipTrigger = true;
		list_Opps[0].Reason_for_Advising__c = 'BDC';
		list_Opps[0].Benefits_Current_Setup_Step__c = 'Completed';
		list_Opps[0].StageName = 'ER Confirm';
		update list_Opps[0];
		OpportunityTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = true;

		Contact objContact = [SELECT Id FROM Contact WHERE AccountId = :list_Opps[0].AccountId LIMIT 1];
		Test.startTest();
		Transition_to_Fulfillment__c objTTF = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(list_Opps[0].Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal'))
			.setContactId(objContact.Id)
			.setSendOrder(false)
			.build();

		ApexPages.Standardcontroller objSC = new ApexPages.Standardcontroller(objTTF);
		ApexPages.currentPage().getParameters().put('id', list_Opps[0].Id);
		NewTransitionToFulfillmentController objController = new NewTransitionToFulfillmentController(objSC);
		objController.initData();

		objController.ttfRecord.Contact__c = objContact.Id;
		objController.ttfRecord.Send_Order__c = true;
		objController.disableSendOrder = false;
		objController.SaveTTFRecord();

		Test.stopTest();

		OpportunityContactRole objContactRoleRec = [SELECT Id, Check_Additional_POC__c, IsPrimary FROM OpportunityContactRole LIMIT 1];
		System.assert(objContactRoleRec.IsPrimary = true , 'Opportunity Contact Role is not set Primary');		
	}
}