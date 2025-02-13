@isTest
private without sharing class TicketTriggerHelperTest {
	@testsetup
	static void setupData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		List<Account> list_objAccounts = new List<Account>();
		Account objAccRec = new TestDataFactory.AccountBuilder()
			.setName('Test Demo AccountName 1')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setBillingStreet('Testing Avenue 1')
			.setBillingPostalCode('123456')
			.setPhone('19992344444')
			.setCompanyTradeName('Company trade name 1')
			.setShippingStreet('Testing Avenue 1')
			.setShippingPostalCode('123455')
			.build();
		list_objAccounts.add(objAccRec);

		Account objPartnerAcc = new TestDataFactory.AccountBuilder()
			.setName('Test Partner Acc')
			.setAccountType('Software Partner')
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Partner'))
			.build();

		list_objAccounts.add(objPartnerAcc);

		insert list_objAccounts;

		Contact objContact = new TestDataFactory.ContactBuilder().setLastName('Test Contact').setAccountId(objAccRec.Id).setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID).build();
		insert objContact;

		List<Ticket_Mapping__c> list_objTicketMapping = new List<Ticket_Mapping__c>();
		Ticket_Mapping__c objTM = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Customer Change Request')
			.setTicketReasonDetails('Carrier Change Requested')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('With Advising')
			.setFromSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setToTeam(TicketUtil.TICKET_TEAM_ADVISING)
			.build();

		list_objTicketMapping.add(objTM);

		Ticket_Mapping__c objTM1 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Group Set Up Issue')
			.setTicketReasonDetails('Carrier Change Requested')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('With Advising')
			.setFromSubTeam('')
			.setToTeam(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.build();

		list_objTicketMapping.add(objTM1);

		Ticket_Mapping__c objTM2 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Cancel')
			.setTicketReasonDetails('Carrier Denial')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('With Advising')
			.setFromSubTeam('')
			.setToTeam(TicketUtil.TICKET_TEAM_NEW_PLAN_SALES)
			.build();

		list_objTicketMapping.add(objTM2);

		Ticket_Mapping__c objTM3 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Issue Clarification')
			.setTicketReasonDetails('')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('With Advising')
			.setFromSubTeam('')
			.setToTeam(TicketUtil.TICKET_TEAM_BENEFIT_COMPLAINCE)
			.build();

		list_objTicketMapping.add(objTM3);

		Ticket_Mapping__c objTM4 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Pending Items')
			.setTicketReasonDetails('Incomplete Form')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('Awaiting Routing')
			.setToSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setFromSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setToTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setFromTeamProcessStep(TicketUtil.TICKET_TEAM_ONBOARDING)
			.build();
		list_objTicketMapping.add(objTM4);

		Ticket_Mapping__c objTM5 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setTicketReasonDetails('Self Funded')
			.setAutomatedQCErrorRequired('Yes')
			.setOrderStatusWhenTicketIsClosed('Back to status prior to ticket creation')
			.setOrderStatusWhenTicketIsOpen('Awaiting Routing')
			.setFromSubTeam('Advocate')
			.setToTeam(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.setToSubTeam('Qualifier')
			.setFromTeamProcessStep('')
			.setUpdateOrderStatus('BO And All CO')
			.build();
		list_objTicketMapping.add(objTM5);

		Ticket_Mapping__c objTM6 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Insufficient Data')
			.setTicketReasonDetails('Incorrect rates for plan year')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('Back to status prior to ticket creation')
			.setOrderStatusWhenTicketIsOpen('Implementing Plans')
			.setToSubTeam(TicketUtil.STR_FACILITATOR_1)
			.setFromSubTeam(TicketUtil.STR_FACILITATOR_2)
			.setToTeam(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.setFromTeamProcessStep(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.setUpdateOrderStatus(TicketUtil.STR_ONLY_AFFECTED_CO)
			.build();
		list_objTicketMapping.add(objTM6);

		Ticket_Mapping__c objTM7 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Rate Discrepancy')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('Approved Pending EE Audit')
			.setOrderStatusWhenTicketIsOpen('Awaiting Routing')
			.setToSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setFromSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setToTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setFromTeamProcessStep(TicketUtil.TICKET_TEAM_ONBOARDING)
			.build();
		list_objTicketMapping.add(objTM7);

		Ticket_Mapping__c objTM8 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setTicketReasonDetails('Waiting Period Does Not Meet Requirements')
			.setAutomatedQCErrorRequired('No')
			.setOrderStatusWhenTicketIsClosed('Ready for Qualification')
			.setOrderStatusWhenTicketIsOpen('Requires ER Outreach')
			.setToSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setFromSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setToTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.build();
		list_objTicketMapping.add(objTM8);

		//Ticket mapping for BYB Advocate
		Ticket_Mapping__c objTM9 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('BYB Unresponsive Customer')
			.setOrderStatusWhenTicketIsClosed('Back to status prior to ticket creation')
			.setOrderStatusWhenTicketIsOpen('With Sales')
			.setFromSubTeam('BYB Advocate')
			.setToTeam(TicketUtil.TICKET_TEAM_BOR_SALES)
			.setTicketReasonDetails('')
			.build();
		list_objTicketMapping.add(objTM9);

		Ticket_Mapping__c objTM10 = new TestDataFactory.TicketMappingBuilder()
			.setTicketReason('Incorrect package submitted to carrier')
			.setOrderStatusWhenTicketIsClosed('Ready for Confirmation')
			.setOrderStatusWhenTicketIsOpen('Ready for Submission Prep')
			.setFromSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setToTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setToSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.build();
		list_objTicketMapping.add(objTM10);

		insert list_objTicketMapping;

		Opportunity objOpptyRenewals = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
			.setName('OppRecord')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(Date.newInstance(2016, 12, 9))
			.setAccountId(objAccRec.Id)
			.build();

		Opportunity objOpptyBOR = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Opp BoR')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(Date.newInstance(2016, 12, 9))
			.setAccountId(objAccRec.Id)
			.build();

		Opportunity objTaxCreditsOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setName('Test Oppty for Auto Task Creation')
			.setStage(OpportunityUtil.NEW_STAGE)
			.setCloseDate(Date.newInstance(2024, 12, 9))
			.build();

		Opportunity objTaxCreditsOppty2 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setName('Test Oppty for Auto Task Creation')
			.setStage(OpportunityUtil.NEW_STAGE)
			.setCloseDate(Date.newInstance(2024, 12, 9))
			.build();

		insert new List<Opportunity>{ objOpptyRenewals, objOpptyBOR, objTaxCreditsOppty, objTaxCreditsOppty2 };

		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setName('TEST BENEFIT ORDER')
			.setRecordType(BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID)
			.setOpp(objOpptyRenewals.Id)
			.setStatus(BenefitOrderUtil.STATUS_FULFILLED)
			.setQualificationOwner(UserInfo.getUserId())
			.setOwnerId(UserInfo.getUserId())
			.build();

		Benefit_Order__c objBenefitOrderBOR = new TestDataFactory.BenefitOrderBuilder()
			.setName('TEST BENEFIT ORDER BoR')
			.setRecordType(BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID)
			.setOpp(objOpptyBOR.Id)
			.setOwnerId(UserInfo.getUserId())
			.build();

		insert new List<Benefit_Order__c>{ objBenefitOrder, objBenefitOrderBOR };

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test').setUniqueName('Test').setState('CA').build();
		insert objCarrier;

		Carrier_Play_Information__c objCarrierPlay = new TestDataFactory.CarrierPlayInformationBuilder()
			.setFrom(26)
			.setTo(31)
			.setEventType('Order')
			.setPlayModeType(TicketUtil.STR_POST_PLAY)
			.setBeforeAfter(TicketUtil.BEFORE_ONWARD_EVENT)
			.setCarrier(objCarrier.Id)
			.build();
		insert objCarrierPlay;

		Carrier_Order__c objCo = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setBenefitOrder(objBenefitOrder.Id)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO)
			.setRecordTypeId(CarrierOrderUtil.RECTYPE_NEW_PLAN)
			.setImplementationStage(CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_QUALIFICATION)
			.setOwnerId(UserInfo.getUserId())
			.setBenefitTypes('Test')
			.build();
		Carrier_Order__c objCOBoR = new TestDataFactory.CarrierOrderbuilder()
			.setName('TEST CARRIER ORDER BoR')
			.setCarrier(objCarrier.Id)
			.setBenefitOrder(objBenefitOrderBOR.Id)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION)
			.setRecordTypeId(CarrierOrderUtil.REC_TYPE_BOR)
			.setOwnerId(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.build();
		insert new List<Carrier_Order__c>{ objCO, objCOBoR };

		Carrier_Order__c objCOBoRChild = new TestDataFactory.CarrierOrderbuilder()
			.setName('TEST CARRIER ORDER BoR')
			.setCarrier(objCarrier.Id)
			.setBenefitOrder(objBenefitOrderBOR.Id)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO)
			.setImplementationStage(CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION)
			.setRecordTypeId(CarrierOrderUtil.REC_TYPE_BOR)
			.setOwnerId(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.setParentCarrierOrder(objCOBoR.Id)
			.build();
		insert objCOBoRChild;

		Order objOrder = new TestDataFactory.OrderBuilder()
			.setAccountId(objAccRec.Id)
			.setOpportunityId(objOpptyRenewals.Id)
			.setActiveEECount(10)
			.setEffectiveDate(System.today())
			.setStatus('Drafted')
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setOwnerId(UserInfo.getUserId())
			.build();

		insert objOrder;

		List<Case> list_Cases = new List<Case>();
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_BENEFITS_RENEWAL_CASE)
			.setAccountId(objAccRec.Id)
			.setSubject('Test Relation')
			.setDescription('Test Relation')
			.setSuppliedEmail('TickettriggerHelper@gusto.com')
			.setType(CaseUtils.TYPE_SALES)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.build();
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccRec.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Phone')
			.setSubject('Test Ticket insertion triggering insert/update TicketTRigger')
			.setDescription('Test')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase2);
		insert list_Cases;

		//Record for BYOB
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Account1').setOwnerId(UserInfo.getUserId()).build();

		insert objAccount;

		Opportunity objCompanyOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID)
			.setAccountId(objAccount.Id)
			.setName('Test Company')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(System.today())
			.build();
		insert objCompanyOpportunity;

		Benefit_Order__c objBOBYB = new TestDataFactory.BenefitOrderBuilder()
			.setName('Test BYB BO')
			.setStatus(BenefitOrderUtil.STATUS_READY_FOR_INTRO)
			.setAccount(objCompanyOpportunity.AccountId)
			.setOpp(objCompanyOpportunity.Id)
			.setRecordType(BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID)
			.setOwnerID(UserInfo.getUserId())
			.build();

		insert objBOBYB;
		TicketTriggerHelper.skipTrigger = true;
		List<Ticket__c> list_objTickets = new List<Ticket__c>();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setDescription('Test Ardius')
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.build();
		list_objTickets.add(objTicket);

		Ticket__c objTicketCloseDate = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setDescription('Test Ardius Ticket')
			.setOwnerId(UserInfo.getUserId())
			.setAnticipatedCloseDate(system.today() + 1)
			.setRecordTypeId(Ticketutil.ARDIUS_TICKET_RT_ID)
			.build();
		list_objTickets.add(objTicketCloseDate);

		insert list_objTickets;
		TicketTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testPayrollSalesEscalationTkt() {
		Test.startTest();
		Order objOrder = [SELECT Id FROM Order LIMIT 1];
		Ticket__c objTkt = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.PAYROLL_SALES_ESCALATION_RT_ID)
			.setEscalationReason('Missing Information')
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setOwnerId(UserInfo.getUserId())
			.setOrderId(objOrder.Id)
			.build();
		insert objTkt;

		objTkt = [SELECT Id, OwnerId, Opportunity__c, Opportunity__r.OwnerId FROM Ticket__c WHERE Id = :objTkt.Id];
		System.assertNotEquals(null, objTkt.Opportunity__c, 'Opportunity should be populated from Order');
		System.assertEquals(objTkt.OwnerId, objTkt.Opportunity__r.OwnerId, 'Owner should be same as Oppty Owner');
		Test.stopTest();
	}

	@isTest
	static void testAdvisingFulfilmentCustomerChangeReq() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		Case objCase = [SELECT Id FROM Case LIMIT 1];
		Ticket__c objTkt = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.build();
		insert objTkt;

		objTkt.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTkt.Close_Reason__c = 'NA';
		objTkt.Escalation_Reason__c = 'Customer Change Request';
		objTkt.Escalation_Reason_Detail__c = 'Carrier Change Requested';
		objTkt.Reporting_Team__c = TicketUtil.TICKET_ROLE_IMPLEMENTATION;
		objTkt.Team__c = TicketUtil.TICKET_TEAM_ADVISING;
		objTkt.Benefit_Order__c = objBO.Id;
		update objTkt;

		Test.stopTest();

		List<Benefit_Order__c> lstBenefitOrder = [SELECT Id, Order_Status__c FROM Benefit_Order__c WHERE Id = :objBO.Id];
		System.assertEquals(lstBenefitOrder[0].Order_Status__c, BenefitOrderUtil.STATUS_READY_FOR_QUALIFICATION, 'Status should be Ready For Qualification');

		delete objTkt;
		undelete objTkt;
	}

	@isTest
	static void testEROutreachTkt() {
		Test.startTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		Case objCase = [SELECT Id FROM Case LIMIT 1];
		List<Ticket__c> list_Tickets = new List<Ticket__c>();

		Ticket__c objTkt = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCO.Id)
			.setEscalationReason('Pending Items')
			.setEscalationReasonDetail('Incomplete Form')
			.setReportingTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.build();
		list_Tickets.add(objTkt);

		Ticket__c objTkt2 = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCO.Id)
			.setEscalationReason('Pending Items')
			.setEscalationReasonDetail('Incomplete Form')
			.setReportingTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.build();
		objTkt2.ER_Outreach_count__c = 1;
		objTkt2.ER_Outreach_Comments__c = '[' + System.now() + '] test';
		objTkt2.ER_Outreach_Date__c = System.today();

		list_Tickets.add(objTkt2);
		insert list_Tickets;

		objTkt.ER_Outreach_count__c = 1;
		objTkt.ER_Outreach_Comments__c = '[' + System.now() + '] test';
		objTkt.ER_Outreach_Date__c = System.today();

		objBO.Order_Status__c = TicketUtil.TICKET_STATUS_ER_OUTREACH_REQ;
		update objBO;
		update objTkt;

		//objTkt.Status__c = 'Awaiting ER response - Pending Item';
		//update objTkt;

		objTkt.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTkt.Close_Reason__c = 'NA';
		update objTkt;

		Test.stopTest();
	}

	@isTest
	static void testBenefitsBoRTkt() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID LIMIT 1];
		Carrier_Order__c objCarrierOrder = [SELECT Id FROM Carrier_Order__c WHERE Benefit_Order__c = :objBenefitOrder.Id LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setEscalationReason(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReasonDetail('Self Funded')
			.setReportingTeam('Advocate')
			.setTeam(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.setSubTeam('Qualifier')
			.setBenefitOrderId(objBenefitOrder.Id)
			.setCarrierOrderId(objCarrierOrder.Id)
			.setInitialStatus('Ready for Qualification')
			.build();
		insert objTicket;

		objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket.Close_Reason__c = 'NA';

		update objTicket;

		Test.stopTest();
	}

	@isTest
	static void testBenefitsBoRBOCOTkt() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID LIMIT 1];
		Carrier_Order__c objCarrierOrder = [SELECT Id FROM Carrier_Order__c WHERE Benefit_Order__c = :objBenefitOrder.Id AND Parent_Carrier_Order__c = NULL LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setEscalationReason('Insufficient Data')
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReasonDetail('Incorrect rates for plan year')
			.setReportingTeam(TicketUtil.STR_FACILITATOR_2)
			.setTeam(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.setSubTeam(TicketUtil.STR_FACILITATOR_2)
			.setBenefitOrderId(objBenefitOrder.Id)
			.setCarrierOrderId(objCarrierOrder.Id)
			.setInitialStatus('Ready for Qualification')
			.build();
		insert objTicket;

		objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket.Close_Reason__c = 'NA';

		update objTicket;

		Test.stopTest();
	}

	@isTest
	static void testFulfilledTkt() {
		Test.startTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		Case objCase = [SELECT Id FROM Case LIMIT 1];

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setEscalationReason('Rate Discrepancy')
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReasonDetail('Incorrect rates for plan year')
			.setReportingTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCO.Id)
			.setCloseDate(System.today().adddays(15))
			.setErrorOrigin('Benefit Transfer Fulfillment')
			.setRateDiscrepencyResolution('No Error')
			.build();
		insert objTicket;

		objTicket.Error_Origin__c = 'Sales';
		objTicket.Error_Origin_Details__c = TicketUtil.TICKET_TEAM_BOR_SALES;
		objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket.Close_Reason__c = 'NA';
		update objTicket;

		Test.stopTest();
	}

	@isTest
	static void testAdvisingFulfilmentBOTkt() {
		Test.startTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID LIMIT 1];
		Case objCase = [SELECT Id FROM Case LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.build();
		insert objTicket;

		objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket.Close_Reason__c = 'NA';
		objTicket.Escalation_Reason__c = 'Customer Change Request';
		objTicket.Escalation_Reason_Detail__c = 'Carrier Change Requested';
		objTicket.Reporting_Team__c = TicketUtil.TICKET_ROLE_IMPLEMENTATION;
		objTicket.Team__c = TicketUtil.TICKET_TEAM_ADVISING;
		objTicket.Benefit_Order__c = objBO.Id;
		update objTicket;

		Test.stopTest();
	}

	@isTest
	static void testBenefitsBoRTkt1() {
		Test.startTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReason(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setEscalationReasonDetail('Self Funded')
			.setReportingTeam('Advocate')
			.setTeam(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.setSubTeam('Qualifier')
			.setBenefitOrderId(objBO.Id)
			.setInitialStatus('Ready for Qualification')
			.build();
		insert objTicket;

		objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket.Close_Reason__c = 'NA';

		update objTicket;

		Test.stopTest();
	}

	@isTest
	static void markrerouting() {
		Test.startTest();
		User objMDRUser = new TestDataFactory.UserBuilder()
			.setAlias('mdruser')
			.setEmail('mdruser@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('mdruser@testorg.com')
			.setUserRoleId([SELECT Id FROM UserRole WHERE Name = 'sales_sdr_partner_xx' LIMIT 1][0].Id)
			.build();
		insert objMDRUser;
		TicketTriggerHelper obj = new TicketTriggerHelper();
		Boolean blnrerouting = obj.markRequiresRerouting(objMDRUser);
		Test.stopTest();
	}

	@isTest
	static void testSetTimeToFirstResponse() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setEscalationReason(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReasonDetail('Self Funded')
			.setReportingTeam('Advocate')
			.setTeam(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.setSubTeam('Qualifier')
			.setBenefitOrderId(objBenefitOrder.Id)
			.setInitialStatus('Ready for Qualification')
			.build();
		insert objTicket;

		objTicket.OwnerId = UserInfo.getUserId();
		objTicket.Status__c = TicketUtil.TICKET_STATUS_INPROGRESS;
		update objTicket;

		Ticket__c objUpdatedTicket = [SELECT Id, InProgress_Date_Time__c FROM Ticket__c WHERE Id = :objTicket.Id LIMIT 1];
		System.assertEquals(objUpdatedTicket.InProgress_Date_Time__c.date(), System.now().date(), 'Not assigned to a User');
	}

	@isTest
	static void testSetTimeToFirstResponseNegative() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setEscalationReason(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReasonDetail('Self Funded')
			.setReportingTeam('Advocate')
			.setTeam(TicketUtil.TICKET_BENEFIT_TRANSFER)
			.setSubTeam('Qualifier')
			.setBenefitOrderId(objBenefitOrder.Id)
			.setInitialStatus('Ready for Qualification')
			.build();
		insert objTicket;

		List<QueueSobject> list_Queues = [SELECT QueueId FROM QueueSobject WHERE Queue.Name = :TicketUtil.QUEUE_NAME_GUSTO_LEARN_SUPPORT LIMIT 1];
		if (!list_Queues.isEmpty()) {
			objTicket.OwnerId = list_Queues[0].QueueId;
			update objTicket;

			Ticket__c objUpdatedTicket = [SELECT Id, Assigned_to_User_At__c FROM Ticket__c WHERE Id = :objTicket.Id LIMIT 1];
			System.assertEquals(objUpdatedTicket.Assigned_to_User_At__c, null, 'Not assigned to a User');
		}
	}

	/**
	 * @author       Anurag Gautam
	 * @description  This is the test method to validate the ticket status changes
	 	              when associated carrier order owner is Carrier Implementation Queue then status can not be changed.
	 * @param         NA
	 * @return       NA
	**/
	@isTest
	static void testTicketStatusCannotBeClosed() {
		String strErrorMessage;

		Test.startTest();

		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordType.Name = 'New Plan' LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id, Owner.Name FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id LIMIT 1];

		Group queueRecord = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Carrier Implementation Queue'];
		objCO.OwnerId = queueRecord.Id;
		update objCO;

		Case objCase = [SELECT Id FROM Case LIMIT 1];

		Ticket__c objTicketToTest = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCO.Id)
			.setEscalationReason('Rate Discrepancy')
			.setEscalationReasonDetail('Incomplete Form')
			.setReportingTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setRateDiscrepencyResolution('No Error')
			.setErrorOrigin('Benefit Transfer Fulfillment')
			.setCloseDate(System.today().adddays(15))
			.build();
		insert objTicketToTest;

		objTicketToTest.Error_Origin__c = 'Sales';
		objTicketToTest.Error_Origin_Details__c = TicketUtil.TICKET_TEAM_BOR_SALES;
		objTicketToTest.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicketToTest.Close_Reason__c = 'NA';

		try {
			update objTicketToTest;
		} catch (Exception objEX) {
			strErrorMessage = objEX.getMessage();
		}

		Test.stopTest();

		Ticket__c objTicketToCheck = [SELECT Id, Status__c FROM Ticket__c WHERE Id = :objTicketToTest.Id];
		System.assertEquals(TicketUtil.TICKET_STATUS_NEW, objTicketToCheck.Status__c, 'Ticket status should not be changed to closed');
		System.assertEquals(true, strErrorMessage.contains(TicketUtil.TICKET_STATUS_ERROR_MESSAGE));
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for ticket creation for Changed User Role
	 * @param         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testTicketReRouting() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordType.Name = 'New Plan' LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id, Owner.Name FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		UserRoleTriggerHelper.skipTrigger = true;
		TicketTriggerHelper.skipTrigger = true;
		User_Role__c objUserRole = new TestDataFactory.UserRoleBuilder()
			.setUserId(UserInfo.getUserId())
			.setUserTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setUserSkillType(TicketUtil.TICKET_OWNER_ROLE_TYPE_CORE)
			.build();
		insert objUserRole;
		Case objCase = [SELECT Id FROM Case LIMIT 1];

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCO.Id)
			.setEscalationReason(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setEscalationReasonDetail('Waiting Period Does Not Meet Requirements')
			.setReportingTeam(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setSkipAssignment(true)
			.build();
		insert objTicket;

		UserRoleTriggerHelper.skipTrigger = false;
		TicketTriggerHelper.skipTrigger = false;

		objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket.Close_Reason__c = 'NA';
		update objTicket;
		Test.stopTest();

		System.assert([SELECT COUNT() FROM Ticket__c WHERE Escalation_Reason__c = :TicketUtil.TICKET_ROLE_QUALIFICATION LIMIT 1] == 1);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method to check BO Order status after ticket is closed.
	 * @param         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testBOStatus() {
		Benefit_Order__c objBO = [SELECT Id, Name, Order_Status__c FROM Benefit_Order__c WHERE Name = 'Test BYB BO' LIMIT 1];
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_BYB_TICKET_RT_ID)
			.setDescription('Test Payroll Compliance Ticket')
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReason('BYB Unresponsive Customer')
			.setBenefitOrderId(objBO.Id)
			.setTeam(TicketUtil.TICKET_TEAM_BOR_SALES)
			.setReportingTeam('BYB Advocate')
			.setEscalationReasonDetail('')
			.setInitialStatus(objBO.Id + '=>Ready for Intro')
			.build();
		insert objTicket;

		Ticket__c objTicket1 = [SELECT Id, Status__c, Team__c, Reporting_Team__c, Escalation_Reason_Detail__c, Escalation_Reason__c, Initial_Status__c FROM Ticket__c WHERE Id = :objTicket.Id];
		objTicket1.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket1.Escalation_Reason__c = 'BYB Unresponsive Customer';
		objTicket1.Priority__c = TicketUtil.TICKET_PRIORITY_LOW;
		update objTicket1;

		Test.stopTest();

		Benefit_Order__c objBO1 = [SELECT Id, Name, Order_Status__c FROM Benefit_Order__c WHERE Id = :objBO.Id];
		System.assertEquals(objBO1.Order_Status__c, BenefitOrderUtil.STATUS_READY_FOR_INTRO, 'Status should be Ready for Intro');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method to test the CO Follow up date when ticket is closed related BO
	 * @parms         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testCOFollowUpDate() {
		Benefit_Order__c objBO = [SELECT Id, Name, Order_Status__c FROM Benefit_Order__c WHERE Name = 'TEST BENEFIT ORDER' LIMIT 1];
		Carrier_Order__c objCOTemp = [SELECT Id, Name, Implementation_Stage__c, Carrier__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id];
		Test.startTest();
		Carrier_Play_Information__c objCarrierPlay = [SELECT Id, Name, Event_Type__c, Play_Mode_Type__c FROM Carrier_Play_Information__c WHERE Carrier__c = :objCOTemp.Carrier__c];

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setDescription('Test Payroll Compliance Ticket')
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReason('Incorrect package submitted to carrier')
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCOTemp.Id)
			.setReportingTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setEscalationReasonDetail('')
			.setCloseDate(System.today())
			.build();
		insert objTicket;

		Ticket__c objTicket1 = [SELECT Id, Status__c, Team__c, Reporting_Team__c, Escalation_Reason_Detail__c, Escalation_Reason__c, Initial_Status__c FROM Ticket__c WHERE Id = :objTicket.Id];
		objTicket1.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket1.Close_Reason__c = 'NA';
		update objTicket1;

		Test.stopTest();

		Carrier_Order__c objCO = [SELECT Id, Name, Implementation_Stage__c, Follow_Up_Date__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id];
		System.assert(objCO.Follow_Up_Date__c != null, 'Carrier Order Follow up date should not be null');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method to check the owner assignment for Team BYB Advocate.
	 * @param         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testTicketCreationForBYBAdvocate() {
		Benefit_Order__c objBO = [SELECT Id, Name, Order_Status__c, OwnerId FROM Benefit_Order__c WHERE Name = 'Test BYB BO' LIMIT 1];
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_BYB_TICKET_RT_ID)
			.setDescription('Test Payroll Compliance Ticket')
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReason('BYB Unresponsive Customer')
			.setEscalationReasonDetail(' ')
			.setBenefitOrderId(objBO.Id)
			.setTeam('BYB Advocate')
			.setReportingTeam(TicketUtil.TICKET_TEAM_BOR_SALES)
			.build();
		insert objTicket;

		Test.stopTest();
		Ticket__c objTicket1 = [SELECT Id, Status__c, Team__c, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket1.OwnerId, objBO.OwnerId, 'Ticket Owner and Benefot Order Id should be same');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method to check the owner assignment for Team BYB Memeber Ops.
	 * @param         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testTicketCreationForMOpsBYB() {
		Benefit_Order__c objBO = [SELECT Id, Name, Order_Status__c, OwnerId FROM Benefit_Order__c WHERE Name = 'Test BYB BO' LIMIT 1];
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_BYB_TICKET_RT_ID)
			.setDescription('Test Payroll Compliance Ticket')
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReason('BYB Unresponsive Customer')
			.setEscalationReasonDetail(' ')
			.setBenefitOrderId(objBO.Id)
			.setTeam(TicketUtil.TICKET_TEAM_BYB_MEMBER_OPS)
			.setReportingTeam(TicketUtil.TICKET_TEAM_BOR_SALES)
			.build();
		insert objTicket;

		Test.stopTest();
		Ticket__c objTicket1 = [SELECT Id, Status__c, Team__c, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket1.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_MEMBER_FULFILLMENT_BYB }).get(TicketUtil.QUEUE_NAME_MEMBER_FULFILLMENT_BYB),
			'Ticket Owner should be BYB Queue'
		);
	}

	/**
	 * @author       Bhagat Singh
	 * @description  Test method to check the owner assignment for Benefits Transfer queue.
	 * @param        N/A
	 * @return       N/A
	 **/
	@isTest
	static void createBenefitsTransferTicket() {
		Test.startTest();
		Order objOrder = [SELECT Id FROM Order LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.BENEFITS_TRANSFER_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setOrderId(objOrder.Id)
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, Status__c, Team__c, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_BENEFIT_TRANSFER }).get(TicketUtil.QUEUE_NAME_BENEFIT_TRANSFER),
			'Ticket Owner should be BENEFIT TRANSFER Queue'
		);
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method to check the updation of Advising Blocked Reason on Opportunitiy when ticket is closed with Ticket reason `Recertification`.
	 * @param         N/A
	 * @return       N/A
	 **/
	@isTest
	static void testUpdationOnOpportunity() {
		OpportunityTriggerHelper.skipTrigger = true;
		Opportunity objOpp = [SELECT Id, Advising_Blocked_Reason__c FROM Opportunity LIMIT 1];
		objOpp.Advising_Blocked_Reason__c = 'Pending recert';
		update objOpp;
		OpportunityTriggerHelper.skipTrigger = false;
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(OpportunityTriggerHelper.RECERTIFICATION_TEAM_QUEUE_ID)
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setDescription('Test Payroll Compliance Ticket')
			.setEscalationReason('Recertification')
			.setOppId(objOpp.Id)
			.setTeam(TicketUtil.TICKET_TEAM_ADVISING)
			.setCloseDate(System.today())
			.build();
		insert objTicket;

		Ticket__c objTicket1 = [SELECT Id, Status__c FROM Ticket__c WHERE Id = :objTicket.Id];
		objTicket1.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket1.Renewal_Date__c = System.today();
		update objTicket1;
		Test.stopTest();

		System.assertEquals([SELECT Id, Advising_Blocked_Reason__c FROM Opportunity WHERE Id = :objOpp.Id].Advising_Blocked_Reason__c, null);
	}

	/**
	 * @author       Ajay Krishna P U
	 * @description  Test Auto task creation
	 **/
	@isTest
	static void testAutoTaskCreation() {
		Task_Template__mdt objTemplate = [SELECT Task_Type__c, Priority__c, Sub_Type__c FROM Task_Template__mdt WHERE Is_Active__c = TRUE AND DeveloperName = 'Ardius_Data_Cleanup' LIMIT 1];
		Opportunity objTaxCreditsOppty = [SELECT Id, Company_Information_Complete__c FROM Opportunity WHERE RecordTypeId = :OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID LIMIT 1];

		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setDescription('Test Ardius Ticket')
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setCloseDate(System.today())
			.setOppId(objTaxCreditsOppty.Id)
			.build();
		insert objTicket;

		OpportunityTriggerHelper.skipTrigger = true;
		objTaxCreditsOppty.Company_Information_Complete__c = true;
		update objTaxCreditsOppty;
		OpportunityTriggerHelper.skipTrigger = false;

		objTicket.Federal_Credit_Amount__c = 60000;
		objTicket.Status__c = objTemplate.Sub_Type__c;
		update objTicket;

		objTicket = [SELECT Id, Task_Priority__c FROM Ticket__c WHERE Id = :objTicket.Id LIMIT 1];
		List<Task> list_Tasks = [SELECT Id, Description, Priority, Status, Subject, Type FROM Task WHERE WhatId = :objTicket.Id ORDER BY LastModifiedDate DESC LIMIT 1];

		System.assert(!list_Tasks.isEmpty(), 'Auto Task Creation failed');
		System.assert(list_Tasks[0].Priority == objTicket.Task_Priority__c, 'Invalid Task Priority');
		System.assert(list_Tasks[0].Type == objTemplate.Task_Type__c, 'Invalid Task Type');
		Test.stopTest();

		//Test Amendment Eligible
		objTicket.Amendment_Eligible__c = true;
		objTicket.Qualification_Status__c = TicketUtil.QUALIFICATION_STATUS_QUALIFIED;
		objTicket.Re_Sync_Tasks__c = true;
		update objTicket;
		list_Tasks = [SELECT Id, Feature_Request__c FROM Task WHERE WhatId = :objTicket.Id AND Feature_Request__c = :TicketUtil.TICKET_TEMPLATE_FV_AMENDMENT_ELIGIBLE];
		System.assert(!list_Tasks.isEmpty(), 'Auto Task Creation failed - Amendment_Eligible__c');

		objTicket = [SELECT Id, Re_Sync_Tasks__c FROM Ticket__c WHERE Id = :objTicket.Id LIMIT 1];
		System.assertEquals(false, objTicket.Re_Sync_Tasks__c, 'Resync failed');
	}

	/**
	 * @author       Deepesh Rao
	 * @description  Test task creation for revision required
	 **/
	@isTest
	static void testRevisionRequiredTask() {
		Test.startTest();

		Ticket__c objTicket = [
			SELECT Id, Anticipated_Close_Date__c, Revisions_Required__c
			FROM Ticket__c
			WHERE Status__c = :TicketUtil.TICKET_STATUS_NEW AND Anticipated_Close_Date__c != NULL
			LIMIT 1
		];
		System.assertEquals(objTicket.Id != null, true, 'No ticket record found');
		System.assertEquals(objTicket.Anticipated_Close_Date__c != null, true, 'Close date is null');
		System.assertEquals(false, objTicket.Revisions_Required__c, 'Revision required is true');
		objTicket.Revisions_Required__c = true;
		update objTicket;
		System.assertEquals(true, objTicket.Revisions_Required__c, 'Ticket update failed');
		Task objTask = [SELECT Id, Subject FROM Task WHERE whatId = :objTicket.Id LIMIT 1];
		system.assertEquals(objTask.Id != null, true, 'Task record not present');
		system.assertEquals(TaskUtil.TASK_SUBJECT_REQUESTED, objTask.Subject, 'Task subject is different');
		objTicket = [SELECT Anticipated_Close_Date__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.Anticipated_Close_Date__c == null, true, 'Close date is not null');

		Test.stopTest();
	}

	/**
	 * @author       Ajay Krishna P U
	 * @description  Test Auto close generated Task
	 * Auto generated Task are auto closed when Status changed or get Disqualified +  Status = Qualification Needed
	 **/
	@isTest
	static void testAutoCloseGeneratedTasks() {
		List<Ticket__c> list_Tickets = [SELECT Id, Status__c FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assert(list_Tickets.size() == 1, 'Failed, Invalid Ticket data');
		Ticket__c objTicket = list_Tickets[0];

		Test.startTest();

		//1. Set a Status => Auto generate a Task
		objTicket.Status__c = TicketUtil.TICKET_STATUS_DATA_LOAD;
		update objTicket;

		//1.1 Verify Task created
		List<Task> list_Tasks = [SELECT Id, Status, Feature_Request__c FROM Task WHERE WhatId = :objTicket.Id AND Feature_Request__c = :TicketUtil.TICKET_STATUS_DATA_LOAD];
		System.assert(!list_Tasks.isEmpty(), 'Task did not created on with template identifier as status');
		Task objTaskDataLoad = list_Tasks[0];
		System.assert(objTaskDataLoad.Status != TaskUtil.TASK_STATUS_COMPLETE, 'Invalid Task Status, expected a non closed Task');

		//2. Update Status Qualification Needed => Auto close previous Tasks and creates new Task
		objTicket.Status__c = TicketUtil.TICKET_STATUS_REPORT_CREATION;
		update objTicket;

		//2.1 Verify Previous Task closed
		objTaskDataLoad = [SELECT Id, Status FROM Task WHERE Id = :objTaskDataLoad.Id];
		System.assert(objTaskDataLoad.Status == TaskUtil.TASK_STATUS_COMPLETE, 'Invalid Task Status, expected a closed Task');

		Test.stopTest();
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Assign MB Compliance Queue
	 **/
	@isTest
	static void testOwnerMBComplianceQueue() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.MB_COMPLIANCE_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setOwnerId(UserInfo.getUserId())
			.setReason('Enrollment')
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_MB_COMPLIANCE }).get(TicketUtil.QUEUE_NAME_MB_COMPLIANCE),
			'Ticket Owner should be MB Compliance Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Assign Advising Fulfillment Queue
	 **/
	@isTest
	static void testOwnerAdvisingFulfillmentQueue() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(objCase.Id)
			.setRenewalDate(System.today())
			.setStates('CA')
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, Account__c, OwnerId, Created_Date_Time__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertNotEquals(null, objTicket.Created_Date_Time__c, 'Created Date Time should be populated');
		System.assertNotEquals(null, objTicket.Account__c, 'Account should be updated on Ticket');
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_ADVISING_FULFILLMENT }).get(TicketUtil.QUEUE_ADVISING_FULFILLMENT),
			'Ticket Owner should be Advising Fulfillment Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Assign Benefits Compliance Queue
	 **/
	@isTest
	static void testOwnerBenefitsComplianceQueue() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setReportingTeam(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setEscalationReason('Other')
			.build();
		insert objTicket;

		objTicket = [SELECT Id, OwnerId, Team__c, RecordTypeId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_BENEFITS_COMPLIANCE }).get(TicketUtil.QUEUE_NAME_BENEFITS_COMPLIANCE),
			'Ticket Owner should be Benefits Compliance Queue'
		);

		objTicket.Team__c = TicketUtil.TICKET_TEAM_FULL_STACK_SALES;
		update objTicket;

		objTicket = [SELECT Id, OwnerId, RecordTypeId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.RecordTypeId, TicketUtil.SALES_ESCALATION_TICKET_RT_ID, 'Record Type should be set to sales escalation');

		Test.stopTest();
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Assign Care Escalations Queue
	 **/
	@isTest
	static void testOwnerCareEscalationsQueue() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.PAYROLL_AUDIT_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setEscalationReason(TicketUtil.TICKET_REASON_CARE_ESCALATION)
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_CARE_ESCALATIONS }).get(TicketUtil.QUEUE_NAME_CARE_ESCALATIONS),
			'Ticket Owner should be Care Escalations Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Assign Credit & Collections Queue
	 **/
	@isTest
	static void testOwnerCreditCollectionsQueue() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.CREDIT_COLLECTIONS_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setDescription('Test')
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_CREDIT_COLLECTIONS }).get(TicketUtil.QUEUE_NAME_CREDIT_COLLECTIONS),
			'Ticket Owner should be Credit & Collections Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Financial Crimes Queue
	 **/
	@isTest
	static void testOwnerFinancialCrimesQueue() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.FINANCIAL_CRIMES_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setDescription('Test')
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_FINANCIAL_CRIMES }).get(TicketUtil.QUEUE_NAME_FINANCIAL_CRIMES),
			'Ticket Owner should be Financial Crimes Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner GustoLearn Support Queue
	 **/
	@isTest
	static void testOwnerGustoLearnSupportQueue() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.GUSTO_LEARN_SUPPORT_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setEscalationReason('Other')
			.setDescription('Test')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSummary('Test Summary')
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_GUSTO_LEARN_SUPPORT }).get(TicketUtil.QUEUE_NAME_GUSTO_LEARN_SUPPORT),
			'Ticket Owner should be GustoLearn Support Queue'
		);
	}

	/**
	 * @author       Atul
	 * @description  Test Ticket Name Search population
	 **/
	@isTest
	static void testPopulateTicketNameSearch() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setDescription('Test')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSummary('Test Summary')
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, Ticket_Name_Search__c, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.Ticket_Name_Search__c, 'Test Demo AccountName 1', 'Ticket Name should be Test Demo AccountName 1');
	}
	/**
	 * @author       Swati Arya
	 * @description  Test Owner New Plan Sales Queue
	 **/
	@isTest
	static void testOwnerNewPlanSalesQueue() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id FROM Benefit_Order__c LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.NEW_PLAN_SALES_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setEscalationReason('Other')
			.setDescription('Test')
			.setBenefitOrderId(objBenefitOrder.Id)
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_NEW_PLAN_SALES }).get(TicketUtil.QUEUE_NAME_NEW_PLAN_SALES),
			'Ticket Owner should be New Plan Sales Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Payroll Transfer Queue
	 **/
	@isTest
	static void testOwnerPayrollTransferQueue() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.PAYROLL_TRANSFER_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_PAYROLL_TRANSFER }).get(TicketUtil.QUEUE_NAME_PAYROLL_TRANSFER),
			'Ticket Owner should be Payroll Transfer Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Risk Investigation Queue
	 **/
	@isTest
	static void testOwnerRiskInvestigationQueue() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.RISK_INVESTIGATION_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReason('Admin Change')
			.setEscalationReasonDetail('Account Access Issue')
			.setDescription('Test')
			.setCallBackNumber('1234567890')
			.setUserLink('www.testuser.com')
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_RISK_INVESTIGATION }).get(TicketUtil.QUEUE_NAME_RISK_INVESTIGATION),
			'Ticket Owner should be Risk Investigation Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner Sales Escalation Queue
	 **/
	@isTest
	static void testOwnerSalesEscalationQueue() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.SALES_ESCALATION_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_SALES_ESCALATION }).get(TicketUtil.QUEUE_NAME_SALES_ESCALATION),
			'Ticket Owner should be Sales Escalation Queue'
		);
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner BizDev Queue
	 **/
	@isTest
	static void testOwnerBizDevQueueInsert() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objPartnerAccount = [SELECT Id FROM Account WHERE RecordType.Name = 'Partner' LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setEscalationReason('Integration Feedback')
			.setDescription('Test')
			.setAccountId(objAccount.Id)
			.setSummary('Test Summary')
			.setOther('Test')
			.setHelpCenterArticlesReviewed('Test')
			.setReviewedBy(UserInfo.getUserId())
			.setIntegration(objPartnerAccount.Id)
			.build();
		insert objTicket;
		Test.stopTest();

		objTicket = [SELECT Id, Status__c, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_BIZ_DEV }).get(TicketUtil.QUEUE_NAME_BIZ_DEV),
			'Ticket Owner should be BizDev Queue'
		);
		System.assertEquals(TicketUtil.TICKET_STATUS_NEW, ObjTicket.Status__c, 'Ticket Status should be set to new');
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Owner BizDev Queue
	 **/
	@isTest
	static void testOwnerBizDevQueueUpdate() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];
		Account objPartnerAccount = [SELECT Id FROM Account WHERE RecordType.Name = 'Partner' LIMIT 1];
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.SALES_ESCALATION_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.build();
		insert objTicket;

		objTicket.RecordTypeId = TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID;
		objTicket.Escalation_Reason__c = 'Integration Feedback';
		objTicket.Description__c = 'Test';
		objTicket.Account__c = objAccount.Id;
		objTicket.Summary__c = 'Test Summary';
		objTicket.Other__c = 'Test';
		objTicket.Help_Center_articles_reviewed__c = 'Test';
		objTicket.Ticket_Reviewed_By__c = UserInfo.getUserId();
		objTicket.Integration__c = objPartnerAccount.Id;
		update objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, Status__c, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_BIZ_DEV }).get(TicketUtil.QUEUE_NAME_BIZ_DEV),
			'Ticket Owner should be BizDev Queue'
		);
		System.assertEquals(TicketUtil.TICKET_STATUS_NEW, ObjTicket.Status__c, 'Ticket Status should be set to new');

		objTicket.Status__c = TicketUtil.TICKET_STATUS_SOLVED;
		update objTicket;

		objTicket = [SELECT Id, Status__c, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(TicketUtil.TICKET_STATUS_SOLVED, ObjTicket.Status__c, 'Ticket Status should be set to Solved');
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Ticket Record Type Change To Sales Escalation
	 **/
	@isTest
	static void testSalesExcalationRTChangeInsert() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setReportingTeam(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setEscalationReason('Other')
			.setTeam(TicketUtil.TICKET_TEAM_FULL_STACK_SALES)
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId, RecordTypeId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.RecordTypeId, TicketUtil.SALES_ESCALATION_TICKET_RT_ID, 'Record Type should be set to sales escalation');
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Stamping of Prioity Fields
	 **/
	@isTest
	static void testStampingTicketPriorityField() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.PAYROLL_AUDIT_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setEscalationReason(TicketUtil.TICKET_REASON_TWO_FACTOR_ACTIVITY)
			.setUserLink('www.test.com')
			.build();
		insert objTicket;

		objTicket = [SELECT Id, Priority__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertNotEquals(objTicket.Priority__c, TicketUtil.TICKET_PRIORITY_URGENT, 'Priority should be set to Urgent');

		objTicket.Escalation_Reason__c = TicketUtil.TICKET_REASON_COMPANY_ONBOARDING;
		update objTicket;

		objTicket = [SELECT Id, Priority__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.Priority__c, TicketUtil.TICKET_PRIORITY_HIGH, 'Priority should be set to High');

		objTicket.Escalation_Reason__c = TicketUtil.TICKET_REASON_EXPEDITED_PAYROLL;
		update objTicket;

		objTicket = [SELECT Id, Priority__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.Priority__c, TicketUtil.TICKET_PRIORITY_MEDIUM, 'Priority should be set to Medium');

		Test.stopTest();
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Stamping of Risk Fields
	 **/
	@isTest
	static void testStampingTicketRiskFields() {
		Test.startTest();
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.BENEFITS_COMPLIANCE_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setOwnerId(UserInfo.getUserId())
			.setReportingTeam(TicketUtil.TICKET_ROLE_QUALIFICATION)
			.setEscalationReason('Other')
			.setTeam(TicketUtil.TICKET_TEAM_FULL_STACK_SALES)
			.build();
		insert objTicket;

		objTicket.Status__c = TicketUtil.TICKET_STATUS_INPROGRESS;
		update objTicket;

		objTicket = [SELECT Id, InProgress_Date_Time__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertNotEquals(null, objTicket.InProgress_Date_Time__c, 'In Progress Date Time field should be stamped');

		objTicket.OwnerId = UserInfo.getUserId();
		update objTicket;

		objTicket = [SELECT Id, Assigned_to_User_At__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertNotEquals(null, objTicket.Assigned_to_User_At__c, 'Assigned To User At field should be stamped');

		objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		update objTicket;

		objTicket = [SELECT Id, Closed_Date_Time__c, Close_Date__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertNotEquals(null, objTicket.Closed_Date_Time__c, 'Closed Date Time field should be stamped');
		System.assertNotEquals(null, objTicket.Close_Date__c, 'Closed Date field should be stamped');

		Test.stopTest();
	}

	/**
	 * @author       Ajay Krishna P U
	 * @description  Test Reset Un-responsive flag
	 * The flag will be reset when Ticket status changes
	 **/
	@isTest
	static void testResetUnResponsiveFlag() {
		List<Ticket__c> list_Tickets = [SELECT Id, Status__c FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 2];
		System.assert(list_Tickets.size() == 2, 'Failed, Invalid Ticket data');
		Ticket__c objTicket1 = list_Tickets[0];
		Ticket__c objTicket2 = list_Tickets[1];

		Test.startTest();
		//Set Unresponsive flag
		objTicket1.Status__c = TicketUtil.TICKET_STATUS_REPORT_CREATION;
		objTicket1.Unresponsive__c = true;
		objTicket2.Status__c = TicketUtil.TICKET_STATUS_REPORT_CREATION;
		objTicket2.Unresponsive__c = true;
		update new List<Ticket__c>{ objTicket1, ObjTicket2 };

		//Update Tickets for Testing
		objTicket1.Status__c = TicketUtil.TICKET_STATUS_DATA_LOAD;
		objTicket2.Tax_Year__c = '2023';
		objTicket1.Communication_Status__c = TicketUtil.COMM_STATUS_IN_PROGRESS;
		objTicket2.Communication_Status__c = TicketUtil.COMM_STATUS_IN_PROGRESS;
		update new List<Ticket__c>{ objTicket1, ObjTicket2 };
		Test.stopTest();

		Map<Id, Ticket__c> map_Results = new Map<Id, Ticket__c>(
			[SELECT Id, Status__c, Unresponsive__c, Tax_Year__c, Communication_Status__c FROM Ticket__c WHERE Id = :new List<Id>{ objTicket1.Id, objTicket2.Id }]
		);
		objTicket1 = map_Results.get(objTicket1.Id);
		objTicket2 = map_Results.get(objTicket2.Id);

		System.assert(TicketUtil.TICKET_STATUS_DATA_LOAD == objTicket1.Status__c, 'Failed, Status did not updated');
		System.assert(false == objTicket1.Unresponsive__c, 'Failed, Unresponsive__c did not updated');

		System.assert('2023' == objTicket2.Tax_Year__c, 'Failed, Tax Year did not updated');
		System.assert(true == objTicket2.Unresponsive__c, 'Failed, Unresponsive__c did updated');

		//Make Ticket closed/Lost
		objTicket1.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
		objTicket2.Status__c = TicketUtil.TICKET_STATUS_LOST;
		objTicket2.Lost_Detail__c = 'Out of business';
		update new List<Ticket__c>{ objTicket1, ObjTicket2 };

		map_Results = new Map<Id, Ticket__c>([SELECT Id, Status__c, Unresponsive__c, Tax_Year__c, Communication_Status__c FROM Ticket__c WHERE Id = :new List<Id>{ objTicket1.Id, objTicket2.Id }]);
		objTicket1 = map_Results.get(objTicket1.Id);
		objTicket2 = map_Results.get(objTicket2.Id);

		System.assert(null == objTicket1.Communication_Status__c, 'Failed, Invalid Communication Status - Closed');
		System.assert(null == objTicket2.Communication_Status__c, 'Failed, Invalid Communication Status - Lost');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test updateBusinessDaysOnCase() method
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void testupdateBusinessDaysOnCaseMethod() {
		Test.startTest();
		List<Id> list_CaseIds = new List<Id>();
		Case objCase = [SELECT Id, AccountId FROM Case WHERE RecordType.Name = 'Benefits Renewal Case'];
		list_CaseIds.add(objCase.Id);
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setCaseId(objCase.Id)
			.setEscalationReason(TicketUtil.TICKET_REASON_RECERTIFICATION)
			.setAccountId(objCase.AccountId)
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert objTicket;
		TickettriggerHelper.updateBusinessDaysOnCase(list_CaseIds);
		Test.stopTest();
		objCase = [SELECT Id, Automated_RFI_Flow__c, RFI_3rd_Business_Day__c, RFI_6th_Business_Day__c FROM Case WHERE Id = :objCase.Id];
		System.assert(objCase.Automated_RFI_Flow__c, 'Automated_RFI_Flow__c of Case is set to True');
		System.assert(objCase.RFI_6th_Business_Day__c != null, 'RFI_6th_Business_Day__c of Case is updated.');
		System.assert(objCase.RFI_6th_Business_Day__c != null, 'RFI_6th_Business_Day__c of Case is updated.');
	}

	/**
	 * @author       Swati Arya
	 * @description  Test to skip the Owner Assignment Changes when the bln flag is set
	 **/
	@isTest
	static void testOwnerSkipAssignemntLogic() {
		Test.startTest();
		TicketTriggerHelper.blnSkipTicketTriggerAssignment = true;
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.MB_COMPLIANCE_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setOwnerId(UserInfo.getUserId())
			.setReason('Enrollment')
			.build();
		insert objTicket;

		Test.stopTest();

		objTicket = [SELECT Id, OwnerId FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertNotEquals(
			objTicket.OwnerId,
			GlobalQueryHelper.getNameQueueMap(new Set<String>{ TicketUtil.QUEUE_NAME_MB_COMPLIANCE }).get(TicketUtil.QUEUE_NAME_MB_COMPLIANCE),
			'Ticket Owner should not be MB Compliance Queue'
		);
	}

	/**
	 * @author       Soujanya NJ
	 * @description  Automation on change of Case Status btw Awaiting Internal Support and In Progress
	 **/
	@isTest
	static void testUpdateCaseAutomation() {
		Test.startTest();
		List<Case> list_objCases = [SELECT Id, Status FROM Case WHERE RecordTypeId = :CaseUtils.RECTYPE_ENGAGEMENT];

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.setCaseId(list_objCases[0].Id)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReason('Pending Items')
			.setEscalationReasonDetail('Incomplete Form')
			.setReportingTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.build();
		insert objTicket;
		List<Case> list_TicketCases = [SELECT Id, Status FROM case WHERE Id = :objTicket.Case__c];
		System.assertEquals(list_TicketCases[0].Status, 'Awaiting Internal Support', 'Case Status should be updated to Awaiting Internal Support');

		List<Ticket__c> list_objTickets = [SELECT Id, Close_Reason__c, Status__c, Case__c FROM Ticket__c WHERE Id = :objTicket.id];
		list_objTickets[0].Close_Reason__c = 'Closing';
		list_objTickets[0].Status__c = TicketUtil.TICKET_STATUS_CLOSED;

		update list_objTickets[0];
		List<Case> list_UpdatedCases = [SELECT Id, Status FROM Case WHERE Id = :list_objTickets[0].Case__c];

		System.assertEquals(list_UpdatedCases[0].Status, 'In Progress', 'Case Status should be updated to In Progress');
		Test.stopTest();
	}

	/**
	 * @author       Yogesh Kherjani
	 * @description  test method for new to escalated
	 **/
	@isTest
	static void testTaskTicketHandler() {
		Test.startTest();
		TicketTriggerHelper.blnSkipTicketTriggerAssignment = true;
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setOwnerId(UserInfo.getUserId())
			.setReason('Enrollment')
			.build();
		insert objTicket;

		objTicket.Status__c = TicketUtil.TICKET_STATUS_ESCALATED;
		update objTicket;

		System.assert(objTicket.Status__c == TicketUtil.TICKET_STATUS_ESCALATED, 'Invalid Ticket Status, expected a Escalated');

		Test.stopTest();
	}

	/**
	 * @author       Ajay Krishna P U
	 * @description  Test Ardius Custom Routing
	 **/
	@isTest
	static void testArdiusCustomRouting() {
		List<Ticket__c> list_Tickets = [SELECT Id, Status__c FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID ORDER BY LastModifiedDate DESC LIMIT 2];
		System.assertEquals(list_Tickets.size(), 2, 'Failed, Invalid Ticket data');
		Ticket__c objTicketPrior = list_Tickets[0];
		Ticket__c objTicket = list_Tickets[1];

		List<User> list_Users = [SELECT Id FROM User WHERE Profile.Name = :TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR AND IsActive = TRUE LIMIT 2];
		System.assertEquals(list_Users.size(), 2, 'Failed, Invalid User data');
		User objUserA = list_Users[0];
		User objUserB = list_Users[1];

		List<Opportunity> list_Opportunities = [SELECT Id, AccountId FROM Opportunity WHERE AccountId != NULL LIMIT 1];
		System.assertEquals(list_Opportunities.size(), 1, 'Failed, Invalid Opportunity data');
		Opportunity objRefOpportunity = list_Opportunities[0];
		Account objRefAccount = new Account(Id = objRefOpportunity.AccountId);

		//Set Base
		TicketTriggerHelper.skipTrigger = true;

		objTicketPrior.OwnerId = objUserA.Id;
		objTicketPrior.Opportunity__c = objRefOpportunity.Id;
		objTicketPrior.Account__c = objRefAccount.Id;
		objTicketPrior.Qualification_Status__c = null;

		objTicket.OwnerId = objUserB.Id;
		objTicket.Opportunity__c = objRefOpportunity.Id;
		objTicket.Account__c = objRefAccount.Id;
		objTicket.Qualification_Status__c = null;
		update new List<Ticket__c>{ objTicketPrior, objTicket };

		TicketTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();

		// Set Opportunity Type as Existing Business and trigger routing
		objRefOpportunity.Type = OpportunityUtil.OPPTY_TYPE_EXISTING_BUSINESS;
		update objRefOpportunity;
		objTicket.Qualification_Status__c = TicketUtil.QUALIFICATION_STATUS_QUALIFIED;
		objTicket.Re_route__c = true;
		update objTicket;

		objTicket = [SELECT Id, OwnerId, Re_route__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.OwnerId, objTicketPrior.OwnerId, 'Routing failed - Existing Business update');
		System.assertEquals(objTicket.Re_route__c, false, 'Re-route did not reset - Existing Business update');

		// Set Control Group and Trigger routing
		objRefAccount.Control_Group__c = 'Ctrl A';
		update objRefAccount;
		objRefOpportunity.Type = null;
		update objRefOpportunity;
		objTicket.OwnerId = objUserB.Id;
		objTicket.Re_route__c = true;
		update objTicket;

		objTicket = [SELECT Id, OwnerId, Re_route__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.OwnerId, objTicketPrior.OwnerId, 'Routing failed - Control Group update');
		System.assertEquals(objTicket.Re_route__c, false, 'Re-route did not reset - Control Group update');

		// Set Opportunity Type as Existing Business & Control Group and Trigger routing
		objRefAccount.Control_Group__c = 'Ctrl B';
		update objRefAccount;
		objRefOpportunity.Type = OpportunityUtil.OPPTY_TYPE_EXISTING_BUSINESS;
		update objRefOpportunity;
		objTicket.OwnerId = objUserB.Id;
		objTicket.Re_route__c = true;
		update objTicket;

		objTicket = [SELECT Id, OwnerId, Re_route__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(objTicket.OwnerId, objTicketPrior.OwnerId, 'Routing failed - Opportunity Type as Existing Business & Control Group update');
		System.assertEquals(objTicket.Re_route__c, false, 'Re-route did not reset - Opportunity Type as Existing Business & Control Group update');

		Test.stopTest();

		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testHandleOwnerChangeUnitTest() {
		Test.startTest();
		TicketTriggerHelper.blnSkipTicketTriggerAssignment = true;
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setOwnerId(UserInfo.getUserId())
			.setReason('Enrollment')
			.build();
		insert objTicket;

		Ticket__c objTicket1 = [SELECT Id, Is_Ticket_Owner_Benefits_Compliance__c FROM Ticket__c WHERE Id = :objTicket.Id];

		System.assert(!objTicket1.Is_Ticket_Owner_Benefits_Compliance__c, 'Ticket owner should not be Benefit Compliance.');
		Test.stopTest();
	}

	/**
	 * @description Test Task owner change based on Ticket
	 */
	@isTest
	static void testArdiusTicketOwnerAssignedToTaskOwner() {
		List<Ticket__c> list_Tickets = [SELECT Id, OwnerId FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 2];
		System.assertEquals(2, list_Tickets.size(), 'Invalid Test data - Tickets');

		Ticket__c objTicket1 = list_Tickets[0];

		List<Group> list_Queues = [SELECT Id FROM Group WHERE DeveloperName = 'R_D_Tax_Credit_Customer_Ops_Queue'];
		System.assertEquals(1, list_Queues.size(), 'Invalid test data - Queues');
		Id idQueue = list_Queues[0].Id;

		Test.startTest();
		Task objTask1 = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(RecordTypes.getRecordTypeIdFromDeveloperName('Task', 'Standard'))
			.setWhatId(objTicket1.Id)
			.setStatus(TaskUtil.TASK_STATUS_OPEN)
			.setPriority(TaskUtil.TASK_PRIORITY_LOW)
			.setSubject(TaskUtil.TASK_SUBJECT_REQUESTED)
			.setFeatureRequest('Standard1')
			.setStartDate(System.now())
			.setOwnerId(idQueue)
			.build();
		
		insert objTask1;

		List<User> list_Users = [SELECT Id FROM User WHERE Profile.Name = :TaskUtil.USER_PROFILE_NAME_ZP_SYSTEM_ADMINISTRATOR AND IsActive = TRUE LIMIT 1];
		System.assertEquals(list_Users.size(), 1, 'Invalid test data - Users');
		Id idUser = list_Users[0].Id;

		//Set Base
		objTicket1.OwnerId = idQueue;
		update objTicket1;

		//Ticket owner changed to another User
		objTicket1.OwnerId = idUser;
		update objTicket1;

		//Check Owner change - Task
		objTask1 = [SELECT Id, OwnerId FROM Task WHERE Id = :objTask1.Id];
		System.assertEquals(objTask1.OwnerId, objTicket1.OwnerId, 'Failed, Task OwnerId not updated - Queue to User');

		Test.stopTest();
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method Validate Ticket_Action_Required__c field on Carrier Order.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testTicketActionRequiredOnCO() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id, OwnerId, Ticket_Action_Required__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		Case objCase = [SELECT Id FROM Case LIMIT 1];

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(objCO.OwnerId)
			.setCaseId(objCase.Id)
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setEscalationReason('Rate Discrepancy')
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReasonDetail('Incorrect rates for plan year')
			.setReportingTeam(TicketUtil.TICKET_ROLE_FULFILLMENT)
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCO.Id)
			.setCloseDate(System.today().adddays(15))
			.setErrorOrigin('Benefit Transfer Fulfillment')
			.setRateDiscrepencyResolution('No Error')
			.build();
		insert objTicket;

		Test.stopTest();

		objCO = [SELECT Id, OwnerId, Ticket_Action_Required__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		System.assertEquals(true, objCO.Ticket_Action_Required__c, 'Ticket Action Required field on Carrier Order was not updated.');
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test updates of date time fields on status change of SE Ticket to In Progress
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testSETicketUpdateInProgress() {
		Test.startTest();

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.SOLUTION_ENGINEER_REQUEST_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority('Low')
			.build();
		insert objTicket;

		objTicket.Status__c = 'In Progress';
		update objTicket;

		Test.stopTest();

		Ticket__c objTicketAssert = [SELECT Id, InProgress_Date_Time__c FROM Ticket__c WHERE Id = :objTicket.Id LIMIT 1];
		System.assertNotEquals(null, objTicketAssert.InProgress_Date_Time__c, 'Ticket In Progress Date/Time was not updated.');
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test updates of date time fields on status change of SE Ticket to In Progress
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testSETicketUpdateInReview() {
		Test.startTest();

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.SOLUTION_ENGINEER_REQUEST_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority('Low')
			.build();
		insert objTicket;

		objTicket.Status__c = 'In Review';
		update objTicket;

		Test.stopTest();

		Ticket__c objTicketAssert = [SELECT Id, In_Review_Date_Time__c FROM Ticket__c WHERE Id = :objTicket.Id LIMIT 1];
		System.assertNotEquals(null, objTicketAssert.In_Review_Date_Time__c, 'Ticket In Review Date/Time was not updated.');
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Test updates of date time fields on status change of SE Ticket to In Progress
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testSETicketUpdateResolvedClosed() {
		Test.startTest();

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.SOLUTION_ENGINEER_REQUEST_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setPriority('Low')
			.build();
		insert objTicket;

		objTicket.Research_and_Resolution__c = 'Research Completed.';
		objTicket.Status__c = 'Resolved';
		update objTicket;

		Test.stopTest();

		Ticket__c objTicketAssert = [SELECT Id, Resolved_Closed_Date_Time__c FROM Ticket__c WHERE Id = :objTicket.Id LIMIT 1];
		System.assertNotEquals(null, objTicketAssert.Resolved_Closed_Date_Time__c, 'Ticket Resolved/Closed Date/Time was not updated.');
	}

	/**
	 * @description Test Opp Closed Won on Ardius Ticket Status Change
	 * @author Ajay Krishna P U
	 * @since 2024-11-13
	 */
	@isTest
	static void testUpdationOnOpportunityToClosedWon() {
		List<Opportunity> list_Opps = [
			SELECT Id, StageName
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID AND StageName != :OpportunityUtil.CLOSED_WON_STAGE
			LIMIT 2
		];
		System.assertEquals(2, list_Opps.size(), 'Inavlaid Test data');
		Opportunity objOpp1 = list_Opps[0];
		Opportunity objOpp2 = list_Opps[1];

		Test.startTest();
		Ardius_Configuration__c objConfig = Ardius_Configuration__c.getInstance();
		objConfig.Client_Approval_Tracking_Ticket_Statuses__c = TicketUtil.TICKET_STATUS_CLOSED + ';' + TicketUtil.TICKET_STATUS_DATA_LOAD;
		upsert objConfig;

		//after insert
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setStatus(TicketUtil.TICKET_STATUS_CLOSED)
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setOppId(objOpp1.Id)
			.build();
		insert objTicket;

		objOpp1 = [SELECT Id, StageName FROM Opportunity WHERE Id = :objOpp1.Id];
		System.assertEquals(OpportunityUtil.CLOSED_WON_STAGE, objOpp1.StageName, 'Opportunity not updated to closed won');

		//after update
		objTicket.Status__c = TicketUtil.TICKET_STATUS_DATA_LOAD;
		objTicket.Opportunity__c = objOpp2.Id;
		update objTicket;

		objOpp2 = [SELECT Id, StageName FROM Opportunity WHERE Id = :objOpp2.Id];
		System.assertEquals(OpportunityUtil.CLOSED_WON_STAGE, objOpp2.StageName, 'Opportunity2 not updated to closed won');

		Test.stopTest();
	}

	/**
	 * @description Test Opp Closed Lost on Ardius Ticket Status Change to Lost
	 * @author Jayesh Gawande
	 * @since 2024-11-18
	 */
	@isTest
	static void testupdateOpportunityToClosedLost() {
		List<Opportunity> list_Opps = [
			SELECT Id, StageName
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID AND StageName != :OpportunityUtil.CLOSED_LOST_STAGE
			LIMIT 2
		];
		System.assertEquals(2, list_Opps.size(), 'Invalid Test data');
		Opportunity objOpp1 = list_Opps[0];
		Opportunity objOpp2 = list_Opps[1];

		Test.startTest();

		//after insert
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setStatus(TicketUtil.TICKET_STATUS_LOST)
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setOppId(objOpp1.Id)
			.build();
		insert objTicket;

		objOpp1 = [SELECT Id, StageName FROM Opportunity WHERE Id = :objOpp1.Id];
		System.assertEquals(OpportunityUtil.CLOSED_LOST_STAGE, objOpp1.StageName, 'Opportunity not updated to Closed Lost');

		//after update
		Ticket__c objTicket2 = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setStatus(TicketUtil.TICKET_STATUS_DATA_LOAD)
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setOppId(objOpp2.Id)
			.build();
		insert objTicket2;

		objTicket2.Status__c = TicketUtil.TICKET_STATUS_LOST;
		update objTicket2;

		objOpp2 = [SELECT Id, StageName FROM Opportunity WHERE Id = :objOpp2.Id];
		System.assertEquals(OpportunityUtil.CLOSED_LOST_STAGE, objOpp2.StageName, 'Opportunity2 not updated to Closed Lost');

		Test.stopTest();
	}

	/**
	 * @description Test Opp re-opened on Ardius Ticket inserted or updated from 'lost' to any other open status
	 */
	@isTest
	static void testUpdationOnRelatedOpportunity() {
		List<Opportunity> list_Opps = [
			SELECT Id, StageName
			FROM Opportunity
			WHERE RecordTypeId = :OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID AND StageName != :OpportunityUtil.CLOSED_WON_STAGE
			LIMIT 1
		];
		System.assertEquals(1, list_Opps.size(), 'Invalid Test data');
		Opportunity objOpp1 = list_Opps[0];

		Test.startTest();
		objOpp1.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
		update objOpp1;

		//On ticket Insert --> Opp.Stage = New
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(UserInfo.getUserId())
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.setOppId(objOpp1.Id)
			.build();
		insert objTicket;

		objOpp1 = [SELECT Id, StageName, Ticket_Status__c FROM Opportunity WHERE Id = :objOpp1.Id];
		System.assertEquals(OpportunityUtil.DISCOVERY_CALL_SCHEDULED_STAGE, objOpp1.StageName, 'Opportunity not updated to new');

		//On ticket Insert --> Assert related ticket status is populated on opportunity
		System.assertEquals(objTicket.Status__c, objOpp1.Ticket_Status__c, 'Ticket status not populated on opportunity');

		//On Ticket Lost to another value ==> Opp.Stage = New
		objTicket.Status__c = TicketUtil.TICKET_STATUS_LOST;
		update objTicket;

		objTicket.Status__c = TicketUtil.TICKET_STATUS_NEW;
		update objTicket;

		objOpp1 = [SELECT Id, StageName, Ticket_Status__c FROM Opportunity WHERE Id = :objOpp1.Id];
		System.assertEquals(OpportunityUtil.DISCOVERY_CALL_SCHEDULED_STAGE, objOpp1.StageName, 'Opportunity2 not updated to new');

		//On ticket update --> Assert related ticket status is updated on opportunity
		System.assertEquals(objTicket.Status__c, objOpp1.Ticket_Status__c, 'Ticket status not updated on opportunity');
		Test.stopTest();
	}
}