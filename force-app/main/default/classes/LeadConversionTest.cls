@isTest
private without sharing class LeadConversionTest {
	class ExpectedResult {
		Id leadId;
		Boolean expectedSuccess;

		Boolean createAccount = true;
		Boolean createContact = true;
		Boolean createOpportunity = true;

		Id expectedAccountId;
		Id expectedContactId;
		Id expectedOpportunityId;

		ExpectedResult(Id leadId, Boolean expectedSuccess) {
			this.leadId = leadId;
			this.expectedSuccess = expectedSuccess;
		}

		void setExpectedAccountId(Id accountId) {
			createAccount = false;
			this.expectedAccountId = accountId;
		}

		void setExpectedContactId(Id contactId) {
			createContact = false;
			this.expectedContactId = contactId;
		}

		void setExpectedOpportunityId(Id opportunityId) {
			createOpportunity = false;
			this.expectedOpportunityId = opportunityId;
		}
	}

	@isTest
	private static void standard_conversion_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST');
		insert testLead;

		ExpectedResult expectedResult = new ExpectedResult(testLead.Id, true);

		convert_assert(testLead, expectedResult);
	}

	@isTest
	private static void convert_existing_company_id_on_account_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', ZP_Company_ID__c = '12345');
		insert testLead;

		Account testAccount = new Account(Name = 'TEST', ZP_Company_ID__c = '12345');
		insert testAccount;

		ExpectedResult expectedResult = new ExpectedResult(testLead.Id, true);
		expectedResult.setExpectedAccountId(testAccount.Id);

		convert_assert(testLead, expectedResult);
	}

	@isTest
	private static void convert_existing_company_lead_id_on_account_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', ZP_Company_Lead_ID__c = '12345');
		insert testLead;

		Account testAccount = new Account(Name = 'TEST', ZP_Company_Lead_ID__c = '12345');
		insert testAccount;

		ExpectedResult expectedResult = new ExpectedResult(testLead.Id, true);
		expectedResult.setExpectedAccountId(testAccount.Id);

		convert_assert(testLead, expectedResult);
	}

	@isTest
	private static void convert_existing_email_on_contact_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', Email = 'test@email.com');
		insert testLead;

		Account testAccount = new Account(Name = 'TEST');
		insert testAccount;

		Contact testContact = new Contact(AccountId = testAccount.Id, FirstName = 'TEST', LastName = 'TEST', Email = 'test@email.com');
		insert testContact;

		ExpectedResult expectedResult = new ExpectedResult(testLead.Id, true);
		expectedResult.setExpectedAccountId(testAccount.Id);
		expectedResult.setExpectedContactId(testContact.Id);

		convert_assert(testLead, expectedResult);
	}

	@isTest
	private static void do_not_create_opportunity_with_existing_company_id_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', ZP_Company_ID__c = '12345');
		insert testLead;

		Account testAccount = new Account(Name = 'TEST');
		insert testAccount;

		Opportunity testOpportunity = new Opportunity(AccountId = testAccount.Id, Name = 'TEST', StageName = 'SAL', CloseDate = System.today(), ZP_Company_ID__c = '12345');
		insert testOpportunity;

		ExpectedResult expectedResult = new ExpectedResult(testLead.Id, true);
		expectedResult.setExpectedAccountId(testAccount.Id);
		expectedResult.setExpectedOpportunityId(null);

		convert_assert(testLead, expectedResult);
	}

	@isTest
	private static void transfer_company_id_to_account_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', ZP_Company_ID__c = '12345');
		insert testLead;
		transfer_to_sobject_test(testLead, 'Account', 'ZP_Company_ID__c', '12345');
	}

	@isTest
	private static void transfer_company_lead_id_to_account_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', ZP_Company_Lead_ID__c = '12345');
		insert testLead;
		transfer_to_sobject_test(testLead, 'Account', 'ZP_Company_Lead_ID__c', '12345');
	}

	@isTest
	private static void transfer_employees_to_account_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', NumberOfEmployees = 10);
		insert testLead;
		transfer_to_sobject_test(testLead, 'Account', 'NumberOfEmployees', 10);
	}

	@isTest
	private static void transfer_owner_to_account_test() {
		Id ownerId = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.Name LIKE :'%admin%' LIMIT 1][0].Id;
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', OwnerId = ownerId);
		insert testLead;
		transfer_to_sobject_test(testLead, 'Account', 'OwnerId', ownerId);
	}

	@isTest
	private static void transfer_lead_source_detail_to_account_test() {
		String testValue = 'TEST STRING';
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', Lead_Source_Detail__c = testValue);
		insert testLead;
		transfer_to_sobject_test(testLead, 'Account', 'Lead_Source_Detail__c', testValue);
	}

	@isTest
	private static void transfer_company_id_to_opportunities_test() {
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', ZP_Company_ID__c = '12345');
		insert testLead;
		transfer_to_sobject_test(testLead, 'Opportunity', 'ZP_Company_ID__c', '12345');
	}

	@isTest
	private static void transfer_employees_to_opportunity_test() {
		TriggerHandler.bypass('OpportunityTriggerHandler');
		TriggerHandler.bypass('LeadTriggerHandler');
		TriggerHandler.bypass('AccountTriggerHandler');

		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', NumberOfEmployees = 10);
		insert testLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Account testAccount = new Account(Name = 'TEST');
		insert testAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Opportunity testOpportunity = new Opportunity(AccountId = testAccount.Id, Name = 'TEST', NumberOfEmployees__c = 10, StageName = 'SAL', CloseDate = System.today(), ZP_Company_ID__c = '12345');
		insert testOpportunity;
		TriggerHandler.clearBypass('OpportunitytTriggerHandler');
		transfer_to_sobject_test(testLead, 'Opportunity', 'NumberOfEmployees__c', 10);
	}

	@isTest
	private static void transfer_owner_to_opportunity_test() {
		Id ownerId = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.Name LIKE :'%admin%' LIMIT 1][0].Id;
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', OwnerId = ownerId);
		insert testLead;
		transfer_to_sobject_test(testLead, 'Opportunity', 'OwnerId', ownerId);
	}

	@isTest
	private static void transfer_owner_to_contact_test() {
		Id ownerId = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.Name LIKE :'%admin%' LIMIT 1][0].Id;
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', OwnerId = ownerId);
		insert testLead;
		transfer_to_sobject_test(testLead, 'Contact', 'OwnerId', ownerId);
	}

	@isTest
	private static void transfer_email_to_contact_test() {
		String emailAddress = 'test@email.com';
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', Email = emailAddress);
		insert testLead;
		transfer_to_sobject_test(testLead, 'Contact', 'Email', emailAddress);
	}

	/**
	 * @author David Schach
	 * @description Testing change of owner to check that converted record owners match
	 * @param none
	 */
	@isTest
	private static void ownership_test() {
		Id ownerId = [SELECT Id FROM User WHERE IsActive = TRUE AND Is_Api_Integration__c = FALSE AND UserRole.Name LIKE 'sales%' LIMIT 1][0].Id;
		System.assertNotEquals(null, ownerId);

		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', OwnerId = ownerId);
		insert testLead;

		LeadConversion.ConversionResult conversionResult = run_conversion_test(testLead);

		Database.LeadConvertResult convertResult = conversionResult.convertResults[0];
		System.assert(convertResult.isSuccess());

		Id actualAccountOwnerId = [SELECT OwnerId FROM Account WHERE Id = :convertResult.accountId LIMIT 1][0].OwnerId;
		System.assertEquals(ownerId, actualAccountOwnerId);

		Id actualOpportunityOwnerId = [SELECT OwnerId FROM Opportunity WHERE Id = :convertResult.opportunityId LIMIT 1][0].OwnerId;
		System.assertEquals(ownerId, actualOpportunityOwnerId);

		Id actualContactOwnerId = [SELECT OwnerId FROM Contact WHERE Id = :convertResult.contactId LIMIT 1][0].OwnerId;
		System.assertEquals(ownerId, actualContactOwnerId);
	}

	static LeadConversion.ConversionResult run_conversion_test(Lead testLead) {
		List<Lead> testLeads = new List<Lead>{ testLead };

		User zenpayrollUser = [SELECT Id FROM User WHERE Profile.Name = 'ZP API Connection' AND IsActive = TRUE LIMIT 1][0];
		System.assertNotEquals(null, zenpayrollUser);

		LeadConversion.ConversionResult conversionResult;
		System.runAs(zenpayrollUser) {
			Test.startTest();
			conversionResult = LeadConversion.convert(testLeads);
			Test.stopTest();
		}

		return conversionResult;
	}

	private static void convert_assert(Lead testLead, ExpectedResult expectedResult) {
		LeadConversion.ConversionResult conversionResult = run_conversion_test(testLead);

		for (Database.LeadConvertResult convertResult : conversionResult.convertResults) {
			expected_result_assert(convertResult, expectedResult);
		}
	}

	private static void expected_result_assert(Database.LeadConvertResult convertResult, ExpectedResult expectedResult) {
		Id leadId = convertResult.getLeadId();

		Boolean actualSuccess = convertResult.isSuccess();
		System.assertEquals(expectedResult.expectedSuccess, convertResult.isSuccess());

		converted_account_assert(convertResult, expectedResult);
		converted_contact_assert(convertResult, expectedResult);
		converted_opportunity_assert(convertResult, expectedResult);
	}

	private static void converted_account_assert(Database.LeadConvertResult convertResult, ExpectedResult expectedResult) {
		Id actualAccountId = convertResult.getAccountId();
		create_assert(expectedResult.createAccount, expectedResult.expectedAccountId, actualAccountId);
	}

	private static void converted_contact_assert(Database.LeadConvertResult convertResult, ExpectedResult expectedResult) {
		Id actualContactId = convertResult.getContactId();
		create_assert(expectedResult.createContact, expectedResult.expectedContactId, actualContactId);
	}

	private static void converted_opportunity_assert(Database.LeadConvertResult convertResult, ExpectedResult expectedResult) {
		Id actualOpportunityId = convertResult.getOpportunityId();
		create_assert(expectedResult.createOpportunity, expectedResult.expectedOpportunityId, actualOpportunityId);
	}

	private static void create_assert(Boolean create, Id expectedId, Id actualId) {
		if (create) {
			System.assertNotEquals(expectedId, actualId);
		} else {
			System.assertEquals(expectedId, actualId);
		}
	}

	/**
	 * @author David Schach
	 * @description transfer_to_sobject_test description
	 * @param  testLead          testLead to be checked
	 * @param  objectName        objeObject to check against
	 * @param  expectedFieldName expeField to check
	 * @param  expectedValue     expeExpected value
	 * @todo   Remove this method and perform query explicitly in each test method
	 */
	private static void transfer_to_sobject_test(Lead testLead, String objectName, String expectedFieldName, Object expectedValue) {
		LeadConversion.ConversionResult conversionResult = run_conversion_test(testLead);
		String queryString = 'SELECT ' + expectedFieldName + ' FROM ' + objectName + ' LIMIT 1';
		SObject result = Database.query(queryString)[0];
		Object actualValue = result.get(expectedFieldName);
		System.assertEquals(expectedValue, actualValue);
	}

	private static void existing_opportunity_test() {
		TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('OpportunityTriggerHandler');
		Lead testLead = new Lead(FirstName = 'TEST', LastName = 'TEST', Company = 'TEST', ZP_Company_ID__c = '12345');
		insert testLead;

		Account testAccount = new Account(Name = 'TEST');
		insert testAccount;

		Opportunity testOpportunity = new Opportunity(AccountId = testAccount.Id, Name = 'TEST', StageName = 'SAL', NumberOfEmployees__c = 10, CloseDate = System.today(), ZP_Company_ID__c = '12345');
		insert testOpportunity;

		Map<String, Object> expectedOpportunityFieldValues;

		run_conversion_test(testLead);

		List<String> fields = new List<String>(expectedOpportunityFieldValues.keySet());

		String queryString = 'SELECT ' + String.join(fields, ',') + ' FROM Opportunity';

		List<Opportunity> results = Database.query(queryString);
		System.assertEquals(1, results.size());
	}

	/**
	 * @author Praveen Sethu
	 * Asserts Test if reseller lead is converted based on existing account with firm id
	 **/
	@isTest
	static void testResellerLeadConversionBasedOnFirmId() {
		LeadTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@gmail.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('In-app')
			.build();
		insert objLead;

		Account objResellerAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Reseller Account')
			.setZPFirmId('4561111111')
			.setNormalizedEmailDomain('resellerlead.com')
			.build();
		insert objResellerAcc;
		LeadTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = false;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder().setZPFirmId(objResellerAcc.ZP_Firm_Id__c).setEmail(objLead.Email).setName('test name').build();
		insert objZPAccFirm;
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted);
		System.assertEquals(objResellerAcc.Id, objLeadAssert.ConvertedAccountId);
		System.assertNotEquals(null, objLeadAssert.ConvertedContactId);
		// Assert opportunity is not created for reseller leads
		System.assertEquals(null, objLeadAssert.ConvertedOpportunityId);
	}
}