/**
 * @Author       :   Pradeep Chary
 * @CreatedDate  :   05-12-2024
 * @Desc         :   Test class for ReRouteCaseController
**/
@isTest
public class ReRouteCaseControllerTest {
    
    @testSetup
    static void setUp() {
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Benefits Care'];
        UserRole objRole = [SELECT Id FROM UserRole WHERE Name = 'Core & Complete'];
        User objUser = new TestDataFactory.UserBuilder()
            .setUserName('benefitscaretestuser@gusto.com')
            .setFirstName('benefitscare')
            .setLastName('testuser')
            .setEmail('benefitscaretestuser@gusto.com')
            .setProfileId(objProfile.Id)
            .setUserRoleId(objRole.Id)
            .setTimeZoneSidKey('America/Denver')
            .setLocaleSidKey('en_US')
            .setLanguageLocaleKey('en_US')
            .setEmailEncoding('ISO-8859-1')
            .setAlias('caretest')
            .setIsActive(true)
            .build();
        User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
        System.runAs(objCurrentUser) {
            insert objUser;
        }
        
        Map<String, QueueRoutingConfig> map_RoutingConfigByName = new Map<String, QueueRoutingConfig>();
        Map<String, Group> map_QueueByName = new Map<String, Group>();
        
        for (Group objGroup : [SELECT Id, Name 
                               FROM Group WHERE Type = 'Queue' 
                               AND Name IN ('Engagement - Auto First Response Queue', 'Engagement Cases')])
        {
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
        
        Account objAccount = new TestDataFactory.AccountBuilder()
            .setRecordTypeId('Company')
            .setName('TEST ROUTE ACCOUNT')
            .setNumberOfActiveEEs(30)
            .build();
        insert objAccount;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
            .setRecordTypeId('Company')
            .setAccountId(objAccount.Id)
            .setFirstName('TEST')
            .setLastName('ROUTE CONTACT')
            .setEmail('test.routecontact@gusto.com')
            .setZPUserRole('Payroll Admin')
            .build();
        insert objContact;
        
        Case_Reason_Classification__c objCaseReason = new TestDataFactory.CaseReasonClassificationBuilder()
            .setName('Payroll pillar case reason')
            .setIsActive(true)
            .setReasonCode('test_payroll_pillar')
            .setCaseTypePillar(CaseUtils.PAYROLL_CASE_PILLAR)
            .setType('Engagement')
            .setRoutingTeam('Internal')
            .setSupportLevel(CaseUtils.TIER_1)
            .build();
        insert objCaseReason;
        
        List<Case> list_Cases = new List<Case>();
        Case objCase = new TestDataFactory.CaseBuilder()
            .setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setSubject('Test Case 1 Subject')
            .setDescription('Test Case 1 Description')
            .setSuppliedEmail('test.routecontact@gusto.com')
            .setStatus(CaseUtils.STATUS_OPEN)
            .setOrigin(CaseUtils.ORIGIN_EMAIL)
            .build();
        objCase.Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO;
        objCase.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
        list_Cases.add(objCase);
        insert list_Cases;
        
        Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
            .setCaseId(list_Cases[0].Id)
            .setReasonCode('test_payroll_pillar')
            .setSupportLevel(CaseUtils.TIER_1)
            .setCaseType(CaseUtils.PAYROLL_CASE_PILLAR)
            .build();
        insert objPrediction;
    }
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Test method to check case skills
    **/
    @isTest
    public static void testCheckCaseSkills() {
        Test.startTest();
        List<Case> list_Cases = [SELECT 
                                 Id,
                                 Origin,
                                 Channel__c,
                                 Persona__c,
                                 Company_Size__c,
                                 Sub_Pillar__c,
                                 Type,
                                 Support_Level__c,
                                 Routing_Team__c,
                                 Specialization__c 
                                 FROM Case 
                                 WHERE Subject = 'Test Case 1 Subject'
                                 LIMIT 1];
        User objCurrentUser = [SELECT Id FROM User WHERE Email = 'benefitscaretestuser@gusto.com'][0];
        System.runAs(objCurrentUser) {
            ReRouteCaseController.CaseInput objInput = new ReRouteCaseController.CaseInput();
            objInput.objCase = list_Cases[0];
            objInput.objOldCase = list_Cases[0];
            
            List<Boolean> list_blnIsSkillMatched = ReRouteCaseController.checkCaseSkills(new List<ReRouteCaseController.CaseInput> { objInput });
            Assert.isTrue(list_blnIsSkillMatched[0] == true, 'Skills matched');
        }
        Test.stopTest();
    }
}