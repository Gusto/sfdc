public class OpportunityRoutingQueuable implements Queueable, Database.AllowsCallouts {
    public Map<Id, Opportunity> map_Opportunities = new Map<Id, Opportunity>();
    
    public OpportunityRoutingQueuable(Map<Id, Opportunity> map_Opportunities) {
        this.map_Opportunities = map_Opportunities;
    }
    
    public void execute(QueueableContext context) {
        if (map_Opportunities != null && !map_Opportunities.isEmpty()) {
            List<SendAccountToRingLead.RequestWrapper> list_ReqWrappers = new List<SendAccountToRingLead.RequestWrapper>();
            for (Opportunity objOpp : map_Opportunities.values()) {
                SendAccountToRingLead.RequestWrapper objRequest = new SendAccountToRingLead.RequestWrapper();
                objRequest.idRecord = objOpp.Id;
                objRequest.strObjectType = 'Opportunity';
                objRequest.strRoutingType = 'Tier Upsell';
                list_ReqWrappers.add(objRequest);
            }
            SendAccountToRingLead.sendAccountToRingLead(list_ReqWrappers);
        }
    }
}