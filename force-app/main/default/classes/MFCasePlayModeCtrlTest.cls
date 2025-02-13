/**
 * @description  Used for testing the Case Play Mode
 * @author       Bhagat Singh
 * @date         11/18/2024
 * @see          MFCasePlayModeCtrl
 **/
@isTest
public class MFCasePlayModeCtrlTest {
	@testSetup
	static void setup() {
		Utils.skipTrigger(true);
		list<Play_Mode_Config__c> list_Config = new List<Play_Mode_Config__c>();

		Play_Mode_Config__c objConfig = new Play_Mode_Config__c();
		objConfig.Name = 'NHE';
		objConfig.Case_record_Type__c = 'MF NHE';
		objConfig.Case_Type__c = 'NHE';
		objConfig.Owner_Queue__c = 'Member Fulfillment';
		objConfig.Play_Mode_Class__c = 'Select Number of Cases Play Mode';
		objConfig.Sorted_by_Field__c = 'Anticipated_Effective_Date__c';
		objConfig.Status_Exceptions__c = 'Draft';
		list_Config.add(objConfig);
		insert objConfig;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Guardian').setUniqueName('Guardian').setState('CA').build();
		insert objCarrier;
		Account objAccRecord = new TestDataFactory.AccountBuilder()
			.setName('Test Demo AccountName 1')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setBillingStreet('Testing Avenue 1')
			.setBillingPostalCode('123456')
			.setPhone('19992344444')
			.setCompanyTradeName('Company trade name 1')
			.setShippingStreet('Testing Avenue 1')
			.setShippingPostalCode('123455')
			.build();
		insert objAccRecord;

		Opportunity objOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('OppRecord')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(Date.today().addDays(60))
			.setAccountId(objAccRecord.Id)
			.build();
		insert objOppNewPlan;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('MF NHE')
			.setAccountId(objAccRecord.Id)
			.setOpportunity(objOppNewPlan.Id)
			.setIdCarrier(objCarrier.Id)
			.setSubject('Test Relation')
			.setDescription('Test Relation')
			.setSuppliedEmail('TickettriggerHelper@gusto.com')
			.setType(CaseUtils.TYPE_NHE)
			.setAnticipatedEffectiveDate(Date.today().addDays(30))
			.setStatus('New')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.build();
		insert objCase;

		Set<String> set_QueueNames = new Set<String>{ 'Member Fulfillment' };
		Map<String, Id> map_QueueNameToId = GlobalQueryHelper.getNameQueueMap(set_QueueNames);
		Case objUpdateCase = new Case(Id = objCase.Id);
		objUpdateCase.OwnerId = map_QueueNameToId.get('Member Fulfillment');
		update objUpdateCase;

		Utils.skipTrigger(false);
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method validate MF Case Play Mode Class.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testMFCasePlayMode() {
		Test.startTest();
		MFCasePlayModeCtrl.getUserInformation();
		MFCasePlayModeCtrl.getCaseDetails(CaseUtils.TYPE_NHE, MFCasePlayModeCtrl.STR_NONE);
		List<String> list_Cases = MFCasePlayModeCtrl.executePlay(CaseUtils.TYPE_NHE, MFCasePlayModeCtrl.STR_NONE, '1');

		Test.stopTest();

		List<Case> list_ExistingCases = [SELECT Id, OwnerId, RecordTypeId, Status, Type, Anticipated_Effective_Date__c FROM Case WHERE Type = :CaseUtils.TYPE_NHE];
		System.assertEquals(list_Cases[0], list_ExistingCases[0].Id, 'NHE Case not correctly Play out.');
		System.assertEquals(list_ExistingCases[0].OwnerId, UserInfo.getUserId(), 'NHE Case not correctly assigned.');
	}
}