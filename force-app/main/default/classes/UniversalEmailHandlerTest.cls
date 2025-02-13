/**
 * @name         UniversalEmailHandlerTest
 * @author       Sanjay Paryani
 * @date         01/28/2020
 * @description  Test class for UniversalEmailHandler
 **/
@isTest
public class UniversalEmailHandlerTest {
	static final String ALGORITHM_NAME = 'HMacSHA1';
	static final Blob BINARY_ATTACHMENT_BLOB = Crypto.generateMac(
		ALGORITHM_NAME,
		Blob.valueOf('test'),
		Blob.valueOf('test_key')
	);

	@testSetup
	static void setupData() {
		List<Account> list_AccountsToInsert = new List<Account>();
		Account objAccount1 = new Account();
		objAccount1.Name = 'C2 Construction Services LLC';
		objAccount1.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objAccount1.ZP_Company_Id__c = '12121212121212';
		list_AccountsToInsert.add(objAccount1);
		insert list_AccountsToInsert;

		List<Case> list_CasesToInsert = new List<Case>();
		Case objCase1 = new Case();
		objCase1.Subject = 'SECURE C2 Construction Services LLC Application Has Been Approved';
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		objCase1.Description = 'Test';
		objCase1.Type = 'Benefits New Plan';
		objCase1.AccountId = list_AccountsToInsert.get(0).Id;
		list_CasesToInsert.add(objCase1);
		insert list_CasesToInsert;

		List<Contact> list_ContactsToInsert = new List<Contact>();
		Contact objContact1 = new Contact();
		objContact1.FirstName = 'User';
		objContact1.LastName = 'Contact Acme';
		objContact1.Email = 'user@acmeonetwothree.com';
		objContact1.AccountId = list_AccountsToInsert.get(0).Id;
		list_ContactsToInsert.add(objContact1);
		insert list_ContactsToInsert;
	}

	static testMethod void testNewInboundEmail_1() {
		Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();

		objEmail.subject = 'Re: SECURE C2 Construction Services LLC Application Has Been Approved';
		objEmail.fromName = 'User Acme';
		objEmail.toAddresses = new List<String>();
		objEmail.toAddresses.add('carrierops@gusto.com');
		objEmail.fromAddress = 'user@acme.com';
		objEmail.replyTo = 'user@acme.com';
		objEmail.plainTextBody = getTextBody();
		objEmail.htmlBody = getHTMLBody();
		Messaging.InboundEmail.BinaryAttachment[] objBinaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>(
			1
		);
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		objBinaryAttachment.Filename = 'test.txt';
		objBinaryAttachment.Body = BINARY_ATTACHMENT_BLOB;
		objBinaryAttachments[0] = objBinaryAttachment;
		objEmail.binaryAttachments = objBinaryAttachments;

		Messaging.InboundEmail.TextAttachment[] objTextAttachments = new List<Messaging.InboundEmail.TextAttachment>(
			1
		);
		Messaging.InboundEmail.TextAttachment objTextAttachment = new Messaging.InboundEmail.TextAttachment();
		objTextAttachment.Filename = 'test.txt';
		objTextAttachment.Body = 'test';
		objTextAttachments[0] = objTextAttachment;
		objEmail.textAttachments = objTextAttachments;

		objEnvelope.fromAddress = 'user@acme.com';

		// setup controller object
		UniversalEmailHandler objUniversalHandler = new UniversalEmailHandler();
		Messaging.InboundEmailResult objInboundEmailResult = objUniversalHandler.handleInboundEmail(
			objEmail,
			objEnvelope
		);
		System.assertEquals(objInboundEmailResult.success, true);
	}

	static testMethod void testNewInboundEmail_2() {
		Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();

		objEmail.subject = 'Your Principal verification code';
		objEmail.fromName = 'User Acme';
		objEmail.toAddresses = new List<String>();
		//objEmail.toAddresses.add('carrierops@gusto.com');
		objEmail.fromAddress = 'user@acme.com';
		objEmail.replyTo = 'user@acme.com';
		objEmail.ccAddresses = new List<String>();
		objEmail.ccAddresses.add('carrierops@zenpayroll.com');
		objEmail.plainTextBody = getTextBody();
		objEmail.htmlBody = getHTMLBody();
		Messaging.InboundEmail.BinaryAttachment[] objBinaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>(
			1
		);
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		objBinaryAttachment.Filename = 'test.txt';
		objBinaryAttachment.Body = BINARY_ATTACHMENT_BLOB;
		objBinaryAttachments[0] = objBinaryAttachment;
		objEmail.binaryAttachments = objBinaryAttachments;

		Messaging.InboundEmail.TextAttachment[] objTextAttachments = new List<Messaging.InboundEmail.TextAttachment>(
			1
		);
		Messaging.InboundEmail.TextAttachment objTextAttachment = new Messaging.InboundEmail.TextAttachment();
		objTextAttachment.Filename = 'test.txt';
		objTextAttachment.Body = 'test';
		objTextAttachments[0] = objTextAttachment;
		objEmail.textAttachments = objTextAttachments;

		objEnvelope.fromAddress = 'user@acme.com';

		// setup controller object
		UniversalEmailHandler objUniversalHandler = new UniversalEmailHandler();
		Messaging.InboundEmailResult objInboundEmailResult = objUniversalHandler.handleInboundEmail(
			objEmail,
			objEnvelope
		);
		System.assertEquals(objInboundEmailResult.success, true);
	}

	static testMethod void testNewInboundEmail_3() {
		Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();

		objEmail.subject = 'Your Principal verification code';
		objEmail.fromName = 'User Acme';
		objEmail.toAddresses = new List<String>();
		objEmail.toAddresses.add('carrierops@gusto.com');
		objEmail.fromAddress = 'user@gusto.com';
		objEmail.replyTo = 'user@gusto.com';
		objEmail.ccAddresses = new List<String>();
		objEmail.ccAddresses.add('carrierops@zenpayroll.com');
		objEmail.plainTextBody = getTextBody();
		objEmail.htmlBody = getHTMLBody();
		Messaging.InboundEmail.BinaryAttachment[] objBinaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>(
			1
		);
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		objBinaryAttachment.Filename = 'test.txt';
		objBinaryAttachment.Body = BINARY_ATTACHMENT_BLOB;
		objBinaryAttachments[0] = objBinaryAttachment;
		objEmail.binaryAttachments = objBinaryAttachments;

		Messaging.InboundEmail.TextAttachment[] objTextAttachments = new List<Messaging.InboundEmail.TextAttachment>(
			1
		);
		Messaging.InboundEmail.TextAttachment objTextAttachment = new Messaging.InboundEmail.TextAttachment();
		objTextAttachment.Filename = 'test.txt';
		objTextAttachment.Body = 'test';
		objTextAttachments[0] = objTextAttachment;
		objEmail.textAttachments = objTextAttachments;

		objEnvelope.fromAddress = 'user@acme.com';

		// setup controller object
		UniversalEmailHandler objUniversalHandler = new UniversalEmailHandler();
		Messaging.InboundEmailResult objInboundEmailResult = objUniversalHandler.handleInboundEmail(
			objEmail,
			objEnvelope
		);
		System.assertEquals(objInboundEmailResult.success, true);
	}

	static testMethod void testNewInboundEmail_4() {
		Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();

		objEmail.subject = 'Your Principal verification code';
		objEmail.fromName = 'User Acme';
		objEmail.toAddresses = new List<String>();
		objEmail.toAddresses.add('carrierops@gusto.com');
		objEmail.fromAddress = 'user@acmeonetwothree.com';
		objEmail.replyTo = 'user@acmeonetwothree.com';
		objEmail.ccAddresses = new List<String>();
		objEmail.ccAddresses.add('carrierops@zenpayroll.com');
		objEmail.plainTextBody = getTextBody();
		objEmail.htmlBody = getHTMLBody();
		Messaging.InboundEmail.BinaryAttachment[] objBinaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>(
			1
		);
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		objBinaryAttachment.Filename = 'test.txt';
		objBinaryAttachment.Body = BINARY_ATTACHMENT_BLOB;
		objBinaryAttachments[0] = objBinaryAttachment;
		objEmail.binaryAttachments = objBinaryAttachments;

		Messaging.InboundEmail.TextAttachment[] objTextAttachments = new List<Messaging.InboundEmail.TextAttachment>(
			1
		);
		Messaging.InboundEmail.TextAttachment objTextAttachment = new Messaging.InboundEmail.TextAttachment();
		objTextAttachment.Filename = 'test.txt';
		objTextAttachment.Body = 'test';
		objTextAttachments[0] = objTextAttachment;
		objEmail.textAttachments = objTextAttachments;

		objEnvelope.fromAddress = 'user@acme.com';

		// setup controller object
		UniversalEmailHandler objUniversalHandler = new UniversalEmailHandler();
		Messaging.InboundEmailResult objInboundEmailResult = objUniversalHandler.handleInboundEmail(
			objEmail,
			objEnvelope
		);
		System.assertEquals(objInboundEmailResult.success, true);
	}

	static testMethod void testNewInboundEmail_5() {
		Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();

		objEmail.subject = 'Important information regarding your group coverage';
		objEmail.fromName = 'User Acme';
		objEmail.toAddresses = new List<String>();
		objEmail.toAddresses.add('carrierops@gusto.com');
		objEmail.fromAddress = 'user@acme.com';
		objEmail.replyTo = 'user@acme.com';
		objEmail.ccAddresses = new List<String>();
		objEmail.ccAddresses.add('carrierops@zenpayroll.com');
		objEmail.plainTextBody = 'Please review the attached document(s) containing information in regards to;Should you have any questions, please contact CaliforniaChoice Customer Service Center by dialing (800) 558-8003.;Thank you.;Hello,;';
		//objEmail.htmlBody = getHTMLBody();
		Messaging.InboundEmail.BinaryAttachment[] objBinaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>(
			1
		);
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		objBinaryAttachment.Filename = 'test.txt';
		objBinaryAttachment.Body = BINARY_ATTACHMENT_BLOB;
		objBinaryAttachments[0] = objBinaryAttachment;
		objEmail.binaryAttachments = objBinaryAttachments;

		Messaging.InboundEmail.TextAttachment[] objTextAttachments = new List<Messaging.InboundEmail.TextAttachment>(
			1
		);
		Messaging.InboundEmail.TextAttachment objTextAttachment = new Messaging.InboundEmail.TextAttachment();
		objTextAttachment.Filename = 'test.txt';
		objTextAttachment.Body = 'test';
		objTextAttachments[0] = objTextAttachment;
		objEmail.textAttachments = objTextAttachments;

		objEnvelope.fromAddress = 'user@acme.com';

		// setup controller object
		UniversalEmailHandler objUniversalHandler = new UniversalEmailHandler();
		Messaging.InboundEmailResult objInboundEmailResult = objUniversalHandler.handleInboundEmail(
			objEmail,
			objEnvelope
		);
		System.assertEquals(objInboundEmailResult.success, true);
	}

	static testMethod void testNewInboundEmailWithBase64Url() {
		Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();

		objEmail.subject = 'Your Kaiser Permanente Small Business coverage has been approved';
		objEmail.fromName = 'User Acme';
		objEmail.toAddresses = new List<String>();
		objEmail.toAddresses.add('carrierops@gusto.com');
		objEmail.fromAddress = 'user@acme.com';
		objEmail.replyTo = 'user@acme.com';
		objEmail.ccAddresses = new List<String>();
		objEmail.ccAddresses.add('carrierops@zenpayroll.com');
		objEmail.plainTextBody = 'Thank you for choosing Kaiser Permanente. Your plan choice(s) and final rates (based on the enrollment applications we received) are attached.';
		objEmail.plainTextBody += 'Please review these materials as they contain important information about paying your premiums, managing your account online, and how you and';
		objEmail.plainTextBody += 'your employees can get the most out of your Kaiser Permanente coverage.Kaiser PermanenteSmall Business';
		objEmail.htmlBody = getHTMLBody() + getBase64UrlImageTag();
		Messaging.InboundEmail.BinaryAttachment[] objBinaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>(
			1
		);
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		objBinaryAttachment.Filename = 'test.txt';
		objBinaryAttachment.Body = BINARY_ATTACHMENT_BLOB;
		objBinaryAttachments[0] = objBinaryAttachment;
		objEmail.binaryAttachments = objBinaryAttachments;

		Messaging.InboundEmail.TextAttachment[] objTextAttachments = new List<Messaging.InboundEmail.TextAttachment>(
			1
		);
		Messaging.InboundEmail.TextAttachment objTextAttachment = new Messaging.InboundEmail.TextAttachment();
		objTextAttachment.Filename = 'test.txt';
		objTextAttachment.Body = 'test';
		objTextAttachments[0] = objTextAttachment;
		objEmail.textAttachments = objTextAttachments;

		objEnvelope.fromAddress = 'user@acme.com';

		// setup controller object
		UniversalEmailHandler objUniversalHandler = new UniversalEmailHandler();
		Messaging.InboundEmailResult objInboundEmailResult = objUniversalHandler.handleInboundEmail(
			objEmail,
			objEnvelope
		);
		System.assertEquals(objInboundEmailResult.success, true);
	}

	private static String getTextBody() {
		String strBody = '';
		strBody += '-----------------------------------------------';
		strBody += '\nsubject : TEST';
		strBody += '\nThis is my test email';
		return strBody;
	}

	private static String getHTMLBody() {
		String strBody = '';
		strBody += '-----------------------------------------------<br/>';
		strBody += '<br/>subject : TEST';
		strBody += '<br/>This is my test email';
		return strBody;
	}

	// get Image tag with Base64URl
	private static String getBase64UrlImageTag() {
		String strBody = '';
		strBody += '<br/><img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAPAAA/+4';
		strBody += 'AJkFkb2JlAGTAAAAAAQMAFQQDBgoNAAABywAAAgsAAAJpAAACyf/bAIQABgQEBAUEBgUFBgkGBQYJCwgGBggLDAoKCwoK';
		strBody += 'DBAMDAwMDAwQDA4PEA8ODBMTFBQTExwbGxscHx8fHx8fHx8fHwEHBwcNDA0YEBAYGhURFRofHx8fHx8fHx8fHx8fHx8fH';
		strBody += 'x8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8f/8IAEQgAEAAQAwERAAIRAQMRAf/EAJQAAQEBAAAAAAAAAAAAAA';
		strBody += 'AAAAMFBwEAAwEAAAAAAAAAAAAAAAAAAAEDAhAAAQUBAQAAAAAAAAAAAAAAAgABAwQFESARAAIBAwIHAAAAAAAAAAAAAAE';
		strBody += 'RAgAhMRIDQWGRocEiIxIBAAAAAAAAAAAAAAAAAAAAIBMBAAMAAQQDAQAAAAAAAAAAAQARITHwQVGBYXGR4f/aAAwDAQAC';
		strBody += 'EQMRAAAB0UlMciEJn//aAAgBAQABBQK5bGtFn6pWi2K12wWTRkjb/9oACAECAAEFAvH/2gAIAQMAAQUCIuIJOqRndRiv/9';
		strBody += 'oACAECAgY/Ah//2gAIAQMCBj8CH//aAAgBAQEGPwLWQzwHepfNbcUNfM4tUIbA9QL4AvnxTlAxacpWJReOlf/aAAgBAQMB';
		strBody += 'PyHZDveuCyu4B4lz2lDKto2ca5uclPK0aoq32x8xgTSLeSgbyzT65n//2gAIAQIDAT8hlQjP/9oACAEDAwE/IaE9GcZF';
		strBody += 'J//aAAwDAQACEQMRAAAQ5F//2gAIAQEDAT8Q1oowKccI3KTdAWkPLw2ssIrwKYUzuJoUJsIHOCoG23ISlja+rU9QvC';
		strBody += 'x//9oACAECAwE/EAuNIiKf/9oACAEDAwE/ECujJzHf7iwHOv5NhK+8efH50z//2Q==" alt="Red dot" />';
		return strBody;
	}
}