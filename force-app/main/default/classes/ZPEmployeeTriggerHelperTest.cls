/**
 * @name		:ZPEmployeeTriggerHelperTest
 * @author
 * @date
 * @description :Unit tests for ZPEmployeeTriggerHelper, ZPEmployeeTriggerHandler, ZPEmployeeTrigger
 * @class		:ZPEmployeeTriggerHelper, ZPEmployeeTriggerHandler, ZPEmployeeTrigger
 * @revisions   :August 23, 2021 ------------ Neha ------------ Added test scenarios for processing Residence State
 **/
@isTest
public class ZPEmployeeTriggerHelperTest {
	/**
	 * @Author      : Neha Dabas
	 * @Description : Create Test Data
	 * @Parm        : null
	 * @Return      : null
	 **/
	@TestSetup
	static void makeData() {
		List<State_Name_to_abbreviations_Mapping__c> list_StateName = new List<State_Name_to_abbreviations_Mapping__c>();

		list_StateName.add(new State_Name_to_abbreviations_Mapping__c(Name = 'Missouri', State_Abbreviation__c = 'MO', State_Name__c = 'MO', HI_Active__c = true));

		insert list_StateName;

		List<HI_Opportunity_Router_State__c> list_HiStates = new List<HI_Opportunity_Router_State__c>();

		list_HiStates.add(new TestDataFactory.HIOpportunityRouterStateBuilder().setStateName('Missouri').setState('MO').setPriority('1').build());

		insert list_HiStates;

		List<Account> list_Accounts = new List<Account>();
		list_Accounts.add(
			new TestDataFactory.AccountBuilder()
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setName('Test Accountant - 1')
				.setOnboardingFlow('In-App')
				.setZPCompanyId('11119999')
				.setBillingState('Missouri')
				.setBillingCountry('United States')
				.build()
		);
		insert list_Accounts;

		List<Contact> list_Contacts = new List<Contact>();
		list_Contacts.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(list_Accounts[0].Id)
				.setFirstName('Funnybones')
				.setLastName('Testing C')
				.setEmail('funnybone1@secondcontact.com')
				.setEmployeeId('5453255')
				.build()
		);
		insert list_Contacts;
	}

	/**
	 * @Author      :
	 * @Description : Test Employee Insertion
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testAfterInsertRecords() {
		Test.startTest();
		ZPEmployeeTriggerHandler.resetSkipTriggerFlags();

		ZP_Employee__c objEmployee = new TestDataFactory.ZPEmployeeBuilder().setCompanyId('11119999').setProcessingState('Queued').build();

		insert objEmployee;

		objEmployee.Processing_State__c = 'Processed';
		update objEmployee;

		Test.stopTest();

		Account objAccountRec = [SELECT Id, ZP_Company_id__c, No_Of_Employees_Filling_State__c, No_of_EEs_in_HI_State__c, BillingState FROM Account];

		System.assertEquals(0, objAccountRec.No_Of_Employees_Filling_State__c, 'Number of EE Filling State should be 0');
		System.assertEquals(0, objAccountRec.No_of_EEs_in_HI_State__c, 'Number of EE in HI State should be 0');
	}

	/**
	 * @Author      :
	 * @Description : Test Skip trigger functionality
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testSkipTrigger() {
		ZPEmployeeTriggerHelper.skipTrigger = true;

		ZP_Employee__c objEmployee = new ZP_Employee__c();
		objEmployee.Processing_State__c = 'Queued';
		objEmployee.Company_Id__c = '11119999';
		insert objEmployee;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Residence State Update on Employee Insert
	 * @Parm        : null
	 * @Return      : null
	 **/
	static testMethod void testResidenceStateUpdateAtInsert() {
		Test.startTest();
		ZPEmployeeTriggerHandler.resetSkipTriggerFlags();

		ZP_Employee__c objEmployee = new TestDataFactory.ZPEmployeeBuilder().setEmployeeId('5453255').setCompanyId('11119999').setProcessingState('Queued').setResidenceState('CA').build();
		insert objEmployee;

		Test.stopTest();

		Contact objContact = [SELECT Residence_State__c, Account.Resident_States__c FROM Contact WHERE Employee_Id__c = '5453255' LIMIT 1];

		System.assert(objContact.Account.Resident_States__c != null && objContact.Account.Resident_States__c.contains('CA'), 'Resident State is incorrect on account.');
		System.assertEquals(objContact.Residence_State__c, 'CA', 'Residence State should be set to CA.');
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Residence State Update on Employee Update
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testResidenceStateUpdateAtUpdate() {
		Test.startTest();
		ZPEmployeeTriggerHandler.resetSkipTriggerFlags();

		ZP_Employee__c objEmployee = new TestDataFactory.ZPEmployeeBuilder().setEmployeeId('5453255').setCompanyId('11119999').setProcessingState('Queued').build();
		insert objEmployee;

		objEmployee.Residence_State__c = 'CA';
		update objEmployee;

		Test.stopTest();

		Contact objContact = [SELECT Residence_State__c, Account.Resident_States__c FROM Contact WHERE Employee_Id__c = '5453255' LIMIT 1];

		System.assert(objContact.Account.Resident_States__c != null && objContact.Account.Resident_States__c.contains('CA'));
		System.assertEquals(objContact.Residence_State__c, 'CA', 'Residence State should be set to CA.');
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Residence State Update on Employee Delete
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testResidenceStateUpdateOnDelete() {
		Test.startTest();
		ZPEmployeeTriggerHandler.resetSkipTriggerFlags();

		ZP_Employee__c objEmployee = new TestDataFactory.ZPEmployeeBuilder().setEmployeeId('5453255').setCompanyId('11119999').setProcessingState('Queued').setResidenceState('CA').build();
		insert objEmployee;

		objEmployee.Deleted_At__c = System.now();
		update objEmployee;

		Test.stopTest();

		Contact objContact = [SELECT Residence_State__c, Account.Resident_States__c FROM Contact WHERE Employee_Id__c = '5453255' LIMIT 1];

		System.assert(String.isBlank(objContact.Account.Resident_States__c), 'Account Resident State should be blank');
		System.assert(String.isBlank(objContact.Residence_State__c), 'Contact Resident State should be blank');
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Test Residence State Update Without company id and employee id
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testResidenceStateUpdateNegative() {
		Test.startTest();
		ZPEmployeeTriggerHandler.resetSkipTriggerFlags();

		ZP_Employee__c objEmployee = new TestDataFactory.ZPEmployeeBuilder().setProcessingState('Queued').setResidenceState('CA').build();
		insert objEmployee;

		Test.stopTest();

		Contact objContact = [SELECT Residence_State__c, Account.Resident_States__c FROM Contact WHERE Employee_Id__c = '5453255' LIMIT 1];

		System.assert(String.isBlank(objContact.Account.Resident_States__c), 'Account Resident State should be blank');
		System.assert(String.isBlank(objContact.Residence_State__c), 'Contact Resident State should be blank');
	}
}