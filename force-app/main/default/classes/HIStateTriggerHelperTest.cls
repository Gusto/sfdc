@isTest
private class HIStateTriggerHelperTest {
	@testSetup
	static void setup() {
		State__c objState = new TestDataFactory.StateBuilder().setName('Arizona_1').setAbbreviation('AZ_1').setId('3').build();
		insert objState;
	}

	/**
	 * @Author      : Bhagat singh
	 * @Description : Process HI_State__c Record : Insert State Record
	 **/
	@isTest
	static void insertHIStateRecord() {
		Test.startTest();
		HIStateTriggerHelper.queue = true;
		HI_State__c objHIState = new TestDataFactory.HIStateBuilder().setId('5').setKey('CA').setName('California').build();
		insert objHIState;

		Test.stopTest();

		List<State__c> list_States = [SELECT Name, Abbreviation__c FROM State__c WHERE Id__c = :objHIState.Id__c LIMIT 1];
		System.assertEquals(list_States[0].Name, 'California', 'Create State__c record with respect to HI_State__c');
		System.assertEquals(list_States[0].Abbreviation__c, 'CA', 'Create State__c record with respect to HI_State__c');
	}

	/**
	 * @Author      : Bhagat singh
	 * @Description : Process HI_State__c Record : Update State Record
	 **/
	@isTest
	static void updateHIStateRecord() {
		Test.startTest();
		HIStateTriggerHelper.queue = true;
		HIStateTriggerHelper.skipTrigger = true;
		State__c objStates = [SELECT Id, Name, Abbreviation__c FROM State__c WHERE Id__c = '3' LIMIT 1];
		HI_State__c objHIState = new TestDataFactory.HIStateBuilder().setId('3').setKey('AZ').setName('Arizona').build();
		insert objHIState;

		HIStateTriggerHelper.skipTrigger = false;

		update objHIState;

		Test.stopTest();

		List<State__c> list_States = [SELECT Name, Abbreviation__c FROM State__c WHERE Id = :objStates.Id LIMIT 1];
		System.assertEquals(list_States[0].Name, 'Arizona', 'Update State__c record with respect to HI_State__c');
		System.assertEquals(list_States[0].Abbreviation__c, 'AZ', 'Update State__c record with respect to HI_State__c');
	}

	/**
	 * @Author      : Bhagat singh
	 * @Description : Process HI_State__c Record : Validate Required field - State Id
	 **/
	@isTest
	static void validateHIStateRecord() {
		Test.startTest();
		HIStateTriggerHelper.queue = true;
		List<HI_State__c> list_HIStates = new List<HI_State__c>();
		list_HIStates.add(new TestDataFactory.HIStateBuilder().setId('').setKey('CA').setName('California').build());
		list_HIStates.add(new TestDataFactory.HIStateBuilder().setId('6').setKey('CO').setName('Colorado').build());
		insert list_HIStates;

		Test.stopTest();

		list_HIStates = [SELECT Message__c, Processing_State__c FROM HI_State__c WHERE Key__c = 'CA' LIMIT 1];
		System.assertEquals(list_HIStates[0].Processing_State__c, IntegrationUtils.ERROR_STATE, 'Validation - State Id is missing.');
		System.assertEquals(list_HIStates[0].Message__c, 'State Id is missing in the record.', 'Validation - State Id is missing.');
	}
}