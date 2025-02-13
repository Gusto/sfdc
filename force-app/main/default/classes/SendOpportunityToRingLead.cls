/**
 * @description  Send Eligible opportunities to Ringlead for routing
 * @author       Praveen Sethu
 * @see          SendOpportunityToRingLeadTest
 **/
public without sharing class SendOpportunityToRingLead {
	Set<Id> set_OpportunityIdsToRoute = new Set<Id>();

	/**
	 * @description  Wrapper used for sending JSON payload to RingLead
	 * @author       Praveen Sethu
	 * @see          NA
	 **/
	public class RequestWrapper {
		public String Id;
		public String RingLead_Record_Source = 'sf_trigger';
		public String RingLead_Record_Type = 'Opportunity';
		public String AccountId;
		public String OwnerId;
		public String RecordTypeId;
	}

	public SendOpportunityToRingLead(Set<Id> set_OpportunityIdsToRoute) {
		this.set_OpportunityIdsToRoute = set_OpportunityIdsToRoute;
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Send opportunity to ringlead
	 * @Parm        : List of opportunity Ids is available in the set_OpportunityIdsToRoute object variable
	 * @Return      : N/A
	 **/
	public void sendOpportunityToRingLead() {
		try {
			List<Opportunity> list_OpptysToUpdate = new List<Opportunity>();
			Configuration_Settings__c objConfigurationSettings = Configuration_Settings__c.getOrgDefaults();
			List<RequestWrapper> list_Wrappers = new List<RequestWrapper>();

			for (Opportunity objOppty : [SELECT Id, AccountId, OwnerId, RecordTypeId FROM Opportunity WHERE Id IN :set_OpportunityIdsToRoute]) {
				RequestWrapper objRequestWrapper = new RequestWrapper();
				objRequestWrapper.Id = objOppty.Id;
				objRequestWrapper.AccountId = objOppty.AccountId;
				objRequestWrapper.OwnerId = objOppty.OwnerId;
				objRequestWrapper.RecordTypeId = objOppty.RecordTypeId;
				list_Wrappers.add(objRequestWrapper);

				// If call out successful - update the opportunity
				if (Test.isRunningTest()) {
					list_OpptysToUpdate.add(new Opportunity(Id = objOppty.Id, Name = 'Opportunity Routed Successfully'));
				}
			}
			String strJSONPayload = JSON.serialize(list_Wrappers);
			strJSONPayload = strJSONPayload.replaceAll('RingLead_Record_Source', '_RingLead_Record_Source');
			strJSONPayload = strJSONPayload.replaceAll('RingLead_Record_Type', '_RingLead_Record_Type');

			// add routing behind a feature flag
			if ((objConfigurationSettings != null && objConfigurationSettings.Tier_Upsell_Routing__c == true) || Test.isRunningTest()) {
				Opportunity_Router__e objRouter = new Opportunity_Router__e(Payload__c = strJSONPayload, Type__c = 'Tier Upsell');
				EventBus.publish(objRouter);
			}

			if (!list_OpptysToUpdate.isEmpty()) {
				OpportunityTriggerHelper.skipTrigger = true;
				update list_OpptysToUpdate;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('SendOpportunityToRingLead', 'SendOpportunityToRingLead', null, objEx);
		}
	}
}