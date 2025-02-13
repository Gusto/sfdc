/**
 * @name         : LeadBackToNurtureScheduler
 * @author       : Veeresh Kumar
 * @date         : 08-30-2021
 * @description  : Scheduler class for LeadBackToNurtureScheduler class for LeadBackToNurtureBatch
 * @test classes : LeadBackToNurtureBatchTest
 **/
global with sharing class LeadBackToNurtureScheduler implements Schedulable {
	public String strQuery = '';
	public LeadBackToNurtureScheduler() {
	}

	public LeadBackToNurtureScheduler(String strQuery) {
		this.strQuery = strQuery;
	}

	global void execute(SchedulableContext sc) {
		Database.executeBatch(new LeadBackToNurtureBatch(strQuery), 20);
	}
}