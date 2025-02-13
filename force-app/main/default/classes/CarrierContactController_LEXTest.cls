@isTest
public class CarrierContactController_LEXTest {
	static testMethod void testGetContactData() {
		//To get the contacts related to the carrier Account

		Account objAccount = new Account(Name = 'Test');
		insert objAccount;
		Contact objContact = new Contact(AccountId = objAccount.Id, LastName = 'Test', FirstName = 'test');
		insert objContact;
		Test.startTest();
		List<Contact> list_contact = CarrierContactLookupController_LEX.getContacts('test', objAccount.Id);
		System.assertEquals(true, list_contact.size() > 0);
		Test.stopTest();
	}
}