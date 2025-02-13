trigger HRWorkerInformationTrigger on HR_Worker_Information__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
  
    if (FeatureManagement.checkPermission('Bypass_Triggers')) {return;}
	new HRWorkerInformationTriggerHandler().run();
}