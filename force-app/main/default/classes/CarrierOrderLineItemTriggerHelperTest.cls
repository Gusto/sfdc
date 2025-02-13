/*
 * To cover unit test scenarios of CarrierOrderLineItemTriggerHelper class
 */
@isTest
class CarrierOrderLineItemTriggerHelperTest {
	@testSetup
	static void setupData() {
		// Opportunity
		Opportunity objOppty = TestUtility.BenefitsBoROpportunity();

		// Benefit Order
		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID)
			.setStatusDetail('Owner only group')
			.setName('TEST BENEFIT ORDER')
			.setOpp(objOppty.Id)
			.setType('TAdA')
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBO;

		// Carrier
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test Carrier').setState('AL;AK').build();
		insert objCarrier;

		// Carrier Order
		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setRecordTypeId(CarrierOrderUtil.REC_TYPE_BOR)
			.setName('Test Carrier Order')
			.setCarrier(objCarrier.Id)
			.setStartDate(System.Today())
			.setImplementationStage('Qualification')
			.setBenefitOrder(objBO.Id)
			.setOwnerID(UserInfo.getUserId())
			.build();
		objCO.Facilitator_2_Plan_Build__c = 'Y';
		objCO.Resign_Required__c = 'No';
		objCO.Contribution_per_the_ER__c = 'test';
		insert objCO;

		//Neha, 30 Sep 2019, added record type as Benefits
		Id idBenefitsChk = Cache.getRecordTypeId('BOR_Master_Checklist__c', 'Benefits');
		List<String> list_checklistTypes = new List<String>{ 'HSA', 'FSA', 'DCA', 'Commuter', null };
		List<BOR_Master_Checklist__c> list_masterCheckList = new List<BOR_Master_Checklist__c>();
		for (String strType : list_checklistTypes) {
			list_masterCheckList.add(
				new BOR_Master_Checklist__c(RecordTypeId = idBenefitsChk, BOR_Checklist_Name__c = 'Test ' + strType, Mandatory__c = true, BOR_Checklist_Status__c = 'Active', TADA_Type__c = strType)
			);
		}
		insert list_masterCheckList;
	}

	@isTest
	static void testBenefitsChecklist() {
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		Test.startTest();
		System.assertEquals(0, [SELECT Id FROM BOR_Checklist__c].size(), 'BOR Checklist is not empty');

		List<String> list_benefitTypes = new List<String>{
			'Flexible Spending Account - Medical',
			'Flexible Spending Account - Dependent Care',
			'HSA',
			'Commuter',
			'Flexible Spending Account - Medical',
			'Dental'
		};
		List<Integer> list_renewalDate = new List<Integer>{ 3, 6, 7, 9, 11, 13 };
		List<Carrier_Order_Line_Item__c> list_COLI = new List<Carrier_Order_Line_Item__c>();
		for (Integer iRow = 0; iRow < list_renewalDate.size(); iRow++) {
			list_COLI.add(
				new Carrier_Order_Line_Item__c(
					Carrier_Order__c = objCO.Id,
					Benefit_Types__c = list_benefitTypes[iRow],
					Group_Number__c = list_benefitTypes[iRow].left(3) + ' - ' + list_renewalDate[iRow],
					Renewal_Date__c = System.Today().addDays(list_renewalDate[iRow])
				)
			);
		}
		insert list_COLI;

		Integer intChecklistSize = [SELECT Id FROM BOR_Checklist__c].size();
		System.assertNotEquals(0, intChecklistSize, 'BOR Checklist is empty');

		objCO = [SELECT Id, Number_Of_Collected_Documents__c, Total_Number_Of_Documents__c, Benefit_Order__c FROM Carrier_Order__c WHERE Id = :objCO.Id];
		System.assertNotEquals(null, objCO.Number_Of_Collected_Documents__c, '[CO] Number of Collected Doc is not populated');
		System.assertNotEquals(null, objCO.Total_Number_Of_Documents__c > 0, '[CO] Total Number of Doc is not populated');

		Benefit_Order__c objBO = [SELECT Id, Number_Of_Collected_Documents__c, Total_Number_Of_Documents__c, Renewal_Date__c FROM Benefit_Order__c WHERE Id = :objCO.Benefit_Order__c];
		System.assertNotEquals(null, objBO.Number_Of_Collected_Documents__c > 0, '[BO] Number of Collected Doc is not populated');
		System.assertNotEquals(null, objBO.Total_Number_Of_Documents__c > 0, '[BO] Total Number of Doc is not populated');
		Date dtBORenewalDate = objBO.Renewal_Date__c;

		delete list_COLI[0];
		System.assertEquals(--intChecklistSize, [SELECT Id FROM BOR_Checklist__c].size(), 'Checklist not removed');

		objBO = [SELECT Id, Renewal_Date__c FROM Benefit_Order__c WHERE Id = :objCO.Benefit_Order__c];
		System.assertNotEquals(dtBORenewalDate, objBO.Renewal_Date__c, 'Renewal Date is unchanged');
		Test.stopTest();
	}
}