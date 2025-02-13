/**
 * @description  Test Class for OrderBannerController
 * @author       Debasmita Rawooth
 * @date         11-12-2024
 **/
@IsTest
public class OrderBannerControllerTest {
	@TestSetup
	static void setup() {
		Profile objProfile1 = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User' LIMIT 1];
		Profile objProfile2 = [SELECT Id FROM Profile WHERE Name = 'MMPR User' LIMIT 1];
		UserRole objUserRole1 = [SELECT Id, Name FROM UserRole WHERE Name = 'Payroll Transfer Fulfillment' LIMIT 1];
		UserRole objUserRole2 = [SELECT Id, Name FROM UserRole WHERE Name = 'sales_partner_ae_xx' LIMIT 1];

		User objUser;
		User objUser1;
		User objUser2;

		System.runAs(new User(Id = UserInfo.getUserId())) {
			objUser = new TestDataFactory.UserBuilder()
				.setAlias('dummy1')
				.setEmail('user1@example.com')
				.setEmailEncoding('UTF-8')
				.setLastName('User1')
				.setLanguageLocaleKey('en_US')
				.setLocaleSidKey('en_US')
				.setProfileId(objProfile1.Id)
				.setUserRoleId(objUserRole1.Id)
				.setClassQueue('Class 1')
				.setUserName('OrderBanneruser1@example.com')
				.setTimeZoneSidKey('America/Los_Angeles')
				.build();
			insert objUser;

			objUser1 = new TestDataFactory.UserBuilder()
				.setAlias('dummy2')
				.setEmail('user2@example.com')
				.setEmailEncoding('UTF-8')
				.setLastName('User2')
				.setLanguageLocaleKey('en_US')
				.setLocaleSidKey('en_US')
				.setProfileId(objProfile1.Id)
				.setUserRoleId(objUserRole1.Id)
				.setClassQueue('Class 2')
				.setUserName('OrderBanneruser2@example.com')
				.setTimeZoneSidKey('America/Los_Angeles')
				.build();
			insert objUser1;

			objUser2 = new TestDataFactory.UserBuilder()
				.setAlias('dummy3')
				.setEmail('user3@example.com')
				.setEmailEncoding('UTF-8')
				.setLastName('User3')
				.setLanguageLocaleKey('en_US')
				.setLocaleSidKey('en_US')
				.setProfileId(objProfile1.Id)
				.setUserRoleId(objUserRole1.Id)
				.setClassQueue('Class 1')
				.setUserName('OrderBanneruser3@example.com')
				.setTimeZoneSidKey('America/Los_Angeles')
				.build();
			insert objUser2;
		}

		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder().setName('name').setRecordTypeId('Company').setPricebook2Id(Test.getStandardPricebookId()).build();
		insert objAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setStage('SAL')
			.setCloseDate(System.today())
			.setName('test opp')
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
			.setAccountId(objAccount.Id)
			.setNumberOfEE(1)
			.setZPCompanyId('12121212121212')
			.setSourceID('12121212121212')
			.setClosedOwnerDivision('Partner')
			.build();
		insert objOpportunity;

		Order objOrder = new TestDataFactory.OrderBuilder()
			.setEffectiveDate(System.today())
			.setAccountId(objAccount.Id)
			.setStatus('Drafted')
			.setFirstCheckDate(System.today().addDays(8))
			.setCommunicationsTimeCommitment(1.5)
			.setPtoTimeCommitment(0)
			.setBenefitsTimeCommitment(0)
			.setStatesTimeCommitment(0.1666)
			.setEmployeeTimeCommitment(2.5308)
			.setPayrollsTimeCommitment(15.2304)
			.build();
		insert objOrder;

		GradientWorks__Queue__c objQueueRecord = new TestDataFactory.GradientWorksQueueBuilder().setName('PT - Orders Queue - Week Test 1').setAssignmentField('ownerId').setSlotIndex(0).build();
		insert objQueueRecord;

		PT_Order_Team_Capacity__c objTeamCapacity = new TestDataFactory.PTCapacityBuilder()
			.setName('Partner - Week 1')
			.setQueueId(objQueueRecord.Id)
			.setUsedCapacity(22)
			.setPercentTotalCapacity(50)
			.setTeamDivisionName('Partner')
			.build();
		insert objTeamCapacity;

		GradientWorks__QueueUser__c objQueueUser = new TestDataFactory.GradientWorksQueueUserBuilder()
			.setQueueId(objQueueRecord.Id)
			.setUserId(objUser1.Id)
			.setUsedCapacity(45)
			.setMaxCapacity(50)
			.build();
		insert objQueueUser;
	}

	/**
	 * @Author      : Debasmiota Rawooth
	 * @Description : Test method for checkRoleProfileOfUser
	 **/
	@IsTest
	static void testCheckRoleProfileOfUser() {
		Id userId = [SELECT Id FROM User WHERE Email = 'user1@example.com'].Id;
		Test.startTest();
		OrderBannerController.checkRoleProfileOfUser(userId);
		Test.stopTest();
	}

	/**
	 * @Author      : Debasmiota Rawooth
	 * @Description : Test method for Banner 1
	 **/
	@IsTest
	static void testCheckPTCapacityMorethan80() {
		Decimal decTotalTimeCommitment = 23;
		String strOrderStatus = 'Drafted';
		List<GradientWorks__Queue__c> list_queue = [
			SELECT Id, Order_Assignment_Start_Date__c, Order_Assignment_End_Date__c
			FROM GradientWorks__Queue__c
			WHERE Name = 'PT - Orders Queue - Week Test 1'
		];
		List<Order> list_order = [SELECT Id, First_Check_Date__c, Status FROM Order WHERE Status = 'Drafted'];
		Date dtFirstCheckDate = list_order[0].First_Check_Date__c;
		String strClosedOwnerDivision = 'Partner';

		Test.startTest();
		OrderBannerController.QueueResult queueResult = OrderBannerController.getQueueRecord(decTotalTimeCommitment, strOrderStatus, dtFirstCheckDate, strClosedOwnerDivision);
		Test.stopTest();

		System.assertEquals(true, queueResult.blnUsedCapacityMoreThanLimit, 'Used capacity not calculated correctly.');
	}

	/**
	 * @Author      : Debasmiota Rawooth
	 * @Description : Test method for Banner 2
	 **/
	@IsTest
	static void testCheckNoRepsWithEnoughCapacity() {
		Decimal decTotalTimeCommitment = 23;
		String strOrderStatus = 'Drafted';
		List<Order> list_order = [SELECT Id, First_Check_Date__c, Status FROM Order WHERE Status = 'Drafted'];
		Date dtFirstCheckDate = list_order[0].First_Check_Date__c;
		String strClosedOwnerDivision = 'Partner';
		Test.startTest();
		OrderBannerController.QueueResult queueResult = OrderBannerController.getQueueRecord(decTotalTimeCommitment, strOrderStatus, dtFirstCheckDate, strClosedOwnerDivision);
		Test.stopTest();
		System.assertEquals(true, queueResult.blnNoRepsWithEnoughCapacity, 'Rep capacity not calculated correctly.');
	}

	/**
	 * @Author      : Debasmiota Rawooth
	 * @Description : Test method for Banner 3
	 **/
	@IsTest
	static void testCheckNoRepsWithRightSkillsHaveCapacity() {
		Decimal decTotalTimeCommitment = 23;
		String strOrderStatus = 'Drafted';
		List<Order> list_order = [SELECT Id, First_Check_Date__c, Status FROM Order WHERE Status = 'Drafted'];
		Date dtFirstCheckDate = list_order[0].First_Check_Date__c;
		String strClosedOwnerDivision = 'Partner';
		GradientWorks__QueueUser__c objQueueUser = [SELECT Id, GradientWorks__Used_Capacity__c, GradientWorks__Maximum_Capacity__c FROM GradientWorks__QueueUser__c];
		objQueueUser.GradientWorks__Used_Capacity__c = 10;
		update objQueueUser;

		Test.startTest();
		OrderBannerController.QueueResult queueResult = OrderBannerController.getQueueRecord(decTotalTimeCommitment, strOrderStatus, dtFirstCheckDate, strClosedOwnerDivision);
		Test.stopTest();
		System.assertEquals(false, queueResult.blnRtmPtTeamHasCapacity, 'Capacity of Reps with skills not calculated correctly.');
	}

	/**
	 * @Author      : Debasmiota Rawooth
	 * @Description : Test method for Banner 4
	 **/
	@IsTest
	static void testCheckPtTeamAtCapacity() {
		Decimal decTotalTimeCommitment = 50;
		String strOrderStatus = 'Drafted';
		List<Order> list_order = [SELECT Id, First_Check_Date__c, Status FROM Order WHERE Status = 'Drafted'];
		Date dtFirstCheckDate = list_order[0].First_Check_Date__c;
		String strClosedOwnerDivision = 'Partner';
		GradientWorks__QueueUser__c objQueueUser = [SELECT Id, GradientWorks__Used_Capacity__c, GradientWorks__Maximum_Capacity__c FROM GradientWorks__QueueUser__c];
		objQueueUser.GradientWorks__Used_Capacity__c = 50;
		update objQueueUser;

		Test.startTest();
		OrderBannerController.QueueResult queueResult = OrderBannerController.getQueueRecord(decTotalTimeCommitment, strOrderStatus, dtFirstCheckDate, strClosedOwnerDivision);
		Test.stopTest();
		System.assertEquals(true, queueResult.blnPtTeamIsAtCapacity, 'PT team capacity not calculated correctly.');
	}
}