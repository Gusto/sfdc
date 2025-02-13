/**
 * @name         : ChimaAIPreChatController
 * @author       : David (Dato) Tsamalashvili
 * @date         : 07/11/2023
 * @description  : Controller class for Chima AI API Callouts
 * @see 		 : ChimaAIPreChatControllerTest
 **/
public without sharing class ChimaAIPreChatController {
	private static final String CX_CO_Pilot = 'CX Co-Pilot';
	private static final String BENEFITS_CO_Pilot = 'Benefits Co-Pilot';
	private static final String CASE_COMPLETION = 'Case Completion';
	private static final String Dingo_CX_CO_Pilot = 'Dingo AI CX Co-Pilot';
	private static final String COMPONENT_TYPE_CX = 'cx';
	private static final String COMPONENT_TYPE_BENEFITS = 'benefits';
	private static final String AI_TOOL_MULESOFT = 'Mulesoft';
	private static final String AI_TOOL_CHIMA = 'Chima';
	private static final String CHIMA_CX_ERROR_MESSAGE = 'CX Co-Pilot is not available at this moment. You can try again or talk with Advanced Product Specialist.';
	private static final String CHIMA_BENEFITS_ERROR_MESSAGE = 'Benfits Co-Pilot is not available at this moment. Please try again in sometime.';
	@testvisible
	private static final String CO_PILOT = 'CO-PILOT';

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Handles API Callout to Chima AI for Utility Bar
	 * @param       : strInputQuestion - question entered by user
	 * @Return      : responseWrapper - answer with details from Chima AI
	 **/
	@AuraEnabled
	public static ResponseWrapper chimaAISupportConversation(String strInputQuestion, String strRecordURL, String strRecordId) {
		//Get default settings from custom settings
		Chima_AI_Config__c objConfig = Chima_AI_Config__c.getOrgDefaults();
		String strChimaAIBearerToken = objConfig.Co_Pilot_Token__c;
		Integer intChimaAITimeout = (Integer) objConfig.Co_Pilot_TimeOut__c;
		String strResponse = '';

		strInputQuestion = strInputQuestion.replaceAll('"', '\\\\"');

		ChimaAIPreChatController.ChimaBenfitAIRequestWrapper objRequest = new ChimaAIPreChatController.ChimaBenfitAIRequestWrapper();
		objRequest.user_question = strInputQuestion;
		objRequest.conversation_history = new List<ChimaAIPreChatController.ChimaBenefitConversationHistoryWrapper>();
		objRequest.timestamp = '06-16-2023 10:48 PM PT';
		objRequest.company_uuid = '1872631872';
		objRequest.company_id = 17612712;
		objRequest.user_role_id = 12197219;
		objRequest.conversation_id = '';
		objRequest.salesforce_user_id = UserInfo.getUserId();
		objRequest.salesforce_name = UserInfo.getName();

		String strRequestBody = JSON.serialize(objRequest);

		HttpRequest objHTTPRequest = new HttpRequest();

		objHTTPRequest.setEndpoint(objConfig.Mulesoft_Converse_Endpoint__c);
		objHTTPRequest.setHeader('Authorization', 'Basic ' + objConfig.Mulesoft_Authorization__c);

		objHTTPRequest.setMethod('POST');
		objHTTPRequest.setHeader('Content-Type', 'application/json');
		objHTTPRequest.setTimeout(intChimaAITimeout);
		objHTTPRequest.setBody(strRequestbody);

		try {
			HttpResponse objHTTPResponse = new Http().send(objHTTPRequest);

			if (objHTTPResponse.getStatusCode() == 200) {
				// Process the successful response from the external web service
				strResponse = objHTTPResponse.getBody();
				ResponseWrapper objResponseWrapper = null;

				// JSON response formats from Mulesoft are slightly different
				// Actual response from Mulesoft is available within the 'message' attribute
				MulesoftResponseWrapper objMulesoftResponseWrapper = (MulesoftResponseWrapper) JSON.deserialize(strResponse, MulesoftResponseWrapper.class);
				objResponseWrapper = objMulesoftResponseWrapper.message;

				String strCurrentAIModal = objMulesoftResponseWrapper.response_received_from == CO_PILOT ? Dingo_CX_CO_Pilot : CX_CO_Pilot;

				// check if chima conversation has proper answer
				if (String.isBlank(objResponseWrapper.answer) || String.isBlank(objResponseWrapper.conversation_id)) {
					return handleChimaErrorMsg(strInputQuestion, CHIMA_CX_ERROR_MESSAGE, strCurrentAIModal);
				}

				objResponseWrapper.answerURL = objResponseWrapper.support_url;
				objResponseWrapper.conversation_id = objResponseWrapper.conversation_id;

				//Create AI Interaction Record
				AI_Interaction_Detail__c objAIInteractionDetail = new AI_Interaction_Detail__c();
				objAIInteractionDetail.User_Question__c = strInputQuestion;
				objAIInteractionDetail.AI_Response__c = objResponseWrapper.answer;
				objAIInteractionDetail.AI_Response_Article_URL__c = objResponseWrapper.answerURL;
				objAIInteractionDetail.Interaction_Id__c = objResponseWrapper.conversation_id;
				objAIInteractionDetail.Type__c = strCurrentAIModal;
				objAIInteractionDetail.Page_Source__c = strRecordURL;

				// Link case record
				if (String.isNotBlank(strRecordId) && strRecordId.startsWith('500')) {
					objAIInteractionDetail.Case__c = strRecordId;
				}

				insert objAIInteractionDetail;

				objResponseWrapper.strAIInteractionId = objAIInteractionDetail.Id;

				return objResponseWrapper;
			} else {
				return handleChimaErrorMsg(strInputQuestion, CHIMA_CX_ERROR_MESSAGE, Dingo_CX_CO_Pilot);
			}
		} catch (Exception objException) {
			objException.setMessage(objException.getMessage() + ' ==== ' + strRequestbody + ' ==== ' + strResponse);

			ExceptionLogUtil.logException('ChimaAIPreChatController', 'chimaAISupportConversation', objException);
			return handleChimaErrorMsg(strInputQuestion, CHIMA_CX_ERROR_MESSAGE, Dingo_CX_CO_Pilot);
		}
	}

	@AuraEnabled
	public static void createErrorLog(String strErrorMessage) {
		ExceptionLogUtil.logException('ChimaAIPreChatController', 'chimaAISupportConversation', strErrorMessage, '');
	}

	@AuraEnabled
	public static void updateAIInteractionTimer(String strAIInteractionId, Integer intCalloutProcessingTime) {
		AI_Interaction_Detail__c objAIInteractionDetail = [SELECT Id FROM AI_Interaction_Detail__c WHERE Id = :strAIInteractionId];

		objAIInteractionDetail.Callout_Processing_Time__c = intCalloutProcessingTime;

		try {
			update objAIInteractionDetail;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ChimaAIPreChatController', 'updateAIInteractionTimer', objException);
			throw new AuraHandledException(objException.getMessage());
		}
	}

	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : Handle chima error message
	 * @param       : strInputQuestion - input question
	 * @Return      : ResponseWrapper - Chima Response
	 **/
	private static ResponseWrapper handleChimaErrorMsg(String strInputQuestion, String strErrorMessage, String strInteractionType) {
		ResponseWrapper objResponseWrapper = new ResponseWrapper();
		objResponseWrapper.answerURL = '';
		objResponseWrapper.conversation_id = 'conversationid' + Datetime.now().getTime();
		objResponseWrapper.answer = strErrorMessage;
		objResponseWrapper.blnHasError = true;

		try {
			AI_Interaction_Detail__c objAIInteractionDetail = new AI_Interaction_Detail__c();
			objAIInteractionDetail.User_Question__c = strInputQuestion;
			objAIInteractionDetail.AI_Response__c = strErrorMessage;
			objAIInteractionDetail.AI_Response_Article_URL__c = '';
			objAIInteractionDetail.Interaction_Id__c = objResponseWrapper.conversation_id;
			objAIInteractionDetail.Type__c = strInteractionType;

			insert objAIInteractionDetail;

			objResponseWrapper.strAIInteractionId = objAIInteractionDetail.Id;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ChimaAIPreChatController', 'handleChimaErrorMsg', objException);
			throw new AuraHandledException(objException.getMessage());
		}

		return objResponseWrapper;
	}

	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : Get AI Interaction Detail by live chat transcript Id
	 * @param       : strLiveChatTranscriptId - Live chat transcript Id
	 * @Return      : List<AI_Interaction_Detail__c> - List of AI Interaction Details
	 **/
	@AuraEnabled(cacheable=true)
	public static List<AI_Interaction_Detail__c> getChimaAIConversationDetails(String strLiveChatTranscriptId) {
		if (String.isBlank(strLiveChatTranscriptId)) {
			return new List<AI_Interaction_Detail__c>();
		}

		return [
			SELECT
				Id,
				User_Question__c,
				AI_Response__c,
				CreatedBy.Name,
				AI_Response_Article_URL__c,
				Interaction_Id__c,
				Rating__c,
				Feedback__c,
				Advanced_Support_Feedback__c,
				Advanced_Support_Rating__c,
				Chat_Transcript__c,
				Chat_Transcript__r.Status,
				Chat_Transcript__r.OwnerId
			FROM AI_Interaction_Detail__c
			WHERE Chat_Transcript__c = :strLiveChatTranscriptId
			ORDER BY CreatedDate ASC
		];
	}

	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : Get Chat Button List
	 * @Return      : List<LiveChatButton> - List of Live Chat Button
	 **/
	@AuraEnabled(cacheable=true)
	public static List<LiveChatButton> getChatButtonLst() {
		Id idCurrentUser = UserInfo.getUserId();

		User objUser = [SELECT Id, Vendor__c, Profile.Name FROM User WHERE Id = :idCurrentUser];

		if ((String.isBlank(objUser.Vendor__c) || objUser.Vendor__c == 'Gusto') && objUser.Profile.Name != 'Vendor CX') {
			return [SELECT Id, DeveloperName FROM LiveChatButton WHERE DeveloperName = 'Payroll_Internal' OR DeveloperName = 'Benefits_Internal' ORDER BY DeveloperName DESC];
		}

		return [SELECT Id, DeveloperName FROM LiveChatButton WHERE DeveloperName = 'Vendor_SME_PRC_Internal'];
	}

	public class ChimaBenefitAIConversationWrapper {
		@AuraEnabled
		public String strInputQuestion { get; set; }
		@AuraEnabled
		public String model { get; set; }
	}

	public class ChimaBenfitAIRequestWrapper {
		public String user_question;
		public List<ChimaBenefitConversationHistoryWrapper> conversation_history;
		public String timestamp;
		public String company_uuid;
		public Integer company_id;
		public Integer user_role_id;
		public String conversation_id;
		public String salesforce_user_id;
		public String salesforce_name;
		public String team;
		public String model;
	}

	public class ChimaBenefitConversationHistoryWrapper {
		public String question;
		public String answer;
	}

	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : Handles API Callout to Chima Benefit AI for Utility Bar
	 * @Parm        : strInputQuestion - question entered by user
	 * @Return      : responseWrapper - answer with details from Chima AI
	 **/
	@AuraEnabled
	public static ResponseWrapper chimaBenefitAISupportConversation(ChimaBenefitAIConversationWrapper objChimaBenefitAIConversation) {
		//Get default settings from custom settings
		Chima_AI_Config__c objConfig = Chima_AI_Config__c.getOrgDefaults();
		String strChimaAIEndPoint = objConfig.Benefit_Co_Pilot_Endpoint__c;
		String strChimaAIBearerToken = objConfig.Co_Pilot_Token__c;
		Integer intChimaAITimeout = (Integer) objConfig.Co_Pilot_TimeOut__c;

		User obCurrentUser = [SELECT Id, Name, Sub_Team__c FROM User WHERE Id = :UserInfo.getuserId()];

		// Make the callout to the external web service
		ChimaBenfitAIRequestWrapper chimaBenefitAIRequestObj = new ChimaBenfitAIRequestWrapper();
		chimaBenefitAIRequestObj.user_question = objChimaBenefitAIConversation.strInputQuestion;
		chimaBenefitAIRequestObj.conversation_history = new List<ChimaBenefitConversationHistoryWrapper>();
		chimaBenefitAIRequestObj.timestamp = '06-16-2023 10:48 PM PT';
		chimaBenefitAIRequestObj.company_uuid = '1872631872';
		chimaBenefitAIRequestObj.company_id = 17612712;
		chimaBenefitAIRequestObj.user_role_id = 12197219;
		chimaBenefitAIRequestObj.conversation_id = '';
		chimaBenefitAIRequestObj.salesforce_user_id = obCurrentUser.Id;
		chimaBenefitAIRequestObj.salesforce_name = obCurrentUser.Name;
		chimaBenefitAIRequestObj.team = obCurrentUser.Sub_Team__c;
		chimaBenefitAIRequestObj.model = String.isNotBlank(objChimaBenefitAIConversation.model) ? objChimaBenefitAIConversation.model.toLowercase() : objChimaBenefitAIConversation.model;

		String strRequestbody = JSON.serialize(chimaBenefitAIRequestObj);

		HttpRequest objHTTPRequest = new HttpRequest();
		objHTTPRequest.setEndpoint(strChimaAIEndPoint);
		objHTTPRequest.setMethod('POST');
		objHTTPRequest.setHeader('Content-Type', 'application/json');
		objHTTPRequest.setTimeout(intChimaAITimeout);
		objHTTPRequest.setHeader('Authorization', 'Bearer ' + strChimaAIBearerToken);
		objHTTPRequest.setBody(strRequestbody);

		try {
			HttpResponse objHTTPResponse = new Http().send(objHTTPRequest);

			if (objHTTPResponse.getStatusCode() == 200) {
				// Process the successful response from the external web service
				String strResponse = objHTTPResponse.getBody();

				// JSON response formats from Mulesoft are slightly different
				// Actual response from Mulesoft is available within the 'message' attribute
				MulesoftResponseWrapper objMulesoftResponseWrapper = (MulesoftResponseWrapper) JSON.deserialize(strResponse, MulesoftResponseWrapper.class);
				ResponseWrapper objResponseWrapper = objMulesoftResponseWrapper.message;

				objResponseWrapper.answerURL = objResponseWrapper.support_url;
				objResponseWrapper.conversation_id = objResponseWrapper.conversation_id;

				if (String.isBlank(objResponseWrapper.answer) || String.isBlank(objResponseWrapper.conversation_id)) {
					return handleChimaErrorMsg(objChimaBenefitAIConversation.strInputQuestion, CHIMA_BENEFITS_ERROR_MESSAGE, BENEFITS_CO_Pilot);
				}

				//Create AI Interaction Record
				AI_Interaction_Detail__c objAIInteractionDetail = new AI_Interaction_Detail__c();
				objAIInteractionDetail.User_Question__c = objChimaBenefitAIConversation.strInputQuestion;
				objAIInteractionDetail.AI_Response__c = objResponseWrapper.answer;
				objAIInteractionDetail.AI_Response_Article_URL__c = objResponseWrapper.support_url_1;
				objAIInteractionDetail.AI_Response_Article_URL_2__c = objResponseWrapper.support_url_2;
				objAIInteractionDetail.AI_Response_Article_URL_3__c = objResponseWrapper.support_url_3;
				objAIInteractionDetail.Interaction_Id__c = objResponseWrapper.conversation_id;
				objAIInteractionDetail.Type__c = BENEFITS_CO_Pilot;

				insert objAIInteractionDetail;

				return objResponseWrapper;
			} else {
				return handleChimaErrorMsg(objChimaBenefitAIConversation.strInputQuestion, CHIMA_BENEFITS_ERROR_MESSAGE, BENEFITS_CO_Pilot);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ChimaAIPreChatController', 'chimaBenefitAISupportConversation', objException);
			return handleChimaErrorMsg(objChimaBenefitAIConversation.strInputQuestion, CHIMA_BENEFITS_ERROR_MESSAGE, BENEFITS_CO_Pilot);
		}
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Handles API Callout to Chima AI for Utility Bar
	 * @param       : intRating - current response rating
	 * @param       : strQuestionId - conversation id generated by Chima AI
	 * @param       : componentType - Represent from where chima componenet is called CX or Benefit
	 * @param       : strFeedback - Feedback for each interaction
	 * @Return      : responseWrapper - answer with details from Chima AI
	 **/
	@AuraEnabled
	public static String chimaAISupportFeedback(Integer intRating, String strQuestionId, String componentType, String strFeedback, String strTranscriptId) {
		List<AI_Interaction_Detail__c> lst_AIInteraction = [SELECT Id, Type__c FROM AI_Interaction_Detail__c WHERE Interaction_Id__c = :strQuestionId ORDER BY CreatedDate DESC LIMIT 1];

		//Get default settings from custom settings
		Chima_AI_Config__c objConfig = Chima_AI_Config__c.getOrgDefaults();
		String strChimaAIBearerToken = objConfig.Co_Pilot_Token__c;
		Integer intChimaAITimeout = (Integer) objConfig.Co_Pilot_TimeOut__c;
		String strModelContext = '';
		String SUCCESS = 'SUCCESS';
		Boolean blnCaptainRequest = false;
		Boolean blnIsAllowedFeedbackCallout = true;

		if (String.isNotBlank(strTranscriptId)) {
			LiveChatTranscript objTranscript = [SELECT Id, OwnerId FROM LiveChatTranscript WHERE Id = :strTranscriptId];
			// set captain request to true if transcript owner is the same as the logged in user
			blnCaptainRequest = objTranscript.OwnerId == UserInfo.getUserId();
		}

		if (componentType == COMPONENT_TYPE_CX) {
			strModelContext = objConfig.Co_Pilot_Model_Context__c;
		} else if (componentType == COMPONENT_TYPE_BENEFITS) {
			strModelContext = objConfig.Benefits_Model_Context__c;

			//Stop user to give feedback for benefits co pilot
			Chima_AI_Feedback__c objChimaAIFeedback = Chima_AI_Feedback__c.getInstance(UserInfo.getUserId());

			if (objChimaAIFeedback.Send_No_Feedback__c != null && objChimaAIFeedback.Send_No_Feedback__c) {
				blnIsAllowedFeedbackCallout = false;
			}
		}

		if (String.isNotBlank(strFeedback)) {
			strFeedback = strFeedback.replaceAll('"', '\\\\"');
		}

		//check user is allowed to give feedback for benefits co pilot
		if (blnIsAllowedFeedbackCallout) {
			ChimaFeedbackRequestWrapper objChimaFeedbackRequestWrapper = new ChimaFeedbackRequestWrapper();

			objChimaFeedbackRequestWrapper.company_uuid = '1872631872';
			objChimaFeedbackRequestWrapper.company_id = 17612712;
			objChimaFeedbackRequestWrapper.user_role_id = 12197219;
			objChimaFeedbackRequestWrapper.model_context = strModelContext;
			objChimaFeedbackRequestWrapper.rating = intRating;
			objChimaFeedbackRequestWrapper.conversation_id = strQuestionId;
			objChimaFeedbackRequestWrapper.salesforce_user_id = UserInfo.getUserId();
			objChimaFeedbackRequestWrapper.salesforce_name = UserInfo.getName();
			objChimaFeedbackRequestWrapper.feedback = String.isBlank(strFeedback) ? '' : strFeedback;
			objChimaFeedbackRequestWrapper.captain_interaction = blnCaptainRequest;

			if (!lst_AIInteraction.isEmpty()) {
				objChimaFeedbackRequestWrapper.type = lst_AIInteraction[0].Type__c == Dingo_CX_CO_Pilot ? 'COPILOT' : 'CHIMA';
			}

			// Make the callout to the external web service
			String strRequestbody = JSON.serialize(objChimaFeedbackRequestWrapper);
			System.debug(strRequestbody);

			HttpRequest objHTTPRequest = new HttpRequest();

			// Decide whether Mulesoft is the AI tool
			objHTTPRequest.setEndpoint(objConfig.Mulesoft_AI_Response_Feedback_Endpoint__c);
			objHTTPRequest.setHeader('Authorization', 'Basic ' + objConfig.Mulesoft_Authorization__c);

			objHTTPRequest.setMethod('POST');
			objHTTPRequest.setHeader('Content-Type', 'application/json');
			objHTTPRequest.setTimeout(intChimaAITimeout);
			objHTTPRequest.setBody(strRequestbody);

			try {
				HttpResponse objHTTPResponse = new Http().send(objHTTPRequest);

				if (objHTTPResponse.getStatusCode() != 200) {
					// Get the error message from the response body
					String strResponseBody = objHTTPResponse.getBody();

					// Parse the response body to extract the error message
					Map<String, Object> map_ErrorResponse = (Map<String, Object>) JSON.deserializeUntyped(strResponseBody);
					String strErrorMessage = (String) map_ErrorResponse.get('message');

					throw new AuraHandledException(strErrorMessage);
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException('ChimaAIPreChatController', 'chimaBenefitAISupportConversation', objException);
				throw new AuraHandledException(objException.getMessage());
			}
		}

		//update AI interaction
		try {
			if (!lst_AIInteraction.isEmpty()) {
				lst_AIInteraction[0].Captain_Interaction__c = blnCaptainRequest;

				if (blnCaptainRequest) {
					lst_AIInteraction[0].Advanced_Support_Rating__c = intRating;
					lst_AIInteraction[0].Advanced_Support_Feedback__c = strFeedback;
				} else {
					lst_AIInteraction[0].Rating__c = intRating;
					lst_AIInteraction[0].Feedback__c = strFeedback;
				}

				update lst_AIInteraction;
			}

			return SUCCESS;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ChimaAIPreChatController', 'chimaBenefitAISupportConversation', objException);
			throw new AuraHandledException(objException.getMessage());
		}
	}

	public class ChimaFeedbackRequestWrapper {
		public String company_uuid;
		public Integer company_id;
		public Integer user_role_id;
		public String model_context;
		public Integer rating;
		public String conversation_id;
		public String salesforce_user_id;
		public String salesforce_name;
		public String feedback;
		public Boolean captain_interaction;
		public String type;
	}

	public class ResponseWrapper {
		@AuraEnabled
		public String answer { get; set; }
		@AuraEnabled
		public String answerURL { get; set; }
		public String support_url { get; set; }
		@AuraEnabled
		public String support_url_1 { get; set; }
		@AuraEnabled
		public String support_url_2 { get; set; }
		@AuraEnabled
		public String support_url_3 { get; set; }
		public String timestamp { get; set; }
		public String company_uuid { get; set; }
		public Integer company_id { get; set; }
		public Integer user_role_id { get; set; }
		@AuraEnabled
		public String conversation_id { get; set; }
		@AuraEnabled
		public String strAIInteractionId { get; set; }
		@AuraEnabled
		public Boolean blnHasError { get; set; }
	}

	public class MulesoftResponseWrapper {
		@AuraEnabled
		public String status { get; set; }
		@AuraEnabled
		public String event_id { get; set; }
		@AuraEnabled
		public String response_received_from { get; set; }
		@AuraEnabled
		public ResponseWrapper message { get; set; }
	}

	/**
	 * Author: David (Dato) Tsamalashvili
	 * Date: 07/12/2023
	 * Desc: does the current user have permission to see the Chima Co Pilot
	 */
	@AuraEnabled
	public static Boolean displayCoPilot() {
		Boolean blnDisplayCoPilot = validateCoPilotPermissions();

		return blnDisplayCoPilot;
	}

	/**
	 * @author David (Dato) Tsamalashvili
	 * @description get permission set assignments for the current user
	 * @return blnHasPermission
	 */
	public static Boolean validateCoPilotPermissions() {
		Chima_AI_Config__c objConfig = Chima_AI_Config__c.getOrgDefaults();
		String strChimaPermSet = objConfig.Co_Pilot_Permission_Set__c;

		Set<Id> set_PermissionSetGroupId = new Set<Id>();

		for (PermissionSetAssignment objPermissionSetAssginment : [
			SELECT Id, PermissionSet.Name, PermissionSetGroupId
			FROM PermissionSetAssignment
			WHERE AssigneeId = :UserInfo.getUserId() AND (PermissionSet.Name = :strChimaPermSet OR PermissionSetGroupId != NULL)
		]) {
			if (objPermissionSetAssginment.PermissionSet.Name == strChimaPermSet) {
				return true;
			}

			set_PermissionSetGroupId.add(objPermissionSetAssginment.PermissionSetGroupId);
		}

		for (PermissionSetGroupComponent objPermissionSetGroupComponent : [SELECT PermissionSet.Name FROM PermissionSetGroupComponent WHERE PermissionSetGroupId IN :set_PermissionSetGroupId]) {
			if (objPermissionSetGroupComponent.PermissionSet.Name == strChimaPermSet) {
				return true;
			}
		}

		return false;
	}

	/**
	 * @author Praveen Sethu
	 * @description Creates new AI Interaction Detail records
	 */
	@AuraEnabled
	public static void createAIInteraction(AI_Interaction_Detail__c objInteractionToInsert) {
		insert objInteractionToInsert;
	}

    /**
	 * @author Yogesh Kherajani
	 * @description Get todays current user AI Interaction record
	 */
	@AuraEnabled
	public static List<AI_Interaction_Detail__c> getTodayLiveChatTranscripts(List<String> strInteractionIds){
		return [
			SELECT
				Id,
				CreatedDate,
				User_Question__c,
				AI_Response__c,
				CreatedBy.Name,
				AI_Response_Article_URL__c,
				Interaction_Id__c,
				Callout_Processing_Time__c,
				Rating__c,
				Feedback__c,
				Advanced_Support_Feedback__c,
				Advanced_Support_Rating__c,
				Chat_Transcript__c,
				Chat_Transcript__r.Status,
				Chat_Transcript__r.OwnerId
			FROM AI_Interaction_Detail__c
			WHERE Id NOT IN :strInteractionIds
			AND Type__c != 'Co-Pilot Load'
			AND CreatedDate = TODAY
			AND CreatedById = :UserInfo.getUserId()
			ORDER BY CreatedDate ASC
		];
	}
}