/**
Created by : Gaurav Khare
Created Date : 4/23/2019
**/
public with sharing class BulkOrderCSVDataTriggerQueue implements Queueable {
	private List<Bulk_Order_CSV_Data__c> recList;

	public BulkOrderCSVDataTriggerQueue(List<Bulk_Order_CSV_Data__c> inputRecList) {
		recList = inputRecList;
	}

	public void execute(QueueableContext context) {
		BulkOrderCSVDataTriggerHelper.queue = true;
		if (recList.size() > 0) {
			update recList;
		}
	}
}