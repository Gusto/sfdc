/**
 * @description  Testing Wallet Feedback functionality
 * @author       Praveen Sethu
 * @date         10-26-2022
 * @see          WalletBotUpdateFeedbackTest
 **/
@isTest
public with sharing class WalletBotUpdateFeedbackTest {
    
    @testSetup
    static void setUp() {
        AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
        
        Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('TEST ACCOUNT')
			.setJoinedDate(System.today())
			.setZPCompanyId(String.valueOf(Utils.getRandomIntValue(10)))
			.build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('TEST1')
			.setLastName('Con1')
			.setEmail('ttest1con@test.com')
			.setZPUserId(String.valueOf(Utils.getRandomIntValue(10)))
			.build();
		insert objContact;
        
        Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Test subject')
			.setStatus('New')
			.setType('Payroll Care')
			.setOrigin('Web')
			.setDirection('Inbound')
			.setSuppliedPhone('1234567890')
			.setSubscriberId('5678765')
			.setAutomationStatus('Started')
			.build();
        insert objCase;

		LiveChatVisitor objVisitor = new LiveChatVisitor();
		insert objVisitor;

        LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
            .setChatKey('53454364')
            .setCaseId(objCase.Id)
            .setDivrid('2606f4a3-d2a6-44d9-8bf9-18de3ce97b25')
			.setRecordTypeId('External')
			.setChatVisitor(objVisitor.Id)
			.build();
		insert objLiveChat;
        
        AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		CaseTriggerHelper.skipTrigger = false;
    }
    
	/**
	 * @Author:			Praveen Sethu
	 * @Description:	Tests if invocable is able to successfully receieve input and send back success and error messages
	 * @Parms:			NA
	 */
	@isTest
	public static void testWalletLiveChatTranscript() {
		WalletBotUpdateFeedback.FeedbackInput objInput = new WalletBotUpdateFeedback.FeedbackInput();
		objInput.strChatKey = '53454364';
        objInput.strReaction = 'Smile';
        objInput.strFreeFormResponse = 'Smile';
        objInput.strQuestionAnswered = 'Yes';
		List<WalletBotUpdateFeedback.FeedbackOutput> list_FeedbackOutput = WalletBotUpdateFeedback.updateFeedback(new List<WalletBotUpdateFeedback.FeedbackInput>{ objInput });
		System.assertEquals(true, list_FeedbackOutput.get(0).blnSuccess);
	}
    
    /**
	 * @Author:			Pradeep Chary
	 * @Description:	Tests for MessagingSession
	 * @Parms:			NA
	 */
	@isTest
	public static void testWalletMessagingSession() {
		MessagingSession objSession = new MessagingSession();
		objSession.Status = 'New';
		WalletBotUpdateFeedback.objTestMessagingSession = objSession;
		
		WalletBotUpdateFeedback.FeedbackInput objInput = new WalletBotUpdateFeedback.FeedbackInput();
		objInput.strChatKey = '53454364-ms';
        objInput.strReaction = 'Smile';
        objInput.strFreeFormResponse = 'Smile';
        objInput.strQuestionAnswered = 'Yes';
		List<WalletBotUpdateFeedback.FeedbackOutput> list_FeedbackOutput = WalletBotUpdateFeedback.updateFeedback(new List<WalletBotUpdateFeedback.FeedbackInput>{ objInput });
		System.assertEquals(true, list_FeedbackOutput.get(0).blnSuccess);
	}
}