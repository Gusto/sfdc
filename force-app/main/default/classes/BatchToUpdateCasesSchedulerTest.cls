@isTest
public class BatchToUpdateCasesSchedulerTest {
	@testSetup
	static void setUp() {
		Account objAccount = new Account();
		objAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Reseller');
		objAccount.Name = 'Test Company';
		objAccount.ZP_Company_ID__c = '00000000000000';
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test Contact Name')
			.setLastName('Test Last Name')
			.setZPUserId('777777777777777')
			.setEmail('testuer@abccompany.com')
			.build();
		insert objContact;

		List<Lead> list_Leads = new List<Lead>();
		Lead objLead = new Lead();
		objLead.FirstName = 'Test';
		objLead.LastName = 'Test';
		objLead.Email = 'test@test.com';
		objLead.Company = 'Test';
		objLead.LeadSource = 'G2 crowd';
		objLead.Phone = '1234567890';
		objLead.G2_Crowd_Company_SIze__c = 'Myself Only';
		list_Leads.add(objLead);

		Lead objLead2 = new Lead();
		objLead2.FirstName = 'Test';
		objLead2.LastName = 'Test';
		objLead2.Email = 'testReseller@test.com';
		objLead2.Company = 'Test';
		objLead2.LeadSource = 'G2 crowd';
		objLead2.Phone = '1234567890';
		objLead2.G2_Crowd_Company_SIze__c = 'Myself Only';
		objLead2.RecordTypeId = Cache.getRecordTypeId('Lead', 'Reseller');
		list_Leads.add(objLead2);
		insert list_Leads;

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Sales Cases');
		objCase.Subject = 'Test';
		objCase.Description = 'Test';
		objCase.Type = 'QLE';
		objCase.SuppliedEmail = 'testuer@abccompany.com';
		insert objCase;
	}

	@isTest
	static void testBatchMethod() {
		Test.startTest();
		String strCron = '0 0 * * * ?';
		BatchToUpdateCasesScheduler objBatch = new BatchToUpdateCasesScheduler();
		String strJobId = System.schedule('BatchToUpdateCasesScheduler Job', strCron, objBatch);
		Test.stopTest();
		System.assertNotEquals(null, strJobId, 'Job ID should not be null');
	}
}