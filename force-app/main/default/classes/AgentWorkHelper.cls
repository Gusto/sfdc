public with sharing class AgentWorkHelper {
    public static boolean skipTrigger = false;
    public set<Id> setCaseIds = new Set<Id>();
    List<Case> listCasesToUpdate = new List<Case>();
    public AgentWorkHelper() {

    }
    public void processBeforeInsert(List<AgentWork> newAgentWorkList) {
        Engagement_Flow_Configuration__c setting = Engagement_Flow_Configuration__c.getInstance(UserInfo.getProfileId());
        for(AgentWork agentWorkObj : newAgentWorkList) {
            setCaseIds.add(agentWorkObj.WorkItemId);
        }
        if(setCaseIds.size() > 0) {
            
            for(Case caseObj : [SELECT Id,OwnerId, 
                                         Status,Solve_QA_Omni_Trigger_Time__c, 
                                         Trigger_Omni_Flow__c 
                                                FROM Case 
                                                WHERE Id IN :setCaseIds]) {
                Case caseVar = new Case(Id = caseObj.Id);
                System.debug('**** caseObj.Trigger_Omni_Flow__c'+caseObj.Trigger_Omni_Flow__c);
                System.debug('**** caseObj.OwnerId'+caseObj.OwnerId);
                if(caseObj.Trigger_Omni_Flow__c){
                    caseVar.Trigger_Omni_Flow__c = false;
                }
                if( setting!=null && caseObj.OwnerId == setting.Engagement_Solve_QA_Queue__c){
                    caseVar.Solve_QA_Omni_Trigger_Time__c = null;
                }
                listCasesToUpdate.add(caseVar);
                System.debug('**** listCasesToUpdate'+listCasesToUpdate);
            }
        }
        if(listCasesToUpdate.size() > 0) {
            CaseTriggerHelper.skipTrigger = true;
            update listCasesToUpdate;
        }

       
    }

}