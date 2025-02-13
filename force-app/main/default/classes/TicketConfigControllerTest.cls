/**
 * @name         : TicketConfigController
 * @author       : Praveen Sethu
 * @date         : 09-16-2020
 * @description  : Test class for TicketConfigController
 **/
@isTest
public class TicketConfigControllerTest {
	//Flag to indicate when to throw an exception
	public static Boolean blnThrowException = false;
	/**
	 * @Author      : Ankit CS
	 * @Description : This method creates all the test data
	 **/
	@testSetup
	static void setupData() {
		// Insert new company account
		Account objAccount = TestUtility.CompanyAccount();

		// Create a new Contact
		ContactTriggerHelper.skipTrigger = false;
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setEmail('testuer@abccompany.com')
			.setAccountId(objAccount.Id)
			.setFirstName('Test Contact')
			.setLastName('Test')
			.build();
		insert objContact;

		//Creating new Case
		Case objCase = new TestDataFactory.CaseBuilder().setRecordTypeId('Payroll Care').setAccountId(objAccount.Id).setContactId(objContact.Id).build();
		insert objCase;
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test method for loadTicketConfig()
	 **/
	@isTest
	static void testLoadTicketConfig() {
		Test.startTest();

		TicketConfigController.TicketConfigResponseWrapper objResponseWrapper = TicketConfigController.loadTicketConfig();
		System.assertEquals(true, objResponseWrapper.blnIsSuccess, 'Ticket Config Controller - Not able to load ticket config');

		Test.stopTest();
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test method for saveTicketConfig() & getTicketConfigInfo()
	 **/
	@isTest
	static void testSaveAndRetrieveTicketConfig() {
		Test.startTest();

		Case objCase = [SELECT Id FROM Case LIMIT 1];
		String strConfigJson =
			'[{"size":"6","overrideLabel":"","label":"Access to Care",' +
			+'"isVisible":null,"isRequired":false,"input":null,"criteriaList":null,"api":"Access_to_Care__c"},' +
			+'{"size":"6","overrideLabel":"","label":"Approved by Carrier?","isVisible":null,"isRequired":false,' +
			+'"input":null,"criteriaList":null,"api":"Approved_by_Carrier__c"}]';
		Ticket_Config__c objConfigToInsert = new Ticket_Config__c(Configuration_Json__c = strConfigJson, Ticket_Reason__c = 'Change Request', Is_Active__c = true);
		objConfigToInsert = TicketConfigController.saveTicketConfig(objConfigToInsert);
		//Assert if the Ticket Config was created successfully
		System.assert(objConfigToInsert.Id != null, 'Ticket_Config__c Id should not be null.');

		TicketConfigController.CreateTicketResponseWrapper objWrapper = TicketConfigController.getTicketConfigInfo('Change Request', '', objCase.Id);
		System.assertEquals(true, objWrapper.objTicketConfig != null, 'Ticket Config Controller - Unable to insert Ticket Config');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To cover catch blocks
	 **/
	@isTest
	static void testExceptions() {
		Test.startTest();

		blnThrowException = true;
		TicketConfigController.TicketConfigResponseWrapper objResponseWrapper = TicketConfigController.loadTicketConfig();
		System.assert(!objResponseWrapper.blnIsSuccess, 'Success boolean should be false.');

		String strConfigJson =
			'[{"size":"6","overrideLabel":"","label":"Access to Care",' +
			+'"isVisible":null,"isRequired":false,"input":null,"criteriaList":null,"api":"Access_to_Care__c"},' +
			+'{"size":"6","overrideLabel":"","label":"Approved by Carrier?","isVisible":null,"isRequired":false,' +
			+'"input":null,"criteriaList":null,"api":"Approved_by_Carrier__c"}]';
		Ticket_Config__c objConfigToInsert = new Ticket_Config__c(Configuration_Json__c = strConfigJson, Ticket_Reason__c = 'Change Request', Is_Active__c = true);
		objConfigToInsert = TicketConfigController.saveTicketConfig(objConfigToInsert);
		System.assert(objConfigToInsert == null, 'Ticket_Config__c should be null.');

		TicketConfigController.CreateTicketResponseWrapper objWrapper = TicketConfigController.getTicketConfigInfo('Change Request', '', null);
		System.assert(objWrapper.objTicketConfig == null, 'Ticket_Config__c should be null.');
		blnThrowException = false;

		Test.stopTest();
	}
}