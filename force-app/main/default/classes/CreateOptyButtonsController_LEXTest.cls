@isTest
public with sharing class CreateOptyButtonsController_LEXTest {
    @isTest
    public static void testGetAccountDetails() {
        Account objAcct = new Account(
            Name = 'Test Account'
        );
        insert objAcct;

        Case objCase = new Case(
            Subject = 'Test Case',
            AccountId = objAcct.Id,
            Origin = 'Web',
            Direction__c = 'Inbound',
            RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care'),
            Type = 'Payroll Care'
        );
        CaseTriggerHelper.skipTrigger = true;
        insert objCase;

        createOptyButtonsController_LEX.getAccountDetails(objCase.Id);
    }
}