@isTest
public class UnblockBenefitOrderExtTest {
	static final String OPP_STAGE_NAME = 'SAL';
	static final Id ID_LOGGED_USER = UserInfo.getUserId();
	static final Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
	static final Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
	static final Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

	@TestSetup
	static void makeData() {
		skipTriggers();

		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		User objUser = new User();
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		objUser.Username = 'test1239@gm.com';
		objUser.LastName = 'test';
		objUser.Email = 'test1239@gm.com';
		objUser.Alias = 'boalias';
		objUser.CommunityNickname = 'boalias';
		objUser.TimeZoneSidKey = 'America/Denver';
		objUser.LocaleSidKey = 'en_US';
		objUser.EmailEncodingKey = 'ISO-8859-1';
		objUser.LanguageLocaleKey = 'en_US';
		objUser.FederationIdentifier = 'test@gm.com';
		objUser.ProfileId = objProfile.Id;
		objUser.IsActive = false;
		insert objUser;

		Carrier__c objCarrier = TestUtility.Carrier();
		Carrier__c objCarrier1 = TestUtility.Carrier();

		// New Plan Record
		Account objCompanyAccount = TestUtility.createAccount(false, null, '100989005');
		Opportunity objNewPlanOpp = TestUtility.createOpp(
			OPP_RT_BENEFITS_NEW_PLAN,
			objCompanyAccount.Id,
			OPP_STAGE_NAME
		);

		Benefit_Order__c objNewPlanBO = TestUtility.createBenefitOrder(objNewPlanOpp.Id, BO_RT_NEW_PLAN, false, null);
		objNewPlanBO.Order_Status__c = BenefitOrderUtil.STATUS_BLOCKED;
		objNewPlanBO.Blocked_Reason__c = 'Carrier Delay';
		update objNewPlanBO;

		Carrier_Order__c objNewPlanCarrierOrder = TestUtility.createCarrierOrder(
			objNewPlanBO.Id,
			objCarrier.Id,
			CO_RT_NEW_PLAN,
			false,
			null
		);
		Carrier_Order__c objNewPlanCarrierOrder1 = TestUtility.createCarrierOrder(
			objNewPlanBO.Id,
			objCarrier1.Id,
			CO_RT_NEW_PLAN,
			false,
			null
		);

		objNewPlanCarrierOrder.Implementation_Stage__c = 'Ready for Qualification';
		objNewPlanCarrierOrder.Name = 'Qualification Record 1';
		list_CarrierOrders.add(objNewPlanCarrierOrder);

		objNewPlanCarrierOrder1.Implementation_Stage__c = 'Ready for Qualification';
		objNewPlanCarrierOrder1.Name = 'Qualification Record 1';
		list_CarrierOrders.add(objNewPlanCarrierOrder1);


		Opportunity objNewPlanOpp1 = TestUtility.createOpp(
			OPP_RT_BENEFITS_NEW_PLAN,
			objCompanyAccount.Id,
			OPP_STAGE_NAME
		);

		Benefit_Order__c objNewPlanBO1 = TestUtility.createBenefitOrder(
			objNewPlanOpp1.Id,
			BO_RT_NEW_PLAN,
			false,
			null
		);
		objNewPlanBO1.Order_Status__c = 'Ready For Qualification';
		update objNewPlanBO1;

		Opportunity objNewPlanOpp2 = TestUtility.createOpp(
			OPP_RT_BENEFITS_NEW_PLAN,
			objCompanyAccount.Id,
			OPP_STAGE_NAME
		);

		Benefit_Order__c objNewPlanBO2 = TestUtility.createBenefitOrder(
			objNewPlanOpp2.Id,
			BO_RT_NEW_PLAN,
			false,
			null
		);
		objNewPlanBO2.Order_Status__c = 'Blocked';
		objNewPlanBO2.Blocked_Reason__c = 'Benefit Advisor Escalation';
		objNewPlanBO2.OwnerId = objUser.Id;
		update objNewPlanBO2;

        Opportunity objNewPlanOpp3 = TestUtility.createOpp(
			OPP_RT_BENEFITS_NEW_PLAN,
			objCompanyAccount.Id,
			OPP_STAGE_NAME
		);

		Benefit_Order__c objNewPlanBO3 = TestUtility.createBenefitOrder(objNewPlanOpp3.Id, BO_RT_NEW_PLAN, false, null);
		objNewPlanBO3.Order_Status__c = BenefitOrderUtil.STATUS_BLOCKED;
		objNewPlanBO3.Blocked_Reason__c = 'COps Escalation';
		update objNewPlanBO3;

        Carrier_Order__c objNewPlanCarrierOrder2 = TestUtility.createCarrierOrder(
			objNewPlanBO3.Id,
			objCarrier.Id,
			CO_RT_NEW_PLAN,
			false,
			null
		);
		Carrier_Order__c objNewPlanCarrierOrder3 = TestUtility.createCarrierOrder(
			objNewPlanBO3.Id,
			objCarrier1.Id,
			CO_RT_NEW_PLAN,
			false,
			null
		);

		objNewPlanCarrierOrder2.Implementation_Stage__c = BenefitOrderUtil.STATUS_BLOCKED;
		objNewPlanCarrierOrder2.Name = 'Qualification Record 2';
		list_CarrierOrders.add(objNewPlanCarrierOrder2);

		objNewPlanCarrierOrder3.Implementation_Stage__c = 'Ready for Qualification';
		objNewPlanCarrierOrder3.Name = 'Qualification Record 3';
		list_CarrierOrders.add(objNewPlanCarrierOrder3);

		update list_CarrierOrders;

	}

	static testMethod void testUnblockedFunctionality() {
		Test.startTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE Blocked_Reason__c = 'Carrier Delay' LIMIT 1];

		ApexPages.StandardController objBOStandardController = new ApexPages.StandardController(objBO);
		UnblockBenefitOrderExt objUnblockBOExtension = new UnblockBenefitOrderExt(objBOStandardController);
		objUnblockBOExtension.unblockBenefitOrder();

		Test.stopTest();

		objBO = [SELECT id, Order_Status__c FROM Benefit_Order__c WHERE Id = :objBO.Id LIMIT 1];
		System.assertNotEquals(BenefitOrderUtil.STATUS_BLOCKED, objBO.Order_Status__c);
	}

    static testMethod void testUnblockedFunctionalityWithAlreadyCOBlocked() {
		Test.startTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE Blocked_Reason__c = 'COps Escalation' LIMIT 1];

		ApexPages.StandardController objBOStandardController = new ApexPages.StandardController(objBO);
		UnblockBenefitOrderExt objUnblockBOExtension = new UnblockBenefitOrderExt(objBOStandardController);

		Test.stopTest();

        objBO = [SELECT id, Order_Status__c FROM Benefit_Order__c WHERE Id = :objBO.Id LIMIT 1];
		System.assertEquals(BenefitOrderUtil.STATUS_BLOCKED, objBO.Order_Status__c);
		System.assertEquals(objUnblockBOExtension.blnUnBlockPermissionError, true);
	}

	static testMethod void testUnblockedFunctionalityInValidOrderStatus() {
		Test.startTest();

		Benefit_Order__c objBO = [
			SELECT Id
			FROM Benefit_Order__c
			WHERE Order_Status__c = 'Ready for Qualification'
			LIMIT 1
		];

		ApexPages.StandardController objBOStandardController = new ApexPages.StandardController(objBO);
		UnblockBenefitOrderExt objUnblockBOExtension = new UnblockBenefitOrderExt(objBOStandardController);

		Test.stopTest();

		System.assertEquals(objUnblockBOExtension.blnUnBlockPermissionError, true);
	}

	static testMethod void testUnblockedFunctionalityInValidUser() {
		Test.startTest();

		Benefit_Order__c objBO = [
			SELECT Id
			FROM Benefit_Order__c
			WHERE Blocked_Reason__c = 'Benefit Advisor Escalation'
			LIMIT 1
		];

		ApexPages.StandardController objBOStandardController = new ApexPages.StandardController(objBO);
		UnblockBenefitOrderExt objUnblockBOExtension = new UnblockBenefitOrderExt(objBOStandardController);
		objUnblockBOExtension.cancel();

		Test.stopTest();

		System.assertEquals(objUnblockBOExtension.blnUnBlockPermissionError, true);
	}

	static void skipTriggers() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
	}
}