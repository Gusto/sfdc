/**
 * @name         : SendAccountQualtricsSurveyBatchTest
 * @author       : Debasmita Rawooth
 * @date         : 01-08-2023
 * @description  : Test Class for SendAccountQualtricsSurveyBatch
 * @test classes : NA
 **/
@isTest
class SendAccountQualtricsSurveyBatchTest {
	@testSetup
	static void testData() {
		List<Account> list_Accounts;
		List<Contact> list_Contacts;

		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setBatchSize(10).build();

		insert objConfigSettings;

		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc1')
			.setZpCompanyId('11111111111111')
			.setTier('Premium')
			.setCurrentTierStartDate(System.Today() - 100)
			.build();

		Account objAccount2 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc2')
			.setZpCompanyId('222222222222')
			.setTier('Premium')
			.setCurrentTierStartDate(System.Today() - 5)
			.build();

		Account objAccount3 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc3')
			.setZpCompanyId('33333333333333')
			.setTier('Premium')
			.setCurrentTierStartDate(System.Today() - 100)
			.setAccountStatus('Suspended Customer')
			.build();

		Account objAccount4 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc4')
			.setZpCompanyId('444444444444')
			.setTier('Simple')
			.setCurrentTierStartDate(System.Today() - 150)
			.build();

		Account objAccount5 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Acc5')
			.setZpCompanyId('555555555555')
			.setTier('Premium')
			.setCurrentTierStartDate(System.Today() - 100)
			.build();

		list_Accounts = new List<Account>{ objAccount1, objAccount2, objAccount3, objAccount4, objAccount5 };
		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(list_Accounts[0].Id)
			.setFirstName('Test New')
			.setLastName('Contact 1')
			.setEmail('testcontactemail1@test.com')
			.setZPUserRole('Primary Payroll Admin')
			.build();

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(list_Accounts[1].Id)
			.setFirstName('Test New')
			.setLastName('Contact 2')
			.setEmail('testcontactemail2@test.com')
			.setZPUserRole('Primary Payroll Admin')
			.build();

		Contact objContact3 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(list_Accounts[2].Id)
			.setFirstName('Test New')
			.setLastName('Contact 3')
			.setEmail('testcontactemail3@test.com')
			.setZPUserRole('Payroll Admin')
			.build();

		Contact objContact4 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(list_Accounts[3].Id)
			.setFirstName('Test New')
			.setLastName('Contact 4')
			.setEmail('testcontactemail4@test.com')
			.setZPUserRole('Primary Payroll Admin')
			.build();

		Contact objContact5 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(list_Accounts[4].Id)
			.setFirstName('Test New')
			.setLastName('Contact 5')
			.setEmail('testcontactemail5@test.com')
			.setZPUserRole('Payroll Admin')
			.build();
    
		list_Contacts = new List<Contact>{ objContact1, objContact2, objContact3, objContact4, objContact5 };
		ContactTriggerHelper.skiptrigger = true;
		insert list_Contacts;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test that emails are being sent to Primary Payroll Admin Contacts related to a Premium Account which has become Premium within last 90 days
	 * @Parm        : void
	 *  @Return     : void
	 **/
	@isTest
	static void testSendEmailToPrimaryPayrollAdminPositive() {
		Test.startTest();
		SendAccountQualtricsSurveyBatch objBatchJob = new SendAccountQualtricsSurveyBatch();
		objBatchJob.execute(null);
		Test.stopTest();

		List<Contact> list_Contacts = [SELECT Id, Email, AccountId FROM Contact WHERE LastName = 'Contact 1'];
		List<EmailMessage> list_EmailMessages = [SELECT Id, Subject, ToAddress, RelatedToId, ActivityId FROM EmailMessage WHERE RelatedToId = :list_Contacts[0].AccountId];
		if (OrganizationUtilities.canSendEmails()) {
			System.assertEquals(1, list_EmailMessages.size(), 'Email was not sent');
			System.assertEquals(list_Contacts[0].AccountId, list_EmailMessages[0].RelatedToId, 'Email was not sent');
			System.assertEquals(list_Contacts[0].Email, list_EmailMessages[0].ToAddress, 'Email was not sent');
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test that emails are not being sent to Primary Payroll Admin Contacts related to a Premium Account which has become Premium prior to last 90 days
	 * @Parm        : void
	 *  @Return     : void
	 **/
	@isTest
	static void testSendEmailToPrimaryPayrollAdminNegative() {
		Test.startTest();
		SendAccountQualtricsSurveyBatch objBatchJob = new SendAccountQualtricsSurveyBatch();
		objBatchJob.execute(null);
		Test.stopTest();

		List<Contact> list_Contacts = [SELECT Id, Email, AccountId FROM Contact WHERE LastName = 'Contact 2'];
		List<EmailMessage> list_EmailMessages = [SELECT Id, Subject, ToAddress, RelatedToId, ActivityId FROM EmailMessage WHERE RelatedToId = :list_Contacts[0].AccountId];
		System.assertEquals(0, list_EmailMessages.size(), 'Email was sent to non-eligible Contact');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test that emails are not being sent to Primary Payroll Admin Contacts related to a Suspended Account
	 * @Parm        : void
	 *  @Return     : void
	 **/
	@isTest
	static void testSendEmailToPrimaryPayrollAdminSuspended() {
		Test.startTest();
		SendAccountQualtricsSurveyBatch objBatchJob = new SendAccountQualtricsSurveyBatch();
		objBatchJob.execute(null);
		Test.stopTest();

		List<Contact> list_Contacts = [SELECT Id, Email, AccountId FROM Contact WHERE LastName = 'Contact 3'];
		List<EmailMessage> list_EmailMessages = [SELECT Id, Subject, ToAddress, RelatedToId, ActivityId FROM EmailMessage WHERE RelatedToId = :list_Contacts[0].AccountId];
		System.assertEquals(0, list_EmailMessages.size(), 'Email was sent to non-eligible Contact');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test that emails are not being sent to Primary Payroll Admin Contacts related to a non-Premium Account
	 * @Parm        : void
	 *  @Return     : void
	 **/
	@isTest
	static void testSendEmailToPrimaryPayrollAdminNonPremium() {
		Test.startTest();
		SendAccountQualtricsSurveyBatch objBatchJob = new SendAccountQualtricsSurveyBatch();
		objBatchJob.execute(null);
		Test.stopTest();

		List<Contact> list_Contacts = [SELECT Id, Email, AccountId FROM Contact WHERE LastName = 'Contact 4'];
		List<EmailMessage> list_EmailMessages = [SELECT Id, Subject, ToAddress, RelatedToId, ActivityId FROM EmailMessage WHERE RelatedToId = :list_Contacts[0].AccountId];
		System.assertEquals(0, list_EmailMessages.size(), 'Email was sent to non-eligible Contact');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test that emails are not being sent to Contacts not having Primary Payroll Admin Role related to a Premium Account
	 * @Parm        : void
	 *  @Return     : void
	 **/
	@isTest
	static void testSendEmailToNonPrimaryPayrollAdmin() {
		Test.startTest();
		SendAccountQualtricsSurveyBatch objBatchJob = new SendAccountQualtricsSurveyBatch();
		objBatchJob.execute(null);
		Test.stopTest();

		List<Contact> list_Contacts = [SELECT Id, Email, AccountId FROM Contact WHERE LastName = 'Contact 5'];
		List<EmailMessage> list_EmailMessages = [SELECT Id, Subject, ToAddress, RelatedToId, ActivityId FROM EmailMessage WHERE RelatedToId = :list_Contacts[0].AccountId];
		System.assertEquals(0, list_EmailMessages.size(), 'Email was sent to non-eligible Contact');
	}
}