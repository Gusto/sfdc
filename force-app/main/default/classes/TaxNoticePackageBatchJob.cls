/**
* Author: Todd Dowdy
* Date: 08/12/2022
* Desc: Batch scheduler for TaxNoticePackageBatch class 
**/
global class TaxNoticePackageBatchJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
        Integer intBatch = objConfigSettings?.TaxNoticePackageBatch__c != null ? (Integer) objConfigSettings.TaxNoticePackageBatch__c : 20;

        TaxNoticePackageBatch objTaxNoticePackageBatch = new TaxNoticePackageBatch(); 
        database.executebatch(objTaxNoticePackageBatch, intBatch);
    }
}