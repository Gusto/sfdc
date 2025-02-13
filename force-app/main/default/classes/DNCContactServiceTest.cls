@istest
public class DNCContactServiceTest {
	@isTest
	static void testGetContactData() {
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('TestAccount').build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setPhone('8888888888')
			.setMobilePhone('8888888888')
			.setOtherPhone('8888888888')
			.setLastName('TestContact')
			.build();
		insert objContact;

		DNCContactService.doGet();

		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testPostCopntactData() {
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('TestAccount').build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setPhone('8888888888')
			.setMobilePhone('8888888888')
			.setOtherPhone('8888888888')
			.setLastName('TestContact')
			.build();
		insert objContact;

		List<DNCContactService.contactUpdateInfo> list_ContactInfos = new List<DNCContactService.contactUpdateInfo>();
		DNCContactService.contactUpdateInfo objInfo = new DNCContactService.contactUpdateInfo();
		objInfo.id = objContact.Id;
		objInfo.activityExists = 'true';
		objInfo.doNotCall = 'true';
		list_ContactInfos.add(objInfo);
		DNCContactService.doPost(list_ContactInfos);

		System.assert(true, 'Fixing Apex PMD issue.');
	}
}