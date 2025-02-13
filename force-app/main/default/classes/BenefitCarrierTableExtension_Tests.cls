/* This is a Test Class for BenefitCarrierTableExtension.cls*/

@isTest
private class BenefitCarrierTableExtension_Tests {
	/* @author        Praveen Sethu
	 * @description	  Setup method to insert tier config custom settings
	 * @param         void
	 * @return        void
	 **/
	@testSetup
	static void setup() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;
	}

	@isTest
	private static void OrderTableTest() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c);

		PriceBook2 bk = new PriceBook2();
		bk.Name = objTierConfig.New_Price_1__c;
		bk.IsActive = true;
		insert bk;

		// insert product list and assert
		List<Product2> prodList = new List<Product2>();
		prodList.add(TestUtility.createTestProduct('Active Employee', 'Payroll', false));
		prodList.add(TestUtility.createTestProduct('Company', 'Employee', false));
		prodList.add(TestUtility.createTestProduct('Contractor', 'Employee', false));
		prodList.add(TestUtility.createTestProduct('Medical', 'Employee', false));
		insert prodList;

		OpportunityTriggerHelper.skipTrigger = true;

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();
		opp1.Pricebook2Id = bk.id;
		update opp1;

		//Insert benefit order
		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);

		//Insert carrier
		Carrier__c carrier1 = TestUtility.Carrier();

		//Insert carrier order
		Carrier_Order__c carrierOrder1 = TestUtility.createTestCarrierOrder(carrier1.Id, 'Test Carrier Order', benefitOrdr1.Id, true);

		//Create policy and then update its benefit type
		//List<Policy__c> policyList = new List<Policy__c>();
		//Policy__c pol1 = TestUtility.createTestPolicy(opp1.Id, carrier1.Id, true, 'Test Policy1', carrierOrder1.Id, false);
		//pol1.Benefit_Type__c = 'Medical';
		//policyList.add(pol1);
		//insert policyList;

		User_Preference__c userPrefRec = new User_Preference__c();
		userPrefRec.User__c = userInfo.getUserId();
		userPrefRec.Benefit_Order_Status__c = 'New';
		userPrefRec.Carrier_Order_Implementation_Stage__c = 'New';
		insert userPrefRec;

		Test.startTest();
		PageReference pageRef = Page.BenefitCarrierTable;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id FROM Benefit_Order__c]));
		setCon.setSelected([SELECT Id FROM Benefit_Order__c]);

		ApexPages.StandardController con;
		BenefitCarrierTableExtension ext = new BenefitCarrierTableExtension(con);
		ext.size = 10;
		//ext.Coverage_Effective_Date__c
		ext.userRecord.Carrier_Name__c = 'Test Carrier Order';
		ext.selectedCarrierOrderStatus.add(new SelectOption('New', 'New'));
		ext.selectedBenefitOrderStatus.add(new SelectOption('New', 'New'));
		ext.refreshOrders();
		ext.saveMe();
		ext.benefitOrderView();
		ext.refreshPageSize();
		ext.getBenefitOrders();
		Test.stopTest();

		System.assertEquals(1, [SELECT id FROM Benefit_Order__c].size());
		System.assertEquals(0, ext.noOfRecords);
	}
}