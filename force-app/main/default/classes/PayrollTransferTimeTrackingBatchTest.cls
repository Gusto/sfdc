@isTest
public class PayrollTransferTimeTrackingBatchTest {
	@testsetup
	private static void setupTestData() {
		//Create a user who will be the facilitator
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User'];

		User facilitator = new TestDataFactory.UserBuilder()
			.setEmail('testfacilitator@testorg.com')
			.setFirstName('Implementation')
			.setLastName('facilitator')
			.setProfileId(p.Id)
			.setUserName('Implementation.facilitator@test.Implementation')
			.setIsActive(true)
			.build();
		insert facilitator;
		//Insert Account
		Account account = new Account();
		account.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		account.ZP_Company_Id__c = 'TestChkLst241019';
		account.Name = 'TestAccountChecklist';

		AccountTriggerHelper.skiptrigger = true;
		insert new List<Account>{ account };

		//Contact
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(account.Id)
			.setFirstName('fName1')
			.setLastName('lName1')
			.setEmail('testAddress1@domain.com')
			.build();
		insert objContact1;

		//Order
		Order objOrder = new TestDataFactory.OrderBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setAccountId(account.Id)
			.setStatus('Drafted')
			.setPayrollRunDate(Date.today())
			.setEffectiveDate(Date.today())
			.build();

		Order objOrder1 = new TestDataFactory.OrderBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setAccountId(account.Id)
			.setStatus('Drafted')
			.setPayrollRunDate(Date.valueOf('2019-11-11'))
			.setEffectiveDate(Date.today())
			.build();

		Order objOrder2 = new TestDataFactory.OrderBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setAccountId(account.Id)
			.setStatus('Onboarding Steps 1 - 6')
			.setPayrollRunDate(Date.valueOf('2019-11-11'))
			.setEffectiveDate(Date.today())
			.build();

		insert new List<Order>{ objOrder, objOrder1, objOrder2 };

		//Insert checklists
		List<Order_Facilitator_Checklist__c> lstChk = new List<Order_Facilitator_Checklist__c>();

		lstChk.add(new Order_Facilitator_Checklist__c(Checklist_Name__c = 'test chk1', Order__c = objOrder.Id, Sequence__c = 1));
		lstChk.add(new Order_Facilitator_Checklist__c(Checklist_Name__c = 'test chk2', Order__c = objOrder.Id, Sequence__c = 2));
		lstChk.add(new Order_Facilitator_Checklist__c(Checklist_Name__c = 'test chk3', Order__c = objOrder1.Id, Sequence__c = 1));
		lstChk.add(new Order_Facilitator_Checklist__c(Checklist_Name__c = 'test chk4', Order__c = objOrder1.Id, Sequence__c = 2));
		lstChk.add(new Order_Facilitator_Checklist__c(Checklist_Name__c = 'test chk5', Order__c = objOrder2.Id, Sequence__c = 1));
		lstChk.add(new Order_Facilitator_Checklist__c(Checklist_Name__c = 'test chk6', Order__c = objOrder2.Id, Sequence__c = 2));
		lstChk.add(new Order_Facilitator_Checklist__c(Checklist_Name__c = 'test ch7', Order__c = objOrder2.Id, Sequence__c = 3));

		insert lstChk;

		objOrder.Status = 'Collecting Documents';
		objOrder.Data_Entry_Assist__c = facilitator.Id;
		objOrder.Facilitator_Work_Start_DateTime__c = System.now();
		objOrder2.Status = 'Onboarding Steps 8 - 9';
		objOrder1.Status = 'Drafted';

		update new List<Order>{ objOrder, objOrder1, objOrder2 };
	}

	@isTest
	private static void testPTAnatyticsBatch() {
		PayrollTransferTimeTrackingBatch batch = new PayrollTransferTimeTrackingBatch();
		Test.startTest();
		Database.executeBatch(batch);
		Test.stopTest();

		System.assert([SELECT COUNT() FROM Analytics_Time_Tracker__c] > 0, 'There should be more than 1 record.');

		Database.executeBatch(batch);
	}
}