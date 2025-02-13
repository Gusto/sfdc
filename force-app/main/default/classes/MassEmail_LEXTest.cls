@isTest
public class MassEmail_LEXTest {
    static testMethod void testFetchSearchResults(){
        //Method to fetch cases on the basis of queues and case reasons
        Group groupObj = [SELECT Id, Name, DeveloperName, Email, Type 
                          FROM Group 
                          WHERE Type = 'Queue' 
                          AND Name = 'Care Payroll Class 1' 
                          LIMIT 1];
        String queueName = groupObj.Name;
        String caseReason;
        Case cse = new Case();
        cse.Subject='Test MassEmail LEX';
        cse.Description='Test';
        cse.Origin='Email';
        cse.SuppliedEmail = 'test.test1@test.com';
        insert cse;
        
        List<Case> caseList = [ SELECT 
                                    Id,
                                    Routing_Case_Reason_Classification__r.Name,
                                    CaseNumber 
                                FROM Case 
                                WHERE Subject = 'Test MassEmail LEX'];
        for(Case caseObj : caseList){
            caseReason = caseObj.Routing_Case_Reason_Classification__r.Name;
        }
        Test.startTest();
        List<Case> fetchCaseList = MassEmail_LEX.fetchSearchResults(queueName,caseReason);
        System.assertEquals(true, caseList.size()>0);
        Test.stopTest();
    }
    
    static testMethod void testQueryQueues(){
        // Method to get all the queues.
        List<Group> queueNameList =  MassEmail_LEX.queryQueues();
        System.assertEquals(true, queueNameList.size()>0);  
    }
    
    static testMethod void testFetchCaseReasons(){
        //Method to fetch case reasons on the basis of queue selected
        Group groupObj = [SELECT Id, Name, DeveloperName, Email, Type 
                          FROM Group 
                          WHERE Type ='Queue' 
                          AND Name = 'Care Payroll Class 1' 
                          LIMIT 1];
        String queueName = groupObj.Name;
        
        Test.startTest();
        List<Case> caseList = MassEmail_LEX.fetchCaseReasons(queueName);
        System.assertEquals(false,caseList.size()>0);
        Test.stopTest();
    }
    
    static testMethod void testGetFolderNames(){
        //Method to fetch email template folder names
        Test.startTest();
        Map<String,String> tempMap = MassEmail_LEX.fetchEmailFolderNames();
        System.assertEquals(true, tempMap.size()>0);
        Test.stopTest();
    }
    
    static testMethod void testSendEmail(){
        List<Case> list_Cases = new List<Case>();
        List<String> list_CaseIds = new List<String>();
        //Method to send email
        EmailTemplate objTemplate = new EmailTemplate();
        objTemplate.isActive = true;
        objTemplate.Name = 'name';
        objTemplate.DeveloperName = 'email_temp_name';
        objTemplate.TemplateType = 'text';
        objTemplate.HtmlValue = 'test stuff';
        objTemplate.FolderId = UserInfo.getUserId();
        
        String strTemplate = JSON.serialize(objTemplate);
        for (Integer i = 0; i < 5; i++) {
            Case objCase = new Case();
            objCase.Subject = 'Test MassEmail LEX';
            objCase.Description = 'Test';
            objCase.Origin = 'Email';
            objCase.SuppliedEmail = 'test.test1@test.com';
            list_Cases.add(objCase);
        }
        insert list_Cases;
        for (Case objCase: list_Cases) {
            list_CaseIds.add(objCase.Id);  
        }
        Test.startTest();
        MassEmail_LEX.sendEmail(strTemplate, list_CaseIds, true); 
        Test.stopTest(); 
        List<EmailMessage> list_Messages = [SELECT Id FROM EmailMessage WHERE ParentId IN :list_Cases];
        System.assertEquals(5, list_Messages.size(), 'EmailMessage records were not created for all cases');
    }
    
    static testMethod void testFetchTemplate(){
        MassEmail_LEX.fetchAllEmailTemplates();
    }
    
    static testMethod void testDisplayTemplate(){
        EmailTemplate objTemplate = new EmailTemplate();
        objTemplate.isActive = true;
        objTemplate.Name = 'nameTest';
        objTemplate.DeveloperName = 'email_temp_name';
        objTemplate.TemplateType = 'text';
        objTemplate.HtmlValue = 'test stuff';
        objTemplate.Description = 'test desc';
        objTemplate.FolderId = UserInfo.getUserId();
        insert objTemplate;
        
        Test.startTest();        
        EmailTemplate objTemp = MassEmail_LEX.displayTemplate(objTemplate.Id);
        System.assertEquals(true, (objTemp.Id != null));
        Test.stopTest();
    }
    
    static testMethod void testUpdateCaseAndAttachEmail(){
        List<Case> list_Cases = new List<Case>();
        List<EmailMessage> list_EmailMessage = new List<EmailMessage>();
        for (Integer i = 0; i < 5; i++) {
            Case objCase = new Case();
            objCase.Subject = 'Test MassEmail LEX';
            objCase.Description = 'Test';
            objCase.Origin = 'Email';
            objCase.SuppliedEmail = 'test.test1@test.com';
            list_Cases.add(objCase);
        }
        insert list_Cases;
        String strListCases = JSON.serialize(list_Cases);

        EmailMessage objEmailMsg = new EmailMessage(); // Created a EmailMessage and copy all details.
        objEmailMsg.ToAddress = 'testUser@test.com';
        objEmailMsg.Subject = 'Test Subject';
        objEmailMsg.HtmlBody = '<br></br><font color="white">test</font>';
        objEmailMsg.ParentId = list_Cases[0].Id; //Attaching with the case
        objEmailMsg.MessageDate = System.now(); 
        objEmailMsg.Status = '0';
        objEmailMsg.fromAddress = 'testEmail@gusto.com';            
        list_EmailMessage.add(objEmailMsg);
        String strListEmail = JSON.serialize(list_EmailMessage);

        Test.startTest();
        MassEmail_LEX.updateCaseAndAttachEmail(strListCases, strListEmail, true);
        Test.stopTest();
        List<EmailMessage> list_Messages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
        System.assert(!list_Messages.isEmpty(), 'EmailMessage record was not created');
    }

    static testMethod void testUpdateCaseAndAttachEmailWithoutThrowingError() {
        List<Case> list_Cases = new List<Case>();
        List<EmailMessage> list_EmailMessage = new List<EmailMessage>();
        for (Integer i = 0; i < 5; i++) {
            Case objCase = new Case();
            objCase.Subject = 'Test MassEmail LEX';
            objCase.Description = 'Test';
            objCase.Origin = 'Email';
            objCase.SuppliedEmail = 'test.test1@test.com';
            list_Cases.add(objCase);
        }
        insert list_Cases;
        String strListCases = JSON.serialize(list_Cases);

        EmailMessage objEmailMsg = new EmailMessage(); // Created a EmailMessage and copy all details.
        objEmailMsg.ToAddress = 'testUser@test.com';
        objEmailMsg.Subject = 'Test Subject';
        objEmailMsg.HtmlBody = '<br></br><font color="white">test</font>';
        objEmailMsg.ParentId = list_Cases[0].Id; //Attaching with the case
        objEmailMsg.MessageDate = System.now(); 
        objEmailMsg.Status = '0';
        objEmailMsg.fromAddress = 'testEmail@gusto.com';            
        list_EmailMessage.add(objEmailMsg);
        String strListEmail = JSON.serialize(list_EmailMessage);

        Test.startTest();
        MassEmail_LEX.updateCaseAndAttachEmail(strListCases, strListEmail, false);
        Test.stopTest();
        List<EmailMessage> list_Messages = [SELECT Id FROM EmailMessage WHERE ParentId = :list_Cases[0].Id];
        System.assert(!list_Messages.isEmpty(), 'EmailMessage record was not created');
    }
}