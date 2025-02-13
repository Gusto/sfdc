/**
Created by : Gaurav Khare
Created Date : 4/29/2019
**/

@isTest
public class BulkOrderUploadStatusTest {
	@isTest
	static void statusData() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User usr = new User(
			Alias = 'gusst11',
			Email = 'gusto.standarduser2@gustotestorg.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'TestingCase',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = p.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'gusto.standarduser2@gustotestorg.com',
			Out_Of_Office__c = false
		);
		insert usr;
		System.assertNotEquals(null, usr.Id, 'Id cannot be null');

		Account accRec1 = new TestDataFactory.AccountBuilder()
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
		insert accRec1;

		Contact conRec1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(accRec1.id)
			.setFirstName('Test Demo')
			.setLastName('AccountName 1')
			.setEmail('TestAccount11@accTest.com')
			.setPhone('19992344444')
			.setMailingStreet('Testing Avenue 1')
			.setMailingPostalCode('123455')
			.setMobilePhone('19992344444')
			.setOtherPhone('19992344444')
			.setAlternateEmail('TestAccount12@accTest.com')
			.build();
		insert conRec1;

		Opportunity opp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
			.setName('TEST OPPORTUNITY')
			.setAccountId(accRec1.Id)
			.setStage('SAL')
			.setCloseDate(Date.newInstance(2019, 7, 1))
			.setOrderGenerated(false)
			.setCloseDate(system.today())
			.setMaestro(false)
			.setNumberOfEE(1)
			.setNumberOfContractors(0)
			.setZPCompanyId('1111111111')
			.setSourceID('TransitionToFull212')
			.build();
		insert opp;
		OpportunitytriggerHelper.SkipTrigger = false;

		Transition_to_Fulfillment__c rec = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setRecordTypeId(cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer'))
			.setBenefitsPointOfContact('Test')
			.setOpportunityId(opp.Id)
			.build();
		rec.Renewal_Exception__c = 'Yes';
		rec.Renewal_Date__c = Date.today();
		rec.Medical_New_Carrier__c = 'aa';
		rec.Dental_Carrier__c = 'aa';
		rec.Vision_Carrier__c = 'aa';
		rec.LiDi_Carrier__c = 'aa';
		rec.FSA_HSA_401K__c = 'aa';
		rec.Contact_Preference__c = 'Call';
		insert rec;

		Bulk_Migration_Request__c bmrRec = new Bulk_Migration_Request__c();
		bmrRec.Requested_By__c = usr.id;
		bmrRec.Requested_First_Check_Date__c = System.now().date();
		bmrRec.Primary_Point_of_Contact__c = conRec1.Id;
		bmrRec.Final_Check_Date__c = System.now().date();
		bmrRec.Secondary_Contact__c = conRec1.Id;
		bmrRec.Transition_To_Fulfillment__c = rec.id;
		bmrRec.Reseller_Account__c = accRec1.Id;
		insert bmrRec;

		PageReference pageRef = Page.BulkOrderUploadStatus;
		test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('id', bmrRec.Id);
		BulkOrderUploadStatus data = new BulkOrderUploadStatus();
		data.refreshData();
		data.redirectToBMRRecord();
	}
}