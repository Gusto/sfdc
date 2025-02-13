/**
 * @Author       :   David (Dato) Tsamalashvili
 * @ModifiedDate :   01/27/2022
 * @Desc         :   Batch job to process ZP Company Suspension records
 * @TestClass    :   ZPCompanySuspensionBatchTest
 **/
public with sharing class ZPCompanySuspensionBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string strQuery = 'SELECT Id FROM ZP_Company_Suspension__c WHERE Processing_State__c = \'Error\' OR Processing_State__c = \'Queued\'';

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> list_Scope) {
		List<ZP_Company_Suspension__c> list_Suspensions = (List<ZP_Company_Suspension__c>) list_Scope;
		ZPCompanySuspensionTriggerHelper.queue = true;
		update list_Suspensions;
	}

	public void finish(Database.BatchableContext BC) {
		Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();

		Integer intOnbFunnelBatchSize = objConfig?.Onboarding_Funnel_Batch_Size__c?.intValue() != null &&
			objConfig?.Onboarding_Funnel_Batch_Size__c?.intValue() != 0
			? objConfig.Onboarding_Funnel_Batch_Size__c.intValue()
			: 5;

		Database.executeBatch(new ZPCompanyOnboardingBatch(), intOnbFunnelBatchSize);

		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'ZPCompanySuspensionBatch', false);
	}
}