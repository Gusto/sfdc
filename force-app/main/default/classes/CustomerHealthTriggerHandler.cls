/**
    @Author       :   David (Dato) Tsamalashvili
    @CreatedDate  :   02/12/2024
    @Desc         :   Trigger Handler class that delegates tasks between CustomerHealthTrigger and CustomerHealthTriggerHeper
**/
public with sharing class CustomerHealthTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;

	/**** To reset all skip trigger flags for Customer Health ****/
	public static void resetSkipTriggerFlags() {
		CustomerHealthTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**** Handles Before Insert Context ****/
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				CustomerHealthTriggerHelper customerHealthTrigHelper = new CustomerHealthTriggerHelper();
				customerHealthTrigHelper.processBeforeInsert(Trigger.new);

				//generate an error for testing
				if (blnTestException) {
					Integer intException = 0 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('CustomerHealthTriggerHandler', 'BeforeInsert', ex);
			}
		}
	}

	/**** Handles After Insert Context ****/
	public override void afterInsert() {
		// Check if After Insert Logic needs to be Skipped
		if (!blnSkipBeforeUpdate) {
			try {
				CustomerHealthTriggerHelper customerHealthTrigHelper = new CustomerHealthTriggerHelper();
				customerHealthTrigHelper.processAfterInsert(Trigger.new);

				//generate an error for testing
				if (blnTestException) {
					Integer intException = 0 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('CustomerHealthTriggerHandler', 'AfterInsert', ex);
			}
		}
	}

	/**** Handles Before Update Context ****/
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				CustomerHealthTriggerHelper customerHealthTrigHelper = new CustomerHealthTriggerHelper();
				customerHealthTrigHelper.processBeforeUpdate((List<Customer_Health__c>) Trigger.new, (Map<Id, Customer_Health__c>) Trigger.oldMap);

				//generate an error for testing
				if (blnTestException) {
					Integer intException = 0 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('CustomerHealthTriggerHandler', 'BeforeUpdate', ex);
			}
		}
	}

	/**** Handles After Update Context ****/
	public override void afterUpdate() {
		// Check if After Update Logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				CustomerHealthTriggerHelper customerHealthTrigHelper = new CustomerHealthTriggerHelper();
				customerHealthTrigHelper.processAfterUpdate((List<Customer_Health__c>) Trigger.new, (Map<Id, Customer_Health__c>) Trigger.oldMap);

				//generate an error for testing
				if (blnTestException) {
					Integer intException = 0 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('CustomerHealthTriggerHandler', 'AfterUpdate', ex);
			}
		}
	}
}