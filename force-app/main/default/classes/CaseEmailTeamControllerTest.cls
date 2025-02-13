/*
 * Description: Test Class for CaseEmailTeamController
 * Author: Omar Benitez
 * Date: 04/22/2024
 */
@isTest
public class CaseEmailTeamControllerTest {
	@testSetup
	static void setUp() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		Account objAcc = TestUtility.CompanyAccount();

		Carrier__c objCar = new Carrier__c();
		objCar.Name = 'Test Carrier 1';
		objCar.New_Plan_Email_List__c = 'my new plan::test@test.com';
		objCar.BOR_Transfer_Email_List__c = 'my BOR::test@test.com';
		objCar.Renewal_Email_List__c = 'Test::test@test.com';
		objCar.Submission_Email__c = 'test@test.com';
		insert objCar;

		Opportunity objOpp = TestUtility.BenefitsRenewalOpportunity();

		Benefit_Order__c objBenefitOrdr1 = TestUtility.createTestBenefitOrder('Renewal', objOpp.Id, 'Test Benefit Order', true);
		Carrier_Order__c objCarrierOrder1 = TestUtility.createTestCarrierOrder(objCar.Id, 'Test Carrier Order', objBenefitOrdr1.Id, true);

		Policy__c objPolicy = new Policy__c();
		objPolicy.Carrier__c = objCar.Id;
		objPolicy.Opportunity__c = objOpp.id;
		objPolicy.Is_Selected__c = true;
		insert objPolicy;
		Contact objContact = TestUtility.createTestContact(objAcc.Id, ContactUtil.COMPANY_CONTACT_RT_ID);

		Case objCse = new Case();
		objCse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Renewal Case');
		objCse.AccountId = objAcc.Id;
		objCse.Subject = 'Test Case 1';
		objCse.Description = 'Test';
		objCse.Type = 'QLE';
		objCse.Opportunity__c = objOpp.id;
		objCse.Carrier_Order__c = objCarrierOrder1.Id;
		objCse.ContactId = objContact.Id;
		CaseTriggerHelper.skipTrigger = true;
		insert objCse;
		//BoR
		Opportunity objOppBoR = TestUtility.BenefitsBoROpportunity();
		Benefit_Order__c objBOBoR = TestUtility.createTestBenefitOrder('Benefits BoR', objOppBoR.Id, 'Test BO ', true);
		Carrier_Order__c objCarrierOrderBoR = TestUtility.createTestCarrierOrder(objCar.Id, 'Test CO BoR', objBOBoR.Id, true);
		Policy__c objPolicyBoR = new Policy__c();
		objPolicyBoR.Carrier__c = objCar.Id;
		objPolicyBoR.Opportunity__c = objOppBoR.id;
		objPolicyBoR.Is_Selected__c = true;
		insert objPolicyBoR;
		Case objCseBor = new Case();
		objCseBor.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
		objCseBor.AccountId = objAcc.Id;
		objCseBor.Subject = 'Test Case BoR';
		objCseBor.Description = 'Test';
		objCseBor.Type = 'QLE';
		objCseBor.Opportunity__c = objOppBoR.id;
		objCseBor.Carrier_Order__c = objCarrierOrderBoR.Id;
		CaseTriggerHelper.skipTrigger = true;
		insert objCseBor;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAcc.Id)
			.setRecordTypeId('MF QLE')
			.setType('QLE')
			.setSubject('Test  MF QLE  Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test MF QLE Case')
			.setIdCarrier(objCar.Id)
			.setContactId(objContact.Id)
            .setAnticipatedEffectiveDate(System.today())
			.build();
        objCase.QLE_Event_Type__c = 'Relocation';
		insert objCase;
	}
	/* Testing for CaseEmailTeamController.getCaseTeamMemberIds with the contact related to the case and case team members */
	@isTest
	static void testGetCaseTeamMemberIds() {
		//BYB Records
		BenefitOrderHelperTests.skipTrigger(true);
		BenefitOrderHelper.skipTrigger = false;
		Account objAccBYB = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('test acc3').build();
		insert objAccBYB;
		Opportunity objOpportunityBYB = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits BYOB'))
			.setName('Company Opp')
			.setAccountId(objAccBYB.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();
		insert objOpportunityBYB;
		Benefit_Order__c objBenefitOrderBYB = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB'))
			.setName('New BYB')
			.setAccount(objAccBYB.Id)
			.setOpp(objOpportunityBYB.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();
        Test.startTest();
		insert objBenefitOrderBYB;
		Case objCaseToUpdate = [SELECT Id, ContactId FROM Case WHERE Benefit_Order__c = :objBenefitOrderBYB.Id LIMIT 1];
		Id idRT = ContactUtil.COMPANY_CONTACT_RT_ID;
		List<Contact> list_Contacts = new List<Contact>();
		list_Contacts.add(new Contact(FirstName = 'Test', LastName = 'User01', recordTypeId = idRT, AccountId = objAccBYB.Id, Email = 'testuser01@gusto.com', Zp_User_Id__c = '75001'));
		list_Contacts.add(new Contact(FirstName = 'Test', LastName = 'User02', recordTypeId = idRT, AccountId = objAccBYB.Id, Email = 'testuser02@gusto.com', Zp_User_Id__c = '75002'));
		list_Contacts.add(new Contact(FirstName = 'Test', LastName = 'User03', recordTypeId = idRT, AccountId = objAccBYB.Id, Email = 'testuser03@gusto.com', Zp_User_Id__c = '75003'));
		list_Contacts.add(new Contact(FirstName = 'Test', LastName = 'User04', recordTypeId = idRT, AccountId = objAccBYB.Id, Email = 'testuser04@gusto.com', Zp_User_Id__c = '75004'));
		insert list_Contacts;
		CaseTeamRole objCaseTeamRole = [SELECT ID FROM CaseTeamRole LIMIT 1];
		List<CaseTeamMember> list_CaseTeamMembers = new List<CaseTeamMember>();
		for (Integer i = 1; i < 4; i++) {
			list_CaseTeamMembers.add(new CaseTeamMember(ParentId = objCaseToUpdate.Id, MemberId = list_Contacts[i].Id, TeamRoleId = objCaseTeamRole.Id));
		}
		insert list_CaseTeamMembers;
		objCaseToUpdate.ContactId = list_Contacts[0].Id;
		update objCaseToUpdate;
		
		List<Id> list_response = CaseEmailTeamController.getCaseTeamMemberIds(objCaseToUpdate.Id);
		Test.stopTest();

		System.assertNotEquals(null, list_response, 'It should not be null');
		System.assertEquals(4, list_response.size(), 'It should be four');
	}

	/* Testing for CaseEmailTeamController.getCaseTeamMemberIds with only the contact related to the case */
	@isTest
	static void testGetCaseTeamMemberId() {
		//BYB Records
		BenefitOrderHelperTests.skipTrigger(true);
		BenefitOrderHelper.skipTrigger = false;
		Account objAccBYB = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('test acc3').build();
		insert objAccBYB;
		Opportunity objOpportunityBYB = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits BYOB'))
			.setName('Company Opp')
			.setAccountId(objAccBYB.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();
		insert objOpportunityBYB;
		Benefit_Order__c objBenefitOrderBYB = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB'))
			.setName('New BYB')
			.setAccount(objAccBYB.Id)
			.setOpp(objOpportunityBYB.Id)
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.build();
        Test.startTest();
		insert objBenefitOrderBYB;
		Case objCaseToUpdate = [SELECT Id, ContactId FROM Case WHERE Benefit_Order__c = :objBenefitOrderBYB.Id LIMIT 1];
		Id idRT = ContactUtil.COMPANY_CONTACT_RT_ID;
		List<Contact> list_Contacts = new List<Contact>();
		list_Contacts.add(new Contact(FirstName = 'Test', LastName = 'User01', recordTypeId = idRT, AccountId = objAccBYB.Id, Email = 'testuser01@gusto.com', Zp_User_Id__c = '75001'));
		insert list_Contacts;
		objCaseToUpdate.ContactId = list_Contacts[0].Id;
		update objCaseToUpdate;
		
		List<Id> list_response = CaseEmailTeamController.getCaseTeamMemberIds(objCaseToUpdate.Id);
		Test.stopTest();

		System.assertNotEquals(null, list_response, 'It should not be null');
		System.assertEquals(1, list_response.size(), 'It should be one case team member Id');
	}

	/* Testing for CaseEmailTeamController.getCarrierOptions */
	@isTest
	static void testGetCarrierOptions() {
		Case objCase = [SELECT ID FROM Case WHERE RecordTypeId = :cache.getRecordTypeId('Case', 'Benefits Renewal Case') LIMIT 1];
		Test.startTest();
		Map<String, Object> map_response = CaseEmailTeamController.getCarrierOptions(objCase.Id);
		Test.stopTest();
		System.assertNotEquals(null, map_response.get('fromEmail'), 'It should have the fromEmail');
		System.assertNotEquals(null, map_response.get('carrierId'), 'It should have the carrier Id');
	}

	/* Testing for CaseEmailTeamController.getCarrierOptions BoR */
	@isTest
	static void testGetCarrierOptionsBoR() {
		Case objCase = [SELECT ID FROM Case WHERE RecordTypeId = :cache.getRecordTypeId('Case', 'Benefits BoR') LIMIT 1];
		Test.startTest();
		Map<String, Object> map_response = CaseEmailTeamController.getCarrierOptions(objCase.Id);
		Test.stopTest();
		System.assertNotEquals(null, map_response.get('fromEmail'), 'It should have the fromEmail');
	}

	/* Testing for CaseEmailTeamController.getEmailOptions */
	@isTest
	static void testGetEmailOptions() {
		Carrier__c objCarrier = [SELECT ID FROM Carrier__c WHERE Name = 'Test Carrier 1'];
		Test.startTest();
		Map<String, Object> map_response = CaseEmailTeamController.getEmailOptions(objCarrier.Id);
		Test.stopTest();
		System.assertNotEquals(null, map_response, 'It should have the email options');
	}
	/* Testing for CaseEmailTeamController.updateDraft */
	@isTest
	static void testUpdateDraft() {
		Case objCase = [SELECT ID FROM Case WHERE RecordTypeId = :cache.getRecordTypeId('Case', 'Benefits Renewal Case') LIMIT 1];
		List<EmailMessage> list_emailMessages = [SELECT ID FROM EmailMessage WHERE RelatedToId = :objCase.Id];
		System.assertEquals(0, list_emailMessages.size(), 'There should not be any emailMessage');
		Test.startTest();
		CaseEmailTeamController.updateDraft(objCase.Id, 'toemail@testcarrier.com', UserInfo.getUserEmail());
		Test.stopTest();
		list_emailMessages = [SELECT ID FROM EmailMessage WHERE RelatedToId = :objCase.Id];
		System.assertEquals(1, list_emailMessages.size(), 'There should get one emailMessage');
	}
	/* Testing for CaseEmailTeamController.createEmailCarrier */
	@isTest
	static void testCreateEmailCarrier() {
		Case objCase = [SELECT ID FROM Case WHERE RecordTypeId = :cache.getRecordTypeId('Case', 'MF QLE') LIMIT 1];
		List<EmailMessage> list_emailMessages = [SELECT ID FROM EmailMessage WHERE RelatedToId = :objCase.Id];
		System.assertEquals(0, list_emailMessages.size(), 'There should not be any emailMessage');
		Test.startTest();
		CaseEmailTeamController.createEmailCarrier(objCase.Id);
		Test.stopTest();
		list_emailMessages = [SELECT ID, ToAddress FROM EmailMessage WHERE RelatedToId = :objCase.Id];
		System.assertEquals(1, list_emailMessages.size(), 'There should get one emailMessage');
		System.assertEquals('test@test.com', list_emailMessages[0].ToAddress, 'Email should be the same');
	}
	/* Testing for CaseEmailTeamController.createEmailCustomer */
	@isTest
	static void testCreateEmailCustomer() {
		Case objCase = [SELECT ID FROM Case WHERE RecordTypeId = :cache.getRecordTypeId('Case', 'MF QLE') LIMIT 1];
		List<EmailMessage> list_emailMessages = [SELECT ID FROM EmailMessage WHERE RelatedToId = :objCase.Id];
		System.assertEquals(0, list_emailMessages.size(), 'There should not be any emailMessage');
		Test.startTest();
		CaseEmailTeamController.createEmailCustomer(objCase.Id);
		Test.stopTest();
		list_emailMessages = [SELECT ID, ToAddress FROM EmailMessage WHERE RelatedToId = :objCase.Id];
		System.assertEquals(1, list_emailMessages.size(), 'There should get one emailMessage');
		System.assertEquals('abc@gusto.com', list_emailMessages[0].ToAddress, 'Email should be the same');
	}
}