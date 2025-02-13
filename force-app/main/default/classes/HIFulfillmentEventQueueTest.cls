/**
  Author:        Robin Grover
  Company:       Gusto
  Description:   This is a test class for HIFulfillmentEventQueue

  History
  7/5/2017    Robin Grover     Initial Implementation
  **/
@isTest
private class HIFulfillmentEventQueueTest {

    static {
        Account testAcc = new Account(
            ZP_Company_ID__c = '7757616923505614',
            Name  = 'Test Account'
        );
        insert testAcc;

        Carrier__c testCarrier = new Carrier__c(
            Key__c = 'bcbs_ma',
            Name = 'Test Carrier',
            State__c = 'AL'
        );
        insert testCarrier;
    }
    static testMethod void queueHIFulfillEventRecord() {
      
        HIFulfillmentEventTriggerHelper.queue = true;
        Blob key = EncryptionUtils.generateKey('Master');
        
        HI_Fulfillment_Event__c hiEventRec = new HI_Fulfillment_Event__c();
        hiEventRec.id__c = 'Test321';
        hiEventRec.Event_Type__c = 'MF Termination';
        hiEventRec.Event_Info__c = '{ '+
        '"losing_benefits_date":"2017-06-22", '+
        '"losing_benefits_reason":"Termination", '+
        '"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132", '+
        '"employee":{ '+
        '"id":7757869431696318, '+
        '"first_name":"Ethan", '+
        '"last_name":"Fritsch", '+
        '"middle_initial":"B", '+
        '"status":"Terminated", '+
        '"ssn":"123456789", '+
        '"birthday":"1992-01-25", '+
        '"company_id":7757616923505614, '+
        '"hired_at":"2017-03-20", '+
        '"employment_status":"full_time", '+
        '"home_address":{ '+
        '"id":7757727713844547, '+
        '"street_1":"45218 Deangelo Glens", '+
        '"street_2":"Suite 683", '+
        '"city":"Cambridge", '+
        '"county_name":"Middlesex", '+
        '"state":"MA", '+
        '"zip":"02141", '+
        '"country":"USA", '+
        '"phone":null, '+
        '"created_at":"2017-03-20T06:41:28.000-07:00", '+
        '"updated_at":"2017-03-20T06:41:28.000-07:00", '+
        '"fax":null, '+
        '"inactive":false, '+
        '"work_address":false '+
        '}, '+
        '"work_address":{ '+
        '"id":7757727712904980, '+
        '"street_1":"660 Flavie Circle", '+
        '"street_2":"Apt. 340", '+
        '"city":"Cambridge", '+
        '"county_name":"Middlesex", '+
        '"state":"MA", '+
        '"zip":"02141", '+
        '"country":"USA", '+
        '"phone":"9590115024", '+
        '"created_at":"2015-04-21T07:10:17.000-07:00", '+
        '"updated_at":"2017-01-02T00:13:08.000-08:00", '+
        '"fax":"2697601503", '+
        '"inactive":false, '+
        '"work_address":true, '+
        '"employee_count":9 '+
        '}, '+
        '"email":"blanca123123.sipes7757869449148235@ziemecummerata.net", '+
        '"gender":"male", '+
        '"panda_url":"http://manage.zenpayroll.dev:3000/companies/7757616923505614/employees/7757869431696318", '+
        '"hippo_url":"http://localhost:4001/companies/7757616923505614/employees/7757869431696318", '+
        '"payroll_type":"Exempt" '+
        '}, '+
        '"company":{ '+
        '"id":7757616923505614, '+
        '"name":"Spinka-Waelchi", '+
        '"email":"broderick7757869448502232@mann.co", '+
        '"salesforce_account_id":null, '+
        '"work_states":null, '+
        '"sic_code":"7372", '+
        '"mailing_address":{ '+
        '"id":7757727712904979, '+
        '"street_1":"52021 Boyle Pike", '+
        '"street_2":"Suite 164", '+
        '"city":"Boston", '+
        '"county_name":"Suffolk", '+
        '"state":"MA", '+
        '"zip":"02114", '+
        '"country":"USA", '+
        '"phone":"2264329797", '+
        '"created_at":"2015-04-21T07:08:47.000-07:00", '+
        '"updated_at":"2017-01-02T00:13:24.000-08:00", '+
        '"fax":"8991424225", '+
        '"inactive":false, '+
        '"work_address":true, '+
        '"employee_count":0 '+
        '}, '+
        '"filing_address":{ '+
        '"id":7757727712904980, '+
        '"street_1":"660 Flavie Circle", '+
        '"street_2":"Apt. 340", '+
        '"city":"Cambridge", '+
        '"county_name":"Middlesex", '+
        '"state":"MA", '+
        '"zip":"02141", '+
        '"country":"USA", '+
        '"phone":"9590115024", '+
        '"created_at":"2015-04-21T07:10:17.000-07:00", '+
        '"updated_at":"2017-01-02T00:13:08.000-08:00", '+
        '"fax":"2697601503", '+
        '"inactive":false, '+
        '"work_address":true, '+
        '"employee_count":9 '+
        '}, '+
        '"benefits_address":{ '+
        '"id":7757727712904980, '+
        '"street_1":"660 Flavie Circle", '+
        '"street_2":"Apt. 340", '+
        '"city":"Cambridge", '+
        '"county_name":"Middlesex", '+
        '"state":"MA", '+
        '"zip":"02141", '+
        '"country":"USA", '+
        '"phone":"9590115024", '+
        '"created_at":"2015-04-21T07:10:17.000-07:00", '+
        '"updated_at":"2017-01-02T00:13:08.000-08:00", '+
        '"fax":"2697601503", '+
        '"inactive":false, '+
        '"work_address":true, '+
        '"employee_count":9 '+
        '}, '+
        '"number_of_eligible_ees":4, '+
        '"number_of_ineligible_ees":0, '+
        '"has_federal_cobra":null, '+
        '"is_suspended":false, '+
        '"panda_url":"http://manage.zenpayroll.dev:3000/companies/7757616923505614", '+
        '"hippo_url":"http://localhost:4001/companies/7757616923505614" '+
        '}, '+
        '"state_carriers":[ '+
        '{ '+
        '"id":234, '+
        '"name":"Blue Cross Blue Shield", '+
        '"state":"MA", '+
        '"key":"bcbs_ma", '+
        '"url":"http://localhost:4001/national_carriers/7/state_carriers/234", '+
        '"forms":[{"id":2929, '+
        '"name":"name", '+
        '"url":"url"}] '+
        '}, '+
        '{ '+
        '"id":207, '+
        '"name":"Guardian", '+
        '"state":"WA", '+
        '"key":"guardian_wa", '+
        '"url":"http://localhost:4001/national_carriers/7/state_carriers/207", '+
        '"forms":[{"id":2929, '+
        '"name":"name", '+
        '"url":"url"}] '+
        '} '+
        '], '+
        '"subscriptions":[ '+
        '{ '+
        '"id":72582, '+
        '"benefit_type":"medical", '+
        '"subscriber_id":"36166776", '+
        '"start_date":"2017-03-20", '+
        '"end_date":"2017-09-24", '+
        '"processed":true, '+
        '"enrollment_id":34528, '+
        '"employee_id":7757869431696318, '+
        '"dependent_ids":[ '+
        '{"id":121212}'+
        '], '+
        '"state_carrier_id":234, '+
        '"url":"http://localhost:4001/companies/7757616923505614/employees/7757869431696318/subscriptions/72582", '+
        '"total_premium":469.29 '+
        '} '+
        '], '+
        '"policies":[ '+
        '{ '+
        '"id":13628, '+
        '"name":"HMO Blue New England $1000 Deductible ", '+
        '"group_number":"6913996", '+
        '"plan_id":2937, '+
        '"visible":true, '+
        '"termination_policy":"last_day_of_employment", '+
        '"url":"http://localhost:4001/companies/7757616923505614/policies/13628" '+
        '} '+
        '], '+
        '"dependents":[{"id":121212, '+
        '"first_name":"first_name", '+
        '"last_name":"last_name", '+
        '"ssn":"ssn", '+
        '"birthday":"2017-03-20", '+
        '"gender":"gender", '+
        '"dependent_type":"dependent_type", '+
        '"employee_id":12012012} '+
        '], '+
        '"subscriptions_link":"http://localhost:4001/companies/7757616923505614/employees/7757869431696318/subscriptions",'+
        '"dependents_link":"http://localhost:4001/companies/7757616923505614/employees/7757869431696318/dependents" '+
        '}';
        insert hiEventRec;
        
        List<HI_Fulfillment_Event__c> fulfillmentList = new List<HI_Fulfillment_Event__c>();
        fulfillmentList.add(hiEventRec);
        HIFulfillmentEventQueue updateJob = new HIFulfillmentEventQueue(fulfillmentList);
            ID jobID = System.enqueueJob(updateJob);
        
        hiEventRec =[Select Id, Processing_State__c from HI_Fulfillment_Event__c where Id=:hiEventRec.Id];
        //system.assertEquals(IntegrationUtils.PROCESSED_STATE, hiEventRec.Processing_State__c);

    }
}