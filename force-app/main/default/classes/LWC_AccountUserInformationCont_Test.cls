/**
 * @name         : LWC_AccountUserInformationCont_Test
 * @author       : Dhir Kumar
 * @date         : 10-08-2020
 * @description  : This class has test methods for LWC_AccountUserInformationController
 **/
@isTest
public class LWC_AccountUserInformationCont_Test {
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
			.setName('TestAcc')
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
		Contact objContact = new TestDataFactory.ContactBuilder().setAccountId(objAccount.Id).setLastName('TestContact').setZPUserId('12312321').setRecordTypeId('Company').build();
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
			.setUserPermission('teste, test')
			.build();
		list_ZPUserRoles.add(objZPUserRole);

		insert list_ZPUserRoles;
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the updateContactOnSave method.
	 **/
	static testMethod void testUpdateContactOnSave() {
		Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		objCase.AccountId = null;
		CaseTriggerHelper.skipTrigger = true;
		update objCase;
		Test.startTest();
		LWC_AccountUserInformationController.updateContactOnSave(objCase.Id, objAccount.Id);
		Test.stopTest();
		Case objUpdatedCase = [SELECT Id, AccountId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objUpdatedCase.AccountId, objAccount.Id);
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the queryCase method.
	 **/
	static testMethod void testQueryCase() {
		Case objCase = [SELECT Id FROM Case LIMIT 1];
		Test.startTest();
		Map<String, SObject> map_Response = LWC_AccountUserInformationController.queryCase(objCase.Id);
		Test.stopTest();
		System.assert(map_Response.get('CaseRec') != null);
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the getUserInformation method.
	 **/
	static testMethod void testGetUserInformation() {
		Case objCase = [SELECT Id FROM Case LIMIT 1];
		Test.startTest();
		LWC_AccountUserInformationController.UserRoleInformation objWrapper = LWC_AccountUserInformationController.getUserInformation(objCase.Id);
		System.assertEquals(objWrapper.list_CompanyInfo[0].strCompanyName, 'TestContact');
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : To test the getAccountantMap method.
	 **/
	static testMethod void testGetAccountantMap() {
		Test.startTest();
		Map<String, Contact> map_Response = LWC_AccountUserInformationController.getAccountantMap(new Set<String>{ '12312321' });
		System.assertEquals(map_Response.get('12312321').Name, 'TestContact');
		Test.stopTest();
	}
}