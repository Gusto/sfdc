@isTest
public class IkbSearchControllerTest {
	@testSetup
	static void setupMethod() {
		User objcurrentUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()][0];
		//create user
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('Admin')
			.setExemptfromValidationRules(true)
			.setUserName('admin@testorg.com.test')
			.setEmail('admin@testorg.com')
			.setUserRoleId([SELECT id FROM UserRole WHERE developerName = 'sales_partner_xx_xx_mgr'][0].Id)
			.setFirstName('Test')
			.setLastName('User')
			.setUserPermissionsKnowledgeUser(true)
			.setProfileId(TestDataFactory.objZPSysAdminProfile.Id)
			.build();
		System.runAs(objcurrentUser) {
			insert objAdminUser;
		}
		System.runAs(objAdminUser) {
			Help__kav help = new Help__kav();
			help.Article_Id__c = '12345';
			help.External_Id__c = 'Internal-12345';
			help.Title = 'Test';
			help.Description__c = 'Test';
			help.UrlName = 'Test';
			insert help;
		}

	}

	@isTest
	static void testIKBSearchController() {
		Test.startTest();
		IkbSearchController ikb = new IkbSearchController();
		ikb.getArticleList();
		ApexPages.currentPage().getParameters().put('articleId', '12345');
		ikb.viewArticle();
		//System.assertEquals('Test', ikb.articleTitle, 'Article Title should be Test.');
		Test.stopTest();
	}
}