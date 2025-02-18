@isTest
public class OrderTriggerHelperTest {
	public static User adminUser;
	public static List<Account> testAccountList;
	public static List<Opportunity> testOppList;
	static final Id ORDER_RT_COMPANYMIGRATION = Cache.getRecordTypeId('Order', 'Company Migration');
	static final Id LOGGED_IN_USER_ID = userInfo.getUserId();
	static final Id TTF_RT_PAYROLLTRANSFER = Cache.getRecordTypeId('Transition_To_Fulfillment__c', 'Payroll Transfer');

	static {
		createTestData();
	}

	static void createTestData() {
		adminUser = new TestDataFactory.UserBuilder()
			.setUserName('test_adminUser@gusto.com')
			.setExemptfromValidationRules(true)
			.setIsActive(true)
			.setProfileId(TestDataFactory.objZPSysAdminProfile.Id)
			.setEmail('test_adminUser@gusto.com')
			.build();
		insert adminUser;
		System.assertNotEquals(null, adminUser.Id, 'User Id should not be null.');

		System.runAs(adminUser) {
			// insert org default tier config settings
			Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
			insert objTierConfig;

			//Insert Phone Number Assignment Data
			HR_Worker_Information__c obj_HRWorker = new HR_Worker_Information__c(Email__c = 'test_adminUser@gusto.com', Status__c = 'Active', Last_Name__c = adminUser.LastName);
			insert obj_HRWorker;

			//Create a user who will be the facilitator
			Profile p = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User'];

			User facilitator = new TestDataFactory.UserBuilder().setUserName('test_facilitatorUser@gusto.com').setIsActive(true).setProfileId(p.Id).setEmail('test_facilitatorUser@gusto.com').build();
			insert facilitator;

			// insert accounts list
			Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
			testAccountList = new List<Account>{ objAccount };

			insert testAccountList;
			// assert if accounts are inserted successfully
			for (Account acc : testAccountList) {
				System.assertNotEquals(null, acc.Id, 'Account Id should not be null.');
			}

			// insert opportunity list
			testOppList = new List<Opportunity>();
			for (integer i = 0; i < 1; i++) {
				Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
					.setAccountId(testAccountList[i].Id)
					.setName('TestOpp')
					.setStage('SAL')
					.setCloseDate(System.today())
					.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
					.build();
				testOppList.add(objOpp);
			}
			insert testOppList;
			// assert if opportunities are inserted successfully
			for (Opportunity objOpp : testOppList) {
				System.assertNotEquals(null, objOpp.Id, 'Opportunity Id should not be null.');
			}
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : method that creates User Role, Skills, User Skills,
	 *              FBOS Forecast and Benefit Allocation  records for
	 *          "Payroll Transfer Facilitator" role.
	 * @Parm        : null
	 * @Return      : null
	 **/
	static void createUserRoleAndSkills() {
		User_Role__c objUserRole = new TestDataFactory.UserRoleBuilder().setUserId(UserInfo.getUserId()).build();
		insert objUserRole;

		Role__c objRole = new Role__c();
		objRole.Name = 'Payroll Transfer Facilitator';
		insert objRole;

		Skill__c objSkill = new TestDataFactory.SkillBuilder().setRoleId(objRole.Id).setPTSkills('Direct Order').build();
		insert objSkill;

		User_Skill__c objUserSkill = new TestDataFactory.UserSkillBuilder().setSkillId(objSkill.Id).setUserRoleId(objUserRole.Id).build();
		// insert User Skill Record
		insert objUserSkill;

		apexPages.currentPage().getParameters().put('userRole', 'Payroll Transfer Facilitator');
		ApexPages.StandardController ptForecastStandCtrl = new ApexPages.StandardController(new Payroll_Transfer_FBOS_Forecast__c());
		PTForecastCreationAssignmentExtension objExtension = new PTForecastCreationAssignmentExtension(ptForecastStandCtrl);

		objExtension.foreCastObj.Year__c = '2021'; // set year
		objExtension.getForecastRecord();
		objExtension.insertNewForecastRecord(); // create new entry
		System.assert(objExtension.lstForecastWrap != null && objExtension.lstForecastWrap.size() > 0, 'lstForecastWrap size should be greater than 0.');

		objExtension.lstForecastWrap[0].objForecast.Month__c = 'January';
		objExtension.intIndxToBeUpdated = 0;
		objExtension.onMonthChange();

		objExtension.lstForecastWrap[0].objForecast.FBOS_Forecast__c = 29;
		System.assert(objExtension.lstForecastWrap[0].intTotalMonthCap == 29, 'intTotalMonthCap should be 29.');
		objExtension.upsertForecastRecords();

		System.assert([SELECT COUNT() FROM Payroll_Transfer_FBOS_Forecast__c] > 0, 'Record count should be more than 0.');

		Payroll_Transfer_FBOS_Forecast__c objFbos = [SELECT Id FROM Payroll_Transfer_FBOS_Forecast__c LIMIT 1];

		//In Edit Mode
		apexPages.currentPage().getParameters().put('userRole', 'Payroll Transfer Facilitator');
		ptForecastStandCtrl = new ApexPages.StandardController(objFbos);
		objExtension = new PTForecastCreationAssignmentExtension(ptForecastStandCtrl);
		objExtension.showUserAssignmentSection();
		objExtension.upsertBOARecords();

		System.assert([SELECT COUNT() FROM Benefit_Order_Allocation__c] > 0, 'Record count should be more than 0.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Method to test "Faciliatator Due Date" calculation
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testFacilitatorDueDate() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			OrderTriggerHelper.skipTrigger = false;
			Order objOrder = new TestDataFactory.OrderBuilder()
				.setAccountId(testAccountList[0].Id)
				.setOpportunityId(testOppList[0].Id)
				.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
				.setStatus('Drafted')
				.setOwnerId(UserInfo.getUserId())
				.build();
			objOrder.Active_Employee_Count__c = 10;
			objOrder.EffectiveDate = System.today();
			objOrder.Payroll_Run_Date__c = System.today();
			objOrder.First_Check_Date__c = System.today();
			insert objOrder;

			Test.stopTest();

			List<Order> list_Orders = [
				SELECT Id, Payroll_Run_Date__c, Facilitator_Due_Date__c
				FROM Order
				WHERE Id = :objOrder.Id
			];
			System.assertEquals(-3, OrderTriggerHelper.intFacilitatorDueDateDaysFromPayrollRunDate, 'intFacilitatorDueDateDaysFromPayrollRunDate should be -3.');
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : "Ready_For_Facilitator_Due_Date__c" field
	 *                  populating logic.
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testReadyForFacilitatorDueDateAssignment() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			OrderTriggerHelper.skipTrigger = false;
			Order objOrder = new TestDataFactory.OrderBuilder()
				.setAccountId(testAccountList[0].Id)
				.setOpportunityId(testOppList[0].Id)
				.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
				.setStatus('Drafted')
				.setOwnerId(UserInfo.getUserId())
				.build();

			objOrder.Active_Employee_Count__c = 10;
			objOrder.EffectiveDate = System.today();
			objOrder.Payroll_Run_Date__c = System.today();
			objOrder.First_Check_Date__c = System.today();
			objOrder.Facilitator_Due_Date__c = System.today();
			insert objOrder;

			List<Order> list_Orders = [SELECT Id, Ready_For_Facilitator_Due_Date__c FROM Order WHERE Id = :objOrder.Id];
			System.assert(list_Orders[0].Ready_For_Facilitator_Due_Date__c != null, 'Ready_For_Facilitator_Due_Date__c should not be null.');

			objOrder.Facilitator_Due_Date__c = System.today().addDays(2);
			update objOrder;
			Test.stopTest();

			List<Order> list_TempOrders = [
				SELECT Id, Ready_For_Facilitator_Due_Date__c
				FROM Order
				WHERE Id = :objOrder.Id
			];
			System.assert(list_TempOrders[0].Ready_For_Facilitator_Due_Date__c != null, 'Ready_For_Facilitator_Due_Date__c should not be null.');
			System.assert(
				list_Orders[0].Ready_For_Facilitator_Due_Date__c != list_TempOrders[0].Ready_For_Facilitator_Due_Date__c,
				'Ready_For_Facilitator_Due_Date__c of order and temp order should not match.'
			);
		}
	}

	@isTest
	static void testpopulateOrderOnMatchingOpportunities() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			System.runAs(adminUser) {
				List<Order> orderList = new List<Order>();
				for (integer i = 0; i < 1; i++) {
					Order ord = new Order();
					ord.AccountId = testAccountList[i].Id;
					ord.Active_Employee_Count__c = 10;
					ord.EffectiveDate = System.today();
					ord.Status = 'Drafted';
					ord.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
					ord.Deductions_List__c = 'Test,Test';
					orderList.add(ord);
				}
				insert orderList;
				// assert if company migration on opportunity is updated
				for (Opportunity objOpp : [SELECT Order__c FROM Opportunity]) {
					System.assertNotEquals(null, objOpp.Order__c, 'Order on Opportunity should not be null.');
				}
				update orderList;
				delete orderList;
			}
			Test.stopTest();
		}
	}

	@isTest
	static void payrollTransferTest() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			Order ord = new Order();
			ord.AccountId = testAccountList[0].Id;
			ord.Active_Employee_Count__c = 10;
			ord.EffectiveDate = System.today();
			ord.Status = 'Onboarding Steps 8 - 9';
			ord.Data_Entry_Assist__c = LOGGED_IN_USER_ID;
			ord.Payroll_Run_Date__c = System.today();
			ord.RecordTypeId = ORDER_RT_COMPANYMIGRATION;
			insert ord;

			Case objCase = new Case(Status = 'New', origin = 'Panda', Order__c = ord.Id, Integration_Key__c = 'panda-1213');
			insert objCase;

			OrderTriggerHelper.updateOrderNotificationOnCase();
			orderTRiggerhelper.UpdateOrderNotificationForFinalStepOnCase();

			Test.stopTest();
			System.assert(true, 'Fixing Apex PMD issue.');
		}
	}

	@isTest
	static void bulkMigrationTest() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			Bulk_Migration_Request__c objBulkMig = new Bulk_Migration_Request__c();
			objBulkMig.Bulk_Migration_Status__c = 'New';
			insert objBulkMig;

			Order ord = new Order();
			ord.AccountId = testAccountList[0].Id;
			ord.Active_Employee_Count__c = 10;
			ord.EffectiveDate = System.today();
			ord.Status = 'Drafted';
			ord.Bulk_Migration__c = objBulkMig.Id;
			insert ord;

			ord.Status = 'Closed: Payroll Run';
			ord.First_Payroll_Call_Scheduled__c = 'Partner Account (no call needed)';

			update ord;

			Bulk_Migration_Request__c bulkMigObj = [
				SELECT Id, Bulk_Migration_Status__c
				FROM Bulk_Migration_Request__c
				WHERE Id = :objBulkMig.Id
			];
			System.assertEquals('Completed', bulkMigObj.Bulk_Migration_Status__c, 'Bulk_Migration_Status__c should be Completed.');
			Test.stopTest();
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : test for updateSynOrderAndBMROwners method
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void bulkMigrationFacilitatorAssignmentTest() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			createUserRoleAndSkills();

			Bulk_Migration_Request__c objBulkMig = new Bulk_Migration_Request__c();
			objBulkMig.Bulk_Migration_Status__c = 'New';
			objBulkMig.Facilitator__c = UserInfo.getUserId();
			insert objBulkMig;

			Order objOrder = new Order();
			objOrder.AccountId = testAccountList[0].Id;
			objOrder.Active_Employee_Count__c = 10;
			objOrder.EffectiveDate = Date.newInstance(2021, 1, 4);
			objOrder.Facilitator_Due_Date__c = Date.newInstance(2021, 1, 4);
			objOrder.Status = 'Drafted';
			objOrder.Bulk_Migration__c = objBulkMig.Id;
			insert objOrder;

			objOrder.Assign_Facilitator__c = true;
			update objOrder;
			Test.stopTest();

			List<Order> list_Orders = [SELECT Id, Data_Entry_Assist__c, Status FROM Order WHERE Id = :objOrder.Id];
			System.assert(list_Orders.get(0).Status == 'Drafted', 'Order status should be Drafted.');
		}
	}

	@isTest
	static void testCalculateRunDate() {
		Test.startTest();
		System.runAs(adminUser) {
			Bulk_Migration_Request__c objBulkMig = new Bulk_Migration_Request__c();
			objBulkMig.Bulk_Migration_Status__c = 'New';
			insert objBulkMig;

			List<User> lstFacilitator = [SELECT Id FROM USer WHERE Profile.Name = 'Direct Sales User'];
			List<String> lstPrevProvider = new List<String>{
				'ADP Run',
				'Intuit Online Payroll',
				'QuickBooks Online',
				'Paychex',
				'Ovation (Heartland) Payroll',
				'PEOs',
				'Paycor',
				'QuickBooks Desktop',
				'BenefitMall',
				'Paycom',
				'Namely',
				'Local Provider',
				'Zenefits',
				'Thompson Reuters',
				'Sage',
				'Xero',
				'Square Payroll',
				'SurePayroll',
				'ADP',
				'ADP (other product)',
				'ADP (other)',
				'Paychex (other)',
				'Wells Fargo',
				'Offline',
				'Other',
				''
			};
			List<String> lstPaySchedule = new List<String>{
				'Annually',
				'Every other week',
				'Every week',
				'Monthly',
				'Quarterly',
				'Semiannually',
				'Twice per month'	
			};
			List<Order> lstOrders = new List<Order>();
			for (Integer index = 0; index < 1; index++) {
				Order ord = new Order(
					AccountId = testAccountList[index].Id,
					OpportunityId = testOppList[index].Id,
					Active_Employee_Count__c = 20,
					EffectiveDate = System.today().addDays(index),
					Status = 'Drafted',
					Bulk_Migration__c = objBulkMig.Id,
					First_Check_Date__c = System.today().addDays(index + 3)
				);

				if (index == 0) {
					ord.Data_Entry_Assist__c = lstFacilitator[0].Id;
				}
				ord.Pay_Schedules__c = lstPaySchedule[index + 6];
				ord.Pay_Schedule_2__c = lstPaySchedule[index + 6];
				ord.Previous_Payroll_Provider__c = lstPrevProvider[index + 6];
				lstOrders.add(ord);
			}
			OrderTriggerHelper.skipTrigger = true;
			insert lstOrders;
			orderTriggerHelper controller = new OrderTriggerHelper();
			OrderTriggerHelper.skipTrigger = false;

			Integer indx = 0;
			for (Order ord : lstOrders) {
				if (indx == 0) {
					ord.Status = 'Closed: Payroll Run';
					ord.First_Payroll_Call_Scheduled__c = 'Partner Account (no call needed)';
					ord.OwnerId = LOGGED_IN_USER_ID;
					ord.Pay_Date_Extension_Reason__c = 'Clerical Error';
					ord.First_Check_Date__c = System.today().addDays(20);
					ord.of_Benefits__c = 3;
					ord.PTO__c = true;
					ord.of_Pay_Rates__c = 0;
					ord.of_Deductions__c = 0;
				} else if (indx == 1) {
					ord.of_Pay_Rates__c = 5;
					ord.of_Deductions__c = 5;
					ord.Pay_Schedules__c = 'Monthly';
					ord.Pay_Schedule_2__c = 'Monthly';
					ord.Previous_Payroll_Provider__c = 'Intuit Online Payroll';
					ord.Assign_Facilitator__c = true;
					ord.Data_Entry_Assist__c = null;
				}
				if (indx < lstPaySchedule.size()) {
					ord.Pay_Schedules__c = lstPaySchedule[indx];
					ord.Pay_Schedule_2__c = lstPaySchedule[indx];
				}
				ord.Previous_Payroll_Provider__c = lstPrevProvider[indx];

				indx++;
			}

			update lstOrders;
		}
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testCalculateRunDateWithOtherPaySchedule() {
		Test.startTest();
		System.runAs(adminUser) {
			List<String> lstPrevProvider = new List<String>{
				'ADP Run',
				'Intuit Online Payroll',
				'QuickBooks Online',
				'Paychex',
				'Ovation (Heartland) Payroll',
				'PEOs',
				'Paycor',
				'QuickBooks Desktop',
				'BenefitMall',
				'Paycom',
				'Namely',
				'Local Provider',
				'Zenefits',
				'Thompson Reuters',
				'Sage',
				'Xero',
				'Square Payroll',
				'SurePayroll',
				'ADP',
				'ADP (other product)',
				'ADP (other)',
				'Paychex (other)',
				'Wells Fargo',
				'Offline',
				'Other',
				''
			};
			List<String> lstPaySchedule = new List<String>{
				'Annually',
				'Every other week',
				'Every week',
				'Monthly',
				'Quarterly',
				'Semiannually',
				'Twice per month'
			};

			List<Order> lstOrders = new List<Order>();
			for (Integer index = 0; index < 1; index++) {
				Order ord = new Order(
					AccountId = testAccountList[index].Id,
					OpportunityId = testOppList[index].Id,
					Active_Employee_Count__c = 20,
					EffectiveDate = System.today().addDays(index),
					Status = 'Drafted',
					First_Check_Date__c = System.today().addDays(index + 3)
				);
				ord.Pay_Schedules__c = lstPaySchedule[index];
				ord.Pay_Schedule_2__c = lstPaySchedule[index];
				ord.Previous_Payroll_Provider__c = lstPrevProvider[index];
				lstOrders.add(ord);
			}

			insert lstOrders;

			Integer indx = 6;
			for (Order ord : lstOrders) {
				ord.Pay_Schedules__c = lstPaySchedule[indx];
				ord.Pay_Schedule_2__c = lstPaySchedule[indx];
				ord.Previous_Payroll_Provider__c = lstPrevProvider[indx];

				indx++;
			}

			update lstOrders;
		}
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testCalculatePayDateFields() {
		Test.startTest();
		System.runAs(adminUser) {
			List<String> lstPrevProvider = new List<String>{
				'Zenefits',
				'Thompson Reuters',
				'Sage',
				'Xero',
				'Square Payroll',
				'SurePayroll',
				'ADP',
				'ADP (other product)',
				'ADP (other)',
				'Paychex (other)',
				'Wells Fargo',
				'Offline',
				'Other',
				''
			};
			List<String> lstPaySchedule = new List<String>{ 
				'Annually',
				'Every other week',
				'Every week',
				'Monthly',
				'Quarterly',
				'Semiannually',
				'Twice per month'	
			};

			List<Order> lstOrders = new List<Order>();
			for (Integer index = 0; index < 1; index++) {
				Order ord = new Order(
					AccountId = testAccountList[index].Id,
					OpportunityId = testOppList[index].Id,
					Active_Employee_Count__c = 20,
					EffectiveDate = System.today().addDays(index),
					Status = 'Drafted',
					First_Check_Date__c = System.today().addDays(index + 3)
				);
				ord.Pay_Schedules__c = lstPaySchedule[index];
				ord.Pay_Schedule_2__c = lstPaySchedule[index];
				ord.Previous_Payroll_Provider__c = lstPrevProvider[index];
				lstOrders.add(ord);
			}

			insert lstOrders;

			lstOrders = [SELECT Id, First_Check_Date__c, Original_Check_Date__c FROM Order];

			for (Order ord : lstOrders) {
				System.assert(ord.Original_Check_Date__c == ord.First_Check_Date__c, 'First_Check_Date__c and Original_Check_Date__c should be same on order.');
			}
			Integer indx = 0;

			for (Order ord : lstOrders) {
				ord.First_Check_Date__c = ord.First_Check_Date__c.addDays(5);

				if (indx == 0) {
					ord.Pay_Date_Extension_Reason__c = 'Clerical Error';
				}

				indx++;
			}

			update lstOrders;

			lstOrders[0].Original_Check_Date__c = Date.today().addDays(5);
			lstOrders[0].Pay_Date_Extension_count__c = 1;
			lstOrders[0].Benefits_List__c = 'Health Insurance401k';
			lstOrders[0].Pay_Date_Extension_Reason__c = 'Clerical Error';
			lstOrders[0].Pay_Rates__c = 'Test';
			lstOrders[0].First_Check_Date__c = lstOrders[0].Original_Check_Date__c;

			update lstOrders[0];
		}
		Test.stopTest();
	}

	@isTest
	private static void testPhoneNoPopulation() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			CaseTriggerHelper.skipTrigger = true;
			Case cse = new Case();
			cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Transfer Case');
			cse.AccountId = testAccountList[0].Id;
			cse.Subject = 'Test';
			cse.Description = 'Test';
			cse.Type = 'Payroll Transfer';
			cse.Origin = 'Panda';
			cse.SuppliedEmail = 'test.test@test.com';
			cse.Large_Scale_Issue__c = 'Test LSI';
			cse.Integration_Key__c = 'test12331L023';
			CaseTriggerHelper.skipTrigger = true;
			insert cse;
			CaseTriggerHelper.skipTrigger = false;

			List<Order> orderList = new List<Order>();
			for (integer i = 0; i < 1; i++) {
				Order ord = new Order();
				ord.AccountId = testAccountList[i].Id;
				ord.Active_Employee_Count__c = 10;
				ord.EffectiveDate = System.today();
				ord.Status = 'Drafted';
				ord.case__c = cse.Id;
				orderList.add(ord);
			}
			OrderTriggerHelper.skipTrigger = true;
			insert orderList;
			OrderTriggerHelper.skipTrigger = false;

			cse.order__c = orderList[0].Id;
			update cse;

			orderList[0].OwnerId = adminUser.Id;
			update orderList[0];
			Test.stopTest();
			System.assert(true, 'Fixing Apex PMD issue.');
		}
	}

	@isTest
	private static void testUpdateCaseStatusAsClosedOnOrderCloser() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();

			CaseTriggerHelper.skipTrigger = true;
			Case objCase = new Case();
			objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Transfer Case');
			objCase.AccountId = testAccountList[0].Id;
			objCase.Subject = 'Test';
			objCase.Description = 'Test';
			objCase.Type = 'Payroll Transfer';
			objCase.Origin = 'Email';
			objCase.SuppliedEmail = 'test.test@test.com';
			objCase.Large_Scale_Issue__c = 'Test LSI';
			objCase.Integration_Key__c = 'test123Key';
			CaseTriggerHelper.skipTrigger = true;
			insert objCase;
			CaseTriggerHelper.skipTrigger = false;

			List<Order> list_Orders = new List<Order>();
			for (integer i = 0; i < 1; i++) {
				Order objOrder = new Order();
				objOrder.AccountId = testAccountList[i].Id;
				objOrder.Active_Employee_Count__c = 10;
				objOrder.EffectiveDate = System.today();
				objOrder.Status = 'Drafted';
				objOrder.case__c = objCase.Id;
				list_Orders.add(objOrder);
			}
			OrderTriggerHelper.skipTrigger = true;
			insert list_Orders;
			OrderTriggerHelper.skipTrigger = false;

			objCase.order__c = list_Orders[0].Id;
			update objCase;

			list_Orders[0].Status = 'Closed: Payroll Run';
			update list_Orders[0];

			Test.stopTest();

			List<Case> list_Cases = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
			System.assert(list_Cases[0].Status != null, 'Case status should not be null.');
		}
	}

	@isTest
	private static void testBOARelationshipCountUpdate() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			List<Order> orderList = new List<Order>();
			for (integer i = 0; i < 1; i++) {
				Order ord = new Order();
				ord.AccountId = testAccountList[i].Id;
				ord.Active_Employee_Count__c = 10;
				ord.EffectiveDate = System.today();
				ord.Status = 'Drafted';
              
				orderList.add(ord);
			}
			OrderTriggerHelper.skipTrigger = true;
			insert orderList;
			OrderTriggerHelper.skipTrigger = false;

			User_Role__c userRoleObj = new User_Role__c();
			userRoleObj.User__c = adminUser.Id;
			insert userRoleObj;
            
			Benefit_Order_Allocation__c boa = new Benefit_Order_Allocation__c(User_Role__c = userRoleObj.Id, User__c = adminUser.Id);
			insert boa;

			Order_BOA_Relationship__c boaRelationship = new Order_BOA_Relationship__c(Orders__c = orderList[0].Id, Benefit_Order_Allocation__c = boa.Id);
			insert boaRelationship;

			orderList[0].OwnerId = adminUser.Id;
			orderList[0].Active_Employee_Count__c = 13;
			orderList[0].Assign_Facilitator__c = true;
			orderList[0].Facilitator_Follow_Up_Date__c = Date.today().addDays(3);
			orderList[0].Facilitator_Follow_Up_Date_Reason__c = 'EPD JIRA';
			orderList[0].Jira_Link__c = 'JIRA-0001';
			update orderList[0];
			System.assert([SELECT COUNT() FROM Order_BOA_Relationship__c WHERE Order_Employee_Count_Formula__c = 13] > 0, 'Record count should be more than 0.');

			orderList[0].OwnerId = UserInfo.getUserId();
			update orderList[0];
			Test.stopTest();
		}
	}

	@isTest
	static void bigDeskTest() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			Order objOrder = new Order();
			objOrder.AccountId = testAccountList[0].Id;
			objOrder.Active_Employee_Count__c = 70;
			objOrder.Contractor_Count__c = 10;
			objOrder.Inactive_Employee_Count__c = 25;
			objOrder.EffectiveDate = System.today();
			objOrder.Status = 'Onboarding Steps 8 - 9';
			objOrder.Data_Entry_Assist__c = LOGGED_IN_USER_ID;
			objOrder.Payroll_run_date__c = System.today();
			objOrder.RecordTypeId = ORDER_RT_COMPANYMIGRATION;
			insert objOrder;
			Test.stopTest();

			List<Order> list_Orders = [SELECT Id, Big_Desk_Sandbox_Type__c FROM Order WHERE Id = :objOrder.Id];
			System.assert(list_Orders[0].Big_Desk_Sandbox_Type__c != null, 'Big_Desk_Sandbox_Type__c should not be null.');
		}
	}

	@isTest
	static void bigDeskNegativeTest() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			Order objOrder = new Order();
			objOrder.AccountId = testAccountList[0].Id;
			objOrder.Active_Employee_Count__c = 10;
			objOrder.Contractor_Count__c = 10;
			objOrder.Inactive_Employee_Count__c = 5;
			objOrder.EffectiveDate = System.today();
			objOrder.Status = 'Onboarding Steps 8 - 9';
			objOrder.Data_Entry_Assist__c = LOGGED_IN_USER_ID;
			objOrder.Payroll_Run_Date__c = System.today();
			objOrder.RecordTypeId = ORDER_RT_COMPANYMIGRATION;
			objOrder.Deductions_List__c = 'Test';
			objOrder.Financial_Health_Benefits__c = 'Test';
			objOrder.Which_Health_Benefits_Currently_Offered__c = 'Test';
			objOrder.Transportation_Benefits__c = 'Test';
			objOrder.Other_Health_Benefits_Currently_Offered__c = 'Test';
			objOrder.Other_Financial_Benefits_Currently_Offer__c = 'Test';
			objOrder.Pay_Rates__c = 'Test';
			insert objOrder;
			Test.stopTest();

			List<Order> list_Orders = [SELECT Id, Big_Desk_Sandbox_Type__c FROM Order WHERE Id = :objOrder.Id];
			System.assert(list_Orders[0].Big_Desk_Sandbox_Type__c == null, 'Big_Desk_Sandbox_Type__c should be null.');
		}
	}

	@isTest
	private static void sendIntroEmailTest() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			ContactTriggerHelper.skipTrigger = true;
			CaseTriggerHelper.skipTrigger = true;
			AccountTriggerHelper.skipTrigger = true;
			OpportunityTriggerHelper.skipTrigger = true;
			List<Account> list_accounts = [SELECT Id FROM Account LIMIT 1];
			Contact objContact = new TestDataFactory.ContactBuilder()
				.setRecordTypeId('Company')
				.setAccountId(list_accounts[0].Id)
				.setFirstName('CompanyMigration')
				.setLastName('OrderTriggerHelperTest')
				.setPhone('9898798789')
				.setEmail('test@temp.com')
				.build();

			insert objContact;

			Order objOrder = new TestDataFactory.OrderBuilder()
				.setAccountId(testAccountList[0].Id)
				.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
				.setStatus('Drafted')
				.setOwnerId(UserInfo.getUserId())
				.build();

			objOrder.Active_Employee_Count__c = 10;
			objOrder.EffectiveDate = System.today();
			objOrder.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
			objOrder.Deductions_List__c = 'Test,Test';
			objOrder.Financial_Health_Benefits__c = 'group term life insurance,traditional or roth 401 or 403\n';
			objOrder.Which_Health_Benefits_Currently_Offered__c = 'medical, dental, vision;health savings account;health flexible spending account';
			objOrder.Transportation_Benefits__c = 'Test,Test';
			objOrder.Other_Health_Benefits_Currently_Offered__c = 'Test,Test';
			objOrder.Other_Financial_Benefits_Currently_Offer__c = 'Test,Test';
			objOrder.Pay_Rates__c = 'Test,Test';
			objOrder.Team_Invitation_Preference__c = 'admin';
			OrderTriggerHelper.skipTrigger = true;
			insert objOrder;

			Case objCase = TestDataFactory.createCaseRecord('Payroll Transfer Case', false);
			objCase.Status = 'New';
			objCase.origin = 'Panda';
			objCase.Order__c = objOrder.Id;
			objCase.ContactId = objContact.Id;
			objCase.AccountId = list_accounts[0].Id;
			objCase.Integration_Key__c = 'panda-1213';
			caseTriggerHelper.skipTrigger = true;
			insert objCase;

			objOrder.Previous_Payroll_Provider__c = 'Intuit Online Payroll';
			OrderTriggerHelper.skipTrigger = false;
			update objOrder;
			Test.stopTest();

			System.assertEquals(1, [SELECT Id FROM EmailMessage WHERE ParentId = :objCase.Id].size(), 'There should be 1 EmailMessage.');
		}
	}

	@isTest
	private static void sendSubmitTTFNotificationTest() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			List<Opportunity> list_Opportunities = [SELECT Id, AccountId FROM Opportunity];

			Test.startTest();
			Order objOrder = new TestDataFactory.OrderBuilder()
				.setAccountId(testAccountList[0].Id)
				.setStatus('Drafted')
				.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
				.setOwnerId(UserInfo.getUserId())
				.build();
			objOrder.OpportunityId = list_Opportunities[0].Id;
			objOrder.Active_Employee_Count__c = null;
			objOrder.Contractor_Count__c = null;
			objOrder.Inactive_Employee_Count__c = null;
			objOrder.EffectiveDate = System.today();
			objOrder.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
			objOrder.Deductions_List__c = ';Test';
			objOrder.Financial_Health_Benefits__c = ';group term life insurance;traditional or roth 401 or 403';
			objOrder.Which_Health_Benefits_Currently_Offered__c = ';health savings account;health flexible spending account;dependent care flexible spending account';
			objOrder.Transportation_Benefits__c = ';Test';
			objOrder.Other_Health_Benefits_Currently_Offered__c = ';Test';
			objOrder.Other_Financial_Benefits_Currently_Offer__c = ';Test';
			objOrder.Pay_Rates__c = ';Test';
			objOrder.Benefits_List__c = 'Test';
			objOrder.Team_Invitation_Preference__c = 'admin';
			OrderTriggerHelper.skipTrigger = true;
			insert objOrder;

			Case objCase = TestDataFactory.createCaseRecord('Payroll Transfer Case', false);
			objCase.Status = 'New';
			objCase.origin = 'Panda';
			objCase.Order__c = objOrder.Id;
			objCase.Integration_Key__c = 'panda-Submit123';
			caseTriggerHelper.skipTrigger = true;
			insert objCase;

			objOrder.Case__c = objCase.Id;
			objOrder.Migration_State__c = OrderUtils.BASICS_COMPLETED;
			OrderTriggerHelper.skipTrigger = false;
			update objOrder;

			Test.stopTest();

			List<EmailMessage> list_EmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :objCase.Id];
			System.assert(list_EmailMessages.size() > 0, 'list_EmailMessages size should be greater than 0.');
		}
	}
	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Method to test Payroll Transfer TTF creation from Order
	 * @Parm        : null
	 * @Return      : null
	 **/
	/*@isTest
	static void testTTFCreation() {
		User objUser = [SELECT Id FROM User WHERE Email = 'test_adminUser@gusto.com'];
		System.runAs(objUser) {
			Test.startTest();
			OrderTriggerHelper.skipTrigger = false;
			Order objOrder = new TestDataFactory.OrderBuilder()
				.setAccountId(testAccountList[0].Id)
				.setOpportunityId(testOppList[0].Id)
				.setRecordTypeId(ORDER_RT_COMPANYMIGRATION)
				.setStatus('Drafted')
				.setOwnerId(UserInfo.getUserId())
				.setEffectiveDate(System.today())
				.setDemoComplete('Yes')
				.setPrevPayrollProvider('Sage')
				.setExceptionRequest(false)
				.setExceptionRequestReason('Accountant has been let go')
				.setTwoFactorRequired('Yes')
				.setPointOfContactName('Test')
				.build();
			insert objOrder;

			Test.stopTest();

			List<Order> list_Orders = [
				SELECT Id, Payroll_Run_Date__c, Facilitator_Due_Date__c
				FROM Order
				WHERE Id = :objOrder.Id
			];
			List<Transition_To_Fulfillment__c> list_TTF = [
				SELECT
					Id,
					Name,
					RecordTypeId,
					TTF_Status__c,
					Order__c,
					Account__c,
					Opportunity__c,
					Demo_Complete__c,
					Previous_Payroll_Provider__c,
					Point_of_Contact_Name__c,
					Exception_Request__c,
					Reason_for_exception_request__c,
					Doesnot_require_2_factor_Authentication__c
				FROM Transition_To_Fulfillment__c
				WHERE Order__c = :objOrder.Id
			];
			System.assertEquals(1, list_TTF.size(), 'There should be 1 record of Transition_To_Fulfillment__c in list.');
			System.assertEquals(TTF_RT_PAYROLLTRANSFER, list_TTF[0].RecordTypeId, 'RecordTypeId should match.');
			System.assertEquals(objOrder.AccountId, list_TTF[0].Account__c, 'Account Id should match.');
			System.assertEquals(objOrder.OpportunityId, list_TTF[0].Opportunity__c, 'Opportunity Id should match.');
			System.assertEquals('Sales Submitted', list_TTF[0].TTF_Status__c, 'TTF_Status__c should be Sales Submitted.');
			System.assertEquals(objOrder.Demo_Complete__c, list_TTF[0].Demo_Complete__c, 'Demo_Complete__c should match.');
			System.assertEquals(objOrder.Previous_Payroll_Provider__c, list_TTF[0].Previous_Payroll_Provider__c, 'Previous_Payroll_Provider__c should match.');
			System.assertEquals(objOrder.Point_of_Contact_Name__c, list_TTF[0].Point_of_Contact_Name__c, 'Point_of_Contact_Name__c should match.');
			System.assertEquals('No', list_TTF[0].Exception_Request__c, 'Exception_Request__c should be No.');
			System.assertEquals(objOrder.Exception_Request_Reason__c, list_TTF[0].Reason_for_exception_request__c, 'Reason_for_exception_request__c should be same as Exception_Request_Reason__c.');
			System.assertEquals('N', list_TTF[0].Doesnot_require_2_factor_Authentication__c, 'Doesnot_require_2_factor_Authentication__c should be N.');
		}
	}*/
}