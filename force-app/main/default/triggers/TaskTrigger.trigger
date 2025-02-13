trigger TaskTrigger on Task(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (FeatureManagement.checkPermission('Bypass_Triggers')) {
		return;
	}
	if (!TaskTriggerHelper.skipTrigger) {
		new TaskTriggerHandler().run();
	}
	if (!TriggerTaskDispatchClass.skipTrigger) {
		TriggerTaskDispatchClass.TriggerTaskDispatch(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
	}
}