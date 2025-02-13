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
private class TaxOpsFailedFilingTriggerHelperTest {
	@TestSetup
	static void myUnitTest() {
		Account acc = TestUtility.CompanyAccount();

		list<Contact> list_Contacts = new List<Contact>();

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.Id)
			.setFirstName('TestContact')
			.setLastName('Test')
			.setEmail('taxopsfailedfiling@gusto1.com')
			.setPhone('1234567')
			.build();
		list_Contacts.add(objContact);

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.Id)
			.setFirstName('Test2Contact')
			.setLastName('Test2')
			.setEmail('taxopsfailedfiling2@gusto1.com')
			.setPhone('123456')
			.build();
		list_Contacts.add(objContact2);

		insert list_Contacts;

		list<ZP_User__c> zpUserList = new List<ZP_User__c>();

		ZP_User__c zpUser1 = new ZP_User__c();
		zpUser1.id__c = 'TaxOpsZPUser1';
		zpUser1.email__c = 'taxopsfailedfiling@gusto1.com';
		zpUser1.Created_At__c = System.now().adddays(-5);
		zpUser1.Updated_At__c = System.now().adddays(-1);
		zpUser1.Name = 'TestZPUser1';
		zpUserList.add(zpUser1);

		ZP_User__c zpUser2 = new ZP_User__c();
		zpUser2.id__c = 'TaxOpsZPUser2';
		zpUser2.email__c = 'taxopsfailedfiling2@gusto.com';
		zpUser2.Created_At__c = System.now().adddays(-4);
		zpUser2.Updated_At__c = System.now().adddays(-1);
		zpUser2.Name = 'TestZPUser2';
		zpUserList.add(zpUser2);

		insert zpUserList;

		list<ZP_User_Role__c> zpUserRoleList = new List<ZP_User_Role__c>();
		ZP_User_Role__c zpUserRole1 = new ZP_User_Role__c();
		zpUserRole1.Type__c = 'Role::PayrollAdmin';
		zpUserRole1.User_Id__c = 'TaxOpsZPUser1';
		zpUserRole1.Company_Id__c = 'TestTaxOps12345';
		zpUserRole1.Is_Primary__c = true;
		zpUserRoleList.add(zpUserRole1);

		ZP_User_Role__c zpUserRole2 = new ZP_User_Role__c();
		zpUserRole2.Type__c = 'Role::PayrollAdmin';
		zpUserRole2.User_Id__c = 'TaxOpsZPUser2';
		zpUserRole2.Company_Id__c = 'TestTaxOps12345';
		zpUserRoleList.add(zpUserRole2);

		insert zpUserRoleList;

		User usr = [SELECT id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(usr) {
			Test.startTest();
			createEmailTemplate();
			Test.stopTest();
		}
	}

	@isTest
	static void insertTaxOpsFailedFilings() {
		Test.startTest();
		list<Account> accList = [SELECT id FROM Account];
		list<ZP_User_Role__c> roleList = [SELECT id FROM ZP_User_Role__c];
		System.assert(roleList.size() == 2, 'There should be 2 ZP_User_Role__c records in list.');

		list<Contact> list_Contacts = [SELECT id FROM Contact];
		System.assert(list_Contacts.size() == 2, 'There should be 2 Contacts in list.');

		Tax_Ops_Failed_Filing__c filingRec = new Tax_Ops_Failed_Filing__c();
		filingRec.ZP_Company_Id__c = 'TestTaxOps12345';
		filingRec.Account__c = accList.get(0).id;
		filingRec.Email_Template_Unique_Name__c = 'Test_TaxOps_Email_TEmplate_TaxOps123321';
		TaxOpsFailedFilingTriggerHelper.skipTrigger = false;
		insert filingRec;

		TaxOpsFailedFilingTriggerHelper.skipTrigger = false;
		update filingRec;

		TaxOpsFailedFilingTriggerHelper.skipTrigger = false;
		delete filingRec;
		Test.stopTest();
	}

	@future
	private static void createEmailTemplate() {
		EmailTemplate validEmailTemplate = new EmailTemplate();
		validEmailTemplate.isActive = true;
		validEmailTemplate.Name = 'Test TaxOps Email TEmplate';
		validEmailTemplate.DeveloperName = 'Test_TaxOps_Email_TEmplate_TaxOps123321';
		validEmailTemplate.TemplateType = 'text';
		validEmailTemplate.FolderId = UserInfo.getUserId();
		insert validEmailTemplate;
	}
}