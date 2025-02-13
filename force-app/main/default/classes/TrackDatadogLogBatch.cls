/**
* @name         : TrackDatadogLogBatch
* @author       : Bhagat Singh
* @date         : 26/09/2024
* @description  : Batch class to track the logs in datadog.
* @test classes : TrackDatadogLogBatchTest
**/
public with sharing class TrackDatadogLogBatch implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    public static String strURL = '';
    public static String strApiKey = '';
    public static String strApplocationKey = '';
    public static String strHostName = URL.getOrgDomainURL().getHost();
    public static String strEnv = 'development';
    public static String STR_PROD = 'production';
    public Map<String, Boolean> map_BatchClassWithFlag = new Map<String, Boolean>();
    public static Set<String> set_ClassName = new Set<String>();
    public static Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();

    /**
    * @Author      : Bhagat Singh
    * @Description : This static block initialize the static variables.
    **/   
    static {
        if (!OrganizationUtilities.isSandbox()) {
            strEnv = STR_PROD;
        }
        strURL = objConfigSettings.Datadog_URL__c;
        strApiKey = objConfigSettings.Datadog_API_Key__c;
        strApplocationKey = objConfigSettings.Datadog_Integration_Key__c;
        if (String.isNotBlank(objConfigSettings.Datadog_Classes__c)) {
            for (String strClassName :objConfigSettings.Datadog_Classes__c.split(',')) {
                set_ClassName.add(strClassName.trim().toLowerCase());
            }
        }
        
        if (Test.isRunningTest()) {
            set_ClassName.add('oeincompleteemailbatch');
            set_ClassName.add('oereminderemailbatch');
        }
    }

    public void execute(SchedulableContext objSC) {
        Database.executeBatch(new TrackDatadogLogBatch(), 1);        
    }
    
    /**
    * @Author      : Bhagat Singh
    * @Description : This method return the apex job running today.
    **/   
    public Database.QueryLocator start(Database.BatchableContext objBC) {
        String strBaseQuery = 'SELECT Id, createddate, ApexClass.Name, CompletedDate, ExtendedStatus, JobItemsProcessed, ' +
            ' JobType, LastProcessed, LastProcessedOffset, MethodName, NumberOfErrors, Status, TotalJobItems' +
            ' FROM AsyncApexJob ';
        String strWhere = ' WHERE CompletedDate = TODAY AND ApexClass.Name IN : set_ClassName order by createddate desc';
        
        String strQuery = strBaseQuery + strWhere;
        If (Test.isRunningTest()) {
            strQuery = strBaseQuery + ' WHERE ApexClass.Name IN : set_ClassName Limit 1';
        }
        
        return Database.getQueryLocator(strQuery);
    }
    
    /**
    * @Author      : Bhagat Singh
    * @Description : Process the apex job and track logs in datadog.
    **/ 
    public void execute(Database.BatchableContext objBC, List<sObject> list_Scope) {
        if (list_Scope.size() > 0) {
            String strStatus = 'ok';   
            AsyncApexJob objJob = (AsyncApexJob)list_Scope[0];
            if (!map_BatchClassWithFlag.containsKey(objJob.ApexClass.Name.toLowerCase())) {
                map_BatchClassWithFlag.put(objJob.ApexClass.Name.toLowerCase(), true);
                DateTime dtCompletedDateTime = objJob.CompletedDate;
                Date dtCompletedDate = Date.newInstance(dtCompletedDateTime.year(), dtCompletedDateTime.month(), dtCompletedDateTime.day());
                
                if ((objJob.NumberOfErrors != null && objJob.NumberOfErrors > 0) || objJob.TotalJobItems == null || objJob.TotalJobItems == 0) {
                    strStatus = 'warn';
                }
                
                String strMsg = objJob.ApexClass.Name + ' - Job Completed Date :' + dtCompletedDateTime.format() + 
                    ' - Total Job Items :' + objJob.TotalJobItems + 
                    ' - Job Items Processed: ' + objJob.JobItemsProcessed + 
                    ' - Number Of Errors:' + objJob.NumberOfErrors + 
                    ' - Status: ' + objJob.Status + 
                    ' - Extended Status: '+ objJob.ExtendedStatus;
                
                String strTags = 'env:' + strEnv + ',status:' + strStatus + ',log_status:' + strStatus + ',class_name:' + objJob.ApexClass.Name + ',org_name:' + strHostName + ',completed_date:' + dtCompletedDate.format();
                
                String strJSON = '[{"ddsource":"salesforce","ddtags":"' + strTags + '",'+
                    '"hostname":"'+ strHostName +'",'+
                    '"message":"' + strMsg +'",'+
                    '"service":"salesforce"}]';
                
                callOutDatadog(strJSON);    
            }
        }
    }
    
    /**
    * @Author      : Bhagat Singh
    * @Description : If apex job not running during the day, track the log in data dog.
    **/ 
    public void finish(Database.BatchableContext objBC) {
        for (String strClassName :set_ClassName) {
            if (!map_BatchClassWithFlag.containsKey(strClassName)) {
                String strTags = 'env:' + strEnv + ',status:error' + ',log_status:error' + ',class_name:' + strClassName + ',org_name:' + strHostName + ',completed_date:' + Date.today().format();
                String strMsg = strClassName + ' : Job not executed on ' + Date.today().format(); 
                String strJSON = '[{"ddsource":"salesforce","ddtags":"' + strTags + '",'+
                    '"hostname":"'+ strHostName +'",'+
                    '"message":"' + strMsg +'",'+
                    '"service":"salesforce"}]';
                
                callOutDatadog(strJSON);
            }
        }
    }

    /**
    * @Author      : Bhagat Singh
    * @Description : Call out data dog.
    **/ 
    public static HttpRequest callOutDatadog(String strJSON){
        HttpRequest objHTTPReq = new HttpRequest();
        try {
            objHTTPReq.setEndpoint(strURL);
            objHTTPReq.setMethod('POST');
            objHTTPReq.setHeader('Content-Type', 'application/json');
            objHTTPReq.setHeader('DD-API-KEY', strApiKey);
            objHTTPReq.setHeader('DD-APPLICATION-KEY', strApplocationKey);
            objHTTPReq.setBody(strJSON);
            objHTTPReq.setTimeOut(120000);
            Http objHTTP = new Http();
            if (!Test.isRunningTest()) {
                HTTPResponse objHTTPRes = objHTTP.send(objHTTPReq);
            }
        } catch (Exception objEx){
            ExceptionLogUtil.logException('TrackDatadogLogBatch', 'callOutDatadog', objEx.getMessage(), objEx.getStackTraceString(), '. line number: ' + objEx.getLineNumber());
        }
        
        return objHTTPReq;
    }    
}