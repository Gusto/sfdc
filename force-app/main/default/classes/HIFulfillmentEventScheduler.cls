global with sharing class HIFulfillmentEventScheduler Implements Schedulable {

    global void execute(SchedulableContext sc){
    	database.executeBatch(new HIFulfillmentEventBatch(),10);
    }
}