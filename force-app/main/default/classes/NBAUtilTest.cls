/**
 * @description  Test class for validating commonly used NBA functions
 * @author       Praveen Sethu
 * @date         10-15-2023
 **/
@isTest
public without sharing class NBAUtilTest {
	/**
	 * @author      Praveen Sethu
	 * @description Test replacing business days function
	 **/
	@isTest
	static void testReplacingBusinessDays() {
		String strInputQuery = 'SELECT Id FROM Opportunity WHERE CreatedDate > ' + NBAUtil.N_BUSINESS_DAYS_AGO + ':20';
		Test.startTest();
		String strReplacedQuery = NBAUtil.replaceCustomFunctions(strInputQuery);
		Test.stopTest();

		System.assertEquals(true, !strReplacedQuery.contains(NBAUtil.N_BUSINESS_DAYS_AGO), 'N Business days ago not replaced correctly');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method is used to replacing business days future function
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testReplacingBusinessDaysForAdd() {
		String strInputQuery = 'SELECT Id FROM Opportunity WHERE CreatedDate > ' + NBAUtil.N_BUSINESS_DAYS_FUTURE + ':20';
		Test.startTest();
		String strReplacedQuery = NBAUtil.convertCustomFunctionsToSOQL(strInputQuery);
		Test.stopTest();

		System.assertEquals(true, !strReplacedQuery.contains(NBAUtil.N_BUSINESS_DAYS_FUTURE), 'N Business days future not replaced correctly');
	}

	/**
	 * @author       Omar Benitez
	 * @description  This method is used to replacing business days future date function
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testReplacingBusinessDaysDateForAdd() {
		String strInputQuery = 'SELECT Id FROM Opportunity WHERE Renewal_Date__c  > ' + NBAUtil.N_D_BUSINESS_DAYS_FUTURE + ':20';
		Test.startTest();
		String strReplacedQuery = NBAUtil.convertCustomFunctionsToSOQL(strInputQuery);
		Test.stopTest();
		System.assertEquals(true, !strReplacedQuery.contains(NBAUtil.N_D_BUSINESS_DAYS_FUTURE), 'N D Business days future not replaced correctly');
	}

	/**
	 * @author       Omar Benitez
	 * @description  This method is used to replacing business days ago date function
	 * @param        null
	 * @return       null
	 **/
	@isTest
	static void testReplacingBusinessDaysDate() {
		String strInputQuery = 'SELECT Id FROM Opportunity WHERE Renewal_Date__c  > ' + NBAUtil.N_BUSINESS_DAYS_AGO + ':20';
		Test.startTest();
		String strReplacedQuery = NBAUtil.convertCustomFunctionsToSOQL(strInputQuery);
		Test.stopTest();
		System.assertEquals(true, !strReplacedQuery.contains(NBAUtil.N_BUSINESS_DAYS_AGO), 'N D Business days ago not replaced correctly');
	}
}