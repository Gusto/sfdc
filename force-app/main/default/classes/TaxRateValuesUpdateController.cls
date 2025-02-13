public with sharing class TaxRateValuesUpdateController {
	static final String RT_TNI_MANUAL_INDEXING = 'Manual Indexing';
	static final String RT_TNI_OCR = 'OCR';

	/*
	 * @author:         Pravesh Rana
	 * @description:    return record of Case object based on parameter Id
	 * @param:          strCaseId [Case record Id]
	 * @return:			Instance of Case
	 */
	@AuraEnabled
	public static List<Tax_Rate_Values__c> getTaxRateValues(String strCaseId) {
		return [
			SELECT Id, Rate_Decimal__c, Tax_Rate_Type__r.Name, Tax_Rate_Type__r.ZP_Tax_Rate_Name__c, Tax_Rate_Type__c, Tax_Notice_Index__c,
            Tax_Notice_Index__r.Case__r.Status
			FROM Tax_Rate_Values__c
			WHERE Tax_Notice_Index__r.Case__c = :strCaseId AND Tax_Notice_Index__r.RecordType.Name != :RT_TNI_OCR
			ORDER BY NAME ASC
		];
	}

	/*
	 * @author:         Pravesh Rana
	 * @description:    return comma separated field api names
	 * @param:          N/A
	 * @return:			comma separated field api names
	 */
	@AuraEnabled
	public static List<String> getFields() {
		try {
			List<String> list_strFieldsAPINames = new List<String>();
			for (Schema.FieldSetMember objField : SObjectType.Case.FieldSets.Notice_Index_Fields.getFields()) {
				list_strFieldsAPINames.add(objField.getFieldPath());
			}

			return list_strFieldsAPINames;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}