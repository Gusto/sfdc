/********************************************************************
 * Info : PTForecastCreationAssignmentExtTest is used to cover PTForecastCreationAssignmentExtension
 *        which is related with 'Payroll Transfer FBOS Forecast', User, User Skill, Skill, Role etc.
 *        and Bulk Migration Request Objects.
 *
 * Created by : Lirik on 10/10/2019
 ***********************************************************************/

@isTest
public class PTForecastCreationAssignmentExtTest {
	// define variables to use in class
	public static User adminUser;
	public static User mktUser;
	public static User_Skill__c userSkillObj;

	static {
		createTestData();
	}

	// create setup data
	static void createTestData() {
		adminUser = new TestDataFactory.UserBuilder()
			.setEmail('test@testorg.com')
			.setFirstName('Test')
			.setLastName('User')
			.setProfileId(TestDataFactory.objZPSysAdminProfile.Id)
			.setUserName('test.user@gustotestorg.com')
			.setExemptfromValidationRules(true)
			.build();
		insert adminUser;
		System.assertNotEquals(null, adminUser.Id, 'User id should not be null');

		try {
			// get user other then not logged in user.
			mktUser = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.Name = 'Payroll Care' LIMIT 1];
		} catch (QueryException qe) {
			System.assertNotEquals(null, mktUser.Id, 'User id should not be null');
		}

		System.runAs(adminUser) {
			// insert list of Skill
			List<Skill__c> lstSkill = new List<Skill__c>();
			User_Role__c userRoleObj = new User_Role__c();
			userRoleObj.User__c = adminUser.Id;
			insert userRoleObj;
			System.assertNotEquals(null, userRoleObj.Id, 'User role id should not be null');

			// insert list of Role
			List<Role__c> roleList = new List<Role__c>();
			Role__c roleObj = new Role__c();
			roleObj.Name = 'Payroll Transfer Advocate';
			roleList.add(roleObj);

			// insert Role Record
			Role__c roleObj1 = new Role__c();
			roleObj1.Name = 'Payroll Transfer Facilitator';
			roleList.add(roleObj1);
			insert roleList;
			System.assert(roleList.size() > 0, 'There should be more than 1 role in list.');

			// insert Skill Record
			Skill__c skillObj1 = new Skill__c();

			skillObj1.Role__c = roleList[0].Id;
			skillObj1.Payroll_Transfer_Skills__c = 'Direct Order';

			lstSkill.add(skillObj1);
			insert skillObj1;
			System.assertNotEquals(null, skillObj1.Id, 'Skill id should not be null');

			userSkillObj = new User_Skill__c();
			userSkillObj.Skill__c = skillObj1.Id;
			userSkillObj.User_Role__c = userRoleObj.Id;
			// insert User Skill Record
			insert userSkillObj;
			System.assertNotEquals(null, userSkillObj.Id, 'User skill id should not be null');
		}
	}
	@isTest
	static void testPTForecastCreAssignExtforUnauthorizedUser() {
		Test.startTest();

		// code run as marketing user
		System.runAs(mktUser) {
			try {
				// Call standard controller with Payroll Transfer FBOS Forecast object as a parameter
				ApexPages.StandardController ptfStandCtrl = new ApexPages.StandardController(new Payroll_Transfer_FBOS_Forecast__c());
				PTForecastCreationAssignmentExtension ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);

				System.assert(ctrl.lstForecastWrap == null || ctrl.lstForecastWrap.size() == 0, 'lstForecastWrap should be null or empty.');
			} catch (exception ex) {
				System.assert(false, 'There should be no exception.');
			}
		}

		Test.stopTest();
	}
	@isTest
	static void testForecastANDBOAForAuthorizedUser() {
		Test.startTest();
		// Call standard controller with Payroll Transfer FBOS Forecast object as a parameter
		ApexPages.StandardController ptfStandCtrl = new ApexPages.StandardController(new Payroll_Transfer_FBOS_Forecast__c());
		PTForecastCreationAssignmentExtension ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);
		// code run as admin user
		System.runAs(adminUser) {
			ctrl.foreCastObj.Year__c = '2021'; // set year
			ctrl.getForecastRecord();
			ctrl.insertNewForecastRecord(); // create new entry
			System.assert(null != ctrl.lstForecastWrap && ctrl.lstForecastWrap.size() > 0, 'lstForecastWrap size should be greater than 0.');

			ctrl.lstForecastWrap[0].objForecast.Month__c = 'January';
			ctrl.intIndxToBeUpdated = 0;

			ctrl.onMonthChange();

			ctrl.lstForecastWrap[0].objForecast.FBOS_Forecast__c = 29;

			System.assert(ctrl.lstForecastWrap[0].intTotalMonthCap == 29, 'intTotalMonthCap should be 29.');
			ctrl.upsertForecastRecords();

			System.assert([SELECT COUNT() FROM Payroll_Transfer_FBOS_Forecast__c] > 0, 'Record count should be more than 0.');

			Payroll_Transfer_FBOS_Forecast__c fBOS = [SELECT Id FROM Payroll_Transfer_FBOS_Forecast__c LIMIT 1];

			//In Edit Mode
			ptfStandCtrl = new ApexPages.StandardController(fBOS);
			ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);

			ctrl.showUserAssignmentSection();
			ctrl.upsertBOARecords();

			System.assert([SELECT COUNT() FROM Benefit_Order_Allocation__c] > 0, 'Record count should be more than 0.');
		}

		//Create a user who will be the advocate
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User'];

		User advocate = new TestDataFactory.UserBuilder()
			.setEmail('test2@testorg.com')
			.setFirstName('Test')
			.setLastName('User2')
			.setProfileId(p.Id)
			.setUserName('test.user2@test.org')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.build();
		insert advocate;

		//get role details
		Role__c roleObj = [SELECT Id FROM Role__c WHERE Name = 'Payroll Transfer Advocate'];
		Skill__c skillObj = [SELECT Id FROM Skill__c WHERE Payroll_Transfer_Skills__c = 'Direct Order'];

		User_Role__c userRoleAdv = new User_Role__c(User__c = advocate.Id);

		insert userRoleAdv;

		User_Skill__c userSkillObj = new User_Skill__c();
		userSkillObj.Skill__c = skillObj.Id;
		userSkillObj.User_Role__c = userRoleAdv.Id;
		// insert User Skill Record
		insert userSkillObj;

		System.runAs(adminUser) {
			Payroll_Transfer_FBOS_Forecast__c fBOS = [SELECT Id FROM Payroll_Transfer_FBOS_Forecast__c LIMIT 1];
			ptfStandCtrl = new ApexPages.StandardController(fBOS);
			ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);
			ctrl.showFBOSSection();

			ctrl.getForeCastAndBOARecords();

			ctrl.upsertBOARecords();
		}
		Test.stopTest();
	}
	@isTest
	static void testForecastDeletion() {
		Test.startTest();
		// Call standard controller with Payroll Transfer FBOS Forecast object as a parameter
		ApexPages.StandardController ptfStandCtrl = new ApexPages.StandardController(new Payroll_Transfer_FBOS_Forecast__c());
		PTForecastCreationAssignmentExtension ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);
		// code run as admin user
		System.runAs(adminUser) {
			ctrl.foreCastObj.Year__c = '2021'; // set year
			ctrl.getForecastRecord();
			ctrl.insertNewForecastRecord(); // create new entry
			System.assert(null != ctrl.lstForecastWrap && ctrl.lstForecastWrap.size() > 0, 'lstForecastWrap size should be greater than 0.');

			ctrl.lstForecastWrap[0].objForecast.Month__c = 'January';
			ctrl.intIndxToBeUpdated = 0;

			ctrl.onMonthChange();

			ctrl.lstForecastWrap[0].objForecast.FBOS_Forecast__c = 10;

			System.assert(ctrl.lstForecastWrap[0].intTotalMonthCap == 10, 'intTotalMonthCap should be 10.');
			System.assert(ctrl.lstForecastWrap[0].intNoOfWeeks > 0, 'intNoOfWeeks size should be greater than 0.');

			ctrl.insertNewForecastRecord(); // create new entry
			ctrl.lstForecastWrap[1].objForecast.Month__c = 'March';
			ctrl.intIndxToBeUpdated = 1;

			ctrl.onMonthChange();

			ctrl.lstForecastWrap[1].objForecast.FBOS_Forecast__c = 90;

			System.assert(ctrl.lstForecastWrap[1].intTotalMonthCap == 90, 'intTotalMonthCap should be 90.');
			System.assert(ctrl.lstForecastWrap[1].intNoOfWeeks > 0, 'intNoOfWeeks size should be greater than 0.');

			ctrl.upsertForecastRecords();

			System.assert([SELECT COUNT() FROM Payroll_Transfer_FBOS_Forecast__c] > 0, 'Record count should be more than 0.');

			Payroll_Transfer_FBOS_Forecast__c fBOS = [SELECT Id FROM Payroll_Transfer_FBOS_Forecast__c LIMIT 1];

			//In Edit Mode
			ptfStandCtrl = new ApexPages.StandardController(fBOS);
			ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);

			ctrl.intIndxToBeRemoved = 0;
			ctrl.removeForecastRecord();
			System.assert([SELECT COUNT() FROM Payroll_Transfer_FBOS_Forecast__c] == 1, 'Record count should be 1.');
		}
	}
	@isTest
	static void testForecastNegativeScenarios() {
		// Call standard controller with Payroll Transfer FBOS Forecast object as a parameter
		ApexPages.StandardController ptfStandCtrl = new ApexPages.StandardController(new Payroll_Transfer_FBOS_Forecast__c());
		PTForecastCreationAssignmentExtension ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);
		// code run as admin user
		System.runAs(adminUser) {
			ctrl.foreCastObj.Year__c = '2021'; // set year
			ctrl.getForecastRecord();
			ctrl.insertNewForecastRecord(); // create new entry
			System.assert(null != ctrl.lstForecastWrap && ctrl.lstForecastWrap.size() > 0, 'lstForecastWrap size should be greater than 0.');

			ctrl.lstForecastWrap[0].objForecast.Month__c = 'January';
			ctrl.intIndxToBeUpdated = 0;

			ctrl.onMonthChange();

			ctrl.lstForecastWrap[0].objForecast.FBOS_Forecast__c = 10;

			System.assert(ctrl.lstForecastWrap[0].intTotalMonthCap == 10, 'intTotalMonthCap should be 10.');

			ctrl.insertNewForecastRecord(); // create new entry
			System.assert(null != ctrl.lstForecastWrap && ctrl.lstForecastWrap.size() > 0, 'lstForecastWrap size should be greater than 0.');

			ctrl.lstForecastWrap[1].objForecast.Month__c = 'January';
			ctrl.intIndxToBeUpdated = 1;

			ctrl.onMonthChange();

			ctrl.lstForecastWrap[1].objForecast.FBOS_Forecast__c = 10;

			System.assert(ctrl.lstForecastWrap[1].intTotalMonthCap == 10, 'intTotalMonthCap should be 10.');

			//try to save duplicate records
			ctrl.upsertForecastRecords();

			System.assert([SELECT COUNT() FROM Payroll_Transfer_FBOS_Forecast__c] == 0, 'Record count should be 0.');

			ctrl.lstForecastWrap.remove(1);

			//try to save forecast where week total doesnot match month cap
			ctrl.lstForecastWrap[0].objForecast.First_Week_Cap__c = 12;

			ctrl.upsertForecastRecords();
			System.assert([SELECT COUNT() FROM Payroll_Transfer_FBOS_Forecast__c] == 0, 'Record count should be 0.');

			//try to save forecast without month
			ctrl.lstForecastWrap[0].objForecast.First_Week_Cap__c = 10;
			ctrl.lstForecastWrap[0].objForecast.Month__c = null;
			ctrl.upsertForecastRecords();
			System.assert([SELECT COUNT() FROM Payroll_Transfer_FBOS_Forecast__c] == 0, 'Record count should be 0.');
		}
	}

	@isTest
	static void testBOANegativeScenarios() {
		// Call standard controller with Payroll Transfer FBOS Forecast object as a parameter
		ApexPages.StandardController ptfStandCtrl = new ApexPages.StandardController(new Payroll_Transfer_FBOS_Forecast__c());
		PTForecastCreationAssignmentExtension ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);
		// code run as admin user
		System.runAs(adminUser) {
			ctrl.foreCastObj.Year__c = '2021'; // set year
			ctrl.getForecastRecord();
			ctrl.insertNewForecastRecord(); // create new entry
			System.assert(null != ctrl.lstForecastWrap && ctrl.lstForecastWrap.size() > 0, 'lstForecastWrap size should be greater than 0.');

			ctrl.lstForecastWrap[0].objForecast.Month__c = 'January';
			ctrl.intIndxToBeUpdated = 0;

			ctrl.onMonthChange();

			ctrl.lstForecastWrap[0].objForecast.FBOS_Forecast__c = 10;

			System.assert(ctrl.lstForecastWrap[0].intTotalMonthCap == 10, 'intTotalMonthCap should be 10.');

			ctrl.upsertForecastRecords();

			Payroll_Transfer_FBOS_Forecast__c fBOS = [SELECT Id FROM Payroll_Transfer_FBOS_Forecast__c LIMIT 1];

			//In Edit Mode
			ptfStandCtrl = new ApexPages.StandardController(fBOS);
			ctrl = new PTForecastCreationAssignmentExtension(ptfStandCtrl);

			ctrl.showUserAssignmentSection();

			for (Integer indx = 0; indx < ctrl.lstUserAssignmentWrap.size(); indx++) {
				for (Integer wk : ctrl.lstUserAssignmentWrap[indx].mapWeekToBOA.keySet()) {
					Benefit_Order_Allocation__c objOA = ctrl.lstUserAssignmentWrap[indx].mapWeekToBOA.get(wk);
					objOA.Week_Order_Capacity__c += 1;
					ctrl.lstUserAssignmentWrap[indx].mapWeekToBOA.put(wk, objOA);
				}
			}

			ctrl.upsertBOARecords();

			System.assert([SELECT COUNT() FROM Benefit_Order_Allocation__c] == 0, 'Record count should be 0.');

			ctrl.selectedMonth = '';
			ctrl.fetchAdvocates();
		}
	}
}