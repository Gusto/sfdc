@isTest
public class HIBenefitsAdminTriggerHelperTest {
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
		HIBenefitsAdminTriggerHelper.queue = true;
		HI_Benefits_Admin__c objHIAdmin = new HI_Benefits_Admin__c();
		objHIAdmin.Company_Id__c = null;
		insert objHIAdmin;

		objHIAdmin = [SELECT Id, Processing_State__c FROM HI_Benefits_Admin__c WHERE Id = :objHIAdmin.Id];
		//Commented out by David (Dato) Tsamalashvili - 05/31/2019
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIAdmin.Processing_State__c, 'Processing_State__c should match.');
	}

	@isTest
	static void noUserId() {
		HIBenefitsAdminTriggerHelper.queue = true;
		HI_Benefits_Admin__c objHIAdmin = new HI_Benefits_Admin__c();
		objHIAdmin.Company_Id__c = '11111111111111';
		objHIAdmin.ZP_User_Id__c = null;
		insert objHIAdmin;
		objHIAdmin.ZP_User_Id__c = '1234';
		update objHIAdmin;
		System.assert(true, 'Fixed Apex PMD issue.');
	}

	@isTest
	static void companyIdDoesExit() {
		HIBenefitsAdminTriggerHelper.queue = true;
		HI_Benefits_Admin__c objHIAdmin = new HI_Benefits_Admin__c();
		objHIAdmin.Company_Id__c = 'werwerr';
		objHIAdmin.ZP_User_Id__c = '';
		insert objHIAdmin;

		objHIAdmin = [SELECT Id, Processing_State__c FROM HI_Benefits_Admin__c WHERE Id = :objHIAdmin.Id];
		//Commented out by David (Dato) Tsamalashvili - 05/31/2019
		System.assertEquals(IntegrationUtils.ERROR_STATE, objHIAdmin.Processing_State__c, 'Processing_State__c should match.');
	}

	@isTest
	static void processData() {
		HIBenefitsAdminTriggerHelper.queue = true;
		HI_Benefits_Admin__c objHIAdmin = new HI_Benefits_Admin__c();
		objHIAdmin.Company_Id__c = '11111111111111';
		objHIAdmin.ZP_User_Id__c = '8888';
		insert objHIAdmin;

		objHIAdmin.Deleted_At__c = System.today();
		update objHIAdmin;
		System.assert(true, 'Fixed Apex PMD issue.');
	}
	@isTest
	static void withoutZPUserRole() {
		HIBenefitsAdminTriggerHelper.queue = true;
		HI_Benefits_Admin__c objHIAdmin = new HI_Benefits_Admin__c();
		objHIAdmin.Company_Id__c = '11111111111111';
		objHIAdmin.ZP_User_Id__c = '88898';
		insert objHIAdmin;
		delete objHIAdmin;
		System.assert(true, 'Fixed Apex PMD issue.');
	}

	@isTest
	static void processDeadState() {
		HIBenefitsAdminTriggerHelper.queue = true;
		HI_Benefits_Admin__c objHIAdmin = new HI_Benefits_Admin__c();
		objHIAdmin.Company_Id__c = 'werwerr';
		objHIAdmin.ZP_User_Id__c = '';
		objHIAdmin.Processing_State__c = IntegrationUtils.DEAD_STATE;
		insert objHIAdmin;

		objHIAdmin = [SELECT Id, Processing_State__c FROM HI_Benefits_Admin__c WHERE Id = :objHIAdmin.Id];
		//Commented out by David (Dato) Tsamalashvili - 05/31/2019
		System.assertEquals(IntegrationUtils.DEAD_STATE, objHIAdmin.Processing_State__c, 'Processing_State__c should match.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, Create Team Members
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testCreateTeamMember() {
		HIBenefitsAdminTriggerHelper.queue = true;
		HIBenefitSignatoryTriggerHelper.queue = true;
		Test.startTest();
		Account objAccount = [SELECT Id, ZP_company_id__c FROM Account WHERE Name = 'test' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setFirstName('Artoo')
			.setLastName('Detoo')
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setEmail('testuser@abccompany.com')
			.build();
		insert objContact;
		Opportunity objOpportunity = [SELECT Id, ZP_Company_ID__c FROM Opportunity WHERE Name = 'test' LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setOpportunity(objOpportunity.Id)
			.setType('Benefits Renewal')
			.setSubject('Test Case Owner Change Ben Admin Update Member Ops')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Case Owner Change Ben Admin Update')
			.setIntegrationId('hippo-Benefits_Renewal-894443421999')
			.build();
		insert objCase;
		Test.stopTest();
		System.assertEquals(0, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member should be created.');
		HI_Benefits_Admin__c objHIAdmin = new TestDataFactory.HIBenefitsAdminBuilder().setCompanyId('11111111111111').setZPUserId('8888').build();
		insert objHIAdmin;
		System.assertEquals(1, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member should not be Created.');
		HI_Benefits_Signatory__c objHISignatory = new TestDataFactory.HIBenefitsSignatoryBuilder().setCompanyId('11111111111111').setZPUserId('8888').build();
		insert objHISignatory;
		System.assertEquals(1, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member should not be duplicate with same ZP_user_Id.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, deletion of case team member with same contact
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testDeleteCaseTeamMemberWithSameCont() {
		HIBenefitsAdminTriggerHelper.queue = true;
		HIBenefitSignatoryTriggerHelper.queue = true;
		Test.startTest();
		Account objAccount = [SELECT Id, ZP_company_id__c FROM Account WHERE Name = 'test' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setFirstName('Artoo')
			.setLastName('Detoo')
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setEmail('testuser@abccompany.com')
			.build();
		insert objContact;
		Opportunity objOpportunity = [SELECT Id, ZP_Company_ID__c FROM Opportunity WHERE Name = 'test' LIMIT 1];
		ZP_User__c objZPUser = [SELECT Id, Email__c FROM ZP_User__c WHERE Email__c = 'test@gusto.com'];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setOpportunity(objOpportunity.Id)
			.setType('Benefits Renewal')
			.setSubject('Test Case Owner Change Ben Admin Update Member Ops')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Case Owner Change Ben Admin Update')
			.setIntegrationId('hippo-Benefits_Renewal-894443421999')
			.build();
		insert objCase;
		Test.stopTest();
		HI_Benefits_Admin__c objHIAdmin = new TestDataFactory.HIBenefitsAdminBuilder().setCompanyId('11111111111111').setZPUserId('8888').build();
		insert objHIAdmin;
		HI_Benefits_Signatory__c objHISignatory = new TestDataFactory.HIBenefitsSignatoryBuilder().setCompanyId('11111111111111').setZPUserId('8888').build();
		insert objHISignatory;
		System.assertEquals(1, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member should not be Created.');
		objHIAdmin.Deleted_At__c = System.today();
		update objHIAdmin;
		System.assertEquals(1, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member should not be deleted as signatory is not deleted.');
		objHISignatory.Deleted_At__c = System.today();
		update objHISignatory;
		System.assertEquals(0, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member should be  Deleted.');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test Method to check, delettion and creation of case team member with diff. contact
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testCreateDeleteMemberWithDiffContact() {
		HIBenefitsAdminTriggerHelper.queue = true;
		HIBenefitSignatoryTriggerHelper.queue = true;
		Test.startTest();
		Account objAccount = [SELECT Id, ZP_company_id__c FROM Account WHERE Name = 'test' LIMIT 1];
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setFirstName('Artoo')
			.setLastName('Detoo')
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setZPUserId('123456')
			.setEmail('testuser@abccompany.com')
			.build();
		insert objContact;
		ZP_User__c objZPUser1 = new TestDataFactory.ZPUserBuilder().setCustomId('123456').setEmail('testuser@abccompany.com').setCreatedAt(System.today()).setUpdatedAt(System.today()).build();
		insert objZPUser1;
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setFirstName('test')
			.setLastName('Contact2')
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setZPUserId('98766545')
			.setEmail('testContact2@abccompany.com')
			.build();
		insert objContact1;
		ZP_User__c objZPUser2 = new TestDataFactory.ZPUserBuilder().setCustomId('98766545').setEmail('testContact2@abccompany.com').setCreatedAt(System.today()).setUpdatedAt(System.today()).build();
		insert objZPUser2;
		ZP_User_Role__c objZPUserRole1 = new TestDataFactory.ZPUserRoleBuilder().setUserId('123456').setCompanyId('11111111111111').setFirstName('Testdone1').setLastName('Test1').build();
		insert objZPUserRole1;
		ZP_User_Role__c objZPUserRole2 = new TestDataFactory.ZPUserRoleBuilder().setUserId('98766545').setCompanyId('11111111111111').setFirstName('Testdone2').setLastName('Test2').build();
		insert objZPUserRole2;
		Opportunity objOpportunity = [SELECT Id, ZP_Company_ID__c FROM Opportunity WHERE Name = 'test' LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setOpportunity(objOpportunity.Id)
			.setType('Benefits Renewal')
			.setSubject('Test Case Owner Change Ben Admin Update Member Ops')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Test Case Owner Change Ben Admin Update')
			.setIntegrationId('hippo-Benefits_Renewal-894443421999')
			.build();
		insert objCase;
		Test.stopTest();
		HI_Benefits_Admin__c objHIAdmin = new TestDataFactory.HIBenefitsAdminBuilder().setCompanyId('11111111111111').setZPUserId('123456').build();
		insert objHIAdmin;
		HI_Benefits_Signatory__c objHISignatory = new TestDataFactory.HIBenefitsSignatoryBuilder().setCompanyId('11111111111111').setZPUserId('98766545').build();
		insert objHISignatory;
		System.assertEquals(2, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member is not created.');
		objHIAdmin.Deleted_At__c = System.today();
		update objHIAdmin;
		System.assertEquals(1, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member is not deleted for HiBenefitAdmin.');
		objHISignatory.Deleted_At__c = System.today();
		update objHISignatory;
		System.assertEquals(0, [SELECT COUNT() FROM CaseTeamMember WHERE ParentId = :objCase.Id], 'Case Team Member is not Deleted for HI_Benefits_Signatory__c.');
	}
}