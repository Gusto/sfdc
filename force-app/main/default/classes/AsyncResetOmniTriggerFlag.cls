global class AsyncResetOmniTriggerFlag {
    public AsyncResetOmniTriggerFlag() {

    }
    @future
    public static void resetOmniTriggerFlag(Set<Id> recordIds){
        try{
            List<Case> listCases = [ SELECT Id, Trigger_Omni_Flow__c
                                            FROM Case 
                                            WHERE Id IN :recordIds AND 
                                            Trigger_Omni_Flow__c = true ];
            if(!listCases.isEmpty()){
                for(Case eachCase : listCases){
                    eachCase.Trigger_Omni_Flow__c = false;
                }
               // Database.Update(listCases, false);
            }
        } catch (Exception objException) {
            ExceptionLogUtil.logException('AsyncResetOmniTriggerFlag', 'resetOmniTriggerFlag', objException.getMessage(), 'Low');
        }
        
    }
}