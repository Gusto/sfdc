/**
 * @name         BatchDMLTest
 * @author       Sanjay Paryani
 * @date         05/28/2020
 * @description  Test class for BatchDML
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
private class BatchDMLTest {
	@isTest
	static void test_BatchDMLInsert() {
		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		List<Carrier__c> list_CarriersToUpdate = new List<Carrier__c>();
		List<Carrier__c> list_CarriersToDelete = new List<Carrier__c>();

		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Test Care California').setUniqueName('Test Care').setState('CA').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Test Care New York').setUniqueName('Test Care').setState('NY').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setState('NY;TX;CA,MO').setPartnerType('TAdA').build());

		Test.startTest();
		if (!list_Carriers.isEmpty()) {
			BatchDML.Operation batchInsert = BatchDML.Operation.INS;
			ID batchInsertJobID = System.enqueueJob(new BatchDML(batchInsert, list_Carriers, false));
		}
		System.assertNotEquals(0, list_Carriers.size(), 'The list cannot be empty.');
		Test.stopTest();
	}

	@isTest
	static void test_BatchDMLUpdate() {
		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		List<Carrier__c> list_CarriersToUpdate = new List<Carrier__c>();
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Test Care California').setUniqueName('Test Care').setState('CA').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Test Care New York').setUniqueName('Test Care').setState('NY').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setState('NY;TX;CA,MO').setPartnerType('TAdA').build());
		insert list_Carriers;

		for (Carrier__c c : [SELECT Id, Name, Carrier_Unique_Name__c, State__c FROM Carrier__c LIMIT 2]) {
			list_CarriersToUpdate.add(c);
		}

		Test.startTest();
		if (!list_Carriers.isEmpty()) {
			list_CarriersToUpdate[0].Carrier_Unique_Name__c = 'Test Care';
			list_CarriersToUpdate[1].Carrier_Unique_Name__c = 'Test Care';

			BatchDML.Operation batchUpdate = BatchDML.Operation.UPD;
			ID batchUpdateJobID = System.enqueueJob(new BatchDML(batchUpdate, list_CarriersToUpdate, false));
		}
		System.assertNotEquals(0, list_CarriersToUpdate.size(), 'The list cannot be empty.');
		Test.stopTest();
	}

	@isTest
	static void test_BatchDMLDelete() {
		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		List<Carrier__c> list_CarriersToDelete = new List<Carrier__c>();
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Test Care California').setUniqueName('Test Care').setState('CA').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Test Care New York').setUniqueName('Test Care').setState('NY').build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setState('NY;TX;CA,MO').setPartnerType('TAdA').build());
		insert list_Carriers;

		for (Carrier__c c : [SELECT Id, Name, Carrier_Unique_Name__c, State__c FROM Carrier__c]) {
			list_CarriersToDelete.add(c);
		}

		Test.startTest();
		BatchDML.Operation batchDelete = BatchDML.Operation.DEL;
		ID batchDeleteJobID = System.enqueueJob(new BatchDML(batchDelete, list_CarriersToDelete, false));
		System.assertNotEquals(0, list_CarriersToDelete.size(), 'The list cannot be empty.');
		Test.stopTest();
	}
}