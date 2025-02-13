@isTest
public class CaseActionsFieldConfigurationTest {
	
    static testmethod void testGetRecordTypeAndFieldsForValidSobject() {
        
        // Create a new Payroll Care Case
     	Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
        // Fetch all record type and field names for Case
        CaseActionsFieldConfigurationController.FieldConfigurationResponse objResponseForValidSObject = CaseActionsFieldConfigurationController.getCaseRecordTypeAndFieldNames(objCase.Id);
        System.assertEquals(true, objResponseForValidSObject.blnIsSuccess, 'Case Actions Field Configuration - Not able to fetch Case fields and record types');
        
    }
    
    static testmethod void testGetRecordTypeAndFieldsForInValidSobject() {
    	
        // Try to fetch record type and fields for invalid SObject
        CaseActionsFieldConfigurationController.FieldConfigurationResponse objResponseForInvalidSObject = CaseActionsFieldConfigurationController.getCaseRecordTypeAndFieldNames(null);
        System.assertEquals(false, objResponseForInvalidSObject.blnIsSuccess, 'Case Actions Field Configuration - Able to fetch fields and record types for invalid sObject');
    }
    
    static testmethod void testRetrievingCaseFieldConfiguration() {
        
        // Insert a new test config
        Case_Action_Fields__c objCaseOutputConfigForPayrollCare = new Case_Action_Fields__c(Is_Active__c = true, Display_Type__c = 'Action' , SObject_Type__c = 'Case', Record_Type__c = 'Payroll Care');
        insert objCaseOutputConfigForPayrollCare;
        
        CaseActionsFieldConfigurationController.FieldConfigurationResponse objResponse = CaseActionsFieldConfigurationController.returnCaseFieldConfiguration('Payroll Care', 'Action', 'Case');
		System.assertEquals(true, objResponse.objCaseActionField != null, 'Case Actions Field Configuration - Not able to find case actions config');        
    }
    
    static testmethod void testSaveCaseFieldConfig() {
        
        String strConfigJson = '[{"size":"6","overrideLabel":"","label":"Owner ID","isVisible":true,"isRequired":false,"input":true,"criteriaList":null,"api":"OwnerId"},{"size":"6","overrideLabel":"","label":"Routing Case Reason","isVisible":true,"isRequired":false,"input":true,"criteriaList":[{"value":"Web","operator":"Equals","name":"Case Origin","key":"criteria 0","api":"Origin"}],"api":"Routing_Case_Reason__c"}]';
    	Boolean blnIsInsertSuccessful = CaseActionsFieldConfigurationController.saveCaseFieldConfig('Payroll Care', 'Action', 'Case', strConfigJson);
        System.assertEquals(true, blnIsInsertSuccessful, 'Case Actions Field Configuration - Saving case action config failed'); 
    }
    
    
    static testmethod void testReturnLookupFields() {
    	List<String> list_caseLookupFields = CaseActionsFieldConfigurationController.returnLookupFields('Case');
        System.assertEquals(true, list_caseLookupFields.contains('Account'), 'Case Actions Field Configuration - Not able to find Account as lookup field on Case'); 
    }
    
    static testmethod void testReturnRelatedObjects() {
        Map<String, List<CaseActionsFieldConfigurationController.RelatedListResponseWrapper>> map_relatedObjects = CaseActionsFieldConfigurationController.returnRelatedObjects('Case');
        System.assertEquals(true, map_relatedObjects.containsKey('Attachment'), 'Case Actions Field Configuration - Not able to find Attachment on related object map'); 
    }
    
    static testmethod void testRecordTypeAndFieldList() {
        CaseActionsFieldConfigurationController.RelatedListResponseWrapper objResponse = CaseActionsFieldConfigurationController.returnRecordTypeAndFieldList('Case');
        System.assertEquals(true, objResponse.recordTypeList.contains('Payroll Care'), 'Case Actions Field Configuration - Payroll Care record type not found on Case');
    }
    
    
    static testmethod void testSaveRelatedConfig() {
        Boolean blnIsRelatedConfigSavedSuccessful = CaseActionsFieldConfigurationController.saveRelatedConfig('Case', 'Related List', 'Account', 'Case', 'Cases', '', 'AccountId');
        System.assertEquals(true, blnIsRelatedConfigSavedSuccessful, 'Case Actions Configuration - Failed to save related configuration');
        
        List<Case_Action_Fields__c> list_caseActionFieldLists = CaseActionsFieldConfigurationController.getRelatedConfig('Case', 'Related List', 'Account', 'Case', 'Cases', 'AccountId');
        System.assertEquals(true, list_caseActionFieldLists.size() > 0, 'Case Actios Configuration - Unable to retrieve related list configuration');
    }
}