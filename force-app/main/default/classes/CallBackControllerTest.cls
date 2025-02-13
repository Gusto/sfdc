@isTest
private class CallBackControllerTest {
	@TestSetup
	static void setupMethod() {
		Account acc = TestUtility.CompanyAccount();

		Contact contact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.id)
			.setFirstName('Test Contact')
			.setLastName('CallBackTest')
			.setZPUserId('777777777777777')
			.setEmail('testuer@abccompany.com')
			.setPhone('1234564543')
			.build();
		insert contact;
	}

	@isTest
	static void validateInITMethod() {
		List<Account> accList = [SELECT id FROM Account];
		list<Contact> conList = [SELECT id FROM Contact];

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		if (accList.size() > 0) {
			cse.AccountId = accList.get(0).Id;
		}
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'Sales';
		cse.Origin = 'Email';
		cse.SuppliedEmail = 'test.test@test.com';
		cse.SuppliedPhone = '4598598495';
		cse.SuppliedName = 'TestCallBack Controller';
		cse.Auto_Close_Date_Time__c = system.now();
		if (conList.size() > 0) {
			cse.ContactId = conList[0].id;
		}

		CaseTriggerHelper.skipTrigger = true;
		insert cse;

		apexPages.currentPage().getParameters().put('caseId', cse.id);
		apexPages.currentPage().getParameters().put('contactId', conList[0].id);
		CallBackController controller = new CallbackController();
		controller.submitCallBack();

		list<Case_Audit_log__c> auditList = [SELECT id FROM Case_Audit_log__c];

		system.assert(auditList.size() > 0, 'List cannot be empty');

		cse.SuppliedPhone = '45985984953';
		update cse;

		CallBackController controller2 = new CallbackController();
		controller2.submitCallBack();

		cse.SuppliedPhone = '';
		update cse;

		CallBackController controller3 = new CallbackController();
		controller3.submitCallBack();

		cse.SuppliedPhone = '4598598495';
		cse.SuppliedName = '';
		update cse;

		CallBackController controller4 = new CallbackController();
		controller4.submitCallBack();
	}
}