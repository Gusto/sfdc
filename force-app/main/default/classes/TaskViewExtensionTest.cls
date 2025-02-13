@istest
public class TaskViewExtensionTest {
	private static testMethod void testTaskView() {
		Account acc = TestUtility.CompanyAccount();
		acc.ZP_Company_ID__c = '1111111111';
		update acc;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		insert cse;

		Task tsk = new Task();
		tsk.WhatId = cse.Id;
		insert tsk;

		Test.startTest();
		ApexPages.currentPage().getParameters().put('id', tsk.id);
		ApexPages.StandardController stdCase = new ApexPages.StandardController(tsk);
		TaskViewExtension extension = new TaskViewExtension(stdCase);

		Test.stopTest();
	}
}