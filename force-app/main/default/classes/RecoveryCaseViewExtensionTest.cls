@istest
public class RecoveryCaseViewExtensionTest {
	@isTest
	private static void testSaveRecoveryCase() {
		Account objAccount = TestUtility.CompanyAccount();
		objAccount.ZP_Company_ID__c = '1111111111';
		update objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setFirstName('RecovertTest')
			.setLastName('TestClass')
			.setAccountId(objAccount.Id)
			.setPhone('123456')
			.setZPUserId('5555')
			.build();
		insert objContact;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Recovery Cases');
		cse.AccountId = objAccount.Id;
		cse.ContactId = objContact.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.origin = 'Phone';
		insert cse;

		ZP_User_Role__c role = new ZP_User_Role__c();
		role.Company_Id__c = '1111111111';
		role.First_Name__c = 'First';
		role.Last_Name__c = 'Last';
		role.Phone__c = '1234567890';
		role.Type__c = 'Role::Signatory';
		role.User_Id__c = '5555';
		role.User_Permissions__c = 'full_access';
		insert role;

		test.startTest();
		ApexPages.currentPage().getParameters().put('id', cse.Id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
		RecoveryCaseViewExtension extension = new RecoveryCaseViewExtension(stdCase);
		cse = extension.theCase;
		cse.Requires_Action__c = true;
		extension.SaveRecoveryCase();

		cse = [SELECT Id, Requires_Action__c FROM Case WHERE Id = :cse.Id];
		System.assert(cse.Requires_Action__c, 'Requires_Action__c should be true.');
		test.stopTest();
	}
}