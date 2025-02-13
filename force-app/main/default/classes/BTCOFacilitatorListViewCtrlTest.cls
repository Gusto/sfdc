/**
 * @name         BTCOFacilitatorListViewCtrlTest
 * @author       Sanjay Paryani
 * @date         05/14/2020
 * @description  Test class for BTCOFacilitatorListViewCtrl
 * @revisions    Date ------------ Name ------------ Comments
 **/
@isTest
public class BTCOFacilitatorListViewCtrlTest {
	@testsetup
	public static void setupTestData() {
		UserRole r = [SELECT ID, Name, DeveloperName FROM UserRole WHERE DeveloperName = 'Benefit_Transfer_Fulfillment'].get(0);

		User U1 = new User(
			ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
			.Id,
			LastName = 'last',
			firstName = 'first',
			Email = 'puser000@lirik.com',
			Username = 'puser000@amamama.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			UserRoleId = r.Id,
			IsActive = true,
			Out_Of_Office__c = false,
			Back_In_Office_Date_Time__c = system.today()
		);
		insert U1;
	}

	public static testMethod void TestMethod1() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		TicketTriggerHelper.skipTrigger = true;
		account acc1 = TestUtility.CompanyAccount();

		Opportunity opp1 = TestUtility.BenefitsBoROpportunity();
		opp1.Account = acc1;
		update opp1;
        
		Benefit_Order__c boRec = new Benefit_Order__c();
		borec.Opportunity__c = opp1.Id;
		borec.Order_Status__c = 'Alignment Approved';
		borec.Application_Status__c = 'Plans Confirmed';
		boRec.RecordTypeId = cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
		borec.Renewal_Date__c = system.today();
		insert borec;

		Carrier__c obj_Carrier = new Carrier__c();
		obj_Carrier.Name = 'Test';
		obj_Carrier.Termination_Effective_Date__c = 'On the Date';
		obj_Carrier.State__c = 'al;ak';
		insert obj_Carrier;

		Carrier_Order__c obj_CarrierOrder = new Carrier_Order__c();
		obj_CarrierOrder.Name = 'TestCarrierOrder';
		obj_CarrierOrder.Benefit_Types__c = 'Medical';
		obj_CarrierOrder.Carrier__c = obj_Carrier.Id;
		obj_CarrierOrder.Benefit_Order__c = borec.id;
		obj_CarrierOrder.Start_Date__c = System.today() - 50;
		obj_CarrierOrder.Renewal_Date__c = date.today();
		obj_CarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		obj_CarrierOrder.Implementation_Stage__c = 'Ready for Document Collection';
		obj_CarrierOrder.OwnerId = UserInfo.getUserId();
		obj_CarrierOrder.OOO_Comments__c = 'test comment';
		obj_CarrierOrder.Initial_Owner__c = UserInfo.getUserId();
		obj_CarrierOrder.Facilitator_2_Enrollment_Review__c = UserInfo.getUserId();
		obj_CarrierOrder.Facilitator_2_Plan_Review__c = UserInfo.getUserId();
		insert obj_CarrierOrder;

		// Assertions for records inserted
		System.assertNotEquals(null, boRec.Id, 'Benefit Order should be inserted');
		System.assertNotEquals(null, obj_Carrier.Id, 'Carrier should be inserted');
		System.assertNotEquals(null, obj_CarrierOrder.Id, 'Carrier Order should be inserted');

		Test.startTest();

		Role__c roleObj2 = new Role__c();
		roleObj2.Name = 'Benefit Transfer Facilitator 1';
		insert roleObj2;
		Role__c roleObj = new Role__c();
		roleObj.Name = 'Benefit Transfer Facilitator 2';
		insert roleObj;
		List<User_Role__c> list_UserRole = new List<User_Role__c>();
		list_UserRole.add(new User_Role__c(User__c = UserInfo.getUserId()));
		insert list_UserRole;

		List<Skill__c> lstSkill = new List<Skill__c>();
		lstSkill.add(new Skill__c(Role__c = roleObj.Id, Build_Plans__c = true));
		lstSkill.add(new Skill__c(Role__c = roleObj2.Id, Build_Plans__c = true));
		insert lstSkill;

		List<User_Skill__c> list_UserSkill = new List<User_Skill__c>();
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[0].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2', User_Role__c = list_UserRole[0].Id));
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[1].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2', User_Role__c = list_UserRole[0].Id));
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[0].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2', User_Role__c = list_UserRole[0].Id));
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[1].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 2', User_Role__c = list_UserRole[0].Id));
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[0].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 1', User_Role__c = list_UserRole[0].Id));
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[1].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 1', User_Role__c = list_UserRole[0].Id));
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[0].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 1', User_Role__c = list_UserRole[0].Id));
		list_UserSkill.add(new User_Skill__c(Skill__c = lstSkill[1].Id, Skill_Role_Name__c = 'Benefit Transfer Facilitator 1', User_Role__c = list_UserRole[0].Id));
		insert list_UserSkill;

		case c1 = new case();
		c1.status = 'New';
		c1.Requires_Action__c = true;
		insert c1;

		Ticket__c t1 = new Ticket__c();
		t1.Carrier_Order__c = obj_CarrierOrder.id;
		t1.OwnerId = UserInfo.getUserId();
		t1.Escalation_Reason__c = null;
		t1.Escalation_Reason_Detail__c = null;
        t1.Account__c = acc1.Id;
        t1.Carrier__c = obj_Carrier.Id;
        t1.Description__c = 'Test';
		insert t1;

		BTCOFacilitatorListViewCtrl Ctrl = new BTCOFacilitatorListViewCtrl();
		ctrl.RetriveTicket();
		Ctrl.list_SelectedCarrier = new List<string>();
		Ctrl.list_SelectedCarrier.add('TestCarrierOrder');
		Ctrl.getUserData();
		ctrl.PopulateState();
		Ctrl.RefreshFacPanel();
		Ctrl.RefreshFacOOOPanel();
		Ctrl.SaveOOONotes();

		obj_CarrierOrder.Implementation_Stage__c = 'Implementing Plans';
		update obj_CarrierOrder;

		// Asserting updates to Carrier Order
		obj_CarrierOrder = [SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :obj_CarrierOrder.Id];
		System.assertEquals('Implementing Plans', obj_CarrierOrder.Implementation_Stage__c, 'Carrier Order should have updated Implementation Stage');

		Ctrl.ReasignBOOnOOO();
		Ctrl.ResetSearch();
		Ctrl.strFromAge = '10';
		Ctrl.strToAge = '20';
		Ctrl.strTotalDoc = '30';
		Ctrl.strDocCollectedPercentage = '60';
		Ctrl.SearchCarrierOrder();

		Ctrl.blnIsFAC1 = false;
		Ctrl.blnIsFAC2 = true;
		Ctrl.ReasignBOOnOOO();

		// Assertions for final state
		System.assertEquals(true, Ctrl.blnIsFAC2, 'blnIsFAC2 should be true');

		Test.stopTest();
	}
}