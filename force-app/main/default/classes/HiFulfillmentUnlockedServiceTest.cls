@isTest
private class HiFulfillmentUnlockedServiceTest {
	static testMethod void testUnlocService() {
		hiFulfillmentEventTriggerHelper.skipTrigger = true;
		Hi_Fulfillment_Event__c unLockEvent = new Hi_Fulfillment_Event__c();
		unLockEvent.Event_Type__c = 'enrollment_unlocked';
		unLockEvent.Employee_Id__c = '111';
		insert unLockEvent;

		Hi_Fulfillment_Event__c terminationEvent = new Hi_Fulfillment_Event__c();
		terminationEvent.Event_Type__c = 'employee_losing_eligibility';
		terminationEvent.Employee_Id__c = '111';
		insert terminationEvent;

		Hi_Fulfillment_Event__c nheEvent = new Hi_Fulfillment_Event__c();
		nheEvent.Event_Type__c = 'enrollment_ready_for_processing';
		nheEvent.Employee_Id__c = '111';
		insert nheEvent;

		HiFulfillmentUnlockedService.updateInfo upInfo = new HiFulfillmentUnlockedService.updateInfo();
		upInfo.id = unLockEvent.id;

		System.assertNotEquals(null, upInfo.id, 'The Hi_Fulfillment_Event__c record should have been inserted successfully.');

		HiFulfillmentUnlockedService.doPost(upInfo);

		//Assert that the 'Enrollment_Unlocked_Processed__c' field was updated to true of Hi_Fulfillment_Event__c record.
		Hi_Fulfillment_Event__c var_HiFulfillmentEvent = [SELECT Id, Enrollment_Unlocked_Processed__c FROM Hi_Fulfillment_Event__c WHERE Id = :unLockEvent.Id];
		System.assertEquals(true, var_HiFulfillmentEvent.Enrollment_Unlocked_Processed__c, 'The Enrollment_Unlocked_Processed__c field should be set to true after the event is processed.');
	}
}