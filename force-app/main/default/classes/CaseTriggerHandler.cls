/**
 * @author Alex Xiong
 * @description handler class for CaseTrigger
 * @see CaseTriggerHelperTest
 */
public class CaseTriggerHandler extends TriggerHandler {
    // Context Specific Skip Flags
    public static Boolean blnSkipBeforeInsert = false;
    public static Boolean blnSkipAfterInsert = false;
    public static Boolean blnSkipBeforeUpdate = false;
    public static Boolean blnSkipAfterUpdate = false;
    public static Boolean blnSkipBeforeDelete = false;

    /**** To reset all skip trigger flags for Case ****/
    public static void resetSkipTriggerFlags() {
        CaseTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = false;
    }

    /**** Handles Before Insert Context ****/
    public override void beforeInsert() {
        // Check if Before Insert logic needs to be skipped
        if (!blnSkipBeforeInsert) {
            try {
                CaseTriggerHelper objHelper = new CaseTriggerHelper();
                objHelper.processBeforeInsert((List<Case>) Trigger.new);
            } catch (Exception ex) {
                triggerExceptionEmail(ex, 'BeforeInsert');
            }
        }
    }

    /**** Handles After Insert Context ****/
    public override void afterInsert() {
        // Check if After Insert logic needs to be skipped
        if (!blnSkipAfterInsert) {
            try {
                CaseTriggerHelper objHelper = new CaseTriggerHelper();
                objHelper.processAfterInsert((Map<Id, Case>) Trigger.newMap);
            } catch (Exception ex) {
                triggerExceptionEmail(ex, 'AfterInsert');
            }
        }
    }

    /**** Handles Before Update Context ****/
    public override void beforeUpdate() {
        // Check if Before Update logic needs to be skipped
        if (!blnSkipBeforeUpdate) {
            try {
                CaseTriggerHelper objHelper = new CaseTriggerHelper();
                objHelper.processBeforeUpdate(
                    (Map<Id, Case>) Trigger.oldMap,
                    (Map<Id, Case>) Trigger.newMap
                );
            } catch (Exception ex) {
                triggerExceptionEmail(ex, 'BeforeUpdate');
            }
        }
    }

    /**** Handles After Update Context ****/
    public override void afterUpdate() {
        // Check if After Update logic needs to be skipped
        if (!blnSkipAfterUpdate) {
            try {
                CaseTriggerHelper objHelper = new CaseTriggerHelper();
                objHelper.processAfterUpdate(
                    (Map<Id, Case>) Trigger.oldMap,
                    (Map<Id, Case>) Trigger.newMap
                );
            } catch (Exception ex) {
                triggerExceptionEmail(ex, 'AfterUpdate');
            }
        }
    }

    /**** Handles Before Delete Context ****/
    public override void beforeDelete() {
        // Check if After Update logic needs to be skipped
        if (!blnSkipBeforeDelete) {
            try {
                CaseTriggerHelper objHelper = new CaseTriggerHelper();
                objHelper.processBeforeDelete(
                    (List<Case>) Trigger.old,
                    (Map<Id, Case>) Trigger.oldMap
                );
            } catch (Exception ex) {
                triggerExceptionEmail(ex, 'BeforeDelete');
            }
        }
    }

    /**
     * @author Alex Xiong
     * @description create Exception Log and send an email whenever CaseTrigger has an error
     */
    public static void triggerExceptionEmail(Exception ex, String strContext) {
        if (Test.isRunningTest() && !EmailToCaseTest.blnTestRealLife) {
            for (Case objCase : (List<Case>) Trigger.new) {              
                objCase.addError('\n\nCaused by: ' + ex.getTypeName() + ': ' + ex.getMessage() + '\n\n' + ex.getStackTraceString());                                                                                        
            }
        }

        ExceptionLogUtil.logException('CaseTrigger', strContext, 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
        String strToAddresses = System.Label.Daily_Limit_Notification_Email_List;
        List<String> list_ToAddresses = strToAddresses.split(';');

        String strEmailSubject = 'Case Trigger Exception: ' + ex.getMessage();
        String strEmailBody = 'Case Trigger Exception:\n\nCaused by: ' + ex.getTypeName() + ': ' + ex.getMessage() + '\n\n' + ex.getStackTraceString();

        Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
        objEmail.setSubject(strEmailSubject);
        objEmail.setPlainTextBody(strEmailBody);
        objEmail.setToAddresses(list_ToAddresses);
        if(OrganizationUtilities.canSendEmails()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{objEmail});
        }
    }

}