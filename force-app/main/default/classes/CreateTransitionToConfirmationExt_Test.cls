@isTest
private class CreateTransitionToConfirmationExt_Test {
	@isTest
	static void CreateTransition() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		Id idBenefitOrderNewPlanRecType = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(idBenefitOrderNewPlanRecType)
			.setName('Test Benefit Order')
			.setStatusDetail('STATUS DETAIL')
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenefitOrder;

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('TEST CARRIER').setUniqueName('TEST CARRIER').setState('TS').build();
		insert objCarrier;

		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier')
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'New Plan'))
			.setCarrier(objCarrier.Id)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOrderType('TAdA: Pre OE Setup')
			.build();
		insert objCarrierOrder;

		Test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(objCarrierOrder);
		PageReference pageRef = Page.CreateTransitionToConfirmation;
		pageRef.getParameters().put('id', String.valueOf(objCarrierOrder.Id));
		Test.setCurrentPage(pageRef);
		CreateTransitionToConfirmationExt dedit = new CreateTransitionToConfirmationExt(sc);
		dedit.initconfirmation();
		Test.stopTest();
	}
}