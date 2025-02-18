/**
 * @description  Used for testing the related records
 * @author       Bhagat Singh
 * @date         07/15/2024
 * @see          RelatedRecordsCtrl
 **/
@isTest
public class RelatedRecordsCtrlTest {
	@testSetup
	static void setup() {
		Utils.skipTrigger(true);
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test').setUniqueName('Test').setState('CA').build();
		insert objCarrier;
		Account objAccRecord = new TestDataFactory.AccountBuilder()
			.setName('Test Demo AccountName 1')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setBillingStreet('Testing Avenue 1')
			.setBillingPostalCode('123456')
			.setPhone('19992344444')
			.setCompanyTradeName('Company trade name 1')
			.setShippingStreet('Testing Avenue 1')
			.setShippingPostalCode('123455')
			.build();
		insert objAccRecord;

		Opportunity objOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('OppRecord')
			.setStage(OpportunityUtil.SAL_STAGE)
			.setCloseDate(Date.today().addDays(60))
			.setAccountId(objAccRecord.Id)
			.build();
		insert objOppNewPlan;

		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
			.setName('TEST BENEFIT ORDER')
			.setRecordType(BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID)
			.setOpp(objOppNewPlan.Id)
			.setStatus(BenefitOrderUtil.STATUS_FULFILLED)
			.setQualificationOwner(UserInfo.getUserId())
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert objBO;

		Carrier_Order__c objCO = new TestDataFactory.CarrierOrderBuilder()
			.setName('TEST CARRIER ORDER')
			.setCarrier(objCarrier.Id)
			.setBenefitOrder(objBO.Id)
			.setOrderType(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO)
			.setRecordTypeId(CarrierOrderUtil.RECTYPE_NEW_PLAN)
			.setImplementationStage(CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_QUALIFICATION)
			.setOwnerId(UserInfo.getUserId())
			.setBenefitTypes('Test')
			.build();
		insert objCO;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_BENEFITS_NEW_PLAN_CASE)
			.setAccountId(objAccRecord.Id)
			.setBenefitOrder(objBO.Id)
			.setOpportunity(objOppNewPlan.Id)
			.setSubject('Test Relation')
			.setDescription('Test Relation')
			.setSuppliedEmail('TickettriggerHelper@gusto.com')
			.setType(CaseUtils.TYPE_SALES)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.build();
		insert objCase;
		
		Task objTask = new TestDataFactory.TaskBuilder()
			.setRecordTypeId(TaskUtil.TASK_BENEFIT_FULFILLMENT_RT_ID)
			.setWhatId(objCO.Id)
			.setStatus(TaskUtil.TASK_STATUS_CONNECT)
			.setSubject('Open Task')
			.setType(TaskUtil.TASK_TYPE_DEMO)
			.build();
		insert objTask;
		
		Utils.skipTrigger(false);
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method validate open Ticket with Carrier Order redords.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testGetOpenTicketIdWithCO() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID LIMIT 1];
		Carrier_Order__c objCO = [SELECT Id, OwnerId, Ticket_Action_Required__c FROM Carrier_Order__c WHERE Benefit_Order__c = :objBO.Id LIMIT 1];
		Case objCase = [SELECT Id FROM Case WHERE Benefit_Order__c = :objBO.Id LIMIT 1];

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOwnerId(objCO.OwnerId)
			.setCaseId(objCase.Id)
			.setRecordTypeId(TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setEscalationReason('Rate Discrepancy')
			.setPriority(TicketUtil.TICKET_PRIORITY_LOW)
			.setEscalationReasonDetail('Incorrect rates for plan year')
			.setReportingTeam('Confirmation')
			.setTeam(TicketUtil.TICKET_TEAM_ONBOARDING)
			.setSubTeam(TicketUtil.TICKET_ROLE_IMPLEMENTATION)
			.setBenefitOrderId(objBO.Id)
			.setCarrierOrderId(objCO.Id)
			.setCloseDate(System.today().adddays(15))
			.setErrorOrigin('Benefit Transfer Fulfillment')
			.setRateDiscrepencyResolution('No Error')
			.build();
		insert objTicket;

		Ticket__c objOpenTicket = RelatedRecordsCtrl.getOpenTicketIdWithCO(objCO.Id);

		Test.stopTest();

		System.assertEquals(objCO.OwnerId, objOpenTicket.OwnerId, 'There is no open ticket exist with carrier order.');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method validate Convert lightning links into classic.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testConvertLightningToClassic() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID LIMIT 1];
		String strExpectedURL = RelatedRecordsCtrl.strClassicURL + '/' + objBO.Id;
		String strInputURL = 'https://gusto.lightning.force.com/lightning/r/Benefit_Order__c/' + objBO.Id + '/view';
		String strBaseURL = 'https://gusto.lightning.force.com';
		RelatedRecordsCtrl.WrapperUrl objWrapper = RelatedRecordsCtrl.convertURL(strInputURL, strBaseURL);

		Test.stopTest();

		System.assertEquals(strExpectedURL, objWrapper.strOutputUrl, 'Unable to covert URL.');
		System.assertEquals(RelatedRecordsCtrl.strLWCToClassicMsg, objWrapper.strMessage, 'Unable to covert URL.');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method validate Convert classic links into lightning.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testConvertClassicToLightning() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id FROM Benefit_Order__c WHERE RecordTypeId = :BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID LIMIT 1];
		String strExpectedURL = 'https://gusto.lightning.force.com/lightning/r/Benefit_Order__c/' + objBO.Id + '/view';
		String strInputURL =  RelatedRecordsCtrl.strClassicURL + '/' + objBO.Id;
		String strBaseURL = 'https://gusto.lightning.force.com';
		RelatedRecordsCtrl.WrapperUrl objWrapper = RelatedRecordsCtrl.convertURL(strInputURL, strBaseURL);

		Test.stopTest();

		System.assertEquals(strExpectedURL, objWrapper.strOutputUrl, 'Unable to covert URL.');
		System.assertEquals(RelatedRecordsCtrl.strClassicToLWCMsg, objWrapper.strMessage, 'Unable to covert URL.');
	}
	
	/**
	 * @author       Bhagat Singh
	 * @description  This method show open Task with Carrier Order records.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void testOpenTaskWithCO() {
		Test.startTest();
		Carrier_Order__c objCO = [SELECT Id, OwnerId, Ticket_Action_Required__c FROM Carrier_Order__c WHERE RecordTypeId = :CarrierOrderUtil.RECTYPE_NEW_PLAN LIMIT 1];
		List<RelatedRecordsCtrl.TaskWrapper> list_Tasks = RelatedRecordsCtrl.getOpenTaskWithCO(objCO.Id);
		Test.stopTest();
		
		System.assertEquals('Open Task', list_Tasks[0].strSubject, 'There is not open task');		
	}
}