/**
 * @name         HIGroupEventOAIntroEmailTest
 * @author       Bhagat Singh
 * @date         07 July 2021
 * @description  Test class for HIGroupEventOAIntroEmail class.
 **/
@isTest
private class HIGroupEventOAIntroEmailTest {
	/**
	 * @Author       Bhagat Singh
	 * @Description  Test Class setup method
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		List<Email_Macro__c> list_EmailMacros = new List<Email_Macro__c>();
		Email_Macro__c objMacro = new Email_Macro__c();
		objMacro.Macro_Identifier__c = 'OA-INTRO-EMAIL-SUBJECT-1';
		objMacro.Body__c = 'Action required: Response needed to set up benefits for [ACCOUNT NAME]';
		list_EmailMacros.add(objMacro);

		objMacro = new Email_Macro__c();
		objMacro.Macro_Identifier__c = 'OA-INTRO-EMAIL-SUBJECT-2';
		objMacro.Body__c = 'Please read: Let’s start renewing [ACCOUNT NAME]’s benefits!';
		list_EmailMacros.add(objMacro);

		insert list_EmailMacros;

		State__c objState = new State__c(Name = 'California', Abbreviation__c = 'CA', Key__c = 'CA');
		insert objState;

		Opportunity objOpp = TestUtility.BenefitsNewPlanOpportunity();
		Account objAcc = new Account(
			Id = objOpp.AccountId,
			ZP_Company_Id__c = '72239',
			Tier__c = objTierConfig.New_Tier_1__c,
			AM_Tier__c = 'Gold',
			ShippingState = 'California',
			BillingState = 'California'
		);
		update objAcc;

		objOpp.Source_ID__c = 'hawaiian_ice-new_plans_application-11001';
		objOpp.HI_Effective_Date__c = System.today().addDays(2);
		objOpp.Benefits_Current_Setup_Step__c = 'Verifying Eligibility';
		update objOpp;

		Carrier__c objCarrier = TestUtility.Carrier();
		Policy__c objPolicy = (Policy__c) Policy__c.SObjectType.newSObject();
		objPolicy.Name = 'TEST POLICY';
		objPolicy.Opportunity__c = objOpp.Id;
		objPolicy.Carrier__c = objCarrier.Id;
		objPolicy.Is_Selected__c = true;
		objPolicy.State__c = objState.Id;
		insert objPolicy;

		//Create Contact
		Contact objContact = new Contact(
			FirstName = 'Test',
			LastName = 'User01',
			recordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID,
			AccountId = objOpp.AccountId,
			Email = 'testuser01@gusto.com',
			Zp_User_Id__c = '75001'
		);
		insert objContact;

		//Create TTF record.
		NewTransitionToFulfillmentController.BO_order_type = new List<String>();
		NewTransitionToFulfillmentController.BO_order_type.add('Carrier Switch');
		Id idTTFRecordType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		TestUtility.createTestTransitionToFulfillment(objOpp.AccountId, objContact.Id, objOpp.Id, idTTFRecordType, true);

		List<Role__c> list_Roles = new List<Role__c>();
		list_Roles.add(new Role__c(Name = 'Implementation Advocate', Skill_Type__c = 'Implementation Advocate', Team__c = 'Core'));
		list_Roles.add(new Role__c(Name = 'Qualification', Skill_Type__c = 'Qualification', Team__c = 'Core'));
		list_Roles.add(new Role__c(Name = 'Submission', Skill_Type__c = 'Submission', Team__c = 'Core'));
		insert list_Roles;

		List<Skill__c> list_Skills = new List<Skill__c>();
		list_Skills.add(
			new Skill__c(
				Benefits_Big_Desk__c = true,
				Role__c = list_Roles[0].Id,
				Tier__c = objTierConfig.New_Tier_1__c,
				State_Group__c = 'California',
				Partner__c = 'Gold',
				Order_Type__c = 'New to Gusto'
			)
		);
		list_Skills.add(
			new Skill__c(
				Benefits_Big_Desk__c = true,
				Role__c = list_Roles[1].Id,
				Tier__c = objTierConfig.New_Tier_1__c,
				State_Group__c = 'California',
				Partner__c = 'Gold',
				Order_Type__c = 'New to Gusto'
			)
		);
		list_Skills.add(
			new Skill__c(
				Benefits_Big_Desk__c = true,
				Role__c = list_Roles[2].Id,
				Tier__c = objTierConfig.New_Tier_1__c,
				State_Group__c = 'California',
				Partner__c = 'Gold',
				Order_Type__c = 'New to Gusto'
			)
		);
		insert list_Skills;

		List<User> list_Users = TestUtility.createUsers('Benefits Fulfillment', 3);
		List<User_Role__c> list_UserRoles = new List<User_Role__c>();
		list_UserRoles.add(new User_Role__c(User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core', User__c = list_Users[0].Id));
		list_UserRoles.add(new User_Role__c(User_Skill_Team__c = 'Qualification', User_Skill_Type__c = 'Core', User__c = list_Users[1].Id));
		list_UserRoles.add(new User_Role__c(User_Skill_Team__c = 'Submission', User_Skill_Type__c = 'Core', User__c = list_Users[2].Id));
		insert list_UserRoles;

		List<User_Skill__c> list_UserSkills = new List<User_Skill__c>();
		list_UserSkills.add(new User_Skill__c(User_Role__c = list_UserRoles[0].Id, Skill__c = list_Skills[0].Id, Active__c = true));
		list_UserSkills.add(new User_Skill__c(User_Role__c = list_UserRoles[1].Id, Skill__c = list_Skills[1].Id, Active__c = true));
		list_UserSkills.add(new User_Skill__c(User_Role__c = list_UserRoles[2].Id, Skill__c = list_Skills[2].Id, Active__c = true));
		insert list_UserSkills;

		Utils.skipTrigger(false);
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Test OA Intro Email : Negative case - Benefit Order record not found
	 **/
	@isTest
	static void tesOAIntoEmailBONotFound() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'OA_intro_email',
			Application_Id__c = '11001',
			Application_Type__c = 'New Plan',
			Company_Id__c = '72240',
			Event_Id__c = '11001',
			Event_Type__c = 'OA_intro_email',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":72240,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.DOC_COLLECTION_DEAD_UNPROCESSED_EVENT);
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Test OA Intro Email : Negative case - Case record not found
	 **/
	@isTest
	static void tesOAIntoEmailCaseNotFound() {
		Test.startTest();
		Case objCase = [SELECT Id, ContactId, AccountId FROM Case WHERE Benefit_Order__c != NULL AND Integration_Id__c LIKE 'hippo-%' LIMIT 1];
		if (objCase != null) {
			Utils.skipTrigger(true);
			delete objCase;
			Utils.skipTrigger(false);
		}

		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'OA_intro_email',
			Application_Id__c = '11001',
			Application_Type__c = 'New Plan',
			Company_Id__c = '72239',
			Event_Id__c = '11001',
			Event_Type__c = 'OA_intro_email',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.CASE_RELATED_TO_BO_NOT_FOUND);
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Test OA Intro Email : Postive case
	 **/
	@isTest
	static void tesHIGroupEventOAIntroEmailEventInfo() {
		Test.startTest();
		Case objCase = [SELECT Id, ContactId, AccountId, Benefit_Order__c, Benefit_Order__r.OwnerId FROM Case WHERE Benefit_Order__c != NULL AND Integration_Id__c LIKE 'hippo-%' LIMIT 1];
		Carrier__c objCarrier = [SELECT Id FROM Carrier__c LIMIT 1];

		Utils.skipTrigger(true);
		Carrier_Order__c objParentCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Parent CO')
			.setOrderType('Carrier Switch')
			.setBenefitOrder(objCase.Benefit_Order__c)
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'New Plan'))
			.setOwnerID(GlobalQueryHelper.getQueueIdByName('Carrier Implementation Queue'))
			.setCarrier(objCarrier.Id)
			.setImplementationStage('Ready for OE Prep')
			.build();
		insert objParentCO;

		Benefit_Order__c objChildBO = new TestDataFactory.BenefitOrderBuilder()
			.setName('Child BO')
			.setType('Carrier Switch')
			.setOwnerID(objCase.Benefit_Order__r.OwnerId)
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'New Plan'))
			.build();
		objChildBO.Parent_Benefit_Order__c = objCase.Benefit_Order__c;
		insert objChildBO;
		Carrier_Order__c objChildCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('Child CO')
			.setOrderType('Carrier Switch')
			.setBenefitOrder(objChildBO.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'New Plan'))
			.setOwnerID(GlobalQueryHelper.getQueueIdByName('Carrier Implementation Queue'))
			.setCarrier(objCarrier.Id)
			.setImplementationStage('Ready for OE Prep')
			.build();
		insert objChildCO;
		List<Contact> list_Contact = new List<Contact>();
		list_Contact.add(new Contact(FirstName = 'User 1', LastName = 'Test', Email = 'mycaseuser1@gusto.com', AccountId = objCase.AccountId));
		list_Contact.add(new Contact(FirstName = 'User 2', LastName = 'Test', Email = 'mycaseuser2@gusto.com', AccountId = objCase.AccountId));
		list_Contact.add(new Contact(FirstName = 'User 3', LastName = 'Test', Email = 'mycaseuser3@gusto.com', AccountId = objCase.AccountId));
		list_Contact.add(new Contact(FirstName = 'User 4', LastName = 'Test', Email = 'mycaseuser4@gusto.com', AccountId = objCase.AccountId));
		insert list_Contact;

		List<CaseTeamRole> list_CaseTeamRoles = [SELECT Id FROM CaseTeamRole WHERE Name = 'Customer Contact'];
		Id idCaseTeamRole = null;
		if (list_CaseTeamRoles != null && list_CaseTeamRoles.size() > 0) {
			idCaseTeamRole = list_CaseTeamRoles[0].Id;
		}

		Id idNewPlan = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		List<CaseTeamMember> list_CaseTeams = new List<CaseTeamMember>();
		list_CaseTeams.add(new CaseTeamMember(MemberId = list_Contact[1].Id, ParentId = objCase.Id, TeamRoleId = idCaseTeamRole));
		list_CaseTeams.add(new CaseTeamMember(MemberId = list_Contact[2].Id, ParentId = objCase.Id, TeamRoleId = idCaseTeamRole));
		list_CaseTeams.add(new CaseTeamMember(MemberId = list_Contact[3].Id, ParentId = objCase.Id, TeamRoleId = idCaseTeamRole));
		insert list_CaseTeams;
		Utils.skipTrigger(false);

		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'OA_intro_email',
			Application_Id__c = '11001',
			Application_Type__c = 'New Plan',
			Company_Id__c = '72239',
			Event_Id__c = '11001',
			Event_Type__c = 'OA_intro_email',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
		);
		insert objHIGroupEvent;
		Test.stopTest();
		if(OrganizationUtilities.canSendEmails()){
			List<EmailMessage> list_EmailMessage = [SELECT Id, CcAddress, HtmlBody FROM EmailMessage WHERE ParentId = :objCase.Id AND Email_Template_Name__c = 'OA_Intro_Email'];
			System.assert(list_EmailMessage.size() > 0);
			String strCCAddress = list_EmailMessage[0].CcAddress;
			System.assert(strCCAddress.contains('mycaseuser2@gusto.com'));
			System.assert(strCCAddress.contains('mycaseuser3@gusto.com'));
			System.assert(strCCAddress.contains('mycaseuser4@gusto.com'));

			objParentCO = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :objParentCO.Id];
			objChildCO = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :objChildCO.Id];
			System.assertEquals('OE', objParentCO.Implementation_Stage__c);
			System.assertEquals('OE', objChildCO.Implementation_Stage__c);
		}
		
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Validate : Event Info required field
	 **/
	@isTest
	static void tesHIGroupEventValidationNoEventInfo() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(Name = 'OA_intro_email', Event_Id__c = '11001', Event_Type__c = 'OA_intro_email', Processing_State__c = 'Queued');
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_EVENT_INFO_MISSING);
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Validate : Application Id required field.
	 **/
	@isTest
	static void tesHIGroupEventValidationNoApplicationId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'OA_intro_email',
			Event_Id__c = '11001',
			Event_Type__c = 'OA_intro_email',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11002,"company_id":"","application_id":"" ,"application_type":"","email_body":"test email body","event_type":"OA_intro_email"}'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_APPLICATION_ID_MISSING);
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Validate : Application Type required field.
	 **/
	@isTest
	static void tesHIGroupEventValidationNoApplicationType() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'OA_intro_email',
			Event_Id__c = '11001',
			Event_Type__c = 'OA_intro_email',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11002,"company_id":"","application_id":"" ,"application_type":"","email_body":"test email body","event_type":"OA_intro_email"}',
			Application_Id__c = '11001'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_APPLICATION_TYPE_MISSING);
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Validate : Company Id required field.
	 **/
	@isTest
	static void tesHIGroupEventValidationNoCompanyId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'OA_intro_email',
			Event_Id__c = '11001',
			Event_Type__c = 'OA_intro_email',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11002,"company_id":"","application_id": "11001","application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}',
			Application_Id__c = '11001',
			Application_Type__c = 'New Plan'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_COMPANY_ID_MISSING);
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Validate : Email Body required field.
	 **/
	@isTest
	static void tesHIGroupEventValidationNoEmailBody() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'OA_intro_email',
			Event_Id__c = '11001',
			Event_Type__c = 'OA_intro_email',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11002,"company_id":"72239","application_id": "11001","application_type":"New Plan","email_body":"","event_type":"OA_intro_email"}',
			Application_Id__c = '11001',
			Application_Type__c = 'New Plan',
			Company_Id__c = '72239'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_EMAIL_BODY_MISSING);
	}

	/**
	 * @Author       Bhagat Singh
	 * @Description  Validate : ErrorLog created, if any exception occured.
	 **/
	@isTest
	static void tesHIGroupEventValidateErrorLogs() {
		Test.startTest();
		try {
			HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
				Name = 'OA_intro_email',
				Event_Id__c = '11001',
				Processing_State__c = 'Blank',
				Event_Info__c = '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
			);
			insert objHIGroupEvent;
		} catch (Exception objExp) {
			HIGroupEventOAIntroEmail.createErrorLog(objExp);
		}
		Test.stopTest();

		List<Exception_Log__c> list_ErrorLogs = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'HIGroupEventOAIntroEmail'];
		System.assert(list_ErrorLogs.size() > 0);
	}

	/**
	 * @Author       Rushi Ravisaheb
	 * @Description  Test OA Intro Email : Negative case - Contact Email blank
	 **/
	@isTest
	static void tesOAIntroBlankContactEmail() {
		Test.startTest();
		Case objCase = [SELECT Id, ContactId, AccountId FROM Case WHERE Benefit_Order__c != NULL AND Integration_Id__c LIKE 'hippo-%' LIMIT 1];
		Contact objContact = [SELECT Id, Email FROM Contact WHERE Id = :objCase.ContactId];
		if (objContact != null) {
			ContactTriggerHelper.skipTrigger = true;
			objContact.Email = null;
			update objContact;
			ContactTriggerHelper.skipTrigger = false;
		}

		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Name = 'OA_intro_email',
			Application_Id__c = '11001',
			Application_Type__c = 'New Plan',
			Company_Id__c = '72239',
			Event_Id__c = '11001',
			Event_Type__c = 'OA_intro_email',
			Processing_State__c = 'Queued',
			Event_Info__c = '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
		);
		insert objHIGroupEvent;
		Test.stopTest();
		if(OrganizationUtilities.canSendEmails()){
			System.assert([SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'HIGroupEventOAIntroEmail'].isEmpty());
		}
	}
}