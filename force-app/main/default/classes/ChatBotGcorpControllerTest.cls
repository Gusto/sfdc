/**
 * @description       : Unit tests for ChatBotGcorpController
 **/
@isTest
public class ChatBotGcorpControllerTest {
	@TestSetup
	public static void testSetup() {
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setTier('Simple').setRecordTypeId('Company').build();
		insert objAccount;

		Account objAccount1 = new TestDataFactory.AccountBuilder().setName('Test Account With Joined Date').setTier('Simple').setJoinedDate(System.today()).setRecordTypeId('Company').build();
		insert objAccount1;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setAccountId(objAccount.Id)
			.setFirstName('contactFirst')
			.setLastName('contactLast')
			.setPhone('0000000000')
			.setEmail('test1@test.com')
			.setRecordTypeId('Company')
			.build();
		insert objContact;

		Contact objContactTwo = new TestDataFactory.ContactBuilder()
			.setAccountId(objAccount1.Id)
			.setFirstName('contactFirst')
			.setLastName('contactLast')
			.setPhone('0000000000')
			.setEmail('test2@test.com')
			.setRecordTypeId('Company')
			.build();
		insert objContactTwo;

		Contact objContactWithoutAccount = new TestDataFactory.ContactBuilder()
			.setFirstName('contactFirst')
			.setLastName('contactLast')
			.setPhone('0000000000')
			.setEmail('test3@test.com')
			.setRecordTypeId('Company')
			.build();
		insert objContactWithoutAccount;
	}

	/**
	 * @description Get customer Info without Joined Date
	 **/
	@isTest
	public static void getCustomerInfoWithoutJoinedDatePandaTest() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript
		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('test1@test.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objLiveChatVisitor.Id)
			.build();

		insert objLiveChatTranscript;

		//Given existing contact and account information when visitor with email address is found
		Test.startTest();
		List<ChatBotGcorpController.Input> list_TranscriptInputs = new List<ChatBotGcorpController.Input>();
		ChatBotGcorpController.Input objTranscriptInput = new ChatBotGcorpController.Input();
		objTranscriptInput.routableID = objLiveChatTranscript.Id;
		objTranscriptInput.visitorEmail = 'test1@test.com';
		list_TranscriptInputs.add(objTranscriptInput);
		List<ChatBotGcorpController.Output> list_BotOutputs = ChatBotGcorpController.getCustomerInfo(list_TranscriptInputs);
		ChatBotGcorpController.Output objBotOutput = list_BotOutputs[0];
		Test.stopTest();

		//Assert that the account and contact information is returned
		System.assertEquals(false, objBotOutput.blnIsAccountAvailableAndPayrollRun, 'Account have not run payroll');
		System.assertEquals(true, objBotOutput.blnIsAccountAvailable, 'Account available');
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test1@test.com'];
		System.assertEquals(objContact.Id, objBotOutput.objContact.Id, 'Contact not returned');
		System.assertEquals(objAccount.Id, objBotOutput.idAccount, 'Account not returned');
	}

	/**
	 * @description Get customer Info with Joined Date
	 **/
	@isTest
	public static void getCustomerInfoWithJoinedDatePandaTest() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Account With Joined Date'];
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record
		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('test2@test.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objLiveChatVisitor.Id)
			.build();

		insert objLiveChatTranscript;

		//Given existing contact and account information when visitor with email address is found
		Test.startTest();
		List<ChatBotGcorpController.Input> list_TranscriptInputs = new List<ChatBotGcorpController.Input>();
		ChatBotGcorpController.Input objTranscriptInput = new ChatBotGcorpController.Input();
		objTranscriptInput.routableID = objLiveChatTranscript.Id;
		objTranscriptInput.visitorEmail = 'test2@test.com';
		list_TranscriptInputs.add(objTranscriptInput);
		List<ChatBotGcorpController.Output> list_BotOutputs = ChatBotGcorpController.getCustomerInfo(list_TranscriptInputs);
		ChatBotGcorpController.Output objBotOutput = list_BotOutputs[0];
		Test.stopTest();

		//Assert that the account and contact information is returned
		System.assertEquals(true, objBotOutput.blnIsAccountAvailableAndPayrollRun, 'Account have run payroll');
		System.assertEquals(false, objBotOutput.blnIsAccountAvailable, 'Account not available');
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test2@test.com'];
		System.assertEquals(objContact.Id, objBotOutput.objContact.Id, 'Contact not returned');
		System.assertEquals(objAccount.Id, objBotOutput.idAccount, 'Account not returned');
	}

	/**
	 * @description Get customer Info without Account
	 **/
	@isTest
	public static void getCustomerInfoWithoutAccountTest() {
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record and link to the Case
		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('test3@test.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objLiveChatVisitor.Id)
			.build();

		insert objLiveChatTranscript;

		//Given existing contact and account information when visitor with email address is found
		Test.startTest();
		List<ChatBotGcorpController.Input> list_TranscriptInputs = new List<ChatBotGcorpController.Input>();
		ChatBotGcorpController.Input objTranscriptInput = new ChatBotGcorpController.Input();
		objTranscriptInput.routableID = objLiveChatTranscript.Id;
		objTranscriptInput.visitorEmail = 'test3@test.com';
		list_TranscriptInputs.add(objTranscriptInput);
		List<ChatBotGcorpController.Output> list_BotOutputs = ChatBotGcorpController.getCustomerInfo(list_TranscriptInputs);
		ChatBotGcorpController.Output objBotOutput = list_BotOutputs[0];
		Test.stopTest();

		//Assert that the account and contact information is returned
		System.assertEquals(null, objBotOutput.blnIsAccountAvailableAndPayrollRun, 'No account');
		System.assertEquals(false, objBotOutput.blnIsAccountAvailable, 'Account not available');
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test3@test.com'];
		System.assertEquals(objContact.Id, objBotOutput.objContact.Id, 'Contact not returned');
		System.assertEquals(true, String.isBlank(objBotOutput.idAccount), 'Account not blank');
	}

	/**
	 * @description Check customer Info when no contact exists
	 **/
	@isTest
	public static void getCustomerInfoWithoutContactTest() {
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record and link to the Case
		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('test3@test.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objLiveChatVisitor.Id)
			.build();

		insert objLiveChatTranscript;

		//Given existing contact and account information when visitor with email address is not found
		Test.startTest();
		List<ChatBotGcorpController.Input> list_TranscriptInputs = new List<ChatBotGcorpController.Input>();
		ChatBotGcorpController.Input objTranscriptInput = new ChatBotGcorpController.Input();
		objTranscriptInput.routableID = objLiveChatTranscript.Id;
		objTranscriptInput.visitorEmail = 'test4@test.com';
		list_TranscriptInputs.add(objTranscriptInput);
		List<ChatBotGcorpController.Output> list_BotOutputs = ChatBotGcorpController.getCustomerInfo(list_TranscriptInputs);
		ChatBotGcorpController.Output objBotOutput = list_BotOutputs[0];
		Test.stopTest();

		//Assert that the information is not returned
		System.assertEquals(false, objBotOutput.blnIsAccountAvailableAndPayrollRun, 'No account should exist');
		System.assertEquals(false, objBotOutput.blnIsAccountAvailable, 'Account should not be available');
		System.assertEquals(null, objBotOutput.objContact, 'Contact should not exist');
		System.assertEquals(true, String.isBlank(objBotOutput.idAccount), 'Account should be blank');
	}
}