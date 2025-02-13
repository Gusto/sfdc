public without sharing class CreateCompanyMigrationCaseController {
	private final ZP_Company_Migration__c companyMigration;

	public CreateCompanyMigrationCaseController() {
		companyMigration = [SELECT Id, Name, External_Key__c, Id__c FROM ZP_Company_Migration__c WHERE External_Key__c = :ApexPages.currentPage().getParameters().get('MigrationId')];
	}

	public PageReference createCase() {
		ZPCompanyMigrationTriggerHelper.blnManualInitiation = true;

		List<Case> caseList = [SELECT Id FROM case WHERE Integration_Key__c = :companyMigration.External_Key__c];
		if (caseList.size() > 0) {
			ApexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Case already exists'));
			return null;
		}

		update companyMigration;

		caseList = [SELECT Id FROM case WHERE Integration_Key__c = :companyMigration.External_Key__c];
		if (caseList.size() > 0) {
			ApexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Case is successfully created'));
			return null;
		}

		return null;
	}

	public PageReference cancelAction() {
		Order ord = [SELECT Id FROM Order WHERE External_Key__c = :companyMigration.External_Key__c];

		PageReference pgref = new PageReference('/' + ord.Id);
		pgref.setRedirect(true);
		return pgref;
	}
}