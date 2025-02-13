/**
 * @name             TaxResAnalyticsBatchTest
 * @author           Pravesh Rana
 * @date             08/17/2021
 * @description      Process Case records in batches, for tracking metrics for Tax Res Case Analytics
 * @Covered class    TaxResAnalyticsBatch and TaxResTimeTrackingUtil
 * @revisions        Date ------------ Name ------------ Comments
 **/
@isTest
public class TaxResAnalyticsBatchTest {
	static String TIME_TRACKING_TAX_RES = Cache.getRecordTypeId('Analytics_Time_Tracker__c', 'Tax Resolution');

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void setUpSampleData() {
		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();
		Role__c objRole = TestDataFactory.CreateRole('Account Specialist');
		Region_POD__c objRegionPOD = TestDataFactory.CreateAgencyRegion('Test Notice Region', 'Notice Analyst');

		List<Region_POD_mapping__c> list_RegionPODMappings = TestDataFactory.CreateAgencyRegionPODMapping(objRegionPOD, list_AgencyInformations);

		List<Skill__c> list_Skills = TestDataFactory.CreateSkill(objRole, list_RegionPODMappings);
		User_Role__c objUserAccountSpecialistRole = TestDataFactory.CreateUserRole('Account Specialist');
		List<User_Skill__c> list_UserSkills = TestDataFactory.CreateUserSkill(objUserAccountSpecialistRole, list_Skills);
		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);

		Case objCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		objCase.Status = 'Data Capture in Progress';
		objCase.Agency_Information__c = list_AgencyInformations[0].Id;
		CaseTriggerHelper.skipTrigger = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		List<Case_Audit_Log__c> list_CaseAuditLogs = new List<Case_Audit_Log__c>();

		DateTime dtmFromTime = System.now().addHours(-1);
		DateTime dtmToTime = System.now().addHours(1);
		list_CaseAuditLogs.add(
			new TestDataFactory.TaxResCaseAuditLogBuilder()
				.setCaseId(objCase.Id)
				.setEventType('Status Change')
				.setFromStatus('Ready for Research')
				.setToStatus('Research in progress')
				.setFromDateTime(dtmFromTime)
				.setToDateTime(dtmToTime)
				.setCurrentRole(CaseUtils.TAXRES_ACCOUNT_SPECIALIST)
				.build()
		);

		dtmFromTime = dtmToTime.addHours(1);
		dtmToTime = dtmFromTime.addHours(1);
		list_CaseAuditLogs.add(
			new TestDataFactory.TaxResCaseAuditLogBuilder()
				.setCaseId(objCase.Id)
				.setEventType('Status Change')
				.setFromStatus('Research in progress')
				.setToStatus('Waiting for Coordinator')
				.setFromDateTime(dtmFromTime)
				.setToDateTime(dtmToTime)
				.setCurrentRole(CaseUtils.TAXRES_ACCOUNT_SPECIALIST)
				.build()
		);

		insert list_CaseAuditLogs;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Checks of the code is creating "Analytics_Time_Tracker__c" object records properly
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void checkAnalyticsRecordCreationPositive() {
		Test.startTest();
		TaxResAnalyticsBatch objBatch = new TaxResAnalyticsBatch();
		Database.executeBatch(objBatch, 1);
		Test.stopTest();

		List<Analytics_Time_Tracker__c> list_AnalyticRecords = [SELECT Id FROM Analytics_Time_Tracker__c];
		System.assert(list_AnalyticRecords.size() > 0, 'Analytics Time Tracker records are missing.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Checks the scenario of not able to create "Analytics_Time_Tracker__c" recordss
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void checkAnalyticsRecordCreationNegative() {
		List<Case_Audit_Log__c> list_CaseAudits = [SELECT Id FROM Case_Audit_Log__c];
		delete list_CaseAudits;

		List<Analytics_Time_Tracker__c> list_AnalyticRecords = [SELECT Id FROM Analytics_Time_Tracker__c];
		if (list_AnalyticRecords.size() > 0) {
			delete list_AnalyticRecords;
		}

		Test.startTest();
		TaxResAnalyticsBatch objBatch = new TaxResAnalyticsBatch();
		Database.executeBatch(objBatch, 1);
		Test.stopTest();

		list_AnalyticRecords = [SELECT Id FROM Analytics_Time_Tracker__c];
		System.assert(list_AnalyticRecords.size() == 0, 'Able to find time tracker records');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Checks the scheduleable functionality of the batch class
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void checkSchedulableFunctionality() {
		Test.startTest();
		TaxResAnalyticsBatch objBatch = new TaxResAnalyticsBatch();
		String CRON_EXP = '0 0 23 * * ?';
		String jobId = system.schedule('TaxRes Analytics Check', CRON_EXP, objBatch);
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(CRON_EXP, ct.CronExpression, 'job not scheduled');
		System.assertEquals(0, ct.TimesTriggered, 'should only be triggered once.');
		Test.stopTest();
	}
}