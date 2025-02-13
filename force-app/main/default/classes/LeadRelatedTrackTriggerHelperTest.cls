/**
Created by : Robin
Created Date : 7/19/2017
**/
@isTest
public class LeadRelatedTrackTriggerHelperTest {
	static testMethod void newRecInsertTrigger() {
		List<Lead> leadList = TestUtility.Leads(1);
		insert leadList;

		Task t = new Task(WhoId = leadList[0].Id, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Email').getRecordTypeId(), Type = 'Email');
		insert t;

		System.assertEquals(1, [SELECT COUNT() FROM Lead_Related_Tracking__c]);

		t = new Task(WhoId = leadList[0].Id, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId(), Type = 'Outbound Call');
		insert t;

		System.assertEquals(1, [SELECT COUNT() FROM Lead_Related_Tracking__c]);
		delete [SELECT Id FROM Lead_Related_Tracking__c LIMIT 1];
	}
}