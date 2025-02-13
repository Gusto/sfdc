@isTest
public class TaxComplianceControllerTest {

    @TestSetup
    static void setupTestData() {
        Case objParentCase = TestDataFactory.createCaseRecord('Compliance', true);
        Case objChildCase = TestDataFactory.createCaseRecord('Compliance', true);
    }

    /**
     * @Author      : Sindhu
     * @Description : validate "TaxComplianceController.prePopulateComplianceChildCaseDetails" method
     * @Parm        : NA
     * @Return      : NA
     **/
    @isTest
    static void testAutopopulationOnChildCase() {
        Test.startTest();
        // Parent case
        List<Case> list_Cases = [SELECT Id, Subject, (SELECT Id, Agency_Due_Date__c, Eng_Due_Date__c, System_impacted__c FROM Tax_Compliance__r) FROM Case WHERE RecordType.Name = 'Compliance' LIMIT 2];
        Case objParentCase = list_Cases[0];
        Case objChildCase = list_Cases[1];
        
        Tax_Compliance__c objTaxCompliance;
        if(objParentCase.Tax_Compliance__r == null || objParentCase.Tax_Compliance__r.size()== 0 ) {
        	objTaxCompliance = new Tax_Compliance__c(Case__c = objParentCase.Id);
            insert objTaxCompliance;
        } else {
            objTaxCompliance = objParentCase.Tax_Compliance__r[0];
        }
        
        System.assertEquals(true, objTaxCompliance.Id != null, 'Tax compliance not generated');
        ContentVersion objContentVersion = new TestDataFactory.ContentVersionBuilder().setFlowCreated(false).setPathOnClient('test.pdf').setTitle('test').setVersionData(Blob.valueOf('sample content1')).build();
        insert objContentVersion;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id].ContentDocumentId;

        TestDataFactory.ContentDocumentLinkBuilder objContentDocumentLinkBuilder = new TestDataFactory.ContentDocumentLinkBuilder();

        objContentDocumentLinkBuilder.setContentDocumentId(String.valueOf(contentDocumentId));
        objContentDocumentLinkBuilder.setLinkedEntityId(String.valueOf(objParentCase.Id));
        ContentDocumentLink objContentDocumentLink = objContentDocumentLinkBuilder.build();
        insert objContentDocumentLink;

        Tax_Compliance__c objParentTaxCompliance = objTaxCompliance;
        objParentTaxCompliance.Agency_Due_Date__c = System.Today();
        objParentTaxCompliance.Eng_Due_Date__c = System.Today().addDays(1);
        objParentTaxCompliance.System_impacted__c = 'Compliance Tracker';
        update objParentTaxCompliance;

        // Update child case
        objChildCase.ParentId = objParentCase.Id;
        update objChildCase;
        
		Tax_Compliance__c objTaxComplianceChild;
        if(objChildCase.Tax_Compliance__r == null || objChildCase.Tax_Compliance__r.size()== 0 ) {
        	objTaxComplianceChild = new Tax_Compliance__c(Case__c = objChildCase.Id);
            insert objTaxComplianceChild;
        } else {
            objTaxComplianceChild = objChildCase.Tax_Compliance__r[0];
        }
        
        List<case> list_ChildCases = [SELECT Id,ParentId FROM Case WHERE Id =: objChildCase.Id];
        TaxComplianceController.prePopulateComplianceChildCaseDetails(list_ChildCases);
        
        List<Case> list_ChildCase = [SELECT Id, Subject, (SELECT Id, Agency_Due_Date__c, Eng_Due_Date__c, System_impacted__c FROM Tax_Compliance__r) FROM Case WHERE ID =: objChildCase.Id];
        System.assertEquals(objParentCase.Subject, list_ChildCase[0].Subject, 'Subject not copied to child case');
        System.assertEquals(objParentTaxCompliance.Agency_Due_Date__c, list_ChildCase[0].Tax_Compliance__r[0].Agency_Due_Date__c, 'Agency Due Date not copied');
        System.assertEquals(objParentTaxCompliance.Eng_Due_Date__c, list_ChildCase[0].Tax_Compliance__r[0].Eng_Due_Date__c, 'Eng Due Date not copied');

        Test.stopTest();
    }
    
    /**
     * @Author      : Rinkita
     * @Description : validate "TaxComplianceController.createEmailMessage" method
     * @Parm        : NA
     * @Return      : NA
     **/
    @isTest
    static void testCreateEmailMessageForCase() {
        //EmailMessage Object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        List<String> list_toAddresses= new List<String>();
        list_toAddresses.add('receive@test.com');
        email.subject = 'Test Contact Email';
        email.toAddresses  = list_toAddresses;
        email.ccAddresses  = list_toAddresses;
        email.fromAddress = 'test@test.com';
        email.HtmlBody = 'Test Contact Email html';
        email.plainTextBody  = 'Test Contact Email plain text';
        email.fromAddress = 'test@test.com';
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
         
        Test.startTest();
        Case cs = [SELECT Id FROM Case WHERE RecordType.Name = 'Compliance' LIMIT 1];
        
        TaxComplianceController.createEmailMessage(cs, email);
        EmailMessage emailMsg = [Select id, Subject from EmailMessage where parentId =: cs.Id];
        ContentDocumentLink contDocLink = [select id from ContentDocumentLink where LinkedEntityId =: emailMsg.Id];
        
        Assert.isNotNull(emailMsg, 'EmailMessage not created successfully');
        System.assertEquals('Test Contact Email', emailMsg.subject, 'Agency Due Date not copied');
        Assert.isNotNull(emailMsg, 'Attachment not created successfully');

        Test.stopTest();
    }

}