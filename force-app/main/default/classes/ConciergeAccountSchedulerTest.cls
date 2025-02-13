@isTest
private class ConciergeAccountSchedulerTest {
	@testSetup
	static void createRecords() {
		list<Account> accList = new List<Account>();
		list<Contact> conList = new List<Contact>();
		list<AccountContactRelation> relationList = new List<AccountContactRelation>();

		Account Company1 = new Account();
		company1.recordTypeId = Cache.getRecordTypeId('Account', 'Company');
		company1.Name = 'Concierge Company 1';
		company1.Concierge_Group__c = 'Tier 1';
		company1.ZP_Company_Id__c = '11111111111111';
		accList.add(company1);

		insert accList;

		ZP_Company__c zpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setProcessingState('Queued')
			.setCreatedAtDate(System.today())
			.setName('Test Company')
			.build();
		insert zpCompany;

		ZP_User__c user = new ZP_User__c();
		user.Id__c = '777777777777777';
		user.email__c = 'testuserConciergeTest@gusto.com';
		user.Last_Sign_In_At__c = System.now();
		user.Created_At__c = System.now();
		user.Updated_At__c = System.now();
		insert user;

		List<ZP_User_Role__c> userRoleList = new List<ZP_User_Role__c>();

		ZP_User_Role__c userRole = new ZP_User_Role__c();
		userRole.User_Id__c = '777777777777777';
		userRole.Id__c = '2222222222233';
		userRole.Company_Id__c = '11111111111111';
		userRole.Created_At__c = System.now();
		userRole.Updated_At__c = System.now();
		userRole.Type__c = 'Role::PayrollAdmin';
		userRoleList.add(userRole);

		insert userRoleList;

		Contact contact1 = new Contact();
		contact1.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
		Contact1.LastName = 'conciergeMainContact';
		contact1.AccountId = company1.Id;
		contact1.ZP_User_Id__c = '777777777777777';
		conList.add(contact1);

		insert conList;
	}

	@isTest
	static void testBatchMethod() {
		Test.startTest();
		String Cron_Sched = '0 0 * * * ?';
		ConciergeAccountScheduler CAS = new ConciergeAccountScheduler();
		String jobID = System.schedule('ConciergeAccountScheduler Job', Cron_Sched, CAS);
		System.assert(jobID != null, 'Job ID should not be null');
		Test.stopTest();
	}
}