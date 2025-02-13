/*
    Description - Apex Classed used to fetch and save dynamic actions, output and related list configuration
    Author - Praveen Sethu
    Date - 09/16/2020
*/
public without sharing class CaseActionsFieldConfigurationController {

    /* Wrapper Class to be shared between Class and LWC */
    public class FieldConfigurationResponse {
        
        // List of case record types
        @AuraEnabled
        public List<String> list_caseRecordType;
        
        // List of case fields
        @AuraEnabled
        public List<String> list_caseFields;
        
        // record type
        @AuraEnabled
        public String strRecordType;

        // Sobject type derived from record pate
        @AuraEnabled
        public String strSObjectType;

        // Map of SObject Label to Api Name
        @AuraEnabled
        public Map<String, String> map_SobjectLabelToApiName = new Map<String, String>();

        // Field config for a particular record type
        @AuraEnabled
        public Case_Action_Fields__c objCaseActionField = new Case_Action_Fields__c();
        
        @AuraEnabled
        public Boolean blnIsSuccess;
        
    }

    public class RelatedListResponseWrapper {

        @AuraEnabled
        public String objectName;
        
        @AuraEnabled
        public String fieldName;

        @AuraEnabled
        public String relationshipName;
        

        @AuraEnabled
        public List<String> recordTypeList;

        @AuraEnabled
        public List<String> fieldList;


        public RelatedListResponseWrapper(String objectName, String fieldName, String relationshipName) {
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.relationshipName = relationshipName;
        }

        public RelatedListResponseWrapper(List<String> recordTypeList, List<String> fieldList) {
            this.recordTypeList = recordTypeList;
            this.fieldList = fieldList;
        }
    }
    
    // Field Wrapper object
    public class CaseFieldWrapper {
        public String label;
        public String overrideLabel;
        public String size;
        public Boolean input;
        public String api;
        public Boolean isVisible;
        public Boolean isRequired;
        public List<CaseFilterCriteria> criteriaList;
    }
    
    // Filter Criteria
    public class CaseFilterCriteria {
        public String name;
        public String operator;
        public String value;
        public String key;
        public String api;
    }
    
    /* Returns list of fields and record types for a particular idCase */
    @AuraEnabled
    public static FieldConfigurationResponse getCaseRecordTypeAndFieldNames(Id idCase){
        // Declare all variables
        FieldConfigurationResponse objResponseToReturn = new FieldConfigurationResponse();
        objResponseToReturn.blnIsSuccess = false;
        List<String> list_caseRecordType = new List<String>();
        
        try {
            // Get Context SObject = Fetching SObject Type from Record Page
            String strContextSObject = idCase.getSObjectType().getDescribe().getName();
            // Dynamic Query to Fetch Record Type
            String strSOQLQuery = 'SELECT Id, RecordType.Name FROM ' + strContextSObject + ' WHERE Id=:idCase';   
            // SObject API Name to Label Map
            objResponseToReturn.map_SobjectLabelToApiName = getSObjectApiNameToLabelMap();
            // Query to fetch Dynamic Object
            SObject obj = Database.query(strSOQLQuery);
            // Record type
            String strRecordType = (String)obj.getSobject('RecordType').get('Name');
            objResponseToReturn.strRecordType = strRecordType;
            // List of all other record types
            for(RecordType objRecordType: [SELECT Id, Name FROM RecordType WHERE SObjectType = :strContextSObject]) {
                list_caseRecordType.add(objRecordType.Name);
            }
            objResponseToReturn.list_caseRecordType = list_caseRecordType;
            objResponseToReturn.list_caseFields = getCaseFieldList(strContextSObject);
            objResponseToReturn.strSObjectType = strContextSObject;
            objResponseToReturn.blnIsSuccess = true;
            return objResponseToReturn;
            
        } catch(Exception objException) {
            objResponseToReturn.blnIsSuccess = false;
            ExceptionLogUtil.logException('CaseActionsFieldConfigurationController', 'getCaseRecordTypeAndFieldNames', objException.getMessage(), objException.getStackTraceString());
            return objResponseToReturn;
        }
    }
    /* Returns list of fields for a particular strContextSObject */
    public static List<String> getCaseFieldList(String strContextSObject) {
        // Get a map of field names from Schema class
        Map <String, Schema.SObjectField> map_field = Utils.getSObjectDescribe(strContextSObject).fields.getMap();
        
        List<String> list_caseFields = new List<String>();
        // Iterate over each value, get field description
        for(Schema.SObjectField objSField : map_field.Values()) {
            Schema.DescribeFieldResult objDField = objSField.getDescribe();
            // Check if the label is not already added to the list
            if(!list_caseFields.contains(objDField.getLabel())) {
                list_caseFields.add(objDField.getLabel());
            }
        }
        // Sort fields alphabetically and add return the list
        list_caseFields.sort();
        return list_caseFields;
    }
    
    /*
        - Returns case field configuration for a particular record type, display type and sObject Type
    */
    @AuraEnabled
    public static FieldConfigurationResponse returnCaseFieldConfiguration(String strRecordType, String strDisplayType, String strSObjectType){
        Case_Action_Fields__c objCaseActionField;
        FieldConfigurationResponse objResponseToReturn = new FieldConfigurationResponse();
        
        List<Case_Action_Fields__c> list_caseActionFields = [
            SELECT
              Id,
              Configuration_Json__c
            FROM
              Case_Action_Fields__c
            WHERE
              Record_Type__c = :strRecordType
            AND
              Is_Active__c = true 
            AND
              SObject_Type__c = :strSObjectType
            AND
              Display_Type__c =:strDisplayType
        ];
        
        if(!list_caseActionFields.isEmpty()) {
            objCaseActionField = list_caseActionFields.get(0);
        }
        objResponseToReturn.objCaseActionField = objCaseActionField;
        objResponseToReturn.list_caseFields = getCaseFieldList(strSObjectType);
        return objResponseToReturn;
    }
    

    /*
        - Saves Case field configuration for a particular record type, display type and sObject Type
    */
    @AuraEnabled
    public static Boolean saveCaseFieldConfig(String strRecordType, String strDisplayType, String strSObjectType, String strJson){
        Boolean blnIsSaveSuccessful = false;
        Case_Action_Fields__c objCaseToUpsert = new Case_Action_Fields__c();
        Map<String, String> map_fieldLabelToApi = new Map<String, String>();
        try {
            // Get a map of field label and api name
            map_fieldLabelToApi = getCaseFieldLabelToApiMap(strSObjectType);
            List<CaseFieldWrapper> list_wrapper = (List<CaseFieldWrapper>) System.JSON.deserialize(strJson, List<CaseFieldWrapper>.class);

            for(CaseFieldWrapper objWrapper: list_wrapper) {
                if(map_fieldLabelToApi.containsKey(objWrapper.label)) {
                     // Update field api for each field
                    objWrapper.api = map_fieldLabelToApi.get(objWrapper.label);
                }

                // If it has criterias, update api names for each criteria
                if(objWrapper.criteriaList != null) {  
                    for(CaseFilterCriteria objFilterCriteria : objWrapper.criteriaList) {
                        if(String.isNotBlank(objFilterCriteria.name) && String.isNotBlank(objFilterCriteria.operator)) {
                            if(map_fieldLabelToApi.containsKey(objFilterCriteria.name)) {
                                objFilterCriteria.api = map_fieldLabelToApi.get(objFilterCriteria.name);
                            }
                        }
                    }
                }
            }
            // Serialize JSON Strng
            strJson = System.JSON.serialize(list_wrapper);
            // Fetch Active Config List
            List<Case_Action_Fields__c> list_caseActions = [
                SELECT
                  Id,
                  Configuration_Json__c
                FROM
                  Case_Action_Fields__c
                WHERE
                  Record_Type__c = :strRecordType
                AND
                  Is_Active__c = true 
                AND
                  SObject_Type__c = :strSObjectType
                AND
                  Display_Type__c =:strDisplayType
            ];
            
            // Find an active config, set configuration_json__c and upsert
            if(!list_caseActions.isEmpty()) {
                objCaseToUpsert = list_caseActions.get(0);
            }
            objCaseToUpsert.Name = strRecordType;
            objCaseToUpsert.Is_Active__c = true;
            objCaseToUpsert.Configuration_Json__c = strJson;
            objCaseToUpsert.Record_Type__c = strRecordType;
            objCaseToUpsert.Display_Type__c = strDisplayType;
            objCaseToUpsert.SObject_Type__c = strSObjectType;
            upsert objCaseToUpsert;
            blnIsSaveSuccessful = true;
            return blnIsSaveSuccessful;
        } catch(Exception objException) {
            ExceptionLogUtil.logException('CaseActionsFieldConfigurationController', 'getCaseRecordTypeAndFieldNames', objException.getMessage(), objException.getStackTraceString());
            return false;
        }
    }
    
    // Returns a generic strSObjectType as input -  Returns a map field label and field api
    public static Map<String, String> getCaseFieldLabelToApiMap(String strSObjectType) {
        
        Map <String, Schema.SObjectType> map_Schema = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> map_field = map_Schema.get(strSObjectType).getDescribe().fields.getMap();
        Map<String, String> map_fieldLabelToApi = new Map<String, String>();

        for (Schema.SObjectField objSField: map_field.Values()) {
            Schema.DescribeFieldResult objDField = objSField.getDescribe();
            map_fieldLabelToApi.put(objDField.getLabel(), objDField.getName());
        }
        return map_fieldLabelToApi;
        
    }

    // Returns a Map of all SObjects and their correspnding Api Name
    public static Map<String, String> getSObjectApiNameToLabelMap() {

        Map<String, String> map_SobjectLabelToApiName = new Map<String, String>();
        for ( Schema.SObjectType o : Schema.getGlobalDescribe().values() ){   
            Schema.DescribeSObjectResult objResult = o.getDescribe();
            if(objResult.isAccessible() && objResult.isCreateable() && !objResult.isCustomSetting() && objResult.isDeletable() && objResult.isQueryable() && objResult.isSearchable() && objResult.isUpdateable()) {
                map_SobjectLabelToApiName.put(objResult.getName(), objResult.getLabel());
            }
        }
        
        return map_SobjectLabelToApiName;
    } 

    /* Methods related to Dynamic Related List Builder */
    @AuraEnabled public static List<String> returnLookupFields(String strSObject) {
        List<String> lst_lookupFields = new List<String>();

        Map <String, Schema.SObjectType> map_Schema = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> map_Field = map_Schema.get(strSObject).getDescribe().fields.getMap();
        Map<String, String> fieldLabelToApiMap = new Map<String, String>();

        for (Schema.SObjectField objSfield: map_Field.Values()) {
            Schema.DescribeFieldResult objDField = objSfield.getDescribe();
        
            if(objDField.getType() == Schema.DisplayType.Reference) {
                List<Schema.sObjectType> list_sObjectType = objDField.getReferenceTo();
                for(Schema.sObjectType objSObjectType: list_sObjectType) {
                    if(!lst_lookupFields.contains(objSObjectType.getDescribe().getName())) {
                        lst_lookupFields.add(objSObjectType.getDescribe().getName());
                    }
                }
            }
        }
        return lst_lookupFields;
    }

    // Returns a list of related objects for a parent strSObject
    @AuraEnabled public static Map<String, List<RelatedListResponseWrapper>> returnRelatedObjects(String strSObject) {

        Map<String, List<RelatedListResponseWrapper>> map_objectNameToRelatedList = new Map<String, List<RelatedListResponseWrapper>>();
        Schema.DescribeSObjectResult objDescribe = ((SObject)Type.forName(strSObject).newInstance()).getSObjectType().getDescribe();

        for (Schema.ChildRelationship objChild : objDescribe.getChildRelationships()){
            if(!map_objectNameToRelatedList.containsKey(String.valueOf(objChild.getChildSObject()))) {
                // Create a new list of wrapper
                List<RelatedListResponseWrapper> list_RelationshipWrapper = new List<RelatedListResponseWrapper>();
                // instantiate a new object wrapper, add to the list
                list_RelationshipWrapper.add(new RelatedListResponseWrapper(String.valueOf(objChild.getChildSObject()), String.valueOf(objChild.getField()), String.valueOf(objChild.getRelationshipName())));
                // set it against the key
                map_objectNameToRelatedList.put(String.valueOf(objChild.getChildSObject()), list_RelationshipWrapper);
            } else {
                
                // If it contains the key
                // get list of wrapper from the map
                List<RelatedListResponseWrapper> list_RelationshipWrapper = map_objectNameToRelatedList.get(String.valueOf(objChild.getChildSObject()));

                list_RelationshipWrapper.add(new RelatedListResponseWrapper(String.valueOf(objChild.getChildSObject()), String.valueOf(objChild.getField()), String.valueOf(objChild.getRelationshipName())));
                // set it against the key
                map_objectNameToRelatedList.put(String.valueOf(objChild.getChildSObject()), list_RelationshipWrapper);

            }
        }
        return map_objectNameToRelatedList;
    }

    // Return Record Type and Field for a generic strSObject type
    @AuraEnabled
    public static RelatedListResponseWrapper returnRecordTypeAndFieldList(String strSObject) {
        // Declare variables
        List<String> list_RecordType = new List<String>();
        List<String> list_fields = new List<String>();
        // SOQL to fetch all record types
        for(RecordType objRecordType: [Select Id, Name from RecordType Where SObjectType = :strSObject]) {
            list_RecordType.add(objRecordType.Name);
        }
        // Fetches all fields related to a generic strSObject type
        list_fields = getCaseFieldList(strSObject);
        // Return response back
        return new RelatedListResponseWrapper(list_RecordType, list_fields);
    }

    // Saves Related Config Data
    @AuraEnabled
    public static Boolean saveRelatedConfig(String strSObjectType, String strDisplayType, String strLookupField, String strRelatedObject, String strRelatedField, String strConfigJson, String strRelationshipField){
            try {
                // Initialize isUpdateSuccessful as false
                Boolean isUpdateSuccessful = false;
                Case_Action_Fields__c objCaseToUpsert = new Case_Action_Fields__c();
                // Check for an active config with parameters receieved 
                List<Case_Action_Fields__c> list_caseActions = [
                    SELECT
                    Id
                    FROM
                    Case_Action_Fields__c
                    WHERE
                    Is_Active__c = true 
                    AND
                    SObject_Type__c = :strSObjectType
                    AND
                    Display_Type__c =:strDisplayType
                    AND
                    Related_Lookup_Field__c = :strLookupField
                    AND
                    Related_Object__c = :strRelatedObject
                    AND
                    Related_List_Name__c = :strRelatedField
                    AND
                    Relationship_Field__c = :strRelationshipField
                ];
                // Check if the list is not empty
                if(!list_caseActions.isEmpty()) {
                    // Fetch the first value
                    objCaseToUpsert = list_caseActions.get(0);
                }

                // Set details and upsert record
                objCaseToUpsert.Name = strSObjectType + ' related ' + strLookupField;
                objCaseToUpsert.SObject_Type__c = strSObjectType;
                objCaseToUpsert.Display_Type__c = strDisplayType;
                objCaseToUpsert.Related_Lookup_Field__c = strLookupField;
                objCaseToUpsert.Related_Object__c = strRelatedObject;
                objCaseToUpsert.Related_List_Name__c = strRelatedField;
                objCaseToUpsert.Configuration_Json__c = strConfigJson;
                objCaseToUpsert.Is_Active__c = true;
                objCaseToUpsert.Relationship_Field__c = strRelationshipField;

                upsert objCaseToUpsert;
                isUpdateSuccessful = true;
                return isUpdateSuccessful;
            } catch(Exception objException) {
                ExceptionLogUtil.logException('CaseActionsFieldConfigurationController', 'saveRelatedConfig', objException.getMessage(), objException.getStackTraceString());
                return false;
            }
    }

    // Fetches related record config based on parameters receieved
    @AuraEnabled
    public static List<Case_Action_Fields__c> getRelatedConfig(String strSObjectType, String strDisplayType, String strLookupField, String strRelatedObject, String strRelatedField, String strRelationshipField) {

        return [
            SELECT
                Id,
                Configuration_Json__c
            FROM
                Case_Action_Fields__c
            WHERE
                Is_Active__c = true 
            AND
                SObject_Type__c = :strSObjectType
            AND
                Display_Type__c =:strDisplayType
            AND
                Related_Lookup_Field__c = :strLookupField
            AND
                Related_Object__c = :strRelatedObject
            AND
                Related_List_Name__c = :strRelatedField
            AND
                Relationship_Field__c = :strRelationshipField
        ];
    }
}