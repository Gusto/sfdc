/*****************************************************************************************************************************
 * Info : FeedCommentTriggerHelper is used to cover FeedCommentTriggerHelperTest
 *        which is related with 'Feed Comment', Order, User, Account and 'Order Facilitator Checklist' Object.
 *
 * Created by : Lirik on 10/22/2019
 ******************************************************************************************************************************/
@isTest
public class FeedCommentTriggerHelperTest {
	@isTest
	static void testCallOnfeedCommentTriggerHelper() {
		// insert accounts list
		List<Account> testAccountList = new List<Account>();
		List<Order> lstUpdateOrder = new List<Order>();
		Id companyRecordTypeId = Cache.getRecordTypeId('Account', 'Company');

		for (Integer i = 0; i < 2; i++) {
			Account ac = new TestDataFactory.AccountBuilder().setRecordTypeId(companyRecordTypeId).setName('TestAccount').build();
			testAccountList.add(ac);
		}

		AccounTTriggerHelper.SkipTrigger = true;
		insert testAccountList;

		// assert if accounts are inserted successfully
		for (Account acc : testAccountList) {
			System.assertNotEquals(null, acc.Id, 'Account Id should not be null.');
		}

		Order ord = new Order();
		ord.AccountId = testAccountList[0].Id;
		ord.OwnerId = System.UserInfo.getUserId();
		ord.Active_Employee_Count__c = 10;
		ord.EffectiveDate = System.today();
		ord.Status = 'Drafted';
		ord.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
		ord.Deductions_List__c = 'Test,Test';
		ord.Data_Entry_Assist__c = System.UserInfo.getUserId();
		ord.Bulk_Migration__c = null;
		ord.RecordTypeId = cache.getRecordTypeId('Order', 'Company Migration');
		ord.First_Check_Date__c = System.now().date();
		ord.Facilitator_Due_Date__c = System.now().date();
		ord.Follow_Up_Date__c = System.now().date();
		lstUpdateOrder.add(ord);
		insert lstUpdateOrder;
		ord.OwnerId = System.UserInfo.getUserId();
		update ord;
		List<FeedComment> feeds = new List<FeedComment>();
		Map<ID, FeedComment> newFeedMap = new Map<ID, FeedComment>();

		Order_Facilitator_Checklist__c ordFaciCheck = new Order_Facilitator_Checklist__c(
			Blocked_Username__c = 'UnameTest',
			Checklist_Name__c = 'Test',
			Is_Blocked__c = false,
			Is_Checked__c = true,
			Is_Completed__c = true,
			Order__c = lstUpdateOrder[0].Id
		);
		OrderFacilitatorChecklistTriggerHelper.skipTrigger = true;
		insert ordFaciCheck;

		FeedItem feeItem = new FeedItem();
		feeItem.ParentId = ordFaciCheck.Id;
		feeItem.body = '@' + System.UserInfo.getFirstName() + ' ' + System.UserInfo.getLastName();
		FeedItemTriggerHelper.skipTrigger = true;
		insert feeItem;

		FeedComment feedCom = new FeedComment(
			createddate = System.Today(),
			FeedItemId = feeItem.Id,
			CommentType = 'TextComment',
			CommentBody = '@' + System.UserInfo.getFirstName() + ' ' + System.UserInfo.getLastName()
		);
		FeedCommentTriggerHelper.skipTrigger = true;
		insert feedCom;

		newFeedMap.put(feedCom.Id, feedCom);

		feedCom.CommentBody = System.UserInfo.getUserName();
		FeedCommentTriggerHelper.skipTrigger = true;
		update feedCom;

		newFeedMap.put(feedCom.Id, feedCom);

		delete feedCom;
		FeedCommentTriggerHelperTest feedCommentTrgr = new FeedCommentTriggerHelperTest();
	}
}