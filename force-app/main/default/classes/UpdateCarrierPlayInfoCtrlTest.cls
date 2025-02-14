/**
 * @name         UpdateCarrierPlayInfoCtrlTest
 * @author       Omar Benitez
 * @date         18th Sep 2024
 * @description  Test class for UpdateCarrierPlayInfoCtrl
 **/
@isTest
class UpdateCarrierPlayInfoCtrlTest {
	@testSetup
	static void setup() {
		//Insert custom settings
		insert new List<Carrier_Play_Information_Defaults__c>{
			new TestDataFactory.CarrierPlayInfoDefaultBuilder().setName('AuditFirstPlayBef').setEventType('Audit').setPlayModeType('First Play').setBeforeAfter('Before').setNumberOfDays(3).build(),
			new TestDataFactory.CarrierPlayInfoDefaultBuilder().setName('AuditFirstPlayAft').setEventType('Audit').setPlayModeType('First Play').setBeforeAfter('After').setNumberOfDays(2).build(),
			new TestDataFactory.CarrierPlayInfoDefaultBuilder()
				.setName('OrderFirstPlayBef1_15')
				.setEventType('Order')
				.setPlayModeType('First Play')
				.setBeforeAfter('Before')
				.setNumberOfDays(2)
				.setFrom(1)
				.setTo(15)
				.build()
		};

		List<Carrier__c> list_Carriers = new List<Carrier__c>{
			new TestDataFactory.CarrierBuilder().setName('Test Care California').setUniqueName('Test Care').setState('CA').setId('CarrierId1').build(),
			new TestDataFactory.CarrierBuilder().setName('Test Care New York').setUniqueName('Test Care').setState('NY').setId('CarrierId2').build(),
			new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setState('NY;TX;CA,MO').setId('CarrierId3').build()
		};
		insert list_Carriers;
	}

	@isTest
	static void testFetchCarriers() {
		Test.startTest();
		Map<String, Object> map_response = UpdateCarrierPlayInfoCtrl.fetchCarriers();
		Test.stopTest();
		List<String> list_CarrierUniqueName = (List<String>) map_response.get('carriers');
		System.assertNotEquals(0, list_CarrierUniqueName.size(), 'It should return a list of Carriers');
	}

	@isTest
	static void testFetchCarrierPlayInfo() {
		List<Carrier__c> list_Carriers = [SELECT ID FROM Carrier__c];
		Set<Id> set_CarrierIds = new Map<ID, Carrier__c>(list_Carriers).keySet();
		List<Id> list_CarrierIds = new List<Id>(set_CarrierIds);
		Test.startTest();
		Map<String, Object> map_response = UpdateCarrierPlayInfoCtrl.fetchCarrierPlayInfo(list_CarrierIds);
		Map<String, Carrier_Play_Information__c> map_CarrierPlayInfo = (Map<String, Carrier_Play_Information__c>) map_response.get('map_CarrierPlayInfo');
		Test.stopTest();
		System.assertNotEquals(0, map_CarrierPlayInfo.size(), 'It should return a map of Carrier Play Information');
	}
	@isTest
	static void testSaveCarrierPlayInfo() {
		List<Carrier__c> list_Carriers = [SELECT ID FROM Carrier__c];
		Set<Id> set_CarrierIds = new Map<ID, Carrier__c>(list_Carriers).keySet();
		List<Id> list_CarrierIds = new List<Id>(set_CarrierIds);
		Test.startTest();
		Map<String, Object> map_response = UpdateCarrierPlayInfoCtrl.fetchCarrierPlayInfo(list_CarrierIds);
		Map<String, Carrier_Play_Information__c> map_CarrierPlayInfo = (Map<String, Carrier_Play_Information__c>) map_response.get('map_CarrierPlayInfo');
		System.assertNotEquals(0, map_CarrierPlayInfo.size());
		Id idCarrierToQuery = map_CarrierPlayInfo.values()[0].Id;
		map_CarrierPlayInfo.values()[0].Number_of_Days__c = 400;
		UpdateCarrierPlayInfoCtrl.saveCarrierPlayInfo(map_CarrierPlayInfo.values());
		Carrier_Play_Information__c objCarrierPlayUpdated = [SELECT ID, Number_of_Days__c FROM Carrier_Play_Information__c WHERE ID = :idCarrierToQuery];
		Test.stopTest();
		System.assertEquals(400, objCarrierPlayUpdated.Number_of_Days__c, 'It should update the Number of Days field');
	}
}