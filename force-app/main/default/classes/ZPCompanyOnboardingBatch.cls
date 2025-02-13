public with sharing class ZPCompanyOnboardingBatch implements Database.Batchable<sObject>{
	
    public Database.QueryLocator start(Database.BatchableContext bc) {
        string queryString = 'Select Id from ZP_Company_Onboarding_Funnel__c where Processing_State__c=\'Error\' or Processing_State__c=\'Queued\'';
        
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        ZPCompanyTriggerHelper.queue=true;
        List<ZP_Company_Onboarding_Funnel__c> companyList= (List<ZP_Company_Onboarding_Funnel__c>)scope;
        
        update companyList;
    }
    
    public void finish(Database.BatchableContext BC){
        
        
        AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedById};
        mail.setToAddresses(toAddresses);
        mail.setSubject('ZPCompanyOnboardingFunnelBatch ' + a.Status);
        mail.setPlainTextBody('records processed ' + a.TotalJobItems +   'with '+ a.NumberOfErrors + ' failures.');
         if(a.NumberOfErrors>0){
        	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}