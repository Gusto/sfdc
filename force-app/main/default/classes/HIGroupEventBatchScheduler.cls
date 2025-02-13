/**
 * @name         : HIGroupEventBatchScheduler
 * @author       : Sanjay Paryani
 * @date         : 09/13/2021
 * @description  : Scheduler for HIGroupEventBatch class
 * @test classes : HIGroupEventBatchTest
 **/
global with sharing class HIGroupEventBatchScheduler Implements Schedulable {

    global void execute(SchedulableContext sc){
    	database.executeBatch(new HIGroupEventBatch(), 100);
    }
}