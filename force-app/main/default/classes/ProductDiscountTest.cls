/**
 * @description Test class for Product Discounts
 * This is also the test class to test functionalities of OpportunityLineItemTriggerHandler
 * @author Debasmita Rawooth
 * @author David Schach
 * @date Jan 2022
 * @see ProductDiscountTriggerHandler
 * @see ProductDiscountHelper
 * @group Product Discount
 */
@IsTest
private class ProductDiscountTest {
	private static final String RESELLER_ZPFIRM_ID = '9999';
	private static final String CUSTOMER_ZPCOMPANY_ID = '8888';
	private static final String ARD_CUSTOMER_ZPCOMPANY_ID = '4444';
	/**
	 * @description Set up data - Product, Pricebook
	 * @author Debasmita Rawooth
	 */
	@testSetup
	private static void setup() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		List<PriceBook2> list_Pricebooks = new List<PriceBook2>();
		PriceBook2 objCorePricebook = new PriceBook2(Name = objTierConfig.Old_Price_1__c, IsActive = true, Product_Tier__c = objTierConfig.Old_Tier_1__c);
		list_Pricebooks.add(objCorePricebook);

		PriceBook2 objPremiumPricebook = new PriceBook2(Name = objTierConfig.New_Price_3__c, IsActive = true, Product_Tier__c = objTierConfig.New_Tier_3__c);
		list_Pricebooks.add(objPremiumPricebook);

		PriceBook2 objArdiusPriceBook = new TestDataFactory.PriceBookBuilder().setName('Ardius').setActive().build();
		list_Pricebooks.add(objArdiusPriceBook);

		PriceBook2 objArdiusStandardPriceBook = new TestDataFactory.PriceBookBuilder().setName('R&D Tax Credits - Gusto Standard').setActive().build();
		list_Pricebooks.add(objArdiusStandardPriceBook);

		PriceBook2 objArdiusPremiumPriceBook = new TestDataFactory.PriceBookBuilder().setName('R&D Tax Credits - Gusto Premium Order Form').setActive().build();
		list_Pricebooks.add(objArdiusPremiumPriceBook);

		insert list_Pricebooks;

		Ardius_Configuration__c objArdiusConfig = new TestDataFactory.ArdiusConfigurationBuilder()
			.build();
		insert objArdiusConfig;

		List<Product2> list_Products = new List<Product2>();
		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('Company')
				.setFamily('Company')
				.setProductType(OpportunityUtil.PRODUCT_TYPE_MONTHLY)
				.setProductCategory('Payroll')
				.setDiscountsType('premium_tier_discount;accountant')
				.build()
		);
		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('Active Employee')
				.setFamily('Payroll')
				.setProductType(OpportunityUtil.PRODUCT_TYPE_EMPLOYEES)
				.setProductCategory('Payroll')
				.setDiscountsType('premium_tier_discount;accountant')
				.build()
		);
		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('Contractor')
				.setFamily('Payroll')
				.setProductType(OpportunityUtil.PRODUCT_TYPE_CONTRACTORS)
				.setProductCategory('Payroll')
				.setDiscountsType('premium_tier_discount;accountant')
				.build()
		);

		Product2 objArdiusProd1 = new TestDataFactory.ProductBuilder().setName('Ardius Calculation Fee').setFamily('Ardius').setDiscountsType('premium_tier_discount;accountant').build();
		list_Products.add(objArdiusProd1);

		Product2 objArdiusProd2 = new TestDataFactory.ProductBuilder().setName('Utilization %').setFamily('Ardius').setDiscountsType('premium_tier_discount;accountant').build();
		list_Products.add(objArdiusProd2);

		for (Product2 objProd2 : list_Products) {
			objProd2.ExternalId = '1';
		}
		insert list_Products;

		List<PricebookEntry> list_Entries = new List<PricebookEntry>();
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, objCorePricebook.Id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, objCorePricebook.Id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, objCorePricebook.Id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, objPremiumPricebook.Id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, objPremiumPricebook.Id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, objPremiumPricebook.Id, false));

		//Ardius Pricebook entries
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objArdiusProd1.Id).setUnitPrice(1000).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objArdiusProd2.Id).setUnitPrice(100).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objArdiusProd1.Id).setUnitPrice(1000).setPriceBookId(objArdiusStandardPriceBook.Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objArdiusProd2.Id).setUnitPrice(100).setPriceBookId(objArdiusStandardPriceBook.Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objArdiusProd1.Id).setUnitPrice(1000).setPriceBookId(objArdiusPremiumPriceBook.Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objArdiusProd2.Id).setUnitPrice(100).setPriceBookId(objArdiusPremiumPriceBook.Id).setIsActive(true).build());

		insert list_Entries;

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account 1').setZPFirmId(RESELLER_ZPFIRM_ID).build();
		objResellerAccount.Customers_Reward_Eligible__c = 4;
		objResellerAccount.AM_Tier__c = 'Bronze';
		insert objResellerAccount;

		Account objCompAccount = new TestDataFactory.AccountBuilder()
			.setNumberOfActiveEEs(5)
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Gustomer1')
			.setZPCompanyId(CUSTOMER_ZPCOMPANY_ID)
			.build();
		objCompAccount.Pricing__c = objPremiumPricebook.Name;
		objCompAccount.Sold_By__c = objResellerAccount.Id;
		objCompAccount.Number_of_Active_Employees__c = 5;
		objCompAccount.Tier__c = objTierConfig.New_Tier_3__c;
		insert objCompAccount;

		Account objArdiusGustoCustomer = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Ardius_A01')
			.setZpCompanyId(ARD_CUSTOMER_ZPCOMPANY_ID)
			.setBillingState('California')
			.setBillingCountry('United States')
			.build();

		insert objArdiusGustoCustomer;

		Account objArdiusNonGustoCustomer = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Ardius_A02')
			.setBillingState('California')
			.setBillingCountry('United States')
			.build();

		insert objArdiusNonGustoCustomer;

		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = new TestDataFactory.ZPPayerPricingPlanBuilder()
			.setPayerId(CUSTOMER_ZPCOMPANY_ID)
			.setId('56789')
			.setProductId('1')
			.build();
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objPayerPricingPlan;
		TriggerHandler.clearbypass('AccountTriggerHandler');

		Opportunity objPayrollOpp = new TestDataFactory.OpportunityBuilder()
			.setName('Gustomer - Payroll')
			.setCloseDate(Date.today().addDays(19))
			.setStage(null)
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setSoldBy(objResellerAccount.Id)
			.setAccountId(objCompAccount.Id)
			.setZPCompanyId(CUSTOMER_ZPCOMPANY_ID)
			.build();
		objPayrollOpp.NumberOfEmployees__c = 5;
		insert objPayrollOpp;
	}

	/**
	 * @author         Debasmita Rawooth
	 * @author         David Schach
	 * @description    Test No Product Discounts are created
	 */
	@isTest
	private static void testNoProductDiscount() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Opportunity objOpportunityAssert = [SELECT Id, Name, ZP_Company_ID__c, Source_Id__c, NumberOfEmployees__c FROM Opportunity WHERE AccountId = :objAccountAssert.Id];
		System.assertEquals(objOpportunityAssert.ZP_Company_ID__c, objAccountAssert.ZP_Company_Id__c);
		System.assertEquals(5, objOpportunityAssert.NumberOfEmployees__c);
		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         David Schach
	 * @description    Test No Product Discounts are created with negative percent
	 */
	@IsTest
	static void testInsertNegativeProductDiscount() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Opportunity objOpportunityAssert = [SELECT Id, Name, ZP_Company_ID__c, Source_Id__c, NumberOfEmployees__c FROM Opportunity WHERE AccountId = :objAccountAssert.Id];

		Product_Discount__c objPD = new Product_Discount__c();

		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.Discount_Type__c = 'premium_tier_discount';
		objPD.Discount_Percent__c = -5;
		objPD.ZP_Product_Id__c = '1';
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		Test.startTest();
		upsert objPD UniqueId__c;
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @description The Reseller is inserted and goes up a tier level
	 * @author David Schach
	 */
	@isTest
	private static void testResellerDiscountInsertUpgrade() {
		Test.startTest();

		Account objResellerAccount = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];

		System.assertEquals(10.00, objResellerAccount.Discount__c);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);

		Account objCustomerAccount = [SELECT Id, Name, ZP_Company_ID__c, Reward_Eligible__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];
		System.assert(!objCustomerAccount.Reward_Eligible__c);
		objCustomerAccount.Reward_Eligible__c = true;
		objCustomerAccount.Product_Interest__c = 'international_payroll_onboarding';
		objCustomerAccount.Product_Interest_Countries__c = 'CA';
		update objCustomerAccount;

		objResellerAccount.Customers_Reward_Eligible__c = 20;
		objResellerAccount.AM_Tier__c = 'Silver';
		update objResellerAccount;

		Account objResellerAssert = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];

		System.assertEquals(15.00, objResellerAssert.Discount__c);

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);
		System.assertEquals(15, [SELECT Discount_Percent__c FROM Product_Discount__c LIMIT 1].Discount_Percent__c);

		Test.stopTest();
	}

	/**
	 * @description The reseller is inserted and goes down a level
	 * @author David Schach
	 */
	@isTest
	private static void testResellerDiscountInsertDowngrade() {
		Test.startTest();

		Account objResellerAccount = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];

		System.assertEquals(10.00, objResellerAccount.Discount__c);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);

		Account objCustomerAccount = [SELECT Id, Name, ZP_Company_ID__c, Reward_Eligible__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];
		System.assert(!objCustomerAccount.Reward_Eligible__c);
		objCustomerAccount.Reward_Eligible__c = true;
		update objCustomerAccount;

		objResellerAccount.Customers_Reward_Eligible__c = 0;
		objResellerAccount.AM_Tier__c = 'Starter';
		update objResellerAccount;

		Account objResellerAssert = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];
		System.assertEquals(0.00, objResellerAssert.Discount__c);

		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @description The reseller is inserted after the opp goes CW
	 * @author Prity Kumari
	 */
	@isTest
	private static void testResellerDiscountAfterCW() {
		Test.startTest();
		//workaround to reset limits
		Account objResellerAccount = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];

		System.assertEquals(10.00, objResellerAccount.Discount__c);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);

		Account objCustomerAccount = [SELECT Id, Name, ZP_Company_ID__c, Reward_Eligible__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];
		System.assert(!objCustomerAccount.Reward_Eligible__c);
		objCustomerAccount.Reward_Eligible__c = true;
		update objCustomerAccount;
		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);

		Opportunity objOpportunity = [SELECT Id, Name, ZP_Company_ID__c, Source_Id__c, NumberOfEmployees__c FROM Opportunity WHERE AccountId = :objCustomerAccount.Id];
		TriggerHandler.bypass('OpportunityTriggerHandler');
		objOpportunity.StageName = 'Closed Won';
		update objOpportunity;
		TriggerHandler.clearAllBypasses();

		objResellerAccount.Customers_Reward_Eligible__c = 0;
		objResellerAccount.AM_Tier__c = 'Starter';
		update objResellerAccount;

		Test.stopTest();
		Account objResellerAssert = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];
		System.assertEquals(0.00, objResellerAssert.Discount__c);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         Debasmita Rawooth
	 * @author         David Schach
	 * @description    Test reseller discount update to 0 and Product Discount Deletion
	 */
	@isTest
	private static void testResellerDiscountDelete() {
		Test.startTest();
		Account objResellerAccount = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];

		System.assertEquals(10.00, objResellerAccount.Discount__c);

		Account objAccountAssert = [SELECT Id, Name, Reward_Eligible__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];
		objAccountAssert.Reward_Eligible__c = true;
		update objAccountAssert;

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);

		objResellerAccount.Customers_Reward_Eligible__c = 0;
		objResellerAccount.AM_Tier__c = 'Starter';
		objResellerAccount.Discount__c = 0;
		update objResellerAccount;
		// should auto-delete, as has 0%
		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);

		Product_Discount__c deletedPD = [SELECT Id, Discount_Percent__c, Discount_Amount__c FROM Product_Discount__c WHERE IsDeleted = TRUE LIMIT 1 ALL ROWS];
		Boolean hasError = false;
		try {
			undelete deletedPD;
		} catch (DMLException e) {
			hasError = true;
		}
		Test.stopTest();
		System.assert(hasError);
	}

	/**
	 * @author         Debasmita Rawooth
	 * @author         David Schach
	 * @description    Test Product Discount is created on ZP Adjustment creation
	 */
	@isTest
	private static void testCustomerSelectDiscountInsertTwo() {
		Account objAccountAssert = [SELECT Id, Name FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		Opportunity objOpportunityAssert = [
			SELECT Id, Name, Amount, Pricebook2.Product_Tier__c, IsClosed, RecordType.Name, TotalOpportunityQuantity
			FROM Opportunity
			WHERE AccountId = :objAccountAssert.Id
		];
		System.assertEquals(objTierConfig.New_Tier_3__c, objOpportunityAssert.Pricebook2.Product_Tier__c);

		Decimal decInitialOppAmount = objOpportunityAssert.Amount;

		System.assert([SELECT COUNT() FROM OpportunityLineItem] >= 2);

		Test.startTest();

		Product_Discount__c objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.ZP_Product_Id__c = '1';
		objPD.Discount_Type__c = 'premium_tier_discount';
		objPD.Discount_Percent__c = 5.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		upsert objPD UniqueId__c;

		Test.stopTest();

		Product_Discount__c objPDAssert = [SELECT Id, Discount_Percent__c FROM Product_Discount__c];

		System.assertEquals(5.00, objPDAssert.Discount_Percent__c);

		objOpportunityAssert = [SELECT Id, Name, Amount, IsClosed FROM Opportunity WHERE AccountId = :objAccountAssert.Id];

		List<Product_Discount__c> pdList = [SELECT Id, Discount_Percent__c FROM Product_Discount__c];
		System.assertEquals(1, pdList.size());

		List<OpportunityLineItem> list_OppLineItemsAssert = [
			SELECT Id, Opportunity.Amount, PricebookEntry.Pricebook2.Product_Tier__c, Subtotal, Discount, TotalPrice
			FROM OpportunityLineItem
			WHERE OpportunityId = :objOpportunityAssert.Id
		];
		System.assert(!list_OppLineItemsAssert.isEmpty());
		for (OpportunityLineItem objOLI : list_OppLineItemsAssert) {
			System.assertEquals(objTierConfig.New_Tier_3__c, objOLI.PricebookEntry.Pricebook2.Product_Tier__c);
		}

		Decimal decAmount = 0;

		for (OpportunityLineItem objOppLineItem : list_OppLineItemsAssert) {
			decAmount += objOppLineItem.TotalPrice;
			System.assertEquals(pdList[0].Discount_Percent__c, objOppLineItem.Discount);
		}

		System.assertEquals(decAmount, objOpportunityAssert.Amount);
		System.assert(decInitialOppAmount > list_OppLineItemsAssert[0].Opportunity.Amount);

		objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.ZP_Product_Id__c = '1';
		objPD.Discount_Type__c = 'premium_tier_discount';
		objPD.Discount_Percent__c = 10.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		upsert objPD UniqueId__c;

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);

		System.assertEquals(0.9 * decInitialOppAmount, [SELECT Id, Amount FROM Opportunity WHERE Id = :objOpportunityAssert.Id].Amount);
	}

	/**
	 * @author         Debasmita Rawooth
	 * @author         David Schach
	 * @description    Test Product Discount is created on ZP Adjustment creation
	 */
	@isTest
	private static void testProductDiscountInsertTestInvalidType() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		Opportunity objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id];
		Decimal decInitialOppAmount = objOpportunityAssert.Amount;

		Test.startTest();

		Product_Discount__c objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.ZP_Product_Id__c = '1';
		objPD.Discount_Type__c = 'test';
		objPD.Discount_Percent__c = 5.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);

		Boolean hasError = false;
		try {
			upsert objPD UniqueId__c;
		} catch (Exception e) {
			hasError = true;
		}
		Test.stopTest();
		System.assert(hasError);

		objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id AND IsClosed = FALSE];

		System.assertEquals(decInitialOppAmount, objOpportunityAssert.Amount);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);

		List<OpportunityLineItem> list_OppLineItemsAssert = [SELECT Id, Opportunity.Amount, Subtotal, Discount, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :objOpportunityAssert.Id];

		System.assert(!list_OppLineItemsAssert.isEmpty());

		Decimal decAmount = 0;
		for (OpportunityLineItem objOppLineItem : list_OppLineItemsAssert) {
			decAmount += objOppLineItem.TotalPrice;
		}
		System.assertEquals(decAmount, objOpportunityAssert.Amount);
	}

	/**
	 * @author         David Schach
	 * @description    Test Product Discount is not included when CloseDate does not fall between start and end dates
	 */
	@isTest
	private static void testCustomerSelectDiscountInsertBadDates() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		Opportunity objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id];
		Decimal decInitialOppAmount = objOpportunityAssert.Amount;

		Test.startTest();

		Product_Discount__c objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.ZP_Product_Id__c = '1';
		objPD.Discount_Type__c = 'premium_tier_discount';
		objPD.Discount_Percent__c = 5.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(2);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);

		upsert objPD UniqueId__c;

		Test.stopTest();

		objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id AND IsClosed = FALSE];

		System.assertEquals(decInitialOppAmount, objOpportunityAssert.Amount);

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         Debasmita Rawooth
	 * @description    Test reseller discount update and accountant product discount creation
	 */
	@isTest
	private static void testResellerDiscount() {
		Test.startTest();
		Account objResellerAssert = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];
		System.assertEquals(10.00, objResellerAssert.Discount__c);

		Account objCustomerAccount = [SELECT Id, Name, ZP_Company_ID__c, Reward_Eligible__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];
		System.assert(!objCustomerAccount.Reward_Eligible__c);

		objCustomerAccount.Reward_Eligible__c = true;
		update objCustomerAccount;

		Opportunity objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objCustomerAccount.Id AND IsClosed = FALSE];

		Product_Discount__c objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.ZP_Product_Id__c = '1';
		objPD.Discount_Type__c = 'premium_tier_discount';
		objPD.Discount_Percent__c = 5.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		upsert objPD UniqueId__c;

		List<Product_Discount__c> listProductDiscountAssert = [
			SELECT Id, ZP_Product_Id__c, Discount_Type__c, Discount_Percent__c
			FROM Product_Discount__c
			WHERE Opportunity__c = :objOpportunityAssert.Id
		];
		System.debug('listProductDiscountAssert:' + listProductDiscountAssert);
		System.assertEquals(2, listProductDiscountAssert.size());

		for (Product_Discount__c pdc : listProductDiscountAssert) {
			if (pdc.ZP_Product_Id__c == null) {
				System.assertEquals(10, pdc.Discount_Percent__c);
			} else if (pdc.Discount_Type__c == 'premium_tier_discount') {
				System.assertEquals(5, pdc.Discount_Percent__c);
			}
		}

		List<OpportunityLineItem> list_OppLineItemsAssert = [SELECT Id, Opportunity.Amount, Subtotal, Discount, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :objOpportunityAssert.Id];
		System.assert(!list_OppLineItemsAssert.isEmpty());

		Decimal decAmount = 0;
		for (OpportunityLineItem objOppLineItem : list_OppLineItemsAssert) {
			decAmount += objOppLineItem.TotalPrice;
			System.assertEquals(15.00, objOppLineItem.Discount);
		}
		System.assertEquals(decAmount, list_OppLineItemsAssert[0].Opportunity.Amount);

		Test.stopTest();
	}

	/**
	 * @author         Debasmita Rawooth
	 * @description    Test Product Discounts are deleted on update of ZP Adjustment to update discount to 0
	 */
	@isTest
	private static void testCustomerSelectDiscountDeletetZeroPercent() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		Opportunity objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id];

		System.assert([SELECT COUNT() FROM OpportunityLineItem] >= 2);

		Product_Discount__c objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.ZP_Product_Id__c = '1';
		objPD.Discount_Type__c = 'premium_tier_discount';
		objPD.Discount_Percent__c = 5.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		upsert objPD UniqueId__c;

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);

		Test.startTest();

		objPD.Discount_Percent__c = 0.00;
		upsert objPD UniqueId__c;

		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         David Schach
	 * @description    Test Product Discounts are deleted on update of ZP Adjustment to update discount to 0
	 */
	@isTest
	private static void testCustomerSelectDiscountDeleteUndelete() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		Opportunity objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id];
		Decimal decInitialAmount = objOpportunityAssert.Amount;

		System.assert([SELECT COUNT() FROM OpportunityLineItem] >= 2);

		Product_Discount__c objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.ZP_Product_Id__c = '1';
		objPD.Discount_Type__c = 'premium_tier_discount';
		objPD.Discount_Percent__c = 5.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		upsert objPD UniqueId__c;

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);

		Test.startTest();

		delete objPD;

		Test.stopTest();

		objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id];
		System.assertEquals(decInitialAmount, objOpportunityAssert.Amount);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);

		Boolean blnHasError = false;
		try {
			undelete [SELECT Id FROM Product_Discount__c WHERE Id = :objPD.Id ALL ROWS];
		} catch (DMLException e) {
			blnHasError = true;
		}
		System.assert(blnHasError);
	}

	/**
	 * @author         David Schach
	 * @description    Test Product Discounts are deleted on update of ZP Adjustment to update discount to 0
	 */
	@isTest
	private static void testResellerDiscountDeleteUndelete() {
		Test.startTest();
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		Opportunity objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id];
		Decimal decInitialAmount = objOpportunityAssert.Amount;

		System.assert([SELECT COUNT() FROM OpportunityLineItem] >= 2);

		Product_Discount__c objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.Discount_Type__c = 'accountant';
		objPD.Discount_Percent__c = 5.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		upsert objPD UniqueId__c;

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);

		delete objPD;

		Test.stopTest();

		objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id];
		System.assertEquals(decInitialAmount, objOpportunityAssert.Amount);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);

		Boolean blnHasError = false;
		try {
			undelete [SELECT Id FROM Product_Discount__c WHERE Id = :objPD.Id ALL ROWS];
		} catch (DMLException e) {
			blnHasError = true;
		}
		System.assert(blnHasError);
	}

	@isTest
	private static void testResellerWithCustomerSelectDiscount() {
		Test.startTest();
		Account objResellerAccount = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];
		System.assertEquals(10.00, objResellerAccount.Discount__c);

		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c, Reward_Eligible__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];
		objAccountAssert.Reward_Eligible__c = true;
		update objAccountAssert;

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);

		Opportunity objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id AND IsClosed = FALSE];

		Product_Discount__c objPD = new Product_Discount__c();
		objPD.Opportunity__c = objOpportunityAssert.Id;
		objPD.ZP_Product_Id__c = '1';
		objPD.Discount_Type__c = 'premium_tier_discount';
		objPD.Discount_Percent__c = 5.00;
		objPD.Date_Start__c = Date.today();
		objPD.Date_End__c = Date.today().addDays(30);
		objPD.UniqueId__c = ProductDiscountHelper.createProductDiscountUniqueId(objPD);
		upsert objPD UniqueId__c;

		List<Product_Discount__c> listProductDiscountAssert1 = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			WHERE Opportunity__c = :objOpportunityAssert.Id
		];
		System.assertEquals(2, listProductDiscountAssert1.size());

		List<OpportunityLineItem> list_OppLineItemsAssert = [SELECT Id, Subtotal, Discount, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :objOpportunityAssert.Id];
		System.assert(!list_OppLineItemsAssert.isEmpty());

		objOpportunityAssert = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :objAccountAssert.Id AND IsClosed = FALSE];

		Decimal decAmount = 0;
		for (OpportunityLineItem objOppLineItem : list_OppLineItemsAssert) {
			decAmount += objOppLineItem.TotalPrice;
			System.assertEquals(15.00, objOppLineItem.Discount);
		}
		System.assertEquals(decAmount, objOpportunityAssert.Amount);

		Test.stopTest();
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test Updates on OLI based on Product discount records created for Ardius Gusto Customer
	 * @Parm        : void
	 * @Return      : void
	 **/
	@istest
	static void testArdiusGustoOpportunityInsert() {
		Account objArdiusGustoCustomer = [
			SELECT Id, Name, ZP_Company_ID__c
			FROM Account
			WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_ID__c = :ARD_CUSTOMER_ZPCOMPANY_ID
			LIMIT 1
		];

		Test.startTest();
		Opportunity objArdiusGustoOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setName('Test ARD Gusto Customer')
			.setAccountId(objArdiusGustoCustomer.Id)
			.setZPCompanyId(ARD_CUSTOMER_ZPCOMPANY_ID)
			.setStage('Raw')
			.setCloseDate(System.today())
			.build();
		objArdiusGustoOpportunity.State_Credit__c = 230.00;
		objArdiusGustoOpportunity.Federal_Credit__c = 160.00;

		insert objArdiusGustoOpportunity;
		Test.stopTest();

		Opportunity objOpportunityAssert = [SELECT Id, Name, State_Credit__c, Federal_Credit__c, RecordTypeId FROM Opportunity WHERE Id = :objArdiusGustoOpportunity.Id LIMIT 1];

		List<OpportunityLineItem> list_OppLineItemAssert = [
			SELECT Id, Discount_Type__c, UnitPrice, Discount, Product_Name__c
			FROM OpportunityLineItem
			WHERE OpportunityId = :objArdiusGustoOpportunity.Id
		];
		System.assertEquals(2, list_OppLineItemAssert.size());
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test Updates on OLI based on Product discount records created for Ardius Non-Gusto Customer
	 * @Parm        : void
	 * @Return      : void
	 **/
	@istest
	static void testArdiusNonGustoOpportunityInsert() {
		Account objArdiusNonGustoCustomer = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_ID__c = NULL LIMIT 1];

		Test.startTest();
		Opportunity objArdiusNonGustoOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setName('Test ARD Non Gusto Customer')
			.setAccountId(objArdiusNonGustoCustomer.Id)
			.setStage('Raw')
			.setCloseDate(System.today())
			.build();
		objArdiusNonGustoOpportunity.State_Credit__c = 230.00;
		objArdiusNonGustoOpportunity.Federal_Credit__c = 160.00;

		insert objArdiusNonGustoOpportunity;
		Test.stopTest();

		Opportunity objOpportunityAssert = [SELECT Id, Name, State_Credit__c, Federal_Credit__c, RecordTypeId FROM Opportunity WHERE Id = :objArdiusNonGustoOpportunity.Id LIMIT 1];

		List<OpportunityLineItem> list_OppLineItemAssert = [
			SELECT Id, Discount_Type__c, UnitPrice, Discount, Product_Name__c
			FROM OpportunityLineItem
			WHERE OpportunityId = :objArdiusNonGustoOpportunity.Id
		];
		System.assertEquals(2, list_OppLineItemAssert.size());
	}

	/**
	 * @author Ajay Krishna P U
	 * @description Test Ardius Discount Calculation logic
	 * The Discount should not be recalculated in case of Ardius Opps
	 */
	@isTest
	static void testArdiusOpportunityDiscountCalculation() {
		Ardius_Configuration__c objArdiusConfig = Ardius_Configuration__c.getInstance();
		objArdiusConfig.Block_Discounts_After_Customer_Approval__c = true;
		upsert objArdiusConfig;
		OpportunityLineItem objOppLineItem = new OpportunityLineItem();
		Account objArdiusGustoCustomer = [
			SELECT Id, Name, ZP_Company_ID__c
			FROM Account
			WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID AND ZP_Company_ID__c = :ARD_CUSTOMER_ZPCOMPANY_ID
			LIMIT 1
		];

		Test.startTest();
		Opportunity objArdiusGustoOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setName('Test ARD Gusto Customer')
			.setAccountId(objArdiusGustoCustomer.Id)
			.setZPCompanyId(ARD_CUSTOMER_ZPCOMPANY_ID)
			.setStage('Raw')
			.setCloseDate(System.today())
			.build();
		objArdiusGustoOpportunity.State_Credit__c = 230.00;
		objArdiusGustoOpportunity.Federal_Credit__c = 160.00;

		insert objArdiusGustoOpportunity;
		

		List<OpportunityLineItem> list_OppLineItems = [SELECT Id, Discount FROM OpportunityLineItem WHERE OpportunityId = :objArdiusGustoOpportunity.Id];
		System.assert(list_OppLineItems.size() > 0, 'Auto Add Product functionality failed');
		objOppLineItem = list_OppLineItems[0];

		//Update Opp Line item and validate Discount
		objOppLineItem.Discount = 20;
		objOppLineItem.Discount_Description__c = 'Order Form Discount';
		update objOppLineItem;
		objOppLineItem = [SELECT Id, Discount, Product2Id, UnitPrice, Quantity, OpportunityId FROM OpportunityLineItem WHERE Id = :objOppLineItem.Id];
		System.assert(objOppLineItem.Discount == 20, 'Failed, Ardius Opp Line item Discount resetted - Update');
		Test.stopTest();

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setDescription('Test Ardius')
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setOppId(objArdiusGustoOpportunity.Id)
			.build();

		TicketTriggerHelper.skipTrigger = true;
		insert objTicket;

		objOppLineItem.Discount = 25;
		update objOppLineItem;
		objOppLineItem = [SELECT Id, Discount, Product2Id, UnitPrice, Quantity, OpportunityId FROM OpportunityLineItem WHERE Id = :objOppLineItem.Id];
		System.assert(objOppLineItem.Discount == 25, 'Failed, Ardius Opp Line item Discount not updated');

		objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		update objTicket;

		Boolean blnHasError = false;
		try {
			objOppLineItem.Discount = 30;
			update objOppLineItem;
		} catch (Exception objEx) {
			blnHasError = true;
		}
		System.assertEquals(blnHasError, true, 'Failed, Block discount after customer approval failed');
	}

	/**
	 * @author Praveen Sethu
	 * @description Test deleting Growth/Expansion Line Item - At least one line item should be present
	 */
	@isTest
    static void testDeletingGrowthExpansionLineItem() {
        // Data Setup
		// Create a Medical Policy
		Product2 objGustoHRProd = new Product2(Name = 'GustoHR Pro', Family = 'Medical', ProductCode = 'MED', IsActive = true);
		insert objGustoHRProd;

		PricebookEntry objStandardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = objGustoHRProd.Id, UnitPrice = 10, IsActive = true);
		insert objStandardPrice;

		// Create a new Test Pricebook
		Pricebook2 objPricebook = new Pricebook2(Name = 'Sales Product Catalog', IsActive = true);
		insert objPricebook;

		PricebookEntry objCustomPrice = new PricebookEntry(Pricebook2Id = objPricebook.Id, Product2Id = objGustoHRProd.Id, UnitPrice = 10, IsActive = true);
		insert objCustomPrice;
        
        AccountTriggerHelper.skipTrigger = true;
        OpportunityTriggerHelper.skipTrigger = true;
        // Payload to create company opportunity - Insert placeholder to replace account Id and opportunity record type Id
		String strJSONPayload = '{ "sObjectType": "Opportunity", "AccountId": "<<ACCOUNT_ID>>", "StageName": "New", "RecordTypeId": "<<RECORDTYPE_ID>>", "Name": "Test Growth", "NumberOfEmployees__c": 10, "CloseDate": "2024-12-17" }';
		String strTodayDate = String.valueOf(Date.today().addDays(1));
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.setTier('simple')
			.setSetUpSteps(20.0)
            .setNumberOfActiveEEs(10)
			.build();

		insert objCompanyAccount;

		// Replace placeholders with actual values
		Id idRecordTypeId = OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID;
		strJSONPayload = strJSONPayload.replaceAll('<<ACCOUNT_ID>>', objCompanyAccount.Id);
		strJSONPayload = strJSONPayload.replaceAll('<<RECORDTYPE_ID>>', idRecordTypeId);
        strJSONPayload = strJSONPayload.replaceAll('<<CLOSEDATE>>', strTodayDate);

		// Create Growth/Expansion opportunity
		RecordCreateController.ResponseWrapper objWrapper = RecordCreateController.createRecord(strJSONPayload, true);
        
        Opportunity objOppty = [SELECT Id, (SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE AccountId = :objCompanyAccount.Id AND RecordTypeId = :idRecordTypeId LIMIT 1];
        
        Test.startTest();
        Boolean blnException = false;
        try {
            delete objOppty.OpportunityLineItems;
        } catch(Exception objEx) {
            blnException = true;
        }
        Test.stopTest();
        
        System.assertEquals(true, blnException, 'Exception not thrown when deleting line items');
    }
}