@isTest
public class BatchUpdateFirstResponseDateCaseTest {
	@testSetup
	static void setup() {
		List<Case> list_CaseList = new List<Case>();
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setFirstResponseBatchSize(10).build();

		insert objConfigSettings;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('R&D Tax Credits')
			.setOrigin('Email')
			.setSubject('Web case 2')
			.setStatus('New')
			.setSuppliedPhone('1234567890')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('web case created')
			.setFirstResponseTime(system.now().addDays(2))
			.build();
		list_CaseList.add(objCase);

		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('R&D Tax Credits')
			.setOrigin('Email')
			.setSubject('Web case 2')
			.setStatus('New')
			.setSuppliedPhone('1234567890')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('web case created')
			.build();
		list_CaseList.add(objCase1);

		CaseTriggerHelper.skipTrigger = true;
		insert list_CaseList;
		CaseTriggerHelper.skipTrigger = false;
		List<EmailMessage> list_EmailMessageList = new List<EmailMessage>();
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setToAddress('testemail@test.com')
			.setIncoming(false)
			.setStatus('2')
			.setParentId(objCase.Id)
			.build();
		list_EmailMessageList.add(objEmailMessage);

		EmailMessage objEmailMessage1 = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setToAddress('testemail1@test.com')
			.setIncoming(false)
			.setStatus('2')
			.setParentId(objCase1.Id)
			.build();
		list_EmailMessageList.add(objEmailMessage1);
		EmailMessageTriggerHelper.skipTrigger = true;
		insert list_EmailMessageList;
		EmailMessageTriggerHelper.skipTrigger = false;
	}

	/**
	 * @Author      : Deepesh Rao
	 * @Description : Test method for BatchUpdateFirstResponseDateScheduler schedule apex
	 **/
	static testMethod void testBatchScheduler() {
		BatchUpdateFirstResponseDateScheduler objScheduler = new BatchUpdateFirstResponseDateScheduler();
		String strSchedule = '0 0 0 1 * ? *';
		Test.startTest();
		String strJobId = System.schedule('Test first time response schedule', strSchedule, objScheduler);
		Test.stopTest();

		System.assert(strJobId != null);
	}

	@isTest
	static void firstResponseTimeUpdateTest() {
		Test.startTest();
		Database.executeBatch(new BatchUpdateFirstResponseDateCase(), 10);
		Test.stopTest();

		EmailMessage objEmailMessage = [SELECT Id, CreatedDate FROM EmailMessage WHERE toAddress = 'testemail@test.com' LIMIT 1];
		Assert.AreEqual(objEmailMessage.Id != null, true, 'No Email Message Record found');
		Case objCase = [SELECT Id, First_Response_Time__c FROM Case WHERE SuppliedEmail = 'test@gusto.com' LIMIT 1];
		Assert.AreEqual(objCase.Id != null, true, 'No Case Record found');
		Assert.AreEqual(objCase.First_Response_Time__c, objEmailMessage.CreatedDate, 'Error in batch');
	}

	@isTest
	static void firstResponseTimeUpdateIsNullTest() {
		Test.startTest();
		Database.executeBatch(new BatchUpdateFirstResponseDateCase(), 10);
		Test.stopTest();

		EmailMessage objEmailMessage = [SELECT Id, CreatedDate FROM EmailMessage WHERE toAddress = 'testemail1@test.com' LIMIT 1];
		Assert.AreEqual(objEmailMessage.Id != null, true, 'No Email Message Record found');
		Case objCase = [SELECT Id, First_Response_Time__c FROM Case WHERE SuppliedEmail = 'test1@gusto.com' LIMIT 1];
		Assert.AreEqual(objCase.Id != null, true, 'No Case Record found');
		Assert.AreEqual(objCase.First_Response_Time__c, objEmailMessage.CreatedDate, 'Error in batch');
	}
}