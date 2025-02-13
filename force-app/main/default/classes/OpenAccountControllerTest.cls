/**
 * @description  used for testing different page urls from panda and hippo
 * @author       Praveen Sethu
 * @date         07-25-2022
 * @see          OpenAccountController
 **/
@isTest
public class OpenAccountControllerTest {
	@testSetup
	static void setup() {
		List<App_URL_Map__c> list_URLMaps = new List<App_URL_Map__c>();

		// Panda Dev URL
		list_URLMaps.add(new App_URL_Map__c(App_Name__c = 'Panda', Environment__c = 'Dev', URL__c = 'https://app.gusto-staging.com'));

		// Panda Prod URL
		list_URLMaps.add(new App_URL_Map__c(App_Name__c = 'Panda', Environment__c = 'Prod', URL__c = 'https://app.gusto.com'));

		// Hippo Dev URL
		list_URLMaps.add(new App_URL_Map__c(App_Name__c = 'Hippo', Environment__c = 'Dev', URL__c = 'https://hippo.gusto-staging.com'));

		// Panda Prod URL
		list_URLMaps.add(new App_URL_Map__c(App_Name__c = 'Hippo', Environment__c = 'Prod', URL__c = 'https://hippo.gusto.com'));

		insert list_URLMaps;
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Company and Firm Panda and Hippo URLs are set properly from Account layout
	 **/
	@isTest
	static void testAccountURL() {
		AccountTriggerHelper.skipTrigger = true;
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('97867').build();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Resller Account').setZPFirmId('98676').build();

		Test.startTest();
		insert new List<Account>{ objCompanyAccount, objResellerAccount };
		Test.stopTest();

		OpenAccountController.OpenAccountWrapper objResponseWrapper = OpenAccountController.getAccountExternalURL(objCompanyAccount.Id, 'Panda');
		System.assertEquals(true, objResponseWrapper.blnSuccess);

		objResponseWrapper = OpenAccountController.getAccountExternalURL(objResellerAccount.Id, 'Panda');
		System.assertEquals(true, objResponseWrapper.blnSuccess);

		objResponseWrapper = OpenAccountController.getAccountExternalURL(objCompanyAccount.Id, 'Hippo');
		System.assertEquals(true, objResponseWrapper.blnSuccess);
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if success flag is false for Accounts without company id
	 **/
	@isTest
	static void testAccountURLWithoutCompanyId() {
		AccountTriggerHelper.skipTrigger = true;
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').build();

		Test.startTest();
		insert new List<Account>{ objCompanyAccount };
		Test.stopTest();

		OpenAccountController.OpenAccountWrapper objResponseWrapper = OpenAccountController.getAccountExternalURL(objCompanyAccount.Id, 'Panda');
		System.assertEquals(false, objResponseWrapper.blnSuccess);
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Company Panda and Hippo URLs are set properly from Opportunity layout
	 **/
	@isTest
	static void testOpportunityURL() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('97867').build();
		insert objCompanyAccount;

		Opportunity objCompanyOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Company Oppty - Payroll')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();

		Test.startTest();
		insert objCompanyOppty;
		Test.stopTest();

		OpenAccountController.OpenAccountWrapper objResponseWrapper = OpenAccountController.getAccountExternalURL(objCompanyOppty.Id, 'Panda');
		System.assertEquals(true, objResponseWrapper.blnSuccess);
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if Company and Firm Panda and Hippo URLs are set properly from Lead layout
	 **/
	@isTest
	static void testLeadURL() {
		LeadTriggerHelper.skipTrigger = true;

		Lead objCompanyLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('company@normalizeinsert.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.setZPCompanyID('67867')
			.build();

		Lead objResellerLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@gmail.com.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setLeadSource('LinkedIn')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.setZPFirmId('8767567')
			.build();

		Test.startTest();
		insert new List<Lead>{ objCompanyLead, objResellerLead };
		Test.stopTest();

		OpenAccountController.OpenAccountWrapper objResponseWrapper = OpenAccountController.getAccountExternalURL(objCompanyLead.Id, 'Panda');
		System.assertEquals(true, objResponseWrapper.blnSuccess);

		objResponseWrapper = OpenAccountController.getAccountExternalURL(objResellerLead.Id, 'Panda');
		System.assertEquals(true, objResponseWrapper.blnSuccess);

		objResponseWrapper = OpenAccountController.getAccountExternalURL(objCompanyLead.Id, 'Hippo');
		System.assertEquals(true, objResponseWrapper.blnSuccess); 
	}
}