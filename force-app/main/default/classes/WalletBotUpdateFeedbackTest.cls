/**
 * @description  Testing Wallet Feedback functionality
 * @author       Praveen Sethu
 * @date         10-26-2022
 * @see          WalletBotUpdateFeedbackTest
 **/
@isTest
public with sharing class WalletBotUpdateFeedbackTest {
	/**
	 * @Author:			Praveen Sethu
	 * @Description:	Tests if invocable is able to successfully receieve input and send back success and error messages
	 * @Parms:			NA
	 */
	@isTest
	public static void testWalletFeedback() {
		WalletBotUpdateFeedback.FeedbackInput objInput = new WalletBotUpdateFeedback.FeedbackInput();
		objInput.strChatKey = 'chat key';
		List<WalletBotUpdateFeedback.FeedbackOutput> list_FeedbackOutput = WalletBotUpdateFeedback.updateFeedback(new List<WalletBotUpdateFeedback.FeedbackInput>{ objInput });
		System.assertEquals(false, list_FeedbackOutput.get(0).blnSuccess);
	}
}