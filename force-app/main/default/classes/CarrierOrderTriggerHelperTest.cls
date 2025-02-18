@isTest
private class CarrierOrderTriggerHelperTest {
	static final Id CO_RT_BENEFITS_BOR = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
	static final Id BO_RT_BENEFITS_BOR = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
	static final Id OPP_RT_BENEFITS_BOR = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');
	static final Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
	static final Id OPP_RT_BENEFITS_RENEWAL = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
	static final Id OPP_RT_BENEFITS_CHANGE = Cache.getRecordTypeId('Opportunity', 'Benefits Change');
	static final String OPP_STAGE_NAME = 'SAL';
	static final Id ID_LOGGED_USER = UserInfo.getUserId();
	static final Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
	static final Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
	static final Id CO_RT_RENEWAL = Cache.getRecordTypeId('Carrier_Order__c', 'Renewal');
	static final Id BO_RT_RENEWAL = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
	static final Id CO_RT_CHANGE = Cache.getRecordTypeId('Carrier_Order__c', 'Benefit Change');
	static final Id BO_RT_CHANGE = Cache.getRecordTypeId('Benefit_Order__c', 'Change');
	static final String CO_STAGENAME_READYFORSUBMISSIONPREP = 'Ready for Submission Prep';
	static final String CO_STAGENAME_READYFORCONFIRMATION = 'Ready for Confirmation';

	@testsetup
	static void setupTestData() {
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Confirmation_Automation_Eligible_Carrier__mdt objCarrierConfiguration = [SELECT Carrier_Id__c FROM Confirmation_Automation_Eligible_Carrier__mdt WHERE Carrier_Id__c != NULL LIMIT 1];

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder()
			.setName('TEST CARRIER')
			.setState(objState.Id)
			.setId('25')
			.setCarrierId(objCarrierConfiguration.Carrier_Id__c)
			.setGroupSubmissionEvent('Same')
			.build();
		list_Carriers.add(objCarrier);

		Carrier__c objCarrier1 = new TestDataFactory.CarrierBuilder().setName('Alegeus').setPartnerType('TAdA').setUniqueName('Alegeus').setId('Alegeus001').setState('AK').build();
		list_Carriers.add(objCarrier1);

		Carrier__c objCarrierBeforeMonth = new TestDataFactory.CarrierBuilder()
			.setName('Before Month Carrier')
			.setState(objState.Id)
			.setId('11')
			.setNewPlanSubmissionEvent('Before Month')
			.setMemberSubmissionEvent('Before Month')
			.setGroupSubmissionEvent('Before Month')
			.setNewPlanVariationNum1(10)
			.setMemberVariationNumber(1)
			.setGroupVariationNumber(1)
			.setMemberVariationNumber2(1)
			.setGroupVariationNumber2(1)
			.build();
		list_Carriers.add(objCarrierBeforeMonth);

		Carrier__c objCarrierAfterMonth = new TestDataFactory.CarrierBuilder()
			.setName('After Month Carrier')
			.setState(objState.Id)
			.setId('22')
			.setNewPlanSubmissionEvent('After Month')
			.setMemberSubmissionEvent('After Month')
			.setGroupSubmissionEvent('After Month')
			.setNewPlanVariationNum1(10)
			.setMemberVariationNumber(1)
			.setGroupVariationNumber(1)
			.setMemberVariationNumber2(1)
			.setGroupVariationNumber2(1)
			.setNewPlanVariationNum2(5)
			.build();
		list_Carriers.add(objCarrierAfterMonth);

		Carrier__c objCarrierBeforeDays = new TestDataFactory.CarrierBuilder()
			.setName('Before Days Carrier')
			.setState(objState.Id)
			.setId('33')
			.setNewPlanSubmissionEvent('Before Days')
			.setMemberSubmissionEvent('Before Days')
			.setGroupSubmissionEvent('Before Days')
			.setNewPlanVariationNum1(10)
			.setMemberVariationNumber(1)
			.setGroupVariationNumber(1)
			.setMemberVariationNumber2(1)
			.setGroupVariationNumber2(1)
			.build();
		list_Carriers.add(objCarrierBeforeDays);

		Carrier__c objCarrierAfterDays = new TestDataFactory.CarrierBuilder()
			.setName('After Days Carrier')
			.setState(objState.Id)
			.setId('44')
			.setNewPlanSubmissionEvent('After Days')
			.setMemberSubmissionEvent('After Days')
			.setGroupSubmissionEvent('After Days')
			.setNewPlanVariationNum1(10)
			.setMemberVariationNumber(1)
			.setGroupVariationNumber(1)
			.setMemberVariationNumber2(1)
			.setGroupVariationNumber2(1)
			.build();
		list_Carriers.add(objCarrierAfterDays);

		Carrier__c objCarrierSame = new TestDataFactory.CarrierBuilder()
			.setName('Before Month Carrier')
			.setState(objState.Id)
			.setId('55')
			.setNewPlanSubmissionEvent('same')
			.setMemberSubmissionEvent('same')
			.setGroupSubmissionEvent('same')
			.setNewPlanVariationNum1(10)
			.setMemberVariationNumber(1)
			.setGroupVariationNumber(1)
			.setMemberVariationNumber2(1)
			.setGroupVariationNumber2(1)
			.build();
		list_Carriers.add(objCarrierSame);

		insert list_Carriers;

		list_Carriers = new List<Carrier__c>();
		objCarrierAfterMonth.Member_Submission_Event__c = 'After Month';
		objCarrierAfterMonth.Group_Submission_Event__c = 'After Month';
		objCarrierAfterMonth.New_Plan_Submission_Event__c = 'After Month';
		list_Carriers.add(objCarrierAfterMonth);

		objCarrierBeforeDays.Group_Submission_Event__c = 'Before Days';
		objCarrierBeforeDays.Member_Submission_Event__c = 'Before Days';
		objCarrierBeforeDays.New_Plan_Submission_Event__c = 'Before Days';
		list_Carriers.add(objCarrierBeforeDays);

		objCarrierAfterDays.Group_Submission_Event__c = 'After Days';
		objCarrierAfterDays.Member_Submission_Event__c = 'After Days';
		objCarrierAfterDays.New_Plan_Submission_Event__c = 'After Days';
		list_Carriers.add(objCarrierAfterDays);

		objCarrierSame.Group_Submission_Event__c = 'same';
		objCarrierSame.Member_Submission_Event__c = 'same';
		objCarrierSame.New_Plan_Submission_Event__c = 'same';
		list_Carriers.add(objCarrierSame);

		list_Carriers.add(objCarrierBeforeMonth);

		update list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		Account objParentAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989003').setRecordTypeId('Company').build();
		list_Accounts.add(objParentAccount);

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989005').setRecordTypeId('Company').build();
		list_Accounts.add(objCompanyAccount);

		Account objCompanyAccountBlocked = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('10098900787').setRecordTypeId('Company').build();
		list_Accounts.add(objCompanyAccountBlocked);

		insert list_Accounts;

		Account objChildAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989004').setRecordTypeId('Company').setParentAccount(objParentAccount.Id).build();
		insert objChildAccount;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Opportunity objOppBOR = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_BOR)
			.setAccountId(objAccount.Id)
			.setStage(OPP_STAGE_NAME)
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objOppBOR);

		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objParentAccount.Id)
			.setStage(OPP_STAGE_NAME)
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		Opportunity objChildOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objChildAccount.Id)
			.setStage(OPP_STAGE_NAME)
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objChildOppNewPlan);

		Opportunity objRenewalOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_RENEWAL)
			.setAccountId(objAccount.Id)
			.setStage(OPP_STAGE_NAME)
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objRenewalOpp);

		Opportunity objNewPlanOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objCompanyAccount.Id)
			.setStage(OPP_STAGE_NAME)
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objNewPlanOpp);

		Opportunity objNewPlanOppBlocked = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objCompanyAccountBlocked.Id)
			.setStage(OPP_STAGE_NAME)
			.setName('Test Opp')
			.setCloseDate(System.Today())
			.build();
		list_Opportunities.add(objNewPlanOppBlocked);

		Opportunity objChangeOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_CHANGE)
			.setAccountId(objCompanyAccount.Id)
			.setStage(OPP_STAGE_NAME)
			.setName('Test Opp')
			.setCloseDate(System.Today())
			.build();
		list_Opportunities.add(objChangeOpp);
		insert list_Opportunities;

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan, objChildOppNewPlan, objRenewalOpp, objNewPlanOpp, objNewPlanOppBlocked });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Benefit_Order__c objBORBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_BENEFITS_BOR)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objOppBOR.Id)
			.setStatusDetail('Owner only group')
			.setType('BOR + TAdA')
			.setTotalNumberOfDocuments(1)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objBORBO);

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);

		Benefit_Order__c objRenewalBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_RENEWAL)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objRenewalOpp.Id)
			.setOwnerID(UserInfo.getUserId())
			.setCoverageEffectiveDate(System.today())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objRenewalBO);

		Benefit_Order__c objNewPlanBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objNewPlanOpp.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objNewPlanBO);

		Benefit_Order__c objNewPlanBOBlocked = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objNewPlanOppBlocked.Id)
			.setOwnerID(UserInfo.getUserId())
			.setStatus('Blocked')
			.setBlockedReason('Carrier Reply')
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objNewPlanBOBlocked);

		Benefit_Order__c objChangeBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_CHANGE)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objChangeOpp.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objChangeBO);

		insert list_BenefitOrders;

		Carrier_Order__c objBORCO1 = new TestDataFactory.CarrierOrderBuilder()
			.setName('TestCarrierOrder')
			.setCarrier(objCarrier.Id)
			.setStartDate(System.today())
			.setRecordTypeId(CO_RT_BENEFITS_BOR)
			.setImplementationStage('Qualification')
			.setFacilitator2PlanBuild('Y')
			.setResignRequired('No')
			.setContributionPerTheER('test')
			.setBenefitOrder(objBORBO.Id)
			.setOwnerID(UserInfo.getUserId())
			.build();
		list_CarrierOrders.add(objBORCO1);

		Carrier_Order__c objBORCO2 = new TestDataFactory.CarrierOrderBuilder()
			.setName('TestCarrierOrder- ALegeus')
			.setCarrier(objCarrier1.Id)
			.setStartDate(System.today())
			.setRecordTypeId(CO_RT_BENEFITS_BOR)
			.setImplementationStage('Qualification')
			.setFacilitator2PlanBuild('Y')
			.setResignRequired('No')
			.setContributionPerTheER('test')
			.setBenefitOrder(objBORBO.Id)
			.setOwnerID(UserInfo.getUserId())
			.build();
		list_CarrierOrders.add(objBORCO2);

		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Parent Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		Carrier_Order__c objRenewalCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Confirmation Automation Eligible')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objRenewalBO.Id)
			.setOrderPlayableDate(System.today().addDays(10))
			.setImplementationStage('Ready for Confirmation')
			.setEligibleForConfirmationAutomation(true)
			.setOwnerID(UserInfo.getUserId())
			.build();
		list_CarrierOrders.add(objRenewalCarrierOrder);

		Carrier_Order__c objNewPlanCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Confirmation Automation')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objNewPlanBO.Id)
			.setOrderPlayableDate(System.today().addDays(10))
			.setOwnerID(UserInfo.getUserId())
			.build();
		list_CarrierOrders.add(objNewPlanCarrierOrder);

		Carrier_Order__c objNewPlanCarrierOrderBlocked = new TestDataFactory.CarrierOrderBuilder()
			.setName('BO Blocked')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objNewPlanBOBlocked.Id)
			.setImplementationStage('Qualification')
			.setOwnerID(UserInfo.getUserId())
			.build();
		list_CarrierOrders.add(objNewPlanCarrierOrderBlocked);

		insert list_CarrierOrders;

		Benefit_Order__c objChildBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objChildOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setParentBenefitOrder(objParentBONewPlan.Id)
			.setIsMultiEIN(false)
			.build();
		insert objChildBO;

		Carrier_Order__c objChildCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('TestCarrierOrderChild')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objChildBO.Id)
			.setParentCarrierOrder(objParentCarrierOrder.Id)
			.setOrderPlayableDate(System.today().addDays(10))
			.setIsMultiEIN(true)
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objChildCO;

		Carrier_Order_Line_Item__c objCOLineItem = new TestDataFactory.CarrierOrderLineItemBuilder()
			.setCarrierOrder(objBORCO1.Id)
			.setBenefitTypes('Flexible Spending Account - Medical')
			.setRenewalDate(System.today().addDays(10))
			.build();
		insert objCOLineItem;

		Task objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_BENEFIT_FULFILLMENT_RT_ID)
				.setWhatId(objBORCO1.Id)
				.setStatus(TaskUtil.TASK_STATUS_CONNECT)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.build();
			insert objTask;

		PriceBook2 objPriceBook2 = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPriceBook2;

		List<Product2> list_Products = new List<Product2>();
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Medical').setFamily('Benefit').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Dental').setFamily('Employee').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Vision').setFamily('Employee').build());
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Life').setFamily('Employee').build());
		insert list_Products;

		List<PricebookEntry> list_PricebooksEntry = new List<PricebookEntry>();
		list_PricebooksEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_PricebooksEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_PricebooksEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[2].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_PricebooksEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[3].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_PricebooksEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(objPriceBook2.Id).setIsActive(true).build());
		list_PricebooksEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(objPriceBook2.Id).setIsActive(true).build());
		list_PricebooksEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[2].Id).setUnitPrice(5).setPriceBookId(objPriceBook2.Id).setIsActive(true).build());
		list_PricebooksEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[3].Id).setUnitPrice(5).setPriceBookId(objPriceBook2.Id).setIsActive(true).build());
		insert list_PricebooksEntry;
	}

	static void skipTriggers() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		CaseTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		CarrierTriggerHelper.skipTrigger = true;
	}

	/**
	 * @description  This method is used to test the case creation for the related CO with Benefits Change Case record type .
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testCOWithChangeCase() {
		Test.startTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_CHANGE];

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Name != 'Alegeus' LIMIT 1];

		Carrier_Order__c objChangeCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Carrier Order Name')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_CHANGE)
			.setBenefitOrder(objBO.Id)
			.setImplementationStage('Ready for Submission Prep')
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('Carrier Swtich')
			.setGroupNumber('12346; 4562563;5624855')
			.build();
		insert objChangeCarrierOrder;
		Test.stopTest();

		Id idCaseRecordType = Cache.getRecordTypeId('Case', 'Benefits Change Case');
		Case objCase = [SELECT Id, Group_Number__c FROM Case WHERE RecordTypeId = :idCaseRecordType];

		System.assertEquals(objCase.Group_Number__c, '12346', 'Case is created with Group_Number__c as : 12346');
	}

	/**
	 * @description  This method is used to test the functionality of handle cancel CO .
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testHandleCancelCarrierOrder() {
		Test.startTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id, Implementation_Stage__c, Benefit_Order__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_BENEFITS_BOR AND Name = 'TestCarrierOrder'];

		objCarrierOrder.Implementation_Stage__c = 'Canceled';
		update objCarrierOrder;

		Test.stopTest();

		// type chnaged from BOR +TADA to BOR TAdA Only
		System.assertEquals([SELECT Id, Type__c FROM Benefit_Order__c WHERE Id = :objCarrierOrder.Benefit_Order__c].Type__c, 'BOR TAdA Only', 'Type of BO is set to BOR TAdA Only');
	}

	/**
	 * @description  This method is used to test the functionality of updating Implementation stage on CO .
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testUpdateImplementationStage() {
		Test.startTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id, Implementation_Stage__c, Benefit_Order__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_BENEFITS_BOR AND Name = 'TestCarrierOrder'];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		Test.stopTest();

		System.assertEquals(
			[SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Id = :objCarrierOrder.Benefit_Order__c].Order_Status__c,
			'Qualification',
			'Order_Status__c of BO is set as : Qualification'
		);
	}

	/**
	 * @description  This method is used to test the functionality for Blocked CO .
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testBOBlockedStatusNotChanged() {
		Test.startTest();

		Carrier_Order__c objCO = [SELECT Id, Implementation_Stage__c, Benefit_Order__c FROM Carrier_Order__c WHERE Name = 'BO Blocked'];
		objCO.Implementation_Stage__c = 'Ready for Submission Prep';
		update objCO;

		Test.stopTest();

		Benefit_Order__c objBO = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Id = :objCO.Benefit_Order__c];

		System.assertEquals(objBO.Order_Status__c, 'Blocked', 'Order_Status__c of BO is set as : Blocked');
	}

	/**
	 * @description  This method is used to test the functionality for Case creation of type Carrier Submission .
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testCaseProcess() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		List<PriceBook2> list_PriceBook = [SELECT Id FROM PriceBook2 LIMIT 1];

		Account objAccount = new TestDataFactory.AccountBuilder().setName('testingforTask').setZPCompanyId('679800112211').setRecordTypeId('Company').build();
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('Engaged')
			.setCloseDate(System.Today())
			.setName('Test Opp 1')
			.setPriceBookId(list_PriceBook.get(0).Id)
			.setNumberOfEE(12)
			.build();
		insert objOpportunity;

		Carrier__c objCarrierRec = [SELECT Id, Group_Submission_Event__c FROM Carrier__c WHERE Group_Submission_Event__c = 'After Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('Test Benefit Order')
			.setOpp(objOpportunity.Id)
			.setOwnerID(ID_LOGGED_USER)
			.setStatus('New')
			.setCoverageEffectiveDate(System.today())
			.setPushRateReason('Not enough EE enrolled')
			.setIsMultiEIN(false)
			.build();
		insert objBenefitOrder;

		Test.startTest();

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('CarrierORderHandlerTest')
			.setCarrier(objCarrierRec.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objCO;

		objBenefitOrder.Order_Status__c = 'QA';
		update objBenefitOrder;

		Test.stopTest();

		List<Carrier_Order__c> list_CarrierOrders = [
			SELECT Id, OwnerId, (SELECT Id, Type FROM Cases__r WHERE Origin = 'Hippo' AND Status = 'Open')
			FROM Carrier_Order__c
			WHERE Benefit_Order__c = :objBenefitOrder.Id
		];

		System.assert(list_CarrierOrders[0].OwnerId == Label.Carrier_Implementation_Queue, 'CO is assigned to the Queue');
		System.assert(list_CarrierOrders[0].Cases__r.size() > 0, 'Cases are created for the CO');
		System.assert(list_CarrierOrders[0].Cases__r[0].Type == 'Carrier Submission', 'Case related to CO has Type as :Carrier Submission');
	}

	/**
	 * @description  This method is used to test the functionality for Submission_Deadline__c assignment.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void populateNoTadaDeadlineDateNewPlanAfterMonthVariationEvent() {
		BenefitOrderHelper.skipTrigger = true;

		Test.startTest();

		Benefit_Order__c objBenefitOrder = [SELECT Id, OwnerId, Coverage_Effective_Date__c, Push_Rate_Reason__c FROM Benefit_Order__c WHERE RecordType.Name = 'New Plan' LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 30);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier__c objCarrier = [SELECT Id, New_Plan_Submission_Event__c FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'After Month' LIMIT 1];

		objCarrier.New_Plan_Submission_Event__c = 'After Month';
		update objCarrier;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('TAdA: No Pre OE Setup')
			.build();
		insert objCarrierOrder;

		Test.stopTest();

		List<Carrier_Order__c> listCOs = [SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];

		System.assert(listCOs[0].Submission_Deadline__c != null, 'CO has Submission_Deadline__c value');
	}

	/**
	 * @description  This method is used to test the Queue assignmnet for CO.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testAssignOwnerAndSubPrepDateForCONewPlan() {
		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Name != 'Alegeus' LIMIT 1];

		//Parent Carrier Order
		Carrier_Order__c objParentCarrierOrder = [SELECT Id FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_NEW_PLAN AND Parent_Carrier_Order__c = NULL AND Name = 'Parent Carrier Order'];

		//Child Data
		Benefit_Order__c objBOChild = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN AND Parent_Benefit_Order__c != NULL];

		CarrierOrderTriggerHelper.skipTrigger = false;
		objParentCarrierOrder.Implementation_Stage__c = CO_STAGENAME_READYFORSUBMISSIONPREP;
		update objParentCarrierOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setImplementationStage(CO_STAGENAME_READYFORCONFIRMATION)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBOChild.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setParentCarrierOrder(objParentCarrierOrder.Id)
			.build();
		insert objCarrierOrder;

		Test.stopTest();

		System.assertNotEquals([SELECT OwnerId FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].OwnerId, Label.Carrier_Implementation_Queue, 'CO is assigned to the Queue');
	}

	/**
	 * @description  This method is used to test the population of the Checklist_Completed_Date_Time__c - positive case.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testUpdateChecklistCompletedDateTimePositive() {
		Test.startTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_BENEFITS_BOR AND Name = 'TestCarrierOrder'];

		CarrierOrderTriggerHelper.skipTrigger = false;
		objCarrierOrder.Checklist_For_Plan_Build__c = true;
		objCarrierOrder.Checklist_For_Enrollment_Review__c = true;
		objCarrierOrder.Checklist_Completed_Date_Time__c = null;
		update objCarrierOrder;

		Test.stopTest();

		System.assertNotEquals(
			[SELECT Checklist_Completed_Date_Time__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Checklist_Completed_Date_Time__c,
			null,
			'Checklist completed date time should not be null'
		);
	}

	/**
	 * @description  This method is used to test the population of the Checklist_Completed_Date_Time__c - Negative case.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testUpdateChecklistCompletedDateTimeNegative() {
		Test.startTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_BENEFITS_BOR AND Name = 'TestCarrierOrder'];

		CarrierOrderTriggerHelper.skipTrigger = false;
		objCarrierOrder.Checklist_For_Plan_Build__c = true;
		objCarrierOrder.Checklist_For_Enrollment_Review__c = false;
		objCarrierOrder.Checklist_Completed_Date_Time__c = null;
		update objCarrierOrder;

		Test.stopTest();

		System.assertEquals(
			[SELECT Checklist_Completed_Date_Time__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Checklist_Completed_Date_Time__c,
			null,
			'Checklist completed date time should not be null'
		);
	}

	/**
	 * @description  This method is used to test the functionality of CO after canceling and population of Submission_Deadline__c on QA Lines of Coverage.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void canceledImplementationStage() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;

		List<Policy__c> list_Policies = new List<Policy__c>();
		List<QA_Lines_Of_Coverage__c> list_LinesOfCoverages = new List<QA_Lines_Of_Coverage__c>();

		List<PriceBook2> list_PriceBook = [SELECT Id FROM PriceBook2 LIMIT 1];

		Opportunity objOpportunity = [SELECT Id, Pricebook2Id, NumberOfEmployees__c FROM Opportunity WHERE RecordTypeId = :OPP_RT_BENEFITS_NEW_PLAN LIMIT 1];

		objOpportunity.Pricebook2Id = list_PriceBook.get(0).Id;
		objOpportunity.NumberOfEmployees__c = 12;
		objOpportunity.HI_Effective_Date__c = system.today();
		update objOpportunity;

		Test.startTest();

		Benefit_Order__c objBenefitOrder = [SELECT Id, Status_Detail__c FROM Benefit_Order__c WHERE RecordType.Name = 'New Plan' AND Opportunity__c = :objOpportunity.Id];
		objBenefitOrder.Status_Detail__c = 'Cancelled - Duplicate Order';
		update objBenefitOrder;

		QA_Sheet__c objQASheet = new TestDataFactory.QASheetBuilder().setBenefitOrderId(objBenefitOrder.Id).setRecordTypeId(Cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan')).build();
		insert objQASheet;

		Transition_to_Fulfillment__c objTTFRecord = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpportunity.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan'))
			.setSendOrder(true)
			.build();
		insert objTTFRecord;

		Carrier__c objAlegeusCarrier = [SELECT Id FROM Carrier__c WHERE Name = 'Alegeus'];

		Carrier_Version_Detail__c objCarrierVersionDetail = new TestDataFactory.CarrierVersionDetailBuilder()
			.setEffetciveDate(System.today().addDays(-30))
			.setVersionKey('Alegeus001')
			.setCarrierId(objAlegeusCarrier.Id)
			.setNumberOfPlansAllowedBasedOnFTE('Demo Text')
			.setNumberOfPlansAllowedOnEnrolleCount('Demo Text')
			.build();
		insert objCarrierVersionDetail;

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder()
			.setName('Test Policy1')
			.setIdOpprtunity(objOpportunity.Id)
			.setIdCarrier(objAlegeusCarrier.Id)
			.setBenefitType('Medical')
			.setIsSelected(true)
			.setContributionSchemeType('Percentage Of Base')
			.setIsBase(true)
			.build();
		list_Policies.add(objPolicy);

		Policy__c objPolicyNonBase = new TestDataFactory.PolicyBuilder()
			.setName('Test Policy1')
			.setIdOpprtunity(objOpportunity.Id)
			.setIdCarrier(objAlegeusCarrier.Id)
			.setBenefitType('Medical')
			.setIsSelected(true)
			.setContributionSchemeType('Percentage Of Base')
			.setIsBase(false)
			.build();
		list_Policies.add(objPolicyNonBase);

		Policy__c objPolicyDental = new TestDataFactory.PolicyBuilder()
			.setName('Test Policy1')
			.setIdOpprtunity(objOpportunity.Id)
			.setIdCarrier(objAlegeusCarrier.Id)
			.setBenefitType('Dental')
			.setIsSelected(true)
			.setContributionSchemeType('Percentage Of Base')
			.setIsBase(true)
			.build();
		list_Policies.add(objPolicyDental);

		insert list_Policies;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test CarrierORderHandlerTest')
			.setCarrier(objAlegeusCarrier.Id)
			.setRecordTypeId(CO_RT_CHANGE)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setOrderAssignment('New To Gusto')
			.setBenefitTypes('Test')
			.build();
		insert objCarrierOrder;

		QA_Lines_Of_Coverage__c objQALineOfCoverage = new TestDataFactory.QALineOfCoverageBuilder()
			.setQASheetId(objQaSheet.Id)
			.setCarrierOrderId(objCarrierOrder.Id)
			.setLinesOfCoverage('Medical')
			.setBenefitSelectedCarrier(objAlegeusCarrier.Id)
			.build();
		list_LinesOfCoverages.add(objQALineOfCoverage);

		insert list_LinesOfCoverages;

		objCarrierOrder = [SELECT Id, Submission_Deadline__c, Implementation_Stage__c, Stage_Detail__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		objCarrierOrder.Submission_Deadline__c = System.today();
		update objCarrierOrder;

		objCarrierOrder.Implementation_Stage__c = 'Canceled';
		objCarrierOrder.Stage_Detail__c = 'Cancelled - Duplicate Order';
		update objCarrierOrder;

		Test.stopTest();

		List<QA_Lines_Of_Coverage__c> list_QARecords = [SELECT Id, Submission_Deadline__c FROM QA_Lines_Of_Coverage__c WHERE Id = :objQALineOfCoverage.Id];

		if (list_QARecords.size() > 0) {
			System.assert(list_QARecords[0].Submission_Deadline__c != null, 'Submission_Deadline__c on QA_Lines_Of_Coverage__c is not null.');
		}
	}

	/**
	 * @description  This method is used to populate the Submitted_Completed_Datetime__c, Member_Submission_Date__c and Group_Submission_Date__c on CO.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testCarrierOrderAutomationStatusCheck() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CarrierTriggerHelper.skipTrigger = true;

		Opportunity objOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId = :OPP_RT_BENEFITS_RENEWAL LIMIT 1];
		objOpportunity.CloseDate = System.Today();
		objOpportunity.StageName = OPP_STAGE_NAME;
		update objOpportunity;

		Benefit_Order__c objBenefitOrder = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE Opportunity__c = :objOpportunity.Id LIMIT 1];

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Member_Submission_Event__c = 'After Month' LIMIT 1];
		Carrier__c objCarrierBeforeDays = [SELECT Id FROM Carrier__c WHERE Member_Submission_Event__c = 'Before Days' LIMIT 1];
		Carrier__c objCarrierAfterDays = [SELECT Id FROM Carrier__c WHERE Member_Submission_Event__c = 'After Days' LIMIT 1];

		Transition_to_Fulfillment__c objTTFRecord = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpportunity.Id)
			.setAccountId(objOpportunity.AccountId)
			.setHSARenewalDate(System.today())
			.setFSARenewalDate(System.today())
			.setDCARenewalDate(System.today())
			.setTypeOfTADA('Flexible Spending Account - Dependent Care;Commuter')
			.setMultiEIN('Y')
			.setSendOrder(true)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal'))
			.build();
		TransitionToFulfilmentTriggerHelper.skipTrigger = true;
		insert objTTFRecord;

		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		objBenefitOrder.Transition_To_Fulfillment__c = objTTFRecord.Id;
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOrderType('New to Gusto')
			.setGroupNumber('2')
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objCarrierOrder;

		objCarrierOrder = [SELECT Id, Implementation_Stage__c, Automation_Status__c, Automation_Message__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id LIMIT 1];

		objCarrierOrder.Carrier__c = objCarrierBeforeDays.Id;
		objCarrierOrder.Implementation_Stage__c = 'Ready for Submission Prep';
		update objCarrierOrder;

		objCarrierOrder.Automation_Status__c = 'Failed';
		update objCarrierOrder;

		objCarrierOrder.Carrier__c = objCarrierAfterDays.Id;
		objCarrierOrder.Automation_Status__c = 'Completed';
		update objCarrierOrder;

		objCarrierOrder.Automation_Status__c = 'Completed';
		objCarrierOrder.Automation_Message__c = 'Manual Review Required';
		update objCarrierOrder;

		Test.stopTest();

		List<Carrier_Order__c> list_CarrierOrder = [
			SELECT Id, Submitted_Completed_Datetime__c, Implementation_Stage__c, Member_Submission_Date__c, Group_Submission_Date__c, Carrier__r.name
			FROM Carrier_Order__c
			WHERE Id = :objCarrierOrder.Id
		];

		System.assert(list_CarrierOrder[0].Member_Submission_Date__c != null, 'Member_Submission_Date__c populated on CO');
		System.assert(list_CarrierOrder[0].Group_Submission_Date__c != null, 'Group_Submission_Date__c populated on CO');
	}

	/**
	 * @description  This method is used to test the assignment of Confirmation owner to CO.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void updateFollowUpDateConfirmation() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'Before Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		objBenefitOrder.Order_Status__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('TAdA: Pre OE Setup')
			.setConfirmationOwner(ID_LOGGED_USER)
			.setImplementationStage(CarrierOrderUtil.STAGE_PENDING_CONFIRMATION)
			.build();
		insert objCarrierOrder;

		objCarrierOrder.Follow_Up_Date__c = System.now().date();
		update objCarrierOrder;

		Test.stopTest();

		List<Carrier_Order__c> list_CarrierOrder = [SELECT Id, Confirmation_Owner__c, Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];

		System.assert(list_CarrierOrder[0].Implementation_Stage__c == 'Ready for Confirmation', 'CO stage again set as: Ready for Confirmation');
	}

	/**
	 * @description  This method is used to test the setSubmissionForTadaPreOESetup Method.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testsetSubmissionForTadaPreOESetup() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'Before Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		objBenefitOrder.Order_Status__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('TAdA: Pre OE Setup')
			.setConfirmationOwner(ID_LOGGED_USER)
			.setImplementationStage(CarrierOrderUtil.STAGE_PENDING_CONFIRMATION)
			.build();
		insert objCarrierOrder;

		objCarrierOrder.Follow_Up_Date__c = System.now().date();
		update objCarrierOrder;

		Test.stopTest();

		List<Carrier_Order__c> list_CarrierOrder = [SELECT Id, Group_Submission_Date__c,Confirmation_Owner__c, Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];

		System.assert(list_CarrierOrder[0].Group_Submission_Date__c == system.today().addDays(3), true);
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void updateFollowUpDateConfirmationAfter15Date() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'Before Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('TAdA: Pre OE Setup')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		Test.stopTest();

		System.assertNotEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c, null, 'Submission Deadline is not blank.');
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[After Month].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineDateAfterMonth() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'After Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;
		BenefitOrderHelper.skipTrigger = false;
		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('TAdA: Pre OE Setup')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		objCarrierOrder = [SELECT Id, Effective_Date_Changed_on__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		Date dtSubmissionDate = objCarrierOrder.Submission_Deadline__c;

		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2019, 10, 1);
		update objBenefitOrder;
		Test.stopTest();
		System.assertEquals(
			[SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c,
			dtSubmissionDate,
			'Submission Deadline value is not changed.'
		);
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[Before Month].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineDateBeforeMonth() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'Before Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('TAdA: No Pre OE Setup')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		objCarrierOrder = [SELECT Id, Effective_Date_Changed_on__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		Date dtSubmissionDate = objCarrierOrder.Submission_Deadline__c;

		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		update objBenefitOrder;

		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		/**
            whether Coverage_Effective_Date__c is starting of month or after mid of month
            if the Carrier is of Before Month New Plan Event for TAdA: No Pre OE Setup Record
            Submission will alway calculated from the starting of Month using New_Plan_Variation_Num2__c
            that's why value is same
        **/
		System.assertEquals(
			[SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c,
			dtSubmissionDate,
			'Submission Deadline has same value as it before.'
		);
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[After Month].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineDateAfterMonthTadaNoPre() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'After Month' LIMIT 1];
		objCarrier.New_Plan_Variation_Num1__c = 10;
		objCarrier.New_Plan_Variation_Num2__c = 1;
		update objCarrier;

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('TAdA: No Pre OE Setup')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		objCarrierOrder = [SELECT Id, Effective_Date_Changed_on__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		Date dtSubmissionDate = objCarrierOrder.Submission_Deadline__c;

		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		update objBenefitOrder;

		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		System.assertEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c, dtSubmissionDate, 'Submission Deadline is not chnaged.');
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[Before Month Non TADA].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineDateBeforeMonthNonTADA() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'Before Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		objCarrierOrder = [SELECT Id, Effective_Date_Changed_on__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		Date dtSubmissionDate = objCarrierOrder.Submission_Deadline__c;

		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		update objBenefitOrder;

		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		/**
            whether Coverage_Effective_Date__c is starting of month or after mid of month
            if the Carrier is of Before Month New Plan Event for Non TADA Record
            Submission will alway calculated from the starting of Month
            that's why value is same
        **/
		System.assertEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c, dtSubmissionDate, 'Submission Deadline is not Changed.');
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[After Month Non TADA].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineDateAfterMonthNonTADA() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'After Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		objCarrierOrder = [SELECT Id, Effective_Date_Changed_on__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		update objBenefitOrder;

		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		System.assertNotEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c, null, 'Submission Deadline is not blank.');
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[Before Month Non TADA with Num2].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineBeforeMonthNonTADAWithNum2() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'Before Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		objCarrierOrder = [SELECT Id, Effective_Date_Changed_on__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		Date dtSubmissionDate = objCarrierOrder.Submission_Deadline__c;

		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		update objBenefitOrder;

		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		System.assertNotEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c, null, 'Submission Deadline is not null.');
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[Before days Non TADA with Num2].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineBeforeDaysNonTADAWithNum2() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'Before days' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		Date dtSubmissionDate = [SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c;

		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 8, 1);
		update objBenefitOrder;

		objCarrierOrder.Order_Type__c = 'TAdA: No Pre OE Setup';
		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		/**
		 * on th basis of Order type Submission deadline changes
		 */
		System.assertNotEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c, dtSubmissionDate, 'Submission Deadline is changed.');
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[After days Non TADA with Num2].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineAfterDaysNonTADAWithNum2() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'Before days' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		objCarrierOrder = [SELECT Id, Effective_Date_Changed_on__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		Date dtSubmissionDate = objCarrierOrder.Submission_Deadline__c;

		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 1);
		update objBenefitOrder;

		objCarrierOrder.Order_Type__c = 'TAdA: No Pre OE Setup';
		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		System.assertNotEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c, null, 'Submission Deadline is not null.');
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[same Non TADA with Num2].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineSameNonTADAWithNum2() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'same' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 9, 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;

		Date dtSubmissionDate = [SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c;

		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(2018, 8, 1);
		update objBenefitOrder;

		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		System.assertNotEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c, dtSubmissionDate, 'Submission Deadline is changed.');
	}

	/**
	 * @description  This method is used to test the functionality of Submission_Deadline__c assignment[After Month Non TADA with Num2].
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void calculateSubmissionDeadlineAfterMonthNonTADAWithNum2() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'After Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id, Name FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN AND Name = 'TEST BENEFIT ORDER 1' LIMIT 1];
		Date dtToday = System.Today();
		delete [SELECT Id FROM Carrier_Order__c WHERE Benefit_Order__c = :objBenefitOrder.Id];
		objBenefitOrder.OwnerId = ID_LOGGED_USER;
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(dtToday.year(), (dtToday.month() - 3), 20);
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setConfirmationOwner(ID_LOGGED_USER)
			.build();
		insert objCarrierOrder;
		BenefitOrderHelper.skipTrigger = true;
		objCarrierOrder = [SELECT Id, Effective_Date_Changed_on__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		objBenefitOrder.Coverage_Effective_Date__c = Date.newInstance(dtToday.year(), (dtToday.month() - 1), 1);
		update objBenefitOrder;

		objCarrierOrder.Effective_Date_Changed_on__c = System.now();
		update objCarrierOrder;

		Test.stopTest();

		System.assertNotEquals(
			[SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.id].Submission_Deadline__c,
			objCarrierOrder.Submission_Deadline__c,
			'Submission Deadline is changed.'
		);
	}

	/**
	 * @description  This method is used to test the Carrier Order Creation.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void MultiEINCOUpdates() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		Test.startTest();

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		Opportunity objOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId = :OPP_RT_BENEFITS_BOR LIMIT 1];

		List<Carrier__c> list_Carriers = new List<Carrier__c>();

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Group_Submission_Event__c = 'Before Month' LIMIT 1];
		Carrier__c objCarrierAfterDays = [SELECT Id FROM Carrier__c WHERE Group_Submission_Event__c = 'After Days' LIMIT 1];
		Carrier__c objCarrierBeforeDays = [SELECT Id FROM Carrier__c WHERE Group_Submission_Event__c = 'Before Days' LIMIT 1];
		Carrier__c objCarrierAfterMonth = [SELECT Id FROM Carrier__c WHERE Group_Submission_Event__c = 'After Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_BENEFITS_BOR)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objOpportunity.Id)
			.setAccount(objOpportunity.AccountId)
			.setType('BOR BOR TAdA Only')
			.setQualificationOwner(ID_LOGGED_USER)
			.setStatus('Ready for Qualification')
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.setBORId('zpEIN6789021')
			.setCoverageEffectiveDate(System.today())
			.build();
		list_BenefitOrders.add(objBenefitOrder);

		Benefit_Order__c objBenefitOrder2 = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_BENEFITS_BOR)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objOpportunity.Id)
			.setAccount(objOpportunity.AccountId)
			.setType('BOR BOR TAdA Only')
			.setQualificationOwner(ID_LOGGED_USER)
			.setStatus('Ready for Qualification')
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.setBORId('zpEIN67890212')
			.setCoverageEffectiveDate(System.today())
			.build();
		list_BenefitOrders.add(objBenefitOrder2);

		insert list_BenefitOrders;

		Carrier_Order__c objCarrierOrderParent = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_BENEFITS_BOR)
			.setBenefitOrder(objBenefitOrder2.Id)
			.setOwnerID(ID_LOGGED_USER)
			.setOrderType('TAdA: Pre OE Setup')
			.setImplementationStage('Ready for Qualification')
			.setStartDate(System.today() - 51)
			.setIsMultiEIN(true)
			.setRenewalDate(System.today())
			.build();
		list_CarrierOrders.add(objCarrierOrderParent);

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_BENEFITS_BOR)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(ID_LOGGED_USER)
			.setOrderType('TAdA: No Pre OE Setup')
			.setImplementationStage('Ready for Qualification')
			.setStartDate(System.today() - 50)
			.setIsMultiEIN(true)
			.setRenewalDate(System.today())
			.build();
		list_CarrierOrders.add(objCarrierOrder);

		insert list_CarrierOrders;

		objCarrierOrder.Carrier__c = objCarrierAfterMonth.Id;
		update objCarrierOrder;

		objCarrierOrderParent.Carrier__c = objCarrierBeforeDays.Id;
		update objCarrierOrderParent;

		objCarrierOrder.Carrier__c = objCarrierAfterDays.Id;
		objCarrierOrder.Implementation_Stage__c = 'Closed Admin';
		update objCarrierOrder;

		delete list_CarrierOrders;

		undelete list_CarrierOrders;

		Test.stopTest();

		List<Carrier_Order__c> list_CarrierOrdersTemp = [SELECT Id FROM Carrier_Order__c WHERE Benefit_Order__c = :objBenefitOrder.Id OR Benefit_Order__c = :objBenefitOrder2.Id];
		System.assert(list_CarrierOrdersTemp.size() > 0, 'Carrier Order is present related with the BO.');
	}

	// Carrier order's ownerID does changed
	/**
	 * @description  This method is used to test the CO Route submission orders to the automation.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testGroupSubmissionPostive() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		PolicyHelper.skipTrigger = true;
		PolicyHelper.skipOppDispatchTrigger = true;

		Test.startTest();

		List<PriceBook2> list_PriceBook = [SELECT Id FROM PriceBook2 LIMIT 1];

		Opportunity objOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId = :OPP_RT_BENEFITS_RENEWAL LIMIT 1];
		objOpportunity.Pricebook2Id = list_PriceBook[0].Id;
		objOpportunity.NumberOfEmployees__c = 15;
		update objOpportunity;

		RPA_Submission_Automation_rules__mdt objSubmissionRules = [
			SELECT Active__c, Carrier_Id__c, Order_Type__c, HI_Carrier_Id__c, Submission_Type__c
			FROM RPA_Submission_Automation_rules__mdt
			WHERE Active__c = TRUE AND Order_Type__c != NULL AND Carrier_Id__c != NULL AND Submission_Type__c = 'RPA Only'
			LIMIT 1
		];
		String strCarrierId = '';
		for (String strId : objSubmissionRules.HI_Carrier_Id__c.split(';')) {
			strCarrierId = strId;
			break;
		}

		State__c objState = [SELECT ID FROM State__c WHERE Name = 'TEST STATE' LIMIT 1];

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder()
			.setName('Beam Dental')
			.setKey('Beam64')
			.setId(strCarrierId)
			.setCarrierId(objSubmissionRules.Carrier_Id__c)
			.setState(objState.Id)
			.build();
		insert objCarrier;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objOpportunity.AccountId)
			.setEmail('testuer@abccompany.com')
			.setInferFitScore('D')
			.setLastName('Test')
			.build();
		insert objContact;

		Transition_to_Fulfillment__c objFulfillment = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpportunity.Id)
			.setContactId(objContact.Id)
			.setHasAffiliates(false)
			.setPEO('Y')
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal'))
			.setSendOrder(true)
			.build();
		insert objFulfillment;

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_RENEWAL)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objOpportunity.Id)
			.setAccount(objOpportunity.AccountId)
			.setQualificationOwner(ID_LOGGED_USER)
			.setStatus('Same carrier, plan/group level changes')
			.setOwnerID(ID_LOGGED_USER)
			.setIsMultiEIN(false)
			.setCoverageEffectiveDate(System.today().addDays(75))
			.setTransitionToFulfillment(objFulfillment.Id)
			.build();
		insert objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(ID_LOGGED_USER)
			.setImplementationStage('Same carrier, plan/group level changes')
			.setOrderAssignment(objSubmissionRules.Order_Type__c)
			.setStartDate(System.today() - 50)
			.setGroupNumber('1234')
			.setIsMultiEIN(false)
			.setOrderPlayableDate(System.today().addDays(10))
			.setIsORderEligibleForSubAutomation(true)
			.build();
		insert objCarrierOrder;

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder()
			.setIdOpprtunity(objOpportunity.Id)
			.setIdCarrier(objCarrier.Id)
			.setName('Test Policy1')
			.setIsSelected(true)
			.setBenefitType('Medical')
			.setIdCarrierOrder(objCarrierOrder.Id)
			.setIsBase(false)
			.build();
		insert objPolicy;

		QA_Sheet__c objQaSheet = new TestDataFactory.QASheetBuilder().setBenefitOrderId(objBenefitOrder.Id).setRecordTypeId(Cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal')).build();
		insert objQaSheet;

		QA_Lines_Of_Coverage__c objQALineOfCoverage = new TestDataFactory.QALineOfCoverageBuilder()
			.setQASheetId(objQaSheet.Id)
			.setCarrierOrderId(objCarrierOrder.Id)
			.setBenefitSelectedCarrier(objCarrier.Id)
			.setLinesOfCoverage('Medical')
			.setContributionChange('Yes')
			.build();
		insert objQALineOfCoverage;

		Test.stopTest();

		List<Carrier_Order__c> list_CarrierOrder = [
			SELECT
				Name,
				Implementation_Stage__c,
				Stage_Detail__c,
				Order_Assignment__c,
				Carrier__r.Carrier_Id__c,
				Carrier__r.State__c,
				Submitted_Completed_Datetime__c,
				Days_Until_Effective_Date__c,
				Group_Number__c,
				OwnerId,
				Parent_Carrier_Order__c,
				Is_Multi_EIN__c,
				Is_Order_Eligible_For_Sub_Automation__c,
				Benefit_Types__c,
				HI_Carrier_Id__c,
				Carrier__r.Id__c,
				Waiting_Period_Change__c,
				Contribution_Change__c,
				Plan_Change__c,
				Submission_Deadline_Date__c,
				(SELECT Id FROM Policies__r),
				(SELECT Id, Contribution_Change__c, Carrier_Order__c, Benefits_selected_Carrier__r.Id__c, Lines_Of_Coverage__c FROM QA_Lines_Of_Coverage__r),
				Benefit_Order__r.Transition_To_Fulfillment__r.Do_they_have_affiliates__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__c = :objBenefitOrder.Id AND Id = :objCarrierOrder.Id
		];

		// Logic call from DisplayEditTTSExt Positive Case
		List<Carrier_Order__c> list_CarrierOrderTemp = SubmissionAutomationHelper.routeSubmissionCOToAutomation(list_CarrierOrder);

		if (!list_CarrierOrderTemp.isEmpty()) {
			String strOwnerId = list_CarrierOrderTemp[0].OwnerId;
			System.assertEquals([SELECT Name FROM Group WHERE Id = :strOwnerId].Name, 'Automation Queue', 'Co is assigned to Automation Queue');
		}
	}

	/**
	 * @description  This method is used to test the CO Route submission orders to the automation - Negative Case.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testGroupSubmissionNegativeCase() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		PolicyHelper.skipTrigger = true;
		PolicyHelper.skipOppDispatchTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;

		Test.startTest();

		List<PriceBook2> list_PriceBook = [SELECT Id FROM PriceBook2 LIMIT 1];

		Opportunity objOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId = :OPP_RT_BENEFITS_NEW_PLAN LIMIT 1];
		objOpportunity.Pricebook2Id = list_PriceBook[0].Id;
		objOpportunity.NumberOfEmployees__c = 15;
		update objOpportunity;

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c LIMIT 1];

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objOpportunity.AccountId)
			.setEmail('testuer@abccompany.com')
			.setInferFitScore('D')
			.setLastName('Test')
			.build();
		insert objContact;

		Transition_to_Fulfillment__c objFulfillment = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpportunity.Id)
			.setContactId(objContact.Id)
			.setHasAffiliates(false)
			.setPEO('Y')
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan'))
			.setSendOrder(true)
			.build();
		insert objFulfillment;

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER')
			.setOpp(objOpportunity.Id)
			.setAccount(objOpportunity.AccountId)
			.setQualificationOwner(ID_LOGGED_USER)
			.setStatus('New to Gusto')
			.setOwnerID(ID_LOGGED_USER)
			.setIsMultiEIN(false)
			.setCoverageEffectiveDate(System.today().addDays(5))
			.setTransitionToFulfillment(objFulfillment.Id)
			.build();
		insert objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(ID_LOGGED_USER)
			.setImplementationStage('New to Gusto')
			.setOrderAssignment('Same carrier')
			.setStartDate(System.today() - 50)
			.setGroupNumber('1234')
			.setIsMultiEIN(false)
			.setOrderPlayableDate(System.today().addDays(10))
			.build();
		insert objCarrierOrder;

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder()
			.setIdOpprtunity(objOpportunity.Id)
			.setIdCarrier(objCarrier.Id)
			.setName('Test Policy1')
			.setIsSelected(true)
			.setBenefitType('Medical')
			.setIdCarrierOrder(objCarrierOrder.Id)
			.setIsBase(false)
			.build();
		insert objPolicy;

		QA_Sheet__c objQaSheet = new TestDataFactory.QASheetBuilder().setBenefitOrderId(objBenefitOrder.Id).setRecordTypeId(Cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan')).build();
		insert objQaSheet;

		QA_Lines_Of_Coverage__c objQALineOfCoverage = new TestDataFactory.QALineOfCoverageBuilder()
			.setQASheetId(objQaSheet.Id)
			.setCarrierOrderId(objCarrierOrder.Id)
			.setBenefitSelectedCarrier(objCarrier.Id)
			.setLinesOfCoverage('Medical')
			.setContributionChange('Yes')
			.build();

		insert objQALineOfCoverage;

		Test.stopTest();

		List<Carrier_Order__c> list_CarrierOrder = [
			SELECT
				Name,
				Implementation_Stage__c,
				Stage_Detail__c,
				Order_Assignment__c,
				Carrier__r.Carrier_Id__c,
				Carrier__r.State__c,
				Submitted_Completed_Datetime__c,
				Days_Until_Effective_Date__c,
				Group_Number__c,
				OwnerId,
				Parent_Carrier_Order__c,
				Is_Multi_EIN__c,
				Is_Order_Eligible_For_Sub_Automation__c,
				Benefit_Types__c,
				HI_Carrier_Id__c,
				Carrier__r.Id__c,
				Waiting_Period_Change__c,
				Contribution_Change__c,
				Plan_Change__c,
				Submission_Deadline_Date__c,
				(SELECT Id FROM Policies__r),
				(SELECT Id, Contribution_Change__c, Carrier_Order__c, Benefits_selected_Carrier__r.Id__c, Lines_Of_Coverage__c FROM QA_Lines_Of_Coverage__r),
				Benefit_Order__r.Transition_To_Fulfillment__r.Do_they_have_affiliates__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__c != NULL AND Benefit_Order__c = :objBenefitOrder.Id AND Id = :objCarrierOrder.Id
		];

		List<Carrier_Order__c> list_CarrierOrderTemp = SubmissionAutomationHelper.routeSubmissionCOToAutomation(list_CarrierOrder);
		if (!list_CarrierOrderTemp.isEmpty()) {
			String strOwnerId = list_CarrierOrderTemp[0].OwnerId;
			System.assertNotEquals(strOwnerId.indexOf('00G'), 0, 'Incorrect Result');
		}
	}

	/**
	 * @description  This method is used to test the Confirmation Automation Eligibility of CO.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testConfirmationAutomationEligibility() {
		Test.startTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Name = 'Confirmation Automation'];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		objCarrierOrder.Eligible_for_Confirmation_Automation__c = false;
		update objCarrierOrder;

		Test.stopTest();

		System.assert(
			[SELECT Eligible_for_Confirmation_Automation__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Eligible_for_Confirmation_Automation__c,
			'Eligible_for_Confirmation_Automation__c of CO is Checked.'
		);
	}

	/**
	 * @description  This method is used to test the Confirmation Automation Eligibility of CO - Negative Case.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testConfirmationAutomationEligibilityMarkAsFalse() {
		Test.startTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Name = 'Confirmation Automation Eligible'];
		objCarrierOrder.Implementation_Stage__c = 'Approved Pending EE Audit';
		update objCarrierOrder;

		System.assert(
			[SELECT Eligible_for_Confirmation_Automation__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Eligible_for_Confirmation_Automation__c,
			'Eligible_for_Confirmation_Automation__c of CO is Checked.'
		);

		objCarrierOrder.Implementation_Stage__c = 'Approved';
		update objCarrierOrder;

		Test.stopTest();

		System.assert(
			![SELECT Eligible_for_Confirmation_Automation__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Eligible_for_Confirmation_Automation__c,
			'Eligible_for_Confirmation_Automation__c of CO is unchecked.'
		);
	}

	/**
	 * @description  This method is used to test the Eligible fo Confirmation Automation of CO.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testConfirmationAutomationApprovedMarkAsFalse() {
		Test.startTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Name = 'Confirmation Automation Eligible'];
		objCarrierOrder.Implementation_Stage__c = 'Approved';
		update objCarrierOrder;

		Test.stopTest();

		System.assert(
			![SELECT Eligible_for_Confirmation_Automation__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Eligible_for_Confirmation_Automation__c,
			'Eligible_for_Confirmation_Automation__c of CO is unchecked.'
		);
	}

	/**
	 * @description  This method is used to test the functionality of PRnding Item CO.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testUpdateCOAsPendingItem() {
		Test.startTest();

		Carrier_Order__c objCarrierOrder = [SELECT Id, Implementation_Stage__c, Benefit_Order__c FROM Carrier_Order__c WHERE Name = 'Confirmation Automation Eligible'];
		objCarrierOrder.Implementation_Stage__c = 'Pending Item';
		update objCarrierOrder;

		Test.stopTest();

		System.assertEquals(
			[SELECT Order_Status__c FROM Benefit_Order__c WHERE Id = :objCarrierOrder.Benefit_Order__c].Order_Status__c,
			'Ready for Submission Prep',
			'Order status of the BO is set as : Ready for Submission Prep'
		);
	}

	/**
	 * @description  This method is used to test re-processing of the Cases.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testReProcessCases() {
		Test.startTest();

		Id idBO = null;
		Set<Id> set_COIds = new Set<Id>();
		for (Carrier_Order__c objCO : [SELECT Id, Benefit_Order__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_RENEWAL]) {
			set_COIds.add(objCO.Id);
			idBO = objCO.Benefit_Order__c;
		}
		List<Case> list_Cases = [SELECT Id, Group_Number__c FROM Case WHERE Benefit_Order__c = :idBO];
		if (list_Cases.size() > 0) {
			delete list_Cases;
		}
		CarrierOrderTriggerHelper.reProcessCases(set_COIds, true);

		Test.stopTest();

		list_Cases = [SELECT Id, Group_Number__c FROM Case WHERE Benefit_Order__c = :idBO];
		System.assert(list_Cases.size() > 0, 'Cases are available related to the BO');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the updation of playable dates on child COs.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testPlayableDates() {
		Test.startTest();
		Carrier_Order__c objParentCO = [SELECT Id, Order_Playable_Date__c, Audit_Playable_Date__c FROM Carrier_Order__c WHERE Name = 'Parent Carrier Order'];
		objParentCO.Order_Playable_Date__c = System.today();
		objParentCO.Audit_Playable_Date__c = System.today();
		update objParentCO;
		Carrier_Order__c objParentCOTemp = [SELECT Id, Order_Playable_Date__c, Audit_Playable_Date__c FROM Carrier_Order__c WHERE Id = :objParentCO.Id];
		Carrier_Order__c objChildCO = [SELECT Id, Order_Playable_Date__c, Audit_Playable_Date__c FROM Carrier_Order__c WHERE Parent_Carrier_Order__c = :objParentCO.Id];
		Test.stopTest();
		System.assertEquals(objParentCOTemp.Order_Playable_Date__c, objChildCO.Order_Playable_Date__c, 'Parent Order Playable date is populated on the Child CO.');
		System.assertEquals(objParentCOTemp.Audit_Playable_Date__c, objChildCO.Audit_Playable_Date__c, 'Parent Audit Playable date is populated on the CHild CO.');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Submission Deadline Start Date for submission start event `Same`.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testPopulateSubStartDateForSameEvent() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id, Name FROM Carrier__c WHERE Id__c != NULL LIMIT 1];
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		Opportunity objOpp = [SELECT Id, HI_Effective_Date__c FROM Opportunity WHERE Id = :objBO.Opportunity__c];
		objOpp.HI_Effective_Date__c = System.today();
		update objOpp;

		Carrier_Version_Detail__c objCarrierVersion = new TestDataFactory.CarrierVersionDetailBuilder()
			.setEffetciveDate(System.today())
			.setVersionKey('101')
			.setCarrierId(objCarrier.Id)
			.setWithChangesSubmissionStartEvent('Same')
			.build();
		insert objCarrierVersion;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 1')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_PLAN_GROUP_LEVEL_CHANGES)
			.build();
		insert objCO;
		Test.stopTest();
		System.assertEquals(
			[SELECT Id, Submission_Deadline_Start_Date__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Submission_Deadline_Start_Date__c != null,
			true,
			'Submission_Deadline_Start_Date__c is not null.'
		);
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Submission Deadline Start Date for submission start event `Before Month`.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testPopulateSubStartDateForBeforeMonthEvent() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id, Name FROM Carrier__c WHERE Id__c != NULL LIMIT 1];
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		Opportunity objOpp = [SELECT Id, HI_Effective_Date__c FROM Opportunity WHERE Id = :objBO.Opportunity__c];
		objOpp.HI_Effective_Date__c = System.today();
		update objOpp;

		Carrier_Version_Detail__c objCarrierVersion = new TestDataFactory.CarrierVersionDetailBuilder()
			.setEffetciveDate(System.today())
			.setVersionKey('102')
			.setCarrierId(objCarrier.Id)
			.setWithChangesSubmissionStartEvent('Before Month')
			.setWithChangesSubStartVariationNo(5)
			.build();
		insert objCarrierVersion;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 2')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_PLAN_GROUP_LEVEL_CHANGES)
			.build();
		insert objCO;
		Test.stopTest();
		System.assertEquals(
			[SELECT Id, Submission_Deadline_Start_Date__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Submission_Deadline_Start_Date__c != null,
			true,
			'Submission_Deadline_Start_Date__c of CO is populated.'
		);
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Submission Deadline Start Date for submission start event `After Month`.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testPopulateSubStartDateForAfterMonthEvent() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id, Name FROM Carrier__c WHERE Id__c != NULL LIMIT 1];
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		Opportunity objOpp = [SELECT Id, HI_Effective_Date__c FROM Opportunity WHERE Id = :objBO.Opportunity__c];
		objOpp.HI_Effective_Date__c = System.today();
		update objOpp;

		Carrier_Version_Detail__c objCarrierVersion = new TestDataFactory.CarrierVersionDetailBuilder()
			.setEffetciveDate(System.today())
			.setVersionKey('103')
			.setCarrierId(objCarrier.Id)
			.setWithChangesSubmissionStartEvent('After Month')
			.setWithChangesSubStartVariationNo(5)
			.build();
		insert objCarrierVersion;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_PLAN_GROUP_LEVEL_CHANGES)
			.build();
		insert objCO;
		Test.stopTest();
		System.assertEquals(
			[SELECT Id, Submission_Deadline_Start_Date__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Submission_Deadline_Start_Date__c != null,
			true,
			'Submission_Deadline_Start_Date__c is not null.'
		);
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Submission Deadline Start Date for submission start event `Before Days`.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testPopulateSubStartDateForBeforeDaysEvent() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id, Name FROM Carrier__c WHERE Id__c != NULL LIMIT 1];
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		Opportunity objOpp = [SELECT Id, HI_Effective_Date__c FROM Opportunity WHERE Id = :objBO.Opportunity__c];
		objOpp.HI_Effective_Date__c = System.today();
		update objOpp;

		Carrier_Version_Detail__c objCarrierVersion = new TestDataFactory.CarrierVersionDetailBuilder()
			.setEffetciveDate(System.today())
			.setVersionKey('104')
			.setCarrierId(objCarrier.Id)
			.setWithoutChangesSubmissionStartEvent('Before Days')
			.setWithoutChangesSubStartVariationNo(5)
			.build();
		insert objCarrierVersion;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES)
			.build();
		insert objCO;
		Test.stopTest();
		System.assertEquals(
			[SELECT Id, Submission_Deadline_Start_Date__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Submission_Deadline_Start_Date__c != null,
			true,
			'Submission_Deadline_Start_Date__c of CO is not null.'
		);
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Submission Deadline Start Date for submission start event `After Days`.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testPopulateSubStartDateForAfterDaysEvent() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id, Name FROM Carrier__c WHERE Id__c != NULL LIMIT 1];
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		Opportunity objOpp = [SELECT Id, HI_Effective_Date__c FROM Opportunity WHERE Id = :objBO.Opportunity__c];
		objOpp.HI_Effective_Date__c = System.today();
		update objOpp;

		Carrier_Version_Detail__c objCarrierVersion = new TestDataFactory.CarrierVersionDetailBuilder()
			.setEffetciveDate(System.today())
			.setVersionKey('105')
			.setCarrierId(objCarrier.Id)
			.setWithoutChangesSubmissionStartEvent('After Days')
			.setWithoutChangesSubStartVariationNo(5)
			.build();
		insert objCarrierVersion;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES)
			.build();
		insert objCO;
		Test.stopTest();
		System.assertEquals(
			[SELECT Id, Submission_Deadline_Start_Date__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Submission_Deadline_Start_Date__c != null,
			true,
			'Submission_Deadline_Start_Date__c of CO is not null.'
		);
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Submission Deadline Date for New plan even `Before Days` For New plan.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testPopulateSubStartDateForBeforeDaysEvent1() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id, Name FROM Carrier__c WHERE Id__c != NULL LIMIT 1];
		objCarrier.New_Plan_Variation_Num1__c = 3;
		objCarrier.New_Plan_Submission_Event__c = 'Before Days';
		update objCarrier;

		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		Opportunity objOpp = [SELECT Id, HI_Effective_Date__c FROM Opportunity WHERE Id = :objBO.Opportunity__c];
		objOpp.HI_Effective_Date__c = System.today();
		update objOpp;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO)
			.build();
		insert objCO;
		Test.stopTest();
		System.assertEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Submission_Deadline__c != null, true, 'Submission_Deadline__c of CO is not null.');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Submission Deadline Date for New plan event `After Days` For New plan.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testPopulateSubDeadlineDateForAfterDaysEvent1() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE New_Plan_Submission_Event__c = 'After Days' LIMIT 1];

		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN LIMIT 1];
		Opportunity objOpp = [SELECT Id, HI_Effective_Date__c FROM Opportunity WHERE Id = :objBO.Opportunity__c];
		objOpp.HI_Effective_Date__c = System.today();
		update objOpp;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE)
			.build();
		insert objCO;
		Test.stopTest();
		System.assertEquals([SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Submission_Deadline__c != null, true, 'Submission_Deadline__c is not null.');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Submission Deadline date for Member Event.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void populateSubmissionDeadlineForMemberEvent() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Member_Submission_Event__c = 'After Month' LIMIT 1];

		Benefit_Order__c objBenefitOrder = [SELECT Id, OwnerId, Coverage_Effective_Date__c, Push_Rate_Reason__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		objBenefitOrder.Coverage_Effective_Date__c = System.today();
		update objBenefitOrder;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBenefitOrder.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE)
			.build();
		insert objCO;
		Test.stopTest();

		List<Carrier_Order__c> lstCO = [SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCO.Id];

		System.assert(lstCO[0].Submission_Deadline__c != null, 'Submission_Deadline__c is populated.');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of Member_Submission_Date__c for before month Member Event.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void populateSubmissionDeadlineForMemberEventBeforeMonth() {
		Test.startTest();
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Member_Submission_Event__c = 'Before Month' LIMIT 1];
		objCarrier.Member_Variation_Number_2__c = 2;
		update objCarrier;

		Benefit_Order__c objBenefitOrder = [SELECT Id, OwnerId, Coverage_Effective_Date__c, Push_Rate_Reason__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		objBenefitOrder.Coverage_Effective_Date__c = System.today();
		update objBenefitOrder;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBenefitOrder.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE)
			.build();
		insert objCO;
		Test.stopTest();

		List<Carrier_Order__c> lstCO = [SELECT Id, Member_Submission_Date__c, Submission_Deadline__c FROM Carrier_Order__c WHERE Id = :objCO.Id];
		System.assert(lstCO[0].Member_Submission_Date__c != null, 'Member_Submission_Date__c of CO is populated.');
	}

	/**
	 * @author          Bhagat Singh
	 * @description     This method is used to test the population of Automated_Submission__c field value as 'Bot Submission'.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void automatedSubmissionAsBOT() {
		Test.startTest();
		Carrier_Order__c objCO = [SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_NEW_PLAN LIMIT 1];
		objCO.Automation_Status__c = CarrierOrderUtil.AUTOMATION_STATUS_COMPLETED;
		objCO.Sent_to_HI_for_Submission__c = false;
		update objCO;

		Test.stopTest();

		System.assert(
			[SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Automated_Submission__c ==
			CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_BOT,
			'Automated_Submission__c od CO is set as :Bot Submission'
		);
	}

	/**
	 * @author          Bhagat Singh
	 * @description     This method is used to test the population of Automated_Submission__c field value as 'HI/Bot Submission'.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void automatedSubmissionAsHIAndBOT() {
		Test.startTest();
		Carrier_Order__c objCO = [SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_NEW_PLAN LIMIT 1];
		objCO.Automation_Status__c = CarrierOrderUtil.AUTOMATION_STATUS_COMPLETED;
		objCO.Sent_to_HI_for_Submission__c = true;
		update objCO;

		Test.stopTest();

		System.assert(
			[SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c FROM Carrier_Order__c WHERE Id = :objCO.Id].Automated_Submission__c ==
			CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_HI_AND_BOT,
			'Automated_Submission__c of CO is set as :HI/Bot Submission'
		);
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of API_Submission_Date__c and Submitted_Completed_Datetime__c HI_Submission_Automation_Status__c is Sucess.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testAPISubmissionDatePopulationSuccess() {
		Test.startTest();
		Carrier_Order__c objCO = [SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_NEW_PLAN LIMIT 1];

		objCO.HI_Submission_Automation_Status__c = 'Success';
		objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION;
		update objCO;

		Test.stopTest();

		Carrier_Order__c objCO1 = [SELECT Id, API_Submission_Date__c, Submitted_Completed_Datetime__c FROM Carrier_Order__c WHERE Id = :objCO.Id];

		System.assert(objCO1.API_Submission_Date__c != null, 'API_Submission_Date__c is populated.');
		System.assert(objCO1.Submitted_Completed_Datetime__c != null, 'Submitted_Completed_Datetime__c is populated.');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the population of API_Submission_Date__c and Submitted_Completed_Datetime__c HI_Submission_Automation_Status__c is Failed.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testAPISubmissionDatePopulationFailed() {
		Test.startTest();
		Carrier_Order__c objCO = [SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_NEW_PLAN LIMIT 1];

		objCO.HI_Submission_Automation_Status__c = 'Failed';
		objCO.Submitted_Completed_Datetime__c = System.today().addDays(1);
		update objCO;

		Test.stopTest();

		Carrier_Order__c objCO1 = [SELECT Id, API_Submission_Date__c, Submitted_Completed_Datetime__c FROM Carrier_Order__c WHERE Id = :objCO.Id];

		System.assert(objCO1.API_Submission_Date__c != null, 'API_Submission_Date__c is populated.');
		System.assert(objCO1.Submitted_Completed_Datetime__c != objCO1.API_Submission_Date__c, 'Submitted_Completed_Datetime__c is populated but not changed.');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the Implementation stage Detail
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testsetCarrierOrderImpStageWithReadyForsubPrep() {
		Test.startTest();
		Carrier_Order__c objCO = [
			SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c, Benefit_Order__c
			FROM Carrier_Order__c
			WHERE RecordTypeId = :CO_RT_NEW_PLAN
			LIMIT 1
		];
		Carrier__c objCarrier = [SELECT Id,Name,Partner_Type__c From Carrier__c Where Name = 'Alegeus'];
		objCO.Order_Type__c = 'TAdA: Pre OE Setup';
		objCO.Carrier__c = objCarrier.Id;
		objCO.Benefit_Types__c = 'HSA';
		objCO.Implementation_Stage__c = 'Ready for Submission Prep';
		update objCO;

		Test.stopTest();
		Carrier_Order__c objCO1 = [SELECT Id, Implementation_Stage__c, Carrier__c, Stage_Detail__c FROM Carrier_Order__c WHERE Id = :objCO.Id];
		System.assertEquals('Ready for TAdA Setup', objCO1.Stage_Detail__c, 'Implementation statge detail not populated');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the Implementation stage Detail
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testsetCarrierOrderImpStagewithSubPrep() {
		Test.startTest();
		Carrier_Order__c objCO = [
			SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c, Benefit_Order__c
			FROM Carrier_Order__c
			WHERE RecordTypeId = :CO_RT_NEW_PLAN
			LIMIT 1
		];
		Carrier__c objCarrier = [SELECT Id,Name,Partner_Type__c From Carrier__c Where Name = 'Alegeus'];
		objCO.Order_Type__c = 'TAdA: Pre OE Setup';
		objCO.Carrier__c = objCarrier.Id;
		objCO.Benefit_Types__c = 'HSA';
		objCO.Implementation_Stage__c = 'Submission Prep';
		update objCO;

		Test.stopTest();
		Carrier_Order__c objCO1 = [SELECT Id, Implementation_Stage__c, Carrier__c, Stage_Detail__c FROM Carrier_Order__c WHERE Id = :objCO.Id];
		System.assertEquals('TAdA Setup Pending', objCO1.Stage_Detail__c, 'Implementation statge detail not populated');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the Implementation stage Detail
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testsetCarrierOrderImpStageWithApproved() {
		Test.startTest();
		Carrier_Order__c objCO = [
			SELECT Id, Automation_Status__c, Sent_to_HI_for_Submission__c, Automated_Submission__c, Benefit_Order__c
			FROM Carrier_Order__c
			WHERE RecordTypeId = :CO_RT_NEW_PLAN
			LIMIT 1
		];
		Carrier__c objCarrier = [SELECT Id,Name,Partner_Type__c From Carrier__c Where Name = 'Alegeus'];
		objCO.Order_Type__c = 'TAdA: Pre OE Setup';
		objCO.Carrier__c = objCarrier.Id;
		objCO.Benefit_Types__c = 'HSA';
		objCO.Implementation_Stage__c = 'Approved';
		update objCO;

		Test.stopTest();
		Carrier_Order__c objCO1 = [SELECT Id, Implementation_Stage__c, Carrier__c, Stage_Detail__c FROM Carrier_Order__c WHERE Id = :objCO.Id];
		System.assertEquals('TAdA Setup Complete', objCO1.Stage_Detail__c, 'Implementation statge detail not populated');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the Implementation stage Detail
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testSetOrderDetailsRFOEPWithOEDate() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		objBO.Open_Enrollment_Start_Date__c = System.Today();
		update objBO;
		Carrier__c objCarrier = [SELECT Id,Name,Partner_Type__c From Carrier__c Where Name = 'Alegeus'];
		List<Carrier_Order__c> list_CarrierOrder = new List<Carrier_Order__c>();
		Carrier_Order__c objCarrierOrder1 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP)
			.setOrderType(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
			.build();
		list_CarrierOrder.add(objCarrierOrder1);

		Carrier_Order__c objCarrierOrder2 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 4')
			.setRecordTypeId(CO_RT_CHANGE)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.ID)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP)
			.setOrderType(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
			.build();
		list_CarrierOrder.add(objCarrierOrder2);
		insert list_CarrierOrder;

		Test.stopTest();
		Benefit_Order__c objBORecord = [SELECT Id, Status_Detail__c FROM Benefit_Order__c WHERE Id = :objBO.Id];
		Carrier_Order__c objCO1 = [SELECT Id, Implementation_Stage__c, Carrier__c, Stage_Detail__c FROM Carrier_Order__c WHERE Id = :list_CarrierOrder[0].Id];
		System.assertEquals(objCO1.Stage_Detail__c, objBORecord.Status_Detail__c, 'Order status detail not populated');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the Implementation stage Detail
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testSetOrderDetailsWithoutOEDate() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		Carrier__c objCarrier = [SELECT Id,Name,Partner_Type__c From Carrier__c Where Name = 'Alegeus'];
		List<Carrier_Order__c> list_CarrierOrder = new List<Carrier_Order__c>();
		Carrier_Order__c objCarrierOrder3 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 4')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.ID)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP)
			.setOrderType(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
			.build();
		list_CarrierOrder.add(objCarrierOrder3);

		Carrier_Order__c objCarrierOrder4 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_CHANGE)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP)
			.setOrderType(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
			.build();
		list_CarrierOrder.add(objCarrierOrder4);
		insert list_CarrierOrder;

		Test.stopTest();
		Benefit_Order__c objBORecord = [SELECT Id, Status_Detail__c, Order_Status__c FROM Benefit_Order__c WHERE Id = :objBO.Id];
		Carrier_Order__c objCO1 = [SELECT Id, Implementation_Stage__c, Carrier__c, Stage_Detail__c FROM Carrier_Order__c WHERE Id = :list_CarrierOrder[1].Id];
		System.assertEquals(CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP, objBORecord.Order_Status__c, 'Order status not populated');
		System.assertEquals(objCO1.Stage_Detail__c, objBORecord.Status_Detail__c, 'Order status detail not populated');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the Implementation stage Detail
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testSetOrderDetailsRFSP() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		objBO.Open_Enrollment_Start_Date__c = System.Today();
		update objBO;
		Carrier__c objCarrier = [SELECT Id,Name,Partner_Type__c From Carrier__c Where Name = 'Alegeus'];
		Carrier_Order__c objCarrierOrder4 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP)
			.setOrderType(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
			.build();
		insert objCarrierOrder4;

		Test.stopTest();
		Benefit_Order__c objBORecord = [SELECT Id, Status_Detail__c, Order_Status__c FROM Benefit_Order__c WHERE Id = :objBO.Id];
		Carrier_Order__c objCO1 = [SELECT Id, Implementation_Stage__c, Carrier__c, Stage_Detail__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder4.Id LIMIT 1];
		System.assertEquals(CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP, objBORecord.Order_Status__c, 'Order status not populated');
		System.assertEquals(objCO1.Stage_Detail__c, objBORecord.Status_Detail__c, 'Order status detail not populated');
	}

	/**
	 * @author          Deepika Saini
	 * @description     This method is used to test the Implementation stage Detail
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void testSetOrderDetailsWithOEDateRFSP() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Name, Opportunity__c FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_RENEWAL LIMIT 1];
		objBO.Open_Enrollment_Start_Date__c = System.Today();
		update objBO;
		Carrier__c objCarrier = [SELECT Id,Name,Partner_Type__c From Carrier__c Where Name = 'Alegeus'];
		List<Carrier_Order__c> list_CarrierOrder = new List<Carrier_Order__c>();
		Carrier_Order__c objCarrierOrder3 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 4')
			.setRecordTypeId(CO_RT_RENEWAL)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_APPROVED)
			.setOrderType(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
			.build();
		list_CarrierOrder.add(objCarrierOrder3);

		Carrier_Order__c objCarrierOrder4 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order 3')
			.setRecordTypeId(CO_RT_CHANGE)
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier.Id)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP)
			.setOrderType(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
			.build();
		list_CarrierOrder.add(objCarrierOrder4);
		insert list_CarrierOrder;

		Test.stopTest();
		Benefit_Order__c objBORecord = [SELECT Id, Status_Detail__c, Order_Status__c FROM Benefit_Order__c WHERE Id = :objBO.Id];
		Carrier_Order__c objCO1 = [SELECT Id, Implementation_Stage__c, Carrier__c, Stage_Detail__c FROM Carrier_Order__c WHERE Id = :list_CarrierOrder[1].Id];
		System.assertEquals(CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP, objBORecord.Order_Status__c, 'Order status not populated');
		System.assertEquals(objCO1.Stage_Detail__c, objBORecord.Status_Detail__c, 'Order status detail not populated');
	}
	
	/**
	 * @description  Method for setting Special enrollment start date
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void setSpecialEnrollmentStartDate() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;

		List<Policy__c> list_Policies = new List<Policy__c>();
		List<QA_Lines_Of_Coverage__c> list_LinesOfCoverages = new List<QA_Lines_Of_Coverage__c>();

		List<PriceBook2> list_PriceBook = [SELECT Id FROM PriceBook2 LIMIT 1];

		Opportunity objOpportunity = [SELECT Id, Pricebook2Id, NumberOfEmployees__c FROM Opportunity WHERE RecordTypeId = :OPP_RT_BENEFITS_NEW_PLAN LIMIT 1];

		objOpportunity.Pricebook2Id = list_PriceBook.get(0).Id;
		objOpportunity.NumberOfEmployees__c = 12;
		objOpportunity.HI_Effective_Date__c = system.today();
		update objOpportunity;

		Test.startTest();

		Benefit_Order__c objBenefitOrder = [SELECT Id, Status_Detail__c FROM Benefit_Order__c WHERE RecordType.Name = 'New Plan' AND Opportunity__c = :objOpportunity.Id];
		objBenefitOrder.Coverage_Effective_Date__c = System.today();
		objBenefitOrder.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBenefitOrder;

		QA_Sheet__c objQASheet = new TestDataFactory.QASheetBuilder()
			.setBenefitOrderId(objBenefitOrder.Id)
			.setRecordTypeId(Cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan'))
			.setOpportunityId(objOpportunity.Id)
			.build();
		insert objQASheet;

		Transition_to_Fulfillment__c objTTFRecord = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpportunity.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan'))
			.setSendOrder(true)
			.build();
		insert objTTFRecord;

		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Id__c = '11'];

		Carrier_Version_Detail__c objCarrierVersionDetail = new TestDataFactory.CarrierVersionDetailBuilder()
			.setEffetciveDate(System.today().addDays(-30))
			.setVersionKey('Carrier001')
			.setCarrierId(objCarrier.Id)
			.setNumberOfPlansAllowedBasedOnFTE('Demo Text')
			.setNumberOfPlansAllowedOnEnrolleCount('Demo Text')
			.build();
		objCarrierVersionDetail.Without_Changes_Submission_Start_Event__c= 'Before Days';
		objCarrierVersionDetail.Without_Changes_Sub_Start_Variation_No__c=45;
		insert objCarrierVersionDetail;

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder()
			.setName('Test Policy1')
			.setIdOpprtunity(objOpportunity.Id)
			.setIdCarrier(objCarrier.Id)
			.setBenefitType('Medical')
			.setIsSelected(true)
			.setContributionSchemeType('Percentage Of Base')
			.setIsBase(true)
			.build();
		list_Policies.add(objPolicy);

		insert list_Policies;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test CarrierORderHandlerTest')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('Same carrier, NO plan/group level changes')
			.setOrderAssignment('Same carrier, NO plan/group level changes')
			.setBenefitTypes('Medical')
			.build();
		insert objCarrierOrder;

		QA_Lines_Of_Coverage__c objQALineOfCoverage = new TestDataFactory.QALineOfCoverageBuilder()
			.setQASheetId(objQaSheet.Id)
			.setCarrierOrderId(objCarrierOrder.Id)
			.setLinesOfCoverage('Medical')
			.setBenefitSelectedCarrier(objCarrier.Id)
			.build();
		list_LinesOfCoverages.add(objQALineOfCoverage);
		insert list_LinesOfCoverages;
		objQASheet.Special_Enrollment__c= 'N';
		update objQASheet;

		Test.stopTest();
		List<Carrier_Order__c> list_CarrierOrder = [SELECT Id, Submission_Deadline_Start_Date__c FROM Carrier_Order__c where Id =:objCarrierOrder.Id];
		System.assert(list_CarrierOrder[0].Submission_Deadline_Start_Date__c != null, 'Submission_Deadline_Start_Date__c on Carrier Order is not null.');
	}

	/**
	 * @description  Method for setting Special enrollment start date
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testValidateCarrierOrderStage() {
		Exception validationException;
		try {
			Test.startTest();

			Carrier_Order__c objCarrierOrder = [SELECT Id, Implementation_Stage__c, Benefit_Order__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_BENEFITS_BOR AND Name = 'TestCarrierOrder'];

			objCarrierOrder.Implementation_Stage__c = 'Approved';
			update objCarrierOrder;

			Test.stopTest();
		}
		catch(Exception ex) {
			validationException = ex;
		}
		System.assertEquals(validationException.getMessage().contains(System.Label.RestrictOrderApproveErrorMessage), true, 'Approved Order Email validation does not match');
	}

	/**
	 * @description  Method for setting Special enrollment start date
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testTicketOnwerChangedOnCOOwner() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Name FROM Benefit_Order__c WHERE RecordTypeId = :BO_RT_NEW_PLAN AND Name = 'TEST BENEFIT ORDER 1' LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id, OwnerId FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id];
		
		TicketTriggerHelper.skipTrigger = true;
		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
			Ticket__c objTicket = new TestDataFactory.TicketBuilder()
				.setOwnerId(objCO.OwnerId)
				.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
				.setStatus(TicketUtil.TICKET_STATUS_NEW)
				.setEscalationReason('Rate Discrepancy')
				.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
				.setEscalationReasonDetail('Incorrect rates for plan year')
				.setReportingTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
				.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
				.setSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
				.setBenefitOrderId(objBO.Id)
				.setCarrierOrderId(objCO.Id)
				.setCloseDate(System.today().adddays(15))
				.setErrorOrigin('Benefit Transfer Fulfillment')
				.setRateDiscrepencyResolution('No Error')
				.build();
			insert objTicket;
			User objMDRUser = new TestDataFactory.UserBuilder()
				.setAlias('mdruser')
				.setEmail('mdruser@testorg.com')
				.setEmailEncoding('UTF-8')
				.setFirstName('Test')
				.setLastName('User')
				.setLanguageLocaleKey('en_US')
				.setLocaleSidKey('en_US')
				.setProfileId(UserInfo.getProfileId())
				.setTimeZoneSidKey('America/Los_Angeles')
				.setUserName('mdruser@testorg.com')
				.setUserRoleId([SELECT Id FROM UserRole WHERE Name = 'sales_sdr_partner_xx' LIMIT 1][0].Id)
				.build();
			insert objMDRUser;
			TicketTriggerHelper.skipTrigger = false;
			
			objCO.OwnerId = objMDRUser.Id;
			update objCO;
		 }
		Test.stopTest();
		Ticket__c objTicket1 = [SELECT Id, OwnerId FROM Ticket__c WHERE Carrier_Order__c = :objCO.Id LIMIT 1];
		System.assertEquals(objCO.OwnerId, objTicket1.OwnerId, 'Ticket Owner should be same as of Carrier Order Owner.');
	}

	/**
	 * @author          Bhagat Singh
	 * @description     This method is used to test the Implementation stage, when carrier order manually created.
	 * @params          NA
	 * @return          NA
	 */
	@isTest
	static void manuallyCreateCarrierOrder() {
		Test.startTest();
		Carrier_Order__c objCO = [SELECT Id, Benefit_Order__c FROM Carrier_Order__c WHERE RecordTypeId = :CO_RT_NEW_PLAN LIMIT 1];

		Carrier__c objAnthemCarrier = new TestDataFactory.CarrierBuilder()
			.setName('Anthem Blue Cross')
			.setId('1')
			.setNewPlanSubmissionEvent('Before Month')
			.setMemberSubmissionEvent('Before Month')
			.setGroupSubmissionEvent('Before Month')
			.setNewPlanVariationNum1(10)
			.setMemberVariationNumber(1)
			.setGroupVariationNumber(1)
			.setMemberVariationNumber2(1)
			.setGroupVariationNumber2(1)
			.build();
		insert objAnthemCarrier;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('New Carrier Order')
			.setCarrier(objAnthemCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objCO.Benefit_Order__c)
			.setOwnerID(UserInfo.getUserId())
			.setOrderType('New to Gusto')
			.setIsMultiEIN(true)
			.build();
		insert objCarrierOrder;
		Test.stopTest();

		System.assertEquals(
			CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP,
			[SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id].Implementation_Stage__c,
			'Invalid Implementation Stage'
		);
	}
}