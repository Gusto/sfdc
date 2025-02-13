/**
 * Created by brent on 1/5/16.
 */
@isTest
private class TriggerTaskResponseTimeTest {
	private static List<Lead> leads = new List<Lead>();
	private static List<Account> accounts = new List<Account>();
	private static final Integer NumberOfAccounts = 5;
	private static final Integer NumberOfLeads = 5;
	public static final Id TaskCallRecordTypeId = Schema.Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Call').getRecordTypeId();
	public static final String ConvertedLeadStatus = Config.LeadConversion.CONVERTED_LEAD_STATUS;

	@testSetup
	static void createTestData() {
		AccountTriggerHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;
		accounts.addAll(createAccountsList());
		insert accounts;
		System.assertEquals(NumberOfAccounts, accounts.size(), 'Number of accounts should match.');

		for (Integer i = 0; i < NumberOfLeads; i++) {
			leads.add(new TestDataFactory.LeadBuilder().setRecordTypeId(LeadUtil.LABEL_RESELLER).build());
		}
		Integer i = 1;
		for (Lead objLead : leads) {
			objLead.FirstName = 'Test Lead ';
			objLead.LastName = String.valueOf(i);
			objLead.Company = String.valueOf(i);
			objLead.ZP_Company_ID__c = String.valueOf(i);
			i++;
		}
		insert leads;
		System.assertEquals(NumberOfLeads, leads.size(), 'Number of leads should match.');
	}

	@isTest
	static void TriggerTaskWithSkipTriggerCreateOutboundCallAccount() {
		Test.startTest();
		TriggerTaskDispatchClass.skipTrigger = true;
		String strSchedule = 'Scheduled';
		List<Task> list_Tasks = new List<Task>();
		accounts = [SELECT Id FROM Account];

		for (Account objAcc : accounts) {
			list_Tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = strSchedule, WhatId = objAcc.Id));
		}
		insert list_Tasks;

		Test.stopTest();

		System.assertEquals(NumberOfAccounts, accounts.size(), 'Number of accounts should match.');
		System.assertEquals(NumberOfAccounts, list_Tasks.size(), 'Number of leads should match the number of accounts.');

		Map<Id, Task> map_Tasks = new Map<Id, Task>(list_Tasks);
		for (Task objTask : [SELECT Id, CreatedDate, Account.Response_Date_Time__c, Status, IsClosed FROM Task WHERE Id IN :map_Tasks.keyset()]) {
			System.assert(!objTask.IsClosed, 'Tast should not be closed.');
			System.assertEquals(strSchedule, objTask.Status, 'Task status should be Scheduled.');
			System.assertEquals(null, objTask.Account.Response_Date_Time__c, 'Response date time on task\'s account should be null.');
		}
	}

	@isTest
	static void TriggerTask_CreateOutboundCallAccount_A() {
		final String tskStatus = 'Scheduled';
		List<Task> tasks = new List<Task>();
		accounts = [SELECT Id FROM Account];
		for (Account a : accounts) {
			tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = tskStatus, WhatId = a.Id));
		}
		Test.startTest();
		insert tasks;
		Test.stopTest();
		System.assertEquals(NumberOfAccounts, accounts.size(), 'Number of accounts should match.');
		System.assertEquals(NumberOfAccounts, tasks.size(), 'Number of tasks should match the number of accounts.');
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		for (Task t : [SELECT Id, CreatedDate, Account.Response_Date_Time__c, Status, IsClosed FROM Task WHERE Id IN :taskMap.keyset()]) {
			System.assert(!t.IsClosed, 'Tast should not be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Scheduled.');
			System.assertEquals(null, t.Account.Response_Date_Time__c, 'Response date time on task\'s account should be null.');
		}
	}

	@isTest
	static void TriggerTask_CreateOutboundCallAccount_B() {
		final String tskStatus = 'Connect';
		List<Task> tasks = new List<Task>();
		accounts = [SELECT Id FROM Account];
		for (Account a : accounts) {
			tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = tskStatus, WhatId = a.Id));
		}
		Test.startTest();
		insert tasks;
		Test.stopTest();
		System.assertEquals(NumberOfAccounts, accounts.size(), 'Number of accounts should match.');
		System.assertEquals(NumberOfAccounts, tasks.size(), 'Number of tasks should match the number of accounts.');
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		for (Task t : [SELECT Id, CreatedDate, Account.Response_Date_Time__c, Status, IsClosed FROM Task WHERE Id IN :taskMap.keyset()]) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Connect.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on task\'s account and CreatedDate on task should be same.');
		}
	}

	@isTest
	static void TriggerTask_CreateOutboundCallAccount_C() {
		final String tskStatus = 'Voicemail';
		List<Task> tasks = new List<Task>();
		accounts = [SELECT Id FROM Account];
		for (Account a : accounts) {
			tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = tskStatus, WhatId = a.Id));
		}
		Test.startTest();
		insert tasks;
		Test.stopTest();
		System.assertEquals(NumberOfAccounts, accounts.size(), 'Number of accounts should match.');
		System.assertEquals(NumberOfAccounts, tasks.size(), 'Number of tasks should match the number of accounts.');
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		for (Task t : [SELECT Id, CreatedDate, Account.Response_Date_Time__c, Status, IsClosed FROM Task WHERE Id IN :taskMap.keyset()]) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Voicemail.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on task\'s account and CreatedDate on task should be same.');
		}
	}

	@isTest
	static void TriggerTask_CreateOutboundCallAccount_D() {
		final String tskStatus = 'Attempt';
		List<Task> tasks = new List<Task>();
		accounts = [SELECT Id FROM Account];
		for (Account a : accounts) {
			tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = tskStatus, WhatId = a.Id));
		}
		Test.startTest();
		insert tasks;
		Test.stopTest();
		System.assertEquals(NumberOfAccounts, accounts.size(), 'Number of accounts should match.');
		System.assertEquals(NumberOfAccounts, tasks.size(), 'Number of tasks should match the number of accounts.');
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		for (Task t : [SELECT Id, CreatedDate, Account.Response_Date_Time__c, Status, IsClosed FROM Task WHERE Id IN :taskMap.keyset()]) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Attempt.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on task\'s account and CreatedDate on task should be same.');
		}
	}

	@isTest
	static void TriggerTask_CreateOutboundCallLead_A() {
		final String tskStatus = 'Scheduled';
		List<Task> tasks = new List<Task>();
		leads = [SELECT Id FROM Lead];
		for (Lead l : leads) {
			tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = tskStatus, WhoId = l.Id));
		}
		Test.startTest();
		insert tasks;
		Test.stopTest();
		System.assertEquals(NumberOfLeads, leads.size(), 'Number of leads should match.');
		System.assertEquals(NumberOfLeads, tasks.size(), 'Number of tasks should match the number of leads.');
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		for (Task t : [SELECT Id, AccountId, CreatedDate, Status, IsClosed FROM Task WHERE Id IN :taskMap.keyset()]) {
			System.assert(!t.IsClosed, 'Tast should not be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Scheduled.');
			System.assertEquals(null, t.AccountId, 'AccountId on task should be null.');
		}
	}

	@isTest
	static void TriggerTask_CreateOutboundCallLead_B() {
		final String tskStatus = 'Connect';
		List<Task> tasks = new List<Task>();
		leads = [SELECT Id FROM Lead];
		for (Lead l : leads) {
			tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = tskStatus, WhoId = l.Id));
		}
		Test.startTest();
		insert tasks;
		Test.stopTest();
		System.assertEquals(NumberOfLeads, leads.size(), 'Number of leads should match.');
		System.assertEquals(NumberOfLeads, tasks.size(), 'Number of tasks should match the number of leads.');
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		for (Task t : [SELECT Id, AccountId, CreatedDate, Status, IsClosed FROM Task WHERE Id IN :taskMap.keyset()]) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Connect.');
			System.assertEquals(null, t.AccountId, 'AccountId on task should be null.');
		}
	}

	@isTest
	static void TriggerTask_CreateOutboundCallLead_C() {
		final String tskStatus = 'Scheduled';
		List<Task> tasks = new List<Task>();
		leads = [SELECT Id FROM Lead];
		for (Lead l : leads) {
			tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = tskStatus, WhoId = l.Id));
		}
		Test.startTest();
		insert tasks;
		Test.stopTest();
		System.assertEquals(NumberOfLeads, leads.size(), 'Number of leads should match.');
		System.assertEquals(NumberOfLeads, tasks.size(), 'Number of tasks should match the number of leads.');
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		for (Task t : [SELECT Id, AccountId, CreatedDate, Status, IsClosed FROM Task WHERE Id IN :taskMap.keyset()]) {
			System.assert(!t.IsClosed, 'Tast should not be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Scheduled.');
			System.assertEquals(null, t.AccountId, 'AccountId on task should be null.');
		}
	}

	@isTest
	static void TriggerTask_CreateOutboundCallLead_D() {
		final String tskStatus = 'Attempt';
		List<Task> tasks = new List<Task>();
		leads = [SELECT Id FROM Lead];
		for (Lead l : leads) {
			tasks.add(new Task(RecordTypeId = TaskCallRecordTypeId, Type = 'Outbound Call', Status = tskStatus, WhoId = l.Id));
		}
		Test.startTest();
		insert tasks;
		Test.stopTest();
		System.assertEquals(NumberOfLeads, leads.size(), 'Number of leads should match.');
		System.assertEquals(NumberOfLeads, tasks.size(), 'Number of tasks should match the number of leads.');
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		for (Task t : [SELECT Id, AccountId, CreatedDate, Status, IsClosed FROM Task WHERE Id IN :taskMap.keyset()]) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Attempt.');
			System.assertEquals(null, t.AccountId, 'AccountId on task should be null.');
		}
	}

	@isTest
	static void TriggerTask_UpdateOutboundCallAccount_A() {
		final String tskStatus = 'Connect';
		Map<Id, Account> originalAccounts = new Map<Id, Account>([SELECT Id FROM Account]);
		System.assertEquals(NumberOfAccounts, originalAccounts.size(), 'Number of accounts should match.');
		List<Task> tasks = TestUtility.Task_OutboundCall(originalAccounts.keySet(), null, 'Scheduled', -1);
		System.assertEquals(NumberOfAccounts, tasks.size(), 'Number of tasks should match the number of accounts.');
		insert tasks;
		for (Task t : tasks) {
			System.assert(!t.IsClosed, 'Tast should not be closed.');
			t.Status = tskStatus;
		}
		Test.startTest();
		update tasks;
		Test.stopTest();
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		Task[] updatedTasks = [SELECT Id, Status, IsClosed, Account.Response_Date_Time__c, CreatedDate FROM Task WHERE Id IN :taskMap.keySet()];
		for (Task t : updatedTasks) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Connect.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on task\'s account and CreatedDate on task should be same.');
		}
	}

	@isTest
	static void TriggerTask_UpdateOutboundCallAccount_B() {
		final String tskStatus = 'Voicemail';
		Map<Id, Account> originalAccounts = new Map<Id, Account>([SELECT Id FROM Account]);
		System.assertEquals(NumberOfAccounts, originalAccounts.size(), 'Number of accounts should match.');
		List<Task> tasks = TestUtility.Task_OutboundCall(originalAccounts.keySet(), null, 'Scheduled', -3);
		System.assertEquals(NumberOfAccounts, tasks.size(), 'Number of tasks should match the number of accounts.');
		insert tasks;
		for (Task t : tasks) {
			System.assert(!t.IsClosed, 'Tast should not be closed.');
			t.Status = tskStatus;
		}
		Test.startTest();
		update tasks;
		Test.stopTest();
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		Task[] updatedTasks = [SELECT Id, Status, IsClosed, AccountId, CreatedDate FROM Task WHERE Id IN :taskMap.keySet()];
		Map<Id, Account> updatedAccounts = new Map<Id, Account>([SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :originalAccounts.keySet()]);
		for (Task t : updatedTasks) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Voicemail.');
			System.assertEquals(t.CreatedDate, updatedAccounts.get(t.AccountId).Response_Date_Time__c, 'Response_Date_Time__c on task\'s account and CreatedDate on task should be same.');
		}
	}

	@isTest
	static void TriggerTask_UpdateOutboundCallAccount_C() {
		final String tskStatus = 'Attempt';
		Map<Id, Account> originalAccounts = new Map<Id, Account>([SELECT Id FROM Account]);
		System.assertEquals(NumberOfAccounts, originalAccounts.size(), 'Number of accounts should match.');
		List<Task> tasks = TestUtility.Task_OutboundCall(originalAccounts.keySet(), null, 'Scheduled', -3);
		System.assertEquals(NumberOfAccounts, tasks.size(), 'Number of tasks should match the number of accounts.');
		insert tasks;
		for (Task t : tasks) {
			System.assert(!t.IsClosed, 'Tast should not be closed.');
			t.Status = tskStatus;
		}
		Test.startTest();
		update tasks;
		Test.stopTest();
		Map<Id, Task> taskMap = new Map<Id, Task>(tasks);
		Task[] updatedTasks = [SELECT Id, Status, IsClosed, AccountId, CreatedDate FROM Task WHERE Id IN :taskMap.keySet()];
		Map<Id, Account> updatedAccounts = new Map<Id, Account>([SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :originalAccounts.keySet()]);
		for (Task t : updatedTasks) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(tskStatus, t.Status, 'Task status should be Attempt.');
			System.assertEquals(t.CreatedDate, updatedAccounts.get(t.AccountId).Response_Date_Time__c, 'Response_Date_Time__c on task\'s account and CreatedDate on task should be same.');
		}
	}

	@isTest
	static void TriggerTask_DeleteOutboundCallAccount_A() {
		Map<Id, Account> originalAccounts = new Map<Id, Account>([SELECT Id FROM Account]);
		System.assertEquals(NumberOfAccounts, originalAccounts.size(), 'Number of accounts should match.');
		List<Task> tasks = TestUtility.Task_OutboundCall(originalAccounts.keySet(), null, 'Connect', -3);
		insert tasks;
		List<Account> AccountsWithTasks = ([SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :originalAccounts.keySet()]);
		for (Account a : AccountsWithTasks) {
			System.assertNotEquals(null, a.Response_Date_Time__c, 'Account\'s Response_Date_Time__c should not be null.');
		}
		Test.startTest();
		delete tasks;
		Test.stopTest();
		List<Account> AccountsWithoutTasks = ([SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :originalAccounts.keySet()]);
		for (Account a : AccountsWithoutTasks) {
			System.assertEquals(null, a.Response_Date_Time__c, 'Account\'s Response_Date_Time__c should be null.');
		}
	}

	@isTest
	static void TriggerTask_DeleteOutboundCallAccount_B() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		Map<Id, Account> originalAccounts = new Map<Id, Account>([SELECT Id FROM Account]);
		System.assertEquals(NumberOfAccounts, originalAccounts.size(), 'Number of accounts should match.');
		List<Task> t1 = TestUtility.Task_OutboundCall(originalAccounts.keySet(), null, 'Voicemail', -5);
		insert t1;
		Map<Id, Task> tasks1 = new Map<Id, Task>(t1);

		List<Task> task1Accounts = ([SELECT CreatedDate, Account.Response_Date_Time__c FROM Task WHERE Id IN :tasks1.keySet()]);
		for (Task t : task1Accounts) {
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
		delete tasks1.values();
	}

	@isTest
	static void TriggerTask_MultipleOutboundCallsAccount_A() {
		final String tskStatus = 'Connect';
		List<Account> accountList = createAccountsList();
		insert accountList;
		Map<Id, Account> accountMap = new Map<Id, Account>(accountList);
		List<Task> outboundCall1 = TestUtility.Task_OutboundCall(accountMap.keySet(), null, 'Scheduled', -5);
		insert outboundCall1;
		for (Account a : accountList) {
			System.assertEquals(null, a.Response_Date_Time__c, 'Account\'s Response_Date_Time__c should be null.');
		}
		System.assertEquals(NumberOfAccounts, outboundCall1.size(), 'Number of tasks should match the number of accounts.');
		List<Task> outboundCall2 = TestUtility.Task_OutboundCall(accountMap.keySet(), null, 'Scheduled', -3);
		insert outboundCall2;
		for (Account a : accountList) {
			System.assertEquals(null, a.Response_Date_Time__c, 'Account\'s Response_Date_Time__c should be null.');
		}
		System.assertEquals(NumberOfAccounts, outboundCall2.size(), 'Number of tasks should match the number of accounts.');
		for (Task t : outboundCall1) {
			t.Status = tskStatus;
		}
		Test.startTest();
		update outboundCall1;
		Test.stopTest();
		List<Task> updatedTasks = [SELECT Id, CreatedDate, Status, IsClosed, Account.Response_Date_Time__c FROM Task WHERE Id IN :outboundCall1];
		for (Task t : updatedTasks) {
			System.assertEquals(tskStatus, t.Status, 'Task status should be Connect.');
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
	}

	@isTest
	static void TriggerTask_MultipleOutboundCallsAccount_B() {
		AccountTriggerHelper.skipTrigger = true;
		final String tskStatus = 'Connect';
		List<Account> accountList = createAccountsList();
		insert accountList;
		Map<Id, Account> accountMap = new Map<Id, Account>(accountList);
		List<Task> outboundCall1 = TestUtility.Task_OutboundCall(accountMap.keySet(), null, 'Scheduled', -5);
		insert outboundCall1;
		for (Account a : accountList) {
			System.assertEquals(null, a.Response_Date_Time__c, 'Account\'s Response_Date_Time__c should be null.');
		}
		System.assertEquals(NumberOfAccounts, outboundCall1.size(), 'Number of tasks should match the number of accounts.');
		List<Task> outboundCall2 = TestUtility.Task_OutboundCall(accountMap.keySet(), null, 'Scheduled', -3);
		insert outboundCall2;
		for (Account a : accountList) {
			System.assertEquals(null, a.Response_Date_Time__c, 'Account\'s Response_Date_Time__c should be null.');
		}
		System.assertEquals(NumberOfAccounts, outboundCall2.size(), 'Number of tasks should match the number of accounts.');
		for (Task t : outboundCall2) {
			t.Status = tskStatus;
		}
		Test.startTest();
		update outboundCall2;
		Test.stopTest();
		List<Task> updatedTasks = [SELECT Id, CreatedDate, Status, IsClosed, AccountId FROM Task WHERE Id IN :outboundCall2];
		List<Account> updatedAccounts = [SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :accountMap.keySet()];
		Map<Id, Account> updatedAccountMap = new Map<Id, Account>(updatedAccounts);
		for (Task t : updatedTasks) {
			System.assertEquals(tskStatus, t.Status, 'Task status should be Connect.');
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, updatedAccountMap.get(t.AccountId).Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
	}

	@isTest
	static void TriggerTask_MultipleOutboundCallsAccount_C() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		final String tskStatus = 'Connect';
		List<Account> accountList = createAccountsList();
		insert accountList;
		Map<Id, Account> accountMap = new Map<Id, Account>(accountList);

		List<Task> outboundCall1 = TestUtility.Task_OutboundCall(accountMap.keySet(), null, tskStatus, -5);
		insert outboundCall1;
		List<Task> updatedTasks1 = [SELECT Id, CreatedDate, Status, IsClosed, AccountId FROM Task WHERE Id IN :outboundCall1];
		List<Account> updatedAccounts1 = [SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :accountMap.keySet()];
		Map<Id, Account> updatedAccountMap1 = new Map<Id, Account>(updatedAccounts1);
		for (Task t : updatedTasks1) {
			System.assertEquals(tskStatus, t.Status, 'Task status should be Connect.');
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, updatedAccountMap1.get(t.AccountId).Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}

		List<Task> outboundCall2 = TestUtility.Task_OutboundCall(accountMap.keySet(), null, tskStatus, -3);
		insert outboundCall2;
		List<Task> updatedTasks2 = [SELECT Id, CreatedDate, Status, IsClosed, AccountId FROM Task WHERE Id IN :outboundCall2];
		List<Account> updatedAccounts2 = [SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :accountMap.keySet()];
		Map<Id, Account> updatedAccountMap2 = new Map<Id, Account>(updatedAccounts2);
		for (Task t : updatedTasks2) {
			System.assertEquals(tskStatus, t.Status, 'Task status should be Connect.');
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertNotEquals(t.CreatedDate, updatedAccountMap2.get(t.AccountId).Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
		Test.startTest();
		delete outboundCall1;
		Test.stopTest();
		List<Account> updatedAccounts3 = [SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :accountMap.keySet()];
		Map<Id, Account> updatedAccountMap3 = new Map<Id, Account>(updatedAccounts3);
		for (Task t : updatedTasks2) {
			System.assertEquals(tskStatus, t.Status, 'Task status should be Connect.');
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, updatedAccountMap3.get(t.AccountId).Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
	}

	@isTest
	static void TriggerTask_MultipleTasksOnAccount_A() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		List<Account> accountList = createAccountsList();
		insert accountList;
		Map<Id, Account> accountMap = new Map<Id, Account>(accountList);
		List<Task> standard1 = TestUtility.Task_Standard(accountMap.keySet(), null, 'Open', -5);
		insert standard1;
		Test.startTest();
		for (Task t : standard1) {
			t.Status = 'Completed';
		}
		update standard1;

		List<Task> outboundCall2 = TestUtility.Task_OutboundCall(accountMap.keySet(), null, 'Connect', -3);
		insert outboundCall2;
		List<Task> updatedTasks1 = [SELECT Id, CreatedDate, Status, IsClosed, AccountId FROM Task WHERE Id IN :outboundCall2];
		List<Account> updatedAccounts1 = [SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :accountMap.keySet()];
		Map<Id, Account> updatedAccountMap1 = new Map<Id, Account>(updatedAccounts1);
		for (Task t : updatedTasks1) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, updatedAccountMap1.get(t.AccountId).Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
		Test.stopTest();
	}

	@isTest
	static void TriggerTask_MultipleTasksOnAccount_B() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		List<Account> accountList = createAccountsList();
		insert accountList;
		Map<Id, Account> accountMap = new Map<Id, Account>(accountList);
		List<Task> listStandard2 = TestUtility.Task_Standard(accountMap.keySet(), null, 'Open', -3);
		insert listStandard2;
		Map<Id, Task> standard2 = new Map<Id, Task>(listStandard2);
		List<Task> listOutboundCall2 = TestUtility.Task_OutboundCall(accountMap.keySet(), null, 'Scheduled', -2);
		insert listOutboundCall2;
		Map<Id, Task> outboundCall2 = new Map<Id, Task>(listOutboundCall2);
		for (Task t : outboundCall2.values()) {
			t.Status = 'Connect';
		}
		update outboundCall2.values();
		List<Task> updatedTasks1 = [SELECT Id, CreatedDate, IsClosed, Account.Response_Date_Time__c FROM Task WHERE Id IN :outboundCall2.keySet()];
		for (Task t : updatedTasks1) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
	}

	@isTest
	static void TriggerTask_OutboundCallLeadConversion_A() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		final String tskStatus = 'Connect';
		Set<Id> convertedAccountIds = new Set<Id>();
		Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id FROM Lead LIMIT 50]);
		List<Task> outboundCalls = TestUtility.Task_OutboundCall(null, leadMap.keyset(), 'Scheduled', -3);
		insert outboundCalls;
		List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
		for (Lead l : leadMap.values()) {
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(l.Id);
			lc.setConvertedStatus(ConvertedLeadStatus);
			lcs.add(lc);
		}
		Test.startTest();
		Database.LeadConvertResult[] lcrs = Database.ConvertLead(lcs, false);
		Test.stopTest();
		for (Database.LeadConvertResult lcr : lcrs) {
			System.assert(lcr.isSuccess(), 'Lead should have been converted successfully.');
			convertedAccountIds.add(lcr.getAccountId());
		}
		List<Account> convertedAccounts = [SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :convertedAccountIds];
		for (Account a : convertedAccounts) {
			System.assertEquals(null, a.Response_Date_Time__c, 'Account\'s Response_Date_Time__c should be null.');
		}
		Map<Id, Task> outboundCallsMap = new Map<Id, Task>(outboundCalls);
		List<Task> tasksToUpdate = [SELECT Id, Status, IsClosed, AccountId, Who.Type, CreatedDate FROM Task WHERE Id IN :outboundCallsMap.keySet()];
		for (Task t : tasksToUpdate) {
			System.assert(!t.IsClosed, 'Tast should not be closed.');
			System.assertEquals('Contact', t.Who.Type, 'Task\'s Who should refer to Contact record.');
			t.Status = 'Connect';
		}
		update tasksToUpdate;
		List<Task> updatedTasks = [SELECT Id, IsClosed, Account.Response_Date_Time__c, CreatedDate FROM Task WHERE Id IN :outboundCallsMap.keySet()];
		for (Task t : updatedTasks) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
	}

	@isTest
	static void TriggerTask_OutboundCallLeadConversion_B() {
		LeadTriggerHelper.skipTrigger = true;
		TaskTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		final String tskStatus = 'Connect';
		Set<Id> convertedAccountIds = new Set<Id>();
		Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id FROM Lead LIMIT 50]);
		List<Task> outboundCalls = TestUtility.Task_OutboundCall(null, leadMap.keyset(), tskStatus, -1);
		insert outboundCalls;
		List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
		for (Lead l : leadMap.values()) {
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(l.Id);
			lc.setConvertedStatus(ConvertedLeadStatus);
			lcs.add(lc);
		}
		Test.startTest();
		Database.LeadConvertResult[] lcrs = Database.ConvertLead(lcs, false);
		Test.stopTest();
		for (Database.LeadConvertResult lcr : lcrs) {
			System.assert(lcr.isSuccess(), 'Lead should have been converted successfully.');
			convertedAccountIds.add(lcr.getAccountId());
		}
		Map<Id, Task> outboundCallsMap = new Map<Id, Task>(outboundCalls);
		List<Task> tasksAfterConversion = [SELECT Id, IsClosed, Account.Response_Date_Time__c, CreatedDate FROM Task WHERE Id IN :outboundCallsMap.keySet()];
		for (Task t : tasksAfterConversion) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
	}

	@isTest
	static void TriggerTask_OutboundCallLeadConversion_C() {
		LeadTriggerHelper.skipTrigger = true;
		TaskTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		final String tskStatus = 'Connect';
		Set<Id> convertedAccountIds = new Set<Id>();
		Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id FROM Lead LIMIT 50]);
		List<Task> outboundCalls = TestUtility.Task_OutboundCall(null, leadMap.keyset(), 'Scheduled', -3);
		insert outboundCalls;
		List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
		for (Lead l : leadMap.values()) {
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(l.Id);
			lc.setConvertedStatus(ConvertedLeadStatus);
			lcs.add(lc);
		}
		Test.startTest();
		Database.LeadConvertResult[] lcrs = Database.ConvertLead(lcs, false);
		Test.stopTest();
		for (Database.LeadConvertResult lcr : lcrs) {
			System.assert(lcr.isSuccess(), 'Lead should have been converted successfully.');
			convertedAccountIds.add(lcr.getAccountId());
		}
		List<Account> convertedAccounts = [SELECT Id, Response_Date_Time__c FROM Account WHERE Id IN :convertedAccountIds];
		for (Account a : convertedAccounts) {
			System.assertEquals(null, a.Response_Date_Time__c, 'Account\'s Response_Date_Time__c should be null.');
		}
		List<Task> outboundCalls2 = TestUtility.Task_OutboundCall(convertedAccountIds, null, tskStatus, -3);
		insert outboundCalls2;
		Map<Id, Task> outboundCalls2Map = new Map<Id, Task>(outboundCalls2);
		List<Task> insertedTasks = [SELECT Id, IsClosed, Account.Response_Date_Time__c, CreatedDate FROM Task WHERE AccountId IN :outboundCalls2Map.keySet()];
		for (Task t : insertedTasks) {
			System.assert(t.IsClosed, 'Tast should be closed.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
	}

	@isTest
	static void TriggerTask_OutboundCallLeadConversion_D() {
		AccountTriggerHelper.skipTrigger = true;
		final String tskStatus = 'Connect';
		Set<Id> convertedAccountIds = new Set<Id>();
		Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id FROM Lead LIMIT 50]);
		List<Task> outboundCalls1 = TestUtility.Task_OutboundCall(null, leadMap.keyset(), tskStatus, -5);
		insert outboundCalls1;
		List<Task> outboundCalls2 = TestUtility.Task_OutboundCall(null, leadMap.keyset(), tskStatus, -4);
		insert outboundCalls2;
		List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
		for (Lead l : leadMap.values()) {
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(l.Id);
			lc.setConvertedStatus(ConvertedLeadStatus);
			lcs.add(lc);
		}
		Test.startTest();
		Database.LeadConvertResult[] lcrs = Database.ConvertLead(lcs, false);
		Test.stopTest();
		for (Database.LeadConvertResult lcr : lcrs) {
			System.assert(lcr.isSuccess(), 'Lead should have been converted successfully.');
			convertedAccountIds.add(lcr.getAccountId());
		}
		Map<Id, Task> outboundCall1Map = new Map<Id, Task>(outboundCalls1);
		List<Task> outboundCalls1AfterConversion = [SELECT Id, IsClosed, Account.Response_Date_Time__c, CreatedDate FROM Task WHERE Id IN :outboundCall1Map.keyset()];
		for (Task t : outboundCalls1AfterConversion) {
			System.assert(t.IsClosed, 'Task should be closed.');
			System.assertEquals(t.CreatedDate, t.Account.Response_Date_Time__c, 'Response_Date_Time__c on Task\'s account should match the CreatedDate on task.');
		}
	}

	private static List<Account> createAccountsList() {
		List<Account> list_Accounts = new List<Account>();
		for (Integer i = 0; i < NumberOfAccounts; i++) {
			list_Accounts.add(new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build());
		}
		return list_Accounts;
	}
}