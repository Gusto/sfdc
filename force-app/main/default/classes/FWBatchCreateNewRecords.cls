/**
 * @name         FWBatchCreateNewRecords
 * @author       Deepika Saini
 * @date         08 Jul 2022
 * @description  This batch is used to create new records when records to be inserted are greater than max limit.
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class FWBatchCreateNewRecords implements Database.Batchable<Sobject>, Database.Stateful {
	List<sObject> list_NewRecords = new List<sObject>();

	public FWBatchCreateNewRecords(List<sObject> list_NewRecordsToBeCreated) {
		list_NewRecords.addAll(list_NewRecordsToBeCreated);
	}

	public Iterable<sObject> Start(Database.BatchableContext objBatch) {
		return list_NewRecords;
	}
	public void execute(Database.BatchableContext objBatch, List<sObject> list_NewRecords) {
		try {
			insert list_NewRecords;
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('FWBatchCreateNewRecords', 'execute', objEx.getMessage(), objEx.getStackTraceString());
		}
	}
	public void finish(Database.BatchableContext objBatch) {
	}
}