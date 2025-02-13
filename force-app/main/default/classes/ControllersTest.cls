/**
 * Created by brent.johnson on 11/27/16.
 */
@isTest
private without sharing class ControllersTest {
	@isTest
	static void assign_pricebook_from_account_test() {
		Account account = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.build();
		account.Pricebook2__c = Test.getStandardPricebookId();
		insert account;
		System.assertNotEquals(null, account.Id, 'Id cannot be null');
		System.assertNotEquals(null, account.Pricebook2__c, 'Incorrect Result');

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(account.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setIsHistorical(true)
			.setNumberOfEE(12)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		insert objOpportunity;

		Order order = new TestDataFactory.OrderBuilder()
			.setAccountId(account.Id)
			.setOpportunityId(objOpportunity.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setStatus('Drafted')
			.setOwnerId(UserInfo.getUserId())
			.setEffectiveDate(System.today())
			.build();
		insert order;
		System.assertEquals(null, order.Pricebook2Id, 'Incorrect Result');

		Id accountPricebookId = [SELECT Pricebook2__c FROM Account WHERE Id = :order.AccountId][0].Pricebook2__c;
		System.assertNotEquals(null, accountPricebookId, 'Incorrect Result');

		Controllers.Orders controller = new Controllers.Orders(new List<Order>{ Order });
		Test.startTest();
		controller.assignPricebook();
		Test.stopTest();

		System.assertEquals(accountPricebookId, order.Pricebook2Id, 'Incorrect Result');
	}

	@isTest
	static void assign_pricebook_from_opportunity_test() {
		Account account = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.build();
		insert account;

		Opportunity opportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(account.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setIsHistorical(true)
			.setNumberOfEE(12)
			.setHIEffectiveDate(System.today().addDays(30))
			.setPriceBookId(Test.getStandardPricebookId())
			.build();
		insert opportunity;

		System.assertNotEquals(null, Opportunity.Id, 'Incorrect Result');
		System.assertNotEquals(null, Opportunity.Pricebook2Id, 'Incorrect Result');

		Order order = new TestDataFactory.OrderBuilder()
			.setAccountId(account.Id)
			.setOpportunityId(opportunity.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setStatus('Drafted')
			.setOwnerId(UserInfo.getUserId())
			.setEffectiveDate(System.today())
			.build();
		insert order;
		order.OpportunityId = opportunity.Id;
		System.assertEquals(null, order.Pricebook2Id, 'Id cannot be null');

		Id opportunityPricebookId = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :order.OpportunityId LIMIT 1][0].Pricebook2Id;
		System.assertNotEquals(null, opportunityPricebookId, 'Id cannot be null');

		Controllers.Orders controller = new Controllers.Orders(new List<Order>{ Order });
		Test.startTest();
		controller.assignPricebook();
		Test.stopTest();

		System.assertEquals(opportunityPricebookId, order.Pricebook2Id, 'Incorrect Result');
	}

	@isTest
	static void create_standard_order_package() {
		TestUtils.create_price_book_entries();
		BulkOrderCSVDataTriggerHelper.skipTrigger = true;

		Pricebook2 testPricebook = [SELECT Id, (SELECT Id FROM PricebookEntries) FROM Pricebook2 WHERE IsStandard = FALSE LIMIT 1][0];
		System.assertNotEquals(null, testPricebook, 'Incorrect Result');
		List<PricebookEntry> testEntries = testPricebook.PricebookEntries;
		System.assert(!testEntries.isEmpty(), 'This List cannot be empty');
		for (PricebookEntry pbeEntry : testEntries) {
			pbeEntry.Maintain__c = true;
		}
		update testEntries;

		Account account = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.build();
		insert account;

		Opportunity opportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(account.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setIsHistorical(true)
			.setNumberOfEE(12)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		insert opportunity;

		Order order = new TestDataFactory.OrderBuilder()
			.setAccountId(account.Id)
			.setOpportunityId(opportunity.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setStatus('Drafted')
			.setOwnerId(UserInfo.getUserId())
			.setEffectiveDate(System.today())
			.build();
		order.Pricebook2Id = testPricebook.Id;
		insert order;

		System.assertNotEquals(null, order.Id, 'Id cannot be null');
		System.assertEquals(testPricebook.Id, order.Pricebook2Id, 'Incorrect Result');

		Controllers.Orders controller = new Controllers.Orders(new List<Order>{ Order });
		Test.startTest();
		controller.createStandardPackage();
		Test.stopTest();

		List<OrderItem> orderItems = [SELECT Id FROM OrderItem WHERE OrderId = :order.Id];
		System.assert(!orderItems.isEmpty(), 'List cannot be empty');
	}

	@isTest
	static void sync_account() {
		BulkOrderCSVDataTriggerHelper.skipTrigger = true;

		Map<SObjectField, SObjectField> fieldReference = new Map<SObjectField, SObjectField>{
			Schema.Account.Previous_Payroll_Provider__c => Schema.Order.Previous_Payroll_Provider__c,
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

		Account testAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert testAccount;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity opportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(testAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setIsHistorical(true)
			.setNumberOfEE(12)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		insert opportunity;

		Order order = new TestDataFactory.OrderBuilder()
			.setAccountId(testAccount.Id)
			.setOpportunityId(opportunity.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setStatus('Drafted')
			.setOwnerId(UserInfo.getUserId())
			.setEffectiveDate(System.today())
			.build();
		insert order;

		System.assertNotEquals(null, order.Id, 'Id cannot be null');

		Controllers.Orders controller = new Controllers.Orders(new List<Order>{ Order });
		Test.startTest();
		controller.syncAccount();
		Test.stopTest();
	}
}