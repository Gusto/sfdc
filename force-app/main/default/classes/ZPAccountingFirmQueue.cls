public with sharing class ZPAccountingFirmQueue implements Queueable {
	private List<ZP_Accounting_Firm__c> list_Firms;

	public ZPAccountingFirmQueue(List<ZP_Accounting_Firm__c> list_InputFirms) {
		list_Firms = list_InputFirms;
	}

	public void execute(QueueableContext context) {
		ZPAccountingFirmTriggerHelper.queue = true;
		if (list_Firms.size() > 0) {
			update list_Firms;
		}
	}
}