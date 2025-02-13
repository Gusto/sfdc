@isTest
private class CaseContactSearchControllerTest {
	@testSetup
	static void testSetupUtilityMethod() {
		AccountTriggerHelper.skipTrigger = true;
		//ConntactTriggerHelper.skipTrigger=true;

		list<Contact> conlist = new List<Contact>();

		Account acc = TestUtility.CompanyAccount();

		Contact cont = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.id)
			.setFirstName('Test_Contact')
			.setLastName('TestCaseContactSearch1')
			.setEmail('caseContactSearch1@gusto.com')
			.setPhone('9999000090')
			.setZPUserId('contactSearch12345')
			.build();

		Contact cont2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.id)
			.setFirstName('Test_Contact1')
			.setLastName('TestCaseContactSearch2')
			.setEmail('caseContactSearch2@gusto.com')
			.setPhone('9999000091')
			.setZPUserId('contactSearch123456')
			.build();

		conlist.add(cont);
		conlist.add(cont2);

		insert conList;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'Payroll Care';
		cse.Genesys_Call_Id__c = 'genId321321';
		insert cse;
	}

	@isTest
	static void searchPresentContact() {
		test.starttest();
		list<Case> caseList = [SELECT id, ContactId FROM case];
		Case tempCaseRec = new Case();
		if (caseList.size() > 0) {
			tempCaseRec = caseList.get(0);
		}

		list<Contact> conList = [SELECT id FROM Contact];

		apexPages.currentpage().getparameters().put('key', '9999000091');
		apexPages.currentpage().getparameters().put('genesysId', 'genId321321');
		apexPages.currentpage().getparameters().put('src', 'SF');

		CaseContactSearchController controller = new CaseContactSearchController();
		controller.initialPhone = '9999000091';
		controller.openCaseId = tempCaseRec.id;
		Id[] fixedSearchResults = new List<Id>{ conList.get(0).id };
		Test.setFixedSearchResults(fixedSearchResults);
		controller.initialSearch();
		controller.searchContact();
		list<Contact> tempList = controller.contactSearchList;
		//system.assert(tempList.size()>0);
		controller.selectedContactId = conList.get(0).id;

		system.assert(tempCaseRec.ContactId == null, 'Contact Id cannot be null');
		controller.updateCaseWithContact();
		caseList = [SELECT id, ContactId FROM case];
		system.assert(caseList.get(0).ContactId != null, 'Contact Id cannot be null');

		test.stopTest();
	}

	@isTest
	static void updateCaseWithContactAndUnkowCallerMethod() {
		test.startTest();
		list<Case> caseList = [SELECT id, ContactId FROM case];
		Case tempCaseRec = new Case();
		if (caseList.size() > 0) {
			tempCaseRec = caseList.get(0);
		}

		list<Account> accList = [SELECT id FROM Account];

		apexPages.currentpage().getparameters().put('key', '9999000091');
		apexPages.currentpage().getparameters().put('genesysId', 'genId321321');
		apexPages.currentpage().getparameters().put('src', 'SF');
		apexPages.currentpage().getparameters().put('ZPUseremail', '123');

		CaseContactSearchController controller = new CaseContactSearchController();
		controller.initialPhone = '9999000091';
		controller.openCaseId = tempCaseRec.id;
		controller.newContact.LastName = 'TestContactSearchUser';
		controller.newContact.FirstName = 'ContactSearchControllerTest';

		controller.newContact.Phone = '9999000093';
		controller.selectedContactAccount = accList.get(0).id;
		controller.addUserPopulateField();
		system.assert(CaseContactSearchController.getPotentialContacts('TestCaseContactSearch2').size() > 0, 'Cannot be null');

		controller.createAssignContact();
		system.assert([SELECT id FROM Contact WHERE lastName = 'TestContactSearchUser'].size() > 0, 'Cannot be null');
		controller.handleUnknowUser();

		test.stopTest();
	}
}