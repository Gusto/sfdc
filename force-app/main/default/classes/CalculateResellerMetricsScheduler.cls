/**
 * @description  Scheduler class for calculating reseller metrics
 * @author       Praveen Sethu
 * @date         01-28-2023
 * @see          CalculateResellerMetricsBatchTest
 **/

public with sharing class CalculateResellerMetricsScheduler implements Schedulable {
	public void execute(SchedulableContext sc) {
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatchSize = config.Calculate_Reseller_Metrics_Batch__c.intValue() != null &&
			config.Calculate_Reseller_Metrics_Batch__c.intValue() != 0
			? config.Calculate_Reseller_Metrics_Batch__c.intValue()
			: 1;

		Database.executeBatch(new CalculateResellerMetricsBatch(), intBatchSize);
	}
}