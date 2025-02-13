/**
 * @description The Test class for PartnerProgramCompanyDataTriggerHelper
 * @author      Ajay Krishna P U
 * @since       2023-04-18
 */
@isTest
public with sharing class PartnerProgramCompanyTriggerHelperTest {
	private final static String COMPANY_1_ACCOUNT_REF = 'PP1-Company Account';
	private final static String COMPANY_2_ACCOUNT_REF = 'PP2-Company Account';
	private final static String RESELLER_1_ACCOUNT_REF = 'PP1-Reseller Account';
	private final static String RESELLER_2_ACCOUNT_REF = 'PP2-Reseller Account';

	/**
	 * @description Test Setup
	 */
	@TestSetup
	static void makeData() {
		Account objCompanyAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName(COMPANY_1_ACCOUNT_REF).build();
		Account objCompanyAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName(COMPANY_2_ACCOUNT_REF).build();
		Account objResellerAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName(RESELLER_1_ACCOUNT_REF).build();
		Account objResellerAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName(RESELLER_2_ACCOUNT_REF).build();

		AccountTriggerHelper.skipTrigger = true;
		insert new List<Account>{ objCompanyAccount1, objCompanyAccount2, objResellerAccount1, objResellerAccount2 };
		AccountTriggerHelper.skipTrigger = false;

		Partner_Program_Company_Data__c objPartnerProgram = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(objResellerAccount1.Id)
			.setAccount(objCompanyAccount1.Id)
			.build();

		PartnerProgramCompanyDataTriggerHelper.blnSkipTrigger = true;
		insert objPartnerProgram;
		PartnerProgramCompanyDataTriggerHelper.blnSkipTrigger = false;
	}

	/**
	 * @description Test on Partner Program Insert
	 */
	@isTest
	static void testPartnerProgramInsert() {
		Map<String, Account> map_NameToAccount = getAccountMap();

		Test.startTest();
		Partner_Program_Company_Data__c objPartnerProgram = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_1_ACCOUNT_REF).Id)
			.build();
		insert objPartnerProgram;
		Test.stopTest();

		Account objReseller = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(Utils.isMultiPicklistContains(objReseller.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Recalculate Tracker did not update - insert');
	}

	/**
	 * @description Test on Partner Program Update - Managing Firm
	 */
	@isTest
	static void testPartnerProgramUpdateManagingFirm() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		Partner_Program_Company_Data__c objPartnerProgram = queryPartnerProgram(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);

		Test.startTest();
		objPartnerProgram.Managing_Accounting_Firm__c = map_NameToAccount.get(RESELLER_2_ACCOUNT_REF).Id;
		update objPartnerProgram;
		Test.stopTest();

		Account objReseller1 = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(Utils.isMultiPicklistContains(objReseller1.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Recalculate Tracker did not update - update - 1');

		Account objReseller2 = queryAccount(map_NameToAccount.get(RESELLER_2_ACCOUNT_REF).Id);
		System.assert(Utils.isMultiPicklistContains(objReseller2.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Recalculate Tracker did not update - update - 2');
	}

	/**
	 * @description Test on Partner Program Update - Account
	 */
	@isTest
	static void testPartnerProgramUpdateAccount() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		Partner_Program_Company_Data__c objPartnerProgram = queryPartnerProgram(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);

		Test.startTest();
		objPartnerProgram.Account__c = map_NameToAccount.get(COMPANY_2_ACCOUNT_REF).Id;
		update objPartnerProgram;
		Test.stopTest();

		Account objReseller1 = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(Utils.isMultiPicklistContains(objReseller1.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Recalculate Tracker did not update - update');
	}

	/**
	 * @description Test on Partner Program Deactivate
	 */
	@isTest
	static void testPartnerProgramDeactivate() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		Partner_Program_Company_Data__c objPartnerProgram = queryPartnerProgram(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);

		Test.startTest();
		objPartnerProgram.Deleted_At__c = Date.today();
		update objPartnerProgram;
		Test.stopTest();

		Account objReseller1 = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(Utils.isMultiPicklistContains(objReseller1.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Recalculate Tracker did not update - update');
	}

	/**
	 * @description Test on Partner Program Deactivate & Account Change
	 */
	@isTest
	static void testPartnerProgramDeactivateAndAccountUpdate() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		Partner_Program_Company_Data__c objPartnerProgram = queryPartnerProgram(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);

		Test.startTest();
		//Deactivate
		objPartnerProgram.Deleted_At__c = Date.today();
		update objPartnerProgram;

		Test.stopTest();
		//Reset Tracker
		Account objReseller1 = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		objReseller1.Recalculate_Metrics_Tracker__c = null;
		update objReseller1;

		//Account Change
		objPartnerProgram.Account__c = map_NameToAccount.get(COMPANY_2_ACCOUNT_REF).Id;
		update objPartnerProgram;
		objReseller1 = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(false == Utils.isMultiPicklistContains(objReseller1.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Recalculate Tracker did not update - update');
	}

	/**
	 * @description Test Partner Program Delete
	 */
	@isTest
	static void testPartnerProgramDelete() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		Partner_Program_Company_Data__c objPartnerProgram = queryPartnerProgram(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);

		Test.startTest();
		delete objPartnerProgram;
		Test.stopTest();

		Account objReseller1 = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(Utils.isMultiPicklistContains(objReseller1.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Recalculate Tracker did not update - Delete');
	}

	/**
	 * @description Test Partner Program Un-Delete
	 */
	@isTest
	static void testPartnerProgramUnDelete() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		Partner_Program_Company_Data__c objPartnerProgram = queryPartnerProgram(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);

		delete objPartnerProgram;
		Account objReseller1 = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		objReseller1.Recalculate_Metrics_Tracker__c = null;
		update objReseller1;

		Test.startTest();
		undelete objPartnerProgram;
		Test.stopTest();

		objReseller1 = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(Utils.isMultiPicklistContains(objReseller1.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR), 'Recalculate Tracker did not update - UnDelete');
	}

	/**
	 * @description Test Exception, to cover Exception log catch blocks
	 */
	@isTest
	static void testException() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		Partner_Program_Company_Data__c objPartnerProgram = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_1_ACCOUNT_REF).Id)
			.build();

		Test.startTest();
		PartnerProgramCompanyDataTriggerHandler.blnTestException = true;

		insert objPartnerProgram;
		update objPartnerProgram;
		delete objPartnerProgram;
		undelete objPartnerProgram;
		Test.stopTest();

		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'PartnerProgramCompanyDataTriggerHandler'];
		System.assert(4 == list_Exceptions.size(), 'Exceptions are not raised as expected');
	}

	/**
	 * @description Get Name --> Account Map of Test data
	 * @return      `Map<String, Account>`
	 */
	static Map<String, Account> getAccountMap() {
		Map<String, Account> map_NameToAccount = new Map<String, Account>();
		List<String> list_AccountNames = new List<String>{ COMPANY_1_ACCOUNT_REF, COMPANY_2_ACCOUNT_REF, RESELLER_1_ACCOUNT_REF, RESELLER_2_ACCOUNT_REF };
		for (Account objAccount : [SELECT Id, Name FROM Account WHERE Name IN :list_AccountNames]) {
			map_NameToAccount.put(objAccount.Name, objAccount);
		}

		return map_NameToAccount;
	}

	/**
	 * @description     Query Account based on @idAccount
	 * @param idAccount Account Id to Query
	 * @return          `Account`
	 */
	static Account queryAccount(Id idAccount) {
		List<Account> list_Accounts = [SELECT Id, Recalculate_Metrics_Tracker__c FROM Account WHERE Id = :idAccount];
		System.assert(!list_Accounts.isEmpty(), 'Account Not found');

		return list_Accounts[0];
	}

	/**
	 * @description      Query Partner Programs base don managing Firm Id
	 * @param idReseller The related managing Firm/Reseller id
	 * @return           `Partner_Program_Company_Data__c`
	 */
	static Partner_Program_Company_Data__c queryPartnerProgram(Id idReseller) {
		List<Partner_Program_Company_Data__c> list_PartnerPrograms = [
			SELECT Id, Managing_Accounting_Firm__c, Account__c
			FROM Partner_Program_Company_Data__c
			WHERE Managing_Accounting_Firm__c = :idReseller
		];
		System.assert(!list_PartnerPrograms.isEmpty(), 'Partner Program Not found');

		return list_PartnerPrograms[0];
	}
}