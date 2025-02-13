public with sharing class TaxOpsTaskCSVDataTriggerHelper {
    
    public static boolean skipTrigger = false;
    public static integer counter=0;
    public static boolean queue = false;

    public TaxOpsTaskCSVDataTriggerHelper(){

    }
    
    public void OnBeforeInsert(List<Tax_Ops_Tasks_Csv_Data__c > lst_CSVData){
        counter++;  
        for(Tax_Ops_Tasks_Csv_Data__c dataObj: lst_CSVData){
            dataObj.Processing_Status__c=IntegrationUtils.QUEUED_STATE;
            dataObj.Message__c = '';
        }
    }
    
    public void OnAfterInsert(Map<ID, Tax_Ops_Tasks_Csv_Data__c > newCSVDataMap){

    }
    
    public void OnBeforeUpdate(Map<ID, Tax_Ops_Tasks_Csv_Data__c >  oldCSVDataMap, Map<ID, Tax_Ops_Tasks_Csv_Data__c > newCSVDataMap){
        counter++;
        for(Tax_Ops_Tasks_Csv_Data__c dataObj: newCSVDataMap.values()){
            dataObj.Processing_Status__c=IntegrationUtils.QUEUED_STATE;
            dataObj.Message__c = '';
        }
    }
    
    public void OnAfterUpdate(Map<ID, Tax_Ops_Tasks_Csv_Data__c >  oldCSVDataMap, Map<ID, Tax_Ops_Tasks_Csv_Data__c > newCSVDataMap){

    }
    
    public void OnBeforeDelete(Tax_Ops_Tasks_Csv_Data__c[] csvDataToDelete, Map<ID, Tax_Ops_Tasks_Csv_Data__c > oldCSVDataMap){
        counter++;        
    }
    
    public void OnAfterDelete(Tax_Ops_Tasks_Csv_Data__c[] deletedCSVData, Map<ID, Tax_Ops_Tasks_Csv_Data__c > oldCSVDataMap){
        counter++;
        
    }    
    
    
    public void OnUndelete(Tax_Ops_Tasks_Csv_Data__c[] restoredCSVData){
        counter++;
    }
    
    public void processInformation(List<Tax_Ops_Tasks_Csv_Data__c > lst_CSVData){

        
    }

    
    
}