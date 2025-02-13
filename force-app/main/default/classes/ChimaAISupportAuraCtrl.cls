/**
 * @name         : ChimaAISupportAuraCtrl
 * @author       : Yogesh Kherajani
 * @date         : 24/04/2024
 * @description  : Controller class for Chima AI to link chat transcript record with interaction records
 * @see 		 : ChimaAISupportAuraCtrlTest
 **/
public without sharing class ChimaAISupportAuraCtrl {
	private static final String AGENT_FEEDBACK = 'Agent Feedback';

	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : Link chat transcript record with interaction records
	 * @param       : strCaseRecId - Case Record Id
	 * @param		: lst_AIInteractionDetailIds - List AI Interaction Ids
	 **/
	@AuraEnabled
	public static void handleUpdateLiveChatTranscriptOnAIInteraction(String strChatKey, List<String> lst_AIInteractionDetailIds) {
		try {
			LiveChatTranscript objLiveChatTranscript = [SELECT Id FROM LiveChatTranscript WHERE ChatKey = :strChatKey];

			List<AI_Interaction_Detail__c> lst_AIInteractionDetail = new List<AI_Interaction_Detail__c>();

			for (String strAIInteractionDetailId : lst_AIInteractionDetailIds) {
				AI_Interaction_Detail__c objAIInteractionDetail = new AI_Interaction_Detail__c();
				objAIInteractionDetail.Id = strAIInteractionDetailId;
				objAIInteractionDetail.Chat_Transcript__c = objLiveChatTranscript.Id;

				lst_AIInteractionDetail.add(objAIInteractionDetail);
			}

			if (!lst_AIInteractionDetail.isEmpty()) {
				update lst_AIInteractionDetail;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ChimaAISupportAuraCtrl', 'handleUpdateLiveChatTranscriptOnAIInteraction', objException);
			throw new AuraHandledException(objException.getMessage());
		}
	}

	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : Create AI Interaction detail for agent feedback for interaction with captain
	 * @param       : strChatKey - Live agent session key
	 * @param		: strFeedback - feedback provided by agent for interaction with captain
	 * @param		: strInteractionRating - rating provide by agent for interaction with captain
	 **/
	@AuraEnabled
	public static void updateAgentFeedback(String strChatKey, String strFeedback, String strInteractionRating) {
		//Get the LiveChatTranscript Id for the specific chatkey
		List<LiveChatTranscript> lst_LiveChatTranscript = [SELECT Id FROM LiveChatTranscript WHERE ChatKey = :strChatKey];

		if (!lst_LiveChatTranscript.isEmpty()) {
			try {
				//Create AI Interaction Record
				AI_Interaction_Detail__c objAIInteractionDetail = new AI_Interaction_Detail__c();
				objAIInteractionDetail.Interaction_Id__c = 'conversationid' + Datetime.now().getTime();
				objAIInteractionDetail.Type__c = AGENT_FEEDBACK;
				objAIInteractionDetail.Interaction_Rating__c = strInteractionRating;
				objAIInteractionDetail.Agent_Feedback__c = strFeedback;
				objAIInteractionDetail.Chat_Transcript__c = lst_LiveChatTranscript[0].Id;

				insert objAIInteractionDetail;
			} catch (Exception objException) {
				ExceptionLogUtil.logException('ChimaAISupportAuraCtrl', 'updateAgentFeedback', objException);
				throw new AuraHandledException(objException.getMessage());
			}
		}
	}

	/**
	 * @Author      : Yogesh Kherajani
	 * @Description : Get live chat transcript details
	 * @param       : strChatKey - Live agent session key
	 **/
	@AuraEnabled
	public static List<LiveChatTranscript> getLiveChatTranscriptDetail(String strChatKey) {
		//Get the LiveChatTranscript Id for the specific chatkey
		return [SELECT Id, Owner.Name FROM LiveChatTranscript WHERE ChatKey = :strChatKey];
	}
}