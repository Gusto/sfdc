global class OnboardingHIOppCreationBatch implements Database.Batchable<sObject> {
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String strQuery =
			'SELECT Id, Account__c,Created_At__c, Account__r.Name, Account__r.Has_HI_Opportunities__c, Account__r.BillingAddress, Account__r.BillingState,' +
			'Account__r.NumberOfEmployees_Lead__c,Account__r.HI_Owner__c,' +
			'Onboarding_Survey_Offer_Benefits__c, Onboarding_HI_Opp_Created__c, Process_HI_Opp_Creation__c, Skip_Onboarding_Opp_Creation__c, Company_Lead_Number_of_Employees__c,' +
			'Number_of_Active_Employees__c, Onboarding_Survey_Interested_Benefit_Opt__c, Id__c, Want_to_switch_brokers__c, Initiated_by_Accountant__c, Currently_Offer_Health_Benefits__c, Open_to_Switching_Broker__c, ' +
			' Which_Gusto_benefits_interested_in__c, When_to_start_offering_benefits__c, Who_to_contact__c, Existing_Health_Benefits_Renewal_Date__c, Contribution_to_EE_Health_Coverage_cost__c, Interested_in_offering_HI_to_employees__c, Interest_in_adding_benefits_to_Gusto__c ' + 
			' FROM ZP_Company__c WHERE Onboarding_HI_Opp_Created__c = false' +
			' AND Process_HI_Opp_Creation__c = true AND Skip_Onboarding_Opp_Creation__c = false' +
			' AND CreatedDate >= 2020-08-01T00:00:01z AND CreatedDate < TODAY';
		return Database.getQueryLocator(strQuery);
	}

	global void execute(Database.BatchableContext bc, List<ZP_Company__c> scope) {
		Set<String> set_CompanyIds = new Set<String>();
		List<ZP_Company__c> list_ZPCompany = (List<ZP_Company__c>) scope;

		for (ZP_Company__c objZP : list_ZPCompany) {
			set_CompanyIds.add(objZP.Id__c);
		}

		OnboardingHIOppCreationService.doCreateOpportunity(list_ZPCompany, set_CompanyIds);
	}

	global void finish(Database.BatchableContext bc) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'OnboardingHIOppCreationBatch', false);
	}
}