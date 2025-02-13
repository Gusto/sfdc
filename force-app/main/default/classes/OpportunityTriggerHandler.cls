/**
 * Trigger Handler that delegates tasks between OpportunityTrigger and OpportunityTriggerHelper
 * @author Sourav Mitra
 * @since 10-06-2020
 * @see OpportunityTriggerHandlerTest
 * @see OpportunityTriggerHelperTest
 */
public without sharing class OpportunityTriggerHandler extends TriggerHandler {
	private List<Opportunity> newRecords;
	private List<Opportunity> oldRecords;
	private Map<Id, Opportunity> newRecordsMap;
	private Map<Id, Opportunity> oldRecordsMap;

	/**
	 * Constructor
	 */
	public OpportunityTriggerHandler() {
		super('OpportunityTriggerHandler');
		this.newRecords = (List<Opportunity>) Trigger.new;
		this.oldRecords = (List<Opportunity>) Trigger.old;
		this.newRecordsMap = (Map<Id, Opportunity>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, Opportunity>) Trigger.oldMap;
	}

	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;

	/**
	 * Handles Before Insert Context
	 */
	public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				OpportunityTriggerHelper objHelper = new OpportunityTriggerHelper();
				objHelper.processBeforeInsert(newRecords);
			} catch (Exception ex) {
				if (!ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
					ExceptionLogUtil.logException('OpportunityTriggerHandler', 'BeforeInsert', ex);
				}
			}
		}
	}

	/**
	 * Handles After Insert Context
	 */
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				OpportunityTriggerHelper objHelper = new OpportunityTriggerHelper();
				objHelper.processAfterInsert(newRecords);
			} catch (Exception ex) {
				if (!ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
					ExceptionLogUtil.logException('OpportunityTriggerHandler', 'AfterInsert', ex);
				}
			}
		}
	}

	/**
	 * Handles Before Update Context
	 */
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				OpportunityTriggerHelper objHelper = new OpportunityTriggerHelper();
				objHelper.processBeforeUpdate(newRecords, oldRecordsMap);
			} catch (Exception ex) {
				if (!ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
					ExceptionLogUtil.logException('OpportunityTriggerHandler', 'BeforeUpdate', ex);
				}
			}
		}
	}

	/**
	 * Handles After Update Context
	 */
	public override void afterUpdate() {
		// Check if After Update logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				OpportunityTriggerHelper objHelper = new OpportunityTriggerHelper();
				objHelper.processAfterUpdate(newRecords, oldRecordsMap);
			} catch (Exception ex) {
				if (!ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
					ExceptionLogUtil.logException('OpportunityTriggerHandler', 'AfterUpdate', ex);
				}
			}
		}
	}

	public override void beforeDelete() {
	} //NOPMD

	public override void afterDelete() {
	} //NOPMD

	public override void afterUndelete() {
	} //NOPMD
}