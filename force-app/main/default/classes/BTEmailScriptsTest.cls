/*
    @Author : David (Dato) Tsamalashvili
    @Date   : May 29, 2020
    @Desc   : Test class for BTEmailScripts
*/
@isTest
public class BTEmailScriptsTest {
	@isTest
	static void createEmailCasesV2() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'success@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 1', From_Addresses__c = 'test@dt1.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'support@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 2', From_Addresses__c = 'test@dt2.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account1')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 1', Email = 'test@dt1.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 2', Email = 'test@dt2.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_2() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'benefits@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 3', From_Addresses__c = 'test@dt3.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'bor-transfer@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 4', From_Addresses__c = 'test@dt4.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account2')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 3', Email = 'test@dt3.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 4', Email = 'test@dt4.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_3() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'newplans@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 5', From_Addresses__c = 'test@dt5.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'renewalcarriercomms@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 6', From_Addresses__c = 'test@dt6.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account3')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 5', Email = 'test@dt5.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 6', Email = 'test@dt6.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_4() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'cashout-support@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 7', From_Addresses__c = 'test@dt7.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'cobra@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 8', From_Addresses__c = 'test@dt8.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account4')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 7', Email = 'test@dt7.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 8', Email = 'test@dt8.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_5() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'compliance@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 9', From_Addresses__c = 'test@dt9.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'payrollonboarding@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 10', From_Addresses__c = 'test@dt10.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account5')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 10', Email = 'test@dt9.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 11', Email = 'test@dt10.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_6() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'memberfulfillment@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 11', From_Addresses__c = 'test@dt11.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'payopsptserrors@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 12', From_Addresses__c = 'test@dt12.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account6')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 12', Email = 'test@dt11.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 13', Email = 'test@dt12.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_7() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'poa.support@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 13', From_Addresses__c = 'test@dt13.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'assurance@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 14', From_Addresses__c = 'test@dt14.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account7')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 14', Email = 'test@dt13.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 15', Email = 'test@dt14.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_8() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'payrollops@zenpayroll.com', Subject__c = 'test', Text_Body__c = 'text body test 13', From_Addresses__c = 'test@dt13.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'benefits-newplans@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 14', From_Addresses__c = 'test@dt14.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account8')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 14', Email = 'test@dt13.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 15', Email = 'test@dt14.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_9() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'benefits-onboarding@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 13', From_Addresses__c = 'test@dt13.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'cash-reserve-support@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 14', From_Addresses__c = 'test@dt14.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account9')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 14', Email = 'test@dt13.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 15', Email = 'test@dt14.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_10() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'cashout-support@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 13', From_Addresses__c = 'test@dt13.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'flexible-pay-support@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 14', From_Addresses__c = 'test@dt14.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'wallet@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 15', From_Addresses__c = 'test@dt15.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account10')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 13', Email = 'test@dt13.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 14', Email = 'test@dt14.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 15', Email = 'test@dt15.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_11() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'garnishments@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 13', From_Addresses__c = 'test@dt13.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'recovery@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 14', From_Addresses__c = 'test@dt14.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account11')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 14', Email = 'test@dt13.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 15', Email = 'test@dt14.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_12() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'setup@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 13', From_Addresses__c = 'test@dt13.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'taxcompliance@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 14', From_Addresses__c = 'test@dt14.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account12')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 14', Email = 'test@dt13.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 15', Email = 'test@dt14.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}

	@isTest
	static void createEmailCasesV2_13() {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		Set<Id> set_tempIds = new Set<Id>();

		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'setup@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 13', From_Addresses__c = 'test@dt13.ss'));
		list_tempObj.add(new BizTech_Temp_Obj__c(To_Address__c = 'underwriting@gusto.com', Subject__c = 'test', Text_Body__c = 'text body test 14', From_Addresses__c = 'test@dt14.ss'));

		insert list_tempObj;

		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_tempIds.add(obj.Id);
		}

		//create account for contacts
		AccountTriggerHelper.skipTrigger = true;
		Account account = new TestDataFactory.AccountBuilder()
            .setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
            .setName('Company Account13')
            .setZPCompanyId('1111111111')
            .build();
		insert account;
		AccountTriggerHelper.skipTrigger = false;

		//insert contacts
		Id id_conRecordType = Cache.getRecordTypeId('Contact', 'Company');
		List<Contact> list_contacts = new List<Contact>();

		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 14', Email = 'test@dt13.ss'));
		list_contacts.add(new Contact(AccountId = account.Id, RecordTypeId = id_conRecordType, FirstName = 'fTest', LastName = 'lTest 15', Email = 'test@dt14.ss'));

		ContactTriggerHelper.skipTrigger = true;
		insert list_contacts;
		ContactTriggerHelper.skipTrigger = false;

		//process data
		EmailMessageTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BTEmailScripts.createEmailCasesV2(set_tempIds);
		System.assertNotEquals(0, list_tempObj.size(), 'Incorrect List Size');
	}
}