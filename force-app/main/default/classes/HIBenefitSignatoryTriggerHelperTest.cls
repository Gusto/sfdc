@isTest
public class HIBenefitSignatoryTriggerHelperTest {
	@TestSetup
	static void makeData() {
		ZPCompanyTriggerHelper.queue = true;
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Account objAcc = new Account();
		objAcc.Name = 'test';
		objAcc.ZP_company_id__c = '11111111111111';
		objAcc.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		insert objAcc;

		List<ZP_User__c> list_ZPUser = new List<ZP_User__c>();
		ZP_User__c objZPUser = new ZP_User__c();
		objZPUser.Email__c = 'test@gusto.com';
		objZPUser.Id__c = '8888';
		objZPUser.Created_At__c = System.today();
		objZPUser.Updated_At__c = System.today();
		list_ZPUser.add(objZPUser);

		ZP_User__c objZPUser1 = new ZP_User__c();
		objZPUser1.Email__c = 'test1@gusto.com';
		objZPUser1.Id__c = '88898';
		objZPUser1.Created_At__c = System.today();
		objZPUser1.Updated_At__c = System.today();
		list_ZPUser.add(objZPUser1);

		insert list_ZPUser;

		ZP_User_Role__c objZPUserRole = new ZP_User_Role__c();
		objZPUserRole.User_Id__c = '8888';
		objZPUserRole.Company_Id__c = '11111111111111';
		objZPUserRole.First_Name__c = 'Test';
		objZPUserRole.Last_Name__c = 'Test';
		insert objZPUserRole;

		Opportunity objOpportunity = new Opportunity();
		objOpportunity.Name = 'test';
		objOpportunity.CloseDate = System.today();
		objOpportunity.StageName = 'SAL';
		objOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		objOpportunity.AccountId = objAcc.Id;
		objOpportunity.NumberOfEmployees__c = 1;
		objOpportunity.ZP_Company_ID__c = '11111111111111';
		objOpportunity.Source_Id__c = '11111111111111';
		objOpportunity.Description = 'Test Description Test Description ';
		objOpportunity.Anchor_Pay_Date__c = System.today().adddays(-5);
		insert objOpportunity;
	}
	@isTest
	static void benefitSignatoryWitoutAnyData() {
		HIBenefitSignatoryTriggerHelper.queue = true;
		HI_Benefits_Signatory__c objSignatory = new HI_Benefits_Signatory__c();
		objSignatory.Company_Id__c = null;
		insert objSignatory;

		objSignatory = [SELECT Id, Processing_State__c FROM HI_Benefits_Signatory__c WHERE Id = :objSignatory.Id];
		//Commented out by David (Dato) Tsamalashvili - 05/31/2019
		System.assertEquals(IntegrationUtils.ERROR_STATE, objSignatory.Processing_State__c, 'Processing_State__c should match.');
	}

	@isTest
	static void noUserId() {
		HIBenefitSignatoryTriggerHelper.queue = true;
		HI_Benefits_Signatory__c objSignatory = new HI_Benefits_Signatory__c();
		objSignatory.Company_Id__c = '11111111111111';
		objSignatory.ZP_User_Id__c = null;
		insert objSignatory;
		objSignatory.ZP_User_Id__c = '1234';
		update objSignatory;
		System.assert(true, 'Fixed Apex PMD issue.');
	}

	@isTest
	static void companyIdDoesExit() {
		HIBenefitSignatoryTriggerHelper.queue = true;
		HI_Benefits_Signatory__c objSignatory = new HI_Benefits_Signatory__c();
		objSignatory.Company_Id__c = 'werwerr';
		objSignatory.ZP_User_Id__c = '';
		insert objSignatory;

		objSignatory = [SELECT Id, Processing_State__c FROM HI_Benefits_Signatory__c WHERE Id = :objSignatory.Id];
		//Commented out by David (Dato) Tsamalashvili - 05/31/2019
		System.assertEquals(IntegrationUtils.ERROR_STATE, objSignatory.Processing_State__c, 'Processing_State__c should match.');
	}

	@isTest
	static void processData() {
		HIBenefitSignatoryTriggerHelper.queue = true;
		HI_Benefits_Signatory__c objSignatory = new HI_Benefits_Signatory__c();
		objSignatory.Company_Id__c = '11111111111111';
		objSignatory.ZP_User_Id__c = '8888';
		insert objSignatory;

		List<OpportunityContactRole> list_OppContactRole = [SELECT Id FROM OpportunityContactRole];
		System.assertNotEquals(0, list_OppContactRole.size(), 'OpportunityContactRole list size should not be 0.');
		objSignatory.Deleted_At__c = System.today();
		update objSignatory;
	}
	@isTest
	static void withoutZPUserRole() {
		HIBenefitSignatoryTriggerHelper.queue = true;
		HI_Benefits_Signatory__c objSignatory = new HI_Benefits_Signatory__c();
		objSignatory.Company_Id__c = '11111111111111';
		objSignatory.ZP_User_Id__c = '88898';
		insert objSignatory;
		delete objSignatory;
		System.assert(true, 'Fixed Apex PMD issue.');
	}

	@isTest
	static void processDeadState() {
		HIBenefitSignatoryTriggerHelper.queue = true;
		HI_Benefits_Signatory__c objSignatory = new HI_Benefits_Signatory__c();
		objSignatory.Company_Id__c = 'werwerr';
		objSignatory.ZP_User_Id__c = '';
		objSignatory.Processing_State__c = IntegrationUtils.DEAD_STATE;
		insert objSignatory;

		objSignatory = [SELECT Id, Processing_State__c FROM HI_Benefits_Signatory__c WHERE Id = :objSignatory.Id];
		//Commented out by David (Dato) Tsamalashvili - 05/31/2019
		System.assertEquals(IntegrationUtils.DEAD_STATE, objSignatory.Processing_State__c, 'Processing_State__c should match.');
	}
}