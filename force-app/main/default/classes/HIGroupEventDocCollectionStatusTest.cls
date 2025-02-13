/**
 * @name         HIGroupEventDocCollectionStatusTest
 * @author       Deepika Saini
 * @date         02/09/2021
 * @description  Test class for HIGroupEventDocCollectionStatus class.
 **/
@isTest
class HIGroupEventDocCollectionStatusTest {
	static final Id LOGGED_IN_USER_ID = UserInfo.getUserId();

	@testSetup
	static void makeData() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		Opportunity objOpp = TestUtility.BenefitsNewPlanOpportunity();
		Account objAcc = new Account(Id = objOpp.AccountId, ZP_Company_Id__c = '72239');
		objOpp.Source_ID__c = 'hawaiian_ice-new_plan_application-72239';
		update objOpp;
		update objAcc;

		Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('New Plan', objOpp.Id, 'Test Record', false);
		objBO.Account__c = objOpp.Accountid;
		objBO.Order_Status__c = 'Ready for Qualification';
		objBO.OwnerId = LOGGED_IN_USER_ID;
		objBO.Coverage_Effective_Date__c = System.today().addDays(10);
		insert objBO;

		//Second record
		Opportunity objOppRenewal = TestUtility.BenefitsRenewalOpportunity();
		Account objAccRenewal = new Account(Id = objOppRenewal.AccountId, ZP_Company_Id__c = '72240');
		objOppRenewal.Source_ID__c = 'hawaiian_ice-renewal_application-72240';
		update objOppRenewal;
		update objAccRenewal;

		Benefit_Order__c objBORenewal = TestUtility.createTestBenefitOrder('Renewal', objOppRenewal.Id, 'Test Record', false);
		objBORenewal.Account__c = objOppRenewal.Accountid;
		objBORenewal.Order_Status__c = 'Ready for Qualification';
		objBORenewal.OwnerId = LOGGED_IN_USER_ID;
		objBORenewal.Coverage_Effective_Date__c = System.today().addDays(10);
		insert objBORenewal;
	}

	static HIGroupEvent__c createHIGroupEventData(String strEventType, String strEventId) {
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(Event_Type__c = strEventType, Event_Id__c = strEventId);

		return objHIGroupEvent;
	}

	static testMethod void testDocCollectionEventsValidationNoEventInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c58b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c == IntegrationUtils.ERROR_STATE);
	}

	static testMethod void testDocCollectionEventsValidationNoApplicationInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c58b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEvent.Event_Info__c = '{ "application_type" : "New Plan", "event_id" : "11121", "company_id" : "72239", "event_type" : "document_collection_status", "documents_status" : "all_uploaded", "created_at" : "2021-02-01T13:23:00.429-07:00" }';
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c == IntegrationUtils.ERROR_STATE);
	}

	static testMethod void testDocCollectionEventsValidationNoApplicationTypeInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c58b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEvent.Event_Info__c = '{ "application_id" : "hawaiian_ice-new_plan_application-72239", "event_id" : "11121", "company_id" : "72239", "event_type" : "document_collection_status", "documents_status" : "all_uploaded", "created_at" : "2021-02-01T13:23:00.429-07:00" }';
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c == IntegrationUtils.ERROR_STATE);
	}

	static testMethod void testDocCollectionEventsValidationNoCompanyIdInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c58b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEvent.Event_Info__c = '{ "application_type" : "New Plan", "application_id" : "hawaiian_ice-new_plan_application-72239", "event_id" : "11121", "event_type" : "document_collection_status", "documents_status" : "all_uploaded", "created_at" : "2021-02-01T13:23:00.429-07:00" }';
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c == IntegrationUtils.ERROR_STATE);
	}

	static testMethod void testDocCollectionEventsValidationNoDocumentStatusInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c58b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEvent.Event_Info__c = '{ "application_type" : "New Plan", "application_id" : "hawaiian_ice-new_plan_application-72239", "event_id" : "11121", "company_id" : "72239", "event_type" : "document_collection_status", "created_at" : "2021-02-01T13:23:00.429-07:00" }';
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c == IntegrationUtils.ERROR_STATE);
	}

	static testMethod void testDocCollectionEventsWithSuccessStatus() {
		Test.startTest();
		String strMasterJSON = '{ "application_type" : "New Plan", "application_id" : "hawaiian_ice-new_plan_application-72239", "event_id" : "11121", "company_id" : "72239", "event_type" : "document_collection_status", "documents_status" : "all_uploaded", "created_at" : "2021-02-01T13:23:00.429-07:00" }';
		HIGroupEvent__c objHIGroupEvent = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c58b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEvent.Event_Info__c = strMasterJSON;
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c == IntegrationUtils.PROCESSED_STATE);
	}

	static testMethod void testDocCollectionEventsWithErrorStatus() {
		Test.startTest();
		String strMasterJSON = '{ "application_type" : "New Plan", "application_id" : "hawaiian_ice-new_plan_application-72239", "event_id" : "11121", "company_id" : "72239", "event_type" : "document_collection_status", "documents_status" : "all_upload", "created_at" : "2021-02-01T13:23:00.429-07:00" }';
		HIGroupEvent__c objHIGroupEvent = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c58b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEvent.Event_Info__c = strMasterJSON;
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c == IntegrationUtils.ERROR_STATE);
	}

	static testMethod void testDocCollectionEventsWithMultipleDataStatus() {
		Test.startTest();
		String strMasterJSONWithError = '{ "application_type" : "New Plan", "application_id" : "hawaiian_ice-new_plan_application-72239", "event_id" : "11121", "company_id" : "72239", "event_type" : "document_collection_status", "documents_status" : "all_upload", "created_at" : "2021-02-01T13:23:00.429-07:00" }';
		String strMasterJSONWithoutError = '{ "application_type" : "Renewal", "application_id" : "hawaiian_ice-renewal_application-72240", "event_id" : "11122", "company_id" : "72240", "event_type" : "document_collection_status", "documents_status" : "all_uploaded", "created_at" : "2021-02-01T13:23:00.429-07:00" }';
		String strMasterJSONWithoutBO = '{ "application_type" : "Renewal", "application_id" : "hawaiian_ice-renewal_application-72241", "event_id" : "11123", "company_id" : "72241", "event_type" : "document_collection_status", "documents_status" : "all_uploaded", "created_at" : "2021-02-01T13:23:00.429-07:00" }';

		List<HIGroupEvent__c> list_HIGroupEventsToBeInserted = new List<HIGroupEvent__c>();
		HIGroupEvent__c objHIGroupEventWithError = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c58b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEventWithError.Event_Info__c = strMasterJSONWithError;
		list_HIGroupEventsToBeInserted.add(objHIGroupEventWithError);

		HIGroupEvent__c objHIGroupEventWithoutError = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c68b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEventWithoutError.Event_Info__c = strMasterJSONWithoutError;
		list_HIGroupEventsToBeInserted.add(objHIGroupEventWithoutError);

		HIGroupEvent__c objHIGroupEventWithoutBO = createHIGroupEventData(HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS, 'c78b1e1a-b0f3-4602-a067-7bfbaab8kjll');
		objHIGroupEventWithoutBO.Event_Info__c = strMasterJSONWithoutBO;
		list_HIGroupEventsToBeInserted.add(objHIGroupEventWithoutBO);
		insert list_HIGroupEventsToBeInserted;

		Test.stopTest();
		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEventWithError.Id].Processing_State__c == IntegrationUtils.ERROR_STATE);
		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEventWithoutError.Id].Processing_State__c == IntegrationUtils.PROCESSED_STATE);
		System.assert([SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEventWithoutBO.Id].Processing_State__c == IntegrationUtils.ERROR_STATE);
	}
}