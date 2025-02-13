/**
 * Test Class for ZPAdjustment-initiated Product Discount updates
 * @author Debasmita Rawooth
 * @author David Schach
 * @since Jan 2022
 * @group Product Discount
 * @see ZPAdjustmentTriggerHandler
 */
@isTest
public class ZPAdjustmentTriggerHandlerTest {
	private static final String RESELLER_ZPFIRM_ID = '9999';
	private static final String CUSTOMER_ZPCOMPANY_ID = '8888';

	/**
	 * @description Set up data - Product, Pricebook
	 * @author David Schach
	 */
	@testSetup
	static void setup() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		List<Pricebook2> list_PbsToInsert = new List<Pricebook2>();
		PriceBook2 objPriceBookOne = new PriceBook2(Name = objTierConfig.New_Price_1__c, IsActive = true, Product_Tier__c = objTierConfig.New_Tier_1__c);
		list_PbsToInsert.add(objPriceBookOne);

		PriceBook2 objPriceBookTwo = new PriceBook2(Name = objTierConfig.New_Price_3__c, IsActive = true, Product_Tier__c = objTierConfig.New_Tier_3__c);
		list_PbsToInsert.add(objPriceBookTwo);
		insert list_PbsToInsert;

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
		for (Product2 p : list_Products) {
			p.ExternalId = '1';
		}
		insert list_Products;

		List<PricebookEntry> list_Entries = new List<PricebookEntry>();
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, objPriceBookOne.Id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, objPriceBookOne.Id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, objPriceBookTwo.Id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, objPriceBookTwo.Id, false));
		insert list_Entries;

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account 1').setZPFirmId(RESELLER_ZPFIRM_ID).build();
		objResellerAccount.Customers_Reward_Eligible__c = 4;
		objResellerAccount.AM_Tier__c = 'Bronze';
		objResellerAccount.Discount__c = 10;

		TriggerHandler.bypass('AccountTriggerHandler');
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Account objCompAccount = new TestDataFactory.AccountBuilder()
			.setNumberOfActiveEEs(5)
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Gustomer1')
			.setZPCompanyId(CUSTOMER_ZPCOMPANY_ID)
			.build();
		objCompAccount.Sold_By__c = objResellerAccount.Id;
		objCompAccount.Number_of_Active_Employees__c = 5;
		insert objCompAccount;

		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = new TestDataFactory.ZPPayerPricingPlanBuilder().setPayerId(objCompAccount.ZP_Company_ID__c).setId('56789').setProductId('1').build();
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objPayerPricingPlan;
		TriggerHandler.clearbypass('AccountTriggerHandler');

		Opportunity objpayrollOpp = new TestDataFactory.OpportunityBuilder()
			.setName('Gustomer - Payroll')
			.setCloseDate(Date.today().addDays(19))
			.setStage(null)
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setSoldBy(objResellerAccount.Id)
			.setAccountId(objCompAccount.Id)
			.setZPCompanyId(CUSTOMER_ZPCOMPANY_ID)
			.build();
		objpayrollOpp.NumberOfEmployees__c = 5;
		insert objpayrollOpp;
	}

	@isTest
	static void testInsertOneZPAdjustmentProductType() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		Opportunity objOpportunityAssert = [
			SELECT Id, Name, ZP_Company_ID__c, Amount, IsClosed, RecordType.Name, Account.ZP_Company_Id__c, Sold_By__r.Name, TotalOpportunityQuantity
			FROM Opportunity
			WHERE AccountId = :objAccountAssert.Id AND IsClosed = FALSE
		];

		System.assert([SELECT COUNT() FROM OpportunityLineItem] >= 2);

		System.assertEquals(objOpportunityAssert.ZP_Company_ID__c, objAccountAssert.ZP_Company_ID__c);

		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Test.startTest();

		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		Test.stopTest();

		ZP_Adjustments__c objZPAdjustmentAssert = [SELECT Id, Id__c, Adjustment_Type__c, Percentage__c FROM ZP_Adjustments__c];
		System.assertEquals(5.00, objZPAdjustmentAssert.Percentage__c);

		objOpportunityAssert = [
			SELECT Id, Name, ZP_Company_ID__c, Amount, IsClosed, RecordType.Name, Account.ZP_Company_Id__c, Sold_By__r.Name, TotalOpportunityQuantity
			FROM Opportunity
			WHERE AccountId = :objAccountAssert.Id AND IsClosed = FALSE
		];

		List<Product_Discount__c> list_ProductDiscounts = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			WHERE Opportunity__c = :objOpportunityAssert.Id
		];
		System.assertEquals(1, list_ProductDiscounts.size());
		System.assertEquals(objZPAdjustmentAssert.Id__c, list_ProductDiscounts[0].ZP_Adjustment_Id__c);
		System.assertEquals(objZPAdjustmentAssert.Adjustment_Type__c, list_ProductDiscounts[0].Discount_Type__c);
		System.assertEquals(objZPAdjustmentAssert.Percentage__c, list_ProductDiscounts[0].Discount_Percent__c);
	}

	/**
	 * @description Insert a select tier discount without a Product Id
	 * @author David Schach
	 */
	@isTest
	static void testInsertBadZPAdjustmentProductType() {
		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Test.startTest();
		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId(null)
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		Test.stopTest();

		ZP_Adjustments__c objZPAdjustmentAssert = [SELECT Id, Id__c, Adjustment_Type__c, Percentage__c FROM ZP_Adjustments__c];
		System.assertEquals(5.00, objZPAdjustmentAssert.Percentage__c);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         Debasmita Rawooth
	 * @author         David Schach
	 * @description    Test Product Discount is updated on ZP Adjustment update
	 */
	@isTest
	static void testProductDiscountInsertTwo() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Test.startTest();

		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		Test.stopTest();

		ZP_Adjustments__c objZPAdjustmentAssert = [SELECT Id, Id__c, Adjustment_Type__c, Percentage__c FROM ZP_Adjustments__c];
		System.assertEquals(5.00, objZPAdjustmentAssert.Percentage__c);

		Opportunity objOpportunityAssert = [
			SELECT Id, Name, ZP_Company_ID__c, Amount, IsClosed, RecordType.Name, Account.ZP_Company_Id__c, Sold_By__r.Name, TotalOpportunityQuantity
			FROM Opportunity
			WHERE AccountId = :objAccountAssert.Id AND IsClosed = FALSE
		];

		List<Product_Discount__c> list_ProductDiscounts = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			WHERE Opportunity__c = :objOpportunityAssert.Id
		];

		System.assertEquals(1, list_ProductDiscounts.size());
		System.assertEquals(objZPAdjustmentAssert.Id__c, list_ProductDiscounts[0].ZP_Adjustment_Id__c);
		System.assertEquals(objZPAdjustmentAssert.Adjustment_Type__c, list_ProductDiscounts[0].Discount_Type__c);
		System.assertEquals(objZPAdjustmentAssert.Percentage__c, list_ProductDiscounts[0].Discount_Percent__c);

		ZP_Adjustments__c objZPAdjustments2 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22222')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments2;

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         David Schach
	 * @description    Test Product Discount with negative percent
	 */
	@isTest
	static void testProductDiscountInsertTestNegativePercent() {
		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Test.startTest();

		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(-5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		Test.stopTest();
		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         Debasmita Rawooth
	 * @author         David Schach
	 * @description    Test Product Discount is created on ZP Adjustment creation
	 */
	@isTest
	static void testProductDiscountInsertTestInvalidType() {
		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Test.startTest();

		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('Discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today().addDays(-2))
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		Test.stopTest();

		ZP_Adjustments__c objZPAdjustmentAssert = [SELECT Id, Id__c, Adjustment_Type__c, Percentage__c FROM ZP_Adjustments__c];
		System.assertEquals(5.00, objZPAdjustmentAssert.Percentage__c);
		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	@isTest
	static void testZPAdjustmentDataMigration() {
		Account objResellerAccount = [SELECT Id, Name, Customers_Reward_Eligible__c, Discount__c FROM Account WHERE ZP_Firm_ID__c = :RESELLER_ZPFIRM_ID LIMIT 1];
		System.assertEquals(10.00, objResellerAccount.Discount__c);

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);

		Account objCustomerAccount = [SELECT Id, Name, ZP_Company_ID__c, Reward_Eligible__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];
		System.assert(!objCustomerAccount.Reward_Eligible__c);

		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Opportunity objPayrollOpp1 = new TestDataFactory.OpportunityBuilder()
			.setName('Gustomer - Payroll 1')
			.setCloseDate(Date.today().addDays(19))
			.setStage(null)
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setSoldBy(objResellerAccount.Id)
			.setAccountId(objCustomerAccount.Id)
			.setZPCompanyId(CUSTOMER_ZPCOMPANY_ID)
			.build();
		objPayrollOpp1.NumberOfEmployees__c = 5;

		Opportunity objPayrollOpp2 = new TestDataFactory.OpportunityBuilder()
			.setName('Gustomer - Payroll 2')
			.setCloseDate(Date.today().addDays(19))
			.setStage(null)
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setSoldBy(objResellerAccount.Id)
			.setAccountId(objCustomerAccount.Id)
			.setZPCompanyId(CUSTOMER_ZPCOMPANY_ID)
			.build();
		objPayrollOpp2.NumberOfEmployees__c = 5;

		List<Opportunity> list_listOpportunities = new List<Opportunity>{ objPayrollOpp1, objPayrollOpp2 };

		Test.startTest();

		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		insert list_listOpportunities;

		update objZPAdjustments;
		Test.stopTest();

		ZP_Adjustments__c objZPAdjustmentAssert = [SELECT Id, Id__c, Adjustment_Type__c, Percentage__c FROM ZP_Adjustments__c];
		System.assertEquals(5.00, objZPAdjustmentAssert.Percentage__c);

		List<Opportunity> list_OpportunityAssert = [
			SELECT Id, Name, ZP_Company_ID__c, Amount, IsClosed, RecordType.Name, Account.ZP_Company_Id__c, Sold_By__r.Name, TotalOpportunityQuantity
			FROM Opportunity
			WHERE AccountId = :objCustomerAccount.Id AND IsClosed = FALSE
		];
		System.assertEquals(3, list_OpportunityAssert.size());

		objCustomerAccount.Reward_Eligible__c = true;
		update objCustomerAccount;
		System.assertEquals(6, [SELECT COUNT() FROM Product_Discount__c]);

		List<Product_Discount__c> list_ProductDiscountAssert1 = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
		];

		for (Product_Discount__c objPD : list_ProductDiscountAssert1) {
			if (objPD.Discount_Type__c == 'accountant') {
				System.assertEquals(10, objPD.Discount_Percent__c);
			} else if (objPD.Discount_Type__c == 'premium_tier_discount') {
				System.assertEquals(5, objPD.Discount_Percent__c);
				System.assertEquals(objZPAdjustmentAssert.Id__c, objPD.ZP_Adjustment_Id__c);
				System.assertEquals(objZPAdjustmentAssert.Adjustment_Type__c, objPD.Discount_Type__c);
				System.assertEquals(objZPAdjustmentAssert.Percentage__c, objPD.Discount_Percent__c);
			}
		}
		System.assertEquals(6, list_ProductDiscountAssert1.size());
	}

	/**
	 * @author         Debasmita Rawooth
	 * @author         David Schach
	 * @description    Test Product Discount is updated on simple update of ZP Adjustment
	 */
	@isTest
	static void testZPAdjustmentUpdate() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Test.startTest();
		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		ZP_Adjustments__c objZPAdjustmentAssert = [SELECT Id, Id__c, Adjustment_Type__c, Percentage__c FROM ZP_Adjustments__c];
		System.assertEquals(5.00, objZPAdjustmentAssert.Percentage__c);

		List<Product_Discount__c> list_ProductDiscounts = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			WHERE Opportunity__r.AccountId = :objAccountAssert.Id AND Opportunity__r.IsClosed = FALSE
		];

		System.assertEquals(1, list_ProductDiscounts.size());
		System.assertEquals(objZPAdjustmentAssert.Id__c, list_ProductDiscounts[0].ZP_Adjustment_Id__c);
		System.assertEquals(objZPAdjustmentAssert.Adjustment_Type__c, list_ProductDiscounts[0].Discount_Type__c);
		System.assertEquals(objZPAdjustmentAssert.Percentage__c, list_ProductDiscounts[0].Discount_Percent__c);

		objZPAdjustments.Percentage__c = 10;
		update objZPAdjustments;

		Test.stopTest();

		Opportunity objOpportunityAssert = [
			SELECT Id, Name, ZP_Company_ID__c, Amount, IsClosed, RecordType.Name, Account.ZP_Company_Id__c, Sold_By__r.Name, TotalOpportunityQuantity
			FROM Opportunity
			WHERE AccountId = :objAccountAssert.Id
		];

		List<Product_Discount__c> list_ProductDiscountsAssert2 = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			WHERE Opportunity__c = :objOpportunityAssert.Id
		];

		System.assertEquals(1, list_ProductDiscountsAssert2.size());
		System.assertEquals(10, list_ProductDiscountsAssert2[0].Discount_Percent__c);
	}

	/**
	 * @author         Debasmita Rawooth
	 * @description    Test Product Discounts are deleted on update of ZP Adjustment to blank out adjustment type
	 */
	@isTest
	static void testProductDiscountDeleteAtNoZPAdjustmentDiscountType() {
		Account objAccountAssert = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Test.startTest();

		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		ZP_Adjustments__c objZPAdjustmentAssert = [SELECT Id, Id__c, Adjustment_Type__c, Percentage__c, Amount__c FROM ZP_Adjustments__c];
		System.assertEquals(5.00, objZPAdjustmentAssert.Percentage__c);

		List<Product_Discount__c> list_ProductDiscounts = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			WHERE Opportunity__r.AccountId = :objAccountAssert.Id
		];
		System.assertEquals(1, list_ProductDiscounts.size());
		System.assertEquals(objZPAdjustmentAssert.Id__c, list_ProductDiscounts[0].ZP_Adjustment_Id__c);
		System.assertEquals(objZPAdjustmentAssert.Adjustment_Type__c, list_ProductDiscounts[0].Discount_Type__c);
		System.assertEquals(objZPAdjustmentAssert.Percentage__c, list_ProductDiscounts[0].Discount_Percent__c);

		//list_ProductDiscounts[0].Discount_Percent = 0;
		objZPAdjustments.Adjustment_Type__c = null;
		update objZPAdjustments;

		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         David Schach
	 * @description    Test Product Discount is NOT updated on new ZP Adjustment for same Opp with older ID
	 */
	@isTest
	static void testZPAdjustmentUpdateOldRecord() {
		TriggerHandler.bypass('ProductDiscountTriggerHandler');
		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		Test.startTest();
		ZP_Adjustments__c objZPAdjustments = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22221')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments;

		// inserting an "old" adjustment record in the same batch should not change the product discount percent
		ZP_Adjustments__c objZPAdjustments2 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22220')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments2;

		Test.stopTest();

		System.assertEquals(2, [SELECT COUNT() FROM ZP_Adjustments__c]);

		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);
		Product_Discount__c objPDAssert = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			LIMIT 1
		];
		System.assertEquals(5, objPDAssert.Discount_Percent__c);
	}

	/**
	 * @author         David Schach
	 * @description    Test Product Discount is set with the newest ZP Adjustment when two are in the same batch
	 */
	@isTest
	static void testZPAdjustmentMultipleRecordsSameBatch() {
		TriggerHandler.bypass('ProductDiscountTriggerHandler');
		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		List<ZP_Adjustments__c> list_ZPAdjustmentsToInsert = new List<ZP_Adjustments__c>();

		// inserting an "old" adjustment record should not change the product discount percent (in the same batch)
		ZP_Adjustments__c objZPAdjustments2 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22222')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		list_ZPAdjustmentsToInsert.add(objZPAdjustments2);

		ZP_Adjustments__c objZPAdjustments3 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22223')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		list_ZPAdjustmentsToInsert.add(objZPAdjustments3);
		ZP_Adjustments__c objZPAdjustments9 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22229')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		list_ZPAdjustmentsToInsert.add(objZPAdjustments9);
		ZP_Adjustments__c objZPAdjustments4 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22224')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		list_ZPAdjustmentsToInsert.add(objZPAdjustments4);
		ZP_Adjustments__c objZPAdjustments5 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22225')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		list_ZPAdjustmentsToInsert.add(objZPAdjustments5);

		Test.startTest();
		insert list_ZPAdjustmentsToInsert;
		Test.stopTest();

		Product_Discount__c objPDAssert = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			LIMIT 1
		];
		System.assertEquals(5, objPDAssert.Discount_Percent__c);
		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         David Schach
	 * @description    Test Product Discount is set with the newest ZP Adjustment when two are in the same batch
	 */
	@isTest
	static void testZPAdjustmentExistingPlusMultipleRecordsSameBatch() {
		TriggerHandler.bypass('ProductDiscountTriggerHandler');
		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = [SELECT Id, Id__c, Payer_Id__c FROM ZP_Payer_Pricing_Plan__c];

		// Get org default tier config settings and assert select tier discount is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, 'premium_tier_discount');

		ZP_Adjustments__c objZPAdjustments8 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22228')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		insert objZPAdjustments8;

		List<ZP_Adjustments__c> list_ZPAdjustmentsToInsert = new List<ZP_Adjustments__c>();

		// inserting an "old" adjustment record should not change the product discount percent (in the same batch)

		ZP_Adjustments__c objZPAdjustments3 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22223')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		list_ZPAdjustmentsToInsert.add(objZPAdjustments3);
		ZP_Adjustments__c objZPAdjustments9 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22229')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(5.00)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		list_ZPAdjustmentsToInsert.add(objZPAdjustments9);
		ZP_Adjustments__c objZPAdjustments4 = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22224')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();
		list_ZPAdjustmentsToInsert.add(objZPAdjustments4);

		Test.startTest();
		insert list_ZPAdjustmentsToInsert;
		Test.stopTest();

		Product_Discount__c objPDAssert = [
			SELECT Id, Name, Opportunity__c, Opportunity__r.Account.ZP_Company_ID__c, ZP_Adjustment_Id__c, Discount_Type__c, Discount_Percent__c, Discount_Amount__c
			FROM Product_Discount__c
			LIMIT 1
		];
		System.assertEquals(5, objPDAssert.Discount_Percent__c);
		System.assertEquals(1, [SELECT COUNT() FROM Product_Discount__c]);
	}

	/**
	 * @author         Praveen Sethu
	 * @description    Test if Premium Tier Discount is updated on Company Account
	 */
	@isTest
	static void testUpdatingPremiumTierDiscount() {
		Account objCompAccount = [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c = :CUSTOMER_ZPCOMPANY_ID LIMIT 1];

		// set up data - insert payer pricing plan record
		ZP_Payer_Pricing_Plan__c objPayerPricingPlan = new TestDataFactory.ZPPayerPricingPlanBuilder().setPayerId(objCompAccount.ZP_Company_ID__c).setId('56789').setProductId('1').build();
		insert objPayerPricingPlan;

		// insert ZP Adjustment record
		ZP_Adjustments__c objZPAdjustment = new TestDataFactory.ZPAdjustmentBuilder()
			.setId('22224')
			.setPayerPricingPlanId(objPayerPricingPlan.Id__c)
			.setProductId('1')
			.setAdjustmentType('premium_tier_discount')
			.setPercentage(10)
			.setPeriodStart(System.today())
			.setPeriodEnd(System.today().addDays(30))
			.build();

		Test.startTest();
		insert objZPAdjustment;
		Test.stopTest();

		// Assert if Premium Tier discount was updated
		Account objAccountAssert = [SELECT Id, Premium_Tier_Discount__c FROM Account WHERE Id = :objCompAccount.Id];
		System.assertEquals(10, objAccountAssert.Premium_Tier_Discount__c, 'Premium tier discount was not updated');
	}
}