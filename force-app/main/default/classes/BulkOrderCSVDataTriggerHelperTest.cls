/**
Created by : Gaurav Khare
Created Date : 4/23/2019
**/
@isTest
public class BulkOrderCSVDataTriggerHelperTest {
	@testSetup
	static void setUp() {
		User objUser = new TestDataFactory.UserBuilder()
			.setAlias('Test')
			.setEmail('testuser123@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User123')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('testouser123@testorg.com')
			.build();
		objUser.Exempt_from_Validation_Rules__c = true;
		insert objUser;
		System.assertNotEquals(null, objUser.Id, 'Id cannot be null');

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Demo AccountName 1')
			.setZPCompanyId('1111111111')
			.setJoinedDate(System.now().date())
			.setCompanyTradeName('Company trade name 1')
			.setShippingStreet('Testing Avenue 1')
			.setShippingPostalCode('123455')
			.setBillingStreet('Testing Avenue 1')
			.setPhone('19992344444')
			.setBillingPostalCode('123456')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test Contact Name')
			.setLastName('Test Last Name')
			.setEmail('testuer@abccompany.com')
			.build();
		ContactTriggerHelper.skipTrigger = true;
		insert objContact;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('TEST OPPORTUNITY')
			.setAccountId(objAccount.Id)
			.setStage('Raw')
			.setCloseDate(Date.newInstance(2019, 7, 1))
			.setOrderGenerated(false)
			.setMaestro(false)
			.build();
		OpportunitytriggerHelper.skipTrigger = true;
		insert objOpportunity;

		Transition_to_Fulfillment__c objTransition = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer'))
			.setBenefitsPointOfContact('Test')
			.setOpportunityId(objOpportunity.Id)
			.build();
		objTransition.Renewal_Exception__c = 'Yes';
		objTransition.Renewal_Date__c = Date.today();
		objTransition.Medical_New_Carrier__c = 'aa';
		objTransition.Dental_Carrier__c = 'aa';
		objTransition.Vision_Carrier__c = 'aa';
		objTransition.LiDi_Carrier__c = 'aa';
		objTransition.FSA_HSA_401K__c = 'aa';
		objTransition.Contact_Preference__c = 'Call';
		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		insert objTransition;

		Bulk_Migration_Request__c objBulk = new TestDataFactory.BulkMigrationRequestBuilder()
			.setRequestedById(objUser.Id)
			.setRequestedFirstCheckDate(System.now().date())
			.setPrimaryPointOfContactId(objContact.Id)
			.setFinalCheckDate(System.now().date())
			.setSecondaryContactId(objContact.Id)
			.setResellerAccount(objAccount.Id)
			.build();
		objBulk.Transition_To_Fulfillment__c = objTransition.Id;
		BulkMigrationRequestTriggerHelper.skipTrigger = true;
		insert objBulk;

		List<Bulk_Order_CSV_Data__c> list_BulkOrderCsvData = new List<Bulk_Order_CSV_Data__c>();
		for (Integer i = 0; i < 100; i++) {
			Bulk_Order_CSV_Data__c objBulkOrderCSVData = new Bulk_Order_CSV_Data__c();
			objBulkOrderCSVData.No_of_Active_Employees__c = '1';
			objBulkOrderCSVData.No_of_Contractors__c = '2';
			list_BulkOrderCsvData.add(objBulkOrderCSVData);
		}
		//Negative testing
		for (Integer i = 0; i < 50; i++) {
			list_BulkOrderCsvData.get(i).Company_ID__c = 'TEst Acc';
			list_BulkOrderCsvData.get(i).Bulk_Migration_Request__c = objBulk.Id;
		}
		// Positive Testing
		for (Integer i = 50; i < 100; i++) {
			list_BulkOrderCsvData.get(i).Company_ID__c = objAccount.ZP_Company_ID__c;
			list_BulkOrderCsvData.get(i).Bulk_Migration_Request__c = objBulk.Id;
		}
		insert list_BulkOrderCsvData;

		// cover delete and Undelete
		delete list_BulkOrderCsvData;
		undelete list_BulkOrderCsvData;
	}

	@isTest
	static void uploadDataTest() {
		List<Bulk_Migration_Request__c> list_BulkRequests = [SELECT Id FROM Bulk_Migration_Request__c];
		// 50 Orders should get created

		List<Order> list_Orders = [SELECT Id FROM Order WHERE Bulk_Migration__c = :list_BulkRequests[0].Id];

		// One Case should get created
		List<Case> list_Cases = [SELECT Id FROM Case WHERE Bulk_Migration__c = :list_BulkRequests[0].Id];
		System.assertNotEquals(list_Cases.size(), 0, 'List cannot empty');
	}
}