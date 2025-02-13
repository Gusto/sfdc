/**
 * @name         : PaymentInvoiceQueryHelperTest
 * @author       : Praveen Sethu
 * @date         : 08-24-2022
 * @description  :
 **/
@isTest
public with sharing class PaymentInvoiceQueryHelperTest {

	/**
	 * @description Test setup methods that creates company accounts
	 * @author Praveen Sethu
	 */
	@testSetup
	static void setup() {
		// Create a new company account
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('123456789').build();
		objAccnt.Joined_Date_Panda__c = System.Today();
		insert objAccnt;
		TriggerHandler.clearAllBypasses();
	}

	/**
	 * @Author      : Praveeen Sethu
	 * @Description : Gets Payment Invocie records when Batch Processing State is null
	 **/
	@IsTest
	static void testPaymentInvoiceQuery() {
		// create invoice run log record
		Invoice_Run_Log__c objInvoiceRunLog = new TestDataFactory.InvoiceRunLogBuilder()
			.setNumberOfInvoice(1)
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(Date.today())
			.setPeriodEnd(Date.today().addDays(10))
			.setBatchProcessingState(IntegrationUtils.QUEUED_STATE)
			.build();
		insert objInvoiceRunLog;

		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setCompanyId('123456789')
			.setPeriodStart(objInvoiceRunLog.Period_Start__c)
			.setPeriodEnd(objInvoiceRunLog.Period_End__c)
			.setPaid(true)
			.setWorkflowRunNumber(objInvoiceRunLog.Workflow_Run_Number__c)
			.build();
		insert objInvoice;

		Test.startTest();
		List<Integer> list_InvoiceCount = PaymentInvoiceQueryHelper.getPaymentInvoicesByDate(new List<Id>{ objInvoiceRunLog.Id });
		List<Integer> list_InvoiceWOJoinDateCount = PaymentInvoiceSlackMessageQueryHelper.getPaymentInvoicesByDateWOJoinDate(new List<Id>{ objInvoiceRunLog.Id });
		Test.stopTest();

		System.assertEquals(1, list_InvoiceCount.get(0), 'Incorrect queued invoices');
		System.assertEquals(0, list_InvoiceWOJoinDateCount.get(0), 'Invoice not processed without join date.');
	}

	/**
	 * @Author      : Praveeen Sethu
	 * @Description : Gets Payment Invocie records when Batch Processing State is Processed
	 **/
	@IsTest
	static void testProcessedInvoiceLogQuery() {
		// create invoice run log record
		Invoice_Run_Log__c objInvoiceRunLog = new TestDataFactory.InvoiceRunLogBuilder()
			.setNumberOfInvoice(1)
			.setWorkflowRunNumber('WF-0001')
			.setPeriodStart(Date.today())
			.setPeriodEnd(Date.today().addDays(10))
			.setBatchProcessingState(IntegrationUtils.PROCESSED_STATE)
			.build();
		insert objInvoiceRunLog;

		// Set it without company id - Payment Invoice will go to Error State
		Payment_Invoice__c objInvoice = new TestDataFactory.PaymentInvoiceBuilder()
			.setPeriodStart(objInvoiceRunLog.Period_Start__c)
			.setPeriodEnd(objInvoiceRunLog.Period_End__c)
			.setPaid(true)
			.setWorkflowRunNumber(objInvoiceRunLog.Workflow_Run_Number__c)
			.build();
		insert objInvoice;

		Test.startTest();
		List<Integer> list_InvoiceCount = PaymentInvoiceQueryHelper.getPaymentInvoicesByDate(new List<Id>{ objInvoiceRunLog.Id });
		List<Integer> list_InvoiceWOJoinDateCount = PaymentInvoiceSlackMessageQueryHelper.getPaymentInvoicesByDateWOJoinDate(new List<Id>{ objInvoiceRunLog.Id });
		Test.stopTest();

		System.assertEquals(1, list_InvoiceCount.get(0), 'Incorrect Processed Invoices');
		System.assertEquals(0, list_InvoiceWOJoinDateCount.get(0), 'Invoice not processed without join date.');
	}
}