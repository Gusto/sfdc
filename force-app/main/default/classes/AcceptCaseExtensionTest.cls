@isTest
public class AcceptCaseExtensionTest {
	@isTest
	private static void testSaveMFAuditCase() {
		Account acc = TestUtility.CompanyAccount();

		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		Case cse = new Case();
		cse.setOptions(dmo);
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Sales Cases');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		AcceptCaseExtension extension = new AcceptCaseExtension(stdCase);
		cse = extension.theCase;
		extension.acceptCase();

		cse = [SELECT id, ownerid FROM case WHERE id = :cse.Id];
		System.assert(cse.OwnerId == UserInfo.getUserId(), 'Current User should be the owner.');

		extension.acceptCase();

		extension.backToCase();
		Test.stopTest();
	}
}