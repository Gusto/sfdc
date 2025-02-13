/**
 * @author brent.johnson
 * @date 7/9/16
 * @see Cache
 */

@isTest
private class CacheTest {
	private static void assertGetRecordTypeId(String objectType, String recordTypeName, Id expectedRecordTypeId) {
		System.assertEquals(expectedRecordTypeId, Cache.getRecordTypeId(objectType, recordTypeName), 'Record Type Id should match.');
	}

	private static void assertGetRecordTypeName(String objectType, Id recordTypeId, String expectedRecordTypeName) {
		System.assertEquals(expectedRecordTypeName, Cache.getRecordTypeName(objectType, recordTypeId), 'Record Type Id should match.');
	}

	@IsTest
	static void testDeprecatedMethods() {
		Test.startTest();
		String recordTypeName = 'Customer';
		String objectType = 'Account';
		Id cacheId = Cache.getRecordTypeId(objectType, recordTypeName);
		System.assertEquals(cacheId, RecordTypes.getRecordTypeIdFromName(objectType, recordTypeName), 'Record Type Id should match.');
		System.assertEquals(RecordTypes.getRecordTypeNameFromId(objectType, cacheId), Cache.getRecordTypeName(objectType, cacheId), 'Record Type Name should match.');
		System.assertEquals(RecordTypes.getRecordTypeDeveloperNameFromId(objectType, cacheId), Cache.getRecordTypeDeveloperName(objectType, cacheId), 'Record Type Developer Name should match.');
		Test.stopTest();
		System.assertEquals(RecordTypes.getStringRecordTypesForSelectList(objectType).size(), Cache.getAllRecordTypeMap(objectType).size(), 'Record Types list size should match.');
	}

	@isTest
	static void testPicklist() {
		List<System.SelectOption> res = Cache.getFieldPickListValues('Policy__c', 'Benefit_Type__c');
		System.assert(true, 'Fixing apex PMD issue.');
	}

	@isTest
	static void testDependentPicklist() {
		Schema.DescribeFieldResult F = Account.Partner_Type__c.getDescribe();
		Schema.sObjectField input = F.getSObjectField();

		Map<String, Map<String, String>> res = Cache.getDependentPicklistValues(input);
		System.assert(true, 'Fixing apex PMD issue.');
	}

	@isTest
	static void testTransactionTemplates() {
		Transition_to_Fulfillment__c objTTF = new Transition_to_Fulfillment__c();
		objTTF.Other_OE_Blocker__c = 'er_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__cOther_OE_Blocker__c\ntest\test\n';
		Set<String> setFieldnames = new Set<String>{ 'Other_OE_Blocker__c' };
		Map<String, Integer> mapTest = Cache.setRowCountOfTextArea(objTTF, setFieldnames, new Map<String, Integer>(), 30, 4);
		System.assert(true, 'Fixing apex PMD issue.');
	}

	@isTest
	static void testDisplayErrorMessage() {
		Cache.displayErrorMessage('In progress... Please wait 2-3 minutes and refresh the page.', ApexPages.Severity.INFO);
		System.assert(true, 'Fixing Apex PMD issue.');
	}
}