@isTest
public class NPRU_TicketButtonOnBODetailExtTest {
	static final Id ID_LOGGED_USER = UserInfo.getUserId();
	static final Id ADVISING_INBOUND_QUEUE = TicketUtil.map_AdvisingQueue?.get('Advising_Inbound_Support');
	@testSetup
	private static void create_Test_Data() {
		BenefitOrderHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;

		Opportunity opp1 = TestUtility.BenefitsNewPlanOpportunity();

		Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('New Plan', opp1.Id, 'Test Benefit Order', true);

		objBO.Order_Status__c = 'OE';
		objBO.ownerID = ID_LOGGED_USER;
		objBO.UW_Owner__c = ID_LOGGED_USER;
		objBO.Coverage_Effective_Date__c = System.today();
		objBO.Open_Enrollment_Start_Date__c = System.today();
		objBO.Open_Enrollment_End_Date__c = System.today();
		objBO.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBO;

		Carrier__c testCarrier = new CArrier__c(State__c = 'FL');
		insert testCarrier;

		Carrier__c objCarrier = TestUtility.Carrier();

		Carrier_Order__c carOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		carOrder.Name = 'TEST CARRIER ORDER';
		carOrder.Carrier__c = testCarrier.Id;
		carOrder.Benefit_Order__c = objBO.Id;
		carOrder.Order_Type__c = 'New to Gusto';
		insert carOrder;

		Carrier_Order__c objCarrierOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarrierOrder.Name = 'TEST CARRIER ORDER';
		objCarrierOrder.Carrier__c = objCarrier.Id;
		objCarrierOrder.Benefit_Order__c = objBO.Id;
		objCarrierOrder.Order_Type__c = 'TAdA: Pre OE Setup';
		objCarrierOrder.OwnerId = ID_LOGGED_USER;
		objCarrierOrder.Confirmation_Owner__c = ID_LOGGED_USER;
		objCarrierOrder.Audit_Owner__c = ID_LOGGED_USER;
		insert objCarrierOrder;

		Carrier_Order__c objCarrierOrder1 = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarrierOrder1.Name = 'TEST CARRIER ORDER';
		objCarrierOrder1.Carrier__c = objCarrier.Id;
		objCarrierOrder1.Benefit_Order__c = objBO.Id;
		objCarrierOrder1.Order_Type__c = 'TAdA: Pre OE Setup';
		objCarrierOrder1.OwnerId = ID_LOGGED_USER;

		objCarrierOrder1.Audit_Owner__c = null;
		insert objCarrierOrder1;

		//update CO owner to user

		carOrder.OwnerId = ID_LOGGED_USER;
		carOrder.Confirmation_Owner__c = ID_LOGGED_USER;
		carOrder.Audit_Owner__c = ID_LOGGED_USER;
		update carOrder;

		List<Ticket_Mapping__c> list_Mappings = new List<Ticket_Mapping__c>();
		Ticket_Mapping__c objTicketMapping1 = new Ticket_Mapping__c();
		objTicketMapping1.Ticket_Reason_s__c = 'Customer Change Request';
		objTicketMapping1.Automated_QC_Error_Required__c = 'Yes';
		objTicketMapping1.Order_Status_when_Ticket_is_Closed__c = 'Ready for Qualification';
		objTicketMapping1.Order_Status_while_Ticket_is_Open__c = 'With Advising';
		objTicketMapping1.Ticket_Reason_Details__c = 'Carrier Change Requested';
		objTicketMapping1.From_Sub_Team_s__c = 'Implementation Advocate';
		objTicketMapping1.To_Team__c = 'Benefits Advising';
		list_Mappings.add(objTicketMapping1);

		Ticket_Mapping__c objTicketMapping2 = new Ticket_Mapping__c();
		objTicketMapping2.Ticket_Reason_s__c = 'Group Set Up Issue';
		objTicketMapping2.Automated_QC_Error_Required__c = 'Yes';
		objTicketMapping2.Order_Status_when_Ticket_is_Closed__c = 'Ready for Qualification';
		objTicketMapping2.Order_Status_while_Ticket_is_Open__c = 'With Advising';
		objTicketMapping2.Ticket_Reason_Details__c = 'Carrier Change Requested';
		objTicketMapping2.From_Sub_Team_s__c = '';
		objTicketMapping2.To_Team__c = 'Benefits Transfer';
		list_Mappings.add(objTicketMapping2);

		Ticket_Mapping__c objTicketMapping3 = new Ticket_Mapping__c();
		objTicketMapping3.Ticket_Reason_s__c = 'Cancel';
		objTicketMapping3.Automated_QC_Error_Required__c = 'Yes';
		objTicketMapping3.Order_Status_when_Ticket_is_Closed__c = 'Ready for Qualification';
		objTicketMapping3.Order_Status_while_Ticket_is_Open__c = 'With Advising';
		objTicketMapping3.Ticket_Reason_Details__c = 'Carrier Denial';
		objTicketMapping3.From_Sub_Team_s__c = '';
		objTicketMapping3.To_Team__c = 'New Plan Sales';
		list_Mappings.add(objTicketMapping3);

		Ticket_Mapping__c objTicketMapping4 = new Ticket_Mapping__c();
		objTicketMapping4.Ticket_Reason_s__c = 'Issue Clarification';
		objTicketMapping4.Automated_QC_Error_Required__c = 'Yes';
		objTicketMapping4.Order_Status_when_Ticket_is_Closed__c = 'Ready for Qualification';
		objTicketMapping4.Order_Status_while_Ticket_is_Open__c = 'With Advising';
		objTicketMapping4.Ticket_Reason_Details__c = '';
		objTicketMapping4.From_Sub_Team_s__c = '';
		objTicketMapping4.To_Team__c = 'Benefits Compliance';
		list_Mappings.add(objTicketMapping4);

		//Neha, For Submission
		Ticket_Mapping__c objTicketMapping5 = new Ticket_Mapping__c();
		objTicketMapping5.Ticket_Reason_s__c = 'Pending Items';
		objTicketMapping5.Automated_QC_Error_Required__c = 'Yes';
		objTicketMapping5.Order_Status_when_Ticket_is_Closed__c = 'Ready For Confirmation';
		objTicketMapping5.Order_Status_while_Ticket_is_Open__c = 'Pending Item';
		objTicketMapping5.Ticket_Reason_Details__c = 'Incomplete Form';
		objTicketMapping5.From_Sub_Team_s__c = 'Implementation Advocate';
		objTicketMapping5.To_Team__c = 'Onboarding';
		objTicketMapping5.To_Sub_Team__c = 'Fulfillment';
		list_Mappings.add(objTicketMapping5);

		//For Fulfillment
		Ticket_Mapping__c objTicketMapping7 = new Ticket_Mapping__c();
		objTicketMapping7.Ticket_Reason_s__c = 'New Hire enrollments not offered';
		objTicketMapping7.Automated_QC_Error_Required__c = 'NO';
		objTicketMapping7.Order_Status_when_Ticket_is_Closed__c = '';
		objTicketMapping7.Order_Status_while_Ticket_is_Open__c = '';
		objTicketMapping7.Ticket_Reason_Details__c = 'Other';
		objTicketMapping7.From_Sub_Team_s__c = 'Implementation Advocate';
		objTicketMapping7.To_Team__c = 'Onboarding';
		objTicketMapping7.To_Sub_Team__c = 'Fulfillment';
		list_Mappings.add(objTicketMapping7);

		//For Fulfillment
		Ticket_Mapping__c objTicketMapping9 = new Ticket_Mapping__c();
		objTicketMapping9.Ticket_Reason_s__c = 'TAdA Termination';
		objTicketMapping9.Automated_QC_Error_Required__c = 'Yes';
		objTicketMapping9.Order_Status_when_Ticket_is_Closed__c = 'Ready For Confirmation';
		objTicketMapping9.Order_Status_while_Ticket_is_Open__c = 'Pending Item';
		objTicketMapping9.Ticket_Reason_Details__c = 'Incomplete Form';
		objTicketMapping9.From_Sub_Team_s__c = 'Implementation Advocate';
		objTicketMapping9.To_Team__c = 'Onboarding';
		objTicketMapping9.To_Sub_Team__c = 'Fulfillment';
		list_Mappings.add(objTicketMapping9);

		Ticket_Mapping__c objTicketMapping10 = new Ticket_Mapping__c(
			Ticket_Reason_s__c = 'Licensing',
			Automated_QC_Error_Required__c = 'NO',
			Order_Status_when_Ticket_is_Closed__c = 'No Impact on Status',
			Order_Status_while_Ticket_is_Open__c = 'No Impact on Status',
			From_Sub_Team_s__c = 'Implementation Advocate',
			To_Team__c = 'Benefits Compliance',
			Action_Required_by_Ticket_Recipient__c = 'Licensing'
		);
		list_Mappings.add(objTicketMapping10);

		Ticket_Mapping__c objTicketMapping11 = new Ticket_Mapping__c(
			Ticket_Reason_s__c = 'Concession/Reimbursement',
			Automated_QC_Error_Required__c = 'NO',
			Order_Status_when_Ticket_is_Closed__c = 'No Impact on Status',
			Order_Status_while_Ticket_is_Open__c = 'No Impact on Status',
			From_Sub_Team_s__c = 'Implementation Advocate',
			To_Team__c = 'Benefits Compliance',
			Action_Required_by_Ticket_Recipient__c = 'Concession/Reimbursement'
		);
		list_Mappings.add(objTicketMapping11);

		State_Name_to_abbreviations_Mapping__c st = new State_Name_to_abbreviations_Mapping__c();
		st.Name = 'Alabama';
		st.State_Abbreviation__c = 'Alabama';
		st.State_Name__c = 'AL';
		insert st;

		//Ticket Mapping for carrier IO for New plan sales
		Ticket_Mapping__c objTicketMap = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Customer outreach required')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToTeam('New Plan Sales')
			.build();
		list_Mappings.add(objTicketMap);

		// Ticket Mapping for carrier IO for Fulfillment Pending Item: Response Needed
		Ticket_Mapping__c objTicketMap1 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Pending Item: Response Needed')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTicketMap1);

		// Ticket Mapping for carrier IO for Fulfillment Pending Item: Clarification Needed
		Ticket_Mapping__c objTicketMap01 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Pending Item: Clarification Needed')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTicketMap01);

		// Ticket Mapping for carrier IO for Fulfillment Response Needed
		Ticket_Mapping__c objTicketMap2 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Pending Item: Response Needed')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTicketMap2);

		// Ticket Mapping for carrier IO for Fulfillment Pending Item: Clarification Needed
		Ticket_Mapping__c objTicketMap02 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Pending Item: Clarification Needed')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Fulfillment')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTicketMap02);

		// Ticket Mapping for carrier IO for Implementation Advocate
		Ticket_Mapping__c objTicketMap3 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Carrier Escalation')
			.setTicketReasonDetails('Customer outreach required')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('Carrier IO')
			.setToSubTeam('Implementation Advocate')
			.setToTeam('Onboarding')
			.build();
		list_Mappings.add(objTicketMap3);

		//Ticket mapping for BYB Advocate
		Ticket_Mapping__c objTicketMap4 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('BYB Expedite Enrollment')
			.setOrderStatusWhenTicketIsClosed('No Impact on Status')
			.setOrderStatusWhenTicketIsOpen('No Impact on Status')
			.setFromSubTeam('BYB Advocate')
			.setToTeam('BYB Member Ops')
			.setTicketReasonDetails('')
			.build();
		list_Mappings.add(objTicketMap4);

		Ticket_Mapping__c objTicketMap5 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('BYB Unresponsive Customer')
			.setOrderStatusWhenTicketIsClosed('Back to status prior to ticket creation')
			.setOrderStatusWhenTicketIsOpen('With Sales')
			.setFromSubTeam('BYB Advocate')
			.setToTeam('BoR Sales')
			.setTicketReasonDetails('')
			.build();
		list_Mappings.add(objTicketMap5);

		Ticket_Mapping__c objTicketMap6 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('BYB Multiple brokers - Split lines of coverage')
			.setOrderStatusWhenTicketIsClosed('Back to status prior to ticket creation')
			.setOrderStatusWhenTicketIsOpen('With Advising')
			.setFromSubTeam('BYB Advocate')
			.setToTeam('Benefits Advising')
			.setTicketReasonDetails('')
			.build();
		list_Mappings.add(objTicketMap6);

		insert list_Mappings;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Account1').setOwnerId(UserInfo.getUserId()).build();
		insert objAccount;

		Opportunity objCompanyOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setAccountId(objAccount.Id)
			.setName('Test Company')
			.setStage(OpportunityUtil.SAL_STAGE)
			.build();
		insert objCompanyOpportunity;

		Benefit_Order__c objBOBYB = new TestDataFactory.BenefitOrderBuilder()
			.setName('Test BYB BO')
			.setStatus('Ready for Intro')
			.setAccount(objCompanyOpportunity.AccountId)
			.setOpp(objCompanyOpportunity.Id)
			.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB'))
			.build();
		objBOBYB.OwnerId = ID_LOGGED_USER;
		insert objBOBYB;
	}

	static testMethod void ticketCreationForAdvising() {
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;

		Opportunity objOpp = [SELECT Id, Owner_Role_Name__c, OwnerId FROM Opportunity LIMIT 1];
		objOpp.Owner_Role_Name__c = FWManageRoleUtil.ROLE_BENEFITS_DESIGNER;
		update objOpp;

		OpportunityTriggerHelper.skipTrigger = false;

		User objAdminUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		System.runAs(objAdminUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'All');
			ApexPages.StandardController objBOStandardCtrl = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objBOStandardCtrl);
			objExtension.strSelectedTeam = 'Benefits Advising';
			objExtension.subTeam();
			objExtension.strSelectedReason = 'Customer Change Request';
			objExtension.ticketDetail();
			objExtension.strSelectedReasonDetail = 'Carrier Change Requested';
			objExtension.updateTicketOwner();
			objExtension.saveTicket();
			objExtension.saveQCError();
		}

		Test.stopTest();

		List<Ticket__c> list_Tickets = [
			SELECT Id, OwnerId
			FROM Ticket__c
			WHERE Escalation_Reason__c = 'Customer Change Request'
		];
		System.assert(list_Tickets.size() > 0);
		System.assertEquals(objOpp.OwnerId, list_Tickets[0].OwnerId, 'Ticket owner should be Opportunity Owner');
	}

	static testMethod void ticketCreationForTransfer() {
		Test.startTest();
		//User adminUser = [Select Id From User Where Username = 'Implementation.Advocate@test.Implementation'];
		User adminUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUserRole = new User_Role__c(User__c = adminUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;
		Benefit_Order__c boObj = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		System.runAs(adminUser) {
			ApexPages.CurrentPage().getParameters().put('id', boObj.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController stdController = new ApexPages.StandardController(boObj);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(stdController);
			extension.strSelectedTeam = 'Benefit Transfer';
			extension.subTeam();
			//*extension.strSelectedReason = 'Group Set Up Issue';
			extension.ticketDetail();
			extension.strSelectedReasonDetail = '';
			extension.objTicketRecord.Team__c = 'Benefit Transfer';
			extension.saveTicket();
			extension.objQCError.To_Sub_team__c = '';
			extension.saveQCError();
		}

		Test.stopTest();

		system.assert([SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Group Set Up Issue' LIMIT 1] == 0);
	}

	static testMethod void ticketCreationForSales() {
		Test.startTest();
		//User adminUser = [Select Id From User Where Username = 'Implementation.Advocate@test.Implementation'];
		User adminUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUserRole = new User_Role__c(User__c = adminUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;
		Benefit_Order__c boObj = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		System.runAs(adminUser) {
			ApexPages.CurrentPage().getParameters().put('id', boObj.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController stdController = new ApexPages.StandardController(boObj);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(stdController);
			extension.strSelectedTeam = 'New Plan Sales';
			extension.subTeam();
			extension.strSelectedReason = 'Cancel';
			extension.strSelectedSubTeam = 'Implementation Advocate';
			extension.ticketDetail();
			extension.strSelectedReasonDetail = 'Carrier Denial';
			extension.objTicketRecord.Team__c = 'New Plan Sales';
			extension.saveTicket();
			extension.objTicketRecord.Due_Date__c = Date.today();
			extension.saveTicket();
			extension.objQCError.To_Sub_team__c = 'Implementation Advocate';
			extension.saveQCError();
		}

		Test.stopTest();

		system.assert([SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Cancel' LIMIT 1] == 1);
	}

	static testMethod void ticketCreationForCompliance() {
		Test.startTest();
		//User adminUser = [Select Id From User Where Username = 'Implementation.Advocate@test.Implementation'];
		User adminUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUserRole = new User_Role__c(User__c = adminUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;
		Benefit_Order__c boObj = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		System.runAs(adminUser) {
			ApexPages.CurrentPage().getParameters().put('id', boObj.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController stdController = new ApexPages.StandardController(boObj);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(stdController);
			extension.strSelectedTeam = 'Benefits Compliance';
			extension.subTeam();
			extension.strSelectedReason = 'Concession request';
			extension.strSelectedSubTeam = '';
			extension.ticketDetail();
			extension.strSelectedReasonDetail = '';
			extension.objTicketRecord.Team__c = 'Benefits Compliance';
			extension.saveTicket();
			extension.objQCError.To_Sub_team__c = 'Fulfillment';
			extension.saveQCError();
		}

		Test.stopTest();

		system.assert([SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Concession request' LIMIT 1] == 1);
	}
	//Neha, 13 Aug 2019, To cover the schenarios when to_Sub_Team is Fulfillment
	static testMethod void ticketCreationForFulfillment() {
		Test.startTest();
		//User adminUser = [Select Id From User Where Username = 'Implementation.Advocate@test.Implementation'];
		User adminUser = new User(Id = ID_LOGGED_USER);
		Benefit_Order__c boObj = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c LIMIT 1];
		System.runAs(adminUser) {
			ApexPages.CurrentPage().getParameters().put('id', boObj.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'All');
			ApexPages.StandardController stdController = new ApexPages.StandardController(boObj);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(stdController);
			extension.objTicketRecord.Team__c = 'Onboarding';
			extension.strSelectedTeam = 'Onboarding';

			extension.subTeam();
			extension.strSelectedSubTeam = 'Fulfillment';
			extension.strSelectedReason = 'Pending Items';
			extension.assignOwner();
			extension.ticketDetail();
			extension.strSelectedReasonDetail = 'Incomplete Form';

			extension.strSelectedSubTeam = 'Fulfillment';
			extension.strSelectedReason = 'TAdA Termination';
			extension.strSelectedReasonDetail = 'Incomplete Form';
			extension.ticketDetail();

			extension.strSelectedSubTeam = 'Fulfillment';
			extension.strSelectedCO = '';
			extension.objTicketRecord.Summary__c = 'test';
			extension.saveTicket();

			extension.strSelectedSubTeam = 'None';
			extension.saveTicket();

			extension.strSelectedSubTeam = 'Fulfillment';
			extension.strSelectedReason = 'Pending Items';
			extension.strSelectedReasonDetail = 'None';
			extension.saveTicket();

			extension.strSelectedCO = objCO.Id;
			extension.assignOwnerFromCO();

			extension.strSelectedReasonDetail = 'Incomplete Form';
			extension.saveTicket();
			extension.saveQCError();
		}

		Test.stopTest();
		system.assert([SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = 'Pending Items' LIMIT 1] == 1);
	}

	static testMethod void ticketCreationForTADA() {
		Test.startTest();
		User objUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUserRole = new User_Role__c(User__c = objUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c LIMIT 1];

		System.runAs(objUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'All');
			ApexPages.StandardController objBOStandardCtrl = new ApexPages.StandardController(objBO);

			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objBOStandardCtrl);
			objExtension.objTicketRecord.Team__c = 'Onboarding';
			objExtension.strSelectedTeam = 'Onboarding';

			objExtension.subTeam();
			objExtension.strSelectedSubTeam = 'Fulfillment';
			objExtension.strSelectedReason = 'TAdA Termination';

			objExtension.ticketDetail();
			objExtension.strSelectedReasonDetail = 'Incomplete Form';
			objExtension.objTicketRecord.Summary__c = 'test';
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assert([SELECT Id FROM Ticket__c WHERE Escalation_Reason__c = 'TAdA Termination'].size() > 0);
	}
	
	static testMethod void qcErrorCreationForFulfillment() {
		Test.startTest();
		User adminUser = new User(Id = ID_LOGGED_USER);
		Benefit_Order__c boObj = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		System.runAs(adminUser) {
			ApexPages.CurrentPage().getParameters().put('id', boObj.Id);
			ApexPages.StandardController stdController = new ApexPages.StandardController(boObj);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(stdController);
			extension.strSelectedTeam = 'Onboarding';

			extension.subTeam();
			extension.objQCError.To_Sub_team__c = 'Fulfillment';
			extension.strSelectedReason = 'New Hire enrollments not offered';
			extension.assignOwner();
			extension.ticketDetail();
			extension.strSelectedReasonDetail = 'Other';
			extension.objQCError.QA_Error_Team__c = 'Onboarding';

			extension.strSelectedCO = [SELECT Id FROM Carrier_Order__c LIMIT 1].Id;
			extension.assignOwnerFromCO();

			extension.saveQCError();
		}

		Test.stopTest();

		system.assert(
			[
				SELECT COUNT()
				FROM Ticket__c
				WHERE Escalation_Reason__c = 'New Hire enrollments not offered'
				LIMIT 1
			] == 0
		);
	}

	static testMethod void ticketCreationForFulfillmentAutomation() {
		Test.startTest();
		User objAdminUser = new User(Id = ID_LOGGED_USER);
		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c LIMIT 1];

		objCO.OwnerId = [SELECT ID FROM Group WHERE Name = 'Carrier Implementation Queue' LIMIT 1].Id;
		objCO.Sent_to_HI_for_Submission__c = true;
		update objCO;
		System.runAs(objAdminUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'All');
			ApexPages.StandardController objTicketStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objNewTicketBO = new NPRU_TicketButtonOnBODetailExt(objTicketStdController);
			objNewTicketBO.objTicketRecord.Team__c = 'Onboarding';
			objNewTicketBO.subTeam();
			objNewTicketBO.objTicketRecord.Team__c = 'Onboarding';
			objNewTicketBO.strSelectedSubTeam = 'Fulfillment';
			objNewTicketBO.assignOwner();
			objNewTicketBO.strSelectedReason = 'Pending Items';
			objNewTicketBO.strSelectedReasonDetail = 'Incomplete Form';
			objNewTicketBO.saveTicket();
		}

		Test.stopTest();

		System.assert([SELECT COUNT() FROM Ticket__c WHERE Carrier_Order__c = :objCO.Id LIMIT 1] == 0);
	}

	static testMethod void ticketCreationForConcessionReimbursement() {
		List<Ticket__c> list_Ticket = new List<Ticket__c>();
		Test.startTest();
		User objAdminUser = new User(Id = ID_LOGGED_USER);

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c LIMIT 1];

		System.runAs(objAdminUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(objStdController);
			extension.strSelectedTeam = 'Benefits Compliance';
			extension.subTeam();
			extension.strSelectedReason = 'Concession/Reimbursement';
			extension.strSelectedSubTeam = '';
			extension.ticketDetail();
			extension.strSelectedReasonDetail = '';
			extension.objTicketRecord.Team__c = 'Benefits Compliance';
			extension.saveTicket();

			List<Carrier__c> list_Carrier = [SELECT id FROM Carrier__c];
			extension.objTicketRecord.Carrier__c = list_Carrier[0].Id;
			extension.copyCarrierStatesToTicket();
			extension.saveTicket();

			extension.objTicketRecord.Error_Type__c = 'Plan Mismatch';
			extension.saveTicket();

			extension.objTicketRecord.Error_Origin__c = 'Sales';
			extension.saveTicket();

			extension.objTicketRecord.Error_Origin_Date__c = Date.today();
			extension.saveTicket();

			extension.objTicketRecord.Reimbursement_Amount_Requested__c = 2;
			extension.saveTicket();

			extension.objTicketRecord.Number_of_Discounted_Months_Requested__c = 2;
			extension.saveTicket();

			extension.objTicketRecord.Discount_Amount_Requested__c = 2;
			extension.saveTicket();

			list_Ticket = [SELECT id, Escalation_Reason__c FROM Ticket__c WHERE Benefit_Order__c = :objBO.Id];
			system.assert(list_Ticket.size() > 0);
		}

		Test.stopTest();

		System.assert(list_Ticket[0].Escalation_Reason__c == 'Concession/Reimbursement');
	}

	static testMethod void ticketCreationForLicensing() {
		List<Ticket__c> list_Ticket = new List<Ticket__c>();
		Test.startTest();
		User objAdminUser = new User(Id = ID_LOGGED_USER);

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c LIMIT 1];

		System.runAs(objAdminUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(objStdController);
			extension.strSelectedTeam = 'Benefits Compliance';
			extension.subTeam();
			extension.strSelectedReason = 'Licensing';
			extension.strSelectedSubTeam = '';
			extension.ticketDetail();
			extension.strSelectedReasonDetail = '';
			extension.objTicketRecord.Team__c = 'Benefits Compliance';
			extension.saveTicket();

			extension.objTicketRecord.Broker_s_Name__c = UserInfo.getUserId();
			extension.saveTicket();

			extension.objTicketRecord.Broker_s_Team__c = 'Sales';
			extension.saveTicket();

			extension.objTicketRecord.Broker_s_Home_State__c = 'LA';
			extension.saveTicket();

			list_Ticket = [SELECT id, Escalation_Reason__c FROM Ticket__c WHERE Benefit_Order__c = :objBO.Id];
			system.assert(list_Ticket.size() > 0);
		}

		Test.stopTest();

		System.assert(list_Ticket[0].Escalation_Reason__c == 'Licensing');
	}

	static testMethod void ticketCreationForConcessionNegativeCase() {
		List<Ticket__c> list_Ticket = new List<Ticket__c>();
		Test.startTest();
		User objAdminUser = new User(Id = ID_LOGGED_USER);

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c LIMIT 1];

		System.runAs(objAdminUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(objStdController);
			extension.strSelectedTeam = 'Benefits Compliance';
			extension.subTeam();
			extension.strSelectedReason = 'Concession/Reimbursement';
			extension.strSelectedSubTeam = '';
			extension.ticketDetail();
			extension.strSelectedReasonDetail = '';
			extension.objTicketRecord.Team__c = 'Benefits Compliance';
			extension.saveTicket();

			//validate required field messsage
			for (ApexPages.Message msg : ApexPages.getMessages()) {
				System.assertEquals(TicketUtil.REQ_MSG_CARRIER, msg.getSummary());
			}
		}

		Test.stopTest();

		//Ticket record should not be created
		list_Ticket = [SELECT id, Escalation_Reason__c FROM Ticket__c WHERE Benefit_Order__c = :objBO.Id];
		system.assert(list_Ticket.size() == 0);
	}

	static testMethod void ticketCreationForLicensingNegativeCase() {
		List<Ticket__c> list_Ticket = new List<Ticket__c>();
		Test.startTest();
		User objAdminUser = new User(Id = ID_LOGGED_USER);

		User_Role__c objUserRole = new User_Role__c(User__c = objAdminUser.Id, User_Skill_Team__c = 'Implementation Advocate', User_Skill_Type__c = 'Core');
		insert objUserRole;

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c LIMIT 1];

		System.runAs(objAdminUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.CurrentPage().getParameters().put('sortField', 'Escalation_Reason__c');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt extension = new NPRU_TicketButtonOnBODetailExt(objStdController);
			extension.strSelectedTeam = 'Benefits Compliance';
			extension.subTeam();
			extension.strSelectedReason = 'Licensing';
			extension.strSelectedSubTeam = '';
			extension.ticketDetail();
			extension.strSelectedReasonDetail = '';
			extension.objTicketRecord.Team__c = 'Benefits Compliance';
			extension.saveTicket();

			//validate required field messsage
			for (ApexPages.Message msg : ApexPages.getMessages()) {
				System.assertEquals(TicketUtil.REQ_MSG_BROKERS_NAME, msg.getSummary());
			}
		}

		Test.stopTest();

		//Ticket record should not be created
		list_Ticket = [SELECT id, Escalation_Reason__c FROM Ticket__c WHERE Benefit_Order__c = :objBO.Id];
		system.assert(list_Ticket.size() == 0);
	}

	/**
	 * @author      : Deepika Saini
	 * @description : Test method for ticket creation for Carrier IO role
	 * @param        : N/A
	 * @return      : N/A
	 **/
	@isTest
	static void testTicketCreationForCarrierIO() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUsereRole = new TestDataFactory.UserRoleBuilder().setUserId(objIAUser.id).setUserTeam('Carrier IO').setUserSkillType('Core').build();
		insert objUsereRole;

		Benefit_Order__c objBO = [
			SELECT Id
			FROM Benefit_Order__c
			WHERE recordType.name = 'New Plan'
			LIMIT 1
		];
		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objStdController);
			objExtension.strSelectedTeam = 'New Plan Sales';

			objExtension.assignOwner();

			objExtension.strSelectedReason = 'Carrier Escalation';
			objExtension.ticketDetail();

			objExtension.objTicketRecord.Due_Date__c = Date.today();

			objExtension.strSelectedReasonDetail = 'Customer outreach required';
			objExtension.saveTicket();
		}
		Test.stopTest();

		system.assert([SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'Carrier IO' LIMIT 1] > 0);
	}

	/**
	 * @author      : Deepika Saini
	 * @description : Test method for ticket creation for Carrier IO role for Implementation advocate
	 * @param        : N/A
	 * @return      : N/A
	 **/
	@isTest
	static void testTicketCreationForCarrierIOIA() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUsereRole = new TestDataFactory.UserRoleBuilder().setUserId(objIAUser.id).setUserTeam('Carrier IO').setUserSkillType('Core').build();
		insert objUsereRole;

		Benefit_Order__c objBO = [
			SELECT Id
			FROM Benefit_Order__c
			LIMIT 1
		];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objStdController);
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

		system.assert([SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'Carrier IO' LIMIT 1] > 0);
	}

	/**
	 * @author      : Deepika Saini
	 * @description : Test method for ticket creation for Carrier IO role for Fulfillment
	 * @param        : N/A
	 * @return      : N/A
	 **/
	@isTest
	static void testTicketCreationForCarrierIOCon() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUsereRole = new TestDataFactory.UserRoleBuilder().setUserId(objIAUser.id).setUserTeam('Carrier IO').setUserSkillType('Core').build();
		insert objUsereRole;

		Benefit_Order__c objBO = [
			SELECT Id
			FROM Benefit_Order__c
			LIMIT 1
		];
		Carrier_Order__c objCO = [
			SELECT id, name, Order_Type__c, Confirmation_Owner__c, Audit_Owner__c
			FROM Carrier_Order__c
			WHERE Confirmation_Owner__c != NULL
			LIMIT 1
		];
		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objStdController);
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
			objExtension.strSelectedCO = objCO.Id;
			objExtension.assignOwnerFromCO();
			objExtension.saveTicket();
		}
		Test.stopTest();
		Ticket__c objT = [SELECT id, ownerID FROM Ticket__c];
		system.assertEquals(objT.ownerID, objCO.Confirmation_Owner__c);
	}

	/**
	 * @author      : Deepika Saini
	 * @description : Test method for ticket creation for Carrier IO role for Fulfillment negative
	 * @param        : N/A
	 * @return      : N/A
	 **/
	@isTest
	static void testTicketCreationForCarrierIOfulNeg() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUsereRole = new TestDataFactory.UserRoleBuilder().setUserId(objIAUser.id).setUserTeam('Carrier IO').setUserSkillType('Core').build();
		insert objUsereRole;

		Benefit_Order__c objBO = [
			SELECT Id, (SELECT id, name FROM Carrier_Orders__r WHERE Order_Type__c = 'TAdA: Pre OE Setup')
			FROM Benefit_Order__c
			LIMIT 1
		];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objStdController);
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
			objExtension.strSelectedCO = null;
			objExtension.assignOwnerFromCO();
			objExtension.saveTicket();
		}
		Test.stopTest();

		system.assert([SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'Carrier IO' LIMIT 1] == 0);
		ApexPages.Message[] objPageMessage = ApexPages.getMessages();
		System.assertNotEquals(0, objPageMessage.size());

		Boolean blnIsMessageFound = false;

		for (ApexPages.Message objMessage : objPageMessage) {
			if (
				objMessage.getSummary() == TicketUtil.REQ_MSG_ASSOCIATED_CARRIER &&
				objMessage.getSeverity() == ApexPages.Severity.Error
			) {
				blnIsMessageFound = true;
			}
		}
		System.assert(blnIsMessageFound);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for BYB MEmeber OPs
	 * @param         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testTicketCreationForBYBMOps() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUsereRole = new TestDataFactory.UserRoleBuilder().setUserId(objIAUser.id).setUserTeam('BYB Advocate').setUserSkillType('Core').build();
		insert objUsereRole;

		Benefit_Order__c objBO = [
			SELECT Id
			FROM Benefit_Order__c
			WHERE Name = 'Test BYB BO'
			LIMIT 1
		];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objStdController);
			objExtension.strSelectedTeam = 'BYB Member Ops';
			objExtension.assignOwner();
			objExtension.strSelectedReason = 'BYB Expedite Enrollment';
			objExtension.ticketDetail();
			objExtension.objTicketRecord.Description__c = 'Test1';
			objExtension.strSelectedCO = null;
			objExtension.assignOwnerFromCO();
			objExtension.saveTicket();
		}

		Test.stopTest();

		System.assert([SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'BYB Advocate' LIMIT 1] > 0);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for BOR Sales
	 * @param         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testTicketCreationForBORSales() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUsereRole = new TestDataFactory.UserRoleBuilder().setUserId(objIAUser.id).setUserTeam('BYB Advocate').setUserSkillType('Core').build();
		insert objUsereRole;

		Benefit_Order__c objBO = [
			SELECT Id
			FROM Benefit_Order__c
			WHERE Name = 'Test BYB BO'
			LIMIT 1
		];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objStdController);
			objExtension.strSelectedTeam = 'BoR Sales';
			objExtension.assignOwner();
			objExtension.strSelectedReason = 'BYB Unresponsive Customer';
			objExtension.ticketDetail();
			objExtension.strSelectedReasonDetail = 'None';
			objExtension.objTicketRecord.Description__c = 'Test1';
			objExtension.saveTicket();
		}
		Test.stopTest();

		Ticket__c objTicket = [SELECT Id, Name, Initial_Status__c FROM Ticket__c WHERE Reporting_Team__c = 'BYB Advocate' LIMIT 1];
		System.assert(objTicket.Initial_Status__c != null);
		System.assert([SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'BYB Advocate' LIMIT 1] > 0);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Benefit Advising
	 * @param         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testTicketCreationForBenefitAdvising() {
		Test.startTest();
		User objIAUser = new User(Id = ID_LOGGED_USER);
		User_Role__c objUsereRole = new TestDataFactory.UserRoleBuilder().setUserId(objIAUser.id).setUserTeam('BYB Advocate').setUserSkillType('Core').build();
		insert objUsereRole;

		Benefit_Order__c objBO = [
			SELECT Id
			FROM Benefit_Order__c
			WHERE Name = 'Test BYB BO'
			LIMIT 1
		];

		System.runAs(objIAUser) {
			ApexPages.CurrentPage().getParameters().put('id', objBO.Id);
			ApexPages.CurrentPage().getParameters().put('selectedView', 'My');
			ApexPages.StandardController objStdController = new ApexPages.StandardController(objBO);
			NPRU_TicketButtonOnBODetailExt objExtension = new NPRU_TicketButtonOnBODetailExt(objStdController);
			objExtension.strSelectedTeam = 'Benefits Advising';
			objExtension.assignOwner();
			objExtension.strSelectedReason = 'BYB Multiple brokers - Split lines of coverage';
			objExtension.ticketDetail();
			objExtension.objTicketRecord.Description__c = 'Test1';
			objExtension.strSelectedCO = null;
			objExtension.assignOwnerFromCO();
			objExtension.saveTicket();
		}
		Test.stopTest();

		System.assert([SELECT COUNT() FROM Ticket__c WHERE Reporting_Team__c = 'BYB Advocate' LIMIT 1] > 0);
	}
}