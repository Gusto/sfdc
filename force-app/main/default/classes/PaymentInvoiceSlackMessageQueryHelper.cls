public with sharing class PaymentInvoiceSlackMessageQueryHelper {
    /**
	 * @Author      : Anurag Gautam
	 * @Description : Gets count of Payment Invoice records for specific start and end date where Account doesn't have the Joined date.
	 * @Parm        : list_InvoiceRunLogs - Invoice Run Log record Id
	 * @Return      : Total number of invoices without joined date.
	 **/
	@InvocableMethod(label='Get Payment Invoices Count without Join Date' description='Returns list of Payment Invoices for specific period start and end date.' category='Payment_Invoice__c')
	public static List<Integer> getPaymentInvoicesByDateWOJoinDate(List<Id> list_InvoiceRunLogs) {
		Integer intPaymentInvoiceWOJoinedDateCount = 0;
		Id idInvoiceRunLog = list_InvoiceRunLogs.get(0);
		if (idInvoiceRunLog != null) {
			//Get Invoice run log
			Invoice_Run_Log__c objInvoiceRunLog = [
				SELECT Id, Period_Start__c, Period_End__c, Workflow_Run_Number__c, Batch_Processing_State__c, Number_of_Invoice__c
				FROM Invoice_Run_Log__c
				WHERE Id = :idInvoiceRunLog
			];

			if (objInvoiceRunLog != null) {
				if (objInvoiceRunLog.Batch_Processing_State__c == IntegrationUtils.PROCESSED_STATE) {
					//Get a count of processed invoices where account doesn't have the join date. 
					intPaymentInvoiceWOJoinedDateCount = [
						SELECT COUNT()
						FROM Payment_Invoice__c
						WHERE
							Workflow_Run_Number__c = :objInvoiceRunLog.Workflow_Run_Number__c
							AND Period_Start_Date__c = :objInvoiceRunLog.Period_Start__c
							AND Period_End_Date__c = :objInvoiceRunLog.Period_End__c
							AND Message__c =: PaymentInvoiceTriggerHelper.FIRST_INVOICE_NO_ACCOUNT_JOIN_DATE
					];
				}
			}
		}
		// returning the count and this being used in Zuora_Invoice_After_Batch_Async_Flow flow.
		return new List<Integer>{intPaymentInvoiceWOJoinedDateCount};
	}
}