/**
Created by : Praveen Sethu
Created Date : 10/05/2020
Updated by : David Schach
Updated Date : 10/28/2021
Description: Trigger Handler class that delegates tasks between ContactTrigger and ContactTriggerHelper
**/
public with sharing class ContactTriggerHandler extends TriggerHandler {
	private List<Contact> newRecords;
	private List<Contact> oldRecords;
	private Map<Id, Contact> newRecordsMap;
	private Map<Id, Contact> oldRecordsMap;

	public ContactTriggerHandler() {
		super('ContactTriggerHandler');
		this.newRecords = (List<Contact>) Trigger.new;
		this.oldRecords = (List<Contact>) Trigger.old;
		this.newRecordsMap = (Map<Id, Contact>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, Contact>) Trigger.oldMap;
	}

	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;

	/**** To reset all skip trigger flags for Contact ****/
	public static void resetSkipTriggerFlags() {
		ContactTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**** Handles Before Insert Context ****/
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				ContactTriggerHelper objHelper = new ContactTriggerHelper();
				objHelper.processBeforeInsert((List<Contact>) Trigger.new);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('ContactTriggerHandler', 'beforeInsert', null, objException);
			}
		}
	}

	/**** Handles After Insert Context ****/
	public override void afterInsert() {
		// Check if After Insert Logic needs to be Skipped
		if (!blnSkipAfterInsert) {
			try {
				ContactTriggerHelper objHelper = new ContactTriggerHelper();
				objHelper.processAfterInsert((Map<Id, Contact>) Trigger.newMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('ContactTriggerHandler', 'afterInsert', null, objException);
			}
		}
	}

	/**** Handles Before Update Context ****/
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			// Contact Before Update Logic
			// Calling Trigger Helper Classes that inturn call ContactUtil Classes
			try {
				ContactTriggerHelper objHelper = new ContactTriggerHelper();
				objHelper.processBeforeUpdate((List<Contact>) Trigger.new, (Map<Id, Contact>) Trigger.oldMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('ContactTriggerHandler', 'beforeUpdate', null, objException);
			}
		}
	}

	/**** Handles After Update Context ****/
	public override void afterUpdate() {
		// Check if After Update Logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			// Contact After Update Logic
			// Calling Trigger Helper Classes that inturn call ContactUtil Classes
			try {
				ContactTriggerHelper objHelper = new ContactTriggerHelper();
				objHelper.processAfterUpdate((Map<Id, Contact>) Trigger.newMap, (Map<Id, Contact>) Trigger.oldMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('ContactTriggerHandler', 'afterUpdate', null, objException);
			}
		}
	}

	/**** Handles After Delete Context ****/
	public override void afterDelete() {
		// Check if After Delete Logic needs to be skipped
		if (!blnSkipAfterDelete) {
			// Contact After Delete Logic
			// Calling Trigger Helper Classes that inturn call ContactUtil Classes
			try {
				ContactTriggerHelper objHelper = new ContactTriggerHelper();
				objHelper.processAfterDelete((List<Contact>) Trigger.old, (Map<Id, Contact>) Trigger.oldMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('ContactTriggerHandler', 'afterDelete', null, objException);
			}
		}
	}
}