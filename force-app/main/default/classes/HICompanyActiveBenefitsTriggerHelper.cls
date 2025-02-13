public with sharing class HICompanyActiveBenefitsTriggerHelper {
    
    public static boolean skipTrigger = false;
    private static integer counter=0;
    public static boolean queue=false;
    public static Boolean blnTestException = false;
    
    
    public void OnBeforeInsert(List<HI_Company_Active_Benefits__c> benefits){ 
        
        if(queue==true){
            processInformation(benefits);        
        } else {
            for(HI_Company_Active_Benefits__c objHICompany : benefits){
                objHICompany.Processing_Status__c=IntegrationUtils.QUEUED_STATE;
            }
        }
    }
    
    public void OnAfterInsert(Map<ID, HI_Company_Active_Benefits__c> newBenefitMap) {
        if(queue==false && !test.isRunningTest()){
            try{
                ID jobID = System.enqueueJob(new HICompanyActiveBenefitsQueue(newBenefitMap.values()));
            } catch(Exception ex){
                ExceptionLogUtil.logException('HICompanyActiveBenefitsTriggerHelper', 'OnAfterInsert', ex.getMessage(), ex.getStackTraceString());
            }
        }
    }
    
    @future
    public static void OnAfterInsertAsync(Set<ID> insertedBenefitIDs){
        
    }
    
    public void OnBeforeUpdate(Map<ID, HI_Company_Active_Benefits__c>  oldBenefitMap, Map<ID, HI_Company_Active_Benefits__c> newBenefitMap){
        counter++;
        if(queue==true){
            processInformation(newBenefitMap.values());
        } else {
            for(HI_Company_Active_Benefits__c objHICompany : newBenefitMap.values()){
                objHICompany.Processing_Status__c=IntegrationUtils.QUEUED_STATE;
            }
        }

        if(blnTestException){
			Integer intException = 0 / 0;
		}
    }
    
    public void OnAfterUpdate(Map<ID, HI_Company_Active_Benefits__c>  oldBenefitMap, Map<ID, HI_Company_Active_Benefits__c> newBenefitMap) {
        if(queue==false && !test.isRunningTest()){
            try{
                ID jobID = System.enqueueJob(new HICompanyActiveBenefitsQueue(newBenefitMap.values()));
            } catch(Exception ex){
                ExceptionLogUtil.logException('HICompanyActiveBenefitsTriggerHelper', 'OnAfterUpdate', ex.getMessage(), ex.getStackTraceString());
            }
        } 
    }
    
    @future
    public static void OnAfterUpdateAsync(Set<ID> updatedBenefitIDs){
        
    }
    
    public void OnBeforeDelete(HI_Company_Active_Benefits__c[] benefitsToDelete, Map<ID, HI_Company_Active_Benefits__c> oldBenefitMap){
        counter++;
    }
    
    public void OnAfterDelete(HI_Company_Active_Benefits__c[] deletedBenefits, Map<ID, HI_Company_Active_Benefits__c> oldBenefitMap){

        
    }
    
    @future
    public static void OnAfterDeleteAsync(Set<ID> deletedBenefitIDs){
        
    }
    
    public void OnUndelete(HI_Company_Active_Benefits__c[] restoredBenefits){
       counter++;
    }
    
    private void processInformation(List<HI_Company_Active_Benefits__c> benefitList){
        
        if(benefitList != null && benefitList.size()>0){
            
            map<string,string> companyIdBenefitsStrmap = new map<string,string>();
            Map<String, String> accountZPCompanyIdToAccIdMap = new Map<String, String>();
            list<Account> toUpdateAccountList = new list<Account>();
            List<Account> originalToUpdateAccountList = new List<Account>();
            
            for(HI_Company_Active_Benefits__c rec: benefitList){
                if(!String.isblank(rec.Zp_Company_Id__c))
                	companyIdBenefitsStrmap.put(rec.Zp_Company_Id__c,rec.HI_Is_Active_Benefits__c);       
            }
            
            for(Account accRec: [select id, ZP_Company_ID__c, HI_Active_Benefits__c from Account where ZP_Company_ID__c in: companyIdBenefitsStrmap.keyset()]){
                if(companyIdBenefitsStrmap.containsKey(accRec.ZP_Company_ID__c)){
                    if(String.valueOf(accRec.HI_Active_Benefits__c) != companyIdBenefitsStrmap.get(accRec.ZP_Company_ID__c)){
                        accRec.HI_Active_Benefits__c = Boolean.valueOf(companyIdBenefitsStrmap.get(accRec.ZP_Company_ID__c));
                        originalToUpdateAccountList.add(accRec);
                    }
                    
                    toUpdateAccountList.add(accRec);
                    accountZPCompanyIdToAccIdMap.put(accRec.ZP_Company_ID__c, accRec.Id);
                }
            }
            
            if(toUpdateAccountList.size()>0){
                Map < String, String > dmlUpsertErrorsMap = new Map < String, String >();
            
                if(originalToUpdateAccountList.size() > 0){
                    List<Database.UpsertResult> saveResult = database.upsert(originalToUpdateAccountList,Account.Fields.ZP_Company_ID__c,false);
                    dmlUpsertErrorsMap = Utils.processUpsertResult(
                        saveResult,
                        originalToUpdateAccountList,
                        'ZP_Company_ID__c',
                        true,
                        'HICompanyActiveBenefitsTriggerHelper-ProcessInformation'
                    );
                }
                
                for(HI_Company_Active_Benefits__c hiActiveBenefits : benefitList){
                    if(String.isblank(hiActiveBenefits.Zp_Company_Id__c)){
                        setProcessingState(IntegrationUtils.ERROR_STATE,'ZP Company Id is missing in the record.',hiActiveBenefits);
                        continue;
                    }
                    
                    if(!accountZPCompanyIdToAccIdMap.containsKey(hiActiveBenefits.Zp_Company_Id__c)){
                        setProcessingState(IntegrationUtils.ERROR_STATE,'Zp Company Id does not exist on any accounts.',hiActiveBenefits);
                        continue;
                    }
                    
                    if (dmlUpsertErrorsMap.containsKey(hiActiveBenefits.Zp_Company_Id__c) ){
                        setProcessingState(IntegrationUtils.ERROR_STATE,dmlUpsertErrorsMap.get(hiActiveBenefits.Zp_Company_Id__c),hiActiveBenefits);
                    } else {
                        setProcessingState(IntegrationUtils.PROCESSED_STATE,'Processed',hiActiveBenefits);                           
                    } 
                }
            }else{
                for(HI_Company_Active_Benefits__c hiActiveBenefits : benefitList){
                    setProcessingState(IntegrationUtils.ERROR_STATE,'Zp Company Id does not exist on any accounts.',hiActiveBenefits);
                }
            }          
        }
    }
    
    // populating HI_Fulfillment_Event__c object fields
    public static HI_Company_Active_Benefits__c setProcessingState(String ProcessingState, String message, HI_Company_Active_Benefits__c  objActiveBenefits){
        objActiveBenefits.Processing_Status__c = ProcessingState;
        objActiveBenefits.Message__c = message;
        objActiveBenefits.Processed_At__c =System.now();
        return objActiveBenefits;
    }
}