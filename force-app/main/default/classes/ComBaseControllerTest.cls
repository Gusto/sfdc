/**
 * @name         : ComBaseControllerTest
 * @author       : Nigam Goyal
 * @date         : 06-30-2022
 * @description  : Cover test Coverage ComBaseControllerTest c
 **/
@isTest
public with sharing class ComBaseControllerTest {
	@isTest
	static void createErrorLogTest() {
		ComBaseController.createErrorLog('errormsg', 'componentName', 'methodname');
		List<Exception_Log__c> list_ExceptionLogs = [SELECT Id FROM Exception_Log__c WHERE Method_Name__c = 'methodname'];
		System.assert(list_ExceptionLogs.size() > 0, 'Exception_Log__c not created');
	}

	@isTest
	static void getSObjectNamePostiveTest() {
		Account objAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		insert objAccnt;
		ComBaseController.getSObjectName(objAccnt.Id);
	}

	@isTest
	static void getSObjectNameNeagtiveTest() {
		try {
			ComBaseController.getSObjectName('test');
		} catch (Exception ex) {
		}
	}
}