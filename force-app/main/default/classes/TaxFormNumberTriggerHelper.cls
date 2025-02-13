/**
 * @name         TaxFormNumberTriggerHelper
 * @author       Pravesh Rana
 * @date         09/28/2023
 * @description
 * @test class   TaxFormNumberTriggerHelperTest
 **/
public with sharing class TaxFormNumberTriggerHelper {
	public static Boolean skipTrigger = false;
	Set<Id> set_AgencyIds = new Set<Id>();
	Map<String, Set<String>> map_AgencyIdPresentFormNumbers = new Map<String, Set<String>>();

	static final String DUPLICATE_ERROR_MSG = 'Duplicate record not allowed: This "Form Number" already exists for the selected agency.';

	public TaxFormNumberTriggerHelper() {
	}

	public void processBeforeInsert(List<Tax_Form_Number__c> list_FormNumbers) {
		createCollectionsBefore(list_FormNumbers, new Map<ID, Tax_Form_Number__c>());
		getAgencyBasedFormNumbers();
		duplicateFormNumberCheck(list_FormNumbers);
	}

	public void processBeforeUpdate(Map<ID, Tax_Form_Number__c> map_OldFormNumber, Map<ID, Tax_Form_Number__c> map_NewFormNumber) {
		createCollectionsBefore(map_NewFormNumber.values(), map_OldFormNumber);
		getAgencyBasedFormNumbers();
		duplicateFormNumberCheck(map_NewFormNumber.values());
	}

	/**
	 * @author pravesh
	 * @description prevents user from creating TFN records with duplicate "Form Number"
	 */
	void duplicateFormNumberCheck(List<Tax_Form_Number__c> list_FormNumbers) {
		for (Tax_Form_Number__c objFormNumber : list_FormNumbers) {
			if (map_AgencyIdPresentFormNumbers?.containsKey(objFormNumber.Agency_Information__c)) {
				Set<String> set_FormNumbers = map_AgencyIdPresentFormNumbers.get(objFormNumber.Agency_Information__c);

				if (set_FormNumbers.contains(objFormNumber.Form_Number__c)) {
					objFormNumber.addError(DUPLICATE_ERROR_MSG);
				}
			}
		}
	}

	/**
	 * @author pravesh
	 * @description Create data collections to be used across functions
	 */
	void createCollectionsBefore(List<Tax_Form_Number__c> list_FormNumbers, Map<Id, Tax_Form_Number__c> map_OldFormNumbers) {
		for (Tax_Form_Number__c objFormNumber : list_FormNumbers) {
			Tax_Form_Number__c objOldFormNumber;
			if (map_OldFormNumbers?.size() > 0) {
				objOldFormNumber = map_OldFormNumbers.get(objFormNumber.Id);
			}

			if (
				(objOldFormNumber == null && objFormNumber.Agency_Information__c != null && objFormNumber.Form_Number__c != null) ||
				(objOldFormNumber != null && (objOldFormNumber.Form_Number__c != objFormNumber.Form_Number__c || objOldFormNumber.Agency_Information__c != objFormNumber.Agency_Information__c))
			) {
				set_AgencyIds.add(objFormNumber.Agency_Information__c);
			}
		}
	}

	/**
	 * @author pravesh
	 * @description get agency based Unique Form NUmbers information
	 */
	void getAgencyBasedFormNumbers() {
		map_AgencyIdPresentFormNumbers = new Map<String, Set<String>>();

		if (set_AgencyIds?.size() > 0) {
			for (Tax_Form_Number__c objFormNumber : [SELECT Id, Form_Number__c, Agency_Information__c FROM Tax_Form_Number__c WHERE Agency_Information__c IN :set_AgencyIds AND Agency_Information__c != null]) {
				Set<String> set_FormNumbers = new Set<String>();
				if (map_AgencyIdPresentFormNumbers.containsKey(objFormNumber.Agency_Information__c)) {
					set_FormNumbers = map_AgencyIdPresentFormNumbers.get(objFormNumber.Agency_Information__c);
				}

				set_FormNumbers.add(objFormNumber.Form_Number__c);
				map_AgencyIdPresentFormNumbers.put(objFormNumber.Agency_Information__c, set_FormNumbers);
			}
		}
	}
}