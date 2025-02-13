@isTest
public class HIBenefitSignatoryQueueTest {

    @isTest
    static void processSignatoryInfo() {
        HIBenefitSignatoryTriggerHelper.queue=false;
        HI_Benefits_Signatory__c signatory = new HI_Benefits_Signatory__c();
        signatory.Company_Id__c='werwerr';
        signatory.ZP_User_Id__c='';
        insert signatory;
        
        List<HI_Benefits_Signatory__c> signatoryList = new List<HI_Benefits_Signatory__c>();
        signatoryList.add(signatory);
        HIBenefitSignatoryQueue updateJob = new HIBenefitSignatoryQueue(signatoryList);
            ID jobID = System.enqueueJob(updateJob);
        
        signatory=[Select Id, Processing_State__c from HI_Benefits_Signatory__c where Id=:signatory.Id];
        system.assertEquals(IntegrationUtils.QUEUED_STATE, signatory.Processing_State__c);
    }    
}