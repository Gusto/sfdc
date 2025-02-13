/**
 * @name         BatchDML
 * @author       Sanjay Paryani
 * @date         05/28/2020
 * @description  Used to perform DML - insert, update, delete in bulk using Queueable mechanism
 * @revisions    Date ------------ Name ------------ Comments
 **/

global class BatchDML implements Queueable {
	global enum Operation {
		INS,
		UPD,
		DEL
	}
	global Integer BatchSize;

	// To get the batch dml size for which we want to process records.
	Configuration_Settings__c configRec = Configuration_Settings__c.getOrgDefaults();

	private Operation operation;
	private List<SObject> recordList;
	private BatchDML followupJob;
	private Boolean blnSkipConfig;

	global BatchDML(Operation operation, List<SObject> recordList, Boolean blnSkipConfigTemp) {
		this.operation = operation;
		this.recordList = recordList;
		this.blnSkipConfig = blnSkipConfigTemp;
	}

	// Process the records
	global void execute(QueueableContext context) {
		if (recordList == null || recordList.isEmpty()) {
			return;
		}

		if (configRec != null && configRec.Batch_DML_Size__c != null && !blnSkipConfig) {
			BatchSize = Integer.valueOf(configRec.Batch_DML_Size__c);
		} else {
			BatchSize = 10000;
		}

		BatchDML.skipTrigger(true);
		Integer size = this.recordList.size();
		Schema.SObjectType sObjectType = recordList.getSObjectType();

		List<SObject> activeBatch = (List<SObject>) Type.forName('List<' + sObjectType + '>').newInstance();

		if (size > BatchSize) {
			// take the last <BatchSize> records from the top and put the rest in the next queueable
			for (Integer i = size - 1; i >= size - BatchSize; i--) {
				activeBatch.add(this.recordList.remove(i));
			}
			followupJob = new BatchDML(this.operation, this.recordList, this.blnSkipConfig);
		} else {
			activeBatch = this.recordList;
		}

		switch on this.operation {
			when INS {
				insert activeBatch;
			}
			when UPD {
				update activeBatch;
			}
			when DEL {
				delete activeBatch;
			}
		}
		BatchDML.skipTrigger(false);
		if (followupJob != null) {
			if (!Test.isRunningTest()) {
				System.enqueueJob(followupJob);
			}
		}
	}

	public static void skipTrigger(Boolean bnlFlag) {
		AccountTriggerHelper.skipTrigger = bnlFlag;
		UR_ResearchProjectDetailTriggerHelper.skipTrigger = bnlFlag;
	}
}