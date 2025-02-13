@isTest
public class ViewAccountByCompanyControllerTest {
	@isTest
	static void testViewCompany() {
		ZPCompanyTriggerHelper.queue = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test').setZPCompanyId('11111111111111').build();

		insert objAccount;

		ApexPages.currentPage().getParameters().put('CompanyId', '11111111111111');
		ViewAccountByCompanyController objController = new ViewAccountByCompanyController();
		objController.viewAccount();
		objController.getAccount();
	}

	@isTest
	static void testViewFirm() {
		ZPCompanyTriggerHelper.queue = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Test').setZPFirmId('11111111111111').build();

		insert objAccount;

		ApexPages.currentPage().getParameters().put('FirmId', '11111111111111');
		ViewAccountByCompanyController objController = new ViewAccountByCompanyController();
		objController.viewAccount();
		objController.getAccount();
	}
}