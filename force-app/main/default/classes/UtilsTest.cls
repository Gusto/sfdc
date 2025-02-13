/**
 * @name         : UtilsTest
 * @description  : Test methods for Utils
 **/
@isTest
private without sharing class UtilsTest {
	//set bulk count to 50 in sandbox but reduce in produce to speed up testing
	static Integer bulkCount {
		get {
			if (bulkCount == null) {
				if (OrganizationUtilities.isProduction()) {
					bulkCount = 10;
				} else {
					bulkCount = 50;
				}
			}
			return bulkCount;
		}
		set;
	}

	/**
	 * @description Temporary method until it can be verified that Utils.SkipTrigger is no longer needed
	 * @author David Schach
	 */
	@isTest
	static void tempTestSkipTrigger() {
		Test.startTest();
		//TODO: Delete this if CaseTriggerHandler/HelperTest no longer references it
		Utils.skipTrigger(true);
		Test.stopTest();
	}

	@isTest
	static void basic_code_coverage() {
		Lead l = new Lead(); // missing fields so we get some database errors
		Database.SaveResult[] results = Database.insert(new List<Lead>{ l }, false);
		String errorsString = Utils.ConsolidateErrors(results[0].getErrors());
		System.assert(String.isNotBlank(errorsString), 'errorsString should not be blank.');

		// Included just for coverage - need to move the method to a better location
		Utils.queryCaseTeamRoles('Customer Contact');
	}

	@isTest
	static void insert_and_log_sobject() {
		Account acc = createAccountsList(1)[0];
		Utils.insertAndLog(acc, true);
		System.assertNotEquals(null, acc.Id, 'Account Id should not be null.');
		List<Account> accounts = [SELECT Id FROM Account];
		System.assertEquals(1, accounts.size(), 'There should be 1 account.');
	}

	@isTest
	static void insert_and_log_sobjects() {
		List<Account> accounts = createAccountsList(5);
		Utils.insertAndLog(accounts, true);
		accounts = [SELECT Id FROM Account];
		System.assertEquals(5, accounts.size(), 'There should be 5 accounts.');
	}

	@isTest
	static void update_and_log_sobjects() {
		List<Account> accounts = createAccountsList(5);
		Utils.insertAndLog(accounts, true);
		accounts = [SELECT Id FROM Account];
		System.assertEquals(5, accounts.size(), 'There should be 5 accounts.');
		Utils.updateAndLog(accounts, false);
		Utils.updateAndLog(accounts[0], false);
		System.assertEquals(5, accounts.size(), 'There should be 5 accounts.');
	}

	@isTest
	static void testdoDMLAndReturnAllErrors() {
		User adminUser = new TestDataFactory.UserBuilder()
			.setUserName('mdruser@testorg.com')
			.setEmail('mdruser@testorg.com')
			.setProfileId([SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'].Id)
			.build();
		insert adminUser;
		System.assertNotEquals(null, adminUser.Id, 'User Id should not be null.');

		System.runAs(adminUser) {
			Test.startTest();

			List<Account> accounts = createAccountsList(5);
			Map<String, String> errorMap = new Map<String, String>();

			errorMap = Utils.doDMLAndReturnAllErrors('Insert', 'Id', accounts, false, true, 'UtilsTest-testdoDMLAndReturnAllErrors');
			System.assertEquals(0, errorMap.size(), 'errorMap size should be 0.');

			// call update method and assert
			errorMap = Utils.doDMLAndReturnAllErrors('Update', 'Id', accounts, false, true, 'UtilsTest-testdoDMLAndReturnAllErrors');
			System.assertEquals(0, errorMap.size(), 'errorMap size should be 0.');

			// reproduce an error by hitting a validation rule
			for (Account ac : accounts) {
				ac.EE_Active_Count_Panda__c = 1;
			}
			errorMap = Utils.doDMLAndReturnAllErrors('Upsert', 'Id', accounts, false, true, 'UtilsTest-testdoDMLAndReturnAllErrors');
			System.assertEquals(5, errorMap.size(), 'errorMap size should be 5.');

			// call delete method and assert
			errorMap = Utils.doDMLAndReturnAllErrors('Delete', 'Id', accounts, false, true, 'UtilsTest-testdoDMLAndReturnAllErrors');
			System.assert(errorMap.keySet().size() >= 0, 'There should be 0 or more than 0 entries in errorMap.');

			Test.stopTest();
		}
	}

	@isTest
	static void humanize_string_test() {
		Map<String, String> humanizedValueMap = new Map<String, String>{
			null => null,
			'first and last' => 'First and Last',
			'of either before' => 'Of Either Before',
			'UPPER CASE' => 'Upper Case',
			'sWAP cASE' => 'Swap Case',
			'Perfectly Titlized' => 'Perfectly Titlized',
			'Both 43524534 AND words Are importANT' => 'Both 43524534 and Words Are Important',
			'!@#$%^&*() DONT FORGET THE Symbols' => '!@#$%^&*() Dont Forget the Symbols'
		};

		for (String stringValue : humanizedValueMap.keySet()) {
			System.assertEquals(humanizedValueMap.get(stringValue), Utils.humanize(stringValue), 'Humanize string should match.');
		}

		String fieldNameString = Utils.getFieldAPINameString('Account');
		Utils.getProfileNameMap();
	}

	@isTest
	static void testGetSObjectDescribe() {
		String ObjectName = 'Account';
		Schema.DescribeSObjectResult sobject_describe = Schema.getGlobalDescribe().get(ObjectName).getDescribe();
		Schema.DescribeSObjectResult sobject_describe_Util = Utils.getSObjectDescribe(ObjectName);
		System.assertEquals (sobject_describe.getLabel(),sobject_describe_Util.getLabel(),'Logic is Not valid');
	}

	@isTest
	static void testStateCode() {
		String stateCd = Utils.getStateCode('Alabama');
		System.assertEquals('AL', stateCd, 'State code should match.');
		System.assertEquals('', Utils.getStateCode('NotAState'), 'State code should match.');

		ZP_Sales_Tax_Jurisdictions__c taxInfo = new ZP_Sales_Tax_Jurisdictions__c();
		taxInfo.State__c = 'AL';
		taxInfo.Effective_From__c = System.today() - 1;
		insert taxInfo;
		Utils.setStateTaxMap();
	}

	@isTest
	static void testTimeZoneFields() {
		Integer result = Utils.getTimezoneOffset();
		BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
		DateTime dtOldDateTime = System.now().addDays(-2);
		DateTime dtNewDateTime = System.now();

		System.assertEquals(0, Utils.businessHours(null, dtOldDateTime, dtNewDateTime), 'Business hours should be 0.');
		System.assertEquals(0, Utils.businessMinutes(null, dtOldDateTime, dtNewDateTime), 'Business hours should be 0.');

		if (BusinessHours.isWithin(bh.Id, dtOldDateTime) && BusinessHours.isWithin(bh.Id, dtNewDateTime)) {
			System.assertNotEquals(0, Utils.businessHours(bh.Id, dtOldDateTime, dtNewDateTime), 'Business hours should be 0.');
			System.assertNotEquals(0, Utils.businessMinutes(bh.Id, dtOldDateTime, dtNewDateTime), 'Business hours should be 0.');
		}
	}

	@isTest
	static void testFuturetriggerCaseAssignmentRule() {
		Test.startTest();
		List<Id> list_UserId = new List<Id>();
		list_UserId.add(UserInfo.getUserId());
		Utils.futuretriggerCaseAssignmentRule(list_UserId);
		Test.stopTest();
	}

	@isTest
	static void testgetRolesSet() {
		Test.startTest();
		Utils.getRolesSet('test', 'test');
		Test.stopTest();
	}

	@isTest
	static void testgetStrArrayToString() {
		Test.startTest();
		Utils.getStrArrayToString('["a","a"]', ';');
		Test.stopTest();
	}

	@isTest
	static void testDayMethods() {
		Test.startTest();
		Utils.isWeekendDay(System.today());
		Utils.getBusinessDayFromDate(System.today(), 1);
		Utils.getNextBusinessDay();
		Test.stopTest();
	}

	@isTest
	static void testProcessSaveRecords() {
		Test.startTest();
		List<Account> list_AccountsToBeInserted = new List<Account>();
		Account objAcc = new Account();
		list_AccountsToBeInserted.add(objAcc);
		Map<String, String> map_AccountInsertErrors = new Map<String, String>();
		List<Database.SaveResult> list_SaveResults = Database.insert(list_AccountsToBeInserted, false);
		map_AccountInsertErrors = Utils.processSaveRecords(list_SaveResults, list_AccountsToBeInserted, 'Id', true, 'UtilsTest', 'testProcessSaveRecords');
		Test.stopTest();

		System.assert([SELECT Count(Id) FROM Exception_Log__c].size() > 0, 'There should be more than 0 Exception logs.');
	}

	@isTest
	static void testProcessUpsertRecords() {
		Test.startTest();
		List<Account> list_AccountsToBeUpserted = new List<Account>();
		Account objAcc1 = TestUtility.CompanyAccount();
		Account objAcc2 = TestUtility.CompanyAccount();
		objAcc1.ZP_Company_ID__c = '1234';
		objAcc2.ZP_Company_ID__c = '1234';
		list_AccountsToBeUpserted.add(objAcc1);
		list_AccountsToBeUpserted.add(objAcc2);

		Map<String, String> map_AccountUpsertErrors = new Map<String, String>();
		List<Database.UpsertResult> list_UpsertResults = Database.upsert(list_AccountsToBeUpserted, false);
		map_AccountUpsertErrors = Utils.processUpsertRecords(list_UpsertResults, list_AccountsToBeUpserted, 'Id', true, 'UtilsTest', 'testProcessUpsertRecords');
		Test.stopTest();

		System.assert([SELECT Count(Id) FROM Exception_Log__c].size() > 0, 'There should be more than 0 Exception logs.');
	}

	@IsTest
	static void insertAndLogTest() {
		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		System.runAs(thisUser) {
			Account objAccount = createAccountsList(1)[0];
			Test.startTest();
			Utils.insertAndLog(objAccount, true);
			objAccount.name = 'TestName';
			Utils.updateAndLog(objAccount, true);
			Test.stopTest();
		}

		System.assertEquals(1, [SELECT COUNT() FROM Account], 'There should be 1 account.');
	}

	@IsTest
	static void insertAndLogTestError() {
		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		System.runAs(thisUser) {
			Account objAccount = createAccountsList(1)[0];
			objAccount.name = '';
			Test.startTest();
			Utils.insertAndLog(objAccount, false);
			objAccount.name = 'TestName';
			Utils.insertAndLog(objAccount, false);
			objAccount.name = '';
			Utils.updateAndLog(objAccount, false);
			Test.stopTest();
		}
	}

	@IsTest
	static void testTimestampDiffs() {
		DateTime startTime = System.now();
		DateTime endTime = System.now().addDays(1).addMinutes(1);
		Test.startTest();
		Utils.getTimeStampDiff(startTime, endTime, 'Days');
		Utils.getTimeStampDiff(startTime, endTime, 'Hours');
		Utils.getTimeStampDiff(startTime, endTime, 'Minutes');
		Utils.getTimeStampDiff(startTime, endTime, 'Seconds');
		Utils.getTimeStampDiff(startTime, endTime, 'Milliseconds');
		Test.stopTest();
	}

	@isTest
	static void testTabAccessAndGroupMembership() {
		Group objGroup = [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName = 'AllInternalUsers' LIMIT 1];

		Test.startTest();
		User objUserThisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		System.runAs(objUserThisUser) {
			Utils.checkTabAccessGeneric(objGroup.DeveloperName);
			Set<Id> set_groupIDs = new Set<Id>();
			for (Group gr : [SELECT Id FROM Group LIMIT 10]) {
				set_groupIDs.add(gr.Id);
			}
			Utils.getGroupsForIds(set_groupIDs);
		}
		Utils.checkTabAccessGeneric(Utils.ENGAGEMENT_CASE_ROUTING_GROUP);
		Test.stopTest();
	}

	/**
	 * @author        Neha Dabas
	 * @description    Unit test for addOrSubtractBusinessHoursToDate()
	 */
	@isTest
	static void testAddOrSubtractBusinessHoursToDate() {
		Test.startTest();
		DateTime dtCalculatedTimestamp = Utils.addOrSubtractBusinessHoursToDate(System.now(), 24);

		System.assert(dtCalculatedTimestamp.date() > System.today(), 'Calculated Timestamp date should be in future.');
		Test.stopTest();
	}

	/**
	 * @author		Ajay Krishna P U
	 * @description Test Add Business Days
	 */
	@isTest
	static void testAddBusinessDays() {
		Date dtBeforeHoliday = Date.newInstance(2019, 12, 24);
		Date dtAfterHoliday = Utils.addBusinessDays(dtBeforeHoliday, 1);
		System.assert(dtBeforeHoliday.daysBetween(dtAfterHoliday) > 1, 'Holiday calculation failed.');

		Date dtBeforeWeekend = Date.newInstance(2023, 1, 20); //Friday
		Date dtAfterWeekend = Utils.addBusinessDays(dtBeforeWeekend, 1);
		System.assert(dtBeforeWeekend.daysBetween(dtAfterWeekend) > 1, 'Weekend calculation failed.');
	}

	/**
	 * @description Included to increase the code coverage
	 */
	@isTest
	static void testMethods() {
		Utils.getState('AL');
		Utils.checkifStateCodeisPresent(new Set<String>{ 'AL' }, 'Alabama');

		Test.startTest();
		Utils.triggerCaseAssignmentRule(new List<Id>());
		Utils.sendEmail('testTo@gusto.com', 'Test Gusto', 'Test mail', 'Testing..');
		Utils.getCarrierVersion(new Map<String, Date>());
		Test.stopTest();

		System.assert(Utils.getRandomIntValue(5).length() >= 5, 'RandomInt failed');
		System.assert(Utils.generateRandomFromRange(5, 10) >= 5, 'generateRandomFromRange failed');
	}

	/**
	 * @description Test Add value to a Multipicklist
	 */
	@isTest
	static void testAddToMultiPicklist() {
		String strResult = Utils.addToMultiPicklistValue(null, null);
		System.assert(null == strResult, 'Failed for (original = null, add = null)');

		strResult = Utils.addToMultiPicklistValue('', '');
		System.assert(null == strResult, 'Failed for (original = "", add = "")');

		strResult = Utils.addToMultiPicklistValue(null, 'Add_Val');
		System.assert('Add_Val' == strResult, 'Failed for (original = null, add = Add_Val)');

		strResult = Utils.addToMultiPicklistValue('Org_Val', null);
		System.assert('Org_Val' == strResult, 'Failed for (original = Org_Val, add = null)');

		strResult = Utils.addToMultiPicklistValue('Org_Val', 'Add_Val');
		System.assert('Org_Val;Add_Val' == strResult || 'Add_Val;Org_Val' == strResult, 'Failed for (original = Org_Val, add = Add_Val)');
	}

	/**
	 * @description Test Convert to Null If Blank
	 */
	@isTest
	static void testToNullIfBlank() {
		String strResult = Utils.toNullIfBlank(null);
		System.assert(null == strResult, 'Failed for value = null');

		strResult = Utils.toNullIfBlank('');
		System.assert(null == strResult, 'Failed for value = "" ');

		strResult = Utils.toNullIfBlank('Data');
		System.assert('Data' == strResult, 'Failed for value = Data');
	}

	/**
	 * @description Test Multi pick list Contains
	 */
	@isTest
	static void testIsMultiPicklistContains() {
		Boolean blnResult = Utils.isMultiPicklistContains(null, 'Val');
		System.assert(false == blnResult, 'Failed for (picklist = null, value = Val)');

		blnResult = Utils.isMultiPicklistContains('', 'Val');
		System.assert(false == blnResult, 'Failed for (picklist = "", value = Val)');

		blnResult = Utils.isMultiPicklistContains('Abc;Bcd', '');
		System.assert(false == blnResult, 'Failed for (picklist = Abc;Bcd, value =	"")');

		blnResult = Utils.isMultiPicklistContains('Abc;Bcd', null);
		System.assert(false == blnResult, 'Failed for (picklist = Abc;Bcd, value = null)');

		blnResult = Utils.isMultiPicklistContains('Abc;Bcd', 'Val');
		System.assert(false == blnResult, 'Failed for (picklist = Abc;Bcd, value = Val)');

		blnResult = Utils.isMultiPicklistContains('Val', 'Val');
		System.assert(true == blnResult, 'Failed for (picklist = Val, value = Val)');

		blnResult = Utils.isMultiPicklistContains('Val;Val2;Abc', 'Val');
		System.assert(true == blnResult, 'Failed for (picklist = Val;Val2;Abc, value = Val)');

		blnResult = Utils.isMultiPicklistContains('xyZ;Abc;Bcd;Efg', 'aBc');
		System.assert(true == blnResult, 'Failed for (picklist = xyZ;Abc;Bcd;Efg, value = aBc)');

		blnResult = Utils.isMultiPicklistContains('xyZ;Abc;Bcd;Efg', 'Abcd');
		System.assert(false == blnResult, 'Failed for (picklist = xyZ;Abc;Bcd;Efg, value= Abcd)');

		blnResult = Utils.isMultiPicklistContains('xyZ;Abcd;Bcd;Efg', 'Abc');
		System.assert(false == blnResult, 'Failed for (picklist = xyZ;Abcd;Bcd;Efg, value= Abc)');
	}

	private static List<Account> createAccountsList(Integer intNumberOfAccounts) {
		List<Account> list_Accounts = new List<Account>();
		for (Integer i = 0; i < intNumberOfAccounts; i++) {
			list_Accounts.add(new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build());
		}
		return list_Accounts;
	}

	/**
	* @Author      : Bhagat Singh
	* @Description : Test method to get carrier Infomation
	**/
	@isTest
	static void validateCarrierInfo() {
		Test.startTest();
		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		list_Carriers.add(new TestDataFactory.CarrierBuilder()
			.setName(CaseUtils.CARRIER_FLORIDA_BLUE)
			.setUniqueName(CaseUtils.CARRIER_FLORIDA_BLUE)
			.setState('CA')
			.setCarrierId('112')
			.setTerminationEffectiveDate('End of Month')
			.build());
		list_Carriers.add(new TestDataFactory.CarrierBuilder()
			.setName('alegeus')
			.setUniqueName('alegeus')
			.setState('CA')
			.setCarrierId('112')
			.setTerminationEffectiveDate('End of Month')
			.setPartnerType('TAdA')
			.build());
		insert list_Carriers;

		Map<Id, Carrier__c> map_Carrier = Utils.getCarrierInfo(new Set<Id>{list_Carriers[0].Id});

		Test.stopTest();
		System.assertEquals(CaseUtils.CARRIER_FLORIDA_BLUE, map_Carrier.get(list_Carriers[0].Id).Name, 'Florida Blue carrier does not exist.');
		System.assert(Utils.set_TAdACarrierIds.contains(list_Carriers[1].Id), 'TAdA Carrier Not exist.');
	}
}