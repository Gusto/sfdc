/**
 * Represents a scheduler class for creating and executing a batch job.
 */
public class CreateICPBatchScheduler implements Schedulable {
	// The batch job to execute
	Database.Batchable<SObject> batchable;
	// The size of the batch
	Integer batchSize;

	// Constructor
	public CreateICPBatchScheduler(Database.Batchable<SObject> batchable, Integer batchSize) {
		// Set the batch job and batch size
		this.batchable = batchable;
		// Set the batch size
		this.batchSize = batchSize;
	}

	// Execute the batch job
	public void execute(SchedulableContext sc) {
		// Execute the batch job
		Database.executeBatch(batchable, batchSize);
	}
}