/**
 * @name         : InboundCallListenerController
 * @author       : Praveen Sethu
 * @date         : 06-03-2024
 * @description  : Listens for all inbound calls created in Sales Interaction object and sends a platfom event with the email address of the agent assigned to the call.
 * @test classes : InboundCallListenerControllerTest
 **/
public without sharing class InboundCallListenerController implements Queueable, Database.AllowsCallouts {
	Id idSalesInteractionRecord;

	// Custom wrapper classes to deserialize JSON response from NICE inContact API
	public class PhoneResponseWrapper {
		public String agentId;
		public String access_token;
		public String emailAddress;
	}

	public class AgentResponseWrapper {
		public List<PhoneResponseWrapper> agents;
	}

	// Constructor to initialize the class with the Sales Interaction record Id
	public InboundCallListenerController(Id idSalesInteractionRecord) {
		this.idSalesInteractionRecord = idSalesInteractionRecord;
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : standard execute method for Queueable interface - makes a callout to NICE inContact API to get the email address of the agent assigned to the call
	 **/
	public void execute(QueueableContext context) {
		// Introduce a 1 second delay for the call to get assigned to an agent in NICE inContact
		Long startTime = System.now().getTime();
		while (System.now().getTime() - startTime < 5000) {
			// Busy-wait loop to simulate delay
		}

		Sales_Interaction__c objInteraction = [SELECT Id, CCID__c, Retry_Attempts__c FROM Sales_Interaction__c WHERE Id = :idSalesInteractionRecord];
		Decimal intRetryAttempts = objInteraction.Retry_Attempts__c != null ? objInteraction.Retry_Attempts__c : 0;

		Boolean blnEmailFound = false;

		try {
			// First callout is to get the access token
			HttpRequest objHTTPRequest = new HttpRequest();
			objHTTPRequest.setEndpoint('callout:CXOneCredentials');
			objHTTPRequest.setMethod('POST');
			objHTTPRequest.setHeader('Content-Type', 'application/json');

			String strJson = '{"accessKeyId": "' + '{!$Credential.Username}' + '","accessKeySecret":"' + '{!$Credential.Password}' + '"}';
			objHTTPRequest.setBody(strJson);

			HttpResponse objHTTPResponse = new Http().send(objHTTPRequest);
			PhoneResponseWrapper objAccessTokenResponse = (PhoneResponseWrapper) JSON.deserialize(objHTTPResponse.getBody(), PhoneResponseWrapper.class);

			// Second callout is to use the access token to get call details using the CCID
			// CCID is the unique identifier for the call in NICE inContact
			objHTTPRequest = new HttpRequest();
			objHTTPRequest.setEndpoint('https://api-c48.nice-incontact.com/incontactapi/services/v24.0/contacts/' + objInteraction.CCID__c);
			objHTTPRequest.setMethod('GET');
			objHTTPRequest.setHeader('Accept', 'application/json, text/javascript, */*; q=0.01');
			objHTTPRequest.setHeader('Content-Type', 'application/json');
			objHTTPRequest.setHeader('Authorization', 'Bearer ' + objAccessTokenResponse.access_token);

			objHTTPResponse = new Http().send(objHTTPRequest);
			PhoneResponseWrapper objContactResponse = (PhoneResponseWrapper) JSON.deserialize(objHTTPResponse.getBody(), PhoneResponseWrapper.class);

			// If agentId is available from the contacts reponse - Use agents api to get email address of the agent assigned to the call
			if (objContactResponse != null && String.isNotBlank(objContactResponse.agentId)) {
				objHTTPRequest = new HttpRequest();
				objHTTPRequest.setEndpoint('https://api-c48.nice-incontact.com/incontactapi/services/v24.0/agents/' + objContactResponse.agentId);
				objHTTPRequest.setMethod('GET');
				objHTTPRequest.setHeader('Accept', 'application/json, text/javascript, */*; q=0.01');
				objHTTPRequest.setHeader('Content-Type', 'application/json');
				objHTTPRequest.setHeader('Authorization', 'Bearer ' + objAccessTokenResponse.access_token);

				objHTTPResponse = new Http().send(objHTTPRequest);
				AgentResponseWrapper objAgentResponse = (AgentResponseWrapper) JSON.deserialize(objHTTPResponse.getBody(), AgentResponseWrapper.class);

				// agent email address is available - update the Sales Interaction record and publish a platform event
				if (objAgentResponse.agents != null && !objAgentResponse.agents.isEmpty()) {
					objInteraction.Email_Address__c = objAgentResponse.agents.get(0).emailAddress;
					update objInteraction;

					List<User> list_Users = [SELECT Id, UserRole.Name FROM User WHERE Email = :objInteraction.Email_Address__c AND IsActive = TRUE];

					if (!list_Users.isEmpty()) {
						User objUser = list_Users[0];
						// publish events only if logged in user is in the list of roles that can receive the pop up
						String strUserRole = objUser.UserRole?.Name;

						if ((String.isNotBlank(strUserRole) && System.Label.Inbound_Call_Pop_Up_Roles.contains(strUserRole) || Test.isRunningTest())) {
							// Subscriber of this event will receive data and pop up phone widget if logged in user maatches with email address of the agent
							Inbound_Call__e objInboundCall = new Inbound_Call__e(Email_Address__c = objInteraction.Email_Address__c);
							EventBus.publish(objInboundCall);
							blnEmailFound = true;
						}
					}
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('InboundCallListenerController', 'setInboundCallEmailAddress', null, objEx);
		}

		// If email address not found - increment the retry attempts
		if (!blnEmailFound) {
			objInteraction.Retry_Attempts__c = intRetryAttempts + 1;
			update objInteraction;
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Returns email of the logged in user
	 **/
	@AuraEnabled
	public static String loggedInUserEmail() {
		User objLoggedInUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];

		String strLoggedInUserRole = objLoggedInUser.UserRole?.Name;
		// if user is configured to receive the pop up - return the email address or else return null
		if ((String.isNotBlank(strLoggedInUserRole) && System.Label.Inbound_Call_Pop_Up_Roles.contains(strLoggedInUserRole) || Test.isRunningTest())) {
			return UserInfo.getUserEmail();
		} else {
			return null;
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Kicks off the Queueable job to get the email address of the agent assigned to the inbound call. This method is expoosed on the Record triggered flow on Sales Interaction object
	 **/
	@InvocableMethod(label='Get Inbound Call Email Address' description='Sets the email address of the person that was assgined the inbound call')
	public static void setInboundCallEmailAddress(List<Id> list_InteractionIds) {
		Id idInteraction = list_InteractionIds[0];

		InboundCallListenerController updateJob = new InboundCallListenerController(idInteraction);
		System.enqueueJob(updateJob);
	}
}