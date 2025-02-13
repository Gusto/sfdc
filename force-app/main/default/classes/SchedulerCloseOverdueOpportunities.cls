/**
 * @name         : SchedulerCloseOverdueOpportunities
 * @author       : Ankit CS
 * @date         : 11-29-2021
 * @description  : Scheduler class for BatchCloseOverdueOpportunities
 * @test classes : BatchCloseOverdueOpportunitiesTest
**/
public class SchedulerCloseOverdueOpportunities implements Schedulable {
    public void execute(SchedulableContext objSchedulableContext) {
        Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
        Integer intBatchSize = objConfig.Close_Opps_Batch_Size__c.intValue() != null &&
            objConfig.Close_Opps_Batch_Size__c.intValue() != 0
            ? objConfig.Close_Opps_Batch_Size__c.intValue()
            : 100;
        BatchCloseOverdueOpportunities objBatchInstance = new BatchCloseOverdueOpportunities();
        Database.executeBatch(objBatchInstance, intBatchSize);
    }
}