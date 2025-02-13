/**
 * @name         HIGroupEventTTSNotePostOEEmailTest
 * @author       Deepika Saini
 * @date         10-07-2021
 * @description  Test class for HIGroupEventTTSNotePostOEEmail class.
 **/
@isTest
private class HIGroupEventTTSNotePostOEEmailTest {
	public final static Id SUBMISSION_NEW_PLAN_TTF_RT_ID = Cache.getRecordTypeId('Transition_To_Fulfillment__c', 'Submission New Plan');
	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;
		
		skipTrigger(true);
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
		objOpp.HI_Effective_Date__c = System.today().addDays(5);
		objOpp.Benefits_Current_Setup_Step__c = 'Verifying Eligibility';
		update objOpp;

		Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('New Plan', objOpp.Id, 'Test BO ', false);
		objBO.Account__c = objOpp.AccountId;
		objBO.Status_Detail__c = 'STATUS DETAIL';
		objBO.Coverage_Effective_Date__c = Date.today().addDays(5);
		insert objBO;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAcc.Id)
			.setFirstName('Test')
			.setLastName('User01')
			.setEmail('testuser01@gusto.com')
			.setZPUserId('75001')
			.build();
		insert objContact;

		Carrier__c objCarrier = TestUtility.Carrier();
		objCarrier.Carrier_Id__c = '8';
		objCarrier.Id__c = '2';
        update objCarrier;

		Carrier_Order__c objCO = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCO.Name = 'TEST CARRIER ORDER';
		objCO.Carrier__c = objCarrier.Id;
		objCO.Benefit_Order__c = objBO.Id;
		objCO.Order_Type__c = 'Same Carrier, NO Plan/Group Level Changes';
		objCO.Order_Assignment__c = 'Same Carrier, NO Plan/Group Level Changes';
		objCO.Member_Submission_Date__c = Date.today().addDays(25);
		objCO.Group_Number__c = '120022';
		insert objCO;

		Policy__c objPolicy = TestUtility.createTestPolicy(objOpp.Id, objCarrier.Id, true, 'Test Policy 1', objCO.Id, false);
		objPolicy.Benefit_Type__c = 'Vision';
		insert objPolicy;

		Case objCase = TestUtility.createCustomerCase(objOpp.Id, objBO.Id, objAcc.Id, objContact.Id, 'Benefits New Plan Case');
		insert objCase;

		List<Contact> list_Contact = new List<Contact>();
		list_Contact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(objAcc.Id)
				.setFirstName('User 1')
				.setLastName('My')
				.setEmail('mycaseuser1@gusto.com')
				.setZPUserId('75101')
				.build()
		);
		list_Contact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(objAcc.Id)
				.setFirstName('User 2')
				.setLastName('My')
				.setEmail('mycaseuser2@gusto.com')
				.setZPUserId('75102')
				.build()
		);
		list_Contact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(objAcc.Id)
				.setFirstName('User 3')
				.setLastName('My')
				.setEmail('mycaseuser3@gusto.com')
				.setZPUserId('75103')
				.build()
		);
		insert list_Contact;

		List<CaseTeamRole> list_CaseTeamRoles = [SELECT Id FROM CaseTeamRole WHERE Name = 'Customer Contact'];
		Id idCaseTeamRole = null;
		if (list_CaseTeamRoles != null && list_CaseTeamRoles.size() > 0) {
			idCaseTeamRole = list_CaseTeamRoles[0].Id;
		}

		Id idNewPlan = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		List<CaseTeamMember> list_CaseTeams = new List<CaseTeamMember>();
		list_CaseTeams.add(new CaseTeamMember(MemberId = list_Contact[0].Id, ParentId = objCase.Id, TeamRoleId = idCaseTeamRole));
		list_CaseTeams.add(new CaseTeamMember(MemberId = list_Contact[1].Id, ParentId = objCase.Id, TeamRoleId = idCaseTeamRole));
		list_CaseTeams.add(new CaseTeamMember(MemberId = list_Contact[2].Id, ParentId = objCase.Id, TeamRoleId = idCaseTeamRole));
		insert list_CaseTeams;

		List<Email_Macro__c> list_EmailMacro = new List<Email_Macro__c>();
		list_EmailMacro.add(new TestDataFactory.EmailMacroBuilder().setMacroIdentifier('OE_EMAIL_GHOST_PLAN').setBody('[Ghost Plan Removed] only allows companies to offer the plans that employees chose during open enrollment. No one on your team enrolled in the [Plan Name] plan, so this will be removed from your company\'s offerings for this policy year. You can choose to add this plan again during your renewal next year.').build());
		insert list_EmailMacro;

		Utils.skipTrigger(false);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Positive Case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventPositiveCase() {
		skipTrigger(true);
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setName('OE_post_email')
			.setEventId('11001')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL)
			.setProcessingState('Queued')
			.setEventInfo('{"event_id":"11001","company_id":"72239","application_id":"11001","application_type":"New Plan"}')
			.setApplicationId('11001')
			.setApplicationType('New Plan')
			.build();
		insert objHIGroupEvent;

		Test.stopTest();
		if(OrganizationUtilities.canSendEmails()){
			List<EmailMessage> list_EmailMessage = [SELECT Id, CcAddress, HtmlBody FROM EmailMessage WHERE Email_Template_Name__c = :HIGroupEventTTSNotePostOEEmail.NEWPLAN_EMAIL_TEMPLATE];
			System.assert(list_EmailMessage.size() > 0);
			String strCCAddress = list_EmailMessage[0].CcAddress;
			System.assert(strCCAddress.contains('mycaseuser1@gusto.com'));
			System.assert(strCCAddress.contains('mycaseuser2@gusto.com'));
			System.assert(strCCAddress.contains('mycaseuser3@gusto.com'));
			Id idAutomationQueue = GlobalQueryHelper.getQueueIdByName('Automation Queue');
		}
		List<Carrier_Order__c> list_COs = [SELECT Id, OwnerId FROM Carrier_Order__c WHERE Carrier__r.Carrier_Id__c = '8'];
		System.assert(list_COs.size() > 0);
		//System.assert(list_COs[0].OwnerId == idAutomationQueue);
		skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Ghost Plan Positive Case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventGhostPlanPositiveCase() {
		skipTrigger(true);
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setName('OE_post_email')
			.setEventId('11001')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL)
			.setProcessingState('Queued')
			.setEventInfo(
				'{"event_id":"11001","company_id":"72239","application_id":"11001","application_type":"New Plan","ghost_plans":[{"carrier_name":"Guardian","plan_details":["Guardian plan 1","Guardian plan 2"]},{"carrier_name":"UnitedHealthcare","plan_details":["UH plan 1","UH plan 2"]}]}'
			)
			.setApplicationId('11001')
			.setApplicationType('New Plan')
			.build();
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Id, RecordTypeId FROM Transition_To_Fulfillment__c].RecordTypeId == SUBMISSION_NEW_PLAN_TTF_RT_ID);
		if(OrganizationUtilities.canSendEmails()) {
			List<EmailMessage> list_EmailMessage = [SELECT Id, CcAddress, HtmlBody FROM EmailMessage WHERE Email_Template_Name__c = :HIGroupEventTTSNotePostOEEmail.NEWPLAN_EMAIL_TEMPLATE];
			System.assert(list_EmailMessage.size() > 0);
			String strEmailBody = list_EmailMessage[0].HtmlBody;
			System.assert(strEmailBody.contains('Guardian, UnitedHealthcare'));
		}
		skipTrigger(false);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Validate : Event Info required field
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidationNoEventInfo() {
		Test.startTest();

		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setName('OE_post_email')
			.setEventId('11001')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL)
			.setProcessingState('Queued')
			.build();
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_EVENT_INFO_MISSING);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Validate : Application Id required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidationNoApplicationId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setName('OE_post_email')
			.setEventId('11001')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL)
			.setProcessingState('Queued')
			.setEventInfo('{"event_id":"11001","company_id":"","application_id":"","application_type":""}')
			.build();
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_APPLICATION_ID_MISSING);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Validate : Application Type required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidationNoApplicationType() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setName('OE_post_email')
			.setEventId('11001')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL)
			.setProcessingState('Queued')
			.setEventInfo('{"event_id":"11001","company_id":"","application_id":"","application_type":""}')
			.setApplicationId('11001')
			.build();
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_APPLICATION_TYPE_MISSING);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Validate : Company Id required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventValidationNoCompanyId() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setName('OE_post_email')
			.setEventId('11001')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL)
			.setProcessingState('Queued')
			.setEventInfo('{"event_id":"11001","company_id":"","application_id":"11001","application_type":"New Plan"}')
			.setApplicationId('11001')
			.setApplicationType('New Plan')
			.build();
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_COMPANY_ID_MISSING);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Validate : Application type is Invalid required field.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void tesHIGroupEventInvalidApplicationType() {
		Test.startTest();
		HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
			.setName('OE_post_email')
			.setEventId('11001')
			.setEventType(HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL)
			.setProcessingState('Queued')
			.setEventInfo('{"event_id":"11001","company_id":"12354","application_id":"11001","application_type":"Benefits BoR"}')
			.setApplicationId('11001')
			.setApplicationType('Benefits BoR')
			.build();
		insert objHIGroupEvent;

		Test.stopTest();

		System.assert([SELECT Message__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Message__c == HIGroupEventUtil.ERROR_APPLICATION_TYPE_INVALID);
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		PolicyHelper.skipTrigger = blnFlag;
	}
}