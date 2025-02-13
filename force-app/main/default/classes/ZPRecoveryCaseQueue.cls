public with sharing class ZPRecoveryCaseQueue implements Queueable {
	private List<ZP_Recovery_Case__c> ZPRecoveryEntries;

	public ZPRecoveryCaseQueue(List<ZP_Recovery_Case__c> inputZPRecoveryEntries) {
		ZPRecoveryEntries = inputZPRecoveryEntries;
	}

	public void execute(QueueableContext context) {
		ZPRecoveryCaseTriggerHelper.queue = true;
		if (ZPRecoveryEntries.size() > 0) {
			update ZPRecoveryEntries;
		}
	}
}