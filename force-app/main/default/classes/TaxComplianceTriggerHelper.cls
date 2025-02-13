/**
 * @name         TaxComplianceTriggerHelper
 * @author       Sindhu
 * @date         06/17/2024
 * @description  Helper Class for TaxComplianceTrigger
 **/
public class TaxComplianceTriggerHelper {
    public static Boolean blnSkipTrigger = false;
    public static Set<Id> set_ComplainceNotUpdatedByIntegrationUser;
    
    /**
	 * @Description : Helper method when new Tax compliance record is created Routing to Asana Inititated. This method run after Update and for Specific conditions Only.
	 * @Param       : oldTaxComplianceMap , newTaxComplianceMap
	 * @Return      : Boolean
	 **/ 
    public void processAfterInsert(Map<ID, Tax_Compliance__c> map_NewTaxCompliance) {
        // method to call asana integration on compliance record insertion
        doComplianceCalloutToAsana(map_NewTaxCompliance); 
    }
    
    /**
	 * @Description : Helper method Verifying whether any field is changed comparing to oldTaxComplianceMap with newTaxComplianceMap. This method run after Update
	 * @Param       : oldTaxComplianceMap , newTaxComplianceMap
	 * @Return      : Boolean
	 **/ 
    public void processAfterUpdate(Map<ID, Tax_Compliance__c> map_OldTaxCompliance, Map<ID, Tax_Compliance__c> map_NewTaxCompliance) {
        // method to call asana integration on compliance record Updation
        doComplianceCalloutToAsanaUpdate(map_OldTaxCompliance, map_NewTaxCompliance);
    }
    
    /**
	 * @Description : Helper method Verifying whether any field is changed comparing to oldTaxComplianceMap with newTaxComplianceMap. This method run after Update
	 * @Param       : oldTaxComplianceMap , newTaxComplianceMap
	 * @Return      : Boolean
	 **/ 
    public static Boolean blnVerifyFieldChange(Map<ID, Tax_Compliance__c> map_OldTaxComplianceMap, Map<ID, Tax_Compliance__c> map_NewTaxComplianceMap) {
        Boolean blnIsChanged = false;
        set_ComplainceNotUpdatedByIntegrationUser = new Set<Id>();
        for (Tax_Compliance__c  tc : map_NewTaxComplianceMap.Values()) {
            if (blnCompareTaxComplainceFieldsValue(tc, map_OldTaxComplianceMap.get(tc.Id)))
            {
                blnIsChanged = true;
            }
            
            // Keep only Tax complaince Id which are not updating by Integration User
            if (System.Label.SalesforceAsanaIntegrationUser.contains(tc.LastModifiedById) == false) {
                set_ComplainceNotUpdatedByIntegrationUser.add(tc.Id);
            }
        }
        return blnIsChanged;      
    }
    
    public static Boolean blnCompareTaxComplainceFieldsValue(Tax_Compliance__c newTaxComplianceRecord, Tax_Compliance__c oldTaxComplianceRecord) {
        String strTaxComplainceFields = System.Label.TaxComplianceFieldListToValidate;
        List<String> list_TaxComplainceFields = new List<String>();
        Boolean blnIsChanged = false;
        if (String.isNotBlank(strTaxComplainceFields)) {
            //Label have multiple value with comma seperated
            if (strTaxComplainceFields.contains(',')) {
                list_TaxComplainceFields = strTaxComplainceFields.split(',');
            } 
            //Label has single value only
            else { 
                list_TaxComplainceFields.add(strTaxComplainceFields.trim());
            } 
            //Compare new value vs old value
            for (String strTCField : list_TaxComplainceFields) {
                if (String.isNotBlank(strTCField) && (newTaxComplianceRecord.get(strTCField.trim()) != oldTaxComplianceRecord.get(strTCField.trim()))) {
                    return true; 
                }
            }
        }
        return false; 
    }
    
    public void doComplianceCalloutToAsana(Map<Id, Tax_Compliance__c> map_TaxComplianceRecords) { 
		// Handles After Insert Conditions 
        Map<ID, Tax_Compliance__c> map_TaxComplianceAsanaForInsert = new Map<ID, Tax_Compliance__c>([SELECT Id, Case__c,Case__r.CreatedDate, Case__r.OwnerId,Case__r.ParentId, Case__r.Status, Case__r.Owner.Name, Case__r.Owner.Type, Case__r.Subject, Case__r.Description, Case__r.Batch_Id__c,Case__r.Parent.Batch_Id__c, Case__r.Agency_Information__r.Name, Case__r.Compliance_Score__c, Agency_Due_Date__c, Follow_up_Date__c, Eng_Status__c, Who_Owns_this_Initiative__c, Tier__c, Eng_Due_Date__c, In_App_content__c, Customer_Comms__c, Knowledge_Management_Readiness__c, Help_Center_IKB_Internal__c, Help_Center_IKB_External__c, CX_Comms__c, Impacts__c, System_impacted__c, Frequency_of_Update__c, EPDD_DRI__c, Resource_Link__c, Customer_Count__c, Classification_Type__c, Compliance_Team_POC__c FROM Tax_Compliance__c WHERE Id IN: map_TaxComplianceRecords.keySet() AND Case__r.Status !=: CaseUtils.STRG_NEW AND Case__r.Status !=: CaseUtils.STR_NO_LONGER_NEEDED AND Case__r.RecordType.DeveloperName =: CaseUtils.STR_COMPLIANCE AND Case__r.Owner.Type !=: CaseUtils.STRG_QUEUE]);              
        if (!map_TaxComplianceAsanaForInsert.isEmpty() && map_TaxComplianceAsanaForInsert.size() > 0) {
            System.enqueueJob(new SendComplianceToAsanaRouting(map_TaxComplianceAsanaForInsert, true));
            TaxComplianceTriggerHelper.blnSkipTrigger = true;
        }        
    }
    
    public void doComplianceCalloutToAsanaUpdate(Map<ID, Tax_Compliance__c> map_OldTaxComplianceRecords, Map<ID, Tax_Compliance__c> map_NewTaxComplianceRecords) {
        //Handle After Update Conditions
        if (blnVerifyFieldChange(map_OldTaxComplianceRecords, map_NewTaxComplianceRecords) && set_ComplainceNotUpdatedByIntegrationUser.size() > 0) {
            Map<ID, Tax_Compliance__c> map_TaxComplianceAsanaForUpdate = new Map<ID, Tax_Compliance__c>([SELECT Id, Case__c,Case__r.CreatedDate, Case__r.Id,Case__r.ParentId, Case__r.OwnerId, Case__r.Status, Case__r.Owner.Name, Case__r.Case_Owner_Name__c,Case__r.Owner.Type,Case__r.RecordType.DeveloperName,Case__r.Subject, Case__r.Description, Case__r.Batch_Id__c,Case__r.Parent.Batch_Id__c,Case__r.Agency_Information__r.Name, Case__r.Compliance_Score__c, Name, Agency_Due_Date__c, Follow_up_Date__c, Eng_Status__c, Who_Owns_this_Initiative__c, Tier__c, Eng_Due_Date__c, In_App_content__c, Customer_Comms__c, Knowledge_Management_Readiness__c, Help_Center_IKB_Internal__c, Help_Center_IKB_External__c, CX_Comms__c, Impacts__c, System_impacted__c, Frequency_of_Update__c, EPDD_DRI__c, Resource_Link__c, Customer_Count__c, Classification_Type__c, Compliance_Team_POC__c FROM Tax_Compliance__c  WHERE Id IN:set_ComplainceNotUpdatedByIntegrationUser AND(NOT(Case__r.Status IN (:CaseUtils.STATUS_CLOSED, :CaseUtils.STR_NO_LONGER_NEEDED,:CaseUtils.STR_DELETE, :CaseUtils.STR_UN_SUPPORTED,:CaseUtils.STR_NO_CHANGE) AND Case__r.Batch_Id__c = null))]);
            Map<Id, Tax_Compliance__c> map_RecordsToInsert = new Map<Id, Tax_Compliance__c>();
            Map<Id, Tax_Compliance__c> map_RecordsToUpdate = new Map<Id, Tax_Compliance__c>();

            for(Tax_Compliance__c objTaxCompliance: map_TaxComplianceAsanaForUpdate.values()) {
                //insert for the first time

                if(String.isBlank(objTaxCompliance.Case__r.Batch_Id__c) && objTaxCompliance.Case__r.Status != CaseUtils.STRG_NEW && objTaxCompliance.Case__r.Status != CaseUtils.STR_DELETE && objTaxCompliance.Case__r.Status != CaseUtils.STR_UN_SUPPORTED && objTaxCompliance.Case__r.Status != CaseUtils.STR_NO_CHANGE && objTaxCompliance.Case__r.Status != CaseUtils.STR_NO_LONGER_NEEDED && objTaxCompliance.Case__r.RecordType.DeveloperName == CaseUtils.STR_COMPLIANCE && objTaxCompliance.Case__r.Owner.Type != CaseUtils.STRG_QUEUE) {
                    map_RecordsToInsert.put(objTaxCompliance.Id, objTaxCompliance);
                } else if (String.isNotBlank(objTaxCompliance.Case__r.Batch_Id__c)){
                    map_RecordsToUpdate.put(objTaxCompliance.Id, objTaxCompliance);
                }
            }

            if (!map_RecordsToInsert.isEmpty() && map_RecordsToInsert.size() > 0) {
                System.enqueueJob(new SendComplianceToAsanaRouting(map_RecordsToInsert, true));
                TaxComplianceTriggerHelper.blnSkipTrigger = true;
            }

            if (!map_RecordsToUpdate.isEmpty() && map_RecordsToUpdate.size() > 0) {
                System.enqueueJob(new SendComplianceToAsanaRouting(map_RecordsToUpdate, false));
                TaxComplianceTriggerHelper.blnSkipTrigger = true;
            }
        }
    }
}