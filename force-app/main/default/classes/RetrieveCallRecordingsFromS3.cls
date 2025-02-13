/**
 * @name         : RetrieveCallRecordingsFromS3
 * @author       : Sean DesMarteau
 * @date         : 11-11-2021
 * @description  : Retrieves call recordings from S3 via a Workato recipe. If recordings are found they are posted to Chatter as a message.
 * @test classes : RetrieveCallRecordingsFromS3Test
 **/
public with sharing class RetrieveCallRecordingsFromS3 {
	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Invocable method to retrieve recordings and post to Chatter.
	 * @Parm        : list_InputRequests - List of Request Object - Contains TicketId, CaseId, Call Id
	 * @Return      : list_OutputResults - List of Result Object - Contains Status Code
	 **/
	@InvocableMethod(
		callout=true
		label='Retrieve Call Recording From S3'
		description='Retrieves call recordings from S3 and posts message to Chatter'
	)
	public static List<Result> execute(List<Request> list_InputRequests) {
		Request objInputRequest = list_InputRequests[0];

		List<Result> list_OutputResults = new List<Result>();

		// HTTP Callout
		Http objHttp = new Http();
		HttpRequest objRequest = new HttpRequest();

		objRequest.setEndpoint('callout:Workato_Call_Recordings/' + objInputRequest.strCallId);
		objRequest.setMethod('GET');
		objRequest.setHeader('API-TOKEN', '{!$Credential.Password}');

		HttpResponse objResponse = objHttp.send(objRequest);

		// Post to Chatter
		if (objResponse.getStatusCode() == 200) {
			Integer intRecordingNumber = 1;

			ResponseWrapper objResponseWrapper = (ResponseWrapper) System.JSON.deserialize(
				objResponse.getBody(),
				ResponseWrapper.class
			);

			ConnectApi.MessageBodyInput objMessageBodyInput = new ConnectApi.MessageBodyInput();
			objMessageBodyInput.MessageSegments = new List<ConnectApi.MessageSegmentInput>();
			ConnectApi.FeedItemInput objFeedItemInput = new ConnectApi.FeedItemInput();
			objFeedItemInput.SubjectId = objInputRequest.TicketId;
			ConnectApi.TextSegmentInput objTextSegment;

			objTextSegment = new ConnectApi.TextSegmentInput();
			objTextSegment.Text = 'The following recordings have been retrieved for Case: ';
			objMessageBodyInput.MessageSegments.add(objTextSegment);

			ConnectApi.EntityLinkSegmentInput objEntityLinkSegmentInputContact = new ConnectApi.EntityLinkSegmentInput();
			objEntityLinkSegmentInputContact.entityId = objInputRequest.caseId;
			objMessageBodyInput.MessageSegments.add(objEntityLinkSegmentInputContact);

			objTextSegment = new ConnectApi.TextSegmentInput();
			objTextSegment.Text =
				'. The links to these recordings will expire at ' +
				DateTime.now()
					.addSeconds(objResponseWrapper.recordingsExpiration)
					.format('MM/dd/yyyy hh:mm a zz', 'America/Los_Angeles');
			objMessageBodyInput.MessageSegments.add(objTextSegment);

			objMessageBodyInput.MessageSegments.add(markupBegin(ConnectApi.MarkupType.UnorderedList, '')); // Unorderded List Start
			for (RecordingURL objRecordingURL : objResponseWrapper.RecordingURLs) {
				objMessageBodyInput.MessageSegments.add(markupBegin(ConnectApi.MarkupType.ListItem, '')); // List Item End
				objMessageBodyInput.MessageSegments.add(
					markupBegin(ConnectApi.MarkupType.Hyperlink, objRecordingURL.URL)
				);

				objTextSegment = new ConnectApi.TextSegmentInput();
				objTextSegment.text = 'Recording ' + intRecordingNumber;
				objMessageBodyInput.MessageSegments.add(objTextSegment);

				objMessageBodyInput.MessageSegments.add(markupEnd(ConnectApi.MarkupType.Hyperlink));
				objMessageBodyInput.MessageSegments.add(markupEnd(ConnectApi.MarkupType.ListItem)); // List Item End

				intRecordingNumber++;
			}

			objMessageBodyInput.MessageSegments.add(markupEnd(ConnectApi.MarkupType.UnorderedList)); // Unorderded List End

			objFeedItemInput.Body = objMessageBodyInput;

			// Post to Chatter
			ConnectApi.FeedElement objFeedElement = ConnectApi.ChatterFeeds.postFeedElement(
				Network.getNetworkId(),
				objFeedItemInput
			);
		}

		// Return Result
		Result objResult = new Result();
		objResult.statusCode = objResponse.getStatusCode();
		list_OutputResults.add(objResult);

		return list_OutputResults;
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Request Object Defintion. Used for input [arameters for invocable method.
	 **/
	public class Request {
		@InvocableVariable(label='Ticket Id' description='Ticket Id' required=true)
		public Id ticketId;

		@InvocableVariable(label='Case Id' description='Case Id' required=true)
		public Id caseId;

		@InvocableVariable(label='Call Id' description='Call Id' required=true)
		public String strCallId;
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Result Object Defintion. Used for input Parameters for invocable method.
	 **/
	public class Result {
		@InvocableVariable(label='Status Code' description='Status code from HTTP Callout' required=true)
		public Integer statusCode;
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Wrapper for HTTP Response
	 **/
	public class ResponseWrapper {
		public List<RecordingURL> recordingURLs;
		public Integer recordingsExpiration;
	}

	public class RecordingURL {
		public String URL;
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Generates a ConnectApi.MarkupBeginSegmentInput based off input parameters.
	 * @Parm        : markupType - Markup type to generate
	 * 				  url - URL to use if MarkupType is Hyperlink
	 * @Return      : objMarkupBeginSegment - Complete ConnectApi.MarkupBeginSegmentInput
	 **/
	public static ConnectApi.MarkupBeginSegmentInput markupBegin(ConnectApi.MarkupType strMarkupType, String strUrl) {
		ConnectApi.MarkupBeginSegmentInput objMarkupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
		objMarkupBeginSegment.MarkupType = strMarkupType;
		objMarkupBeginSegment.Url = strUrl;

		return objMarkupBeginSegment;
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Generates a ConnectApi.MarkupEndSegmentInput based off input parameters.
	 * @Parm        : markupType - Markup type to generate
	 * @Return      : objMarkupEndSegment - Complete ConnectApi.MarkupEndSegmentInput
	 **/
	public static ConnectApi.MarkupEndSegmentInput markupEnd(ConnectApi.MarkupType strMarkupType) {
		ConnectApi.MarkupEndSegmentInput objMarkupEndSegment = new ConnectApi.MarkupEndSegmentInput();
		objMarkupEndSegment.MarkupType = strMarkupType;

		return objMarkupEndSegment;
	}
}