/**
 * @name         : GFTicketTriggerHandler
 * @author       : Alex Xiong
 * @date         : 04/20/2021
 * @description  : The trigger handler for processing GF Tickets
 * @test classes : GFTicketTriggerHelperTest
 **/
public class GFTicketTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;

	/**** To reset all skip trigger flags for GF_Ticket__c ****/
	public static void resetSkipTriggerFlags() {
		GFTicketTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**** Handles Before Insert Context ****/
	public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				GFTicketTriggerHelper objHelper = new GFTicketTriggerHelper();
				objHelper.processBeforeInsert((List<GF_Ticket__c>) Trigger.new);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('GFTicketTriggerHandler', 'BeforeInsert', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}
	}

	/**** Handles After Insert Context ****/
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				GFTicketTriggerHelper objHelper = new GFTicketTriggerHelper();
				objHelper.processAfterInsert((Map<Id, GF_Ticket__c>) Trigger.newMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('GFTicketTriggerHandler', 'AfterInsert', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}
	}

	/**** Handles Before Update Context ****/
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				GFTicketTriggerHelper objHelper = new GFTicketTriggerHelper();
				objHelper.processBeforeUpdate(
					(Map<Id, GF_Ticket__c>) Trigger.oldMap,
					(Map<Id, GF_Ticket__c>) Trigger.newMap
				);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('GFTicketTriggerHandler', 'BeforeUpdate', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}

		if(blnTestException){
			Integer intException = 0 / 0;
		}
	}

	/**** Handles After Update Context ****/
	public override void afterUpdate() {
		// Check if After Update logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				GFTicketTriggerHelper objHelper = new GFTicketTriggerHelper();
				objHelper.processAfterUpdate(
					(Map<Id, GF_Ticket__c>) Trigger.oldMap,
					(Map<Id, GF_Ticket__c>) Trigger.newMap
				);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('GFTicketTriggerHandler', 'AfterUpdate', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}
	}
}