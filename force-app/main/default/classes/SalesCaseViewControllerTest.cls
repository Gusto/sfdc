@isTest
public with sharing class SalesCaseViewControllerTest {
	@testSetup
	static void setUp() {
		TriggerHandler.bypass('AccountTriggerHandler');
		CaseTriggerHelper.skipTrigger = true;

		Account objAcc = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('TEST ACCOUNT')
			.setZPCompanyId('1111111111')
			.setJoinedDate(System.today())
			.build();
		insert objAcc;

		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAcc.Id)
			.setSubject('Test')
			.setDescription('Test')
			.setType('Payroll Care')
			.build();
		insert objCase;
		Test.stopTest();
	}

	@isTest
	static void testDoRoutingTaxRes() {
		Case objCase = new Case();
		List<Case> list_Cases = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c FROM Case WHERE Type = 'Payroll Care'];
		if (list_Cases.size() > 0) {
			objCase = list_Cases.get(0);
		}
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		SalesCaseViewController.doRouting(objCase.Id, 'Benefits New Plan Case');
        SalesCaseViewController.doRouting(objCase.Id, 'Benefits Renewal Case');
		SalesCaseViewController.doRouting(objCase.Id, 'Tax Res');
		Test.stopTest();
		List<Case> list_CasesUpdated = [SELECT Id, CaseNumber, RecordType.Name FROM Case WHERE Id = :objCase.Id];
		System.assertEquals('Tax Res', list_CasesUpdated[0].RecordType.Name);
	}

	@isTest
	static void testDoRoutingRoute() {
		Case objCase = new Case();
		List<Case> list_Cases = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c FROM Case WHERE Type = 'Payroll Care'];
		if (list_Cases.size() > 0) {
			objCase = list_Cases.get(0);
		}
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		SalesCaseViewController.doRouting(objCase.Id, 'Benefits Care');
		SalesCaseViewController.doRouting(objCase.Id, 'Payroll Care');
		SalesCaseViewController.doRouting(objCase.Id, 'Payroll Audit');
		SalesCaseViewController.doRouting(objCase.Id, 'Benefits BoR');
		SalesCaseViewController.doRouting(objCase.Id, 'Tax Ops');
		SalesCaseViewController.doRouting(objCase.Id, 'Modern Bank');
		Test.stopTest();
		List<Case> list_CasesUpdated = [SELECT Id, CaseNumber, RecordType.Name FROM Case WHERE Id = :objCase.Id];
		System.assertEquals('Modern Bank', list_CasesUpdated[0].RecordType.Name);
	}

	@isTest
	static void testExceptionInController() {
		SalesCaseViewController.blnTestException = true;
		CaseTriggerHelper.skipTrigger = true;
		Case objCase = new Case();
		List<Case> list_Cases = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c FROM Case WHERE Type = 'Payroll Care'];
		if (list_Cases.size() > 0) {
			objCase = list_Cases.get(0);
		}
		Test.startTest();
		SalesCaseViewController.doRouting(objCase.Id, 'Benefits New Plan Case');
		Test.stopTest();

		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'SalesCaseViewController'];
		System.assertNotEquals(0, list_Exceptions.size());
	}
}