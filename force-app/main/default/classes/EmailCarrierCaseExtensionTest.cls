@istest
public class EmailCarrierCaseExtensionTest {
	private static testMethod void testCaseExtension() {
		Account acc = TestUtility.CompanyAccount();

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		EmailCarrierCaseExtension extension = new EmailCarrierCaseExtension(stdCase);

		test.stopTest();
	}

	private static testMethod void testCaseExtensionWithCarrier() {
		Account acc = TestUtility.CompanyAccount();

		Carrier__c carrier = new Carrier__c();
		carrier.Name = 'Test';
		carrier.Submission_Email__c = 'test@test.com';
		insert carrier;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.Carrier__c = carrier.Id;
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		EmailCarrierCaseExtension extension = new EmailCarrierCaseExtension(stdCase);

		test.stopTest();
	}
	private static testMethod void testEmailActionForContinuationTerminationCases() {
		Account acc = TestUtility.CompanyAccount();

		Carrier__c carrier = new Carrier__c();
		carrier.Name = 'Test';
		carrier.Submission_Email__c = 'test@test.com';
		insert carrier;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF Termination');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'Continuation Termination';
		cse.Carrier__c = carrier.Id;
		insert cse;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		EmailCarrierCaseExtension extension = new EmailCarrierCaseExtension(stdCase);
		system.assert(String.isNotBlank(extension.strFromEmailAddresses) && extension.strFromEmailAddresses.containsIgnoreCase('cobra@gusto.com'));
		test.stopTest();
	}
}