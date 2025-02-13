public class HIFulfillmentEmployeeInfoTriggerHelper {
	public static boolean skipTrigger = false;
    private static integer counter=0;
    public static boolean queue=false;
	
	
	public void OnBeforeInsert(List<HI_Fulfillment_Employee_Info__c> employees){ 
           

    }
    
    public void OnAfterInsert(Map<ID, HI_Fulfillment_Employee_Info__c> newEmployeeMap) {

    }
    
    @future
    public static void OnAfterInsertAsync(Set<ID> insertedEmployeeIDs){
        
    }
    
    public void OnBeforeUpdate(Map<ID, HI_Fulfillment_Employee_Info__c>  oldEmployeeMap, Map<ID, HI_Fulfillment_Employee_Info__c> newEmployeeMap){
        counter++;
        
        for(HI_Fulfillment_Employee_Info__c info : newEmployeeMap.values()){
            HI_Fulfillment_Employee_Info__c oldInfo = oldEmployeeMap.get(info.id);
            
            if(oldInfo.HI_Sent_At__c > info.HI_Sent_At__c){
                info.addError('New values cannot be overwritted with old values');
            }
        }
    }
    
    public void OnAfterUpdate(Map<ID, HI_Fulfillment_Employee_Info__c>  oldEmployeeMap, Map<ID, HI_Fulfillment_Employee_Info__c> newEmployeeMap) {
    	
    }
    /*
    @future
    public static void OnAfterUpdateAsync(Set<ID> updatedEmployeeIDs){
        
    }*/
    
    public void OnBeforeDelete(HI_Fulfillment_Employee_Info__c[] employeeToDelete, Map<ID, HI_Fulfillment_Employee_Info__c> oldEmployeeMap){
        counter++;
    }
    
    public void OnAfterDelete(HI_Fulfillment_Employee_Info__c[] deletedEmployees, Map<ID, HI_Fulfillment_Employee_Info__c> oldEmployeeMap){

        
    }
    /*
    @future
    public static void OnAfterDeleteAsync(Set<ID> deletedEmployeeIDs){
        
    }*/
    
    public void OnUndelete(HI_Fulfillment_Employee_Info__c[] restoredEmployees){
       counter++;
    }
}