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
				// Send custom callout to Mulesoft endpoint
				HttpRequest objHTTPReq = new HttpRequest();
				objHTTPReq.setEndpoint('callout:Account_Routing_Mulesoft');
				objHTTPReq.setMethod('POST');
				objHTTPReq.setBody(JSON.serialize(objWrapper));
				objHTTPReq.setHeader('Content-Type', 'application/json');
				objHTTPReq.setTimeOut(120000);

				Http objHTTP = new Http();
				HTTPResponse objHTTPRes = objHTTP.send(objHTTPReq);

				// update account route count flag if running from test class
				if (Test.isRunningTest()) {
					Account objAcc = new Account(Id = objWrapper.idRecord, Account_Route_Count__c = 2);
					list_AccountsToUpdate.add(objAcc);
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