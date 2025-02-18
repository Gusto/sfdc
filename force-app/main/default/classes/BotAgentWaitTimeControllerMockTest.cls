/**
 * @description  Test sending request to Chat API
 * @author       Debasmita Rawooth
 * @date         19/10/2023
 **/
@isTest
global with sharing class BotAgentWaitTimeControllerMockTest implements HttpCalloutMock {
	/**
	 * @description Sending fake response from Chat API
	 * @author      Debasmita Rawooth
	 * @param       HTTP Request
	 * @return      HTTP Response
	 **/
	global HTTPResponse respond(HTTPRequest objReq) {
		LiveChatButton objChatButton = [SELECT Id, MasterLabel, DeveloperName FROM LiveChatButton WHERE MasterLabel = 'GCorpPricing' LIMIT 1];

		BotAgentWaitTimeController_LEX.ResponseWrapper objResponse = new BotAgentWaitTimeController_LEX.ResponseWrapper();

		BotAgentWaitTimeController_LEX.Results objResult = new BotAgentWaitTimeController_LEX.Results();
		objResult.estimatedWaitTime = 120;
		objResult.id = objChatButton.id;
		objResult.isAvailable = true;

		List<BotAgentWaitTimeController_LEX.Results> list_Results = new List<BotAgentWaitTimeController_LEX.Results>();
		list_Results.add(objResult);

		BotAgentWaitTimeController_LEX.Message objMsg = new BotAgentWaitTimeController_LEX.Message();
		objMsg.results = list_Results;

		BotAgentWaitTimeController_LEX.Messages objMessage = new BotAgentWaitTimeController_LEX.Messages();
		objMessage.type = 'Availability';
		objMessage.message = objMsg;

		List<BotAgentWaitTimeController_LEX.Messages> list_Messages = new List<BotAgentWaitTimeController_LEX.Messages>();
		list_Messages.add(objMessage);

		objResponse.messages = list_Messages;

		HttpResponse objRes = new HttpResponse();
		objRes.setHeader('Content-Type', 'application/json');
		objRes.setBody(JSON.serialize(objResponse));
		objRes.setStatusCode(200);

		return objRes;
	}
}