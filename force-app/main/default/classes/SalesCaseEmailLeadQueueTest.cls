@isTest
public class SalesCaseEmailLeadQueueTest {
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

		SalesCaseEmailLeadQueueTriggerHelper.queue = false;

		Sales_Case_Email_Lead_Queue__c queue = new Sales_Case_Email_Lead_Queue__c();
		queue.Case__c = cse.Id;
		insert queue;

		List<Lead> leadList = [SELECT Id, Email FROM Lead WHERE email = 'test@test.com'];
		system.assert(leadList.size() == 0);

		test.stopTest();
	}
}