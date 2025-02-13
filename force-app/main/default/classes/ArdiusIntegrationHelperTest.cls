/**
 * @description Ardius Integration Helper Test class
 * @author      Ajay Krishna P U
 * @since       2024-01-03
 */
@isTest
public with sharing class ArdiusIntegrationHelperTest {
	final static String DEBUG_LOG = 'DEBUG_LOG';
	final static String EXCEPTION_LOG = 'EXCEPTION_LOG';

	/**
	 * @description To setup initial Test data setup
	 */
	@TestSetup
	static void setupData() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		TicketTriggerHelper.skipTrigger = true;

		Ardius_Configuration__c objArdiusConfig = new TestDataFactory.ArdiusConfigurationBuilder()
			.setActivateTicketIntegration(true)
			.setIntegrationInDebugMode(true)
			.build();
		insert objArdiusConfig;

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Demo AccountName 1')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setBillingStreet('Testing Avenue 1')
			.setBillingPostalCode('123456')
			.setPhone('19992344444')
			.setCompanyTradeName('Company trade name 1')
			.setShippingStreet('Testing Avenue 1')
			.setShippingPostalCode('123455')
			.build();
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setAccountId(objAccount.Id)
			.setName('Test Ardius Opportunity')
			.setStage(OpportunityUtil.NEW_STAGE)
			.setCloseDate(System.today())
			.build();
		insert objOpportunity;

		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setOppId(objOpportunity.Id)
			.setAccountId(objAccount.Id)
			.setStatus(TicketUtil.TICKET_STATUS_NEW)
			.setDescription('Test Ardius')
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId(TicketUtil.ARDIUS_TICKET_RT_ID)
			.build();
		insert objTicket;

		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
		TicketTriggerHelper.skipTrigger = false;
	}

	/**
	 * @description Test Un Responsive API
	 * triggered when Unresponsive__c = true
	 */
	@isTest
	static void testUnResponsive() {
		Test.setMock(HttpCalloutMock.class, new GeneralSuccessCalloutMock());

		List<Ticket__c> list_Tickets = [SELECT Id FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assertEquals(1, list_Tickets.size(), 'Test data Ticket unavailable');
		Ticket__c objTicket = list_Tickets[0];

		Test.startTest();
		objTicket.Unresponsive__c = true;
		update objTicket;
		Test.stopTest();

		Map<String, List<Exception_Log__c>> map_TypeToLogs = getIntegrationLogs();
		System.assertEquals(1, map_TypeToLogs.get(DEBUG_LOG).size(), 'Failed - Unresponsive, success log did not generated');
		System.assertEquals(0, map_TypeToLogs.get(EXCEPTION_LOG).size(), 'Failed - Unresponsive, exception log generated');
	}

	/**
	 * @description Test Un Responsive API
	 * triggered when Unresponsive__c = false
	 */
	@isTest
	static void testResponsive() {
		Test.setMock(HttpCalloutMock.class, new GeneralSuccessCalloutMock());

		List<Ticket__c> list_Tickets = [SELECT Id FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assertEquals(1, list_Tickets.size(), 'Test data Ticket unavailable');
		Ticket__c objTicket = list_Tickets[0];

		//Skip trigger ==> skip integration
		TicketTriggerHelper.skipTrigger = true;
		objTicket.Unresponsive__c = true;
		update objTicket;
		TicketTriggerHelper.skipTrigger = false;

		Test.startTest();
		objTicket.Unresponsive__c = false;
		update objTicket;
		Test.stopTest();

		Map<String, List<Exception_Log__c>> map_TypeToLogs = getIntegrationLogs();
		System.assertEquals(1, map_TypeToLogs.get(DEBUG_LOG).size(), 'Failed - Responsive, success log did not generated');
		System.assertEquals(0, map_TypeToLogs.get(EXCEPTION_LOG).size(), 'Failed - Responsive, exception log generated');
	}

	/**
	 * @description Test Lost API
	 * triggered when Status__c = Lost
	 */
	@isTest
	static void testLost() {
		Test.setMock(HttpCalloutMock.class, new GeneralSuccessCalloutMock());

		List<Ticket__c> list_Tickets = [SELECT Id FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assertEquals(1, list_Tickets.size(), 'Test data Ticket unavailable');
		Ticket__c objTicket = list_Tickets[0];

		Test.startTest();
		objTicket.Status__c = TicketUtil.TICKET_STATUS_LOST;
		objTicket.Lost_Detail__c = 'Price';
		objTicket.Lost_Detail2__c = 'Other';
		update objTicket;
		Test.stopTest();

		Map<String, List<Exception_Log__c>> map_TypeToLogs = getIntegrationLogs();
		System.assertEquals(1, map_TypeToLogs.get(DEBUG_LOG).size(), 'Failed - Lost, success log did not generated');
		System.assertEquals(0, map_TypeToLogs.get(EXCEPTION_LOG).size(), 'Failed - Lost, exception log generated');
	}

	/**
	 * @description Test UnLost API
	 * triggered when Status__c Changed from Lost to other
	 */
	@isTest
	static void testUnLost() {
		Test.setMock(HttpCalloutMock.class, new GeneralSuccessCalloutMock());

		List<Ticket__c> list_Tickets = [SELECT Id FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assertEquals(1, list_Tickets.size(), 'Test data Ticket unavailable');
		Ticket__c objTicket = list_Tickets[0];

		//Skip trigger ==> skip integration
		TicketTriggerHelper.skipTrigger = true;
		objTicket.Status__c = TicketUtil.TICKET_STATUS_LOST;
		objTicket.Lost_Detail__c = 'Price';
		objTicket.Lost_Detail2__c = 'Other';
		update objTicket;
		TicketTriggerHelper.skipTrigger = false;

		Test.startTest();
		objTicket.Status__c = TicketUtil.TICKET_STATUS_NEW;
		objTicket.Lost_Detail__c = null;
		objTicket.Lost_Detail2__c = null;
		update objTicket;
		Test.stopTest();

		Map<String, List<Exception_Log__c>> map_TypeToLogs = getIntegrationLogs();
		System.assertEquals(1, map_TypeToLogs.get(DEBUG_LOG).size(), 'Failed - UnLost, success log did not generated');
		System.assertEquals(0, map_TypeToLogs.get(EXCEPTION_LOG).size(), 'Failed - UnLost, exception log generated');
	}

	/**
	 * @description Test UnResponsive API Failure
	 */
	@isTest
	static void testUnResponsiveFailure() {
		Test.setMock(HttpCalloutMock.class, new GeneralFailureCalloutMock());

		List<Ticket__c> list_Tickets = [SELECT Id FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assertEquals(1, list_Tickets.size(), 'Test data Ticket unavailable');
		Ticket__c objTicket = list_Tickets[0];

		Test.startTest();
		objTicket.Unresponsive__c = true;
		update objTicket;
		Test.stopTest();

		Map<String, List<Exception_Log__c>> map_TypeToLogs = getIntegrationLogs();
		System.assertEquals(1, map_TypeToLogs.get(DEBUG_LOG).size(), 'Failed - UnResponsive, log did not generated');
		System.assertEquals(1, map_TypeToLogs.get(EXCEPTION_LOG).size(), 'Failed - UnResponsive, exception log did not generated');
	}

	/**
	 * @description Test Lost API Failure
	 */
	@isTest
	static void testLostFailure() {
		Test.setMock(HttpCalloutMock.class, new GeneralFailureCalloutMock());

		List<Ticket__c> list_Tickets = [SELECT Id FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assertEquals(1, list_Tickets.size(), 'Test data Ticket unavailable');
		Ticket__c objTicket = list_Tickets[0];

		Test.startTest();
		objTicket.Status__c = TicketUtil.TICKET_STATUS_LOST;
		objTicket.Lost_Detail__c = 'Price';
		objTicket.Lost_Detail2__c = 'Other';
		update objTicket;
		Test.stopTest();

		Map<String, List<Exception_Log__c>> map_TypeToLogs = getIntegrationLogs();
		System.assertEquals(1, map_TypeToLogs.get(DEBUG_LOG).size(), 'Failed - Lost,  log did not generated');
		System.assertEquals(1, map_TypeToLogs.get(EXCEPTION_LOG).size(), 'Failed - Lost, exception log did not generated');
	}

	/**
	 * @description Test UnLost API Failure
	 */
	@isTest
	static void testUnLostFailure() {
		Test.setMock(HttpCalloutMock.class, new GeneralFailureCalloutMock());

		List<Ticket__c> list_Tickets = [SELECT Id FROM Ticket__c WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID LIMIT 1];
		System.assertEquals(1, list_Tickets.size(), 'Test data Ticket unavailable');
		Ticket__c objTicket = list_Tickets[0];

		//Skip trigger ==> skip integration
		TicketTriggerHelper.skipTrigger = true;
		objTicket.Status__c = TicketUtil.TICKET_STATUS_LOST;
		objTicket.Lost_Detail__c = 'Price';
		objTicket.Lost_Detail2__c = 'Other';
		update objTicket;
		TicketTriggerHelper.skipTrigger = false;

		Test.startTest();
		objTicket.Status__c = TicketUtil.TICKET_STATUS_NEW;
		objTicket.Lost_Detail__c = null;
		objTicket.Lost_Detail2__c = null;
		update objTicket;
		Test.stopTest();

		Map<String, List<Exception_Log__c>> map_TypeToLogs = getIntegrationLogs();
		System.assertEquals(1, map_TypeToLogs.get(DEBUG_LOG).size(), 'Failed - UnLost,  log did not generated');
		System.assertEquals(1, map_TypeToLogs.get(EXCEPTION_LOG).size(), 'Failed - UnLost, exception log did not generated');
	}

	/**
	 * @description Utility method to get the Integration status
	 * @return      `Map<String, List<Exception_Log__c>>`
	 */
	static Map<String, List<Exception_Log__c>> getIntegrationLogs() {
		Map<String, List<Exception_Log__c>> map_TypeToLogs = new Map<String, List<Exception_Log__c>>{ EXCEPTION_LOG => new List<Exception_Log__c>(), DEBUG_LOG => new List<Exception_Log__c>() };

		for (Exception_Log__c objLog : [SELECT Id, Class_Name__c FROM Exception_Log__c WHERE Class_Name__c LIKE 'ArdiusIntegrationHelper%']) {
			if (objLog.Class_Name__c.contains(' Debug')) {
				map_TypeToLogs.get(DEBUG_LOG).add(objLog);
			} else {
				map_TypeToLogs.get(EXCEPTION_LOG).add(objLog);
			}
		}

		return map_TypeToLogs;
	}

	/**
	 * Mock Response - Success
	 */
	public class GeneralSuccessCalloutMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest request) {
			HttpResponse objResponse = new HttpResponse();
			objResponse.setHeader('Content-Type', 'application/json');
			objResponse.setBody('{"status": "SUCCESS"}');
			objResponse.setStatusCode(200);
			return objResponse;
		}
	}

	/**
	 * Mock Response - Failure
	 */
	public class GeneralFailureCalloutMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest request) {
			HttpResponse objResponse = new HttpResponse();
			objResponse.setHeader('Content-Type', 'application/json');
			objResponse.setBody('{"status":"FAILURE","event_id":"0","response":"failed: bad request (400)"}');
			objResponse.setStatusCode(400);
			return objResponse;
		}
	}
}