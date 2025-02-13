public with sharing class TaxOpsFailedRecordTriggerHelper {
    public static boolean skipTrigger = false;
    public static integer counter=0; 
    
    public void OnBeforeInsert(List<Tax_Ops_Failed_Record__c> failedRecords){
        counter++; 
        //populateContactForTaxOpsFailedRecords(failedRecords); 
        for(Tax_Ops_Failed_Record__c rec: failedRecords){
            /*if(rec.FEIN_Encrypt__c != null){
                rec.FEIN__c = rec.FEIN_Encrypt__c;
            }*/
            
            if(String.isNotBlank(rec.FEIN__c)){
                String fein = replaceSpecialCharacters(rec.FEIN__c);
                rec.FEIN__c = fein;
            }
            if(String.isNotBlank(rec.Account_Number__c)){
                String accountNumb = replaceSpecialCharacters(rec.Account_Number__c);
                rec.Account_Number__c = accountNumb;
            }
        }       
    } 
        
    public void OnAfterInsert(Map<ID, Tax_Ops_Failed_Record__c> newFailedRecordMap){
        //sendEmailMessageForTaxOpsFailedRecords(newFailedRecordMap.values());
    }
    
    /*@future
    public static void OnAfterInsertAsync(Set<ID> insertedFailedRecordIDs){
        
    }*/
    
    public void OnBeforeUpdate(Map<ID, Tax_Ops_Failed_Record__c>  oldFailedRecordMap, Map<ID, Tax_Ops_Failed_Record__c> newFailedRecordMap){
        for(Tax_Ops_Failed_Record__c rec: newFailedRecordMap.values()){
            if(String.isNotBlank(rec.FEIN__c)){
                String fein = replaceSpecialCharacters(rec.FEIN__c);
                rec.FEIN__c = fein;
            }
            if(String.isNotBlank(rec.Account_Number__c)){
                String accountNumb = replaceSpecialCharacters(rec.Account_Number__c);
                rec.Account_Number__c = accountNumb;
            }
        }
        counter++;
    }
    
    public void OnAfterUpdate(Map<ID, Tax_Ops_Failed_Record__c>  oldFailedRecordMap, Map<ID, Tax_Ops_Failed_Record__c> newFailedRecordMap){
        
    }
    
    /*@future
    public static void OnAfterUpdateAsync(Set<ID> updatedFailedRecordIDs){
        
    }*/
    
    public void OnBeforeDelete(Tax_Ops_Failed_Record__c[] failedRecordToDelete, Map<ID, Tax_Ops_Failed_Record__c> oldFailedRecordMap){
        counter++;
        
    }
    
    public void OnAfterDelete(Tax_Ops_Failed_Record__c[] deletedFailedRecord, Map<ID, Tax_Ops_Failed_Record__c> oldFailedRecordMap){
        counter++;
        
    }
    
    /*@future
    public static void OnAfterDeleteAsync(Set<ID> deletedFailedRecordIDs){
        
    }*/
    
    public void OnUndelete(Tax_Ops_Failed_Record__c[] restoredFailedRecords){
        counter++;
    }
    
    public String replaceSpecialCharacters(String val){
        if(string.isNotBlank(val)){
            String res = val.replaceAll('[^a-zA-Z0-9]', '');
        	return res;
        }
		return val;        
    }
}