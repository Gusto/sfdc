/**
 * @author Yogesh Kherajani
 * @since 09/18/2024
 **/
@isTest
public class SendSlackNotForOppResellerSchedulerTest {
    //Setup Data
	@testSetup
    private static void setupData(){
        slackv2__Message_Destination__c objSlackMessageDestinationRec = new slackv2__Message_Destination__c();
        objSlackMessageDestinationRec.slackv2__Channel_Name__c = 'test-slack-channel';
        objSlackMessageDestinationRec.slackv2__Channel_Id__c = 'C0615L9CUG3';
        INSERT objSlackMessageDestinationRec;
            
        Account objResellerAccount = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
            .setName('Discovery Account')
            .setZPFirmId('4561111111')
            .build();
        
        INSERT objResellerAccount;
        
        Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
            .setSoldBy(objResellerAccount.Id)
            .setName('APD Upsell Opportunity')
            .setStage('Raw')
            .setType('Upsell')
            .build();
        
        INSERT objOpportunity;
    }
    
    //Uni test to test if the scheduler is correctly working and slack able to send message and Opp Reseller to false
    @isTest
    private static void unitTest(){
        Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        objOpp.Send_Slack_to_Reseller__c = TRUE;
        
        UPDATE objOpp;
        
        Test.startTest();
        String jobId = System.schedule('SendSlackNotForOppReseller Scheduler Test', '0 05 * * * ?', new SendSlackNotForOppResellerScheduler());
        CronTrigger objConTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals('0 05 * * * ?', objConTrigger.CronExpression);
        System.assertEquals(0, objConTrigger.TimesTriggered);
        Test.stopTest();
        
        objOpp = [SELECT Id, Send_Slack_to_Reseller__c FROM Opportunity LIMIT 1];
        
		System.assertEquals(false, objOpp.Send_Slack_to_Reseller__c, 'Send Slack To Reseller to false');
    }
}