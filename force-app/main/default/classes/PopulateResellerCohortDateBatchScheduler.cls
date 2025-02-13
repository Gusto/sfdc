/**
    Created by : Aurobind Ravichandran
    Created Date : 10/01/2020 
**/
global with sharing class PopulateResellerCohortDateBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
    	database.executeBatch(new PopulateResellerCohortDateBatch(), 20);
    }
}