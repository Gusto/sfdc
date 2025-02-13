/**
 * @description       : Test class of HICarrierInformationBatch
 * @author            : Nigam Goyal
 * @last modified on  : 07-30-2024
 * @last modified by  : Nigam Goyal
 **/
@isTest
public class HICarrierInformationBatchTest {
	/* @author        Nigam Goyal
	 * @description	  Setup method to insert tier config custom settings
	 * @param         void
	 * @return        void
	 **/
	@testSetup
	static void setup() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setActiveTadaProvider('alegeus').build();
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
		list_PriceBookEntry.add(
			new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[0].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(false).build()
		);
		list_PriceBookEntry.add(
			new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[1].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(false).build()
		);
		list_PriceBookEntry.add(
			new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[2].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(false).build()
		);
		list_PriceBookEntry.add(
			new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products2[3].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(false).build()
		);
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

		Carrier__c objCarrierRec2 = new TestDataFactory.CarrierBuilder().setName('Alegeus').setKey('alegeus').setId('alegeus123').setPartnerType('TAdA').build();
		list_Carriers.add(objCarrierRec2);

		Carrier__c objCarrierRec3 = new TestDataFactory.CarrierBuilder().setName('Test1236').setKey('test1236').setId('test1236').build();
		list_Carriers.add(objCarrierRec3);

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
		TransitiontoFulfilmentTriggerHelper.skipTrigger = false;

		HI_BoR_Transfer__c objHIBor = new TestDataFactory.HIBorTransferBuilder()
			.setId('zp123321')
			.setBenefitTypes('["medical", "dental", "vision", "fsa", "commuter"]')
			.setAdditionalInformation(
				'{"administrators"=>{"fsa"=>"Zenefits", "commuter"=>"Zenefits"}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}'
			)
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
			.setCreatedDate(DateTime.now().addDays(-35))
			.build();
		list_HICarrier.add(objHICarrier);

		HI_Carrier_Information__c objHICarrier2 = new TestDataFactory.HICarrierInformationBuilder()
			.setBorTransferId('test1234Queued')
			.setKey('test1234Queued')
			.setId('test1234Queued')
			.setPolicyNumber('Test1')
			.setSecondaryPolicyNumber('Policy001')
			.setPlanType('Commuter')
			.setCreatedDate(DateTime.now().addDays(-3))
			.build();
		list_HICarrier.add(objHICarrier2);

		HI_Carrier_Information__c objHICarrier6 = new TestDataFactory.HICarrierInformationBuilder()
			.setBorTransferId('zp1233212')
			.setKey('test1234QueuedToDead')
			.setId('HI54321QueuedToDead')
			.setPolicyNumber('Test1')
			.setSecondaryPolicyNumber('Policy001')
			.setPlanType('Commuter')
			.setCreatedDate(DateTime.now().addDays(-8))
			.build();
		list_HICarrier.add(objHICarrier6);

		HICarrierInformationTriggerHelper.queue = true;

		HI_Carrier_Information__c objHICarrier4 = new TestDataFactory.HICarrierInformationBuilder()
			.setBorTransferId('zp1233212')
			.setKey('test123444')
			.setId('HI5432144')
			.setPolicyNumber('Test1')
			.setSecondaryPolicyNumber('Policy001')
			.setPlanType('Commuter')
			.setCreatedDate(DateTime.now().addDays(-181))
			.setProcessingState('Dead')
			.build();
		list_HICarrier.add(objHICarrier4);

		HI_Carrier_Information__c objHICarrier5 = new TestDataFactory.HICarrierInformationBuilder()
			.setBorTransferId('zp1233212')
			.setKey('test123455')
			.setId('HI5432155')
			.setPolicyNumber('Test1')
			.setSecondaryPolicyNumber('Policy001')
			.setPlanType('Commuter')
			.setCreatedDate(DateTime.now().addDays(-181))
			.setProcessingState('Dead')
			.build();
		list_HICarrier.add(objHICarrier5);

		HI_Carrier_Information__c objHICarrier3 = new TestDataFactory.HICarrierInformationBuilder()
			.setBorTransferId('zp123321')
			.setKey('test1236')
			.setId('HI7654321')
			.setPolicyNumber('Pl011')
			.setSecondaryPolicyNumber('SP011')
			.setPlanType('FSA')
			.setCreatedDate(DateTime.now().addDays(-90))
			.build();
		list_HICarrier.add(objHICarrier3);

		HICarrierInformationTriggerHelper.isBOInsert = true;
		insert list_HICarrier;
	}

	/**
	 * @description Test deletion of dead records through HICarrierInformationBatch
	 * @author Nigam Goyal | 07-30-2024
	 **/
	@isTest
	static void testDeletingDeadRecords() {
        HICarrierInformationBatch objHICarrierInformationBatch = new HICarrierInformationBatch();
		List<HI_Carrier_Information__c> list_HICarrier = [
			SELECT Id, Processing_State__c, CreatedDate
			FROM HI_Carrier_Information__c
			WHERE Processing_State__c = 'Dead' AND CreatedDate < :DateTime.now().addDays(-180)
		];
		System.assertEquals(2, list_HICarrier.size(), 'Expected 2 dead records, but found zero');

		Test.startTest();
		database.executeBatch(objHICarrierInformationBatch, 10);
		Test.stopTest();

		List<HI_Carrier_Information__c> list_HICarrierAfterProcessing = [
			SELECT Id, Processing_State__c, CreatedDate
			FROM HI_Carrier_Information__c
			WHERE Processing_State__c = 'Dead' AND CreatedDate < :DateTime.now().addDays(-180)
		];
		System.assertEquals(0, list_HICarrierAfterProcessing.size(), 'Dead records not deleted');
	}

	/**
	 * @description Test marking of dead records from error records through HICarrierInformationBatch
	 * @author Nigam Goyal | 07-30-2024
	 **/
	@isTest
	static void testMarkingDeadRecords() {
        HICarrierInformationBatch objHICarrierInformationBatch = new HICarrierInformationBatch();
		List<HI_Carrier_Information__c> list_HICarrier = [
			SELECT Id, Processing_State__c, CreatedDate
			FROM HI_Carrier_Information__c
			WHERE Processing_State__c = 'Error' AND CreatedDate < :DateTime.now().addDays(-7)
		];

		System.assertEquals(1, list_HICarrier.size(), 'There is no error records');

		Test.startTest();
		database.executeBatch(objHICarrierInformationBatch, 10);
		Test.stopTest();

		List<HI_Carrier_Information__c> list_HICarrierAfterProcessing = [SELECT Id, Processing_State__c, CreatedDate FROM HI_Carrier_Information__c WHERE Id IN :list_HICarrier];
		System.assertEquals('Dead', list_HICarrierAfterProcessing[0].Processing_State__c, 'Error record is not changed to dead record');
	}
}