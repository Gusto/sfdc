/**
 * The TethrCallTriggerHandler class is a trigger handler for Tethr calls.
 * It extends the TriggerHandler base class and handles the after insert context for Tethr calls.
 * Test class: TethrEventTriggerHelperTest
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
	 * Handles the before insert context for Tethr calls.
	 * Calls the TethrCallTriggerHelper to process the after insert logic.
	 */
	public override void beforeInsert() {
		try {
			// Create an instance of the helper class
			TethrCallTriggerHelper objHelper = new TethrCallTriggerHelper();

			// Process the before insert logic using the helper class
			objHelper.processBeforeInsert((List<Tethr__Tethr_Call__c>) Trigger.new);
		} catch (Exception objException) {
			// Log any exceptions that occur during processing
			ExceptionLogUtil.logException('TethrCallTriggerHandler', 'beforeInsert', null, objException);
		}
	}
}