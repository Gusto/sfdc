/**
Created by : Yuvraj/Prashant
Created Date : 13/10/2020
**/
@isTest
private class ContactTriggerHelperTest {
	@testSetup
	private static void setup() {
		//create user
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('partam')
			.setEmail('partneram@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('partneram@testorg.com')
			.setExemptfromValidationRules(true)
			.build();

		// List of Accounts to insert
		List<Account> list_AccountsToInsert = new List<Account>();
		// List of Contacts to insert
		List<Contact> list_ContactsToInsert = new List<Contact>();

		//insert Company Account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('1234567890').build();
		list_AccountsToInsert.add(objCompanyAccount);

		User objcurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objcurrentUser) {
			insert objAdminUser;
		}

		Account objCompanyAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('1111').build();
		Account objCompanyAccount3 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('2222').build();

		System.runAs(objAdminUser) {
			//insert Company Account as admin user
			objCompanyAccount2.Qualified_Status_Detail__c = 'Chose Competitor';
			objCompanyAccount2.Previous_Payroll_Provider__c = '';
			insert objCompanyAccount2;

			//insert Company Account as admin user
			objCompanyAccount3.Qualified_Status_Detail__c = 'Chose Competitor';
			objCompanyAccount3.Previous_Payroll_Provider__c = '';
			insert objCompanyAccount3;
		}

		// Create a new Reseller Account
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account ').setZPFirmId('111111112343').build();
		list_AccountsToInsert.add(objResellerAccount);

		//insert Embedded Company Account
		Account objEmbeddedCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID)
			.setName('Embedded Company Account')
			.setZPCompanyId('111111122222222')
			.build();
		list_AccountsToInsert.add(objEmbeddedCompanyAccount);

		insert list_AccountsToInsert;

		//Insert Company Id
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('test@company.com')
			.setZPUserId('789456123')
			.build();
		list_ContactsToInsert.add(objContact);

		//Insert Company Id
		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objCompanyAccount2.Id)
			.setFirstName('First Name2')
			.setLastName('Last Name2')
			.setEmail('test2@company.com')
			.setZPUserId('4444')
			.build();
		list_ContactsToInsert.add(objContact2);

		insert list_ContactsToInsert;
	}

	@isTest
	private static void testBeforeInsertFieldUpdates() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];
		Contact objContact = [SELECT Id, Email, Session_ID_First__c, Phone, Unique_Email_Address_Contact__c, Referral_User__c, Referral_Date_Time__c FROM Contact WHERE Email = 'test@company.com'];

		Test.startTest();
		objContact.ZP_Phone__c = '9687777777';
		objContact.Session_Id__c = 'testSesssionId';
		objContact.Referral_Sent__c = true;
		update objContact;
		Test.stopTest();

		Contact objContactAssert = [
			SELECT Id, Session_ID_First__c, Phone, Unique_Email_Address_Contact__c, Referral_User__c, Referral_Date_Time__c, Email
			FROM Contact
			WHERE Email = 'test@company.com'
		];

		// Test if unique email address and email address are the same
		System.assertEquals(objContactAssert.Unique_Email_Address_Contact__c, objContact.Email, 'Unique Email address not set properly');
		// Test if Phone and ZP Phone are the same
		System.assertEquals(objContactAssert.Phone, objContact.ZP_Phone__c, 'Phone and ZP Phone are not in sync');
		// Test if Session Id is populated properly
		System.assertEquals(objContactAssert.Session_ID_First__c, objContact.Session_Id__c, 'Session Id First not updated properly');
		// Assert if Referral User is updated successfully
		System.assertEquals(objContactAssert.Referral_User__c, UserInfo.getUserId(), 'Referral user not updated');
		// Assert if Referral Date and Time are updated successfully
		System.assertEquals(objContactAssert.Referral_Date_Time__c != null, true, 'Referral Date Time is not updated');
	}

	@isTest
	private static void testNormalizationOnInsert() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];
		NormalizationUtil objNormalization = new NormalizationUtil();

		Map<String, String> map_EmailToNormalizedValue = new Map<String, String>();

		Test.startTest();

		map_EmailToNormalizedValue = objNormalization.normaliseDomainFieldBulkified(new Set<String>{ 'TESTEMAIL@TESTING.COM' });

		// Create new Company Contact with non-normalized email and phone
		Contact objContact = new Contact(
			LastName = 'Test Contact',
			RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID,
			AccountId = objAccount.Id,
			Email = 'TESTEMAIL@zenefits.com',
			Alternate_Email__c = 'TESTEMAIL@zenefits.com',
			Phone = '(123)-456-7890',
			MobilePhone = '(123)-456-7890',
			OtherPhone = '(123)-456-7890'
		);
		insert objContact;

		// Assert if normalizations were applied on Email and Phone
		Contact objContactAssert = [
			SELECT
				Id,
				Normalized_Email_Domain__c,
				Normalized_Alternate_Email_Domain__c,
				Email,
				Alternate_Email__c,
				Phone,
				Normalized_Phone__c,
				MobilePhone,
				Normalized_Mobile_Phone__c,
				OtherPhone,
				Normalized_Other_Phone__c
			FROM Contact
			WHERE Id = :objContact.Id
		];
		Test.stopTest();

		// Normalization of Phone numbers
		System.assertEquals(objContactAssert.Normalized_Phone__c, objNormalization.normalisePhoneField(objContactAssert.Phone), 'Phone number not normalized successfully');
		System.assertEquals(objContactAssert.Normalized_Mobile_Phone__c, objNormalization.normalisePhoneField(objContactAssert.MobilePhone), 'Mobile Phone number not normalized successfully');
		System.assertEquals(objContactAssert.Normalized_Other_Phone__c, objNormalization.normalisePhoneField(objContactAssert.OtherPhone), 'Other Phone number not normalized successfully');

		// Normalization of Email Addresses
		// Check if Map has non-normalized email address as key, then value should be normalized email domain
		if (map_EmailToNormalizedValue.containsKey(objContactAssert.Email)) {
			System.assertEquals(objContactAssert.Normalized_Email_Domain__c, map_EmailToNormalizedValue.get(objContactAssert.Email), 'Email domains not normalized successfully');
			System.assertEquals(
				objContactAssert.Normalized_Alternate_Email_Domain__c,
				map_EmailToNormalizedValue.get(objContactAssert.Alternate_Email__c),
				'Alternate Email domains not normalized successfully'
			);
		}
	}

	@isTest
	private static void testsendNotificationToSlack() {
		// Query Reseller Account
		Account objResllerAccnt = [SELECT Id FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];

		Test.startTest();
		// Create a new Resller Contact and set Send_To_Partner_Slack_New_Add__c = false
		Contact objContact = new Contact(
			LastName = 'Test Contact',
			RecordTypeId = ContactUtil.RESELLER_CONTACT_RT_ID,
			AccountId = objResllerAccnt.Id,
			Send_To_Partner_Slack_New_Add__c = false,
			Email = 'test@reseller.com'
		);
		insert objContact;
		Test.stopTest();

		// Assert if Send_To_Partner_Slack_New_Add__c was set to True
		Contact objContactAssert = [SELECT Id, Send_To_Partner_Slack_New_Add__c FROM Contact WHERE Id = :objContact.Id];

		System.assertEquals(true, objContactAssert.Send_To_Partner_Slack_New_Add__c, 'Send Partner Slack New Add Flag was not set to True');
	}

	@isTest
	private static void testTaskCreationForABCContacts() {
		// Query Company Account
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];

		Test.startTest();
		// Create a new Company Account and Set ABC_Lead_Match__c to True
		Contact objContact = new Contact(LastName = 'Test Last Name', AccountId = objAccount.Id, ABC_Lead_Match__c = true, Email = 'test@abc.com');
		insert objContact;
		Test.stopTest();

		// Query if Task was created for the newly insert Contact when ABC_Lead_Match__c is set to True
		List<Task> list_Tasks = [SELECT Id, Subject FROM Task WHERE Subject = 'New Contact from ABC' AND WhoId = :objContact.Id];
		System.assertEquals(list_Tasks.size(), 1, 'Tasks not created for Contacts when ABC_Lead_Match__c is set to true');
	}

	@isTest
	private static void testcreateTaskForResllerContact() {
		// Query Reseller Account
		Account objAccount = [SELECT Id, OwnerId FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID LIMIT 1];

		Test.startTest();
		// Create a new reseller contact and set ZP User Role as Accountant
		Contact objContact = new Contact(
			LastName = 'Test Contact',
			RecordTypeId = ContactUtil.RESELLER_CONTACT_RT_ID,
			AccountId = objAccount.Id,
			Email = 'test@resller.com',
			ZP_User_Role__c = 'Accountant'
		);
		insert objContact;
		Test.stopTest();

		// Assert if Tasks were created
		List<Task> list_Tasks = [SELECT Id, OwnerId FROM Task WHERE Subject = 'New Accountant Added' AND WhatId = :objAccount.id];
		System.assertEquals(list_Tasks.size(), 1, 'Tasks not created for reseller contacts');

		// Assert for Task's ownership
		if (!list_Tasks.isEmpty()) {
			System.assertEquals(list_Tasks.get(0).OwnerId, objAccount.OwnerId, 'Tasks owners not set to Account Owner');
		}
	}

	@isTest
	private static void testAccountDomainnInsert() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@company.com'];

		Test.startTest();
		// Fetch all email domain records related to particular account
		List<Account_Email_Domain__c> list_AccountEmailDomains = [SELECT Id, Name FROM Account_Email_Domain__c WHERE Account__c = :objAccount.Id];
		Test.stopTest();
		// Assert if number of records is greater than zero
		System.assertEquals(list_AccountEmailDomains.size() > 0, true, 'No Account Email Domain records found');

		// Fetch Email Domain record
		Account_Email_Domain__c objEmailDomain = list_AccountEmailDomains.get(0);

		Contact objContactAssert = [SELECT Id, Normalized_Email_Domain__c FROM Contact WHERE Id = :objContact.Id];
		// Assert Normalized Email Domain and Name from Account_Email_Domain__c record
		System.assertEquals(objEmailDomain.Name, objContactAssert.Normalized_Email_Domain__c, 'Email domain names not matching after insert');
	}

	@isTest
	private static void testAccountDomainMappingOnUpdate() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@company.com'];

		Test.startTest();
		// Change Email and update Contact
		objContact.Email = 'test@testing2.com';
		update objContact;
		Test.stopTest();

		// Fetch all email domain records related to particular account
		List<Account_Email_Domain__c> list_AccountEmailDomains = [SELECT Id, Name FROM Account_Email_Domain__c WHERE Account__c = :objAccount.Id];

		// Assert if number of records is greater than zero
		System.assertEquals(list_AccountEmailDomains.size() > 0, true, 'No Account Email Domain records found');

		Account_Email_Domain__c objEmailDomain = list_AccountEmailDomains.get(0);

		Contact objContactAssert = [SELECT Id, Normalized_Email_Domain__c FROM Contact WHERE Id = :objContact.Id];
		// Assert Normalized Email Domain and Name from Account_Email_Domain__c record
		System.assertEquals(objEmailDomain.Name, objContactAssert.Normalized_Email_Domain__c, 'Email domain names not matching after update');
	}

	@isTest
	private static void testAccountDomainMappingOnDelete() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@company.com'];

		Test.startTest();
		delete objContact;
		Test.stopTest();

		// Fetch all email domain records related to particular account
		List<Account_Email_Domain__c> list_AccountEmailDomains = [SELECT Id, Name FROM Account_Email_Domain__c WHERE Account__c = :objAccount.Id];

		// Assert if number of records is greater than zero
		System.assertEquals(list_AccountEmailDomains.size() == 0, true, 'Account Domain records not deleted after contact is deleted');
	}

	@isTest
	private static void testMarkExcludedDomainForUXResearch() {
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@company.com'];

		// Create a new UR_Excluded_Contact_Domain__c record
		UR_Excluded_Contact_Domain__c objExcludedDomains = new UR_Excluded_Contact_Domain__c(Name = 'company.com');
		insert objExcludedDomains;

		Test.startTest();
		update objContact;
		Test.stopTest();

		Contact objContactAssert = [SELECT Id, UXResearch_Exclude_Domain__c FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(true, objContactAssert.UXResearch_Exclude_Domain__c, 'UXResearch_Exclude_Domain__c was not set to true');
	}

	@isTest
	private static void testBeforeUpdateFieldUpdates() {
		Contact objContact = [SELECT Id, Email FROM Contact WHERE Email = 'test@company.com'];

		Test.startTest();
		// Update Contact
		Contact objContactToUpdate = new Contact(Id = objContact.Id, Email = 'test@testing2.com', ZP_Phone__c = '9687777777', Session_Id__c = 'testSesssionId');
		update objContactToUpdate;
		Test.stopTest();

		Contact objContactAssert = [SELECT Id, Session_ID_First__c, Phone, Unique_Email_Address_Contact__c, Email FROM Contact WHERE Id = :objContact.Id];

		// Test if unique email address and email address are the same
		System.assertEquals(objContactAssert.Unique_Email_Address_Contact__c, objContactToUpdate.Email, 'Unique Email address not set properly');
		// Test if Phone and ZP Phone are the same
		System.assertEquals(objContactAssert.Phone, objContactToUpdate.ZP_Phone__c, 'Phone and ZP Phone are not in sync');
		// Test if Session Id is populated properly
		System.assertEquals(objContactAssert.Session_ID_First__c, objContactToUpdate.Session_Id__c, 'Session Id First not updated properly');
	}

	@isTest
	private static void testNormalizationOnUpdate() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' LIMIT 1];
		NormalizationUtil objNormalization = new NormalizationUtil();

		Map<String, String> map_EmailToNormalizedValue = new Map<String, String>();

		map_EmailToNormalizedValue = objNormalization.normaliseDomainFieldBulkified(new Set<String>{ 'TEST@TESTING.COM', 'TEST@TESTING2.COM' });

		// Create new Company Contact with non-normalized email and phone
		Contact objContact = new Contact(
			LastName = 'Test Contact',
			RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID,
			AccountId = objAccount.Id,
			Email = 'TESTEMAIL@NORMALIZE1.COM',
			Alternate_Email__c = 'TESTEMAIL@TESTING.COM'
		);
		insert objContact;

		Test.startTest();
		Contact objContactToUpdate = new Contact(Id = objContact.Id, Email = 'TEST@NORMALIZE2.COM', Phone = '(123)-456-7890', MobilePhone = '(123)-456-7890', OtherPhone = '(123)-456-7890');
		update objContactToUpdate;
		Test.stopTest();

		// Assert if normalizations were applied on Email and Phone
		Contact objContactAssert = [
			SELECT
				Id,
				Normalized_Email_Domain__c,
				Normalized_Alternate_Email_Domain__c,
				Email,
				Alternate_Email__c,
				Phone,
				Normalized_Phone__c,
				MobilePhone,
				Normalized_Mobile_Phone__c,
				OtherPhone,
				Normalized_Other_Phone__c
			FROM Contact
			WHERE Id = :objContact.Id
		];

		// Normalization of Phone numbers
		System.assertEquals(objContactAssert.Normalized_Phone__c, objNormalization.normalisePhoneField(objContactAssert.Phone), 'Phone number not normalized successfully');
		System.assertEquals(objContactAssert.Normalized_Mobile_Phone__c, objNormalization.normalisePhoneField(objContactAssert.MobilePhone), 'Mobile Phone number not normalized successfully');
		System.assertEquals(objContactAssert.Normalized_Other_Phone__c, objNormalization.normalisePhoneField(objContactAssert.OtherPhone), 'Other Phone number not normalized successfully');

		// Normalization of Email Addresses
		// Check if Map has non-normalized email address as key, then value should be normalized email domain
		if (map_EmailToNormalizedValue.containsKey(objContactAssert.Email)) {
			System.assertEquals(objContactAssert.Normalized_Email_Domain__c, map_EmailToNormalizedValue.get(objContactAssert.Email), 'Email domains not normalized successfully');
			System.assertEquals(
				objContactAssert.Normalized_Alternate_Email_Domain__c,
				map_EmailToNormalizedValue.get(objContactAssert.Alternate_Email__c),
				'Alternate Email domains not normalized successfully'
			);
		}
	}

	@isTest
	private static void testUpdateOutreachEngagementFields() {
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@company.com'];

		Test.startTest();
		// Change ID_of_Currently_Active_Sequence__c and update contact
		objContact.ID_of_Currently_Active_Sequence__c = '342';
		update objContact;
		Test.stopTest();

		Integer intOutReach = [SELECT COUNT() FROM Outreach_Engagement__c WHERE Contact__c = :objContact.Id];

		System.assertEquals(1, intOutReach, 'Number of outreach records did not match');
	}

	@isTest
	private static void testSkipTrigger() {
		ContactTriggerHelper.skipTrigger = true;

		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test@company.com'];
		Test.startTest();
		update objContact;
		Test.stopTest();

		System.assert(true, 'Fixing apex PMD warning.');

		ContactTriggerHandler.resetSkipTriggerFlags();
	}

	/*** Test if ABC_Reseller_Lead__c is set properly on Contact ***/
	@isTest
	private static void testABCResellerLeadUpdate() {
		Lead objResellerLead = TestUtils.createNewLead(LeadUtil.RESELLER_LEAD_RT_ID, 'FName', 'LName', 'resellerlead@one.com', '123456789', 'Reseller 1', false);
		objResellerLead.LeadSource = LeadUtil.LEADSOURCE_ABC;
		insert objResellerLead;

		Account objAccount = TestUtils.createAccount(AccountUtil.COMPANY_ACCOUNT_RT_ID, 'Test Account', true);

		Test.startTest();
		Contact objContact = TestUtils.createContact(objAccount.Id, 'First Name', 'Last Name', objResellerLead.Email, true);
		Test.stopTest();

		Contact objContactAssert = [SELECT Id, ABC_Reseller_Lead__c FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(objResellerLead.Id, objContactAssert.ABC_Reseller_Lead__c, 'Id should match.');
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh
	 * @Description : Asserts if Normalized_Email_Domain__c is updated on both old and new Accounts,
						when parent AccountId is remapped on Contact
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	private static void testEmailDomainWhenParentAccountIsRemapped() {
		List<Account> list_AccountsToInsert = new List<Account>();
		List<Contact> list_ContactsToInsert = new List<Contact>();

		Account objCompanyAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Account 1').build();
		list_AccountsToInsert.add(objCompanyAccount1);

		Account objCompanyAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Account 2').build();
		list_AccountsToInsert.add(objCompanyAccount2);

		AccountTriggerHelper.skipTrigger = true;
		insert list_AccountsToInsert;
		AccountTriggerHelper.skipTrigger = false;

		Test.startTest();

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount1.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('test@testdomain1.com')
			.build();
		list_ContactsToInsert.add(objContact1);

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount1.Id)
			.setFirstName('Test First Name2')
			.setLastName('Test Last Name2')
			.setEmail('test@testdomain2.com')
			.build();
		list_ContactsToInsert.add(objContact2);

		insert list_ContactsToInsert;

		Contact objContact1InsertAssert = [SELECT Id, Normalized_Email_Domain__c FROM Contact WHERE Id = :objContact1.Id];
		// Test if domain is extracted from the Email
		System.assertEquals('testdomain1.com', objContact1InsertAssert.Normalized_Email_Domain__c, 'A domain is not extracted and set from the Email');

		Contact objContact2InsertAssert = [SELECT Id, Normalized_Email_Domain__c FROM Contact WHERE Id = :objContact2.Id];
		// Test if domain is extracted from the Email
		System.assertEquals('testdomain2.com', objContact2InsertAssert.Normalized_Email_Domain__c, 'A domain is not extracted and set from the Email');

		objContact1.AccountId = objCompanyAccount2.Id;
		update objContact1;

		Test.stopTest();

		Contact objContact1UpdateAssert = [SELECT Id, Normalized_Email_Domain__c FROM Contact WHERE Id = :objContact1.Id];
		// Test if domain is extracted from the Email
		System.assertEquals('testdomain1.com', objContact1UpdateAssert.Normalized_Email_Domain__c, 'A domain is not extracted and set from the Email');

		Account objCompanyAccount1Assert = [SELECT Id, Normalized_Email_Domain__c FROM Account WHERE Id = :objCompanyAccount1.Id];
		// Test if domain on Account is reset
		System.assertEquals('testdomain2.com', objCompanyAccount1Assert.Normalized_Email_Domain__c, 'The domain is not reset when parent account on contact is remapped');

		Account objCompanyAccount2Assert = [SELECT Id, Normalized_Email_Domain__c FROM Account WHERE Id = :objCompanyAccount2.Id];
		// Test if domain on Account is reset
		System.assertEquals('testdomain1.com', objCompanyAccount2Assert.Normalized_Email_Domain__c, 'The domain is not reset when parent account on contact is remapped');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Website field on Account is not overridden due to new contacts insert or update
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testWebsiteOverrideOnAccount() {
		AccountTriggerHelper.skipTrigger = true;
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('ABC Account 1')
			.setNormalizedEmailDomain('normdomain.com')
			.setWebsite('www.normdomain.com')
			.build();
		insert objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		Test.startTest();
		// Insert a contact with generic email domain. Result = Account Website should be blank
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newemail@newdomain.com')
			.build();
		insert objContact;
		Test.stopTest();

		Account objAccAssert = [SELECT Id, Normalized_Email_Domain__c, Website FROM Account WHERE Id = :objCompanyAccount.Id];

		// Assert Website field is not overriden due to new contacts getting inserted
		// Account website takes priority over Account Email Domain
		System.assertEquals(objCompanyAccount.Website, objAccAssert.Website, 'Website should match.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Insert a contact with generic email domain. Result = Account Website should be blank
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testWebsiteUpdateOnAccount() {
		AccountTriggerHelper.skipTrigger = true;
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('ABC Account 1').build();
		insert objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		Email_Domain__c objDomain = new TestDataFactory.EmailDomainBuilder().setName('fakedomain.com').build();
		insert objDomain;

		Account objAccAssert = [SELECT Id, Normalized_Email_Domain__c, Website FROM Account WHERE Id = :objCompanyAccount.Id];

		// Assert email domain and website are already blank
		System.assert(String.isBlank(objAccAssert.Normalized_Email_Domain__c), 'Normalized_Email_Domain__c should be blank.');
		System.assert(String.isBlank(objAccAssert.Website), 'Website should be blank.');

		Test.startTest();
		// Insert a contact with generic email domain. Result = Account Website should be blank
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newemail@fakedomain.com')
			.build();
		insert objContact;
		Test.stopTest();

		objAccAssert = [SELECT Id, Normalized_Email_Domain__c, Website FROM Account WHERE Id = :objCompanyAccount.Id];

		// Assert email domain and website are not updated
		System.assert(String.isBlank(objAccAssert.Normalized_Email_Domain__c), 'Normalized_Email_Domain__c should be blank.');
		System.assert(String.isBlank(objAccAssert.Website), 'Website should be blank.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test Reseller Lead is getting converted into Reseller Contact
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testResellerLeadConvertsIntoResellerContact() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.RESELLER_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setCompany('CompanyAcc')
			.setEmail('resellerlead@gmail.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setLeadSource('In-app')
			.build();
		LeadTriggerHelper.skipTrigger = true;
		insert objLead;

		Test.startTest();
		// Convert Lead
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });
		Test.stopTest();

		Contact objConAssert = [SELECT Id, RecordTypeId FROM Contact WHERE Email = :objLead.Email];
		System.assertEquals(ContactUtil.RESELLER_CONTACT_RT_ID, objConAssert.RecordTypeId, 'Record Type Id should match.');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test Company Lead is getting converted into Company Contact
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	@isTest
	static void testCompanyLeadConvertsIntoCompanyContact() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setCompany('CompanyAcc')
			.setEmail('company@gmail.com')
			.setPhone('123456789')
			.setCompany('Company Lead')
			.setLeadSource('In-app')
			.build();
		LeadTriggerHelper.skipTrigger = true;
		// ZP Company Id is required before conversion
		objLead.ZP_Company_Id__c = '123456';
		insert objLead;

		Test.startTest();
		// Convert Lead
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });
		Test.stopTest();

		Contact objConAssert = [SELECT Id, RecordTypeId FROM Contact WHERE Email = :objLead.Email];
		System.assertEquals(ContactUtil.COMPANY_CONTACT_RT_ID, objConAssert.RecordTypeId, 'Record Type Id should match.');
	}

	/**
	 * @description Test if Recent fields (Source, Campaign, Content are set on Campaign Member from Contact)
	 * @author      Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testRecentAttributionOnContact() {
		// Creating Company Account
		Account objAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		AccountTriggerHelper.skipTrigger = true;
		insert objAccnt;
		AccountTriggerHelper.skipTrigger = false;

		// Creating Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('newmember@recentcampaign.com')
			.build();

		ContactTriggerHelper.skipTrigger = true;
		insert objContact;
		ContactTriggerHelper.skipTrigger = false;

		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Recent Attribution Contact').setIsActive(true).setType(ContactUtil.CAMPAIGN_TYPE_WEBINAR).build();
		CampaignTriggerHelper.blnSkipTrigger = true;
		insert objCampaign;
		CampaignTriggerHelper.blnSkipTrigger = false;

		CampaignMember objMember = new TestDataFactory.CampaignMemberBuilder().setContactId(objContact.Id).setStatus('Responded').setCampaignId(objCampaign.Id).build();
		CampaignMemberTriggerHelper.skipTrigger = true;
		insert objMember;
		CampaignMemberTriggerHelper.skipTrigger = false;

		Test.startTest();
		Contact objContactToUpdate = new Contact(Id = objContact.Id, Recent_Source__c = 'Recent Source', Recent_Campaign__c = 'Recent Campaign', Recent_Content__c = 'Recent Content');
		update objContactToUpdate;
		Test.stopTest();

		CampaignMember objMemberAssert = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM CampaignMember WHERE Id = :objMember.Id];
		System.assertEquals(objContactToUpdate.Recent_Source__c, objMemberAssert.Recent_Source__c, 'Recent_Source__c should match.');
		System.assertEquals(objContactToUpdate.Recent_Campaign__c, objMemberAssert.Recent_Campaign__c, 'Recent_Campaign__c should match.');
		System.assertEquals(objContactToUpdate.Recent_Content__c, objMemberAssert.Recent_Content__c, 'Recent_Content__c should match.');
	}

	/**
	 * @description Test if Recent fields (Source, Campaign, Content are  NOT set on Campaign Member from Contact)
	 * @author      Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	static void testRecentAttributionOnContactNegative() {
		// Creating Company Account
		Account objAccnt = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account 1').setZPCompanyId('1111111111').build();
		AccountTriggerHelper.skipTrigger = true;
		insert objAccnt;
		AccountTriggerHelper.skipTrigger = false;

		// Creating Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('newmember@recentcampaign.com')
			.build();

		ContactTriggerHelper.skipTrigger = true;
		insert objContact;
		ContactTriggerHelper.skipTrigger = false;

		// Creating new active Campaign
		Campaign objCampaign = new TestDataFactory.CampaignBuilder().setName('Recent Attribution Contact').setIsActive(true).setType('Event').build();
		CampaignTriggerHelper.blnSkipTrigger = true;
		insert objCampaign;
		CampaignTriggerHelper.blnSkipTrigger = false;

		CampaignMember objMember = new TestDataFactory.CampaignMemberBuilder().setContactId(objContact.Id).setStatus('Responded').setCampaignId(objCampaign.Id).build();
		CampaignMemberTriggerHelper.skipTrigger = true;
		insert objMember;
		CampaignMemberTriggerHelper.skipTrigger = false;

		Test.startTest();
		Contact objContactToUpdate = new Contact(Id = objContact.Id, Recent_Source__c = 'Recent Source', Recent_Campaign__c = 'Recent Campaign', Recent_Content__c = 'Recent Content');
		update objContactToUpdate;
		Test.stopTest();

		CampaignMember objMemberAssert = [SELECT Id, Recent_Source__c, Recent_Campaign__c, Recent_Content__c FROM CampaignMember WHERE Id = :objMember.Id];
		System.assertNotEquals(objContact.Recent_Source__c, objMemberAssert.Recent_Source__c, 'Recent_Source__c should match.');
		System.assertNotEquals(objContact.Recent_Campaign__c, objMemberAssert.Recent_Campaign__c, 'Recent_Campaign__c should match.');
		System.assertNotEquals(objContact.Recent_Content__c, objMemberAssert.Recent_Content__c, 'Recent_Content__c should match.');
	}

	@isTest
	private static void testSetContactCompanyRecordType() {
		// Query company account
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '1234567890' AND RecordTypeId = :AccountUtil.COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Test.startTest();
		// Create a Reseller Contact and associate it with Company Account
		Contact objContact = new Contact(LastName = 'Test Contact', RecordTypeId = ContactUtil.RESELLER_CONTACT_RT_ID, AccountId = objAccount.Id);
		insert objContact;
		Test.stopTest();

		// Assert if Record Type changes from Reseller to Company
		Contact objContactAssert = [SELECT Id, RecordTypeId FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(ContactUtil.COMPANY_CONTACT_RT_ID, objContactAssert.RecordTypeId, 'Reseller record type was not changed to Company');
	}

	@isTest
	private static void testSetEmbeddedCompanyRecordType() {
		// Query embedded company account
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '111111122222222' AND RecordTypeId = :AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Test.startTest();
		// Create a Company Contact and associate it with Embedded Company Account
		Contact objContact = new Contact(LastName = 'Test Embedded Contact', RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID, AccountId = objAccount.Id);
		insert objContact;
		Test.stopTest();

		// Assert if Record Type changes from Company to Embedded Company
		Contact objContactAssert = [SELECT Id, RecordTypeId FROM Contact WHERE Id = :objContact.Id];
		System.assertEquals(ContactUtil.EMBEDDED_COMPANY_CONTACT_RT_ID, objContactAssert.RecordTypeId, 'Company record type was not changed to Embedded Company');
	}

	@isTest
	private static void testAccountValidationSkip() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '2222' LIMIT 1];
		Contact objContact = [SELECT Id, Email, AccountId FROM Contact WHERE Email = 'test2@company.com'];

		Test.startTest();
		objContact.AccountId = objAccount.Id;
		update objContact;
		Test.stopTest();

		Contact objContactAssert = [SELECT Id, AccountId, Email FROM Contact WHERE Email = 'test2@company.com'];

		System.assertEquals(objContactAssert.AccountId, objAccount.Id, 'Id should match.');
	}

	/**
	 * @author     Debasmita Rawooth
	 * @description Test if Email Opt Out - Outreach is getting updated based on subscription preferences
	 **/
	@isTest
	static void testEmailOptOutOutreachUpdate() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '111111122222222' AND RecordTypeId = :AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Set<String> set_finalSubscriptionValues = new Set<String>();
		// Creating Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('subscription@preference.com')
			.build();

		insert objContact;

		Contact objContactAssert = [SELECT Id, Salesloft_Email_Opt_Out__c, Customer_Subscriptions__c FROM Contact WHERE Id = :objContact.Id];

		System.assertEquals(true, objContactAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.OUTREACH), 'Outreach preference is not updated');
		System.assertEquals(false, objContactAssert.Salesloft_Email_Opt_Out__c, 'Email Opt Out - Outreach is updated on insert.');

		if (objContactAssert.Customer_Subscriptions__c != null) {
			set_finalSubscriptionValues.addAll(objContactAssert.Customer_Subscriptions__c.split(';'));
		}
		if (set_finalSubscriptionValues.contains(SubscriptionCenterUtil.OUTREACH)) {
			set_finalSubscriptionValues.remove(SubscriptionCenterUtil.OUTREACH);
		}

		Test.startTest();
		// update subscription preference to remove Outreach and check Email Opt Out - Outreach is updated
		objContact.Customer_Subscriptions__c = String.join(new List<String>(set_finalSubscriptionValues), ';');
		update objContact;
		Test.stopTest();

		objContactAssert = [
			SELECT Id, Salesloft_Email_Opt_Out__c
			FROM Contact
			WHERE Id = :objContact.Id
		];

		System.assertEquals(true, objContactAssert.Salesloft_Email_Opt_Out__c, 'Email Opt Out - Outreach is not updated.');
	}

	/**
	 * @author     Debasmita Rawooth
	 * @description Test if subscription preferences are getting updated based on Email Opt Out - Outreach update.
	 **/
	@isTest
	static void testSubscriptionPreferenceOutreachUpdate() {
		Account objAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = '111111122222222' AND RecordTypeId = :AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID LIMIT 1];

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('subscription@preference.com')
			.build();

		insert objContact;

		Contact objContactAssert = [SELECT Id, Salesloft_Email_Opt_Out__c, Customer_Subscriptions__c FROM Contact WHERE Id = :objContact.Id];

		System.assertEquals(true, objContactAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.OUTREACH), 'Outreach preference is not updated');
		System.assertEquals(false, objContactAssert.Salesloft_Email_Opt_Out__c, 'Email Opt Out - Outreach is updated on insert.');

		Test.startTest();
		// update subscription preference to remove Outreach and check Email Opt Out - Outreach is updated
		objContact.Salesloft_Email_Opt_Out__c = true;
		update objContact;
		Test.stopTest();

		objContactAssert = [
			SELECT Id, Salesloft_Email_Opt_Out__c, Customer_Subscriptions__c
			FROM Contact
			WHERE Id = :objContact.Id
		];

		System.assertEquals(false, objContactAssert.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.OUTREACH), 'Outreach preference is not removed.');
	}
}