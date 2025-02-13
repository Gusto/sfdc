/**
 * @author       Sanjay Paryani - Updated by Prity Kumari
 * @date         12/17/2019
 * @description  Test class for ExceptionLogUtil
 * @see          ExceptionLogUtil
 **/
@isTest
public class ExceptionLogUtilTest {
	/**
	 * @author David Schach
	 * @description Test passing in just exception, then parsing
	 */
	@isTest
	static void logExceptionTest() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Test.startTest();
		try {
			Account acc = new Account(Name = '');
			insert acc;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ExceptionLogUtilTest', 'logExceptionTest', ex.getMessage(), ex.getStackTraceString());
		}
		System.assertEquals(1, [SELECT COUNT() FROM Exception_Log__c], 'Errors dont match');

		try {
			Account acc = new Account(Name = '');
			insert acc;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ExceptionLogUtilTest', 'logExceptionTest', null, ex);
			ExceptionLogUtil.logException('ExceptionLogUtilTest', 'logExceptionTest', ex);
		}

		Test.stopTest();
		//assertion changed since there should be two errors due to two accounts failing - Prity K
		// updated due to two logs created on second attempt - David S
		System.assertEquals(3, [SELECT COUNT() FROM Exception_Log__c], 'Errors dont match');
	}

	/**
	 * @author Prity Kumari
	 * @description Test method used for logging exception from a try/catch, where additional information is available, such as Stack Trace, Line Number, etc.
	 */
	@isTest
	static void logExceptionTestWithAdditionalParameters() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Test.startTest();
		Account acc = new Account();
		try {
			acc = new Account(Name = '');
			insert acc;
		} catch (Exception ex) {
			List<String> listExceptionString = new List<String>();
			listExceptionString.add(ex.getMessage());
			listExceptionString.add(ex.getStackTraceString());
			listExceptionString.add(ex.getTypeName());
			ExceptionLogUtil.logException(
				Id.valueOf(System.UserInfo.getUserId()),
				acc.Id,
				'ExceptionLogUtilTest',
				'logExceptionTest',
				listExceptionString,
				ex.getLineNumber(),
				ex.getMessage(),
				'Test'
			);
		}
		System.assertEquals(1, [SELECT COUNT() FROM Exception_Log__c], 'Errors dont match');
	}

	/**
	 * @author          Sanjay Paryani
	 * @description    Test method used for logging exception from a try/catch, where additional information is available, such as Stack Trace, Line Number, etc.
	 */
	@isTest
	static void logExceptionTestWithDBAdditionalParameters() {
		List<Account> insertSobjList = new List<Account>();
		TriggerHandler.bypass('AccountTriggerHandler');
		Test.startTest();
		Account acc = new Account(Name = '');
		insertSobjList.add(acc);
		//insert list of records given using Database.insert
		Database.SaveResult[] listSaveResult = Database.insert(insertSobjList, false);
		String[] strErrorList = new String[0];

		//Iterate thru SaveResult list
		for (Integer i = 0; i < listSaveResult.size(); i++) {
			//validate whether record is created successfully or not, if not add all error msgs to an error list
			if (!listSaveResult[i].success) {
				for (Database.Error e : listSaveResult[i].errors) {
					strErrorList.add('ID: ' + insertSobjList.get(i) + ' |  ERROR: ' + e.getStatusCode() + ': ' + e.getMessage());
				}
			}
		}

		//Validate error list and logException flag to create exception log
		if (!strErrorList.isEmpty()) {
			//Invoke logException method from ExceptionLogUtil class to create exception log record
			ExceptionLogUtil.logException(UserInfo.getUserId(), 'ExceptionLogUtilTest', 'logExceptionTestWithAdditionalParameters', strErrorList, 'High');
		}

		Test.stopTest();
		System.assertEquals(1, [SELECT COUNT() FROM Exception_Log__c], 'Errors dont match');
	}

	/**
	 * @author         Sanjay Paryani
	 * @description    Test method used for logging exception using Database.Error, where return details are simplified.
	 */
	@isTest
	static void testExceptionLoggingDatabaseError() {
		TriggerHandler.bypass('ContactTriggerHandler');
		Test.startTest();
		List<Contact> listContacts = new List<Contact>();
		listContacts.add(new Contact(FirstName = 'Test1'));
		List<Exception> listException = new List<Exception>();
		try {
			insert listContacts;
		} catch (Exception e) {
			listException.add(e);
		}
		ExceptionLogUtil.logException('Error', 'ExceptionLogUtil', 'testExceptionLogging', listException);
		Test.stopTest();
		System.assertEquals(1, [SELECT COUNT() FROM Exception_Log__c], 'Errors dont match');
	}

	/**
	 * @author         Prity Kumari
	 * @description    Test Exception Logging with Id
	 */
	@isTest
	static void testExceptionLoggingWithId() {
		TriggerHandler.bypass('AccountTriggerHandler');
		Test.startTest();
		List<Account> listAccounts = new List<Account>();
		Set<String> setRecordIds = new Set<String>();
		Account objResellerAcc = new TestDataFactory.AccountBuilder().setName('').setZPCompanyId('1234').build();
		setRecordIds.add(String.valueOf(objResellerAcc.ZP_Company_Id__c));
		listAccounts.add(objResellerAcc);
		//insert list of records given using Database.insert
		Database.SaveResult[] listSaveResult = Database.insert(listAccounts, false);

		for (Integer i = 0; i < listSaveResult.size(); i++) {
			//validate whether record is created successfully or not, if not add all error msgs to an error list
			if (!listSaveResult[i].success) {
				for (Database.Error e : listSaveResult[i].errors) {
					ExceptionLogUtil.logExceptionWithId('ExceptionLogUtilTest', 'logExceptionWithId', e.getMessage(), null, setRecordIds);
				}
			}
		}
		Test.stopTest();
		System.assertEquals(1, [SELECT COUNT() FROM Exception_Log__c], 'Errors dont match');
	}
}