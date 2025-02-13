/**
 * @description       :
 * @author            : Nigam Goyal
 * @group             :
 * @last modified on  : 07-27-2022
 * @last modified by  : Nigam Goyal
 **/
@isTest
public with sharing class ComLookupControllerTest {
	@testSetup
	static void testSetup() {
		Account objAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		insert objAccnt;

		// Creating Company Account
		Account objAccnt1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company \'s 2').setZPCompanyId('1111111112').build();
		insert objAccnt1;

		// Creating Company Contact
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setFirstName('Test First\' Name1')
			.setLastName('Test Last\' Name1')
			.setEmail('newmember17@campaign.com')
			.setNormalizedPhone('1876543211')
			.build();
		insert objContact1;

		// Creating Company Contact
		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setLastName('Test Contact233')
			.setEmail('newmember881@campaign.com')
			.setNormalizedPhone('1876543211')
			.build();
		insert objContact2;

		// Creating Company Contact
		Contact objContact3 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setLastName('Test Contact1')
			.setEmail('newmember9881@campaign.com')
			.setNormalizedPhone('1876543211')
			.build();
		insert objContact3;
	}

	@isTest
	static void getTitleFieldTest() {
		Map<Id, Account> map_Accounts = new Map<Id, Account>([SELECT Id FROM Account]);
		List<String> list_AccountIds = new List<String>();
		for (Id idAccountId : map_Accounts.keySet()) {
			list_AccountIds.add(idAccountId);
		}
		List<String> list_QueryFieldApiNames = new List<String>();
		list_QueryFieldApiNames.add('Name');
		ComLookupController.getSelectedRecordsList('Account', '', 'Id', list_AccountIds, list_QueryFieldApiNames);
	}

	@IsTest
	static void getSelectedRecordsList() {
		Map<Id, Account> map_Accounts = new Map<Id, Account>([SELECT Id FROM Account]);
		List<String> list_AccountIds = new List<String>();
		for (Id idAccountId : map_Accounts.keySet()) {
			list_AccountIds.add(idAccountId);
		}
		List<String> list_QueryFieldApiNames = new List<String>();
		list_QueryFieldApiNames.add('Name');
		Test.startTest();
		ComLookupController.SObjectListAndObjLabel objSObjectListAndLabel = ComLookupController.getSelectedRecordsList('Account', 'Name', 'Id', list_AccountIds, list_QueryFieldApiNames);

		ComLookupController.getSobjectName(list_AccountIds);
		Test.stopTest();
		System.assert(objSObjectListAndLabel.list_Sobjects.size() == 2, 'sObjectList should be returned');
		System.assert(objSObjectListAndLabel.strLabel == 'Account', 'SobjectLabel Account should be returned');
		Boolean blnExceptionOccurred = false;
		try {
			ComLookupController.getSelectedRecordsList('Contct', 'Nam', 'Id', null, null);
		} catch (Exception e) {
			blnExceptionOccurred = true;
		}
		System.assert(blnExceptionOccurred, 'An Exception was not thrown');
	}

	@IsTest
	static void getRecordsList_Test() {
		List<Contact> list_Contacts = new List<Contact>();
		list_Contacts = [SELECT Id FROM Contact LIMIT 1];
		List<String> list_ContactIds = new List<String>();

		if (list_Contacts.size() > 0) {
			list_ContactIds.add(list_Contacts[0].Id);
		}
		List<String> list_QueryFieldApiName = new List<String>();
		list_QueryFieldApiName.add('FirstName');
		List<SObject> list_SobjList = ComLookupController.getRecordsList('Contact', 'Name', 'Id', 'Name', 'Test', list_ContactIds, null, list_QueryFieldApiName);

		System.assert(list_SobjList.size() == 2, 'sObjList having one Records should be returned');
		Boolean blnExceptionOccurred = false;
		try {
			ComLookupController.getRecordsList('Contact', 'Name', 'I', 'Name', 'Test', list_ContactIds, null, null);
		} catch (Exception e) {
			blnExceptionOccurred = true;
		}
		System.assert(blnExceptionOccurred, 'An Exception was not thrown');
	}

	@IsTest
	static void getCoverDifferentCases_Test() {
		System.assertEquals(ComLookupUtil.CASE_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('case'), 'Did Not Match');
		System.assertEquals(ComLookupUtil.TASK_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('task'), 'Did Not Match');
		System.assertEquals(ComLookupUtil.EVENT_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('event'), 'Did Not Match');
		System.assertEquals(ComLookupUtil.ASSET_RELATIONSHIP_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('assetrelationship'), 'Did Not Match');
		System.assertEquals(ComLookupUtil.KNOWLEDGE_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('knowledge__kav'), 'Did Not Match');
		System.assertEquals(ComLookupUtil.EMAILMESSAGE_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('emailmessage'), 'Did Not Match');
		System.assertEquals(ComLookupUtil.CONTENTDOCUMENT_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('contentdocument'), 'Did Not Match');
		System.assertEquals(ComLookupUtil.CONTENTVERSION_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('contentversion'), 'Did Not Match');
		System.assertEquals(ComLookupUtil.DEFAULT_OBJECT_TITLE_FIELDNAME, ComLookupController.selectTitleFieldApiName('account'), 'Did Not Match');
	}
}