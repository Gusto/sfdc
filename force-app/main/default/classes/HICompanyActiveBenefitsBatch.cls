/**
 * @name         : HICompanyActiveBenefitsBatch
 * @date         : 09-26-2023
 * @description  : Update the HI Is Active Benefits field of each HI Company Active Benefits record to False. 
 * 				   If the record has passed 2 days and HI Is Active Benefits is active.
 **/
public class HICompanyActiveBenefitsBatch implements Database.Batchable<sObject>{
	public Database.QueryLocator start(Database.BatchableContext BC){
        //Retrieve HI Company Active Benefits records where the last modified date is 2 days before and HI_Is_Active_Benefits__c is active
        String query = 'SELECT Id FROM HI_Company_Active_Benefits__c WHERE LastModifiedDate < LAST_N_DAYS:2 AND HI_Is_Active_Benefits__c = \'True\'';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<HI_Company_Active_Benefits__c> list_HICompanyActiveBenefits){
        //Update the HI Is Active Benefits field of each HI Company Active Benefits record to False
        for(HI_Company_Active_Benefits__c objHICompanyActiveBenefits : list_HICompanyActiveBenefits){
            objHICompanyActiveBenefits.HI_Is_Active_Benefits__c = 'False';
        }
        
        if(!list_HICompanyActiveBenefits.isEmpty()){
            try{
                //Update HI Company Active Benefits Records
            	update list_HICompanyActiveBenefits;
            }catch(Exception objException){
                ExceptionLogUtil.logException('HICompanyActiveBenefitsBatch', 'execute', objException);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){}
}