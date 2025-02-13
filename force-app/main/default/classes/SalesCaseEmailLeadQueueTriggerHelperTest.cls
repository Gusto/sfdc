@isTest
public class SalesCaseEmailLeadQueueTriggerHelperTest {
	static testMethod void testWithSuppliedEmail() {
		Account acc = TestUtility.CompanyAccount();

		test.startTest();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Sales Cases');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		String descritpion = '';
		descritpion += '\nEmail address: test@test.com';
		descritpion += '\nFirst Name: FirstName';
		descritpion += '\nLast Name: LastName';
		cse.Description = descritpion;
		cse.Type = 'Sales Email';
		cse.SuppliedEmail = 'test@test.com';
		cse.SuppliedName = 'Test Test';
		insert cse;

		SalesCaseEmailLeadQueueTriggerHelper.queue = true;

		Sales_Case_Email_Lead_Queue__c queue = new Sales_Case_Email_Lead_Queue__c();
		queue.Case__c = cse.Id;
		insert queue;

		Lead l = [SELECT Id, Email FROM Lead WHERE email = 'test@test.com'];
		system.assert(l.Email == 'test@test.com');

		test.stopTest();

		//delete cse;
	}

	static testMethod void testWithOutSuppliedEmail() {
		Account acc = TestUtility.CompanyAccount();

		test.startTest();

		SalesCaseEmailLeadQueueTriggerHelper.queue = true;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Sales Cases');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		String descritpion = '';
		descritpion += '\r\nEmail address: test111@test.com';
		descritpion += '\r\nFirst name: FirstName';
		descritpion += '\r\nLast name: LastName';
		cse.Description = descritpion;
		cse.Type = 'Sales Email';
		insert cse;

		//Sales_Case_Email_Lead_Queue__c queue = new Sales_Case_Email_Lead_Queue__c();
		//queue.Case__c = cse.Id;
		//insert queue;

		Lead l = [SELECT Id, Email FROM Lead WHERE email = 'test111@test.com'];
		system.assert(l.Email == 'test111@test.com');

		Sales_Case_Email_Lead_Queue__c queue = [SELECT Id FROM Sales_Case_Email_Lead_Queue__c];
		update queue;
		delete queue;

		test.stopTest();

		//delete cse;
	}
}