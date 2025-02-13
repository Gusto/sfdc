/**
Created by : Gaurav Khare
Created Date : 4/23/2019
**/
public with sharing class BulkUserCSVDataTriggerQueue implements Queueable {
	private Set<Id> recIds;
	private String operation;
	private Map<String, String> dmlAllErrorsMap = new Map<String, String>();

	public BulkUserCSVDataTriggerQueue(Set<Id> inputRecIds, Map<String, String> inputDmlAllErrorsMap, string inputOperation) {
		recIds = inputRecIds;
		operation = inputOperation;
		dmlAllErrorsMap = inputDmlAllErrorsMap;
	}

	public void execute(QueueableContext context) {
		BulkUserCSVDataTriggerHelper helper = new BulkUserCSVDataTriggerHelper();
		if (operation == 'ProcessRecords') {
			if (recIds.size() > 0) {
				helper.processInformation(recIds);
			}
		} else {
			helper.updateStatus(dmlAllErrorsMap, recIds);
		}
	}
}