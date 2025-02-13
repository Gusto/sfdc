/**
 * @name         HIGroupEventRenewalAlternateRequestTest
 * @author       Bhagat Singh
 * @date         23 July 2021
 * @description  Test class for HIGroupEventRenewalAlternateRequest class.
 **/
@isTest
private class HIGroupEventRenewalAlternateRequestTest {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		skipTrigger(true);
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		State__c objState = new State__c(Name = 'California', Abbreviation__c = 'CA', Key__c = 'CA');
		insert objState;

		Opportunity objOpp = TestUtility.BenefitsRenewalOpportunity();
		Account objAcc = new Account(
			Id = objOpp.AccountId,
			ZP_Company_Id__c = '72239',
			Tier__c = objTierConfig.New_Tier_1__c,
			AM_Tier__c = 'Gold',
			ShippingState = 'California',
			BillingState = 'California'
		);
		update objAcc;

		objOpp.Source_ID__c = 'hawaiian_ice-new_plans_application-11001';
		objOpp.HI_Effective_Date__c = System.today().addDays(2);
		objOpp.Benefits_Current_Setup_Step__c = 'Completed';
		update objOpp;

		skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test renewal_alternates_requested : Negative case - Opportunity record not found
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesOpportunityRecordNotFound() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'renewal_alternates_requested',
			Application_Id__c = '11001',
			Company_Id__c = '72240',
			Event_Id__c = '11001',
			Event_Type__c = 'renewal_alternates_requested',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":72240,"application_id":11001,"alternate_packages_requested_timestamp":"1637901413","event_type":"renewal_alternates_requested"}'
		);
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.RENEWAL_DEAD_UNPROCESSED_EVENT);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test renewal_alternates_requested : Postive case - update opportunity stage
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testUpdateOpportunityStage() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'renewal_alternates_requested',
			Application_Id__c = '11001',
			Company_Id__c = '72239',
			Event_Id__c = '11001',
			Event_Type__c = 'renewal_alternates_requested',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":72239,"application_id":11001,"alternate_packages_requested_timestamp":"1637901413","event_type":"renewal_alternates_requested"}'
		);
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Id, StageName FROM Opportunity WHERE Application_Id__c = '11001' AND Account.ZP_Company_Id__c = '72239'].StageName == HIGroupEventRenewalAlternateRequest.OPP_STAGE_NAME);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : Event Info required field
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidationNoEventInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'renewal_alternates_requested',
			Event_Id__c = '11001',
			Event_Type__c = 'renewal_alternates_requested',
			Processing_State__c = 'Queued'
		);
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_EVENT_INFO_MISSING);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : Application Id required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidationNoApplicationId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'renewal_alternates_requested',
			Event_Id__c = '11001',
			Event_Type__c = 'renewal_alternates_requested',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":72239,"application_id":"","alternate_packages_requested_timestamp":"1637901413","event_type":"renewal_alternates_requested"}'
		);
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_APPLICATION_ID_MISSING);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : Company Id required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidationNoCompanyId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'renewal_alternates_requested',
			Event_Id__c = '11001',
			Event_Type__c = 'renewal_alternates_requested',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":"","application_id":11001,"alternate_packages_requested_timestamp":"1637901413","event_type":"renewal_alternates_requested"}',
			Application_Id__c = '11001'
		);
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_COMPANY_ID_MISSING);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : alternate_packages_requested_timestamp required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidationRequestDate() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'renewal_alternates_requested',
			Event_Id__c = '11001',
			Event_Type__c = 'renewal_alternates_requested',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":"72239","application_id":11001,"alternate_packages_requested_timestamp":"","event_type":"renewal_alternates_requested"}',
			Application_Id__c = '11001',
			Company_Id__c = '72239'
		);
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_ALTERNATE_REQ_DATE);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate : ErrorLog created, if any exception occured.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidateErrorLogs() {
		Test.startTest();
		try {
			HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
				Name = 'renewal_alternates_requested',
				Event_Id__c = '11001',
				Processing_State__c = 'Blank',
				Event_Info__c = '{"event_id":11001,"company_id":"72239","application_id":11001,"alternate_packages_requested_timestamp":"1637901413","event_type":"renewal_alternates_requested"}'
			);

			insert objHIGroupEvent;
		} catch (Exception objExp) {
			HIGroupEventRenewalAlternateRequest.createErrorLog(objExp);
		}

		Test.stopTest();

		List<Exception_Log__c> list_ErrorLogs = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'HIGroupEventRenewalAlternateRequest'];
		System.assert(list_ErrorLogs.size() > 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
	}
}