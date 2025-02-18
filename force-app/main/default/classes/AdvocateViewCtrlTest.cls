/********************************************************************
 * Info : AdvocateViewCtrlTest is used to cover AdvocateViewCtrl
 *        which is related with 'Transition to Fulfillment', Account, User, Contact,
 *        Opportunity, Order and Bulk Migration Request Objects.
 *
 * Created by : Lirik on 10/16/2019
 ***********************************************************************/

@isTest
public class AdvocateViewCtrlTest {
	@isTest
	static void testCallOnAdvocateActionView() {
		User adminUser = new TestDataFactory.UserBuilder()
			.setAlias('Admin')
			.setEmail('admin@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('admin@testorg.com.test3')
			.build();
		adminUser.Exempt_from_Validation_Rules__c = true;
		insert adminUser;
		System.assertNotEquals(null, adminUser.Id, 'Incorrect User');
		// Run code by Admin user
		System.runAs(adminUser) {
			// insert accounts list
			List<Account> list_Accounts = new List<Account>();

			for (Integer i = 0; i < 5; i++) {
				Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account' + i).setOnboardingFlow('In-App').build();
				list_Accounts.add(objCompanyAccount);
			}

			AccounTTriggerHelper.SkipTrigger = true;
			insert list_Accounts;

			for (Account acc : list_Accounts) {
				System.assertNotEquals(null, acc.Id, 'Account Insertion Unsuccesful');
			}

			// insert contacts list
			List<Contact> list_Contacts = new List<Contact>();
			for (Integer i = 0; i < 5; i++) {
				Contact objContact = new TestDataFactory.ContactBuilder()
					.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
					.setAccountId(list_Accounts[i].Id)
					.setFirstName('Test' + i)
					.setLastName('User' + i)
					.setEmail('testuser' + i + '@abccompany.com')
					.build();
				list_Contacts.add(objContact);
			}

			ContactTriggerHelper.SkipTrigger = true;
			insert list_Contacts;

			// insert opportunity list
			List<Opportunity> list_Opportunities = new List<Opportunity>();

			for (Integer i = 0; i < 5; i++) {
				Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
					.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
					.setName('Acquisition Opportunity' + i)
					.setAccountId(list_Accounts[i].Id)
					.setStage('Open')
					.setCloseDate(System.today())
					.build();
				list_Opportunities.add(objOpportunity);
			}

			OpportunityTriggerHelper.SkipTrigger = true;
			insert list_Opportunities;

			// assert if opportunities are inserted successfully
			for (Opportunity opp : list_Opportunities) {
				System.assertNotEquals(null, opp.Id, 'Opportunity Insertion Unsuccessful');
			}

			// insert Transition to Fulfillment
			Id RecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
			Transition_to_Fulfillment__c rec = new TestDataFactory.TransitionToFulfillmentBuilder()
				.setRecordTypeId(RecordTypeId)
				.setBenefitsPointOfContact('Test')
				.setOpportunityId(list_Opportunities[0].Id)
				.build();
			rec.Renewal_Exception__c = 'Yes';
			rec.Renewal_Date__c = Date.today();
			rec.Medical_New_Carrier__c = 'aa';
			rec.Dental_Carrier__c = 'aa';
			rec.Vision_Carrier__c = 'aa';
			rec.LiDi_Carrier__c = 'aa';
			rec.FSA_HSA_401K__c = 'aa';
			rec.Contact_Preference__c = 'Call';
			TransitiontoFulfilmentTriggerHelper.SkipTrigger = true;
			insert rec;
			System.assertNotEquals(null, rec.Id, 'Insertion Unsuccessful');

			Order objOrderTemp = new Order();
			objOrderTemp.First_Check_Date__c = System.today();
			objOrderTemp.Follow_Up_Date__c = System.today().addDays(30);
			objOrderTemp.Work_Start_Date__c = System.today();
			objOrderTemp.Requested_Pay_Date__c = System.today().addDays(40);

			// insert Bulk Migration Request
			Bulk_Migration_Request__c bmrRec = new TestDataFactory.BulkMigrationRequestBuilder()
				.setRequestedById(UserInfo.getUserId())
				.setRequestedFirstCheckDate(System.today().addDays(20))
				.setPrimaryPointOfContactId(list_Contacts[0].Id)
				.setFinalCheckDate(System.now().date())
				.setSecondaryContactId(list_Contacts[0].Id)
				.setResellerAccount(list_Accounts[0].Id)
				.setBulkMigrationStatus('New')
				.setFacilitatorId(UserInfo.getUserId())
				.build();
			bmrRec.Transition_To_Fulfillment__c = rec.Id;
			BulkMigrationRequestTriggerHelper.SkipTrigger = true;
			insert bmrRec;
			System.assertNotEquals(null, bmrRec.Id, 'Insertion Unsuccesful');
			BulkMigrationRequestTriggerHelper.SkipTrigger = false;

			List<Order> ordList = new List<Order>();
			Order ord = new Order();
			ord.AccountId = list_Accounts[0].Id;
			ord.Active_Employee_Count__c = 10;
			ord.EffectiveDate = System.today();
			ord.Status = 'Drafted';
			ord.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
			ord.Deductions_List__c = 'Test,Test';
			ord.Data_Entry_Assist__c = System.UserInfo.getUserId();
			ord.Bulk_Migration__c = bmrRec.Id;
			ord.RecordTypeId = cache.getRecordTypeId('Order', 'Company Migration');
			ord.First_Check_Date__c = System.now().date();
			ord.Follow_Up_Date__c = System.now().date();
			OrderTriggerHelper.SkipTrigger = true;
			ordList.add(ord);

			Order ord1 = new Order();
			ord1.AccountId = list_Accounts[0].Id;
			ord1.Active_Employee_Count__c = 10;
			ord1.EffectiveDate = System.today();
			ord1.Status = 'Drafted';
			ord1.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
			ord1.Deductions_List__c = 'Test,Test';
			ord1.Data_Entry_Assist__c = System.UserInfo.getUserId();
			ord1.Bulk_Migration__c = bmrRec.Id;
			ord1.RecordTypeId = cache.getRecordTypeId('Order', 'Company Migration');
			ord1.First_Check_Date__c = System.now().date();
			ord1.Follow_Up_Date__c = System.now().date();
			OrderTriggerHelper.SkipTrigger = true;
			ordList.add(ord1);
			OrderTriggerHelper.SkipTrigger = true;
			insert ordList;

			List<Order> orderListNoBlkMgr = new List<Order>();
			for (integer i = 0; i < 5; i++) {
				Order ordNoMgr = new Order();
				ordNoMgr.AccountId = list_Accounts[0].Id;
				ordNoMgr.Active_Employee_Count__c = 10;
				ordNoMgr.EffectiveDate = System.today();
				ordNoMgr.Status = 'Drafted';
				ordNoMgr.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
				ordNoMgr.Deductions_List__c = 'Test,Test';
				ordNoMgr.Data_Entry_Assist__c = System.UserInfo.getUserId();
				ordNoMgr.Bulk_Migration__c = null;
				ordNoMgr.RecordTypeId = cache.getRecordTypeId('Order', 'Company Migration');
				ordNoMgr.First_Check_Date__c = System.now().date();
				ordNoMgr.Follow_Up_Date__c = System.now().date();
				orderListNoBlkMgr.add(ordNoMgr);
			}
			OrderTriggerHelper.SkipTrigger = true;
			insert orderListNoBlkMgr;
			System.assert(orderListNoBlkMgr.size() > 0, 'Insertion Unsuccessful');

			// insert Case
			Case cse = new Case();
			cse.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
			cse.ContactId = list_Contacts[0].Id;
			cse.AccountId = list_Accounts[0].Id;
			cse.ownerId = System.userinfo.getuserid();
			cse.Requires_Action__c = true;
			cse.Subject = 'Test';
			cse.Description = 'Test';
			cse.Type = 'Payroll Transfer';
			cse.Origin = 'Panda';
			cse.SuppliedEmail = 'test.test@test.com';
			cse.Large_Scale_Issue__c = 'Test LSI';
			cse.Incoming_Email_Received_Date__c = System.today();
			CaseTriggerHelper.skipTrigger = true;
			insert cse;
			System.assertNotEquals(null, cse.Id, 'Insertion Unsuccessful');

			// insert Ticket
			Ticket__c ticket = new Ticket__c(Escalation_Reason__c = 'Sales Resell', Description__c = 'Test', Order__c = ordList[0].Id, OwnerId = System.UserInfo.getUserId(), Priority__c = 'Low');
			TicketTriggerHelper.SkipTrigger = true;
			insert ticket;

			// insert Order Status Change History
			Order_Status_Change_History__c OSCHRec = new Order_Status_Change_History__c();
			OSCHRec.Order__c = orderListNoBlkMgr[0].Id;
			OSCHRec.End_Time__c = System.now();
			OSCHRec.From_Status__c = 'In Progress';
			OSCHRec.Start_Time__c = System.now() - (40 / 1440);
			OSCHRec.To_Status__c = 'In Progress';
			insert OSCHRec;
			System.assertNotEquals(null, OSCHRec.Id, 'Insertion Unsuccessful');

			Test.startTest();

			// Call AdvocateViewCtrl class and its different methods
			AdvocateViewCtrl advCtrlCall = new AdvocateViewCtrl();
			advCtrlCall.IsFacilitator = false;
			advCtrlCall.CallOnAdvocateActionView();
			advCtrlCall.CallOnAdvocateBMR_MultiFEINview();
			advCtrlCall.objOrderTemp = new Order();
			advCtrlCall.objOrderTemp.First_Check_Date__c = Date.Today();
			advCtrlCall.objOrderTemp.Follow_Up_Date__c = Date.Today().addDays(35);
			advCtrlCall.objOrderTemp.Work_Start_Date__c = Date.Today();
			advCtrlCall.objOrderTemp.Requested_Pay_Date__c = Date.Today().addDays(35);
			advCtrlCall.ShowBMRStats();
			advCtrlCall.currentObjName = 'Order';
			advCtrlCall.currentView = 'Adv Cohort';
			advCtrlCall.saveCohortPreference();
			advCtrlCall.currentObjName = 'Order';
			advCtrlCall.currentView = 'Adv BMR';
			advCtrlCall.saveBMRPreference();
			advCtrlCall.CallOnAdvocateActionView();
			advCtrlCall.CallOnAdvocateBMR_MultiFEINview();
			advCtrlCall.ShowBMRStats();
			advCtrlCall.ShowCohortOrders();
			advCtrlCall.ShowBMROrders();
			advCtrlCall.updateInternalCommRequire();
			advCtrlCall.RetriveCustomerCommunication();
			advCtrlCall.updateRequireStatus();
			advCtrlCall.CallOnAdvocateCohortView();
			advCtrlCall.ShowSalesCom();
			advCtrlCall.CallOnOOOView();

			for (AdvocateViewCtrl.OrderWrapper objOW : advCtrlCall.list_OrderOOOWarpper) {
				if (objOW.objOrder.Bulk_Migration__c != null) {
					advCtrlCall.idSelectedOrder = objOW.objOrder.Id;
				}
			}
			advCtrlCall.selectBMRRecord();
			advCtrlCall.SaveOOONotes();
			advCtrlCall.ReasignBOOnOOO();

			// Call wrapper CustomerCommWrapper class and its properties
			AdvocateViewCtrl.CustomerCommWrapper advCtrlCustComWrapCall = new AdvocateViewCtrl.CustomerCommWrapper();
			advCtrlCustComWrapCall.intDaySinceLastReceived = 10;
			advCtrlCustComWrapCall.objCase = cse;
			System.assertNotEquals(null, advCtrlCustComWrapCall, 'Error');

			// Call wrapper TicketWrapper class and its properties
			list<AdvocateViewCtrl.CustomerCommWrapper> lstCustomerCommWrapper = new List<AdvocateViewCtrl.CustomerCommWrapper>();
			AdvocateViewCtrl.TicketWrapper advCtrlCustTicketWrapCall = new AdvocateViewCtrl.TicketWrapper();
			advCtrlCustTicketWrapCall.intDaySinceLastCreated = 10;
			advCtrlCustTicketWrapCall.objTicket = ticket;
			lstCustomerCommWrapper.add(advCtrlCustComWrapCall);
			System.assertNotEquals(null, advCtrlCustComWrapCall, 'Error');
			advCtrlCall.lstCustomerCommWrapper = lstCustomerCommWrapper;

			// Call wrapper OrderWrapper class and its properties
			AdvocateViewCtrl.OrderWrapper advCtrlOrdWrapCall = new AdvocateViewCtrl.OrderWrapper();
			advCtrlOrdWrapCall.objOrder = orderListNoBlkMgr[0];
			advCtrlOrdWrapCall.noc = 10;
			advCtrlOrdWrapCall.daySince = 10;
			System.assertNotEquals(null, advCtrlOrdWrapCall, 'Error');

			ApexPages.CurrentPage().getparameters().put('strOrderId', ordList[0].Id);
			list<AdvocateViewCtrl.OrderWrapper> lstInternalCommunication = new List<AdvocateViewCtrl.OrderWrapper>();
			lstInternalCommunication.add(advCtrlOrdWrapCall);

			ApexPages.CurrentPage().getparameters().put('strCaseId', cse.Id);

			// Call wrapper OrderStatWarpper class and its properties
			AdvocateViewCtrl.OrderStatWarpper advCtrlOrdStartWrapCall = new AdvocateViewCtrl.OrderStatWarpper();
			advCtrlOrdStartWrapCall.strOrderStatus = 'Test';
			advCtrlOrdStartWrapCall.strNumberOfOrder = 10;
			advCtrlOrdStartWrapCall.oldestNoOfday = 10.10;
			advCtrlOrdStartWrapCall.strAverage = 'Low';
			advCtrlOrdStartWrapCall.strOldestOrderId = orderListNoBlkMgr[0].Id;
			advCtrlOrdStartWrapCall.strOldestOrderName = 'OrdTestName';
			System.assertNotEquals(null, advCtrlOrdStartWrapCall, 'Error');

			advCtrlCall.lstInternalCommunication = lstInternalCommunication;
			advCtrlCall.updateInternalCommRequire();
			advCtrlCall.updateRequireStatus();

			AdvocateViewCtrl advCtrlCall1 = new AdvocateViewCtrl();
			List<string> lstSelectedBMR = new List<string>();
			advCtrlCall1.IsFacilitator = true;
			advCtrlCall1.objOrderTemp = objOrderTemp;
			advCtrlCall1.strCurrentUserId = adminUser.Id;
			advCtrlCall1.ShowBMRStats();
			advCtrlCall1.lstSelectedBMR = lstSelectedBMR;
			advCtrlCall1.ShowBMRStats();
			lstSelectedBMR.add('BMR');
			advCtrlCall1.lstSelectedBMR = lstSelectedBMR;
			Test.stopTest();
		}
	}

	@isTest
	static void testCustomerCommunication() {
		User adminUser = new TestDataFactory.UserBuilder()
			.setAlias('Admin')
			.setEmail('admin@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('admin@testorg.com.test4')
			.build();
		adminUser.Exempt_from_Validation_Rules__c = true;
		insert adminUser;
		System.assertNotEquals(null, adminUser.Id, 'Insertion Unsuccessful');
		// Run code by Admin user
		System.runAs(adminUser) {
			// insert accounts list
			List<Account> list_Accounts = new List<Account>();
			Id companyRecordTypeId = Cache.getRecordTypeId('Account', 'Company');

			for (Integer i = 0; i < 5; i++) {
				Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(companyRecordTypeId).setName('Company Account' + i).setOnboardingFlow('In-App').build();
				list_Accounts.add(objCompanyAccount);
			}

			AccounTTriggerHelper.SkipTrigger = true;
			insert list_Accounts;

			for (Account acc : list_Accounts) {
				System.assertNotEquals(null, acc.Id, 'Account Insertion Unsuccesful');
			}

			// insert contacts list
			List<Contact> list_Contacts = new List<Contact>();
			for (Integer i = 0; i < 5; i++) {
				Contact objContact = new TestDataFactory.ContactBuilder()
					.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
					.setAccountId(list_Accounts[i].Id)
					.setFirstName('Test' + i)
					.setLastName('User' + i)
					.setEmail('testuser' + i + '@abccompany.com')
					.build();
				list_Contacts.add(objContact);
			}

			ContactTriggerHelper.SkipTrigger = true;
			insert list_Contacts;

			// insert opportunity list
			List<Opportunity> list_Opportunities = new List<Opportunity>();

			for (Integer i = 0; i < 5; i++) {
				Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
					.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
					.setName('Acquisition Opportunity' + i)
					.setAccountId(list_Accounts[i].Id)
					.setStage('Open')
					.setCloseDate(System.today())
					.build();
				list_Opportunities.add(objOpportunity);
			}

			OpportunityTriggerHelper.SkipTrigger = true;
			insert list_Opportunities;

			List<Order> ordList = new List<Order>();
			Order ord = new Order();
			ord.AccountId = list_Accounts[0].Id;
			ord.Active_Employee_Count__c = 10;
			ord.EffectiveDate = System.today();
			ord.Status = 'Drafted';
			ord.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
			ord.Deductions_List__c = 'Test,Test';
			ord.Data_Entry_Assist__c = System.UserInfo.getUserId();
			ord.RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration');
			ord.First_Check_Date__c = System.now().date();
			ord.Follow_Up_Date__c = System.now().date();
			OrderTriggerHelper.SkipTrigger = true;
			ordList.add(ord);

			insert ordList;

			Test.startTest();

			// Call AdvocateViewCtrl class and its different methods
			AdvocateViewCtrl advCtrlCall = new AdvocateViewCtrl();
			advCtrlCall.CallOnAdvocateActionView();
			advCtrlCall.updateRequireStatus();

			Test.stopTest();
		}
	}
}