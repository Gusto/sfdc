/**
    @Created by : Gaurav Khare
    @Created Date : 20-Jan-2020
    @Desc : Schedular claas to Delete email service logs before 7 days
**/
global class SchedularToDeleteEmailServiceLog Implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new BatchDeleteEmailServiceLogs());
    }
    
}