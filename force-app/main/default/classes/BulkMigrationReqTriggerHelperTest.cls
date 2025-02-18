/**
Created by : Gaurav Khare
Created Date : 5/06/2019
**/

@isTest
public class BulkMigrationReqTriggerHelperTest {
	@TestSetup
	static void dataSetupMethod() {
		BulkMigrationRequestTriggerHelper.SkipTrigger = true;
		ContactTriggerHelper.SkipTrigger = true;
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('Implementation.Advocate@test.Implementation')
			.setExemptfromValidationRules(true)
			.setEmail('partneram@testorg.com')
			.setProfileId(UserInfo.getProfileId())
			.build();
		insert objUser;

		User objUserLoggedIn = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(objUserLoggedIn) {
			Contact objContact1 = new TestDataFactory.ContactBuilder().setRecordTypeId('Company').setFirstName('First Name1').setLastName('Last Name1').setEmail('testuser1@firstcontact.com').build();
			insert objContact1;

			Bulk_Migration_Request__c objBulkMigrationRequest = new TestDataFactory.BulkMigrationRequestBuilder()
				.setRequestedById(objUser.Id)
				.setRequestedFirstCheckDate(System.now().date())
				.setPrimaryPointOfContactId(objContact1.Id)
				.setFinalCheckDate(System.now().date())
				.setSecondaryContactId(objContact1.Id)
				.setAssignmentErrorMessage('')
				.build();
			insert objBulkMigrationRequest;

			EmailMessage objEmailMessage2 = new TestDataFactory.EmailMessageBuilder()
				.setFromAddress('test@acme.com')
				.setToAddress('test.test@gusto.com;test.test1@test.com')
				.setSubject('testing')
				.setTextBody('America')
				.setRelatedToId(objBulkMigrationRequest.Id)
				.setEmailTemplateName('Notify_Bulk_Migration_Request_Facilitator')
				.build();
			insert objEmailMessage2;
			AccountTriggerHelper.skipTrigger = true;
			ContactTriggerHelper.skipTrigger = true;
			CaseTriggerHelper.skipTrigger = true;
			OpportunityTriggerHelper.skipTrigger = true;

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
				.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
				.build();
			insert objOpportunity;

			Contact objContact = new TestDataFactory.ContactBuilder()
				.setFirstName('Artoo')
				.setLastName('Detoo')
				.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
				.setAccountId(objCompanyAccount.Id)
				.setZPUserId('bulk_4324324321')
				.setEmail('BulkMigrationReqTriggerHelperTest@gusto.com')
				.build();
			insert objContact;

			Case objCase = new TestDataFactory.CaseBuilder()
				.setRecordTypeId('Payroll Transfer Case')
				.setAccountId(objCompanyAccount.Id)
				.setSubject('Test')
				.setDescription('Test')
				.setType('Payroll Transfer')
				.setOrigin('Email')
				.setSuppliedEmail('BulkMigrationReqTriggerHelperTestCase@gusto.com')
				.setAuthorizedUser('No')
				.build();
			objcase.Direction__c = 'Inbound';
			insert objcase;

			Transition_to_Fulfillment__c objTTF = new TestDataFactory.TransitionToFulfillmentBuilder()
				.setRecordTypeId(cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer'))
				.setOpportunityId(objOpportunity.Id)
				.setBenefitOrderId(null)
				.build();
			insert objTTF;
		}
	}
	/**
	 * By:
	 * Date Created :
	 * Desc :  BulMigStatusChangeTest
	 */
	@isTest
	static void BulMigStatusChangeTest() {
		BulkMigrationRequestTriggerHandler.resetSkipTriggerFlags();
		BulkMigrationRequestTriggerHandler.blnTestException = true;
		List<Account> list_TestAccounts = [SELECT Id FROM Account];
		list<Case> list_Cases = [SELECT id FROM Case];

		Bulk_Migration_Request__c objBulkMigrationRequest = new TestDataFactory.BulkMigrationRequestBuilder().setBulkMigrationStatus('New').build();
		insert objBulkMigrationRequest;

		Order objOrder = new TestDataFactory.OrderBuilder()
			.setAccountId(list_TestAccounts[0].Id)
			.setActiveEECount(10)
			.setEffectiveDate(System.today())
			.setStatus('Drafted')
			.setBulkMigrationId(objBulkMigrationRequest.Id)
			.setFirstPayrollCallScheduled('Yes')
			.build();
		OrderTriggerHelper.skipTrigger = true;
		insert objOrder;
		OrderTriggerHelper.skipTrigger = false;

		Bulk_Migration_Request__c objBulkMig = [SELECT Id, Bulk_Migration_Status__c, Bulk_Case__c FROM Bulk_Migration_Request__c WHERE Id = :objBulkMigrationRequest.Id];
		objBulkMig.Bulk_Migration_Status__c = 'Completed';
		objBulkMig.Bulk_Case__c = list_Cases.get(0).Id;
		OrderTriggerHelper.skipTrigger = true;
		update objBulkMig;
		OrderTriggerHelper.skipTrigger = false;

		Order objOrderQueried = [SELECT Id, Status FROM Order];
		System.assertEquals(objOrderQueried.status, 'Closed: Payroll Run', 'Failed');

		delete objBulkMigrationRequest;
		undelete objBulkMigrationRequest;
	}
	/**
	 * By:Pawan
	 * Date Created :22-Apr-2023
	 * Desc :  testFacilitatorAssignment
	 */
	@isTest
	static void testFacilitatorAssignment() {
		List<Account> list_TestAccounts = [SELECT id FROM Account];
		list<Transition_to_Fulfillment__c> list_TransitionTofullfillment = [SELECT Id FROM Transition_to_Fulfillment__c];

		Bulk_Migration_Request__c objBulkMigrationRequest = new TestDataFactory.BulkMigrationRequestBuilder().setBulkMigrationStatus('New').setResellerAccount(list_TestAccounts[0].Id).build();
		insert objBulkMigrationRequest;

		Order objOrder = new TestDataFactory.OrderBuilder()
			.setAccountId(list_TestAccounts[0].Id)
			.setActiveEECount(10)
			.setEffectiveDate(System.today())
			.setStatus('Drafted')
			.setBulkMigrationId(objBulkMigrationRequest.Id)
			.setFirstPayrollCallScheduled('Yes')
			.build();
		OrderTriggerHelper.skipTrigger = true;
		insert objOrder;
		OrderTriggerHelper.skipTrigger = false;

		System.assertNotEquals(null, list_TransitionTofullfillment, 'List should not be null.');
		objBulkMigrationRequest.facilitator__c = userInfo.getUserId();
		objBulkMigrationRequest.Transition_To_Fulfillment__c = list_TransitionTofullfillment.get(0).Id;
		OrderTriggerHelper.skipTrigger = true;
		update objBulkMigrationRequest;
		OrderTriggerHelper.skipTrigger = false;
		BulkMigrationRequestTriggerHelper.skipTrigger = true;
		update objBulkMigrationRequest;

		BulkMigrationRequestUtil objUtil = new BulkMigrationRequestUtil();
	}

	/**
	 * By:Pawan
	 * Date Created :22-Apr-2023
	 * Desc :  testAssignOwner
	 */
	@isTest
	static void testAssignOwner() {
		Test.startTest();
		List<Bulk_Migration_Request__c> list_BulkMReq = [SELECT Id, Ownerid FROM Bulk_Migration_Request__c];
		List<Group> list_AssignQueueBMR = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Company_Migration_Unassigned_Orders'];
		System.assertEquals(list_AssignQueueBMR[0].ID, list_BulkMReq[0].Ownerid, 'Failed');
		Test.stopTest();
	}

	/**
	 * By:Pawan
	 * Date Created :22-Apr-2023
	 * Desc :  testUpsertEmailMessageOnOwnerChange
	 */
	@isTest
	static void testUpsertEmailMessageOnOwnerChange() {
		Test.startTest();
		List<Bulk_Migration_Request__c> list_BulkMReq = [SELECT Id, Ownerid FROM Bulk_Migration_Request__c];
		User objUser = [SELECT Id FROM User WHERE Email = 'partneram@testorg.com'];

		User objUserLoggedIn = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		System.runAs(objUserLoggedIn) {
			Bulk_Migration_Request__c objBulkMigrationRequest = new TestDataFactory.BulkMigrationRequestBuilder().setRecordId(list_BulkMReq[0].id).setOwnerId(objUser.Id).build();
			update objBulkMigrationRequest;

			List<EmailMessage> list_EmailMessages = [
				SELECT Id, Email_Template_Name__c, RelatedToId
				FROM EmailMessage
				WHERE Email_Template_Name__c = 'Notify_Bulk_Migration_Request_Owner' AND RelatedToId = :objBulkMigrationRequest.Id
				ORDER BY CreatedDate DESC
			];

			Test.stopTest();
			List<Bulk_Migration_Request__c> list_BulkMR = [SELECT Id, Ownerid FROM Bulk_Migration_Request__c WHERE Id = :objBulkMigrationRequest.id];

			System.assertNotEquals(list_BulkMReq[0].Ownerid, list_BulkMR[0].Ownerid, 'Failed');
			System.assertEquals('Notify_Bulk_Migration_Request_Owner', list_EmailMessages[0].Email_Template_Name__c, 'Failed');
		}
	}

	/**
	 * By:Pawan
	 * Date Created :22-Apr-2023
	 * Desc :  testUpsertEmailMessageOnBMRFailure
	 */
	@isTest
	static void testUpsertEmailMessageOnBMRFailure() {
		Test.startTest();
		List<Bulk_Migration_Request__c> list_BulkMReq = [SELECT Id, Ownerid, Assignment_Error_Message__c FROM Bulk_Migration_Request__c];

		User objUserLoggedIn = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		System.runAs(objUserLoggedIn) {
			Bulk_Migration_Request__c objBulkMigrationRequest = new TestDataFactory.BulkMigrationRequestBuilder().setRecordId(list_BulkMReq[0].id).setAssignmentErrorMessage('test12').build();
			update objBulkMigrationRequest;

			List<EmailMessage> list_EmailMessages = [
				SELECT Id, Email_Template_Name__c
				FROM EmailMessage
				WHERE Email_Template_Name__c = 'Notify_Bulk_Migration_Assignment_Failure' AND RelatedToId = :objBulkMigrationRequest.id
				ORDER BY CreatedDate DESC
			];

			Test.stopTest();
			List<Bulk_Migration_Request__c> list_BulkMR = [SELECT Id, Ownerid, Assignment_Error_Message__c FROM Bulk_Migration_Request__c WHERE Id = :objBulkMigrationRequest.id];

			System.assertNotEquals(list_BulkMReq[0].Assignment_Error_Message__c, list_BulkMR[0].Assignment_Error_Message__c, 'Failed');
			System.assertEquals('Notify_Bulk_Migration_Assignment_Failure', list_EmailMessages[0].Email_Template_Name__c, 'Failed');
		}
	}

	/**
	 * By:Pawan
	 * Date Created :22-Apr-2023
	 * Desc :  testUpsertEmailMessageOnFacilitatorChange
	 */
	@isTest
	static void testUpsertEmailMessageOnFacilitatorChange() {
		Test.startTest();
		List<Bulk_Migration_Request__c> list_BulkMReq = [SELECT Id, Ownerid, Assignment_Error_Message__c, Facilitator__c FROM Bulk_Migration_Request__c];

		User objUser = [SELECT Id FROM User WHERE Email = 'partneram@testorg.com'];
		User objUserLoggedIn = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		System.runAs(objUserLoggedIn) {
			Bulk_Migration_Request__c objBulkMigrationRequest = new TestDataFactory.BulkMigrationRequestBuilder().setRecordId(list_BulkMReq[0].id).setFacilitatorId(objUser.Id).build();
			update objBulkMigrationRequest;

			List<EmailMessage> list_EmailMessages = [
				SELECT Id, Email_Template_Name__c
				FROM EmailMessage
				WHERE Email_Template_Name__c = 'Notify_Bulk_Migration_Request_Facilitator' AND RelatedToId = :objBulkMigrationRequest.id
				ORDER BY CreatedDate DESC
			];

			Test.stopTest();
			List<Bulk_Migration_Request__c> list_BulkMR = [SELECT Id, Ownerid, Assignment_Error_Message__c, Facilitator__c FROM Bulk_Migration_Request__c WHERE id = :objBulkMigrationRequest.id];
			System.assertNotEquals(list_BulkMReq[0].Facilitator__c, list_BulkMR[0].Facilitator__c, 'Failed');
			System.assertEquals('Notify_Bulk_Migration_Request_Facilitator', list_EmailMessages[0].Email_Template_Name__c, 'Failed');
		}
	}
}