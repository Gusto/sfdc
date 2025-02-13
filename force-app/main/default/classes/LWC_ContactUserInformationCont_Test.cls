/**
 * @name         : LWC_ContactUserInformationCont_Test
 * @author       : Dhir Kumar
 * @date         : 10-07-2020
 * @description  : This class has test methods for LWC_ContactUserInformationController
 **/
@isTest
public class LWC_ContactUserInformationCont_Test {
	/**
	 * @Author      : Ankit CS
	 * @Description : This method creates all the test data.
	 **/
	@testSetup
	static void setupData() {

         // insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		//Account creation
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('TestAccount')
			.setZPCompanyId('12312321')
			.setZPFirmId('12312321')
			.setConciergeGroupId('test')
			.setConciergeGroup('test')
			.setTier(objTierConfig.New_Tier_2__c)
			.setAMTier('Gold')
			.setRecordTypeId('Company')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert objAccount;

		//Contact creation
		Contact objContact = new TestDataFactory.ContactBuilder().setAccountId(objAccount.Id).setLastName('TestContact').setRecordTypeId('Company').setZPUserId('12312321').build();
		ContactTriggerHelper.skipTrigger = true;
		insert objContact;

		//Case creation
		Case objCase = new TestDataFactory.CaseBuilder()
			.setSubject('Om Test')
			.setStatus('New')
			.setOrigin('Email')
			.setSuppliedEmail('test@gmail.com')
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.build();
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;

		//ZP User creation
		ZP_User__c objZPUser = new TestDataFactory.ZPUserBuilder().setEmail('test@gmail.com').setCreatedAt(System.now()).setUpdatedAt(System.now()).build();
		insert objZPUser;

		//ZP UserRole creation
		List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('12312321')
			.setCompanyId('12312321')
			.setAccFirmId('12312321')
			.setType('Role::PayrollAdmin')
			.setFirstName('Test')
			.setLastName('Test')
			.setIsPrimary(true)
			.setIsBillingAdmin(true)
			.setUserPermission('teste, test')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('12312321')
			.setCompanyId('12312321')
			.setAccFirmId('12312321')
			.setType('Role::Contractor')
			.setFirstName('Test')
			.setLastName('Test')
			.setIsPrimary(true)
			.setIsBillingAdmin(true)
			.setUserPermission('teste, test')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('12312321')
			.setCompanyId('12312321')
			.setAccFirmId('12312321')
			.setType('Role::Signatory')
			.setFirstName('Test')
			.setLastName('Test')
			.setIsPrimary(true)
			.setIsBillingAdmin(true)
			.setUserPermission('teste, test')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('12312321')
			.setCompanyId('12312321')
			.setAccFirmId('12312321')
			.setType('Role::Accountant')
			.setFirstName('Test')
			.setLastName('Test')
			.setIsPrimary(true)
			.setIsBillingAdmin(true)
			.setUserPermission('teste, test')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setUserId('12312321')
			.setCompanyId('12312321')
			.setAccFirmId('12312321')
			.setType('Role::Employee')
			.setFirstName('Test')
			.setLastName('Test')
			.setIsPrimary(true)
			.setIsBillingAdmin(true)
			.setUserPermission('teste, test')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		insert list_ZPUserRoles;

		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript(CaseId = objCase.Id, LiveChatVisitorId = objLiveChatVisitor.Id);
		insert objLiveChatTranscript;
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the queryCase method.
	 **/
	static testMethod void testQueryCase() {
		Test.startTest();

		Case objCase = [SELECT Id FROM Case LIMIT 1];
		Map<String, SObject> map_Response = LWC_ContactUserInformationController.queryCase(objCase.Id);
		System.assert(map_Response.get('CaseRec') != null);

		LiveChatTranscript objLiveChatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
		Map<String, SObject> map_ResponseLiveChatTranscript = LWC_ContactUserInformationController.queryCase(objLiveChatTranscript.Id);
		System.assert(map_ResponseLiveChatTranscript.get('CaseRec') != null);

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the getUserInformation method.
	 **/
	static testMethod void testGetUserInformation() {
		Test.startTest();

		Case objCase = [SELECT Id FROM Case LIMIT 1];
		LWC_ContactUserInformationController.UserRoleInformation objWrapper = LWC_ContactUserInformationController.getUserInformation(objCase.Id);
		System.assertEquals(objWrapper.list_CompanyInfo[0].strCompanyName, 'TestAccount');

		LiveChatTranscript objLiveChatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
		LWC_ContactUserInformationController.UserRoleInformation objWrapperLiveChatTranscript = LWC_ContactUserInformationController.getUserInformation(objLiveChatTranscript.Id);
		System.assertEquals(objWrapperLiveChatTranscript.list_CompanyInfo[0].strCompanyName, 'TestAccount');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the updateAccount method.
	 **/
	static testMethod void testUpdateAccount() {
		Test.startTest();

		Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		LWC_ContactUserInformationController.updateAccount(true, objCase.Id, objAccount.Id);
		Case objUpdatedCase = [SELECT Id, AccountId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objUpdatedCase.AccountId, objAccount.Id);

		LiveChatTranscript objLiveChatTranscript = [SELECT Id, CaseId FROM LiveChatTranscript LIMIT 1];
		LWC_ContactUserInformationController.updateAccount(true, objLiveChatTranscript.Id, objAccount.Id);
		objUpdatedCase = [SELECT Id, AccountId FROM Case WHERE Id = :objLiveChatTranscript.CaseId];
		System.assertEquals(objUpdatedCase.AccountId, objAccount.Id);

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the updateContactOnSave method.
	 **/
	static testMethod void testUpdateContactOnSave() {
		Test.startTest();

		Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		objCase.ContactId = null;
		CaseTriggerHelper.skipTrigger = true;
		update objCase;

		LWC_ContactUserInformationController.updateContactOnSave(objCase.Id, objContact.Id);
		Case objUpdatedCase = [SELECT Id, ContactId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objUpdatedCase.ContactId, objContact.Id);

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the updateContactOnSave method.
	 **/
	static testMethod void testUpdateContactOnSaveLiveChatTranscript() {
		Test.startTest();

		Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		objCase.ContactId = null;
		CaseTriggerHelper.skipTrigger = true;
		update objCase;

		LiveChatTranscript objLiveChatTranscript = [SELECT Id, CaseId FROM LiveChatTranscript LIMIT 1];
		LWC_ContactUserInformationController.updateContactOnSave(objLiveChatTranscript.Id, objContact.Id);
		Case objUpdatedCase = [SELECT Id, ContactId FROM Case WHERE Id = :objLiveChatTranscript.CaseId];
		System.assertEquals(objUpdatedCase.ContactId, objContact.Id);

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the getAccountantMap method.
	 **/
	static testMethod void testGetAccountantMap() {
		Test.startTest();
		Map<String, Account> map_Response = LWC_ContactUserInformationController.getAccountantMap(new Set<String>{ '12312321' });
		System.assertEquals(map_Response.get('12312321').ZP_Firm_ID__c, '12312321');
		Test.stopTest();
	}
}