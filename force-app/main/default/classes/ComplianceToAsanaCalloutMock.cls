/**
 * @description  Test sending case from sfdc to create or update task in Asana
 * @author       Sindhu Madapati
 * @date         06-28-2024
 **/
@isTest
global with sharing class ComplianceToAsanaCalloutMock implements HttpCalloutMock {
    global integer statusCode = 200;
    global ComplianceToAsanaCalloutMock (integer statusCode) {
       this.statusCode = statusCode; 
    }
    global HTTPResponse respond(HTTPRequest objReq) {
        HttpResponse objRes = new HttpResponse();
        objRes.setHeader('Content-Type', 'application/json');
        
        // Check the HTTP method and set the response accordingly
        if (objReq.getMethod() == 'POST') {
            objRes.setStatusCode(statusCode); // Ensure the status code is set for a successful response
            objRes.setBody('{"status":"success","event_id":"a96269a0-1a11-11ef-abaf-02208e4ca769","message":{"asana_task_id":"12345"}}');
            objRes.setStatus('OK');
        } else if (objReq.getMethod() == 'PATCH') {
            objRes.setStatusCode(statusCode); // Ensure the status code is set for a successful response
            objRes.setBody('{"status":"success","event_id":"a96269a0-1a11-11ef-abaf-02258e4ca769","message":"successfully updated in Asana"}');
            objRes.setStatus('OK');
        } else {
            objRes.setStatusCode(400);
            objRes.setBody('{"status":"failure","event_id":"a96269a0-1a11-11ef-abaf-02298e47a769","error_message":"Bad Request"}');
            objRes.setStatus('fail');
        }
        
        return objRes;
    }
}