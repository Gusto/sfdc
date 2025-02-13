public with sharing class HIRenewalQueue implements Queueable {
	private List<HI_Renewal__c> list_Renewals;

	public HIRenewalQueue(List<HI_Renewal__c> list_InputRenewals) {
		list_Renewals = list_InputRenewals;
	}

	public void execute(QueueableContext context) {
		HIRenewalTriggerHelper.queue = true;
		if (list_Renewals.size() > 0) {
			update list_Renewals;
		}
	}
}