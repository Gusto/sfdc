@isTest
public with sharing class CarrierVersionDetailTriggerHelperTest {
	@TestSetup
	static void makeData() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		CarrierTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(Cache.getRecordTypeId('Account', 'Company')).setName('Test Account').build();
		insert objAcc;

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits Renewal'))
			.setAccountId(objAcc.Id)
			.setName('Test Opp')
			.setStage('Open')
			.setCloseDate(System.today())
			.setHIEffectiveDate(System.today())
			.build();
		insert objOpp;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Blue Shield of California').setUniqueName('Blue Shield of California').setState('CA').setCarrierId('94').build();
		objCarrier.Id__c = '12';
		insert objCarrier;
		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID)
			.setName('Test Benefit Order')
			.setAccount(objAcc.Id)
			.setOpp(objOpp.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenefitOrder;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Test Carrier Order')
			.setRecordTypeId(cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
			.setImplementationStage('Ready for Qualification')
			.setOwnerID(UserInfo.getUserId())
			.setCarrier(objCarrier.Id)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES)
			.build();
		insert objCO;

		Carrier_Version_Detail__c objCarrierVersion = new Carrier_Version_Detail__c();
		objCarrierVersion.Carrier_Id__c = objCarrier.Id;
		objCarrierVersion.With_Changes_Sub_Start_Variation_No__c = 10;
		objCarrierVersion.Without_Changes_Sub_Start_Variation_No__c = 5;
		objCarrierVersion.With_Changes_Submission_Start_Event__c = 'Before Days';
		objCarrierVersion.Without_Changes_Submission_Start_Event__c = 'After Days';
		objCarrierVersion.Effective_date__c = System.today();
		objCarrierVersion.Member_Submission_Event__c = 'Before Days';
		objCarrierVersion.Member_Submission_Variation1__c = 1;
		objCarrierVersion.Member_Submission_Variation2__c = 1;
		objCarrierVersion.Group_Submission_Event__c = 'Before Days';
		objCarrierVersion.Group_Variation_Number1__c = 3;
		objCarrierVersion.Group_Variation_Number2__c = 3;
		objCarrierVersion.New_Plan_Submission_Event__c = 'After Days';
		objCarrierVersion.New_Plan_Variation_Num1__c = 4;
		objCarrierVersion.New_Plan_Variation_Num2__c = 4;
		insert objCarrierVersion;
		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
		BenefitOrderHelper.skipTrigger = false;
		CarrierTriggerHelper.skipTrigger = false;
		CarrierOrderTriggerHelper.skipTrigger = false;
	}

	/**
	 * @author			Deepika Saini
	 * @description		This method is used to test the population of Submission_Deadline_Start_Date__c.
	 * @params			NA
	 * @return			NA
	 */
	@isTest
	public static void testSubmissionDeadlineStartDatePopulation() {
		Carrier_Version_Detail__c objCarrierVersion = [SELECT Id, Carrier_Id__c, Without_Changes_Sub_Start_Variation_No__c FROM Carrier_Version_Detail__c LIMIT 1];
		objCarrierVersion.Without_Changes_Sub_Start_Variation_No__c = 1;
		update objCarrierVersion;

		Carrier_Order__c objCO = [SELECT Id, Submission_Deadline_Start_Date__c FROM Carrier_Order__c WHERE Carrier__c = :objCarrierVersion.Carrier_Id__c];

		System.assert(objCO.Submission_Deadline_Start_Date__c != null);
	}

	/**
	 * @author			Deepika Saini
	 * @description		This method is used to test the population of Group_Submission_Date__c.
	 * @params			NA
	 * @return			NA
	 */
	@isTest
	public static void testGroupSubmissionDate() {
		Carrier_Version_Detail__c objCarrierVersion = [SELECT Id, Carrier_Id__c, Without_Changes_Sub_Start_Variation_No__c FROM Carrier_Version_Detail__c LIMIT 1];
		objCarrierVersion.Group_Submission_Event__c = 'same';
		update objCarrierVersion;

		Carrier_Order__c objCO = [SELECT Id, Group_Submission_Date__c FROM Carrier_Order__c WHERE Carrier__c = :objCarrierVersion.Carrier_Id__c];

		System.assert(objCO.Group_Submission_Date__c != null);
	}

	/**
	 * @author			Deepika Saini
	 * @description		This method is used to test the population of Member_Submission_Date__c.
	 * @params			NA
	 * @return			NA
	 */
	@isTest
	public static void testMemberSubmissionDate() {
		Carrier_Version_Detail__c objCarrierVersion = [SELECT Id, Carrier_Id__c, Without_Changes_Sub_Start_Variation_No__c FROM Carrier_Version_Detail__c LIMIT 1];
		objCarrierVersion.Member_Submission_Event__c = 'after days';
		update objCarrierVersion;

		Carrier_Order__c objCO = [SELECT Id, Member_Submission_Date__c FROM Carrier_Order__c WHERE Carrier__c = :objCarrierVersion.Carrier_Id__c];

		System.assert(objCO.Member_Submission_Date__c != null);
	}

	/**
	 * @author			Deepika Saini
	 * @description		This method is used to test the population of Submission_Deadline__c.
	 * @params			NA
	 * @return			NA
	 */
	@isTest
	public static void testNPSubmissionDeadlineDate() {
		Carrier_Version_Detail__c objCarrierVersion = [SELECT Id, Carrier_Id__c, Without_Changes_Sub_Start_Variation_No__c FROM Carrier_Version_Detail__c LIMIT 1];
		objCarrierVersion.New_Plan_Submission_Event__c = 'same';
		update objCarrierVersion;

		Carrier_Order__c objCO = [SELECT Id, Submission_Deadline__c FROM Carrier_Order__c WHERE Carrier__c = :objCarrierVersion.Carrier_Id__c];

		System.assert(objCO.Submission_Deadline__c != null);
	}
}