/**
 * @name         BTAssignmentUtilTest
 * @author       Deepika
 * @date         24-02-2020
 * @description  Test class for BTAssignmentUtil
 * @revisions    Date ------------ Name ------------ Comments
 **/
@istest
private class BTAssignmentUtilTest {
	@testsetup
	public static void setupTestData() {
		skipTrigger(true);
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setActiveTadaProvider('alegeus').build();
		insert objConfigSettings;
		List<Profile> list_Profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User objUser1 = new User(
			ProfileId = list_Profiles[0].Id,
			LastName = 'User1',
			firstName = 'My',
			Email = 'myfirstuser@gusto.com',
			Username = 'myfirstuser@testgusto.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			IsActive = true,
			Out_Of_Office__c = false,
			Back_In_Office_Date_Time__c = system.today()
		);
		insert objUser1;

		User objUser2 = new User(
			ProfileId = list_Profiles[0].Id,
			LastName = 'User2',
			firstName = 'My',
			Email = 'myseconduser@gusto.com',
			Username = 'myseconduser@testgusto.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			IsActive = true,
			Out_Of_Office__c = false,
			Back_In_Office_Date_Time__c = System.today()
		);
		insert objUser2;

		list<Opportunity> list_Opp = new List<Opportunity>();

		Opportunity objOpp = TestUtility.BenefitsBoROpportunity();
		objOpp.Id__c = 'HIBORTRANSFERzp9989888';
		list_Opp.add(objOpp);

		Opportunity objOpp2 = TestUtility.BenefitsBoROpportunity();
		objOpp2.Id__c = 'HIBORTRANSFERzp9989889';
		list_Opp.add(objOpp2);

		Opportunity objOpp3 = TestUtility.BenefitsBoROpportunity();
		objOpp3.Id__c = 'HIBORTRANSFERzp99898891';
		list_Opp.add(objOpp3);

		Opportunity objOpp4 = TestUtility.BenefitsBoROpportunity();
		objOpp4.Id__c = 'HIBORTRANSFERzp99898892';
		list_Opp.add(objOpp4);

		Opportunity objOpp5 = TestUtility.BenefitsBoROpportunity();
		objOpp5.Id__c = 'HIBORTRANSFERzp99898893';
		list_Opp.add(objOpp5);

		update list_Opp;

		Account newAcc = new Account(id = objOpp2.AccountId, ParentId = objOpp.AccountId);
		update newAcc;

		//=========================Carrier creation==========================
		Carrier__c objCarrier = TestUtility.Carrier();
		objCarrier.Name = 'Alegeus';
		objCarrier.Key__c = 'alegeus32199';
		objCarrier.ID__c = 'alegeus32199';
		objCarrier.Partner_type__c = 'TAdA';
		update objCarrier;

		Carrier__c objCarrier1 = TestUtility.Carrier();
		objCarrier1.Name = 'Amerihealth';
		objCarrier1.Key__c = 'Amerihealth32199';
		objCarrier1.ID__c = 'Amerihealth32199';
		update objCarrier1;

		//======================benefit order creation======================================
		Id idBenefitsBoR = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
		Id idTTFBoRRecordTypeId = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BoR');

		Benefit_Order__c objBORec = new Benefit_Order__c(
			Opportunity__c = objOpp.id,
			Account__c = objOpp.AccountID,
			UW_Owner__c = UserInfo.getUserId(),
			Is_Multi_EIN__c = true,
			Order_Status__c = 'Ready for Qualification',
			BOR_ID__c = 'zp9989888',
			RecordTypeId = idBenefitsBoR,
			Type__c = 'BOR',
			OwnerId = objUser1.Id
		);

		Benefit_Order__c objBORecNonTaDa = new Benefit_Order__c(
			Opportunity__c = objOpp2.id,
			Account__c = objOpp2.AccountId,
			UW_Owner__c = UserInfo.getUserId(),
			Is_Multi_EIN__c = true,
			Order_Status__c = 'Ready for Qualification',
			BOR_ID__c = 'zp9989889',
			RecordTypeId = idBenefitsBoR,
			Type__c = 'BOR'
		);

		Benefit_Order__c objBORecBORTADA = new Benefit_Order__c(
			Opportunity__c = objOpp3.id,
			Account__c = objOpp3.AccountId,
			UW_Owner__c = UserInfo.getUserId(),
			Order_Status__c = 'Ready for Qualification',
			BOR_ID__c = 'zp99898891',
			RecordTypeId = idBenefitsBoR,
			Type__c = 'BOR + TAdA'
		);

		Benefit_Order__c objBORecBOROnly = new Benefit_Order__c(
			Opportunity__c = objOpp4.id,
			Account__c = objOpp4.AccountId,
			UW_Owner__c = UserInfo.getUserId(),
			Order_Status__c = 'Ready for Qualification',
			BOR_ID__c = 'zp99898892',
			RecordTypeId = idBenefitsBoR,
			Type__c = 'BOR TAdA Only'
		);

		insert new List<Benefit_Order__c>{ objBOrec, objBORecNonTaDa, objBORecBORTADA, objBORecBOROnly };

		//=========================Transition to fulfillment=============================
		Transition_to_Fulfillment__c objTTFRecord = new Transition_to_Fulfillment__c(
			Opportunity__c = objOpp.Id,
			Account__c = objOpp.AccountId,
			FSA_Renewal_Date__c = System.today(),
			Benefit_Order__c = objBORec.Id,
			Type_of_Transfer_TADA_s__c = 'FSA;Commuter',
			Multi_EIN__c = 'Y'
		);

		Transition_to_Fulfillment__c objTTFRecord1 = new Transition_to_Fulfillment__c(
			Opportunity__c = objOpp2.Id,
			Account__c = objOpp2.AccountId,
			Benefit_Order__c = objBORecNonTaDa.id,
			Medical_Renewal_Date__c = 'Amerihealth32199>2020/4/27',
			Dental_Renewal_Date__c = 'Amerihealth32199>2020/4/27',
			Multi_EIN__c = 'Y',
			Type_of_TADA_s__c = 'Flexible Spending Account - Dependent Care',
			RecordTypeId = idTTFBoRRecordTypeId
		);

		Transition_to_Fulfillment__c objTTFRecord2 = new Transition_to_Fulfillment__c(
			Opportunity__c = objOpp3.Id,
			Account__c = objOpp3.AccountId,
			Benefit_Order__c = objBORecBORTADA.id,
			Medical_Renewal_Date__c = 'Amerihealth32199>2020/4/27',
			FSA_Renewal_Date__c = System.today()
		);

		Transition_to_Fulfillment__c objTTFRecord3 = new Transition_to_Fulfillment__c(
			Opportunity__c = objOpp4.Id,
			Account__c = objOpp4.AccountId,
			Benefit_Order__c = objBORecBOROnly.id,
			Medical_Renewal_Date__c = 'Amerihealth32199>2020/4/27'
		);

		insert new List<Transition_to_Fulfillment__c>{ objTTFRecord, objTTFRecord1, objTTFRecord2, objTTFRecord3 };

		//======================HI BOR Transfer==============START================
		//tada
		HI_BoR_Transfer__c objHIBor = new HI_BoR_Transfer__c(
			Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "commuter"=>"Zenefits"}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}',
			Id__c = 'zp9989888',
			Benefit_Types__c = '["fsa", "commuter"]'
		);
		//non tada
		HI_BoR_Transfer__c objHIBor1 = new HI_BoR_Transfer__c(
			Additional_Information__c = '{"administrators"=>{}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}',
			Id__c = 'zp9989889',
			Benefit_Types__c = '["medical", "dental"]'
		);

		//BO + tada
		HI_BoR_Transfer__c objHIBor2 = new HI_BoR_Transfer__c(
			Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits"}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}',
			Id__c = 'zp99898891',
			Benefit_Types__c = '["medical", "fsa"]'
		);

		HI_BoR_Transfer__c objHIBor3 = new HI_BoR_Transfer__c(
			Additional_Information__c = '{"administrators"=>{}, "title"=>"Benefits Administrator", "effective_month"=>1, "effective_month_same_as_medical"=>"yes"}',
			Id__c = 'zp99898892',
			Benefit_Types__c = '["medical"]'
		);

		insert new List<HI_BoR_Transfer__c>{ objHIBor, objHIBor1, objHIBor2, objHIBor3 };

		//=============user skills setup============Start===========
		list<User_Role__c> list_userRoles = new List<User_Role__c>();

		User_Role__c objUserRole = new User_Role__c();
		objUserRole.User__c = objUser1.Id;
		list_UserRoles.add(objUserRole);

		User_Role__c objUserRole1 = new User_Role__c();
		objUserRole1.User__c = objUser2.Id;
		list_UserRoles.add(objUserRole1);

		User_Role__c objUserRole2 = new User_Role__c();
		objUserRole2.User__c = UserInfo.getUserId();
		list_UserRoles.add(objUserRole2);

		insert list_UserRoles;

		Role__c objRol = new Role__c();
		objRol.Name = 'Benefit Transfer Facilitator 1';
		insert objRol;

		Role__c objRol2 = new Role__c();
		objRol2.Name = 'Benefit Transfer Advocate';
		insert objRol2;

		list<Skill__c> list_skill = new List<Skill__c>();
		Skill__c objSkill1 = new Skill__c();
		objSkill1.TADA__c = true;
		objSkill1.POD_Skills__c = 'POD 1';
		objSkill1.Role__c = objRol.Id;
		list_skill.add(objSkill1);

		Skill__c objSkill2 = new Skill__c();
		objSkill2.TADA__c = true;
		objSkill2.POD_Skills__c = 'POD 1';
		objSkill2.Role__c = objRol2.Id;
		list_skill.add(objSkill2);

		insert list_skill;

		list<User_Skill__c> list_userSkill = new List<User_Skill__c>();

		User_Skill__c Usr_Skill = new User_Skill__c();
		Usr_Skill.User_Role__c = list_UserRoles.get(0).Id;
		Usr_Skill.Skill_Role_Name__c = 'Benefit Transfer Advocate';
		Usr_Skill.Skill__c = objSkill2.Id;
		list_userSkill.add(Usr_Skill);

		User_Skill__c Usr_Skill2 = new User_Skill__c();
		Usr_Skill2.User_Role__c = list_UserRoles.get(1).Id;
		Usr_Skill2.Skill_Role_Name__c = 'Benefit Transfer Advocate';
		Usr_Skill2.Skill__c = objSkill2.Id;
		list_userSkill.add(Usr_Skill2);

		User_Skill__c Usr_Skill3 = new User_Skill__c();
		Usr_Skill3.User_Role__c = list_userRoles.get(2).Id;
		Usr_Skill3.Skill_Role_Name__c = 'Benefit Transfer Facilitator 1';
		Usr_Skill3.Skill__c = objSkill1.Id;
		list_userSkill.add(Usr_Skill3);

		insert list_userSkill;

		Benefit_Order_Allocation__c objAllocation = new Benefit_Order_Allocation__c();
		objAllocation.User_Role__c = objUserRole.id;
		objAllocation.User__c = objUser1.id;
		objAllocation.Max_BO__c = 5;
		objAllocation.Role_Type__c = 'Advocate';
		objAllocation.Month__c = System.today().month();
		objAllocation.Year__c = System.today().year();
		objAllocation.RecordTypeId = cache.getRecordTypeID('Benefit_Order_Allocation__c', 'Benefits');
		insert objAllocation;

		Benefit_Order_Allocation__c objAllocation1 = new Benefit_Order_Allocation__c();
		objAllocation1.User_Role__c = objUserRole1.id;
		objAllocation1.User__c = objUser2.id;
		objAllocation1.Max_BO__c = 5;
		objAllocation1.Role_Type__c = 'Advocate';
		objAllocation1.Month__c = System.today().month();
		objAllocation1.Year__c = System.today().year();
		objAllocation1.RecordTypeId = cache.getRecordTypeID('Benefit_Order_Allocation__c', 'Benefits');
		insert objAllocation1;

		//==========HI Carrier Info===============START=========================
		list<HI_Carrier_Information__c> list_HICarrier = new List<HI_Carrier_Information__c>();
		HI_Carrier_Information__c objHICarrier = new HI_Carrier_Information__c(BOR_Transfer_Id__c = 'zp9989888', Key__c = 'alegeus32199', Id__c = 'HI99654321', Plan_Type__c = 'fsa');
		list_HICarrier.add(objHICarrier);

		HI_Carrier_Information__c objHICarrier1 = new HI_Carrier_Information__c(BOR_Transfer_Id__c = 'zp9989889', Key__c = 'Amerihealth32199', Id__c = 'HI99654322', Plan_Type__c = 'medical');
		list_HICarrier.add(objHICarrier1);

		HI_Carrier_Information__c objHICarrier2 = new HI_Carrier_Information__c(BOR_Transfer_Id__c = 'zp9989889', Key__c = 'Amerihealth32199', Id__c = 'HI99654323', Plan_Type__c = 'dental');
		list_HICarrier.add(objHICarrier2);

		HI_Carrier_Information__c objHICarrier3 = new HI_Carrier_Information__c(BOR_Transfer_Id__c = 'zp99898891', Key__c = 'Amerihealth32199', Id__c = 'HI99654324', Plan_Type__c = 'medical');
		list_HICarrier.add(objHICarrier3);

		HI_Carrier_Information__c objHICarrier4 = new HI_Carrier_Information__c(BOR_Transfer_Id__c = 'zp99898892', Key__c = 'Amerihealth32199', Id__c = 'HI99654325', Plan_Type__c = 'medical');
		list_HICarrier.add(objHICarrier4);

		HICarrierInformationTriggerHelper.isBOInsert = true;
		insert list_HICarrier;
		skipTrigger(false);
		
	}

	/*
	 * @author:         Bhagat Signh
	 * @description:    Tests non assignemnt of Benefit Order to a user
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void assignmentNoBOToUser() {
		Test.startTest();
		skipTrigger(true);
		List<User> list_Users = [SELECT Id FROM User WHERE Email = 'myfirstuser@gusto.com'];
		if (list_Users.size() > 0) {
			List<Benefit_Order__c> list_BOs = [SELECT Id, OwnerId, Initial_Owner__c FROM Benefit_Order__c WHERE OwnerId = :list_Users[0].Id];
			if (list_BOs.size() > 0) {
				delete list_BOs;
			}
		}
		skipTrigger(false);

		List<Benefit_Order__c> list_BOs = [
			SELECT Id, Opportunity__c, Type__c, Order_Status__c, RecordTypeId, Is_Multi_EIN__c, Parent_Benefit_Order__c, Assignment_Message__c, Initial_Owner__c, OwnerId, Account__c
			FROM Benefit_Order__c
			WHERE Opportunity__r.Id__c != 'HIBORTRANSFERzp99898891'
		];

		BTAssignmentUtil objAssignment = new BTAssignmentUtil();
		objAssignment.processBOForAdvocateAssignment(list_BOs, false);

		Test.stopTest();

		list_BOs = [SELECT Id, Initial_Owner__c, Initial_Owner__r.Name, OwnerId FROM Benefit_Order__c WHERE OwnerId = :list_Users[0].Id];
		System.assert(list_BOs.size() == 0);
	}

	/*
	 * @author:         Bhagat Signh
	 * @description:    Tests assignemnt of Benefit Order to a user
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void assignCONegativeCase() {
		Test.startTest();
		List<User> list_Users = [SELECT Id FROM User WHERE Email = 'myfirstuser@gusto.com'];
		List<Benefit_Order__c> list_BOs = new List<Benefit_Order__c>();
		for (Benefit_Order__c objBO : [
			SELECT Id, Opportunity__c, Type__c, Order_Status__c, RecordTypeId, Is_Multi_EIN__c, Parent_Benefit_Order__c, Assignment_Message__c, Initial_Owner__c, OwnerId, Account__c
			FROM Benefit_Order__c
			WHERE OwnerId = :list_Users[0].Id
		]) {
			objBO.OwnerId = null;
			list_BOs.add(objBO);
		}

		BTAssignmentUtil objAssignment = new BTAssignmentUtil();
		objAssignment.processBOForAdvocateAssignment(list_BOs, true);

		Test.stopTest();

		list_BOs = [SELECT Id FROM Benefit_Order__c WHERE OwnerId = :list_Users[0].Id];
		System.assert(list_BOs.size() == 0);
	}

	/*
	 * @author:         Bhagat Signh
	 * @description:    Tests assignemnt of Benefit Order and Carrier orders to a user based on least BO cap set up.
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void assignmentCOBasedOnLeastBOCaps() {
		Test.startTest();
		skipTrigger(true);
		List<User> list_Users = [SELECT Id FROM User WHERE Email = 'myseconduser@gusto.com'];
		List<Opportunity> list_Opps = [SELECT Id, AccountID FROM Opportunity WHERE Id__c = 'HIBORTRANSFERzp99898893'];
		if (list_Opps.size() > 0) {
			Id idBenefitsBoR = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
			Benefit_Order__c objBO = new Benefit_Order__c(
				Opportunity__c = list_Opps[0].id,
				Account__c = list_Opps[0].AccountId,
				UW_Owner__c = UserInfo.getUserId(),
				Is_Multi_EIN__c = true,
				Order_Status__c = 'Ready for Qualification',
				BOR_ID__c = 'zp9989888',
				RecordTypeId = idBenefitsBoR,
				Type__c = 'BOR',
				OwnerId = list_Users[0].Id
			);
			insert objBO;

			Transition_to_Fulfillment__c objTTF = new Transition_to_Fulfillment__c(
				Opportunity__c = list_Opps[0].id,
				Account__c = list_Opps[0].AccountId,
				Benefit_Order__c = objBO.id,
				Medical_Renewal_Date__c = 'Amerihealth32199>2020/4/27'
			);

			insert objTTF;
		}
		skipTrigger(false);

		Id idLoginUser = UserInfo.getUserId();
		List<Carrier_Order__c> list_COs = [
			SELECT
				Benefit_Order__c,
				Id,
				Name,
				Carrier__c,
				Benefit_Types__c,
				Is_Multi_EIN__c,
				Total_Number_Of_Documents__c,
				RecordTypeId,
				Parent_Carrier_Order__c,
				Number_Of_Collected_Documents__c,
				Carrier__r.BT_Facilitator_POD__c,
				Initial_Owner__c,
				Assignment_Message__c,
				OwnerId,
				Implementation_Stage__c,
				Start_Date__c,
				OOO_Timestamp__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__r.Opportunity__r.Id__c != 'HIBORTRANSFERzp99898891'
		];

		List<Benefit_Order__c> list_BOs = [
			SELECT Id, Opportunity__c, Type__c, Order_Status__c, RecordTypeId, Is_Multi_EIN__c, Parent_Benefit_Order__c, Assignment_Message__c, Initial_Owner__c, OwnerId, Account__c
			FROM Benefit_Order__c
			WHERE Opportunity__r.Id__c != 'HIBORTRANSFERzp99898891'
		];

		BTAssignmentUtil objAssignment = new BTAssignmentUtil();
		objAssignment.processBOForAdvocateAssignment(list_BOs, false);
		Id idLastCO;
		for (Carrier_Order__c objCO : list_COs) {
			if (idLastCO == null) {
				idLastCO = objCO.Id;
			} else {
				objCO.Parent_Carrier_Order__c = idLastCO;
			}
			objCO.Start_Date__c = System.today();
		}

		CarrierOrderTriggerHelper.skipTrigger = true;
		update list_COs;

		objAssignment.processCOForFacilitator1Assignment(list_COs, list_COs);
		objAssignment.processBOForAdvocateAssignment(list_BOs, false);

		list_COs = [
			SELECT
				Benefit_Order__c,
				Id,
				Name,
				Carrier__c,
				Benefit_Types__c,
				Number_Of_Collected_Documents__c,
				Total_Number_Of_Documents__c,
				Is_Multi_EIN__c,
				RecordTypeId,
				Parent_Carrier_Order__c,
				Carrier__r.BT_Facilitator_POD__c,
				Initial_Owner__c,
				Assignment_Message__c,
				OwnerId,
				Implementation_Stage__c,
				Start_Date__c,
				OOO_Timestamp__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__r.Opportunity__r.Id__c = 'HIBORTRANSFERzp99898891'
		];
		list_BOs = [
			SELECT Id, Opportunity__c, Type__c, Order_Status__c, RecordTypeId, Is_Multi_EIN__c, Parent_Benefit_Order__c, Assignment_Message__c, Initial_Owner__c, OwnerId, Account__c
			FROM Benefit_Order__c
			WHERE Opportunity__r.Id__c = 'HIBORTRANSFERzp99898891'
		];

		objAssignment.processBOForAdvocateAssignment(list_BOs, false);
		objAssignment.processCOForFacilitator1Assignment(list_COs, list_COs);

		List<String> list_UserIds = new List<string>();
		Set<String> set_UserIds = new Set<string>();
		Map<String, Decimal> map_UserRecordDeciCounts = new Map<String, Decimal>();
		Map<String, Integer> map_UserRecordInteCounts = new Map<String, Integer>();

		list_Users = [SELECT Id FROM User WHERE Email = 'myfirstuser@gusto.com'];
		Decimal decCounter = 1;
		list_UserIds.add(list_Users[0].Id);
		map_UserRecordDeciCounts.put(list_Users[0].Id, decCounter);
		map_UserRecordInteCounts.put(list_Users[0].Id, Integer.valueOf(decCounter));
		decCounter++;
		list_UserIds.add(idLoginUser);
		map_UserRecordDeciCounts.put(idLoginUser, decCounter);
		map_UserRecordInteCounts.put(idLoginUser, integer.valueOf(decCounter));
		set_UserIds.addAll(list_UserIds);

		objAssignment.getEligibleUsersWithLowestCount(list_UserIds, map_UserRecordDeciCounts);
		List<String> list_TempLists = objAssignment.getEligibleUsersWithHighestDocPercentage(set_UserIds, map_UserRecordInteCounts, map_UserRecordInteCounts);
		list_TempLists = objAssignment.getEligibleUsersWithLowestCOCount(set_UserIds, map_UserRecordInteCounts);

		objAssignment.map_skillTypeUserIds.put('bor', new Set<string>{ list_Users[0].Id });

		objAssignment.getCapDetailsForRamping();

		Test.stopTest();

		list_COs = [SELECT Id, Initial_Owner__c, OwnerId, Owner.Name FROM Carrier_Order__c WHERE OwnerId = :list_Users[0].Id];
		System.assert(list_COs.size() == 0);
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    processBOForAdvocateAssignment test
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void processBOForAdvocateAssignmentTest() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [SELECT Id, Benefit_Order__c FROM Carrier_Order__c WHERE Carrier__r.Name = 'Alegeus' LIMIT 1];
		List<Benefit_Order__c> list_BOs = [
			SELECT Id, Opportunity__c, Type__c, Order_Status__c, RecordTypeId, Is_Multi_EIN__c, Parent_Benefit_Order__c, Assignment_Message__c, Initial_Owner__c, OwnerId, Account__c
			FROM Benefit_Order__c
			WHERE ID = :objCarrierOrder.Benefit_Order__c
		];

		BTAssignmentUtil objAssignment = new BTAssignmentUtil();
		objAssignment.processBOForAdvocateAssignment(list_BOs, false);
		System.assert(list_BOs[0].Type__c.containsIgnoreCase('Tada'));
		Test.stopTest();
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    processBOForAdvocateAssignment test
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void processBOForAdvocateAssignmentNegativeTest() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [SELECT Id, Benefit_Order__c FROM Carrier_Order__c WHERE Carrier__r.Name != 'Alegeus' LIMIT 1];
		List<Benefit_Order__c> list_BOs = [
			SELECT Id, Opportunity__c, Type__c, Order_Status__c, RecordTypeId, Is_Multi_EIN__c, Parent_Benefit_Order__c, Assignment_Message__c, Initial_Owner__c, OwnerId, Account__c
			FROM Benefit_Order__c
			WHERE ID = :objCarrierOrder.Benefit_Order__c
		];
		System.debug('objCarrierOrder'+objCarrierOrder);
		System.debug('list_BOs'+list_BOs);
		BTAssignmentUtil objAssignment = new BTAssignmentUtil();
		objAssignment.processBOForAdvocateAssignment(list_BOs, false);
		System.debug('list_BOs'+list_BOs);
		System.assert(!list_BOs[0].Type__c.containsIgnoreCase('Tada'));
		Test.stopTest();
	}

	/*
	 * @author:         Bhagat Singh
	 * @description:    Assgin Case to Benefit Transfer Advocate
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void assignCaseToBenefitTransferAdvocate() {
		Utils.skipTrigger(true);
		Carrier_Order__c objCarrierOrder = [SELECT Id, Benefit_Order__c FROM Carrier_Order__c WHERE Carrier__r.Name = 'Alegeus' LIMIT 1];
		List<Benefit_Order__c> list_BOs = [
			SELECT Id, Opportunity__c, Type__c, Order_Status__c, RecordTypeId, Is_Multi_EIN__c, Parent_Benefit_Order__c, Assignment_Message__c, Initial_Owner__c, OwnerId, Account__c
			FROM Benefit_Order__c
			WHERE ID = :objCarrierOrder.Benefit_Order__c
		];

		String strType = list_BOs[0].Type__c;
		list_BOs[0].OwnerId = UserInfo.getUserId();
		list_BOs[0].Type__c = null;
		update list_BOs[0];

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(list_BOs[0].Account__c)
			.setFirstName('Test')
			.setLastName('User1')
			.setEmail('testuser@abccompany.com')
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(list_BOs[0].Account__c)
			.setRecordTypeId('Benefits BoR')
			.setType('BoR')
			.setSubject('Welcome to Benefits with Gusto!')
			.setOrigin('Hippo')
			.setStatus('New')
			.setSuppliedEmail('CasetriggerHelper@gusto.com')
			.setDescription('Welcome to Benefits with Gusto!')
			.setIntegrationId('hippo-Benefits_BoR-' + list_BOs[0].Opportunity__c)
			.setContactId(objContact.Id)
			.setOpportunity(list_BOs[0].Opportunity__c)
			.setBenefitOrder(list_BOs[0].Id)
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert objCase;
		Utils.skipTrigger(false);

		Test.startTest();

		list_BOs[0].Type__c = strType;
		update list_BOs[0];

		Test.stopTest();

		objCase = [SELECT Id, OwnerId, Benefit_Order__c, Benefit_Order__r.OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCase.Benefit_Order__r.OwnerId, objCase.OwnerId, 'Benefit Order & case is not assigned to  Benefit Transfer Advocate.');
	}

	/*
	 * @author:         Omar Benitez
	 * @description:    Tests non assignemnt of Benefit Order to a Benefit Transfer Queue
	 * @Parm:            N/A
	 * @Return:          N/A
	 */
	@isTest
	static void assignmentNoBOToUserBenefitTransferQueue() {
		Test.startTest();
		skipTrigger(true);
		List<User> list_Users = [SELECT Id FROM User WHERE Email = 'myfirstuser@gusto.com'];
		if (list_Users.size() > 0) {
			List<Benefit_Order__c> list_BOs = [SELECT Id, OwnerId, Initial_Owner__c FROM Benefit_Order__c WHERE OwnerId = :list_Users[0].Id];
			if (list_BOs.size() > 0) {
				delete list_BOs;
			}
		}
		List<Benefit_Order_Allocation__c> objBenefitOrderAllocations = [SELECT ID, Max_BO__c FROM Benefit_Order_Allocation__c];
		for (Benefit_Order_Allocation__c objBOA : objBenefitOrderAllocations) {
			objBOA.Max_BO__c = 0;
		}
		update objBenefitOrderAllocations;
		skipTrigger(false);
		List<Benefit_Order__c> list_BOs = [
			SELECT Id, Opportunity__c, Type__c, Order_Status__c, RecordTypeId, Is_Multi_EIN__c, Parent_Benefit_Order__c, Assignment_Message__c, Initial_Owner__c, OwnerId, Account__c
			FROM Benefit_Order__c
			WHERE Opportunity__r.Id__c != 'HIBORTRANSFERzp99898892' AND Is_Multi_EIN__c = FALSE
		];
		BTAssignmentUtil objAssignment = new BTAssignmentUtil();
		objAssignment.processBOForAdvocateAssignment(list_BOs, false);
		Test.stopTest();
		Id iDBenefitTransferQueue = GlobalQueryHelper.getQueueNameAndIdMap(new Set<String>{ BTBOSideViewCtrl.BENEFIT_TRANSFER_QUEUE }).get(BTBOSideViewCtrl.BENEFIT_TRANSFER_QUEUE);
		for (Benefit_Order__c objBO : list_BOs) {
			System.assertEquals(iDBenefitTransferQueue, objBO.OwnerId, 'Owner should be bt queue');
		}
	}
	/*
	 * @author:         Omar Benitez
	 * @description:    Tests for getUserDataForFAC1
	 */
	@isTest
	static void testGetUserDataForFAC1() {
		Test.startTest();
		BTAssignmentUtil objAssignment = new BTAssignmentUtil();
		objAssignment.getUserDataForFAC1(new Set<String>{ 'POD 1' });
		Test.stopTest();
		System.assertNotEquals(0, objAssignment.map_PODWithUserIds.size(), 'map should not be null');
	}

	public static void skipTrigger(Boolean blnFlag) {
		UserTriggerHelper.skipTrigger = blnFlag;
		BenefitOrderHelper.skipTrigger = blnFlag;
		CarrierOrderTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		TransitiontoFulfilmentTriggerHelper.skipTrigger = blnFlag;
	}
}