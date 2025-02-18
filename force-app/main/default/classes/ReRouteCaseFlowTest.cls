/*
 * Description: This test class contains test methods to test varios scenarios in the Re-Route case flow.
 * Author: Soujanya N.J
 * Date: 08/09/2024
 */
@isTest
public class ReRouteCaseFlowTest {

    @testSetup
	static void setUp() {
        AccountTriggerHelper.skipTrigger = true;
	    ContactTriggerHelper.skipTrigger = true;
        List<Account> list_Accounts = new List<Account>();
        List<Contact> list_Contacts = new List<Contact>();
        List<Case> list_Cases = new List<Case>();
	    List<User> list_Users = new List<User>();
	    List<Case_Reason_Classification__c> list_CaseReasons = new List<Case_Reason_Classification__c>();
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];

		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('testUser@gusto.com')
			.setFirstName('Test')
			.setLastName('User')
			.setEmail('testUser@gusto.com')
			.setProfileId(objProfile.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('testUser')
			.setVendor('true')
			.setIsActive(true)
			.build();
			list_Users.add(objUser);

			User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
			System.runAs(objCurrentUser) {
			insert list_Users;
			}

        Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Account')
			.setRecordTypeId('Company')
			.build();
			list_Accounts.add(objAccount);

        Account objAccount2 = new TestDataFactory.AccountBuilder()
			.setName('Test Account 2')
			.setRecordTypeId('Company')
			.build();
			list_Accounts.add(objAccount2);

        Account objAccount3 = new TestDataFactory.AccountBuilder()
			.setName('Test Account 3')
			.setRecordTypeId('Company')
			.build();
			list_Accounts.add(objAccount3);
        	insert list_Accounts;

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
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('Contact 2')
			.setEmail('test.contact2@gusto.com')
			.build();
			list_Contacts.add(objContact2);

        Contact objContact3 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('Contact 3')
			.setEmail('test.contact3@gusto.com')
			.build();
			list_Contacts.add(objContact3);
        	insert list_Contacts;

       	AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;

		Case_Reason_Classification__c objCaseReason1 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Route to Spanish')
			.setIsActive(true)
			.setReasonCode('route_to_spanish')
			.setCaseTypePillar(CaseUtils.PAYROLL_CASE_PILLAR)
			.setType('Engagement')
			.setRoutingTeam('Internal')
			.setSpecialization('Spanish')
			.setSupportLevel(CaseUtils.TIER_1)
			.build();
			list_CaseReasons.add(objCaseReason1);
			insert list_CaseReasons;

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
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_PHONE)
			.setSubject('Test Case Origin')
			.setStatus(CaseUtils.STATUS_OPEN)
            .setSource('C2CB')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test')
			.build();
			list_Cases.add(objCase1);

        	Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test Escalated Case')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test')
			.build();
			list_Cases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount2.Id)
			.setContactId(objContact2.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test Specialization Case')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test')
			.blnEscalated(false)
			.build();
			list_Cases.add(objCase3);

			insert list_Cases;
    }

 	/**
	 * @description To test Route without specialization
	 * @author Soujanya NJ
	 */
	@isTest
	static void testRouteSpecializationCase() {

		User objTAMUser = [SELECT Id FROM User WHERE Username = 'testUser@gusto.com'];
		Case objCase = [SELECT Id,Type, Support_Level__c, Case_In_Route__c, Is_Case_Manual_Create__c, Toggle__c,owner.name FROM Case WHERE Subject  = 'Test Specialization Case'];

		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.PAYROLL_CASE_PILLAR)
			.build();
			insert objPrediction;

			objCase.Type = 'Payroll';
			objCase.Support_Level__c = 'Tier 1';
			objCase.Case_In_Route__c = True;
			objCase.Is_Case_Manual_Create__c  = False;
			objCase.Toggle__c = !objCase.Toggle__c;

			Test.StartTest();
			update objCase;	
			Test.StopTest();

		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
	}

     /**
	 * @description To test Route with specialization
	 * @author Soujanya NJ
	 */
	@isTest
	static void testRouteNoSpecializationCase() {

		Case objCase = [SELECT Id FROM Case WHERE Subject  = 'Test Specialization Case'];

		objCase.Type = 'Payroll';
		objCase.Support_Level__c = 'Tier 1';
		objCase.Case_In_Route__c = True;
		objCase.Is_Case_Manual_Create__c  = False;

		Test.StartTest();
		update objCase;
		Test.StopTest();

		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
	}

	/**
	 * @description To test Route to Spanish
	 * @author Soujanya NJ
	 */
	@isTest
	static void testRoutetoSpanish() {

	    Case objCase = [SELECT Id,OwnerId, Status, Toggle__c,Routing_Case_Reason__c,Routing_Case_Reason_Classification__c,Specialization__c,Type,Support_Level__c,Case_In_Route__c,Company_Size__c FROM Case WHERE Subject  = 'Test Specialization Case'];
	    Case_Reason_Classification__c objCaseReasonClassification = [SELECT Id FROM Case_Reason_Classification__c WHERE Reason_Code__c = 'route_to_spanish'];

        Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel(CaseUtils.TIER_1)
			.setCaseType(CaseUtils.BENEFITS_CASE_PILLAR)
			.build();
			insert objPrediction;

            objCase.Status = 'In Progress';
			objCase.Routing_Case_Reason__c = 'Route to Spanish';
			objCase.Routing_Case_Reason_Classification__c  = objCaseReasonClassification.Id;
			objCase.Specialization__c = 'Spanish';
       	 	objCase.Type = 'Benefits';
			objCase.Support_Level__c = 'Tier 2';
       	 	objCase.Case_In_Route__c = True;
        	objCase.Persona__c = 'Admin';
        	objCase.Toggle__c = !objCase.Toggle__c;
        	objCase.Company_Size__c = 'Grower 25-49';
        	objCase.Is_Case_Manual_Create__c  = False;

			Test.StartTest();
			update objCase;
			Test.StopTest();

		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
        List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId, Skill.DeveloperName FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id];
        Assert.isTrue(!list_Skills.isEmpty(), 'Skill Requirement is Spanish');
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
        Assert.isTrue(list_PSR[0].RoutingPriority == 2, 'Routing priority should be 2');
	}

	/**
	 * @description To test Non Engagement scenario
	 * @author Soujanya NJ
	 */
	@isTest
	static void testCaseWithNonEngagement() {

        Case objCase = [SELECT Id,RecordType.Name FROM Case WHERE Subject  = 'Test Specialization Case'];
		Contact objContact = [SELECT id,AccountId FROM Contact where lastName = 'Contact'];

        objCase.RecordType.Name = CaseUtils.RECTYPE_NAME_TAXRES;

		Test.StartTest();
		update objCase;
		Test.StopTest();

		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		Assert.isTrue(list_PSR.isEmpty(), 'PSR was not created');
	}


	 /**
	 * @description To test Route with No specialization Vendor User
	 * @author Soujanya NJ
	 */
	@isTest
	static void testRouteNoSpecializationCaseWithVendor() {

		Case objCase = [SELECT Id FROM Case WHERE Subject  = 'Test Specialization Case'];

		objCase.Type = 'Payroll';
		objCase.Support_Level__c = 'Tier 1';
		objCase.Case_In_Route__c = True;
		objCase.Is_Case_Manual_Create__c  = False;

		Test.StartTest();
		User objCurrentUser = [SELECT Id FROM User WHERE Email = 'testUser@gusto.com'];
		System.runAs(objCurrentUser) {
		update objCase;
		}	
		Test.StopTest();

		List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
		Assert.isTrue(!list_PSR.isEmpty(), 'PSR was not created');
	}

}