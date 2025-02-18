/**
 *author: Debasmita Rawooth
 *date: 23-09-2024
 *desc: Tets Class for OpportunityContactRolesControllerTest
 **/
@isTest
public class OpportunityContactRolesControllerTest {
	@testSetup
	static void setup() {
		List<Contact> list_Contacts = new List<Contact>();
		List<OpportunityContactRole> list_OppContactsRole = new List<OpportunityContactRole>();

		CaseTeamRole objCaseTeamRole = [SELECT Id, Name FROM CaseTeamRole WHERE Name = 'Customer Contact' LIMIT 1];

		//create the Account

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(LogSmartCallingUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Payroll Account')
			.setBillingStreet('298 S. Ringo Street')
			.setBillingCity('Little Rock')
			.setBillingPostalCode('72201')
			.setBillingCountry('United States')
			.setPhone('501-555-5555')
			.setWebsite('www.testco.com')
			.setZPCompanyID('zpcompanyid01')
			.build();
		AccountTriggerHelper.skipTrigger = true;
		insert objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		List<Contact> list_Contact = new List<Contact>();
		//create contacts
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Paul')
			.setLastName('Test')
			.setPhone('04802701314')
			.setEmail('testUser1@gmail.com')
			.setNormalizedPhone('04802701314')
			.setMailingStreet('298 S. Ringo Street')
			.setMailingCity('Little Rock')
			.setMailingPostalCode('72201')
			.setMobilePhone('9876543210')
			.setZPPhone('9876544321')
			.build();
		list_Contact.add(objContact1);

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Debas')
			.setLastName('Test')
			.setPhone('04802701315')
			.setEmail('testUser2@gmail.com')
			.setNormalizedPhone('04802701315')
			.setMobilePhone('9876543211')
			.setZPPhone('9876544322')
			.build();
		list_Contact.add(objContact2);

		Contact objContact3 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('John')
			.setLastName('Test')
			.setPhone('04802701316')
			.setEmail('testUser3@gmail.com')
			.setNormalizedPhone('04802701316')
			.setMobilePhone('9876543212')
			.setZPPhone('9876544323')
			.build();
		list_Contact.add(objContact3);

		ContactTriggerHelper.skipTrigger = true;
		insert list_Contact;
		ContactTriggerHelper.skipTrigger = false;

		//Create Case
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Transfer Case')
			.setType('Payroll Care')
			.setStatus('Open')
			.setPriority('Medium')
			.setDescription('Test Case 1 Description')
			.setSubject('Test Case 1 Subject')
			.build();
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		Opportunity objCompanyOpp = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Acquisition Opp')
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setCloseDate(Date.today())
			.setStage('Posted')
			.setZPCompanyID(objCompanyAccount.ZP_Company_Id__c)
			.build();
		insert objCompanyOpp;

		//Create Opp Contact Roles
		insert new List<OpportunityContactRole>{
			new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(objCompanyOpp.Id).setContactId(objContact1.Id).setRole('Primary Payroll Admin').setIsPrimary(true).build(),
			new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(objCompanyOpp.Id).setContactId(objContact2.Id).setRole('Benefits Signatory').setIsPrimary(false).build(),
			new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(objCompanyOpp.Id).setContactId(objContact3.Id).setRole('Payroll Admin').setIsPrimary(false).build()
		};

		Order objOrder = new TestDataFactory.OrderBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setOpportunityId(objCompanyOpp.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setStatus('Drafted')
			.setOwnerId(UserInfo.getUserId())
			.setEffectiveDate(System.today())
			.build();
		insert objOrder;
		objOrder.Case__c = objCase.Id;
		objOrder.OpportunityId = objCompanyOpp.Id;
		update objOrder;
	}

	/**
	 * @Author      : Debasmiota Rawooth
	 * @Description : Test method for getContactRolesByOrder
	 **/
	@isTest
	static void testGetContactRoles() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Payroll Account' LIMIT 1];
		Order objOrder = [SELECT Id FROM Order WHERE AccountId = :objAccount.Id LIMIT 1];
		Test.startTest();
		List<OpportunityContactRole> list_opportunityContactRoles = OpportunityContactRolesController.getContactRolesByOrder(objOrder.Id);
		System.assertEquals(3, list_opportunityContactRoles.size());
		Test.stopTest();
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test method for updatePrimaryContactOnOrder
	 **/
	@isTest
	static void testUpdatePrimaryContactOnOrder() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Payroll Account' LIMIT 1];
		Order objOrder = [SELECT Id FROM Order WHERE AccountId = :objAccount.Id LIMIT 1];
		Contact objPrimaryContact = [SELECT Id, Name FROM Contact WHERE Email = 'testUser1@gmail.com' LIMIT 1];
		List<Contact> list_additionalContacts = [SELECT Id, Name FROM Contact WHERE Email != 'testUser1@gmail.com'];
		List<Id> list_additionalContactIds = new List<Id>();
		for (Contact objContact : list_additionalContacts) {
			list_additionalContactIds.add(objContact.Id);
		}
		Test.startTest();
		OpportunityContactRolesController.updatePrimaryContactOnOrder(objOrder.Id, objPrimaryContact.Id, list_additionalContactIds);
		Order objOrderAssert = [SELECT Id, Primary_Contact__c FROM Order WHERE AccountId = :objAccount.Id LIMIT 1];
		System.assertEquals(objOrderAssert.Primary_Contact__c, objPrimaryContact.Id);
		Test.stopTest();
	}
}