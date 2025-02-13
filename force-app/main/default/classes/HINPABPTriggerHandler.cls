/*
 * @name         : HINPABPTriggerHandler
 * @author       : Sanjay Paryani
 * @date         : 06-04-2021
 * @description  : HI_New_Plans_ApplicationsBenefitsPackage__c Handler Logic
 * @test classes : HINPABPTriggerHelperTest
 */
public class HINPABPTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipAfterInsert = false;

	/**** Handles After Insert Context ****/
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				HINPABPTriggerHelper objHelper = new HINPABPTriggerHelper();
				objHelper.processAfterInsert((Map<Id, HI_New_Plans_ApplicationsBenefitsPackage__c>) Trigger.newMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'HINPABPTriggerHandler',
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
}