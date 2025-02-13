@isTest
public class CaseMergeLightningController_Test {
    @isTest
    static void caseMergeScenario(){
        Case caseObj = new Case(Status = 'New', Origin = 'Phone'); 
        insert caseObj;
        
        Test.startTest();
        CaseMergeLightningController.getCaseData(caseObj.id);
        
        Case c = [Select id,status from case where id = : caseObj.id];
        System.assertEquals(c.status, 'Closed');
        Test.stopTest();
    }
    static testMethod void getCaseData(){
        Case caseObj = new Case(
            Status = 'New', 
            Origin = 'Phone',
            RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care')
        ); 
        insert caseObj;
        
        Test.startTest();
        CaseMergeLightningController.activateCaseAssignmentRules(caseObj.id);
        
        Case c = [SELECT Id, Status FROM Case WHERE Id = : caseObj.id];
        System.assertEquals(c.status, 'New');
        Test.stopTest();
    }
    static testMethod void setCaseOwner(){
        Case caseObj = new Case(
            Status = 'New',
            Origin = 'Phone',
            RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care')
        ); 
        insert caseObj;
        
        Test.startTest();
        CaseMergeLightningController.setCaseOwner(UserInfo.getUserId(), caseObj.id);
        
        Case c = [SELECT Id, Status FROM Case WHERE Id = : caseObj.id];
        System.assertEquals(c.status, 'New');
        Test.stopTest();
    }
    @isTest
    static void testInsertChatterFeed(){
        Case objCase = new Case(Status = 'New', Origin = 'Phone'); 
        insert objCase;
        String strCaseNumber;
        List<Case> lst_case = [SELECT Id,CaseNumber FROM Case WHERE Id = :objCase.Id];
        for(Case objCaseNmbr : lst_case){
            strCaseNumber = objCaseNmbr.CaseNumber;
        }
        
        Case objNewCase = new Case(Status = 'Open', Origin = 'Web');
        insert objNewCase;
        
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = objCase.Id; 
        insert email;
        
        Attachment obj = new Attachment();
        obj.Body = Blob.valueOf('I am doing good');
        obj.ParentId = email.Id;
        obj.Name = 'Dummy.pdf';
        obj.ContentType = 'application/pdf';
        insert obj;
        
        FeedItem feed = new FeedItem (
            parentid = objCase.id,
            Type = 'TextPost',
            Body = 'Hello');
            insert feed ; 
        
        FeedComment fc = new FeedComment(CommentBody='Test Comment',FeedItemId = feed.Id);
        insert fc;
        
        Test.startTest();
        String strFeed = CaseMergeLightningController.insertChatterFeed(objCase.Id, strCaseNumber, objNewCase.Id);
        Test.stopTest();
    }

    /*
    * @author:         Ankit CS
    * @description:    Test method for insertCaseChatterNotes()
    */
    @isTest
    static void testInsertCaseChatterNotes() {
        List<Case> list_Cases = new List<Case>();
        Case objCase1 = new TestDataFactory.CaseBuilder()
            .setSubject('Test Phone Case')
            .setOrigin('Phone')
            .setDescription('Phone Case')
            .setRecordTypeId('Payroll Care')
            .build();
        list_Cases.add(objCase1);

        Case objCase2 = new TestDataFactory.CaseBuilder()
            .setSubject('Test Followup Case')
            .setOrigin('Follow Up Email')
            .setDescription('Followup case')
            .setRecordTypeId('Payroll Care')
            .build();
        list_Cases.add(objCase2);

        insert list_Cases;

        Map<String, String> map_Fields = new Map<String, String>();
        map_Fields.put('Subject', objCase2.Subject);
        map_Fields.put('Description', objCase2.Description);
        map_Fields.put('Customer_Query_Request__c', 'Test Customer Request');
        map_Fields.put('Action_Correction_Needed__c', 'Test Action Needed');
        map_Fields.put('Reason_for_Follow_up_Case__c', 'Out of Scope');

        ConnectApi.FeedElementPage objTestPage = new ConnectApi.FeedElementPage();
        List<ConnectApi.FeedItem> list_TestItem = new List<ConnectApi.FeedItem>();
        list_TestItem.add(new ConnectApi.FeedItem());
        objTestPage.Elements = list_TestItem;
        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null, ConnectApi.FeedType.RECORD, 'me', objTestPage);

        Test.startTest();
        CaseMergeLightningController.insertCaseChatterNotes(objCase1.Id, objCase2.Id, map_Fields);
        Test.stopTest();
        System.assertEquals(1, ConnectAPIMock.getFeedCount());
    }
}