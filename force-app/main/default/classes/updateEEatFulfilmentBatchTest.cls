/**
 * @name         updateEEatFulfilmentBatchTest
 * @author       Praveen Sethu
 * @date         02-18-2021
 * @description  Testing UpdateEEatFulfilment
 **/

@isTest
public class updateEEatFulfilmentBatchTest {
	@testSetup
	static void setupData() {
		List<Product2> list_Products = new List<Product2>();
		List<PricebookEntry> list_PBEntries = new List<PricebookEntry>();

		Account objAcct = TestUtility.CompanyAccount();

		PriceBook2 objPriceBook = new PriceBook2(Name = 'Benefits 2017', IsActive = true);
		insert objPriceBook;

		list_Products.add(TestUtility.createTestProduct('Medical', 'Benefit', false));
		list_Products.add(TestUtility.createTestProduct('Long Term Disability', 'Employee', false));
		insert list_Products;

		list_PBEntries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, Test.getStandardPriceBookId(), false));
		list_PBEntries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, objPriceBook.id, false));
		insert list_PBEntries;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID).setName('Test New Plan Oppty').setPriceBookId(objPriceBook.Id)
			.setCloseDate(System.today()).setAccountId(objAcct.Id).setStage('Closed Won').setNumberOfEE(12).build();
		insert objOppty;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Carrier').setState('CA').build();
		insert objCarrier;

		Policy__c objPolicy = new TestDataFactory.PolicyBuilder().setName('Test Policy').setIdOpprtunity(objOppty.Id)
			.setIdCarrier(objCarrier.Id).setIsSelected(true).setBenefitType('Medical').build();
		insert objPolicy;
	}

	/*** Test if Batch job updates Opportunity Number of Employees and Line Item Quantities ***/
	@isTest
	static void testBatchEENonZero() {
		Opportunity objOppty = [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID];

		Benefit_Order__c objOrder = new Benefit_Order__c(
			Name = 'Test New Plan Order',
			Opportunity__c = objOppty.Id,
			Account__c = objOppty.AccountId,
			Order_Status__c = 'Fulfilled',
			EE_at_Fulfillment__c = 10
		);
		insert objOrder;

		Test.startTest();
		Database.executeBatch(new updateEEatFulfilment(), 10);
		Test.stopTest();

		objOrder = [SELECT Id, EE_at_Fulfillment__c, Opportunity__c FROM Benefit_Order__c WHERE Order_Status__c = 'Fulfilled'];
		objOppty = [SELECT Id, NumberOfEmployees__c FROM Opportunity WHERE Id = :objOrder.Opportunity__c];

		// Assert if 'EE_at_Fulfillment__c' on Benifit Order is equal to 'Number of Employees' on Opportunity
		System.assertEquals(objOrder.EE_at_Fulfillment__c, objOppty.NumberOfEmployees__c);

		List<OpportunityLineItem> list_LineItemsAssert = [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOppty.Id];
		System.assertEquals(objOrder.EE_at_Fulfillment__c, list_LineItemsAssert[0].Quantity);
	}

	/*** Test if Batch job updates Opportunity Number of Employees and Line Item Quantities ***/
	@isTest
	static void testBatchEEZero() {
		Opportunity objOppty = [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID];

		Benefit_Order__c objOrder = new Benefit_Order__c(
			Name = 'Test New Plan Order',
			Opportunity__c = objOppty.Id,
			Account__c = objOppty.AccountId,
			Order_Status__c = 'Fulfilled',
			EE_at_Fulfillment__c = 0
		);
		insert objOrder;

		Test.startTest();
		Database.executeBatch(new updateEEatFulfilment(), 10);
		Test.stopTest();

		objOrder = [SELECT Id, EE_at_Fulfillment__c, Opportunity__c FROM Benefit_Order__c WHERE Order_Status__c = 'Fulfilled'];
		objOppty = [SELECT Id, NumberOfEmployees__c FROM Opportunity WHERE Id = :objOrder.Opportunity__c];

		// Assert if 'EE_at_Fulfillment__c' on Benifit Order is equal to 'Number of Employees' on Opportunity
		System.assertEquals(objOrder.EE_at_Fulfillment__c, objOppty.NumberOfEmployees__c);

		List<OpportunityLineItem> list_LineItemsAssert = [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId = :objOppty.Id];
		System.assert(list_LineItemsAssert.isEmpty());
	}
}