/**
 * @name         : InsuranceQuoteEmailBatchScheduler
 * @author       : David (Dato) Tsamalashvili
 * @date         : 10-13-2021
 * @description  : Scheduler class for InsuranceQuoteEmailBatch
 * @test classes : InsuranceQuoteEmailBatchTest
 **/
public with sharing class InsuranceQuoteEmailBatchScheduler implements Schedulable {
	public void execute(SchedulableContext sc) {
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatchSize = config.IQ_Email_Bath_Size__c.intValue() != null &&
			config.IQ_Email_Bath_Size__c.intValue() != 0
			? config.IQ_Email_Bath_Size__c.intValue()
			: 2;

		Database.executeBatch(new InsuranceQuoteEmailBatch(), intBatchSize);
	}
}