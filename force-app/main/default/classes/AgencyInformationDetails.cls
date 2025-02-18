/** @name       AgencyInformationDetails
* @author       Sujan
* @date         7th November 2024
* @description  Handles the Get, Create, and Update of Agency Information Child Objects .
* @test class   AgencyInformationDetailsTest
* @revisions    Date ------------ Name ------------ Comments
**/
public with sharing class AgencyInformationDetails {
    // Method for upserting Agencies Supporting Combined-Reporting by Record Type
    public static Map<String,Agencies_Supporting_Combined_Reporting__c> getASCRRelatedRecords(Id recordId){
        String strSobjectApiName = 'Agencies_Supporting_Combined_Reporting__c';
        Map<String,Agencies_Supporting_Combined_Reporting__c> mapReturn = new Map<String,Agencies_Supporting_Combined_Reporting__c>();
        try {
            Map<String, Schema.SObjectType> mapSchema = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> mapField = mapSchema.get(strSobjectApiName).getDescribe().fields.getMap();
            List<String> lstApiNames = new list<String>();
            for(String apiName : mapField.keyset())
            {
                lstApiNames.add(apiName);
            }
            String strApiNames = string.join(lstApiNames,',');
            String strQuery = 'SELECT ' + strApiNames + ' FROM ' + strSobjectApiName + ' WHERE Agency_Information__c =\''+ recordId+'\'';
            List<Agencies_Supporting_Combined_Reporting__c> lstASCRRecords = Database.query(strQuery);
            String strAgencyInfoRecType = Schema.getGlobalDescribe().get(strSobjectApiName).getDescribe().getRecordTypeInfosByName().get('Combined-Reporting Agency Info').getRecordTypeId();
            String strAnnualFilingoRecType = Schema.getGlobalDescribe().get(strSobjectApiName).getDescribe().getRecordTypeInfosByName().get('Combined-Reporting, Annual Filing (Reconciliation)').getRecordTypeId(); 
            String strNonAnnualFilingRecType = Schema.getGlobalDescribe().get(strSobjectApiName).getDescribe().getRecordTypeInfosByName().get('Combined-Reporting, Non-Annual Filings').getRecordTypeId();
            Map<String,String> mapRecordTypes = new Map<String,String>();
            mapRecordTypes.put(strAgencyInfoRecType,'Combined-Reporting Agency Info');
            mapRecordTypes.put(strAnnualFilingoRecType,'Combined-Reporting, Annual Filing (Reconciliation)');
            mapRecordTypes.put(strNonAnnualFilingRecType,'Combined-Reporting, Non-Annual Filings');
            if(lstASCRRecords.isEmpty()){
                List<Agencies_Supporting_Combined_Reporting__c> lstASCRRecordsToCreate = new List<Agencies_Supporting_Combined_Reporting__c>();
                for(String recType:mapRecordTypes.keySet()){
                    Agencies_Supporting_Combined_Reporting__c objASCRRecord = new Agencies_Supporting_Combined_Reporting__c();
                    objASCRRecord.RecordTypeId = recType;
                    objASCRRecord.Agency_Information__c=recordId;
                    lstASCRRecordsToCreate.add(objASCRRecord);
                }
                if(!lstASCRRecordsToCreate.isEmpty()){
                    INSERT lstASCRRecordsToCreate; //DML
                    for(Agencies_Supporting_Combined_Reporting__c objCreatedRecord:lstASCRRecordsToCreate){
                        mapReturn.put(maprecordTypes.get(objCreatedRecord.RecordTypeId),objCreatedRecord);
                    }
                }       
            }else{
                for(Agencies_Supporting_Combined_Reporting__c objExistingRecord:lstASCRRecords){
                    mapReturn.put(maprecordTypes.get(objExistingRecord.RecordTypeId),objExistingRecord);
                }
            }
        } catch (Exception objException) {  
            ExceptionLogUtil.logException(
                'AgentInformationDetails',
                'getASCRRelatedRecords',
                objException.getMessage(),
                objException.getStackTraceString()
            );
        }      
        return mapReturn;
    }
    // Method for upserting SUI Agencies Records by Record Type
    public static Map<String,SUI_Agencies__c> getSUIRelatedRecords(Id recordId){
        
        String strSobjectApiName = 'SUI_Agencies__c';
        Map<String,SUI_Agencies__c> mapReturn = new Map<String,SUI_Agencies__c>();
        try {
            Map<String, Schema.SObjectType> mapSchema = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> mapField = mapSchema.get(strSobjectApiName).getDescribe().fields.getMap();
            List<String> lstApiNames = new list<String>();
            for(String apiName : mapField.keyset())
            {
                lstApiNames.add(apiName);
            }
            String strApiNames = string.join(lstApiNames,',');
            String strQuery = 'SELECT ' + strApiNames + ' FROM ' + strSobjectApiName + ' WHERE Agency_Information__c =\''+ recordId+'\'';
            List<SUI_Agencies__c> lstSuiRecords = Database.query(strQuery);
            String strAnnualRateDeterminationsRecType = Schema.getGlobalDescribe().get('SUI_Agencies__c').getDescribe().getRecordTypeInfosByName().get('Annual Rate Determinations').getRecordTypeId();
            String strGeneralSUIAgencyInfoRecType = Schema.getGlobalDescribe().get('SUI_Agencies__c').getDescribe().getRecordTypeInfosByName().get('General SUI Agency Info').getRecordTypeId(); 
            String strSuiLiabilityRecType = Schema.getGlobalDescribe().get('SUI_Agencies__c').getDescribe().getRecordTypeInfosByName().get('SUI Liability').getRecordTypeId();
            String strSuiReportingRequirementsRecType = Schema.getGlobalDescribe().get('SUI_Agencies__c').getDescribe().getRecordTypeInfosByName().get('SUI Reporting Requirements').getRecordTypeId();
            Map<String,String> mapRecordTypes = new Map<String,String>();
            mapRecordTypes.put(strAnnualRateDeterminationsRecType,'Annual Rate Determinations');
            mapRecordTypes.put(strGeneralSUIAgencyInfoRecType,'General SUI Agency Info');
            mapRecordTypes.put(strSuiLiabilityRecType,'SUI Liability');
            mapRecordTypes.put(strSuiReportingRequirementsRecType,'SUI Reporting Requirements');
            if(lstSuiRecords.isEmpty()){
                List<SUI_Agencies__c> lstSuiRecordsToCreate = new List<SUI_Agencies__c>();
                for(String recType:mapRecordTypes.keySet()){
                    SUI_Agencies__c objSuiRecord = new SUI_Agencies__c();
                    objSuiRecord.RecordTypeId = recType;
                     objSuiRecord.Agency_Information__c=recordId;
                    lstSuiRecordsToCreate.add(objSuiRecord);
                }
                if(!lstSuiRecordsToCreate.isEmpty()){
                    INSERT lstSuiRecordsToCreate; //DML
                    for(SUI_Agencies__c objCreatedRecord:lstSuiRecordsToCreate){
                        mapReturn.put(maprecordTypes.get(objCreatedRecord.RecordTypeId),objCreatedRecord);
                    }
                }       
            }else{
                for(SUI_Agencies__c objExistingRecord:lstSuiRecords){
                    mapReturn.put(maprecordTypes.get(objExistingRecord.RecordTypeId),objExistingRecord);
                }
            }
        } catch (Exception objException) {  
            ExceptionLogUtil.logException(
                'AgentInformationDetails',
                'getSUIRelatedRecords',
                objException.getMessage(),
                objException.getStackTraceString()
            );
        }      
        return mapReturn;
    }
    // Method for upserting SUI Agencies and SIT Agencies Records by Record Type along with Conditional Rendering of Fields
    @AuraEnabled
    public static  List<objectData> getFieldMetadata(Id recordId,String ObjectAPIName){  
        Map<String,objectData> mapReturnData = new Map<String,objectData>();
        Map<String,SUI_Agencies__c> mapSuiRecord = new  Map<String,SUI_Agencies__c>();    
        Map<String,SIT_Agencies__c> mapSitRecord = new Map<String,SIT_Agencies__c>();
         Map<String,Agencies_Supporting_Combined_Reporting__c> mapASCRRecord = new Map<String,Agencies_Supporting_Combined_Reporting__c>();
        try {
            if(ObjectAPIName == 'SUI_Agencies__c'){
                mapSuiRecord = getSUIRelatedRecords(recordId);
            }
            else if(ObjectAPIName == 'SIT_Agencies__c'){
                mapSitRecord = getSITRelatedRecords(recordId);
            }
            else if(ObjectAPIName == 'Agencies_Supporting_Combined_Reporting__c'){
                mapASCRRecord = getASCRRelatedRecords(recordId);
            }
            for(AgentInformation_Layout__mdt objagent:[SELECT Id,Dependent_Field_Type__c,Filter_Condition__c,DependentField_API_Name__c,Field_API_Name__c,IsAlwaysVisible__c,IsDependent__c,Object_API_Name__c,Record_Type_Name__c,DeveloperName FROM AgentInformation_Layout__mdt WHERE Object_API_Name__c =:ObjectAPIName ]){         
                Map<String, Object> mapFieldsToValue = new Map<String, Object>();
                if(mapReturnData!=null && mapReturnData.containsKey(objagent.Record_Type_Name__c)){
                    fieldData fieldData = new fieldData();
                    fieldData.isVisible = objagent.IsAlwaysVisible__c;
                    if(ObjectAPIName == 'SUI_Agencies__c'){          
                        SUI_Agencies__c objSuiRecord = mapSuiRecord.get(objagent.Record_Type_Name__c);
                        mapFieldsToValue = objSuiRecord.getPopulatedFieldsAsMap();              
                    }
                    else if(ObjectAPIName == 'SIT_Agencies__c'){            
                        SIT_Agencies__c objSitRecord = mapSitRecord.get(objagent.Record_Type_Name__c);
                        mapFieldsToValue = objSitRecord.getPopulatedFieldsAsMap();
                    }
                     else if(ObjectAPIName == 'Agencies_Supporting_Combined_Reporting__c'){            
                        Agencies_Supporting_Combined_Reporting__c objASCRRecord = mapASCRRecord.get(objagent.Record_Type_Name__c);
                        mapFieldsToValue = objASCRRecord.getPopulatedFieldsAsMap();
                    }
                    String strDependentFieldValue = ''+mapFieldsToValue.get(objagent.DependentField_API_Name__c);
                    if(objagent.IsDependent__c && objagent.Filter_Condition__c?.split(':')[1]?.split(';')?.contains(strDependentFieldValue)){
                        fieldData.isVisible = true;
                    }
                    fieldData.FieldAPIName = objagent.Field_API_Name__c;
                    fieldData.metadata = objagent;
                    mapReturnData.get(objagent.Record_Type_Name__c).fieldDataList.add(fieldData);
                }else{
                    objectData objData = new objectData();
                    objData.RecordTypeName = objagent.Record_Type_Name__c;
                    objData.Id = objagent.Id;
                    objData.ObjectApiName = objagent.Object_API_Name__c;            
                    fieldData fieldData = new fieldData();
                    fieldData.isVisible = objagent.IsAlwaysVisible__c;
                    if(ObjectAPIName == 'SUI_Agencies__c'){
                        objData.RecordId = mapSuiRecord.get(objagent.Record_Type_Name__c).Id;
                        SUI_Agencies__c objSuiRecord = mapSuiRecord.get(objagent.Record_Type_Name__c);
                        mapFieldsToValue = objSuiRecord.getPopulatedFieldsAsMap();
                    }
                    else if(ObjectAPIName == 'SIT_Agencies__c'){  
                        objData.RecordId = mapSitRecord.get(objagent.Record_Type_Name__c).Id;
                        SIT_Agencies__c objSitRecord = mapSitRecord.get(objagent.Record_Type_Name__c);
                        mapFieldsToValue = objSitRecord.getPopulatedFieldsAsMap();
                    }
                     else if(ObjectAPIName == 'Agencies_Supporting_Combined_Reporting__c'){  
                        objData.RecordId = mapASCRRecord.get(objagent.Record_Type_Name__c).Id;
                        Agencies_Supporting_Combined_Reporting__c objASCRRecord = mapASCRRecord.get(objagent.Record_Type_Name__c);
                        mapFieldsToValue = objASCRRecord.getPopulatedFieldsAsMap();
                    }
                    String dependentFieldValue = ''+mapFieldsToValue.get(objagent.DependentField_API_Name__c);
                    if(objagent.IsDependent__c && objagent.Filter_Condition__c?.split(':')[1]?.split(';')?.contains(dependentFieldValue)){
                        fieldData.isVisible = true;
                    } 
                    fieldData.FieldAPIName = objagent.Field_API_Name__c;
                    fieldData.metadata = objagent;
                    List<fieldData> lst_fieldData = new List<fieldData>();
                    lst_fieldData.add(fieldData);
                    objData.fieldDataList = lst_fieldData;
                    mapReturnData.put(objagent.Record_Type_Name__c,objData);
                }
            }
        } catch (Exception objException) {  
            ExceptionLogUtil.logException(
                'AgentInformationDetails',
                'getFieldMetadata',
                objException.getMessage(),
                objException.getStackTraceString()
            );
        }  
        return mapReturnData.values();
    }
    public class objectData{
        @AuraEnabled
        public  String RecordTypeName;
        @AuraEnabled
        public  String  Id;
        @AuraEnabled
        public  String  ObjectApiName;
        @AuraEnabled
        public  String  RecordId;  
        @AuraEnabled
        public List<fieldData> fieldDataList;
    }
    public class fieldData{
        @AuraEnabled
        public  Boolean isVisible;
        @AuraEnabled
        public  String FieldAPIName;
        @AuraEnabled
        public  AgentInformation_Layout__mdt metadata;
    }
    // Method for upserting SIT Agencies Records by Record Type
    public static Map<String,SIT_Agencies__c> getSITRelatedRecords(Id recordId){
        
        String strSobjectApiName = 'SIT_Agencies__c';
        Map<String,SIT_Agencies__c> mapReturnDetails = new  Map<String,SIT_Agencies__c>();
        try {
            Map<String, Schema.SObjectType> mapSchema = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> mapfield = mapSchema.get(strSobjectApiName).getDescribe().fields.getMap();
            List<String> lstApiNames =  new list<String>();
            for(String apiName : mapfield.keyset())
            {
                lstApiNames.add(apiName);
            }
            string strAllFields = string.join(lstApiNames,',');
            String strQuery = 'SELECT ' + strAllFields + ' FROM ' + strSobjectApiName + ' WHERE Agency_Information__c =\''+ recordId+'\'';
            List<SIT_Agencies__c> lstSITRecords = Database.query(strQuery);
            String strAnnualFilingReconciliationRecType = Schema.getGlobalDescribe().get('SIT_Agencies__c').getDescribe().getRecordTypeInfosByName().get('Annual Filing (Reconciliation)').getRecordTypeId();
            String strEmployeeWithholdingCertificateRecType = Schema.getGlobalDescribe().get('SIT_Agencies__c').getDescribe().getRecordTypeInfosByName().get('Employee Withholding Certificate').getRecordTypeId(); 
            String strSuiForm1099NECRecType = Schema.getGlobalDescribe().get('SIT_Agencies__c').getDescribe().getRecordTypeInfosByName().get('Form 1099-NEC').getRecordTypeId();
            String strSitFormW2RecType = Schema.getGlobalDescribe().get('SIT_Agencies__c').getDescribe().getRecordTypeInfosByName().get('Form W-2').getRecordTypeId();
            String strSitGeneralSITAgencyInfoRecType = Schema.getGlobalDescribe().get('SIT_Agencies__c').getDescribe().getRecordTypeInfosByName().get('General SIT Agency Info').getRecordTypeId();
            Map<String,String> mapRecordTypes = new Map<String,String>();
            mapRecordTypes.put(strAnnualFilingReconciliationRecType,'Annual Filing (Reconciliation)');
            mapRecordTypes.put(strEmployeeWithholdingCertificateRecType,'Employee Withholding Certificate');
            mapRecordTypes.put(strSuiForm1099NECRecType,'Form 1099-NEC');
            mapRecordTypes.put(strSitFormW2RecType,'Form W-2');
            mapRecordTypes.put(strSitGeneralSITAgencyInfoRecType,'General SIT Agency Info');
            if(lstSITRecords.isEmpty()){
                List<SIT_Agencies__c> lstSitRecordsToCreate = new List<SIT_Agencies__c>();
                for(String recType:mapRecordTypes.keySet()){
                    SIT_Agencies__c objSitRecord = new SIT_Agencies__c();
                    objSitRecord.RecordTypeId = recType;
                     objSitRecord.Agency_Information__c=recordId;
                    lstSitRecordsToCreate.add(objSitRecord);
                }
                if(!lstSitRecordsToCreate.isEmpty()){
                    INSERT lstSitRecordsToCreate; //DML
                    for(SIT_Agencies__c objCreatedRecord:lstSitRecordsToCreate){
                        mapReturnDetails.put(mapRecordTypes.get(objCreatedRecord.RecordTypeId),objCreatedRecord);
                    }
                }            
            }else{
                for(SIT_Agencies__c objExistingRecord:lstSITRecords){
                    mapReturnDetails.put(mapRecordTypes.get(objExistingRecord.RecordTypeId),objExistingRecord);
                }
            }      
        } catch (Exception objException) {  
            ExceptionLogUtil.logException(
                'AgentInformationDetails',
                'getSITRelatedRecords',
                objException.getMessage(),
                objException.getStackTraceString()
            );
        }  
        return mapReturnDetails;
    }
    
}