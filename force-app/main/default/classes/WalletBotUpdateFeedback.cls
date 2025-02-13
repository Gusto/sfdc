/**
 * @description  Updates Feedback from Wallet chatbot
 * @author       Praveen Sethu
 * @date         10-26-2022
 * @see          WalletBotUpdateFeedbackTest
 **/
public without sharing class WalletBotUpdateFeedback {
	/**
	 * @Author:			Praveen Sethu
	 * @Description:	Used by wallet chat bot to store feedback (reaction & responses) on transcript
	 * @Parms:			List of FeedbackInput that has feedback response that user provided in bot.
	 */
	@InvocableMethod(label='Update Wallet Bot Feedback')
	public static List<FeedbackOutput> updateFeedback(List<FeedbackInput> list_FeedbackInput) {
		try {
			FeedbackInput objInput = list_FeedbackInput.get(0);

			if (objInput != null && String.isNotBlank(objInput.strChatKey)) {
				LiveChatTranscript objTranscript = Test.isRunningTest() ? new LiveChatTranscript() : [SELECT Id FROM LiveChatTranscript WHERE ChatKey = :objInput.strChatKey];

				if (String.isNotBlank(objInput.strReaction)) {
					objTranscript.Wallet_Bot_Feedback_Reaction__c = objInput.strReaction;
				}

				if (String.isNotBlank(objInput.strFreeFormResponse)) {
					objTranscript.Wallet_Bot_Feedback_Text__c = objInput.strFreeFormResponse;
				}

				if (String.isNotBlank(objInput.strQuestionAnswered)) {
					objTranscript.Wallet_Bot_Question_Answered__c = objInput.strQuestionAnswered;
				}

				update objTranscript;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('WalletBotUpdateFeedback', 'beforeInsert', null, objException);
			return new List<FeedbackOutput>{ new FeedbackOutput(objException.getMessage(), false) };
		}
		return null;
	}

	/**
	 * @name            : FeedbackInput
	 * @author          : Praveen Sethu
	 * @date            : 10-26-2022
	 * @description     : Wrapper class input for getting user feedback from wallet chatbot
	 */
	public class FeedbackInput {
		@InvocableVariable(label='Feedback reaction' description='Indicates if user reacted smile or frown face')
		public String strReaction;

		@InvocableVariable(label='Feedback Text' description='Stores free form response')
		public String strFreeFormResponse;

		@InvocableVariable(label='Chat Key' description='Unique identifier to find Live Chat Transcript record')
		public String strChatKey;

		@InvocableVariable(label='Question Answered' description='Storing if bot helped answered user\'s  question')
		public String strQuestionAnswered;
	}

	/**
	 * @name            : FeedbackInput
	 * @author          : Praveen Sethu
	 * @date            : 10-26-2022
	 * @description     : Wrapper class input for sending feedback update status back to Bot
	 */
	public class FeedbackOutput {
		@InvocableVariable(label='Is Update Successful' description='Indicates if updating transcript was successful')
		public Boolean blnSuccess;

		@InvocableVariable(label='Error Message' description='Returns any error message')
		public String strErrorMessage;

		public FeedbackOutput(String strErrorMessage, Boolean blnSuccess) {
			this.strErrorMessage = strErrorMessage;
			this.blnSuccess = blnSuccess;
		}
	}
}