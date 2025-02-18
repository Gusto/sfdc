/** @name       AgencyInfo_ChildController
* @author       Rinkita
* @date         26th September 2024
* @description  Handles the Get, Create, and Update of Form_Name_Number__c .
* @test class   AgencyInfo_FormNameControllerTest
* @revisions    Date ------------ Name ------------ Comments
**/
public class AgencyInfo_ChildController {
    
    // Method for upserting Form_Name_Number__c by Record Type
    @AuraEnabled
    public static Integer upsertFormNameRecord (List<Form_Name_Number__c> list_FormNames, String strRecType, String strObjName) {
        Integer intRecordsUpserted = 0;
        try{
            Id idRecord = [SELECT Id FROM RecordType WHERE sObjectType =: strObjName and Name =: strRecType LIMIT 1].Id;
            
            for (Form_Name_Number__c objFormName : list_FormNames) {
                objFormName.RecordTypeId = idRecord;
            }
            Database.UpsertResult[] list_upsertResult = Database.upsert(list_FormNames, false);
            
            for (Database.UpsertResult result : list_upsertResult) {
                if (result.isSuccess()) {
                    intRecordsUpserted += 1;
                }
            }
        }catch (Exception objException) {
            ExceptionLogUtil.logException('AgencyInfo_FormNameController', 'upsertFormNameRecord', objException.getMessage(), objException.getStackTraceString()); 
        } 
        return intRecordsUpserted;
    }
    
    // Method for upserting Filing_Frequency_Schedule__c by Record Type
    @AuraEnabled
    public static Integer upsertFilingFrequencyRecord (List<Filing_Frequency_Schedule__c> list_FileFreqSch, String strRecType, String strObjName) {
        Integer intRecordsUpserted = 0;
        try{
            Id idRecord = [SELECT Id FROM RecordType WHERE sObjectType =: strObjName and Name =: strRecType LIMIT 1].Id;
            
            for (Filing_Frequency_Schedule__c objFileFreqSch : list_FileFreqSch) {
                objFileFreqSch.RecordTypeId = idRecord;
            }
            Database.UpsertResult[] list_upsertResult = Database.upsert(list_FileFreqSch, false);
            
            for (Database.UpsertResult result : list_upsertResult) {
                if (result.isSuccess()) {
                    intRecordsUpserted += 1;
                }
            }
        }catch (Exception objException) {
            ExceptionLogUtil.logException('AgencyInfo_FormNameController', 'upsertFilingFrequencyRecord', objException.getMessage(), objException.getStackTraceString()); 
        } 
        return intRecordsUpserted;
    }
    
    // Method for upserting Deposit_Frequency_Schedule__c
    @AuraEnabled
    public static Integer upsertDepositFrequencyRecord (List<Deposit_Frequency_Schedule__c> list_DepoFreqSch) {
        Integer intRecordsUpserted = 0;
        try{
            Database.UpsertResult[] list_upsertResult = Database.upsert(list_DepoFreqSch, false);
            
            for (Database.UpsertResult result : list_upsertResult) {
                if (result.isSuccess()) {
                    intRecordsUpserted += 1;
                }
            }
        }catch (Exception objException) {
            ExceptionLogUtil.logException('AgencyInfo_FormNameController', 'upsertDepositFrequencyRecord', objException.getMessage(), objException.getStackTraceString()); 
        } 
        return intRecordsUpserted;
    }
    
     // Method for upserting Fixed_Tax_Surcharge__c
    @AuraEnabled
    public static Integer upsertFixedTaxSurRecord (List<Fixed_Tax_Surcharge__c> list_FixedTaxSur) {
        Integer intRecordsUpserted = 0;
        try{
            Database.UpsertResult[] list_upsertResult = Database.upsert(list_FixedTaxSur, false);
            
            for (Database.UpsertResult result : list_upsertResult) {
                if (result.isSuccess()) {
                    intRecordsUpserted += 1;
                }
            }
        }catch (Exception objException) {
            ExceptionLogUtil.logException('AgencyInfo_FormNameController', 'upsertFixedTaxSurRecord', objException.getMessage(), objException.getStackTraceString()); 
        } 
        return intRecordsUpserted;
    }
    
    // Method for deleting Agency Information's child object by Object Name
    @AuraEnabled
    public static void deleteChildRecord (List<String> list_ToDelete, String strObjName) {
        if(strObjName == 'Form_Name_Number__c') {
            Form_Name_Number__c[] list_formNameToDelete = [SELECT Id FROM Form_Name_Number__c WHERE Id in: list_ToDelete]; 
            delete list_formNameToDelete;
        }
        else if(strObjName == 'Filing_Frequency_Schedule__c') {
            Filing_Frequency_Schedule__c[] list_FileFreqToDelete = [SELECT Id FROM Filing_Frequency_Schedule__c WHERE Id in: list_ToDelete]; 
            delete list_FileFreqToDelete;
        }
        else if(strObjName == 'Deposit_Frequency_Schedule__c') {
            Deposit_Frequency_Schedule__c[] list_DepositFreqToDelete = [SELECT Id FROM Deposit_Frequency_Schedule__c WHERE Id in: list_ToDelete]; 
            delete list_DepositFreqToDelete;
        }
        else if(strObjName == 'Fixed_Tax_Surcharge__c') {
            Fixed_Tax_Surcharge__c[] list_FixedTaxSurToDelete = [SELECT Id FROM Fixed_Tax_Surcharge__c WHERE Id in: list_ToDelete]; 
            delete list_FixedTaxSurToDelete;
        }       
    }
    
    //Method for getting Custom Metadata for counter by Object Name
    @AuraEnabled(cacheable=true)
    public static Integer getComplianceMetadata(String strObjName) {
        Integer intCounter=3;
        try{
            intCounter = (Integer)[SELECT Counter_Agency_Info__c FROM Compliance_CaseMapping__mdt WHERE ObjectName__c =: strObjName LIMIT 1].Counter_Agency_Info__c;
            return intCounter;
        }catch (Exception objException) {
            ExceptionLogUtil.logException('AgencyInfo_FormNameController', 'getComplianceMetadata', objException.getMessage(), objException.getStackTraceString()); 
        } 
        return intCounter;
    }
    
    //Method for getting Form_Name_Number__c for the provided Agency Informaiton Id
    @AuraEnabled(cacheable=true)
    public static List<Form_Name_Number__c> getChildFormNameRecType(Id idAgencyInfoId, String strRecType, Integer intCounter) {
        return [SELECT Id, Form_Name_Number_Text__c, Main_Filing_Format__c, Filing_Due_Date_s__c, Representation_In_App__c,
                Does_The_Form_Change_Annually__c, If_Paper_Filing_Address_Payee_Info__c, Can_We_Send_Paper__c
                FROM Form_Name_Number__c WHERE Agency_Information__c =: idAgencyInfoId and RecordType.name =: strRecType];
    }
    
    //Method for getting Filing_Frequency_Schedule__c for the provided Agency Informaiton Id
    @AuraEnabled(cacheable=true)
    public static List<Filing_Frequency_Schedule__c> getChildFilingFrequencyScheduleRecType(Id idAgencyInfoId, String strRecType, Integer intCounter) {
        return [select Id, Filing_Applicable_Forms__c, Filing_Due_Date_Info_Link__c, Filing_Frequency_Schedule_Type__c, Filing_Schedule_Behavior__c 
                from Filing_Frequency_Schedule__c
                WHERE Agency_Information__c =: idAgencyInfoId and RecordType.name =: strRecType];
    }
    
    //Method for getting Deposit_Frequency_Schedule__c for the provided Agency Informaiton Id
    @AuraEnabled(cacheable=true)
    public static List<Deposit_Frequency_Schedule__c> getChildDepositFrequencySchedule(Id idAgencyInfoId, Integer intCounter) {
        return [select id, Deposit_Due_Date_Info_Link__c, Deposit_Frequency_Schedule_Type__c, Deposit_Schedule_Behavior__c, Is_Currently_Forced_Or_Fallback__c 
                from Deposit_Frequency_Schedule__c 
                WHERE Agency_Information__c =: idAgencyInfoId];
    }
    
    //Method for getting Fixed_Tax_Surcharge__c for the provided Agency Informaiton Id
    @AuraEnabled(cacheable=true)
    public static List<Fixed_Tax_Surcharge__c> getChildFixedTaxSurcharge(Id idAgencyInfoId, Integer intCounter) {
        return [select id, Fixed_Tax_Surcharge_Name__c, Fixed_Tax_Surcharge_Rate__c, Fixed_Tax_Surcharge_Notes__c, Applies_To_All_Employers__c, Effective_Date__c, Is_Surcharge_FUTA_Recertifiable__c 
                from Fixed_Tax_Surcharge__c 
                WHERE Agency_Information__c =: idAgencyInfoId];
    }
}