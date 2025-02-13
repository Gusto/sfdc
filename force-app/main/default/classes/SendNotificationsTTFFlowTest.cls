/**
 * @description  This class is used for testing Payroll Transfer Notifications TTF flow.
 * that sends intro emails based on criteria.
 * @author       Aviinandaan Dutta
 * @date         04-17-2023
 * @see          Payroll_Transfer_Notifications_TTF
 **/
@isTest
public class SendNotificationsTTFFlowTest {
	static final String TTF_RT_PAYROLLTRANSFER = Cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
	static final Id ORDER_RT_COMPANYMIGRATION = Cache.getRecordTypeId('Order', 'Company Migration');
    
    @testSetup
	static void setup() {
		User objDirectSalesUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'Direct Sales User' AND IsActive = TRUE LIMIT 1];

        AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
        OrderTriggerHelper.skipTrigger = true;
        
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_TYPE)
			.setName('Discovery Account')
			.setOnboardingFlow('In-App')
			.setNormalizedEmailDomain('my18.com')
			.build();
		insert objCompanyAccount;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setName('TEST OPPORTUNITY')
			.setCloseDate(Date.today())
			.setAccountId(objCompanyAccount.id)
			.setStage('SAL')
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.build();
		insert objOpportunity;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(cache.getRecordTypeId('Contact', 'Company'))
			.setLastName('Test contact')
			.setAccountId(objCompanyAccount.Id)
			.setEmail('test@test.com')
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Transfer Case')
			.setSubject('Test Payroll Transfer Case')
			.setDescription('Test')
			.setStatus('Open')
			.build();
		objCase.TTF_Point_Of_Contact__c = objContact.Id;
        objCase.ownerId = objDirectSalesUser.Id;
        objCase.Integration_Key__c = 'zenpayroll-company_migration-32130';
        objCase.Origin = 'Gusto';
        objCase.Order_Owner_Name__c = 'Company Migration - Unassigned Orders';
		insert objCase;

		Order objOrder = new TestDataFactory.OrderBuilder()
			.setRecordTypeId(cache.getRecordTypeId('Order', 'Company Migration'))
			.setOpportunityId(objOpportunity.Id)
			.setAccountId(objCompanyAccount.Id)
			.setEffectiveDate(System.today().addDays(30))
			.setStatus('Started')
			.build();
		objOrder.Case__c = objCase.Id;
        objOrder.OwnerId = objDirectSalesUser.Id;
        objOrder.First_Check_Date__c = System.today();
		insert objOrder;

		Transition_to_Fulfillment__c objTTF = new TestDataFactory.TransitionToFulfillmentBuilder()
			.setRecordTypeId(cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer'))
			.setOpportunityId(objOpportunity.Id)
			.build();
		objTTF.Order__c = objOrder.Id;
		objTTF.Contact__c = objContact.Id;
		insert objTTF;
        
        objOrder.Transition_to_Fulfillment__c = objTTF.Id;
        update objOrder;
        
        AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
        OrderTriggerHelper.skipTrigger = false;
	}

	/**
	 * @description Test intro email when call needed template should be sent
	 **/
	@isTest
	static void shouldSendIntroEmailCallNeededTemplate() {
		User objDirectSalesUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'Direct Sales User' AND IsActive = TRUE LIMIT 1];
		objDirectSalesUser.Exempt_from_Validation_Rules__c = true;
		update objDirectSalesUser;
		Transition_to_Fulfillment__c objTTF = [SELECT TTF_Status__c, Intro_Notification_Sent__c, RecordType.Name, Order__r.Bulk_Migration__c, Contact__r.Email FROM Transition_to_Fulfillment__c]
			.get(0);
		Test.startTest();
        TransitionToFulfilmentTriggerHelper.skipTrigger=true;
		System.runAs(objDirectSalesUser) {
			objTTF.TTF_Status__c = TransitiontoFulfilmentUtil.TTF_STATUS_PT_APPROVED;
			update objTTF;
		}
        Test.stopTest();
		objTTF = [
			SELECT TTF_Status__c, Intro_Notification_Sent__c, Documents_Collected__c, Exception_Request__c, Order__r.Case__c, Order__c, Contact__r.Email
			FROM Transition_to_Fulfillment__c
			WHERE Id = :objTTF.Id
		];
		if(OrganizationUtilities.canSendEmails()){
			List<EmailMessage> list_EmailMessages = [SELECT ActivityId, Email_Template_Name__c, ParentId, RelatedToId, Status, ToAddress, FromAddress FROM EmailMessage];
			List<OrgWideEmailAddress> list_orgEmails = [SELECT Id, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Payroll Transfer' LIMIT 1];
			String strFromAddress;
			if (!list_orgEmails.isEmpty()) {
				strFromAddress = list_orgEmails.get(0).Address;
			}
			Task objTask = [SELECT Type, WhatId FROM Task WHERE Id = :list_EmailMessages.get(0).ActivityId];
			System.assertEquals(true, list_EmailMessages.size() == 1, 'Email message not created');
			System.assertEquals(true, list_EmailMessages.get(0).Email_Template_Name__c.contains('Payroll_Transfer_Intro_Email'), 'Email message has wrong template');
			System.assertEquals(objTTF.Order__r.Case__c, list_EmailMessages.get(0).ParentId, 'Email message not related to TTF.Order.case');
			System.assertEquals(true, objTask.Type == 'Outbound Email' && objTask.WhatId == objTTF.Order__c, 'Email message not related to TTF.Order');
			System.assertEquals(objTTF.Contact__r.Email, list_EmailMessages.get(0).ToAddress, 'Email message sent to wrong address');
			System.assertEquals(strFromAddress, list_EmailMessages.get(0).FromAddress, 'Email message sent from wrong address');
			System.assertEquals(true, objTTF.Intro_Notification_Sent__c, 'Intro Notification sent flag on TTF not set');
		}
	}

	/**
	 * @description Test intro email when no call needed template should be sent
	 **/
	@isTest
	static void shouldSendIntroEmailNoCallTemplate() {
		User objDirectSalesUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'Direct Sales User' AND IsActive = TRUE LIMIT 1];
		objDirectSalesUser.Exempt_from_Validation_Rules__c = true;
		update objDirectSalesUser;
		Transition_to_Fulfillment__c objTTF = [SELECT TTF_Status__c, Intro_Notification_Sent__c, RecordType.Name, Order__r.Bulk_Migration__c, Contact__r.Email FROM Transition_to_Fulfillment__c]
			.get(0);
		Test.startTest();
        TransitionToFulfilmentTriggerHelper.skipTrigger = true;
		System.runAs(objDirectSalesUser) {
            objTTF.TTF_Status__c = TransitiontoFulfilmentUtil.TTF_STATUS_PT_APPROVED;
            objTTF.Documents_Collected__c = true;
            update objTTF;
        }
		Test.stopTest();
		objTTF = [
			SELECT TTF_Status__c, Intro_Notification_Sent__c, Documents_Collected__c, Exception_Request__c, Order__r.Case__c, Order__c, Contact__r.Email
			FROM Transition_to_Fulfillment__c
			WHERE Id = :objTTF.Id
		];
		if(OrganizationUtilities.canSendEmails()){
			List<EmailMessage> list_EmailMessages = [SELECT ActivityId, Email_Template_Name__c, ParentId, RelatedToId, Status, ToAddress, FromAddress FROM EmailMessage];
			List<OrgWideEmailAddress> list_orgEmails = [SELECT Id, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Payroll Transfer' LIMIT 1];
			String strFromAddress;
			if (!list_orgEmails.isEmpty()) {
				strFromAddress = list_orgEmails.get(0).Address;
			}
			Task objTask = [SELECT Type, WhatId FROM Task WHERE Id = :list_EmailMessages.get(0).ActivityId];
			System.assertEquals(true, list_EmailMessages.size() == 1, 'Email message not created');
			System.assertEquals(true, list_EmailMessages.get(0).Email_Template_Name__c.contains('Payroll_Transfer_Intro_Email_IOP_QBO_2'), 'Email message has wrong template');
			System.assertEquals(objTTF.Order__r.Case__c, list_EmailMessages.get(0).ParentId, 'Email message not related to TTF.Order.case');
			System.assertEquals(true, objTask.Type == 'Outbound Email' && objTask.WhatId == objTTF.Order__c, 'Email message not related to TTF.Order');
			System.assertEquals(objTTF.Contact__r.Email, list_EmailMessages.get(0).ToAddress, 'Email message sent to wrong address');
			System.assertEquals(strFromAddress, list_EmailMessages.get(0).FromAddress, 'Email message sent from wrong address');
			System.assertEquals(true, objTTF.Intro_Notification_Sent__c, 'Intro Notification sent flag on TTF not set');
		}
	}

	/**
	 * @description Test intro email when exception request template should be sent
	 **/
	@isTest
	static void shouldSendIntroEmailExceptionRequestTemplate() {
		User objDirectSalesUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'Direct Sales User' AND IsActive = TRUE LIMIT 1];
		objDirectSalesUser.Exempt_from_Validation_Rules__c = true;
		update objDirectSalesUser;
		Transition_to_Fulfillment__c objTTF = [SELECT TTF_Status__c, Intro_Notification_Sent__c, RecordType.Name, Order__r.Bulk_Migration__c, Contact__r.Email FROM Transition_to_Fulfillment__c]
			.get(0);
		Test.startTest();
        TransitionToFulfilmentTriggerHelper.skipTrigger = true;
		System.runAs(objDirectSalesUser) {
            objTTF.TTF_Status__c = TransitiontoFulfilmentUtil.TTF_STATUS_PT_APPROVED;
            objTTF.Exception_Request__c = 'Yes';
            objTTF.Customer_Aware_of_Shorter_timeline__c = 'Yes';
            objTTF.Reason_for_exception_request__c = 'Current payroll provider shut down';
            update objTTF;
        }
		Test.stopTest();
		objTTF = [
			SELECT TTF_Status__c, Intro_Notification_Sent__c, Documents_Collected__c, Exception_Request__c, Order__r.Case__c, Order__c, Contact__r.Email
			FROM Transition_to_Fulfillment__c
			WHERE Id = :objTTF.Id
		];
		if(OrganizationUtilities.canSendEmails()){
			List<EmailMessage> list_EmailMessages = [SELECT ActivityId, Email_Template_Name__c, ParentId, RelatedToId, Status, ToAddress, FromAddress FROM EmailMessage];
			List<OrgWideEmailAddress> list_orgEmails = [SELECT Id, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Payroll Transfer' LIMIT 1];
			String strFromAddress;
			if (!list_orgEmails.isEmpty()) {
				strFromAddress = list_orgEmails.get(0).Address;
			}
			Task objTask = [SELECT Type, WhatId FROM Task WHERE Id = :list_EmailMessages.get(0).ActivityId];
			System.assertEquals(true, list_EmailMessages.size() == 1, 'Email message not created');
			System.assertEquals(true, list_EmailMessages.get(0).Email_Template_Name__c.contains('Payroll_Transfer_Intro_Email_Exception_Request'), 'Email message has wrong template');
			System.assertEquals(objTTF.Order__r.Case__c, list_EmailMessages.get(0).ParentId, 'Email message not related to TTF.Order.case');
			System.assertEquals(true, objTask.Type == 'Outbound Email' && objTask.WhatId == objTTF.Order__c, 'Email message not related to TTF.Order');
			System.assertEquals(objTTF.Contact__r.Email, list_EmailMessages.get(0).ToAddress, 'Email message sent to wrong address');
			System.assertEquals(strFromAddress, list_EmailMessages.get(0).FromAddress, 'Email message sent from wrong address');
			System.assertEquals(true, objTTF.Intro_Notification_Sent__c, 'Intro Notification sent flag on TTF not set');
		}
	}

	/**
	 * @description Test intro email negative scenario, no email should be sent 
	 **/
	@isTest
	static void shouldNotSendIntroEmail() {
		User objDirectSalesUser = [SELECT Id, UserRoleId, UserRole.DeveloperName, UserRole.Name, Profile.Name FROM User WHERE Profile.Name = 'Direct Sales User' AND IsActive = TRUE LIMIT 1];
		objDirectSalesUser.Exempt_from_Validation_Rules__c = true;
		update objDirectSalesUser;
		Transition_to_Fulfillment__c objTTF = [SELECT TTF_Status__c, Intro_Notification_Sent__c, RecordType.Name, Order__r.Bulk_Migration__c, Contact__r.Email FROM Transition_to_Fulfillment__c]
			.get(0);
		objTTF.Intro_Notification_Sent__c = true;
		update objTTF;
		Test.startTest();
        TransitionToFulfilmentTriggerHelper.skipTrigger = true;
		System.runAs(objDirectSalesUser) {
            objTTF.TTF_Status__c = TransitiontoFulfilmentUtil.TTF_STATUS_PT_APPROVED;
            update objTTF;
        }
		Test.stopTest();
		List<EmailMessage> list_EmailMessages = [SELECT ActivityId, Email_Template_Name__c, ParentId, RelatedToId, Status, ToAddress, FromAddress FROM EmailMessage];
		System.assertEquals(true, list_EmailMessages.size() == 0, 'Sent email messages exceeding allowed count');
	}
}