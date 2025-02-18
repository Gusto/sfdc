/**
 * The TethrCallTriggerHandler class is a trigger handler for Tethr events.
 * It extends the TriggerHandler base class and handles the after insert context for Tethr events.
 */
public without sharing class TethrCallTriggerHandler extends TriggerHandler {
    // Static variable to skip the trigger if needed
    public static Boolean blnSkipTrigger = false;

    // Private variables to hold the new and old records and their maps
    private List<Tethr__Tethr_Call__c> newRecords;
    private List<Tethr__Tethr_Call__c> oldRecords;
    private Map<Id, Tethr__Tethr_Call__c> newRecordsMap;
    private Map<Id, Tethr__Tethr_Call__c> oldRecordsMap;

    /**
     * Constructor for the TethrCallTriggerHandler class.
     * Initializes the new and old records and their maps from the trigger context.
     */
    public TethrCallTriggerHandler() {
        super('TethrCallTriggerHandler');
        this.newRecords = (List<Tethr__Tethr_Call__c>) Trigger.new;
        this.oldRecords = (List<Tethr__Tethr_Call__c>) Trigger.old;
        this.newRecordsMap = (Map<Id, Tethr__Tethr_Call__c>) Trigger.newMap;
        this.oldRecordsMap = (Map<Id, Tethr__Tethr_Call__c>) Trigger.oldMap;
    }

    /**
     * Handles the after insert context for Tethr events.
     * Calls the TethrEventTriggerHelper to process the after insert logic.
     */
    public override void beforeInsert() {
        try {
            // Create an instance of the helper class
            TethrCallTriggerHelper objHelper = new TethrCallTriggerHelper();
            System.debug(Trigger.newMap);
            System.debug(Trigger.new);
            
            
            // Process the before insert logic using the helper class
            objHelper.processBeforeInsert((List<Tethr__Tethr_Call__c>) Trigger.new);
        } catch (Exception objException) {
            // Log any exceptions that occur during processing
            ExceptionLogUtil.logException('TethrCallTriggerHandler', 'afterInsert', null, objException);
        }
    }
}