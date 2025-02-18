@isTest
public class TestLiveChatTranscriptTriggerHelper {
	@isTest
	public static void testMethod2() {
		List<BusinessHours> bhs = [SELECT id FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement'];
		System.assertEquals(1, bhs.size(), 'There should be 1 BusinessHour record.');

		Account acc = new Account(name = 'Test');
		insert acc;

		contact con = new contact();
		con.accountId = acc.id;
		con.LastName = 'Full';
		insert con;

		Case cs = new Case(subject = 'Test Case', origin = 'Web', status = 'test', contactId = con.id, accountId = acc.id);

		insert cs;

		LiveChatVisitor visitor = new LiveChatVisitor();
		insert visitor;

		Test.startTest();

		LiveChatTranscript tx = new LiveChatTranscript(
			chatKey = '53454364',
			liveChatVisitorId = visitor.id,
			caseId = cs.Id,
			DIVR_Id__c = '2606f4a3-d2a6-44d9-8bf9-18de3ce97b25',
			RecordTypeId = Cache.getRecordTypeId('LiveChatTranscript', 'External')
		);

		insert tx;

		PresenceUserConfig puc = [SELECT Id FROM PresenceUserConfig WHERE DeveloperName = 'CX_Internal_Chat' LIMIT 1];
		ServicePresenceStatus sps = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'Available_Chat' LIMIT 1];

		Case_Audit_Log__c caseAuditLogObj = new Case_Audit_Log__c();
		caseAuditLogObj.Event_Type__c = 'Chat';
		caseAuditLogObj.Case__c = cs.Id;
		insert caseAuditLogObj;

		caseAuditLogObj.Event_Type__c = 'Email';
		update caseAuditLogObj;

		ID SChannelId = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'sfdc_liveagent' LIMIT 1].Id;

		User user1 = new User();
		user1.id = UserInfo.getUserId();
		try {
			System.runAs(user1) {
				AgentWork awObj = new AgentWork(WorkItemId = tx.Id, ServiceChannelId = SChannelId, UserId = user1.id);
				insert awObj;
			}
		} catch (Exception e) {
			ExceptionLogUtil.logException('TestLiveChatTranscriptTriggerHelper', 'testMethod2', e.getMessage(), e.getStackTraceString());
		}

		tx.Body = '<p align="center">Agent Alex</p>( 12s ) Alex: Thanks for reaching out to Gusto, how can we assist you today?<br>( 19s ) {CUSTOMER FIRSTNAME}: hi<br>( 23s ) Alex: yo<br>( 29s ) {CUSTOMER FIRSTNAME}: waiting<br>( 33s ) Alex: yeah<br>( 1h 1m 50s ) {CUSTOMER FIRSTNAME}: ';
		tx.Status = 'Completed';
		update tx;
		LiveChatTranscript l = [SELECT Chat_Duration_parsed__c FROM LiveChatTranscript];

		tx.Status = 'Missed';
		update tx;
		System.assertNotEquals(0, l.Chat_Duration_parsed__c, 'Chat Duration Period should not be 0.');
		Test.stopTest();
	}

	@isTest
	public static void testMethod3() {
		List<BusinessHours> bhs = [SELECT id FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement'];
		System.assertEquals(1, bhs.size(), 'There should be 1 BusinessHour record.');

		Account acc = new Account(name = 'Test');
		insert acc;

		contact con = new contact();
		con.accountId = acc.id;
		con.LastName = 'Full';
		insert con;

		Case cs = new Case(subject = 'Test Case', origin = 'Web', status = 'test', contactId = con.id, accountId = acc.id);

		insert cs;

		LiveChatVisitor visitor = new LiveChatVisitor();
		insert visitor;

		LiveChatTranscript tx = new LiveChatTranscript(
			chatKey = '2323434',
			liveChatVisitorId = visitor.id,
			caseId = cs.Id,
			DIVR_Id__c = '2606f4a3-d2a6-44d9-8bf9-18de3ce97b25',
			RecordTypeId = Cache.getRecordTypeId('LiveChatTranscript', 'External')
		);

		insert tx;

		Test.startTest();
		LiveChatTranscript l = [SELECT Chat_Duration_parsed__c FROM LiveChatTranscript];

		PresenceUserConfig puc = [SELECT Id FROM PresenceUserConfig WHERE DeveloperName = 'CX_Internal_Chat' LIMIT 1];
		ServicePresenceStatus sps = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'Available_Chat' LIMIT 1];

		Case_Audit_Log__c caseAuditLogObj = new Case_Audit_Log__c();
		caseAuditLogObj.Event_Type__c = 'Chat';
		caseAuditLogObj.Case__c = cs.Id;
		insert caseAuditLogObj;

		caseAuditLogObj.Event_Type__c = 'Email';
		update caseAuditLogObj;

		ID SChannelId = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'sfdc_liveagent' LIMIT 1].Id;

		User user1 = new User();
		user1.id = UserInfo.getUserId();
		try {
			System.runAs(user1) {
				AgentWork awObj = new AgentWork(WorkItemId = l.Id, ServiceChannelId = SChannelId, UserId = user1.id);
				insert awObj;
			}
		} catch (Exception e) {
			ExceptionLogUtil.logException('TestLiveChatTranscriptTriggerHelper', 'testMethod3', e.getMessage(), e.getStackTraceString());
		}

		l.Body = '<p align="center">Agent Alex</p>( 12s ) Alex: Thanks for reaching out to Gusto, how can we assist you today?<br>( 19s ) {CUSTOMER FIRSTNAME}: hi<br>( 23s ) Alex: yo<br>( 29s ) {CUSTOMER FIRSTNAME}: waiting<br>( 33s ) Alex: yeah<br>( 1h 1m 50s ) {CUSTOMER FIRSTNAME}: ';
		l.Status = 'Missed';
		LiveChatTranscriptTriggerHelper.boolTestThis = true;
		update l;

		System.assertNotEquals(0, l.Chat_Duration_parsed__c, 'Chat Duration Period should not be 0.');
		Test.stopTest();
	}

	/**
	 * @author Lalitha Kasturi
	 * @description test coverage for ChatTranscript
	 */

	@testSetup
	static void setUp() {
		// create company account

		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;

		// Creating Company Account
		Account objAccnt = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account 1')
			.setZPCompanyId('1111111111')
			.setNumberOfActiveEEs(80)
			.build();
		insert objAccnt;

		// Creating Company Account
		Account objAccnt1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company \'s 2').setZPCompanyId('1111111112').build();
		insert objAccnt1;

		// Creating Company Contact
		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setFirstName('Test First\' Name1')
			.setLastName('Test Last\' Name1')
			.setEmail('newmember1@campaign.com')
			.setNormalizedPhone('1876543211')
			.setZPUserRole('Payroll Admin')
			.build();
		insert objContact1;

		// Creating Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccnt.Id)
			.setFirstName('Test First Name1')
			.setLastName('Test Last Name1')
			.setEmail('newmember@campaign.com')
			.setNormalizedPhone('9876543211')
			.setPhone('9876543211')
			.build();
		insert objContact;

		// Creating Company Lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('leadcampaign@member.com')
			.setPhone('123456789')
			.setCompany('Company Lead 1')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('LinkedIn')
			.build();
		insert objLead;

		// Creating Company Lead
		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('FName \' Special')
			.setLastName('LName \' Special')
			.setEmail('leadcampaign@member1.com')
			.setPhone('123456789')
			.setCompany('Company \'s Lead 1')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('LinkedIn')
			.build();
		insert objLead1;

		//create opportunity
		TriggerHandler.bypass('OpportunityTriggerHandler');
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('Test Opp')
			.setAccountId(objAccnt.Id)
			.setStage('Open')
			.setCloseDate(System.today())
			.build();

		objOpportunity.ZP_Company_ID__c = '1111111111';
		objOpportunity.Offers_Health_Insurance__c = 'Yes';
		insert objOpportunity;

		List<Case_Pillar_Mapping__c> list_CasePillarMappings = new List<Case_Pillar_Mapping__c>();
		Case_Pillar_Mapping__c objMapping = new TestDataFactory.CasePillarMappingBuilder()
			.setName('CPM001')
			.setType('Payroll')
			.setSupportLevel('Tier 1')
			.setCompanySize('Standard 5-24')
			.setPersona('Admin')
			.setPillar('Test Pillar')
			.setSubPillar('Test Sub Pillar')
			.setCaseOrigin('Chat')
			.setWFMQueueTag('Test WFM Queue Tag')
			.setPillarKey('P-001')
			.setSubPillarKey('SP-001')
			.build();
		list_CasePillarMappings.add(objMapping);

		Case_Pillar_Mapping__c objMapping2 = new TestDataFactory.CasePillarMappingBuilder()
			.setName('CPM002')
			.setType('Payroll')
			.setSupportLevel('Tier 1')
			.setCompanySize('Standard 5-24')
			.setPersona('Accountant')
			.setPillar('Test Pillar')
			.setSubPillar('Test Sub Pillar')
			.setCaseOrigin('Chat')
			.setWFMQueueTag('Test WFM Queue Tag')
			.setPillarKey('P-001')
			.setSubPillarKey('SP-001')
			.build();
		list_CasePillarMappings.add(objMapping2);

		Case_Pillar_Mapping__c objMapping3 = new TestDataFactory.CasePillarMappingBuilder()
			.setName('CPM003')
			.setPillar('Cancel Pillar')
			.setSubPillar('Cancel Sub Pillar')
			.setCaseOrigin('Chat')
			.setWFMQueueTag('Cancel WFM Queue')
			.setPillarKey('P-003')
			.setSubPillarKey('SP-003')
			.setSpecialization('Cancel')
			.build();
		list_CasePillarMappings.add(objMapping3);
		
		insert list_CasePillarMappings;

		List<Case_Reason_Classification__c> list_CaseReasons = new List<Case_Reason_Classification__c>();
		Case_Reason_Classification__c objCaseReason1 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test case reason')
			.setIsActive(true)
			.setReasonCode('zp_giving_or_charity')
			.setCaseTypePillar(CaseUtils.PAYROLL_CASE_PILLAR)
			.setType('Engagement')
			.setRoutingTeam('Internal')
			.setSupportLevel(CaseUtils.TIER_1)
			.build();
		list_CaseReasons.add(objCaseReason1);

		insert list_CaseReasons;
	}

	@isTest
	public static void checkChatTranscriptOpportunityID() {
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setCompanyId('1111111111')
			.setCompanyUUID('e512de89-9639-474b-aebf-0cf26b3075ea')
			.setVisitorEmailAddress('newmember@campaign.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.build();

		insert objLiveChat;

		LiveChatTranscript objLiveChatassert = [SELECT Id, Opportunity__c FROM LiveChatTranscript WHERE Id = :objLiveChat.Id];
		System.assert(objLiveChatassert.Opportunity__c != null, 'OpportunityID has not been populated');
	}

	@isTest
	public static void checkChatTranscriptLeadID() {
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.build();

		insert objLiveChat;

		LiveChatTranscript objLiveChatassert = [SELECT Id, LeadId, AccountId, ContactId FROM LiveChatTranscript WHERE Id = :objLiveChat.Id];
		System.assert(objLiveChatassert.LeadId != null, 'LeadID has not been populated');
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test  LeadSource update if value is null for Lead created with LiveChatTranscript.
	 **/
	@isTest
	static void testLiveChatLeadSourceUpdatePositive() {
		User objUser = [SELECT Id, Name FROM User WHERE Name = :LeadUtil.PLATFORM_INTEGRATION_USER LIMIT 1];
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setPhone('9876424575')
			.setCompany('Xero Partner')
			.setStatus('New')
			.setLeadSource('Sourcing Error')
			.build();

		System.runAs(objUser) {
			LeadTriggerHelper.skiptrigger = true;
			insert objLead;
			LeadTriggerHelper.skiptrigger = false;
		}

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.setLeadSource('Live Chat')
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		// assert if lead source is updated to live Chat
		Lead objLeadAssert = [SELECT Id, LeadSource, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(objLiveChat.Lead_Source__c, objLeadAssert.LeadSource, 'Lead Source is not equal to Chat Transcript value');
		Test.stopTest();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test LeadSource does not update if prior value is present for Leads created with LiveChatTranscript.
	 **/
	@isTest
	static void testLiveChatLeadSourceUpdateNegative() {
		User objUser = [SELECT Id, Name FROM User WHERE Name = :LeadUtil.PLATFORM_INTEGRATION_USER LIMIT 1];
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setPhone('9876424575')
			.setCompany('Xero Partner')
			.setStatus('New')
			.setLeadSource('Web')
			.build();

		System.runAs(objUser) {
			LeadTriggerHelper.skiptrigger = true;
			insert objLead;
			LeadTriggerHelper.skiptrigger = false;
		}

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.setLeadSource('Live Chat')
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		// assert if lead source is updated to live Chat
		Lead objLeadAssert = [SELECT Id, LeadSource, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(objLiveChat.Lead_Source__c, objLeadAssert.LeadSource, 'Lead Source is being over written with Chat Transcript value');
		Test.stopTest();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Phone field is updatde for Leads created with LiveChatTranscript if Phone was blank.
	 **/
	@isTest
	static void testLiveChatPhoneUpdatePositive() {
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setCompany('Xero Partner')
			.setStatus('New')
			.build();
		insert objLead;

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.setPhone('9987655434')
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		// assert if lead phone is updated with phone value from live Chat if phone is blank on Lead
		Lead objLeadAssert = [SELECT Id, Phone, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(objLiveChat.Phone__c, objLeadAssert.Phone, 'Lead Phone is not equal to Live Chat Phone');
		Test.stopTest();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test AlternatePhone is updated for Leads created with LiveChatTranscript if Phone has a different value
	 **/
	@isTest
	static void testLiveChatAlternatePhoneUpdate() {
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setPhone('9876424575')
			.setCompany('Xero Partner')
			.setStatus('New')
			.build();
		insert objLead;

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.setPhone('9987655434')
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		// assert if lead phone is not updated and alternalte phone is updated with phone value from live Chat if its different from existing phone value
		Lead objLeadAssert = [SELECT Id, Phone, Alternate_Phone__c, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(objLiveChat.Phone__c, objLeadAssert.Phone, 'Lead Phone is getting overwritten with Live Chat Phone');
		System.assertEquals(objLiveChat.Phone__c, objLeadAssert.Alternate_Phone__c, 'Lead Alternate Phone is not equal to Live Chat Phone');
		Test.stopTest();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test AlternatePhone does not get updated for Leads created with LiveChatTranscript if Phone value on chat is same as value on Lead
	 **/
	@isTest
	static void testLiveChatPhoneUpdateNegative() {
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setPhone('9876424575')
			.setCompany('Xero Partner')
			.setStatus('New')
			.build();
		insert objLead;

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.setPhone('9876424575')
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		// assert if lead alternate phone does not get updated if phone value is same
		Lead objLeadAssert = [SELECT Id, Phone, Alternate_Phone__c, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(objLiveChat.Phone__c, objLeadAssert.Alternate_Phone__c, 'Lead Alternate Phone is getting updated with Live Chat Phone');
		Test.stopTest();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Attribution fields get updated on Lead if the fields were blank earlier.
	 **/
	@isTest
	static void testLiveChatAttributionFieldsUpdateGCorpV2Positive() {
		User objUser = [SELECT Id, Name FROM User WHERE Name = :LeadUtil.PLATFORM_INTEGRATION_USER LIMIT 1];
		LiveChatButton objChatButton = [SELECT Id, MasterLabel, DeveloperName FROM LiveChatButton WHERE MasterLabel = 'GCorpV2' LIMIT 1];

		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setPhone('9876424575')
			.setCompany('Test')
			.setStatus('New')
			.setLeadSource('Sourcing Error')
			.build();

		System.runAs(objUser) {
			LeadTriggerHelper.skiptrigger = true;
			insert objLead;
			LeadTriggerHelper.skiptrigger = false;
		}

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.setZPLeadCampaign('New Lead Campaign')
			.setUTMMedium('New UTM Medium')
			.setUTMContent('New UTM Content')
			.setPlacement('New Placement')
			.setNetwork('New Network')
			.setMatchType('New Match Type')
			.setKeyword('New Keyword')
			.setGclid('New GCLID')
			.setDevice('New Device')
			.setCreative('New Device')
			.setMsclkid('New MSCLKID')
			.setLandingPage('New Landing Page')
			.setAdGroup('New Ad Group')
			.setVisitorId('23456')
			.setSessionId('45678')
			.setLastFormFillUrl('New Last Form Fill URL')
			.setLeadCreationOffer('New Lead Creation Offer')
			.setRecentCampaign('New Recent Campaign')
			.setRecentContent('New Recent Content')
			.setRecentSource('New Recent Source')
			.setUrlOfConversion('New URL of Conversion')
			.setReferringUrl('New Referring URL')
			.setChatButtonId(objChatButton.Id)
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		// assert that lead fields get updated with live Chat transcript values
		Lead objLeadAssert = [
			SELECT
				Id,
				ZP_Lead_Campaign__c,
				Trk_UTM_Medium__c,
				Trk_UTM_Content__c,
				Trk_Placement__c,
				Trk_network__c,
				Trk_matchtype__c,
				Trk_Keyword__c,
				Trk_gclid__c,
				Trk_Device__c,
				Trk_creative__c,
				msclkid__c,
				Landing_Page__c,
				adgroup__c,
				Visitor_Id__c,
				Session_Id__c,
				Last_Form_Fill_URL__c,
				Lead_Creation_Offer__c,
				Recent_Campaign__c,
				Recent_Content__c,
				Recent_Source__c,
				URL_of_Conversion__c,
				Referring_Url__c,
				MQL_Reason__c
			FROM Lead
			WHERE Id = :objLead.Id
		];
		System.assertEquals(objLiveChat.ZP_Lead_Campaign__c, objLeadAssert.ZP_Lead_Campaign__c, 'Lead ZP_Lead_Campaign__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_UTM_Medium__c, objLeadAssert.Trk_UTM_Medium__c, 'Lead Trk_UTM_Medium__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_UTM_Content__c, objLeadAssert.Trk_UTM_Content__c, 'Lead Trk_UTM_Content__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_Placement__c, objLeadAssert.Trk_Placement__c, 'Lead Trk_Placement__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_network__c, objLeadAssert.Trk_network__c, 'Lead Trk_network__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_matchtype__c, objLeadAssert.Trk_matchtype__c, 'Lead Trk_matchtype__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_Keyword__c, objLeadAssert.Trk_Keyword__c, 'Lead Trk_Keyword__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_gclid__c, objLeadAssert.Trk_gclid__c, 'Lead Trk_gclid__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_Device__c, objLeadAssert.Trk_Device__c, 'Lead Trk_Device__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_creative__c, objLeadAssert.Trk_creative__c, 'Lead Trk_creative__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.msclkid__c, objLeadAssert.msclkid__c, 'Lead msclkid__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.adgroup__c, objLeadAssert.adgroup__c, 'Lead adgroup__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Visitor_Id__c, objLeadAssert.Visitor_Id__c, 'Lead Visitor_Id__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Session_Id__c, objLeadAssert.Session_Id__c, 'Lead Session_Id__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Last_Form_Fill_URL__c, objLeadAssert.Last_Form_Fill_URL__c, 'Lead Last_Form_Fill_URL__c data is not equal to Live Chat Transcript data');
		System.assertEquals(LeadUtil.LEADSOURCE_LIVE_CHAT, objLeadAssert.Lead_Creation_Offer__c, 'Lead Lead_Creation_Offer__c data is not equal to Live Chat');
		System.assertEquals(objLiveChat.Recent_Campaign__c, objLeadAssert.Recent_Campaign__c, 'Lead Recent_Campaign__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Recent_Content__c, objLeadAssert.Recent_Content__c, 'Lead Recent_Content__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Recent_Source__c, objLeadAssert.Recent_Source__c, 'Lead Recent_Source__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.URL_of_Conversion__c, objLeadAssert.URL_of_Conversion__c, 'Lead URL_of_Conversion__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Referring_Url__c, objLeadAssert.Referring_Url__c, 'Lead Referring_Url__c data is not equal to Live Chat Transcript data');
		System.assertEquals(LeadUtil.MQL_REASON_IB_CHAT, objLeadAssert.MQL_Reason__c, 'Lead MQL_Reason__c data is not equal to Inbound Chat');

		Test.stopTest();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Attribution fields get updated on Lead if the fields were blank earlier.
	 **/
	@isTest
	static void testLiveChatAttributionFieldsUpdateGCorpPricingPositive() {
		User objUser = [SELECT Id, Name FROM User WHERE Name = :LeadUtil.PLATFORM_INTEGRATION_USER LIMIT 1];
		LiveChatButton objChatButton = [SELECT Id, MasterLabel, DeveloperName FROM LiveChatButton WHERE MasterLabel = 'GCorpPricing' LIMIT 1];

		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setPhone('9876424575')
			.setCompany('Xero Partner')
			.setStatus('New')
			.setLeadSource('Sourcing Error')
			.build();

		System.runAs(objUser) {
			LeadTriggerHelper.skiptrigger = true;
			insert objLead;
			LeadTriggerHelper.skiptrigger = false;
		}

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.setZPLeadCampaign('New Lead Campaign')
			.setUTMMedium('New UTM Medium')
			.setUTMContent('New UTM Content')
			.setPlacement('New Placement')
			.setNetwork('New Network')
			.setMatchType('New Match Type')
			.setKeyword('New Keyword')
			.setGclid('New GCLID')
			.setDevice('New Device')
			.setCreative('New Device')
			.setMsclkid('New MSCLKID')
			.setLandingPage('New Landing Page')
			.setAdGroup('New Ad Group')
			.setVisitorId('23456')
			.setSessionId('45678')
			.setLastFormFillUrl('New Last Form Fill URL')
			.setLeadCreationOffer('New Lead Creation Offer')
			.setRecentCampaign('New Recent Campaign')
			.setRecentContent('New Recent Content')
			.setRecentSource('New Recent Source')
			.setUrlOfConversion('New URL of Conversion')
			.setReferringUrl('New Referring URL')
			.setChatButtonId(objChatButton.Id)
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		// assert that lead fields get updated with live Chat transcript values
		Lead objLeadAssert = [
			SELECT
				Id,
				ZP_Lead_Campaign__c,
				Trk_UTM_Medium__c,
				Trk_UTM_Content__c,
				Trk_Placement__c,
				Trk_network__c,
				Trk_matchtype__c,
				Trk_Keyword__c,
				Trk_gclid__c,
				Trk_Device__c,
				Trk_creative__c,
				msclkid__c,
				Landing_Page__c,
				adgroup__c,
				Visitor_Id__c,
				Session_Id__c,
				Last_Form_Fill_URL__c,
				Lead_Creation_Offer__c,
				Recent_Campaign__c,
				Recent_Content__c,
				Recent_Source__c,
				URL_of_Conversion__c,
				Referring_Url__c,
				MQL_Reason__c
			FROM Lead
			WHERE Id = :objLead.Id
		];
		System.assertEquals(objLiveChat.ZP_Lead_Campaign__c, objLeadAssert.ZP_Lead_Campaign__c, 'Lead ZP_Lead_Campaign__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_UTM_Medium__c, objLeadAssert.Trk_UTM_Medium__c, 'Lead Trk_UTM_Medium__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_UTM_Content__c, objLeadAssert.Trk_UTM_Content__c, 'Lead Trk_UTM_Content__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_Placement__c, objLeadAssert.Trk_Placement__c, 'Lead Trk_Placement__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_network__c, objLeadAssert.Trk_network__c, 'Lead Trk_network__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_matchtype__c, objLeadAssert.Trk_matchtype__c, 'Lead Trk_matchtype__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_Keyword__c, objLeadAssert.Trk_Keyword__c, 'Lead Trk_Keyword__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_gclid__c, objLeadAssert.Trk_gclid__c, 'Lead Trk_gclid__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_Device__c, objLeadAssert.Trk_Device__c, 'Lead Trk_Device__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Trk_creative__c, objLeadAssert.Trk_creative__c, 'Lead Trk_creative__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.msclkid__c, objLeadAssert.msclkid__c, 'Lead msclkid__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.adgroup__c, objLeadAssert.adgroup__c, 'Lead adgroup__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Visitor_Id__c, objLeadAssert.Visitor_Id__c, 'Lead Visitor_Id__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Session_Id__c, objLeadAssert.Session_Id__c, 'Lead Session_Id__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Last_Form_Fill_URL__c, objLeadAssert.Last_Form_Fill_URL__c, 'Lead Last_Form_Fill_URL__c data is not equal to Live Chat Transcript data');
		System.assertEquals(LeadUtil.LEADCREATION_OFFER_PROACTIVE_CHAT, objLeadAssert.Lead_Creation_Offer__c, 'Lead Lead_Creation_Offer__c data is not equal to Live Chat');
		System.assertEquals(objLiveChat.Recent_Campaign__c, objLeadAssert.Recent_Campaign__c, 'Lead Recent_Campaign__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Recent_Content__c, objLeadAssert.Recent_Content__c, 'Lead Recent_Content__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Recent_Source__c, objLeadAssert.Recent_Source__c, 'Lead Recent_Source__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.URL_of_Conversion__c, objLeadAssert.URL_of_Conversion__c, 'Lead URL_of_Conversion__c data is not equal to Live Chat Transcript data');
		System.assertEquals(objLiveChat.Referring_Url__c, objLeadAssert.Referring_Url__c, 'Lead Referring_Url__c data is not equal to Live Chat Transcript data');
		System.assertEquals(LeadUtil.MQL_REASON_IB_CHAT, objLeadAssert.MQL_Reason__c, 'Lead MQL_Reason__c data is not equal to Inbound Chat');

		Test.stopTest();
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description Test Attribution fields do not get updated if the fields had previous value.
	 **/
	@isTest
	static void testLiveChatAttributionFieldsUpdateNegative() {
		User objUser = [SELECT Id, Name FROM User WHERE Name = :LeadUtil.PLATFORM_INTEGRATION_USER LIMIT 1];
		LiveChatVisitor objChatVisitor = new LiveChatVisitor();
		insert objChatVisitor;

		Test.startTest();
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('testingSource@gusto.com')
			.setPhone('9876424575')
			.setCompany('Xero Partner')
			.setStatus('New')
			.setZPLeadCampaign('Test initial Lead Campaign')
			.setUTMMedium('Test initial UTM Campaign')
			.setUTMContent('Test initial UTM Content')
			.setPlacement('Test initial Placement')
			.setNetwork('Test initial Network')
			.setMatchType('Test initial Match Type')
			.setKeyword('Test initial Keyword')
			.setGclid('Test initial GCLID')
			.setDevice('Test initial Device')
			.setCreative('Test initial Creative')
			.setMsclkid('Test initial MSCLKID')
			.setLandingPage('Test initial Landing Page')
			.setAdGroup('Test initisl ADGroup')
			.setVisitorId('12345')
			.setSessionId('67890')
			.setLastFormFillUrl('Test initial Last Form Fill URL')
			.setLeadCreationOffer('Test initial Lead Creation Offer')
			.setRecentCampaign('Test initial Recent Campaign')
			.setRecentContent('Test initial Recent Content')
			.setRecentSource('Test initial Recent Source')
			.setUrlOfConversion('Test initial URL of Conversion')
			.setReferringUrl('Test Referring URL')
			.setMQLReason('SAL')
			.setLeadSource('Sourcing Error')
			.build();

		System.runAs(objUser) {
			LeadTriggerHelper.skiptrigger = true;
			insert objLead;
			LeadTriggerHelper.skiptrigger = false;
		}

		LiveChatTranscript objLiveChat = new TestDataFactory.LiveChatTranscriptBuilder()
			.setVisitorEmailAddress('leadcampaign@member1.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('Internal')
			.setQuestion('Test')
			.setChatVisitor(objChatVisitor.Id)
			.setLeadId(objLead.Id)
			.setZPLeadCampaign('New Lead Campaign')
			.setUTMMedium('New UTM Medium')
			.setUTMContent('New UTM Content')
			.setPlacement('New Placement')
			.setNetwork('New Network')
			.setMatchType('New Match Type')
			.setKeyword('New Keyword')
			.setGclid('New GCLID')
			.setDevice('New Device')
			.setCreative('New Device')
			.setMsclkid('New MSCLKID')
			.setLandingPage('New Landing Page')
			.setAdGroup('New Ad Group')
			.setVisitorId('23456')
			.setSessionId('45678')
			.setLastFormFillUrl('New Last Form Fill URL')
			.setLeadCreationOffer('New Lead Creation Offer')
			.setRecentCampaign('New Recent Campaign')
			.setRecentContent('New Recent Content')
			.setRecentSource('New Recent Source')
			.setUrlOfConversion('New URL of Conversion')
			.setReferringUrl('New Referring URL')
			.build();

		insert objLiveChat;
		objLiveChat.LeadId = objLead.Id;
		update objLiveChat;

		// assert that lead fields do not get updated with live Chat transcript values if they have a value
		Lead objLeadAssert = [
			SELECT
				Id,
				ZP_Lead_Campaign__c,
				Trk_UTM_Medium__c,
				Trk_UTM_Content__c,
				Trk_Placement__c,
				Trk_network__c,
				Trk_matchtype__c,
				Trk_Keyword__c,
				Trk_gclid__c,
				Trk_Device__c,
				Trk_creative__c,
				msclkid__c,
				Landing_Page__c,
				adgroup__c,
				Visitor_Id__c,
				Session_Id__c,
				Last_Form_Fill_URL__c,
				Lead_Creation_Offer__c,
				Recent_Campaign__c,
				Recent_Content__c,
				Recent_Source__c,
				URL_of_Conversion__c,
				Referring_Url__c,
				MQL_Reason__c
			FROM Lead
			WHERE Id = :objLead.Id
		];
		System.assertNotEquals(objLiveChat.ZP_Lead_Campaign__c, objLeadAssert.ZP_Lead_Campaign__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_UTM_Medium__c, objLeadAssert.Trk_UTM_Medium__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_UTM_Content__c, objLeadAssert.Trk_UTM_Content__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_Placement__c, objLeadAssert.Trk_Placement__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_network__c, objLeadAssert.Trk_network__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_matchtype__c, objLeadAssert.Trk_matchtype__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_Keyword__c, objLeadAssert.Trk_Keyword__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_gclid__c, objLeadAssert.Trk_gclid__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_Device__c, objLeadAssert.Trk_Device__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Trk_creative__c, objLeadAssert.Trk_creative__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.msclkid__c, objLeadAssert.msclkid__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Landing_Page__c, objLeadAssert.Landing_Page__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.adgroup__c, objLeadAssert.adgroup__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Visitor_Id__c, objLeadAssert.Visitor_Id__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Session_Id__c, objLeadAssert.Session_Id__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Last_Form_Fill_URL__c, objLeadAssert.Last_Form_Fill_URL__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(LeadUtil.LEADSOURCE_LIVE_CHAT, objLeadAssert.Lead_Creation_Offer__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Recent_Campaign__c, objLeadAssert.Recent_Campaign__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Recent_Content__c, objLeadAssert.Recent_Content__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Recent_Source__c, objLeadAssert.Recent_Source__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.URL_of_Conversion__c, objLeadAssert.URL_of_Conversion__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(objLiveChat.Referring_Url__c, objLeadAssert.Referring_Url__c, 'Lead is overwritten with Live Chat data');
		System.assertNotEquals(LeadUtil.MQL_REASON_IB_CHAT, objLeadAssert.MQL_Reason__c, 'Lead is overwritten with Live Chat data');

		Test.stopTest();
	}

	/**
	 * @author
	 * @description Updating fields of chatlivetranscript to the case
	 **/
	@isTest
	public static void testCaseFieldAutoPopulation() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Company Account 1' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'newmember1@campaign.com' LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Sales')
			.setSubject('Test Chat Case')
			.setOrigin('Gusto')
			.setStatus('Open')
			.setSuppliedEmail('newmember1@campaign.com')
			.setDescription('Test Chat Case')
			.build();
		insert objCase;

		LiveChatVisitor objVisitor = new LiveChatVisitor();
		insert objVisitor;

		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setCompanyId('1111111111')
			.setCompanyUUID('e512de89-9639-474b-aebf-0cf26b3075ea')
			.setVisitorEmailAddress('newmember@campaign.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('External')
			.setQuestion('Test')
			.setChatVisitor(objVisitor.Id)
			.build();
		objLiveChatTranscript.CaseId = objCase.Id;
		insert objLiveChatTranscript;

		Test.startTest();
		objLiveChatTranscript.Request_Type__c = 'Benefits';
		objLiveChatTranscript.Support_Level__c = 'Tier 1';
		objLiveChatTranscript.Persona__c = 'Admin';
		objLiveChatTranscript.Company_Size__c = 'Grower 50';
		update objLiveChatTranscript;
        
		objLiveChatTranscript = [SELECT Id, Request_Type__c, Support_Level__c, Persona__c, Company_Size__c FROM LiveChatTranscript WHERE Id = :objLiveChatTranscript.Id];
		Case objCaseAssert = [SELECT Id, Type, Support_Level__c, Persona__c, Company_Size__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCaseAssert.Type, objLiveChatTranscript.Request_Type__c, 'Case Type is not Populated');
		System.assertEquals(objCaseAssert.Support_Level__c, objLiveChatTranscript.Support_Level__c, 'Case Support Level is not Populated');
		System.assertEquals(objCaseAssert.Persona__c, objLiveChatTranscript.Persona__c, 'Case Persona is not Populated');
		System.assertEquals(objCaseAssert.Company_Size__c, objLiveChatTranscript.Company_Size__c, 'Case Size is not Populated');
		Test.stopTest();
	}

	/**
	 * @author      Ankit C
	 * @description Test if the pillar fields are getting updated
	 **/
	@isTest
	public static void testCasePillarMapping() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Company Account 1' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'newmember1@campaign.com' LIMIT 1];

		Test.startTest();
		LiveChatVisitor objVisitor = new LiveChatVisitor();
		insert objVisitor;

		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setCompanyId('1111111111')
			.setCompanyUUID('e512de89-9639-474b-aebf-0cf26b3075ea')
			.setVisitorEmailAddress('newmember@campaign.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('External')
			.setQuestion('Test')
			.setChatVisitor(objVisitor.Id)
			.build();
		insert objLiveChatTranscript;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setType('Payroll')
			.setSubject('Test Engagement Chat Case')
			.setOrigin('Chat')
			.setStatus('Open')
			.setSuppliedEmail('newmember1@campaign.com')
			.setDescription('Test Engagement Chat Case')
			.build();
		insert objCase;

		objLiveChatTranscript.CaseId = objCase.Id;
		objLiveChatTranscript.Request_Type__c = 'Payroll';
		objLiveChatTranscript.Support_Level__c = 'Tier 1';
		objLiveChatTranscript.Persona__c = 'Accountant';
		objLiveChatTranscript.Company_Size__c = 'Standard 5-24';
		update objLiveChatTranscript;

		objLiveChatTranscript.Persona__c = 'Admin';
		update objLiveChatTranscript;
		Test.stopTest();

		objCase = [SELECT Id, Case_Pillar__c, Sub_Pillar__c, WFM_Queue_Tag__c, Pillar_Key__c, Sub_Pillar_Key__c FROM Case WHERE Id = :objCase.Id];
		Assert.isTrue(String.isNotBlank(objCase.Case_Pillar__c), 'Pillar was not updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.Sub_Pillar__c), 'Sub-Pillar was not updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.WFM_Queue_Tag__c), 'WFM Queue Tag was not updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.Pillar_Key__c), 'Pillar Key was not updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.Sub_Pillar_Key__c), 'Sub-Pillar Key was not updated on Case');
	}
	
	/**
	 * @author      Sirisha K
	 * @description Test Case Reason Classification on Live Chat Transcript
	 **/
	@isTest
	public static void testCaseReasonLogic() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Company Account 1' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'newmember1@campaign.com' LIMIT 1];

		Test.startTest();
		LiveChatVisitor objVisitor = new LiveChatVisitor();
		insert objVisitor;

		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setCompanyId('1111111111')
			.setCompanyUUID('e512de89-9639-474b-aebf-0cf26b3075ea')
			.setVisitorEmailAddress('newmember@campaign.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('External')
			.setQuestion('Test')
			.setChatVisitor(objVisitor.Id)
			.setCaseReasonClassification('zp_giving_or_charity')
			.setPersona('Admin')
			.setCompanySize('Standard 5-24')
			.build();
		insert objLiveChatTranscript;

		LiveChatTranscript objNewChat = [SELECT Id, WFM_Queue_Tag__c FROM LiveChatTranscript WHERE Id = :objLiveChatTranscript.Id];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setType('Payroll')
			.setSubject('Test Engagement Chat Case')
			.setOrigin('Chat')
			.setStatus('Open')
			.setSuppliedEmail('newmember1@campaign.com')
			.setDescription('Test Engagement Chat Case')
			.build();
		insert objCase;

		objLiveChatTranscript.CaseId = objCase.Id;
		objLiveChatTranscript.Request_Type__c = 'Payroll';
		objLiveChatTranscript.Support_Level__c = 'Tier 1';
		objLiveChatTranscript.Persona__c = 'Admin';
		objLiveChatTranscript.Company_Size__c = 'Standard 5-24';
		objLiveChatTranscript.ORCA_Predicted_Support_Level__c = 'Tier 1';
		objLiveChatTranscript.ORCA_Predicted_Specialization__c = 'not_predicted';
		objLiveChatTranscript.Second_Level__c = 'Payroll';
		objLiveChatTranscript.ORCA_Predicted_Case_Reason__c = 'regular_payroll_issue_or_question_';
		objLiveChatTranscript.ORCA_Predicted_Case_Reason_Confidence__c = '0.6969';
		objLiveChatTranscript.ORCA_Predicted_Specialization_Confidence__c = '0.9913';
		objLiveChatTranscript.ORCA_Predicted_Support_Level_Confidence__c = '0.8479';
		objLiveChatTranscript.ORCA_Predicted_Type_Confidence__c = '0.7341';
		update objLiveChatTranscript;
		Test.stopTest();

		objCase = [SELECT Id, Routing_Case_Reason__c, Routing_Case_Reason_Classification__c, Second_Level__c,ORCA_Predicted_Support_Level__c, ORCA_Predicted_Specialization__c, ORCA_Predicted_Case_Reason_Confidence__c, ORCA_Predicted_Specialization_Confidence__c, ORCA_Predicted_Support_Level_Confidence__c, ORCA_Predicted_Type_Confidence__c, ORCA_Predicted_Case_Reason__c  FROM Case WHERE Id = :objCase.Id];
		Case_Reason_Classification__c objCaseReason = [SELECT Id, Name FROM Case_Reason_Classification__c WHERE Reason_Code__c = 'zp_giving_or_charity'];
		Assert.isTrue(String.isNotBlank(objCase.Second_Level__c), 'Second_Level__c updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.ORCA_Predicted_Support_Level__c), 'ORCA Predicted Support Level updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.ORCA_Predicted_Specialization__c), 'ORCA Predicted Specialization updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.ORCA_Predicted_Case_Reason_Confidence__c), 'ORCA Predicted Case Reason Confidence updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.ORCA_Predicted_Specialization_Confidence__c), 'ORCA Predicted Specialization Confidence updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.ORCA_Predicted_Support_Level_Confidence__c), 'ORCA Predicted Support Level Confidence updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.ORCA_Predicted_Type_Confidence__c), 'ORCA Predicted Type Confidence updated on Case');
		Assert.isTrue(String.isNotBlank(objCase.ORCA_Predicted_Case_Reason__c), 'ORCA Predicted Case Reason updated on Case');
		Assert.isTrue(String.isNotBlank(objNewChat.WFM_Queue_Tag__c), 'WFM Queue Tag was not updated on Chat');
	}

	/**
	 * @author      Ankit C
	 * @description Test Chat with Cancel specialization
	 **/
	@isTest
	public static void testCancelChatSpecialization() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'Company Account 1' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'newmember1@campaign.com' LIMIT 1];

		Test.startTest();
		LiveChatVisitor objVisitor = new LiveChatVisitor();
		insert objVisitor;

		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setCompanyId('1111111111')
			.setCompanyUUID('e512de89-9639-474b-aebf-0cf26b3075ea')
			.setVisitorEmailAddress('newmember@campaign.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('External')
			.setQuestion('Test cancel skill')
			.setChatVisitor(objVisitor.Id)
			.setPersona('Admin')
			.setCompanySize('Standard 5-24')
			.setORCASpecialization('Cancel')
			.build();
		insert objLiveChatTranscript;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setType('Payroll')
			.setSubject('Test Cancel Chat Case')
			.setOrigin('Chat')
			.setStatus('Open')
			.setSuppliedEmail('newmember1@campaign.com')
			.setDescription('Test Cancel Chat Case')
			.build();
		insert objCase;
		LiveChatTranscript objNewChat = [SELECT Id, WFM_Queue_Tag__c FROM LiveChatTranscript WHERE Id = :objLiveChatTranscript.Id];

		objLiveChatTranscript.CaseId = objCase.Id;
		update objLiveChatTranscript;
		Test.stopTest();
		objCase = [SELECT Id, WFM_Queue_Tag__c FROM Case WHERE Id = :objCase.Id];
		Assert.areEqual('Cancel WFM Queue', objNewChat.WFM_Queue_Tag__c, 'WFM Queue Tag was not updated on Chat');
		Assert.areEqual('Cancel WFM Queue', objCase.WFM_Queue_Tag__c, 'WFM Queue Tag was not updated on Case');
	}
}