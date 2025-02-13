/**
 * @name         : SearchEmailTemplate_LEXTest
 * @author       : Ankit CS
 * @date         : 07-15-2021
 * @description  : This class has methods for SearchEmailTemplate_LEX apex class.
**/
@isTest
public class SearchEmailTemplate_LEXTest {
    /**
    * @Author      : Ankit CS
    * @Description : Test method for SearchEmailTemplate_LEX.fetchAllEmailTemplateFolders()
    **/
    static testMethod void getEmailTemplates() {
        Test.startTest();
        Map<String, List<Object>> map_Response = SearchEmailTemplate_LEX.fetchAllEmailTemplateFolders();
        System.assert(!map_Response.keySet().isEmpty());
        Test.stopTest();      
    }
    
    /**
    * @Author      : Ankit CS
    * @Description : Test method for SearchEmailTemplate_LEX.fetchLastEmailSubject()
    **/
    static testMethod void testFetchLastEmailSubject() {
        Test.startTest();
        Case objCase = new TestDataFactory.CaseBuilder()
            .setStatus('New')
            .setRecordTypeId('Payroll Care')
            .build();
        insert objCase;

        EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
            .setFromAddress('test@abc.org')
            .setIncoming(true)
            .setToAddress('hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com')
            .setSubject('Test email')
            .setTextBody('23456')
            .setParentId(objCase.Id)
            .build();
        insert objEmailMessage;

        Map<String, Object> map_Response = SearchEmailTemplate_LEX.fetchLastEmailSubject(objCase.Id);
        System.assertEquals(map_Response.get('strSubject'), 'Re: Test email');
        Test.stopTest();
    }

    /**
    * @Author      : Ankit CS
    * @Description : Test method for SearchEmailTemplate_LEX.displayTemplatebyName()
    **/
    static testMethod void testDisplayTemplateByName() {
        Test.startTest();
        EmailTemplate objTemplate = new TestDataFactory.EmailTemplateBuilder()
            .setIsActive(true)
            .setName('NY/TX Small Group Template')
            .setDescription('Push to later date')
            .setDeveloperName('email_temp_name')
            .setTemplateType('Text')
            .setHtmlValue('Test Stuff')
            .setFolderId(UserInfo.getUserId())
            .build();
        insert objTemplate;

        String strTemplate = JSON.serialize(objTemplate);
        EmailTemplate objResultEmailTemplate = SearchEmailTemplate_LEX.displayTemplatebyName(objTemplate.Id);
        Test.stopTest();
        System.assertEquals(objResultEmailTemplate.Name, 'NY/TX Small Group Template');
    }
}