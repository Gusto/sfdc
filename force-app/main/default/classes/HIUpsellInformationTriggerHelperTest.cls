@isTest
public class HIUpsellInformationTriggerHelperTest {
	@TestSetup
	static void createTestData() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setActiveTadaProvider('alegeus').build();
		insert objConfigSettings;
		Utils.skipTrigger(true);
		List<Account> list_objAccount = new List<Account>();

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_TYPE).setZPCompanyId('company321').setName('Gusto HINewPlanApplication Test').build();

		list_objAccount.add(objAccount);

		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_TYPE).setZPCompanyId('company32101').setName('Gusto HINewPlanApplication Test1').build();

		list_objAccount.add(objAccount1);

		Account objAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_TYPE).setZPCompanyId('company3210').setName('Gusto HINewPlanApplication Test2').build();

		list_objAccount.add(objAccount2);

		insert list_objAccount;

		State__c objState = new TestDataFactory.StateBuilder().setAbbreviation('CA').setName('Test State').build();

		insert objState;
		Carrier__c objCarrierRec4 = new TestDataFactory.CarrierBuilder().setName('alegeus').setKey('alegeus').setId('alegeus123').setPartnerType('TAdA').build();
		insert objCarrierRec4;

		//Create Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.id)
			.setLastName('test last name')
			.setZPUserId('9872')
			.build();

		insert objContact;

		List<Opportunity> list_ObjOpp = new List<Opportunity>();

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
			.setAccountId(objAccount1.Id)
			.setName('Test Opportuntiy')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setType(HIUpsellInformationUtil.UPSELL_TYPE_NEW_TADA)
			.setCloseDate(System.today())
			.setSourceID('7654')
			.setAssignmentState('California')
			.build();

		list_ObjOpp.add(objOpp);

		Opportunity objOpp1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
			.setAccountId(objAccount1.Id)
			.setName('Test Opportuntiy')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setType(HIUpsellInformationUtil.UPSELL_TYPE_TRANSFER_TADA)
			.setCloseDate(System.today())
			.setSourceID('765465')
			.setAssignmentState('California')
			.build();

		list_ObjOpp.add(objOpp1);

		Opportunity objOpp2 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
			.setAccountId(objAccount1.Id)
			.setName('Test Opportuntiy')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setType(HIUpsellInformationUtil.UPSELL_TYPE_TRANSFER_TADA)
			.setCloseDate(System.today())
			.setSourceID('7654658')
			.setAssignmentState('California')
			.build();

		list_ObjOpp.add(objOpp2);
		insert list_ObjOpp;
		Policy__c objPolicy = new TestDataFactory.PolicyBuilder().setName('Test Policy').setIdOpprtunity(objOpp.Id).setIdCarrier(objCarrierRec4.Id).setIsSelected(true).build();
		insert objPolicy;
	}

	@isTest
	static void HIUpsellInformationCreateTest() {
		Test.startTest();
		Utils.skipTrigger(true);
		HIUpsellInformationTriggerHelper.queue = true;
		List<HI_Upsell_Information__c> list_objUpsellInfo = new List<HI_Upsell_Information__c>();

		HI_Upsell_Information__c objUpsellInfo = new TestDataFactory.HIUpsellInformationBuilder()
			.setBenefitType(HIUpsellInformationUtil.STR_COMMUTER)
			.setCompanyId('company321')
			.setExternalKey('4567')
			.setId('4567')
			.setMode(HIUpsellInformationUtil.STR_MODE_NORMAL)
			.setType(HIUpsellInformationUtil.STR_NEW_BENEFIT)
			.setUserId('9872')
			.build();

		list_objUpsellInfo.add(objUpsellInfo);

		HI_Upsell_Information__c objUpsellInfo1 = new TestDataFactory.HIUpsellInformationBuilder()
			.setBenefitType(HIUpsellInformationUtil.STR_HSA)
			.setCompanyId('company3210')
			.setExternalKey('76546')
			.setId('98728')
			.setMode(HIUpsellInformationUtil.STR_MODE_NORMAL)
			.setType(HIUpsellInformationUtil.STR_TRANSFER_BENEFIT)
			.setUserId('98728')
			.build();

		list_objUpsellInfo.add(objUpsellInfo1);
		insert list_objUpsellInfo;

		Opportunity objOppty = [SELECT Id, Type FROM Opportunity WHERE Source_ID__c = :objUpsellInfo.External_Key__c LIMIT 1];

		System.assertNotEquals(null, objOppty.Id, 'Opportunity Should be created');
		System.assertEquals(HIUpsellInformationUtil.UPSELL_TYPE_NEW_TADA, objOppty.Type, 'Opportunity Type Should be New TAdA Plan');

		Opportunity objOppty1 = [SELECT Id, Type FROM Opportunity WHERE Source_ID__c = :objUpsellInfo1.External_Key__c LIMIT 1];

		System.assertNotEquals(null, objOppty1.Id, 'Opportunity Should be created');
		System.assertEquals(HIUpsellInformationUtil.UPSELL_TYPE_TRANSFER_TADA, objOppty1.Type, 'Opportunity Type Should be Transfer TAdA Plan');

		Test.stopTest();
	}

	@isTest
	static void HIUpsellInformationUpdateTest() {
		Test.startTest();
		Utils.skipTrigger(true);
		HIUpsellInformationTriggerHelper.queue = true;

		HI_Upsell_Information__c objUpsellInfo = new TestDataFactory.HIUpsellInformationBuilder()
			.setBenefitType(HIUpsellInformationUtil.STR_HSA)
			.setCompanyId('company32101')
			.setExternalKey('7654')
			.setId('9872')
			.setMode(HIUpsellInformationUtil.STR_MODE_NORMAL)
			.setType(HIUpsellInformationUtil.STR_NEW_BENEFIT)
			.setUserId('9872')
			.build();

		insert objUpsellInfo;

		Opportunity objOppty = [SELECT Id, Type, Benefits_Notes__c FROM Opportunity WHERE Source_ID__c = :objUpsellInfo.External_Key__c LIMIT 1];
		System.assertEquals(HIUpsellInformationUtil.UPSELL_TYPE_NEW_TADA, objOppty.Type, 'Opportunity Type Should be New TAdA Plan');
		System.assertEquals(null, objOppty.Benefits_Notes__c, 'Benefits Notes Should be blank since oppty already exists');

		objUpsellInfo.Benefit_Type__c = HIUpsellInformationUtil.STR_COMMUTER;
		update objUpsellInfo;

		Opportunity objOppty1 = [SELECT Id, Type, Benefits_Notes__c FROM Opportunity WHERE Source_ID__c = :objUpsellInfo.External_Key__c LIMIT 1];
		System.assertNotEquals(null, objOppty1.Benefits_Notes__c, 'Benefits Notes Should be updated');
		Test.stopTest();
	}

	@isTest
	static void HIUpsellInformationUpdateTestTransfer() {
		Test.startTest();
		Utils.skipTrigger(true);
		HIUpsellInformationTriggerHelper.queue = true;

		HI_Upsell_Information__c objUpsellInfo = new TestDataFactory.HIUpsellInformationBuilder()
			.setBenefitType(HIUpsellInformationUtil.STR_HSA)
			.setCompanyId('company32101')
			.setExternalKey('7654658')
			.setId('9872')
			.setMode(HIUpsellInformationUtil.STR_MODE_NORMAL)
			.setType(HIUpsellInformationUtil.STR_TRANSFER_BENEFIT)
			.setUserId('9872')
			.build();

		insert objUpsellInfo;

		Opportunity objOppty = [SELECT Id, Type, Benefits_Notes__c FROM Opportunity WHERE Source_ID__c = :objUpsellInfo.External_Key__c LIMIT 1];
		System.assertEquals(HIUpsellInformationUtil.UPSELL_TYPE_TRANSFER_TADA, objOppty.Type, 'Opportunity Type Should be New TAdA Plan');
		System.assertEquals(null, objOppty.Benefits_Notes__c, 'Benefits Notes Should be blank since oppty already exists');

		objUpsellInfo.Benefit_Type__c = HIUpsellInformationUtil.STR_COMMUTER;
		update objUpsellInfo;

		Opportunity objOppty1 = [SELECT Id, Type, Benefits_Notes__c FROM Opportunity WHERE Source_ID__c = :objUpsellInfo.External_Key__c LIMIT 1];
		System.assertNotEquals(null, objOppty1.Benefits_Notes__c, 'Benefits Notes Should be updated');
		Test.stopTest();
	}

	@isTest
	static void HIUpsellInformationUpdateTestClosedOpp() {
		Test.startTest();
		Utils.skipTrigger(true);
		HIUpsellInformationTriggerHelper.queue = true;

		Opportunity objOpptyTest = [SELECT Id, Source_ID__c, StageName FROM Opportunity WHERE Source_ID__c = '765465'];
		objOpptyTest.StageName = OpportunityUtil.CLOSED_WON_STAGE;

		update objOpptyTest;

		HI_Upsell_Information__c objUpsellInfo = new TestDataFactory.HIUpsellInformationBuilder()
			.setBenefitType(HIUpsellInformationUtil.STR_HSA)
			.setCompanyId('company32101')
			.setExternalKey('765465')
			.setId('9872')
			.setMode(HIUpsellInformationUtil.STR_MODE_NORMAL)
			.setType(HIUpsellInformationUtil.UPSELL_TYPE_TRANSFER_TADA)
			.setUserId('9872')
			.build();

		insert objUpsellInfo;

		objUpsellInfo.Benefit_Type__c = HIUpsellInformationUtil.STR_COMMUTER;
		update objUpsellInfo;

		Opportunity objOppty1 = [SELECT Id, Type, Benefits_Notes__c FROM Opportunity WHERE Source_ID__c = :objUpsellInfo.External_Key__c LIMIT 1];
		System.assertEquals(null, objOppty1.Benefits_Notes__c, 'Benefits Notes Should not be updated');

		Test.stopTest();
	}

	@isTest
	static void SkipTriggerTest() {
		Test.startTest();
		Utils.skipTrigger(true);
		HIUpsellInformationTriggerHelper.skipTrigger = true;

		HI_Upsell_Information__c objUpsellInfo = new TestDataFactory.HIUpsellInformationBuilder()
			.setBenefitType(HIUpsellInformationUtil.STR_COMMUTER)
			.setCompanyId('company321')
			.setExternalKey('4567')
			.setId('4567')
			.setMode(HIUpsellInformationUtil.STR_MODE_NORMAL)
			.setType(HIUpsellInformationUtil.STR_NEW_BENEFIT)
			.setUserId('9872')
			.build();

		insert objUpsellInfo;

		List<Opportunity> list_opptyObj = [SELECT Id, Type FROM Opportunity WHERE Source_ID__c = :objUpsellInfo.External_Key__c LIMIT 1];

		System.assertEquals(0, list_opptyObj.size(), 'Opportunity Should not be created');

		Test.stopTest();
	}
}