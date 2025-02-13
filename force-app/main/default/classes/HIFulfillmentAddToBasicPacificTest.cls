@isTest
private class HIFulfillmentAddToBasicPacificTest {

    @TestSetup
    static void dataSetupMethod(){
        Blob key = EncryptionUtils.generateKey('Master');
        List<Account> accList = new List<Account>();
        Account testAcc = new Account( ZP_Company_ID__c = '7757616923575671',  Name  = 'Test Account1'   );
        accList.add(testAcc);
        Account testAcc2 = new Account(  ZP_Company_ID__c = '1370368242490000',   Name  = 'Test Account2' );
        accList.add(testAcc2);
        insert accList;
    }

    @isTest
    static void insertFulfillment(){
        HIFulfillmentEventTriggerHelper.queue = true;
        CaseTriggerHelper.skipTrigger=true;
        test.startTest();
        HI_Fulfillment_Event__c hiEventRec = new HI_Fulfillment_Event__c();
        hiEventRec.id__c = 'Test321';
        hiEventRec.Event_Type__c = 'add_to_basic_pacific';
        hiEventRec.Event_Info__c = '{"employee":{"id":7757869432513137,"first_name":"Chandra","last_name":"Schamberger","middle_initial":"","status":"Terminated","ssn":"123456789","birthday":"1950-07-26","company_id":7757616923575671,"hired_at":"2019-01-02","employment_status":"full_time","home_address":{"id":7757869432673856,"fax":"6805200940","zip":"55422","city":"Minneapolis","phone":"7248216928","state":"MN","country":"USA","inactive":false,"street_1":"3030 Kylie Forges","street_2":"Suite 920","created_at":"2018-12-28T09:44:22.000-08:00","updated_at":"2018-12-28T09:44:22.000-08:00","county_name":"Hennepin","work_address":false},"work_address":{"id":7757869432001114,"fax":"1812109847","zip":"55403","city":"Minneapolis","phone":"6402367165","state":"MN","country":"USA","inactive":false,"street_1":"6170 Edelmira Haven","street_2":"Apt. 789","created_at":"2018-05-15T14:26:13.000-07:00","updated_at":"2018-05-15T14:26:13.000-07:00","county_name":"Hennepin","work_address":true},"email":"jacintoschoen@nader.biz","gender":"female","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923575671/employees/7757869432513137","hippo_url":"http://localhost:4001/companies/7757616923575671/employees/7757869432513137"},"company":{"id":7757616923575671,"name":"Abshire Inc","email":"eulah7757869448824158@purdygislason.co","salesforce_account_id":null,"work_states":["MN","NC","NJ","NY","WI"],"sic_code":"7371","mailing_address":{"id":7757869432001114,"fax":null,"zip":"55403","city":"Minneapolis","phone":"7269752985","state":"MN","country":"USA","inactive":false,"street_1":"863 Tony Bridge","street_2":"Apt. 948","created_at":"2018-05-15T14:26:13.000-07:00","updated_at":"2018-05-15T14:26:13.000-07:00","county_name":"Hennepin","work_address":true,"employee_count":30},"filing_address":{"id":7757869432001114,"fax":null,"zip":"55403","city":"Minneapolis","phone":"7269752985","state":"MN","country":"USA","inactive":false,"street_1":"863 Tony Bridge","street_2":"Apt. 948","created_at":"2018-05-15T14:26:13.000-07:00","updated_at":"2018-05-15T14:26:13.000-07:00","county_name":"Hennepin","work_address":true,"employee_count":30},"benefits_address":{"id":7757869432001114,"fax":null,"zip":"55403","city":"Minneapolis","phone":"7269752985","state":"MN","country":"USA","inactive":false,"street_1":"863 Tony Bridge","street_2":"Apt. 948","created_at":"2018-05-15T14:26:13.000-07:00","updated_at":"2018-05-15T14:26:13.000-07:00","county_name":"Hennepin","work_address":true,"employee_count":30},"number_of_eligible_ees":48,"number_of_ineligible_ees":8,"has_federal_cobra":false,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923575671","hippo_url":"http://localhost:4001/companies/7757616923575671"},"enrollees":[{"id":7757869432513137,"first_name":"Chandra","last_name":"Schamberger","middle_initial":"","status":"Terminated","ssn":"123456789","birthday":"1950-07-26","company_id":7757616923575671,"hired_at":"2019-01-02","employment_status":"full_time","home_address":{"id":7757869432673856,"fax":"6805200940","zip":"55422","city":"Minneapolis","phone":"7248216928","state":"MN","country":"USA","inactive":false,"street_1":"3030 Kylie Forges","street_2":"Suite 920","created_at":"2018-12-28T09:44:22.000-08:00","updated_at":"2018-12-28T09:44:22.000-08:00","county_name":"Hennepin","work_address":false},"work_address":{"id":7757869432001114,"fax":"1812109847","zip":"55403","city":"Minneapolis","phone":"6402367165","state":"MN","country":"USA","inactive":false,"street_1":"6170 Edelmira Haven","street_2":"Apt. 789","created_at":"2018-05-15T14:26:13.000-07:00","updated_at":"2018-05-15T14:26:13.000-07:00","county_name":"Hennepin","work_address":true},"email":"jacintoschoen@nader.biz","gender":"female","panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923575671/employees/7757869432513137","hippo_url":"http://localhost:4001/companies/7757616923575671/employees/7757869432513137"},{"id":82187,"first_name":"Cherly","last_name":"Rowe","ssn":"123456789","birthday":"1964-11-22","gender":"male","dependent_type":"child","employee_id":7757869432513137,"url":"http://localhost:4001/companies/7757616923575671/employees/7757869432513137/dependents/82187"}],"subscriptions":[{"id":555911,"policy_id":53310,"benefit_type":"dental","subscriber_id":"56788824","processing_status":"processed","start_date":"2019-02-01","end_date":"2019-06-30","enrollment_id":423512,"employee_id":7757869432513137,"dependent_ids":[82187],"state_carrier_id":653,"url":"http://localhost:4001/companies/7757616923575671/employees/7757869432513137/subscriptions/555911"},{"id":526557,"policy_id":53311,"benefit_type":"medical","subscriber_id":"88235339","processing_status":"processed","start_date":"2019-03-01","end_date":"2019-06-30","enrollment_id":365100,"employee_id":7757869432513137,"dependent_ids":[82187],"state_carrier_id":657,"url":"http://localhost:4001/companies/7757616923575671/employees/7757869432513137/subscriptions/526557"},{"id":555912,"policy_id":53313,"benefit_type":"vision","subscriber_id":"61185603","processing_status":"processed","start_date":"2019-02-01","end_date":"2019-06-30","enrollment_id":423512,"employee_id":7757869432513137,"dependent_ids":[82187],"state_carrier_id":653,"url":"http://localhost:4001/companies/7757616923575671/employees/7757869432513137/subscriptions/555912"}],"event_date":"2019-05-01","event_type":"Employee termination"}';
        insert hiEventRec;

        set<String> set_zpCompanyId = new set<string>();
        set_zpCompanyId.add('7757616923575671');
        //HIFulfillmentEventHelperFunctions.getBorTransferMap(set_zpCompanyId);
        HIFulfillmentEventHelperFunctions.getBenefitOrderMap(set_zpCompanyId);
        HIFulfillmentEventHelperFunctions.getCarrierInfo(set_zpCompanyId);
        
        
        HIFulfillmentAddToBasicPacificJSON jsonH =new HIFulfillmentAddToBasicPacificJSON();
        list<HI_Fulfillment_Event__c> hiEventRecList = [select id__c,Processing_State__c from HI_Fulfillment_Event__c Limit 1];        
        System.assertEquals(hiEventRecList.get(0).Processing_State__c,'Processed');
        
        HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'Test', new HI_Fulfillment_Event__c());       
        update hiEventRec;

        delete hiEventRec;
        undelete hiEventRec;
		test.stopTest();
    }
}