@isTest
private class TicketSearchControllerTest {
	@testsetup
	static void setupTestData() {
		AccountTriggerHelper.skipTrigger = true;
		contactTriggerHelper.skipTrigger = true;
		ZPUserTriggerHelper.skipTrigger = true;
		ZPUserRoleTriggerHelper.skipTrigger = true;

		ZP_User__c zpUser = new ZP_User__c();
		zpUser.Email__c = 'CaseRelatedTicketsController@gusto.com';
		zpUser.Created_At__c = Date.newInstance(2016, 11, 9);
		zpUser.Updated_At__c = Date.newInstance(2016, 12, 9);
		zpUser.Last_Sign_In_At__c = Date.newInstance(2018, 1, 1);
		zpUser.Id__c = '78787878123';
		insert zpUser;

		ZP_User_Role__c zpUserRole = new ZP_User_Role__c();
		zpUserRole.User_Id__c = '78787878123';
		zpUserRole.Company_id__c = '78787878';
		insert zpUserRole;

		Account acc = TestUtility.CompanyAccount();
		acc.ZP_Company_id__c = '78787878';
		update acc;

		Contact objCont = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setPhone('7878787899')
			.setFirstName('Test')
			.setLastName('CaseRelatedTicketsController')
			.setAccountId(acc.id)
			.setEmail('CaseRelatedTicketsController@gusto.com')
			.setZPUserId('78787878123')
			.build();
		insert objCont;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Care');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'Benefits Care';
		cse.Origin = 'Email';
		cse.SuppliedEmail = 'test.test1@test.com';
		cse.Authorized_User__c = 'No';
		insert cse;

		Ticket__c ticket = new Ticket__c();
		ticket.RecordTypeId = cache.getRecordTypeId('Ticket__c', 'Benefits Compliance');
		ticket.case__c = cse.id;
		ticket.status__c = 'New';
		ticket.priority__c = 'Low';
		ticket.Description__c = 'test';
		ticket.Reporting_Team__c = 'Benefits Care';
		insert ticket;
	}

	@isTest
	static void testTicketRetrival() {
		case caseRec = [SELECT id FROM Case LIMIT 1];

		apexpages.Currentpage().getParameters().put('id', caseRec.id);
		TicketSearchController controller = new TicketSearchController();
		controller.searchRecords();
		List<TicketSearchController.TicketWrapper> tempList = controller.ticketList;

		list<SelectOption> tempCommentFilterList = controller.getCommentDescriptionFilterList();

		System.assert(tempCommentFilterList.size() > 0, 'There should be more than 0 comment filters.');
		controller.searchTicketVar.Description__c = 'test';
		controller.searchRecords();
		controller.getDeselectRecordType();
		controller.getDeselectedRecordTypeValues();
		controller.getSelectedrecordTypeValues();

		controller.getSelectStatus();
		controller.getDeselectStatus();
		list<SelectOption> tempstatusList = controller.getDeselectedStatusValues();
		System.assert(tempstatusList.size() > 0, 'List should have more than 0 items.');
		controller.getSelectedStatusValues();
	}
}