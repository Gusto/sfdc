/**
 * Created by brent.johnson on 11/27/16.
 */

@isTest
private without sharing class SObjectBuilderTest {
	@isTest
	static void build_order() {
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
		insert objAccount;
		Id accountId = objAccount.Id;

		SObjectBuilder.OrderBuilder orderBuilder = new SObjectBuilder.OrderBuilder(accountId);
		Test.startTest();
		BulkOrderCSVDataTriggerHelper.skipTrigger = true;
		Order objOrder = orderBuilder.create();
		Test.stopTest();

		System.assertEquals(accountId, objOrder.AccountId, 'Account Id should match.');
		System.assertEquals(System.today(), objOrder.EffectiveDate, 'EffectiveDate should match.');
		System.assertEquals('Drafted', objOrder.Status, 'Status should be Drafted');
	}

	@isTest
	static void build_order_item() {
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
		insert objAccount;
		Order objOrder = new TestDataFactory.OrderBuilder().setAccountId(objAccount.Id).setEffectiveDate(System.today()).setStatus('Drafted').build();
		insert objOrder;

		Product2 objProduct = new TestDataFactory.ProductBuilder().setName('Medical').setFamily('Medical').build();
		insert objProduct;
		
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;
		PriceBook2 objPB = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPB;

		PricebookEntry objPriceBookEntry = new TestDataFactory.PricebookEntryBuilder().setProductId(objProduct.Id).setPriceBookId(objPB.Id).build();

		PricebookEntry standardPricebookEntry = objPriceBookEntry.clone(false);
		standardPricebookEntry.Pricebook2Id = Test.getStandardPricebookId();
		insert standardPricebookEntry;
		insert objPriceBookEntry;

		Id orderId = objOrder.Id;
		Id pricebookEntryId = objPriceBookEntry.Id;
		Decimal quantity = 5;
		Decimal unitPrice = 10;

		SObjectBuilder.OrderItemBuilder orderItemBuilder = new SObjectBuilder.OrderItemBuilder(orderId, pricebookEntryId, quantity, unitPrice);
		Test.startTest();
		BulkOrderCSVDataTriggerHelper.skiptrigger = true;
		OrderItem orderItem = orderItemBuilder.create();
		Test.stopTest();

		System.assertEquals(orderId, OrderItem.OrderId, 'OrderId should match.');
		System.assertEquals(pricebookEntryId, OrderItem.PricebookEntryId, 'PricebookEntryId should match.');
		System.assertEquals(quantity, OrderItem.Quantity, 'Quantity should match.');
		System.assertEquals(unitPrice, OrderItem.UnitPrice, 'UnitPrice should match.');
	}
}