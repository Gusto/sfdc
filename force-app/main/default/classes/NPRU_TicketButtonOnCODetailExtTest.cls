@isTest
private class NPRU_TicketButtonOnCODetailExtTest {
	static final Id ID_LOGGED_USER = UserInfo.getUserId();

	@testSetup
	static void testData() {
		AccounttriggerHelper.skipTrigger = true;
		OpportunitytriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		insert new State_Name_to_abbreviations_Mapping__c(Name = 'Alabama', State_Abbreviation__c = 'Alabama', State_Name__c = 'AL');

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();

		Benefit_Order__c benefitOrdr1 = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);

		benefitOrdr1.Order_Status__c = 'OE';
		benefitOrdr1.OwnerID = UserInfo.getUserId();
		benefitOrdr1.Coverage_Effective_Date__c = System.today();
		benefitOrdr1.Open_Enrollment_Start_Date__c = System.today();
		benefitOrdr1.Open_Enrollment_End_Date__c = System.today();
		benefitOrdr1.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update benefitOrdr1;

		Carrier__c testCarrier = new CArrier__c(State__c = 'FL');
		insert testCarrier;

		Carrier_Order__c objCarrierOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarrierOrder.Name = 'TEST CARRIER ORDER';
		objCarrierOrder.Carrier__c = testCarrier.Id;
		objCarrierOrder.Benefit_Order__c = benefitOrdr1.Id;
		objCarrierOrder.Order_Type__c = 'New to Gusto';
		objCarrierOrder.Follow_Up_Date__c = system.today().addDays(10);
		objCarrierOrder.Confirmation_Owner__c = ID_LOGGED_USER;
		insert objCarrierOrder;

		Carrier_Order__c objCarrierOrder1 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarrierOrder1.Name = 'TEST CARRIER ORDER1';
		objCarrierOrder1.Carrier__c = testCarrier.Id;
		objCarrierOrder1.Benefit_Order__c = benefitOrdr1.Id;
		objCarrierOrder1.Order_Type__c = 'New to Gusto';
		objCarrierOrder1.Follow_Up_Date__c = system.today().addDays(10);
		insert objCarrierOrder1;

		List<Ticket_Mapping__c> list_Mappings = new List<Ticket_Mapping__c>();
		Ticket_Mapping__c objTM = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Missed EE enrollment')
			.setTicketReasonDetails('')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setToSubTeam('')
			.setFromSubTeam('Fulfillment')
			.setToTeam('Member Processing')
			.build();
		list_Mappings.add(objTM);

		Ticket_Mapping__c objTM1 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Recertification')
			.setTicketReasonDetails('Recertification Not Sent')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('With Advising')
			.setFromSubTeam('Fulfillment')
			.setToTeam('Benefits Advising')
			.build();
		list_Mappings.add(objTM1);

		Ticket_Mapping__c objTM2 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Cancel')
			.setTicketReasonDetails('Carrier Denial')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('With Advising')
			.setFromSubTeam('Fulfillment')
			.setToTeam('New Plan Sales')
			.build();
		list_Mappings.add(objTM2);

		Ticket_Mapping__c objTM3 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Issue Clarification')
			.setTicketReasonDetails('')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('With Advising')
			.setFromSubTeam('Fulfillment')
			.setToTeam('Benefits Compliance')
			.build();
		list_Mappings.add(objTM3);

		//Neha, For Fulfillment
		Ticket_Mapping__c objTM4 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Pending Items')
			.setTicketReasonDetails('Incomplete Form')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Confirmation')
			.setOrderStatusWhenTicketIsOpen('Pending Item')
			.setFromSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.setToSubTeam('Implementation Advocate')
			.build();
		list_Mappings.add(objTM4);

		//Neha, For IA
		Ticket_Mapping__c objTM5 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Denial')
			.setTicketReasonDetails('Carrier Denied Group Application')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('Back to status prior to ticket creation')
			.setOrderStatusWhenTicketIsOpen('Awaiting Routing')
			.setFromSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.setToSubTeam('Implementation Advocate')
			.build();
		list_Mappings.add(objTM5);

		Ticket_Mapping__c objTM6 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Denial')
			.setTicketReasonDetails('Carrier Denied Group Application')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('Awaiting Routing')
			.setOrderStatusWhenTicketIsOpen('Awaiting Routing')
			.setFromSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.setToSubTeam('Implementation Advocate')
			.build();
		list_Mappings.add(objTM6);

		Ticket_Mapping__c objTM8 = new Ticket_Mapping__c(
			Ticket_Reason_s__c = 'Concession/Reimbursement',
			Automated_QC_Error_Required__c = 'NO',
			Order_Status_when_Ticket_is_Closed__c = 'No Impact on Status',
			Order_Status_while_Ticket_is_Open__c = 'No Impact on Status',
			From_Sub_Team_s__c = 'Fulfillment',
			To_Team__c = 'Benefits Compliance',
			Action_Required_by_Ticket_Recipient__c = 'Concession/Reimbursement'
		);
		list_Mappings.add(objTM8);

		// Ticket Mapping for carrier IO for Fulfillment Pending Item: Response Needed
		Ticket_Mapping__c objTM12 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Pending Item: Response Needed')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTM12);

		// Ticket Mapping for carrier IO for Fulfillment Pending Item: Clarification Needed
		Ticket_Mapping__c objTM13 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Pending Item: Clarification Needed')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTM13);

		// Ticket Mapping for carrier IO for Fulfillment Response Needed
		Ticket_Mapping__c objTM14 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Pending Item: Response Needed')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTM14);

		// Ticket Mapping for carrier IO for Fulfillment Pending Item: Clarification Needed
		Ticket_Mapping__c objTM15 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Pending Item: Clarification Needed')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTM15);

		// Ticket Mapping for carrier IO for Implementation Advocate
		Ticket_Mapping__c objTM16 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Customer outreach required')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Implementation Advocate')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTM16);

		//Ticket Mapping for carrier IO for New plan sales
		Ticket_Mapping__c objTM17 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Customer outreach required')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToTeam('New Plan Sales')
			.build();
		list_Mappings.add(objTM17);

		//Ticket mapping for carrier order blocked for Fulfillment
		Ticket_Mapping__c objTM10 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Existing Group Coverage/BOR')
			.setTicketReasonDetails(' ')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('Awaiting Routing')
			.setOrderStatusWhenTicketIsOpen('Blocked')
			.setFromSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.setToSubTeam('Implementation Advocate')
			.build();
		list_Mappings.add(objTM10);

		//Ticket mapping for carrier order blocked for Fulfillment
		Ticket_Mapping__c objTM11 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Existing Group Coverage/BOR')
			.setTicketReasonDetails(' ')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('Awaiting Routing')
			.setOrderStatusWhenTicketIsOpen('Blocked')
			.setFromSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.setToSubTeam('Implementation Advocate')
			.build();
		list_Mappings.add(objTM11);

		insert list_Mappings;
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Benefits Advising
	 **/
	@isTest
	static void ticketCreationForAdvising() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'All');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.objTicketRecord.Reporting_Team__c = 'Fulfillment';
			objExtension.objQCError.From_Sub_Team_s__c = 'Fulfillment';
			objExtension.strSelectedTeam = 'Benefits Advising';
			objExtension.subTeam();

			objExtension.strSelectedReason = 'Customer Change Request';
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = 'Carrier Change Requested';
			objExtension.objTicketRecord.Summary__c = 'Test';
			objExtension.objTicketRecord.Description__c = 'Test';
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Customer Change Request'], 'Customer Change Request ticket should be created.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Benefits Transfer
	 **/
	@isTest
	static void ticketCreationForTransfer() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c coObj = [SELECT Id FROM Carrier_Order__c LIMIT 1];
		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', coObj.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController stdController = new ApexPages.StandardController(coObj);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(stdController);
			objExtension.saveQCError();

			objExtension.strSelectedTeam = 'Benefit Transfer';
			objExtension.subTeam();
			objExtension.saveTicket();

			objExtension.saveQCError();

			objExtension.strSelectedReason = 'Group Set Up Issue';
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = '';
			objExtension.saveTicket();
			objExtension.saveQCError();

			objExtension.objQCError.To_Sub_team__c = 'Fulfillment';
			objExtension.saveQCError();

			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.strSelectedSubTeam = 'None';
			objExtension.saveTicket();
			objExtension.saveQCError();
		}
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Group Set Up Issue'], 'Group Set Up Issue ticket should not be created.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Implementation Advocate - Amplifier
	 **/
	@isTest
	static void ticketCreationForAmp() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c coObj = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', coObj.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController stdController = new ApexPages.StandardController(coObj);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(stdController);
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.subTeam();
			objExtension.objTicketRecord.Summary__c = 'Test';
			objExtension.objTicketRecord.Description__c = 'Test';
			objExtension.strSelectedSubTeam = 'Implementation Advocate - Amplifier';
			objExtension.assignOwner();
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Implementation Advocate - Amplifier'], 'Implementation Advocate - Amplifier ticket should not be created.');
	}

	/**
	 * @author       Neha
	 * @description  Test method for ticket creation for Fulfillment
	 **/
	@isTest
	static void ticketCreationForSubmission() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c coObj = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', coObj.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController stdController = new ApexPages.StandardController(coObj);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(stdController);
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.strSelectedSubTeam = 'Fulfillment';
			objExtension.saveQCError();
			objExtension.subTeam();

			objExtension.strSelectedSubTeam = 'Fulfillment';
			objExtension.strSelectedReason = 'Pending Items';
			objExtension.assignOwner();
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = 'Incomplete Form';
			objExtension.objTicketRecord.Team__c = 'Onboarding';
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Pending Items'], 'Pending Items ticket should not be created.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Confirmation : NeagtiveCase
	 **/
	@isTest
	static void testNeagtiveCaseForConfirmationOwer() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c objCarrierOrder = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCarrierOrder.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCarrierOrder);

			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.subTeam();

			objExtension.strSelectedSubTeam = 'Implementation Advocate';
			objExtension.strSelectedReason = 'Pending Audit';
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = 'Carrier Denied Group Application';
			objExtension.objTicketRecord.Team__c = 'Onboarding';
			objExtension.saveTicket();
		}
		Test.stopTest();

		objCarrierOrder = [SELECT Confirmation_Owner__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		System.assertNotEquals(null, objCarrierOrder.Confirmation_Owner__c, 'Confirmation owner should not be removed.');
	}

	/**
	 * @author       Neha
	 * @description  Test method for ticket creation for Qualification
	 **/
	@isTest
	static void ticketCreationQualificationRecTypeNegative() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c coObj = [SELECT Id, Carrier__c FROM Carrier_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', coObj.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController stdController = new ApexPages.StandardController(coObj);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(stdController);
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.subTeam();

			objExtension.strSelectedSubTeam = 'Qualification';
			objExtension.strSelectedReason = 'Carrier Requirements';
			objExtension.copyCarrierStatesToTicket();
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = 'Unnecessary request for information';
			objExtension.saveTicket();

			objExtension.objTicketRecord.Priority__c = 'Low';
			objExtension.saveTicket();

			objExtension.objTicketRecord.Description__c = 'Test';
			objExtension.saveTicket();

			objExtension.objTicketRecord.Attachment__c = 'Test';
			objExtension.saveTicket();

			objExtension.objTicketRecord.Carrier__c = null;
			objExtension.saveTicket();

			objExtension.objTicketRecord.Carrier__c = coObj.Carrier__c;
			objExtension.objTicketRecord.States__c = null;
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Carrier Requirements'], 'Carrier Requirements ticket should not be created.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Fulfillment Automation
	 **/
	@isTest
	static void ticketCreationForSubmissionAutomation() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		objCO.OwnerId = [SELECT Id FROM Group WHERE Name = 'Carrier Implementation Queue' LIMIT 1].Id;
		objCO.Sent_to_HI_for_Submission__c = true;
		update objCO;

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objTicketStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objNewTicketBO = new NPRU_TicketButtonOnCODetailExt(objTicketStdController);
			objNewTicketBO.objTicketRecord.Reporting_Team__c = 'Fulfillment';
			objNewTicketBO.objQCError.From_Sub_Team_s__c = 'Fulfillment';
			objNewTicketBO.strSelectedTeam = 'Onboarding';
			objNewTicketBO.subTeam();

			objNewTicketBO.strSelectedSubTeam = 'Implementation Advocate';
			objNewTicketBO.assignOwner();

			objNewTicketBO.strSelectedReason = 'Pending Items';
			objNewTicketBO.ticketDetail();

			objNewTicketBO.strSelectedReasonDetail = 'Incomplete Form';
			objNewTicketBO.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM Ticket__c WHERE Carrier_Order__c = :objCO.Id], 'Ticket should not be created for Carrier Order.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Concession Negative Case
	 **/
	@isTest
	static void ticketCreationForConcessionNegativeCase() {
		List<Ticket__c> list_Ticket = new List<Ticket__c>();
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.objTicketRecord.Reporting_Team__c = 'Fulfillment';
			objExtension.objQCError.From_Sub_Team_s__c = 'Fulfillment';
			objExtension.objQCError.To_Sub_team__c = 'Fulfillment';
			objExtension.strSelectedTeam = 'Benefits Compliance';
			objExtension.subTeam();

			objExtension.strSelectedSubTeam = 'Implementation Advocate';
			objExtension.assignOwner();

			objExtension.strSelectedReason = 'Concession/Reimbursement';
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = 'Carrier Denied Group Application';
			objExtension.objTicketRecord.Team__c = 'Onboarding';
			objExtension.strSelectedReason = 'Concession/Reimbursement';
			objExtension.saveTicket();
		}
		Test.stopTest();

		list_Ticket = [SELECT id, Escalation_Reason__c FROM Ticket__c WHERE Carrier_Order__c = :objCO.Id];
		System.assertEquals(0, list_Ticket.size(), 'Ticket should not be created for Carrier Order.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Concession Reimbursement
	 **/
	@isTest
	static void ticketCreationForConcessionReimbursement() {
		List<Ticket__c> list_Ticket = new List<Ticket__c>();
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.objTicketRecord.Reporting_Team__c = 'Fulfillment';
			objExtension.objQCError.From_Sub_Team_s__c = 'Fulfillment';
			objExtension.strSelectedTeam = TicketUtil.TICKET_TEAM_ADVISING;
			objExtension.subTeam();
			objExtension.assignOwner();

			objExtension.strSelectedReason = 'Concession/Reimbursement';
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = 'Carrier Denied Group Application';
			objExtension.objTicketRecord.Summary__c = 'Test';
			objExtension.objTicketRecord.Description__c = 'Test';
			objExtension.saveTicket();

			objExtension.objTicketRecord.Error_Type__c = 'Plan Mismatch';
			objExtension.saveTicket();

			objExtension.objTicketRecord.Error_Origin__c = 'Sales';
			objExtension.saveTicket();

			objExtension.objTicketRecord.Error_Origin_Date__c = Date.today();
			objExtension.saveTicket();

			objExtension.objTicketRecord.Reimbursement_Amount_Requested__c = 2;
			objExtension.saveTicket();

			objExtension.objTicketRecord.Number_of_Discounted_Months_Requested__c = 2;
			objExtension.saveTicket();

			objExtension.objTicketRecord.Discount_Amount_Requested__c = 2;
			objExtension.saveTicket();
		}
		Test.stopTest();

		list_Ticket = [SELECT id, Escalation_Reason__c FROM Ticket__c WHERE Carrier_Order__c = :objCO.Id];
		System.assertEquals(4, list_Ticket.size(), 'A ticket needs to be created for Carrier Order');
		System.assertEquals('Concession/Reimbursement', list_Ticket[0].Escalation_Reason__c, 'Escalation Reason mismatch');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Fulfillment
	 **/
	@isTest
	static void testTicketCreationForFulfillment() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);

		Carrier_Order__c objCO = [SELECT Id, OwnerId FROM Carrier_Order__c LIMIT 1];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.strSelectedTeam = 'Onboarding';

			objExtension.subTeam();
			objExtension.strSelectedSubTeam = 'Fulfillment';
			objExtension.assignOwner();

			objExtension.strSelectedReason = 'Carrier Escalation';
			objExtension.ticketDetail();

			objExtension.objTicketRecord.Due_Date__c = Date.today();
			objExtension.strSelectedReasonDetail = 'Pending Item: Response Needed';
			objExtension.objTicketRecord.Summary__c = 'Test';
			objExtension.objTicketRecord.Description__c = 'Test';
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'Fulfillment'], 'Carrier IO ticket should be created.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Fulfillment positive
	 **/
	@isTest
	static void testTicketCreationForFulfillmentPos() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);

		Carrier_Order__c objCO = [SELECT Id, OwnerId, Confirmation_Owner__c FROM Carrier_Order__c WHERE Confirmation_Owner__c != NULL LIMIT 1];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.subTeam();

			objExtension.strSelectedSubTeam = 'Fulfillment';
			objExtension.assignOwner();

			objExtension.strSelectedReason = 'Carrier Escalation';
			objExtension.ticketDetail();

			objExtension.objTicketRecord.Due_Date__c = Date.today();
			objExtension.strSelectedReasonDetail = 'Pending Item: Response Needed';
			objExtension.objTicketRecord.Summary__c = 'Test1';
			objExtension.objTicketRecord.Description__c = 'Test1';
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(objCO.Confirmation_Owner__c, [SELECT OwnerId FROM Ticket__c WHERE Reporting_Team__c = 'Fulfillment'].OwnerId, 'Ticket Owner should be set to Confirmation Owner');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Implementation advocate
	 **/
	@isTest
	static void testTicketCreationForCarrierIOIA() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);

		Carrier_Order__c objCO = [SELECT Id, OwnerId FROM Carrier_Order__c LIMIT 1];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.subTeam();

			objExtension.strSelectedSubTeam = 'Implementation Advocate';
			objExtension.assignOwner();

			objExtension.strSelectedReason = 'Carrier Escalation';
			objExtension.ticketDetail();

			objExtension.objTicketRecord.Due_Date__c = Date.today();
			objExtension.strSelectedReasonDetail = 'Customer outreach required';
			objExtension.objTicketRecord.Summary__c = 'Test2';
			objExtension.objTicketRecord.Description__c = 'Test2';
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'Fulfillment'], 'Carrier IO ticket should be created.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for New plan sales
	 **/
	@isTest
	static void testTicketCreationForCarrierIONewPlan() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);

		Carrier_Order__c objCO = [SELECT Id, OwnerId FROM Carrier_Order__c LIMIT 1];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.strSelectedTeam = 'New Plan Sales';
			objExtension.assignOwner();

			objExtension.strSelectedReason = 'Carrier Escalation';
			objExtension.ticketDetail();

			objExtension.objTicketRecord.Due_Date__c = Date.today();

			objExtension.strSelectedReasonDetail = 'Customer outreach required';
			objExtension.objTicketRecord.Summary__c = 'Test2';
			objExtension.objTicketRecord.Description__c = 'Test2';
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'Fulfillment'], 'Carrier IO ticket should be created.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for benefit order status check when carrier order status is blocked.
	 **/
	@isTest
	public static void testBOStatus() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);
		Carrier_Order__c objCO = [SELECT Id, OwnerId, Benefit_Order__c FROM Carrier_Order__c LIMIT 1];
		objCO.OwnerId = UserInfo.getUserId();
		objCO.Confirmation_Owner__c = objIAUser.Id;
		CarrierOrderTriggerHelper.skipTrigger = true;
		update objCO;

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.objTicketRecord.Reporting_Team__c = 'Fulfillment';
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.subTeam();

			objExtension.strSelectedSubTeam = 'Implementation Advocate';
			objExtension.assignOwner();

			objExtension.strSelectedReason = 'Existing Group Coverage/BOR';
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = null;
			objExtension.objTicketRecord.Summary__c = 'Test2';
			objExtension.objTicketRecord.Description__c = 'Test2';
			objExtension.saveTicket();
		}
		Test.stopTest();

		objCO = [SELECT Id, OwnerId, Benefit_Order__c, Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :objCO.id];
		System.assertEquals('Blocked', objCO.Implementation_Stage__c, 'CO - Implementation Stage should be Blocked');

		Benefit_Order__c objBO = [SELECT Id, Name, Order_Status__c FROM Benefit_Order__c WHERE Id = :objCO.Benefit_Order__c];
		System.assertNotEquals('Blocked', objBO.Order_Status__c, 'BO - Order Status should not be Blocked');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for carrier order status is populated on Benefit order.
	 **/
	@isTest
	static void testBOStatusPos() {
		Test.startTest();
		User objIAUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c objCO = [SELECT Id, OwnerId, Benefit_Order__c FROM Carrier_Order__c LIMIT 1];
		objCO.OwnerId = UserInfo.getUserId();
		objCO.Confirmation_Owner__c = objIAUser.Id;
		CarrierOrderTriggerHelper.skipTrigger = true;
		update objCO;

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCO);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.objTicketRecord.Reporting_Team__c = 'Fulfillment';
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.subTeam();
			objExtension.strSelectedSubTeam = 'Implementation Advocate';
			objExtension.assignOwner();
			objExtension.strSelectedReason = 'Denial';
			objExtension.ticketDetail();

			objExtension.strSelectedReasonDetail = 'Carrier Denied Group Application';
			objExtension.objTicketRecord.Summary__c = 'Test2';
			objExtension.objTicketRecord.Description__c = 'Test2';
			objExtension.saveTicket();
		}
		Test.stopTest();

		objCO = [SELECT Id, OwnerId, Benefit_Order__c, Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :objCO.id];
		Ticket__c objTicket = [SELECT Id, Initial_Status__c FROM Ticket__c WHERE Carrier_Order__c = :objCO.Id];
		System.assertNotEquals(null, objTicket.Initial_Status__c, 'Intial Status for CO should be set');

		Benefit_Order__c objBO = [SELECT Id, Name, Order_Status__c FROM Benefit_Order__c WHERE Id = :objCO.Benefit_Order__c];
		System.assertEquals(objBO.Order_Status__c, objCO.Implementation_Stage__c, 'CO - Implementation Stage and BO - Order Status does not match');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Fulfillment having pending item for QA error
	 **/
	@isTest
	static void ticketCreationForFulfillmentQAError() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Id = :ID_LOGGED_USER][0];
		Carrier_Order__c objCarrierOrder = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', objCarrierOrder.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objCarrierOrder);
			NPRU_TicketButtonOnCODetailExt objExtension = new NPRU_TicketButtonOnCODetailExt(objStdController);
			objExtension.strSelectedTeam = 'Onboarding';
			objExtension.subTeam();
			objExtension.strSelectedSubTeam = 'Implementation Advocate';
			objExtension.assignOwner();
			objExtension.strSelectedReason = 'Pending Items';
			objExtension.strSelectedReasonDetail = 'Incomplete Form';
			objExtension.objTicketRecord.Summary__c = 'Test summary';
			objExtension.objTicketRecord.Description__c = 'Test summary';

			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM QA_Errors__c WHERE Error_Type__c = 'Pending Items'], 'Pending Items ticket should not be created.');
	}
}