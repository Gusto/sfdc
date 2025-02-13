public with sharing class HIBorTransferQueue implements Queueable {
	private List<HI_BoR_Transfer__c> list_BoRTransfers;

	public HIBorTransferQueue(List<HI_BoR_Transfer__c> list_InputBorTransfers) {
		list_BoRTransfers = list_InputBorTransfers;
	}

	public void execute(QueueableContext context) {
		HIBorTransferTriggerHelper.queue = true;
		if (list_BoRTransfers.size() > 0) {
			update list_BoRTransfers;
		}
	}
}