/**
 * @name         : S3FileArchivalBatchTest
 * @author       : David (Dato) Tsamalashvili
 * @date         : 06/28/2022
 * @description  : Test class for S3FileArchivalBatch
 **/
@isTest
public class S3FileArchivalBatchTest {
	@testSetup
	static void createTestData() {
		//create Payroll Audit
		Payroll_Audit__c objPayrollAudit = new TestDataFactory.PayrollAuditBuilder().setRecordTypeId('Enrollment').setCompanyId('214321431243').build();

		PayrollAuditTriggerHelper.skipTrigger = true;
		insert objPayrollAudit;

		//create Content Version
		ContentVersion objContVersion = new ContentVersion(Title = 'test', PathOnClient = 'test.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);

		insert objContVersion;

		//create Content Document Link
		ContentDocumentLink objContDocLink = new ContentDocumentLink();
		objContDocLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :objContVersion.Id LIMIT 1].ContentDocumentId;
		objContDocLink.LinkedEntityId = objPayrollAudit.Id;
		objContDocLink.shareType = 'V';

		insert objContDocLink;

		//create account
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account 123').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setZPCompanyId('123123123123').build();
		AccountTriggerHelper.skipTrigger = true;
		insert objAccount;

		//create attachment
		List<Attachment> list_Attachments = new List<Attachment>();
		Attachment objAtt_1 = new TestDataFactory.AttachmentBuilder().setName('Test1.pdf').setBody(Blob.valueOf('Test')).setParent(objAccount.Id).build();
		list_Attachments.add(objAtt_1);

		Attachment objAtt_2 = new TestDataFactory.AttachmentBuilder().setName('Test2.pdf').setBody(Blob.valueOf('Test')).setParent(objAccount.Id).build();
		list_Attachments.add(objAtt_2);

		Attachment objAtt_3 = new TestDataFactory.AttachmentBuilder().setName('Test3.pdf').setBody(Blob.valueOf('Test')).setParent(objAccount.Id).build();
		list_Attachments.add(objAtt_3);

		insert list_Attachments;

		//create configuration
		List<Archival_Job_Configuration__c> list_ArchivalConfigs = new List<Archival_Job_Configuration__c>();

		Archival_Job_Configuration__c objAJC_1 = new TestDataFactory.ArchivalJobConfigBuilder()
			.setArchivalType('ContentDocumentLink')
			.setQuery('SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Payroll_Audit__c)')
			.setType('File')
			.setActive(true)
			.setLastRunSize(120)
			.setPriority(1)
			.setCompletedAt(System.now())
			.build();

		list_ArchivalConfigs.add(objAJC_1);

		Archival_Job_Configuration__c objAJC_2 = new TestDataFactory.ArchivalJobConfigBuilder()
			.setArchivalType('Attachment')
			.setQuery('SELECT Id FROM Attachment ORDER BY CreatedDate DESC LIMIT 1')
			.setType('File')
			.setActive(true)
			.setLastRunSize(120)
			.setPriority(1)
			.setCompletedAt(System.now())
			.build();

		list_ArchivalConfigs.add(objAJC_2);

		insert list_ArchivalConfigs;
	}

	@isTest
	static void testContentBatchAuto() {
		Test.startTest();
		S3FileArchivalBatch objArchiveFilesJob = new S3FileArchivalBatch('', 'ContentDocumentLink', false);

		Database.executeBatch(objArchiveFilesJob);
		Test.stopTest();
	}

	@isTest
	static void testAttachmentBatchAuto() {
		Test.startTest();
		S3FileArchivalBatch objArchiveFilesJob = new S3FileArchivalBatch('', 'Attachment', false);

		Database.executeBatch(objArchiveFilesJob);
		Test.stopTest();
	}

	@isTest
	static void testAttachmentBatchManual() {
		Test.startTest();
		String strQuery = 'SELECT Id FROM Attachment ORDER BY CreatedDate DESC LIMIT 1';
		S3FileArchivalBatch objArchiveFilesJob = new S3FileArchivalBatch(strQuery, 'Attachment', true);

		Database.executeBatch(objArchiveFilesJob);
		Test.stopTest();
	}

	@isTest
	static void testScheduleder() {
		Test.startTest();
		// Dynamically scheduling jobs for next year
		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;

		S3FileArchivalBatchScheduler objScheduler = new S3FileArchivalBatchScheduler();
		String strJobId = System.schedule('Test S3 File Archival Scheduler', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();
	}
}