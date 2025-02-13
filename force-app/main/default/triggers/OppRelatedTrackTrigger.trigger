trigger OppRelatedTrackTrigger on Opportunity_Related_Tracking__c(before insert, before update) {
	OppRelatedTrackTriggerHelper handler = new OppRelatedTrackTriggerHelper();

	if (Trigger.isInsert && Trigger.isBefore) {
		handler.OnBeforeInsert(Trigger.new);
	} else if (Trigger.isUpdate && Trigger.isBefore) {
		handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
	} 
}