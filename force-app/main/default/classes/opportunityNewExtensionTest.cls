/**
 * @name         : opportunityNewExtensionTest
 * @author       : Gaurav Khare
 * @date         : 11/07/2019
 * @description  : Test class for opportunityNewExtension
 **/
@isTest
private class opportunityNewExtensionTest {
	@testSetup
	static void setupData() {
		List<Rolesets__c> list_RoleSets = new List<Rolesets__c>{
			new Rolesets__c(Name = 'roleset1', Roleset_Name__c = 'Company', components__c = 'OpportunityNewExtension', Roles__c = 'Primary Payroll Admin\r\nPayroll Admin\r\n'),
			new Rolesets__c(
				Name = 'roleset2',
				Roleset_Name__c = 'Company_Benefits',
				components__c = 'OpportunityTriggerHelper',
				Roles__c = 'Primary Payroll Admin\r\nPayroll Admin\r\nBenefits Signatory\r\nSignatory\r\nBenefits Admin'
			)
		};
		insert list_RoleSets;
		
		List<ZP_User__c> list_ZPUsers = new List<ZP_User__c>{
			new ZP_User__c(Name = 'test 1', Created_At__c = System.now(), Updated_At__c = System.now(), Id__c = '00001', Email__c = 'test@email1.com'),
			new ZP_User__c(Name = 'test 2', Created_At__c = System.now(), Updated_At__c = System.now(), Id__c = '00002', Email__c = 'test@email2.com')
		};

		insert list_ZPUsers;

		Account objAccount = new Account();
		objAccount.Name = 'Test Demo AccountName 1';
		objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
		objAccount.BillingStreet = 'Testing Avenue 1';
		objAccount.BillingPostalCode = '123456';
		objAccount.Company_Trade_Name__c = 'Company trade name 1';
		objAccount.Phone = '19992344444';
		objAccount.ShippingStreet = 'Testing Avenue 1';
		objAccount.ShippingPostalCode = '123455';
		objAccount.Joined_Date_Panda__c = System.today();
		objAccount.ZP_Company_Overall_Status__c = 'Active';
		objAccount.BillingState = 'Arizona';
		objAccount.Number_of_Active_Employees__c = 12;
		insert objAccount;

		Contact objContact = new Contact();
		objContact.AccountId = objAccount.Id;
		objContact.FirstName = 'Test';
		objContact.LastName = 'Test';
		objContact.Email = 'Signatorytest@gusto.com';
		insert objContact;
		
		ZP_User_Role__c objZPUserRole = new ZP_User_Role__c();
		objZPUserRole.User_Id__c = '7777';
		objZPUserRole.Type__c = 'Role::PayrollAdmin';
		objZPUserRole.Company_Id__c = '11111111111112';
		objZPUserRole.Company_account__c = objAccount.Id;
		objZPUserRole.Contact__c = objContact.Id;
		objZPUserRole.Is_Primary__c = false;
		objZPUserRole.Created_At__c = System.now();
		objZPUserRole.Updated_At__c = System.now();
		objZPUserRole.First_Name__c = 'asdf';
		objZPUserRole.Last_Name__c = 'asdf';
		ZpUserRoleTriggerHelper.skipTrigger = true;
		insert objZPUserRole;
		ZpUserRoleTriggerHelper.skipTrigger = false;
		
		ZP_User_Role__c objZPUserRole2 = new ZP_User_Role__c();
		objZPUserRole2.User_Id__c = '7777';
		objZPUserRole2.Type__c = 'Role::PayrollAdmin';
		objZPUserRole2.Company_Id__c = '11111111111112';
		objZPUserRole2.Company_account__c = objAccount.Id;
		objZPUserRole2.Contact__c = objContact.Id;
		objZPUserRole2.Is_Primary__c = true;
		objZPUserRole2.Created_At__c = System.now();
		objZPUserRole2.Updated_At__c = System.now();
		objZPUserRole2.First_Name__c = 'asdf';
		objZPUserRole2.Last_Name__c = 'asdf';
		ZpUserRoleTriggerHelper.skipTrigger = true;
		insert objZPUserRole2;
		ZpUserRoleTriggerHelper.skipTrigger = false;

		setupFuture();
	}

	@future
	public static void setupFuture() {
		UserRole objRole = [SELECT Id FROM UserRole WHERE Developername = 'CSSE'];
		Profile objProfile = TestDataFactory.objZPSysAdminProfile; 
		List<User> list_Users = new List<User>();
        String strNow = String.valueof(Datetime.now()).replaceAll('[-|:|\\s]', '');

		User objCSUser = new TestDataFactory.UserBuilder()
				.setUserName('cssetest' + strNow + '@gusto.com')
				.setLastName('CSUser')
				.setEmail('cssetest@gusto.com')
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.setUserRoleId(objRole.Id)
				.build();
		list_Users.add(objCSUser);

		User objNonCSUser = new TestDataFactory.UserBuilder()
				.setUserName('testuser' + strNow + '@gusto.com')
				.setLastName('TestUser')
				.setEmail('testuser@gusto.com')
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
		list_Users.add(objNonCSUser);

		UserTriggerHelper.skipTrigger = true;
		insert list_Users;
		UserTriggerHelper.skipTrigger = false;
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Creates Opportunity records
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testSaveRec() {
		Account objAccount = [SELECT Id FROM Account LIMIT 1];

		Opportunity objOpportunity = new Opportunity();
		objOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Customer Success');
		objOpportunity.Name = 'OppRecord';
		objOpportunity.AccountId = objAccount.Id;
		objOpportunity.StageName = 'New';
		objOpportunity.CloseDate = System.today();

		Test.startTest();
		ApexPages.CurrentPage().getParameters().put('accid', objAccount.Id);
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		
		opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);
		objExtension.saveRec();
		
		List<OpportunityContactRole> list_OpportunityContactRoles = [SELECT Id FROM OpportunityContactRole];

		System.assertEquals(list_OpportunityContactRoles.size(), 2);
		Test.stopTest();
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Creates Opportunity records
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testSaveRec2() {
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		    
		Opportunity objOpportunity = new Opportunity();
		objOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Customer Success');
		objOpportunity.Name = 'OppRecord';
		objOpportunity.AccountId = objAccount.Id;
		objOpportunity.StageName = 'SAL';
		objOpportunity.CloseDate = System.today();

		Test.startTest();
		ApexPages.CurrentPage().getParameters().put('accid', objAccount.Id);
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		
		opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);
		objExtension.oppRec.RecordTypeId = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
		objExtension.saveRec();
		Test.stopTest();
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Update Opportunity record field Type = 'Tier Upsell'
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testPrepopulateUpsellOpportunity() {
		Account objAccount = [SELECT Id FROM Account LIMIT 1];

		Opportunity objOpportunity = new Opportunity();
		objOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Customer Success');
		objOpportunity.Name = 'OppRecord';
		objOpportunity.AccountId = objAccount.Id;
		objOpportunity.StageName = 'SAL';
		objOpportunity.CloseDate = Date.newInstance(2016, 12, 9);

		Test.startTest();
		ApexPages.CurrentPage().getParameters().put('accid', objAccount.Id);
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		
		opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);
		objExtension.oppRec.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits BoR');
		objExtension.prepopulateUpsellOpportunity();
		
		objExtension.oppRec.RecordTypeId = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
		objExtension.prepopulateUpsellOpportunity();
		Test.stopTest();
	}

	/*
	 * @Author      : Alex Xiong
	 * @Description : Confirm Opportunity trigger logic and VF extension does not create 2 of the same
	 *                    Opportunity Contact Roles
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	public static void testDuplicateContactRoles() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		
		Opportunity objOpportunity = new Opportunity(
			RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Customer Success'),
			Name = 'test opty',
			AccountId = objAccount.Id,
			StageName = 'New',
			CloseDate = System.today()
		);
		insert objOpportunity;

		List<OpportunityContactRole> list_OpportunityContactRoles = [
			SELECT Id
			FROM OpportunityContactRole
			WHERE OpportunityId = :objOpportunity.Id
		];
		
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		OpportunityNewExtension objExtension = new OpportunityNewExtension(objStandardController);
		objExtension.saveRec();

		List<OpportunityContactRole> list_OpportunityContactRolesAfterExt = [SELECT Id FROM OpportunityContactRole];

		System.assertEquals(
			list_OpportunityContactRoles.size(),
			list_OpportunityContactRolesAfterExt.size(),
			'Opportunity trigger and VF extension should not create duplicate Contact Roles'
		);

		Test.stopTest();
	}
	
	/**
	 * @Author		: Alex Xiong
	 * @Description : assert CS user will default the extension's opportunity record type to Customer Success
	 */
	@isTest
	public static void testCSUser() {
		User objUser = [SELECT Id FROM User WHERE Email = 'cssetest@gusto.com' LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];

		Test.startTest();
		System.runAs(objUser) {
			Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setName('CS Opty')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setCloseDate(System.today())
				.build();

			ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
			opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);
			
			System.assertEquals(Cache.getRecordTypeId('Opportunity', 'Customer Success'), objOpportunity.RecordTypeId);
		}
		Test.stopTest();
	}

	/**
	 * @Author		: Alex Xiong
	 * @Description : assert Non-CS user will default the extension's opportunity record type to Customer Success
	 */
	@isTest
	public static void testNonCSUSer() {
		User objNonCSUser = [SELECT Id FROM User WHERE Email = 'testuser@gusto.com' LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];

		Test.startTest();
		System.runAs(objNonCSUser) {
			Opportunity objNotCSOpportunity = new TestDataFactory.OpportunityBuilder()
				.setName('Not CS Opty')
				.setAccountId(objAccount.Id)
				.setStage('Open')
				.setCloseDate(System.today())
				.build();

			ApexPages.StandardController objStandardController = new ApexPages.StandardController(objNotCSOpportunity);
			opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);

			System.assertNotEquals(Cache.getRecordTypeId('Opportunity', 'Customer Success'), objNotCSOpportunity.RecordTypeId);
		}
		Test.stopTest();
	}

	/**
	 * @author Deepesh Rao
	 * @description Test Tax Credits Opportunity Creation when type is Existing Business
	 */
	@isTest
	static void testTaxCreditsOpportunityWhenExistingBusiness() {
		Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
		String strRecordTypeId = OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(strRecordTypeId)
			.setTaxYear('2022')
			.setAccountId(objAccount.Id)
			.setStage('Commit')
			.setType('Existing Business')
			.build();

		Test.startTest();
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);

		objExtension.prepopulateUpsellOpportunity();
		objExtension.saveRec();
		Test.stopTest();

		List<Opportunity> list_Opportunities = [
			SELECT Id, Name, StageName, Tax_Year__c
			FROM Opportunity
			WHERE RecordTypeId = :strRecordTypeId
			ORDER BY CreatedDate DESC
		];
		Assert.AreEqual(1, list_Opportunities.size(), 'Failed, Opportunity not created');
		Assert.AreEqual('Commit', list_Opportunities[0].StageName, 'Invalid Stage');
		Assert.AreEqual('2022', list_Opportunities[0].Tax_Year__c, 'Invalid Tax year');
		Assert.AreEqual(
			objAccount?.Name + ' ' + '-' + ' ' + 'R&D Existing Business ' + list_Opportunities[0].Tax_Year__c,
			list_Opportunities[0].Name,
			'Invalid Opp Name'
		);
	}
    
     /**
	 * @author Deepesh Rao
	 * @description Test Tax Credits Opportunity Creation when type is Expansion
	 */
	@isTest
	static void testTaxCreditsOpportunityWhenExpansion() {
		Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
		String strRecordTypeId = OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(strRecordTypeId)
			.setAccountId(objAccount.Id)
			.setStage('Commit')
			.setType('Expansion')
			.build();
		objOpportunity.Tax_Year__c = '2023';

		Test.startTest();
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);

		objExtension.prepopulateUpsellOpportunity();
		objExtension.saveRec();
		Test.stopTest();

		List<Opportunity> list_Opportunities = [
			SELECT Id, Name, StageName, Tax_Year__c
			FROM Opportunity
			WHERE RecordTypeId = :strRecordTypeId
			ORDER BY CreatedDate DESC
		];
		Assert.AreEqual(1, list_Opportunities.size(), 'Failed, Opportunity not created');
		Assert.AreEqual('Commit', list_Opportunities[0].StageName, 'Invalid Stage');
		Assert.AreEqual('2023', list_Opportunities[0].Tax_Year__c, 'Invalid Tax year');
		Assert.AreEqual(objAccount?.Name + ' ' + '-' + ' ' + 'R&D Expansion ' + list_Opportunities[0].Tax_Year__c, list_Opportunities[0].Name, 'Invalid Opp Name');
	}

     /**
	 * @author Deepesh Rao
	 * @description Test Tax Credits Opportunity Creation when type is any other 
	 */
	@isTest
	static void testTaxCreditsOpportunity() {
		Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
		String strRecordTypeId = OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(strRecordTypeId)
			.setAccountId(objAccount.Id)
			.setStage('Commit')
			.setType('Partnership')
			.build();
		objOpportunity.Tax_Year__c = '2023';

		Test.startTest();
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);

		objExtension.prepopulateUpsellOpportunity();
		objExtension.saveRec();
		Test.stopTest();

		List<Opportunity> list_Opportunities = [
			SELECT Id, Name, StageName, Tax_Year__c, Type
			FROM Opportunity
			WHERE RecordTypeId = :strRecordTypeId
			ORDER BY CreatedDate DESC
		];
		System.assertEquals(1, list_Opportunities.size(), 'Failed, Opportunity not created');
		System.assertEquals('Commit', list_Opportunities[0].StageName, 'Invalid Stage');
		System.assertEquals('2023', list_Opportunities[0].Tax_Year__c, 'Invalid Tax year');
		System.assertEquals(objAccount?.Name + ' ' + '-' + ' ' + 'R&D Partnership ' + list_Opportunities[0].Tax_Year__c, list_Opportunities[0].Name, 'Invalid Opp Name');
	}
	/**
	 * @author Jayesh Gawande
	 * @description Test Tax Credits Opportunity Creation when type is New Business
	 */
	@isTest
	static void testTaxCreditsOpportunityWhenNewBusiness() {
		Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
		String strRecordTypeId = OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder().setRecordTypeId(strRecordTypeId).setAccountId(objAccount.Id).setStage('Commit').setType('New Business').build();
		objOpportunity.Tax_Year__c = '2023';

		Test.startTest();
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);

		objExtension.prepopulateUpsellOpportunity();
		objExtension.saveRec();
		Test.stopTest();

		List<Opportunity> list_Opportunities = [
			SELECT Id, Name, StageName, Tax_Year__c
			FROM Opportunity
			WHERE RecordTypeId = :strRecordTypeId
                        AND Id = :objOpportunity.Id
			ORDER BY CreatedDate DESC
		];
		System.assertEquals(1, list_Opportunities.size(), 'Failed, Opportunity not created');
		System.assertEquals('Commit', list_Opportunities[0].StageName, 'Invalid Stage');
		System.assertEquals('2023', list_Opportunities[0].Tax_Year__c, 'Invalid Tax year');
		System.assertEquals(objAccount?.Name + ' ' + '-' + ' ' + opportunityNewExtension.TAXCREDITS_PREFIX_RD + ' ' + opportunityNewExtension.TAXCREDITS_TYPE_NEW_BUSINESS + ' ' + + list_Opportunities[0].Tax_Year__c, list_Opportunities[0].Name, 'Invalid Opp Name');
	}

	/**
	 * @author Jayesh Gawande
	 * @description Test Tax Credits Opportunity Creation when type is Partnership
	 */
	@isTest
	static void testTaxCreditsOpportunityWhenPartnership() {
		Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
		String strRecordTypeId = OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder().setRecordTypeId(strRecordTypeId).setAccountId(objAccount.Id).setStage('Commit').setType('Partnership').build();
		objOpportunity.Tax_Year__c = '2023';

		Test.startTest();
		ApexPages.StandardController objStandardController = new ApexPages.StandardController(objOpportunity);
		opportunityNewExtension objExtension = new opportunityNewExtension(objStandardController);

		objExtension.prepopulateUpsellOpportunity();
		objExtension.saveRec();
		Test.stopTest();

		List<Opportunity> list_Opportunities = [
			SELECT Id, Name, StageName, Tax_Year__c
			FROM Opportunity
			WHERE RecordTypeId = :strRecordTypeId
                        AND Id = :objOpportunity.Id
			ORDER BY CreatedDate DESC
		];
		System.assertEquals(1, list_Opportunities.size(), 'Failed, Opportunity not created');
		System.assertEquals('Commit', list_Opportunities[0].StageName, 'Invalid Stage');
		System.assertEquals('2023', list_Opportunities[0].Tax_Year__c, 'Invalid Tax year');
		System.assertEquals(objAccount?.Name + ' ' + '-' + ' ' +  opportunityNewExtension.TAXCREDITS_PREFIX_RD + ' ' + opportunityNewExtension.TAXCREDITS_TYPE_PARTNERSHIP + ' ' + list_Opportunities[0].Tax_Year__c, list_Opportunities[0].Name, 'Invalid Opp Name');
	}

	/**
	 * @author Ajay Krishna P U
	 * @description Test Validate Tax Year
	 */
	@isTest
	static void testValidateTaxYear(){
		Test.startTest();
		System.assert(false == opportunityNewExtension.validateTaxYear(null), 'Validation failed - null');
		System.assert(false == opportunityNewExtension.validateTaxYear(''), 'Validation failed - ""');
		System.assert(false == opportunityNewExtension.validateTaxYear(' '), 'Validation failed - " "');
		System.assert(false == opportunityNewExtension.validateTaxYear('abc'), 'Validation failed - abc');
		System.assert(false == opportunityNewExtension.validateTaxYear('abc2021'), 'Validation failed - abc2021');
		System.assert(false == opportunityNewExtension.validateTaxYear('221'), 'Validation failed - 221');

		System.assert(true == opportunityNewExtension.validateTaxYear('2211'), 'Validation failed - 2211');
		System.assert(true == opportunityNewExtension.validateTaxYear('2000'), 'Validation failed - 2000');
		System.assert(true == opportunityNewExtension.validateTaxYear('9999'), 'Validation failed - 9999');
		Test.stopTest();
	}
	
	/**
	 * @author Jayesh Gawande
	 * @description Test for calculateTaxYear method to check Tax Year calulated.
	 */
    @isTest
    static void testCalculateTaxYear() {
        // Create a test date before the custom label date
        Date dtTestDateBefore = Date.newInstance(2023, 8, 12);
        System.assertEquals(2022, opportunityNewExtension.calculateTaxYear(dtTestDateBefore));
        
        // Create a test date on or after the custom label date
        Date dtTestDateOnOrAfter = Date.newInstance(2023, 10, 20);
        System.assertEquals(2023, opportunityNewExtension.calculateTaxYear(dtTestDateOnOrAfter));
    }
}