/**
 * @name         CarrierMassUpdateCtrlTest
 * @author       Deepika Saini
 * @date         02 July 2024
 * @description  CarrierMassUpdateCtrl class code coverage.
 **/
@isTest
public class CarrierMassUpdateCtrlTest {
	@testSetup
	static void makeData() {
		list<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrierRec = new TestDataFactory.CarrierBuilder().setName('Test').setKey('test123').setId('test123').build();
		list_Carriers.add(objCarrierRec);

		Carrier__c objCarrierRec2 = new TestDataFactory.CarrierBuilder().setName('Alegeus').setKey('alegeus123').setId('alegeus123').build();
		list_Carriers.add(objCarrierRec2);

		Carrier__c objCarrierRec3 = new TestDataFactory.CarrierBuilder().setName('Test1236').setKey('test1236').setId('test1236').build();
		list_Carriers.add(objCarrierRec3);

		CarrierTriggerHelper.skipTrigger = true;
		insert list_Carriers;
	}
	/**
	 * @author       Deepika Saini
	 * @description  This method is used update Carrier Records
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testUpdateCarrier() {
		Test.startTest();
		List<Carrier__c> list_Carrier = [SELECT Id, Fulfillment_Carrier_Grouping__c, Carrier_Fulfillment_Blocked__c FROM Carrier__c];
		ApexPages.currentPage().getParameters().put('Id', list_Carrier.get(0).id);
		ApexPages.currentPage().getHeaders().put('referer', 'lightning.force.com');
		ApexPages.StandardSetController objSSC = new ApexPages.StandardSetController(list_Carrier);
		objSSC.setSelected(list_Carrier);
		CarrierMassUpdateCtrl objCon = new CarrierMassUpdateCtrl(objSSC);
		objCon.getFieldOption();
		List<String> list_OptionSelected = new List<String>{ 'Fulfillment Carrier Grouping', 'Carrier Fulfillment Blocked' };
		objCon.list_fieldList = list_OptionSelected;
		objCon.getfieldsToUpdate();
		objCon.getStep();
		objCon.cancel();
		objCon.objCarrier.Fulfillment_Carrier_Grouping__c = 'Group 1';
		objCon.objCarrier.Carrier_Fulfillment_Blocked__c = true;
		objCon.updateCarrier();

		Test.stopTest();

		list_Carrier = [SELECT Id, Fulfillment_Carrier_Grouping__c, Carrier_Fulfillment_Blocked__c FROM Carrier__c];
		System.assertEquals('Group 1', list_Carrier[0].Fulfillment_Carrier_Grouping__c, 'Carrier not updated');
		System.assertEquals('Group 1', list_Carrier[1].Fulfillment_Carrier_Grouping__c, 'Carrier not updated');
		System.assertEquals('Group 1', list_Carrier[2].Fulfillment_Carrier_Grouping__c, 'Carrier not updated');
		System.assertEquals(true, list_Carrier[0].Carrier_Fulfillment_Blocked__c, 'Carrier not updated');
		System.assertEquals(true, list_Carrier[1].Carrier_Fulfillment_Blocked__c, 'Carrier not updated');
		System.assertEquals(true, list_Carrier[2].Carrier_Fulfillment_Blocked__c, 'Carrier not updated');
	}
}