/*
	BY: PR
	Date: May/22/2020
	Desc: Following class is implementing "Code coverage" logic for HICarrierDetailTriggerHelper class 
*/
@isTest
public class HICarrierDetailTriggerHelperTest {
	@testsetup
	static void dataSetupMethod() {
		HI_State_Carrier__c objState = new HI_State_Carrier__c();
		objState.Carrier_Id__c = '123123';
		insert objState;

		HI_Carrier_Detail__c objDetail = new HI_Carrier_Detail__c();
		objDetail.Id__c = 'test321';
		objDetail.Name__c = 'testCarrierName';
		insert objDetail;

		Carrier_Info__c info = new Carrier_Info__c();
		info.Name = 'testCarrierName';
		info.Id__c = '123123';
		info.Key__c = 'testCarrierName_New';
		info.External_Key__c = 'testCarrierName_New_123123';
		info.Carrier_Detail_Id__c = 'test321';
		insert info;
	}

	@isTest
	static void carrierDetailUpdate() {
		test.startTest();

		list<HI_Carrier_Detail__c> list_CarrierDetail = [SELECT Name__c, Id FROM HI_Carrier_Detail__c LIMIT 1];
		list_CarrierDetail.get(0).Name__c = 'testCarrierName_Mod';
		update list_CarrierDetail;

		//Fetch the record again after the update and check if its Name is updated.
		HI_Carrier_Detail__c var_HICarrierDetailRec = [SELECT Name__c FROM HI_Carrier_Detail__c WHERE Name__c = 'testCarrierName_Mod'];
		System.assertEquals('testCarrierName_Mod', var_HICarrierDetailRec.Name__c, 'Name__c should be updated to "testCarrierName_Mod"');
		System.assertNotEquals('testCarrierName', var_HICarrierDetailRec.Name__c, 'Name__c should have changed from the original value');

		test.stopTest();

		delete list_CarrierDetail;

		//Assert for the delete of the HI_Carrier_Detail__c record's list.
		List<HI_Carrier_Detail__c> list_HICarrierDetailDeleted = [SELECT Name__c FROM HI_Carrier_Detail__c WHERE Name__c = 'testCarrierName_Mod'];
		System.assertEquals(0, list_HICarrierDetailDeleted.size(), 'The record should be deleted after delete operation');

		// Undelete the record and check if it is back in the system
		undelete list_CarrierDetail;

		//Assert for the undelete of the HI_Carrier_Detail__c record's list.
		List<HI_Carrier_Detail__c> list_HICarrierDetailUndeleted = [SELECT Name__c FROM HI_Carrier_Detail__c WHERE Name__c = 'testCarrierName_Mod'];
		System.assertEquals(1, list_HICarrierDetailUndeleted.size(), 'The record should be present after undelete operation');
		System.assertEquals('testCarrierName_Mod', list_HICarrierDetailUndeleted[0].Name__c, 'Name__c should remain the same after undelete');
	}
}