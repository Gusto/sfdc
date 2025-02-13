/**
 * @description Test class for TTicketEmailInboundHandler
 * @author      Ajay Krishna P U
 * @since       2023-05-28
 */
@isTest
public with sharing class TicketEmailInboundHandlerTest {
	//Test data identifiers
	static final String TEST_ACCOUNT_NAME = 'Test Account Ref';
	static final String TEST_CONTACT_EMAIL = 'ardius.eto.test.contact@test.com';
	static final String TICKET_REF_1 = 'New';
	static final String DEFAULT_MESSAGE_ID = '<ardius.messageid123@ard.com>';
	static final Messaging.InboundEnvelope ENVELOPE = new Messaging.InboundEnvelope();

	/**
	 * @description Setup Data for testing
	 */
	@TestSetup
	static void makeData() {
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName(TEST_ACCOUNT_NAME).setOwnerId(UserInfo.getUserId()).build();
		insert objAccount;
		AccountTriggerHelper.skipTrigger = false;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail(TEST_CONTACT_EMAIL)
			.setZPUserId('789456123')
			.build();
		insert objContact;

		Ticket__c objTicket1 = new TestDataFactory.TicketBuilder()
			.setStatus(TICKET_REF_1)
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setAccountId(objAccount.Id)
			.build();
		insert objTicket1;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setFromAddress('from@abc.com')
			.setToAddress('to@abc.com')
			.setRelatedToId(objTicket1.Id)
			.setSubject('Test subject')
			.setTextBody('Test body')
			.setMessageIdentifier(DEFAULT_MESSAGE_ID)
			.build();
		insert objEmailMessage;
	}

	/**
	 * @description Test Email Message, Message relation and Attachments are populating as expected
	 */
	@isTest
	static void testEmailMessageCreation() {
		Messaging.InboundEmail.TextAttachment objTextAttachment = new TestDataFactory.TextAttachmentBuilder().setBody('Test').setFileName('abc.vcf').build();
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new TestDataFactory.BinaryAttachmentBuilder().setBody(Blob.valueOf('Test')).setFileName('abc.txt').build();

		Messaging.InboundEmail objInboundEmail = new TestDataFactory.InboundEmailBuilder()
			.setFromAddress('from@abc.com')
			.setFromName('FromAbc')
			.setHtmlBody('<p>Test</p>')
			.setInReplyTo(DEFAULT_MESSAGE_ID)
			.setMessageId('<identifier2@gmail.com>')
			.setPlainTextBody('Test')
			.setReplyTo('from@abc.com')
			.setSubject('Test subject')
			.setCcAddresses(new List<String>{ 'cc@abc.com' })
			.setReferences(new List<String>{ DEFAULT_MESSAGE_ID })
			.setToAddresses(new List<String>{ 'to@abc.com' })
			.setBinaryAttachment(new List<Messaging.InboundEmail.BinaryAttachment>{ objBinaryAttachment })
			.setTextAttachment(new List<Messaging.InboundEmail.TextAttachment>{ objTextAttachment })
			.build();

		Test.startTest();
		Messaging.InboundEmailResult objResult = new TicketEmailInboundHandler().handleInboundEmail(objInboundEmail, ENVELOPE);
		System.assert(null == objResult || objResult.success == true, 'Failed to process');
		Test.stopTest();

		Ticket__c objTicket = getTicket(TICKET_REF_1);
		EmailMessage objEmailMessage = getEmailMessage('Test subject');

		System.assert(objEmailMessage.FromAddress == 'from@abc.com', 'Invalid From address');
		System.assert(objEmailMessage.FromName == 'FromAbc', 'Invalid FromName');
		System.assert(objEmailMessage.HtmlBody == '<p>Test</p>', 'Invalid HtmlBody');
		System.assert(objEmailMessage.TextBody == 'Test', 'Invalid TextBody');
		System.assert(objEmailMessage.Subject == 'Test subject', 'Invalid Subject');

		Map<String, EmailMessageRelation> map_EmailToRelation = getEmailMessageRelation(objEmailMessage.Id);
		System.assert(map_EmailToRelation.containsKey('from@abc.com'), 'From Address not found in relation');
		System.assert(map_EmailToRelation.get('from@abc.com').RelationType == 'FromAddress', 'From Address type not populated');

		System.assert(map_EmailToRelation.containsKey('cc@abc.com'), 'CC Address not found in relation');
		System.assert(map_EmailToRelation.get('cc@abc.com').RelationType == 'CcAddress', 'CC Address type not populated');

		System.assert(map_EmailToRelation.containsKey('to@abc.com'), 'To Address not found in relation');
		System.assert(map_EmailToRelation.get('to@abc.com').RelationType == 'ToAddress', 'To Address type not populated');

		Map<Id, ContentDocumentLink> map_ContentDocumentLinks = getContentDocumentLinks(objEmailMessage.Id);
		System.assert(map_ContentDocumentLinks.keySet().size() == 2, 'Attachments not created as expected');
	}

	/**
	 * @description Check Emails Threading works as expected
	 * The new email have to be linked with same SObject and same EmailMessage
	 */
	@isTest
	static void testEmailThreading() {
		Test.startTest();

		//Parent Email
		Messaging.InboundEmail objInboundEmail1 = new TestDataFactory.InboundEmailBuilder()
			.setFromAddress('from@abc.com')
			.setHtmlBody('<p>Test</p>')
			.setInReplyTo(DEFAULT_MESSAGE_ID)
			.setMessageId('<message1@gmail.com>')
			.setPlainTextBody('Test')
			.setSubject('Test subject1')
			.setToAddresses(new List<String>{ 'to@abc.com' })
			.build();

		Messaging.InboundEmailResult objResult1 = new TicketEmailInboundHandler().handleInboundEmail(objInboundEmail1, ENVELOPE);
		System.assert(null == objResult1 || objResult1.success == true, 'Failed to process');

		Ticket__c objTicket = getTicket(TICKET_REF_1);
		EmailMessage objEmailMessage1 = getEmailMessage('Test subject1');

		System.assert(objEmailMessage1.FromAddress == 'from@abc.com', 'Invalid From address');
		System.assert(objEmailMessage1.Subject == 'Test subject1', 'Invalid Subject');

		//Child Email - In Reply to header
		Messaging.InboundEmail objInboundEmail2 = new TestDataFactory.InboundEmailBuilder()
			.setFromAddress('from@abc.com')
			.setHtmlBody('<p>Test</p>')
			.setMessageId('<message2@gmail.com>')
			.setInReplyTo('<message1@gmail.com>')
			.setPlainTextBody('Test')
			.setSubject('Test subject2')
			.setToAddresses(new List<String>{ 'to@abc.com' })
			.build();

		Messaging.InboundEmailResult objResult2 = new TicketEmailInboundHandler().handleInboundEmail(objInboundEmail2, ENVELOPE);
		System.assert(null == objResult2 || objResult2.success == true, 'Failed to process');

		EmailMessage objEmailMessage2 = getEmailMessage('Test subject2');

		System.assert(objEmailMessage2.ReplyToEmailMessageId == objEmailMessage1.Id, 'Email Messages are not related, Threading failed');
		System.assert(objEmailMessage2.ThreadIdentifier == objEmailMessage1.ThreadIdentifier, 'Email Thread id are not identical, Threading failed');

		//Child Email - Reference header
		Messaging.InboundEmail objInboundEmail3 = new TestDataFactory.InboundEmailBuilder()
			.setFromAddress('from@abc.com')
			.setHtmlBody('<p>Test</p>')
			.setMessageId('<message3@gmail.com>')
			.setPlainTextBody('Test')
			.setSubject('Test subject3')
			.setToAddresses(new List<String>{ 'to@abc.com' })
			.setReferences(new List<String>{ '<message2@gmail.com>' })
			.build();

		Messaging.InboundEmailResult objResult3 = new TicketEmailInboundHandler().handleInboundEmail(objInboundEmail3, ENVELOPE);
		System.assert(null == objResult3 || objResult3.success == true, 'Failed to process');

		EmailMessage objEmailMessage3 = getEmailMessage('Test subject3');

		System.assert(objEmailMessage3.ReplyToEmailMessageId == objEmailMessage2.Id, 'Email Messages are not related - reference relation, Threading failed');
		System.assert(objEmailMessage3.ThreadIdentifier == objEmailMessage2.ThreadIdentifier, 'Email Thread id are not identical - reference relation, Threading failed');
		Test.stopTest();
	}

	/**
	 * @description Test Email Message Relation populated as expected
	 * Email Message address & Any Contact/User found should be linked
	 */
	@isTest
	static void testEmailRelationPopulation() {
		String strUserEmail = UserInfo.getUserEmail();

		Messaging.InboundEmail objInboundEmail = new TestDataFactory.InboundEmailBuilder()
			.setFromAddress(strUserEmail)
			.setHtmlBody('<p>Test</p>')
			.setMessageId('<message1@gmail.com>')
			.setInReplyTo(DEFAULT_MESSAGE_ID)
			.setPlainTextBody('Test')
			.setSubject('Test subject')
			.setToAddresses(new List<String>{ TEST_CONTACT_EMAIL })
			.build();

		Test.startTest();
		Messaging.InboundEmailResult objResult = new TicketEmailInboundHandler().handleInboundEmail(objInboundEmail, ENVELOPE);
		System.assert(null == objResult || objResult.success == true, 'Failed to process');
		Test.stopTest();

		Ticket__c objTicket = getTicket(TICKET_REF_1);
		EmailMessage objEmailMessage = getEmailMessage('Test subject');

		System.assert(objEmailMessage.FromAddress == strUserEmail, 'Invalid From address');
		System.assert(objEmailMessage.Subject == 'Test subject', 'Invalid Subject');

		Map<String, EmailMessageRelation> map_EmailToRelation = getEmailMessageRelation(objEmailMessage.Id);
		System.assert(map_EmailToRelation.containsKey(strUserEmail), 'From Address not found in relation');
		System.assert(map_EmailToRelation.get(strUserEmail).RelationType == 'FromAddress', 'From Address type not populated');
		System.assert(map_EmailToRelation.get(strUserEmail).RelationId != null, 'From Address Recipient not populated');

		System.assert(map_EmailToRelation.containsKey(TEST_CONTACT_EMAIL), 'To Address not found in relation');
		System.assert(map_EmailToRelation.get(TEST_CONTACT_EMAIL).RelationType == 'ToAddress', 'From Address type not populated');
		System.assert(map_EmailToRelation.get(TEST_CONTACT_EMAIL).RelationId != null, 'To Address Recipient not populated');
	}

	/**
	 * @description Test Very Long body Inbound email
	 * The functionality should Truncate the body to the limit and create an attachment with complete content of the email.
	 */
	@isTest
	static void testEmailWithTooLongBody() {
		String strTooLongBody = 'TestBody'.rightPad(TicketEmailInboundHandler.BODY_MAX_LIMIT + 1, 'z');
		Messaging.InboundEmail objInboundEmail = new TestDataFactory.InboundEmailBuilder()
			.setFromAddress('from@abc.com')
			.setHtmlBody(strTooLongBody)
			.setMessageId('<message1@gmail.com>')
			.setInReplyTo(DEFAULT_MESSAGE_ID)
			.setPlainTextBody('Test')
			.setSubject('Test subject')
			.setToAddresses(new List<String>{ 'to@abc.com' })
			.build();

		Test.startTest();
		Messaging.InboundEmailResult objResult = new TicketEmailInboundHandler().handleInboundEmail(objInboundEmail, ENVELOPE);
		System.assert(null == objResult || objResult.success == true, 'Failed to process');
		Test.stopTest();

		Ticket__c objTicket = getTicket(TICKET_REF_1);
		EmailMessage objEmailMessage = getEmailMessage('Test subject');

		System.assert(objEmailMessage.FromAddress == 'from@abc.com', 'Invalid From address');
		System.assert(objEmailMessage.Subject == 'Test subject', 'Invalid Subject');
		System.assert(objEmailMessage.HtmlBody.contains(TicketEmailInboundHandler.TRUNCATED_IDENTIFIER), 'Html Body not truncated properly');
	}

	/**
	 * @description To Test for Un identified Email With Create Case option enabled
	 */
	@isTest
	static void testUnIdentifiedEmailCaseCreation() {
		Messaging.InboundEmail objInboundEmail = new TestDataFactory.InboundEmailBuilder()
			.setFromAddress(TEST_CONTACT_EMAIL)
			.setFromName('FromAbc')
			.setHtmlBody('<p>Test</p>')
			.setMessageId('<identifier1@gmail.com>')
			.setPlainTextBody('Test')
			.setReplyTo(TEST_CONTACT_EMAIL)
			.setSubject('Test subject')
			.setCcAddresses(new List<String>{ 'cc@abc.com' })
			.setToAddresses(new List<String>{ 'to@abc.com' })
			.build();

		Test.startTest();
		Messaging.InboundEmailResult objResult = new TicketEmailInboundHandler().handleInboundEmail(objInboundEmail, ENVELOPE);
		System.assert(null == objResult || objResult.success == true, 'Failed to process');
		Test.stopTest();

		Case objCase = getCase(TEST_CONTACT_EMAIL);
		EmailMessage objEmailMessage = getEmailMessage('Test subject');

		System.assert(objEmailMessage.FromAddress == TEST_CONTACT_EMAIL, 'Invalid From address');
		System.assert(objEmailMessage.FromName == 'FromAbc', 'Invalid FromName');
		System.assert(objEmailMessage.HtmlBody == '<p>Test</p>', 'Invalid HtmlBody');

		System.assert(objCase.Subject == 'Test subject', 'Invalid Case subject');
		System.assert(objCase.Description == 'Test', 'Invalid Case Description');
		System.assert(objCase.SuppliedEmail == TEST_CONTACT_EMAIL, 'Invalid Case Supplied Email');
		System.assert(objCase.ContactId != null, 'Invalid Contact linked');
		System.assert(objCase.AccountId != null, 'Invalid Account linked');
	}

	/**
	 * @description To Test Ticket Communication status on inbound and outbound email
	 */
	@isTest
	static void testCommunicationStatusUpdate() {
		Ticket__c objTicket = getTicket(TICKET_REF_1);

		//1. Check Inbound Email
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setFromAddress('from@abc.com')
			.setToAddress('to@abc.com')
			.setRelatedToId(objTicket.Id)
			.setSubject('Test subject')
			.setTextBody('Test body')
			.build();
		objEmailMessage.ThreadIdentifier = '<testinbound.ardius@g.ardius.com.gusto>';
		objEmailMessage.MessageIdentifier = '<testinbound.ardius@g.ardius.com.gusto>';
		insert objEmailMessage;

		objTicket = getTicket(TICKET_REF_1);
		System.assert(objTicket.Communication_Status__c == TicketUtil.COMM_STATUS_AWAITING_RESPONSE, 'Invalid Communication Status - inbound email');

		//Make Unresponsive
		objTicket.Unresponsive__c = true;
		update objTicket;

		//Check Outbound Email
		Messaging.InboundEmail objInboundEmail = new TestDataFactory.InboundEmailBuilder()
			.setFromAddress(TEST_CONTACT_EMAIL)
			.setFromName('FromAbc')
			.setHtmlBody('<p>Test</p>')
			.setMessageId('<identifier1@gmail.com>')
			.setInReplyTo('<testinbound.ardius@g.ardius.com.gusto>')
			.setPlainTextBody('Test')
			.setReplyTo(TEST_CONTACT_EMAIL)
			.setSubject('Test subject')
			.setCcAddresses(new List<String>{ 'cc@abc.com' })
			.setToAddresses(new List<String>{ 'to@abc.com' })
			.build();

		Test.startTest();
		Messaging.InboundEmailResult objResult = new TicketEmailInboundHandler().handleInboundEmail(objInboundEmail, ENVELOPE);
		System.assert(null == objResult || objResult.success == true, 'Failed to process');
		Test.stopTest();

		objTicket = getTicket(TICKET_REF_1);
		System.assert(objTicket.Communication_Status__c == TicketUtil.COMM_STATUS_RESPONSE_RECEIVED, 'Invalid Communication Status - outbound email');
		System.assert(!objTicket.Unresponsive__c, 'Invalid Unresponsive flag - outbound email');
	}

	/**
	 * @description         Utility - Get Ticket by identifier
	 * @param strIdentifier Identifier
	 * @return              `Ticket__c`
	 */
	static Ticket__c getTicket(String strIdentifier) {
		List<Ticket__c> list_Tickets = [SELECT Id, Communication_Status__c, Unresponsive__c FROM Ticket__c WHERE Status__c = :strIdentifier];
		System.assert(!list_Tickets.isEmpty(), 'Tickets Not found');

		return list_Tickets[0];
	}

	/**
	 * @description         Utility - Get Case by identifier
	 * @param strIdentifier Identifier
	 * @return              `Case`
	 */
	static Case getCase(String strIdentifier) {
		List<Case> list_Cases = [SELECT Id, Subject, Description, SuppliedEmail, ContactId, AccountId FROM Case WHERE SuppliedEmail = :strIdentifier];
		System.assert(!list_Cases.isEmpty(), 'Case Not found');

		return list_Cases[0];
	}

	/**
	 * @description       Get EmailMessage Object from Related to Object
	 * @param idRelatedTo Related to Id
	 * @return            `EmailMessage`
	 */
	static EmailMessage getEmailMessage(String strSubject) {
		List<EmailMessage> list_EmailMessage = [
			SELECT
				Id,
				CcAddress,
				CcIds,
				ClientThreadIdentifier,
				FromAddress,
				FromName,
				HtmlBody,
				Incoming,
				MessageIdentifier,
				Name,
				RelatedToId,
				ReplyToEmailMessageId,
				Status,
				Subject,
				TextBody,
				ThreadIdentifier,
				ToAddress,
				ToIds
			FROM EmailMessage
			WHERE Subject = :strSubject
			ORDER BY CreatedDate DESC
		];

		System.assert(!list_EmailMessage.isEmpty(), 'Email messages Not found');

		return list_EmailMessage[0];
	}

	/**
	 * @description          Get Email Message Relations
	 * @param idEmailMessage Email Message Id
	 * @return               `Map<String, EmailMessageRelation>`
	 */
	static Map<String, EmailMessageRelation> getEmailMessageRelation(Id idEmailMessage) {
		Map<String, EmailMessageRelation> map_EmailToRelation = new Map<String, EmailMessageRelation>();

		for (EmailMessageRelation objRelation : [SELECT Id, EmailMessageId, RelationAddress, RelationType, RelationId FROM EmailMessageRelation WHERE EmailMessageId = :idEmailMessage]) {
			map_EmailToRelation.put(objRelation.RelationAddress, objRelation);
		}

		System.assert(!map_EmailToRelation.isEmpty(), 'No Email Message Relation found');
		return map_EmailToRelation;
	}

	/**
	 * @description          Get related Content document Links and information
	 * @param idEmailMessage Email Message Id
	 * @return               `Map<Id, ContentDocumentLink>`
	 */
	static Map<Id, ContentDocumentLink> getContentDocumentLinks(Id idEmailMessage) {
		return new Map<Id, ContentDocumentLink>([SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersion.PathOnClient FROM ContentDocumentLink WHERE LinkedEntityId = :idEmailMessage]);
	}
}