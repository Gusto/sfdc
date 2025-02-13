/**
 * @description Handles Ardius Integrations
 * Done Asynchronously & Utilizes External services to do callout
 * @author      Ajay Krishna P U
 * @since       2023-12-28
 * @see         ArdiusIntegrationHelperTest
 */
public without sharing class ArdiusIntegrationHelper {
	//Constants
	private static final String DQ_DISQUALIFIED = 'Disqualified';
	private static final String API_STATUS_LOST = 'Lost';
	private static final String API_STATUS_UNRESPONSIVE = 'Unresponsive';
	private static final String LOST_DETAIL_ACCOUNT_FLAGGED = 'Account suspended';
	private static final String LOST_DETAIL2_SUSPENDED = 'Suspended';

	//Static Trackers
	private static List<Id> list_TicketIdsToProcess = new List<Id>();
	private static Set<Id> set_TicketIdsToProcess = new Set<Id>();
	private static Map<Id, Ticket__c> map_OldTicketVersions = new Map<Id, Ticket__c>();

	//Configurations
	private static Ardius_Configuration__c objArdiusConfiguration = Ardius_Configuration__c.getInstance();

	/**
	 * @description           Identify and trigger Ardius Ticket Integration if needed
	 * @param list_NewTickets New Version of Tickets
	 * @param map_OldTickets  Old Version of Tickets
	 */
	public static void triggerTicketIntegration(List<Ticket__c> list_NewTickets, Map<Id, Ticket__c> map_OldTickets) {
		//Skip trigger if Integration is off
		if (objArdiusConfiguration?.Is_Mulesoft_Ticket_Integration_Active__c != true) {
			return;
		}

		//Identify Tickets needs to be synched
		Boolean blnInsert = map_OldTickets == null;
		for (Ticket__c objNewTicket : list_NewTickets) {
			Ticket__c objOldTicket = blnInsert ? null : map_OldTickets.get(objNewTicket.Id);

			if (objNewTicket.RecordTypeId == TicketUtil.ARDIUS_TICKET_RT_ID && objNewTicket.Qualification_Status__c != DQ_DISQUALIFIED && !getIntegrationTypes(objNewTicket, objOldTicket).isEmpty()) {
				addToProcessTracker(objNewTicket, objOldTicket);
			}
		}

		// Schedule an Async process to handle integration
		if (!list_TicketIdsToProcess.isEmpty()) {
			System.enqueueJob(new ArdiusIntegrationHelper.ArdiusIntegrationQueueable(list_TicketIdsToProcess, map_OldTicketVersions));
		}
	}

	/**
	 * @description        Add to tracker variables  which is used for integration
	 * The method can avoid recursion though the internal tracker set_TicketIdsToProcess
	 * @param objNewTicket New Version of Ticket
	 * @param objOldTicket Old version of Ticket, Can be null
	 */
	private static void addToProcessTracker(Ticket__c objNewTicket, Ticket__c objOldTicket) {
		//If already in tracker skip
		if (set_TicketIdsToProcess.contains(objNewTicket.Id)) {
			return;
		}

		//Add to Trackers
		list_TicketIdsToProcess.add(objNewTicket.Id);
		set_TicketIdsToProcess.add(objNewTicket.Id);
		map_OldTicketVersions.put(objNewTicket.Id, objOldTicket);
	}

	/**
	 * @description        Identify the type of integration to be triggered
	 * Note: Add conditions for New integrations here
	 * @param objNewTicket New version of Ticket
	 * @param objOldTicket Old version of Ticket, Can be null
	 * @return             `List<INTEGRATION_TYPE>`
	 */
	private static List<INTEGRATION_TYPE> getIntegrationTypes(Ticket__c objNewTicket, Ticket__c objOldTicket) {
		List<INTEGRATION_TYPE> list_OperationTypes = new List<INTEGRATION_TYPE>();
		Boolean blnInsert = objOldTicket == null;

		//Un Responsive Changed
		if (!blnInsert && objNewTicket.Unresponsive__c != objOldTicket.Unresponsive__c) {
			list_OperationTypes.add(INTEGRATION_TYPE.UN_RESPONSIVE);
		}

		//Lost
		if (objNewTicket.Status__c == TicketUtil.TICKET_STATUS_LOST && (blnInsert || objNewTicket.Status__c != objOldTicket.Status__c)) {
			list_OperationTypes.add(INTEGRATION_TYPE.LOST);
		}

		//Un Lost
		if (!blnInsert && objOldTicket.Status__c == TicketUtil.TICKET_STATUS_LOST && objNewTicket.Status__c != objOldTicket.Status__c) {
			list_OperationTypes.add(INTEGRATION_TYPE.UN_LOST);
		}

		return list_OperationTypes;
	}

	/**
	 * @description                   Generate requests for Integration & triggered from Queue asynchronously
	 * The method re-queries data to factor any changes before triggering the queue like recursion on Ticket trigger
	 * @param list_TicketIdsToProcess The list of Ticket Ids to Process
	 * @param map_OldTicketVersions   The old version of Ticket, A null value represent an Insert operation
	 * @return                        `List<ArdiusIntegrationHelper.IntegrationRequest>`
	 */
	private static List<ArdiusIntegrationHelper.IntegrationRequest> prepareIntegrationRequests(List<Id> list_TicketIdsToProcess, Map<Id, Ticket__c> map_OldTicketVersions) {
		List<ArdiusIntegrationHelper.IntegrationRequest> list_IntegrationRequests = new List<ArdiusIntegrationHelper.IntegrationRequest>();
		if (list_TicketIdsToProcess == null || map_OldTicketVersions == null) {
			return list_IntegrationRequests;
		}

		//Re query Ticket object to get the latest value
		for (Ticket__c objNewTicket : [
			SELECT Id, Status__c, Opportunity__c, Unresponsive__c, Lost_Detail__c, Lost_Detail2__c
			FROM Ticket__c
			WHERE RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID AND Qualification_Status__c != :DQ_DISQUALIFIED AND Id IN :list_TicketIdsToProcess
		]) {
			Ticket__c objOldTicket = map_OldTicketVersions.get(objNewTicket.Id);

			for (INTEGRATION_TYPE enIntegrationType : getIntegrationTypes(objNewTicket, objOldTicket)) {
				list_IntegrationRequests.add(new ArdiusIntegrationHelper.IntegrationRequest(enIntegrationType, objNewTicket, objOldTicket));
			}
		}

		return list_IntegrationRequests;
	}

	/**
	 * @description      Trigger integration by Integration Type
	 * Note: Add conditions for New integrations here
	 * @param objRequest Integration Request
	 */
	private static void doCallout(ArdiusIntegrationHelper.IntegrationRequest objRequest) {
		switch on objRequest.enIntegrationType {
			when UN_RESPONSIVE {
				doUnResponsiveCallout(objRequest);
			}
			when LOST {
				doLostCallout(objRequest);
			}
			when UN_LOST {
				doUnLostCallout(objRequest);
			}
		}
	}

	/**
	 * @description      Trigger and Handle Un- Responsive Callout using External services
	 * @param objRequest Integration Request
	 */
	private static void doUnResponsiveCallout(ArdiusIntegrationHelper.IntegrationRequest objRequest) {
		ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityStatus_Request objAPIInput;
		ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityStatus_Response objAPIResponse;

		try {
			objAPIInput = new ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityStatus_Request();
			objAPIInput.requestParamters = new ExternalService.ArdiusMulesoftService_patchSalesforceOpportunityStatus_IN_requestParamters();
			objAPIInput.requestParamters.status = API_STATUS_UNRESPONSIVE;
			objAPIInput.requestParamters.oppx5fid = objRequest.objNewTicket.Opportunity__c;
			objAPIInput.requestParamters.isx5funresponsive = objRequest.objNewTicket.Unresponsive__c;
			objAPIInput.requestParamters.lostx5fdetail = objRequest.objNewTicket.Lost_Detail__c;
			objAPIInput.requestParamters.lostx5fdetailx5f2 = objRequest.objNewTicket.Lost_Detail2__c;

			objAPIResponse = new ExternalService.ArdiusMulesoftService().patchSalesforceOpportunityStatus(objAPIInput);
		} catch (ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityStatus_ResponseException objEx) {
			handleException(objEx.responseCode, objEx.defaultResponse, objEx, 'doUnResponsiveCallout');
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ArdiusIntegrationHelper', 'doUnResponsiveCallout', objEx);
		} finally {
			debugIntegration(objAPIInput, objAPIResponse, 'doUnResponsiveCallout');
		}
	}

	/**
	 * @description      Trigger and Handle Lost Callout using External services
	 * @param objRequest Integration Request
	 */
	private static void doLostCallout(ArdiusIntegrationHelper.IntegrationRequest objRequest) {
		ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityStatus_Request objAPIInput;
		ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityStatus_Response objAPIResponse;

		try {
			objAPIInput = new ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityStatus_Request();
			objAPIInput.requestParamters = new ExternalService.ArdiusMulesoftService_patchSalesforceOpportunityStatus_IN_requestParamters();
			objAPIInput.requestParamters.status = API_STATUS_LOST;
			objAPIInput.requestParamters.oppx5fid = objRequest.objNewTicket.Opportunity__c;
			objAPIInput.requestParamters.lostx5fdetail = objRequest.objNewTicket.Lost_Detail__c;
			objAPIInput.requestParamters.lostx5fdetailx5f2 = objRequest.objNewTicket.Lost_Detail__c == LOST_DETAIL_ACCOUNT_FLAGGED && String.isBlank(objRequest.objNewTicket.Lost_Detail2__c)
				? LOST_DETAIL2_SUSPENDED
				: objRequest.objNewTicket.Lost_Detail2__c;

			objAPIResponse = new ExternalService.ArdiusMulesoftService().patchSalesforceOpportunityStatus(objAPIInput);
		} catch (ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityStatus_ResponseException objEx) {
			handleException(objEx.responseCode, objEx.defaultResponse, objEx, 'doLostCallout');
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ArdiusIntegrationHelper', 'doLostCallout', objEx);
		} finally {
			debugIntegration(objAPIInput, objAPIResponse, 'doLostCallout');
		}
	}

	/**
	 * @description      Trigger and Handle Un- Lost Callout using External services
	 * @param objRequest Integration Request
	 */
	private static void doUnLostCallout(ArdiusIntegrationHelper.IntegrationRequest objRequest) {
		ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityUnlostByOptyx5fid_Request objAPIInput;
		ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityUnlostByOptyx5fid_Response objAPIResponse;

		try {
			objAPIInput = new ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityUnlostByOptyx5fid_Request();
			objAPIInput.optyx5fid = objRequest.objNewTicket.Opportunity__c;

			objAPIInput.requestParamters = new ExternalService.ArdiusMulesoftService_patchSalesforceOpportunityUnlostByOptyx5fid_IN_requestParamters();
			objAPIInput.requestParamters.status = objRequest.objNewTicket.Status__c;
			objAPIInput.requestParamters.oppx5fid = objRequest.objNewTicket.Opportunity__c;

			objAPIResponse = new ExternalService.ArdiusMulesoftService().patchSalesforceOpportunityUnlostByOptyx5fid(objAPIInput);
		} catch (ExternalService.ArdiusMulesoftService.patchSalesforceOpportunityUnlostByOptyx5fid_ResponseException objEx) {
			handleException(objEx.responseCode, objEx.defaultResponse, objEx, 'doUnLostCallout');
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ArdiusIntegrationHelper', 'doUnLostCallout', objEx);
		} finally {
			debugIntegration(objAPIInput, objAPIResponse, 'doUnLostCallout');
		}
	}

	/**
	 * @description                Handle callout Exception& Create Exception log based on the inputs
	 * @param intResponseCode      Response Status Code
	 * @param strExceptionResponse Exception String
	 * @param objEx                Exception Object
	 * @param strMethod            The method generated the exception
	 */
	private static void handleException(Integer intResponseCode, String strExceptionResponse, Exception objEx, String strMethod) {
		String strMessage = String.format(
			'ResponseCode:{0}, Response:{1}',
			new List<String>{ intResponseCode == null ? '' : String.valueOf(intResponseCode), strExceptionResponse == null ? '' : strExceptionResponse }
		);
		ExceptionLogUtil.logException('ArdiusIntegrationHelper', strMethod, strMessage, objEx.getStackTraceString());
	}

	/**
	 * @description          Debug Integration if Enabled, by creating an Exception log with API request and responses.
	 * @param objAPIRequest  API Request
	 * @param objAPIResponse API Responses
	 * @param strMethod      The method triggered the callout
	 */
	private static void debugIntegration(Object objAPIRequest, Object objAPIResponse, String strMethod) {
		if (objArdiusConfiguration?.Is_Ardius_Integrations_In_Debug__c != true) {
			return;
		}

		String strMessage = String.format(
			'Request:{0}, Response:{1}',
			new List<String>{ objAPIRequest == null ? '' : JSON.serialize(objAPIRequest), objAPIResponse == null ? '' : JSON.serialize(objAPIResponse) }
		);
		ExceptionLogUtil.logException('ArdiusIntegrationHelper - Debug', strMethod, strMessage, '');
	}

	/**
	 * Integration types Enums
	 * Note: Add enums for New integrations here
	 */
	public enum INTEGRATION_TYPE {
		UN_RESPONSIVE,
		LOST,
		UN_LOST
	}

	/**
	 * Queueable apex class trigger integrations
	 */
	public class ArdiusIntegrationQueueable implements Queueable {
		private List<Id> list_TicketIdsToProcess;
		private Map<Id, Ticket__c> map_OldTicketVersions;
		private List<ArdiusIntegrationHelper.IntegrationRequest> list_IntegrationRequests;

		/**
		 * @description                   Constructor to schedule a Queueable job
		 * @param list_TicketIdsToProcess The Ticket Ids to Process
		 * @param map_OldTicketVersions   Old version of Tickets
		 */
		public ArdiusIntegrationQueueable(List<Id> list_TicketIdsToProcess, Map<Id, Ticket__c> map_OldTicketVersions) {
			this.list_TicketIdsToProcess = list_TicketIdsToProcess;
			this.map_OldTicketVersions = map_OldTicketVersions;
			this.list_IntegrationRequests = null;
		}

		/**
		 * @description                   Constructor to re-schedule a Queueable job, Used for internal purpose
		 */
		public ArdiusIntegrationQueueable(List<ArdiusIntegrationHelper.IntegrationRequest> list_IntegrationRequests) {
			this.list_TicketIdsToProcess = null;
			this.map_OldTicketVersions = null;
			this.list_IntegrationRequests = list_IntegrationRequests;
		}

		/**
		 * @description      Queueable Execute triggers integrations one by one
		 * @param objContext Queueable Context
		 */
		public void execute(QueueableContext objContext) {
			//1. Prepare Data if needed
			if (this.list_IntegrationRequests == null) {
				this.list_IntegrationRequests = prepareIntegrationRequests(this.list_TicketIdsToProcess, this.map_OldTicketVersions);
			}

			//2. Check if any request to process
			if (this.list_IntegrationRequests.isEmpty()) {
				return;
			}

			//3. Shift the first item
			ArdiusIntegrationHelper.IntegrationRequest objRequest = this.list_IntegrationRequests.remove(0);

			//3. Trigger the integration
			ArdiusIntegrationHelper.doCallout(objRequest);

			//4. Reschedule Queueable  if needed
			if (!this.list_IntegrationRequests.isEmpty()) {
				System.enqueueJob(new ArdiusIntegrationHelper.ArdiusIntegrationQueueable(this.list_IntegrationRequests));
			}
		}
	}

	/**
	 * Holds the Integration request
	 */
	public class IntegrationRequest {
		INTEGRATION_TYPE enIntegrationType;
		Ticket__c objNewTicket;
		Ticket__c objOldTicket;

		public IntegrationRequest(INTEGRATION_TYPE enIntegrationType, Ticket__c objNewTicket, Ticket__c objOldTicket) {
			this.enIntegrationType = enIntegrationType;
			this.objNewTicket = objNewTicket;
			this.objOldTicket = objOldTicket;
		}
	}
}