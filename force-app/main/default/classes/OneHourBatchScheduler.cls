/**
 * @name         : OneHourBatchScheduler
 * @date         : 08-31-2023
 * @description  : Run Scheduler every one hour to execute batch
 **/
public class OneHourBatchScheduler implements Schedulable{
	public void execute(SchedulableContext SC) {
        //Retrieve the configuration setting record to get the batch size
        Configuration_Settings__c objConfigSetting = Configuration_Settings__c.getOrgDefaults();
        
        //Get GF Ticket batch size
		Integer intBatchSize = 
            objConfigSetting.GF_Ticket_Processing_Batch_Size__c != null && objConfigSetting.GF_Ticket_Processing_Batch_Size__c.intValue() != 0 
            ? objConfigSetting.GF_Ticket_Processing_Batch_Size__c.intValue() : 100;
        
    	UpdateGFTicketProcessingStatusBatch objUpdateGFTicketProcessingStatusBatch = new UpdateGFTicketProcessingStatusBatch(); 
        Database.executeBatch(objUpdateGFTicketProcessingStatusBatch, intBatchSize);
        
        //Get HI Active Company Benefit batch size
        Integer intHICompanyActiveBenefitBatchSize = objConfigSetting.HI_Company_Active_Benefit_Batch_Size__c != null && objConfigSetting.HI_Company_Active_Benefit_Batch_Size__c.intValue() != 0 
            ? objConfigSetting.HI_Company_Active_Benefit_Batch_Size__c.intValue() : 100;
        
        HICompanyActiveBenefitsBatch objHICompanyActiveBenefitsBatch = new HICompanyActiveBenefitsBatch(); 
        Database.executeBatch(objHICompanyActiveBenefitsBatch, intHICompanyActiveBenefitBatchSize);
    }
}