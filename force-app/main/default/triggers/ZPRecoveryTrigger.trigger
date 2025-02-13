trigger ZPRecoveryTrigger on ZP_Recovery_Case__c(before insert, after insert, before update, after update) {
	ZPRecoveryCaseTriggerHelper handler = new ZPRecoveryCaseTriggerHelper();

	if (Trigger.isInsert && Trigger.isBefore) {
		handler.OnBeforeInsert(Trigger.new);
	} else if (Trigger.isInsert && Trigger.isAfter) {
		handler.OnAfterInsert(Trigger.newMap);
	} else if (Trigger.isUpdate && Trigger.isBefore) {
		handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
	} else if (Trigger.isUpdate && Trigger.isAfter) {
		handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
	}
}