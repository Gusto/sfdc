/**
 * @description Test class for ArdiusFollowupTaskGenerationBatch
 * @author      Ajay Krishna P U
 * @since       2024-12-23
 */
@isTest
public without sharing class ArdiusFollowupTaskGenerationBatchTest {
	/**
	 * Test Data creation
	 */
	@TestSetup
	static void makeData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Employer Account').setZPCompanyId('1234567890').build();
		insert objAccount;

		Opportunity objTaxCreditsOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setName('Test Oppty for Auto Task Creation')
			.setStage(OpportunityUtil.NEW_STAGE)
			.setCloseDate(Date.newInstance(2024, 12, 9))
			.setAccountId(objAccount.Id)
			.build();
		insert objTaxCreditsOppty;
	}

	/**
	 * Test whether the task is generated if an Ardius opportunity with Company Info complete is True
	 */
	@isTest
	static void testTaskCreation() {
		List<Opportunity> list_Opportunities = [
			SELECT Id, Company_Information_Complete__c, Collecting_Company_Information_End__c
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID
		];
		System.assert(!list_Opportunities.isEmpty(), 'Invalid test data - opportunity');

		Ardius_Configuration__c objConfig = Ardius_Configuration__c.getInstance();
		upsert objConfig;

		String strQuery = 'SELECT Id FROM Opportunity WHERE Id = \'' + list_Opportunities[0].Id + '\'';

		Test.startTest();
		Database.executeBatch(new ArdiusFollowupTaskGenerationBatch(strQuery));
		Test.stopTest();

		List<Task> list_Tasks = [SELECT Id FROM Task WHERE Feature_Request__c != NULL];
		System.assert(!list_Tasks.isEmpty(), 'Followup task did not generated.');
	}

	/**
	 * @description Test whether the task is not created if the status is mentioned in custom settings.
	 */
	@isTest
	static void testTaskCreationWithInvalidStatus2() {
		Test.startTest();
		System.schedule('Test_ArdiusFollowupTaskGenerationBatchTest', '0 0 0 3 9 ? *', new ArdiusFollowupTaskGenerationBatch());
		Test.stopTest();

		List<Task> list_Tasks = [SELECT Id FROM Task WHERE Feature_Request__c != NULL];
		System.assert(list_Tasks.isEmpty(), 'Followup task generated.');
	}
}