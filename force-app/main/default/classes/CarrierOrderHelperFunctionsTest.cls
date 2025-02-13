/**
 * @name         CarrierOrderHelperFunctionsTest
 * @author       Sourav Mitra
 * @date         05/31/2019
 * @description  Test class for CarrierOrderHelperFunctions
 * @revisions    Date ------------ Name ------------ Comments  
 **/
@isTest
public class CarrierOrderHelperFunctionsTest {
	/* @author        Praveen Sethu
	 * @description	  Setup method to insert tier config custom settings
	 * @param         void
	 * @return        void
	 **/
	@testSetup
	static void setup() {

    	Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder()
			.setActiveTadaProvider('elevate')
			.build();
      	insert objConfigSettings;
        insert new List<Carrier_Play_Information_Defaults__c>{
			new TestDataFactory.CarrierPlayInfoDefaultBuilder().setName('AuditFirstPlayBef').setEventType('Audit').setPlayModeType('First Play').setBeforeAfter('Before').setNumberOfDays(3).build(),
			new TestDataFactory.CarrierPlayInfoDefaultBuilder().setName('AuditFirstPlayAft').setEventType('Audit').setPlayModeType('First Play').setBeforeAfter('After').setNumberOfDays(2).build(),
			new TestDataFactory.CarrierPlayInfoDefaultBuilder()
				.setName('OrderFirstPlayBef1_15')
				.setEventType('Order')
				.setPlayModeType('First Play')
				.setBeforeAfter('Before')
				.setNumberOfDays(2)
				.setFrom(1)
				.setTo(15)
				.build()
		};
            
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		CarrierTriggerHelper.skipTrigger = true;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;
		Id idTTFBoRRecordTypeId = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BoR');
		Id idQASheetRecordTypeRenewal = Cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal');

		// Get org default tier config settings and assert new price 1 is not blank
		System.assertNotEquals(null, objTierConfig.New_Price_1__c);

		PriceBook2 objPB = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPB;
		
		
		List<Product2> list_Products2 = new List<Product2>();
		list_Products2.add(new TestDataFactory.ProductBuilder().setName('Medical').setFamily('Benefit').build());
		list_Products2.add(new TestDataFactory.ProductBuilder().setName('Dental').setFamily('Employee').build());
		list_Products2.add(new TestDataFactory.ProductBuilder().setName('Vision').setFamily('Employee').build());
		list_Products2.add(new TestDataFactory.ProductBuilder().setName('Life').setFamily('Employee').build());
		insert list_Products2;

		List<PricebookEntry> list_PriceBookEntry = new List<PricebookEntry>();
		list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[0].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(false).build());
		list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[1].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(false).build());
		list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[2].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(false).build());
		list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[3].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(false).build());
		list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[0].Id).setUnitPrice(5).setPriceBookId(objPB.Id).setIsActive(false).build());
		list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[1].Id).setUnitPrice(5).setPriceBookId(objPB.Id).setIsActive(false).build());
		list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[2].Id).setUnitPrice(5).setPriceBookId(objPB.Id).setIsActive(false).build());
		list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[3].Id).setUnitPrice(5).setPriceBookId(objPB.Id).setIsActive(false).build());
		insert list_PriceBookEntry;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account1').build();
		insert objAccount;
		
		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
		.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
		.setAccountId(objAccount.Id)
		.setName('TEST OPPORTUNITY')
		.setStage('STAGENAME')
		.setCloseDate(System.Today())
		.setSourceID('hawaiian_ice-new_plans_application-221133225566')
		.setId('HIBORTRANSFERzp123321')
		.build();
		insert objOpp;

		QA_Sheet__c objQASheet1 = new TestDataFactory.QASheetBuilder()
			.setOpportunityId(objOpp.Id)
			.setFederalCobraState('Federal')
			.setSICCodeSupportedByAllCarriers('Yes')
			.setSICCode('test')
			.setBAASigned('Yes')
			.setBAASignedBy('test')
			.setBSASigned('Yes')
			.setBSASignedBy('test')
			.setRecordTypeId(idQASheetRecordTypeRenewal)
			.setNewTAdAs(CarrierOrderUtil.TADA_BEN_TYPE_HSA)
			.setRenewingTAdAs(CarrierOrderUtil.TADA_BEN_TYPE_COMMUTER)
			.build();
		insert objQASheet1;

		OpportunityTriggerHelper.skipTrigger = false;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test').setTerminationEffectiveDate('On the Date').build();
		insert objCarrier;

		list<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrierRec = new TestDataFactory.CarrierBuilder().setName('Test123').setKey('test123').setId('test123').build();
		list_Carriers.add(objCarrierRec);

		Carrier__c objCarrierRec2 = new TestDataFactory.CarrierBuilder().setName('Alegeus').setPartnerType('TAdA').setKey('alegeus123').setId('alegeus123').build();
		list_Carriers.add(objCarrierRec2);

		Carrier__c objCarrierRec3 = new TestDataFactory.CarrierBuilder().setName('Test1236').setKey('test1236').setId('test1236').build();
		list_Carriers.add(objCarrierRec3);
		Carrier__c objCarrierRec4 = new TestDataFactory.CarrierBuilder().setName('Elevate').setKey('elevate').setId('elevate123').setPartnerType('TAdA').build();
    	list_Carriers.add(objCarrierRec4);

		CarrierTriggerHelper.skipTrigger = true;
		insert list_Carriers;

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR'))
			.setOpp(objOpp.Id)
			.setOwnerID(UserInfo.getUserId())
			.setBORId('zp123321')
			.build();
		list_BenefitOrders.add(objBO);

		Benefit_Order__c objBONew = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Renewal'))
			.setOpp(objOpp.Id)
			.setOwnerID(UserInfo.getUserId())
			.setBORId('zp123321')
			.build();
		list_BenefitOrders.add(objBONew);

		Benefit_Order__c objBONew2 = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Renewal'))
			.setOpp(objOpp.Id)
			.setOwnerID(UserInfo.getUserId())
			.setBORId('zp1233210')
			.build();
		list_BenefitOrders.add(objBONew2);

		Benefit_Order__c objBORenewal = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Renewal'))
			.setOpp(objOpp.Id)
			.setOwnerID(UserInfo.getUserId())
			.setBORId('zp123321')
			.build();
		list_BenefitOrders.add(objBORenewal);

		insert list_BenefitOrders;

		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		Transition_to_Fulfillment__c objTTFRecord = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setOpportunityId(objOpp.Id)
			.setRecordTypeId(idTTFBoRRecordTypeId)
			.setAccountId(objOpp.AccountId)
			.setHSARenewalDate(System.today())
			.setMedicalRenewalDate('10/10/2020')
			.setDentalRenewalDate('>10/10/2020')
			.setVisionRenewalDate('>10/10/2020')
			.setLTDRenewalDate('>10/10/2020')
			.setSTDRenewalDate('>10/10/2020')
			.setLifeRenewalDate('>10/10/2020')
			.setFSARenewalDate(System.today())
			.setDCARenewalDate(System.today())
			.setTypeofTransferTADA('HSA;FSA')
			.setTypeofTADA('Flexible Spending Account - Dependent Care;Commuter')
			.build();
		insert objTTFRecord;

    Transition_to_Fulfillment__c objTTFRecord1 = new TestDataFactory.TransitionToFulfillmentBuilder()
      .setOpportunityId(objOpp.Id)
      .setRecordTypeId(idTTFBoRRecordTypeId)
      .setAccountId(objOpp.AccountId)
      .setHSARenewalDate(System.today())
      .setMedicalRenewalDate('10/10/2020;11/10/2020')
      .setDentalRenewalDate('>10/10/2020;11/10/2020')
      .setVisionRenewalDate('>10/10/2020;11/10/2020')
      .setLTDRenewalDate('>10/10/2020;11/10/2020')
      .setSTDRenewalDate('>10/10/2020;11/10/2020')
      .setLifeRenewalDate('>10/10/2020;11/10/2020')
      .setFSARenewalDate(System.today())
      .setDCARenewalDate(System.today())
      .setTypeofTransferTADA('HSA;FSA')
      .setTypeofTADA('Flexible Spending Account - Medical;Commuter')
      .build();
    insert objTTFRecord1;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = false;

		HI_BoR_Transfer__c objHIBor = new TestDataFactory.HIBorTransferBuilder()
			.setId('zp123321')
			.setBenefitTypes('["medical", "dental", "vision", "fsa", "commuter"]')
			.setAdditionalInformation('{"administrators"=>{"fsa"=>"Zenefits", "commuter"=>"Zenefits"}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}')
			.build();
		insert objHIBor;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TestCarrierOrder')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR'))
			.setCarrier(list_Carriers[0].Id)
			.setOwnerID(UserInfo.getUserId())
			.setBenefitOrder(objBO.Id)
			.setOrderType('A;B')
			.setStartDate(System.today() - 50)
			.setImplementationStage('Ready for Document Collection')
			.setRenewalDate(Date.today())
			.setOOOComments('test comment')
			.setInitialOwner(UserInfo.getUserId())
			.setFacilitator2EnrollmentReview(UserInfo.getUserId())
			.setFacilitator2PlanReview(UserInfo.getUserId())
			.build();
		insert objCarrierOrder;

		List<Policy__c> list_Policies = new List<Policy__c>();
		Policy__c objPolicy1 = new TestDataFactory.PolicyBuilder()
		.setIdOpprtunity(objOpp.Id)
		.setIdCarrier(list_Carriers[0].Id)
		.setIsSelected(true)
		.setName('Test Policy1')
		.setBenefitType('Medical')
		.setContributionSchemeType('Percentage Of Base')
		.setIsBase(true)
		.build();
		list_Policies.add(objPolicy1);

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder()
		.setIdOpprtunity(objOpp.Id)
		.setIdCarrier(objCarrier.Id)
		.setIsSelected(true)
		.setName(list_Carriers[0].Id)
		.setBenefitType('Medical')
		.setContributionSchemeType('Percentage Of Base')
		.setIsBase(true)
		.build();
		list_Policies.add(objPolicy);

		Policy__c objFSAPolicy = new TestDataFactory.PolicyBuilder()
		.setIdOpprtunity(objOpp.Id)
		.setIdCarrier(objCarrierRec2.Id)
		.setIsSelected(true)
		.setName(CarrierOrderUtil.TADA_BEN_TYPE_FSA_MEDICAL)
		.setBenefitType(CarrierOrderUtil.TADA_BEN_TYPE_FSA_MEDICAL)
		.setContributionSchemeType('Percentage Of Base')
		.build();
		list_Policies.add(objFSAPolicy);

		Policy__c objFSAPolicyDepCare = new TestDataFactory.PolicyBuilder()
		.setIdOpprtunity(objOpp.Id)
		.setIdCarrier(objCarrierRec2.Id)
		.setIsSelected(true)
		.setName(CarrierOrderUtil.TADA_BEN_TYPE_FSA_DEPENDENT_CARE)
		.setBenefitType(CarrierOrderUtil.TADA_BEN_TYPE_FSA_DEPENDENT_CARE)
		.build();
		list_Policies.add(objFSAPolicyDepCare);

		insert list_Policies;

		list<HI_Carrier_Information__c> list_HICarrier = new List<HI_Carrier_Information__c>();
		HI_Carrier_Information__c objHICarrier = new TestDataFactory.HICarrierInformationBuilder()
		.setBorTransferId('zp123321')
		.setKey('test123')
		.setId('HI654321')
		.setPolicyNumber('Pl001')
		.setSecondaryPolicyNumber('SP001')
		.setPlanType('LTD')
		.build();
		list_HICarrier.add(objHICarrier);

		HI_Carrier_Information__c objHICarrier2 = new TestDataFactory.HICarrierInformationBuilder()
		.setBorTransferId('zp1233212')
		.setKey('test1234')
		.setId('HI54321')
		.setPolicyNumber('Test1')
		.setSecondaryPolicyNumber('Policy001')
		.setPlanType('Commuter')
		.build();
		list_HICarrier.add(objHICarrier2);

		HI_Carrier_Information__c objHICarrier3 = new TestDataFactory.HICarrierInformationBuilder()
		.setBorTransferId('zp123321')
		.setKey('test1236')
		.setId('HI7654321')
		.setPolicyNumber('Pl011')
		.setSecondaryPolicyNumber('SP011')
		.setPlanType('FSA')
		.build();
		list_HICarrier.add(objHICarrier3);

		HICarrierInformationTriggerHelper.isBOInsert = true;
		insert list_HICarrier;
	}

	@isTest
	static void createCarrierOrderMethods() {
		Benefit_Order__c objBO = [
			SELECT Id, BoR_Id__c, Is_Multi_EIN__c, Special_Enrollment__c, RecordTypeId, Opportunity__c, Parent_Benefit_Order__c, Account__c, Coverage_Effective_Date__c, Submission_Deadline__c, Type__c
			FROM Benefit_Order__c
			WHERE RecordType.Name = 'Benefits BoR'
			LIMIT 1
		];
		List<Benefit_Order__c> list_BenefitOrders = [
			SELECT Id, BoR_Id__c, Is_Multi_EIN__c, Special_Enrollment__c, RecordTypeId, Opportunity__c, Parent_Benefit_Order__c, Account__c, Coverage_Effective_Date__c, Submission_Deadline__c, Type__c
			FROM Benefit_Order__c
			WHERE BOR_ID__c = 'zp123321' AND RecordType.Name = 'Renewal'
		];
		Benefit_Order__c objBONew = list_BenefitOrders[0];
		Benefit_Order__c objBORenewal = list_BenefitOrders[1];
		list<HI_Carrier_Information__c> list_HICarrier = [
			SELECT BOR_Transfer_Id__c, Key__c, Id__c, Plan_Type__c, Policy_Number__c, Secondary_Policy_Number__c, Deleted_At__c, Authorized_Date__c, Processing_State__c
			FROM HI_Carrier_Information__c
		];
		//List<Carrier__c> list_Carriers = [SELECT Id FROM Carrier__c WHERE Name = 'Alegeus' LIMIT 1];
		Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];
		Policy__c objPolicy = [SELECT Id, Carrier__c, Policy_Number__c, Name, Benefit_Type__c FROM Policy__c WHERE Benefit_Type__c = 'Medical' AND Name != 'Test Policy1' LIMIT 1];
		Carrier_Order__c objCarrierOrder = [
      		SELECT Id, Renewal_Date__c, Name, Carrier__c, Carrier__r.Partner_Type__c, OwnerId, Benefit_Order__c, Order_Type__c, Implementation_Stage__c, Confirmation_Owner__c
			FROM Carrier_Order__c
			LIMIT 1
		];

		test.startTest();

		CarrierOrderHelperFunctions objCO = new CarrierOrderHelperFunctions();
		CarrierOrderHelperFunctions.getBenefitOrdersById(new Set<Id>{ objBO.Id });
		objCO.processHICarrierInformation(list_HICarrier);

		list<Carrier_Order_Line_Item__c> list_COLineItem = [SELECT Id, HI_Carrier_Information_Id__c FROM Carrier_Order_Line_Item__c LIMIT 1];

		if (list_COLineItem.size() > 0) {
			list<HI_Carrier_Information__c> list_HICI = [
				SELECT ID, BOR_Transfer_Id__c, Key__c, Plan_Type__c
				FROM HI_Carrier_Information__c
				WHERE ID__c = :list_COLineItem.get(0).HI_Carrier_Information_Id__c
			];

			if (list_HICI.size() > 0) {
				map<string, Carrier_Order_Line_Item__c> map_TempCarrierLI = new Map<string, Carrier_Order_Line_Item__c>();

				string strKeyTemp = list_HICI[0].BOR_Transfer_Id__c + ';' + list_HICI[0].Key__c + ';' + list_HICI[0].Plan_Type__c;
				map_TempCarrierLI.put(strKeyTemp, list_COLineItem[0]);
				objCO.deleteUpdateLineItemRecords(map_TempCarrierLI);
			}
		}

		Map<Id, Benefit_Order__c> map_OldBenefitOrders = new Map<Id, Benefit_Order__c>();
		map_OldBenefitOrders.put(objBO.id, objBO);

		Map<Id, Opportunity> map_Opportunities = new Map<Id, Opportunity>();
		map_Opportunities = new Map<Id, Opportunity>(
			[
				SELECT
					Id,
					Name,
					ownerid,
					Notes__c,
					StageName,
					Order_Lost_Date__c,
					Stage_Detail__c,
					Source_ID__c,
					HI_Effective_Date__c,
					Waiting_Period__c,
					AccountId,
					Account.Name,
					Account.Joined_Date_Panda__c,
					Account.EE_Active_Count_Panda__c,
					Type,
					UW_state__c,
					CloseDate,
					Id_And_Source_Id__c,
					Id__c,
					Big_Desk_BenOps__c,
					Owner_Role_Name__c,
					(SELECT id, Type_of_TADA_s__c, Adding_TADA__c, Renewing_TAdA_s__c, Types_of_Renewing_TAdAs__c FROM NP_Complexity_Scorings__r),
					(SELECT Id, New_TAdAs__c, Renewing_TAdAs__c FROM QA_Sheet__r)
				FROM Opportunity
				WHERE Id = :objOpp.Id
			]
		);

		List<Benefit_Order__c> list_Benefits = new List<Benefit_Order__c>();
		list_Benefits.add(objBONew);
		list_Benefits.add(objBO);                                                           

		objCo.createCarrierOrdersAgainstBO(list_Benefits, map_OldBenefitOrders, map_Opportunities);

		list<Policy__c> list_TerminatedCarriers = new List<Policy__c>();
		list_TerminatedCarriers.add(objPolicy);
		NewTransitionToFulfillmentController.terminatedCarrierList = list_TerminatedCarriers;
		list_Benefits = new List<Benefit_Order__c>();
		list_Benefits.add(objBORenewal);
		map_OldBenefitOrders = new Map<Id, Benefit_Order__c>();
		map_OldBenefitOrders.put(objBORenewal.id, objBORenewal);
		objCo.createCarrierOrdersAgainstBO(list_Benefits, map_OldBenefitOrders, map_Opportunities);

		objCo.calculateOrderAssignmentForCO(objCarrierOrder);
		CarrierOrderHelperFunctions.reAssignCOtoInitialFacilitator1OnReturnToOffice(new Set<string>{ UserInfo.getUserId() });
		objCo.getBenefitTypes('LONG_TERM_DISABILITY');
		objCo.getBenefitTypes('SHORT_TERM_DISABILITY');
		objCo.getBenefitTypes('FSA');
		objCo.getBenefitTypes('DCA');
		objCo.getBenefitTypes('Commuter');
		test.stopTest();

		System.assert([SELECT COUNT() FROM Carrier_Order__c WHERE Carrier__r.Name = 'Alegeus'] > 0);
	}

	/**
	 * @author        Deepika Saini
	 * @description	  Re-Assignment of preceeding CO on terminated CO created CO by replacing canceld CO .
	 * @param         void
	 * @return        void
	 **/
	@isTest
	static void testPreceddingCOAssignToTermCO() {
		Test.startTest();
		Utils.skipTrigger(true);
		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account').build();
		insert objAcc;

		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();

		PriceBook2 objPB = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPB;

		Product2 objProduct = new TestDataFactory.ProductBuilder().setName('Medical').setFamily('Medical').build();
		insert objProduct;

		PricebookEntry objPriceBook1 = new TestDataFactory.PricebookEntryBuilder().setProductId(objProduct.Id).setPriceBookId(Test.getStandardPriceBookId()).setUnitPrice(6).setIsActive(false).build();
		insert objPriceBook1;

		PricebookEntry objPriceBook = new TestDataFactory.PricebookEntryBuilder().setProductId(objProduct.Id).setPriceBookId(objPB.Id).setUnitPrice(6).setIsActive(true).build();
		insert objPriceBook;

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits Renewal'))
			.setAccountId(objAcc.Id)
			.setCloseDate(System.Today())
			.setName('Test Opp Renewal')
			.setStage('Open')
			.setPriceBookId(objPB.Id)
			.setBenefitsState('CA')
			.setSourceID('hawaiian_ice-new_plans_application-O321')
			.setOrderGenerated(true)
			.build();
		insert objOpp;

		List<OpportunityLineItem> list_TestOppLineItems = new List<OpportunityLineItem>();
		for (Integer i = 0; i < 2; i++) {
			list_TestOppLineItems.add(new OpportunityLineItem(OpportunityId = objOpp.Id, Quantity = 1.0, TotalPrice = 1.0, PricebookEntryId = objPriceBook.Id, product2id = objProduct.Id));
		}
		insert list_TestOppLineItems;

		State__c objState = new TestDataFactory.StateBuilder().setName('California').setId('12').setAbbreviation('CA').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier1 = new TestDataFactory.CarrierBuilder().setName('Test Carrier 1').setCarrierId('12').setState('CA').setKey('test_carrier_1_ca').setId('90').build();
		list_Carriers.add(objCarrier1);

		Carrier__c objCarrier2 = new TestDataFactory.CarrierBuilder().setName('Test Carrier 2').setCarrierId('22').setState('CA').setKey('test_carrier_2_ca').setId('80').build();
		list_Carriers.add(objCarrier2);

		Carrier__c objCarrier3 = new TestDataFactory.CarrierBuilder().setName('Test Carrier 3').setCarrierId('56').setState('CA').setKey('test_carrier_3_ca').setId('30').build();
		list_Carriers.add(objCarrier3);

		Carrier__c objCarrier4 = new TestDataFactory.CarrierBuilder().setName('Test Carrier 4').setCarrierId('34').setState('CA').setKey('test_carrier_4_ca').setId('19').build();
		list_Carriers.add(objCarrier4);

		insert list_Carriers;

		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Renewal'))
			.setName('Test BO New')
			.setAccount(objAcc.Id)
			.setOpp(objOpp.Id)
			.setCoverageEffectiveDate(System.today())
			.setOwnerID(UserInfo.getUserId())
			.setSubmissionDeadline(System.today())
			.build();
		insert objBO;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier1.Id)
			.setImplementationStage(CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType('Carrier Switch')
			.setSubmissionDeadline(System.today())
			.setMemberSubmissionDate(System.today())
			.setGroupSubmissionDate(System.today())
			.setBenefitTypes('Medical')
			.build();
		insert objCO;
		objCO.Implementation_Stage__c = 'Canceled';
		objCO.Stage_Detail__c = 'Other';
		update objCO;

		Carrier_Order__c objCO2 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
			.setBenefitOrder(objBO.Id)
			.setCarrier(objCarrier3.Id)
			.setImplementationStage(CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setOrderType('Same Carrier, NO Plan/Group Level Changes')
			.setSubmissionDeadline(System.today())
			.setMemberSubmissionDate(System.today())
			.setGroupSubmissionDate(System.today())
			.setBenefitTypes('Dental')
			.build();
		insert objCO2;

		Id idQASheetRecordType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal');
		QA_Sheet__c qas = new TestDataFactory.QASheetBuilder()
		.setBenefitOrderId(objBO.id)
		.setSICCodeSupportedByAllCarriers('Yes')
		.setSICCode('test')
		.setBAASigned('Yes')
		.setBAASignedBy('test')
		.setBSASigned('Yes')
		.setBSASignedBy('test')
		.setRecordTypeId(idQASheetRecordType)
		.setOpportunityId(objOpp.Id)
		.build();
		insert qas;

		List<QA_Lines_Of_Coverage__c> list_QaLineOfCoverage = new List<QA_Lines_Of_Coverage__c>();

		list_QaLineOfCoverage.add( new TestDataFactory.QALineOfCoverageBuilder()
			.setQASheetId(qas.Id)
			.setLinesOfCoverage('Medical')
			.build());
		list_QaLineOfCoverage[0].New_Carrier__c = 'Y';
		insert list_QaLineOfCoverage;

		Utils.skipTrigger(false);

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder()
			.setName('Test Policy')
			.setIdOpprtunity(objOpp.Id)
			.setIdCarrier(objCarrier4.Id)
			.setIsSelected(true)
			.setBenefitType('Medical')
			.setCoverageEffectiveDate(System.today().addDays(10))
			.setExternalKey('External321')
			.setIdState(objState.Id)
			.build();
		insert objPolicy;
		Test.stopTest();
	}
}