/*
	* To run HI HI Opportunity creation based on ZP Company data (identified intereset from survey)
*/
global with sharing class OnboardingHIOppCreationScheduler Implements Schedulable{
    global void execute(SchedulableContext ctx) { 
        Database.executeBatch(new OnboardingHIOppCreationBatch(), 5);
    }
}