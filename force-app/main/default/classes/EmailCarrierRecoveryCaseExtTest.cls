@istest
public class EmailCarrierRecoveryCaseExtTest {
	private static testMethod void testCaseExtension() {
		CaseTeamRole ctr = [SELECT Id, Name FROM CaseTeamRole WHERE Name = 'Customer Contact' LIMIT 1];

		Account acc = TestUtility.CompanyAccount();
		Contact c = new Contact(LastName = 'Test contact', Email = 'TestconGusto123@gmail.com');
		insert c;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.ContactId = c.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		insert cse;

		CaseTeamMember objTeamMember = new CaseTeamMember(ParentId = cse.Id, MemberId = c.Id, TeamRoleId = ctr.id);
		insert objTeamMember;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		EmailCarrierRecoveryCaseExtension extension = new EmailCarrierRecoveryCaseExtension(stdCase);

		Test.stopTest();
	}
}