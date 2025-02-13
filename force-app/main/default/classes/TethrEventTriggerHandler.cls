/**
 * The TethrEventTriggerHandler class is a trigger handler for Tethr events.
 * It extends the TriggerHandler base class and handles the after insert context for Tethr events.
 */
public without sharing class TethrEventTriggerHandler extends TriggerHandler {
    // Static variable to skip the trigger if needed
    public static Boolean blnSkipTrigger = false;

    // Private variables to hold the new and old records and their maps
    private List<Tethr__Tethr_Event__c> newRecords;
    private List<Tethr__Tethr_Event__c> oldRecords;
    private Map<Id, Tethr__Tethr_Event__c> newRecordsMap;
    private Map<Id, Tethr__Tethr_Event__c> oldRecordsMap;

    /**
     * Constructor for the TethrEventTriggerHandler class.
     * Initializes the new and old records and their maps from the trigger context.
     */
    public TethrEventTriggerHandler() {
        super('TethrEventTriggerHandler');
        this.newRecords = (List<Tethr__Tethr_Event__c>) Trigger.new;
        this.oldRecords = (List<Tethr__Tethr_Event__c>) Trigger.old;
        this.newRecordsMap = (Map<Id, Tethr__Tethr_Event__c>) Trigger.newMap;
        this.oldRecordsMap = (Map<Id, Tethr__Tethr_Event__c>) Trigger.oldMap;
    }

    /**
     * Handles the after insert context for Tethr events.
     * Calls the TethrEventTriggerHelper to process the after insert logic.
     */
    public override void afterInsert() {
        try {
            // Create an instance of the helper class
            TethrEventTriggerHelper objHelper = new TethrEventTriggerHelper();
            
            // Process the after insert logic using the helper class
            objHelper.processAfterInsert((Map<Id, Tethr__Tethr_Event__c>) Trigger.newMap);
        } catch (Exception objException) {
            // Log any exceptions that occur during processing
            ExceptionLogUtil.logException('TethrEventTriggerHandler', 'afterInsert', null, objException);
        }
    }
}