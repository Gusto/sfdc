/**
 * @name             TaxResCaseButtonsTest.cls
 * @author           Pravesh Rana
 * @date             July-6-2021
 * @description      This class is used to test the "Code Coverage" of "TaxResCaseButtons" class
 *                  which is related to "Tax Res" project.
 * @Covered class    TaxResCaseButtons
 * @revisions        Date ------------ Name ------------ Comments
 **/
@isTest
public with sharing class TaxResCaseButtonsTest {
	public static String TAXRES_ACC_SPECIALIST_GROUP_NAME = 'TaxRes Change Account Specialist Group';
	public static String TAXRES_TACKLEBOXVIEW_GROUP_NAME = 'TaxRes_View_Tacklebox';

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void handleTestData() {
		Group grp = new Group(Type = 'Queue', Name = 'test queue 1');
		insert grp;

		setupFuture();
		TestDataFactory.CreateUserRole('Notice Analyst');
		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);
		Case ObjCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
	}

	/*
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create user data
	 * @Parm        : NA
	 * @Return      : NA
	 */
	@future
	public static void setupFuture() {
		Profile objProfile = TestDataFactory.objZPSysAdminProfile;
		User objUserWithoutPermission = new TestDataFactory.UserBuilder()
			.setAlias('testU')
			.setEmail('taxResCareCaseButtons@test.com')
			.setLastName('Testing')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('taxResCareCaseButtons@test.com')
			.setProfileId(objProfile.Id)
			.build();
		insert objUserWithoutPermission;

		Group g = [SELECT Id FROM Group WHERE Name = 'test queue 1'];
		QueueSobject mappingObject = new QueueSobject(QueueId = g.Id, SobjectType = 'Case');

		insert mappingObject;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "queryCase" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void queryCaseTest() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];
		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);
			Case objNewCase = TaxResCaseButtons.queryCase(objCase.Id);
			System.assert(objNewCase.Id != null, 'Case Id should not be null.');
		}
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "changeOwner" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void changeOwnerTest() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];
		if (list_Case.size() > 0) {
			Case objCase = list_Case.get(0);
			TaxResCaseButtons.changeOwner(objCase.Id, UserInfo.getUserId());
		}

		Test.stopTest();

		list_Case = [SELECT Id, OwnerId FROM Case LIMIT 1];
		Case objCase = list_Case.get(0);
		System.assert(objCase.OwnerId == UserInfo.getUserId(), 'OwnerId and current user Id should match.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "CompanyAccount" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void updateAccountTest() {
		Case objCase;
		Account objOldAccount;
		Account objNewAccount = new Account();
		Test.startTest();
		List<Case> list_Case = [SELECT Id, AccountId FROM Case LIMIT 1];
		if (list_Case.size() > 0) {
			objCase = list_Case.get(0);
			objOldAccount = new Account(Id = objCase.AccountId);
			objNewAccount = TestDataFactory.CompanyAccount();
			TaxResCaseButtons.updateAccount(objCase.Id, objNewAccount.Id);
		}

		Test.stopTest();

		list_Case = [SELECT Id, AccountId FROM Case WHERE Id = :objCase.Id];
		System.assert(list_Case.size() > 0, 'There should be at least 1 case in list.');
		System.assert(list_Case[0].AccountId != null, 'AccountId on case should not be null.');
		System.assert(list_Case[0].AccountId != objOldAccount.Id, 'AccountId on case should not match with old account Id.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "updateContact" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void updateContactTest() {
		Case objCase;
		Test.startTest();
		Contact objContact = new Contact();
		List<Case> list_Case = [SELECT Id FROM Case WHERE ContactId = NULL LIMIT 1];
		if (list_Case.size() > 0) {
			objCase = list_Case.get(0);
			Account objAccount = TestDataFactory.CompanyAccount();
			objContact = new TestDataFactory.ContactBuilder()
				.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
				.setEmail('TaxResCaseButtonsTest@gusto1.com')
				.setAccountId(objAccount.Id)
				.setFirstName('Test Contact')
				.setLastName('Test')
				.build();
			insert objContact;

			TaxResCaseButtons.updateContact(objCase.Id, objContact.Id);
		}

		Test.stopTest();

		list_Case = [SELECT Id, ContactId FROM Case WHERE Id = :objCase.Id];
		System.assert(list_Case.size() > 0, 'There should be at least 1 case in list.');
		System.assert(list_Case[0].ContactId != null, 'ContactId on case should not be null.');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validate "updateAgencyInfo" method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void updateAgencyInfoTest() {
		Case objCase;
		Test.startTest();
		Contact objContact = new Contact();
		List<Case> list_Case = [SELECT Id FROM Case WHERE Agency_Information__c = NULL LIMIT 1];
		if (list_Case.size() > 0) {
			objCase = list_Case.get(0);
			Agency_Information__c objAgency = new Agency_Information__c(Name = 'Testing Agency');
			insert objAgency;

			TaxResCaseButtons.updateAgencyInfo(objCase.Id, objAgency.Id);
		}
		Test.stopTest();

		list_Case = [SELECT Id, Agency_Information__c FROM Case WHERE Id = :objCase.Id];
		System.assert(list_Case.size() > 0, 'There should be at least 1 case in list.');
		System.assert(list_Case[0].Agency_Information__c != null, 'Agency_Information__c on case should not be null.');
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : validate logged in user in public group for case owner change
	 * @Parm        : NA
	 * @Return      : boolean
	 **/
	@isTest
	static void testChangeOwnerUserInPublicGroup() {
		Boolean blnCheckUserInGroup;
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User objUser = new TestDataFactory.UserBuilder()
			.setAlias('gusst11')
			.setEmail('testuser11@test.com')
			.setFirstName('CreateUser')
			.setLastName('Test')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setProfileId(objProfile.Id)
			.setUserName(TestDataFactory.buildUniqueString())
			.build();

		insert objUser;
		String strChangeOwnerGroup = Label.Change_Owner_Groups.split(',')[0];

		List<Group> list_Groups = [SELECT Id FROM Group WHERE Name = :strChangeOwnerGroup];

		if (list_Groups != null && !list_Groups.isEmpty()) {
			GroupMember objGrpMember = new GroupMember(GroupId = list_Groups[0].Id, UserOrGroupId = objUser.Id);
			insert objGrpMember;

			System.runAs(objUser) {
				Test.startTest();
				blnCheckUserInGroup = TaxResCaseButtons.canUserChangeOwner();
				Test.stopTest();
			}
			System.assert(blnCheckUserInGroup, 'blnCheckUserInGroup should be true.');
		}
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : validate logged in user not in public group for case owner change
	 * @Parm        : NA
	 * @Return      : boolean
	 **/
	@isTest
	static void testChangeOwnerUserNotInPublicGroup() {
		Boolean blnCheckUserInGroup;
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User objUser = new TestDataFactory.UserBuilder()
			.setAlias('gusst22')
			.setEmail('testuser22@test.com')
			.setFirstName('CreateUser2')
			.setLastName('Test2')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setProfileId(objProfile.Id)
			.setUserName(TestDataFactory.buildUniqueString())
			.build();

		insert objUser;

		System.runAs(objUser) {
			Test.startTest();
			blnCheckUserInGroup = TaxResCaseButtons.canUserChangeOwner();
			Test.stopTest();
		}
		System.assert(!blnCheckUserInGroup, 'blnCheckUserInGroup should be false.');
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : validate logged in user in public group for case account specialist change
	 * @Parm        : NA
	 * @Return      : boolean
	 **/
	@isTest
	static void testChangeAccountSpecialistUserInPublicGroup() {
		Boolean blnCheckUserInGroup;
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		List<Case> list_Case = [SELECT Id, Account_Specialist__c FROM Case LIMIT 1];
		List<User> list_UserRecs = new List<User>();
		User objUser = new TestDataFactory.UserBuilder()
			.setAlias('gusst33')
			.setEmail('testuser33@test.com')
			.setFirstName('CreateUser3')
			.setLastName('Test3')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setProfileId(objProfile.Id)
			.setUserName(TestDataFactory.buildUniqueString())
			.build();

		list_UserRecs.add(objUser);

		insert list_UserRecs;

		Group objGroup = [SELECT Id FROM Group WHERE Name = :TAXRES_ACC_SPECIALIST_GROUP_NAME];
		GroupMember objGrpMember = new GroupMember(GroupId = objGroup.Id, UserOrGroupId = objUser.Id);
		insert objGrpMember;

		System.runAs(objUser) {
			Test.startTest();
			blnCheckUserInGroup = TaxResCaseButtons.canUserChangeAccSpecialist();
			Test.stopTest();
		}
		System.assert(blnCheckUserInGroup, 'blnCheckUserInGroup should be true.');
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : validate logged in user not in public group for case account specialist change
	 * @Parm        : NA
	 * @Return      : boolean
	 **/
	@isTest
	static void testChangeAccSpecialistUserNotInPublicGroup() {
		Boolean blnCheckUserInGroup;
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User objUser = new TestDataFactory.UserBuilder()
			.setAlias('gusst55')
			.setEmail('testuser55@test.com')
			.setFirstName('CreateUser5')
			.setLastName('Test5')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setProfileId(objProfile.Id)
			.setUserName(TestDataFactory.buildUniqueString())
			.build();

		insert objUser;

		System.runAs(objUser) {
			Test.startTest();
			blnCheckUserInGroup = TaxResCaseButtons.canUserChangeAccSpecialist();
			Test.stopTest();
		}
		System.assert(!blnCheckUserInGroup, 'blnCheckUserInGroup should be false.');
	}

	/**
	 * @Author      : AKS
	 * @Description : check taxres Tackle View permission
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void tackleViewPermissionTest() {
		Group objTackleboxViewGroup = [SELECT Id FROM Group WHERE DeveloperName = :TAXRES_TACKLEBOXVIEW_GROUP_NAME];
		delete [SELECT Id FROM GroupMember WHERE GroupId = :objTackleboxViewGroup.Id];

		Test.startTest();
		Boolean blnShowLink = TaxResCaseButtons.getMemberToAccessTackleLink();
		System.assert(!blnShowLink, 'blnShowLink should be false.');
		Test.stopTest();
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Check for TaxRes Tacklebox View permission for users
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void tackleViewPermissionUserTest() {
		Group objTackleboxViewGroup = [SELECT Id FROM Group WHERE DeveloperName = :TAXRES_TACKLEBOXVIEW_GROUP_NAME];
		GroupMember objUserMember = new GroupMember();
		objUserMember.UserOrGroupId = UserInfo.getUserId();
		objUserMember.GroupId = objTackleboxViewGroup.Id;
		insert objUserMember;

		Test.startTest();
		Boolean blnShowLink = TaxResCaseButtons.getMemberToAccessTackleLink();
		System.assert(blnShowLink, 'blnShowLink should be true.');
		Test.stopTest();
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Check for TaxRes Tacklebox View permission for roles
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void tackleViewPermissionRoleTest() {
		Group objTackleboxViewGroup = [SELECT Id FROM Group WHERE DeveloperName = :TAXRES_TACKLEBOXVIEW_GROUP_NAME];
		Group objLoggedInUserRole = [SELECT Id FROM Group WHERE Type = 'Role' AND RelatedId = :UserInfo.getUserRoleId()];

		GroupMember objRoleMember = new GroupMember();
		objRoleMember.UserOrGroupId = objLoggedInUserRole.Id;
		objRoleMember.GroupId = objTackleboxViewGroup.Id;
		insert objRoleMember;

		Test.startTest();
		Boolean blnShowLink = TaxResCaseButtons.getMemberToAccessTackleLink();
		System.assert(blnShowLink, 'blnShowLink should be true.');
		Test.stopTest();
	}
}