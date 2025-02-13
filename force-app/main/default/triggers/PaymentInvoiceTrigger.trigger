/**
Created by : Praveen Sethu
Created Date : 07/14/2022
Description: Trigger on Payment Invoice
Test class: PaymentInvoiceTriggerHandlerTest 
**/
trigger PaymentInvoiceTrigger on Payment_Invoice__c (before insert, after insert, before update, after update) {

    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers') || PaymentInvoiceTriggerHandler.blnSkipTrigger ) {return;}

	new PaymentInvoiceTriggerHandler().run();
}