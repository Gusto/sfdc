/**
 * @description       : To cover test coverage of ChatBotController
 * @author            : Nigam Goyal
 * @group             :
 * @last modified on  : 03-16-2023
 * @last modified by  : Nigam Goyal
 **/
@isTest
public with sharing class ChatBotControllerTest {
	@TestSetup
	public static void testSetup() {
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setTier('Simple').setRecordTypeId('Company').build();
		insert objAccount;

		Account objAccount1 = new TestDataFactory.AccountBuilder().setName('Test Account With Joined Date').setTier('Simple').setJoinedDate(System.today()).setRecordTypeId('Company').build();
		insert objAccount1;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount1.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testtranscript@gusto.com')
			.setZPUserId('789456123')
			.build();

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setAccountId(objAccount.Id)
			.setFirstName('contactFirst')
			.setLastName('contactLast')
			.setPhone('0000000000')
			.setEmail('test1@test.com')
			.setRecordTypeId('Company')
			.build();
		insert new List<Contact>{ objContact, objContact2 };

		Case objCase = new TestDataFactory.CaseBuilder()
			.setSubject('test subject')
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setStatus('Open')
			.setOrigin('Email')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.build();
		insert objCase;
	}

	/**
	 * @description Get customer Info without Joined Date
	 * @author Nigam Goyal | 03-16-2023
	 **/
	@isTest
	public static void getCustomerInfoWithoutJoinedDatePandaTest() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record and link to the Case
		LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript();
		objLiveChatTranscript.LiveChatVisitorId = objLiveChatVisitor.Id;
		objLiveChatTranscript.AccountId = objAccount.Id;
		objLiveChatTranscript.ChatKey = '7868756746';
		objLiveChatTranscript.Chat_Visitor_Email__c = 'test1@test.com';
		insert objLiveChatTranscript;

		Test.startTest();
		List<ChatBotController.TranscriptInput> list_TranscriptInputs = new List<ChatBotController.TranscriptInput>();
		ChatBotController.TranscriptInput objTranscriptInput = new ChatBotController.TranscriptInput();
		objTranscriptInput.routableID = objLiveChatTranscript.Id;
		list_TranscriptInputs.add(objTranscriptInput);
		List<ChatBotController.PayrollOutput> list_PayrollOutputs = ChatBotController.getCustomerInfo(list_TranscriptInputs);
		ChatBotController.PayrollOutput objPayrollOutput = list_PayrollOutputs[0];
		Test.stopTest();

		System.assertEquals(false, objPayrollOutput.blnIsAccountAvailableAndPayrollRun);
		System.assertEquals(true, objPayrollOutput.blnIsAccountAvailable);
	}

	/**
	 * @description Get customer info with Joined Date
	 * @author Nigam Goyal | 03-16-2023
	 **/
	@isTest
	public static void getCustomerInfoWithJoinedDatePandaTest() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Account With Joined Date'];
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record and link to the Case
		LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript();
		objLiveChatTranscript.LiveChatVisitorId = objLiveChatVisitor.Id;
		objLiveChatTranscript.AccountId = objAccount.Id;
		objLiveChatTranscript.Chat_Visitor_Email__c = 'testtranscript@gusto.com';
		objLiveChatTranscript.ChatKey = '7868756746';
		insert objLiveChatTranscript;

		Test.startTest();
		List<ChatBotController.TranscriptInput> list_TranscriptInputs = new List<ChatBotController.TranscriptInput>();
		ChatBotController.TranscriptInput objTranscriptInput = new ChatBotController.TranscriptInput();
		objTranscriptInput.routableID = objLiveChatTranscript.Id;
		list_TranscriptInputs.add(objTranscriptInput);
		List<ChatBotController.PayrollOutput> list_PayrollOutputs = ChatBotController.getCustomerInfo(list_TranscriptInputs);
		ChatBotController.PayrollOutput objPayrollOutput = list_PayrollOutputs[0];
		Test.stopTest();

		System.assertEquals(true, objPayrollOutput.blnIsAccountAvailableAndPayrollRun);
		System.assertEquals(false, objPayrollOutput.blnIsAccountAvailable);
	}

	/**
	 * @description Get customer Info without Account
	 * @author Nigam Goyal | 03-16-2023
	 **/
	@isTest
	public static void getCustomerInfoWithoutAccountTest() {
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record and link to the Case
		LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript();
		objLiveChatTranscript.LiveChatVisitorId = objLiveChatVisitor.Id;
		objLiveChatTranscript.ChatKey = '7868756746';
		insert objLiveChatTranscript;

		Test.startTest();
		List<ChatBotController.TranscriptInput> list_TranscriptInputs = new List<ChatBotController.TranscriptInput>();
		ChatBotController.TranscriptInput objTranscriptInput = new ChatBotController.TranscriptInput();
		objTranscriptInput.routableID = objLiveChatTranscript.Id;
		list_TranscriptInputs.add(objTranscriptInput);
		List<ChatBotController.PayrollOutput> list_PayrollOutputs = ChatBotController.getCustomerInfo(list_TranscriptInputs);
		ChatBotController.PayrollOutput objPayrollOutput = list_PayrollOutputs[0];
		Test.stopTest();

		System.assertEquals(null, objPayrollOutput.blnIsAccountAvailableAndPayrollRun);
		System.assertEquals(false, objPayrollOutput.blnIsAccountAvailable);
	}
}