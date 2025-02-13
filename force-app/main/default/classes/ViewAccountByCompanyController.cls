public class ViewAccountByCompanyController {
	private final Account objAccount;

	public ViewAccountByCompanyController() {
		if (ApexPages.currentPage().getParameters().get('CompanyId') != null) {
			objAccount = [SELECT Id, Name FROM Account WHERE ZP_Company_Id__c = :ApexPages.currentPage().getParameters().get('CompanyId')];
		}
		if (ApexPages.currentPage().getParameters().get('FirmId') != null) {
			objAccount = [SELECT Id, Name FROM Account WHERE ZP_Firm_Id__c = :ApexPages.currentPage().getParameters().get('FirmId')];
		}
	}

	public Account getAccount() {
		return objAccount;
	}

	public PageReference viewAccount() {
		PageReference pgref = new PageReference('/' + objAccount.Id);
		pgref.setRedirect(true);
		return pgref;
	}
}