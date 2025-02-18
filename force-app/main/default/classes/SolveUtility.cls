public with sharing class SolveUtility {
    @InvocableMethod(label='Get Solve Trigger time' description='Returns the DateTime Stamp on when Omni Flows must be triggered ' category='Case')
    public static List<case> getSolveTriggerTime( List<Id> ListCaseId){ 
        Time timeHoopStart = Time.newInstance(13, 0, 0, 0); // Hoop Start Time 8 AM EST = 1PM GMT Hoop  and End Time 8 PM EST = 1AM GMT 
        DateTime DateHoopStart = DateTime.newInstanceGmt(System.today(), timeHoopStart);
        DateTime DateHoopEnd = DateTime.newInstanceGmt(System.today(), Time.newInstance(1, 0, 0, 0)).addDays(1);
        DateTime DateNow = System.now();
        Case caseVarFromFlow = [SELECT Id,Solve_QA_Omni_Trigger_Time__c
                                                 FROM Case 
                                                 WHERE Id IN :ListCaseId];
        
        if( DateNow > DateHoopStart && DateNow < DateHoopEnd){
            caseVarFromFlow.Solve_QA_Omni_Trigger_Time__c = Datetime.now();
        }else if( DateNow < DateHoopStart){
			caseVarFromFlow.Solve_QA_Omni_Trigger_Time__c = DateHoopStart;
        }else if( DateNow > DateHoopEnd){
            caseVarFromFlow.Solve_QA_Omni_Trigger_Time__c = DateTime.newInstanceGmt(System.today(), timeHoopStart).addDays(1);
        }
        return new List<Case>{caseVarFromFlow};
    }
}