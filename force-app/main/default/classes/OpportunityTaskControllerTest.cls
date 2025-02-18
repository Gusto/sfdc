/**
 * @description Test class for OpportunityTaskController
 * @see OpportunityTaskController
 */
@isTest
public class OpportunityTaskControllerTest {
	/**
	 * @description Setup Test data
	 */
	@testSetup
	static void setupTestData() {
		Opportunity objOppty = new TestDataFactory.OpportunityBuilder().setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID).setName('Test Oppty').setStage('New').build();
		insert objOppty;

		Ticket__c objTicket = new TestDataFactory.TicketBuilder().setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID).setOppId(objOppty.Id).setOwnerId(UserInfo.getUserId()).build();
		insert objTicket;

		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
			.setWhatId(objOppty.Id)
			.setSubject('Follow-up')
			.setDescription('Comments')
			.setStatus(TaskUtil.TASK_STATUS_OPEN)
			.setOwnerId(UserInfo.getUserId())
			.setActivityDate(Date.Today())
			.build();
		insert objTask;

		Event objEvent = new TestDataFactory.EventBuilder()
			.setWhatId(objTicket.Id)
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Event', 'Event'))
			.setSubject('Event Trigger Test')
			.setDescription('Test Description')
			.setOwnerId(UserInfo.getUserId())
			.setStartDateTime(DateTime.now())
			.setEndDateTime(DateTime.now().addHours(1))
			.setType('Demo')
			.build();
		insert objEvent;
	}

	/**
	 * @description Test for getting the tasks related to opportunity for a particular Ticket object
	 **/
	@isTest
	static void testGetOpportunityTasks() {
		Ticket__c objTestTicket = [SELECT Id FROM Ticket__c LIMIT 1];

		Test.startTest();
		List<Task> list_Tasks = OpportunityTaskController.getsObjectActivities(objTestTicket.Id, 'Standard,Call');
		Test.stopTest();

		System.assert(list_Tasks.size() > 0, 'Expected tasks to be returned');
	}

	/**
	 * @description Test for getting the tasks related to Ticket__c for a particular Opportunity object
	 **/
	@isTest
	static void testGetTicketEvents() {
		Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

		Test.startTest();
		List<Event> list_Events = OpportunityTaskController.getsObjectActivities(objOpportunity.Id, 'Event');
		Test.stopTest();

		System.assert(list_Events.size() > 0, 'Expected tasks to be returned');
	}
}