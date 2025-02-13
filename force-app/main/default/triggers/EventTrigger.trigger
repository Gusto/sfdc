trigger EventTrigger on Event (after insert, after update, before insert, before update) {
    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
	if (EventTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
		return;
	}

    new EventTriggerHelper().run();
}