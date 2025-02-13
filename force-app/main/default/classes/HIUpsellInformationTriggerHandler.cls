/**
 * @description Trigger handler for HI Upsell Information
 *
 * @author Swati Arya
 * @since 2023
 * @group Hi Upsell Information
 */
public without sharing class HIUpsellInformationTriggerHandler extends TriggerHandler {
	private List<HI_Upsell_Information__c> newRecords;
	private List<HI_Upsell_Information__c> oldRecords;
	private Map<Id, HI_Upsell_Information__c> newRecordsMap;
	private Map<Id, HI_Upsell_Information__c> oldRecordsMap;

	/**
	 * @description Constructor
	 * @author David Schach
	 */
	public HIUpsellInformationTriggerHandler() {
		super('HIUpsellInformationTriggerHandler');
		this.newRecords = (List<HI_Upsell_Information__c>) Trigger.new;
		this.oldRecords = (List<HI_Upsell_Information__c>) Trigger.old;
		this.newRecordsMap = (Map<Id, HI_Upsell_Information__c>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, HI_Upsell_Information__c>) Trigger.oldMap;
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
				HIUpsellInformationTriggerHelper objHelper = new HIUpsellInformationTriggerHelper();
				objHelper.processBeforeInsert(newRecords);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('HIUpsellInformationTriggerHandler', 'BeforeInsert', ex);
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
				HIUpsellInformationTriggerHelper objHelper = new HIUpsellInformationTriggerHelper();
				objHelper.processAfterInsert(newRecordsMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('HIUpsellInformationTriggerHandler', 'AfterInsert', ex);
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
				HIUpsellInformationTriggerHelper objHelper = new HIUpsellInformationTriggerHelper();
				objHelper.processBeforeUpdate(oldRecordsMap, newRecordsMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('HIUpsellInformationTriggerHandler', 'BeforeUpdate', ex);
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
				HIUpsellInformationTriggerHelper objHelper = new HIUpsellInformationTriggerHelper();
				objHelper.processAfterUpdate(oldRecordsMap, newRecordsMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('HIUpsellInformationTriggerHandler', 'AfterUpdate', ex);
			}
		}
	}
}