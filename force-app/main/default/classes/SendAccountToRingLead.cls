/**
 * @description  Send Eligible accounts to Mulesoft which then sends to RingLead for Routing
 * @author       Praveen Sethu
 * @date         11-8-2022
 * @see          SendAccountToRingLeadTest
 **/
public with sharing class SendAccountToRingLead {
	/**
	 * @description  Wrapper used for sending JSON payload to Mulesoft and to receieve input from Flow
	 * @author       Praveen Sethu
	 * @date         11-8-2022
	 * @see          NA
	 **/
	public class RequestWrapper {
		// Id of Account Record to be Sent
		@InvocableVariable
		public Id idRecord;

		// Setting object type as Account
		@InvocableVariable
		public String strObjectType = 'Account';

		// Routing Type (Regular or HI Owner)
		@InvocableVariable
		public String strRoutingType = 'Regular';

		// Default Constructor - DO NOT REMOVE
		public RequestWrapper() {
		}

		// Paramterized Constructor
		public RequestWrapper(Id idRecord) {
			this.idRecord = idRecord;
		}
	}

	public class AccountWrapper {
		public String Id;
		public String RingLead_Record_Source = 'sf_trigger';
		public String RingLead_Record_Type = 'Account';
		public String SoldBy;
		public String OwnerId;
		public String RecordTypeId;
	}

	/**
	 * @description Receives account Id from Flow and sends it to Mulesoft which then sends to RingLead for Routing
	 * @author      Praveen Sethu
	 * @param       List<list_ReqWrappers> - List of Invocable wrapper object
	 * @return      NA
	 **/
	@InvocableMethod(callout=true label='Send Account To RingLead' description='Forward request to Mulesoft for sending account to RingLead.')
	public static void sendAccountToRingLead(List<RequestWrapper> list_ReqWrappers) {
		List<Account> list_AccountsToUpdate = new List<Account>();
		try {
			// Iterate over all wrapper objects
			for (RequestWrapper objWrapper : list_ReqWrappers) {
				for (Account objAcc : [SELECT Id, Sold_By__c, OwnerId, RecordTypeId FROM Account WHERE Id = :objWrapper.idRecord]) {
					AccountWrapper objAccountWrapper = new AccountWrapper();
					objAccountWrapper.Id = objAcc.Id;
					objAccountWrapper.SoldBy = objAcc.Sold_By__c;
					objAccountWrapper.OwnerId = objAcc.OwnerId;
					objAccountWrapper.RecordTypeId = objAcc.RecordTypeId;

					String strJSONPayload = JSON.serialize(objAccountWrapper);
					strJSONPayload = strJSONPayload.replaceAll('RingLead_Record_Source', '_RingLead_Record_Source');
					strJSONPayload = strJSONPayload.replaceAll('RingLead_Record_Type', '_RingLead_Record_Type');
					strJSONPayload = strJSONPayload.replaceAll('SoldBy', 'Sold_By__c');

					// Send custom callout to Mulesoft endpoint
					HttpRequest objHTTPReq = new HttpRequest();
					System.debug('Routing Type: ' + objWrapper.strRoutingType);
					if (objWrapper.strRoutingType == 'HI Owner')
						objHTTPReq.setEndpoint('https://login.ringlead.com/api/v1/webtolead/12679/73183429-e851-4879-9e87-803631a2de4c/submission/');
					else if (objWrapper.strRoutingType == 'Regular') {
						objHTTPReq.setEndpoint('https://dms.ringlead.com/api/v1/webtolead/12679/b3e78976-3789-4fd0-b78b-1fa288e9f8ba/submission/');
					}

					System.debug(strJSONPayload);

					objHTTPReq.setMethod('POST');
					objHTTPReq.setBody(strJSONPayload);
					objHTTPReq.setHeader('Content-Type', 'application/json');
					objHTTPReq.setTimeOut(120000);

					System.debug(strJSONPayload);

					Http objHTTP = new Http();
					HTTPResponse objHTTPRes = objHTTP.send(objHTTPReq);
				}
			}

			if (!list_AccountsToUpdate.isEmpty()) {
				AccountTriggerHelper.skipTrigger = true;
				update list_AccountsToUpdate;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('SendAccountToRingLead', 'sendAccountToRingLead', null, objException);
		}
	}
}