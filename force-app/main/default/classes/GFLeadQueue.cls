public with sharing class GFLeadQueue implements Queueable {
	private List<GF_Lead__c> list_Leads;

	public GFLeadQueue(List<GF_Lead__c> list_InputLeadList) {
		list_Leads = list_InputLeadList;
	}

	public void execute(QueueableContext context) {
		GFLeadTriggerHelper.queue = true;
		if (list_Leads.size() > 0) {
			update list_Leads;
		}
	}
}