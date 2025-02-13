@isTest
private class HIPolicyTriggerHelperTest {
    /**
     * @Author        Deepika Saini
     * @Description	  Test data set up
     **/
    @TestSetup
    static void setup() {
        Utils.skipTrigger(true);
        
        Account objAccRec = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Gusto Test').setZPCompanyId('5102020').build();
        insert objAccRec;
        
        insert new TestDataFactory.HIBenefitsPackageBuilder().setId('Benefits321').setCompanyId('5102020').build();
        
        insert new TestDataFactory.HIBenefitChangeApplicationBuilder()
            .setBenefitPackageId('Benefits321')
            .setExternalKey('hawaiian_ice-new_plans_application-O321')
            .build();
        
        State__c objState = new TestDataFactory.StateBuilder().setName('California').setId('State321').setAbbreviation('CA').build();
        insert objState;
        
        insert new TestDataFactory.HIRenewalBuilder().setBenefitPackageId('Benefits321').setExternalKey('hawaiian_ice-new_plans_application-O321').build();
        
        String strCarrierName = 'Beam';
        String strCarrierId = '64';
        String strOrderType = 'Same Carrier, NO Plan/Group Level Changes';
        List<RPA_Submission_Automation_rules__mdt> list_SubmissionMetadata = TestUtility.getSubmissionMetadata(Utils.HI_ONLY);
        if (list_SubmissionMetadata != null) {
            strCarrierName = list_SubmissionMetadata[0].DeveloperName;
            strCarrierId = list_SubmissionMetadata[0].Carrier_Id__c;
            if (String.isNotBlank(list_SubmissionMetadata[0].Order_Type__c)) {
                strOrderType = list_SubmissionMetadata[0].Order_Type__c;
                List<String> list_OrderType = strOrderType.split(';');
                strOrderType = list_OrderType[0].trim();
            }
        }
        
        Carrier__c objCarrier = new TestDataFactory.CarrierBuilder()
            .setName(strCarrierName)
            .setUniqueName('beam_dental_ca')
            .setId('259')
            .setKey('beam_dental_ca')
            .setState('CA')
            .setCarrierId(strCarrierId)
            .build();
        objCarrier.Key__c = 'alegeus';//Added for BBO-1968
        insert objCarrier;
        
        PriceBook2 objPB = TestUtility.createCompanyPriceBookInformation();
        
        insert new TestDataFactory.StateBuilder().setName('Alabama').setId('Alabama').setAbbreviation('AL').build();
        
        insert new TestDataFactory.HICompanyContributionBuilder()
            .setId('compcont1')
            .setCompanyId('5102020')
            .setType('HealthCompanyContribution')
            .setCalculatorInputs('{"type"=>"employee_and_dependents", "employee_calculator"=>{"type"=>"percentage", "percentage"=>"0.5"}, "dependents_calculator"=>{"type"=>"percentage", "percentage"=>"0.25"}}')
            .build();
        
        List<Opportunity> list_Opportunity = new List<Opportunity> {
            new TestDataFactory.OpportunityBuilder()
                .setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
                .setName('Benefits New Plan')
                .setPriceBookId(objPB.id)
                .setAccountId(objAccRec.Id)
                .setStage('SAL')
                .setCloseDate(System.today().addDays(30))
                .setSourceID('hawaiian_ice-new_plans_application-O321')
                .setBenefitsState('CA')
                .setNumberOfEE(5)
                .build(),
            new TestDataFactory.OpportunityBuilder()
                .setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
                .setName('Benefits BoR')
                .setPriceBookId(objPB.id)
                .setAccountId(objAccRec.Id)
                .setStage('SAL')
                .setCloseDate(System.today().addDays(30))
                .setSourceID('hawaiian_ice-new_plans_application-O322')
                .setBenefitsState('CA')
                .setNumberOfEE(5)
                .build()
        };
        insert list_Opportunity;
        
        insert new TestDataFactory.HIPolicyContributionBuilder().setCompanyContributionId('compcont1').setPolicyId('hiPolicy321').build();
        //Added for BBO-1968
        insert new testDataFactory.HIFsaPolicyDetailBuilder().setIdAndProviderKey('O322','alegeus','Benefits3215').build();
        insert new TestDataFactory.PolicyBuilder()
            .setName('Test Policy1')
            .setIdOpprtunity(list_Opportunity[0].Id)
            .setIdCarrier(objCarrier.Id)
            .setIsSelected(true)
            .setExternalKey('External321')
            .setBenefitType('Dental')
            .setRequestType('New Plan')
            .setIdState(objState.id)
            .build();
        
        insert new TestDataFactory.HIHealthPlanDetailBuilder().setBenefitsPlanId('Plan321').build();
        
        insert new TestDataFactory.HIBenefitsPlanBuilder().setNationalCarrierId(strCarrierId).setId('Plan321').setState('CA').build();
        
        insert new TestDataFactory.HIHealthPolicyDetailBuilder().setId('Policy321').build();
        
        insert new TestDataFactory.HINPApplicationsBenefitsPackageBuilder()
            .setId('Benefits321')
            .setBenefitsPackageId('Benefits321')
            .setNewPlansApplicationId('O321')
            .build();
        
        insert new TestDataFactory.HILidiPolicyDetailBuilder().setId('Policy321').build();
        Utils.skipTrigger(false);
    }
    
    /**
     * @author        Abhishek Singh
     * @description	  Test to process the Policy with Provider Key BBO-1968
     **/
    @isTest
    static void testProviderKeyMethod() {
        Test.startTest();
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits3215')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('FsaPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .setBORTransferId('1234')
            .build();
        objHIPolicy.Policy_Detail_Id__c = 'O322';
        insert objHIPolicy;
        Test.stopTest();
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Backlog', objHIPolicy.Processing_State__c);
    }
    
    
    /**
     * @author        Bhagat Singh
     * @description	  Set External Key
     **/
    @isTest
    static void testExternalKey() {
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits321')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('HealthPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .build();
        insert objHIPolicy;
        
        Test.startTest();
        HI_Policy__c objHiPolicyRec = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits321')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External321')
            .setId('hiPolicy321')
            .setPolicyDetailType('LiDiPolicyDetail')
            .setVisible(true)
            .build();
        insert objHiPolicyRec;
        update objHiPolicyRec;
        delete objHiPolicyRec;
        
        HIPolicyTriggerHelper objHipolicyTrgHelp = new HIPolicyTriggerHelper();
        Test.stopTest();
        
        objHIPolicy = [SELECT ID, External_Key__c, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertNotEquals('External321', objHIPolicy.External_Key__c, 'External Key should not be updated');
    }
    
    /**
     * @author        Deepika Saini
     * @description	  Test to process the HI Policy when BOR Transfer Id is present
     **/
    @isTest
    static void testHIPolicyForBorTransId() {
        Test.startTest();
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits321')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('HealthPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .setBORTransferId('1234')
            .build();
        insert objHIPolicy;
        Test.stopTest();
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Processed', objHIPolicy.Processing_State__c, 'Processing State should be Processed');
        System.assert(objHIPolicy.Message__c.Contains('Bor Transfer Id is populated for Big Desk, support to be added later'), 'Error Message does not match');
    }
    
    /**
     * @author        Deepika Saini
     * @description	  Test to process the HI Policy when BOR Transfer Id is present
     **/
    @isTest
    static void testMissingPlanId() {
        Test.startTest();
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits321')
            .setPlanId('Plan3215')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('HealthPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .build();
        insert objHIPolicy;
        Test.stopTest();
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Backlog', objHIPolicy.Processing_State__c, 'Processing State should be Backlog');
        System.assert(objHIPolicy.Message__c.Contains('Corresponding plan does not exist.'), 'Error Message does not match');
    }
    
    /**
     * @author        Deepika Saini
     * @description	  Test to process the HI Policy when BOR Transfer Id is present
     **/
    @isTest
    static void testMissingBenefitPackageId() {
        Test.startTest();
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits3215')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('HealthPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .setBORTransferId('1234')
            .build();
        insert objHIPolicy;
        Test.stopTest();
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Backlog', objHIPolicy.Processing_State__c, 'Processing State should be Backlog');
        System.assert(objHIPolicy.Message__c.Contains('Benefits Package does not exist.'), 'Error Message does not match');
    }
    
    /**
     * @author        Deepika Saini
     * @description	  Test to process the HI Policy when BOR Transfer Id is present
     **/
    @isTest
    static void testMissingPolicyDetailId() {
        Test.startTest();
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits321')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy3215')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('HealthPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .build();
        insert objHIPolicy;
        Test.stopTest();
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Backlog', objHIPolicy.Processing_State__c, 'Processing State should be Backlog');
        System.assert(objHIPolicy.Message__c.Contains('Health Policy Detail does not exist'), 'Error Message does not match');
    }
    
    /**
     * @Author        Rushi R
     * @Description	  Test to validate reprocessing of HI Policy
     **/
    @isTest
    static void testReprocessHIPolicy() {
        OpportunityTriggerHelper.skipTrigger = true;
        DELETE [SELECT Id FROM Opportunity];
        OpportunityTriggerHelper.skipTrigger = false;
        
        Test.startTest();
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits321')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('HealthPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .build();
        insert objHIPolicy;
        
        HI_New_Plans_Application__c objHINewPlansApp = new TestDataFactory.HINewPlansApplicationBuilder()
            .setId('O321')
            .setCompanyId('5102020')
            .setExternalKey('hawaiian_ice-new_plans_application-O321')
            .setReqStartDate(System.today())
            .build();
        insert objHINewPlansApp;
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Backlog', objHIPolicy.Processing_State__c, 'Processing State should be Backlog');
        System.assert(objHIPolicy.Message__c.contains('New Plan Opp does not exist.'), 'Error Message does not match');
        
        Database.executeBatch(new HIPolicyBatch(), 1);
        Test.stopTest();
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Processed', objHIPolicy.Processing_State__c, 'Processing State should be Backlog');
        
        List<Opportunity> list_Oppty = [SELECT Id FROM Opportunity WHERE Source_Id__c = 'hawaiian_ice-new_plans_application-O321'];
        System.assert(!list_Oppty.isEmpty(), 'Opportunity should get created');
    }
    
    /**
     * @Author        Nigam Goyal
     * @Description	  Test to set records as dead from error records after certain days
     **/
    @isTest
    static void testToSetDeadHIPolicy() {
        OpportunityTriggerHelper.skipTrigger = true;
        DELETE [SELECT Id FROM Opportunity];
        OpportunityTriggerHelper.skipTrigger = false;
        
        Test.startTest();
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits321')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('HealthPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .setCreatedDate(DateTime.now().addDays(-7))
            .build();
        insert objHIPolicy;
        
        HI_New_Plans_Application__c objHINewPlansApp = new TestDataFactory.HINewPlansApplicationBuilder()
            .setId('O321')
            .setCompanyId('5102020')
            .setExternalKey('hawaiian_ice-new_plans_application-O321')
            .setReqStartDate(System.today())
            .build();
        insert objHINewPlansApp;
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Backlog', objHIPolicy.Processing_State__c, 'Processing State should be Backlog');
        System.assert(objHIPolicy.Message__c.contains('New Plan Opp does not exist.'), 'Error Message does not match');
        
        Database.executeBatch(new HIPolicyBatch(), 1);
        Test.stopTest();
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Dead', objHIPolicy.Processing_State__c, 'Processing State should be Dead');
    }
    
    /**
     * @Author        Nigam Goyal
     * @Description	  Test to set records as dead from error records after certain days
     **/
    @isTest
    static void testToDeleteDeadHIPolicy() {
        OpportunityTriggerHelper.skipTrigger = true;
        DELETE [SELECT Id FROM Opportunity];
        OpportunityTriggerHelper.skipTrigger = false;
        
        Test.startTest();
        HI_Policy__c objHIPolicy = new TestDataFactory.HIPolicyBuilder()
            .setBenefitsPackageId('Benefits321')
            .setPlanId('Plan321')
            .setState('State321')
            .setPolicyDetailId('Policy321')
            .setExternalKey('External3211')
            .setId('hiPolicy3211')
            .setPolicyDetailType('HealthPolicyDetail')
            .setEffectiveDate(System.today() - 265)
            .setExpirationDate(System.today() + 100)
            .setVisible(true)
            .setCreatedDate(DateTime.now().addDays(-180))
            .setProcessingState('Dead')
            .build();
        insert objHIPolicy;
        
        HI_New_Plans_Application__c objHINewPlansApp = new TestDataFactory.HINewPlansApplicationBuilder()
            .setId('O321')
            .setCompanyId('5102020')
            .setExternalKey('hawaiian_ice-new_plans_application-O321')
            .setReqStartDate(System.today())
            .build();
        insert objHINewPlansApp;
        
        objHIPolicy = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c LIMIT 1];
        System.assertEquals('Dead', objHIPolicy.Processing_State__c, 'Processing State should be Dead');
        
        Database.executeBatch(new HIPolicyBatch(), 1);
        Test.stopTest();
        
        List<HI_Policy__c> list_HIPolices = [SELECT ID, Message__c, Processing_State__c FROM HI_Policy__c WHERE ID = :objHIPolicy.Id];
        System.assertEquals(0, list_HIPolices.size(), 'Dead record should be deleted');
    }
}