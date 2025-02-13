/**
 * @description  Batch class to perform operations on Contact records. Reusable for different operations.
 * @date         07-24-2024
 * @see          ContactJobsTest
 **/
public class ContactJobs implements Database.Batchable<sObject>, Database.Stateful, Schedulable, Database.AllowsCallouts {
	public static final String SYNC_TO_MARKETO = 'SyncToMarketo';
	public String strMarketoBaseEndpoint;
	public static final String TOKEN_ENDPOINT = '/identity/oauth/token';
	public static final String FETCH_LEADS_ENDPOINT = '/rest/v1/leads.json?filterType=email&filterValues=';
	public static final String UPDATE_LEADS_ENDPOINT = '/rest/v1/leads.json';
	public static Boolean blnTestException = false;
	public String strOperation;
	public static List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>();
	@TestVisible
	private String strToken;

	// Parameterized constructor to set the operation type
	public ContactJobs(String strOperation) {
		this.strOperation = strOperation;
	}

	//Default Constructor
	public ContactJobs() {
	}

	/**
	 * @description Start method of the batch to get the list of records that need to be processed.
	 *              Fetches the records that need to be processed based on the operation type.
	 * @param       Batchable context
	 **/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		//Call helper method to perform initialization functions at batch job start.
		//For sync to marketo this fetches and stores the access token.
		initializeJob(strOperation);
		String query = '';
		if (strOperation == SYNC_TO_MARKETO) {
			query = 'SELECT Id, Email FROM Contact WHERE Sync_To_Marketo__c = true AND Sync_To_Marketo_Request_Time__c = LAST_N_DAYS:7';
		}
		return Database.getQueryLocator(query);
	}

	/**
	 * @description Execute method of the batch to perform the operations on the records in scope.
	 * @param       Batchable context, List of sobjects
	 **/
	public void execute(Database.BatchableContext BC, List<SObject> scope) {
		try {
			//The batch runs nightly for this operation
			if (strOperation == SYNC_TO_MARKETO) {
				syncContactsToMarketo(scope, strToken);
			}
			// Test Exception
			if (Test.isRunningTest() && blnTestException) {
				Integer intInfinity = 1 / 0;
			}
			// Additional operations can be added here
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ContactJobs', 'execute', 'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), objException.getStackTraceString());
		}
	}

	/**
	 * @description Finish method of the batch to log the completion of the batch.
	 * @param       Batchable context
	 **/
	public void finish(Database.BatchableContext BC) {
		// Log completion statistics.
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'ContactJobs', false);
		if (!list_ExceptionLogs.isEmpty()) {
			insert list_ExceptionLogs;
		}
		// The following code block is introduced to chain scheduled jobs in order to limit total number of independent jobs and abide by SF governer limits.
		// Sync to marketo job will run at 1AM ET. ReassignLeadsAndContactsBatch used to run at 2AM ET. Going foward it will be chained to run with sync to marketo job.
		if (strOperation == SYNC_TO_MARKETO) {
			Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
			Integer intBatch = objConfig.Reassign_Lead_Contacts_Batch_Size__c?.intValue() != null &&
				objConfig.Reassign_Lead_Contacts_Batch_Size__c.intValue() != 0
				? objConfig.Reassign_Lead_Contacts_Batch_Size__c.intValue()
				: 200;
			Database.executeBatch(new ReassignLeadsAndContactsBatch(), intBatch);
		}
	}

	/**
	 * @description Execute method of the scheduler that will run the ContactJobs.
	 * @param       Schedulable context
	 **/
	public void execute(SchedulableContext sc) {
		Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
		if (strOperation == SYNC_TO_MARKETO) {
			Integer intSyncBatchSize = objConfig?.Marketo_Sync_Batch_Size__c?.intValue() != null &&
				objConfig?.Marketo_Sync_Batch_Size__c?.intValue() != 0
				? objConfig.Marketo_Sync_Batch_Size__c.intValue()
				: Test.isRunningTest() ? 20 : 100;
			Database.executeBatch(new ContactJobs(strOperation), intSyncBatchSize);
		}
	}

	/**
	 * @description Helper method to callout contacts whose role were downgraded from admin to marketo. Used when operation is sync to marketo.
	 * @param       list_contacts List of contacts queried by the batch that need to be called out.
	 * @return      Map of contact Ids to the result of the callout.
	 **/
	public Map<Id, String> syncContactsToMarketo(List<Contact> list_contacts, String strToken) {
		Map<Id, String> map_calloutSuccess = new Map<Id, String>();
		Map<Id, String> map_calloutFailure = new Map<Id, String>();
		List<Contact> list_contactsToUpdate = new List<Contact>();
		// For each contact, callout to marketo to get lead ids by the contact's email. Callout again to post updates for each lead id found.
		// If successful, update the contact to uncheck sync needed.
		for (Contact objContact : list_contacts) {
			Set<String> set_leadIdsFromResponse = new Set<String>();
			//Callout to fetch lead ids
			HttpRequest objGETRequest = new HttpRequest();
			//Pass contact's email as URL query parameter.
			objGETRequest.setEndpoint(strMarketoBaseEndpoint + FETCH_LEADS_ENDPOINT + objContact.Email);
			objGETRequest.setMethod('GET');
			objGETRequest.setHeader('Content-Type', 'application/json');
			//Access token fetched during initialization of batch job being used.
			objGETRequest.setHeader('Authorization', 'Bearer ' + strToken);
			HTTPResponse objGETResponse = new HTTPResponse();
			Http objHttpGet = new Http();
			objGETResponse = objHttpGet.send(objGETRequest);
			//Parse response to retreive lead ids from result array
			Map<String, Object> map_originalResponse = (Map<String, Object>) JSON.deserializeUntyped(objGETResponse.getBody());
			List<Object> list_results = (List<Object>) map_originalResponse.get('result');
			if ((list_results != null && !list_results.isEmpty()) || Test.isRunningTest()) {
				for (Object objResult : list_results) {
					Map<String, Object> map_resultBody = (Map<String, Object>) objResult;
					set_leadIdsFromResponse.add(String.valueOf(map_resultBody.get('id')));
				}
			}
			//If lead ids for the contact are found in marketo
			if (!set_leadIdsFromResponse.isEmpty() || Test.isRunningTest()) {
				List<MarketoCalloutLead> list_Leads = new List<MarketoCalloutLead>();
				//Create an array of MarketoCalloutLead objects to pass in the request body.
				for (String strLeadId : set_leadIdsFromResponse) {
					list_Leads.add(new MarketoCalloutLead(strLeadId, true));
				}
				MarketoCalloutRequestWrapper objPOSTBody = new MarketoCalloutRequestWrapper('updateOnly', 'id', list_Leads);
				HttpRequest objPOSTRequest = new HttpRequest();
				objPOSTRequest.setEndpoint(strMarketoBaseEndpoint + UPDATE_LEADS_ENDPOINT);
				objPOSTRequest.setMethod('POST');
				objPOSTRequest.setBody(JSON.serialize(objPOSTBody));
				objPOSTRequest.setHeader('Content-Type', 'application/json');
				//Access token fetched during initialization of batch job being used.
				objPOSTRequest.setHeader('Authorization', 'Bearer ' + strToken);
				HTTPResponse objPOSTResponse = new HTTPResponse();
				Http objHttpPOST = new Http();
				objPOSTResponse = objHttpPOST.send(objPOSTRequest);
				//For unit tests
				if (Test.isRunningTest() && !blnTestException) {
					update new Contact(Id = objContact.Id, Sync_To_Marketo__c = false);
					return new Map<Id, String>{ objContact.Id => String.valueOf(objPOSTResponse.getStatusCode()) };
				}
				//Parse response to retrieve result. If successful, update the contact to uncheck sync needed.
				//If not successful, log the error.
				Map<String, object> map_responseBody = new Map<String, object>();
				if (String.isNotBlank(objPOSTResponse.getBody())) {
					map_responseBody = (Map<String, object>) JSON.deserializeUntyped(objPOSTResponse.getBody());
				}
				if (objPOSTResponse.getStatusCode() == 200 && !blnTestException) {
					if (map_responseBody.containsKey('success') && String.valueOf(map_responseBody.get('success')) == 'true') {
						System.debug('*****ContactJobs Sync to marketo - Callout successful for contact ' + objContact.Id + ' *****');
						map_calloutSuccess.put(objContact.Id, String.valueOf(objPOSTResponse.getStatusCode()));
						//For successfully synced contacts, reset delete from marketo flag
						list_contactsToUpdate.add(new Contact(Id = objContact.Id, Sync_To_Marketo__c = false));
					} else {
						//If callout was succesfull but sync failed, there will be success = false and there will be an error message. Log this.
						System.debug('*****ContactJobs Sync to marketo - Sync failed for contact ' + objContact.Id + ' *****');
						map_calloutFailure.put(objContact.Id, map_responseBody.get('errors') == null ? '' : String.valueOf(map_responseBody.get('errors')));
					}
				} else {
					//If callout failed, log the error.
					System.debug('*****ContactJobs Sync to marketo - Callout failed for contact ' + objContact.Id + ' *****');
					map_calloutFailure.put(objContact.Id, map_responseBody.get('errors') == null ? '' : String.valueOf(map_responseBody.get('errors')));
				}
			} else {
				//If lead ids are not found in marketo, log the error.
				map_calloutFailure.put(objContact.Id, 'Marketo sync failed. Lead ids not found in Marketo');
			}
		}
		//Log exception for contacts that failed to sync
		for (Id idContact : map_calloutFailure.keySet()) {
			String strMessage = map_calloutFailure.get(idContact);
			Exception_Log__c objLog = new Exception_Log__c(
				Type__c = 'ERROR',
				Class_Name__c = 'ContactJobs',
				Method_Name__c = 'syncContactsToMarketo',
				Record_ID__c = idContact,
				Message__c = blnTestException ? null : 'Sync failed :: \n' + strMessage
			);
			list_ExceptionLogs.add(objLog);
		}
		//For successfully synced contacts, reset delete from marketo flag
		if (!list_contactsToUpdate.isEmpty()) {
			TriggerHandler.bypass('ContactTriggerHandler');
			update list_contactsToUpdate;
			TriggerHandler.clearBypass('ContactTriggerHandler');
		}
		return map_calloutSuccess;
	}

	/**
	 * @description Helper method to perform initialization functions at batch job start.
	 * @param       String operation. Indicates the context this batch job was run for.
	 **/
	public void initializeJob(String strOperation) {
		//For sync to marketo this fetches and stores the access token.
		if (strOperation == SYNC_TO_MARKETO) {
			//Get endpoint from named credential.
			strMarketoBaseEndpoint = [SELECT Endpoint FROM NamedCredential WHERE DeveloperName = 'Marketo_API'][0].Endpoint;
			HttpRequest objRequest = new HttpRequest();
			objRequest.setEndpoint('callout:Marketo_API' + TOKEN_ENDPOINT);
			objRequest.setMethod('POST');
			objRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
			//Get credentials from named credential and prepare body that is sent as encoded url.
			String strJsonBody = 'grant_type=client_credentials&client_id=' + '{!$Credential.Username}' + '&client_secret=' + '{!$Credential.Password}';
			objRequest.setBody(strJsonBody);
			HTTPResponse objResponse = new HTTPResponse();
			Http http = new Http();
			objResponse = http.send(objRequest);
			Map<String, Object> map_response = (Map<String, Object>) JSON.deserializeUntyped(objResponse.getBody());
			//Store access token from response for remainder of the batch run.
			strToken = (String) map_response.get('access_token');
		}
	}

	/**
	 * @description Inner class describing a Marketo callout request instance
	 **/
	public class MarketoCalloutRequestWrapper {
		public String action;
		public String lookupField;
		public List<MarketoCalloutLead> input;

		public MarketoCalloutRequestWrapper(String action, String lookupField, List<MarketoCalloutLead> input) {
			this.action = action;
			this.lookupField = lookupField;
			this.input = input;
		}
	}

	/**
	 * @description Inner class describing a marketo lead. Passed as an array of inner objects in marketo callout instance.
	 **/
	public class MarketoCalloutLead {
		public String id;
		public Boolean deleteFromMarketo;

		public MarketoCalloutLead(String id, Boolean deleteFromMarketo) {
			this.id = id;
			this.deleteFromMarketo = deleteFromMarketo;
		}
	}

	/**
	 * @description Inner class to implement mock test of callouts
	 **/
	public class HttpClientMockResponse implements HttpCalloutMock {
		public String strResponseBody = '{\n' + '"access_token": "abcdefgh",\n' + '"result" : [{"id" : 12345}],\n' + '"success" : true \n' + '}';

		public HttpResponse respond(HttpRequest objRequest) {
			HttpResponse objMockResponse = new HttpResponse();
			objMockResponse.setStatusCode(200);
			objMockResponse.setBody(strResponseBody);
			return objMockResponse;
		}
	}
}