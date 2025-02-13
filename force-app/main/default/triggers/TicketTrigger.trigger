/**
Created by : Deepak Tyagi
Created Date : 11/27/2018
**/
trigger TicketTrigger on Ticket__c (before insert, before update, after insert, after update) {
    if (TicketTriggerHelper.skipTrigger || FeatureManagement.checkPermission('Bypass_Triggers')) {
		return;
	}
	new TicketTriggerHandler().run();
}