@isTest
private class ReassignBenefitOrderOwnerCtrlTest {
	@testSetup
	static void makeData() {
		skipTriggers();

		User objAdminUser = new TestDataFactory.UserBuilder()
			.setUserName('Implementation.Advocate@test.Implementation')
			.setExemptfromValidationRules(true)
			.setEmail('partneram@testorg.com')
			.setProfileId(UserInfo.getProfileId())
			.build();
		insert objAdminUser;

		CaseTeamRole objTeamRole;
		System.runAs(objAdminUser) {
			objTeamRole = new CaseTeamRole(Name = 'Admin', AccessLevel = 'Edit');
			insert objTeamRole;
		}
	}
	
	static void skipTriggers() {
		OppRelatedTrackTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		TaskTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
	}

	@isTest
	static void ReassignBenefitOrderOwnerTestMethod() {
		skipTriggers();

		Test.startTest();
		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account').build();
		insert objAcc;
		Id idOppRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(idOppRecordTypeId)
			.setAccountId(objAcc.Id)
			.setName('Test Opp')
			.setStage('Raw')
			.setCloseDate(System.Today())
			.build();
		insert objOpp;

		Id idBORecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder().setName('Test Benefit Order').setRecordType(idBORecordTypeId).setOpp(objOpp.Id).setStatus('OE').setOwnerID(UserInfo.getUserId()).build();
		insert objBO;
		User objAdminUser = [SELECT Id FROM User WHERE UserName = 'Implementation.Advocate@test.Implementation'];

		objBO.ownerID = UserInfo.getUserId();
		objBO.Coverage_Effective_Date__c = System.today();
		objBO.Open_Enrollment_Start_Date__c = System.today();
		objBO.Open_Enrollment_End_Date__c = System.today();
		objBO.Initial_Owner__c = UserInfo.getUserId();
		objBO.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBO;

		Benefit_Order__c objBO1 = new TestDataFactory.BenefitOrderBuilder().setName('Test Benefit Order').setRecordType(idBORecordTypeId).setOpp(objOpp.Id).setOwnerID(UserInfo.getUserId()).build();
		objBO1.Parent_Benefit_Order__c = objBO.Id;
		insert objBO1;

		List<Id> list_BOIds = new List<Id>();
		ReassignBenefitOrderOwnerCtrl.changeOwner(list_BOIds);

		//Child and Parent Both are selected
		list_BOIds.add(objBO.Id);
		list_BOIds.add(objBO1.Id);
		ReassignBenefitOrderOwnerCtrl.changeOwner(list_BOIds);

		//only parent is Selected
		list_BOIds = new List<Id>();
		list_BOIds.add(objBO.Id);
		ReassignBenefitOrderOwnerCtrl.changeOwner(list_BOIds);
		ReassignBenefitOrderOwnerCtrl.changeOwnerToSelf(list_BOIds);

		System.runAs(objAdminUser) {
			objAdminUser.Out_Of_Office__c = true;
			update objAdminUser;
		}

		objBO.OwnerId = objAdminUser.Id;
		update objBO;
		ReassignBenefitOrderOwnerCtrl.changeOwner(list_BOIds);

		objBO.Order_Status__c = 'Canceled';
		ReassignBenefitOrderOwnerCtrl.changeOwner(list_BOIds);

		list_BOIds = new List<Id>();
		list_BOIds.add(objBO1.Id);
		String strMessage = ReassignBenefitOrderOwnerCtrl.changeOwner(list_BOIds);
		Test.stopTest();
		System.assert(strMessage == 'This Benefit Order is not assigned to you.Only your orders can be moved.');
	}

	@isTest
	static void ReassignBOOwnerTestMethod() {
		skipTriggers();

		Test.startTest();

		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account').build();
		insert objAcc;
		Id idOppRecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(idOppRecordTypeId)
			.setAccountId(objAcc.Id)
			.setName('Test Opp')
			.setStage('Raw')
			.setCloseDate(System.Today())
			.build();
		insert objOpp;

		Id idBORecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder().setName('Test Benefit Order').setRecordType(idBORecordTypeId).setOpp(objOpp.Id).setStatus('OE').setOwnerID(UserInfo.getUserId()).build();
		insert objBO;
		User objAdminUser = [SELECT Id FROM User WHERE UserName = 'Implementation.Advocate@test.Implementation'];

		objBO.OwnerID = objAdminUser.Id;
		objBO.Coverage_Effective_Date__c = System.today();
		objBO.Open_Enrollment_Start_Date__c = System.today();
		objBO.Open_Enrollment_End_Date__c = System.today();
		objBO.Initial_Owner__c = UserInfo.getUserId();
		objBO.Push_Rate_Reason__c = 'Not enough EE enrolled';
		update objBO;

		Benefit_Order__c objBO1 = new TestDataFactory.BenefitOrderBuilder().setName('Test Benefit Order').setRecordType(idBORecordTypeId).setOpp(objOpp.Id).setOwnerID(UserInfo.getUserId()).build();
		objBO1.Parent_Benefit_Order__c = objBO.Id;
		insert objBO1;
		List<Id> list_BOIds = new List<Id>();

		//only parent is Selected
		list_BOIds = new List<Id>();
		list_BOIds.add(objBO.Id);

		User objUser = new User();
		objUser.Id = UserInfo.getUserId();
		objUser.Out_Of_Office__c = false;
		update objUser;
		ReassignBenefitOrderOwnerCtrl.changeOwnerToSelf(list_BOIds);

		objUser.Out_Of_Office__c = true;
		update objUser;
		String strMessage = ReassignBenefitOrderOwnerCtrl.changeOwnerToSelf(list_BOIds);
		Test.stopTest();

		System.assert(strMessage == 'You must return from OOO to reassign your previously owned Benefit Orders back to your queue.');
	}
}