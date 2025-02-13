/**
 * @author Praveen Sethu
 * @since 08/01/2022
 * Test class to validate all payment invoices are getting attached to Opportunity
 **/
@isTest
public class PaymentInvoiceBatchTest {
	public final static Date dtPeriodStart = Date.today().toStartOfMonth();
	public final static Date dtPeriodEnd = Date.today().toStartOfMonth().addDays(25);

	/**
	 * @description Setup test data required for all test methods
	 * @author      Praveen Sethu
	 **/
	@testSetup
	public static void setupData() {
		// create invoice run log record
		Invoice_Run_Log__c objInvoiceRunLog = new TestDataFactory.InvoiceRunLogBuilder()
			.setNumberOfInvoice(1)
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(dtPeriodStart)
			.setPeriodEnd(dtPeriodEnd)
			.build();
		insert objInvoiceRunLog;

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;
	}

	/**
	 * @description Setting up test data for creating pricebook and pricebook entries
	 * @author      Praveen Sethu
	 **/
	public static void setUpNewPrices(String strPriceName) {
		// Start setting up data and create pricebook and pricebook entries
		// Create a new pricebook
		Pricebook2 objPriceBookOne = new TestDataFactory.PriceBookBuilder().setName(strPriceName).setActive().build();
		insert objPriceBookOne;

		// Create new products
		List<Product2> list_Products = new List<Product2>();
		list_Products.add(new TestDataFactory.ProductBuilder().setName('Company').setFamily('Company').setProductType(OpportunityUtil.PRODUCT_TYPE_MONTHLY).setProductCategory('Payroll').build());
		list_Products.add(
			new TestDataFactory.ProductBuilder().setName('Active Employee').setFamily('Payroll').setProductType(OpportunityUtil.PRODUCT_TYPE_EMPLOYEES).setProductCategory('Payroll').build()
		);
		list_Products.add(
			new TestDataFactory.ProductBuilder().setName('Contractor').setFamily('Payroll').setProductType(OpportunityUtil.PRODUCT_TYPE_CONTRACTORS).setProductCategory('Payroll').build()
		);
		insert list_Products;

		// Create pricebook entries
		List<PricebookEntry> list_Entries = new List<PricebookEntry>();
		// create standard pricebook entries before creating custom ones
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[2].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(objPriceBookOne.Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(objPriceBookOne.Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[2].Id).setUnitPrice(5).setPriceBookId(objPriceBookOne.Id).setIsActive(true).build());

		insert list_Entries;
	}

	/**
	 * @description Test payment invoice batch job. Assert if batch job updates opportunity
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testPaymentInvoiceBatchJob() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c, 'New Price 1 is blank');

		// Setup pricebooks and pricebook entries
		setUpNewPrices(objTierConfig.New_Price_1__c);

		// Create a company account and set pricing
		Account objCompAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('1234567890')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		insert objCompAccount;

		// Create a company opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompAccount.Id)
			.setName('Test Opp 1')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setSourceID('343434')
			.build();
		insert objOpportunity;

		// update company opportunity to Closed Won
		OpportunityTriggerHelper.skipTrigger = true;
		objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		update objOpportunity;
		OpportunityTriggerHelper.skipTrigger = false;

		// create a payment invoice and set company id
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setName('Test Payment Invoice')
			.setAmount(100)
			.setContractorCount(10)
			.setEmployeeCount(10)
			.setPricing(objTierConfig.New_Price_1__c)
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(dtPeriodStart)
			.setPeriodEnd(dtPeriodEnd)
			.build();
		insert objInvoice;

		// test if invoice is attached to company account
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Account__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(objCompAccount.Id, objInvoiceAssert.Account__c, 'Account not linked properly');

		// start test and kick off scheduled job which will run batch
		Test.startTest();
		PaymentInvoiceBatch clsScehule = new PaymentInvoiceBatch(null);
		clsScehule.execute(null);
		Test.stopTest();

		// assert if invoice is attached to company opportunity
		Opportunity objOpptyAssert = [SELECT Id, Payment_Invoice__c, NumberOfEmployees__c, Number_of_Contractors__c FROM Opportunity WHERE Id = :objOpportunity.Id];

		// assert if opportunity employees and contractor count is updated
		System.assertEquals(objInvoice.Id, objOpptyAssert.Payment_Invoice__c, 'Invoice and Opportunity not linked');
		System.assertEquals(objInvoice.Employee_Count__c, objOpptyAssert.NumberOfEmployees__c, 'Number of Employees not updated from Invoice');
		System.assertEquals(objInvoice.Contractor_Count__c, objOpptyAssert.Number_of_Contractors__c, 'Number of Contractors not updated from Invoice');
		System.assertEquals(3, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpptyAssert.Id], 'Line items not created on the Opportunity');

		// test if first month invoice generated is updated on Account
		Account objAccountAssert = [SELECT Id, First_Month_Invoice_Generated__c FROM Account WHERE Id = :objCompAccount.Id];
		System.assertEquals(true, objAccountAssert.First_Month_Invoice_Generated__c, 'First Month Invoice not generated on the Account');

		// Assert if batch processing state on invoice run log is updated to Processed
		Invoice_Run_Log__c objInvoiceLog = [SELECT Id, Batch_Processing_State__c, Batch_Message__c FROM Invoice_Run_Log__c LIMIT 1];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objInvoiceLog.Batch_Processing_State__c, 'Batch Processing state not updated to Processed');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objInvoiceLog.Batch_Message__c, 'Batch message not updated to Processed');
	}

	/**
	 * @description Test if payment invoice batch job updates pricing on opportunity
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testPaymentInvoicePricingChange() {
		// Get org default tier config settings and assert new price 1 and 2 are not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c, 'New Price 1 is blank');
		System.assertNotEquals(null, objTierConfig.New_Price_2__c, 'New Price 2 is blank');

		// Setup pricebooks and pricebook entries
		setUpNewPrices(objTierConfig.New_Price_1__c);
		setUpNewPrices(objTierConfig.New_Price_2__c);

		// Create a company account and set pricing
		Account objCompAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('1234567890')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		insert objCompAccount;

		// Create a company opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompAccount.Id)
			.setName('Test Opp 1')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setSourceID('343434')
			.build();
		insert objOpportunity;

		// update company opportunity to Closed Won
		OpportunityTriggerHelper.skipTrigger = true;
		objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		update objOpportunity;
		OpportunityTriggerHelper.skipTrigger = false;

		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setName('Test Payment Invoice')
			.setAmount(100)
			.setContractorCount(10)
			.setEmployeeCount(10)
			.setPricing(objTierConfig.New_Price_2__c)
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(dtPeriodStart)
			.setPeriodEnd(dtPeriodEnd)
			.build();
		insert objInvoice;

		// test if invoice is attached to company account
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Account__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(objCompAccount.Id, objInvoiceAssert.Account__c, 'Invoice not linked to the Company Account');

		// start test and kick off scheduled job which will run batch
		Test.startTest();
		PaymentInvoiceBatch clsScehule = new PaymentInvoiceBatch(null);
		clsScehule.execute(null);
		Test.stopTest();

		// assert if invoice is attached to company opportunity
		Opportunity objOpptyAssert = [SELECT Id, Payment_Invoice__c, NumberOfEmployees__c, Number_of_Contractors__c FROM Opportunity WHERE Id = :objOpportunity.Id];

		// assert if opportunity employees and contractor count is updated
		System.assertEquals(objInvoice.Id, objOpptyAssert.Payment_Invoice__c, 'Invoice not linked to the Company Opportunity');
		System.assertEquals(objInvoice.Employee_Count__c, objOpptyAssert.NumberOfEmployees__c, 'Number of employees not updated on the Opportunity');
		System.assertEquals(objInvoice.Contractor_Count__c, objOpptyAssert.Number_of_Contractors__c, 'Number of contractors not updated on the Opportunity');
		System.assertEquals(3, [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :objOpptyAssert.Id], 'Line items not created on the Opportunity');

		// test if first month invoice generated is updated on Account
		Account objAccountAssert = [SELECT Id, First_Month_Invoice_Generated__c FROM Account WHERE Id = :objCompAccount.Id];
		System.assertEquals(true, objAccountAssert.First_Month_Invoice_Generated__c, 'Invoice generated flag missing on the Account');

		// Assert if batch processing state on invoice run log is updated to Processed
		Invoice_Run_Log__c objInvoiceLog = [SELECT Id, Batch_Processing_State__c, Batch_Message__c FROM Invoice_Run_Log__c LIMIT 1];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objInvoiceLog.Batch_Processing_State__c, 'Batch Processing state not updated to Processed');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objInvoiceLog.Batch_Message__c, 'Batch message not updated to Processed');
	}

	/**
	 * @description Test payment invoice error scenarios. Invoices should not be attached to a non CW opportunity
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testInvoiceNotAttachToCompanyOppty() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c, 'New Price 1 is blank');

		// Setup pricebooks and pricebook entries
		setUpNewPrices(objTierConfig.New_Price_1__c);

		// Create a company account and set pricing
		Account objCompAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('1234567890')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		insert objCompAccount;

		// Create a company opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompAccount.Id)
			.setName('Test Opp 1')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setSourceID('343434')
			.build();
		insert objOpportunity;

		// create a payment invoice and set company id
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setName('Test Payment Invoice')
			.setAmount(100)
			.setContractorCount(10)
			.setEmployeeCount(10)
			.setPricing(objTierConfig.New_Price_1__c)
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(dtPeriodStart)
			.setPeriodEnd(dtPeriodEnd)
			.build();
		insert objInvoice;

		// test if invoice is attached to company account
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Account__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(objCompAccount.Id, objInvoiceAssert.Account__c, 'Invoice not linked to the Account');

		// start test and kick off scheduled job which will run batch
		Test.startTest();
		PaymentInvoiceBatch clsScehule = new PaymentInvoiceBatch(null);
		clsScehule.execute(null);
		Test.stopTest();

		// assert if invoice is not attached to company opportunity
		Opportunity objOpptyAssert = [SELECT Id, Payment_Invoice__c, NumberOfEmployees__c, Number_of_Contractors__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(null, objOpptyAssert.Payment_Invoice__c, 'Invoice is attached to the opportunity');

		// Assert if batch processing state on invoice run log is updated to Processed
		Invoice_Run_Log__c objInvoiceLog = [SELECT Id, Batch_Processing_State__c, Batch_Message__c FROM Invoice_Run_Log__c LIMIT 1];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objInvoiceLog.Batch_Processing_State__c, 'Batch Processing state not updated to Processed');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objInvoiceLog.Batch_Message__c, 'Batch message not updated to Processed');
	}

	/**
	 * @description Test scenario where batch kicks off when there are more invoices than we received. Batch should be aborted and error notification will be sent to Slack
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testBatchWithIncorrectInvoices() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c, 'New Price 1 is blank');

		// create a payment invoice 1
		Payment_Invoice__c objInvoice1 = new TestDataFactory.PaymentInvoiceBuilder()
			.setName('Test Payment Invoice')
			.setAmount(100)
			.setContractorCount(10)
			.setEmployeeCount(10)
			.setPricing(objTierConfig.New_Price_1__c)
			.setCompanyId('7876876756')
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(dtPeriodStart)
			.setPeriodEnd(dtPeriodEnd)
			.build();

		// create a payment invoice 2
		Payment_Invoice__c objInvoice2 = new TestDataFactory.PaymentInvoiceBuilder()
			.setName('Test Payment Invoice')
			.setAmount(100)
			.setContractorCount(10)
			.setEmployeeCount(10)
			.setPricing(objTierConfig.New_Price_1__c)
			.setCompanyId('897876786756')
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(dtPeriodStart)
			.setPeriodEnd(dtPeriodEnd)
			.build();

		insert new List<Payment_Invoice__c>{ objInvoice1, objInvoice2 };

		Test.startTest();
		Database.executeBatch(new PaymentInvoiceBatch(null), 2);
		Test.stopTest();

		// Assert if batch processing state on invoice run log is updated to Error
		Invoice_Run_Log__c objInvoiceLog = [SELECT Id, Batch_Processing_State__c, Batch_Message__c FROM Invoice_Run_Log__c LIMIT 1];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objInvoiceLog.Batch_Processing_State__c, 'Batch processing state not updated to Error');
	}

	/**
	 * @description Test if invoice batch job handles exceptions
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testInvoiceException() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c, 'New Price 1 is blank');

		// Setup pricebooks and pricebook entries
		setUpNewPrices(objTierConfig.New_Price_1__c);

		// Create a company account and set pricing
		Account objCompAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Employer Account')
			.setZPCompanyId('1234567890')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		insert objCompAccount;

		// Create a company opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompAccount.Id)
			.setName('Test Opp 1')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setSourceID('343434')
			.build();
		insert objOpportunity;

		// update company opportunity to Closed Won
		OpportunityTriggerHelper.skipTrigger = true;
		objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		update objOpportunity;
		OpportunityTriggerHelper.skipTrigger = false;

		// create a payment invoice and set company id
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setName('Test Payment Invoice')
			.setAmount(100)
			.setContractorCount(10)
			.setEmployeeCount(10)
			.setPricing(objTierConfig.New_Price_1__c)
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(dtPeriodStart)
			.setPeriodEnd(dtPeriodEnd)
			.build();
		insert objInvoice;

		// test if invoice is attached to company account
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Account__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(objCompAccount.Id, objInvoiceAssert.Account__c, 'Invoice not linked to the Account');

		// start test and kick off scheduled job which will run batch
		// set exception flag to true
		PaymentInvoiceBatch.blnException = true;
		Test.startTest();
		PaymentInvoiceBatch clsScehule = new PaymentInvoiceBatch(null);
		clsScehule.execute(null);
		Test.stopTest();

		// assert if invoice is not attached to company opportunity
		Opportunity objOpptyAssert = [SELECT Id, Payment_Invoice__c, NumberOfEmployees__c, Number_of_Contractors__c FROM Opportunity WHERE Id = :objOpportunity.Id];

		// Assert if batch processing state on invoice run log is updated to Error
		Invoice_Run_Log__c objInvoiceLog = [SELECT Id, Batch_Processing_State__c, Batch_Message__c FROM Invoice_Run_Log__c LIMIT 1];
		System.assertEquals(IntegrationUtils.ERROR_STATE, objInvoiceLog.Batch_Processing_State__c, 'Batch Processing State not updated to Error');
	}

	/**
	 * @description Test if Payment Invoice batch runs and attaches to tier upsell opportunity
	 * @author      Praveen Sethu
	 **/
	@isTest
	static void testTierUpsellPaymentInvoiceBatch() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c, 'New Price 1 is blank');

		// Setup pricebooks and pricebook entries
		setUpNewPrices(objTierConfig.New_Price_1__c);

		// Create a company account and set pricing, upsell open opp to true and set first month invoice generated to true
		Account objCompAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Tier upsell Account')
			.setZPCompanyId('1234567890')
			.setPricing(objTierConfig.New_Price_1__c)
			.setFirstMonthInvoiceGenerated(true)
			.setUpsellOpenOpp(true)
			.build();
		insert objCompAccount;

		OpportunityTriggerHelper.skipTrigger = true;
		// Create a tier upsell opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompAccount.Id)
			.setName('Test Opp 1')
			.setCloseDate(Date.today())
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setSourceID('343434')
			.setStage(OpportunityUtil.MQL_STAGE)
			.build();
		insert objOpportunity;

		// update tier upesell opportunity to Closed Won
		objOpportunity.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		update objOpportunity;
		OpportunityTriggerHelper.skipTrigger = false;

		// create a payment invoice and set company id
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setName('Test Payment Invoice')
			.setAmount(100)
			.setContractorCount(10)
			.setEmployeeCount(10)
			.setPricing(objTierConfig.New_Price_1__c)
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(dtPeriodStart)
			.setPeriodEnd(dtPeriodEnd)
			.build();
		insert objInvoice;

		// test if invoice is attached to company account
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Account__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(objCompAccount.Id, objInvoiceAssert.Account__c, 'Account not linked properly');

		// start test and kick off scheduled job which will run batch
		Test.startTest();
		PaymentInvoiceBatch clsScehule = new PaymentInvoiceBatch(null);
		clsScehule.execute(null);
		Test.stopTest();

		// assert if invoice is attached to tier upsell opportunity
		Opportunity objOpptyAssert = [SELECT Id, Payment_Invoice__c, NumberOfEmployees__c, Number_of_Contractors__c FROM Opportunity WHERE Id = :objOpportunity.Id];

		// assert if opportunity employees and contractor count is updated
		System.assertEquals(objInvoice.Id, objOpptyAssert.Payment_Invoice__c, 'Invoice not linked to the Company Opportunity');
		System.assertEquals(objInvoice.Employee_Count__c, objOpptyAssert.NumberOfEmployees__c, 'Number of employees not updated on the Opportunity');
		System.assertEquals(objInvoice.Contractor_Count__c, objOpptyAssert.Number_of_Contractors__c, 'Number of contractors not updated on the Opportunity');

		// test if upsell open opp is updated on Account
		Account objAccountAssert = [SELECT Id, Upsell_Opp_Open__c FROM Account WHERE Id = :objCompAccount.Id];
		System.assertEquals(false, objAccountAssert.Upsell_Opp_Open__c, 'Upsell Open Opp not updated to False on Company Account');

		// Assert if batch processing state on invoice run log is updated to Processed
		Invoice_Run_Log__c objInvoiceLog = [SELECT Id, Batch_Processing_State__c, Batch_Message__c FROM Invoice_Run_Log__c LIMIT 1];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objInvoiceLog.Batch_Processing_State__c, 'Batch Processing state not updated to Processed');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objInvoiceLog.Batch_Message__c, 'Batch message not updated to Processed');
	}
}