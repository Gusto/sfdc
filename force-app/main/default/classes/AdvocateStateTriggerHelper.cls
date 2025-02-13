public class AdvocateStateTriggerHelper {
	
	public static boolean skipTrigger = false;
    public static integer counter=0; 
    
	public void OnBeforeInsert(List<Advocate_State__c> states)
    { 
        counter++;  
        
    }
    
    public void OnAfterInsert(Map<ID, Advocate_State__c> newStateMap)
    {

		processHistory(null,newStateMap);		
    }
    
    @future
    public static void OnAfterInsertAsync(Set<ID> insertedStateIDs){
        
    }
    
    public void OnBeforeUpdate(Map<ID, Advocate_State__c>  oldStateMap, Map<ID, Advocate_State__c> newStateMap)
    {
        counter++;
	}
	
	public void OnAfterUpdate(Map<ID, Advocate_State__c>  oldStateMap, Map<ID, Advocate_State__c> newStateMap)
	{       
        processHistory(oldStateMap,newStateMap);
    }
    
    @future
    public static void OnAfterUpdateAsync(Set<ID> updatedStateIDs){
        
    }
    
    public void OnBeforeDelete(Advocate_State__c[] stateToDelete, Map<ID, Advocate_State__c> oldStateMap){
        counter++;
    }
    
    public void OnAfterDelete(Advocate_State__c[] deletedStates, Map<ID, Advocate_State__c> oldStateMap){
        counter++;
        
    }
    
    @future
    public static void OnAfterDeleteAsync(Set<ID> deletedStateIDs){
        
    }
    
    public void OnUndelete(Advocate_State__c[] restoredStates){
        counter++;
    }
    
    private void processHistory(map<id,Advocate_State__c> oldStateMap, map<id,Advocate_State__c> newStateMap){
        List<Advocate_State_History__c> historyList = new List<Advocate_State_History__c>();
        for(Advocate_State__c state : newStateMap.Values()){
            if(oldStateMap!=null){
                Advocate_State__c OldState = oldStateMap.get(state.id);
                if(state.State__c!=oldState.State__c){
                    Advocate_State_History__c history = new Advocate_State_History__c(); 
                    history.Advocate_State__c = state.Id;
                    history.From_State__c = oldState.State__c;
                    history.To_State__c = state.State__c;
                    historyList.add(history);
                }
            } else {
                Advocate_State_History__c history = new Advocate_State_History__c(); 
                    history.Advocate_State__c = state.Id;
                    history.From_State__c = null;
                    history.To_State__c = state.State__c;
                    historyList.add(history);
            }
        }
        if(historyList.size()>0){
            insert historyList;
        }
    }
    
}