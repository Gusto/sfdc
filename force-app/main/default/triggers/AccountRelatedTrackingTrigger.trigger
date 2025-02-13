trigger AccountRelatedTrackingTrigger on Account_Related_Tracking__c(before insert, before update) {
	AccountRelatedTrackingTriggerHelper handler = new AccountRelatedTrackingTriggerHelper();
	if (AccountRelatedTrackingTriggerHelper.skipTrigger == false) {
		if (Trigger.isInsert && Trigger.isBefore) {
			handler.OnBeforeInsert(Trigger.new);
		} else if (Trigger.isUpdate && Trigger.isBefore) {
			handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
		} 
	}
}