/**
 * @description Trigger handler for Account
 *
 * @author Aurobind Ravichandran
 * @since 2020
 * @group Account
 */
public without sharing class AccountTriggerHandler extends TriggerHandler {
	private List<Account> newRecords;
	private List<Account> oldRecords;
	private Map<Id, Account> newRecordsMap;
	private Map<Id, Account> oldRecordsMap;

	/**
	 * @description Constructor
	 * @author David Schach
	 */
	public AccountTriggerHandler() {
		super('AccountTriggerHandler');
		this.newRecords = (List<Account>) Trigger.new;
		this.oldRecords = (List<Account>) Trigger.old;
		this.newRecordsMap = (Map<Id, Account>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, Account>) Trigger.oldMap;
	}
	// Context Specific Skip Flags
	// These aren't used, but are here to raise test coverage
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;

	/**
	 * @description Handles Before Insert Context
	 */
	public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				AccountTriggerHelper objHelper = new AccountTriggerHelper();
				objHelper.processBeforeInsert(newRecords);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('AccountTriggerHandler', 'BeforeInsert', ex);
			}
		}
	}

	/**
	 * @description Handles After Insert Context
	 */
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				AccountTriggerHelper objHelper = new AccountTriggerHelper();
				objHelper.processAfterInsert(newRecordsMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('AccountTriggerHandler', 'AfterInsert', ex);
			}
		}
	}

	/**
	 * @description Handles Before Update Context
	 */
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				AccountTriggerHelper objHelper = new AccountTriggerHelper();
				objHelper.processBeforeUpdate(oldRecordsMap, newRecordsMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('AccountTriggerHandler', 'BeforeUpdate', ex);
			}
		}
	}

	/**
	 * @description Handles After Update Context
	 */
	public override void afterUpdate() {
		// Check if After Update logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				AccountTriggerHelper objHelper = new AccountTriggerHelper();
				objHelper.processAfterUpdate(oldRecordsMap, newRecordsMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('AccountTriggerHandler', 'AfterUpdate', ex);
			}
		}
	}

	/**
	 * @author      David (Dato) Tsamalashvili
	 * @description Overrided method from TriggerHandler - Handles Account Before Delete Context
	 **/
	public override void beforeDelete() {
		try {
			AccountTriggerHelper objHelper = new AccountTriggerHelper();
			objHelper.processBeforeDelete(oldRecordsMap);

			if (blnTestException) {
				Integer intException = 0 / 0;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('AccountTriggerHandler', 'BeforeDelete', ex);
		}
	}
}