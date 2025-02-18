/**
 * @description  Get estimated wait time for chat button
 * @author       Debasmita Rawooth
 * @date         09-11-2023
 * @see          BotAgentWaitTimeControllerTest
 **/
public class BotAgentWaitTimeController_LEX {
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
	 * @description Calls Chat API to retrieve agent wait time based on the chat button
	 * @author      Debasmita Rawooth
	 * @param       endPointURL
	 * @return      Agent wait time in seconds
	 **/
	@AuraEnabled(cacheable=true)
	public static Integer getEstimatedWaitTime(String endPointURL) {
		Integer intEstimatedWaitTimeSeconds;

		//callout to Chat API
		HttpRequest objHTTPReq = new HttpRequest();
		objHTTPReq.setEndpoint(endPointURL);
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
					if (objResult.isAvailable == true && objResult.estimatedWaitTime != -1 && objResult.estimatedWaitTime > 0) {
						intEstimatedWaitTimeSeconds = objResult.estimatedWaitTime;
					}
				}
			}
		} else {
			// Get the error message from the response body
			String strResponseBody = objHTTPResponse.getBody();

			// Parse the response body to extract the error message
			Map<String, Object> map_ErrorResponse = (Map<String, Object>) JSON.deserializeUntyped(strResponseBody);
			String strErrorMessage = (String) map_ErrorResponse.get('message');

			ExceptionLogUtil.logException('BotAgentWaitTimeController_LEX', 'getEstimatedWaitTime', strErrorMessage, 'Medium');
		}
		return intEstimatedWaitTimeSeconds;
	}
}