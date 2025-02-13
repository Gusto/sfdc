trigger LeadRelatedTrackTrigger on Lead_Related_Tracking__c(before insert, before update) {
	LeadRelatedTrackTriggerHelper handler = new LeadRelatedTrackTriggerHelper();

	if (Trigger.isInsert && Trigger.isBefore) {
		handler.OnBeforeInsert(Trigger.new);
	}  else if (Trigger.isUpdate && Trigger.isBefore) {
		handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
	} 
}