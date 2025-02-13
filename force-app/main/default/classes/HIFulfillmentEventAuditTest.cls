/**
  Author:        Robin Grover
  Company:       Gusto
  Description:   This is a test class for HIFulfillmentEventTermination

  History
  7/4/2017    Robin Grover     Initial Implementation
 11/9/2020   Rushi Ravisaheb  Fixed 101 SOQL error and formatted class
  **/
@isTest
private class HIFulfillmentEventAuditTest {
	static {
		Utils.skipTrigger(true);
		Blob blobKey = EncryptionUtils.generateKey('Master');

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account').setZPCompanyId('7757616923594875').build();
		insert objAccount;

		List<Carrier__c> list_carriers = new List<Carrier__c>();
		Carrier__c objCarrier1 = new TestDataFactory.CarrierBuilder().setName('Test Carrier1').setKey('bcbs_ma').setId('51').setState('AL').setUniqueName('Test1').build();
		list_carriers.add(objCarrier1);

		Carrier__c objCarrier2 = new TestDataFactory.CarrierBuilder().setName('Test Carrier2').setKey('bcbs_ca').setId('22').setState('AL').setUniqueName('Test2').build();
		list_carriers.add(objCarrier2);

		Carrier__c objCarrier3 = new TestDataFactory.CarrierBuilder().setName('Test Carrier3').setKey('bcbs_co').setId('259').setState('AL').setUniqueName('Test3').build();
		list_carriers.add(objCarrier3);
		insert list_carriers;

		insert new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Company').getRecordTypeId())
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('Test')
			.setEmail('test@test.com')
			.build();

		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits Change'))
			.setName('TEST OPPORTUNITY')
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setSourceID('hawaiian_ice-benefit_change_application-123444')
			.setType('New TAdA Plan')
			.setHIOppAssignmentState('California')
			.build();
		insert objOpportunity;

		BenefitOrderHelper.skipTrigger = true;
		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Schema.SObjectType.Benefit_Order__c.getRecordTypeInfosByName().get('Benefits BoR').getRecordTypeId())
			.setName('Test Benefit Order')
			.setAccount(objAccount.Id)
			.setOpp(objOpportunity.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.setStatus('Ready for Qualification')
			.setStatusDetail('Owner only group')
			.build();
		insert objBenefitOrder;

		CarrierOrderTriggerHelper.skipTrigger = true;
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();
		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR'))
			.setBenefitOrder(objBenefitOrder.Id)
			.setCarrier(objCarrier3.Id)
			.setImplementationStage(CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setBenefitTypes('Medical')
			.setSubmissionDeadline(System.today())
			.setMemberSubmissionDate(System.today())
			.setGroupSubmissionDate(System.today())
			.build();
		list_CarrierOrders.add(objCO);

		Carrier_Order__c objCO1 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR'))
			.setBenefitOrder(objBenefitOrder.Id)
			.setCarrier(objCarrier2.Id)
			.setImplementationStage(CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_QUALIFICATION)
			.setOwnerID(TicketUtil.CARRIER_IMPLEMENTATION_QUEUE_ID)
			.setBenefitTypes('Denatl')
			.setSubmissionDeadline(System.today())
			.setMemberSubmissionDate(System.today())
			.setGroupSubmissionDate(System.today())
			.build();
		list_CarrierOrders.add(objCO1);

		insert list_CarrierOrders;

		List<Case> list_Cases = new List<Case>();
		list_Cases.add(
			new TestDataFactory.CaseBuilder()
				.setAccountId(objBenefitOrder.Account__c)
				.setRecordTypeId('MF Audit')
				.setType('Subscription Still Active for FT to PT EE')
				.setSubject('benefits_status_audit_out_of_sync')
				.setOrigin('Email')
				.setStatus('New')
				.setSuppliedEmail('test1@gusto.com')
				.setDescription('Test Case Owner Change Ben Admin Update')
				.setIntegrationId('Test321')
				.setIntegrationKey('Test321')
				.setFSAUUID('123407')
				.setDCAUUID('123408')
				.setHSAUUID('123409')
				.setSelectionUUIDs('1234011;123402;123403;123404;123405;123406;123407;123408;123409')
				.setBenefitTypes('Medical;Dental;Vision;Long Term Disability;Short Term Disability;Life;FSA;DCA;HSA;')
				.setAnticipatedEffectiveDate(System.Today())
				.setMedicalUUID('1234011')
				.setDentalUUID('123402')
				.setVisionUUID('123403')
				.setLTDUUID('123404')
				.setSTDUUID('123405')
				.build()
		);

		list_Cases.add(
			new TestDataFactory.CaseBuilder()
				.setAccountId(objBenefitOrder.Account__c)
				.setRecordTypeId('MF NHE')
				.setType('NHE')
				.setSubject('benefits_status_audit_out_of_sync')
				.setOrigin('Email')
				.setStatus('New')
				.setSuppliedEmail('test1@gusto.com')
				.setDescription('Test Case Owner Change Ben Admin Update')
				.setIntegrationId('Test3211')
				.setIntegrationKey('Test3211')
				.setFSAUUID('123407')
				.setDCAUUID('123408')
				.setHSAUUID('123409')
				.setSelectionUUIDs('123401;123402;123403;123404;123405;123406;123407;123408;123409')
				.setBenefitTypes('Medical;Dental;Vision;Long Term Disability;Short Term Disability;Life;FSA;DCA;HSA;')
				.setAnticipatedEffectiveDate(System.Today())
				.setMedicalUUID('123401')
				.setDentalUUID('123402')
				.setVisionUUID('123403')
				.setLTDUUID('123404')
				.setSTDUUID('123405')
				.build()
		);

		insert list_Cases;
		Utils.skipTrigger(false);
	}

	/**
	 * @description  This method is used to test the case creation with the HI fulfillment event record - Positive case.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void insertingHIFulfillEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;
		test.startTest();
		HI_Fulfillment_Event__c objHIFulfillmentEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test4321')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type": "unprocessed_subscriptions_audit","subject": "These subscriptions have not been processed within 21 days.","items": [{"id": 98261,"policy_id": 21085,"benefit_type": "dental","subscriber_id": null,"start_date": null,"end_date": null,"processed": false,"enrollment_id": 46898,"employee_id": 7757869431783799,"dependent_ids": [],"state_carrier_id": 51,"url": "http://localhost:4001/companies/7757616923594875/employees/7757869431783799/subscriptions/98261","type": "subscription"}],"instructions": "Please make sure to submit these subscriptions to the carriers ASAP and process them when complete.","company": {"id": 7757616923594875,"name": "Thompson Inc","email": "haylee7757869449053159@wunsch.io","salesforce_account_id": null,"work_states": ["CA","NY","TX"],"sic_code": "5199","mailing_address": {"id": 7757727713638673,"street_1": "96047 Zulauf Ville","street_2": "Apt. 674","city": "New York","county_name": "New York","state": "NY","zip": "10016","country": "USA","phone": "4608470126","created_at": "2016-11-02T09:18:13.000-07:00","updated_at": "2016-11-02T09:18:13.000-07:00","fax": null,"inactive": false,"work_address": true,"employee_count": 5},"filing_address": {"id": 7757727713638673,"street_1": "96047 Zulauf Ville","street_2": "Apt. 674","city": "New York","county_name": "New York","state": "NY","zip": "10016","country": "USA","phone": "4608470126","created_at": "2016-11-02T09:18:13.000-07:00","updated_at": "2016-11-02T09:18:13.000-07:00","fax": null,"inactive": false,"work_address": true,"employee_count": 5},"benefits_address": {"id": 7757727713638673,"street_1": "96047 Zulauf Ville","street_2": "Apt. 674","city": "New York","county_name": "New York","state": "NY","zip": "10016","country": "USA","phone": "4608470126","created_at": "2016-11-02T09:18:13.000-07:00","updated_at": "2016-11-02T09:18:13.000-07:00","fax": null,"inactive": false,"work_address": true,"employee_count": 5},"number_of_eligible_ees": 5,"number_of_ineligible_ees": 0,"has_federal_cobra": null,"is_suspended": false,"panda_url": "http://manage.zenpayroll.dev:3000/companies/7757616923594875","hippo_url": "http://localhost:4001/companies/7757616923594875"},"employee": {"id": 7757869431783799,"first_name": "Meghan","last_name": "Cremin","middle_initial": "N","status": "Active","ssn": "123456789","birthday": "1987-05-22","company_id": 7757616923594875,"hired_at": "2017-06-19","employment_status": "full_time","home_address": {"id": 7757727713991060,"street_1": "7248 Luettgen Square","street_2": "Suite 664","city": "New York","county_name": "New York","state": "NY","zip": "10040","country": "USA","phone": null,"created_at": "2017-06-21T05:51:48.000-07:00","updated_at": "2017-06-21T05:51:48.000-07:00","fax": null,"inactive": false,"work_address": false},"work_address": {"id": 7757727713638673,"street_1": "96047 Zulauf Ville","street_2": "Apt. 674","city": "New York","county_name": "New York","state": "NY","zip": "10016","country": "USA","phone": "4608470126","created_at": "2016-11-02T09:18:13.000-07:00","updated_at": "2016-11-02T09:18:13.000-07:00","fax": null,"inactive": false,"work_address": true,"employee_count": 5},"email": "krystel_greenfelder7757869449255350@adams.biz","gender": "female","panda_url": "http://manage.zenpayroll.dev:3000/companies/7757616923594875/employees/7757869431783799","hippo_url": "http://localhost:4001/companies/7757616923594875/employees/7757869431783799"}}'
			)
			.build();
		insert objHIFulfillmentEvent;

		HIFulfillmentEventAuditJSON objAuditJSON = new HIFulfillmentEventAuditJSON();
		list<HI_Fulfillment_Event__c> list_HIFulfillmentEvents = [SELECT Id__c FROM HI_Fulfillment_Event__c LIMIT 1];

		List<Case> list_Cases = [SELECT Id, AccountId, Account.ZP_Company_ID__c FROM Case WHERE Integration_Id__c = 'Test4321'];
		System.assertEquals(1, list_Cases.size(), 'Case is created with related HI Event');
		System.assertEquals('7757616923594875', list_Cases[0].Account.ZP_Company_ID__c, 'Account is mapped with the Case.');

		HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'Test', new HI_Fulfillment_Event__c());

		update objHIFulfillmentEvent;
		System.assertEquals(IntegrationUtils.DEAD_STATE, [SELECT Processing_State__c FROM HI_Fulfillment_Event__c].Processing_State__c, 'Processing State does not match');

		delete objHIFulfillmentEvent;
		System.assertEquals(true, [SELECT Id FROM HI_Fulfillment_Event__c].isEmpty(), 'Fulfilment record not deleted');

		undelete objHIFulfillmentEvent;
		System.assertEquals(false, [SELECT Id FROM HI_Fulfillment_Event__c].isEmpty(), 'Fulfilment record not recovered');
		Test.stopTest();
	}

	/**
	 * @author Anurag Gautam
	 * @description  This method is used to test the case creation with the HI fulfillment event record with 'employee_ambiguous_status_periods_event' event type.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void insertingEmployeeAmbiguousStatusPeriodsEventRecord() {
		HIFulfillmentEventTriggerHelper.queue = true;

		Test.startTest();
		HI_Fulfillment_Event__c objHIFulfillmentEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test4321')
			.setEventType('employee_ambiguous_status_periods_event')
			.setEventInfo(
				'{"carrier_directory":"https://confluence.gustocorp.com/pages/viewpage.action?pageId=28803132","employee":{"id":7757869431802405,"first_name":"Spencer","last_name":"Lynch","middle_initial":"","status":"Active","ssn":"123456789","birthday":"1988-08-21","company_id":7757616923594875,"hired_at":"2017-06-26","employment_status":"full_time","home_address":{"id":7757727714023258,"street_1":"8246 Mayra Parkways","street_2":"Apt. 407","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94114","country":"USA","phone":null,"created_at":"2017-07-10T12:03:28.000-07:00","updated_at":"2017-07-10T13:46:46.000-07:00","fax":null,"inactive":false,"work_address":false},"work_address":{"id":7757727713979275,"street_1":"4376 Auer Alley","street_2":"Suite 934","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94110","country":"USA","phone":"8356676881","created_at":"2017-06-14T08:38:43.000-07:00","updated_at":"2017-06-15T15:40:57.000-07:00","fax":"5791402278","inactive":false,"work_address":true,"employee_count":9},"email":"yvette7757869449277173@schiller.com","gender":"female","panda_url":"http://manage.zenpayroll.dev:3000/companies/7757616923622642/employees/7757869431802405","hippo_url":"http://localhost:4001/companies/7757616923622642/employees/7757869431802405","payroll_type":"Nonexempt"},"company":{"id":7757616923594875,"name":"Von-Mayert","email":"kraig7757869449235925@moore.name","salesforce_account_id":null,"work_states":["CA"],"sic_code":"7379","mailing_address":{"id":7757727713979275,"street_1":"4376 Auer Alley","street_2":"Suite 934","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94110","country":"USA","phone":"8356676881","created_at":"2017-06-14T08:38:43.000-07:00","updated_at":"2017-06-15T15:40:57.000-07:00","fax":"5791402278","inactive":false,"work_address":true,"employee_count":9},"filing_address":{"id":7757727713966848,"street_1":"97040 Muller Falls","street_2":"Apt. 996","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94117","country":"USA","phone":"8570192238","created_at":"2017-06-06T15:33:00.000-07:00","updated_at":"2017-06-06T15:33:00.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":0},"benefits_address":{"id":7757727713966848,"street_1":"97040 Muller Falls","street_2":"Apt. 996","city":"San Francisco","county_name":"San Francisco","state":"CA","zip":"94117","country":"USA","phone":"8570192238","created_at":"2017-06-06T15:33:00.000-07:00","updated_at":"2017-06-06T15:33:00.000-07:00","fax":null,"inactive":false,"work_address":true,"employee_count":0},"number_of_eligible_ees":6,"number_of_ineligible_ees":3,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.zenpayroll.dev:3000/companies/7757616923622642","hippo_url":"http://localhost:4001/companies/7757616923622642"},"state_carriers":[{"id":22,"name":"Guardian","state":"CA","key":"guardian_ca","url":"http://localhost:4001/national_carriers/24/state_carriers/22","forms":[]},{"id":9,"name":"Aetna","state":"CA","key":"aetna_ca","url":"http://localhost:4001/national_carriers/1/state_carriers/9","forms":[]}],"subscriptions":[{"id":117012,"policy_id":29752,"benefit_type":"vision","subscriber_id":"28743542","start_date":"2017-09-01","end_date":"2018-08-31","processed":true,"enrollment_id":54353,"employee_id":7757869431802405,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923622642/employees/7757869431802405/subscriptions/117012","total_premium":11.51},{"id":117011,"policy_id":29747,"benefit_type":"dental","subscriber_id":"84007579","start_date":"2017-09-01","end_date":"2018-08-31","processed":true,"enrollment_id":54353,"employee_id":7757869431802405,"dependent_ids":[],"state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923622642/employees/7757869431802405/subscriptions/117011","total_premium":50.62},{"id":117365,"policy_id":29750,"benefit_type":"medical","subscriber_id":"72549383","start_date":"2017-09-01","end_date":"2018-08-31","processed":true,"enrollment_id":54353,"employee_id":7757869431802405,"dependent_ids":[],"state_carrier_id":9,"url":"http://localhost:4001/companies/7757616923622642/employees/7757869431802405/subscriptions/117365","total_premium":594.19}],"policies":[{"id":29752,"name":"Guardian EM Vision 12","benefit_type":"vision","group_number":"00542427","policy_number":null,"plan_id":1814,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923622642/policies/29752"},{"id":29747,"name":"Guardian EM Dental 16","benefit_type":"dental","group_number":"00542427","policy_number":null,"plan_id":2470,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923622642/policies/29747"},{"id":29750,"name":"CA Silver MC 2000 Copay","benefit_type":"medical","group_number":"105572","policy_number":null,"plan_id":2499,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":9,"url":"http://localhost:4001/companies/7757616923622642/policies/29750"}],"dependents":[],"forms":[],"subscriptions_url":"http://localhost:4001/companies/7757616923622642/employees/7757869431802405/subscriptions","dependents_url":"http://localhost:4001/companies/7757616923622642/employees/7757869431802405/dependents","source_benefits_status_periods":[{"id":35010,"employee_id":7757869431802405,"employment_id":780529,"employment_event":"hire","benefits_status":"full_time","start_date":"2017-06-26"},{"id":35014,"employee_id":7757869431802405,"employment_id":null,"employment_event":null,"benefits_status":"part_time_eligible","start_date":"2017-08-04"},{"id":35428,"employee_id":7757869431802405,"employment_id":null,"employment_event":null,"benefits_status":"full_time","start_date":"2017-08-18"}],"target_benefits_status_periods":[{"id":35010,"employee_id":7757869431802405,"employment_id":780529,"employment_event":"hire","benefits_status":"full_time","start_date":"2017-06-26"},{"id":35014,"employee_id":7757869431802405,"employment_id":null,"employment_event":null,"benefits_status":"part_time_eligible","start_date":"2017-08-04"},{"id":35428,"employee_id":7757869431802405,"employment_id":null,"employment_event":null,"benefits_status":"full_time","start_date":"2017-08-18"}],"subject":"This employee has ambiguous status period changes and may require modifications to subscriptions","instructions":"Please look at this employees old and new benefit status periods and determine if subscriptions need to be shortened, and communicate with the carriers to send or update termination notices where necessary."}'
			)
			.build();
		insert objHIFulfillmentEvent;

		HIFulfillmentEventAuditJSON objAuditJSON = new HIFulfillmentEventAuditJSON();
		list<HI_Fulfillment_Event__c> list_HIFulfillmentEvents = [SELECT Id__c FROM HI_Fulfillment_Event__c LIMIT 1];

		List<Case> list_Cases = [SELECT Id, AccountId, Description, Account.ZP_Company_ID__c FROM Case WHERE Integration_Id__c = 'Test4321'];
		System.assertEquals(2, list_Cases.size(), 'Case is created with related HI Event');
		System.assertEquals('7757616923594875', list_Cases[0].Account.ZP_Company_ID__c, 'Account is mapped with the Case.');

		for (Case objCase : list_Cases) {
			System.assertEquals(false, objCase.Description.containsIgnoreCase('Subscriber Id'), 'Subscriber Id is found');
		}

		HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'Test', new HI_Fulfillment_Event__c());

		update objHIFulfillmentEvent;
		System.assertEquals(IntegrationUtils.DEAD_STATE, [SELECT Processing_State__c FROM HI_Fulfillment_Event__c].Processing_State__c, 'Processing State does not match');

		delete objHIFulfillmentEvent;
		System.assertEquals(true, [SELECT Id FROM HI_Fulfillment_Event__c].isEmpty(), 'Fulfilment record not deleted');

		undelete objHIFulfillmentEvent;
		System.assertEquals(false, [SELECT Id FROM HI_Fulfillment_Event__c].isEmpty(), 'Fulfilment record not recovered');
		Test.stopTest();
	}

	/**
	 * @author Anurag Gautam
	 * @description  This method is used to test the case creation with the HI fulfillment event record with Company Suspension Audit.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void insertingCompanySuspensionAudit() {
		HIFulfillmentEventTriggerHelper.queue = true;

		Test.startTest();
		HI_Fulfillment_Event__c objHIFulfillmentEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test4321')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"company_suspension_audit","subject":"suspension_status_out_of_sync","items":[{"id":2029500,"uuid":123401,"policy_id":175423,"benefit_type":"medical","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933013701,"dependent_ids":[],"state_carrier_id":259,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"}}'
			)
			.build();
		insert objHIFulfillmentEvent;

		HIFulfillmentEventAuditJSON objAuditJSON = new HIFulfillmentEventAuditJSON();
		list<HI_Fulfillment_Event__c> list_HIFulfillmentEvents = [SELECT Id__c FROM HI_Fulfillment_Event__c LIMIT 1];

		List<Case> list_Cases = [SELECT Id, AccountId, Account.ZP_Company_ID__c, Description FROM Case WHERE Integration_Id__c = 'Test4321'];
		System.assertEquals(1, list_Cases.size(), 'Case is created with related HI Event');
		System.assertEquals('7757616923594875', list_Cases[0].Account.ZP_Company_ID__c, 'Account is mapped with the Case.');

		HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'Test', new HI_Fulfillment_Event__c());

		update objHIFulfillmentEvent;
		delete objHIFulfillmentEvent;
		undelete objHIFulfillmentEvent;
		Test.stopTest();
	}

	/**
	 * @author Anurag Gautam
	 * @description  This method is used to test the case creation with the HI fulfillment event record with Benefit Status Audit.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void insertingBenefitStatusAudit() {
		HIFulfillmentEventTriggerHelper.queue = true;

		Test.startTest();
		HI_Fulfillment_Event__c objHIFulfillmentEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test4321')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"benefits_status_audit","subject":"benefits_status_audit_out_of_sync","items":[{"id":2029500,"uuid":123401,"policy_id":175423,"benefit_type":"medical","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933013701,"dependent_ids":[],"state_carrier_id":259,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"}}'
			)
			.build();
		insert objHIFulfillmentEvent;

		HIFulfillmentEventAuditJSON objAuditJSON = new HIFulfillmentEventAuditJSON();
		list<HI_Fulfillment_Event__c> list_HIFulfillmentEvents = [SELECT Id__c FROM HI_Fulfillment_Event__c LIMIT 1];

		List<Case> list_Cases = [SELECT Id, AccountId, Description, Account.ZP_Company_ID__c FROM Case WHERE Integration_Id__c = 'Test4321'];
		System.assertEquals(1, list_Cases.size(), 'Case is created with related HI Event');
		System.assertEquals('7757616923594875', list_Cases[0].Account.ZP_Company_ID__c, 'Account is mapped with the Case.');

		HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'Test', new HI_Fulfillment_Event__c());

		update objHIFulfillmentEvent;
		delete objHIFulfillmentEvent;
		undelete objHIFulfillmentEvent;
		Test.stopTest();
	}

	/**
	 * @author Anurag Gautam
	 * @description  This method is used to test the case creation with the HI fulfillment event record with Other Status Audit.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void insertingOtherStatusAudit() {
		HIFulfillmentEventTriggerHelper.queue = true;

		Test.startTest();
		HI_Fulfillment_Event__c objHIFulfillmentEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test4321')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"Other_status_audit","subject":"benefits_status_audit_out_of_sync","items":[],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"},"benefit_items":[{"id":20918,"policy_id":34654}]}'
			)
			.build();
		insert objHIFulfillmentEvent;

		HIFulfillmentEventAuditJSON objAuditJSON = new HIFulfillmentEventAuditJSON();
		list<HI_Fulfillment_Event__c> list_HIFulfillmentEvents = [SELECT Id__c FROM HI_Fulfillment_Event__c LIMIT 1];

		List<Case> list_Cases = [SELECT Id, AccountId, Account.ZP_Company_ID__c, Description FROM Case WHERE Integration_Id__c = 'Test4321'];
		System.assertEquals(0, list_Cases.size(), 'Case is created with related HI Event');

		HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, 'Test', new HI_Fulfillment_Event__c());

		update objHIFulfillmentEvent;
		delete objHIFulfillmentEvent;
		undelete objHIFulfillmentEvent;
		Test.stopTest();
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using MF Audit Descriptions metadata positive case.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testMFAuditCaseCreationPositive() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c FROM Benefit_Order__c LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;
		Test.startTest();
		HI_Fulfillment_Event__c objHIEventRec = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setApplicationId('123444')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"OE and Unknown (Off-Cycle)","subject":"benefits_status_audit_out_of_sync","items":[{"id":2029500,"uuid":123401,"policy_id":175423,"benefit_type":"medical","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933013701,"dependent_ids":[],"state_carrier_id":259,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"},{"id":2029501,"uuid":123402,"policy_id":175423,"benefit_type":"dental","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}],"policies":[{"id":175423,"name":"Test Policy 1","benefit_type":"medical","application_id":23456543450017,"application_type":"New Plan","group_number":"2344301","policy_number":null,"plan_id":4970,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":259,"carrier_plan_ids":"","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924672159/policies/466777"},{"id":175423,"name":"Test Policy 2","benefit_type":"dental","application_id":23456543450017,"application_type":"New Plan","group_number":"2344302","policy_number":null,"plan_id":34448,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":22,"carrier_plan_ids":"","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924672159/policies/466772"}],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"},"benefit_items":[{"id":20918,"policy_id":34654}]}'
			)
			.build();
		insert objHIEventRec;
		Test.stopTest();

		Case objMedicalCase = [SELECT Id, Medical_UUID__c, Benefit_Types__c, Type, Benefit_Order__c, Carrier_Order__c FROM Case WHERE Integration_Key__c = 'Test321~123401'];
		System.assertEquals(objMedicalCase.Medical_UUID__c, '123401', 'Case created with the Medical UUID as : 123401');
		System.assertEquals(objMedicalCase.Benefit_Types__c, 'Medical', 'Case created with the Benefit Type as : Medical');
		System.assertEquals(objMedicalCase.Type, 'OE and Unknown (Off-Cycle)', 'Case created with the Type as : OE and Unknown (Off-Cycle)');

		Case objDentalCase = [SELECT Id, Dental_UUID__c, Benefit_Types__c, Type, Benefit_Order__c, Carrier_Order__c FROM Case WHERE Integration_Key__c = 'Test321~123402'];
		System.assertEquals(objDentalCase.Dental_UUID__c, '123402', 'Case created with the Medical UUID as : 123402');
		System.assertEquals(objDentalCase.Benefit_Types__c, 'Dental', 'Case created with the Benefit Type as : Dental');
		System.assertEquals(objDentalCase.Type, 'OE and Unknown (Off-Cycle)', 'Case created with the Type as : OE and Unknown (Off-Cycle)');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using MF Audit Descriptions metadata negative case.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testMFAuditCaseCreationNegative() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Test.startTest();
		HI_Fulfillment_Event__c objHIEventRec = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"Subscription Still Active for FT to PT EE","subject":"benefits_status_audit_out_of_sync","items":[{"id":2029500,"uuid":1234012,"policy_id":175423,"benefit_type":"medical","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933013701,"dependent_ids":[],"state_carrier_id":259,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}],"policies":[{"id":626934,"name":"Group Voluntary Dental Insurance [Active Marketing]","benefit_type":"dental","application_id":123444,"application_type":"Benefits BoR","group_number":"60868494","policy_number":null,"plan_id":82989,"visible":true,"termination_policy":"last_day_of_employment","state_carrier_id":495,"carrier_plan_ids":"","url":"https://hi-ca-audit-logic-revamp-testing.gusto-preview.com/companies/7757616924805463/policies/626934"}],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"}}'
			)
			.build();
		insert objHIEventRec;
		Test.stopTest();

		HI_Fulfillment_Event__c objHIFulfill = [SELECT Id, Message__c, Processing_State__c FROM HI_Fulfillment_Event__c WHERE Id__c = 'Test321'];

		System.assertEquals(objHIFulfill.Message__c, 'Benefit Order is Unfulfilled.', 'HI Fulfillment Event shows Error as BO is not fulfilled');
		System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Medical_UUID__c = '1234012'], 'Case is not created for the HI fulfillment Event');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test the MF Audit Case creation with Parent Case positive case.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testMFAuditCaseCreationWithParentPositive() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, Account__c FROM Benefit_Order__c LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;

		Case objCase = [SELECT Id, AccountId, Type, Anticipated_Effective_Date__c FROM Case WHERE Type = 'Subscription Still Active for FT to PT EE' LIMIT 1];
		objCase.Status = 'Closed';
		update objCase;

		Utils.skipTrigger(false);

		Test.startTest();

		HI_Fulfillment_Event__c objHIEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"Subscription Still Active for FT to PT EE","subject":"benefits_status_audit_out_of_sync","items":[{"id":2029500,"uuid":1234011,"policy_id":175423,"benefit_type":"medical","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933013701,"dependent_ids":[],"state_carrier_id":259,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"},{"id":2029501,"uuid":123402,"policy_id":175423,"benefit_type":"dental","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123403,"policy_id":175423,"benefit_type":"Vision","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123404,"policy_id":175423,"benefit_type":"long_term_disability","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123405,"policy_id":175423,"benefit_type":"short_term_disability","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123406,"policy_id":175423,"benefit_type":"life","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123407,"policy_id":175423,"benefit_type":"fsa","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123408,"policy_id":175423,"benefit_type":"dca","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123409,"policy_id":175423,"benefit_type":"hsa","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"},"benefit_items":[{"id":20918,"policy_id":34654}]}'
			)
			.build();
		insert objHIEvent;

		Test.stopTest();

		Case objCase1 = [SELECT Id, ParentId, Parent.Medical_UUID__c, Anticipated_Effective_Date__c, Special_Instructions__c FROM Case WHERE Medical_UUID__c = '1234011'];
		System.assertEquals(objCase1.ParentId, objCase.Id, 'Closed MF Audit Case set as a parent in new MF Audit Case');
		System.assertEquals(objCase1.Anticipated_Effective_Date__c, objCase.Anticipated_Effective_Date__c, 'Copy Anticipated Effective date from Parent to Child case');
		System.assertEquals(objCase1.Special_Instructions__c, HIFulfillmentEventAudit.strSpecialInstructions, 'If Parent map with MF Audit case then this field value will be populated');
		System.assertEquals(objCase1.Parent.Medical_UUID__c, null, 'UUID will updaed as blank in Parent case.');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test the MF Audit Case creation with Parent Case Negative case.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testMFAuditCaseCreationWithParentNegative() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, Account__c FROM Benefit_Order__c LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;
		Utils.skipTrigger(false);

		Test.startTest();
		HI_Fulfillment_Event__c objHIEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"Subscription Still Active for FT to PT EE","subject":"benefits_status_audit_out_of_sync","items":[{"id":2029500,"uuid":1234011,"policy_id":175423,"benefit_type":"medical","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933013701,"dependent_ids":[],"state_carrier_id":259,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"},"benefit_items":[{"id":20918,"policy_id":34654}]}'
			)
			.build();
		insert objHIEvent;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, ParentId, Selection_UUIDs__c, Special_Instructions__c FROM Case WHERE Medical_UUID__c = '1234011' LIMIT 1];
		System.assertEquals(list_Cases[0].ParentId, null, 'Parent Id on case is blank');
		System.assert(list_Cases[0].Selection_UUIDs__c.contains('123401'), 'Case is created with the Selection UUID as : 123401');
		System.assertEquals(list_Cases[0].Special_Instructions__c, null, 'Special Instructions field is blank in case record.');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test the MF Audit Case creation with Parent MF NHE Case - positive case.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testMFNHEAsParentPositive() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, Account__c FROM Benefit_Order__c LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;

		Case objCase = [SELECT Id, AccountId, Type, Anticipated_Effective_Date__c FROM Case WHERE Type = 'NHE' LIMIT 1];
		objCase.Status = 'Closed';
		update objCase;

		Utils.skipTrigger(false);

		Test.startTest();

		MF_Audit_Descriptions__mdt objMDT = [
			SELECT Audit_Type__c, Description__c, Relative_Object__c, Parent_Cases__c
			FROM MF_Audit_Descriptions__mdt
			WHERE Audit_Type__c = 'Unprocessed NHE Selection'
			LIMIT 1
		];
		String strAuditType = 'Unprocessed NHE Selection';
		if (objMDT != null) {
			strAuditType = objMDT.Audit_Type__c;
		}

		HI_Fulfillment_Event__c objHIEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test3211')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"' +
					strAuditType +
					'","subject":"benefits_status_audit_out_of_sync","items":[{"id":2029500,"uuid":123401,"policy_id":175423,"benefit_type":"medical","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933013701,"dependent_ids":[],"state_carrier_id":259,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"},{"id":2029501,"uuid":123402,"policy_id":175423,"benefit_type":"dental","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123403,"policy_id":175423,"benefit_type":"Vision","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123404,"policy_id":175423,"benefit_type":"long_term_disability","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123405,"policy_id":175423,"benefit_type":"short_term_disability","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123406,"policy_id":175423,"benefit_type":"life","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123407,"policy_id":175423,"benefit_type":"fsa","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123408,"policy_id":175423,"benefit_type":"dca","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123409,"policy_id":175423,"benefit_type":"hsa","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"},"benefit_items":[{"id":20918,"policy_id":34654}]}'
			)
			.build();
		insert objHIEvent;

		Test.stopTest();

		Case objCase1 = [
			SELECT Id, ParentId, Parent.Medical_UUID__c, Parent.RecordTypeId, Anticipated_Effective_Date__c, RecordType.Name, Special_Instructions__c
			FROM Case
			WHERE Medical_UUID__c = '123401' AND RecordType.Name = 'MF Audit'
		];
		System.assertEquals(objCase1.ParentId, objCase.Id, 'Existing NHE Case set as a parent in MF Audit Case');
		System.assertEquals(objCase1.Anticipated_Effective_Date__c, objCase.Anticipated_Effective_Date__c, 'Copy Anticipated Effective date from Parent to Child case');
		System.assertEquals(objCase1.Special_Instructions__c, HIFulfillmentEventAudit.strSpecialInstructions, 'If Parent map with MF Audit case then this field value will be populated');
		System.assertEquals(objCase1.Parent.RecordTypeId, HIEnrollmentEventUtility.CASE_RT_ID_MF_NHE);
		System.assertEquals(objCase1.Parent.Medical_UUID__c, '123401', 'UUID will not updaed as blank in Parent MF NHE case.');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test the MF Audit Case creation with Parent MF NHE Case - negative case.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testMFNHEAsParentNegative() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, Account__c FROM Benefit_Order__c LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;

		Case objCase = [SELECT Id, AccountId, Type FROM Case WHERE Type = 'NHE' LIMIT 1];
		Utils.skipTrigger(false);

		Test.startTest();
		MF_Audit_Descriptions__mdt objMDT = [
			SELECT Audit_Type__c, Description__c, Relative_Object__c, Parent_Cases__c
			FROM MF_Audit_Descriptions__mdt
			WHERE Audit_Type__c = 'Unprocessed NHE Selection'
			LIMIT 1
		];
		String strAuditType = 'Unprocessed NHE Selection';
		if (objMDT != null) {
			strAuditType = objMDT.Audit_Type__c;
		}

		HI_Fulfillment_Event__c objHIEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test3211')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"' +
					strAuditType +
					'","subject":"benefits_status_audit_out_of_sync","items":[{"id":2029500,"uuid":123401,"policy_id":175423,"benefit_type":"medical","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933013701,"dependent_ids":[],"state_carrier_id":259,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"},{"id":2029501,"uuid":123402,"policy_id":175423,"benefit_type":"dental","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123403,"policy_id":175423,"benefit_type":"Vision","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123404,"policy_id":175423,"benefit_type":"long_term_disability","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123405,"policy_id":175423,"benefit_type":"short_term_disability","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123406,"policy_id":175423,"benefit_type":"life","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123407,"policy_id":175423,"benefit_type":"fsa","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123408,"policy_id":175423,"benefit_type":"dca","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}, {"id":2029501,"uuid":123409,"policy_id":175423,"benefit_type":"hsa","subscriber_id":null,"processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":893286,"employee_id":933017201,"dependent_ids":[],"state_carrier_id":22,"url":"https://hippo.gusto.com/companies/7757616923723269/employees/7757869434138614/selections/2029500","type":"benefit_item"}],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":{"hippo_url":"http://localhost:4001/companies/7757616923480535"},"benefit_items":[{"id":20918,"policy_id":34654}]}'
			)
			.build();
		insert objHIEvent;

		Test.stopTest();

		objHIEvent = [SELECT Id, Message__c FROM HI_Fulfillment_Event__c WHERE Id = :objHIEvent.Id];
		String strMgs = 'MF NHE - Case already open ' + objCase.Id;
		System.assert(objHIEvent.Message__c == strMgs, 'Case is not created as it found open MF NHE Case');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using MF Audit Descriptions metadata positive case Phase 2.
	 * @param        null
	 * @return       null
	 **/

	@isTest
	static void testMFAuditCaseCreationPhase2() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c FROM Benefit_Order__c LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;
		Test.startTest();
		HI_Fulfillment_Event__c objHIEventRec = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setApplicationId('123444')
			.setEventType('audit')
			.setEventInfo(
				'{"audit_type":"Error Processing Subscription","subject":"Failed to process selection: There already exists a subscription that starts on or after 2020-08-01","items":[{"id":1870902,"policy_id":135912,"policy_uuid":"020deeb2-3e09-493b-9645-c63acb345ce4","benefit_type":"dental","subscriber_id":"XXX-XX-9659","processing_status":"not_started","start_date":null,"end_date":null,"enrollment_id":836530,"employee_id":7757869432700155,"dependent_ids":[107220],"state_carrier_id":259,"url":"http://hippo.gusto-dev.com:4001/companies/7757616923766124/employees/7757869432700155/selections/1870902","uuid":"dd136f89-bb17-42ef-a0a1-3653a617d375","type":"benefit_item"}],"policies":[{"id":135912,"name":"Delta Dental Platinum Option","benefit_type":"dental","application_id":123444,"application_type":"Benefits BoR","group_number":"45279023","policy_number":null,"plan_id":13006,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":259,"carrier_plan_ids":"","url":"http://hippo.gusto-dev.com:4001/companies/7757616923766124/policies/135912"}],"instructions":null,"company":{"id":7757616923594875,"name":"Harris-Lowe","email":"kiersten.bernhard@predovic.name","salesforce_account_id":null,"work_states":["IL"],"sic_code":"8699","mailing_address":{"id":7757869456902559,"fax":"3069728860","zip":"60606","city":"Chicago","phone":"2785423675","state":"IL","country":"USA","inactive":false,"street_1":"1912 Mosciski Lights","street_2":"Apt. 443","created_at":"2020-11-03T08:01:33-08:00","updated_at":"2020-11-03T08:01:33-08:00","county_name":"Cook","work_address":true,"employee_count":2},"filing_address":{"id":7757869456902559,"fax":"6439148612","zip":"60606","city":"Chicago","phone":"5449303416","state":"IL","country":"USA","inactive":false,"street_1":"1678 Klein Inlet","street_2":"Apt. 815","created_at":"2020-11-03T08:01:33-08:00","updated_at":"2020-11-03T08:01:33-08:00","county_name":"Cook","work_address":true,"employee_count":2},"benefits_address":{"id":7757869456902559,"fax":"6439148612","zip":"60606","city":"Chicago","phone":"5449303416","state":"IL","country":"USA","inactive":false,"street_1":"1678 Klein Inlet","street_2":"Apt. 815","created_at":"2020-11-03T08:01:33-08:00","updated_at":"2020-11-03T08:01:33-08:00","county_name":"Cook","work_address":true,"employee_count":2},"number_of_eligible_ees":8,"number_of_ineligible_ees":1,"has_federal_cobra":false,"is_suspended":false,"panda_url":"http://app.gusto-dev.com:3000/companies/7757616923766124","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923766124","google_drive_folder_url":"No Google Drive folder set up"},"employee":{"id":7757869432700155,"first_name":"Delia","last_name":"Konopelski","middle_initial":"V","status":"Terminated","ssn":null,"birthday":"1971-05-30","company_id":7757616923594875,"hired_at":"2018-07-30","employment_status":"full_time","home_address":{"id":119440359737526,"fax":null,"zip":"20116-6381","city":"McGlynnmouth","phone":null,"state":"MI","country":"Paraguay","inactive":false,"street_1":"9331 Connelly Inlet","street_2":"Suite 390","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"West Damienmouth","work_address":null},"work_address":{"id":352171652060806,"fax":null,"zip":"07139-7702","city":"North Dinotown","phone":"4533165253","state":"MN","country":"Ecuador","inactive":false,"street_1":"419 Marks Crossing","street_2":"Apt. 966","created_at":"2000-01-01","updated_at":"2000-01-01","county_name":"Boyerview","work_address":null},"email":"test@test.com","gender":"female","annual_salary":"82000.0","benefits_eligibility_date":"2018-07-30","panda_url":"http://app.gusto-dev.com:3000/companies/7757616923766124/employees/7757869432700155","hippo_url":"http://hippo.gusto-dev.com:4001/companies/7757616923766124/employees/7757869432700155"}}'
			)
			.build();
		insert objHIEventRec;
		Test.stopTest();

		Case objDentalCase = [
			SELECT Id, Dental_UUID__c, Benefit_Types__c, Type, Benefit_Order__c, Carrier_Order__c
			FROM Case
			WHERE Integration_Key__c = 'Test321~dd136f89-bb17-42ef-a0a1-3653a617d375'
		];
		System.assertEquals(objDentalCase.Dental_UUID__c, 'dd136f89-bb17-42ef-a0a1-3653a617d375', 'Case created with the Medical UUID as : dd136f89-bb17-42ef-a0a1-3653a617d375');
		System.assertEquals(objDentalCase.Benefit_Types__c, 'Dental', 'Case created with the Benefit Type as : Dental');
		System.assertEquals(objDentalCase.Type, 'Error Processing Subscription', 'Case created with the Type as : Error Processing Subscription');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using policies.
	 * @param        null
	 * @return       null
	 **/

	@isTest
	static void testMFAuditCaseCreationPolicies() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, Account__c FROM Benefit_Order__c LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;

		Utils.skipTrigger(false);

		Test.startTest();
		MF_Audit_Descriptions__mdt objMDT = [
			SELECT Audit_Type__c, Description__c, Relative_Object__c, Parent_Cases__c, Audit_Payload__c
			FROM MF_Audit_Descriptions__mdt
			WHERE Audit_Type__c = 'Reconciliation Incorrect Group Information'
			LIMIT 1
		];
		String strAuditType = 'Reconciliation Incorrect Group Information';
		if (objMDT != null) {
			strAuditType = objMDT.Audit_Type__c;
		}
		List<case> list_casesExisting = [SELECT Id FROM CASE WHERE Benefit_Order__c = :objBO.Id];
		System.assertEquals(0, list_casesExisting.size(), 'No existing case should be there');
		HI_Fulfillment_Event__c objHIEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('audit')
			.setApplicationId('123444')
			.setEventInfo(
				'{"audit_type":"' +
					strAuditType +
					'","subject":"benefits_status_audit_out_of_sync","policies":[{"id":29752,"name":"Guardian EM Vision 12","benefit_type":"vision","group_number":"00542427","policy_number":null,"plan_id":1814,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923622642/policies/29752"},{"id":29747,"name":"Guardian EM Dental 16","benefit_type":"dental","group_number":"00542427","policy_number":null,"plan_id":2470,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":25,"url":"http://localhost:4001/companies/7757616923622642/policies/29747"}],"items":[],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":null}'
			)
			.build();
		insert objHIEvent;
		List<case> list_cases = [SELECT Id FROM CASE WHERE Benefit_Order__c = :objBO.Id];
		System.assertEquals(2, list_cases.size(), 'At least 2 case need to be created for 2 Policies');
		Test.stopTest();
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using policies with Existing Parent
	 * @param        null
	 * @return       null
	 **/

	@isTest
	static void testMFAuditCaseCreationPolicieswithExistingParent() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Account objAccount = [SELECT id, ZP_Company_ID__c FROM Account LIMIT 1];
		Contact objContact = [SELECT id, Employee_Id__c FROM Contact WHERE AccountId = :objAccount.id LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, Type FROM Opportunity WHERE AccountId = :objAccount.Id LIMIT 1];
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, Account__c FROM Benefit_Order__c WHERE Opportunity__c = :objOpportunity.Id LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;

		Utils.skipTrigger(false);

		Test.startTest();
		MF_Audit_Descriptions__mdt objMDT = [
			SELECT Audit_Type__c, Description__c, Relative_Object__c, Parent_Cases__c, Audit_Payload__c
			FROM MF_Audit_Descriptions__mdt
			WHERE Audit_Type__c = 'Reconciliation Incorrect Group Information'
			LIMIT 1
		];
		String strAuditType = 'Reconciliation Incorrect Group Information';
		if (objMDT != null) {
			strAuditType = objMDT.Audit_Type__c;
		}
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Id__c = :'22' LIMIT 1];
		Case objNewCaseParent = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('MF Audit')
			.setAccountId(objAccount.Id)
			.setIdCarrier(objCarrier.id)
			.setType(objMDT.Audit_Type__c)
			.setBenefitOrder(objBO.id)
			.setIntegrationId('ABCD~123456778')
			.setIntegrationKey('ABCD~123456778')
			.setStatus('Closed')
			.build();
		objNewCaseParent.Error_Origin__c = 'ER Error';
		objNewCaseParent.Company_ID__c = '7757616923594875';
		insert objNewCaseParent;

		HI_Fulfillment_Event__c objHIEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('audit')
			.setApplicationId('123444')
			.setCompanyId('7757616923594875')
			.setEventInfo(
				'{"audit_type":"' +
					strAuditType +
					'","subject":"benefits_status_audit_out_of_sync","policies":[{"id":29752,"name":"Guardian EM Vision 12","benefit_type":"vision","application_id": "123444","group_number":"00542427","policy_number":null,"plan_id":1814,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923622642/policies/29752"},{"id":29747,"name":"Guardian EM Dental 16","benefit_type":"dental","application_id": "123444","group_number":"00542427","policy_number":null,"plan_id":2470,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":25,"url":"http://localhost:4001/companies/7757616923622642/policies/29747"}],"items":[],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757616923594875,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":null}'
			)
			.build();
		insert objHIEvent;
		List<Case> list_Cases = [SELECT Id, Special_Instructions__c FROM Case WHERE ParentId = :objNewCaseParent.Id];
		System.assertEquals(1, list_Cases.size(), 'At least 1 case need to be created ');
		System.assertEquals(list_Cases[0].Special_Instructions__c, HIFulfillmentEventAudit.strReconciliationSpecialInstructions, 'Special Instruction did not match');
		Test.stopTest();
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to test the Mf Audit Case creation using policies with Existing cases
	 * @param        null
	 * @return       null
	 **/

	@isTest
	static void testMFAuditCaseCreationPolicieswithExistingCases() {
		HIFulfillmentEventTriggerHelper.queue = true;
		Utils.skipTrigger(true);
		Account objAccount = [SELECT id, ZP_Company_ID__c FROM Account LIMIT 1];
		Contact objContact = [SELECT id, Employee_Id__c FROM Contact WHERE AccountId = :objAccount.id LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, Type FROM Opportunity WHERE AccountId = :objAccount.Id LIMIT 1];
		Benefit_Order__c objBO = [SELECT Id, Order_Status__c, Account__c FROM Benefit_Order__c WHERE Opportunity__c = :objOpportunity.Id LIMIT 1];
		objBO.Order_Status__c = 'Fulfilled';
		update objBO;

		Utils.skipTrigger(false);

		Test.startTest();
		MF_Audit_Descriptions__mdt objMDT = [
			SELECT Audit_Type__c, Description__c, Relative_Object__c, Parent_Cases__c, Audit_Payload__c
			FROM MF_Audit_Descriptions__mdt
			WHERE Audit_Type__c = 'Reconciliation Incorrect Group Information'
			LIMIT 1
		];
		String strAuditType = 'Reconciliation Incorrect Group Information';
		if (objMDT != null) {
			strAuditType = objMDT.Audit_Type__c;
		}
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c WHERE Id__c = :'22' LIMIT 1];
		Case objNewCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('MF Audit')
			.setAccountId(objAccount.Id)
			.setIdCarrier(objCarrier.id)
			.setType(objMDT.Audit_Type__c)
			.setBenefitOrder(objBO.id)
			.setIntegrationId('ABCD~123456778')
			.setIntegrationKey('ABCD~123456778')
			.setStatus('New')
			.build();
		objNewCase.Company_ID__c = '7757616923594875';
		insert objNewCase;
		HI_Fulfillment_Event__c objHIEvent = new TestDataFactory.HIFulfillmentEventBuilder()
			.setId('Test321')
			.setEventType('audit')
			.setApplicationId('123444')
			.setCompanyId('7757616923594875')
			.setEventInfo(
				'{"audit_type":"' +
					strAuditType +
					'","subject":"benefits_status_audit_out_of_sync","policies":[{"id":29752,"name":"Guardian EM Vision 12","benefit_type":"vision","application_id": "123444","group_number":"00542427","policy_number":null,"plan_id":1814,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":22,"url":"http://localhost:4001/companies/7757616923622642/policies/29752"},{"id":29747,"name":"Guardian EM Dental 16","benefit_type":"dental","application_id": "123444","group_number":"00542427","policy_number":null,"plan_id":2470,"visible":true,"termination_policy":"last_day_of_month_on_or_after_termination","state_carrier_id":25,"url":"http://localhost:4001/companies/7757616923622642/policies/29747"}],"items":[],"instructions":null,"company":{"id":7757616923594875,"name":"Jaskolski, Nicolas and Feil","email":"edyth.hills7757869448393078@marvin.net","salesforce_account_id":null,"work_states":["IL","MA","NY"],"sic_code":"3699","mailing_address":{"id":7757616923594875,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"filing_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"benefits_address":{"id":7757727712754212,"street_1":"834 Reilly Junctions","street_2":"Apt. 915","city":"Chicago","county_name":"Cook","state":"IL","zip":"60640","country":"USA","phone":"8237165337","created_at":"2014-11-02T16:31:11.000-08:00","updated_at":"2014-11-02T16:31:11.000-08:00","fax":"7757527788","inactive":false,"work_address":true,"employee_count":11},"number_of_eligible_ees":8,"number_of_ineligible_ees":7,"has_federal_cobra":null,"is_suspended":false,"panda_url":"http://manage.gusto-dev.com:3000/companies/7757616923480535","hippo_url":"http://localhost:4001/companies/7757616923480535"},"employee":null}'
			)
			.build();
		insert objHIEvent;
		Case objCase = [SELECT Id, Special_Instructions__c FROM Case WHERE Id = :objNewCase.Id];
		System.assertEquals(objCase.Special_Instructions__c, HIFulfillmentEventAudit.strReconciliationSpecialInstructions, 'Special Instruction did not match');
		Test.stopTest();
	}
}