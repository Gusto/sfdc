public with sharing class SalesCaseEmailLeadQueue implements Queueable {
	private List<Sales_Case_Email_Lead_Queue__c> caseEmailList;

	public SalesCaseEmailLeadQueue(List<Sales_Case_Email_Lead_Queue__c> inputCaseEmailList) {
		caseEmailList = inputCaseEmailList;
	}

	public void execute(QueueableContext context) {
		SalesCaseEmailLeadQueueTriggerHelper.queue = true;
		if (caseEmailList.size() > 0) {
			update caseEmailList;
		}
	}
}