@isTest
private class ManageCaseTeamCaseExtensionTest {
	static ManageCaseTeamCaseExtension extension;

	@testSetup
	static void setUp() {
		CaseTeamRole ctr = [SELECT Id, Name FROM CaseTeamRole WHERE Name = 'Customer Contact' LIMIT 1];

		Account objAccount = new TestDataFactory.AccountBuilder()
			 .setName('Test Company')
			 .setRecordTypeId('Company')
			 .build();

		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('Test')
			.setEmail('test@test.com')
			.setPhone('123456')
			.build();

		insert objContact;

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test2')
			.setLastName('Test')
			.setPhone('123456')
			.build();
		
		insert objContact2;

		Case c = new Case();
		c.ContactId = objContact.Id;
		c.Direction__c = 'Inbound';
		c.Status = 'Open';
		c.Origin = 'Phone';
		c.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res');
		insert c;

		CaseTeamMember member = new CaseTeamMember();
		member.MemberId = objContact.id;
		member.ParentId = c.id;
		member.TeamRoleId = ctr.Id;
		insert member;
	}

	@isTest
	static void setCaseTeamTest() {
		test.startTest();
		List<Case> caseList = [SELECT Id FROM Case];
		setupTestRun(caseList[0]);
		System.assertNotEquals(null, extension.caseTeamList);
		System.assertEquals(1, extension.caseTeamList.size());
		extension.theContact.email = 'test@test.com';
		extension.theContact.LastName = 'Test Last';
		PageReference pageRef = extension.saveContact();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assertEquals(null, pageRef);
		System.assertEquals(1, pageMessages.size());
		test.stopTest();
	}

	@isTest
	static void setCaseTeamMemberTest() {
		test.startTest();
		List<Case> caseList = [SELECT Id FROM Case];
		setupTestRun(caseList[0]);
		System.assertNotEquals(null, extension.caseTeamList);
		System.assertEquals(1, extension.caseTeamList.size());
		extension.theContact.email = 'test1@test.com';
		extension.theContact.LastName = 'Test Last';
		PageReference pageRef = extension.saveContact();
		System.assertEquals(2, extension.caseTeamList.size());
		test.stopTest();
	}

	@isTest
	static void addandDeleteMemberTest() {
		test.startTest();
		List<Case> caseList = [SELECT Id FROM Case];
		Contact contact = [SELECT Id FROM Contact WHERE FirstName = 'Test2' LIMIT 1];
		setupTestRun(caseList[0]);
		System.assertNotEquals(null, extension.caseTeamList);
		System.assertEquals(1, extension.caseTeamList.size());
		extension.theMember.MemberId = contact.id;
		PageReference pageRef = extension.addMember();
		System.assertEquals(2, extension.caseTeamList.size());
		extension.memberId = extension.caseTeamList[0].id;
		extension.deleteCaseTeamMember();
		test.stopTest();
	}

	static void setupTestRun(Case cse) {
		ApexPages.StandardController stdController = new ApexPages.StandardController(cse);
		extension = new ManageCaseTeamCaseExtension(stdController);
		System.assertNotEquals(null, extension);
	}
}