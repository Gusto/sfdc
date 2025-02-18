/**
Created by : David (Dato) Tsamalashvili
Created Date : 9/8/2019
**/
@isTest 
public class OppRelatedTrackingClassTest {
    static testMethod void newRecInsertTrigger(){   
        OpportunityTriggerHelper.skipTrigger = true;
         
        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Test';
        opportunity.StageName = 'SAL';
        opportunity.CloseDate = System.today();
        opportunity.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
        insert opportunity;
        
        Opportunity_Related_Tracking__c  ort = new Opportunity_Related_Tracking__c ();
        ort.Opportunity__c  = opportunity.Id;
        insert ort;
        TaskTriggerHelper.skipTrigger = true;
        Task t  = new Task(
            WhatId = opportunity.Id,
            RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Email').getRecordTypeId(),
            Type = 'Outbound Call' ,
            Status = 'Connect'
        );
        insert t;

        t = new Task(
            WhatId = opportunity.Id,
            RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId(),
            Type = 'Outbound Call',
            Status = 'Attempt'
        );
        insert t;
        
        t = new Task(
            WhatId = opportunity.Id,
            RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId(),
            Type = 'Outbound Call',
            Status = 'Voicemail'
        );
        insert t;
        
        Set<Id> oppIds = new Set<Id>();
        oppIds.add(opportunity.Id);
        
        OppRelatedTrackingClass opCls = new OppRelatedTrackingClass();
        opCls.processInformation(oppIds);
    }
}