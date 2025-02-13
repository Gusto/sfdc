/**
 * @description  Test Class for SendProductUpsellToExternalPartner
 * @author       Debasmita Rawooth
 * @date         30-04-2024
 **/
@istest
public class SendProductUpsellToExternalPartnerTest {
	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Creating test data
	 **/
	@testSetup
	static void setup() {
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		UserRole objRole = [SELECT Id FROM UserRole WHERE Name = 'Core & Complete'];
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('testusernew@gusto.com')
			.setFirstName('TestFirstName')
			.setLastName('TestLastName')
			.setEmail('testusernew@gusto.com')
			.setProfileId(objProfile.Id)
			.setUserRoleId(objRole.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('test')
			.setIsActive(true)
			.build();

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objCurrentUser) {
			insert objUser;
		}

		AccountTriggerHelper.skipTrigger = true;

		//create the Account
		Account objParentAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(LogSmartCallingUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Parent')
			.setBillingStreet('298 S. Ringo Street')
			.setBillingCity('Little Rock')
			.setBillingPostalCode('72201')
			.setBillingCountry('United States')
			.setPhone('501-555-5555')
			.setWebsite('www.testco.com')
			.setNumberOfActiveEEs(10)
			.setZPCompanyID('zpcompanyid01')
			.build();
		insert objParentAccount;

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(LogSmartCallingUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Co.')
			.setBillingStreet('298 S. Ringo Street')
			.setBillingCity('Little Rock')
			.setBillingPostalCode('72201')
			.setBillingCountry('United States')
			.setBillingState('California')
			.setPhone('501-555-5555')
			.setWebsite('www.testco.com')
			.setNumberOfActiveEEs(10)
			.setZPCompanyID('zpcompanyid02')
			.setParentAccount(objParentAccount.Id)
			.setNAICSCode('12345')
			.build();
		insert objCompanyAccount;

		ContactTriggerHelper.skipTrigger = true;
		//create a primary contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('PU')
			.setLastName('Test Positive')
			.setPhone('04802701314')
			.setEmail('testUser@yopmail.com')
			.build();

		insert objContact;

		//create a primary contact
		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objCompanyAccount.Id)
			.setLastName('Test Negative')
			.setPhone('04802701315')
			.setEmail('testUser2@yopmail.com')
			.build();

		insert objContact2;
	}

	/**
	 * @description Test sending Puroduct Upsell data to Humaninterest on creation
	 * @author      Debasmita Rawooth
	 **/
	@isTest
	static void testProductUpsellInsertHI() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE LastName = 'Test Positive' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE FirstName = 'TestFirstName' LIMIT 1];

		Partnership_Interest__c objProdUpsell = new TestDataFactory.ProductUpsellBuilder()
			.setContactId(objContact.Id)
			.setAccountId(objAccount.Id)
			.setNotes('Testing positive scenario.')
			.setTier('Not Discussed')
			.setOwnerId(objUser.Id)
			.build();
		insert objProdUpsell;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new GenerateSuccessCalloutMock());

		Test.startTest();
		SendProductUpsellToExternalPartner.RequestWrapper objWrapper = new SendProductUpsellToExternalPartner.RequestWrapper();
		SendProductUpsellToExternalPartner.sendPUToExternalPartner(
			new List<SendProductUpsellToExternalPartner.RequestWrapper>{ new SendProductUpsellToExternalPartner.RequestWrapper(objProdUpsell.Id, SendProductUpsellToExternalPartner.HUMAN_INTEREST) }
		);
		Test.stopTest();

		// assert that exception log is not created
		List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>(
			[SELECT Id, Class_Name__c, CreatedDate FROM Exception_Log__c WHERE Class_Name__c LIKE 'SendProductUpsellToExternalPartner%']
		);
		System.assertEquals(0, list_ExceptionLogs.size(), 'Callout resulted in exception.');
	}

	/**
	 * @description Test sending Puroduct Upsell data to Remote on creation
	 * @author      Debasmita Rawooth
	 **/
	@isTest
	static void testProductUpsellInsertRemote() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE LastName = 'Test Positive' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE FirstName = 'TestFirstName' LIMIT 1];

		Partnership_Interest__c objProdUpsell = new TestDataFactory.ProductUpsellBuilder()
			.setContactId(objContact.Id)
			.setAccountId(objAccount.Id)
			.setOwnerId(objUser.Id)
			.setNotes('Testing positive scenario.')
			.setTier('Not Discussed')
			.setProductInterestCountries('BQ;AW')
			.build();
		insert objProdUpsell;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new GenerateSuccessCalloutMock());

		Test.startTest();
		SendProductUpsellToExternalPartner.RequestWrapper objWrapper = new SendProductUpsellToExternalPartner.RequestWrapper();
		SendProductUpsellToExternalPartner.sendPUToExternalPartner(
			new List<SendProductUpsellToExternalPartner.RequestWrapper>{ new SendProductUpsellToExternalPartner.RequestWrapper(objProdUpsell.Id, SendProductUpsellToExternalPartner.REMOTE) }
		);
		Test.stopTest();

		// assert that exception log is not created
		List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>(
			[SELECT Id, Class_Name__c, CreatedDate FROM Exception_Log__c WHERE Class_Name__c LIKE 'SendProductUpsellToExternalPartner%']
		);
		System.assertEquals(0, list_ExceptionLogs.size(), 'Callout resulted in exception.');
	}

	/**
	 * @description Test sending Puroduct Upsell data to Guideline on creation
	 * @author      Debasmita Rawooth
	 **/
	@isTest
	static void testProductUpsellInsertGuideline() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE LastName = 'Test Positive' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE FirstName = 'TestFirstName' LIMIT 1];

		Partnership_Interest__c objProdUpsell = new TestDataFactory.ProductUpsellBuilder()
			.setContactId(objContact.Id)
			.setAccountId(objAccount.Id)
			.setOwnerId(objUser.Id)
			.setNotes('Testing positive scenario.')
			.setTier('Not Discussed')
			.setProductInterestCountries('BQ;AW')
			.build();
		insert objProdUpsell;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new GenerateSuccessCalloutMock());

		Test.startTest();
		SendProductUpsellToExternalPartner.RequestWrapper objWrapper = new SendProductUpsellToExternalPartner.RequestWrapper();
		SendProductUpsellToExternalPartner.sendPUToExternalPartner(
			new List<SendProductUpsellToExternalPartner.RequestWrapper>{ new SendProductUpsellToExternalPartner.RequestWrapper(objProdUpsell.Id, SendProductUpsellToExternalPartner.GUIDELINE) }
		);
		Test.stopTest();

		// assert that exception log is not created
		List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>(
			[SELECT Id, Class_Name__c, CreatedDate FROM Exception_Log__c WHERE Class_Name__c LIKE 'SendProductUpsellToExternalPartner%']
		);
		System.assertEquals(0, list_ExceptionLogs.size(), 'Callout resulted in exception.');
	}

	/**
	 * @description Test sending Puroduct Upsell data to NextInsurance on creation
	 * @author      Debasmita Rawooth
	 **/
	@isTest
	static void testProductUpsellInsertNextInsurance() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE LastName = 'Test Positive' LIMIT 1];
		Contact objSecContact = [SELECT Id FROM Contact WHERE LastName = 'Test Negative' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE FirstName = 'TestFirstName' LIMIT 1];

		Partnership_Interest__c objProdUpsell = new TestDataFactory.ProductUpsellBuilder()
			.setContactId(objContact.Id)
			.setAccountId(objAccount.Id)
			.setOwnerId(objUser.Id)
			.setNotes('Testing positive scenario.')
			.setTier('Not Discussed')
			.build();
		insert objProdUpsell;

		objProdUpsell.Secondary_Contact_from_Account__c = objSecContact.Id;
		update objProdUpsell;

		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new GenerateSuccessCalloutMock());

		Test.startTest();
		SendProductUpsellToExternalPartner.RequestWrapper objWrapper = new SendProductUpsellToExternalPartner.RequestWrapper();
		SendProductUpsellToExternalPartner.sendPUToExternalPartner(
			new List<SendProductUpsellToExternalPartner.RequestWrapper>{ new SendProductUpsellToExternalPartner.RequestWrapper(objProdUpsell.Id, SendProductUpsellToExternalPartner.NEXT_INSURANCE) }
		);
		Test.stopTest();

		// assert that exception log is not created
		List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>(
			[SELECT Id, Class_Name__c, CreatedDate FROM Exception_Log__c WHERE Class_Name__c LIKE 'SendProductUpsellToExternalPartner%']
		);
		System.assertEquals(0, list_ExceptionLogs.size(), 'Callout resulted in exception.');
	}

	/**
	 * @description Test sending Puroduct Upsell data to Humaninterest with insufficient data
	 * @author      Debasmita Rawooth
	 **/
	@isTest
	static void testProductUpsellInsertNegative() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE LastName = 'Test Negative' LIMIT 1];
		User objUser = [SELECT Id FROM User WHERE FirstName = 'TestFirstName' LIMIT 1];

		Partnership_Interest__c objProdUpsell = new TestDataFactory.ProductUpsellBuilder().setContactId(objContact.Id).setAccountId(objAccount.Id).setTier('Not Discussed').build();
		insert objProdUpsell;
		// Set mock callout class
		Test.setMock(HttpCalloutMock.class, new GenerateFailureCalloutMock());

		Test.startTest();
		SendProductUpsellToExternalPartner.RequestWrapper objWrapper = new SendProductUpsellToExternalPartner.RequestWrapper();
		SendProductUpsellToExternalPartner.sendPUToExternalPartner(
			new List<SendProductUpsellToExternalPartner.RequestWrapper>{ new SendProductUpsellToExternalPartner.RequestWrapper(objProdUpsell.Id, SendProductUpsellToExternalPartner.HUMAN_INTEREST) }
		);
		Test.stopTest();

		// assert that exception log is created
		List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>(
			[SELECT Id, Class_Name__c, CreatedDate FROM Exception_Log__c WHERE Class_Name__c LIKE 'SendProductUpsellToExternalPartner%']
		);
		System.assertEquals(1, list_ExceptionLogs.size(), 'Callout did not create an exception.');
	}

	/**
	 * Mock Response - Success
	 */
	public class GenerateSuccessCalloutMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest request) {
			HttpResponse objResponse = new HttpResponse();
			objResponse.setHeader('Content-Type', 'application/json');
			objResponse.setBody('{"status": "SUCCESS"}');
			objResponse.setStatusCode(200);
			return objResponse;
		}
	}

	/**
	 * Mock Response - Failure
	 */
	public class GenerateFailureCalloutMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest request) {
			HttpResponse objResponse = new HttpResponse();
			objResponse.setHeader('Content-Type', 'application/json');
			objResponse.setBody('{"status":"FAILURE","event_id":"5e811950-088b-11ef-b97f-0a09460a08a3","response":"Bad request"}');
			objResponse.setStatusCode(400);
			return objResponse;
		}
	}
}