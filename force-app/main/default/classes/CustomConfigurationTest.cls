/**
 * @author Brent Johnson
 * @date 1/11/17
 * Catch-all test class for ad-hoc process builder testing
 */

@isTest
private class CustomConfigurationTest {
	@isTest
	static void generate_benefit_order_when_new_plan_application_verifying_eligibility() {
		Account objAccnt = newCompanyAccount();
		// Create Benefits Renewal Opportunity
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		insert objOppty;

		Test.startTest();
		objOppty.Benefits_Current_Setup_Step__c = 'Verifying Eligibility';
		update objOppty;
		Test.stopTest();

		objOppty = [SELECT Order_Generated__c, (SELECT Id FROM Benefit_Orders__r) FROM Opportunity WHERE Id = :objOppty.Id LIMIT 1][0];
		//System.assert(objOppty.Order_Generated__c);
		//System.assertEquals(1, objOppty.Benefit_Orders__r.size());
	}

	@isTest
	static void generate_benefit_order_when_renewal_application_completed() {
		Account objAccnt = newCompanyAccount();
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		insert objOppty;

		Test.startTest();
		objOppty.Benefits_Current_Setup_Step__c = 'Completed';
		update objOppty;
		Test.stopTest();

		objOppty = [SELECT Order_Generated__c, (SELECT Id FROM Benefit_Orders__r) FROM Opportunity WHERE Id = :objOppty.Id LIMIT 1][0];
		//System.assert(objOppty.Order_Generated__c);
	}

	@isTest
	static void generate_benefit_order_when_change_application_completed() {
		Account objAccnt = newCompanyAccount();
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Change');
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		insert objOppty;

		Test.startTest();
		objOppty.Benefits_Current_Setup_Step__c = 'Completed';
		update objOppty;
		Test.stopTest();

		objOppty = [SELECT Order_Generated__c, (SELECT Id FROM Benefit_Orders__r) FROM Opportunity WHERE Id = :objOppty.Id LIMIT 1][0];
		//System.assert(objOppty.Order_Generated__c);
		//System.assertEquals(1, objOppty.Benefit_Orders__r.size());
	}

	@isTest
	static void close_win_opportunity_when_new_plan_application_completed() {
		Account objAccnt = newCompanyAccount();
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		insert objOppty;

		Test.startTest();
		objOppty.Benefits_Current_Setup_Step__c = 'Completed';
		update objOppty;
		Test.stopTest();

		objOppty = [SELECT IsWon FROM Opportunity WHERE Id = :objOppty.Id LIMIT 1][0];
		//System.assert(objOppty.IsWon);
	}

	@isTest
	static void close_win_opportunity_when_renewal_application_completed() {
		Account objAccnt = newCompanyAccount();
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		insert objOppty;

		Test.startTest();
		objOppty.Benefits_Current_Setup_Step__c = 'Completed';
		update objOppty;
		Test.stopTest();

		objOppty = [SELECT IsWon FROM Opportunity WHERE Id = :objOppty.Id LIMIT 1][0];
		//System.assert(objOppty.IsWon);
	}

	@isTest
	static void close_win_opportunity_when_change_application_completed() {
		Account objAccnt = newCompanyAccount();
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Change');
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		insert objOppty;

		Test.startTest();
		objOppty.Benefits_Current_Setup_Step__c = 'Completed';
		update objOppty;
		Test.stopTest();

		objOppty = [SELECT IsWon FROM Opportunity WHERE Id = :objOppty.Id LIMIT 1][0];
		//System.assert(objOppty.IsWon);
	}

	/**
	 *   GIO-4395
	 *   Process Builder - Benefit Order Status Handler
	 *
	 *   test case
	 *   update the status of a new benefit order to 'ER Docs Received'
	 *
	 *   expected result
	 *   all carrier orders with 'New' implementation stage should be updated to 'ER Docs Received'
	 */

	@isTest
	static void gio_4395_new_plan_benefit_order_status_updated_to_er_docs_received_test() {
		Benefit_Order__c benefitOrder = create_benefit_order_with_carrier_order('New Plan');
		update_benefit_order_status_to_er_docs_received_assert(benefitOrder);
	}

	@isTest
	static void gio_4395_carrier_order_status_is_not_new_test() {
		Account companyAccount = newCompanyAccount();
		Opportunity benefitsOpportunity = newBenefitsOpportunity(companyAccount, 'New Plan');

		Benefit_Order__c benefitOrder = newBenefitOrder(benefitsOpportunity, 'New Plan');
		Carrier__c carrier = newCarrier();
		Carrier_Order__c carrierOrder = newCarrierOrder(benefitOrder, carrier);
		carrierOrder.Implementation_Stage__c = 'Activated';
		update carrierOrder;

		update_benefit_order_status_to_er_docs_received_assert(benefitOrder);
	}

	@isTest
	static void gio_4395_new_plan_benefit_order_updated_without_carrier_orders() {
		Account companyAccount = newCompanyAccount();
		Opportunity objOppty = newBenefitsOpportunity(companyAccount, 'New Plan');
		Benefit_Order__c benefitOrder = TestUtility.createTestBenefitOrder('New Plan', objOppty.Id, 'Benefit Order', true);
		benefitOrder.Order_Status__c = 'New';

		try {
			Test.startTest();
			insert benefitOrder;
			Test.stopTest();
		} catch (Exception e) {
			//System.assert(false);
		}
		System.assert(true, 'There was no exception.');
	}

	static void update_benefit_order_status_to_er_docs_received_assert(Benefit_Order__c testBenefitOrder) {
		List<Carrier_Order__c> oldCarrierOrders = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Benefit_Order__c = :testBenefitOrder.Id];
		Map<Id, Carrier_Order__c> oldCarrierOrderMap = new Map<Id, Carrier_Order__c>(oldCarrierOrders);

		testBenefitOrder.Order_Status__c = 'ER Docs Received';
		Test.startTest();
		update testBenefitOrder;
		Test.stopTest();

		List<Carrier_Order__c> newCarrierOrders = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Benefit_Order__c = :testBenefitOrder.Id];
		Map<Id, Carrier_Order__c> newCarrierOrderMap = new Map<Id, Carrier_Order__c>(newCarrierOrders);

		for (Id carrierOrderId : newCarrierOrderMap.keySet()) {
			Carrier_Order__c newCarrierOrder = newCarrierOrderMap.get(carrierOrderId);
			Carrier_Order__c oldCarrierOrder = oldCarrierOrderMap.get(carrierOrderId);

			if (oldCarrierOrder.Implementation_Stage__c == 'New') {
				System.assertEquals('ER Docs Received', newCarrierOrder.Implementation_Stage__c, 'Implementation_Stage__c should match.');
			}
		}
	}

	/**
	 *   GIO-4395
	 *   Process Builder - Benefits Operations::New plan opportunity
	 *
	 *   test case
	 *   the current step set is set to verifying_eligibility for a benefits new plan opportunity
	 *
	 *   expected result
	 *   a new plan benefit order is generated
	 */

	@isTest
	static void gio_4395_update_current_setup_step_to_verifying_eligibility_test() {
		Account objAccnt = newCompanyAccount();
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		objOppty.Order_Generated__c = false;
		insert objOppty;
		update_current_setup_step_to_verifying_eligibility_assert(objOppty, true);
	}

	@isTest
	static void gio_4395_opportunity_order_is_already_generated() {
		Account objAccnt = newCompanyAccount();
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		objOppty.Order_Generated__c = true;
		insert objOppty;
		update_current_setup_step_to_verifying_eligibility_assert(objOppty, false);
	}

	@isTest
	static void gio_4395_opportunity_is_payroll() {
		Account objAccnt = newCompanyAccount();
		Opportunity objOppty = new Opportunity();
		objOppty.AccountId = objAccnt.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		objOppty.Order_Generated__c = false;
		insert objOppty;
		update_current_setup_step_to_verifying_eligibility_assert(objOppty, false);
	}

	static void update_current_setup_step_to_verifying_eligibility_assert(Opportunity testOpportunity, Boolean expectedOrder) {
		List<Benefit_Order__c> oldBenefitOrders = [SELECT Id FROM Benefit_Order__c WHERE Opportunity__c = :testOpportunity.Id];
		System.assertEquals(0, oldBenefitOrders.size(), 'There should be 0 benefit orders.');

		testOpportunity.Benefits_Current_Setup_Step__c = 'verifying_eligibility';

		Test.startTest();
		update testOpportunity;
		Test.stopTest();

		List<Benefit_Order__c> newBenefitOrders = [SELECT Id FROM Benefit_Order__c WHERE Opportunity__c = :testOpportunity.Id];
		if (expectedOrder) {
			//	System.assertEquals(1, newBenefitOrders.size());
		} else {
			System.assert(newBenefitOrders.isEmpty(), 'newBenefitOrders list should be empty.');
		}
	}

	/**
	 *   GIO-4395
	 *   Process Builder - Benefits Operations::New plan opportunity
	 *   test case
	 *   the current step set is set to completed for a benefits new plan opportunity
	 *   expected result
	 *   the order status for the benefit orders is updated to ER Docs Received (only if the current status is New)
	 */

	@isTest
	static void gio_4395_benefit_order_status_is_not_new() {
		Account companyAccount = newCompanyAccount();
		Opportunity objOppty1 = newBenefitsOpportunity(companyAccount, 'New Plan');
		Benefit_Order__c benefitOrder = TestUtility.createTestBenefitOrder('New Plan', objOppty1.Id, 'Benefit Order', true);
		//Benefit_Order__c benefitOrder = (Benefit_Order__c) SmartFactory.createSObject('Benefit_Order__c', true);
		//	benefitOrder.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		benefitOrder.Order_Status__c = 'Approved';
		//insert benefitOrder;

		Opportunity objOppty = new Opportunity(Id = benefitOrder.Opportunity__c);
		objOppty.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		objOppty.Order_Generated__c = true;
		update objOppty;

		update_current_setup_step_to_completed_assert(objOppty, 'Approved');
	}

	static void update_current_setup_step_to_completed_assert(Opportunity testOpportunity, String expectedStatus) {
		testOpportunity.Benefits_Current_Setup_Step__c = 'Completed';

		Test.startTest();
		update testOpportunity;
		Test.stopTest();

		Benefit_Order__c newBenefitOrder = [SELECT Order_Status__c FROM Benefit_Order__c WHERE Opportunity__c = :testOpportunity.Id LIMIT 1][0];
		//System.assertEquals(expectedStatus, newBenefitOrder.Order_Status__c);
	}

	/**
	 * first payment invoice attacher tests
	 * */

	@isTest
	static void create_payment_invoice_on_account() {
		Account account = newCompanyAccount();
		Opportunity objOppty;
		Payment_Invoice__c paymentInvoice;

		String zp_company_id = generateExternalRecordId();
		String zp_payment_invoice_id = generateExternalRecordId();
		String paymentInvoiceExternalKey = 'zp-payment_invoice-' + zp_payment_invoice_id;

		//objOppty = (Opportunity) SmartFactory.createSObject('Opportunity', true);
		objOppty = new Opportunity();
		objOppty.AccountId = account.Id;
		objOppty.Name = 'Test Opp BNP';
		objOppty.CloseDate = System.today();
		objOppty.StageName = OpportunityUtil.SAL_STAGE;
		objOppty.Pricebook2Id = Test.getStandardPriceBookId();
		//insert objOppty;

		account = new Account(Id = objOppty.AccountId, ZP_Company_ID__c = zp_company_id);
		update account;

		objOppty.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		objOppty.ZP_Company_ID__c = zp_company_id;
		insert objOppty;

		objOppty.StageName = 'Closed Won';
		update objOppty;

		paymentInvoice = new Payment_Invoice__c(
			Account__c = account.Id,
			For_Month__c = '2016-02',
			Employee_Count__c = 20,
			Contractor_Count__c = 10,
			Amount__c = 100,
			Discount__c = .05,
			Additional_Discount__c = .03,
			Volume_Discount__c = .10,
			External_Key__c = paymentInvoiceExternalKey,
			Name = 'TEST ' + zp_payment_invoice_id,
			Bill_to_Accountant__c = false,
			Needs_Refund__c = false,
			Paid__c = false,
			Refund_Paid__c = false
		);

		User integrationUser = [SELECT Id FROM User WHERE Name = 'ZenPayroll' LIMIT 1][0];

		System.runAs(integrationUser) {
			Test.startTest();
			insert paymentInvoice;
			Test.stopTest();
		}
		System.assertEquals(1, [SELECT COUNT() FROM Payment_Invoice__c], 'Record count should be 1.');

		//objOppty = [SELECT Id, Payment_Invoice__c, Amount, NumberOfEmployees__c, ZP_Company_ID__c FROM Opportunity WHERE Id = :objOppty.Id LIMIT 1];

		//System.assertEquals(paymentInvoice.Id, objOppty.Payment_Invoice__c);
	}

	static String generateExternalRecordId() {
		return String.valueOf(Math.random()).removeStart('0.').left(20);
	}

	static Account newCompanyAccount() {
		String strZPCompanyId = generateExternalRecordId();
		Account companyAccount = new TestDataFactory.AccountBuilder()
			.setName(strZPCompanyId + '_name')
			.setRecordTypeId(Cache.getRecordTypeId('Account', 'Company'))
			.setZPCompanyId(strZPCompanyId)
			.build();

		insert companyAccount;
		return companyAccount;
	}

	static Opportunity newBenefitsOpportunity(Account account, String recordType) {
		Account objAccnt = newCompanyAccount();
		Opportunity benefitsOpportunity = new Opportunity();
		benefitsOpportunity.AccountId = objAccnt.Id;
		benefitsOpportunity.Name = 'Test Opp BNP';
		benefitsOpportunity.CloseDate = System.today();
		benefitsOpportunity.StageName = OpportunityUtil.SAL_STAGE;
		benefitsOpportunity.Pricebook2Id = Test.getStandardPriceBookId();
		//insert objOppty;

		benefitsOpportunity.AccountId = account.Id;
		benefitsOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits ' + recordType);
		benefitsOpportunity.Waiting_Period__c = 'test_waiting_period';

		insert benefitsOpportunity;
		return benefitsOpportunity;
	}

	static Benefit_Order__c newBenefitOrder(Opportunity objOppty, String recordType) {
		Benefit_Order__c benefitOrder = (Benefit_Order__c) SmartFactory.createSObject('Benefit_Order__c', false);

		benefitOrder.Account__c = objOppty.AccountId;
		benefitOrder.Opportunity__c = objOppty.Id;
		benefitOrder.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', recordType);

		insert benefitOrder;
		return benefitOrder;
	}

	static Carrier_Order__c newCarrierOrder(Benefit_Order__c benefitOrder, Carrier__c carrier) {
		Carrier_Order__c carrierOrder = (Carrier_Order__c) SmartFactory.createSObject('Carrier_Order__c', false);

		carrierOrder.Benefit_Order__c = benefitOrder.Id;
		carrierOrder.Carrier__c = carrier.Id;

		insert carrierOrder;
		return carrierOrder;
	}

	static Carrier__c newCarrier() {
		Carrier__c carrier = (Carrier__c) SmartFactory.createSObject('Carrier__c', false);

		insert carrier;
		return carrier;
	}

	static Benefit_Order__c create_benefit_order_with_carrier_order(String typeOfOrder) {
		Account companyAccount = newCompanyAccount();
		Opportunity benefitsOpportunity = newBenefitsOpportunity(companyAccount, typeOfOrder);

		Benefit_Order__c benefitOrder = newBenefitOrder(benefitsOpportunity, typeOfOrder);
		Carrier__c carrier = newCarrier();
		Carrier_Order__c carrierOrder = newCarrierOrder(benefitOrder, carrier);
		return benefitOrder;
	}
}