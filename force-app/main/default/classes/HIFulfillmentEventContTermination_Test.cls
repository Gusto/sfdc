/**
 * @name         HIFulfillmentEventContTermination_Test
 * @author       Chaitanya Kurra
 * @date         10-04-2020
 * @description  HIFulfillmentEventContTermination_Test is test class for HIFulfillmentEventContTermination
 *
 * @revisions    Date ------------ Name ------------ Comments
 *
 **/
@isTest
public class HIFulfillmentEventContTermination_Test {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);
		EncryptionUtils.generateKey('Master');
		List<Account> list_Account = new List<Account>();
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('7757616923607181').setName('Test Account 1').build());
		list_Account.add(new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('1370368242490000').setName('Test Account 2').build());
		insert list_Account;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test Carrier').setKey('bcbs_ma').setState('AL').build();
		insert objCarrier;

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
			.setName('Test Opportunity')
			.setAccountId(list_Account[1].Id)
			.setNumberOfEE(5)
			.setId('HIBORTRANSFER6582')
			.setBenefitsState('CA')
			.setStage('SAL')
			.setType('New TAdA Plan')
			.setCloseDate(System.today().addDays(30))
			.setOrderGenerated(false)
			.setAssignmentState('California')
			.build();
		insert objOpp;

		List<Benefit_Order__c> list_BenefitOrder = new List<Benefit_Order__c>();
		list_BenefitOrder.add(
			new TestDataFactory.BenefitOrderBuilder()
				.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR'))
				.setName('Test BENEFIT ORDER 1')
				.setAccount(list_Account[1].id)
				.setOpp(objOpp.Id)
				.setCoverageEffectiveDate(System.today())
				.setOwnerID(UserInfo.getUserId())
				.setSubmissionDeadline(System.today())
				.setStatus('Ready for Qualification')
				.setBORId('6582')
				.setStatusDetail('Owner only group')
				.build()
		);
		list_BenefitOrder.add(
			new TestDataFactory.BenefitOrderBuilder()
				.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR'))
				.setName('Test BENEFIT ORDER 2')
				.setAccount(list_Account[0].id)
				.setOpp(objOpp.Id)
				.setCoverageEffectiveDate(System.today())
				.setOwnerID(UserInfo.getUserId())
				.setSubmissionDeadline(System.today())
				.setStatus('Ready for Qualification')
				.setBORId('6582')
				.setStatusDetail('Owner only group')
				.build()
		);
		insert list_BenefitOrder;

		Utils.skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Insert Hi Fulfilment Record with event type employee_continuation_termination
	 **/
	@isTest
	static void insertHIFulfillEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_continuation_termination')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"losing_benefits_date":"2017-07-27","losing_benefits_reason":"Termination","carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Eileen","last_name":"Koepp","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1981-08-14","company_id":1370368242490000,"hired_at":"2017-07-10","employment_status":"full_time","home_address":{"id":7757727714014570,"street_1":"6198 Elaina Inlet","street_2":"Suite 639","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94109","country":"USA","phone":null,"created_at":"2017-07-05T15:26:28.000-07:00","updated_at":"2017-07-05T15:26:28.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"email":"tamia7757869449269353@uptonreynolds.com","gender":"male","panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000/employees/7757869431795591","hippo_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":1370368242490000,"name":"Homenick-Aufderhar","email":"hollie_haley7757869448810741@ernser.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"8999","mailing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"filing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"benefits_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"number_of_eligible_ees":39,"number_of_ineligible_ees":2,"has_federal_cobra":true,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000","hippo_url":"http://localhost:4001/companies/1370368242490000"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22","forms":[]},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","url":"http://localhost:4001/national_carriers/8/state_carriers/2","forms":[]}],"subscriptions":[{"id":103300,"policy_id":3043,"benefit_type":"dental","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103300","total_premium":58.36},{"id":103301,"policy_id":3044,"benefit_type":"vision","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103301","total_premium":13.44},{"id":103298,"policy_id":8401,"benefit_type":"medical","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103298","total_premium":742.56}],"policies":[{"id":3043,"name":"DentalGuard Preferred [Lob.com]","benefit_type":"dental","group_number":"501254","policy_number":null,"plan_id":163,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3043"},{"id":3044,"name":"VSP Signature Full Feature [Lob.com]","benefit_type":"vision","group_number":"501254","policy_number":null,"plan_id":164,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3044"},{"id":8401,"name":"Platinum Full PPO 0/10 OffEx","benefit_type":"medical","group_number":"W0076882","policy_number":null,"plan_id":952,"visible":true,"termination_policy":null,"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/policies/8401"}],"dependents":[],"forms":[],"alegeus":{"dca":{"subscriptions":[],"policies":[]},"fsa":{"subscriptions":[{"id":103302,"policy_id":26484,"benefit_type":"fsa","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"employee_alegeus_id":218828899,"dependent_ids":[],"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103302"}],"policies":[{"id":26484,"name":"Health FSA","benefit_type":"fsa","company_alegeus_id":964954019,"visible":true,"termination_policy":"last_day_of_employment","url":"http://localhost:4001/companies/1370368242490000/policies/26484"}]},"hsa":{}},"subscriptions_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions","dependents_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/dependents","commuter_benefit":{"id":3,"company_id":1408063107892611,"status":"processed","start_date":"2017-09-01","end_date":null,"upcoming":false,"active":true,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"fixed_amount","parking_contribution_amount":"0","transit_contribution_amount":"255"},"url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"},"commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"}}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<HI_Fulfillment_Event__c> list_HIEvents = [SELECT Message__c, Processing_State__c FROM HI_Fulfillment_Event__c WHERE ID = :objHiEvent.Id];
		System.assertEquals('Data successfully Processed', list_HIEvents[0].Message__c, 'Event unable to processed');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, list_HIEvents[0].Processing_State__c, 'Event unable to processed');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update Hi Fulfilment Record with event type employee_continuation_termination
	 **/
	@isTest
	static void updateHIFulfillEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		HIFulfillmentEventTriggerHelper.skipTrigger = true;
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_continuation_termination')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"losing_benefits_date":"2017-07-27","losing_benefits_reason":"Termination","carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Eileen","last_name":"Koepp","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1981-08-14","company_id":1370368242490000,"hired_at":"2017-07-10","employment_status":"full_time","home_address":{"id":7757727714014570,"street_1":"6198 Elaina Inlet","street_2":"Suite 639","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94109","country":"USA","phone":null,"created_at":"2017-07-05T15:26:28.000-07:00","updated_at":"2017-07-05T15:26:28.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"email":"tamia7757869449269353@uptonreynolds.com","gender":"male","panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000/employees/7757869431795591","hippo_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":1370368242490000,"name":"Homenick-Aufderhar","email":"hollie_haley7757869448810741@ernser.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"8999","mailing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"filing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"benefits_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"number_of_eligible_ees":39,"number_of_ineligible_ees":2,"has_federal_cobra":true,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/1370368242490000","hippo_url":"http://localhost:4001/companies/1370368242490000"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22"},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","url":"http://localhost:4001/national_carriers/8/state_carriers/2"}],"subscriptions":[{"id":103300,"policy_id":3043,"benefit_type":"dental","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103300","total_premium":58.36},{"id":103301,"policy_id":3044,"benefit_type":"vision","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103301","total_premium":13.44},{"id":103298,"policy_id":8401,"benefit_type":"medical","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103298","total_premium":742.56}],"policies":[{"id":3043,"name":"DentalGuard Preferred [Lob.com]","benefit_type":"dental","group_number":"501254","policy_number":null,"plan_id":163,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3043"},{"id":3044,"name":"VSP Signature Full Feature [Lob.com]","benefit_type":"vision","group_number":"501254","policy_number":null,"plan_id":164,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/1370368242490000/policies/3044"},{"id":8401,"name":"Platinum Full PPO 0/10 OffEx","benefit_type":"medical","group_number":"W0076882","policy_number":null,"plan_id":952,"visible":true,"termination_policy":null,"state_carrier_id":2,"url":"http://localhost:4001/companies/1370368242490000/policies/8401"}],"dependents":[],"alegeus":{"dca":{"subscriptions":[],"policies":[]},"fsa":{"subscriptions":[{"id":103302,"policy_id":26484,"benefit_type":"fsa","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"employee_alegeus_id":218828899,"dependent_ids":[],"url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions/103302"}],"policies":[{"id":26484,"name":"Health FSA","benefit_type":"fsa","company_alegeus_id":964954019,"visible":true,"termination_policy":"last_day_of_employment","url":"http://localhost:4001/companies/1370368242490000/policies/26484"}]},"hsa":{}},"subscriptions_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/subscriptions","dependents_url":"http://localhost:4001/companies/1370368242490000/employees/7757869431795591/dependents","commuter_benefit":{"id":3,"company_id":1408063107892611,"status":"processed","start_date":"2017-09-01","end_date":null,"upcoming":false,"active":true,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"fixed_amount","parking_contribution_amount":"0","transit_contribution_amount":"255"},"url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"},"commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"},"forms":[{"id": 1598951,"fully_mapped": false,"missing_values_by_path": ["signature.employer_signature"],"name": "2018 CA Anthem EE Termination","signed_at": null,"state_carrier_id": 22,"url": "http://hippo.gusto-dev.com:4001/attachments/forms/1598951"}]}'
			)
			.build();
		insert objHiEvent;

		HIFulfillmentEventTriggerHelper.skipTrigger = false;
		update objHiEvent;

		Test.stopTest();

		List<HI_Fulfillment_Event__c> list_HIEvents = [SELECT Message__c, Processing_State__c FROM HI_Fulfillment_Event__c WHERE ID = :objHiEvent.Id];
		System.assertEquals('Data successfully Processed', list_HIEvents[0].Message__c, 'Event unable to processed');
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, list_HIEvents[0].Processing_State__c, 'Event unable to processed');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : insert Hi Fulfilment Record with event type employee_continuation_termination & losing_benefits_reason as employee_continuation_termination
	 **/
	@isTest
	static void mapExistingContactHIFulfillEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHiEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('employee_continuation_termination')
			.setEventSubType('Termination')
			.setEventInfo(
				'{"losing_benefits_date":"2017-07-27","losing_benefits_reason":"employee_continuation_termination","carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431795591,"first_name":"Eileen","last_name":"Koepp","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1981-08-14","company_id":7757616923607181,"hired_at":"2017-07-10","employment_status":"full_time","home_address":{"id":7757727714014570,"street_1":"6198 Elaina Inlet","street_2":"Suite 639","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94109","country":"USA","phone":null,"created_at":"2017-07-05T15:26:28.000-07:00","updated_at":"2017-07-05T15:26:28.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"email":"tamia7757869449269353@uptonreynolds.com","gender":"male","panda_url":"http://manage.zenpayroll.dev:3000/companies/7757616923607181/employees/7757869431795591","hippo_url":"http://localhost:4001/companies/7757616923607181/employees/7757869431795591","payroll_type":"Exempt"},"company":{"id":7757616923607181,"name":"Homenick-Aufderhar","email":"hollie_haley7757869448810741@ernser.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"8999","mailing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"filing_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"benefits_address":{"id":1383002648546509,"street_1":"88464 Harmon Pine","street_2":"Suite 812","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94107","country":"USA","phone":"7944174714","created_at":"2013-10-28T16:24:08.000-07:00","updated_at":"2016-05-25T08:12:58.000-07:00","fax":"3587335331","inactive":false,"work_address":true,"employee_count":61},"number_of_eligible_ees":39,"number_of_ineligible_ees":2,"has_federal_cobra":true,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/7757616923607181","hippo_url":"http://localhost:4001/companies/7757616923607181"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22"},{"id":2,"name":"Blue Shield of California","state":"CA","key":"blue_shield_ca","url":"http://localhost:4001/national_carriers/8/state_carriers/2"}],"subscriptions":[{"id":103300,"policy_id":3043,"benefit_type":"dental","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923607181/employees/7757869431795591/subscriptions/103300","total_premium":58.36},{"id":103301,"policy_id":3044,"benefit_type":"vision","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923607181/employees/7757869431795591/subscriptions/103301","total_premium":13.44},{"id":103298,"policy_id":8401,"benefit_type":"medical","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"dependent_ids":[],"state_carrier_id":2,"url":"http://localhost:4001/companies/7757616923607181/employees/7757869431795591/subscriptions/103298","total_premium":742.56}],"policies":[{"id":3043,"name":"DentalGuard Preferred [Lob.com]","benefit_type":"dental","group_number":"501254","policy_number":null,"plan_id":163,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923607181/policies/3043"},{"id":3044,"name":"VSP Signature Full Feature [Lob.com]","benefit_type":"vision","group_number":"501254","policy_number":null,"plan_id":164,"visible":true,"termination_policy":null,"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923607181/policies/3044"},{"id":8401,"name":"Platinum Full PPO 0/10 OffEx","benefit_type":"medical","group_number":"W0076882","policy_number":null,"plan_id":952,"visible":true,"termination_policy":null,"state_carrier_id":2,"url":"http://localhost:4001/companies/7757616923607181/policies/8401"}],"dependents":[],"alegeus":{"dca":{"subscriptions":[],"policies":[]},"fsa":{"subscriptions":[{"id":103302,"policy_id":26484,"benefit_type":"fsa","subscriber_id":null,"start_date":null,"end_date":null,"processed":false,"enrollment_id":48910,"employee_id":7757869431795591,"employee_alegeus_id":218828899,"dependent_ids":[],"url":"http://localhost:4001/companies/7757616923607181/employees/7757869431795591/subscriptions/103302"}],"policies":[{"id":26484,"name":"Health FSA","benefit_type":"fsa","company_alegeus_id":964954019,"visible":true,"termination_policy":"last_day_of_employment","url":"http://localhost:4001/companies/7757616923607181/policies/26484"}]},"hsa":{}},"subscriptions_url":"http://localhost:4001/companies/7757616923607181/employees/7757869431795591/subscriptions","dependents_url":"http://localhost:4001/companies/7757616923607181/employees/7757869431795591/dependents","commuter_benefit":{"id":3,"company_id":1408063107892611,"status":"processed","start_date":"2017-09-01","end_date":null,"upcoming":false,"active":true,"expired":false,"waiting_period":"first_of_month_following_hire","company_contribution_inputs":{"type":"fixed_amount","parking_contribution_amount":"0","transit_contribution_amount":"255"},"url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"},"commuter_employee_benefit":{"id":4,"employee_id":7757869431686263,"commuter_benefit_id":3,"status":"processed","start_date":"2017-09-01","transit_monthly_election":"255.0","transit_monthly_contribution":"255.0","transit_monthly_deduction":"0.0","parking_monthly_election":"0.0","parking_monthly_contribution":"0.0","parking_monthly_deduction":"0.0","url":"https://hippo.gusto.com/companies/1408063107892611/employees/7757869431686263/commuter_employee_benefits/4","commuter_benefit_url":"https://hippo.gusto.com/companies/1408063107892611/commuter_benefits/3"},"forms":[{"id": 1598951,"fully_mapped": false,"missing_values_by_path": ["signature.employer_signature"],"name": "2018 CA Anthem EE Termination","signed_at": null,"state_carrier_id": 22,"url": "http://hippo.gusto-dev.com:4001/attachments/forms/1598951"}]}'
			)
			.build();
		insert objHiEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Contact.Name, Contact.Email, RecordType.Name FROM Case WHERE Account.ZP_Company_ID__c = '7757616923607181' AND ContactId != NULL];
		System.assertEquals('tamia7757869449269353@uptonreynolds.com', list_Cases[0].Contact.Email, 'Contact not map with case.');
	}
}