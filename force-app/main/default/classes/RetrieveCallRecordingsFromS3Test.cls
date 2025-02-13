/**
 * @name         : RetrieveCallRecordingsFromS3Test
 * @author       : Sean DesMarteau
 * @date         : 11-11-2021
 * @description  : Test class for RetrieveCallRecordingsFromS3
 **/
@istest
public with sharing class RetrieveCallRecordingsFromS3Test {
	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Tests the successful response of RetrieveCallRecordingsFromS3
	 **/
	@IsTest(SeeAllData=true) // SeeAllData required because of ConnectAPI usage in RetrieveCallRecordingsFromS3
	static void retrieveCallRecordingsFromS3SuccessTest() {
		// Data Setup
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setSubject('Test Call')
			.setDescription('Test Call')
			.setGenesysCallId('1234-5678-9012-3233')
			.build();
		insert objCase;

		Ticket__c objTicket = new Ticket__c();
		objTicket.RecordTypeId = Cache.getRecordTypeId('Ticket__c', 'Call Recording');
		objTicket.Case__c = objCase.Id;
		insert objTicket;

		// Checking to make sure no chatter posts exist
		List<FeedItem> list_FeedItems = [SELECT Id FROM FeedItem WHERE ParentId = :objTicket.Id];
		System.assertEquals(0, list_FeedItems.size());

		List<RetrieveCallRecordingsFromS3.Request> list_Requests = new List<RetrieveCallRecordingsFromS3.Request>();
		RetrieveCallRecordingsFromS3.Request objRequest = new RetrieveCallRecordingsFromS3.Request();
		objRequest.ticketId = objTicket.Id;
		objRequest.caseId = objCase.Id;
		objRequest.strCallId = objCase.Genesys_Call_Id__c;

		list_Requests.add(objRequest);

		Test.setMock(HttpCalloutMock.class, new CallRecordingSuccessResponse());
		Test.startTest();
		List<RetrieveCallRecordingsFromS3.Result> list_Results = RetrieveCallRecordingsFromS3.execute(list_Requests);
		Test.stopTest();

		// Checking to make sure chatter posts was created
		list_FeedItems = [SELECT Id FROM FeedItem WHERE ParentId = :objTicket.Id];
		System.assertEquals(1, list_FeedItems.size());
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Generate a success mock response for RetrieveCallRecordingsFromS3 callout
	 **/
	class CallRecordingSuccessResponse implements HttpCalloutMock {
		// Implement this interface method
		public HTTPResponse respond(HTTPRequest request) {
			// Create Wrapper Test Data
			RetrieveCallRecordingsFromS3.RecordingURL objRecordingURL = new RetrieveCallRecordingsFromS3.RecordingURL();
			objRecordingURL.URL = 'https://gusto.com/';

			List<RetrieveCallRecordingsFromS3.RecordingURL> list_RecordingUrls = new List<RetrieveCallRecordingsFromS3.RecordingURL>();
			list_RecordingUrls.add(objRecordingURL);

			RetrieveCallRecordingsFromS3.ResponseWrapper objResponseWrapper = new RetrieveCallRecordingsFromS3.ResponseWrapper();
			objResponseWrapper.recordingURLs = list_RecordingUrls;
			objResponseWrapper.recordingsExpiration = 180;

			String strResponseBody = JSON.serialize(objResponseWrapper);

			// Generate Response
			HttpResponse objResponse = new HttpResponse();
			objResponse.setBody(strResponseBody);
			objResponse.setStatusCode(200);
			return objResponse;
		}
	}
}