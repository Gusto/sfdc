@istest
public class ZPCompanyUpdateServiceTest {
	@isTest
	static void testCompanyReprocess() {
		User objCurrentUser = [
			SELECT Id, Exempt_from_Validation_Rules__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];
		objCurrentUser.Exempt_From_Validation_Rules__c = true;
		update objCurrentUser;
		ZP_Company__c objZpCompany;

		System.runAs(objCurrentUser) {
			ZPCompanyTriggerHelper.queue = false;

			objZpCompany = new TestDataFactory.ZPCompanyBuilder()
				.setZPCompanyId('11111111111111')
				.setCompanyLeadId('222222222222')
				.setProcessingState('Error')
				.setCreatedAtDate(System.today())
				.setCreatedByEmail('test@gusto.com')
				.build();

			insert objZpCompany;
		}
		Lead objLead = new Lead();
		objLead.FirstName = 'TestName';
		objLead.lastName = 'Test';
		objLead.Email = 'test@gusto.com';
		objLead.Company = 'test';
		insert objLead;

		System.runAs(objCurrentUser) {
			objLead = [SELECT id, isConverted, Email FROM Lead WHERE Id = :objLead.Id];
			System.assertEquals(objLead.isConverted, false, 'Lead should not be converted.');
			ZPCompanyUpdateService.updateInfo upInfo = new ZPCompanyUpdateService.updateInfo();
			upInfo.zpCompanyId = '' + objZpCompany.Id;
			ZPCompanyUpdateService.doPost(upInfo);
		}
	}
}