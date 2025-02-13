/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ZPNachaEntryReturnsQueueTest {
	@testsetup
	static void dataMethod() {
		ZP_User_Role__c roleRec = new ZP_User_Role__c();
		roleRec.User_Id__c = '0000999900001';
		roleRec.Company_Id__c = '00009999000011';
		roleRec.Type__c = 'Role:Signatory';
		insert roleRec;

		Account acc = TestUtility.CompanyAccount();
		acc.ZP_Company_ID__c = '0000999900001';
		update acc;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setPhone('999999124')
			.setFirstName('Test Contact')
			.setLastName('ZPNachaEntryQueue')
			.setAccountId(acc.id)
			.setEmail('ZPNachaEntry1@gusto.com')
			.setZPUserId('0000999900001')
			.build();

		insert objContact;
	}

	@isTest
	static void createNachaCaseRecTest() {
		Test.startTest();
		ZP_Nacha_Entry_Returns__c ZPRec = new ZP_Nacha_Entry_Returns__c();
		ZPRec.Event_Id__c = '3334445556';
		ZPRec.Event_Type__c = 'Payroll';
		ZPRec.Id__c = '9991110001';
		ZPRec.External_Key__c = 'zenpayroll-nacha_entry_return-9991110001';
		ZPRec.Error_Code__c = 'R011';
		ZPRec.Company_Id__c = '0000999900001';
		ZPRec.Amount__c = 110;
		insert ZPRec;
		ZPRec = [SELECT Id, External_Key__c FROM ZP_Nacha_Entry_Returns__c];
		System.assertEquals(
			ZPRec.External_Key__c,
			'zenpayroll-nacha_entry_return-9991110001',
			'The External_Key__c of ZP_Nacha_Entry_Returns__c records should be zenpayroll-nacha_entry_return-9991110001.'
		);
		test.stopTest();
	}
}