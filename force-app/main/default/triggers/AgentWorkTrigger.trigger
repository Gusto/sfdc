trigger AgentWorkTrigger on AgentWork(before insert) {
    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to True
    if (FeatureManagement.checkPermission('Bypass_Triggers') || AgentWorkHelper.skipTrigger) {
        return;
    }
    new AgentWorkHandler().run();
}