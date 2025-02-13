/**
* @name         HIGroupEventRestService
* @author       Gireesh
* @date         08/01/2020
* @description  This class is a REST service that receives HI Group events and creates in SFDC for further processing.
* @test class   HIGroupEventRestServiceTest.cls
* @revisions    Date ------------ Name ------------ Comments   
**/
@RestResource(urlMapping='/HIGroupEvent/*')
global with sharing class HIGroupEventRestService {
    global class HIGroupEventException extends Exception{}
    public class HIGroupEventWrapper{
        String Application_type;
        String company_id;
        String event_info;
        String event_id;
        String event_type;
    }
  	@HttpPost
    global static String doPost() {
        String strSuccess='success';
        try {
        HIGroupEventWrapper objHIGroupEventWrapper = (HIGroupEventWrapper)json.deserialize
            										 (RestContext.request.requestBody.toString(),
                                                     HIGroupEventWrapper.class);
        if(objHIGroupEventWrapper.event_info==null||
           String.isEmpty(objHIGroupEventWrapper.event_info))
        {
            throw new HIGroupEventException('Missing required value :event_info');
        }
        HIGroupEvent__c objHIGroupEvent=new HIGroupEvent__c(
            Application_type__c=objHIGroupEventWrapper.Application_type,
            Company_id__c=objHIGroupEventWrapper.company_id,
            Event_info__c=objHIGroupEventWrapper.event_info,
            Event_id__c=objHIGroupEventWrapper.event_id,
            Event_type__c=objHIGroupEventWrapper.event_type
        );
        
        
            insert objHIGroupEvent;    
        } catch(Exception ex) {
            ExceptionLogUtil.logException('HIGroupEventRestService', 'doPost', ex.getMessage(),ex.getStackTraceString());        
            String strToAddresses = 'sanjay.paryani@gusto.com';
            List<String> list_ToAddresses = strToAddresses.split(';');
            
            String strEmailSubject = 'HIGroupEventRestService  Exception: ' + ex.getMessage();
            String strEmailBody = 'HIGroupEventRestService  Exception:\n\nCaused by: ' + ex.getTypeName() + ': ' + ex.getMessage() + '\n\n' + ex.getStackTraceString();

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject(strEmailSubject);
            email.setPlainTextBody(strEmailBody);
            email.setToAddresses(list_ToAddresses);
            if(OrganizationUtilities.canSendEmails()){
                Messaging.sendEmail(New Messaging.SingleEmailMessage[]{email});
            }
            strSuccess='Error';
        } 
    
        return strSuccess;
    }
}