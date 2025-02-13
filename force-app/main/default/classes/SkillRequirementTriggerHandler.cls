/**
* @description  Handler class for SkillRequirementTrigger
* @author       Ankit C
* @date         08-06-2024
* @see          SkillRequirementTriggerTest
**/
public class SkillRequirementTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipAfterInsert = false;
	
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				if (
					Test.isRunningTest() && 
					SkillRequirementTriggerHelper.blnThrowException
				) {
					throw new NullPointerException();
				}
				
				SkillRequirementTriggerHelper objHelper = new SkillRequirementTriggerHelper();
				objHelper.processAfterInsert(trigger.new);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'SkillRequirementTriggerHandler', 
					'afterInsert', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
	/**
	 * @description Handle beforeInsert context
	 * @author      Sirisha K
	 * @param       Invoked before interest to default the skill level on the PSR to 10 
	 * @return      NA
	**/
	public override void beforeInsert() {
		if (!blnSkipAfterInsert) {
			try {
				if (
					Test.isRunningTest() && 
					SkillRequirementTriggerHelper.blnThrowException
				) {
					throw new NullPointerException();
				}
				SkillRequirementTriggerHelper objHelper = new SkillRequirementTriggerHelper();
				objHelper.processBeforeInsert(trigger.new);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'SkillRequirementTriggerHandler', 
					'beforeInsert', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
}