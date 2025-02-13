/**
 * @name         : GFLeadBatchTest
 * @author       : David (Dato) Tsamalashvili
 * @date         : 12-28-2021
 * @description  : Test class for batch job - GFLeadBatch
 **/
@isTest
public class GFLeadBatchTest {
	@TestSetup
	static void setup() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setGFLeadBatchSize(1).build();

		insert objConfigSettings;
	}

	@isTest
	static void testBatchExecution() {
		GFLeadTriggerHelper.skipTrigger = true;

		GF_Lead__c objGFLead = new TestDataFactory.GFLeadBuilder()
			.setLeadType('Company')
			.setFName('test')
			.setLName('test')
			.setCompanyName('Test')
			.setEmail('test.test@gusto.com')
			.setSessionId('12345')
			.setVisitorId('12345')
			.setProcessingState('Queued')
			.build();
		insert objGFLead;

		GFLeadTriggerHelper.skipTrigger = false;

		Test.startTest();
		GFLeadBatchScheduler clsScehule = new GFLeadBatchScheduler();
		clsScehule.execute(null);
		Test.stopTest();

		List<GF_Lead__c> list_GFLeads = [SELECT Id FROM GF_Lead__c WHERE Processing_State__c = 'Queued'];
		System.assertEquals(0, list_GFLeads.size());
	}
}