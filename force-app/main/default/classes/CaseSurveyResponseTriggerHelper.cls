public with sharing class CaseSurveyResponseTriggerHelper {    
    
    public static boolean skipTrigger = false;
    public static integer counter=0; 
    
    public void OnBeforeInsert(List<Case_Survey_Response__c> surveyResponseList){
        
        counter++; 
        set<Id> relatedCaseIdSet = new set<Id>();
        for(Case_Survey_Response__c rec: surveyResponseList){
            if(!relatedCaseIdSet.contains(rec.Case__c)){
                rec.Most_Recent_Survey__c = true;
                relatedCaseIdSet.add(rec.Case__c);
            }
        }
        
        if(relatedCaseIdSet.size()>0){
            updateMostRecentFlag(relatedCaseIdSet);
        }
    }
    
    public void OnAfterInsert(Map<ID, Case_Survey_Response__c> newSurveyResponseMap)
    {
        
    }
    
     @future
    public static void OnAfterInsertAsync(Set<ID> insertedSurveyResponseIDs){
        
    }
    
    public void OnBeforeUpdate(Map<ID, Case_Survey_Response__c>  oldSurveyResponseMap, Map<ID, Case_Survey_Response__c> newSurveyResponseMap)
    {
        
    }
    
    public void OnAfterUpdate(Map<ID, Case_Survey_Response__c>  oldSurveyResponseMap, Map<ID, Case_Survey_Response__c> newSurveyResponseMap)
    {
        
    }
    
    @future
    public static void OnAfterUpdateAsync(Set<ID> updatedSurveyResponseIDs){
        
    }
    
    public void OnBeforeDelete(list<Case_Survey_Response__c> surveyResponseToDelete, Map<ID, Case_Survey_Response__c> oldSurveyResponseMap){
        counter++;
    }
    
    public void OnAfterDelete(list<Case_Survey_Response__c> deletedSurveyResponse, Map<ID, Case_Survey_Response__c> oldSurveyResponseMap){
        counter++;
        
    }
    
    @future
    public static void OnAfterDeleteAsync(Set<ID> deletedSurveyResponseIDs){
        
    }
    
    public void OnUndelete(list<Case_Survey_Response__c> restoredSurveyResponse){
        counter++;
    }    
    
    public void updateMostRecentFlag( set<Id> caseIdSet){        
        if(caseIdSet != null && caseIdSet.size()>0){            
            list<Case_Survey_Response__c> caseSurveyToUpdateList = new list<Case_Survey_Response__c>();
						
            for(Case_Survey_Response__c rec: [select id, Most_Recent_Survey__c from Case_Survey_Response__c
                                              where Most_Recent_Survey__c = true and Case__c IN: caseIdSet]){
                rec.Most_Recent_Survey__c = false;
                caseSurveyToUpdateList.add(rec);                                  
            }
            
            if(caseSurveyToUpdateList.size()>0){
                CaseSurveyResponseTriggerHelper.skipTrigger = true;
                update caseSurveyToUpdateList;
                CaseSurveyResponseTriggerHelper.skipTrigger = false;
            }
        }        
    }
}