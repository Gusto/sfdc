/*
 * Description: This test class contains test methods to test varios scenarios in the Omni Skill Assignment flow.
 * Author: Ankit C
 * Date: 07/05/2024
 */
@isTest
public class OmniSkillAssignmentFlowTest {
	@testSetup
	static void setUp() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		List<Account> list_Accounts = new List<Account>();
		List<Case_Reason_Classification__c> list_CaseReasons = new List<Case_Reason_Classification__c>();
		List<Case> list_Cases = new List<Case>();
		List<User> list_Users = new List<User>();
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('testTAM@gusto.com')
			.setFirstName('Test')
			.setLastName('TAM')
			.setEmail('testTAM@gusto.com')
			.setProfileId(objProfile.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('testtam')
			.setIsActive(true)
			.build();

		list_Users.add(objUser);

		User objUser2 = new TestDataFactory.UserBuilder()
			.setUserName('testinactiveTAM@gusto.com')
			.setFirstName('Test')
			.setLastName('Inactive TAM')
			.setEmail('testinactiveTAM@gusto.com')
			.setProfileId(objProfile.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('testtam2')
			.setIsActive(true)
			.setOOO(true)
			.build();

		list_Users.add(objUser2);

		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objCurrentUser) {
			insert list_Users;
		}

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Gusto Global Account')
			.setRecordTypeId('Company')
			.setHelpJourneyRouting('Gusto Global')
			.build();
		list_Accounts.add(objAccount);

		Account objAccount2 = new TestDataFactory.AccountBuilder()
			.setName('Test Account')
			.setRecordTypeId('Company')
			.build();
		list_Accounts.add(objAccount2);

		Account objAccount3 = new TestDataFactory.AccountBuilder()
			.setName('Test Gold Account')
			.setRecordTypeId('Company')
			.setAMTier('Gold')
			.build();
		list_Accounts.add(objAccount3);

		Account objAccount4 = new TestDataFactory.AccountBuilder()
			.setName('Test Premium Account')
			.setRecordTypeId('Company')
			.setTier('Legacy Premium')
			.build();
		list_Accounts.add(objAccount4);

		Account objAccount5 = new TestDataFactory.AccountBuilder()
			.setName('Test Grower 25 Account')
			.setRecordTypeId('Company')
			.setNumberOfActiveEEs(30)
			.build();
		list_Accounts.add(objAccount5);

		Account objAccount6 = new TestDataFactory.AccountBuilder()
			.setName('Test TAM Account')
			.setRecordTypeId('Company')
			.setTAM(objUser.Id)
			.setNumberOfActiveEEs(60)
			.build();
		list_Accounts.add(objAccount6);

		Account objAccount7 = new TestDataFactory.AccountBuilder()
			.setName('Test Inactive TAM Account')
			.setRecordTypeId('Company')
			.setTAM(objUser2.Id)
			.setNumberOfActiveEEs(30)
			.build();
		list_Accounts.add(objAccount7);

		insert list_Accounts;

		List<Contact> list_Contacts = new List<Contact>();
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('Contact')
			.setEmail('test.contact@gusto.com')
			.build();
		list_Contacts.add(objContact);

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount2.Id)
			.setFirstName('Test')
			.setLastName('Contact 2')
			.setZPUserRole('Payroll Admin')
			.setEmail('testcontact@gusto.com')
			.build();
		list_Contacts.add(objContact2);

		Contact objContact3 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount3.Id)
			.setFirstName('Test')
			.setZPUserRole('Accountant')
			.setLastName('Accountant Contact')
			.setEmail('testcontact2@gusto.com')
			.build();
		list_Contacts.add(objContact3);

		Contact objContact4 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount2.Id)
			.setFirstName('Test')
			.setZPUserRole('Accountant')
			.setLastName('Accountant Contact 2')
			.setEmail('testcontact3@gusto.com')
			.build();
		list_Contacts.add(objContact4);

		Contact objContact5 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount4.Id)
			.setFirstName('Test')
			.setLastName('Contact 3')
			.setEmail('testcontact4@gusto.com')
			.build();
		list_Contacts.add(objContact5);

		Contact objContact6 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount5.Id)
			.setFirstName('Test')
			.setLastName('Admin Contact')
			.setZPUserRole('Payroll Admin')
			.setEmail('testcontact5@gusto.com')
			.build();
		list_Contacts.add(objContact6);

		Contact objContact7 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount6.Id)
			.setFirstName('Test')
			.setLastName('TAM Contact')
			.setEmail('testcontact6@gusto.com')
			.setZPUserRole('Payroll Admin')
			.build();
		list_Contacts.add(objContact7);

		Contact objContact8 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount7.Id)
			.setFirstName('Test')
			.setLastName('Inactive TAM Contact')
			.setEmail('testcontact7@gusto.com')
			.setZPUserRole('Payroll Admin')
			.build();
		list_Contacts.add(objContact8);

		insert list_Contacts;
		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;

		Case_Reason_Classification__c objCaseReason1 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Integrations')
			.setIsActive(true)
			.setReasonCode('zp_giving_or_charity')
			.setCaseTypePillar(CaseUtils.PAYROLL_CASE_PILLAR)
			.setType('Engagement')
			.setRoutingTeam('External')
			.setSpecialization('Integrations')
			.setSupportLevel(CaseUtils.TIER_1)
			.build();
		list_CaseReasons.add(objCaseReason1);

		Case_Reason_Classification__c objCaseReason2 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Payroll pillar case reason')
			.setIsActive(true)
			.setReasonCode('test_payroll_pillar')
			.setCaseTypePillar(CaseUtils.PAYROLL_CASE_PILLAR)
			.setType('Engagement')
			.setRoutingTeam('Internal')
			.setSupportLevel(CaseUtils.TIER_2)
			.build();
		list_CaseReasons.add(objCaseReason2);

		Map<String, QueueRoutingConfig> map_RoutingConfigByName = new Map<String, QueueRoutingConfig>();
		Map<String, Group> map_QueueByName = new Map<String, Group>();

		for (Group objGroup : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN ('Engagement - Auto First Response Queue', 'Engagement Cases')]) {
			map_QueueByName.put(objGroup.Name, objGroup);
		}
		
		for (QueueRoutingConfig objRoutingConfig : [SELECT Id, DeveloperName FROM QueueRoutingConfig]) {
			map_RoutingConfigByName.put(objRoutingConfig.DeveloperName, objRoutingConfig);
		}
		
		Engagement_Flow_Configuration__c objFlowConfiguration = new TestDataFactory.FlowConfigurationBuilder()
			.setOwnerId(UserInfo.getOrganizationId())
			.setAcceptedValues('Payroll,Benefits,TAdA,Taxes,Gusto Global,Cancel,Cobra,Workers Comp,Retirement')
			.setFirstResponseQueueId(map_QueueByName.get('Engagement - Auto First Response Queue').Id)
			.setEngagementQueueId(map_QueueByName.get('Engagement Cases').Id)
			.setOmniRecordTypes('Engagement,Payroll_Care,Benefits_Care')
			.setIneligibleOrigins('Phone,Chat')
			.setEngagementRecordTypeId(CaseUtils.RECTYPE_ENGAGEMENT)
			.setEngagementRoutingConfigId(map_RoutingConfigByName.get('Engagement_Case').Id)
			.setOfflineRoutingConfigId(map_RoutingConfigByName.get('Engagement_Case_Offline_Re_Route').Id)
			.setPriorAgentRoutingConfigId(map_RoutingConfigByName.get('Engagement_Case_Route_Prior_Agent').Id)
			.setGustoGlobalId(map_RoutingConfigByName.get('Engagement_Gusto_Global').Id)
			.setEngagementAlertId(map_RoutingConfigByName.get('Engagement_Alert_Cases').Id)
			.setAccountantId(map_RoutingConfigByName.get('Engagement_Accountant').Id)
			.setBenefitsId(map_RoutingConfigByName.get('Engagement_Benefits').Id)
			.setPremiumId(map_RoutingConfigByName.get('Engagement_Premium_or_Priority_Support_New_Cases').Id)
			.setGoldId(map_RoutingConfigByName.get('Engagement_Gold_Silver').Id)
			.setGrowerId(map_RoutingConfigByName.get('Engagement_Grower').Id)
			.setOfflineId(map_RoutingConfigByName.get('Engagement_Case_Offline').Id)
			.build();

		insert objFlowConfiguration;

		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact2.AccountId)
			.setContactId(objContact2.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test agatha prediction 1')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testagatha@gusto.com')
			.setDescription('Test agatha prediction 1')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase1);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact2.AccountId)
			.setContactId(objContact2.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test agatha prediction 2')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testagatha2@gusto.com')
			.setDescription('Test agatha prediction 2')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact3.AccountId)
			.setContactId(objContact3.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case with gold tier account')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testgold@gusto.com')
			.setDescription('Test case with gold tier account')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase3);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact5.AccountId)
			.setContactId(objContact5.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case with premium account')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testpremium@gusto.com')
			.setDescription('Test case with premium account')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase4);

		Case objCase5 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact4.AccountId)
			.setContactId(objContact4.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case with accountant persona')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testaccountant@gusto.com')
			.setDescription('Test case with accountant persona')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase5);

		Case objCase6 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact6.AccountId)
			.setContactId(objContact6.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case with admin grower')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testgrower@gusto.com')
			.setDescription('Test case with admin grower')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase6);

		Case objCase7 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact2.AccountId)
			.setContactId(objContact2.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case with admin benefits')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testbenefits@gusto.com')
			.setDescription('Test case with admin benefits')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase7);

		Case objCase8 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact7.AccountId)
			.setContactId(objContact7.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case with TAM')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testtamcase@gusto.com')
			.setDescription('Test case with TAM')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase8);

		Case objCase9 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact8.AccountId)
			.setContactId(objContact8.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case with inactive TAM')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testinactivetamcase@gusto.com')
			.setDescription('Test case with inactive TAM')
			.setSolveProcessedFlag('No')
			.setInternalAIProcessedFlag('No')
			.build();
		list_Cases.add(objCase9);

		insert list_Cases;
	}
	
	/**
	 * @description To test Gusto Global case creation
	 * @author		Ankit C
	 */
	@isTest
	static void testGustoGlobalCase() {
		Contact objContact = [SELECT Id, AccountId FROM Contact LIMIT 1];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test gusto global case')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test gusto global case')
			.build();
		Test.startTest();
		insert objCase;
		Test.stopTest();
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId, Skill.DeveloperName FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id AND Skill.DeveloperName = 'Gusto_Global'];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 7, 'Routing priority should be 7 for Gusto Global');
		Assert.isTrue(list_Skills.size() == 1, 'Skill requirements are not correct');
		Assert.areEqual('Gusto_Global', list_Skills[0].Skill.DeveloperName, 'Skill should be Gusto Global');
	}

	/**
	 * @description To test Engagement Alert case creation
	 * @author		Ankit C
	 */
	@isTest
	static void testEngagementAlertCase() {
		Contact objContact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'Contact 2'];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test engagement alert case')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('test2@gusto.com')
			.setDescription('Test engagement alert case')
			.setEngagementAlert('General Alert')
			.build();
		Test.startTest();
		insert objCase;
		Test.stopTest();
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId, Skill.DeveloperName FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id AND Skill.DeveloperName = 'General_Alert'];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 0, 'Routing priority should be 0 for General Alert case');
		Assert.isTrue(list_Skills.size() == 1, 'Skill requirements are not correct');
		Assert.areEqual('General_Alert', list_Skills[0].Skill.DeveloperName, 'Skill should be General Alert');
	}

	/**
	 * @description To test agatha prediction with specialization
	 * @author		Ankit C
	 */
	@isTest
	static void testAgathaPredictionWithSpecialization() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testagatha@gusto.com'];
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('bill_pay_test_feature_inquiry')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.PAYROLL_CASE_PILLAR)
			.build();
		Test.startTest();
		insert objPrediction;
		Test.stopTest();
		Set<String> set_SkillNames = new Set<String> {
			'Tier 1',
			'Payroll',
			'Micro 0-4',
			'Admin',
			'External'
		};
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE Skill.MasterLabel IN :set_SkillNames AND RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_Skills.size() == 5, 'Skill requirements are not correct');
	}

	/**
	 * @description To test agatha prediction without specialization
	 * @author		Ankit C
	 */
	@isTest
	static void testAgathaPredictionWOSpecialization() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testagatha2@gusto.com'];
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('test_payroll_pillar')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.BENEFITS_CASE_PILLAR)
			.build();
		Test.startTest();
		insert objPrediction;
		Test.stopTest();
		Set<String> set_SkillNames = new Set<String> {
			'Tier 1',
			'Payroll',
			'Micro 0-4',
			'Admin',
			'External'
		};
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE Skill.MasterLabel IN :set_SkillNames AND RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_Skills.size() == 5, 'Skill requirements are not correct');
	}

	/**
	 * @description To test scenario for Accountant Persona and Gold tier
	 * @author		Ankit C
	 */
	@isTest
	static void testGoldAccountCase() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testgold@gusto.com'];
		
		Test.startTest();
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.TAXES_CASE_PILLAR)
			.build();
		insert objPrediction;
		Test.stopTest();

		Set<String> set_SkillNames = new Set<String> {
			'Tier 1',
			'Taxes',
			'Accountant',
			'Internal'
		};
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE Skill.Masterlabel IN :set_SkillNames AND RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 4, 'Routing priority should be 4');
		Assert.isTrue(list_Skills.size() == 4, 'Skill requirements are not correct');
	}

	/**
	 * @description To test scenario for Premium tier account
	 * @author		Ankit C
	 */
	@isTest
	static void testPremiumAccountCase() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testpremium@gusto.com'];
		
		Test.startTest();
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.PAYROLL_CASE_PILLAR)
			.build();
		insert objPrediction;
		Test.stopTest();

		Set<String> set_SkillNames = new Set<String> {
			'Tier 1',
			'Payroll',
			'Admin',
			'Internal',
			'Standard 5-24'
		};
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE Skill.Masterlabel IN :set_SkillNames AND RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 5, 'Routing priority should be 5');
		Assert.isTrue(list_Skills.size() == 5, 'Skill requirements are not correct');
	}

	/**
	 * @description To test accountant persona
	 * @author		Ankit C
	 */
	@isTest
	static void testPersonaAccountant() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testaccountant@gusto.com'];
		
		Test.startTest();
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.PAYROLL_CASE_PILLAR)
			.build();
		insert objPrediction;
		Test.stopTest();

		Set<String> set_SkillNames = new Set<String> {
			'Tier 1',
			'Payroll',
			'Accountant',
			'Internal'
		};
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE Skill.Masterlabel IN :set_SkillNames AND RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 6, 'Routing priority should be 6');
		Assert.isTrue(list_Skills.size() == 4, 'Skill requirements are not correct');
	}

	/**
	 * @description To admin persona and grower company size
	 * @author		Ankit C
	 */
	@isTest
	static void testAdminGrower() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testgrower@gusto.com'];
		
		Test.startTest();
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.PAYROLL_CASE_PILLAR)
			.build();
		insert objPrediction;
		Test.stopTest();

		Set<String> set_SkillNames = new Set<String> {
			'Tier 1',
			'Payroll',
			'Admin',
			'Internal',
			'Grower 25-49'
		};
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE Skill.Masterlabel IN :set_SkillNames AND RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 2, 'Routing priority should be 2');
		Assert.isTrue(list_Skills.size() == 5, 'Skill requirements are not correct');
	}

	/**
	 * @description To test benefits case
	 * @author		Ankit C
	 */
	@isTest
	static void testBenefitsCase() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testbenefits@gusto.com'];
		
		Test.startTest();
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.BENEFITS_CASE_PILLAR)
			.build();
		insert objPrediction;
		Test.stopTest();

		Set<String> set_SkillNames = new Set<String> {
			'Tier 1',
			'Benefits',
			'Admin',
			'External',
			'Micro 0-4'
		};
		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE Skill.Masterlabel IN :set_SkillNames AND RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 8, 'Routing priority should be 8');
		Assert.isTrue(!list_Skills.isEmpty());
		Assert.isTrue(list_Skills.size() == 5, 'Skill requirements are not correct');
	}

	/**
	 * @description To test if case is routed to TAM
	 * @author		Ankit C
	 */
	@isTest
	static void testTAMRouting() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testtamcase@gusto.com'];
		User objTAMUser = [SELECT Id FROM User WHERE Username = 'testTAM@gusto.com'];
		
		Test.startTest();
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.PAYROLL_CASE_PILLAR)
			.build();
		insert objPrediction;
		Test.stopTest();

		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority, PreferredUserId FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 3, 'Routing priority should be 3');
		Assert.isTrue(list_Skills.isEmpty(), 'Skill requirements should be empty for TAM case');
		Assert.isTrue(list_PSR[0].PreferredUserId == objTAMUser.Id, 'Preferred User on the PSR should be TAM');
	}

	/**
	 * @description To test case routing when TAM is inactive/OOO
	 * @author		Ankit C
	 */
	@isTest
	static void testInactiveTAMRouting() {
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testinactivetamcase@gusto.com'];
		User objTAMUser = [SELECT Id FROM User WHERE Username = 'testinactiveTAM@gusto.com'];
		
		Test.startTest();
		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.PAYROLL_CASE_PILLAR)
			.build();
		insert objPrediction;
		Test.stopTest();

		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority, PreferredUserId FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE Skill.MasterLabel = 'TAM Premier' AND RelatedRecordId = :list_PSR[0].Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
		Assert.isTrue(list_PSR[0].RoutingPriority == 0, 'Routing priority should be 0');
		Assert.isTrue(!list_Skills.isEmpty(), 'Skill requirements should not be empty');
	}
}