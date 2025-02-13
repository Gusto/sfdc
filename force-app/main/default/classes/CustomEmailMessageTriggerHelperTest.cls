@isTest
public class CustomEmailMessageTriggerHelperTest {
	@TestSetup
	static void setupData() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		List<Account> list_AccountsToInsert = new List<Account>();
		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('C2 Construction Services LLC')
			.setZPCompanyId('12121212121212')
			.setJoinedDate(System.today())
			.build();
		list_AccountsToInsert.add(objAccount1);
		insert list_AccountsToInsert;

		Opportunity opp1 = new Opportunity();
		opp1.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits BoR');
		opp1.Name = 'TEST OPPORTUNITY';
		opp1.StageName = 'STAGENAME';
		opp1.CloseDate = System.Today();
		opp1.AccountId = objAccount1.Id;
		insert opp1;

		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('Benefits BoR', opp1.Id, 'Test Benefit Order', false);
		benefitOrdr1.ownerID = UserInfo.getUserId();
		benefitOrdr1.Order_Status__c = 'Ready for Qualification';
		benefitOrdr1.Account__c = objAccount1.Id;
		insert benefitOrdr1;

		Carrier__c testCarrier = TestUtility.Carrier();
		Carrier_Order__c carOrder = TestUtility.createTestCarrierOrder(testCarrier.Id, 'Test Benefit Order', benefitOrdr1.Id, false);
		carOrder.Implementation_Stage__c = 'Ready for Qualification';
		carOrder.Group_Number__c = 'BIZ00059877';
		carOrder.RecordTypeId = cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		insert carOrder;

		List<Case> list_CasesToInsert = new List<Case>();
		Case objCase1 = new Case();
		objCase1.Subject = 'SECURE C2 Construction Services LLC Application Has Been Approved';
		objCase1.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		objCase1.Description = 'Test';
		objCase1.Type = 'Benefits New Plan';
		objCase1.AccountId = list_AccountsToInsert.get(0).Id;
		list_CasesToInsert.add(objCase1);
		//Benefits BoR Case
		Case objCase2 = new Case();
		objCase2.Subject = 'Attn: Oscar Health - BoR Letter for C2 Construction Services LLC BIZ00059877';
		objCase2.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
		objCase2.Description = 'Test';
		objCase2.Type = 'Benefits BOR Carrier Case';
		objCase2.Origin = 'Email';
		objCase2.Direction__c = 'Inbound';
		list_CasesToInsert.add(objCase2);
		insert list_CasesToInsert;
	}

	@isTest
	static void testEmailWithoutCase() {
		List<Email_Message__c> list_EmailMessagesToInsert = new List<Email_Message__c>();

		test.startTest();
		Email_Message__c objEmailMessage = new Email_Message__c();
		objEmailMessage.Subject__c = 'SECURE C2 Construction Services LLC Application Has Been Approved';
		objEmailMessage.From_Addresses__c = 'agent.support@anthem.com';
		objEmailMessage.To_Addresses__c = 'newplans@gusto.com';
		objEmailMessage.Possible_Match__c = 'C2 Construction Services LLC';
		objEmailMessage.Ignore_from_Search__c = false;
		objEmailMessage.Message_Identifier__c = 'test';
		list_EmailMessagesToInsert.add(objEmailMessage);
		CustomEmailMessageTriggerHelper.blnIsCarrierOpsEmail = true;
		insert list_EmailMessagesToInsert;

		test.stopTest();
	}

	@isTest
	static void testEmailWithCase() {
		List<Case> list_GetCases = new List<Case>();
		list_GetCases = [SELECT ID FROM Case WHERE Type = 'Benefits New Plan' LIMIT 1];

		List<Email_Message__c> list_EmailMessagesToInsert = new List<Email_Message__c>();
		Email_Message__c objEmailMessage = new Email_Message__c();
		objEmailMessage.Subject__c = 'SECURE C2 Construction Services LLC Application Has Been Approved';
		objEmailMessage.From_Addresses__c = 'agent.support@anthem.com';
		objEmailMessage.To_Addresses__c = 'newplans@gusto.com';
		objEmailMessage.Possible_Match__c = 'C2 Construction Services LLC';
		objEmailMessage.Ignore_from_Search__c = false;
		objEmailMessage.Parent_Case__c = list_GetCases.get(0).Id;
		list_EmailMessagesToInsert.add(objEmailMessage);
		insert list_EmailMessagesToInsert;

		test.startTest();
		Email_Message__c objEmailMessage2 = new Email_Message__c();
		objEmailMessage2.Subject__c = 'SECURE C2 Construction Services LLC Application Has Been Approved';
		objEmailMessage2.From_Addresses__c = 'agent.support@anthem.com';
		objEmailMessage2.To_Addresses__c = 'newplans@gusto.com';
		objEmailMessage2.Possible_Match__c = 'C2 Construction Services LLC';
		objEmailMessage2.Ignore_from_Search__c = false;
		objEmailMessage2.Parent_Case__c = list_GetCases.get(0).Id;
		insert objEmailMessage2;

		test.stopTest();
	}
	@isTest
	static void testBoREmailWithCase() {
		List<Case> list_GetCases = new List<Case>();
		list_GetCases = [SELECT ID FROM Case WHERE Type = 'Benefits BOR Carrier Case' LIMIT 1];
		List<Email_Message__c> list_EmailMessagesToInsert = new List<Email_Message__c>();
		test.startTest();
		Email_Message__c objEmailMessage = new Email_Message__c();
		objEmailMessage.Subject__c = 'Attn: Oscar Health - BoR Letter for C2 Construction Services LLC BIZ00059877';
		objEmailMessage.From_Addresses__c = 'agent.support@anthem.com';
		objEmailMessage.To_Addresses__c = 'bor-transfer@gusto.com';
		objEmailMessage.To_Address__c = 'bor-transfer@gusto.com';
		objEmailMessage.Possible_Match__c = 'C2 Construction Services LLC';
		objEmailMessage.Possible_Group_Number__c = 'BIZ00059877';
		objEmailMessage.Ignore_from_Search__c = false;
		objEmailMessage.Parent_Case__c = list_GetCases.get(0).Id;
		list_EmailMessagesToInsert.add(objEmailMessage);
		insert list_EmailMessagesToInsert;
		test.stopTest();
	}
	@isTest
	static void testBoREmailWithOutGroupNumberCase() {
		List<Case> list_GetCases = new List<Case>();
		list_GetCases = [SELECT ID FROM Case WHERE Type = 'Benefits BOR Carrier Case' LIMIT 1];
		List<Email_Message__c> list_EmailMessagesToInsert = new List<Email_Message__c>();
		test.startTest();
		Email_Message__c objEmailMessage = new Email_Message__c();
		objEmailMessage.Subject__c = 'Attn: Oscar Health - BoR Letter for C2 Construction Services LLC BIZ00059877';
		objEmailMessage.From_Addresses__c = 'agent.support@anthem.com';
		objEmailMessage.To_Addresses__c = 'bor-transfer@gusto.com';
		objEmailMessage.To_Address__c = 'bor-transfer@gusto.com';
		objEmailMessage.Ignore_from_Search__c = false;
		objEmailMessage.Parent_Case__c = list_GetCases.get(0).Id;
		list_EmailMessagesToInsert.add(objEmailMessage);
		insert list_EmailMessagesToInsert;
		test.stopTest();
	}
	@isTest
	static void testBoREmailNotMaatchedGroupNumberCase() {
		List<Case> list_GetCases = new List<Case>();
		list_GetCases = [SELECT ID FROM Case WHERE Type = 'Benefits BOR Carrier Case' LIMIT 1];
		List<Email_Message__c> list_EmailMessagesToInsert = new List<Email_Message__c>();
		test.startTest();
		Email_Message__c objEmailMessage = new Email_Message__c();
		objEmailMessage.Subject__c = 'Attn: Oscar Health - BoR Letter for C2 Construction Services LLC BIZ00059877';
		objEmailMessage.From_Addresses__c = 'agent.support@anthem.com';
		objEmailMessage.To_Addresses__c = 'bor-transfer@gusto.com';
		objEmailMessage.To_Address__c = 'bor-transfer@gusto.com';
		objEmailMessage.Ignore_from_Search__c = false;
		objEmailMessage.Possible_Group_Number__c = 'BIZ';
		objEmailMessage.Parent_Case__c = list_GetCases.get(0).Id;
		list_EmailMessagesToInsert.add(objEmailMessage);
		insert list_EmailMessagesToInsert;
		test.stopTest();
	}
}