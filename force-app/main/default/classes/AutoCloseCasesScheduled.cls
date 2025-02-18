global class AutoCloseCasesScheduled implements Schedulable {
    global void execute(SchedulableContext sc) {
        AutoCloseCasesBatch batchJob = new AutoCloseCasesBatch();
        Database.executeBatch(batchJob);
    }
}