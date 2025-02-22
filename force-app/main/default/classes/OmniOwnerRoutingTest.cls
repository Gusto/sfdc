/*
* Description: This test class contains test methods to test varios scenarios in the Omni Owner Routing flow.
* Author: Aslam Juneid 
* Date: 16/08/2024
*/

@isTest
public class OmniOwnerRoutingTest {
    
    /**
    * @description Setup method to set data
    * @author		Aslam Juneid
    */
    @testSetup
    static void setUp() {
        AccountTriggerHelper.skipTrigger = true;
        ContactTriggerHelper.skipTrigger = true;
        List<Account> list_Accounts = new List<Account>();
        List<Case_Reason_Classification__c> list_CaseReasons = new List<Case_Reason_Classification__c>();
        List<Case> list_Cases = new List<Case>();
        
        System.runAs(new user(ID = UserInfo.getUserID())){
            userInsert();
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
            .setEmail('testcontact@gusto.com')
            .build();
        list_Contacts.add(objContact2);
        
        insert list_Contacts;
        AccountTriggerHelper.skipTrigger = false;
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
            .setOfflineId(map_RoutingConfigByName.get('Engagement_Case_Offline').Id)
            .setManualOwnerChangeId(map_RoutingConfigByName.get('Engagement_Manual_Owner_Change').Id)
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
        
        insert list_Cases;
    }
    
     /**
    * @description Testing TAM User scnerio for Omni Routing
    * @author		Aslam Juneid
    */
    @isTest
    private static void testTAMUser(){
        User tamUser = [SELECT Id FROM User LIMIT 1];
        List<Case> list_Case = [SELECT id,Engagement_Alert__c,Channel__c,Case_In_Route__c,OwnerId,Status,Origin,recordtype.DeveloperName,Persona__c,AccountId,Account.Technical_Account_Manager__c,Account.CX_Experiment__c FROM Case];
        
        Case objCase = list_Case[0];

        //Assert Check for Initial Values
        Assert.isTrue(objCase.Recordtype.Developername == 'Engagement');
        Assert.isTrue(objCase.Origin == 'Email');
        Assert.isTrue(objCase.Persona__c == 'Admin');
        Assert.isTrue(objCase.AccountId != null);
        Assert.isTrue(objCase.Account.Technical_Account_Manager__c == null);
        Assert.isTrue(objCase.status == 'Open');
        
        //Update TAM on Account
        Account objAccount = new Account();
        objAccount.Id = objCase.AccountId;
        objAccount.Technical_Account_Manager__c = tamUser.Id;
        update objAccount;
        Assert.isTrue(Account.Technical_Account_Manager__c != null);

        //Case Update
        objCase.status = 'Awaiting Response';
        update objCase;
        
        
        List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
        
        //Assert Check PendingServiceRouting not created to make sure OmniOwnerRouting flow didnt invoked
        Assert.isTrue(list_PSR.isEmpty());
    }
    
    /**
    * @description To test  Case Update  with P0 is when the agent goes offline
    * @author		Aslam Juneid
    */
    @isTest
    private static void caseAgentOfflineTest(){
        
        List<Case> list_Case = [SELECT id,Engagement_Alert__c,Channel__c,Case_In_Route__c,OwnerId,Status,Origin,recordtype.DeveloperName,Persona__c,Account.Technical_Account_Manager__c,Account.CX_Experiment__c FROM Case];
        Case objCase = list_Case[0];
        
        //Assert Check for Initial Values
        Assert.isTrue(objCase.Recordtype.Developername == 'Engagement');
        Assert.isTrue(objCase.Origin == 'Email');
        Assert.isTrue(objCase.Persona__c == 'Admin');
        
        
        //Case Update since we can't simulate the agent offline behavior directly, we are updating the status of the case to Open. 
        objCase.status = 'In Progress';
        update  objCase;
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'In Progress');
        
        objCase.status = 'Open';
        Test.startTest();
        update  objCase;
        Test.stopTest();
        
        List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'Open');
        Assert.isTrue(!list_PSR.isEmpty());
        Assert.isTrue(list_PSR[0].RoutingPriority == 0);
        List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id];
        Assert.isTrue(list_Skills.isEmpty());
    }
    /**
    * @description To test  Case Update  for Record Type Change Scnerio
    * @author		Aslam Juneid
    */
    @isTest
    private static void recordTypeChangeTest(){
        
        List<Case> list_Case = [SELECT id,Engagement_Alert__c,Channel__c,Case_In_Route__c,OwnerId,Status,Origin,recordtype.DeveloperName,recordtype.Name,Persona__c,Account.Technical_Account_Manager__c,Account.CX_Experiment__c FROM Case];
        Case objCase = list_Case[0];
        
        //Assert Check for Initial Values
        Assert.isTrue(objCase.Recordtype.Developername == 'Engagement');
        Assert.isTrue(objCase.Origin == 'Email');
        Assert.isTrue(objCase.Persona__c == 'Admin');
        
       
        //Case Update since we can't simulate the agent offline behavior directly, we are updating the status of the case to Open. 
         objCase.recordtypeId = CaseUtils.RECTYPE_BYB;
        objCase.status = 'In Progress';
        update  objCase;
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'In Progress');
        
        objCase.status = 'Open';
        Test.startTest();
        update  objCase;
        Test.stopTest();
        
        List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'Open');
        Assert.isTrue(list_PSR.isEmpty());
    }
    
    /**
    * @description To test  Case Update for assign the "Engagement Alert Cases" routing 
    * @author		Aslam Juneid
    */
    @isTest
    private static void engagementAlertTest(){
        
        List<Case> list_Case = [SELECT id,Engagement_Alert__c,Internal_Support_Requested_From__c,Channel__c,Case_In_Route__c,OwnerId,Status,Origin,recordtype.DeveloperName,Persona__c,Account.Technical_Account_Manager__c,Account.CX_Experiment__c FROM Case];
        Case objCase = list_Case[0];
        
        //Assert Check for Initial Values
        Assert.isTrue(objCase.Recordtype.Developername == 'Engagement');
        Assert.isTrue(objCase.Origin == 'Email');
        Assert.isTrue(objCase.Persona__c == 'Admin');
        
        //Case Update
        objCase.Engagement_Alert__c ='General Alert';
        objCase.Internal_Support_Requested_From__c = 'Risk';
        objCase.status = 'Awaiting Internal Support';
        update  objCase;
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.Internal_Support_Requested_From__c == 'Risk');
        Assert.isTrue(objCase.Engagement_Alert__c == 'General Alert');
        Assert.isTrue(objCase.status == 'Awaiting Internal Support');
        
        //Case Update
        objCase.status = 'In Progress';
        update  objCase;
        
        List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status ==  'In Progress');
        Assert.isTrue(!list_PSR.isEmpty());
        Assert.isTrue(list_PSR[0].RoutingPriority == 0);
        List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id];
        Assert.isTrue(list_Skills.isEmpty());
    }
    
    /**
    * @description To test Case Update for Assign the "Engagement Case Offline" routing 
    * @author		Aslam Juneid
    */
    @isTest
    private static void manualOwnerChangeTest(){
        
        User objUser = [SELECT id,Name FROM User WHERE UserName = 'testinactiveuser@gusto.com'];
        List<Case> list_Case = [SELECT id,Engagement_Alert__c,Internal_Support_Requested_From__c,Channel__c,Case_In_Route__c,OwnerId,Status,Origin,recordtype.DeveloperName,Persona__c,Account.Technical_Account_Manager__c,Account.CX_Experiment__c FROM Case];
        Case objCase = list_Case[0];
        
        //Case Update
        objCase.status = 'Awaiting Response';
        update  objCase;
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'Awaiting Response');
        
        //Case Update
        Id idOldOwner = objCase.OwnerId;
        objCase.OwnerId = objUser.Id;
        objCase.status = 'In Progress';
        update  objCase;
        
        List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'In Progress');
        Assert.isTrue( objCase.OwnerId != idOldOwner);
        Assert.isTrue((String.valueOf(objCase.OwnerId).startswith('005')) );
        Assert.isTrue(!list_PSR.isEmpty());
        Assert.isTrue(list_PSR[0].RoutingPriority == 0);
        List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id];
        Assert.isTrue(list_Skills.isEmpty());
    }
    
    /**
    * @description To test Case Update route to Queue
    * @author		Aslam Juneid
    */
    @isTest
    private static void routeCaseToQueueTest(){
        
        Group objGroup = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN ('Engagement - Auto First Response Queue', 'Engagement Cases') limit 1];
        
        List<Case> list_Case = [SELECT id,Engagement_Alert__c,Internal_Support_Requested_From__c,Channel__c,Case_In_Route__c,OwnerId,Status,Origin,recordtype.DeveloperName,Persona__c,Account.Technical_Account_Manager__c,Account.CX_Experiment__c FROM Case];
        Case objCase = list_Case[0];
        
        //Case Update
        objCase.Status = 'Awaiting Response';
        objCase.Type = 'Payroll';
        update  objCase;
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'Awaiting Response');
        
        //Case Update
        Id idOldOwner = objCase.OwnerId;
        objCase.OwnerId = objGroup.Id;
        
        objCase.status = 'In Progress';
        update  objCase;
        
        List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'In Progress');
        Assert.isTrue(idOldOwner != objCase.OwnerId);
        Assert.isTrue(!(String.valueOf(objCase.OwnerId).startswith('005')) );
        Assert.isTrue(!list_PSR.isEmpty());
        Assert.isTrue(list_PSR[0].RoutingPriority == 1);
        List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id];
        Assert.isTrue(!list_Skills.isEmpty());

    }
    
    /**
    * @description To test Case Update route to Queue
    * @author		Aslam Juneid
    */
    @isTest
    private static void routCaseToUserTest(){
        
        List<Case> list_Case = [SELECT id,Engagement_Alert__c,Internal_Support_Requested_From__c,Channel__c,Case_In_Route__c,OwnerId,Status,Origin,recordtype.DeveloperName,Persona__c,Account.Technical_Account_Manager__c,Account.CX_Experiment__c FROM Case];
        Case objCase = list_Case[0];
        
        //Case Update
        objCase.status = 'Awaiting Response';
        update  objCase;
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'Awaiting Response');
        
        //Case Update
        objCase.status = 'In Progress';
        update  objCase;
        
        List<PendingServiceRouting> list_PSR = [SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting WHERE WorkItemId = :objCase.Id];
        
        //Assert Check for Updated Values
        Assert.isTrue(objCase.status == 'In Progress');
        Assert.isTrue((String.valueOf(objCase.OwnerId).startswith('005')) );
        Assert.isTrue(!list_PSR.isEmpty());
        Assert.isTrue(list_PSR[0].RoutingPriority == 1);
        List<SkillRequirement> list_Skills = [SELECT Id, RelatedRecordId, SkillId FROM SkillRequirement WHERE RelatedRecordId = :list_PSR[0].Id];
        Assert.isTrue(list_Skills.isEmpty());
        
    }
    
    /**
    * @description 	Method to insert the users
    * @author		Aslam Juneid
    */
    
    public static void userInsert(){
        
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
        List<User> list_Users = new List<User>();
        User objUser = new TestDataFactory.UserBuilder()
            .setUserName('testinactiveuser@gusto.com')
            .setFirstName('')
            .setLastName('Test Inactive User')
            .setEmail('testinactiveuser@gusto.com')
            .setProfileId(objProfile.Id)
            .setTimeZoneSidKey('America/Denver')
            .setLocaleSidKey('en_US')
            .setLanguageLocaleKey('en_US')
            .setEmailEncoding('ISO-8859-1')
            .setAlias('test')
            .setIsActive(true)
            .build();
        list_Users.add(objUser);
        
        insert list_Users;
    }
    
}