global with sharing class UpdateEEFulfilmentScheduler Implements Schedulable {

    global void execute(SchedulableContext sc){
      database.executeBatch(new updateEEatFulfilment(),10);
    }
}