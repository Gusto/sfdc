@isTest
public class CaseButtonPushBackToQueueExtensionTest {
	static testMethod void transferOwnershipToQueueTest() {
		//Create a group
		Group testGroup = new Group(Name = 'test group', Type = 'Queue');
		insert testGroup;

		//Create a case
		Case objCase = new Case();
		insert objCase;

		System.runAs(new User(Id = UserInfo.getUserId())) {
			QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
			insert testQueue;
		}

		//Update case ownership to queue
		objCase.OwnerId = testGroup.Id;
		update objCase;

		PageReference PageRef = Page.CaseButtonPushBackToQueue;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id', String.valueOf(objCase.Id));
		ApexPages.StandardController Standard = new ApexPages.StandardController(objCase);

		CaseButtonPushBackToQueueExtension testAccPlan = new CaseButtonPushBackToQueueExtension(Standard);

		testAccPlan.ChangeOwner();

		//Update case ownership to user
		objCase.OwnerId = Userinfo.getUserId();
		update objCase;
		testAccPlan.ChangeOwner();
		System.assertEquals(testGroup.Id, [SELECT OwnerId FROM Case LIMIT 1].OwnerId);
	}
}