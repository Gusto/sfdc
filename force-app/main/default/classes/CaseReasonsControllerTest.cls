@isTest
private class CaseReasonsControllerTest {
	@testSetup
	static void testData() {
		Account acc = TestUtility.CompanyAccount();

		Contact conRec = new Contact();
		conRec.FirstName = 'TestGusto';
		conRec.LastName = 'GustoCaseReasonTest';
		conRec.AccountId = acc.id;
		insert conRec;

		test.startTest();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		insert cse;
		test.stopTest();
	}

	@isTest
	static void accountCaseListSearchTestMethod() {
		Account accRec = [SELECT id FROM Account LIMIT 1];

		apexPages.StandardController sc = new apexPages.StandardController(accRec);
		CaseReasonsController contr = new CaseReasonsController(sc);

		List<Case> tempCaseList = contr.accountCaseList;
		contr.searchCase();

		system.assert(contr.caseStatusOptionList.size() > 0);
		system.assert(contr.caseOriginOptionList.size() > 0);
	}

	@isTest
	static void contactCaseListSearchTestMethod() {
		Contact conRec = [SELECT id, AccountId FROM Contact LIMIT 1];

		apexPages.StandardController sc2 = new apexPages.StandardController(conRec);
		CaseReasonsController contr2 = new CaseReasonsController(sc2);
		contr2.searchCase();

		system.assert(contr2.contactId == conRec.id);

		system.assert(contr2.caseStatusOptionList.size() > 0);
		system.assert(contr2.caseOriginOptionList.size() > 0);
	}
}