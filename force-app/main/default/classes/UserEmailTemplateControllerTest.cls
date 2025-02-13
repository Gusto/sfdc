/**
 * @name         : UserEmailTemplateControllerTest
 * @author       : Old Authors & Prity Kumari
 * @date         : 03-15-2023
 * @description  : UserEmailTemplateController Class
 **/
@isTest(SeeAllData=true)
private class UserEmailTemplateControllerTest {
	static UserEmailTemplateController objContrl;
	static void setupTestRun() {
		objContrl = new UserEmailTemplateController();
		System.assertNotEquals(null, objContrl);
		User objLoggedUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(objLoggedUser) {
			EmailTemplate objEmailTemplate = new TestDataFactory.EmailTemplateBuilder()
				.setName('Test Email Template')
				.setDeveloperName('Test_Email_Template')
				.setHtmlValue('Test Stuff')
				.setFolderId(UserInfo.getUserId())
				.setTemplateType('Text')
				.setBody('HELLO')
				.build();
			insert objEmailTemplate;
		}

		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account 123').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setZPCompanyId('123123123123').build();
		insert objAccount;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId('MF Audit')
			.setType('Audit')
			.setSubject('Test Case Owner Change Ben Admin Update Member Ops')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Case Owner Change Ben Admin Update')
			.build();
		insert objCase;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setToAddress('testemail@test.com').setIncoming(true).build();
		insert objEmailMessage;
	}

	/**
	 * @author      Prity Kumari
	 * @description Test Email Template generation functionality
	 **/
	@isTest
	static void getEmailTemplateTest() {
		setupTestRun();
		Test.startTest();
		objContrl.searchEmailName = 'Test Email Template';
		list<Folder> list_Folders = [SELECT Id, Name FROM Folder WHERE Id = :UserInfo.getUserId() LIMIT 1];
		if (!list_Folders.isEmpty()) {
			objContrl.FolderId = list_Folders[0].Id;
			objContrl.getEmailTemplateData();
			objContrl.getFolders();
			System.assertNotEquals(null, objContrl.emailingTemplates);
			System.assertEquals('Test Email Template', objContrl.emailingTemplates[0].Name);
		}
		Test.stopTest();
	}

	/**
	 * @author      Prity Kumari
	 * @description Test Email Logging functionality
	 **/
	@isTest
	static void logEmailTest() {
		setupTestRun();
		Test.startTest();
		List<Case> list_Cases = [SELECT Id FROM Case WHERE SuppliedEmail = 'test1@gusto.com' LIMIT 1];
		list<EmailTemplate> list_EmailTemplates = [SELECT Id, Body, Name FROM EmailTemplate WHERE Name = 'Test Email Template' LIMIT 1];

		if (list_EmailTemplates.size() > 0 && !list_Cases.isEmpty()) {
			String strTemplateId = list_EmailTemplates[0].Id;
			Boolean objResult = UserEmailTemplateController.logEmailAudit(strTemplateId, list_Cases[0].Id);
			System.assertEquals(true, objResult);

			string strEmailSubject = UserEmailTemplateController.getEmailSubject(list_Cases[0].Id);
			string strEmailBody = UserEmailTemplateController.getTemplateBody(strTemplateId);
			System.assertEquals(true, strEmailBody != null);
		}
		Test.stopTest();
	}
}