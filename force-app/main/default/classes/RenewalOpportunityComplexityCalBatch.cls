public with sharing class RenewalOpportunityComplexityCalBatch implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        
        id renewalRecordTypeId = Cache.getRecordTypeId('Opportunity','Benefits Renewal');
        date startDate = date.newInstance(2019,1,1);
        string queryStr = 'select id,Medical_Renewal__c,Dental_Renewal__c,Vision_Renewal__c,Life_Renewal__c,'+
                            'Long_Term_Disability_Renewal__c,Short_Term_Disability_Renewal__c,FSA_Renewal__c,HSA_Renewal__c,'+
                            'DCA_Renewal__c,Voluntary_Life__c,'+
                            ' recordtypeid, AF_Complexity_Scoring__c '+
                            ' from Opportunity where RecordTypeId=:renewalRecordTypeId and Renewal_Date__c>=:startDate';
        
        
        return Database.getQueryLocator(queryStr);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunityList){
        
        if(opportunityList != null && opportunityList.size()>0){
            OpportunityTriggerHelper objHelper = new OpportunityTriggerHelper();
            for(Opportunity objOppty: opportunityList) {
                objHelper.complexityScoringAdvisingFulfillment(objOppty);
            }
            OpportunityTriggerHelper.skipTrigger = true;
            update opportunityList;
        }        
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}