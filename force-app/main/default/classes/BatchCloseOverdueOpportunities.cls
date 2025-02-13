/**
 * @name         : BatchCloseOverdueOpportunities
 * @author       : Ankit CS
 * @date         : 11-24-2021
 * @description  : This batch closes Opportunities that are Overdue on the 1st of every month. 
                   Scheduler class - SchedulerCloseOverdueOpportunities
 * @test classes : BatchCloseOverdueOpportunitiesTest
**/
public class BatchCloseOverdueOpportunities implements Database.Batchable<sObject>{
    public static final List<String> list_LeadSourcesToExclude = Label.Engagement_CloseOppBatch_LeadSources.split(',');
    public static final Set<String> set_Stages = new Set<String>{ 'New', 'Attempting Contact' };

    public Database.QueryLocator start(Database.BatchableContext objBatchableContext){
        String strQuery = 'SELECT Id, LeadSource, StageName, CloseDate, Closed_via_Automation__c FROM Opportunity ' + 
                          'WHERE StageName IN :set_Stages AND LeadSource NOT IN :list_LeadSourcesToExclude ' + 
                          'AND RecordType.Name = \'Customer Success\' AND CloseDate < TODAY';
        return Database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext objBatchableContext, List<Opportunity> list_Opportunities){ 
        List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>();

        for (Opportunity objOpportunity : list_Opportunities) {
            objOpportunity.StageName = 'Closed Lost';
            objOpportunity.CloseDate = System.today();
            objOpportunity.Closed_via_Automation__c = true;
        }

        // To generate DML Exception from test method.
        if (Test.isRunningTest() && BatchCloseOverdueOpportunitiesTest.blnThrowException 
            && !list_Opportunities.isEmpty()) {
                list_Opportunities[0].Name = null;
        }

        OpportunityTriggerHelper.skipTrigger = true;
        Database.SaveResult[] list_UpdateResults = Database.update(list_Opportunities, false);
        OpportunityTriggerHelper.skipTrigger = false;
        for (Database.SaveResult objSaveResult : list_UpdateResults) {
            if (!objSaveResult.isSuccess()) {
                Id idFailedRecord = objSaveResult.getId();
                for (Database.Error objError : objSaveResult.getErrors()) {
                    Exception_Log__c objLog = new Exception_Log__c(
                        Class_Name__c = 'BatchCloseOverdueOpportunities',
                        Method_Name__c = 'execute',
                        Record_ID__c = idFailedRecord,
                        Message__c = objError.getMessage(),
                        Type__c = String.valueOf(objError.getStatusCode()),
                        OwnerId = Label.Dev_Team_Queue
                    );
                    list_ExceptionLogs.add(objLog);
                }
            }
        }

        if (!list_ExceptionLogs.isEmpty()) {
            insert list_ExceptionLogs;
        }
    }

    public void finish(Database.BatchableContext objBatchableContext){

    }
}