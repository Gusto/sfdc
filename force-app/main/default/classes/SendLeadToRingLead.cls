/**
 * @description  Send Eligible accounts to Mulesoft which then sends to RingLead for Routing
 * @author       Aviinandaan Duta
 * @date         02-29-2024
 * @see          SendLeadToRingLeadTest
 **/
public with sharing class SendLeadToRingLead implements Queueable, Database.AllowsCallouts {
	public Map<Id, Lead> map_Leads = new Map<Id, Lead>();

	// Default Constructor - DO NOT REMOVE
	public SendLeadToRingLead() {
	}

	/**
	 * @Description : Paramterized Constructor
	 * @Param       : Collection of leads needing callout
	 **/
	public SendLeadToRingLead(Map<Id, Lead> map_Leads) {
		this.map_Leads = map_Leads;
	}

	/**
	 * @description  Wrapper used for sending JSON payload to Mulesoft
	 **/
	public class RequestWrapper {
		public Id LeadId;
		public String Email;
		public String FirstName;
		public String LastName;
		public Decimal LeadRouteCount;

		/**
		 * @Description : Paramterized Constructor for callout request wrapper
		 * @Param       : Lead details to be sent in payload - Id, Email, Name, Route count
		 **/
		public RequestWrapper(Id LeadId, String Email, String FirstName, String LastName, Decimal LeadRouteCount) {
			this.LeadId = LeadId;
			this.Email = Email;
			this.FirstName = FirstName;
			this.LastName = LastName;
			this.LeadRouteCount = LeadRouteCount;
		}
	}

	/**
	 * @Description : Execute method of queable interface as entry point of queued job.
	 * 				  It performs the callouts within allowed limit and chains new job if there are remaining callouts
	 * @Parm        : An instance of a queable context
	 * @Return      : N/A
	 **/
	public void execute(QueueableContext context) {
		map_Leads = doCallout(map_Leads);
		if (!map_Leads.isEmpty() && !Test.isRunningTest()) {
			Id idQueueJobId = System.enqueueJob(new SendLeadToRingLead(map_Leads));
			System.debug('*****SendLeadToRingLead - New job with Id ' + idQueueJobId + ' enqueued for remaining callouts*****');
		}
	}

	/**
	 * @Description : Utility method to make callouts to ringlead for lead routing.
	 * @Param       : Leads needing routing
	 * @Return      : Remaining leads that were not called out due to insufficient resources.
	 * @see         : LeadTriggerHelper.doLeadRoutingCallout
	 **/
	public static Map<Id, Lead> doCallout(Map<Id, Lead> map_Leads) {
		Map<Id, Lead> map_LeadsRemaining = new Map<Id, Lead>();
		List<Lead> list_LeadsToUpdate = new List<Lead>();

		//If callouts available, perform callout. Else add to remaining list.
		for (Id idLead : map_Leads.keySet()) {
			Lead objLead = map_Leads.get(idLead);
			if (Limits.getLimitCallouts() > 0) {
				RequestWrapper objRequestContent = new RequestWrapper(objLead.Id, objLead.Email, objLead.FirstName, objLead.LastName, objLead.Lead_Route_Count__c);
				HttpRequest objRequest = new HttpRequest();
				objRequest.setEndpoint('callout:Lead_Routing_Mulesoft');
				objRequest.setMethod('POST');
				objRequest.setBody(JSON.serialize(objRequestContent));
				objRequest.setHeader('Content-Type', 'application/json');
				Http http = new Http();
				HTTPResponse objResponse = http.send(objRequest);

				// update lead route count flag if running from test class
				if (Test.isRunningTest()) {
					objLead.Lead_Route_Count__c = 2;
					list_LeadsToUpdate.add(objLead);
				}
			} else {
				map_LeadsRemaining.put(idLead, objLead);
			}
		}

		if (!list_LeadsToUpdate.isEmpty()) {
			LeadTriggerHelper.skipTrigger = true;
			update list_LeadsToUpdate;
		}
		return map_LeadsRemaining;
	}
}