/*****************************************************************************************************************************
 * Info : CreateEditOrdersFacilitatorCheckListCtrl is used to cover CreateEditOrdFaciChkLstCtrlTest
 *        which is related with 'Feed Comment', Order, User, Account and 'Order Facilitator Checklist' Object.
 *
 * Created by : Lirik on 10/22/2019
 ******************************************************************************************************************************/
@isTest
public class CreateEditOrdFaciChkLstCtrlTest {
	@testSetup
	private static void setupTestData() {
		//Create a user who will be the facilitator
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User'];

		User objFacilitator = new TestDataFactory.UserBuilder()
			.setAlias('tuser')
			.setEmail('facilitator@testorg.com')
			.setFirstName('Test')
			.setLastName('User')
			.setProfileId(p.Id)
			.setUserName('facilitator@testorg.com')
			.setIsActive(true)
			.build();
		insert objFacilitator;

		//Insert Account
		Account account = new Account();
		account.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		account.ZP_Company_Id__c = 'TestChkLst241019';
		account.Name = 'TestAccountChecklist';

		Account account1 = new Account();
		account1.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		account1.ZP_Company_Id__c = 'TestChkLst241020';
		account1.Name = 'TestAccountChecklist';

		AccountTriggerHelper.skiptrigger = true;
		insert new List<Account>{ account, account1 };

		//Contact
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setAccountId(account.Id)
			.setEmail('testAddress1@domain.com')
			.setFirstName('fName1')
			.setLastName('lName1')
			.build();
		insert objContact1;

		//Opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
			.setAccountId(account.Id)
			.setName('TestOppty1')
			.setCloseDate(Date.today())
			.setStage('New')
			.build();

		Opportunity objOpportunity1 = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
			.setAccountId(account1.Id)
			.setName('TestOppty1')
			.setCloseDate(Date.today())
			.setStage('New')
			.build();

		OpportunityTriggerHelper.skiptrigger = true;
		insert new List<Opportunity>{ objOpportunity, objOpportunity1 };

		//Order
		
		
		Order objOrder = new TestDataFactory.OrderBuilder()
		.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
		.setAccountId(account.Id)
		.setOpportunityId(objOpportunity.Id)
		.setDataEntryAssist(objFacilitator.Id)
		.setEffectiveDate(Date.today())
		.setStatus('Drafted')
		.build();

		Order objOrder1 = new TestDataFactory.OrderBuilder()
		.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
		.setAccountId(account.Id)
		.setOpportunityId(objOpportunity.Id)
		.setDataEntryAssist(objFacilitator.Id)
		.setEffectiveDate(Date.today())
		.setStatus('Drafted')
		.build();

		OrderTriggerHelper.skipTrigger = true;
		insert new List<Order>{ objOrder, objOrder1 };

		//Case
		Case objCase = new Case(
			Subject = 'Test CAse',
			Order__c = objOrder.Id,
			RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Transfer Case'),
			ContactId = objContact1.Id
		);

		insert objCase;

		//insert BMR
		Bulk_Migration_Request__c objBMR = new Bulk_Migration_Request__c();
		insert objBMR;

		OrderTriggerHelper.SkipTrigger = true;
		objOrder.Case__c = objCase.Id;
		objOrder.Bulk_Migration__c = objBMR.Id;
		objOrder1.Bulk_Migration__c = objBMR.Id;
		update new List<Order>{ objOrder, objOrder1 };

		Id idBenefitsMasterChk = Cache.getRecordTypeId('BOR_Master_Checklist__c', 'Payroll');

		List<BOR_Master_Checklist__c> masterCheckList = new List<BOR_Master_Checklist__c>();
		BOR_Master_Checklist__c checkList1 = new BOR_Master_Checklist__c(RecordTypeId = idBenefitsMasterChk);
		checklist1.BOR_Checklist_Name__c = '* Added Employees';
		checklist1.Sequence__c = 1;
		checklist1.Mandatory__c = true;
		checklist1.BOR_Checklist_Status__c = 'Active';
		masterCheckList.add(checklist1);
		BOR_Master_Checklist__c checkList2 = new BOR_Master_Checklist__c(RecordTypeId = idBenefitsMasterChk);
		checklist2.BOR_Checklist_Name__c = '* Added Historical Payrolls + QA\'d';
		checklist2.Sequence__c = 2;
		checklist2.Mandatory__c = true;
		checklist2.BOR_Checklist_Status__c = 'Active';
		masterCheckList.add(checklist2);
		BOR_Master_Checklist__c checkList3 = new BOR_Master_Checklist__c(RecordTypeId = idBenefitsMasterChk);
		checklist3.BOR_Checklist_Name__c = 'Test CheckList3';
		checklist3.Sequence__c = 3;
		checklist3.Mandatory__c = true;
		checklist3.BOR_Checklist_Status__c = 'Active';
		masterCheckList.add(checklist3);
		insert masterCheckList;
	}

	@isTest
	private static void testSaveChecklistWithAssociatedOrder() {
		List<Order> lstOrder = [SELECT Id FROM Order WHERE RecordType.Name = 'Company Migration' LIMIT 1];
		Order objOrder = lstOrder != null ? lstOrder[0] : null;
		if (objOrder != null) {
			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objOrder);

			test.startTest();
			CreateEditOrderFacilitatorChecklistCtrl ctrl = new CreateEditOrderFacilitatorChecklistCtrl(stdCtrl);
			ctrl.saveChecklists();

			System.assert([SELECT COUNT() FROM Order_FAcilitator_Checklist__c WHERE Order__c = :objOrder.Id] > 0, 'Order count should be greater than 0.');
			test.stopTest();
		}
	}

	@isTest
	private static void testSaveChecklistWithoutOrder() {
		Order objOrder = new Order();

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objOrder);

		test.startTest();
		CreateEditOrderFacilitatorChecklistCtrl ctrl = new CreateEditOrderFacilitatorChecklistCtrl(stdCtrl);
		ctrl.saveChecklists();

		System.assert([SELECT COUNT() FROM Order_FAcilitator_Checklist__c] == 0, 'Count should be 0.');
		test.stopTest();
	}

	@isTest
	private static void testSaveChecklistWithOrderIdAndFeed() {
		List<Order> lstOrder = [SELECT Id FROM Order WHERE RecordType.Name = 'Company Migration' LIMIT 1];
		Order objOrder = lstOrder != null ? lstOrder[0] : null;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Order());

		PageReference pageRef = Page.CreateEditOrderFacilitatorChecklist;
		pageRef.getParameters().put('orderId', objOrder.Id);
		test.setCurrentPageReference(pageRef);
		test.startTest();
		CreateEditOrderFacilitatorChecklistCtrl ctrl = new CreateEditOrderFacilitatorChecklistCtrl(stdCtrl);
		ctrl.saveChecklistNRefresh();

		System.assert(null != ctrl.lstOrderFacilitatorChkLst && ctrl.lstOrderFacilitatorChkLst.size() > 0, 'List should have more than 0 items.');

		//Insert feed Data
		FeedItem feeItem = new FeedItem();
		feeItem.ParentId = ctrl.lstOrderFacilitatorChkLst[0].id;
		feeItem.body = System.UserInfo.getUserName();
		FeedItemTriggerHelper.skipTrigger = true;
		insert feeItem;

		User facilitator = [SELECT Id FROM USer WHERE Profile.Name = 'Direct Sales User' AND isActive = TRUE LIMIT 1];
		System.runAs(facilitator) {
			FeedComment feedCom = new FeedComment(
				FeedItemId = feeItem.id,
				CommentType = 'TextComment',
				CommentBody = System.UserInfo.getFirstName() + ' ' + System.UserInfo.getLastName()
			);
			FeedCommentTriggerHelper.skipTrigger = true;
			insert feedCom;

			FeedItem fItem = new FeedItem();
			fItem.ParentId = ctrl.lstOrderFacilitatorChkLst[1].id;
			fItem.body = 'Feed Item by Facilitator';
			FeedItemTriggerHelper.skipTrigger = true;
			insert fItem;
		}

		ctrl.loadFeedItems();

		System.assert(ctrl.lstOrderChklstWrapper != null, 'lstOrderChklstWrapper should not be null.');
		System.assert(ctrl.lstOrderChklstWrapper.size() > 0, 'Size of lstOrderChklstWrapper should be greater than 0.');
		System.assert(ctrl.lstOrderChklstWrapper[0].strLastAdvocateComment != '', 'strLastAdvocateComment should not be empty string.');

		test.stopTest();
	}

	@isTest
	private static void testChecklistOperations() {
		List<Order> lstOrder = [SELECT Id FROM Order WHERE RecordType.Name = 'Company Migration' LIMIT 1];
		Order objOrder = lstOrder != null ? lstOrder[0] : null;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objOrder);

		test.startTest();
		CreateEditOrderFacilitatorChecklistCtrl ctrl = new CreateEditOrderFacilitatorChecklistCtrl(stdCtrl);
		System.assert(null != ctrl.lstOrderChklstWrapper && ctrl.lstOrderChklstWrapper.size() > 0, 'lstOrderChklstWrapper should have more than 0 items.');

		//select checklists
		ctrl.lstOrderChklstWrapper[0].objOrderChkLst.Is_Checked__c = true;
		ctrl.lstOrderChklstWrapper[1].objOrderChkLst.Is_Checked__c = true;

		ctrl.saveChecklists();
		//run as facilitator
		User facilitator = [SELECT Id FROM USer WHERE Profile.Name = 'Direct Sales User' AND isActive = TRUE LIMIT 1];
		System.runAs(facilitator) {
			ctrl = new CreateEditOrderFacilitatorChecklistCtrl(stdCtrl);

			//set as Complete
			ctrl.intWrapIndex = 0;
			ctrl.lstOrderChklstWrapper[0].objOrderChkLst.Is_Completed__c = true;
			ctrl.strFieldName = 'Completed';
			ctrl.toggleComplete();
			ctrl.saveChecklists();

			//set as blocked
			ctrl.intWrapIndex = 0;
			ctrl.lstOrderChklstWrapper[0].objOrderChkLst.Is_Blocked__c = true;
			ctrl.strFieldName = 'Blocked';

			ctrl.toggleComplete();
			ctrl.saveChecklists();
			System.assert(!ctrl.lstOrderChklstWrapper[0].objOrderChkLst.Is_Completed__c, 'Is Completed should be false.');
		}
		//add new checklist
		ctrl.addNewCheckList();
		ctrl.lstNewOrderChk[0].objOrderChkLst.Checklist_Name__c = 'New Checklist';

		//ctrl.saveChecklists();
		ctrl.selectAllchecklists();
		//remove checklist
		ctrl.intIndxToBeRemoved = 0;
		ctrl.bool_IsNewChkToBeRemoved = false;
		ctrl.removeChecklist();

		ctrl.intIndxToBeRemoved = 0;
		ctrl.bool_IsNewChkToBeRemoved = true;
		ctrl.removeChecklist();

		test.stopTest();
	}

	@isTest
	private static void testCopyChecklists() {
		List<Order> lstOrder = [SELECT Id FROM Order WHERE RecordType.Name = 'Company Migration' LIMIT 1];
		Order objOrder = lstOrder != null ? lstOrder[0] : null;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objOrder);

		test.startTest();
		CreateEditOrderFacilitatorChecklistCtrl ctrl = new CreateEditOrderFacilitatorChecklistCtrl(stdCtrl);
		System.assert(null != ctrl.lstOrderChklstWrapper && ctrl.lstOrderChklstWrapper.size() > 0, 'lstOrderChklstWrapper should have more than 0 items.');

		//select checklists
		ctrl.lstOrderChklstWrapper[0].objOrderChkLst.Is_Checked__c = true;
		ctrl.lstOrderChklstWrapper[1].objOrderChkLst.Is_Checked__c = true;

		ctrl.saveAndCopychecklists();

		System.assert([SELECT COUNT() FROM Order_Facilitator_Checklist__c] > 3, 'Count should be more than 3.');
		test.stopTest();
	}

	@isTest
	private static void testSaveChecklists() {
		List<Order> lstOrder = [
			SELECT Id, Data_Entry_Assist__c
			FROM Order
			WHERE RecordType.Name = 'Company Migration'
			LIMIT 1
		];
		Order objOrder = lstOrder != null ? lstOrder[0] : null;
		OrderTriggerHelper.skipTrigger = true;
		objOrder.Data_Entry_Assist__c = UserInfo.getUserId();
		update objOrder;
		OrderTriggerHelper.skipTrigger = false;
		Analytics_Time_Tracker__c objTracker = new Analytics_Time_Tracker__c(
			Order__c = objOrder.Id,
			Start_Date__c = DateTime.now()
		);
		insert objTracker;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objOrder);
		test.startTest();
		CreateEditOrderFacilitatorChecklistCtrl ctrl = new CreateEditOrderFacilitatorChecklistCtrl(stdCtrl);
		System.assert(null != ctrl.lstOrderChklstWrapper && ctrl.lstOrderChklstWrapper.size() > 0, 'lstOrderChklstWrapper should have more than 0 items.');
		ctrl.saveChecklists();
		ctrl.selectAll = true;
		for (CreateEditOrderFacilitatorChecklistCtrl.OrderChecklistWrapper objWrap : ctrl.lstOrderChklstWrapper) {
			objWrap.objOrderChkLst.Is_Completed__c = true;
		}
		ctrl.saveChecklists();
		test.stopTest();
	}

	
    /**
     * @Author      : Sanjay Paryani
     * @Description : Tests if on entering Blocked Reason, the due date is allowed to be today and order is saved succesfully
     * @Parm        : NA
     * @Return      : NA
    **/
	@isTest
	private static void test_BlockedReasonEntered() {
		List<Order> list_Orders = [
			SELECT Id, Data_Entry_Assist__c, Blocked_Reason__c
			FROM Order
			WHERE RecordType.Name = 'Company Migration'
			LIMIT 1
		];
		Order objOrder = list_Orders != null ? list_Orders[0] : null;
		OrderTriggerHelper.skipTrigger = true;
		objOrder.Data_Entry_Assist__c = UserInfo.getUserId();
		update objOrder;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objOrder);

		Test.startTest();
		CreateEditOrderFacilitatorChecklistCtrl objChecklistController = new CreateEditOrderFacilitatorChecklistCtrl(
			stdCtrl
		);
		System.assert(
			objChecklistController.lstOrderChklstWrapper != null &&
			objChecklistController.lstOrderChklstWrapper.size() > 0,
			'lstOrderChklstWrapper should have more than 0 items.'
		);

		objChecklistController.selectAll = false;

		objChecklistController.objFollowUpOrder.Facilitator_Follow_Up_Date__c = Date.today();
		objChecklistController.objFollowUpOrder.Facilitator_Follow_Up_Date_Reason__c = 'Other';
		objChecklistController.objFollowUpOrder.Blocked_Reason__c = 'Pausing this account for urgent 2FA access elsewhere';

		objChecklistController.saveChecklists();

		list_Orders = [
			SELECT Id, Data_Entry_Assist__c, Blocked_Reason__c
			FROM Order
			WHERE RecordType.Name = 'Company Migration' AND Blocked_Reason__c != NULL
		];

		Test.stopTest();

		System.assert(list_Orders.size() > 0, 'There should be more than 0 orders.');
		System.assertEquals(
			'Pausing this account for urgent 2FA access elsewhere',
			list_Orders.get(0).Blocked_Reason__c,
			'Blocked reason should match.'
		);
	}

	
	/**
     * @Author      : Sanjay Paryani
     * @Description : Tests if on entering Blocked Reason, but no follow up date reason order still saves without error.
     * @Parm        : NA
     * @Return      : NA
    **/
	@isTest
	private static void test_FollowUpDateReasonNullForToday() {
		List<Order> list_Orders = [
			SELECT Id, Data_Entry_Assist__c, Blocked_Reason__c
			FROM Order
			WHERE RecordType.Name = 'Company Migration'
			LIMIT 1
		];
		Order objOrder = list_Orders != null ? list_Orders[0] : null;
		OrderTriggerHelper.skipTrigger = true;
		objOrder.Data_Entry_Assist__c = UserInfo.getUserId();
		update objOrder;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objOrder);

		Test.startTest();
		CreateEditOrderFacilitatorChecklistCtrl objChecklistController = new CreateEditOrderFacilitatorChecklistCtrl(
			stdCtrl
		);
		System.assert(
			objChecklistController.lstOrderChklstWrapper != null &&
			objChecklistController.lstOrderChklstWrapper.size() > 0,
			'lstOrderChklstWrapper should have more than 0 items.'
		);

		objChecklistController.selectAll = true;

		objChecklistController.objFollowUpOrder.Facilitator_Follow_Up_Date__c = Date.today();
		objChecklistController.objFollowUpOrder.Blocked_Reason__c = 'Pausing this account for urgent 2FA access elsewhere';

		objChecklistController.saveChecklists();

		list_Orders = [
			SELECT Id, Data_Entry_Assist__c, Blocked_Reason__c
			FROM Order
			WHERE RecordType.Name = 'Company Migration' AND Blocked_Reason__c != NULL
		];

		Test.stopTest();

		System.assert(list_Orders.size() > 0, 'There should be more than 0 orders.');
		System.assert(!objChecklistController.missingRequiredField(), 'No required field should be missing.');
	}

	/**
     * @Author      : Sanjay Paryani
     * @Description : Tests if for future follow up date, but no follow up date reason order fails with error.
     * @Parm        : NA
     * @Return      : NA
    **/
	@isTest
	private static void test_FollowUpDateReasonNullForFutureDate() {
		List<Order> list_Orders = [
			SELECT Id, Data_Entry_Assist__c, Blocked_Reason__c
			FROM Order
			WHERE RecordType.Name = 'Company Migration'
			LIMIT 1
		];
		Order objOrder = list_Orders != null ? list_Orders[0] : null;
		OrderTriggerHelper.skipTrigger = true;
		objOrder.Data_Entry_Assist__c = UserInfo.getUserId();
		update objOrder;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objOrder);

		Test.startTest();
		CreateEditOrderFacilitatorChecklistCtrl objChecklistController = new CreateEditOrderFacilitatorChecklistCtrl(
			stdCtrl
		);
		System.assert(
			objChecklistController.lstOrderChklstWrapper != null &&
			objChecklistController.lstOrderChklstWrapper.size() > 0,
			'lstOrderChklstWrapper should have more than 0 items.'
		);

		objChecklistController.selectAll = true;

		objChecklistController.objFollowUpOrder.Facilitator_Follow_Up_Date__c = Date.today().addDays(2);

		objChecklistController.saveChecklists();

		list_Orders = [
			SELECT Id, Data_Entry_Assist__c, Blocked_Reason__c
			FROM Order
			WHERE RecordType.Name = 'Company Migration' AND Blocked_Reason__c != NULL
		];

		Test.stopTest();

		System.assert(list_Orders.size() == 0, 'There should be 0 orders.');
		System.assert(objChecklistController.missingRequiredField(), 'Required field should be missing.');
	}	
}