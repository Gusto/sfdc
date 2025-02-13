/**
 * @author       Deepika Saini
 * @date         22nd July 2024
 * @description  This class is used to test the CarrierOrderMoveToConfirmationCtrl class functionality.
 **/
@isTest
public class CarrierOrderMoveToConfirmationCtrlTest {
	/**
	 * @author      Deepika Saini
	 * @description This method used to test the Implementation Stage and Submission Completion Notes.
	 * @param       NA
	 * @return      NA
	 */
	@isTest
	static void MoveToConfirmationTest() {
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		test.startTest();

		Id boRenewalRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBenOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(boRenewalRecType)
			.setStatusDetail('STATUS DETAIL')
			.setCoverageEffectiveDate(System.today().addDays(5))
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenOrder;
		State__c objState = new TestDataFactory.StateBuilder().setName('California').setId('12').setAbbreviation('CA').build();
		insert objState;

		Carrier__c objCarrier1 = new TestDataFactory.CarrierBuilder().setName('Test Carrier 1').setCarrierId('12').setState('CA').setKey('test_carrier_1_ca').setId('90').build();
		insert objCarrier1;

		Carrier_Order__c objCarrierOrder1 = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
			.setCarrier(objCarrier1.Id)
			.setOwnerID(UserInfo.getUserId())
			.setBenefitOrder(objBenOrder.Id)
			.setOrderType('TAdA: Pre OE Setup')
			.setStartDate(System.today() - 50)
			.setImplementationStage('Approved')
			.build();
		insert objCarrierOrder1;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('TestCarrierOrder')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
			.setCarrier(objCarrier1.Id)
			.setOwnerID(UserInfo.getUserId())
			.setBenefitOrder(objBenOrder.Id)
			.setOrderType('TAdA: Pre OE Setup')
			.setStartDate(System.today() - 50)
			.setImplementationStage('Approved')
			.setParentCarrierOrder(objCarrierOrder1.Id)
			.build();
		insert objCarrierOrder;

		CarrierOrderMoveToConfirmationCtrl.MoveToConfirmation(objCarrierOrder1.Id, 'Test');
		objCarrierOrder = [SELECT Id, Implementation_Stage__c, Submission_Completion_Notes__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder1.Id];
		System.assertEquals('Ready for Confirmation', objCarrierOrder.Implementation_Stage__c, 'Implementation stage should be set to Ready for Confirmation');
		System.assertEquals('Test', objCarrierOrder.Submission_Completion_Notes__c, 'Submission Completion Notes not updated');

		test.stopTest();
	}
}