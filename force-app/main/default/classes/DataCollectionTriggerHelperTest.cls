/*  
        @CreaedBy     ::: Prashant Bhatt (Lirik)
        @CreatedDate  ::: 09/12/2019
        Desc          ::: Test Class for DataCollectionTrigger & DataCollectionTriggerHelper.

*/

@isTest
public with sharing class DataCollectionTriggerHelperTest {
    
    @isTest
    public static void testRawLeads() {
         
        //Crate a account,Case and a data colletion record
        Account acc = TestUtility.CompanyAccount();
        List<Lead> list_leads = new List<Lead>{
            new Lead(
                Company = 'test',
                FirstName ='testFirstName',
                LastName = 'testLastName',
                Email = 'test@test.com',
                Phone='7777777777',
                Status = 'Raw',
                IsConverted=False
            )
        };
        LeadTriggerHelper.skipTrigger = true;
        insert list_leads;
        LeadTriggerHelper.skipTrigger = false;

        List<Case> list_case = new List<Case>{
            new Case (
                RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
                AccountId = acc.Id,
                Subject='Test',
                Status = 'Awaiting Response',
                Description='Test ',
                Type='Payroll Care',
                Origin ='Phone',
                Direction__c ='Inbound',
                SuppliedPhone='8888888888',
                SuppliedEmail = 'test@test.com',
                Integration_Id__c = 'Zendesk-5185',
                Send_Survey__c=true,
                Partner_Record_Id__c = null, 
                Privacy_Requester_Email__c = 'test@test.com'
            ),
            new Case(
                RecordTypeId = cache.getRecordTypeId('Case', 'Privacy Request'),
                Subject='Test',
                Status = 'Identity Verified',
                SuppliedEmail = 'test@test.com',
                Privacy_Requester_Email__c = 'test@test.com',
                Date_Time_Submitted__c = Date.newInstance(System.today().year(), System.today().month(), System.today().day()),
                Lead__c = list_leads[0].Id
            )
        };
        CaseTriggerHelper.skipTrigger = true;
        insert list_case;
        CaseTriggerHelper.skipTrigger = false;

        Task t = new Task(
            WhoId = list_leads[0].Id,
            CallType = 'Inbound',
            RecordTypeId = cache.getRecordTypeId('Task', 'Chat')
        );
        insert t;
        
        List<Data_Collection__c> list_dc = new List<Data_Collection__c> {
            new Data_Collection__c(
                Case__c = list_case[0].Id,
                Data_Use_Case__c = 'Raw Leads'
            )
        };
        insert list_dc;
        
        list_leads[0].Status = 'Engaged';
        LeadTriggerHelper.skipTrigger = true;
        update list_leads;
        LeadTriggerHelper.skipTrigger = false;

        
        Data_Collection__c dc1 = new Data_Collection__c(
            Case__c = list_case[1].Id,
            Data_Use_Case__c = 'Raw Leads'
        );
        insert dc1;

        list_dc[0].Details__c='test data';
        update list_dc[0];
        
    }
}