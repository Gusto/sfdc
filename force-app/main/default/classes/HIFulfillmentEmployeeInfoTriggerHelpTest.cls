@isTest
private class HIFulfillmentEmployeeInfoTriggerHelpTest {
	static testMethod void test1() {
		HI_Fulfillment_Employee_Info__c info = new HI_Fulfillment_Employee_Info__c();
		info.Employee_Id__c = '111112222233333';
		info.First_Name__c = 'Test';
		info.Last_Name__c = 'Test';
		insert info;

		//Check that the record was inserted and the Employee_Id__c is correct
		info = [SELECT Employee_Id__c, First_Name__c FROM HI_Fulfillment_Employee_Info__c WHERE Employee_Id__c = '111112222233333' LIMIT 1];
		System.assertEquals('111112222233333', info.Employee_Id__c, 'The Employee Id should be 111112222233333 after insert.');

		info.First_Name__c = 'eId_Updated';
		update info;

		//Check that the First_Name__c field is updated
		info = [SELECT First_Name__c FROM HI_Fulfillment_Employee_Info__c WHERE Employee_Id__c = '111112222233333' LIMIT 1];
		System.assertEquals('eId_Updated', info.First_Name__c, 'The First Name should be updated to "eId_Updated"');

		//Check that the record is deleted by ensuring no records exist with that Employee_Id__c
		delete info;
		Integer count = [SELECT COUNT() FROM HI_Fulfillment_Employee_Info__c WHERE Employee_Id__c = 'eId_Updated'];
		System.assertEquals(0, count, 'The record should be deleted and not found in the database.');
	}
}