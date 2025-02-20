/**
 *author: Midhuna KB
 *date: 21-01-2021
 *desc: Tets Class for LogSmartCallingControllerLEX
 **/

@isTest
public class LogSmartCallingControllerLEXTest {
	/**
	 * @Author      : Ankit CS
	 * @Description : Creating test data
	 **/
	@testSetup
	static void setup() {
		Test.startTest();
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		Map<String, UserRole> map_UserRoleNameToRole = new Map<String, UserRole>();
		Set<String> set_UserRoleNames = new Set<String>{
			LogSmartCallingUtil.ROLE_SALES_MM_PR_XX,
			LogSmartCallingUtil.ROLE_SALES_SDR_MM_MGR_XX,
			LogSmartCallingUtil.ROLE_SALES_SDR_MM_XX,
			LogSmartCallingUtil.ROLE_SALES_BDR_XX_XX,
			LogSmartCallingUtil.ROLE_SALES_SDR_PARTNER_MGR_XX,
			LogSmartCallingUtil.ROLE_SALES_SDR_PARTNER_XX,
			LogSmartCallingUtil.ROLE_SALES_PARTNER_AE_XX,
			LogSmartCallingUtil.ROLE_ARDIUS,
			LogSmartCallingUtil.ROLE_CUSTOMER_SUCCESS
		};
		Set<String> set_ProfileNames = new Set<String>{
			LogSmartCallingUtil.PROFILE_MDR,
			LogSmartCallingUtil.PROFILE_BENEFITS_USER,
			LogSmartCallingUtil.PROFILE_MMPR_USER,
			LogSmartCallingUtil.PROFILE_CX_USER,
			LogSmartCallingUtil.PROFILE_DEL_ZP_PARTNER_AE,
			LogSmartCallingUtil.PROFILE_ARDIUS_BASE_USER
		};
		Map<String, Profile> map_ProfileNameToProfile = new Map<String, Profile>();

		for (Profile objProfile : [SELECT Id, Name FROM Profile WHERE Name IN :set_ProfileNames]) {
			map_ProfileNameToProfile.put(objProfile.Name, objProfile);
		}

		for (UserRole objUserRole : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN :set_UserRoleNames]) {
			map_UserRoleNameToRole.put(objUserRole.DeveloperName, objUserRole);
		}

		AccountTriggerHelper.skipTrigger = true;

		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('test Res Account').setZPFirmId('firmid01').build();
		insert objResellerAccount;

		//create the Account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(LogSmartCallingUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Co.')
			.setBillingStreet('298 S. Ringo Street')
			.setBillingCity('Little Rock')
			.setBillingPostalCode('72201')
			.setBillingCountry('United States')
			.setPhone('501-555-5555')
			.setWebsite('www.testco.com')
			.setZPCompanyID('zpcompanyid01')
			.setSoldBy(objResellerAccount.Id)
			.build();
		insert objCompanyAccount;

		ContactTriggerHelper.skipTrigger = true;
		//create a primary contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('Paul')
			.setLastName('Test')
			.setPhone('04802701314')
			.setEmail('testUser@yopmail.com')
			.setNormalizedPhone('04802701314')
			.setMailingStreet('298 S. Ringo Street')
			.setMailingCity('Little Rock')
			.setMailingPostalCode('72201')
			.setMobilePhone('9876543210')
			.setZPPhone('9876544321')
			.build();

		ContactTriggerHelper.skipTrigger = true;
		insert objContact;

		CaseTriggerHelper.skipTrigger = true;
		//Create Case
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setContactId(objContact.Id)
			.setType('Payroll Care')
			.setStatus('Open')
			.setPriority('Medium')
			.setDescription('Test Case 1 Description')
			.setSubject('Test Case 1 Subject')
			.build();
		insert objCase;

		//Create Lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName1 setup')
			.setLastName('LName1 setup')
			.setEmail('testlead1@setup.com')
			.setPhone('123456789')
			.setCompany('Oreo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('LinkedIn')
			.build();
		LeadTriggerHelper.skipTrigger = true;
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		//insert User Records
		List<User> list_Users = new List<User>();
		String strUniqueBenefitsUserName = 'benefitsuser' + DateTime.now().getTime() + '@testorg.com';
		User objBenefitsUser = new TestDataFactory.UserBuilder()
			.setAlias('benef')
			.setEmail('benefitsuser@testorg.com')
			.setFirstName('Benefit FName')
			.setLastName('Benefit LName')
			.setProfileId(map_ProfileNameToProfile.get(LogSmartCallingUtil.PROFILE_BENEFITS_USER).Id)
			.setIsActive(true)
			.setUserName(strUniqueBenefitsUserName)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();
		list_Users.add(objBenefitsUser);

		String strMMPRUserName = 'mmpruser' + DateTime.now().getTime() + '@testorg.com';
		User objMMPRUserUser = new TestDataFactory.UserBuilder()
			.setAlias('mmpr')
			.setEmail('mmpruser@testorg.com')
			.setFirstName('MMPR FName')
			.setLastName('MMPR LName')
			.setProfileId(map_ProfileNameToProfile.get(LogSmartCallingUtil.PROFILE_MMPR_USER).Id)
			.setUserRoleId(map_UserRoleNameToRole.get(LogSmartCallingUtil.ROLE_SALES_MM_PR_XX).Id)
			.setIsActive(true)
			.setUserName(strMMPRUserName)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();
		list_Users.Add(objMMPRUserUser);

		// Insert CX User Reccord
		String strUniqueCXUserName = 'cxuser' + DateTime.now().getTime() + '@testorg.com';
		User objCXUser = new TestDataFactory.UserBuilder()
			.setAlias('standt')
			.setEmail('cxuser@testorg.com')
			.setFirstName('CX FName')
			.setLastName('CX LName')
			.setProfileId(map_ProfileNameToProfile.get(LogSmartCallingUtil.PROFILE_CX_USER).Id)
			.setUserRoleId(map_UserRoleNameToRole.get(LogSmartCallingUtil.ROLE_CUSTOMER_SUCCESS).Id)
			.setIsActive(true)
			.setUserName(strUniqueCXUserName)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();
		list_Users.add(objCXUser);

		String strUniqueMDRUserName = 'mdruser' + DateTime.now().getTime() + '@testorg.com';
		User objMDRUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_ProfileNameToProfile.get(LogSmartCallingUtil.PROFILE_MDR).Id)
			.setUserRoleId(map_UserRoleNameToRole.get(LogSmartCallingUtil.ROLE_SALES_SDR_PARTNER_XX).Id)
			.setUserName(strUniqueMDRUserName)
			.setFirstName('MDR FName')
			.setLastName('MDR LName')
			.setEmail('mdruser@testorg.com')
			.setAlias('mduser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();
		list_Users.add(objMDRUser);

		String strUniquePartnerUserName = 'partneruser' + DateTime.now().getTime() + '@testorg.com';
		User objPartnerUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_ProfileNameToProfile.get(LogSmartCallingUtil.PROFILE_DEL_ZP_PARTNER_AE).Id)
			.setUserRoleId(map_UserRoleNameToRole.get(LogSmartCallingUtil.ROLE_SALES_PARTNER_AE_XX).Id)
			.setUserName(strUniquePartnerUserName)
			.setFirstName('Partner FName')
			.setLastName('Partner LName')
			.setEmail('partneruser@testorg.com')
			.setAlias('ptnruser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();
		list_Users.add(objPartnerUser);

		// Added as part of SIFA-250
		String strUniqueArdiusUserName = 'ardiususer' + DateTime.now().getTime() + '@testorg.com';
		User objArdiusUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(map_ProfileNameToProfile.get(LogSmartCallingUtil.PROFILE_ARDIUS_BASE_USER).Id)
			.setUserRoleId(map_UserRoleNameToRole.get(LogSmartCallingUtil.ROLE_ARDIUS).Id)
			.setUserName(strUniqueArdiusUserName)
			.setFirstName('Ardius FName')
			.setLastName('Ardius LName')
			.setEmail('ardiususer@testorg.com')
			.setAlias('arduser')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.build();
		list_Users.add(objArdiusUser);

		System.runAs(objcurrentUser) {
			insert list_Users;
		}

		OpportunityTriggerHelper.skipTrigger = true;
		//creating opportunities
		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Opportunity objCompanyOpp = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Company Opp')
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
			.setCloseDate(Date.today())
			.setStage('Posted')
			.setOwnerId(objMDRUser.Id)
			.setZPCompanyID(objCompanyAccount.ZP_Company_Id__c)
			.build();
		list_Opportunities.add(objCompanyOpp);

		Opportunity objBenefitsOpp = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Benefits New Plan Opp')
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits New Plan'))
			.setCloseDate(Date.today() + 10)
			.setStage('New')
			.setOwnerId(objBenefitsUser.Id)
			.build();
		list_Opportunities.add(objBenefitsOpp);

		Opportunity objCustomerSuccessOpp = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Customer Success Opp')
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Customer Success'))
			.setCloseDate(Date.today() + 10)
			.setStage('New')
			.setOwnerId(objCXUser.Id)
			.build();
		list_Opportunities.add(objCustomerSuccessOpp);

		//Added as part of SIFA-250
		Opportunity objArdiusSalesOpp = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objCompanyAccount.Id)
			.setName('Test Tax Credits Opp')
			.setRecordTypeId(OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID)
			.setCloseDate(Date.today() + 30)
			.setStage('New')
			.setOwnerId(objArdiusUser.Id)
			.build();
		list_Opportunities.add(objArdiusSalesOpp);

		insert list_Opportunities;

		//Added as part of SIFA-250
		Ticket__c objArdiusTicket = new TestDataFactory.TicketBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Ticket__c', 'Ardius'))
			.setOwnerId(objArdiusUser.Id)
			.setStatus('New')
			.setAccountId(objCompanyAccount.Id)
			.setOppId(objArdiusSalesOpp.Id)
			.build();
		TicketTriggerHelper.skipTrigger = true;
		insert objArdiusTicket;
		TicketTriggerHelper.skipTrigger = false;

		//Create Opp Contact Role
		insert new List<OpportunityContactRole>{
			new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(objCompanyOpp.Id).setContactId(objContact.Id).setRole('Payroll Admin').setIsPrimary(true).build(),
			new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(objBenefitsOpp.Id).setContactId(objContact.Id).setRole('Payroll Admin').setIsPrimary(true).build(),
			new TestDataFactory.OpportunityContactRoleBuilder().setOpportunityId(objArdiusSalesOpp.Id).setContactId(objContact.Id).setRole('Payroll Admin').setIsPrimary(true).build()
		};

		//Insert ZP_User_Role__c Record
		ZP_User_Role__c objZPUserRole = new TestDataFactory.ZPUserRoleBuilder()
			.setCompanyAccount(objCompanyAccount.Id)
			.setCompanyId('1234')
			.setContact(objContact.Id)
			.setType('Role::PayrollAdmin')
			.setIsPrimary(false)
			.build();
		insert objZPUserRole;

		//Insert Task records
		insert new List<Task>{
			new TestDataFactory.TaskBuilder().setRecordTypeId(TaskUtil.TASK_CALL_RT_ID).setWhatId(objCompanyAccount.Id).setStatus('Scheduled').build(),
			new TestDataFactory.TaskBuilder().setRecordTypeId(TaskUtil.TASK_CALL_RT_ID).setWhatId(list_Opportunities[0].Id).setStatus('Scheduled').build()
		};

		//Insert States
		insert new List<State__c>{
			new TestDataFactory.StateBuilder().setName('Alabama').setId('1').setAbbreviation('AL').build(),
			new TestDataFactory.StateBuilder().setName('Alaska').setId('2').setAbbreviation('AK').build()
		};

		insert new List<Nice_Interaction__c>{
			new TestDataFactory.NICEInteractionBuilder().setDNIS(new normalizationUtil().normalisePhoneField('1111111111')).setEmailId(objCXUser.Email).setContactID('0000000000000000').build(),
			new TestDataFactory.NICEInteractionBuilder().setDNIS('1111111111').setEmailId('fakeaddress@fake.com').setContactID('9999').build()
		};
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for getStates()
	 **/
	@isTest
	static void testGetStates() {
		Test.startTest();
		List<String> list_States = LogSmartCallingControllerLEX.getStates();
		System.assertEquals(2, list_States.size());
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to get data on load
	 **/
	@isTest
	static void testLogSmartCallingController() {
		Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		User objCXUser = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Email = 'cxuser@testorg.com' LIMIT 1];
		Set<Id> set_AccountIds = new Set<Id>{ objAccount.id };

		Test.startTest();
		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties('Account', objAccount.id);
		String strMetadata = objResponseWrapper.strMetadataProperties;
		Object objAccountContacts = LogSmartCallingControllerLEX.getAccountContacts(objAccount.Id, objCXUser);
		List<Opportunity> list_Opportunities = LogSmartCallingControllerLEX.queryBenefitsOpp(set_AccountIds);
		System.runAs(objCXUser) {
			LogSmartCallingControllerLEX.getAccountContacts(objAccount.Id, objCXUser);
		}
		String strRandomid = LogSmartCallingControllerLEX.getRandomId();
		Test.stopTest();

		System.assertEquals(true, !String.isBlank(strMetadata));
		System.assertEquals(true, objAccountContacts != null);
		System.assertEquals(true, !String.isBlank(strRandomid));
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for createHIOpportunity()
	 **/
	@isTest
	static void testcreateHIOpportunity() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		User objBenefitsUser = [SELECT Id, UserRole.Name, Profile.Name FROM User WHERE Email = 'benefitsuser@testorg.com' LIMIT 1];
		List<AllSmartCalling__mdt> list_MdtSmartCall = LogSmartCallingControllerLEX.queryAllSmartCalling(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objBenefitsUser.Profile.Name);
		List<Contact> list_Contacts = [SELECT Id FROM Contact];
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
		List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
		objFieldSetProperties.strFieldValue = 'Test Notes';
		objFieldSetProperties.strFieldLabel = '401k Notes';
		objFieldSetProperties.strFieldType = 'Long Text Area';
		objFieldSetProperties.blnFieldRequired = false;
		list_FieldSetProperties.add(objFieldSetProperties);

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = 'Account';
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strDisposition = 'Test strDisposition';
		objComponentParameters.strNotes = 'Test strNotes';
		objComponentParameters.blnInboundCall = true;
		objComponentParameters.blnOutboundEmail = true;
		objComponentParameters.blnCreateProductUpsell = true;
		objComponentParameters.list_ProductUpsellValues = list_FieldSetProperties;
		objComponentParameters.list_ObjectDetailValues = list_FieldSetProperties;
		objComponentParameters.blnDoNotCall = true;
		objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
		objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
		objComponentParameters.blnCreatePayrollOpportunity = true;
		objComponentParameters.strPayrollOpportunityName = 'Test strPayrollOpportunityName';
		objComponentParameters.strPayrollOpportunityStage = 'Open';
		objComponentParameters.strPayrollOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.blnCreateHIOpportunity = true;
		objComponentParameters.strHIOpportunityType = 'HI Benefits New Plan';
		objComponentParameters.strHIOpportunityStage = 'Open';
		objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.strHIOpportunityState = '';
		objComponentParameters.strHIOpportunityEmployees = '100';
		objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
		objComponentParameters.strPhoneNumber = '1234567890';
		objComponentParameters.blnHIOpportunityLiveTransfer = true;
		objComponentParameters.strSelectedHIOppConId = list_Contacts[0].Id;
		Test.startTest();
		System.runAs(objBenefitsUser) {
			LogSmartCallingControllerLEX.createHIOpportunity(objComponentParameters, list_MdtSmartCall[0], objBenefitsUser, objAccount.Id, 'Test Opportunity Name1');
			objComponentParameters.strHIOpportunityType = 'HI Benefits BoR';
			LogSmartCallingControllerLEX.createHIOpportunity(objComponentParameters, list_MdtSmartCall[0], objBenefitsUser, objAccount.Id, 'Test Opportunity Name2');
			objComponentParameters.strHIOpportunityType = 'Benefits BYOB';
			objComponentParameters.strObjectName = 'Opportunity';
			LogSmartCallingControllerLEX.createHIOpportunity(objComponentParameters, list_MdtSmartCall[0], objBenefitsUser, objAccount.Id, 'Test Opportunity Name3');
		}
		Test.stopTest();

		Opportunity objOpp = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Benefits BYOB' LIMIT 1];
		System.assertEquals(objOpp != null, true);

		OpportunityContactRole objOppContRole = [SELECT ID,Role FROM OpportunityContactRole WHERE Opportunity.RecordType.Name = 'Benefits BYOB' AND Role =: LogSmartCallingUtil.BENEFITS_OPPORTUNITY_CONTACT_ROLE Limit 1];
		System.assertEquals(objOppContRole != null, true);
		System.assertEquals(objOppContRole.Role, LogSmartCallingUtil.BENEFITS_OPPORTUNITY_CONTACT_ROLE);
	}

	/**
	 * @Author      : Deepesh Rao
	 * @Description : Test method for createArdiusOpportunity()
	 **/
	@isTest
	static void testcreateArdiusOpportunity() {
		User objCXUser = [SELECT Id, UserRole.Name, Profile.Name FROM User WHERE Email = 'cxuser@testorg.com' LIMIT 1];
		List<AllSmartCalling__mdt> list_MdtSmartCall = LogSmartCallingControllerLEX.queryAllSmartCalling(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objCXUser.Profile.Name);
		List<Contact> list_Contacts = [SELECT Id FROM Contact];
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
		List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
		objFieldSetProperties.strFieldValue = 'Test Notes';
		objFieldSetProperties.strFieldLabel = '401k Notes';
		objFieldSetProperties.strFieldType = 'Long Text Area';
		objFieldSetProperties.blnFieldRequired = false;
		list_FieldSetProperties.add(objFieldSetProperties);

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = 'Account';
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strDisposition = 'Test strDisposition';
		objComponentParameters.strNotes = 'Test strNotes';
		objComponentParameters.blnDoNotCall = true;
		objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
		objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
		objComponentParameters.blnCreateArdiusOpportunity = true;
		objComponentParameters.strArdiusOpportunityStage = 'New';
		objComponentParameters.strType = 'New Business';
		objComponentParameters.strArdiusOpportunityCloseDate = String.valueOf(Date.today().addDays(15));

		Test.startTest();
		System.runAs(objCXUser) {
			//LogSmartCallingControllerLEX.createArdiusOpportunity(objComponentParameters, list_MdtSmartCall[0], objCXUser, objAccount.Id, '');
			objComponentParameters.strObjectName = 'Opportunity';
			LogSmartCallingControllerLEX.createArdiusOpportunity(objComponentParameters, list_MdtSmartCall[0], objCXUser, objAccount.Id, '');
		}
		Test.stopTest();

		Opportunity objOpp = [SELECT Id FROM Opportunity WHERE RecordType.Name = 'Tax Credits' LIMIT 1];
		System.assertEquals(objOpp != null, true);
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for createFollowTask(), createPayrollOpportunity()
	 **/
	@isTest
	static void testCreateFollowTask() {
		List<Contact> list_Contacts = new List<Contact>{ [SELECT Id FROM Contact] };
		Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Lead objLead = [SELECT Id FROM Lead LIMIT 1];
		LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
		List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
		objFieldSetProperties.strFieldValue = 'Test Notes';
		objFieldSetProperties.strFieldLabel = '401k Notes';
		objFieldSetProperties.strFieldType = 'Long Text Area';
		objFieldSetProperties.blnFieldRequired = false;
		list_FieldSetProperties.add(objFieldSetProperties);
		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = 'Account';
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strDisposition = 'Test strDisposition';
		objComponentParameters.strNotes = 'Test strNotes';
		objComponentParameters.blnInboundCall = true;
		objComponentParameters.blnOutboundEmail = true;
		objComponentParameters.blnCreateProductUpsell = true;
		objComponentParameters.list_ProductUpsellValues = list_FieldSetProperties;
		objComponentParameters.list_ObjectDetailValues = list_FieldSetProperties;
		objComponentParameters.blnDoNotCall = true;
		objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
		objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
		objComponentParameters.blnCreatePayrollOpportunity = true;
		objComponentParameters.strPayrollOpportunityName = 'Test strPayrollOpportunityName';
		objComponentParameters.strPayrollOpportunityStage = 'Open';
		objComponentParameters.strPayrollOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.blnCreateHIOpportunity = true;
		objComponentParameters.strHIOpportunityType = 'HI Benefits New Plan';
		objComponentParameters.strHIOpportunityStage = 'Open';
		objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.strHIOpportunityState = '';
		objComponentParameters.strHIOpportunityEmployees = '100';
		objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
		objComponentParameters.strPhoneNumber = '1234567890';
		objComponentParameters.blnHIOpportunityLiveTransfer = true;

		Test.startTest();
		LogSmartCallingControllerLEX.createFollowTask(objComponentParameters);
		LogSmartCallingControllerLEX.createPayrollOpportunity(objComponentParameters, objAccount);
		objComponentParameters.strObjectName = 'Opportunity';
		objComponentParameters.strRecordId = objOpportunity.Id;
		LogSmartCallingControllerLEX.createFollowTask(objComponentParameters);
		objComponentParameters.strObjectName = 'Lead';
		objComponentParameters.strRecordId = objLead.Id;
		LogSmartCallingControllerLEX.createFollowTask(objComponentParameters);
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for closePreviousOpenTasks()
	 **/
	@isTest
	static void testClosePreviousOpenTasks() {
		List<Contact> list_Contacts = new List<Contact>{ [SELECT Id FROM Contact] };
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Company Opp' LIMIT 1];
		Lead objLead = [SELECT Id FROM Lead LIMIT 1];
		Task objAccountTask = [SELECT Id FROM Task WHERE WhatId = :objAccount.Id LIMIT 1];
		Task objOpportunityTask = [SELECT Id FROM Task WHERE WhatId = :objOpportunity.Id LIMIT 1];
		LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
		List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
		objFieldSetProperties.strFieldApiName = 'X401k_Notes__c';
		objFieldSetProperties.strFieldLabel = '401k Notes';
		objFieldSetProperties.strFieldType = 'Long Text Area';
		objFieldSetProperties.blnFieldRequired = false;
		objFieldSetProperties.strFieldValue = 'Test Name';
		list_FieldSetProperties.add(objFieldSetProperties);
		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = 'Account';
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strDisposition = 'Test strDisposition';
		objComponentParameters.strNotes = 'Test strNotes';
		objComponentParameters.blnInboundCall = true;
		objComponentParameters.blnOutboundEmail = true;
		objComponentParameters.blnCreateProductUpsell = true;
		objComponentParameters.list_ProductUpsellValues = list_FieldSetProperties;
		objComponentParameters.list_ObjectDetailValues = list_FieldSetProperties;
		objComponentParameters.blnDoNotCall = true;
		objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
		objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
		objComponentParameters.blnCreatePayrollOpportunity = true;
		objComponentParameters.strPayrollOpportunityName = 'Test strPayrollOpportunityName';
		objComponentParameters.strPayrollOpportunityStage = 'Open';
		objComponentParameters.strPayrollOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.blnCreateHIOpportunity = true;
		objComponentParameters.strHIOpportunityType = 'HI Benefits New Plan';
		objComponentParameters.strHIOpportunityStage = 'Open';
		objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.strHIOpportunityState = '';
		objComponentParameters.strHIOpportunityEmployees = '100';
		objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
		objComponentParameters.strPhoneNumber = '1234567890';
		objComponentParameters.blnHIOpportunityLiveTransfer = true;

		Test.startTest();
		LogSmartCallingControllerLEX.closePreviousOpenTasks(objComponentParameters, objAccountTask);
		objComponentParameters.strObjectName = 'Opportunity';
		objComponentParameters.strRecordId = objOpportunity.Id;
		LogSmartCallingControllerLEX.closePreviousOpenTasks(objComponentParameters, objOpportunityTask);
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for createProductUpsell()
	 **/
	@isTest
	static void testCreateProductUpsell() {
		Test.setMock(HttpCalloutMock.class, new GenerateSuccessCalloutMock());
		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		List<Contact> list_Contacts = new List<Contact>{ [SELECT Id FROM Contact] };
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
		User objMMPRUser = [SELECT Id, UserRole.Name, Profile.Name FROM User WHERE Email = 'mmpruser@testorg.com' LIMIT 1];
		LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
		List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
		objFieldSetProperties.strFieldApiName = 'X401k_Notes__c';
		objFieldSetProperties.strFieldValue = 'Test Name';
		objFieldSetProperties.strFieldLabel = '401k Notes';
		objFieldSetProperties.strFieldType = 'Long Text Area';
		objFieldSetProperties.blnFieldRequired = false;
		list_FieldSetProperties.add(objFieldSetProperties);

		objFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
		objFieldSetProperties.strFieldApiName = 'Type__c';
		objFieldSetProperties.strFieldValue = '401k;529;Ardius;Worker';
		objFieldSetProperties.strFieldLabel = 'Type';
		objFieldSetProperties.strFieldType = 'MULTIPICKLIST';
		objFieldSetProperties.blnFieldRequired = false;
		list_FieldSetProperties.add(objFieldSetProperties);

		objFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
		objFieldSetProperties.strFieldApiName = 'X401K_Interest_Type__c';
		objFieldSetProperties.strFieldValue = 'Guideline;Human Interest;Betterment;Vestwell';
		objFieldSetProperties.strFieldLabel = '401K Interest Type';
		objFieldSetProperties.strFieldType = 'PICKLIST';
		objFieldSetProperties.blnFieldRequired = false;
		list_FieldSetProperties.add(objFieldSetProperties);

		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = 'Account';
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strDisposition = 'Test strDisposition';
		objComponentParameters.strNotes = 'Test strNotes';
		objComponentParameters.blnInboundCall = true;
		objComponentParameters.blnOutboundEmail = true;
		objComponentParameters.blnCreateProductUpsell = true;
		objComponentParameters.list_ProductUpsellValues = list_FieldSetProperties;
		objComponentParameters.list_ObjectDetailValues = list_FieldSetProperties;
		objComponentParameters.blnDoNotCall = true;
		objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
		objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
		objComponentParameters.blnCreatePayrollOpportunity = true;
		objComponentParameters.strPayrollOpportunityName = 'Test strPayrollOpportunityName';
		objComponentParameters.strPayrollOpportunityStage = 'Open';
		objComponentParameters.strPayrollOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.blnCreateHIOpportunity = true;
		objComponentParameters.strHIOpportunityType = 'Test strHIOpportunityType';
		objComponentParameters.strHIOpportunityStage = 'Open';
		objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.strHIOpportunityState = 'Test strHIOpportunityState';
		objComponentParameters.strHIOpportunityEmployees = '100';
		objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
		objComponentParameters.strPhoneNumber = '1234567890';
		objComponentParameters.blnHIOpportunityLiveTransfer = true;
		Test.startTest();
		LogSmartCallingControllerLEX.createProductUpsell(objComponentParameters);
		objComponentParameters.strWhoId = '';
		LogSmartCallingControllerLEX.createProductUpsell(objComponentParameters);
		//with Object type as Opportunity
		objComponentParameters.strObjectName = 'Opportunity';
		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strRecordId = objOpportunity.Id;
		LogSmartCallingControllerLEX.createProductUpsell(objComponentParameters);
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for saveRecords() when object name is Account
	 **/
	@isTest
	static void testSaveRecordsForAccount() {
		UserRole objUserRole = new UserRole(Name = 'Partner');
		insert objUserRole;
		User objCXUser = [SELECT Id, Profile.Name, UserRole.Name, Email FROM User WHERE Email = 'benefitsuser@testorg.com' LIMIT 1];
		objCXUser.UserRoleId = objUserRole.Id;
		// update objCXUser;
		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		List<Contact> list_Contacts = [SELECT Id, Phone FROM Contact];
		String strRandomid = LogSmartCallingControllerLEX.getRandomId();
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties('Account', objAccount.id);
		String strMetadata = objResponseWrapper.strMetadataProperties;
		AllSmartCalling__mdt objMetadata = (AllSmartCalling__mdt) JSON.deserialize(strMetadata, AllSmartCalling__mdt.class);
		objMetadata.Inbound_Call__c = true;
		strMetadata = JSON.serialize(objMetadata);
		Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Lead objLead = [SELECT Id FROM Lead LIMIT 1];
		LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties1 = new LogSmartCallingControllerLEX.FieldSetProperties();
		LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties2 = new LogSmartCallingControllerLEX.FieldSetProperties();
		List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties1 = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
		List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties2 = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
		objFieldSetProperties1.strFieldApiName = 'X401k_Notes__c';
		objFieldSetProperties1.strFieldValue = 'Test Notes';
		objFieldSetProperties1.strFieldLabel = '401k Notes';
		objFieldSetProperties1.strFieldType = 'Long Text Area';
		objFieldSetProperties1.blnFieldRequired = false;
		list_FieldSetProperties1.add(objFieldSetProperties1);
		objFieldSetProperties2.strFieldApiName = 'Name';
		objFieldSetProperties2.strFieldValue = 'Test Name';
		objFieldSetProperties2.strFieldLabel = 'Account Name';
		objFieldSetProperties2.strFieldType = 'Name';
		objFieldSetProperties2.blnFieldRequired = false;
		list_FieldSetProperties2.add(objFieldSetProperties2);

		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = 'Account';
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strDisposition = 'Test strDisposition';
		objComponentParameters.strNotes = 'Test strNotes';
		objComponentParameters.blnInboundCall = true;
		objComponentParameters.blnOutboundEmail = true;
		objComponentParameters.blnCreateProductUpsell = true;
		objComponentParameters.list_ProductUpsellValues = list_FieldSetProperties1;
		objComponentParameters.list_ObjectDetailValues = list_FieldSetProperties2;
		objComponentParameters.blnDoNotCall = true;
		objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
		objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
		objComponentParameters.blnCreatePayrollOpportunity = true;
		objComponentParameters.strPayrollOpportunityName = 'Test strPayrollOpportunityName';
		objComponentParameters.strPayrollOpportunityStage = 'Open';
		objComponentParameters.strPayrollOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.blnCreateHIOpportunity = true;
		objComponentParameters.strHIOpportunityType = 'HI Benefits New Plan';
		objComponentParameters.strHIOpportunityStage = 'Open';
		objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
		objComponentParameters.strHIOpportunityState = 'Arizona';
		objComponentParameters.strHIOpportunityEmployees = '100';
		objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
		objComponentParameters.strPhoneNumber = '1234567890';
		objComponentParameters.blnHIOpportunityLiveTransfer = true;
		objComponentParameters.blnTaskScheduledCall = true;
		objComponentParameters.blnInAppScheduler = true;
		objComponentParameters.blnOpportunityDemo = false;

		String strDataInJson = JSON.serialize(objComponentParameters);
		String strNiceInteraction = '';
		Test.startTest();
		try {
			System.runAs(objCXUser) {
				NICE_Interaction__c objNICEInteraction = new TestDataFactory.NICEInteractionBuilder()
					.setDNIS(new normalizationUtil().normalisePhoneField(list_Contacts[0].Phone))
					.setEmailId(objCXUser.Email)
					.setContactID(list_Contacts[0].Id)
					.build();
				insert objNICEInteraction;

				strNiceInteraction = JSON.serialize(objNICEInteraction);

				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, true, strNiceInteraction);

				objComponentParameters.strObjectName = 'Opportunity';
				objComponentParameters.strRecordId = objOpportunity.Id;
				strDataInJson = JSON.serialize(objComponentParameters);
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, true, strNiceInteraction);

				objComponentParameters.strObjectName = 'Lead';
				objComponentParameters.strRecordId = objLead.Id;
				strDataInJson = JSON.serialize(objComponentParameters);
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, strNiceInteraction);
			}
		} catch (Exception objException) {
			System.debug('Exception Occured-->' + objException);
		}
		Test.stopTest();
	}

	@isTest
	static void testSaveRecordsForAccountBenefitsUser() {
		Test.startTest();
		User objBenefitsUser = [SELECT Id, Profile.Name, UserRole.Name, Email FROM User WHERE Email = 'benefitsuser@testorg.com' LIMIT 1];

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		String strRandomid = LogSmartCallingControllerLEX.getRandomId();
		List<Contact> list_Contacts = [SELECT Id, Phone FROM Contact];
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];
		Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties('Account', objAccount.id);
		String strMetadata = objResponseWrapper.strMetadataProperties;
		AllSmartCalling__mdt objMetadata = (AllSmartCalling__mdt) JSON.deserialize(strMetadata, AllSmartCalling__mdt.class);
		strMetadata = JSON.serialize(objMetadata);

		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = 'Account';
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strDisposition = 'Test strDisposition';
		objComponentParameters.strNotes = 'Test strNotes';

		System.runAs(objBenefitsUser) {
			String strDataInJson = JSON.serialize(objComponentParameters);
			LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
			Account objAccountToAssert = [SELECT Id, Benefits_Notes__c, SDR_Notes__c FROM Account WHERE Id = :objAccount.Id];
			Assert.areEqual('Test strNotes', objAccountToAssert.Benefits_Notes__c, 'Benefits Notes not updated');
			Assert.isTrue(String.isBlank(objAccountToAssert.SDR_Notes__c), 'SDR Notes updated');
		}

		Test.stopTest();

		checkForExceptions(false);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test method for saveRecords() when object name is Account
	 **/
	@isTest
	static void testSaveRecordsForAccountAsPartner() {
		Test.setMock(HttpCalloutMock.class, new GenerateSuccessCalloutMock());
		User objPartnerUser = [SELECT Id, Profile.Name, UserRole.Name, Email FROM User WHERE Email = 'partneruser@testorg.com' LIMIT 1];
		Account objAccount;
		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters;

		System.runAs(objPartnerUser) {
			objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

			objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];

			Contact objContact = [SELECT Id, AccountId, Phone FROM Contact WHERE Email = 'testUser@yopmail.com' LIMIT 1];

			LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objAccount.Id);
			String strMetadata = objResponseWrapper.strMetadataProperties;

			objComponentParameters.strWhoId = objContact.Id;
			objComponentParameters.strPhoneNumber = objContact.Phone;
			objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT;
			objComponentParameters.strRecordId = objAccount.Id;

			objComponentParameters.strDisposition = 'test' + LogSmartCallingUtil.TASK_DISPOSITION_CONNECT;
			objComponentParameters.strTaskType = LogSmartCallingUtil.TASK_TYPE_OUTBOUND_CALL;
			objComponentParameters.strPartnerSalesTaskType = LogSmartCallingUtil.TASK_PARTNER_SALES_TYPE_ADMIN;
			objComponentParameters.strTaskSubject = LogSmartCallingUtil.TASK_DISPOSITION_CONNECT;
			objComponentParameters.strNotes = 'Test strNotes';

			// PRODUCT UPSELL:
			objComponentParameters.blnCreateProductUpsell = true;

			LogSmartCallingControllerLEX.FieldSetProperties objX401NotesField = new LogSmartCallingControllerLEX.FieldSetProperties();
			objX401NotesField.strFieldApiName = LogSmartCallingUtil.FIELD_API_401K_NOTES;
			objX401NotesField.strFieldValue = 'Test Notes';

			LogSmartCallingControllerLEX.FieldSetProperties objX529NotesField = new LogSmartCallingControllerLEX.FieldSetProperties();
			objX529NotesField.strFieldApiName = LogSmartCallingUtil.FIELD_API_529_NOTES;
			objX529NotesField.strFieldValue = 'Test Notes';

			LogSmartCallingControllerLEX.FieldSetProperties objPointOfContactField = new LogSmartCallingControllerLEX.FieldSetProperties();
			objPointOfContactField.strFieldApiName = LogSmartCallingUtil.FIELD_API_POINT_OF_CONTACT;
			objPointOfContactField.strFieldValue = objContact.Id;

			LogSmartCallingControllerLEX.FieldSetProperties objTypeFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
			objTypeFieldSetProperties.strFieldApiName = 'Type__c';
			objTypeFieldSetProperties.strFieldValue = '401k;529;Ardius;Worker';
			objTypeFieldSetProperties.strFieldLabel = 'Type';
			objTypeFieldSetProperties.strFieldType = 'MULTIPICKLIST';
			objTypeFieldSetProperties.blnFieldRequired = false;

			LogSmartCallingControllerLEX.FieldSetProperties obj401TypeFieldSetProperties = new LogSmartCallingControllerLEX.FieldSetProperties();
			obj401TypeFieldSetProperties.strFieldApiName = 'X401K_Interest_Type__c';
			obj401TypeFieldSetProperties.strFieldValue = 'Guideline;Human Interest;Betterment;Vestwell';
			obj401TypeFieldSetProperties.strFieldLabel = '401K Interest Type';
			obj401TypeFieldSetProperties.strFieldType = 'PICKLIST';
			obj401TypeFieldSetProperties.blnFieldRequired = false;

			objComponentParameters.list_ProductUpsellValues = new List<LogSmartCallingControllerLEX.FieldSetProperties>{
				objX401NotesField,
				objX529NotesField,
				objPointOfContactField,
				obj401TypeFieldSetProperties,
				objTypeFieldSetProperties
			};

			// CURRENT RECORD:
			LogSmartCallingControllerLEX.FieldSetProperties objAccNameField = new LogSmartCallingControllerLEX.FieldSetProperties();
			objAccNameField.strFieldApiName = 'Name';
			objAccNameField.strFieldValue = 'Test Name';

			objComponentParameters.list_ObjectDetailValues = new List<LogSmartCallingControllerLEX.FieldSetProperties>{ objAccNameField };

			objComponentParameters.blnDoNotCall = true;

			// HI OPPORTUNITY
			objComponentParameters.blnCreateHIOpportunity = true;
			objComponentParameters.strHIOpportunityType = 'HI Benefits New Plan';
			objComponentParameters.strHIOpportunityStage = 'Open';
			objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
			objComponentParameters.strHIOpportunityState = 'Arizona';
			objComponentParameters.strHIOpportunityEmployees = '11';
			objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
			objComponentParameters.blnHIOpportunityLiveTransfer = true;

			String strDataInJson = JSON.serialize(objComponentParameters);
			Test.startTest();
			try {
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
			} catch (Exception objException) {
				System.debug('Exception Occured: ' + objException);
			}
		}
		Test.stopTest();

		Opportunity objHIOpportunityAssert = [
			SELECT Id, HI_Opportunity_Assignment_State__c, Notes__c
			FROM Opportunity
			WHERE RecordTypeId = :LogSmartCallingUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID AND AccountId = :objAccount.Id AND NumberOfEmployees__c = 11
			LIMIT 1
		];
		System.assertEquals(objComponentParameters.strHIOpportunityState, objHIOpportunityAssert.HI_Opportunity_Assignment_State__c);
		System.assertEquals(objComponentParameters.strHIOpportunityNotes, objHIOpportunityAssert.Notes__c);

		Task objTaskAssert = [SELECT Id, WhatId FROM Task WHERE CallDisposition = :objComponentParameters.strDisposition];
		System.assertEquals(objAccount.Id, objTaskAssert.WhatId);

		Sales_Call_Tracking__c objSalClTrackAssert = [SELECT Id, Task__c FROM Sales_Call_Tracking__c WHERE Account__c = :objAccount.Id];
		System.assertEquals(objTaskAssert.Id, objSalClTrackAssert.Task__c);

		Account objAccountToAssert = [SELECT Id, Benefits_Notes__c, SDR_Notes__c FROM Account WHERE Id = :objAccount.Id];
		Assert.areEqual('Test strNotes', objAccountToAssert.SDR_Notes__c, 'SDR Notes not updated');
		Assert.isTrue(String.isBlank(objAccountToAssert.Benefits_Notes__c), 'Benefits Notes updated');

		checkForExceptions(false);
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for saveRecords() when object name is Opportunity
	 **/
	@isTest
	static void testSaveRecordsForOpportunity() {
		Test.startTest();
		User objBenefitsUser = [SELECT Id, Profile.Name, UserRole.Name, Email FROM User WHERE Email = 'benefitsuser@testorg.com' LIMIT 1];

		System.runAs(objBenefitsUser) {
			LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
			List<Contact> list_Contacts = [SELECT Id FROM Contact];
			String strRandomid = LogSmartCallingControllerLEX.getRandomId();
			Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE OwnerId = :objBenefitsUser.Id AND RecordType.Name = 'Benefits New Plan' LIMIT 1];
			LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties('Opportunity', objOpportunity.id);
			String strMetadata = objResponseWrapper.strMetadataProperties;
			AllSmartCalling__mdt objMetadata = (AllSmartCalling__mdt) JSON.deserialize(strMetadata, AllSmartCalling__mdt.class);
			objMetadata.Inbound_Call__c = true;
			strMetadata = JSON.serialize(objMetadata);
			LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties1 = new LogSmartCallingControllerLEX.FieldSetProperties();
			LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties2 = new LogSmartCallingControllerLEX.FieldSetProperties();
			List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties1 = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
			objFieldSetProperties1.strFieldApiName = 'X401k_Notes__c';
			objFieldSetProperties1.strFieldValue = 'Test Notes';
			objFieldSetProperties1.strFieldLabel = '401k Notes';
			objFieldSetProperties1.strFieldType = 'Long Text Area';
			objFieldSetProperties1.blnFieldRequired = false;
			list_FieldSetProperties1.add(objFieldSetProperties1);

			List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties2 = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
			objFieldSetProperties2.strFieldApiName = 'Name';
			objFieldSetProperties2.strFieldValue = 'Test Name';
			objFieldSetProperties2.strFieldLabel = 'Account Name';
			objFieldSetProperties2.strFieldType = 'Name';
			objFieldSetProperties2.blnFieldRequired = true;
			list_FieldSetProperties2.add(objFieldSetProperties2);

			LogSmartCallingControllerLEX.FieldSetProperties objBenefitNotesField = new LogSmartCallingControllerLEX.FieldSetProperties();
			objBenefitNotesField.strFieldApiName = LogSmartCallingUtil.FIELD_API_BENEFIT_NOTES;
			objBenefitNotesField.strFieldValue = 'Test Name';
			list_FieldSetProperties2.add(objBenefitNotesField);

			objComponentParameters.strWhoId = list_Contacts[0].Id;
			objComponentParameters.strObjectName = 'Opportunity';
			objComponentParameters.strRecordId = objOpportunity.Id;
			objComponentParameters.strDisposition = 'Test strDisposition';
			objComponentParameters.strNotes = 'Test strNotes';
			objComponentParameters.blnInboundCall = true;
			objComponentParameters.blnOutboundEmail = true;
			objComponentParameters.blnCreateProductUpsell = true;
			objComponentParameters.list_ProductUpsellValues = list_FieldSetProperties1;
			objComponentParameters.list_ObjectDetailValues = list_FieldSetProperties2;
			objComponentParameters.blnDoNotCall = true;
			objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
			objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
			objComponentParameters.blnCreatePayrollOpportunity = true;
			objComponentParameters.strPayrollOpportunityName = 'Test strPayrollOpportunityName';
			objComponentParameters.strPayrollOpportunityStage = 'Open';
			objComponentParameters.strPayrollOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
			objComponentParameters.blnCreateHIOpportunity = true;
			objComponentParameters.strHIOpportunityType = 'HI Benefits New Plan';
			objComponentParameters.strHIOpportunityStage = 'Open';
			objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
			objComponentParameters.strHIOpportunityState = 'Arizona';
			objComponentParameters.strHIOpportunityEmployees = '100';
			objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
			objComponentParameters.strPhoneNumber = '1234567890';
			objComponentParameters.blnHIOpportunityLiveTransfer = true;
			objComponentParameters.blnOpportunityDemo = true;
			objComponentParameters.blnTaskScheduledCall = true;
			objComponentParameters.blnInAppScheduler = true;
			objComponentParameters.blnOpportunityPPA = false;

			String strDataInJson = JSON.serialize(objComponentParameters);
			try {
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
				objComponentParameters.strObjectName = 'Benefit Order';
				strDataInJson = JSON.serialize(objComponentParameters);
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
			} catch (Exception objException) {
				System.debug('Exception Occured-->' + objException);
			}
		}
		Test.stopTest();

		checkForExceptions(false);
	}

	/**
	 * @Author      : Deepesh Rao
	 * @Description : Test method for saveRecords() when object name is Opportunity for CX user
	 **/
	@isTest
	static void testSaveRecordsForOpportunityAsCXUser() {
		Test.startTest();
		User objCXUser = [SELECT Id, Profile.Name, UserRole.Name, Email FROM User WHERE Email = 'cxuser@testorg.com' LIMIT 1];

		System.runAs(objCXUser) {
			LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
			String strRandomid = LogSmartCallingControllerLEX.getRandomId();
			Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE OwnerId = :objCXUser.Id AND RecordType.Name = 'Customer Success' LIMIT 1];
			LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties('Opportunity', objOpportunity.id);
			String strMetadata = objResponseWrapper.strMetadataProperties;
			AllSmartCalling__mdt objMetadata = (AllSmartCalling__mdt) JSON.deserialize(strMetadata, AllSmartCalling__mdt.class);
			strMetadata = JSON.serialize(objMetadata);
			LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties1 = new LogSmartCallingControllerLEX.FieldSetProperties();
			LogSmartCallingControllerLEX.FieldSetProperties objFieldSetProperties2 = new LogSmartCallingControllerLEX.FieldSetProperties();
			List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties1 = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
			objFieldSetProperties1.strFieldApiName = 'X401k_Notes__c';
			objFieldSetProperties1.strFieldValue = 'Test Notes';
			objFieldSetProperties1.strFieldLabel = '401k Notes';
			objFieldSetProperties1.strFieldType = 'Long Text Area';
			objFieldSetProperties1.blnFieldRequired = false;
			list_FieldSetProperties1.add(objFieldSetProperties1);

			List<LogSmartCallingControllerLEX.FieldSetProperties> list_FieldSetProperties2 = new List<LogSmartCallingControllerLEX.FieldSetProperties>();
			objFieldSetProperties2.strFieldApiName = 'Name';
			objFieldSetProperties2.strFieldValue = 'Test Name';
			objFieldSetProperties2.strFieldLabel = 'Account Name';
			objFieldSetProperties2.strFieldType = 'Name';
			objFieldSetProperties2.blnFieldRequired = true;
			list_FieldSetProperties2.add(objFieldSetProperties2);

			LogSmartCallingControllerLEX.FieldSetProperties objBenefitNotesField = new LogSmartCallingControllerLEX.FieldSetProperties();
			objBenefitNotesField.strFieldApiName = LogSmartCallingUtil.FIELD_API_BENEFIT_NOTES;
			objBenefitNotesField.strFieldValue = 'Test Name';
			list_FieldSetProperties2.add(objBenefitNotesField);

			objComponentParameters.strObjectName = 'Opportunity';
			objComponentParameters.strRecordId = objOpportunity.Id;
			objComponentParameters.strDisposition = 'Test strDisposition';
			objComponentParameters.strNotes = 'Test strNotes';
			objComponentParameters.blnInboundCall = true;
			objComponentParameters.blnOutboundEmail = true;
			objComponentParameters.blnCreateProductUpsell = true;
			objComponentParameters.list_ProductUpsellValues = list_FieldSetProperties1;
			objComponentParameters.list_ObjectDetailValues = list_FieldSetProperties2;
			objComponentParameters.blnDoNotCall = true;
			objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
			objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
			objComponentParameters.blnCreatePayrollOpportunity = true;
			objComponentParameters.strPayrollOpportunityName = 'Test strPayrollOpportunityName';
			objComponentParameters.strPayrollOpportunityStage = 'Open';
			objComponentParameters.strPayrollOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
			objComponentParameters.blnCreateHIOpportunity = true;
			objComponentParameters.strHIOpportunityType = 'HI Benefits New Plan';
			objComponentParameters.strHIOpportunityStage = 'Open';
			objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
			objComponentParameters.strHIOpportunityState = 'Arizona';
			objComponentParameters.strHIOpportunityEmployees = '100';
			objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
			objComponentParameters.strPhoneNumber = '1234567890';
			objComponentParameters.blnHIOpportunityLiveTransfer = true;
			objComponentParameters.blnOpportunityDemo = true;
			objComponentParameters.blnTaskScheduledCall = true;
			objComponentParameters.blnInAppScheduler = true;
			objComponentParameters.blnOpportunityPPA = false;
			objComponentParameters.blnCreateArdiusOpportunity = true;
			objComponentParameters.strArdiusOpportunityStage = 'General Prospects';
			objComponentParameters.strArdiusOpportunityCloseDate = String.valueOf(Date.today().addDays(15));

			String strDataInJson = JSON.serialize(objComponentParameters);
			try {
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
			} catch (Exception objException) {
				System.debug('Exception Occured-->' + objException);
			}
		}
		Test.stopTest();

		checkForExceptions(false);
	}

	/**
	 * @Author      : Deepesh Rao
	 * @Description : Test method for saveRecords() when object name is Ticket(SIFA-250)
	 **/
	@isTest
	static void testSaveRecordsForTicket() {
		Test.startTest();
		User objArdiusUser = [SELECT Id, Profile.Name, UserRole.Name, Email FROM User WHERE Email = 'ardiususer@testorg.com' LIMIT 1];

		System.runAs(objArdiusUser) {
			LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
			List<Contact> list_Contacts = [SELECT Id FROM Contact];
			String strRandomid = LogSmartCallingControllerLEX.getRandomId();
			Ticket__c objTicket = [SELECT Id FROM Ticket__c WHERE OwnerId = :objArdiusUser.Id AND RecordType.Name = 'Ardius' LIMIT 1];
			LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties('Ticket__c', objTicket.id);
			String strMetadata = objResponseWrapper.strMetadataProperties;
			AllSmartCalling__mdt objMetadata = (AllSmartCalling__mdt) JSON.deserialize(strMetadata, AllSmartCalling__mdt.class);
			objMetadata.Inbound_Call__c = true;
			strMetadata = JSON.serialize(objMetadata);

			objComponentParameters.strWhoId = list_Contacts[0].Id;
			objComponentParameters.strObjectName = 'Ticket__c';
			objComponentParameters.strRecordId = objTicket.Id;
			objComponentParameters.strDisposition = 'Test strDisposition';
			objComponentParameters.strNotes = 'Test strNotes';
			objComponentParameters.blnInboundCall = true;
			objComponentParameters.blnOutboundEmail = true;
			objComponentParameters.blnCreateProductUpsell = true;
			objComponentParameters.blnDoNotCall = true;
			objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
			objComponentParameters.strFollowUpSubject = 'Test strFollowUpSubject';
			objComponentParameters.blnCreatePayrollOpportunity = false;
			objComponentParameters.strPayrollOpportunityName = 'Test strPayrollOpportunityName';
			objComponentParameters.strPayrollOpportunityStage = 'Open';
			objComponentParameters.strPayrollOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
			objComponentParameters.blnCreateHIOpportunity = false;
			objComponentParameters.strHIOpportunityType = 'HI Benefits New Plan';
			objComponentParameters.strHIOpportunityStage = 'Open';
			objComponentParameters.strHIOpportunityCloseDate = String.valueOf(Date.today().addDays(15));
			objComponentParameters.strHIOpportunityState = 'Arizona';
			objComponentParameters.strHIOpportunityEmployees = '100';
			objComponentParameters.strHIOpportunityNotes = 'Test strHIOpportunityNotes';
			objComponentParameters.strPhoneNumber = '1234567890';
			objComponentParameters.blnHIOpportunityLiveTransfer = false;
			objComponentParameters.blnOpportunityDemo = false;
			objComponentParameters.blnTaskScheduledCall = false;
			objComponentParameters.blnInAppScheduler = false;
			objComponentParameters.blnOpportunityPPA = false;

			String strDataInJson = JSON.serialize(objComponentParameters);
			try {
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
			} catch (Exception objException) {
				System.debug('Exception Occured-->' + objException);
			}
		}
		Test.stopTest();

		checkForExceptions(false);
	}

	/* @Author      : Veeresh Kumar
	 * @Description : Test method for saveRecords() when object name is Opportunity
	 **/
	@isTest
	static void testSaveRecordsForOpportunityAsAdmin() {
		Test.startTest();

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account WHERE Name = 'Test Co.'];

		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE ZP_Company_Id__c = :objAccount.ZP_Company_Id__c];

		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY, objOpportunity.Id);
		String strMetadata = objResponseWrapper.strMetadataProperties;

		objComponentParameters.strWhoId = '';
		objComponentParameters.strPhoneNumber = '';
		objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY;
		objComponentParameters.strRecordId = objOpportunity.Id;
		objComponentParameters.strDisposition = 'Test Admin Disposition';
		objComponentParameters.strNotes = 'Test Admin Notes';

		objComponentParameters.blnInboundCall = true;
		objComponentParameters.blnOutboundEmail = true;
		objComponentParameters.blnDoNotCall = true;

		String strDataInJson = JSON.serialize(objComponentParameters);
		try {
			LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
		} catch (Exception objException) {
			System.debug('Exception Occured: ' + objException);
		}

		Test.stopTest();

		checkForExceptions(false);

		Task objTaskAssert = [SELECT Id, CallObject, Description FROM Task WHERE WhatId = :objOpportunity.Id AND CallDisposition = 'Test Admin Disposition'];
		System.assertEquals('Test Admin Notes', objTaskAssert.Description);
	}

	/* @Author      : Veeresh Kumar
	 * @Description : Test method for saveRecords() when object name is Opportunity
	 **/
	@isTest
	static void testSaveRecordsForResellerAccAsAdmin() {
		Test.startTest();

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

		Account objCompanyAccount = [SELECT Id, ZP_Company_Id__c FROM Account WHERE Name = 'Test Co.'];
		Account objResellerAccount = [SELECT Id, ZP_Company_Id__c FROM Account WHERE Name = 'test Res Account'];

		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE ZP_Company_Id__c = :objCompanyAccount.ZP_Company_Id__c];

		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objResellerAccount.Id);
		String strMetadata = objResponseWrapper.strMetadataProperties;

		objComponentParameters.strWhoId = '';
		objComponentParameters.strWhatId = objOpportunity.Id;
		objComponentParameters.strPhoneNumber = '';
		objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT;
		objComponentParameters.strRecordId = objResellerAccount.Id;
		objComponentParameters.strDisposition = 'Test Admin Disposition';
		objComponentParameters.strNotes = 'Test Admin Notes';

		objComponentParameters.blnInboundCall = true;
		objComponentParameters.blnOutboundEmail = true;
		objComponentParameters.blnDoNotCall = true;

		String strDataInJson = JSON.serialize(objComponentParameters);
		try {
			LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
		} catch (Exception objException) {
			System.debug('Exception Occured: ' + objException);
		}

		Test.stopTest();

		checkForExceptions(false);

		System.assert(!objResponseWrapper.map_CompanyAccounts.isEmpty());

		Task objTaskAssert = [SELECT Id, CallObject, Description FROM Task WHERE WhatId = :objOpportunity.Id AND CallDisposition = 'Test Admin Disposition'];
		System.assertEquals('Test Admin Notes', objTaskAssert.Description);
	}

	/* @Author      : Anurag Gautam
	 * @Description : Test method for Product interest feature
	 **/
	@isTest
	static void testSaveRecordsForProductInterest() {
		Test.startTest();

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account WHERE Name = 'Test Co.'];

		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE ZP_Company_Id__c = :objAccount.ZP_Company_Id__c];

		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objAccount.Id);
		String strMetadata = objResponseWrapper.strMetadataProperties;

		objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT;
		objComponentParameters.strRecordId = objAccount.Id;

		objComponentParameters.blnAddProductInterest = true;
		objComponentParameters.strProductInterestCountries = 'CA,IN';
		objComponentParameters.productInterestAccountId = objAccount.Id;

		String strDataInJson = JSON.serialize(objComponentParameters);
		try {
			LogSmartCallingControllerLEX.blnTestException = true;
			LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
		} catch (Exception objException) {
			System.debug('Exception Occured: ' + objException);
		}

		Account objAccountForAssert = [SELECT Id, Product_Interest__c, Product_Interest_Countries__c FROM Account WHERE Name = 'Test Co.'];
		System.assertEquals(true, objAccountForAssert.Product_Interest__c.contains('international_payroll_logacall'), 'Product Interest is log a call.');
		System.assertEquals(true, objAccountForAssert.Product_Interest_Countries__c.contains('CA'), 'Product Interest Country is Canada.');
		Test.stopTest();
	}

	/*
	 * @Description : Test method for Error ICP Product interest
	 **/

	@isTest
	static void testSaveRecordsErrorForICPProductInterest() {
		Test.startTest();
		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account WHERE Name = 'Test Co.'];
		// set product interest to ICP
		objAccount.Product_Interest__c = 'international_contractor_payment_onboarding';
		update objAccount;
		objComponentParameters.productInterestAccountId = objAccount.Id;
		objComponentParameters.blnAddProductInterest = true;
		objComponentParameters.strProductInterest = LogSmartCallingUtil.INTERNATIONAL_CONTRACTOR_PAYMENT_LOGACALL;
		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objAccount.Id);
		String strMetadata = objResponseWrapper.strMetadataProperties;
		String strDataInJson = JSON.serialize(objComponentParameters);
		String result = LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, true, '');
		System.assertEquals(LogSmartCallingUtil.CROSS_SELL_OPPORTUNITY_FOR_ICP_ALREADY_EXISTS, result, 'The error message should indicate that a cross-sell opportunity already exists.');
		Test.stopTest();
	}

	/*
	 * @Description : Test method for Error IP Product interest
	 **/
	@isTest
	static void testSaveRecordsErrorForIPProductInterest() {
		Test.startTest();
		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account WHERE Name = 'Test Co.'];
		// create Cross-Sell and Upsell opportunity
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.EMPLOYER_OF_RECORD)
			.setType('Upsell')
			.setStage(OpportunityUtil.QUALIFIED_STAGE)
			.build();
		insert objOpportunity;
		objComponentParameters.productInterestAccountId = objAccount.Id;
		objComponentParameters.blnAddProductInterest = true;
		objComponentParameters.strProductInterest = LogSmartCallingUtil.INTERNATIONAL_PAYROLL_LOG_A_CALL;
		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objAccount.Id);
		String strMetadata = objResponseWrapper.strMetadataProperties;
		String strDataInJson = JSON.serialize(objComponentParameters);
		String result = LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, true, '');
		System.assertNotEquals(LogSmartCallingUtil.UPSELL_OPPORTUNITY_FOR_EMPLOYER_ALREADY_EXISTS, result, 'The error message should indicate that a up-sell opportunity already exists.');
		Test.stopTest();
	}

	/* @Author      : Anurag Gautam
	 * @Description : Test method for Gusto global lead pass
	 **/
	@isTest
	static void testProductUpsellForProductInterest() {
		Test.startTest();

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account WHERE Name = 'Test Co.'];

		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE ZP_Company_Id__c = :objAccount.ZP_Company_Id__c];
		List<Contact> list_Contacts = [SELECT Id FROM Contact];

		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objAccount.Id);
		String strMetadata = objResponseWrapper.strMetadataProperties;

		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT;
		objComponentParameters.strRecordId = objAccount.Id;

		objComponentParameters.blnAddProductInterest = true;
		objComponentParameters.strProductInterestCountries = 'AR,AO';
		objComponentParameters.productInterestAccountId = objAccount.Id;

		String strDataInJson = JSON.serialize(objComponentParameters);
		try {
			LogSmartCallingControllerLEX.blnTestException = true;
			LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
		} catch (Exception objException) {
			System.debug('Exception Occured: ' + objException);
		}

		/**Account objAccountForAssert = [SELECT Id, Product_Interest__c, Product_Interest_Countries__c FROM Account WHERE Name = 'Test Co.'];
		System.assertEquals(true, objAccountForAssert.Product_Interest__c.contains('international_payroll_logacall'), 'Product Interest is log a call.');

		Partnership_Interest__c objProductUpsellForAssert = [SELECT Id, Product_Interest__c FROM Partnership_Interest__c WHERE Contact__c = :list_Contacts[0].Id LIMIT 1];

		System.assertEquals(AccountUtil.EMPLOYER_OF_RECORD, objProductUpsellForAssert.Product_Interest__c, 'Product Interest is not a Employer of Record.');
		System.assertEquals(true, objAccountForAssert.Product_Interest_Countries__c.contains('AR'), 'Product Interest Country is Argentina.');**/
		Test.stopTest();
	}

	/**
	 * @Description : Test method for Gusto global send lead pass to Remote
	 **/
	@isTest
	static void testSendLeadPassToRemote() {
		Test.startTest();

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

		Account objAccount = [SELECT Id, ZP_Company_Id__c FROM Account WHERE Name = 'Test Co.'];

		Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE ZP_Company_Id__c = :objAccount.ZP_Company_Id__c];
		List<Contact> list_Contacts = [SELECT Id FROM Contact];

		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT, objAccount.Id);
		String strMetadata = objResponseWrapper.strMetadataProperties;

		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT;
		objComponentParameters.strRecordId = objAccount.Id;

		objComponentParameters.blnAddProductInterest = true;
		objComponentParameters.strProductInterestCountries = 'AR,AO';
		objComponentParameters.productInterestAccountId = objAccount.Id;

		String strDataInJson = JSON.serialize(objComponentParameters);
		try {
			LogSmartCallingControllerLEX.blnTestException = true;
			LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
		} catch (Exception objException) {
			System.debug('Exception Occured: ' + objException);
		}
		Test.stopTest();
		/**Account objAccountForAssert = [SELECT Id, Product_Interest__c, Product_Interest_Countries__c FROM Account WHERE Name = 'Test Co.'];
		System.assertEquals(true, objAccountForAssert.Product_Interest__c.contains('international_payroll_logacall'), 'Product Interest is log a call.');

		Partnership_Interest__c objProductUpsellForAssert = [SELECT Id, Product_Interest__c FROM Partnership_Interest__c WHERE Contact__c = :list_Contacts[0].Id LIMIT 1];

		System.assertEquals(AccountUtil.EMPLOYER_OF_RECORD, objProductUpsellForAssert.Product_Interest__c, 'Product Interest is not a Employer of Record.');
		System.assertEquals(true, objAccountForAssert.Product_Interest_Countries__c.contains('AR'), 'Product Interest Country is Argentina.');

		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapperLeadPass = LogSmartCallingControllerLEX.getLeadPassDetails(objAccount.Id);
		Assert.isTrue(objResponseWrapperLeadPass.list_CountriesSentToRemote.contains('AR'), 'Country sent to Remote but not fetched.');
		objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		objComponentParameters.strWhoId = list_Contacts[0].Id;
		objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_ACCOUNT;
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strLeadPassCountries = 'AR,AO';
		objComponentParameters.strLeadPassCountriesAdditional = 'BR,IN';
		objComponentParameters.productInterestAccountId = objAccount.Id;
		strDataInJson = JSON.serialize(objComponentParameters);
		try {
			LogSmartCallingControllerLEX.blnTestException = true;
			LogSmartCallingControllerLEX.saveLeadPass(strDataInJson);
		} catch (Exception objException) {
			System.debug('Exception Occured: ' + objException);
		}
		
		objAccountForAssert = [SELECT Id, Product_Interest__c, Product_Interest_Countries__c FROM Account WHERE Name = 'Test Co.'];
		List<Partnership_Interest__c> list_ProductUpsellsForAssert = [
			SELECT Id, Product_Interest__c, Product_Interest_Countries__c
			FROM Partnership_Interest__c
			WHERE Contact__c = :list_Contacts[0].Id
		];
		System.assertEquals(true, objAccountForAssert.Product_Interest_Countries__c.contains('BR'), 'Product Interest Country does not have Brazil.');
		System.assertEquals(2, list_ProductUpsellsForAssert.size(), 'Product upsell not created.');
		for (Partnership_Interest__c objProductUpsell : list_ProductUpsellsForAssert) {
			if (objProductUpsell.Product_Interest_Countries__c.split(';').size() > 2) {
				System.assertEquals(true, objProductUpsell.Product_Interest_Countries__c.contains('BR'), 'Product Interest Country does not have Brazil.');
			}
		}**/
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test method for saveRecords() when object name is Opportunity
	 **/
	@isTest
	static void testSaveRecordsForOpportunityAsMDR() {
		Test.startTest();
		User objMDRUser = [SELECT Id, Profile.Name, UserRole.Name, Email FROM User WHERE Email = 'mdruser@testorg.com' LIMIT 1];
		Opportunity objOpportunity;

		System.runAs(objMDRUser) {
			LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

			objOpportunity = [SELECT Id FROM Opportunity WHERE OwnerId = :objMDRUser.Id AND RecordType.Name = 'Company Opportunity' LIMIT 1];

			LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY, objOpportunity.Id);
			String strMetadata = objResponseWrapper.strMetadataProperties;

			objComponentParameters.strWhoId = '';
			objComponentParameters.strPhoneNumber = '';
			objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_OPPORTUNITY;
			objComponentParameters.strRecordId = objOpportunity.Id;
			objComponentParameters.strDisposition = 'Test MDR Disposition';
			objComponentParameters.strNotes = 'Test MDR OPP strNotes';

			objComponentParameters.blnInboundCall = true;
			objComponentParameters.blnOutboundEmail = true;

			LogSmartCallingControllerLEX.FieldSetProperties objNoOfEmployeesField = new LogSmartCallingControllerLEX.FieldSetProperties();
			objNoOfEmployeesField.strFieldApiName = 'NumberOfEmployees__c';
			objNoOfEmployeesField.strFieldValue = '64';

			objComponentParameters.list_ObjectDetailValues = new List<LogSmartCallingControllerLEX.FieldSetProperties>{ objNoOfEmployeesField };
			objComponentParameters.blnDoNotCall = true;

			String strDataInJson = JSON.serialize(objComponentParameters);
			try {
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, false, '');
			} catch (Exception objException) {
				System.debug('Exception Occured: ' + objException);
			}
		}

		Test.stopTest();

		checkForExceptions(false);

		Task objTaskAssert = [SELECT Id, CallObject, Description FROM Task WHERE WhatId = :objOpportunity.Id AND CallDisposition = 'Test MDR Disposition'];
		System.assertEquals('Test MDR OPP strNotes', objTaskAssert.Description);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test method for saveRecords() when object name is Lead
	 **/
	@isTest
	static void testSaveRecordsForLeadAsMMPR() {
		Test.startTest();
		Lead objLead;
		NICE_Interaction__c objNICEInteraction;
		User objMMPRUser = [SELECT Id, Email FROM User WHERE Email = 'mmpruser@testorg.com' LIMIT 1];

		System.runAs(objMMPRUser) {
			objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('FName1 mmpr')
				.setLastName('LName1 mmpr')
				.setEmail('testlead1@mmpr.com')
				.setPhone('5678987645')
				.setCompany('Godrej')
				.setStatus(LogSmartCallingUtil.LEAD_STATUS_AQL)
				.setLeadSource('LinkedIn')
				.build();
			LeadTriggerHelper.skipTrigger = true;
			insert objLead;
			LeadTriggerHelper.skipTrigger = false;
			LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_LEAD, objLead.Id);

			LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

			objComponentParameters.strWhoId = objLead.Id;
			objComponentParameters.strPhoneNumber = objLead.Phone;
			objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_LEAD;
			objComponentParameters.strRecordId = objLead.Id;

			// TASK DETAILS:
			objComponentParameters.strDisposition = LogSmartCallingUtil.TASK_DISPOSITION_CONNECT;
			objComponentParameters.strTaskType = LogSmartCallingUtil.TASK_TYPE_CALL;
			objComponentParameters.strNotes = 'Test MMPR strNotes';

			objComponentParameters.blnInboundCall = true;

			// PRODUCT UPSELL:
			objComponentParameters.blnCreateProductUpsell = false;
			objComponentParameters.list_ProductUpsellValues = new List<LogSmartCallingControllerLEX.FieldSetProperties>();

			// FOLLOW UP SECTION:
			objComponentParameters.strFollowUpDate = String.valueOf(System.today().addDays(4));
			objComponentParameters.strFollowUpSubject = 'Test MMPR SUBJECT';

			Date dtToday = Date.today();
			String strDate = dtToday.month() + '/' + dtToday.day() + '/' + dtToday.year();

			objNICEInteraction = new TestDataFactory.NICEInteractionBuilder()
				.setDNIS(new normalizationUtil().normalisePhoneField(objLead.Phone))
				.setEmailId(objResponseWrapper.objUserDetails.Email)
				.setContactID('23456543')
				.setCallDurationInSec('300')
				.setCallStartDateAndTime(Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''))
				.setCallEndDateAndTime(Datetime.now().addMinutes(20).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''))
				.build();
			insert objNICEInteraction;

			String strDataInJson = JSON.serialize(objComponentParameters);
			String strNICEInteraction = JSON.serialize(objNICEInteraction);
			try {
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, objResponseWrapper.strMetadataProperties, false, strNICEInteraction);
			} catch (Exception objException) {
				System.debug('Exception Occured: ' + objException);
			}
		}

		Test.stopTest();

		Task objTaskAssert = [SELECT Id, CallObject, Description FROM Task WHERE WhoId = :objLead.Id AND CallObject = :objNiceInteraction.ContactID__c];
		System.assertEquals('Test MMPR strNotes', objTaskAssert.Description);

		//Task objFollowUpTaskAssert = [SELECT Id, ActivityDate FROM Task WHERE Subject = 'Test MMPR SUBJECT'];
		//System.assertEquals(System.today().addDays(4), objFollowUpTaskAssert.ActivityDate);

		Sales_Call_Tracking__c objSalClTrackAssert = [SELECT Id, Task__c FROM Sales_Call_Tracking__c WHERE Lead__c = :objLead.Id];
		System.assertEquals(objTaskAssert.Id, objSalClTrackAssert.Task__c);

		checkForExceptions(false);
	}

	/**
	 * @Author      : Pradeep Chary
	 * @Description : Test method to check Unable to lock row error
	 **/
	@isTest
	static void testGenericDmlOperation() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Co.' LIMIT 1];

		LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties('Account', objAccount.id);
		String strMetadata = objResponseWrapper.strMetadataProperties;

		// Long Text Area:
		LogSmartCallingControllerLEX.FieldSetProperties objBenefitsNotesField = new LogSmartCallingControllerLEX.FieldSetProperties();
		objBenefitsNotesField.strFieldApiName = 'Benefits_Notes__c';
		objBenefitsNotesField.strFieldValue = 'Test Notes';

		// Checkbox:
		LogSmartCallingControllerLEX.FieldSetProperties objBenefits401kField = new LogSmartCallingControllerLEX.FieldSetProperties();
		objBenefits401kField.strFieldApiName = 'Benefits_401k__c';
		objBenefits401kField.strFieldValue = 'TRUE';

		// Number:
		LogSmartCallingControllerLEX.FieldSetProperties objNoOfEmployeesField = new LogSmartCallingControllerLEX.FieldSetProperties();
		objNoOfEmployeesField.strFieldApiName = 'NumberOfEmployees';
		objNoOfEmployeesField.strFieldValue = '10';

		// Date:
		LogSmartCallingControllerLEX.FieldSetProperties objMQLDateField = new LogSmartCallingControllerLEX.FieldSetProperties();
		objMQLDateField.strFieldApiName = 'MQL_Date__c';
		objMQLDateField.strFieldValue = String.valueOf(Date.today());

		// Datetime:
		LogSmartCallingControllerLEX.FieldSetProperties objLastLoginTimeField = new LogSmartCallingControllerLEX.FieldSetProperties();
		objLastLoginTimeField.strFieldApiName = 'Last_Login_Time__c';
		objLastLoginTimeField.strFieldValue = String.valueOf(Datetime.now());

		LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();
		objComponentParameters.strWhoId = '';
		objComponentParameters.strObjectName = 'Account';
		objComponentParameters.strRecordId = objAccount.Id;
		objComponentParameters.strDisposition = 'Test Acc construct test';
		objComponentParameters.strNotes = 'Test strNotes';

		objComponentParameters.blnInboundCall = true;
		objComponentParameters.blnOutboundEmail = true;

		objComponentParameters.list_ObjectDetailValues = new List<LogSmartCallingControllerLEX.FieldSetProperties>{
			objBenefitsNotesField,
			objBenefits401kField,
			objNoOfEmployeesField,
			objMQLDateField,
			objLastLoginTimeField
		};
		objComponentParameters.blnDoNotCall = true;

		LogSmartCallingControllerLEX.blnDMLException = true;

		String strDataInJson = JSON.serialize(objComponentParameters);
		Test.startTest();
		LogSmartCallingControllerLEX.saveRecords(strDataInJson, strMetadata, true, '');
		Test.stopTest();

		System.assertNotEquals(0, [SELECT COUNT() FROM Task WHERE CallDisposition = 'Test Acc construct test']);

		LogSmartCallingControllerLEX.blnDMLException = false;
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Test method for getNiceInteraction()
	 **/
	@isTest
	public static void testGetNiceInteraction() {
		User objCXUser = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Email = 'cxuser@testorg.com' LIMIT 1];
		System.runAs(objCXUser) {
			String strJsonNiceInt = LogSmartCallingControllerLEX.getNiceInteraction('1111111111');
			Nice_Interaction__c objNiceInt = (Nice_Interaction__c) JSON.deserialize(strJsonNiceInt, Nice_Interaction__c.class);
			System.assertEquals('0000000000000000', objNiceInt.ContactID__c);
		}
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test method to check the Error Lead Status can't go back
	 * 	to MQL/ AQL from Unqualified.
	 **/
	@isTest
	public static void testLeadStatusChangeError() {
		Test.startTest();
		Lead objLead;
		User objMMPRUser = [SELECT Id, Email FROM User WHERE Email = 'mmpruser@testorg.com' LIMIT 1];

		System.runAs(objMMPRUser) {
			objLead = new TestDataFactory.LeadBuilder()
				.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
				.setFirstName('FName1 mmpr')
				.setLastName('LName1 mmpr')
				.setEmail('testlead1@mmpr.com')
				.setPhone('5678987645')
				.setCompany('Godrej')
				.setStatus(LogSmartCallingUtil.LEAD_STATUS_UNQUALIFIED)
				.setLeadSource('LinkedIn')
				.setLeadStatusDetail(LogSmartCallingUtil.LEAD_STATUS_DETAIL_BAD_PHONE)
				.build();
			LeadTriggerHelper.skipTrigger = true;
			insert objLead;
			LeadTriggerHelper.skipTrigger = false;

			LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

			objComponentParameters.strWhoId = objLead.Id;
			objComponentParameters.strPhoneNumber = objLead.Phone;
			objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_LEAD;
			objComponentParameters.strRecordId = objLead.Id;

			// TASK DETAILS:
			objComponentParameters.strDisposition = LogSmartCallingUtil.TASK_DISPOSITION_CONNECT;

			objComponentParameters.blnInboundCall = true;
			objComponentParameters.strLeadCurrentStatus = LogSmartCallingUtil.LEAD_STATUS_AQL;

			String strDataInJson = JSON.serialize(objComponentParameters);
			try {
				LogSmartCallingControllerLEX.blnTestException = true;
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, '', true, '');
			} catch (Exception objException) {
				System.debug('Exception Occured: ' + objException);
			}
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test method to check the Error Lead Status can't go back
	 * 	to MQL/ AQL from Unqualified.
	 **/
	@isTest
	public static void testLeadUpdateError() {
		Test.startTest();
		Lead objLead;
		User objMMPRUser = [SELECT Id, Email FROM User WHERE Email = 'mmpruser@testorg.com' LIMIT 1];

		System.runAs(objMMPRUser) {
			objLead = [SELECT Id, Phone FROM Lead WHERE Email = 'testlead1@setup.com'];
			LogSmartCallingControllerLEX.ResponseWrapper objResponseWrapper = LogSmartCallingControllerLEX.getOnLoadProperties(LogSmartCallingUtil.SOBJECT_API_NAME_LEAD, objLead.Id);

			LogSmartCallingControllerLEX.ComponentParameters objComponentParameters = new LogSmartCallingControllerLEX.ComponentParameters();

			objComponentParameters.strWhoId = objLead.Id;
			objComponentParameters.strPhoneNumber = objLead.Phone;
			objComponentParameters.strObjectName = LogSmartCallingUtil.SOBJECT_API_NAME_LEAD;
			objComponentParameters.strRecordId = objLead.Id;

			// TASK DETAILS:
			objComponentParameters.strDisposition = LogSmartCallingUtil.TASK_DISPOSITION_CONNECT;
			objComponentParameters.strTaskType = LogSmartCallingUtil.TASK_TYPE_CALL;
			objComponentParameters.strNotes = 'Test MMPR strNotes';

			objComponentParameters.blnInboundCall = true;

			// CURRENT RECORD:
			LogSmartCallingControllerLEX.FieldSetProperties objStatusField = new LogSmartCallingControllerLEX.FieldSetProperties();
			objStatusField.strFieldApiName = 'Status';
			objStatusField.strFieldValue = LogSmartCallingUtil.LEAD_STATUS_UNQUALIFIED;

			objComponentParameters.list_ObjectDetailValues = new List<LogSmartCallingControllerLEX.FieldSetProperties>{ objStatusField };

			String strDataInJson = JSON.serialize(objComponentParameters);
			try {
				LogSmartCallingControllerLEX.blnTestException = true;
				LogSmartCallingControllerLEX.saveRecords(strDataInJson, objResponseWrapper.strMetadataProperties, true, '');
			} catch (Exception objException) {
				System.debug('Exception Occured: ' + objException);
			}
		}

		Test.stopTest();

		Task objTaskAssert = [SELECT Id, CallObject, Description FROM Task WHERE WhoId = :objLead.Id];
		System.assertEquals('Test MMPR strNotes', objTaskAssert.Description);
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if exceptions are logged
	 **/
	@isTest
	public static void testSaveLTC() {
		Test.startTest();
		Lead objLead;
		User objMMPRUser = [SELECT Id, Email FROM User WHERE Email = 'mmpruser@testorg.com' LIMIT 1];

		System.runAs(objMMPRUser) {
			objLead = [SELECT Id, Phone FROM Lead WHERE Email = 'testlead1@setup.com'];
			LogSmartCallingControllerLEX.saveLTC(LogSmartCallingUtil.SOBJECT_API_NAME_LEAD, objLead.Id);
		}
		Test.stopTest();

		Task objTaskAssert = [SELECT Id, Lead__c, CallDisposition FROM Task WHERE WhoId = :objLead.Id];
		System.assertEquals(objLead.Id, objTaskAssert.Lead__c);
		System.assertEquals(LogSmartCallingUtil.TASK_STATUS_ATTEMPT, objTaskAssert.CallDisposition);

		checkForExceptions(false);
	}

	/**
	 * @author       Veeresh Kumar
	 * @description  Test if exceptions are logged
	 **/
	public static void checkForExceptions(Boolean blnHasException) {
		// Assert exceptions are logged from Task Trigger
		Integer intExceptions = [SELECT COUNT() FROM Exception_Log__c WHERE Class_Name__c = :LogSmartCallingUtil.LOG_SMART_CALL_CONTR_LEX_CLS];

		if (blnHasException) {
			System.assertNotEquals(0, intExceptions);
		} else {
			System.assertEquals(0, intExceptions);
		}
	}

	/**
	 * @description  Test nice interaction processing
	 **/
	@isTest
	public static void testDoCalculations() {
		Nice_Interaction__c objNiceRecord = [SELECT Id, ContactID__c, Processing_State__c, Retry_Process_Count__c FROM Nice_Interaction__c WHERE Email_Id__c != 'fakeaddress@fake.com' LIMIT 1];

		TaskTriggerHelper.skipTrigger = true;
		Task objTask = new Task();
		objTask.Genesys_Interaction_Id__c = objNiceRecord.ContactID__c;
		insert objTask;
		TaskTriggerHelper.skipTrigger = false;

		LogSmartCallingControllerLex.Input objInput = new LogSmartCallingControllerLex.Input();
		objInput.strCallStartDateTime = '11/14/2023 11:47:38 AM';
		objInput.strCallEndDateTime = '11/14/2023 1:16:02 PM';
		objInput.intCallDuration = 120;
		objInput.strGenesysInteractionId = objNiceRecord.ContactID__c;
		objInput.idNiceInteractionId = objNiceRecord.Id;
		objInput.strProcessingState = objNiceRecord.Processing_State__c;
		objInput.intRetryCount = (Integer) objNiceRecord.Retry_Process_Count__c;
		objInput.strComments = 'Test Auto summary by CXOne';
		objInput.strCallResult = 'Call Completed';

		LogSmartCallingControllerLex.Output objOutput = LogSmartCallingControllerLex.doCalculations(new List<LogSmartCallingControllerLex.Input>{ objInput })[0];

		System.assert(objOutput.dateTimeCallStart != null, 'Start date returned should not be null');
		System.assert(objOutput.dateTimeCallEnd != null, 'End date returned should not be null');
		System.assertEquals(objOutput.dateTimeCallStart, DateTime.newInstance(2023, 11, 14, 11, 47, 38), 'DateTime should be of correct instance');
		System.assertEquals(objOutput.dateTimeCallEnd, DateTime.newInstance(2023, 11, 14, 13, 16, 2), 'DateTime should be of correct instance');

		objTask = [
			SELECT Id, CallDurationInSeconds, Date_Completed__c, Start_Date__c, Genesys_Interaction_Id__c, CallDisposition, Description
			FROM Task
			WHERE Genesys_Interaction_Id__c = :objInput.strGenesysInteractionId
		];

		System.assertNotEquals(null, objTask.Date_Completed__c, 'Task date completed should be updated correctly');
		System.assertNotEquals(null, objTask.Start_Date__c, 'Task date start should be updated correctly');
		System.assertEquals(objInput.intCallDuration, objTask.CallDurationInSeconds, 'Task call duration should be updated correctly');
		System.assertEquals(objInput.strComments, objTask.Description, 'Task description should be updated correctly');
		System.assertEquals(objInput.strCallResult, objTask.CallDisposition, 'Task disposition should be updated correctly');

		objNiceRecord = [SELECT Processing_State__c, Retry_Process_Count__c FROM Nice_Interaction__c WHERE Id = :objNiceRecord.Id];
		System.assertEquals('Processed', objNiceRecord.Processing_State__c);

		objNiceRecord = new TestDataFactory.NICEInteractionBuilder()
			.setDNIS('1111111111')
			.setEmailId('address@email.com')
			.setContactID('9999')
			.setCallDurationInSec('120')
			.setCallStartDateAndTime('11/14/2023 11:47:38 AM')
			.setCallEndDateAndTime('11/14/2023 1:16:02 PM')
			.build();
		insert objNiceRecord;

		objInput.strGenesysInteractionId = '9999';
		objInput.idNiceInteractionId = objNiceRecord.Id;
		objInput.strProcessingState = null;
		objInput.intRetryCount = null;
		LogSmartCallingControllerLex.doCalculations(new List<LogSmartCallingControllerLex.Input>{ objInput });

		objNiceRecord = [SELECT Processing_State__c, Retry_Process_Count__c, ContactId__c, Call_Duration_in_Sec__c FROM Nice_Interaction__c WHERE Id = :objNiceRecord.Id];
		System.assertEquals('Retry', objNiceRecord.Processing_State__c);
		System.assertEquals(0, objNiceRecord.Retry_Process_Count__c);

		//Test Scheduler
		objTask.Genesys_Interaction_Id__c = objNiceRecord.ContactId__c;
		objTask.CallDurationInSeconds = null;
		objTask.Start_Date__c = objTask.Date_Completed__c = null;
		objTask.Status = 'Connect';

		TaskTriggerHelper.skipTrigger = true;
		update objTask;
		TaskTriggerHelper.skipTrigger = false;

		Test.startTest();

		String cronExp = '0 0 * * * ?';
		LogSmartCallingScheduler.blnTestException = true;
		String jobId = System.schedule('Test Activity Processing', cronExp, new LogSmartCallingScheduler(1));

		Test.stopTest();

		objTask = [SELECT Id, CallDurationInSeconds, Date_Completed__c, Start_Date__c, Genesys_Interaction_Id__c FROM Task WHERE Genesys_Interaction_Id__c = :objNiceRecord.ContactId__c];
		System.assertEquals(objTask.Start_Date__c, DateTime.newInstance(2023, 11, 14, 11, 47, 38), 'DateTime should be of correct instance');
		System.assertEquals(objTask.Date_Completed__c, DateTime.newInstance(2023, 11, 14, 13, 16, 2), 'DateTime should be of correct instance');
		System.assertEquals(Integer.valueOf(objNiceRecord.Call_Duration_in_Sec__c), objTask.CallDurationInSeconds, 'Task call duration should be updated correctly');
	}

	/**
	 * Mock Response - Success
	 */
	public class GenerateSuccessCalloutMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest request) {
			HttpResponse objResponse = new HttpResponse();
			objResponse.setHeader('Content-Type', 'application/json');
			objResponse.setBody('{"status": "SUCCESS"}');
			objResponse.setStatusCode(200);
			return objResponse;
		}
	}
}