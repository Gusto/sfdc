@isTest
public class FilesComponentController_Test {
   public static Attachment obj;
   public static Case caseObj1;
    public static ContentVersion contentVersionInsert;
   static {
        caseObj1 = new Case();
        caseObj1.Subject = 'Om Test';  
        caseObj1.Status ='New';
        caseObj1.Priority = 'Medium';
        caseObj1.Origin = 'Email';
        insert caseObj1;

        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = caseObj1.Id; 
        insert email;
        
        obj = new Attachment();
        obj.Body = Blob.valueOf('I am doing good');
        obj.ParentId = email.Id;
        obj.Name = 'Dummy.pdf';
        obj.ContentType = 'application/pdf';
        insert obj;
       
        contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
       
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1].ContentDocumentId;
        cdl.LinkedEntityId = caseObj1.Id;
        cdl.shareType = 'V';
        insert cdl;
       
   }
    static testMethod void renameFilePositiveScenario(){  
        Test.startTest();
        FilesComponentController.renameFile('Test', obj.id, true);        
        FilesComponentController.returnFilesList(caseObj1.id, false);
        FilesComponentController.getAttachmentRecord(''+obj.id);
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        FilesComponentController.returnFilesList(caseObj1.id, true);
        System.assertEquals(documents.size(), 1);
        Test.stopTest();
    }
    static testMethod void renameFileNegativeScenario(){
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];        
        Test.startTest();
        FilesComponentController.renameFile('Test', documents[0].id, false);
        FilesComponentController.renameFile('Test', documents[0].id, true);
        System.assertEquals(documents.size(), 1);
        Test.stopTest();
    }
}