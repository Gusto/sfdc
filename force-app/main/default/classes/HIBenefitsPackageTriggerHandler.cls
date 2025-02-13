/*
 * @name         : HIBenefitsPackageTriggerHandler
 * @author       : Sanjay Paryani
 * @date         : 05-12-2021
 * @description  : HI_Benefits_Package__c Handler Logic
 * @test classes : HIBenefitsPackageTriggerHelperTest
 */
public class HIBenefitsPackageTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipAfterUpdate = false;

	/**** Handles After Insert Context ****/
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				HIBenefitsPackageTriggerHelper objHelper = new HIBenefitsPackageTriggerHelper();
				objHelper.processAfterInsert((Map<Id, HI_Benefits_Package__c>) Trigger.newMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'HIBenefitsPackageTriggerHandler',
					'AfterInsert',
					'Exception On Line ' +
					ex.getLineNumber() +
					'-' +
					ex.getMessage(),
					ex.getStackTraceString()
				);
			}
		}
	}

	/**** Handles After Update Context ****/
	public override void afterUpdate() {
		if (!blnSkipAfterUpdate) {
			try {
				HIBenefitsPackageTriggerHelper objHelper = new HIBenefitsPackageTriggerHelper();
				objHelper.processAfterUpdate((Map<Id, HI_Benefits_Package__c>) Trigger.newMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'HIBenefitsPackageTriggerHandler',
					'AfterUpdate',
					'Exception On Line ' +
					ex.getLineNumber() +
					'-' +
					ex.getMessage(),
					ex.getStackTraceString()
				);
			}
		}
	}
}