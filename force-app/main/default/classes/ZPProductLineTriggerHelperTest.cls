/**
 * @name         ZPProductLineTriggerHelperTest
 * @author       Anurag Gautam
 * @date         06/20/2023
 * @description  unit testing for ZP product line scenarios.
 * @see ZPProductLineTriggerHelperTest
 * @see ZPProductLineTriggerHelper
 **/
@isTest
public with sharing class ZPProductLineTriggerHelperTest {
	/**
	 * @author      Anurag Gautam
	 * @description Sets common data for all the test methods
	 **/
	@testSetup
	static void testData() {
		// creating company account
		Account objCompany = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test ZP Company 2').setZPCompanyId('765665766').build();

		AccountTriggerHelper.skipTrigger = true;
		insert objCompany;
		AccountTriggerHelper.skipTrigger = false;

		// creating ZP Companies to check validation for dead companies.
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('765665766')
			.setName('Test ZP Company 2')
			.setProcessingState(IntegrationUtils.MANUAL_ENQUEUE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.setJoinedDate(System.today())
			.build();

		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('765665768')
			.setName('Test ZP Company 3')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.setPartnerProgramCompanyDataId('12131323')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setManagingAccountingFirmId('Reseller Account 1')
			.build();
		List<ZP_Company__c> list_Companies = new List<ZP_Company__c>{ objZPCompany, objZPCompany1 };
		insert list_Companies;

		// Start setting up data and create pricebook and pricebook entries
		// Create a new pricebook
		List<Pricebook2> list_PaymentPlans = new List<Pricebook2>();
		list_PaymentPlans.add(new TestDataFactory.PriceBookBuilder().setName('$80 Base, $12: 1+').setActive().setProductTier('Plus').setPricingPlanId('10').setProductLineId('1').build());

		list_PaymentPlans.add(new TestDataFactory.PriceBookBuilder().setName('$40 Base, $6: 1+').setActive().setProductTier('Simple').setPricingPlanId('11').setProductLineId('2').build());

		list_PaymentPlans.add(new TestDataFactory.PriceBookBuilder().setName('$39 Base, $6: 1+').setActive().setProductTier('Core').setPricingPlanId('12').setProductLineId('3').build());

		list_PaymentPlans.add(new TestDataFactory.PriceBookBuilder().setName('test product 1').setActive().build());

		list_PaymentPlans.add(new TestDataFactory.PriceBookBuilder().setName('test product 2').setActive().build());
		insert list_PaymentPlans;

		// Create new products
		List<Product2> list_Products = new List<Product2>();
		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('Priority Support and HR Services - Contractor')
				.setFamily('Company')
				.setProductCategory('Priority Support and HR Services')
				.setPricingPlanId('201')
				.setProductLineId('101')
				.build()
		);

		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('International Contractor Add-On')
				.setFamily('Employee')
				.setProductCategory('International Contractor Service')
				.setPricingPlanId('200')
				.setProductLineId('100')
				.build()
		);

		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('Premium')
				.setFamily('Company')
				.setExternalId('test product 1')
				.build()
		);

		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('Wholesale')
				.setFamily('Employee')
				.setExternalId('test product 2')
				.build()
		);

		insert list_Products;

		// Create pricebook entries
		List<PricebookEntry> list_Entries = new List<PricebookEntry>();

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[2].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[3].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[0].Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[0].Id).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[1].Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[1].Id).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[2].Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[2].Id).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[2].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[3].Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[3].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[4].Id).setIsActive(true).build());

		insert list_Entries;
	}

	/**
	 * @author       Anurag Gautam
	 * @description  company id validation for ZP Product Line .
	 **/
	@isTest
	static void companyIdValidationCheck() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('')
			.setCompanyEnrollmentID('22222')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('12')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setProductName('test product 1')
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_COMPANY_ID_DOES_NOT_EXIST, 'Company Id is not present.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  type validation for ZP Product Line .
	 **/
	@isTest
	static void typeValidationCheck() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setCompanyEnrollmentID('2222')
			.setType('')
			.setParentID('33333')
			.setPricingPlanID('12')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setProductName('test product 2')
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_TYPE_DOES_NOT_EXIST, 'Type is not present.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Parent Id validation for ZP Product Line .
	 **/
	@isTest
	static void parentIdValidationCheck() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setCompanyEnrollmentID('2222')
			.setType('add_on')
			.setParentID('')
			.setPricingPlanID('12')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_PARENT_ID_DOES_NOT_EXIST, 'Parent Id is not present.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Pricing Plan Id validation for ZP Product Line .
	 **/
	@isTest
	static void pricingPlanValidationCheck() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setCompanyEnrollmentID('2222')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		//System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_PRICING_PLAN_ID_DOES_NOT_EXIST, 'Pricing plan Id is not present.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Product Line Id validation for ZP Product Line .
	 **/
	@isTest
	static void productLineValidationCheck() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setCompanyEnrollmentID('2222')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('12')
			.setProductLineID('')
			.setStatus('active')
			.setStartDate(System.now())
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		//System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_PRODUCT_LINE_ID_DOES_NOT_EXIST, 'Product line Id is not present.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Status validation for ZP Product Line .
	 **/
	@isTest
	static void statusValidationCheck() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setCompanyEnrollmentID('2222')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('12')
			.setProductLineID('1')
			.setStatus('')
			.setStartDate(System.now())
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_STATUS_DOES_NOT_EXIST, 'Status is not present.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Start Date validation for ZP Product Line .
	 **/
	@isTest
	static void startDateValidationCheck() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setCompanyEnrollmentID('2222')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('12')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(null)
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_START_DATE_DOES_NOT_EXIST, 'Start date is not present.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Start Date validation for ZP Product Line .
	 **/
	@isTest
	static void startDateInFuture() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setCompanyEnrollmentID('2222')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('12')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now().addDays(4))
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_FUTURE_START_DATE, 'Start date is in future.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Account validation for ZP Product Line .
	 **/
	@isTest
	static void accountValidation() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setCompanyEnrollmentID('2222')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('12')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyBaseId('44444')
			.build();

		insert objZPProductLine;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_COMPANY_ID_DOES_NOT_EXIST, 'Account doesn not exist');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Product and Pricing validation for ZP Product Line .
	 **/
	@isTest
	static void productAndPricingValidation() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('12')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyBaseId('44444')
			.build();

		insert objZPProductLine;
		objZPProductLine.Company_ID__c = '765665766';
		update objZPProductLine;

		ZP_Product_Line__c objZPProductLine1 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('tier_base')
			.setParentID('33333')
			.setPricingPlanID('13')
			.setProductLineID('2')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyBaseId('44445')
			.setProductName('test product 1')
			.build();

		insert objZPProductLine1;
		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.ERR_MSG_PRODUCT_ERROR, 'Product information does not matched.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Unit test to add active base product
	 **/
	@isTest
	static void processActiveBaseZPProductLine() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('11')
			.setProductLineID('2')
			.setStatus('active')
			.setStartDate(System.now().addDays(-1))
			.setCompanyBaseId('44444')
			.setProductName('test product 1')
			.build();

		insert objZPProductLine;
		objZPProductLine.Company_ID__c = '765665766';
		update objZPProductLine;

		ZP_Product_Line__c objZPProductLine1 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('10')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyBaseId('44445')
			.setProductName('test product 2')
			.build();

		insert objZPProductLine1;
		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine1.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.SUCCESS_MESSAGE, 'Tier has been changed.');

		Account objAccount = [SELECT Id, Tier__c FROM Account WHERE ZP_Company_ID__c = '765665766' LIMIT 1];
		System.assertEquals(objAccount.Tier__c, 'Wholesale', 'Tier is not Wholesale.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Unit test to add active add-on product
	 **/
	@isTest
	static void processActiveAddOnZPProductLine() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('11')
			.setProductLineID('2')
			.setStatus('active')
			.setStartDate(System.now().addDays(-1))
			.setCompanyBaseId('44444')
			.setProductName('test product 1')
			.build();

		insert objZPProductLine;
		objZPProductLine.Company_ID__c = '765665766';
		update objZPProductLine;

		ZP_Product_Line__c objZPProductLine1 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('10')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyBaseId('44445')
			.setProductName('test product 2')
			.build();

		insert objZPProductLine1;

		ZP_Product_Line__c objZPProductLine2 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('add_on')
			.setParentID('44445')
			.setPricingPlanID('201')
			.setProductLineID('101')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyEnrollmentID('892828')
			.build();

		insert objZPProductLine2;

		ZP_Product_Line__c objZPProductLine3 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('add_on')
			.setParentID('44445')
			.setPricingPlanID('200')
			.setProductLineID('100')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyEnrollmentID('892828')
			.build();

		insert objZPProductLine3;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine1.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.SUCCESS_MESSAGE, 'Tier has been changed.');

		Account objAccount = [SELECT Id, Tier__c, Additional_Services__c FROM Account WHERE ZP_Company_ID__c = '765665766' LIMIT 1];
		System.assertEquals(objAccount.Tier__c, 'Wholesale', 'Tier is not Wholesale.');
		System.assertEquals(objAccount.Additional_Services__c, 'International Contractor Service;Priority Support and HR Services', 'Add ons are added');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Unit test to add inactive add-on product
	 **/
	@isTest
	static void processInActiveAddOnZPProductLine() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('11')
			.setProductLineID('2')
			.setStatus('active')
			.setStartDate(System.now().addDays(-1))
			.setCompanyBaseId('44444')
			.build();

		insert objZPProductLine;
		objZPProductLine.Company_ID__c = '765665766';
		update objZPProductLine;

		ZP_Product_Line__c objZPProductLine1 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('10')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyBaseId('44445')
			.build();

		insert objZPProductLine1;

		ZP_Product_Line__c objZPProductLine2 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('add_on')
			.setParentID('44445')
			.setPricingPlanID('201')
			.setProductLineID('101')
			.setStatus('inactive')
			.setStartDate(System.now())
			.setCompanyEnrollmentID('892828')
			.build();

		insert objZPProductLine2;

		ZP_Product_Line__c objZPProductLine3 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('add_on')
			.setParentID('44445')
			.setPricingPlanID('201')
			.setProductLineID('101')
			.setStatus('inactive')
			.setStartDate(System.now())
			.setCompanyEnrollmentID('892828')
			.build();

		insert objZPProductLine3;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine1.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.SUCCESS_MESSAGE, 'Tier has been changed.');

		Account objAccount = [SELECT Id, Tier__c, Additional_Services__c FROM Account WHERE ZP_Company_ID__c = '765665766' LIMIT 1];
		System.assertEquals(objAccount.Tier__c, 'Plus', 'Tier is plus.');
		System.assertEquals(objAccount.Additional_Services__c, null, 'Add ons are not added');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Unit test to add active base and inactive add-on product
	 **/
	@isTest
	static void activeBaseAndInactiveAddOnTest() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('11')
			.setProductLineID('2')
			.setStatus('active')
			.setStartDate(System.now().addDays(-1))
			.setCompanyBaseId('44444')
			.build();

		insert objZPProductLine;
		objZPProductLine.Company_ID__c = '765665766';
		update objZPProductLine;

		ZP_Product_Line__c objZPProductLine1 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('10')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyBaseId('44445')
			.build();

		insert objZPProductLine1;

		ZP_Product_Line__c objZPProductLine2 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('add_on')
			.setParentID('44445')
			.setPricingPlanID('201')
			.setProductLineID('101')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyEnrollmentID('892828')
			.build();

		insert objZPProductLine2;

		ZP_Product_Line__c objZPProductLine3 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('add_on')
			.setParentID('44445')
			.setPricingPlanID('200')
			.setProductLineID('100')
			.setStatus('inactive')
			.setStartDate(System.now())
			.setCompanyEnrollmentID('892828')
			.build();

		insert objZPProductLine3;

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine1.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.SUCCESS_MESSAGE, 'Tier has been changed.');

		Account objAccount = [SELECT Id, Tier__c, Additional_Services__c FROM Account WHERE ZP_Company_ID__c = '765665766' LIMIT 1];
		System.assertEquals(objAccount.Tier__c, 'Plus', 'Tier is plus.');
		System.assertEquals(objAccount.Additional_Services__c, 'Priority Support and HR Services', 'Only active Add ons is added');

		objZPProductLine3.Status__c = 'active';
		update objZPProductLine3;

		Account objAccount1 = [SELECT Id, Tier__c, Additional_Services__c FROM Account WHERE ZP_Company_ID__c = '765665766' LIMIT 1];
		System.assertEquals(objAccount1.Additional_Services__c, 'International Contractor Service;Priority Support and HR Services', 'both active Add ons are added');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  Unit test to add active base product
	 **/
	@isTest
	static void processCheckzWithExternalId() {
		Test.startTest();
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setType('tier_base')
			.setParentID('')
			.setStatus('active')
			.setStartDate(System.now().addDays(-1))
			.setCompanyBaseId('44444')
			.setProductName('test product 1')
			.build();

		insert objZPProductLine;
		objZPProductLine.Company_ID__c = '765665766';
		update objZPProductLine;

		ZP_Product_Line__c objZPProductLine1 = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('10')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now())
			.setCompanyBaseId('44445')
			.setProductName('test product 2')
			.build();

		insert objZPProductLine1;
		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssert = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine1.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssert.Message__c, ZPProductLineUtil.SUCCESS_MESSAGE, 'Tier has been changed.');

		Account objAccount = [SELECT Id, Tier__c FROM Account WHERE ZP_Company_ID__c = '765665766' LIMIT 1];
		Set<String> set_CompanyIds = new Set<String>{ '765665766' };
		ZPProductLineUtil.queryOpportunity(set_CompanyIds);
		System.assertEquals(objAccount.Tier__c, 'Wholesale', 'Tier is not Wholesale.');
	}
}