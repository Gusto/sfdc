/**
 * @description  Test sending lead to RingLead
 * @author       Praveen Sethu
 * @date         11-11-2022
 **/
@isTest
global with sharing class RingLeadMockResponseTest implements HttpCalloutMock {

    /**
	 * @description Sending fake response from RingLead
	 * @author      Praveen Sethu
	 * @param       HTTP Request
	 * @return      HTTP Response
	 **/
	global HTTPResponse respond(HTTPRequest objReq) {
		HttpResponse objRes = new HttpResponse();
		objRes.setHeader('Content-Type', 'application/json');
		objRes.setStatusCode(200);
		return objRes;
	}
}