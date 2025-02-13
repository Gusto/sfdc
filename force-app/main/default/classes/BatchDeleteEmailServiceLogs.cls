/**
    @Created by : Gaurav Khare
    @Created Date : 20-Jan-2020
    @Desc : Delete email service logs before 7 days
**/
public class BatchDeleteEmailServiceLogs implements Database.Batchable<sObject> {
    
    static Date today7 = Date.today().addDays(-7);
    string queryString = null;

    public BatchDeleteEmailServiceLogs(String inputQueryString){
        queryString = inputQueryString;
    }

    public BatchDeleteEmailServiceLogs(){
        
    }

    public Database.QueryLocator start(Database.BatchableContext context)
    {
        if(queryString==null){
            queryString = 'SELECT ID FROM Email_Service_Log__c WHERE CreatedDate < LAST_N_DAYS:5';
        }
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext context, List<SObject> records)
    {
        delete records;
    }

    public void finish(Database.BatchableContext BC){

    }

}