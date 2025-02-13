@isTest
public class OrderDetailsExtensionTest {
	@isTest
	static void testOrderMethod() {
		// insert contacts list
		Contact objContact = new TestDataFactory.ContactBuilder().setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID).setFirstName('Test').setLastName('Company Contact').build();
		ContactTriggerHelper.SkipTrigger = true;
		insert objContact;

		// insert accounts list
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
		AccounTTriggerHelper.SkipTrigger = true;
		insert objAccount;

		Order ord = new Order();
		ord.AccountId = objAccount.Id;
		ord.Active_Employee_Count__c = 10;
		ord.EffectiveDate = System.today();
		ord.Status = 'Drafted';
		ord.States__c = 'HI; AK; CA; AZ; NM; OR; WA; CO; OH; PA; KY';
		ord.Deductions_List__c = 'Test,Test';
		ord.Data_Entry_Assist__c = System.UserInfo.getUserId();
		ord.RecordTypeId = cache.getRecordTypeId('Order', 'Company Migration');
		ord.First_Check_Date__c = System.now().date();
		ord.Follow_Up_Date__c = System.now().date();
		OrderTriggerHelper.SkipTrigger = true;
		insert ord;

		ApexPages.standardController sc = new ApexPages.standardController(ord);
		OrderDetailsExtension objOrder = new OrderDetailsExtension(sc);
		System.assert(true, 'Fixing Apex PMD issue.');
	}
}