global class FailedRecordsAccountAssignmentScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		TaxOpsFailedRecordAccountAssignmentBatch batchCtrl = new TaxOpsFailedRecordAccountAssignmentBatch();
		Database.executeBatch(batchCtrl, 200);
	}
}