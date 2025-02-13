/**
 * @name         : BenefitsNewPlanOppCreationBatch
 * @author       : Debasmita Rawooth
 * @date         : 11-10-2021
 * @description  : Batch Class for creating Benefits New Plan Opportunity based on Insurance Quotes.
 * @test classes : BenefitsNewPlanOppCreationBatchTest
 **/
global class BenefitsNewPlanOppCreationBatch implements Database.Batchable<sObject> {
	public BenefitsNewPlanOppCreationBatch() {
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		String strQuery =
			'SELECT Id, Account__c, Opportunity__c, Status__c, Sales_Rep__c,' +
			' Account__r.BillingState, Account__r.Number_of_Active_Employees__c, Account__r.NumberOfEmployees_Lead__c,Account__r.HI_Owner__c,' +
			' Account__r.Name, Census_State__c, Account__r.ZP_Company_ID__c' +
			' FROM Insurance_Quote__c WHERE Account__c != null AND NewPlanProcessed__c = false';
		return Database.getQueryLocator(strQuery);
	}

	global void execute(Database.BatchableContext bc, List<Insurance_Quote__c> list_InsuranceQuotes) {
		Set<String> set_AccountIds = new Set<String>();

		for (Insurance_Quote__c objInsuranceQuote : list_InsuranceQuotes) {
			set_AccountIds.add(objInsuranceQuote.Account__c);
		}
		BenefitsNewPlanOppCreationService objBenefitsNewPlanOppCreationService = new BenefitsNewPlanOppCreationService();
		objBenefitsNewPlanOppCreationService.createNewOpportunity(list_InsuranceQuotes, set_AccountIds);
	}

	global void finish(Database.BatchableContext bc) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'BenefitsNewPlanOppCreationBatch', false);
	}
}