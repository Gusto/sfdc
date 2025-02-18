/**
 * @description  Get estimated wait time for chat button
 * @author       Debasmita Rawooth
 * @date         09-10-2023
 * @see          RetrieveAgentWaitTimeControllerTest
 **/
public with sharing class RetrieveAgentWaitTimeController {
	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Wrapper for HTTP Response
	 **/
	public class ResponseWrapper {
		public List<Messages> messages;
	}

	public class Messages {
		public String type;
		public Message message;
	}

	public class Message {
		public List<Results> results;
	}

	public class Results {
		public Integer estimatedWaitTime;
		public String id;
		public Boolean isAvailable;
	}

	/**
	 * @description  Invocable class to send input from bot
	 **/
	public class WaitTimeInput {
		@InvocableVariable(required=true)
		public String strEndpointUrl;
	}

	/**
	 * @description  Invocable class to share output with bot
	 **/
	public class WaitTimeOutput {
		@InvocableVariable(required=true)
		public Decimal intEstimatedWaitTimeMinutes;
	}

	/**
	 * @description Calls Chat API to retrieve agent wait time based on the chat button
	 * @author      Debasmita Rawooth
	 * @param       list_WaitTimeInputs
	 * @return      list_WaitTimeOutputs
	 **/
	@InvocableMethod(callout=true label='Get Estimated Wait Time' description='Get estimated agent wait time for chat.')
	public static List<WaitTimeOutput> getEstimatedWaitTime(List<WaitTimeInput> list_WaitTimeInputs) {
		List<WaitTimeOutput> list_WaitTimeOutputs = new List<WaitTimeOutput>();
		WaitTimeOutput objWaitTimeOutput = new WaitTimeOutput();

		String strEndPoint = list_WaitTimeInputs[0].strEndpointUrl;
		//callout to Chat API
		HttpRequest objHTTPReq = new HttpRequest();
		objHTTPReq.setEndpoint(strEndPoint);
		objHTTPReq.setMethod('GET');
		objHTTPReq.setHeader('X-LIVEAGENT-API-VERSION', '59');
		objHTTPReq.setTimeOut(120000);

		Http objHTTP = new Http();
		HTTPResponse objHTTPResponse = objHTTP.send(objHTTPReq);

		if (objHTTPResponse.getStatusCode() == 200) {
			// Process the successful response
			ResponseWrapper objResponseWrapper = (ResponseWrapper) System.JSON.deserialize(objHTTPResponse.getBody(), ResponseWrapper.class);

			List<Results> objResults = new List<Results>();

			for (Messages objMessage : objResponseWrapper.messages) {
				Message objMsg = objMessage.message;
				for (Results objResult : objMsg.results) {
					if (objResult.isAvailable == true && objResult.estimatedWaitTime != -1 && objResult.estimatedWaitTime != 0) {
						if ((objResult.estimatedWaitTime / 60 > 1) && (objResult.estimatedWaitTime / 60 < 20)) {
							objWaitTimeOutput.intEstimatedWaitTimeMinutes = Math.round(objResult.estimatedWaitTime / 60);
						}
						list_WaitTimeOutputs.add(objWaitTimeOutput);
					}
				}
			}
		} else {
			// Get the error message from the response body
			String strResponseBody = objHTTPResponse.getBody();

			// Parse the response body to extract the error message
			Map<String, Object> map_ErrorResponse = (Map<String, Object>) JSON.deserializeUntyped(strResponseBody);
			String strErrorMessage = (String) map_ErrorResponse.get('message');

			ExceptionLogUtil.logException('RetrieveChatWaitTime', 'getEstimatedWaitTime', strErrorMessage, 'Medium');
		}
		return list_WaitTimeOutputs;
	}
}