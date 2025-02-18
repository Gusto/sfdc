/**
 *  @author David (Dato) Tsamalashvili
 *  @since 07/11/2023
 *  @version 1.0
 *  @description Test class for ChimaAIPreChatController
 **/
@isTest
public class ChimaAIPreChatControllerTest {
	@testSetup
	static void setupTestData() {
		Chima_AI_Config__c objChimaAIConfigBuilder = new TestDataFactory.ChimaAIConfigBuilder()
			.setCoPilotToken('testKey')
			.setCoPilotTimeout(5000)
			.setCoPilotPermissionSet('Chima')
			.setBenefitCoPilotEndpoint('https://test.com')
			.setMulesoftConverseEndpoint('https://test.com')
			.setMulesoftAIResponseFeedbackEndpoint('https://test.com')
			.build();

		insert objChimaAIConfigBuilder;

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
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits BYB')
			.setType('BYOB')
			.setSubject('Test Stamp Sales Cases Changes Update')
			.setStatus('New')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Stamp Sales Cases Changes Update')
			.build();

		insert objCase;

		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder().setRecordTypeId('Internal').setCaseId(objCase.Id).setChatVisitor(objLiveChatVisitor.Id).build();
		insert objLiveChatTranscript;
	}

	/**
	 * @author      David (Dato) Tsamalashvili
	 * @description Test method for chimaAISupportConversation
	 **/
	@isTest
	static void testChimaAISupportConversation() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new ChimaAIPreChatControllerMockTest(true));

		Case objCase = [SELECT Id FROM Case LIMIT 1];

		ChimaAIPreChatController.ResponseWrapper objResponse = ChimaAIPreChatController.chimaAISupportConversation('How to add an employee?', objCase.Id, '/' + objCase.Id);
		ChimaAIPreChatController.updateAIInteractionTimer(objResponse.strAIInteractionId, 10);

		Test.stopTest();

		System.assertNotEquals(null, objResponse.answer, 'Answer is null');
		System.assertEquals('This is a test response', objResponse.answer, 'Answer is empty');
	}

	/**
	 * @author      Yogesh Kherajani
	 * @description Test method for chimaAISupportConversation Error
	 **/
	@isTest
	static void testChimaAISupportConversationError() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new ChimaAIPreChatControllerMockTest(false));

		Case objCase = [SELECT Id FROM Case LIMIT 1];

		ChimaAIPreChatController.ResponseWrapper objResponse = ChimaAIPreChatController.chimaAISupportConversation('How to add an employee?', objCase.Id, '/' + objCase.Id);
		ChimaAIPreChatController.updateAIInteractionTimer(objResponse.strAIInteractionId, 10);

		Test.stopTest();

		System.assertNotEquals(null, objResponse.answer, 'Answer is null');
		System.assertEquals(true, objResponse.blnHasError, 'Answer is empty');
	}

	/**
	 * @author      David (Dato) Tsamalashvili
	 * @description Test method for displayCoPilot
	 **/
	@isTest
	static void testDisplayCoPilot() {
		Boolean blnDisplayCoPilot = ChimaAIPreChatController.displayCoPilot();

		System.assertEquals(false, blnDisplayCoPilot, 'Permission set is assigned!!!');
	}

	/**
	 * @author      David (Dato) Tsamalashvili
	 * @description Test method for chimaAISupportFeedback
	 **/
	@isTest
	static void testChimaAISupportFeedback() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new ChimaAIPreChatControllerMockTest(true));

		String strResponse = ChimaAIPreChatController.chimaAISupportFeedback(1, '3234243254242', 'cx', '', null);
		Test.stopTest();

		System.assertNotEquals(null, strResponse, 'Feedback Response is null.');
		System.assertEquals('SUCCESS', strResponse, 'Response is not successful.');
	}

	/**
	 * @author      Yogesh Kherajani
	 * @description Test method for chimaBenefitAISupportConversation
	 **/
	@isTest
	static void testBenefitChimaAISupportConversation() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new ChimaAIPreChatControllerMockTest(true));

		ChimaAIPreChatController.ChimaBenefitAIConversationWrapper objChimaBenefitAIConversation = new ChimaAIPreChatController.ChimaBenefitAIConversationWrapper();
		objChimaBenefitAIConversation.strInputQuestion = 'How to add an employee?';
		objChimaBenefitAIConversation.model = 'Base Model';
		ChimaAIPreChatController.ResponseWrapper objResponse = ChimaAIPreChatController.chimaBenefitAISupportConversation(objChimaBenefitAIConversation);
		Test.stopTest();

		System.assertNotEquals(null, objResponse.answer, 'Answer is null');
		System.assertEquals('This is a test response', objResponse.answer, 'Answer is empty');
	}

	/**
	 * @author      Yogesh Kherajani
	 * @description Test method for getChimaAIConversationDetails
	 **/
	@isTest
	static void testGetChimaAIConversationDetails() {
		LiveChatTranscript objLiveChatTranscript = [SELECT Id FROM LiveChatTranscript ORDER BY CreatedDate DESC LIMIT 1];

		AI_Interaction_Detail__c objAIInteractionDetail = new TestDataFactory.AIInteractionDetailBuilder()
			.setUserQuestion('How to add an employee?')
			.setAIResponse('Here is the article')
			.setLiveChatTranscript(objLiveChatTranscript.Id)
			.build();

		insert objAIInteractionDetail;

		List<AI_Interaction_Detail__c> lst_AIInteractionDetail = ChimaAIPreChatController.getChimaAIConversationDetails(objLiveChatTranscript.Id);

		System.assert(!lst_AIInteractionDetail.isEmpty(), 'Chat Transcript should have related interactions');
	}

	/**
	 * @author      Yogesh Kherajani
	 * @description Test method for getChatButtonLst
	 **/
	@isTest
	static void testGetChatButtonLst() {
		List<LiveChatButton> lst_LiveChatButton = ChimaAIPreChatController.getChatButtonLst();

		System.assert(!lst_LiveChatButton.isEmpty(), 'Live chat button should be returned');
	}

	/**
	 * @author      Yogesh Kherajani
	 * @description Test method for createErrorLog
	 **/
	@isTest
	static void testCreateErrorLog() {
		ChimaAIPreChatController.createErrorLog('Test Error');

		List<Exception_Log__c> lst_ExceptionLog = [SELECT Id FROM Exception_Log__c];

		System.assert(!lst_ExceptionLog.isEmpty(), 'Exception log should be created');
	}

	/**
	 * @author      Yogesh Kherajani
	 * @description Test method for get todays current user AI Interaction record
	 **/    
    @isTest
    static void testGetTodayLiveChatTranscripts(){
        LiveChatTranscript objLiveChatTranscript = [SELECT Id FROM LiveChatTranscript ORDER BY CreatedDate DESC LIMIT 1];

		AI_Interaction_Detail__c objAIInteractionDetail = new TestDataFactory.AIInteractionDetailBuilder()
			.setUserQuestion('How to add an employee?')
			.setAIResponse('Here is the article')
			.setLiveChatTranscript(objLiveChatTranscript.Id)
			.build();

		insert objAIInteractionDetail;
        
        List<AI_Interaction_Detail__c> lst_AIInteractionDetail = ChimaAIPreChatController.getTodayLiveChatTranscripts(new List<String>{});
        
        System.assert(!lst_AIInteractionDetail.isEMpty(), 'Ai Interaction should be created');
    }
}