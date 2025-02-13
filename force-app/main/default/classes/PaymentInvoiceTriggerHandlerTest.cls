/**
 * @description Test class for PaymentInvoiceTriggerHandler
 * @author Praveen Sethu
 * @see PaymentInvoiceTriggerHandler
 */
@isTest
public class PaymentInvoiceTriggerHandlerTest {
	@testSetup
	static void setup() {
		// Create a new company account
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('123456789').build();
		insert objAccnt;
		TriggerHandler.clearAllBypasses();
	}
	/**
	 * @description Validate mapping of payment invoice with valid company id to company account in SFDC
	 * @author Praveen Sethu
	 */
	@isTest
	static void testPaymentInvoiceInsert() {
		Account objAccnt = [SELECT Id, ZP_Company_Id__c FROM Account WHERE ZP_Company_Id__c = '123456789'];

		// Start test and insert new Payment Invoice record
		Test.startTest();
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setCompanyId(objAccnt.ZP_Company_Id__c)
			.setPeriodStart(Date.today())
			.setPeriodEnd(Date.today().addDays(10))
			.setPaid(true)
			.build();
		insert objInvoice;
		Test.stopTest();

		// Query Payment Invoice and check if Account__c was set properly
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Account__c, Paid__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(objInvoiceAssert.Account__c, objAccnt.Id, 'Payment Invoice Account was not set properly');

		Account objAccntAssert = [SELECT Id, First_Day_of_Initial_Invoice_Month__c FROM Account WHERE Id = :objAccnt.Id];
		System.assertNotEquals(null, objAccntAssert.First_Day_of_Initial_Invoice_Month__c, 'First Day of Initial Invoice Month is Null');
	}

	/**
	 * @description Validate payment invoices are mapped to account when they are updated.
	 * @author Praveen Sethu
	 */
	@isTest
	static void testPaymentInvoiceUpdate() {
		Account objAccnt = [SELECT Id, ZP_Company_Id__c FROM Account WHERE ZP_Company_Id__c = '123456789'];

		// For testing purpose, skip payment invoice trigger
		PaymentInvoiceTriggerHandler.blnSkipTrigger = true;
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setCompanyId(objAccnt.ZP_Company_Id__c)
			.setPeriodStart(Date.today())
			.setPeriodEnd(Date.today().addDays(10))
			.setPaid(true)
			.build();
		insert objInvoice;

		PaymentInvoiceTriggerHandler.blnSkipTrigger = false;
		Test.startTest();
		update objInvoice;
		Test.stopTest();

		// Query Payment Invoice and check if Account__c was set properly
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Account__c, Paid__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(objInvoiceAssert.Account__c, objAccnt.Id, 'Payment Invoice Account was not set properly');

		Account objAccntAssert = [SELECT Id, First_Day_of_Initial_Invoice_Month__c FROM Account WHERE Id = :objAccnt.Id];
		System.assertNotEquals(null, objAccntAssert.First_Day_of_Initial_Invoice_Month__c, 'First Day of Initial Invoice Month is Null');
	}

	/**
	 * @description Tests if Rate Plan Id from Zuora is mapped to the right ZP Pricing Plan
	 * @author Praveen Sethu
	 */
	@isTest
	static void testRatePlanMapping() {
		Pricebook2 objPricebook = new TestDataFactory.PriceBookBuilder()
			.setName('$40 Base, $6: 1+')
			.setActive()
			.setProductTier('Simple')
			.setPricingPlanId('10')
			.setProductLineId('1')
			.setRatePlanId('8ac69b1d81de2fb60181ed9d45d52d83')
			.build();
		insert objPricebook;

		Account objAccnt = [SELECT Id, ZP_Company_Id__c FROM Account WHERE ZP_Company_Id__c = '123456789'];

		// Start test and insert new Payment Invoice record
		Test.startTest();
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setCompanyId(objAccnt.ZP_Company_Id__c)
			.setPeriodStart(Date.today())
			.setPeriodEnd(Date.today().addDays(10))
			.setRatePlanId(objPricebook.Rate_Plan_Id__c)
			.build();
		insert objInvoice;
		Test.stopTest();

		// validate pricing is set on payment invoice
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Account__c, Pricing__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(objInvoiceAssert.Account__c, objAccnt.Id, 'Payment Invoice Account was not set properly');
		System.assertEquals(objPricebook.Name, objInvoiceAssert.Pricing__c, 'Pricing does not match short description');
	}

	/**
	 * @description Test if processing state is set to Queued if Account has Tier upsell open opp set to true
	 * @author Praveen Sethu
	 */
	@isTest
	static void testTierUpsellInvoice() {
		Account objAccnt = [SELECT Id, ZP_Company_Id__c FROM Account WHERE ZP_Company_Id__c = '123456789'];

		// Set Tier upsell open opp to True & First Month Invoice Generated to True
		objAccnt.Upsell_Opp_Open__c = true;
		objAccnt.First_Month_Invoice_Generated__c = true;
		objAccnt.Joined_Date_Panda__c = System.Today();
		update objAccnt;

		// Start test and insert new Payment Invoice record
		Test.startTest();
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder().setCompanyId(objAccnt.ZP_Company_Id__c).setPeriodStart(Date.today()).setPeriodEnd(Date.today().addDays(10)).build();
		insert objInvoice;
		Test.stopTest();

		// validate processing state is set on payment invoice
		Payment_Invoice__c objInvoiceAssert = [SELECT Id, Processing_State__c FROM Payment_Invoice__c WHERE Id = :objInvoice.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objInvoiceAssert.Processing_State__c, 'Processing state not set to Queued');
	}
}