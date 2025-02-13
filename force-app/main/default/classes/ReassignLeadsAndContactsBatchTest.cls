/**
 * @name         : ReassignLeadsAndContactsBatchTest
 * @author       : Prity Kumari
 * @date         : 04-20-2022
 * @description  : ReassignLeadsAndContactsBatch Test Class
 * @test classes : N/A
 **/
@IsTest
public with sharing class ReassignLeadsAndContactsBatchTest {
	@testSetup
	static void testUserFeatureChange() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setReassignLeadsAndContactsBatchSize(1000).build();
		insert objConfigSettings;
		Profile objProfile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		UserRole objUserRole = new UserRole(Name = 'CEO');
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		User objPartnerUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(objProfile1.Id)
			.setUserRoleId(objUserRole.Id)
			.setUserName('testsalespartneruserfortask@testtask.com')
			.setFirstName('Test FName')
			.setLastName('Test LName')
			.setEmail('testsalespartneruserfortask@testtask.com')
			.setAlias('puser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();

		System.runAs(objCurrentUser) {
			UserTriggerHelper.skipTrigger = true;
			insert objPartnerUser;
		}
		Account objAccountReseller = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('ABC Reseller Account 1').build();
		insert objAccountReseller;
		Contact objResellerContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.RESELLER_CONTACT_RT_ID)
			.setAccountId(objAccountReseller.Id)
			.setFirstName('Test Company')
			.setLastName('Contact 1')
			.setPhone('1234561234')
			.setEmail('newcontact1@task.com')
			.setNormalizedPhone('1234561234')
			.setOwnerId(objPartnerUser.Id)
			.build();
		ContactTriggerHelper.skipTrigger = true;
		insert objResellerContact;
		ContactTriggerHelper.skipTrigger = false;
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('Test Reseller')
			.setLastName('Lead1')
			.setEmail('test1@test.com')
			.setCompany('ABC Lead')
			.setLeadCreationOffer('List Upload')
			.setLeadSource('Test Class')
			.setAccountCreatedDate(DateTime.now().addDays(-10))
			.setOwnerId(objPartnerUser.Id)
			.build();
		insert objLead;
	}
	/**
	 * @author      : Prity Kumari
	 * @description : Test for Reseller Contacts and Unconverted Leads for
	 *                Inactive Owners go to Chris Charter
	 * @parm        : N/A
	 * @return      : N/A
	 **/
	@isTest
	static void testReassignmentOfLeadsContacts() {
		User objInactiveUser = [SELECT Id, IsActive FROM User WHERE LastName = 'Test LName' LIMIT 1];
		objInactiveUser.IsActive = false;
		update objInactiveUser;

		Test.startTest();
		ReassignLeadsAndContactsBatch.idTestUser = objInactiveUser.Id;
		Id batchJobId = Database.executeBatch(new ReassignLeadsAndContactsBatch(), 1000);
		Test.stopTest();

		Contact objCon = [SELECT OwnerId FROM Contact WHERE Email = 'newcontact1@task.com'];
		System.assertEquals(System.Label.Reseller_Inactive_Owner, objCon.OwnerId);

		Lead objLead = [SELECT OwnerId FROM Lead WHERE Email = 'test1@test.com'];
		System.assertEquals(System.Label.Reseller_Inactive_Owner, objLead.OwnerId);
	}

	/**
	 * @Author      : Prity Kumari
	 * @Description : Test Scheduler
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testReassignLeadsAndContactsScheduler() {
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		User objInactiveUser = [SELECT Id, IsActive FROM User WHERE LastName = 'Test LName' LIMIT 1];
		objInactiveUser.IsActive = false;
		update objInactiveUser;
		System.runAs(objCurrentUser) {
			Test.startTest();
			Integer intYear = Date.today().year() + 1;
			String strCronExp = '0 0 0 15 3 ? ' + intYear;

			ReassignLeadsAndContactsBatch.idTestUser = objInactiveUser.Id;
			ReassignLeadsAndContactsScheduler objScheduler = new ReassignLeadsAndContactsScheduler();
			String strJobId = System.schedule('Test ReassignLeadsAndContactsScheduler', strCronExp, objScheduler);
			// Directly call Scheduler's execute method
			objScheduler.execute(null);
			Test.stopTest();
		}

		Contact objCon = [SELECT OwnerId FROM Contact WHERE Email = 'newcontact1@task.com'];
		System.assertEquals(System.Label.Reseller_Inactive_Owner, objCon.OwnerId);

		Lead objLead = [SELECT OwnerId FROM Lead WHERE Email = 'test1@test.com'];
		System.assertEquals(System.Label.Reseller_Inactive_Owner, objLead.OwnerId);

		//User objAssertUser = [SELECT Id, Inactive__c FROM User WHERE LastName = 'Test LName' LIMIT 1];
		//System.assertEquals(false, objAssertUser.Inactive__c, 'User Inactive__c flag should be unchecked');
	}
}