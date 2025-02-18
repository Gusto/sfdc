/**
 * @description  Test sending request to Chat API
 * @author       Debasmita Rawooth
 * @date         19/10/2023
 **/
@isTest
global with sharing class RetrieveAgentWaitTimeMockTest implements HttpCalloutMock {
	/**
	 * @description Sending fake response from Chat API
	 * @author      Debasmita Rawooth
	 * @param       HTTP Request
	 * @return      HTTP Response
	 **/
	global HTTPResponse respond(HTTPRequest objReq) {
		LiveChatButton objChatButton = [SELECT Id, MasterLabel, DeveloperName FROM LiveChatButton WHERE MasterLabel = 'GCorpPricing' LIMIT 1];

		RetrieveAgentWaitTimeController.ResponseWrapper objResponse = new RetrieveAgentWaitTimeController.ResponseWrapper();

		RetrieveAgentWaitTimeController.Results objResult = new RetrieveAgentWaitTimeController.Results();
		objResult.estimatedWaitTime = 120;
		objResult.id = objChatButton.id;
		objResult.isAvailable = true;

		List<RetrieveAgentWaitTimeController.Results> list_Results = new List<RetrieveAgentWaitTimeController.Results>();
		list_Results.add(objResult);

		RetrieveAgentWaitTimeController.Message objMsg = new RetrieveAgentWaitTimeController.Message();
		objMsg.results = list_Results;

		RetrieveAgentWaitTimeController.Messages objMessage = new RetrieveAgentWaitTimeController.Messages();
		objMessage.type = 'Availability';
		objMessage.message = objMsg;

		List<RetrieveAgentWaitTimeController.Messages> list_Messages = new List<RetrieveAgentWaitTimeController.Messages>();
		list_Messages.add(objMessage);

		objResponse.messages = list_Messages;

		HttpResponse objRes = new HttpResponse();
		objRes.setHeader('Content-Type', 'application/json');
		objRes.setBody(JSON.serialize(objResponse));
		objRes.setStatusCode(200);

		return objRes;
	}
}