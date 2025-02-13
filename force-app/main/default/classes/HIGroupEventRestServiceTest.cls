/**
* @name         HIGroupEventRestServiceTest
* @author       Gireesh
* @date         08/01/2020
* @description  Test class for HIGroupEventRestService
* @revisions    Date ------------ Name ------------ Comments       
**/ 
@isTest
private class HIGroupEventRestServiceTest {
    public static String STR_JSON = '{"company_id": "test123", "event_info": "{\'application_type\':\'NewPlansApplication\',\'application_id\':31063,\'new_hires_not_on_qwr\':\'Max Zheng, Erica Goodwin\',\'date_of_first_hired_ee\':\'2020-07-08\',\'underwriting_issues_resolved\':\'Fixed waiting period for the company\',\'advocate_additional_details\':\'This customer looks great!\',\'submission_additional_details\':\'Lets go!\'}","event_id": "313131","event_type": "qa_sheet_info"}';

    @TestSetup
    static void setupData(){ 
    }
	
    //Test HIGroupEventRestService.
    static testMethod void testPost() {
		RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/HIGroupEvent';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(STR_JSON);
        RestContext.request = req;
        RestContext.response= res;
        String strResponse = HIGroupEventRestService.doPost();
        List<HIGroupEvent__c> list_HIGroupEvent =[select id, Company_Id__c, Processing_State__c from HIGroupEvent__c where Company_Id__c='test123'];
        system.assert(list_HIGroupEvent.size()>0);
    }
     static testMethod void testPost_error() {
		RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/HIGroupEvent';
        req.httpMethod = 'POST';
        req.requestBody =  Blob.valueOf('{"company_id": 122343, "event_info": "","event_id": "313131","event_type": "qa_sheet_info"}');
        RestContext.request = req;
        RestContext.response= res;
        String strResponse = HIGroupEventRestService.doPost();
        system.assert(strResponse=='Error');
    }
    
}