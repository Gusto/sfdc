/**
 * @name         HICarrierVersionDetailTriggerHandlerTest
 * @author       Gireesh
 * @date         07 July 2020
 * @description  Helper class to execute HI Fullfillment open enrollment events
 * @test class   HIFulfillmentEventOpenEnrollmentTest
 * @revisions    Date ------------ Name ------------ Comments
 */
@isTest
private class HICarrierVersionDetailTriggerHandlerTest {
	@testSetup
	static void testSetup() {
		Carrier__C objCarrier = new Carrier__C(name = 'Aetna', id__c = '1', carrier_id__c = '1');
		insert objCarrier;

		HICarrierVersionDetail__c objHICarrierVersion = new HICarrierVersionDetail__c(
			Event_Id__c = 'Ttta2w23',
			Event_Type__c = 'carrier_metadata',
			State_Carrier_Id__c = '1',
			Effective_date__c = System.today(),
			new_plan_email_list__c = 'Test',
			allows_plans_with_no_enrollees__C = 'no',
			allows_out_of_state_employees__C = 'yes',
			number_of_plans_allowed_on_fte_count__c = '["o","p"]'
		);
		insert objHICarrierVersion;
	}

	@isTest
	static void testinserCarrierVersion() {
		Test.startTest();
		HICarrierVersionDetail__c objCarrierVersion = [SELECT Id FROM HICarrierVersionDetail__c LIMIT 1];
		objCarrierVersion.Effective_date__c = System.today() + 31;
		update objCarrierVersion;
		Test.stopTest();

		List<Carrier_Version_Detail__c> list_updatedlist = [SELECT Id FROM Carrier_Version_Detail__c];
		System.assertEquals(2, list_updatedlist.size(), 'New carrier not inserted');
	}

	@isTest
	static void testUpdateCarrierVersion() {
		Test.startTest();
		HICarrierVersionDetail__c objCarrierVersion = [SELECT Id FROM HICarrierVersionDetail__c LIMIT 1];
		objCarrierVersion.Effective_date__c = System.today();
		update objCarrierVersion;
		Test.stopTest();

		List<Carrier_Version_Detail__c> list_updatedlist = [SELECT Id FROM Carrier_Version_Detail__c];
		System.assertEquals(1, list_updatedlist.size(), 'New carrier not updated');
	}

	@isTest
	static void testNoStateCarrierVersion() {
		Test.startTest();
		HICarrierVersionDetail__c objCarrierVersion = [SELECT Id FROM HICarrierVersionDetail__c LIMIT 1];
		objCarrierVersion.State_Carrier_Id__c = '10999';
		update objCarrierVersion;
		Test.stopTest();

		objCarrierVersion = [SELECT Id, Processing_State__c FROM HICarrierVersionDetail__c LIMIT 1];
		System.assertEquals('Error', objCarrierVersion.Processing_State__c, 'Failed: Carrier version data processesd without state');
	}

	@isTest
	static void testCarrierVersionBatch() {
		Test.startTest();
		HICarrierVersionDetail__c objCarrierVersion = [SELECT Id FROM HICarrierVersionDetail__c LIMIT 1];
		objCarrierVersion.State_Carrier_Id__c = '10999';
		update objCarrierVersion;

		insert new Carrier__C(Name = 'Humana', Id__c = '10999', Carrier_Id__c = '10999');
		Database.executeBatch(new HICarrierVersionDetailBatch(), 10);
		Test.stopTest();

		objCarrierVersion = [SELECT id, Processing_State__c FROM HICarrierVersionDetail__c LIMIT 1];
		System.assertEquals('Processed', objCarrierVersion.Processing_State__c, 'Failed: Carrier version data not processesd');
	}

	@isTest
	static void testCarrierVersionBatchScheduler() {
		Test.startTest();
		HICarrierVersionDetailBatch objSchedule = new HICarrierVersionDetailBatch();
		String strJobId = system.schedule('Test HI Carrier Version Schedule', '0 0 23 * * ?', objSchedule);
		Test.stopTest();

		System.assertNotEquals(null, strJobId, 'Job not scheduled');
	}
}