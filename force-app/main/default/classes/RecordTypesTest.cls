/**
 * Test class for RecordTypes.cls
 * We test nonexistent object names, nonexistent record type names, null values, and existing Account record type (if available)
 *
 * @author Evan Callahan
 * @since  2010
 * @author David Schach
 * @see RecordTypes
 * @group Utilities
 */
@IsTest
public with sharing class RecordTypesTest {
	@isTest
	static void testRecTypes() {
		//Test with Bogus object

		System.assertEquals(null, RecordTypes.getRecordType('Bogus', null));

		System.AssertEquals(null, RecordTypes.getRecordTypeIdFromName('Bogust', 'Bogus'));
		System.AssertEquals(null, RecordTypes.getRecordTypeDeveloperNameFromName('Bogust', 'Bogus'));

		System.AssertEquals(null, RecordTypes.getRecordTypeNameFromDeveloperName('Bogus', 'Bogus'));
		System.AssertEquals(null, RecordTypes.getRecordTypeIdFromDeveloperName('Bogus', 'Bogus'));

		System.AssertEquals(null, RecordTypes.getRecordTypeNameFromId('Bogus', null));
		System.AssertEquals(null, RecordTypes.getRecordTypeDeveloperNameFromId('bogus', null));

		System.AssertEquals(null, RecordTypes.getRecordTypeIdFromDeveloperName('Bogus', 'Bogus'));
		System.AssertEquals(null, RecordTypes.getRecordTypeIdFromName('Bogus', 'Bogus'));

		//Test with Account
		System.AssertEquals(null, RecordTypes.getRecordTypeIdFromName('Account', 'Bogus'));

		System.AssertEquals(null, RecordTypes.getRecordTypeDeveloperNameFromName('Account', 'Bogus'));

		System.AssertEquals(null, RecordTypes.getRecordTypeNameFromDeveloperName('Account', 'Bogus'));
		System.AssertEquals(null, RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Bogus'));

		System.AssertEquals(null, RecordTypes.getRecordTypeNameFromId('Account', null));
		System.AssertEquals(null, RecordTypes.getRecordTypeDeveloperNameFromId('Account', null));

		System.AssertEquals(null, RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Bogus'));
		System.AssertEquals(null, RecordTypes.getRecordTypeIdFromName('Account', 'Bogus'));

		System.assert(RecordTypes.getRecordTypeDevNameIdMap('Bogus').isEmpty());
		System.assert(RecordTypes.getRecordTypeNameIdMap('Bogus').isEmpty());
	}

	/**
	 * Separate method for checking if we have Account record type, and then testing that
	 * @author David Schach
	 */
	@IsTest
	static void testAccountRecordType() {
		List<RecordType> accountRecordTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE IsActive = TRUE AND SObjectType = 'Account'];

		RecordTypes.getRecordTypeNameIdMap('Account');
		clearMaps();

		RecordTypes.getRecordTypeDevNameIdMap('Account');
		clearMaps();

		if (!accountRecordTypes.isEmpty()) {
			RecordType activeRT = accountRecordTypes[0];

			RecordTypes.getRecordType('Account', activeRT.Id);

			System.AssertEquals(activeRT.Id, RecordTypes.getRecordTypeIdFromName('Account', activeRt.Name));
			clearMaps();

			System.AssertEquals(activeRT.DeveloperName, RecordTypes.getRecordTypeDeveloperNameFromName('Account', activeRT.Name));
			clearMaps();

			System.AssertEquals(activeRT.Name, RecordTypes.getRecordTypeNameFromDeveloperName('Account', activeRT.DeveloperName));
			System.AssertEquals(activeRT.Id, RecordTypes.getRecordTypeIdFromDeveloperName('Account', activeRT.DeveloperName));
			clearMaps();

			System.AssertEquals(activeRT.Name, RecordTypes.getRecordTypeNameFromId('Account', activeRT.Id));
			clearMaps();

			System.AssertEquals(activeRT.DeveloperName, RecordTypes.getRecordTypeDeveloperNameFromId('Account', activeRT.Id));
			clearMaps();

			Set<String> rtNames = new Set<String>();
			Set<String> rtDevNames = new Set<String>();
			for (RecordType rt : accountRecordTypes) {
				rtNames.add(rt.Name);
				rtDevNames.add(rt.DeveloperName);
			}

			Set<Id> acctRtSet = RecordTypes.getRecordTypeIdSetFromDevNames('Account', rtDevNames);
			clearMaps();
		}
		Map<String, Id> acctTypeMap = RecordTypes.getRecordTypeNameIdMap('Account');
		clearMaps();

		List<SelectOption> rtOptions = RecordTypes.getRecordTypesForSelectList('Account');
		System.assertEquals(accountRecordTypes.size(), rtOptions.size());
		clearMaps();

		rtOptions = RecordTypes.getStringRecordTypesForSelectList('Account');
		System.assertEquals(accountRecordTypes.size(), rtOptions.size());
	}

	/**
	 * Clear all record type maps to enable using fewer methods
	 * @author David Schach
	 */
	private static void clearMaps() {
		RecordTypes.map_recordTypesById.clear();
		RecordTypes.map_recordTypesByName.clear();
		RecordTypes.map_recordTypesByDevName.clear();
		RecordTypes.list_recordTypesList.clear();
	}
}