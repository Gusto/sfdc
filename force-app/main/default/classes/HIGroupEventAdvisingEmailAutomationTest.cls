/*
    Author:PR
    Date: Jan/28/2021
    Class Name: HIGroupEventAdvisingEmailAutomationTest.cls
    Description: This class is used as a code coverage test class for 
                "HIGroupEventAdvisingEmailAutomation.cls"
*/

@isTest
public with sharing class HIGroupEventAdvisingEmailAutomationTest {
	public static String STR_JSON_INTRO =
		'{"application_id": 7239712,"application_type": "renewal", "company_id": 72397, "survey_completed_by": 70002, "tada_interest_from_survey": true,' +
		' "selection_deadline": "2021-01-14", "benefit_address" : {"street_1": "1234 Not a street", "street_2": "test street","city": "Fresno", "state": "CA","zip": "94010", "country": "USA" }, "scorp": false }';

	public static String strInvalidDate = '0023-01-27';
	public static String STR_SELECTION_JSON =
		'{"application_id": 7239712,"application_type": "renewal", "company_id": 72397, "survey_completed_by": 70002, "tada_interest_from_survey": true,' +
		' "selection_deadline": "' + strInvalidDate + '", "benefit_address" : {"street_1": "1234 Not a street", "street_2": "test street","city": "Fresno", "state": "CA","zip": "94010", "country": "USA" }, "scorp": false }';

	public static String STR_JSON_INTRO_NEGATIVE =
		'{"application_id": 7239712,"application_type": "renewal", "company_id": 72397, "survey_completed_by": 70002, "tada_interest_from_survey": true,' +
		' "selection_deadline": "", "benefit_address" : {"street_1": "", "street_2": "","city": "", "state": "","zip": "", "country": "" }, "scorp": false }';
	public static String STR_JSON_INTRO_SCORP =
		'{"application_id": 7239712,"application_type": "renewal", "company_id": 72397, "survey_completed_by": 70002, "tada_interest_from_survey": false,' +
		' "selection_deadline": "", "benefit_address" : {"street_1": "", "street_2": "","city": "", "state": "","zip": "", "country": "" }, "scorp": true }';
	public static String STR_JSON_INTRO_SCORPTADAS =
		'{"application_id": 7239712,"application_type": "renewal", "company_id": 72397, "survey_completed_by": 70002, "tada_interest_from_survey": true,' +
		' "selection_deadline": "", "benefit_address" : {"street_1": "", "street_2": "","city": "", "state": "","zip": "", "country": "" }, "scorp": true }';

	public static String STR_JSON_FOLLOWUP_NONZERO = '{"company_id": 72397,"application_id": 7239712,"application_type": "renewal","selection_deadline": "2021-01-25","number_of_days_remaining": 4}';
	public static String STR_JSON_FOLLOWUP_ZERO =
		'{ "company_id": 72397,"application_id": 7239712,"application_type": "renewal","selection_deadline": "2021-03-25",' +
		'"number_of_days_remaining": 0, "medical": [ { "carrier_name": "UnitedHealthcare", "plan_name": "UHC TX Gold Choice Plus 3500 - ' +
		'CEE9" }], "dental": [{"carrier_name": "Beam", "plan_name": "Beam Smart Premium Plus 100/80/50/50-1500 + Adult Ortho (4A)" }, ' +
		'{"carrier_name": "BCBS", "plan_name": "BCBS Smart Premium Plus 100/80/50/50-1500 + Adult Ortho (4A)" }],  ' +
		' "vision": [{"carrier_name": "Beam", "plan_name": "Beam Smart Premium Plus 100/80/50/50-1500 + Adult Ortho (4A)" }], ' +
		'"life": [{"carrier_name": "Beam", "plan_name": "Beam Smart Premium Plus 100/80/50/50-1500 + Adult Ortho (4A)" }], ' +
		' "long_term_disability": [{"carrier_name": "Beam", "plan_name": "Beam Smart Premium Plus 100/80/50/50-1500 + Adult Ortho (4A)" }], ' +
		' "short_term_disability": [ {"carrier_name": "HUMANA","plan_name": "HUMANA Smart Premium Plus 100/80/50/50-1500 + Adult Ortho (4A)" } ], "tadas": "fsa,dca"}';
	public static String STR_JSON_AUTO_RENEWAL = '{"company_id":72397,"application_id":7239712,"application_type":"renewal","selection_deadline":"2021-01-25"}';
	public static String STR_JSON_ERROR = '{"application_id":7239712,"application_type":"renewal","selection_deadline":"2021-01"}';
	public static String STR_JSON_LF_INTRO = '{"company_id":72397,"application_id":7239712,"application_type":"renewal","selection_deadline":"2024-11-06","benefit_address":{"street_1":"1 Street","street_2":"Apt 1","city":"San Francisco","state":"CA","zip":"94105","country":"US"},"alternate_recommendation_type":"carrier_switch","default_renewal_rate_change":"16%","alternate_package_savings":"28%","default_cost_breakdown_pdf":"zp/link/to/default_package_123.pdf","alternate_cost_breakdown_pdf":"zp/link/to/alternate_package_456.pdf","alternate_package_carrier":"United Healthcare"}';
	public static String STR_JSON_LF_AUTO_RENEWAL = '{"company_id":72397,"application_id":7239712,"application_type":"renewal","selection_deadline":"2025-12-09"}';

	@TestSetup
	static void createTestData() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		//Create Email Macro record
		List<Email_Macro__c> list_EmailMacro = new List<Email_Macro__c>();
		list_EmailMacro.add(new TestDataFactory.EmailMacroBuilder().setMacroIdentifier('inbound_support_pilot_false').setBody('Test Body').build());
		list_EmailMacro.add(new TestDataFactory.EmailMacroBuilder().setMacroIdentifier('inbound_support_pilot_true').setBody('Test Body 123 - please call 415-463-1380').build());
		list_EmailMacro.add(new TestDataFactory.EmailMacroBuilder().setMacroIdentifier('advising_team_signature').setBody('Regards, Advising Team').build());
		list_EmailMacro.add(new TestDataFactory.EmailMacroBuilder().setMacroIdentifier('level_funded_intro_email_carrier_switch_non-TX').setBody(' level_funded_intro_email Regards, Advising Team').build());

		insert list_EmailMacro;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account').setZPCompanyId('72397').build();
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setName('Test Opp')
			.setStage('STAGENAME')
			.setCloseDate(System.Today())
			.setSourceID('hawaiian_ice-renewal-7239712')
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits Renewal'))
			.setAccountId(objAccount.Id)
			.setRegion('East')
			.setOWnerRoleName('Benefits Designer')
			.build();
		insert objOpportunity;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setFirstName('Test First Name')
			.setLastName('Test Last Name')
			.setAccountId(objAccount.Id)
			.setEmail('testuser001@fake.org')
			.setZPUserId('70001')
			.setEmployeeId('10001')
			.setZPUserRole('Accountant; Benefits Admin; Contractor; Employee; Payroll Admin; Primary Payroll Admin; Signatory')
			.build();
		insert objContact;

		OpportunityContactRole objOpportunityContactRole = new TestDataFactory.OpportunityContactRoleBuilder()
			.setOpportunityId(objOpportunity.Id)
			.setContactId(objContact.Id)
			.setRole('Benefits Admin')
			.build();
		insert objOpportunityContactRole;

		//Create new contact
		Contact objContactNew = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setFirstName('Test First NameNew')
			.setLastName('Test Last Name')
			.setEmail('TestEmailNew@gmail.com')
			.setEmployeeId('10002')
			.setZPUserId('70002')
			.setAccountId(objAccount.Id)
			.setZPUserRole('Accountant; Benefits Admin; Contractor; Employee; Payroll Admin; Primary Payroll Admin; Signatory')
			.setMailingCountry('United States')
			.setMailingCity('San Diego')
			.setMailingState('California')
			.build();
		insert objContactNew;

		insert new TestDataFactory.CaseBuilder()
			.setOpportunity(objOpportunity.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setIntegrationId('hippo-Benefits_Renewal-' + string.valueof(objOpportunity.Id))
			.setAutomatedAdvisingEmailsOFF(false)
			.build();
	}

	/**
	 * @description  This method is used to test HI Group event process for `renewal_intro_email` Event type.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailIntroEmailTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO)
			.setEventInfo(STR_JSON_INTRO)
			.build();

		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c, StageName FROM Opportunity LIMIT 1];

		System.assert(list_Opp.size() > 0, 'Opportunity is Present.');
	}

	/**
	 * @description  This method is used to test HI Group event process for `renewal_followup_email` Event type.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailFollowUpEmailTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae82')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP)
			.setEventInfo(STR_JSON_FOLLOWUP_ZERO)
			.build();
		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c FROM Opportunity LIMIT 1];

		System.assert(list_Opp.size() > 0, 'Opportunity is present');
		System.assert(list_Opp.get(0).Advising_Email__c != null, 'Advising_Email__c is not null');
		System.assert(list_Opp.get(0).Advising_Email__c.IndexOf('Final Reminder Email') > -1, 'Advising_Email__c has value as :Final Reminder Email');
	}

	/**
	 * @description  This method is used to test HI Group event process to send EmailMessage for `renewal_intro_email` Event type.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailIntroEmailPhoneQueueTest() {
		OpportunityTriggerHelper.skipTrigger = true;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae893')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO)
			.setEventInfo(STR_JSON_INTRO)
			.build();
		Test.startTest();
		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c, Region__c FROM Opportunity LIMIT 1];
		list_Opp[0].Advising_Email__c = null;
		list_Opp[0].Region__c = 'East';
		update list_Opp;

		insert objHIGroupEvent;
		Test.stopTest();

		List<EmailMessage> list_EmailMessage = [SELECT Id, htmlBody FROM EmailMessage ORDER BY Createddate DESC LIMIT 1];
		if(OrganizationUtilities.canSendEmails()){
			System.assert(list_EmailMessage.size() > 0, 'Email is send.');
			System.assert(list_EmailMessage.get(0).htmlBody != null, 'Email Body is not equal to null.');
		}
	}

	/**
	 * @description  This method is used to test HI Group event process to process for `autorenewal_email` Event type of assignment of Advising_Email__c and Reason_for_Advising__c.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailAutoRenewalEmailTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae83')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_FINAL)
			.setEventInfo(STR_JSON_AUTO_RENEWAL)
			.build();
		Test.startTest();
		insert objHIGroupEvent;

		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c, Reason_for_Advising__c FROM Opportunity LIMIT 1];
		System.assert(list_Opp.size() > 0, 'Opportunity is present');
		System.assert((list_Opp.get(0).Advising_Email__c != null), 'Advising_Email__c is not null');
		System.assert(list_Opp.get(0).Advising_Email__c.IndexOf('Auto Renewal Email') > -1, ' Advising_Email__c is set as : Auto Renewal Email');
		System.assert((list_Opp[0].Reason_for_Advising__c == HIGroupEventAdvisingEmailAutomation.REASON_FOR_ADVISING), 'Reason_for_Advising__c is set as : Auto-renewed');
	}

	/**
	 * @description  This method is used to test HI Group event process for `renewal_intro_email` Event type - Negative.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailIntroEmailNegativeTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO)
			.setEventInfo(STR_JSON_INTRO_NEGATIVE)
			.build();
		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c FROM Opportunity LIMIT 1];
		objHIGroupEvent = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];

		System.assert(list_Opp.size() > 0, 'Opportunity is present.');
		System.assertEquals(objHIGroupEvent.Processing_State__c, 'Error', 'HIGroupEvent__c is in Error state.');
	}

	/**
	 * @description  This method is used to test HI Group event process for `renewal_intro_email` Event type for SCorp.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailIntroEmailScorpTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO)
			.setEventInfo(STR_JSON_INTRO_SCORP)
			.build();
		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c FROM Opportunity LIMIT 1];
		objHIGroupEvent = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];

		System.assert(list_Opp.size() > 0, 'Opportunity is present');
	}

	/**
	 * @description  This method is used to test HI Group event process for `renewal_intro_email` Event type for SCorp.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailIntroEmailScorpAndTaDaTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO)
			.setEventInfo(STR_JSON_INTRO_SCORPTADAS)
			.build();
		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c FROM Opportunity LIMIT 1];
		objHIGroupEvent = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id];

		System.assert(list_Opp.size() > 0, 'Opportunity is present');
	}

	/**
	 * @description  This method is used to test AdvisingEmailJSONWrapper for parsing the JSON.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void AdvisingEmailJsonTest() {
		Test.startTest();
		AdvisingEmailJSONWrapper objWrapper = AdvisingEmailJSONWrapper.parse(STR_JSON_AUTO_RENEWAL);
		System.assert(objWrapper.company_id != null, 'Company Id is not null.');
		Test.stopTest();
	}

	/**
	 * @description  This method is used to test HIGroupEvent__c for Error state.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void AdvisingEmailJsonNegativeTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO)
			.setEventInfo(STR_JSON_ERROR)
			.build();
		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<HIGroupEvent__c> list_Events = [SELECT Id, Processing_State__c FROM HIGroupEvent__c WHERE Processing_State__c = :IntegrationUtils.ERROR_STATE];
		System.assert(list_Events.size() > 0, 'HIGroupEvent__c is in Error state.');
	}

	/**
	 * @description  This method is used to test HI Group event process for `renewal_followup_email` Event type Negative.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailFollowUpEmailNegativeTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP)
			.setEventInfo(STR_JSON_ERROR)
			.build();
		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<HIGroupEvent__c> list_Events = [SELECT Id, Processing_State__c FROM HIGroupEvent__c WHERE Processing_State__c = :IntegrationUtils.DEAD_STATE];
		System.assert(list_Events.size() > 0, 'HIGroupEvent__c is in Dead state.');
	}

	/**
	 * @description  This method is used to test HI Group event process for `autorenewal_email` Event type Negative.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailAutoRenewalEmailNegativeTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_FINAL)
			.setEventInfo(STR_JSON_ERROR)
			.build();
		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<HIGroupEvent__c> list_Events = [SELECT Id, Processing_State__c FROM HIGroupEvent__c WHERE Processing_State__c = :IntegrationUtils.DEAD_STATE];
		System.assert(list_Events.size() > 0, 'HIGroupEvent__c is in Dead state.');
	}

	/**
	 * @description  This method is used to test HI Group event process for `renewal_intro_email` Event type for opportunity update.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailIntroEmailOpportunityUpdateFailedTest() {
		OpportunityTriggerHelper.skipTrigger = true;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO)
			.setEventInfo(STR_JSON_INTRO)
			.build();
		Test.startTest();
		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c, StageName FROM Opportunity LIMIT 1];
		list_Opp[0].StageName = 'ER Confirm';
		update list_Opp;

		insert objHIGroupEvent;
		Test.stopTest();

		List<HIGroupEvent__c> list_HIGroupEvent = [SELECT Id, EMail_Sent__c, Message__c, Processing_State__c FROM HIGroupEvent__c LIMIT 1];
		System.assert(list_HIGroupEvent.size() > 0, 'HIGroupEvent__c is present');
		if(OrganizationUtilities.canSendEmails()){
			System.assertEquals(list_HIGroupEvent[0].EMail_Sent__c, true, 'EMail_Sent__c is checked.');
		}
	}

	/**
	 * @description  This method is used to test HI Group event process for `renewal_intro_email` Event type for opportunity update.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void advisingEmailFollowUpEmailOFFTest() {
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = [SELECT Id FROM Case WHERE Automated_Advising_Emails_Off__c = FALSE LIMIT 1];
		objCase.Automated_Advising_Emails_Off__c = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae82')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP)
			.setEventInfo(STR_JSON_FOLLOWUP_ZERO)
			.setEmailType('Advising Final Reminder Email')
			.build();
		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		List<HIGroupEvent__c> list_HIGroupEvents = [SELECT Id, Email_Sent__c, Message__c, Processing_State__c FROM HIGroupEvent__c LIMIT 1];
		System.assert(list_HIGroupEvents.size() > 0, 'HIGroupEvent__c is present');
		System.assertEquals(list_HIGroupEvents[0].Email_Sent__c, false, 'Email_Sent__c is unchecked.');
		System.assertEquals(list_HIGroupEvents[0].Message__c, 'Event processed successfully but, emails are turned off for the customer.', 'Message__c is match.');
	}

	/**
	 * @description  'renewal_intro_email` Event type with invalid Selection Deadline Date.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void validateSelectionDeadlineDateTest() {
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO)
			.setEventInfo(STR_SELECTION_JSON)
			.build();

		Test.startTest();
		insert objHIGroupEvent;
		Test.stopTest();

		String strExpectedMsg = HIGroupEventAdvisingEmailAutomation.ERROR_MSG_INVALID_SELECTION_DEADLINE + strInvalidDate;
		List<HIGroupEvent__c> list_HIEvents = [SELECT Id, Processing_State__c, Message__c FROM HIGroupEvent__c WHERE Id =:objHIGroupEvent.Id];

		System.assertEquals(strExpectedMsg, list_HIEvents[0].Message__c, HIGroupEventAdvisingEmailAutomation.ERROR_MSG_INVALID_SELECTION_DEADLINE);
		System.assertEquals(IntegrationUtils.DEAD_STATE, list_HIEvents[0].Processing_State__c, HIGroupEventAdvisingEmailAutomation.ERROR_MSG_INVALID_SELECTION_DEADLINE);
	}

	/**
	 * @description  This method is used to test HI Group event process for level_funded_intro_email Event type.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void levelFundedTransitionAdvisingIntroEmail() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae81')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_INTRO_EMAIL )
			.setEventInfo(STR_JSON_LF_INTRO)
			.build();

		insert objHIGroupEvent;
		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c, StageName FROM Opportunity LIMIT 1];

		System.assert(list_Opp.size() > 0, 'Opportunity is Present.');
		System.assertEquals(HIGroupEventAdvisingEmailAutomation.LFT_INTRO, list_Opp[0].Advising_Email__c, 'Level Funded Transition Advising Intro Email, scussfully sent.');
	}

	/**
	 * @description  This method is used to test HI Group event process for level_funded_autorenew_email Event type.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void levelFundedTransitionAdvisingAutoRenewalEmail() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae82')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEWAL_EMAIL )
			.setEventInfo(STR_JSON_LF_AUTO_RENEWAL)
			.build();

		insert objHIGroupEvent;
		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c, StageName FROM Opportunity LIMIT 1];

		System.assert(list_Opp.size() > 0, 'Opportunity is Present.');
		System.assertEquals(HIGroupEventAdvisingEmailAutomation.LFT_AUTO_RENEW, list_Opp[0].Advising_Email__c, 'Level Funded Auto Renewal Advising Email, scussfully sent.');
	}

	/**
	 * @description  This method is used to test HI Group event process for level_funded_transition_renewal_check_in_email Event type.
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void levelFundedTransitionRenewalCheckIn() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setEventId('ecbc176c-815e-4bc3-b545-58f3fe4deae82')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_CHECKIN_EMAIL )
			.setEventInfo(STR_JSON_LF_AUTO_RENEWAL)
			.build();

		insert objHIGroupEvent;
		Test.stopTest();

		List<Opportunity> list_Opp = [SELECT Id, Advising_Email__c, StageName FROM Opportunity LIMIT 1];

		System.assert(list_Opp.size() > 0, 'Opportunity is Present.');
		System.assertEquals(HIGroupEventAdvisingEmailAutomation.LFT_TRANS_CHECK_IN, list_Opp[0].Advising_Email__c, 'Level Funded Auto Renewal Advising Email, scussfully sent.');
	}
}