@isTest
private class ConciergeAccountBatchTest {
	@testSetup
	static void createRecords() {
		List<Account> accList = new List<Account>();
		List<Contact> conList = new List<Contact>();
		List<AccountContactRelation> relationList = new List<AccountContactRelation>();

		Account Company1 = new Account();
		company1.recordTypeId = Cache.getRecordTypeId('Account', 'Company');
		company1.Name = 'Concierge Company 1';
		company1.Concierge_Group__c = 'Tier 1';
		company1.Concierge_Group_Id__c = 'Tier';
		company1.ZP_Company_Id__c = '11111111111111';
		company1.Tier_Update_Status__c = 'Not Processed';
		accList.add(company1);

		insert accList;

		ZP_Company__c zpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setName('Test Company')
			.setProcessingState('Queued')
			.setPartnerProgramCompanyDataId('PPCD1')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.build();
		zpCompany.Company_Lead_Id__c = '222222222222';
		zpCompany.Created_At__c = System.today();
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
		ConciergeAccountBatch controller = new ConciergeAccountBatch();
		Database.executeBatch(controller);
		Test.stopTest();

		List<Contact> conList = [SELECT Id, Concierge_Account__c FROM Contact];
		System.assert(conList.size() > 0, 'List should not be empty');
	}
}