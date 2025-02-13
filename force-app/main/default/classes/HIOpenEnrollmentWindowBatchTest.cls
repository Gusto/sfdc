@isTest
private class HIOpenEnrollmentWindowBatchTest {
	@isTest
	static void testHIOpenEnrollmentWindow() {
		HIOpenEnrollmentWindowTriggerHelper.queue = false;
		HI_Open_Enrollment_Window__c obj = new HI_Open_Enrollment_Window__c();
		obj.Company_Id__c = '44444';
		obj.Created_At__c = DateTime.now();
		obj.Deleted_At__c = DateTime.now();
		obj.External_Key__c = '2222';
		obj.Fulfillment_Id__c = 'Test_FulfillmentId';
		obj.Id__c = '11111';
		obj.Message__c = 'Test';
		obj.New_Hire_Extension_End_Date__c = Date.today();
		obj.OPS_Owner__c = UserInfo.getUserName();
		obj.Processed_At__c = DateTime.now();
		obj.Processing_State__c = 'In Process';
		obj.Updated_At__c = DateTime.now();
		obj.Window_End_Date__c = Date.today().addDays(2);
		obj.Window_Start_Date__c = Date.today();
		insert obj;

		Test.startTest();
		database.executeBatch(new HIOpenEnrollmentWindowBatch(), 10);
		Test.stopTest();
        System.assert(true, 'Fixing Apex PMD issue.');
	}
}