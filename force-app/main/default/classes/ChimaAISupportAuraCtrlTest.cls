/**
 * @name         : ChimaAISupportAuraCtrlTest
 * @author       : Yogesh Kherajani
 * @date         : 24/04/2024
 * @description  : This class has test methods for ChimaAISupportAuraCtrl
 **/
@isTest
public class ChimaAISupportAuraCtrlTest {
    /**
	 * @Author      : Yogesh Kherajani
	 * @Description : This method creates all the test data.
	 **/
	@testSetup
    private static void setupData(){
        // insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		//Account creation
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('TestAccount')
			.setZPCompanyId('12312321')
			.setZPFirmId('12312321')
			.setConciergeGroupId('test')
			.setConciergeGroup('test')
			.setTier(objTierConfig.New_Tier_2__c)
			.setAMTier('Gold')
			.setRecordTypeId('Company')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert objAccount;

		//Contact creation
		Contact objContact = new TestDataFactory.ContactBuilder()
            .setAccountId(objAccount.Id)
            .setLastName('TestContact')
            .setRecordTypeId('Company')
            .setZPUserId('12312321')
            .build();
		ContactTriggerHelper.skipTrigger = true;
		insert objContact;

		//Case creation
		Case objCase = new TestDataFactory.CaseBuilder()
			.setSubject('Om Test')
			.setStatus('New')
			.setOrigin('Email')
			.setSuppliedEmail('test@gmail.com')
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.build();
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
        
        LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;
        
        LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
            .setRecordTypeId('Internal')
            .setCaseId(objCase.Id)
            .setChatVisitor(objLiveChatVisitor.Id)
            .setChatKey('123')
            .build();
		insert objLiveChatTranscript;
    }
    
    /**
	 * @Author      : Yogesh Kherajani
	 * @Description : To test the handleUpdateLiveChatTranscriptOnAIInteraction method.
	 **/
    @isTest
    private static void handleUpdateLiveChatTranscriptOnAIInteractionUnitTest(){
        Case objCase = [
            SELECT Id
            FROM Case
            LIMIT 1
        ];
        
        AI_Interaction_Detail__c objAIInteractionDetail = new AI_Interaction_Detail__c();
        objAIInteractionDetail.User_Question__c = 'How to add an employee?';
        objAIInteractionDetail.AI_Response__c = 'Here is the article';
        
        INSERT objAIInteractionDetail;
        
        ChimaAISupportAuraCtrl.handleUpdateLiveChatTranscriptOnAIInteraction('123', new List<String>{objAIInteractionDetail.Id});
        
        LiveChatTranscript objLiveChatTranscript = [
            SELECT Id 
            FROM LiveChatTranscript
            WHERE CaseId = :objCase.Id 
            ORDER BY CreatedDate 
            DESC 
            LIMIT 1
        ];
        
        List<AI_Interaction_Detail__c> lst_AIInteractionDetail = [
            SELECT Id 
            FROM AI_Interaction_Detail__c 
            WHERE Chat_Transcript__c = :objLiveChatTranscript.Id
        ];
        
        System.assertEquals(lst_AIInteractionDetail.isEmpty(), false, 'AI Interaction Record should linked with Chat Transcript.');
    }
    
    /**
	 * @Author      : Yogesh Kherajani
	 * @Description : To test the updateAgentFeedback method.
	 **/
    @isTest
    private static void updateAgentFeedbackUnitTest(){
        ChimaAISupportAuraCtrl.updateAgentFeedback('123', 'Feedback', '1');
        
        List<AI_Interaction_Detail__c> lst_AIInteractionDetail = [
            SELECT Id 
            FROM AI_Interaction_Detail__c
        ];
        
        System.assertEquals(lst_AIInteractionDetail.isEmpty(), false, 'AI Interaction Record should be created');
    }
    
    /**
	 * @Author      : Yogesh Kherajani
	 * @Description : To test the getLiveChatTranscriptDetail method.
	 **/
    @isTest
    private static void getLiveChatTranscriptDetailUnitTest(){
        List<LiveChatTranscript> lst_LiveChatTranscript = ChimaAISupportAuraCtrl.getLiveChatTranscriptDetail('123');
        
        System.assertEquals(lst_LiveChatTranscript.isEmpty(), false, 'Live Chat Transcript Record should not be empty.');
    }
}