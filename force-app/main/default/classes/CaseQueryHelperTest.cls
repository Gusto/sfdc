/*
@Author:        David (Dato) Tsamalashvili
@Created Date:  09/17/2019
@Description:   Test Class for - CaseQueryHelper
*/
@isTest
public class CaseQueryHelperTest{
    @TestSetup
    static void setup(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<EmailTemplate> list_EmailTemplate = new List<EmailTemplate>{
                new EmailTemplate(
                    DeveloperName = CaseTriggerHelper.AUTO_EMAIL_SIGNATURE_NAME, 
                    FolderId = UserInfo.getUserId(), 
                    TemplateType= 'Text', 
                    Name = 'Auto Email Signature'
                    ),
                new EmailTemplate(
                    DeveloperName = Label.Suspension_Case_Audit_Email_Template_Unique_Name, 
                    FolderId = UserInfo.getUserId(), 
                    TemplateType= 'Text', 
                    Name = Label.Suspension_Case_Audit_Email_Template_Unique_Name
                    )
            };
            insert list_EmailTemplate;
        }
    }

    @isTest
    public static void testGetSuspCaseMailTtemplate(){
        Test.startTest();
        System.assertEquals(false, CaseTriggerHelper.map_EmailTemplates.isEmpty());
        //Yuvraj : 21-05-2020 to cover getCaseContacts and queryCaseContacts
        Contact objContact = new Contact();
        objContact.LastName ='Cont last name';
        objContact.ZP_Phone__c = '172712';
        insert objContact;
         
        Set<Id> conId = new Set<Id>();
        conId.add(objContact.id);
        
        List<Contact> list_contact =CaseQueryHelper.getCaseContacts(conId);
        //Yuvraj : 21-05-2020 to cover getCaseContacts and queryCaseContacts getSubCaseReason,querySubCaseReaso
        List<String> list_caseReason = new List<String>();
        list_caseReason.add('case reason');
        CaseQueryHelper.getSubCaseReason(list_caseReason);
        
        Test.stopTest();
    }
    
    static testMethod void testGetIVRLogs(){
        IVR_Routing_Log__c ivrObj = new IVR_Routing_Log__c(ConversationId__c = 'test');
        insert ivrObj;
        List<String> ivrList = new List<String>();
        ivrList.add(ivrObj.ConversationId__c);
        
        Test.startTest();
        CaseQueryHelper.getIVRLogs(ivrList);
        Test.stopTest();
    }
    
    static testMethod void testGetContactsFromPhone(){
        Contact objContact = new Contact();
        objContact.LastName ='Cont last name';
        objContact.Normalized_Phone__c = '266372';
        objContact.Normalized_Other_Phone__c = '882827';
        objContact.Normalized_Mobile_Phone__c = 'test';
        objContact.ZP_Phone__c = '172712';
        insert objContact;
        
        List<String> conPhoneList = new List<String>();
        conPhoneList.add(objContact.Normalized_Phone__c);
        conPhoneList.add(objContact.Normalized_Other_Phone__c);
        conPhoneList.add(objContact.Normalized_Mobile_Phone__c);
        conPhoneList.add(objContact.ZP_Phone__c);
        
        CaseQueryHelper.getContactsFromPhone(conPhoneList);
        
    }
    
    static testMethod void testGetMassEmail(){
        Set<Id> caseIdSet = new Set<Id>();
        Case cse = TestDataFactory.createCaseRecord('Payroll Care', true);
        caseIdSet.add(cse.Id);
        
        Test.startTest();
        CaseQueryHelper.getMassEmailCases(caseIdSet);
        Test.stopTest();
    }
}