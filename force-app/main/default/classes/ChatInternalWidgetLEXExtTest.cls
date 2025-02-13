/**
 * @name         : ChatInternalWidgetLEXExtTest
 * @author       : Ankit CS
 * @date         : 06-30-2021
 * @description  : Test class for the ChatInternalWidgetLEXExt class.
 **/
@isTest
public with sharing class ChatInternalWidgetLEXExtTest {
	/**
	 * @Author      : Ankit CS
	 * @Description : TestSetup method
	 **/
	@TestSetup
	public static void testSetup() {
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setTier('Simple').setRecordTypeId('Company').build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setAccountId(objAccount.Id)
			.setFirstName('contactFirst')
			.setLastName('contactLast')
			.setPhone('0000000000')
			.setEmail('test1@test.com')
			.setRecordTypeId('Company')
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setSubject('test subject')
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setStatus('Open')
			.setOrigin('Email')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.build();
		insert objCase;

		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript(LiveChatVisitorId = objLiveChatVisitor.Id, ChatKey = '7868756746', CaseId = objCase.Id);
		insert objLiveChatTranscript;

		User objThisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

		System.runAs(objThisUser) {
			List<Group> list_Groups = [
				SELECT Id, Name
				FROM Group
				WHERE Name IN ('Contractor Payroll Internal Chatters', 'Contractor Full-Stack Internal Chatters', 'Concierge Vendor Payroll Class 1', 'Vendor SME FSC Internal Chat')
			];

			Map<String, Id> map_Groups = new Map<String, Id>();

			for (Group objGroup : list_Groups) {
				map_Groups.put(objGroup.Name, objGroup.Id);
			}

			List<User> list_Users = new List<User>();
			Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
			UserRole objCCRole = [SELECT Id FROM UserRole WHERE Name = 'Core & Complete'];

			//prc contractor
			User objTestUser = new TestDataFactory.UserBuilder()
				.setUserName('chatinternalwidgetprc@gusto.com')
				.setFirstName('')
				.setLastName('chat internal prc')
				.setEmail('chatinternalwidgetprc@gusto.com')
				.setProfileId(objProfile.Id)
				.setUserRoleId(objCCRole.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			list_Users.add(objTestUser);

			//fsc contractor
			objTestUser = new TestDataFactory.UserBuilder()
				.setUserName('chatinternalwidgetfsc@gusto.com')
				.setFirstName('')
				.setLastName('chat internal fsc')
				.setEmail('chatinternalwidgetfsc@gusto.com')
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			list_Users.add(objTestUser);

			//concierge
			objTestUser = new TestDataFactory.UserBuilder()
				.setUserName('chatinternalwidgetconcierge@gusto.com')
				.setFirstName('')
				.setLastName('chat internal concierge')
				.setEmail('chatinternalwidgetconcierge@gusto.com')
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			list_Users.add(objTestUser);

			objTestUser = new TestDataFactory.UserBuilder()
				.setUserName('chatinternalwidgetvendorsme@gusto.com')
				.setFirstName('')
				.setLastName('vendor sme')
				.setEmail('chatinternalwidgetvendorsme@gusto.com')
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			list_Users.add(objTestUser);
			insert list_Users;

			List<GroupMember> list_GroupMembers = new List<GroupMember>();

			for (User objUser : list_Users) {
				GroupMember objGroupMember = new GroupMember();
				if (objUser.Email.contains('prc')) {
					objGroupMember = new GroupMember(GroupId = map_Groups.get('Contractor Payroll Internal Chatters'), UserOrGroupId = objUser.Id);
				} else if (objUser.Email.contains('fsc')) {
					objGroupMember = new GroupMember(GroupId = map_Groups.get('Contractor Full-Stack Internal Chatters'), UserOrGroupId = objUser.Id);
				} else if (objUser.Email.contains('concierge')) {
					objGroupMember = new GroupMember(GroupId = map_Groups.get('Concierge Vendor Payroll Class 1'), UserOrGroupId = objUser.Id);
				} else if (objUser.Email.contains('vendorsme')) {
					objGroupMember = new GroupMember(GroupId = map_Groups.get('Vendor SME FSC Internal Chat'), UserOrGroupId = objUser.Id);
				}

				list_GroupMembers.add(objGroupMember);
			}

			insert list_GroupMembers;
		}
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for queryCaseInfo()
	 **/
	@isTest
	public static void testQueryCase1() {
		Test.startTest();

		Case objCase = [SELECT Id FROM Case LIMIT 1];
		LiveChatTranscript objLiveChatTranscript = [SELECT Id, CaseId FROM LiveChatTranscript WHERE CaseId = :objCase.Id];
		ApexPages.StandardController objController = new ApexPages.StandardController(objCase);
		ChatInternalWidgetLEXExt objInstance = new ChatInternalWidgetLEXExt(objController);
		ChatInternalWidgetLEXExt.InternalChatWrapper objWrapper = new ChatInternalWidgetLEXExt.InternalChatWrapper();
		objWrapper = ChatInternalWidgetLEXExt.queryCaseInfo(objLiveChatTranscript.Id);
		System.assertEquals(objWrapper.objLiveChatTranscript.CaseId, objCase.Id, 'Incorrect Result');
		System.assertEquals(objWrapper.objCutoffTime.Case_Origin__c, 'Email', 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for getCaseInfoById()
	 **/
	@isTest
	public static void testQueryCase2() {
		Test.startTest();

		Case objCase = [SELECT Id FROM Case LIMIT 1];
		ApexPages.StandardController objController = new ApexPages.StandardController(objCase);
		ChatInternalWidgetLEXExt objInstance = new ChatInternalWidgetLEXExt(objController);
		ChatInternalWidgetLEXExt.InternalChatWrapper objWrapper = new ChatInternalWidgetLEXExt.InternalChatWrapper();
		objWrapper = ChatInternalWidgetLEXExt.getCaseInfoById(objCase.Id);
		System.assertEquals(objWrapper.objCase.Origin, 'Email', 'Incorrect Result');
		System.assertEquals(objWrapper.objCutoffTime.Case_Origin__c, 'Email', 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for queryCutOffTimeMetadata()
	 **/
	@isTest
	public static void testQueryCutOffTimeMetadata() {
		Test.startTest();

		List<Internal_Chat_Cut_off_Time__mdt> list_Metadata = ChatInternalWidgetLEXExt.queryCutOffTimeMetadata('Email');
		System.assert(!list_Metadata.isEmpty(), 'List should not be empty');
		System.assertEquals(list_Metadata[0].Case_Origin__c, 'Email', 'List should not be empty');
		System.assert(list_Metadata[0].IsActive__c, 'List should not be empty');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Generating test records for Internal_Chat_Cut_off_Time__mdt metadata
	 **/
	public static List<Internal_Chat_Cut_off_Time__mdt> initializeCutoffTimeMetadata(String strOrigin) {
		return new List<Internal_Chat_Cut_off_Time__mdt>{
			new Internal_Chat_Cut_off_Time__mdt(
				DeveloperName = 'Test Cutoff Time',
				Case_Origin__c = strOrigin,
				Cut_off_Time__c = '16:30',
				Message__c = 'You are starting a chat after businsess hours.',
				IsActive__c = true
			)
		};
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : test createSessionCache()
	 */
	@isTest
	public static void testCreateSessionCache() {
		String strResult = ChatInternalWidgetLEXExt.createSessionCache('my question', 'strTabId');
		System.assertEquals('Success', strResult, 'Incorrect Result');
	}

	/**
	 * @author : Alex Xiong
	 * @description : test queue filters
	 */
	@isTest
	public static void testQueueFilters() {
		Test.startTest();
		List<User> list_User = [SELECT Id, Email FROM User WHERE Email LIKE 'chatinternalwidget%'];

		for (User objUser : list_User) {
			ChatInternalWidgetLEXExt.InternalChatWrapper objWrapper = new ChatInternalWidgetLEXExt.InternalChatWrapper();
			ChatInternalWidgetLEXExt.checkQueuesForUser(objUser.Id, objWrapper);

			if (objUser.Email.contains('prc')) {
				System.assert(objWrapper.blnIsPRCContractor, 'Incorrect Result');
			} else if (objUser.Email.contains('fsc')) {
				System.assert(objWrapper.blnIsFSCContractor, 'Incorrect Result');
			} else if (objUser.Email.contains('vendorsme')) {
				System.assert(objWrapper.blnIsVendorSME, 'Incorrect Result');
			}
		}

		Test.stopTest();
	}
}