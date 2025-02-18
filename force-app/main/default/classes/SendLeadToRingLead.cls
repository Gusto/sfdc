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

	public class LeadWrapper {
		public String Id;
		public String RingLead_Record_Source = 'sf_trigger';
		public String RingLead_Record_Type = 'Lead';
		public String OwnerId;
		public String RecordTypeId;
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
				
				LeadWrapper objLeadWrapper = new LeadWrapper();
				objLeadWrapper.Id = objLead.Id;
				objLeadWrapper.OwnerId = objLead.OwnerId;
				objLeadWrapper.RecordTypeId = objLead.RecordTypeId;

				String strJSONPayload = JSON.serialize(objLeadWrapper);
				strJSONPayload = strJSONPayload.replaceAll('RingLead_Record_Source', '_RingLead_Record_Source');
				strJSONPayload = strJSONPayload.replaceAll('RingLead_Record_Type', '_RingLead_Record_Type');

				// Send custom callout to Mulesoft endpoint
				HttpRequest objHTTPReq = new HttpRequest();
				objHTTPReq.setEndpoint('https://dms.ringlead.com/api/v1/webtolead/12679/8c90b913-86a1-494e-b146-1f65a02e34b1/submission/');

				objHTTPReq.setMethod('POST');
				objHTTPReq.setBody(strJSONPayload);
				objHTTPReq.setHeader('Content-Type', 'application/json');
				objHTTPReq.setTimeOut(120000);

				Http objHTTP = new Http();
				HTTPResponse objHTTPRes = objHTTP.send(objHTTPReq);

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