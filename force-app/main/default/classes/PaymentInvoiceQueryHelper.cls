/**
 * @name         : PaymentInvoiceQueryHelper
 * @author       : Praveen Sethu
 * @date         : 08-24-2022
 * @description  : Query Helper class to get payment invoice data
 * @test classes : PaymentInvoiceQueryHelperTest
 **/
public class PaymentInvoiceQueryHelper {
	/**
	 * @Author      : Praveeen Sethu
	 * @Description : Gets count of Payment Invoice records for specific start and end date
	 * @Parm        : list_InvoiceRunLogs - Invoice Run Log record Id
	 * @Return      : N/A
	 **/
	@InvocableMethod(label='Get Payment Invoices By Date' description='Returns list of Payment Invoices for specific period start and end date.' category='Payment_Invoice__c')
	public static List<Integer> getPaymentInvoicesByDate(List<Id> list_InvoiceRunLogs) {
		Set<String> list_PendingStates = new Set<String>{ IntegrationUtils.ERROR_STATE, IntegrationUtils.QUEUED_STATE, IntegrationUtils.BACKLOG };
		Integer intPaymentInvoiceCount = 0;
		Id idInvoiceRunLog = list_InvoiceRunLogs.get(0);
		if (idInvoiceRunLog != null) {
			Invoice_Run_Log__c objInvoiceRunLog = [
				SELECT Id, Period_Start__c, Period_End__c, Workflow_Run_Number__c, Batch_Processing_State__c, Number_of_Invoice__c
				FROM Invoice_Run_Log__c
				WHERE Id = :idInvoiceRunLog
			];

			if (objInvoiceRunLog != null) {
				if (objInvoiceRunLog.Batch_Processing_State__c == IntegrationUtils.PROCESSED_STATE) {
					// if batch job is processed - get invoices with pending processing states
					intPaymentInvoiceCount = [
						SELECT COUNT()
						FROM Payment_Invoice__c
						WHERE
							Workflow_Run_Number__c = :objInvoiceRunLog.Workflow_Run_Number__c
							AND Period_Start_Date__c = :objInvoiceRunLog.Period_Start__c
							AND Period_End_Date__c = :objInvoiceRunLog.Period_End__c
							AND Processing_State__c IN :list_PendingStates
					];
				} else {
					// if batch job is not processed - get all invoices for a workflow run number & period start, end dates
					intPaymentInvoiceCount = [
						SELECT COUNT()
						FROM Payment_Invoice__c
						WHERE
							Workflow_Run_Number__c = :objInvoiceRunLog.Workflow_Run_Number__c
							AND Period_Start_Date__c = :objInvoiceRunLog.Period_Start__c
							AND Period_End_Date__c = :objInvoiceRunLog.Period_End__c
					];

					if (intPaymentInvoiceCount == objInvoiceRunLog.Number_of_Invoice__c) {
						Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
						Integer intBatchSize = config.Payment_Invoice_Batch_Size__c != null ? config.Payment_Invoice_Batch_Size__c.intValue() : 5;

						Database.executeBatch(new PaymentInvoiceBatch(objInvoiceRunLog), intBatchSize);
					}
				}
			}
		}
		return new List<Integer>{ intPaymentInvoiceCount };
	}
}