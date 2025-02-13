/**
 * @description This is a test class for the ViewArchivedFileController.
 * It contains unit tests to ensure the proper functionality of the controller.
 *
 * The class includes a test setup method that creates necessary test data,
 * including a Case record and related EmailMessage records.
 *
 * The test methods will validate various aspects of the ViewArchivedFileController,
 * ensuring that it behaves as expected under different scenarios.
 *
 * @testSetup The setup method creates a test Case record and related EmailMessage records.
 */
@isTest
public class ViewArchivedFileControllerTest {
	/**
	 * @description Test method to validate the getAttachments method of the ViewArchivedFileController.
	 * This method tests the retrieval of email messages and their associated files for a given record.
	 */
	@testSetup
	static void setup() {
		// Create a test Case record
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Engagement')
			.setType('Sales')
			.setSubject('Test Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@acme.com')
			.setDescription('Test Case')
			.build();
		insert objCase;

		// Create test EmailMessage records related to the Case

		EmailMessage objEmail1 = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setToAddress('recipient1@example.com')
			.setFromAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('Testing Auto Close Date Time Update')
			.setTextBody('Auto Close Date Time Update')
			.build();
		objEmail1.MessageDate = DateTime.now().addDays(-1);
		objEmail1.FromName = 'Sender 1';

		EmailMessage objEmail2 = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setToAddress('recipient1@example.com')
			.setFromAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('Testing Auto Close Date Time Update')
			.setTextBody('Auto Close Date Time Update')
			.build();
		objEmail2.MessageDate = DateTime.now().addDays(-2);
		objEmail2.FromName = 'Sender 2';
		insert new List<EmailMessage>{ objEmail1, objEmail2 };

		// Create test NEILON__File__c records related to the EmailMessages
		NEILON__File__c file1 = new NEILON__File__c(NEILON__Parent_Id__c = objEmail1.Id, Name = 'File 1', NEILON__Size__c = 10240, NEILON__Content_Type__c = 'application/pdf');
		NEILON__File__c file2 = new NEILON__File__c(NEILON__Parent_Id__c = objEmail2.Id, Name = 'File 2', NEILON__Size__c = 20480, NEILON__Content_Type__c = 'image/png');
		insert new List<NEILON__File__c>{ file1, file2 };

		// Create test NEILON__File__c records related to the Case
		NEILON__File__c caseFile = new NEILON__File__c(NEILON__Parent_Id__c = objCase.Id, Name = 'Case File', NEILON__Size__c = 30720, NEILON__Content_Type__c = 'text/plain');
		insert caseFile;
	}

	/**
	 * @description Test method to validate the getAttachments method of the ViewArchivedFileController.
	 * This method tests the retrieval of email messages and their associated files for a given record.
	 */
	@isTest
	static void testGetAttachments() {
		// Get the test Case record
		Case objCase = [SELECT Id FROM Case LIMIT 1];

		Test.startTest();
		// Call the getAttachments method
		ViewArchivedFileController.ResponseWrapper response = ViewArchivedFileController.getAttachments(objCase.Id);
		Test.stopTest();

		// Verify the response
		System.assertNotEquals(null, response, 'Response should not be null');
		System.assertEquals(2, response.list_Emails.size(), 'There should be 2 email messages');
		System.assertEquals(1, response.list_RecordAttachments.size(), 'There should be 1 case attachment');

		// Verify the email messages and their attachments
		for (ViewArchivedFileController.EmailWrapper emailWrapper : response.list_Emails) {
			if (emailWrapper.strFromName == 'Sender 1') {
				System.assertEquals(1, emailWrapper.list_Files.size(), 'Sender 1 should have 1 file');
				System.assertEquals('File 1', emailWrapper.list_Files[0].Name, 'File name should be "File 1"');
			} else if (emailWrapper.strFromName == 'Sender 2') {
				System.assertEquals(1, emailWrapper.list_Files.size(), 'Sender 2 should have 1 file');
				System.assertEquals('File 2', emailWrapper.list_Files[0].Name, 'File name should be "File 2"');
			}
		}

		// Verify the case attachment
		System.assertEquals('Case File', response.list_RecordAttachments[0].Name, 'Case file name should be "Case File"');
	}
}