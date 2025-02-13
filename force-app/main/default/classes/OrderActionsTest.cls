/**
 * Created by brent.johnson on 11/27/16.
 */

@isTest
private without sharing class OrderActionsTest {
	@isTest
	static void assign_pricebook_from_account_test() {
		Account objAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId('Company')
			 .setPricebook2Id(Test.getStandardPricebookId())
			 .build(); 
		insert objAccount;
		System.assertNotEquals(null, objAccount.Id);
		System.assertNotEquals(null, objAccount.Pricebook2__c);

		Order objOrder = new TestDataFactory.OrderBuilder()
			 .setAccountId(objAccount.Id)
			 .build();
		System.assertEquals(null, objOrder.Pricebook2Id);

		Id idAccountPriceBook = [SELECT Pricebook2__c FROM Account WHERE Id = :objOrder.AccountId][0].Pricebook2__c;
		System.assertNotEquals(null, idAccountPriceBook);

		Test.startTest();
		OrderActions.assignPricebook(objOrder);
		Test.stopTest();

		System.assertEquals(idAccountPriceBook, objOrder.Pricebook2Id);
	}

	@isTest
	static void assign_pricebook_from_opportunity_test() {
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			 .setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits New Plan'))
			 .setPriceBookId(Test.getStandardPricebookId())
			 .build();
		insert objOpportunity;
		System.assertNotEquals(null, objOpportunity.Id);
		System.assertNotEquals(null, objOpportunity.Pricebook2Id);

		Order objOrder = new TestDataFactory.OrderBuilder()
			 .setOpportunityId(objOpportunity.Id)
			 .build();
		System.assertEquals(null, objOrder.Pricebook2Id);

		Id idOpportunityPricebook = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :objOrder.OpportunityId LIMIT 1][0].Pricebook2Id;
		System.assertNotEquals(null, idOpportunityPricebook);

		Test.startTest();
		OrderActions.assignPricebook(objOrder);
		Test.stopTest();

		System.assertEquals(idOpportunityPricebook, objOrder.Pricebook2Id);
	}

	@isTest
	static void create_standard_order_package() {
		TestUtils.create_price_book_entries();
		BulkOrderCSVDataTriggerHelper.skipTrigger = true;
		Pricebook2 testPricebook = [SELECT Id, (SELECT Id FROM PricebookEntries) FROM Pricebook2 WHERE IsStandard = FALSE LIMIT 1][0];
		System.assertNotEquals(null, testPricebook);
		List<PricebookEntry> testEntries = testPricebook.PricebookEntries;
		System.assert(!testEntries.isEmpty());
		for (PricebookEntry pbeEntry : testEntries) {
			pbeEntry.Maintain__c = true;
		}
		update testEntries;

		Account objAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId('Company')
			 .setPricebook2Id(Test.getStandardPricebookId())
			 .build();
		 INSERT objAccount;
 
		 Order objOrder = new TestDataFactory.OrderBuilder()
			 .setAccountId(objAccount.Id)
			 .setEffectiveDate(System.today())
			 .setStatus('Drafted')
			 .setPricebook2Id(testPricebook.Id)
			 .build();
		insert objOrder;
		System.assertNotEquals(null, objOrder.Id);
		System.assertEquals(testPricebook.Id, objOrder.Pricebook2Id);
		Controllers.Orders controller = new Controllers.Orders(new List<Order>{ objOrder });

		Test.startTest();
		controller.createStandardPackage();
		Test.stopTest();

		List<OrderItem> orderItems = [SELECT Id FROM OrderItem WHERE OrderId = :objOrder.Id];
		System.assert(!orderItems.isEmpty());
	}

	@isTest
	static void link_to_opportunity() {
		TestUtility.createCompanyPriceBookInformation();
		BulkOrderCSVDataTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId('Company')
			 .setZPCompanyId('12121212121212')
			 .build();
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setStage('SAL')
			.setCloseDate(system.today())
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
			.setAccountId(objAccount.Id)
			.setNumberOfEE(1)
			.setZPCompanyId('12121212121212')
			.setSourceID('12121212121212')
			.build();

		insert objOpportunity;

		 // Order order = createOrder();
		// order.AccountId = opportunity.AccountId;
Order objOrder = new TestDataFactory.OrderBuilder()
			 .setAccountId(objOpportunity.AccountId)
			 .setEffectiveDate(System.today())
			 .setStatus('Drafted')
			 .build();

		Test.startTest();
		OrderActions.linkToOpportunity(objOrder);
		Test.stopTest();

		System.assertEquals(objOpportunity.Id, objOrder.OpportunityId);
	}

	@isTest
	static void sync_account() {
		Map<SObjectField, SObjectField> fieldReference = new Map<SObjectField, SObjectField>{
			//Schema.Account.Previous_Payroll_Provider__c => Schema.Order.Previous_Payroll_Provider__c,
			Schema.Account.BillingStreet => Schema.Order.BillingStreet,
			Schema.Account.BillingPostalCode => Schema.Order.BillingPostalCode,
			Schema.Account.BillingCity => Schema.Order.BillingCity,
			Schema.Account.BillingState => Schema.Order.BillingState,
			Schema.Account.BillingStateCode => Schema.Order.BillingStateCode,
			Schema.Account.BillingCountry => Schema.Order.BillingCountry,
			Schema.Account.BillingCountryCode => Schema.Order.BillingCountryCode,
			Schema.Account.ShippingStreet => Schema.Order.ShippingStreet,
			Schema.Account.ShippingPostalCode => Schema.Order.ShippingPostalCode,
			Schema.Account.ShippingCity => Schema.Order.ShippingCity,
			Schema.Account.ShippingState => Schema.Order.ShippingState,
			Schema.Account.ShippingStateCode => Schema.Order.ShippingStateCode,
			Schema.Account.ShippingCountry => Schema.Order.ShippingCountry,
			Schema.Account.ShippingCountryCode => Schema.Order.ShippingCountryCode
		};

		Account objTestAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId('Company')
			 .setZPCompanyId('12121212121212')
			 .setBillingStreet('test')
			 .setBillingState('New York')
			 .setBillingCountry('United States')
			 .setBillingCity('test')
			 .setBillingPostalCode('123456')
			 .setBillingCountryCode('US')
			 .setBillingStateCode('NY')
			 .setShippingStreet('test')
			 .setShippingState('New York')
			 .setShippingCountry('United States')
			 .setShippingCity('test')
			 .setShippingPostalCode('123456')
			 .setShippingCountryCode('US')
			 .setShippingStateCode('NY')
			 .build();
		insert objTestAccount;

		Order objOrder = new TestDataFactory.OrderBuilder()
			 .setAccountId(objTestAccount.Id)
			 .setEffectiveDate(System.today())
			 .setStatus('Drafted')
			 .setBillingStreet('test')
			 .setBillingState('New York')
			 .setBillingCountry('United States')
			 .setBillingCity('test')
			 .setBillingPostalCode('123456')
			 .setBillingCountryCode('US')
			 .setBillingStateCode('NY')
			 .setShippingStreet('test')
			 .setShippingState('New York')
			 .setShippingCountry('United States')
			 .setShippingCity('test')
			 .setShippingPostalCode('123456')
			 .setShippingCountryCode('US')
			 .setShippingStateCode('NY')
			 .build();

		Test.startTest();
		BulkOrderCSVDataTriggerHelper.skipTrigger = true;
		OrderActions.syncAccount(objOrder);
		Test.stopTest();

		for (SObjectField accountField : fieldReference.keySet()) {
			SObjectField orderField = fieldReference.get(accountField);
			System.assertEquals(objTestAccount.get(accountField), objOrder.get(orderField));
		}
	}
}