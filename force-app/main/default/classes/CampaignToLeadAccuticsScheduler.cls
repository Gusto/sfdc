/**
 * @description  Scheduler class for Updating the lead data if there is an update in accutics campaign object
 * @author       Deepak Dhakal
 * @date         06-28-2024
 * @see          CampaignToLeadAccuticsDataUpdateScheduler
 * @testclass  CampaignToLeadAccuticsBatchTest
 **/

global class CampaignToLeadAccuticsScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        // Schedule the batch job
        CampaignToLeadAccuticsDataUpdateBatch batch = new CampaignToLeadAccuticsDataUpdateBatch();
        // Check if there are any existing batch jobs running
        Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
        
        Integer intBatchSize = config.Accutics_Batch_Size__c != null &&
            config.Accutics_Batch_Size__c.intValue() != null &&
            config.Accutics_Batch_Size__c.intValue() != 0
            ? config.Accutics_Batch_Size__c.intValue()
            :20;
        Database.executeBatch(batch, intBatchSize);
    }
}