/**
* @name         ComplianceInboundEmailHandlerTest
* @author       Sindhu
* @date         26th April 2024
* @description  Test class for TaxComplainceEmailHandler & PayrollProductComplianceEmailHandler class
* @revisions    Date ------------ Name ------------ Comments
*/
@isTest
public class ComplianceInboundEmailHandlerTest {
    @isTest
    static void testHandleInboundEmail() {
        // Test data setup        
        Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
        objEmail.fromAddress = 'test@example.com';
        objEmail.subject = 'Test Subject';
        objEmail.plainTextBody = 'Test Description';
        objEmail.headers = (List<Messaging.InboundEmail.Header>) JSON.deserialize(
            '[{"value": "emailAdress","name": "test@example.com"}]}',
            List<Messaging.InboundEmail.Header>.class
        );
        
        // Create a test binary attachment
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.body = Blob.valueOf('Test Attachment Content');
        binaryAttachment.fileName = 'TestAttachment.txt';
        objEmail.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{binaryAttachment};
            
            Compliance_Incoming_Email_Settings__mdt objSettings = new Compliance_Incoming_Email_Settings__mdt(
                Domain_Name__c = 'example.com',
                OCR_Message__c = 'Test OCR Message',
                Origin__c = 'Email',
                Priority__c = 'Medium',
                Queue_Name__c = 'Test Queue',
                Record_Type_Name__c = 'Test Record Type',
                Service_Email__c = 'test@example.com',
                Status__c = 'New',
                Subject__c = 'Test'
            );
        
        Group objGroup = new Group(Type = 'Queue', Name = 'Test Queue');
        insert objGroup;
        
        // Call handleInboundEmail method
        Test.startTest();
        TaxComplianceEmailHandler handlerTaxCompliance = new TaxComplianceEmailHandler();
        Messaging.InboundEmailResult resultTaxCompliance = handlerTaxCompliance.handleInboundEmail(objEmail, null);
        PayrollProductComplianceEmailHandler handlerPayrollProduct = new PayrollProductComplianceEmailHandler(); 
        Messaging.InboundEmailResult resultPayrollProduct = handlerPayrollProduct.handleInboundEmail(objEmail, null);
        Test.stopTest();
        System.assertEquals(true, resultTaxCompliance.success, 'Inbound email handling failed for TaxComplianceEmailHandler');
        System.assertEquals(true, resultPayrollProduct.success, 'Inbound email handling failed for PayrollProductComplianceEmailHandler');
        
        // Verify case creation
        List<Case> list_Cases = [SELECT Id, Priority, Origin, OwnerId, Subject, Type, OCR_Message__c, RecordTypeId, Status FROM Case];
        System.assertEquals(2, list_Cases.size());
        Case objCase = list_Cases[0];
        System.assertEquals(CaseUtils.STRG_MEDIUM, objCase.Priority, 'Incorrect Priority');
        System.assertEquals(CaseUtils.ORIGIN_EMAIL, objCase.Origin, 'Incorrect Origin');
        System.assertEquals('Test Subject', objCase.Subject, 'Incorrect Subject');
        System.assertEquals(CaseUtils.STRG_NEW, objCase.Status, 'Incorrect Status');
        
        
        
        // Verify tax compliance record creation
        List<Tax_Compliance__c> list_TaxComplianceRecords = [SELECT Id, Case__c, Tier__c, Frequency_of_Update__c, Classification_Type__c FROM Tax_Compliance__c];
        System.assertEquals(2, list_TaxComplianceRecords.size());
        Tax_Compliance__c objTaxComplianceRecord = list_TaxComplianceRecords[0];
        System.assertEquals(objCase.Id, objTaxComplianceRecord.Case__c, 'Incorrect Case Id');
        //System.assertEquals(CaseUtils.STRG_TIER, objTaxComplianceRecord.Tier__c, 'Incorrect Tier'); 
        //System.assertEquals(CaseUtils.STRG_FREQUENCT_OF_UPDATE, objTaxComplianceRecord.Frequency_of_Update__c, 'Incorrect Frequency of Update');
        //System.assertEquals(CaseUtils.STRG_ClASSIFICATION_TYPE, objTaxComplianceRecord.Classification_Type__c, 'Incorrect Classification Type'); 
        
    }
    
    @isTest
    static void testHandleInboundEmailException() {
        // Test data setup        
        Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
        objEmail.fromAddress = 'test@example.com';
        objEmail.subject = '[.!Test Subject:ref]';
        objEmail.plainTextBody = 'Test Description';
        objEmail.headers = (List<Messaging.InboundEmail.Header>) JSON.deserialize(
            '[{"value": "emailAdress","name": "test@example.com"}]}',
            List<Messaging.InboundEmail.Header>.class
        );
        
        // Create a test binary attachment
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.body = Blob.valueOf('Test Attachment Content');
        binaryAttachment.fileName = 'TestAttachment.txt';
        objEmail.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{binaryAttachment};
            
            Compliance_Incoming_Email_Settings__mdt objSettings = new Compliance_Incoming_Email_Settings__mdt(
                Domain_Name__c = 'example.com',
                OCR_Message__c = 'Test OCR Message',
                Origin__c = 'Email',
                Priority__c = 'Medium',
                Queue_Name__c = 'Test Queue',
                Record_Type_Name__c = 'Test Record Type',
                Service_Email__c = 'test@example.com',
                Status__c = 'New',
                Subject__c = 'Test'
            );
        
        Group objGroup = new Group(Type = 'Queue', Name = 'Test Queue');
        insert objGroup;
        
        // Call handleInboundEmail method
        Test.startTest();
        TaxComplianceEmailHandler handlerTaxCompliance = new TaxComplianceEmailHandler();
        Messaging.InboundEmailResult resultTaxCompliance = handlerTaxCompliance.handleInboundEmail(objEmail, null);
        PayrollProductComplianceEmailHandler handlerPayrollProduct = new PayrollProductComplianceEmailHandler(); 
        Messaging.InboundEmailResult resultPayrollProduct = handlerPayrollProduct.handleInboundEmail(objEmail, null);
        Test.stopTest();
        System.assertEquals(true, resultTaxCompliance.success, 'Inbound email handling failed for TaxComplianceEmailHandler');
        System.assertEquals(true, resultPayrollProduct.success, 'Inbound email handling failed for PayrollProductComplianceEmailHandler');
        
    }
}