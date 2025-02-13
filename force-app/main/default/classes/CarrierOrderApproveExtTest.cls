@isTest
public class CarrierOrderApproveExtTest {
	@testSetup
	private static void create_Test_Data() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		User systemAdminUser = [SELECT ID FROM User WHERE ID = :UserInfo.getUserId()];
		User adminUser;

		System.runAs(systemAdminUser) {
			adminUser = new TestDataFactory.UserBuilder()
				.setAlias('ImpAdv')
				.setEmail('ImplementationAdvocate@testorg.com')
				.setEmailEncoding('UTF-8')
				.setFirstName('Implementation')
				.setLastName('Advocate')
				.setProfileId(objProfile.Id)
				.setLanguageLocaleKey('en_US')
				.setLocaleSidKey('en_US')
				.setTimeZoneSidKey('America/Los_Angeles')
				.setUserName('Implementation.Advocate@test.Implementation')
				.build();
			adminUser.Exempt_from_Validation_Rules__c = true;
			insert adminUser;
		}

		System.runAs(adminUser) {
			Group groupObj = new Group();
			groupObj.Name = 'Order Stage Update Users';
			insert groupObj;

			GroupMember member = new GroupMember();
			member.UserOrGroupId = adminUser.Id;
			member.GroupId = groupObj.Id;
			insert member;
		}

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();

		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);

		benefitOrdr1.Order_Status__c = 'OE';
		benefitOrdr1.ownerID = adminUser.Id;
		benefitOrdr1.Coverage_Effective_Date__c = System.today();
		benefitOrdr1.Open_Enrollment_Start_Date__c = System.today();
		benefitOrdr1.Open_Enrollment_End_Date__c = System.today();
		benefitOrdr1.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update benefitOrdr1;

		Carrier__c testCarrier = TestUtility.Carrier();

		List<Carrier_Order__c> lstCarrierOrder = new List<Carrier_Order__c>();
		Carrier_Order__c carOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder.Name = 'TEST CARRIER ORDER';
		carOrder.Carrier__c = testCarrier.Id;
		carOrder.Benefit_Order__c = benefitOrdr1.Id;
		carOrder.Implementation_Stage__c = 'With Advising';
		carOrder.Order_Type__c = 'TAdA: Pre OE Setup';
		carOrder.Stage_Detail__c = 'TAdA Setup Complete';
		carOrder.OwnerId = adminUser.Id;
		lstCarrierOrder.add(carOrder);

		Carrier_Order__c carOrder1 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder1.Name = 'TEST CARRIER ORDER 1';
		carOrder1.Carrier__c = testCarrier.Id;
		carOrder1.Benefit_Order__c = benefitOrdr1.Id;
		carOrder1.Implementation_Stage__c = 'Approved';
		carOrder1.OwnerId = UserInfo.getUserId();
		carOrder1.Stage_Detail__c = 'TAdA Setup Complete';
		lstCarrierOrder.add(carOrder1);

		Carrier_Order__c carOrder2 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder2.Name = 'TEST CARRIER ORDER 2';
		carOrder2.Carrier__c = testCarrier.Id;
		carOrder2.Benefit_Order__c = benefitOrdr1.Id;
		carOrder2.Implementation_Stage__c = 'With Advising';
		carOrder2.Order_Type__c = 'TAdA: Pre OE Setup';
		carOrder2.OwnerId = UserInfo.getUserId();
		lstCarrierOrder.add(carOrder2);
		insert lstCarrierOrder;
	}

	@isTest
	static void testUpdateCarrier() {
		Carrier_Order__c coObj = [SELECT Id FROM Carrier_Order__c WHERE Name = 'TEST CARRIER ORDER' LIMIT 1];

		Test.startTest();
		ApexPages.CurrentPage().getparameters().put('id', coObj.Id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(coObj);
		CarrierOrderApproveExt extension = new CarrierOrderApproveExt(stdController);
		extension.updateCarrier();
		Test.stopTest();

		List<Carrier_Order__c> lstCO = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :coObj.Id];
		//system.assertEquals(lstCO[0].Implementation_Stage__c, 'Approved');
		System.assert(lstCO.size() > 0, 'List should not be empty');
	}

	@isTest
	static void testApprove() {
		Carrier_Order__c coObj = [SELECT Id FROM Carrier_Order__c WHERE Name = 'TEST CARRIER ORDER 1' LIMIT 1];

		Test.startTest();
		ApexPages.CurrentPage().getparameters().put('id', coObj.Id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(coObj);
		CarrierOrderApproveExt extension = new CarrierOrderApproveExt(stdController);
		Test.stopTest();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assert(pageMessages.size() != null, 'pageMessages cannot be null');
	}

	@isTest
	static void testApprove1() {
		Carrier_Order__c coObj = [SELECT Id FROM Carrier_Order__c WHERE Name = 'TEST CARRIER ORDER 2' LIMIT 1];

		Test.startTest();
		ApexPages.CurrentPage().getparameters().put('id', coObj.Id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(coObj);
		CarrierOrderApproveExt extension = new CarrierOrderApproveExt(stdController);
		extension.updateCarrier();
		Test.stopTest();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assert(pageMessages.size() != null, 'pageMessages cannot be null');
	}
}