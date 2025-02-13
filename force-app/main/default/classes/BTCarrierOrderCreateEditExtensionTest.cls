/**
 * @name         BTCarrierOrderCreateEditExtensionTest
 * @author       Vinay
 * @date         27-02-2020
 * @description  Test class for BTCarrierOrderCreateEditExtension class . VF page - BTCarrierOrderCreateEdit
 *               Update the test class to have upfront testSetup and added asserts on some of the methods
 **/
@isTest
private class BTCarrierOrderCreateEditExtensionTest {
	static final Id idBoRRecTypeId = Schema.SObjectType.Carrier_Order__c.getRecordTypeInfosByName()
		.get('Benefits BoR')
		.getRecordTypeId();

	@testSetup
	static void makeData() {
		Utils.skipTrigger(true);
		Account objAcct = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('7757616923607181').setJoinedDate(System.today()).setName('Test Account').build();
		insert objAcct;
		
		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('TEST OPPORTUNITY')
			.setAccountId(objAcct.Id)
			.setNumberOfEE(5)
			.setId('aasmEvent321')
			.setBenefitsState('CA')
			.setStage('STAGENAME')
			.setType('New TAdA Plan')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		Benefit_Order__c objBenOrder = new TestDataFactory.BenefitOrderBuilder()
				.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'New Plan'))
				.setName('Test Benefit Order')
				.setAccount(objAcct.id)
				.setOpp(objOppty.Id)
				.setCoverageEffectiveDate(System.today())
				.setOwnerID(UserInfo.getUserId())
				.setSubmissionDeadline(System.today())
				.setStatus('Ready for Qualification')
				.setBORId('aasmEvent321')
				.setStatusDetail('Owner only group')
				.build();
		insert objBenOrder;
		Utils.skipTrigger(false);
	}

	@isTest
	static void testBOWithTaDaCOException() {
		test.startTest();
		Benefit_Order__c boRecWithTaDa = [SELECT Id, UW_Owner__c FROM Benefit_Order__c LIMIT 1];
		boRecWithTaDa.UW_Owner__c = UserInfo.getUserId();
		update boRecWithTaDa;

		Carrier__c objCarrierTaDa = new TestDataFactory.CarrierBuilder().setName('Alegeus').setState('NY').setPartnerType('TAdA').build();
		insert objCarrierTaDa;
		Carrier_Order__c objCarrierOrder = new Carrier_Order__c(
			Carrier__c = objCarrierTaDa.Id,
			Benefit_Order__c = boRecWithTaDa.Id,
			RecordTypeId = idBoRRecTypeId,
			Renewal_Date__c = date.newInstance(
				system.today().addMonths(1).year(),
				system.today().addMonths(1).month(),
				1
			),
			Benefit_Types__c = 'Commuter',
			Implementation_Stage__c = 'With Sales'
		);
		insert objCarrierOrder;

		Carrier_Order_Line_Item__c objCarrieOrderLineItem = new Carrier_Order_Line_Item__c(
			Carrier_Order__c = objCarrierOrder.Id,
			Renewal_Date__c = date.newInstance(
				system.today().addMonths(1).year(),
				system.today().addMonths(1).month(),
				1
			),
			Benefit_Types__c = 'Commuter'
		);
		insert objCarrieOrderLineItem;

		ApexPages.Standardcontroller c = new ApexPages.Standardcontroller(boRecWithTaDa);
		ApexPages.currentPage().getParameters().put('id', boRecWithTaDa.id);
		BTCarrierOrderCreateEditExtension btExtn = new BTCarrierOrderCreateEditExtension(c);
		btExtn.checkTAdAType();
		btExtn.getBenefitType();
		btExtn.addNewRow();
		btExtn.syncCarrierOrders();

		Integer indx = btExtn.list_CarrierOrderDetails.size() - 1;
		btExtn.list_CarrierOrderDetails.get(indx).list_SelectedBenefitType.add('Commuter');
		btExtn.list_CarrierOrderDetails.get(indx).list_SelectedBenefitType.add('HSA');
		btExtn.list_CarrierOrderDetails.get(indx).objCarrierOrder.Id = null;
		btExtn.list_CarrierOrderDetails.get(indx).objCarrierOrder.Renewal_Date__c = date.newInstance(
			system.today().addMonths(1).year(),
			system.today().addMonths(1).month(),
			1
		);

		btExtn.syncCarrierOrders();
		btExtn.addNewRow();

		btExtn.strRowToDelete = '2';
		btExtn.removeNewRow();
		btExtn.syncCarrierOrders();
		test.stopTest();

		system.assert([SELECT COUNT() FROM Carrier_Order__c] == 1);
	}

	@isTest
	static void testBOWithTaDaCOSuccess() {
		test.startTest();
		Benefit_Order__c boRecWithTaDa = [
			SELECT Id, UW_Owner__c, Qualification_Follow_Up_Date__c
			FROM Benefit_Order__c
			LIMIT 1
		];
		boRecWithTaDa.UW_Owner__c = UserInfo.getUserId();
		boRecWithTada.Qualification_Follow_Up_Date__c = system.today().addDays(5);
		update boRecWithTaDa;

		Carrier__c objCarrierTaDa = new TestDataFactory.CarrierBuilder().setName('Alegeus').setState('NY').setPartnerType('TAdA').build();
		insert objCarrierTaDa;
		Carrier__c objCarrierNonTaDa = new TestDataFactory.CarrierBuilder().setName('Test1').setState('CA').build();
		insert objCarrierNonTaDa;

		Carrier_Order__c objCarrierOrder = new Carrier_Order__c(
			Carrier__c = objCarrierTaDa.Id,
			Benefit_Order__c = boRecWithTaDa.Id,
			RecordTypeId = idBoRRecTypeId,
			Renewal_Date__c = date.newInstance(
				system.today().addMonths(1).year(),
				system.today().addMonths(1).month(),
				1
			),
			Benefit_Types__c = 'HSA',
			Implementation_Stage__c = 'With Sales'
		);
		insert objCarrierOrder;

		Carrier_Order_Line_Item__c objCarrieOrderLineItem = new Carrier_Order_Line_Item__c(
			Carrier_Order__c = objCarrierOrder.Id,
			Renewal_Date__c = date.newInstance(
				system.today().addMonths(1).year(),
				system.today().addMonths(1).month(),
				1
			),
			Benefit_Types__c = 'HSA'
		);
		insert objCarrieOrderLineItem;

		ApexPages.Standardcontroller stdCtrl = new ApexPages.Standardcontroller(boRecWithTaDa);
		ApexPages.currentPage().getParameters().put('id', boRecWithTaDa.id);
		BTCarrierOrderCreateEditExtension btExtn = new BTCarrierOrderCreateEditExtension(stdCtrl);
		btExtn.getBenefitType();
		btExtn.syncCarrierOrders();
		btExtn.addNewRow();

		Integer indx = btExtn.list_CarrierOrderDetails.size() - 1;
		btExtn.list_CarrierOrderDetails.get(indx).list_SelectedBenefitType.add('Medical');
		btExtn.list_CarrierOrderDetails.get(indx).list_SelectedBenefitType.add('Vision');
		btExtn.list_CarrierOrderDetails.get(indx).objCarrierOrder.Id = null;
		btExtn.list_CarrierOrderDetails.get(indx).objCarrierOrder.Renewal_Date__c = date.newInstance(
			system.today().addMonths(1).year(),
			system.today().addMonths(1).month(),
			1
		);
		btExtn.list_CarrierOrderDetails.get(indx).objCarrierOrder.Carrier__c = objCarrierNonTaDa.Id;

		btExtn.list_CarrierOrderDetails.get(0).list_SelectedBenefitType.add('Commuter');
		btExtn.list_CarrierOrderDetails.get(0).objCarrierOrder.Renewal_Date__c = date.newInstance(
			system.today().addMonths(1).year(),
			system.today().addMonths(1).month(),
			1
		);

		btExtn.syncCarrierOrders();
		test.stopTest();

		system.assert([SELECT COUNT() FROM Carrier_Order__c] == 2);
	}

	@isTest
	static void testBOWithNonTadaCO() {
		test.startTest();
		Benefit_Order__c boRecNonTaDa = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		Carrier__c objCarrierNonTaDa = new TestDataFactory.CarrierBuilder().setName('Test1').setState('CA').build();
		insert objCarrierNonTaDa;

		Carrier_Order__c objCarrierOrderNonTaDa = new Carrier_Order__c(
			Carrier__c = objCarrierNonTaDa.Id,
			Benefit_Order__c = boRecNonTaDa.Id,
			RecordTypeId = idBoRRecTypeId,
			Renewal_Date__c = date.newInstance(
				system.today().addMonths(1).year(),
				system.today().addMonths(1).month(),
				1
			),
			Benefit_Types__c = 'Medical',
			Implementation_Stage__c = 'With Sales'
		);
		insert objCarrierOrderNonTaDa;

		Carrier_Order_Line_Item__c objCOLIMedical = new Carrier_Order_Line_Item__c(
			Carrier_Order__c = objCarrierOrderNonTaDa.Id,
			Renewal_Date__c = date.newInstance(
				system.today().addMonths(1).year(),
				system.today().addMonths(1).month(),
				1
			),
			Benefit_Types__c = 'Medical'
		);
		insert objCOLIMedical;

		Carrier__c objCarrierTaDa = new TestDataFactory.CarrierBuilder().setName('Alegeus').setState('NY').setPartnerType('TAdA').build();
		insert objCarrierTaDa;
		ApexPages.Standardcontroller stdCtrl = new ApexPages.Standardcontroller(boRecNonTaDa);
		ApexPages.currentPage().getParameters().put('id', boRecNonTaDa.id);
		BTCarrierOrderCreateEditExtension btExtn = new BTCarrierOrderCreateEditExtension(stdCtrl);
		btExtn.getBenefitType();

		btExtn.syncCarrierOrders();
		system.assert([SELECT COUNT() FROM Carrier_Order__c] == 1);
		btExtn.addNewRow();
		Integer indx = btExtn.list_CarrierOrderDetails.size() - 1;
		btExtn.list_CarrierOrderDetails.get(indx).list_SelectedBenefitType.add('Commuter');
		btExtn.list_CarrierOrderDetails.get(indx).objCarrierOrder.Id = null;
		btExtn.list_CarrierOrderDetails.get(indx).objCarrierOrder.Renewal_Date__c = date.newInstance(
			system.today().addMonths(1).year(),
			system.today().addMonths(1).month(),
			1
		);
		btExtn.list_CarrierOrderDetails.get(indx).objCarrierOrder.Carrier__c = objCarrierTaDa.Id;

		btExtn.list_CarrierOrderDetails.get(0).list_SelectedBenefitType.add('Dental');
		btExtn.list_CarrierOrderDetails.get(0).list_SelectedBenefitType.add('Vision');
		btExtn.list_CarrierOrderDetails.get(0).objCarrierOrder.Renewal_Date__c = date.newInstance(
			system.today().addMonths(1).year(),
			system.today().addMonths(1).month(),
			1
		);
		btExtn.syncCarrierOrders();
		test.stopTest();

		system.assert([SELECT COUNT() FROM Carrier_Order__c] == 2);
	}
}