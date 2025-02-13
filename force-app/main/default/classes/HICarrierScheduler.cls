global with sharing class HICarrierScheduler Implements Schedulable {

    global void execute(SchedulableContext sc){
    	database.executeBatch(new HICarrierBatch(),10);
    }
}