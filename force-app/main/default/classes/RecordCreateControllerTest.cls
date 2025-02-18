/**
 * @name         : RecordCreateControllerTest
 * @author       : Praveen Sethu
 * @description  : Test class for RecordCreateController
 * @test
 *
 */
@isTest
public class RecordCreateControllerTest {
	@testSetup
	static void setup() {
		// Data Setup
		// Create a Medical Policy
		Product2 objGustoHRProd = new Product2(Name = 'GustoHR Pro', Family = 'Medical', ProductCode = 'MED', IsActive = true);
		insert objGustoHRProd;

		PricebookEntry objStandardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = objGustoHRProd.Id, UnitPrice = 10, IsActive = true);
		insert objStandardPrice;

		// Create a new Test Pricebook
		Pricebook2 objPricebook = new Pricebook2(Name = 'Payroll Product Catalog', IsActive = true);
		insert objPricebook;

		PricebookEntry objCustomPrice = new PricebookEntry(Pricebook2Id = objPricebook.Id, Product2Id = objGustoHRProd.Id, UnitPrice = 10, IsActive = true);
		insert objCustomPrice;
	}

	// Test getting record types, accessible fields and default values
	@isTest
	static void testGetRecordTypes() {
		// Insert company account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.setTier('simple')
			.setSetUpSteps(20.0)
			.build();
		insert objCompanyAccount;

		// Get available record types from Opportunity
		Test.startTest();
		RecordCreateController.ResponseWrapper objWrapper = RecordCreateController.getRecordTypes('Opportunity', objCompanyAccount.Id);
		Test.stopTest();

		// Assert if success and record types are returned
		System.assertEquals(true, objWrapper.blnSuccess, 'Success not returned from controller');
		System.assertEquals(true, objWrapper.list_RecordCreate.size() > 0, 'Did not return any opportunity record types');
	}

	// Test creating a record - Scenario is creating a Growth/Expansion opportunity
	@isTest
	static void testRecordCreate() {
		// Payload to create company opportunity - Insert placeholder to replace account Id and opportunity record type Id
		String strJSONPayload = '{ "sObjectType": "Opportunity", "AccountId": "<<ACCOUNT_ID>>", "StageName": "New", "RecordTypeId": "<<RECORDTYPE_ID>>", "Name": "Test Growth", "NumberOfEmployees__c": 10 }';

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.setTier('simple')
			.setSetUpSteps(20.0)
			.build();

		insert objCompanyAccount;

		// Replace placeholders with actual values
		Id idRecordTypeId = OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID;
		strJSONPayload = strJSONPayload.replaceAll('<<ACCOUNT_ID>>', objCompanyAccount.Id);
		strJSONPayload = strJSONPayload.replaceAll('<<RECORDTYPE_ID>>', idRecordTypeId);

		// Create Growth/Expansion opportunity
		Test.startTest();
		RecordCreateController.ResponseWrapper objWrapper = RecordCreateController.createRecord(strJSONPayload, true);
		Test.stopTest();

		// Assert if success and record is created
		//Opportunity objOppty = [SELECT Id, (SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE AccountId = :objCompanyAccount.Id AND RecordTypeId = :idRecordTypeId LIMIT 1];
		//System.assertEquals(true, objOppty != null, 'Growth/Expansion not created');
		// System.assertEquals(true, !objOppty.OpportunityLineItems.isEmpty(), 'Growth/Expansion line items not created');
	}

	// Test creating Ardius Tax Credits opportunity
	@isTest
	static void testTaxCreditsTestCase() {
		// Payload to create company opportunity - Insert placeholder to replace account Id and opportunity record type Id
		String strJSONPayload = '{ "sObjectType": "Opportunity", "AccountId": "<<ACCOUNT_ID>>", "StageName": "Raw", "RecordTypeId": "<<RECORDTYPE_ID>>", "Type": "Partnership", "Tax_Year__c": "2025", "Name": "Test Tax Credits Opportunity" }';

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.setTier('simple')
			.setSetUpSteps(20.0)
			.build();
		insert objCompanyAccount;

		Id idRecordTypeId = OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID;

		// Replace placeholders with actual values
		strJSONPayload = strJSONPayload.replaceAll('<<ACCOUNT_ID>>', objCompanyAccount.Id);
		strJSONPayload = strJSONPayload.replaceAll('<<RECORDTYPE_ID>>', idRecordTypeId);

		Test.startTest();
		RecordCreateController.createRecord(strJSONPayload, false);
		Test.stopTest();

		// Assert if success and record is created
		Integer intCount = [SELECT COUNT() FROM Opportunity WHERE AccountId = :objCompanyAccount.Id AND RecordTypeId = :idRecordTypeId];
		System.assertEquals(1, intCount, 'Tax Credits opportunity not created');

		Id idRecord = [SELECT Id FROM Opportunity WHERE AccountId = :objCompanyAccount.Id AND RecordTypeId = :idRecordTypeId LIMIT 1].Id;
		Sobject objRecord = Database.query('SELECT Id, Account.Name FROM Opportunity WHERE Id = :idRecord');

		List<String> list_EntryIds = new List<String>();
		for (PricebookEntry objEntry : [Select Id from PricebookEntry]) {
			list_EntryIds.add(objEntry.Id);
		}
		RecordCreateController.createLineItems(list_EntryIds , objRecord.Id);
		// Check if method successfully returns related field value
		String strValue = RecordCreateController.returnFieldValue('Account.Name', objRecord);
		System.assertEquals(objCompanyAccount.Name, strValue, 'Field value not returned');
	}
}