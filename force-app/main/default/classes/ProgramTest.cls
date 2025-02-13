/**
 * Created by brent.johnson on 11/27/16.
 */

@isTest
private without sharing class ProgramTest {
	@isTest
	static void product2s_test() {
		List<Product2> product2s = new List<Product2>();
		for (Integer count = 0; count < 5; count++) {
			Product2 objProduct = new TestDataFactory.ProductBuilder().setName('Prod').build();
			product2s.add(objProduct);
		}
		insert product2s;

		Map<Id, Product2> product2Map = Program.product2s;

		for (Product2 product2 : product2s) {
			Id product2Id = product2.Id;
			System.assert(product2Map.containsKey(product2Id), 'product2Map should contain product2Id.');
		}
	}

	@isTest
	static void price_book2s_test() {
		List<Pricebook2> pricebook2s = new List<Pricebook2>();
		for (Integer count = 0; count < 5; count++) {
			Pricebook2 objPricebook = new TestDataFactory.PriceBookBuilder().setName('PB').build();
			pricebook2s.add(objPricebook);
		}
		insert pricebook2s;

		Map<Id, Pricebook2> pricebook2Map = Program.pricebook2s;

		for (Pricebook2 pricebook2 : pricebook2s) {
			Id pricebook2Id = pricebook2.Id;
			System.assert(pricebook2Map.containsKey(pricebook2Id), 'pricebook2Map should contain pricebook2Id.');
		}
	}

	@isTest
	static void price_book_entries_test() {
		TestUtils.create_price_book_entries();
		List<PricebookEntry> pricebookEntries = [SELECT Id FROM PricebookEntry];

		Map<Id, PricebookEntry> pricebookEntryMap = Program.pricebookEntries;

		for (PricebookEntry pricebookEntry : pricebookEntries) {
			Id pricebookEntryId = pricebookEntry.Id;
			System.assert(pricebookEntryMap.containsKey(pricebookEntryId), 'pricebookEntryMap should contain pricebookEntryId.');
		}
	}

	@isTest
	static void load_accounts_test() {
		AccountTriggerHelper.skipTrigger = true;
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').setZPCompanyId('1234567890').build();
		insert objCompanyAccount;
		List<Account> accounts = new List<Account>();
		accounts.add(objCompanyAccount);

		Map<Id, Account> accountMap = new Map<Id, Account>(accounts);
		Program.loadAccounts(accountMap.keySet());

		for (Account account : accounts) {
			Id accountId = account.Id;
			Account result = Program.getAccount(accountId);
			System.assertEquals(accountId, result.Id, 'Account Id should match.');
		}
	}

	@isTest
	static void load_opportunities_test() {
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new Account();
		objAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'BizDev');
		objAccount.Name = 'Test';
		insert objAccount;

		Opportunity objOportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test - Payroll')
			.setAccountId(objAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();

		objOportunity.BizDev_Partner__c = objAccount.Id;
		insert objOportunity;

		List<Opportunity> opportunities = new List<Opportunity>();
		opportunities.add(objOportunity);

		Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(opportunities);
		Program.loadOpportunities(opportunityMap.keySet());

		for (Opportunity opportunity : opportunities) {
			Id opportunityId = opportunity.Id;
			Opportunity result = Program.getOpportunity(opportunityId);
			System.assertEquals(opportunityId, result.Id, 'Opportunity Id should match.');
		}
	}

	@isTest
	static void load_orders_test() {
		Account account = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').setZPCompanyId('11111111').build();
		insert account;
		Order objOrder = new TestDataFactory.OrderBuilder().setAccountId(account.Id).setEffectiveDate(Date.today()).setStatus('Drafted').build();
		upsert objOrder;
		List<Order> orders = new List<Order>();
		orders.add(objOrder);

		Map<Id, Order> orderMap = new Map<Id, Order>(orders);
		Program.loadOrdersWithOrderItems(orderMap.keySet());

		for (Order order : orders) {
			Id orderId = order.Id;
			Order result = Program.getOrderWithOrderItems(orderId);
			System.assertEquals(orderId, result.Id, 'Order Id should match.');
		}
	}
}