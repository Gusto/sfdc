@isTest
global class InboundCallMockResponseTest implements HttpCalloutMock {
	/**
	 * @description Sending fake response from NICE inContact API
	 * @author      Praveen Sethu
	 * @param       HTTP Request
	 * @return      HTTP Response
	 **/
	global HTTPResponse respond(HTTPRequest objReq) {
		HttpResponse objRes = new HttpResponse();
		objRes.setHeader('Content-Type', 'application/json');
		objRes.setStatusCode(200);
		objRes.setBody('{"agentId":"test","access_token":"test","agents":[{"emailAddress":"praveen.sethu@gusto.com"}]}');
		return objRes;
	}
}