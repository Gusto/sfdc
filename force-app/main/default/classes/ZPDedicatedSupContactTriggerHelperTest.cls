@isTest
private class ZPDedicatedSupContactTriggerHelperTest {
	@testSetup
	static void setUp() {
		AccountTriggerHelper.SkipTrigger = true;
		ContactTriggerHelper.SkipTrigger = true;
		CaseTriggerHelper.SkipTrigger = true;

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Company')
			.setRecordTypeId('Company')
			.setZPCompanyId('111111111111')
			.build();

		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setPhone('123456')
			.setAccountId(objAccount.Id)
			.setEmail('test@test.com')
			.setFirstName('Test')
			.setLastName('Test')
			.build();
			
		insert objContact;

		List<Case> list_Cases = new List<Case>();
		Case cse = new Case();
		cse.ContactId = objContact.Id;
		cse.AccountId = objAccount.Id;
		cse.Direction__c = 'Inbound';
		cse.Origin = 'Email';
		cse.Zendesk_Id__c = '12345';
		cse.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		list_Cases.add(cse);

		Case objCaseChat1 = new TestDataFactory.CaseBuilder().setSubject('Test Chat Case1').setOrigin('Chat').setRecordTypeId('Payroll Care').setAccountId(objAccount.Id).setContactId(objContact.Id).build();
		list_Cases.add(objCaseChat1);

		Case objCaseChat2 = new TestDataFactory.CaseBuilder()
			.setSubject('Test Chat Case2')
			.setOrigin('Origin')
			.setRecordTypeId('Benefits Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.build();
		objCaseChat2.First_Level__c = 'Test first level';
		list_Cases.add(objCaseChat2);

		insert list_Cases;

		PhoneContact__c pheCnt = new PhoneContact__c();
		pheCnt.Phone__c = '1234512345';
		pheCnt.SMSOptIn__c = true;
		pheCnt.DoNotContact__c = false;
		insert pheCnt;

		Case_Reason_Classification__c cseReason = new Case_Reason_Classification__c();
		cseReason.name = 'Test Reason';
		cseReason.Reason_Code__c = 'solved_test_reason';
		cseReason.Active__c = true;
		insert cseReason;

		AccountTriggerHelper.SkipTrigger = false;
		ContactTriggerHelper.SkipTrigger = false;
		CaseTriggerHelper.SkipTrigger = false;
	}

	static testMethod void testSupportContact() {
		Map<Id, Case> map_Cases = new Map<Id, Case>([SELECT Id, Origin, Channel__c, OwnerId FROM Case]);

		ZP_Company_Dedicated_Support_Contact__c supCont = new ZP_Company_Dedicated_Support_Contact__c();
		supCont.Company_Id__c = '111111111111';
		supCont.Dedicated_Support_Contact_Id__c = '1';
		supCont.Deleted_At__c = null;
		test.startTest();
		insert supCont;
		test.stopTest();

		Map<Id, Case> map_Cases2 = new Map<Id, Case>([SELECT Id, Origin, Channel__c, OwnerId FROM Case]);

		for (Id idCase : map_Cases2.keySet()) {
			Case objOriginalCase = map_Cases.get(idCase);
			Case objUpdatedCase = map_Cases2.get(idCase);
			if (objUpdatedCase.Origin == 'Chat' || (objUpdatedCase.Origin == 'Gusto' && objUpdatedCase.Channel__c == 'Chat')) {
				System.assertEquals(objOriginalCase.OwnerId, objUpdatedCase.OwnerId, 'Chat cases should not be routed');
			} else {
				System.assertNotEquals(objOriginalCase.OwnerId, objUpdatedCase.OwnerId);
			}
		}

		Account acc = [SELECT Id, Concierge_Group__c FROM Account WHERE ZP_Company_id__c = '111111111111'];
		system.assertEquals(null, acc.Concierge_Group__c);

		update supCont;
		delete supCont;
	}
}