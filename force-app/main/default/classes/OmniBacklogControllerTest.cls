/**
* @description Test class for the OmniBacklogController class
* @author      Ankit
* @date        18 Nov 2024       
*/
@isTest
public class OmniBacklogControllerTest {
	@testSetup
	static void setupData() {
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Gusto Global Account')
			.setRecordTypeId('Company')
			.build();
		list_Accounts.add(objAccount);
		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		List<Contact> list_Contacts = new List<Contact>();
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('Contact')
			.setEmail('test.contact@gusto.com')
			.build();
		list_Contacts.add(objContact);
		
		ContactTriggerHelper.skipTrigger = true;
		insert list_Contacts;
		ContactTriggerHelper.skipTrigger = false;
		
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

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case routing')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test case routing')
			.build();
		insert objCase;

		List<Case_Pillar_Mapping__c> list_CasePillarMappings = new List<Case_Pillar_Mapping__c>();
		Case_Pillar_Mapping__c objMapping = new TestDataFactory.CasePillarMappingBuilder()
			.setName('CPM001')
			.setType('Payroll')
			.setSupportLevel('Tier 2')
			.setCompanySize('Standard 5-24')
			.setPersona('Admin')
			.setPillar('Test Pillar')
			.setSubPillar('Test Sub Pillar')
			.setCaseOrigin('Email')
			.setWFMQueueTag('Test WFM Queue Tag')
			.setPillarKey('P-001')
			.setSubPillarKey('SP-001')
			.build();
		list_CasePillarMappings.add(objMapping);

		Case_Pillar_Mapping__c objMapping2 = new TestDataFactory.CasePillarMappingBuilder()
			.setName('CPM002')
			.setSpecialization('Cancel')
			.setPillar('Cancel Pillar')
			.setSubPillar('Cancel Sub Pillar')
			.setCaseOrigin('Email')
			.setWFMQueueTag('Test WFM Queue Tag')
			.setPillarKey('P-002')
			.setSubPillarKey('SP-002')
			.build();
		list_CasePillarMappings.add(objMapping2);

		insert list_CasePillarMappings;
	}

	/**
	 * @author:         Ankit CS
	 * @description:    Tes method for the getFilters method in OmniBacklogController.cls
	*/
	@isTest
	static void testGetFilters() {
		Test.startTest();
		OmniBacklogController.FiltersWrapper objWrapper = OmniBacklogController.getFilters();
		Test.stopTest();
		System.assertNotEquals(null, objWrapper, 'FiltersWrapper should not be null');
		System.assertNotEquals(null, objWrapper.list_Skills, 'Skills should not be empty');
		System.assertNotEquals(null, objWrapper.list_Pillars, 'Pillars should not be empty');
		System.assertNotEquals(null, objWrapper.list_SubPillars, 'Sub pillars should not be empty');
		System.assertNotEquals(null, objWrapper.list_WFMQueues, 'WFM Queues should not be empty');
	}

	/**
	 * @author:         Ankit CS
	 * @description:    Tes method for the getBacklogItems method in OmniBacklogController.cls
	*/
	@isTest
	static void testGetBacklogItems() {
		Case objCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
		objCase.Company_Size__c = 'Standard 5-24';
		objCase.Support_Level__c = 'Tier 2';
		objCase.Persona__c = 'Admin';
		objCase.Type = 'Payroll';
		objCase.Status = 'In Progress';
		objCase.Answer_IQ_Processed__c = 'Yes';
		objCase.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
		Test.startTest();
		update objCase;

		objCase = [SELECT Id, CaseNumber, Case_Pillar__c, Sub_Pillar__c, WFM_Queue_Tag__c FROM Case WHERE Id = :objCase.Id];
		PendingServiceRouting objPSR = [SELECT Id, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id LIMIT 1];
		Skill objSkill = [SELECT Id FROM Skill WHERE DeveloperName = 'Payroll' LIMIT 1];
		List<Id> list_SkillIds = new List<Id>{ objSkill.Id };
		List<String> list_Pillars = new List<String>{ objCase.Case_Pillar__c };
		List<String> list_SubPillars = new List<String>{ objCase.Sub_Pillar__c };
		List<String> list_WFMQueues = new List<String>{ objCase.WFM_Queue_Tag__c };
		List<OmniBacklogController.PendingRoutingWrapper> list_Results = OmniBacklogController.getBacklogItems(
			list_SkillIds, 
			list_Pillars, 
			list_SubPillars, 
			list_WFMQueues, 
			objCase.CaseNumber, 
			String.valueOf(objPSR.RoutingPriority),
			'',
			''
		);
		Test.stopTest();
		Assert.isTrue(!list_Results.isEmpty());
	}
}