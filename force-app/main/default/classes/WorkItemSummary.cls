public with sharing class WorkItemSummary {
    // private String objectApiName = '';
    // private List<Id> workItemIdList = new List<Id>();
    // private List<sObject> workItemList = new List<sObject>();
    // List<Work_Item_Summary__mdt> workItemSettingsList = new List<Work_Item_Summary__mdt>();
    // private String requestBody = '';
    // private String namedCredentialEndpoint = '';
    // public String responseBody = '';

    // // assuming bulk of SAME type of record
    // public WorkItemSummary(List<Id> workItemIdList) {
    //     this.workItemIdList = workItemIdList;
    //     getObjectApiName();
    //     getRecords(); 
    //     formatRequestBody();
    //     this.namedCredentialEndpoint = 'callout:OpenAI_Chat_Summary_NamedCredential';
    // }

    // @InvocableMethod(label='Get LLM Summary' description='Makes a request to LLM for Work Item Summary' category='Case')
    // public static void getWorkItemSummaryInvocable(List<String> workItemIdList) {
    //     WorkItemSummary thisWorkItemSummaryRequest = new WorkItemSummary(workItemIdList);
    //     thisWorkItemSummaryRequest.getWorkItemSummary();
    // }

    // public void getWorkItemSummary() {

    //     // create request 
    //     String methodName = 'getWorkItemSummary';
    //     Http http = new Http();
    //     HttpRequest request = new HttpRequest();
    //     request.setEndpoint(this.namedCredentialEndpoint);
    //     request.setMethod('POST');
    //     request.setHeader('Content-Type', 'application/json');
    //     request.setBody(this.requestBody);
    //     HttpResponse response;     
    //     try {
    //         response = http.send(request);
    //         if (response.getStatusCode() == 200) {
    //             this.responseBody = response.getBody();
    //             // TODO: post to rich text field on object
    //         } 
    //     } catch (Exception postException) {
    //         System.debug(postException.getMessage());
    //         createLog(methodName, postException);
    //     }
    // }

    // // assumes all record ids are for the same object
    // private void getObjectApiName(){
    //     Id firstRecordId = this.workItemIdList[0];
    //     this.objectApiName = firstRecordId.getSObjectType().getDescribe().getName();
    // }

    // private void getRecords(){
    //     // create a local copy of the id list since dynamic soql doesnt work will when referencing this.variable
    //     List<Id> idList = this.workItemIdList;
    //     String selectStatement = 'SELECT ';

    //     // get list of metadata and append all fields to the select statement
    //     this.workItemSettingsList = [SELECT Id, Field_API_Name__c, Object__c
    //                                     FROM Work_Item_Summary__mdt 
    //                                     WHERE Object__c = :this.objectApiName];

    //     for(Work_Item_Summary__mdt workItemSetting : this.workItemSettingsList){
    //         selectStatement = selectStatement + workItemSetting.Field_API_Name__c + ' , ';
    //     }
    //     Integer lastCommmaPosition = selectStatement.lastIndexOf(',');
    //     selectStatement = selectStatement.subString(0, lastCommmaPosition-1);

    //     String fromStatement = ' FROM ' + this.objectApiName;
    //     String whereStatement = ' WHERE Id IN :idList ';
    //     String queryString = selectStatement + ' ' + fromStatement + ' ' + whereStatement;
    //     try{
    //         this.workItemList = Database.query(queryString);
    //     }catch(Exception queryException){
    //         String methodName = 'getRecords';
    //         System.debug(queryException.getMessage());
    //         createLog(methodName, queryException);
    //     }          

    // }

    // // TODO: Adjust logic to handle multiple records in one payload
    // // I did not do this since current request must only have a single record
    // private void formatRequestBody(){
    //     Integer count = 0;
    //     for(sObject thisWorkItem : this.workItemList){
    //         String jsonKeyValuePair = '{';
    //         for(Work_Item_Summary__mdt workItemSetting : this.workItemSettingsList){
    //             String objectName = workItemSetting.Object__c;
    //             String fieldApiName = workItemSetting.Field_API_Name__c;
    //             String fieldValue = (String) thisWorkItem.get(fieldApiName);
    //             jsonKeyValuePair = jsonKeyValuePair + '"' + fieldApiName + '"' + ' : ' + '"' + fieldValue + '"' + ' , ';
    //         }
    //         Integer lastCommmaPosition = jsonKeyValuePair.lastIndexOf(',');
    //         jsonKeyValuePair = jsonKeyValuePair.subString(0, lastCommmaPosition);
    //         jsonKeyValuePair = jsonKeyValuePair + '}';
    //         this.requestBody = jsonKeyValuePair;
    //     }
    // }

    // private void createLog(String methodName, Exception thisException){
    //     String className = WorkItemSummary.class.getName();
    //     ExceptionLogUtil.logException(className, methodName, this.workItemIdList[0], thisException);
    // }


}