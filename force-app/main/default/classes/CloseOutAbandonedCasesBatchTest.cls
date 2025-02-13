@isTest
public class CloseOutAbandonedCasesBatchTest {
	static testMethod void testMethod1() {
		Group testGroup = new Group(Name = 'Phone Routing', Type = 'Queue');
		insert testGroup;

		System.runAs(new User(Id = UserInfo.getUserId())) {
			QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
			insert testQueue;
		}

		Case caseObj = new Case(Call_Connected__c = false, Status = 'New', Origin = 'Phone', OwnerId = testGroup.Id);
		
		CaseTriggerHelper.skipTrigger = true;
		insert caseObj;
		CaseTriggerHelper.skipTrigger = false;

		List<Task> tasks = new List<Task>();
		tasks.add(new Task(ActivityDate = Date.today(), Subject = 'Sample Task', WhatId = caseObj.Id, Status = 'In Progress'));
		insert tasks;

		String strQuery1 = 'SELECT Id, Owner.Name, Origin, (SELECT Id, OwnerId FROM OpenActivities), Call_Connected__c FROM Case';
		String strQuery =
			'SELECT Id, Owner.Name, Origin, (SELECT Id, OwnerId FROM OpenActivities), Call_Connected__c FROM Case ' +
			' WHERE Owner.Name = \'Phone Routing\'' +
			' AND Call_Connected__c = FALSE ' +
			' AND Origin = \'Phone\'';

		Test.startTest();
		CloseOutAbandonedCasesBatch c = new CloseOutAbandonedCasesBatch();
		ID batchprocessid = Database.executeBatch(c, 20);
		Test.stopTest();
	}
}