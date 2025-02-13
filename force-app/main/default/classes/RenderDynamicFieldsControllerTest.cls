@isTest
public class RenderDynamicFieldsControllerTest {
	
    static testmethod void testRenderDynamicFields() {
    	
        // Create a new Payroll Care Case
     	Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
        
        // Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
        
        LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
        insert objLiveChatVisitor;
        
        // Insert a new LiveChatTranscript record and link to the Case
        LiveChatTranscript liveChatTranscript = new LiveChatTranscript();
        liveChatTranscript.LiveChatVisitorId  = objLiveChatVisitor.Id;
        liveChatTranscript.CaseId = objCase.Id;
        insert liveChatTranscript;
        
        
        // Create Case Actions Field Config for Case Output Fields
        // Create a new Config JSON and insert a new criteria
        String strConfigJSON = '[{"size":"6","overrideLabel":"Owner","label":"Owner ID","isVisible":true,"isRequired":false,"input":true,"criteriaList":null,"api":"OwnerId"},{"size":"6","overrideLabel":"","label":"Case Number","isVisible":true,"isRequired":false,"input":true,"criteriaList":[{"value":"0584","operator":"Contains","name":"Case Number","key":"criteria 0","api":"CaseNumber"}],"api":"CaseNumber"},{"size":"6","overrideLabel":null,"label":"Routing Case Reason","isVisible":true,"isRequired":false,"input":true,"criteriaList":[{"value":"Chat","operator":"Not Equals","name":"Case Origin","key":"criteria 0","api":"Origin"},{"value":"Phone","operator":"Not Equals","name":"Case Origin","key":"criteria 1","api":"Origin"},{"value":"","operator":"Not Equals","name":"Routing Case Reason","key":"criteria 2","api":"Routing_Case_Reason__c"}],"api":"Routing_Case_Reason__c"},{"size":"6","overrideLabel":"","label":"Phone","isVisible":true,"isRequired":false,"input":true,"criteriaList":[{"value":"","operator":"Not Equals","name":"Phone","key":"criteria 0","api":"SuppliedPhone"}],"api":"SuppliedPhone"},{"size":"6","overrideLabel":"","label":"Authorized User","isVisible":true,"isRequired":false,"input":true,"criteriaList":[{"value":"No","operator":"Equals","name":"Authorized User","key":"criteria 0","api":"Authorized_User__c"}],"api":"Authorized_User__c"},{"size":"6","overrideLabel":"","label":"Status","isVisible":true,"isRequired":false,"input":true,"criteriaList":[{"value":"sol","operator":"Contains Ignore Case","name":"Status","key":"criteria 0","api":"Status"}],"api":"Status"}]';
        Case_Action_Fields__c objCaseOutputConfigForPayrollCare = new Case_Action_Fields__c(Is_Active__c = true, Display_Type__c = 'Output' , SObject_Type__c = 'Case', Record_Type__c = 'Payroll Care', Configuration_JSON__c = strConfigJSON);
        insert objCaseOutputConfigForPayrollCare;
        
        Case_Action_Fields__c objCaseOutputConfigForPayrollCareReadOnly = new Case_Action_Fields__c(Is_Active__c = true, Display_Type__c = 'Output' , SObject_Type__c = 'Case', Record_Type__c = ' Payroll Care - Read Only', Configuration_JSON__c = strConfigJSON);
        insert objCaseOutputConfigForPayrollCareReadOnly;
        
        // Render Case output fields
        RenderDynamicFieldsController.RenderDynamicFieldResponse responseWithValidConfig = RenderDynamicFieldsController.retrieveOutputConfig(liveChatTranscript.Id, 'Case', 'Id');
        
        // Ensure you have proper response for valid config
        System.assertEquals(true, responseWithValidConfig.blnIsSuccess, 'Render Dynamic Fields Response - Config not found');
        
        // Try to retrieve a output fields for config that does not exist
        RenderDynamicFieldsController.RenderDynamicFieldResponse responseWithInValidConfig = RenderDynamicFieldsController.retrieveOutputConfig(liveChatTranscript.Id, 'Contact', 'ContactId');
        System.assertEquals(false, responseWithInValidConfig.blnIsSuccess, 'Render Dynamic Fields Response - Able to retrieve config that does not exist');
    }
}