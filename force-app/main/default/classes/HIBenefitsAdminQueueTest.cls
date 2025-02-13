@isTest
public class HIBenefitsAdminQueueTest {

    @isTest
    static void processAdminInfo() {
        HIBenefitsAdminTriggerHelper.queue=false;
        HI_Benefits_Admin__c admin = new HI_Benefits_Admin__c();
        admin.Company_Id__c='werwerr';
        admin.ZP_User_Id__c='';
        insert admin;
        
        List<HI_Benefits_Admin__c> adminList = new List<HI_Benefits_Admin__c>();
        adminList.add(admin);
        HIBenefitsAdminQueue updateJob = new HIBenefitsAdminQueue(adminList);
        test.startTest();
            ID jobID = System.enqueueJob(updateJob);
        test.stopTest();
        
        admin=[Select Id, Processing_State__c from HI_Benefits_Admin__c where Id=:admin.Id];
        system.assertEquals(IntegrationUtils.ERROR_STATE, admin.Processing_State__c);
    }    
}