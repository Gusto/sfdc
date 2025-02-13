@istest
public class CaseSearchExtensionTest {
	private static testMethod void testCaseSearch() {
		Account acc = TestUtility.CompanyAccount();

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		Case cse2 = new Case();
		cse2.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse2.AccountId = acc.Id;
		cse2.Subject = 'Test2';
		cse2.Description = 'Test2';
		insert cse2;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		CaseSearchExtension extension = new CaseSearchExtension(stdCase);
		extension.searchString = 'Test2';
		extension.searchCase();
		ApexPages.currentPage().getParameters().put('relatedCase', cse2.id);
		extension.linkCase();

		cse = [SELECT Id, Related_Case__c FROM Case WHERE id = :cse.id];
		System.assertEquals(cse2.id, cse.Related_Case__c);
		test.stopTest();
	}
}