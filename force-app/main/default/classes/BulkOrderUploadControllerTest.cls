/**
Created by : Gaurav Khare
Created Date : 4/29/2019
**/

@isTest
public class BulkOrderUploadControllerTest {
	@isTest
	static void uploadDataTest() {
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

		Bulk_Order_CSV_Columns__c csvCustomSetting = new Bulk_Order_CSV_Columns__c();
		csvCustomSetting.Name = 'Client Company Name';
		csvCustomSetting.Field_Values__c = 'Client Company Name';
		csvCustomSetting.Field_API_Name__c = 'Client_Company_ID__c';
		insert csvCustomSetting;

		Bulk_Order_CSV_Columns__c csvCustomSetting1 = new Bulk_Order_CSV_Columns__c();
		csvCustomSetting1.Name = 'First Pay Date';
		csvCustomSetting1.Field_Values__c = 'First Pay Date';
		csvCustomSetting1.Field_API_Name__c = 'First_Pay_Date__c';
		insert csvCustomSetting1;

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

		BulkOrderUploadController bulkOrderController = new BulkOrderUploadController();
		Bulk_Migration_Request__c temp = new Bulk_Migration_Request__c();
		temp.Requested_By__c = usr.id;
		temp.Requested_First_Check_Date__c = System.now().date();
		temp.Primary_Point_of_Contact__c = conRec1.Id;
		temp.Final_Check_Date__c = System.now().date();
		temp.Secondary_Contact__c = conRec1.Id;
		temp.Transition_To_Fulfillment__c = rec.id;
		temp.Reseller_Account__c = accRec1.Id;
		temp.Bulk_Migration_Owner__c = usr.id;
		bulkOrderController.BMRRecord = temp;

		bulkOrderController.testCSVData = 'Client Company Name,First Pay Date,Previous Payroll Provider,# of Inactive/Dismissed Employees Paid in 2018,Pay Schedule,Entity type,State Operated In,Benefits/Deductions,List deductions,Additional Reimbursements / Pay Types,# of Active Employees,Entity type\r\n222222333333333,2019-04-26,Keep",3,"Keep","Keep,,TRUE, o,,8,\r\n';
		bulkOrderController.readFromFile();
		bulkOrderController.confirm();
		bulkOrderController.discard();

		bulkOrderController.testCSVData = '';
		bulkOrderController.readFromFile();
		bulkOrderController.confirm();

		bulkOrderController.testCSVData = 'Client Company Name,First Pay Date,Previous Payroll Provider,# of Inactive/Dismissed Employees Paid in 2018,Pay Schedule,Entity type,State Operated In,Benefits/Deductions,List deductions,Additional Reimbursements / Pay Types,# of Active Employees,Entity type\r\n222222333333333,26-04-2019,Keep",3,"Keep","Keep,,TRUE, o,,8,\r\n';
		bulkOrderController.readFromFile();
		bulkOrderController.confirm();

		bulkOrderController.testCSVData = 'Client Company Name,First Pay Date,Previous Payroll Provider,# of Inactive/Dismissed Employees Paid in 2018,Pay Schedule,Entity type,State Operated In,Benefits/Deductions,List deductions,Additional Reimbursements / Pay Types,# of Active Employees,Entity type\r\n';
		bulkOrderController.readFromFile();
		bulkOrderController.confirm();
	}
}