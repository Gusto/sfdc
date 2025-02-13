/**
 * New test class to check if automations are triggered based on Tethr Events
 */
@isTest
public without sharing class TethrEventTriggerHelperTest {
	@testSetup
	static void setup() {
		AccountTriggerHelper.skipTrigger = true;
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.setTier('simple')
			.setSetUpSteps(20.0)
			.setBillingState('California')
			.setBillingCountry('United States')
			.build();
		insert objCompanyAccount;

		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
			.setWhatId(objCompanyAccount.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setType(TaskUtil.TASK_TYPE_CALL)
			.setDescription('Test Description')
			.setCallObject('5ace9134-c55b-45fe-8843-450b1ded0b70')
			.build();
		objTask.Genesys_Interaction_Id__c = 'interactionid';
		insert objTask;

		// Insert a valid benefits supporting state
		insert new TestDataFactory.StateNametoAbbreviationsMappingBuilder().setName('California').setStateAbbreviation('California').setStateName('CA').setHIActive(true).build();
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if BoR opportunity is created if Account has no benefits opportunity and has a valid Billing state
	 **/
	@isTest
	static void testProcessAfterInsert() {
		// Get the test Account
		Account objAcc = [SELECT Id FROM Account LIMIT 1];

		// Insert Test Tethr Call
		Tethr__Tethr_Call__c objCall = new Tethr__Tethr_Call__c(
			Tethr__Master_Id__c = 'interactionid',
			Tethr__Call_URI__c = 'test',
			Tethr__DurationOfCall__c = 10,
			Tethr__UniqueTethrId__c = 'interactionid'
		);
		insert objCall;

		// Insert Tethr Event that should kick off Benefits Opportunity creation
		insert new Tethr__Tethr_Event__c(Name = TethrEventTriggerHelper.PARTNER_BOR_OPP_EVT, Tethr__Call__c = objCall.Id);

		// Verify that the Opportunities were created
		List<Opportunity> list_Opps = [SELECT Id, AccountId, LeadSource, RecordTypeId FROM Opportunity WHERE AccountId = :objAcc.Id];
		System.assertEquals(1, list_Opps.size(), 'There should be 1 Opportunity created');
		System.assertEquals(TethrEventTriggerHelper.LEAD_SOURCE_TEHR, list_Opps[0].LeadSource, 'Lead Source should be Tethr');
		System.assertEquals(TethrEventTriggerHelper.BENEFITS_BOR_OPPTY_RT_ID, list_Opps[0].RecordTypeId, 'Record Type should be Benefits BoR');

		// Verify if Account Id and Opportunity Id are linked to Tethr Call
		Tethr__Tethr_Call__c objCallAssert = [SELECT Id, Tethr__Account__c, Tethr__Opportunity__c FROM Tethr__Tethr_Call__c WHERE Id = :objCall.Id];
		System.assertEquals(objAcc.Id, objCallAssert.Tethr__Account__c, 'Account not linked to tehr call');
		System.assertEquals(list_Opps[0].Id, objCallAssert.Tethr__Opportunity__c, 'Opportunity not linked to tehr call');
	}
}