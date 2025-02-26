public with sharing class RecordSummary {
    public final String RESPONSE_SUMMARY_KEY = 'ai_summary'; 
    private String objectApiName = '';
    private List<Id> recordIdList = new List<Id>();
    private List<sObject> recordList = new List<sObject>();
    Record_Summary_Object__mdt recordSummaryObject = new Record_Summary_Object__mdt();
    List<Record_Summary_Field__mdt> recordSummaryFieldList = new List<Record_Summary_Field__mdt>();
    private String requestBody = '';
    public String responseBody = '';

    // assuming bulk of SAME type of record
    public RecordSummary(List<Id> recordIdList) {
        this.recordIdList = recordIdList;
        getObjectApiName();
        getRecords(); 
        formatRequestBody();
    }

    @InvocableMethod(label='Get LLM Summary' description='Makes a request to LLM for Work Item Summary' category='Case')
    public static void getRecordSummaryInvocable(List<String> recordIdList) {
        RecordSummary thisRecordSummaryRequest = new RecordSummary(recordIdList);
        thisRecordSummaryRequest.getRecordSummary();
    }

    public void getRecordSummary() {

        // create request 
        String methodName = 'getRecordSummary';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:OpenAI_Chat_Summary_NamedCredential');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('client_id', '{!$Credential.Open_AI_External_Credential.client_id}');
        request.setHeader('client_secret', '{!$Credential.Open_AI_External_Credential.client_secret}');
        
        system.debug('requestBody***'+ this.requestBody);

        request.setBody(this.requestBody);
        HttpResponse response;     
        try {
            response = http.send(request);
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                this.responseBody = response.getBody();
                system.debug('responseBody88'+ this.responseBody);
                postResponseToSummaryField();
                System.debug('done');
            }else{
                System.debug('response code');
                System.debug(response.getStatusCode());
            } 
        } catch (Exception postException) {
            System.debug(postException.getMessage());
            createLog(methodName, postException);
        }
    }

    // assumes all record ids are for the same object
    private void getObjectApiName(){
        Id firstRecordId = this.recordIdList[0];
        this.objectApiName = firstRecordId.getSObjectType().getDescribe().getName();
    }

    private void getRecords(){
        String methodName = 'getRecords';

        // create a local copy of the id list since dynamic soql doesnt work will when referencing this.variable
        List<Id> idList = this.recordIdList;
        String selectStatement = 'SELECT ';

        try{
            // get list of object level metadata 
            this.recordSummaryObject = [SELECT Id, Summary_Field_API_Name__c, Object__c
                                            FROM Record_Summary_Object__mdt 
                                            WHERE Object__c = :this.objectApiName
                                            LIMIT 1];
        }catch(Exception queryException){
            System.debug(queryException.getMessage());
            createLog(methodName, queryException);
        }

        try{
            // get list of field level metadata and append all fields to the select statement
            this.recordSummaryFieldList = [SELECT Id, JSON_Field_Label__c, Field_API_Name__c, Record_Summary_Object__c
                                            FROM Record_Summary_Field__mdt	 
                                            WHERE Record_Summary_Object__c = :this.recordSummaryObject.Id
                                            ];
        }catch(Exception queryException){
            System.debug(queryException.getMessage());
            createLog(methodName, queryException);
        }


        for(Record_Summary_Field__mdt recordSummaryField : this.recordSummaryFieldList){
            selectStatement = selectStatement + recordSummaryField.Field_API_Name__c + ' , ';
        }
        Integer lastCommmaPosition = selectStatement.lastIndexOf(',');
        selectStatement = selectStatement.subString(0, lastCommmaPosition-1);

        String fromStatement = ' FROM ' + this.objectApiName;
        String whereStatement = ' WHERE Id IN :idList ';
        String queryString = selectStatement + ' ' + fromStatement + ' ' + whereStatement;
        try{
            this.recordList = Database.query(queryString);
        }catch(Exception queryException){      
            System.debug(queryException.getMessage());
            createLog(methodName, queryException);
        }          

    }

    // TODO: Adjust logic to handle multiple records in one payload
    // I did not do this since current request must only have a single record
    private void formatRequestBody(){
        Integer count = 0;
        for(sObject thisRecord : this.recordList){
            String jsonKeyValuePair = '{';
            for(Record_Summary_Field__mdt recordSummaryField : this.recordSummaryFieldList){
                String objectName = this.recordSummaryObject.Object__c;
                String fieldApiName = recordSummaryField.Field_API_Name__c;
                String fieldLabel =  recordSummaryField.JSON_Field_Label__c;
                String fieldValue = ((String) thisRecord.get(fieldApiName)).escapeJava();
                jsonKeyValuePair = jsonKeyValuePair + '"' + fieldLabel + '"' + ' : ' + '"' + fieldValue + '"' + ' , ';
            }
            Integer lastCommmaPosition = jsonKeyValuePair.lastIndexOf(',');
            jsonKeyValuePair = jsonKeyValuePair.subString(0, lastCommmaPosition);
            jsonKeyValuePair = jsonKeyValuePair + '}';
            this.requestBody = jsonKeyValuePair;
        }
    }

    // TODO: Make this work in bulk. Currently posting response to all records
    // may consider adding logic to allow response to be parsed and specific
    // response to be posted to corresponding record 
    private void postResponseToSummaryField(){
        String methodName = 'postResponseToSummaryField';

        for(sObject thisRecord : this.recordList){
            Map<String, Object> deserializedResponse = (Map<String, Object>) JSON.deserializeUntyped(this.responseBody);
            String fieldValue = ((String) deserializedResponse.get(this.RESPONSE_SUMMARY_KEY)).unescapeHtml4();
            thisRecord.put(this.recordSummaryObject.Summary_Field_API_Name__c,fieldValue);
        }
        try{
            update(this.recordList);
        }catch(Exception dmlException){
            System.debug(dmlException.getMessage());
            createLog(methodName, dmlException);
        }
    }

    private void createLog(String methodName, Exception thisException){
        String className = RecordSummary.class.getName();
        ExceptionLogUtil.logException(className, methodName, this.recordIdList[0], thisException);
    }
}