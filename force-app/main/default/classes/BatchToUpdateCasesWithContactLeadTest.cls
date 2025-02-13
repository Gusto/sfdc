/*
    By: Deepak Tyagi
    Date : April 16, 2019
    Description : Case Back attach Batch
*/
@isTest
public class BatchToUpdateCasesWithContactLeadTest {
	@testSetup
	static void setUp() {
		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Reseller').setName('Test Company').setZPCompanyId('00000000000000')
			.build();
		insert objAcc;

		List<Contact> list_Contacts = new List<Contact>{
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company').setAccountId(objAcc.Id)
				.setZPUserId('777777777777777').setFirstName('Test').setLastName('Contact')
				.setEmail('testuer@abccompany.com').setPhone('1234567893')
				.build()
		};
		insert list_Contacts;

		List<Lead> list_Leads = new List<Lead>{
			new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID).setCompany('Test')
				.setFirstName('Test').setLastName('Test').setEmail('test@test.com')
				.setPhone('1234567891').setLeadSource('G2 crowd')
				.build(),
			new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID).setCompany('Test')
				.setFirstName('Test').setLastName('Test').setEmail('testReseller@test.com')
				.setPhone('1234567892').setLeadSource('G2 crowd')
				.build()
		};
		insert list_Leads;
	}

	@isTest
	static void testCaseContactWithEmail() {
		List<Contact> list_Contact = [SELECT Id FROM Contact WHERE Email = 'testuer@abccompany.com'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Sales Cases').setType('QLE').setSubject('Test')
			.setSuppliedEmail('testuer@abccompany.com').setDescription('Test')
			.build();
		insert objCase;

		Test.startTest();
		BatchToUpdateCasesWithContactLead batchObj = new BatchToUpdateCasesWithContactLead();
		Database.executeBatch(batchObj);
		Test.stopTest();

		objCase = [SELECT Id, ContactId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCase.ContactId, list_Contact[0].Id);
	}

	@isTest
	static void testCaseContactWithPhone() {
		List<Contact> list_Contact = [SELECT Id FROM Contact WHERE Phone = '1234567893'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Sales Cases').setType('Phone')
			.setSubject('1234567893 Incoming Call at 4/15/2019 1:46 PM')
			.setDescription('Test').setOrigin('Phone')
			.build();
		insert objCase;

		Test.startTest();
		BatchToUpdateCasesWithContactLead batchObj = new BatchToUpdateCasesWithContactLead();
		Database.executeBatch(batchObj);
		Test.stopTest();

		objCase = [SELECT Id, ContactId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCase.ContactId, list_Contact[0].Id);
	}

	@isTest
	static void testCaseEmailWithCompanyLead() {
		List<Lead> list_Lead = [SELECT Id FROM Lead WHERE Email = 'test@test.com'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Sales Cases').setType('QLE').setSubject('Test')
			.setSuppliedEmail('test@test.com').setDescription('Test')
			.build();
		insert objCase;

		Test.startTest();
		BatchToUpdateCasesWithContactLead batchObj = new BatchToUpdateCasesWithContactLead();
		Database.executeBatch(batchObj);
		Test.stopTest();

		objCase = [SELECT Id, Lead__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCase.Lead__c, list_Lead[0].Id);
	}

	@isTest
	static void testCaseEmailWithResellerLead() {
		List<Lead> list_Lead = [SELECT Id FROM Lead WHERE Email = 'testReseller@test.com'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Sales Cases').setType('QLE').setSubject('Test')
			.setSuppliedEmail('testReseller@test.com').setDescription('Test')
			.build();
		insert objCase;

		Test.startTest();
		BatchToUpdateCasesWithContactLead batchObj = new BatchToUpdateCasesWithContactLead();
		Database.executeBatch(batchObj);
		Test.stopTest();

		objCase = [SELECT Id, Lead__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCase.Lead__c, list_Lead[0].Id);
	}

	@isTest
	static void testCasePhoneWithCompanyLead() {
		List<Lead> list_Lead = [SELECT Id FROM Lead WHERE Email = 'test@test.com'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Sales Cases').setType('Problem')
			.setSubject('1234567891 Incoming Call at 4/15/2019 1:46 PM')
			.setDescription('Test').setOrigin('Phone')
			.build();
		insert objCase;

		Test.startTest();
		BatchToUpdateCasesWithContactLead batchObj = new BatchToUpdateCasesWithContactLead();
		Database.executeBatch(batchObj);
		Test.stopTest();

		objCase = [SELECT Id, Lead__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCase.Lead__c, list_Lead[0].Id);
	}

	@isTest
	static void testCasePhoneWithResellerLead() {
		List<Lead> list_Lead = [SELECT Id FROM Lead WHERE Email = 'testReseller@test.com'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Sales Cases').setType('Problem')
			.setSubject('1234567892 Incoming Call at 4/15/2019 1:46 PM')
			.setDescription('Test').setOrigin('Phone')
			.build();
		insert objCase;

		Test.startTest();
		BatchToUpdateCasesWithContactLead batchObj = new BatchToUpdateCasesWithContactLead();
		Database.executeBatch(batchObj);
		Test.stopTest();

		objCase = [SELECT Id, Lead__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCase.Lead__c, list_Lead[0].Id);
	}

	@isTest
	static void testScheduleJob() {
		List<Lead> list_Lead = [SELECT Id FROM Lead WHERE Email = 'testuer@abccompany.com'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Sales Cases').setType('QLE').setSubject('Test')
			.setSuppliedEmail('testuer@abccompany.com').setDescription('Test')
			.build();
		insert objCase;

		test.startTest();
		String CRON_EXP = '0 0 * * * ?';
		BatchToUpdateCasesWithContactLeadSch sch = new BatchToUpdateCasesWithContactLeadSch();
		String strJobId = System.schedule('Hourly Example Batch Schedule job', CRON_EXP, sch);
		test.stopTest();

		System.assertNotEquals(null, strJobId, 'Job not scheduled');
	}
}