@isTest
private class CaseRelatedTicketsControllerTest {
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

		Contact cont = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.id)
			.setFirstName('Test')
			.setLastName('CaseRelatedTicketsController')
			.setZPUserId('78787878123')
			.setEmail('CaseRelatedTicketsController@gusto.com')
			.setPhone('7878787899')
			.build();
		insert cont;

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
		CaseRelatedTicketsController controller = new CaseRelatedTicketsController();
		controller.searchRecords();
		List<Ticket__c> tempList = controller.ticketList;
		system.assert(tempList.size() > 0, 'List cannot be null');

		list<SelectOption> tempCompanyFilterList = controller.getCompanyContactFilterList();

		controller.searchTicketVar.Due_Date__c = system.today();
		controller.searchTicketVar.Close_Date__c = system.today();
		controller.searchTicketVar.Description__c = 'test';
		controller.searchRecords();
	}
}