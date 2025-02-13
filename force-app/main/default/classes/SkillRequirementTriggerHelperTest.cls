/**
* @description  Test class for SkillRequirementTrigger
* @author       Ankit C
* @date         08-06-2024
**/
@isTest
public class SkillRequirementTriggerHelperTest {
	/**
	 * @description To setup test data
	 * @author      Ankit C
	**/
	@testSetup
	static void setupData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Company Account 1')
			.setRecordTypeId('Company')
			.setZPCompanyId('1111111111')
			.build();
		insert objAccount;
		
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('Contact')
			.setEmail('test.contact@gusto.com')
			.build();
		insert objContact;
		
		List<Case> list_Cases = new List<Case>();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setSubject('Test case 1')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testcase@gusto.com')
			.setDescription('Test case 1')
			.build();
		list_Cases.add(objCase);
		
		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setOrigin(CaseUtils.ORIGIN_CHAT)
			.setSubject('Test chat')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testcase2@gusto.com')
			.setDescription('Test chat case ')
			.build();
		list_Cases.add(objCase2);
		
		insert list_Cases;
		
		LiveChatVisitor objVisitor = new LiveChatVisitor();
		insert objVisitor;

		LiveChatTranscript objLiveChatTranscript = new TestDataFactory.LiveChatTranscriptBuilder()
			.setCompanyId('1111111111')
			.setCompanyUUID('e512de89-9639-474b-aebf-0cf26b3075ea')
			.setVisitorEmailAddress('test.contact@gusto.com')
			.setVisitorFirstName('Vernetta')
			.setVisitorLastName('Stiedemann')
			.setCompanyName('Company Account 1')
			.setRecordTypeId('External')
			.setQuestion('Test')
			.setChatVisitor(objVisitor.Id)
			.setCaseId(objCase2.Id)
			.build();
		insert objLiveChatTranscript;
		
		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
	}
	
	/**
	 * @description To test case transfer
	 * @author      Ankit C
	**/
	@isTest
	static void testCaseTransfer() {
		Set<String> set_SkillNames = new Set<String>{ 'Admin', 'Internal', 'Payroll', 'Tier_1', 'Standard_5_24' };
		Map<String, Skill> map_SkillByName = new Map<String, Skill>();
		for (Skill objSkill : [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName IN :set_SkillNames]) {
			map_SkillByName.put(objSkill.DeveloperName, objSkill);
		}
   
		Case objCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'testcase@gusto.com'];
		ServiceChannel objServiceChannel = [SELECT Id FROM ServiceChannel WHERE MasterLabel = 'Case'];
		PendingServiceRouting objPSR = new TestDataFactory.PendingServiceRoutingBuilder()
			.setWorkItemId(objCase.Id)
			.setServiceChannelId(objServiceChannel.Id)
			.setIsReadyForRouting(false)
			.setCapacity(1)
			.setRoutingType('SkillsBased')
			.setRoutingModel('MostAvailable')
			.setRoutingPriority(2)
			.build();
		insert objPSR;
		
		List<SkillRequirement> list_SkillRequirements = new List<SkillRequirement>();
		SkillRequirement objSkillReq1 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Admin').Id)
			.build();
		list_SkillRequirements.add(objSkillReq1);
		
		SkillRequirement objSkillReq2 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Internal').Id)
			.build();
		list_SkillRequirements.add(objSkillReq2);
		
		SkillRequirement objSkillReq3 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Payroll').Id)
			.build();
		list_SkillRequirements.add(objSkillReq3);
		
		SkillRequirement objSkillReq4 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Tier_1').Id)
			.build();
		list_SkillRequirements.add(objSkillReq4);
		
		SkillRequirement objSkillReq5 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Standard_5_24').Id)
			.build();
		list_SkillRequirements.add(objSkillReq5);
		
		Test.startTest();
		insert list_SkillRequirements;
		Test.stopTest();
		
		objCase = [SELECT Id, Type, Persona__c, Support_Level__c, Company_Size__c, Routing_Team__c FROM Case WHERE Id = :objCase.Id];
		Assert.areEqual('Payroll', objCase.Type, 'Type was not updated correctly');
		Assert.areEqual('Admin', objCase.Persona__c, 'Persona was not updated correctly');
		Assert.areEqual('Tier 1', objCase.Support_Level__c, 'Support Level was not updated correctly');
		Assert.areEqual('Standard 5-24', objCase.Company_Size__c, 'Company Size was not updated correctly');
		Assert.areEqual('Internal', objCase.Routing_Team__c, 'Team was not updated correctly');
	}
	
	/**
	 * @description To test chat transfer
	 * @author      Ankit C
	**/
	@isTest
	static void testChatTransfer() {
		Set<String> set_SkillNames = new Set<String>{ 'Admin', 'Payroll', 'Benefits', 'Tier_2', 'Standard_5_24' };
		Map<String, Skill> map_SkillByName = new Map<String, Skill>();
		for (Skill objSkill : [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName IN :set_SkillNames]) {
			map_SkillByName.put(objSkill.DeveloperName, objSkill);
		}
		
		LiveChatTranscript objChat = [SELECT Id FROM LiveChatTranscript LIMIT 1];
		ServiceChannel objServiceChannel = [SELECT Id FROM ServiceChannel WHERE MasterLabel = 'Chat'];
		PendingServiceRouting objPSR = new TestDataFactory.PendingServiceRoutingBuilder()
			.setWorkItemId(objChat.Id)
			.setServiceChannelId(objServiceChannel.Id)
			.setIsReadyForRouting(false)
			.setCapacity(1)
			.setRoutingType('SkillsBased')
			.setRoutingModel('MostAvailable')
			.setRoutingPriority(2)
			.build();
		insert objPSR;
		
		List<SkillRequirement> list_SkillRequirements = new List<SkillRequirement>();
		SkillRequirement objSkillReq1 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Admin').Id)
			.build();
		list_SkillRequirements.add(objSkillReq1);
		
		SkillRequirement objSkillReq2 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Benefits').Id)
			.build();
		list_SkillRequirements.add(objSkillReq2);
		
		SkillRequirement objSkillReq3 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Tier_2').Id)
			.build();
		list_SkillRequirements.add(objSkillReq3);
		
		SkillRequirement objSkillReq4 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Standard_5_24').Id)
			.build();
		list_SkillRequirements.add(objSkillReq4);
		
		Test.startTest();
		insert list_SkillRequirements;
		Test.stopTest();
		
		objChat = [SELECT Id, Request_Type__c, Persona__c, Support_Level__c, Company_Size__c FROM LiveChatTranscript WHERE Id = :objChat.Id];
		Assert.areEqual('Benefits', objChat.Request_Type__c, 'Type was not updated correctly');
		Assert.areEqual('Admin', objChat.Persona__c, 'Persona was not updated correctly');
		Assert.areEqual('Tier 2', objChat.Support_Level__c, 'Support Level was not updated correctly');
		Assert.areEqual('Standard 5-24', objChat.Company_Size__c, 'Company Size was not updated correctly');
		
		//Throw and exception to cover catch block in SkillRequirementTriggerHandler
		SkillRequirementTriggerHelper.blnThrowException = true;
		SkillRequirement objSkillReq5 = new TestDataFactory.SkillRequirementBuilder()
			.setRelatedRecordId(objPSR.Id)
			.setSkillId(map_SkillByName.get('Payroll').Id)
			.build();
		insert objSkillReq5;
		SkillRequirementTriggerHelper.blnThrowException = false;
	}
}