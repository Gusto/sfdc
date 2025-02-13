@isTest
public class LWC_SubmitCallBackControllerTest {
	static testMethod void testGetQueueList() {
		Test.startTest();
		Phone_Queue__c pq = new Phone_Queue__c();
		pq.Name = 'Concierge Pod 1';
		pq.Queue_Id__c = '7480c16c-b2b0-45b9-8b8c-2b8d295b48ea';
		insert pq;
		LWC_SubmitCallBackController.getQueueList();

		Phone_Queue__c c = [SELECT id, Name FROM Phone_Queue__c WHERE id = :pq.id];
		System.assertEquals(c.Name, 'Concierge Pod 1');
		Test.stopTest();
	}

	static testMethod void testcallBackLoad() {
		Account Acc = TestUtility.CompanyAccount();
		acc.Concierge_Group__c = 'Concierge Pod 1';
		AccountTriggerHelper.skipTrigger = true;
		update acc;
		Contact con = new contact(accountid = acc.id, lastName = 'Test', Phone = '9876543216');
		ContactTriggerHelper.skipTrigger = true;
		insert con;
		Case cse = TestDataFactory.createCaseRecord('Payroll Care', false);
		cse.SuppliedPhone = '9312313921';
		cse.ContactId = con.Id;
		cse.AccountId = acc.Id;
		CaseTriggerHelper.skipTrigger = true;
		insert cse;

		Test.startTest();
		LWC_SubmitCallBackController.callBackLoad(cse.Id);
		LWC_SubmitCallBackController.submitCallBack('00G16000004UUMZEA4', '726726', 'Test', 'Test', cse, cse, true, '32698981');
		Account c = [SELECT id, Name FROM Account WHERE id = :acc.id];
		System.assertEquals(c.Name, 'TEST ACCOUNT');
		Test.stopTest();
	}
	static testMethod void testcallBackPhoneNegativeScenario() {
		Account Acc = TestUtility.CompanyAccount();
		acc.Concierge_Group__c = 'Concierge Pod 1';
		AccountTriggerHelper.skipTrigger = true;
		update acc;
		Contact con = new contact(accountid = acc.id, lastName = 'Test', Phone = '9876543216');
		ContactTriggerHelper.skipTrigger = true;
		insert con;
		Case cse = TestDataFactory.createCaseRecord('Payroll Care', false);
		cse.SuppliedPhone = '9312313921';
		cse.ContactId = con.id;
		CaseTriggerHelper.skipTrigger = true;
		insert cse;

		Test.startTest();
		LWC_SubmitCallBackController.callBackLoad(cse.Id);
		LWC_SubmitCallBackController.submitCallBack('00G16000004UUMZEA4', '', 'Test', 'Test', cse, cse, true, '32698981');
		Account c = [SELECT id, Name FROM Account WHERE id = :acc.id];
		System.assertEquals(c.Name, 'TEST ACCOUNT');
		Test.stopTest();
	}
	static testMethod void testcallBackPhoneNegativeScenario2() {
		Account Acc = TestUtility.CompanyAccount();
		acc.Concierge_Group__c = 'Concierge Pod 1';
		AccountTriggerHelper.skipTrigger = true;
		update acc;
		Contact con = new contact(accountid = acc.id, lastName = 'Test', Phone = '9876543216');
		ContactTriggerHelper.skipTrigger = true;
		insert con;
		Case cse = TestDataFactory.createCaseRecord('Payroll Care', false);
		cse.SuppliedPhone = '9312313921';
		cse.ContactId = con.id;
		CaseTriggerHelper.skipTrigger = true;
		insert cse;

		Test.startTest();
		LWC_SubmitCallBackController.callBackLoad(cse.Id);
		LWC_SubmitCallBackController.submitCallBack('00G16000004UUMZEA4', '72678765426', 'Test', 'Test', cse, cse, true, '32698981');
		Account c = [SELECT id, Name FROM Account WHERE id = :acc.id];
		System.assertEquals(c.Name, 'TEST ACCOUNT');
		Test.stopTest();
	}
	static testMethod void testcallBackNameNegativeScenario2() {
		Account Acc = TestUtility.CompanyAccount();
		acc.Concierge_Group__c = 'Concierge Pod 1';
		AccountTriggerHelper.skipTrigger = true;
		update acc;
		Contact con = new contact(accountid = acc.id, lastName = 'Test', Phone = '9876543216');
		ContactTriggerHelper.skipTrigger = true;
		insert con;
		Case cse = TestDataFactory.createCaseRecord('Payroll Care', false);
		cse.SuppliedPhone = '9312313921';
		cse.ContactId = con.id;
		cse.Auto_Close_Date_Time__c = System.now();
		CaseTriggerHelper.skipTrigger = true;
		insert cse;

		Test.startTest();
		LWC_SubmitCallBackController.callBackLoad(cse.Id);
		LWC_SubmitCallBackController.submitCallBack('00G16000004UUMZEA4', '726765426', '', 'Test', cse, cse, true, '32698981');
		Account c = [SELECT id, Name FROM Account WHERE id = :acc.id];
		System.assertEquals(c.Name, 'TEST ACCOUNT');
		Test.stopTest();
	}
}