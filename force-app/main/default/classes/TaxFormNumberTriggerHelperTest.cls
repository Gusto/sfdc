/**
 * @name         TaxFormNumberTriggerHelperTest
 * @author       Pravesh Rana
 * @date         09/28/2023
 * @description  Code coverage for TaxFormNumberTriggerHelper and TaxFormNumberTriggerHandler
 **/
@isTest
public with sharing class TaxFormNumberTriggerHelperTest {
	public static Boolean blnRunCatchTest = false;

	/**
	 * @author pravesh
	 * @description creating test data
	 */
	@testSetup
	static void setUp() {
		//Creating Agency Information
		Agency_Information__c objAgencyInformation = new TestDataFactory.AgencyInformationBuilder().setName('Test text Res').setActive(true).build();
		insert objAgencyInformation;
	}

	/**
	 * @author pravesh
	 * @description Duplicate Form number positive testing
	 */
	@isTest
	static void duplicateFormNumberCheckTest() {
		List<Agency_Information__c> list_Agencies = [SELECT Id FROM Agency_Information__c];

		Test.startTest();
		Tax_Form_Number__c objTFM = new TestDataFactory.TaxFormNumber().setAgencyInfo(list_Agencies[0].Id).setFormNumber('T123').build();
		insert objTFM;

		List<Tax_Form_Number__c> list_FormNumbers = [SELECT Id FROM Tax_Form_Number__c WHERE Agency_Information__c = :objTFM.Agency_Information__c];
		System.assert(list_FormNumbers.size() == 1, 'one records should be created in org');

		Tax_Form_Number__c objTFM2 = new TestDataFactory.TaxFormNumber().setAgencyInfo(list_Agencies[0].Id).setFormNumber('T123').build();
		try {
			insert objTFM2;
		} catch (Exception ex) {
		}

		list_FormNumbers = [SELECT Id FROM Tax_Form_Number__c WHERE Agency_Information__c = :objTFM.Agency_Information__c];
		System.assert(list_FormNumbers.size() == 1, 'second record should through an error as it has duplicate form number');

		Tax_Form_Number__c objTFM3 = new TestDataFactory.TaxFormNumber().setAgencyInfo(list_Agencies[0].Id).setFormNumber('T1234').build();
		insert objTFM3;

		list_FormNumbers = [SELECT Id FROM Tax_Form_Number__c WHERE Agency_Information__c = :objTFM.Agency_Information__c];
		System.assert(list_FormNumbers.size() == 2, 'two unique records should be created in org by now');

		objTFM3.Form_Number__c = 'T1235';
		update objTFM3;

		Test.stopTest();
	}

	/**
	 * @author pravesh
	 * @description Duplicate Form number negative testing
	 */
	@isTest
	static void duplicateFormNumberCheckNegativeTest() {
		List<Agency_Information__c> list_Agencies = [SELECT Id FROM Agency_Information__c];

		Test.startTest();
		Tax_Form_Number__c objTFM = new TestDataFactory.TaxFormNumber().setAgencyInfo(list_Agencies[0].Id).setFormNumber('T123').build();
		insert objTFM;

		List<Tax_Form_Number__c> list_FormNumbers = [SELECT Id FROM Tax_Form_Number__c WHERE Agency_Information__c = :objTFM.Agency_Information__c];
		System.assert(list_FormNumbers.size() == 1, 'one records should be created in org');

		Tax_Form_Number__c objTFM2 = new TestDataFactory.TaxFormNumber().setAgencyInfo(list_Agencies[0].Id).setFormNumber('T123').build();
		TaxFormNumberTriggerHelper.skipTrigger = true;
		insert objTFM2;

		list_FormNumbers = [SELECT Id FROM Tax_Form_Number__c WHERE Agency_Information__c = :objTFM.Agency_Information__c];
		System.assert(list_FormNumbers.size() == 2, 'two records with duplicate values');

		TaxFormNumberTriggerHandler.resetSkipTriggerFlags();
		Test.stopTest();
	}
}