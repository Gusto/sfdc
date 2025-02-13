@isTest
public class SendComplianceToAsanaRoutingTest {
    
    @TestSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new ComplianceToAsanaCalloutMock(200));
        Case objParentCase = TestDataFactory.createCaseRecord('Compliance', true);
        Case objChildCase = TestDataFactory.createCaseRecord('Compliance', true);
                
        Account objAccount = TestDataFactory.CompanyAccount();
        Contact objContact = TestDataFactory.createTestContact(objAccount.Id);
        Agency_Information__c objAgencyInfo = new TestDataFactory.AgencyInformationBuilder().setName('Test Agency').setActive(true).build();
        insert objAgencyInfo;
       
        List<Case> list_cases = new List<Case>();
        Case objCase = new TestDataFactory.CaseBuilder()
            .setRecordTypeId('Compliance')
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setSubject('test')
            .setType('test')
            .setDescription('Tax Res')
            .setStatus('Open')
            .setOwnerId(UserInfo.getUserId())
            .build();
        insert objCase;
        
        Case objCase1 = new TestDataFactory.CaseBuilder()
            .setRecordTypeId('Compliance')
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .setSubject('Tax Res')
            .setType('Tax Res')
            .setDescription('Tax Res')
            .setStatus('Open')
            .setParentId(objCase.Id)
            .setOwnerId(UserInfo.getUserId())
            .build();
        insert objCase1;
        
    }
    
    //For Update
    @isTest
    static void testAutopopulationOnChildCase1() {
        
        // Parent case
        List<Case> list_Cases = [SELECT Id, Subject,Status, Description, Batch_Id__c,CreatedDate,Agency_Information__r.Name, Compliance_Score__c, (SELECT Id, Agency_Due_Date__c, Eng_Due_Date__c, System_impacted__c FROM Tax_Compliance__r) FROM Case WHERE RecordType.Name = 'Compliance' LIMIT 2];
        Case objParentCase = list_Cases[0];
        
        Case objChildCase = list_Cases[1];
        Tax_Compliance__c objTaxCompliance = list_Cases[0].Tax_Compliance__r[0];
        objTaxCompliance.Agency_Due_Date__c = System.Today();
        objTaxCompliance.Eng_Due_Date__c = System.Today().addDays(1);
        objTaxCompliance.System_impacted__c = 'Compliance Tracker';
        objTaxCompliance.Classification_Type__c = 'Compliance Requirement';
        objTaxCompliance.Compliance_Team_POC__c = ' Payroll Product Compliance';
        objTaxCompliance.Customer_Count__c = 20;
        objTaxCompliance.Resource_Link__c = 'https://www.google.com';
        objTaxCompliance.EPDD_DRI__c = UserInfo.getUserId();
        objTaxCompliance.Frequency_of_Update__c = 'One time Task';
        objTaxCompliance.System_impacted__c = 'Payments & Filings';
        objTaxCompliance.Impacts__c = 'Worker Payments';
        objTaxCompliance.CX_Comms__c = 'ABCD'; 
        objTaxCompliance.Help_Center_IKB_External__c = false;
        objTaxCompliance.Help_Center_IKB_Internal__c = 'https://www.google.com';
        objTaxCompliance.Knowledge_Management_Readiness__c = true;
        objTaxCompliance.Customer_Comms__c = 'BCS';
        objTaxCompliance.In_App_content__c = 'Test ABCD';
        objTaxCompliance.Eng_Status__c = 'In progress';
        objTaxCompliance.Follow_up_Date__c = System.Today();
        objTaxCompliance.Agency_Due_Date__c = System.Today().addDays(2);
        update objTaxCompliance;
        
        Map<Id, Tax_Compliance__c> mapTaxCompliance =  new Map<Id, Tax_Compliance__c>( [SELECT Id,Name, Case__c,Case__r.Id,Case__r.CreatedDate, Case__r.OwnerId, Case__r.Owner.Name, Case__r.Status, Case__r.Case_Owner_Name__c, Case__r.Subject, Case__r.Description, Case__r.Batch_Id__c, Case__r.Agency_Information__r.Name, Case__r.Compliance_Score__c, Classification_Type__c, Compliance_Team_POC__c, Customer_Count__c, Resource_Link__c, EPDD_DRI__c , Frequency_of_Update__c, System_impacted__c, Impacts__c, CX_Comms__c, Help_Center_IKB_External__c, Help_Center_IKB_Internal__c, Knowledge_Management_Readiness__c, Customer_Comms__c , In_App_content__c, Eng_Status__c, Follow_up_Date__c, Agency_Due_Date__c,Eng_Due_Date__c, Who_Owns_this_Initiative__c,Tier__c FROM  Tax_Compliance__c limit 1]);                                                                  
        SendComplianceToAsanaRouting.RequestWrapperUpdate objRequestWrapperUpdate = new SendComplianceToAsanaRouting.RequestWrapperUpdate(mapTaxCompliance.values()[0],objParentCase,'783728');
        SendComplianceToAsanaRouting objSendComplianceToAsanaRouting1 = new SendComplianceToAsanaRouting(mapTaxCompliance, false);
        String strUpdateResponse = '{"status":"success","event_id":"a96269a0-1a11-11ef-abaf-02208e4ca769","message":"update"}';
        ComplianceAsanaUpdateResponse objResponseUpdateWrapper = ComplianceAsanaUpdateResponse.parse(strUpdateResponse);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ComplianceToAsanaCalloutMock(200));
        System.enqueueJob(objSendComplianceToAsanaRouting1);
        Test.stopTest();
    }
    
   
    
    //For Insert
    @isTest
    static void testAutopopulationOnChildCase2() {
        
        // Parent case
        List<Case> list_Cases = [SELECT Id, Subject,Status, Description, Batch_Id__c,CreatedDate,Agency_Information__r.Name, Compliance_Score__c, (SELECT Id, Agency_Due_Date__c, Eng_Due_Date__c, System_impacted__c FROM Tax_Compliance__r) FROM Case WHERE RecordType.Name = 'Compliance' LIMIT 2];
        Case objParentCase = list_Cases[0];
        
        Case objChildCase = list_Cases[1];
        Tax_Compliance__c objTaxCompliance = list_Cases[0].Tax_Compliance__r[0];
        objTaxCompliance.Agency_Due_Date__c = System.Today();
        objTaxCompliance.Eng_Due_Date__c = System.Today().addDays(1);
        objTaxCompliance.System_impacted__c = 'Compliance Tracker';
        objTaxCompliance.Classification_Type__c = 'Compliance Requirement';
        objTaxCompliance.Compliance_Team_POC__c = ' Payroll Product Compliance';
        objTaxCompliance.Customer_Count__c = 20;
        objTaxCompliance.Resource_Link__c = 'https://www.google.com';
        objTaxCompliance.EPDD_DRI__c = UserInfo.getUserId();
        objTaxCompliance.Frequency_of_Update__c = 'One time Task';
        objTaxCompliance.System_impacted__c = 'Payments & Filings';
        objTaxCompliance.Impacts__c = 'Worker Payments';
        objTaxCompliance.CX_Comms__c = 'ABCD'; 
        objTaxCompliance.Help_Center_IKB_External__c = false;
        objTaxCompliance.Help_Center_IKB_Internal__c = 'https://www.google.com';
        objTaxCompliance.Knowledge_Management_Readiness__c = true;
        objTaxCompliance.Customer_Comms__c = 'BCS';
        objTaxCompliance.In_App_content__c = 'Test ABCD';
        objTaxCompliance.Eng_Status__c = 'In progress';
        objTaxCompliance.Follow_up_Date__c = System.Today();
        objTaxCompliance.Agency_Due_Date__c = System.Today().addDays(2);
        update objTaxCompliance;
        
        Map<Id, Tax_Compliance__c> mapTaxCompliance =  new Map<Id, Tax_Compliance__c>( [SELECT Id,Name, Case__c,Case__r.Id,Case__r.CreatedDate, Case__r.OwnerId, Case__r.Owner.Name, Case__r.Status, Case__r.Case_Owner_Name__c, Case__r.Subject, Case__r.Description, Case__r.Batch_Id__c, Case__r.Agency_Information__r.Name, Case__r.Compliance_Score__c, Classification_Type__c, Compliance_Team_POC__c, Customer_Count__c, Resource_Link__c, EPDD_DRI__c , Frequency_of_Update__c, System_impacted__c, Impacts__c, CX_Comms__c, Help_Center_IKB_External__c, Help_Center_IKB_Internal__c, Knowledge_Management_Readiness__c, Customer_Comms__c , In_App_content__c, Eng_Status__c, Follow_up_Date__c, Agency_Due_Date__c,Eng_Due_Date__c, Who_Owns_this_Initiative__c,Tier__c FROM  Tax_Compliance__c limit 1]);
        SendComplianceToAsanaRouting.RequestWrapperInsert objRequestWrapperInsert = new SendComplianceToAsanaRouting.RequestWrapperInsert(mapTaxCompliance.values()[0],objParentCase,'1206129625555843','783728');
        SendComplianceToAsanaRouting objSendComplianceToAsanaRouting2 = new SendComplianceToAsanaRouting(mapTaxCompliance, true);
        Asana_Project_Detail__mdt objAsanaProjectDetail = Asana_Project_Detail__mdt.getInstance('Gusto_Compliance_Watchlist_RoadMap');
        String strInsertResponse = '{"status":"success","event_id":"a96269a0-1a11-11ef-abaf-02208e4ca769","error_message":"test","message":{"asana_task_id":"12345"}}'; 
        ComplianceAsanaIntegrationResponse objResponseWrapper = ComplianceAsanaIntegrationResponse.parse(strInsertResponse);
 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ComplianceToAsanaCalloutMock(200));  
        System.enqueueJob(objSendComplianceToAsanaRouting2);
        Test.stopTest();
    }
    
    
    //To Handle Exception
     @isTest
    static void testAutopopulationOnChildCaseExceptionHandle() {
        
        // Parent case
        List<Case> list_Cases = [SELECT Id, Subject,Status, Description, Batch_Id__c, Agency_Information__r.Name, Compliance_Score__c, (SELECT Id, Agency_Due_Date__c, Eng_Due_Date__c, System_impacted__c FROM Tax_Compliance__r) FROM Case WHERE RecordType.Name = 'Compliance' LIMIT 2];
        Case objParentCase = list_Cases[0];
        
        Case objChildCase = list_Cases[1];
        Tax_Compliance__c objTaxCompliance = list_Cases[0].Tax_Compliance__r[0];
        objTaxCompliance.Agency_Due_Date__c = System.Today();
        objTaxCompliance.Eng_Due_Date__c = System.Today().addDays(1);
        objTaxCompliance.System_impacted__c = 'Compliance Tracker';
        objTaxCompliance.Classification_Type__c = 'Compliance Requirement';
        objTaxCompliance.Compliance_Team_POC__c = ' Payroll Product Compliance';
        objTaxCompliance.Customer_Count__c = 20;
        objTaxCompliance.Resource_Link__c = 'https://www.google.com';
        objTaxCompliance.EPDD_DRI__c = UserInfo.getUserId();
        objTaxCompliance.Frequency_of_Update__c = 'One time Task';
        objTaxCompliance.System_impacted__c = 'Payments & Filings';
        objTaxCompliance.Impacts__c = 'Worker Payments';
        objTaxCompliance.CX_Comms__c = 'ABCD'; 
        objTaxCompliance.Help_Center_IKB_External__c = false;
        objTaxCompliance.Help_Center_IKB_Internal__c = 'https://www.google.com';
        objTaxCompliance.Knowledge_Management_Readiness__c = true;
        objTaxCompliance.Customer_Comms__c = 'BCS';
        objTaxCompliance.In_App_content__c = 'Test ABCD';
        objTaxCompliance.Eng_Status__c = 'In progress';
        objTaxCompliance.Follow_up_Date__c = System.Today();
        objTaxCompliance.Agency_Due_Date__c = System.Today().addDays(2);
        update objTaxCompliance;
        
        Map<Id, Tax_Compliance__c> mapTaxCompliance =  new Map<Id, Tax_Compliance__c>( [SELECT Id,Name, Case__c,Case__r.Id,Case__r.CreatedDate, Case__r.OwnerId, Case__r.Owner.Name, Case__r.Status, Case__r.Case_Owner_Name__c, Case__r.Subject, Case__r.Description, Case__r.Batch_Id__c, Case__r.Agency_Information__r.Name, Case__r.Compliance_Score__c, Classification_Type__c, Compliance_Team_POC__c, Customer_Count__c, Resource_Link__c, EPDD_DRI__c , Frequency_of_Update__c, System_impacted__c, Impacts__c, CX_Comms__c, Help_Center_IKB_External__c, Help_Center_IKB_Internal__c, Knowledge_Management_Readiness__c, Customer_Comms__c , In_App_content__c, Eng_Status__c, Follow_up_Date__c, Agency_Due_Date__c,Eng_Due_Date__c, Who_Owns_this_Initiative__c,Tier__c FROM  Tax_Compliance__c]);
        SendComplianceToAsanaRouting objSendComplianceToAsanaRouting2 = new SendComplianceToAsanaRouting(mapTaxCompliance, true);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ComplianceToAsanaCalloutMock(200));
        System.enqueueJob(objSendComplianceToAsanaRouting2);      
        Test.stopTest();
    }
    
    //For Status Code 400 on Insert
    @isTest
    static void testAutopopulationOnChildCase3() {
        
        // Parent case
        List<Case> list_Cases = [SELECT Id, Subject,Status, Description, Batch_Id__c, Agency_Information__r.Name, Compliance_Score__c, (SELECT Id, Agency_Due_Date__c, Eng_Due_Date__c, System_impacted__c FROM Tax_Compliance__r) FROM Case WHERE RecordType.Name = 'Compliance' LIMIT 2];
        Case objParentCase = list_Cases[0];
        
        Case objChildCase = list_Cases[1];
        Tax_Compliance__c objTaxCompliance = list_Cases[0].Tax_Compliance__r[0];
        objTaxCompliance.Agency_Due_Date__c = System.Today();
        objTaxCompliance.Eng_Due_Date__c = System.Today().addDays(1);
        objTaxCompliance.System_impacted__c = 'Compliance Tracker';
        objTaxCompliance.Classification_Type__c = 'Compliance Requirement';
        objTaxCompliance.Compliance_Team_POC__c = ' Payroll Product Compliance';
        objTaxCompliance.Customer_Count__c = 20;
        objTaxCompliance.Resource_Link__c = 'https://www.google.com';
        objTaxCompliance.EPDD_DRI__c = UserInfo.getUserId();
        objTaxCompliance.Frequency_of_Update__c = 'One time Task';
        objTaxCompliance.System_impacted__c = 'Payments & Filings';
        objTaxCompliance.Impacts__c = 'Worker Payments';
        objTaxCompliance.CX_Comms__c = 'ABCD'; 
        objTaxCompliance.Help_Center_IKB_External__c = false;
        objTaxCompliance.Help_Center_IKB_Internal__c = 'https://www.google.com';
        objTaxCompliance.Knowledge_Management_Readiness__c = true;
        objTaxCompliance.Customer_Comms__c = 'BCS';
        objTaxCompliance.In_App_content__c = 'Test ABCD';
        objTaxCompliance.Eng_Status__c = 'In progress';
        objTaxCompliance.Follow_up_Date__c = System.Today();
        objTaxCompliance.Agency_Due_Date__c = System.Today().addDays(2);
        update objTaxCompliance;
        
        Map<Id, Tax_Compliance__c> mapTaxCompliance =  new Map<Id, Tax_Compliance__c>( [SELECT Id,Name, Case__c,Case__r.Id,Case__r.CreatedDate, Case__r.OwnerId, Case__r.Owner.Name, Case__r.Status, Case__r.Case_Owner_Name__c, Case__r.Subject, Case__r.Description, Case__r.Batch_Id__c, Case__r.Agency_Information__r.Name, Case__r.Compliance_Score__c, Classification_Type__c, Compliance_Team_POC__c, Customer_Count__c, Resource_Link__c, EPDD_DRI__c , Frequency_of_Update__c, System_impacted__c, Impacts__c, CX_Comms__c, Help_Center_IKB_External__c, Help_Center_IKB_Internal__c, Knowledge_Management_Readiness__c, Customer_Comms__c , In_App_content__c, Eng_Status__c, Follow_up_Date__c, Agency_Due_Date__c,Eng_Due_Date__c, Who_Owns_this_Initiative__c,Tier__c FROM  Tax_Compliance__c limit 1]);
        SendComplianceToAsanaRouting objSendComplianceToAsanaRouting2 = new SendComplianceToAsanaRouting(mapTaxCompliance, true);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ComplianceToAsanaCalloutMock(400));
        System.enqueueJob(objSendComplianceToAsanaRouting2);
        Test.stopTest();
    }
    
    //For Status Code 400 on Update
    @isTest
    static void testAutopopulationOnChildCase4() {
        
        // Parent case
        List<Case> list_Cases = [SELECT Id, Subject,Status, Description, Batch_Id__c, Agency_Information__r.Name, Compliance_Score__c, (SELECT Id, Agency_Due_Date__c, Eng_Due_Date__c, System_impacted__c FROM Tax_Compliance__r) FROM Case WHERE RecordType.Name = 'Compliance' LIMIT 2];
        Case objParentCase = list_Cases[0];
        
        Case objChildCase = list_Cases[1];
        Tax_Compliance__c objTaxCompliance = list_Cases[0].Tax_Compliance__r[0];
        objTaxCompliance.Agency_Due_Date__c = System.Today();
        objTaxCompliance.Eng_Due_Date__c = System.Today().addDays(1);
        objTaxCompliance.System_impacted__c = 'Compliance Tracker';
        objTaxCompliance.Classification_Type__c = 'Compliance Requirement';
        objTaxCompliance.Compliance_Team_POC__c = ' Payroll Product Compliance';
        objTaxCompliance.Customer_Count__c = 20;
        objTaxCompliance.Resource_Link__c = 'https://www.google.com';
        objTaxCompliance.EPDD_DRI__c = UserInfo.getUserId();
        objTaxCompliance.Frequency_of_Update__c = 'One time Task';
        objTaxCompliance.System_impacted__c = 'Payments & Filings';
        objTaxCompliance.Impacts__c = 'Worker Payments';
        objTaxCompliance.CX_Comms__c = 'ABCD'; 
        objTaxCompliance.Help_Center_IKB_External__c = false;
        objTaxCompliance.Help_Center_IKB_Internal__c = 'https://www.google.com';
        objTaxCompliance.Knowledge_Management_Readiness__c = true;
        objTaxCompliance.Customer_Comms__c = 'BCS';
        objTaxCompliance.In_App_content__c = 'Test ABCD';
        objTaxCompliance.Eng_Status__c = 'In progress';
        objTaxCompliance.Follow_up_Date__c = System.Today();
        objTaxCompliance.Agency_Due_Date__c = System.Today().addDays(2);
        update objTaxCompliance;
        
        Map<Id, Tax_Compliance__c> mapTaxCompliance =  new Map<Id, Tax_Compliance__c>( [SELECT Id,Name, Case__c,Case__r.Id,Case__r.CreatedDate, Case__r.OwnerId, Case__r.Owner.Name, Case__r.Status, Case__r.Case_Owner_Name__c, Case__r.Subject, Case__r.Description, Case__r.Batch_Id__c, Case__r.Agency_Information__r.Name, Case__r.Compliance_Score__c, Classification_Type__c, Compliance_Team_POC__c, Customer_Count__c, Resource_Link__c, EPDD_DRI__c , Frequency_of_Update__c, System_impacted__c, Impacts__c, CX_Comms__c, Help_Center_IKB_External__c, Help_Center_IKB_Internal__c, Knowledge_Management_Readiness__c, Customer_Comms__c , In_App_content__c, Eng_Status__c, Follow_up_Date__c, Agency_Due_Date__c,Eng_Due_Date__c, Who_Owns_this_Initiative__c,Tier__c FROM  Tax_Compliance__c limit 1]);
        SendComplianceToAsanaRouting objSendComplianceToAsanaRouting1 = new SendComplianceToAsanaRouting(mapTaxCompliance, false);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ComplianceToAsanaCalloutMock(400));    
        System.enqueueJob(objSendComplianceToAsanaRouting1);
        Test.stopTest();
    }
      
}