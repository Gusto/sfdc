@isTest
public class AttachmentTriggerHandlerTest {
	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Sets common data for all the test methods
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@TestSetup
	static void setupData() {
		TriggerHandler.bypassAll();
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();
		insert objCompAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objCompAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@firstcontact.com')
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('MF QLE')
			.setType('QLE')
			.setSubject('Test  MF QLE  Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test MF QLE Case')
			.build();
		insert objCase;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setToAddress('testemail@test.com').setIncoming(true).build();
		insert objEmailMessage;

		TriggerHandler.clearAllBypasses();
	}

	/**
	 * @description Test insert and update of attachment with exe suffix
	 * @author Sanjay Paryani
	 * @author David Schach
	 */
	@isTest
	public static void renameAttachmentTest() {
		Test.startTest();
		EmailMessage objEmailMessage = [SELECT Id FROM EmailMessage LIMIT 1];
		Attachment objAttachment = new Attachment();
		objAttachment.Name = 'encFile.exe';
		objAttachment.Body = Blob.valueOf('Test encryption piece');
		objAttachment.ParentId = objEmailMessage.id;
		insert objAttachment;

		List<Attachment> list_QueriedExeAttachments = [SELECT Id, Name FROM Attachment WHERE Name = 'encFile.exe'];

		List<Attachment> list_QueriedAttachments = [SELECT Id, Name FROM Attachment WHERE Name LIKE 'encFile%'];

		System.assert(list_QueriedExeAttachments.isEmpty());
		System.assertEquals(list_QueriedAttachments.size(), 1);
		System.assertEquals(list_QueriedAttachments.get(0).Name, 'encFile.txt');

		objAttachment.Name = 'encFile.exe';
		update objAttachment;

		list_QueriedExeAttachments = [SELECT Id, Name FROM Attachment WHERE Name = 'encFile.exe'];
		list_QueriedAttachments = [SELECT Id, Name FROM Attachment WHERE Name LIKE 'encFile%'];
		Test.stopTest();

		System.assert(list_QueriedExeAttachments.isEmpty());
		System.assertEquals(list_QueriedAttachments.size(), 1);
		System.assertEquals(list_QueriedAttachments[0].Name, 'encFile.txt');
	}

	/**
	 * @description create EmailMessage attachment and verify actions
	 * @author David Schach
	 */
	@isTest
	static void createNewAttachmentTest() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case LIMIT 1];

		EmailMessage objMsg = new EmailMessage();
		objMsg.ParentId = objCase.id;
		objMsg.FromAddress = 'test@gusto.com';
		objMsg.ToAddress = 'test.test@gusto.com';
		objMsg.Subject = 'Parent test';
		objMsg.TextBody = 'test';
		insert objMsg;

		EmailMessage msg1 = new EmailMessage();
		msg1.ParentId = objCase.id;
		msg1.FromAddress = 'test@gusto.com';
		msg1.ToAddress = 'test.test@gusto.com';
		msg1.Subject = 'test Attachment';
		msg1.TextBody = 'test Attachment';
		msg1.Old_Parent_Email_Id__c = objMsg.id;
		insert msg1;

		Attachment objAttch = new Attachment();
		objAttch.Name = 'Test Attachment';
		objAttch.Body = Blob.valueOf('Test Image');
		objAttch.ParentId = objMsg.id;
		insert objAttch;

		Test.stopTest();

		objMsg = [SELECT Id, HasAttachment FROM EmailMessage WHERE Subject = 'test Attachment'];
		System.assert(objMsg.HasAttachment != null);
	}
}