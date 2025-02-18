public class AgentWorkHandler extends TriggerHandler {
    // Context Specific Skip Flags
    public static Boolean blnSkipBeforeInsert = false;

    /**** Handles Before Insert Context ****/
    public override void beforeInsert() {
        // Check if Before Insert logic needs to be skipped
        if (!blnSkipBeforeInsert) {
            try {
                AgentWorkHelper objHelper = new AgentWorkHelper();
                objHelper.processBeforeInsert((List<AgentWork>) Trigger.new);
            } catch (Exception ex) {
            }
        }
    }
}