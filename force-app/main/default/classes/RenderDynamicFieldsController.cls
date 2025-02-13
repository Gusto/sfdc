/**
 * @name         : RenderDynamicFieldsController
 * @author       : Praveen Sethu
 * @date         : 09-16-2020
 * @description  : Apex class used for rendering dynamic case fields
 * @test classes : RenderDynamicFieldsControllerTest
**/

public without sharing class RenderDynamicFieldsController {
    
    /* Wrapper Class - Serialization and Deserialization is used to share data back and forth between Apex and LWC */
    public class RenderDynamicFieldResponse {
        
        /* Success flag to indicate if apex call was successful */
        @AuraEnabled
        public Boolean blnIsSuccess;
        
        /* Indicates any warning or error message to be shown in LWC */
        @AuraEnabled
        public String strMessage;
        
        /* Config JSON where all field name and criteria list are configured as JSON */
        @AuraEnabled
        public String strConfigJson;
        
        /* Record Id */
        @AuraEnabled
        public Id idRecord;
        
        /* Parameterized Constructor */
        public RenderDynamicFieldResponse(Id idRecord, String strConfigJson, Boolean blnIsSuccess, String strMessage) {
            this.idRecord = idRecord;
            this.strConfigJson = strConfigJson;
            this.blnIsSuccess = blnIsSuccess;
            this.strMessage = strMessage;
        }
    }
    
    @AuraEnabled 
    public static RenderDynamicFieldResponse retrieveOutputConfig(Id idRecord, String strObjectType, String strFieldName) {
        /* Filtered list of field names to return back to the UI. These fields will rendered as lightning output fields using lightning record view form */
        List<CaseActionsFieldConfigurationController.CaseFieldWrapper> lst_fieldNames = new List<CaseActionsFieldConfigurationController.CaseFieldWrapper>();
        String strContextSObject;
        
        try {
            List<Case_Action_Fields__c> list_CaseActionFields = new List<Case_Action_Fields__c>();
            
            if (String.isNotBlank(idRecord)) {
                strContextSObject = idRecord.getSObjectType().getDescribe().getName();
                if (strContextSObject.equals('LiveChatTranscript')) {
                    idRecord = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :idRecord].CaseId;
                    strContextSObject = 'Case';
                }
                
                /* Fetching record type name */
                String strSOQLQuery = 'SELECT Id, RecordType.Name FROM ' + strContextSObject + ' WHERE Id = :idRecord'; 
                /* Fetch record type of the context sObject */
                List<SObject> list_SObjectRecordTypes = Database.query(strSOQLQuery);
                
                if (!list_SObjectRecordTypes.isEmpty()) {
                    SObject objRecordType = list_SObjectRecordTypes[0];
                    String strContextRecordType = (String) objRecordType?.getSobject('RecordType')?.get('Name');
                    /* Query on Case Action Fields if you have context record type, sobject type and field type as output */
                    if (String.isNotBlank(strContextRecordType) && String.isNotBlank(strObjectType)) {
                        list_CaseActionFields = [
                            SELECT
                            Id,
                            Configuration_JSON__c
                            FROM
                            Case_Action_Fields__c
                            WHERE
                            Is_Active__c = true
                            AND
                            Display_Type__c = 'Output'
                            AND
                            Record_Type__c = :strContextRecordType
                            AND
                            SObject_Type__c = :strObjectType
                        ];
                    }
                }
            }            
            
            if (!list_CaseActionFields?.isEmpty()) {
                /* Query fieldName (configured by the User in App Builder) from ContextSObject */
                /* For example - field name could be AccountId. contextSobject could be Case*/
                String strSOQLQueryToFetchId = 'SELECT ' + strFieldName  + ' FROM ' + strContextSObject + ' WHERE Id = :idRecord';
                /* SOQL query #3 */
                SObject objContextRecord = Database.query(strSOQLQueryToFetchId);
                /* Check if the lookup relationship has a value */
                if (objContextRecord.get(strFieldName) != null) {
                    /* Parent Id is the parent of the context sObject. For example, it could be Contact or Account if contextSobject is Case */
                    Id idParent = (Id)objContextRecord.get(strFieldName); 
                    
                    /* deserialize configuration json */
                    List<CaseActionsFieldConfigurationController.CaseFieldWrapper> list_caseFieldConfigWrappers = (List<CaseActionsFieldConfigurationController.CaseFieldWrapper>) System.JSON.deserialize(list_CaseActionFields.get(0).Configuration_Json__c, List<CaseActionsFieldConfigurationController.CaseFieldWrapper>.class);
                    /* if there are criteria specified by the user, form a SOQL string to query list of fields configured by the user */
                    Set<String> set_SOQLFields = new Set<String>();
                    /* Iterate over deserialzed wrapper list */
                    for (CaseActionsFieldConfigurationController.CaseFieldWrapper objWrapper : list_caseFieldConfigWrappers) {
                        /* check if each wrapper has a list of criteria */
                        if (objWrapper.criteriaList != null && objWrapper.criteriaList.size() > 0) {
                            /* if each wrapper has a list of criteria, iterate over each criteria, check if criteria has a name, operator and api value */
                            for (CaseActionsFieldConfigurationController.CaseFilterCriteria objFilterCriteria : objWrapper.criteriaList) {
                                if (String.isNotBlank(objFilterCriteria.name) && String.isNotBlank(objFilterCriteria.operator) && String.isNotBlank(objFilterCriteria.api)) {
                                    /* If criteria has name, api and operator, add them to set of soql fields */
                                    set_SOQLFields.add(objFilterCriteria.api);
                                }
                            }
                        } 
                    }
                    /* Completed fetching soql fields from criteria list */
                    /* Declare a new sObject used for filtering field names base on criteria lsit*/
                    SObject objRecordToReturn;
                    /* Check if set of soql fields at least has one field - which means user set at least one criteria */
                    if (set_SOQLFields.size() > 0) {
                        /* Iterate over each field. Create a SOQL string */
                        String strSoqlFields = '';
                        for (String strEachField : set_SOQLFields) {
                            strSoqlFields = strSoqlFields + ',' + strEachField;
                        }
                        strSoqlFields = strSoqlFields.removeEnd(',');
                        /* Fetch Sobject Record */
                        String strParentSOQLQuery = 'SELECT Id' + strSoqlFields + ' FROM ' + strObjectType + ' WHERE Id = :idParent';
                        objRecordToReturn = Database.query(strParentSOQLQuery);
                    }
                    
                    /* At this point, we have all the data we need for filtering based on criteria */
                    /* Iterate over every field. check each field has a criteria. if yes iterate over each criteria. check if criteria is satisified. if yes, add them to the list of fields */
                    /* If field does not have criteria list, directly add them to the list of fields to be returned */
                    for (CaseActionsFieldConfigurationController.CaseFieldWrapper objWrapper : list_caseFieldConfigWrappers) {
                        /* check if wrapper has a criteria list */
                        if (objWrapper.criteriaList != null && objWrapper.criteriaList.size() > 0) {
                            /* Check if objRecordToReturn is not null */
                            if (objRecordToReturn != null) {
                                /* initially assume all criteria is met */
                                Boolean blnIsMeetCriteria = true;
                                /* iterate over each criteria list */
                                for (CaseActionsFieldConfigurationController.CaseFilterCriteria objFilterCriteria : objWrapper.criteriaList) {
                                    /* Check if criteria name is not empty, operator name is not empty and the api name */
                                    if (String.isNotBlank(objFilterCriteria.name) && String.isNotBlank(objFilterCriteria.operator) && String.isNotBlank(objFilterCriteria.api)) {
                                        /* get value set by the user - which is the value set by the admin on the config json */
                                        String strValueSetByUser = objFilterCriteria.value;
                                        /* set actual value fetched from SObject */
                                        String strValueFetchedCase = String.valueOf(objRecordToReturn.get(objFilterCriteria.api));
                                        strValueFetchedCase = strValueFetchedCase == null ? '' : strValueFetchedCase;
                                        /* Check if operator is Equals or not Equals */
                                        /* Set flag to false, if the record does not meet criteria */
                                        if (objFilterCriteria.operator.equals('Equals')) {
                                            if (!strValueSetByUser.equals(strValueFetchedCase)) {
                                                blnIsMeetCriteria = false;
                                            }
                                        } else if (objFilterCriteria.operator.equals('Not Equals')) {
                                            if (strValueSetByUser.equals(strValueFetchedCase)) {
                                                blnIsMeetCriteria = false;
                                            }
                                        } else if (objFilterCriteria.operator.equals('Contains')) {
                                            if (!strValueFetchedCase.contains(strValueSetByUser)) {
                                                blnIsMeetCriteria = false;
                                            }
                                        } else if (objFilterCriteria.operator.equals('Not Contains')) {
                                            if (strValueFetchedCase.contains(strValueSetByUser)) {
                                                blnIsMeetCriteria = false;
                                            }
                                        } else if (objFilterCriteria.operator.equals('Contains Ignore Case')) {
                                            if (!strValueFetchedCase.containsIgnoreCase(strValueSetByUser)) {
                                                blnIsMeetCriteria = false;
                                            }
                                        } else if (objFilterCriteria.operator.equals('Not Contains Ignore Case')) {
                                            if (strValueFetchedCase.containsIgnoreCase(strValueSetByUser)) {
                                                blnIsMeetCriteria = false;
                                            }
                                        }
                                    }
                                } 
                                /* Once you have iterated over every criteria in the list, check the flag is still true, if yes, add them to the list */
                                if (blnIsMeetCriteria) {
                                    lst_fieldNames.add(objWrapper);
                                }
                            }
                        } else {
                            /* this statement is executed when the field does not have any criteria list */
                            lst_fieldNames.add(objWrapper);
                        }
                    }
                    /* finally serialze the list, send them back to front end LWC */
                    String strConfigJson = System.JSON.serialize(lst_fieldNames);
                    /* return reponses, set success flag to true */
                    return new RenderDynamicFieldResponse(idParent, strConfigJson, true, null);
                    
                } else {
                    return new RenderDynamicFieldResponse(null, null, false, 'Configuration exists, but there is no associated ' +  strObjectType);
                } 
            } else {
                return new RenderDynamicFieldResponse(null, null, false, 'No configuration exists. Please contact Salesforce Admin');
            } 
        } catch(Exception objException) {
            ExceptionLogUtil.logException('RenderDynamicFieldsController', 'retrieveOutputConfig', objException.getMessage(), objException.getStackTraceString() + 'record: ' + idRecord + ' object: ' + strContextSObject);
            return new RenderDynamicFieldResponse(null, null, false, objException.getMessage());
        }
    }
}