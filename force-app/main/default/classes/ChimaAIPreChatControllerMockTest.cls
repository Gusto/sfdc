/**
 * @description  Test sending request to Chima AI
 * @author       David (Dato) Tsamalashvili
 * @date         07/11/2023
 **/
@isTest
global with sharing class ChimaAIPreChatControllerMockTest implements HttpCalloutMock {
	private Boolean blnIsSuccess;

	public ChimaAIPreChatControllerMockTest(Boolean blnIsSuccess) {
		this.blnIsSuccess = blnIsSuccess;
	}
	/**
	 * @description Sending fake response from Chima AI
	 * @author      David (Dato) Tsamalashvili
	 * @param       HTTP Request
	 * @return      HTTP Response
	 **/
	global HTTPResponse respond(HTTPRequest objReq) {
		ChimaAIPreChatController.MulesoftResponseWrapper objMulesoftResponse = new ChimaAIPreChatController.MulesoftResponseWrapper();
		objMulesoftResponse.response_received_from = ChimaAIPreChatController.CO_PILOT;

		ChimaAIPreChatController.ResponseWrapper objResponse = new ChimaAIPreChatController.ResponseWrapper();
		objResponse.answer = 'This is a test response';
		objResponse.answerURL = 'https://www.gusto.com';
		objResponse.support_url = 'https://www.gusto.com';
		objResponse.timestamp = String.valueOf(Datetime.now());
		objResponse.company_uuid = '36124-dsadsa-dsadsa-dsafdadf';
		objResponse.company_id = 2314312;
		objResponse.user_role_id = 312431;
		objResponse.conversation_id = '43143-4312dsad-dadsa';

		objMulesoftResponse.message = objResponse;

		HttpResponse objRes = new HttpResponse();
		objRes.setHeader('Content-Type', 'application/json');
		objRes.setBody(JSON.serialize(objMulesoftResponse));

		if (this.blnIsSuccess) {
			objRes.setStatusCode(200);
		} else {
			objRes.setStatusCode(400);
		}

		return objRes;
	}

	/**
	 * @description Sending fake response from Chima AI for a feedback rating request
	 * @author      David (Dato) Tsamalashvili
	 * @param       HTTP Request
	 * @return      HTTP Response
	 **/
	global HTTPResponse feedbackRating(HTTPRequest objReq) {
		String objResponse = '{"company_uuid": "1872631872", "company_id": 17612712, "user_role_id": 12197219, "conversation_id": \'43143-4312dsad-dadsa\'}';

		HttpResponse objRes = new HttpResponse();
		objRes.setHeader('Content-Type', 'application/json');
		objRes.setBody(JSON.serialize(objResponse));
		objRes.setStatusCode(200);

		return objRes;
	}
}