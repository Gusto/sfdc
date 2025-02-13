@isTest
public class UpdateEEFulfilmentSchedulerTest {

    @isTest
    static void testBatchExecution() {
        Account acc = new Account();
        acc.Name='TestNew Accnt';
        insert acc;

        Opportunity Opp= new Opportunity();
        Opp.Name='Opp-test New Plan';
        Opp.CloseDate=System.today();
        Opp.StageName='Engaged';
        Opp.NumberOfEmployees__c=15;
        Opp.AccountId=acc.Id;
        insert Opp; 
        
        Benefit_Order__c BOopp = new Benefit_Order__c();
        BOopp.Name = 'New BO Opp';
        BOopp.Opportunity__c=Opp.Id;
        BOopp.Account__c=acc.Id;
        BOopp.Order_Status__c='Fulfilled';
        BOopp.EE_at_Fulfillment__c=16;
        insert BOopp;
        
        test.startTest();
            String CRON_EXP = '0 0 * * * ?';
            UpdateEEFulfilmentScheduler sch = new UpdateEEFulfilmentScheduler();
            system.schedule('Hourly Example Batch Schedule job', CRON_EXP, sch);
        test.stopTest();
    }
}