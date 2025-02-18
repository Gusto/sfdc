/**
 * @name         : MessagingSessionTriggerHelper
 * @author       : Pradeep Chary
 * @date         : 09-09-2024
 * @description  : Handler Class for trigger on Messaging Session object
 * @test classes : MessagingSessionTriggerHelperTest
**/
public class MessagingSessionTriggerHandler extends TriggerHandler {
    // Context Specific Skip Flags
    public static Boolean blnSkipBeforeInsert = false;
    public static Boolean blnSkipAfterInsert = false;
    public static Boolean blnSkipBeforeUpdate = false;
    public static Boolean blnSkipAfterUpdate = false;
    public static Boolean blnSkipBeforeDelete = false;
    
    /**** To reset all skip trigger flags for MessagingSession ****/
    public static void resetSkipTriggerFlags() {
        MessagingSessionTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = false;
    }
    
    /**** Handles Before Insert Context ****/
    public override void beforeInsert() {
        // Check if Before Insert logic needs to be skipped
        if (!blnSkipBeforeInsert) {
            try {
                MessagingSessionTriggerHelper objHelper = new MessagingSessionTriggerHelper();
                objHelper.OnBeforeInsert((List<MessagingSession>) Trigger.new);
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
                MessagingSessionTriggerHelper objHelper = new MessagingSessionTriggerHelper();
                objHelper.OnAfterInsert((Map<Id, MessagingSession>) Trigger.newMap);
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
                MessagingSessionTriggerHelper objHelper = new MessagingSessionTriggerHelper();
                objHelper.OnBeforeUpdate(
                    (Map<Id, MessagingSession>) Trigger.oldMap,
                    (Map<Id, MessagingSession>) Trigger.newMap
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
                MessagingSessionTriggerHelper objHelper = new MessagingSessionTriggerHelper();
                objHelper.OnAfterUpdate(
                    (Map<Id, MessagingSession>) Trigger.oldMap,
                    (Map<Id, MessagingSession>) Trigger.newMap
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
                MessagingSessionTriggerHelper objHelper = new MessagingSessionTriggerHelper();
                objHelper.onBeforeDelete(
                    (List<MessagingSession>) Trigger.old,
                    (Map<Id, MessagingSession>) Trigger.oldMap
                );
            } catch (Exception ex) {
                triggerExceptionEmail(ex, 'BeforeDelete');
            }
        }
    }
    
    /**
     * @author Pradeep Chary
     * @description create Exception Log and send an email whenever MessagingSessionTrigger has an error
    **/
    public static void triggerExceptionEmail(Exception ex, String strContext) {
        if (Test.isRunningTest() && !EmailToCaseTest.blnTestRealLife) {
            for (MessagingSession objMessagingSession : (List<MessagingSession>) Trigger.new) {              
                objMessagingSession.addError('\n\nCaused by: ' + ex.getTypeName() + ': ' + ex.getMessage() + '\n\n' + ex.getStackTraceString());                                                                                        
            }
        }
        
        ExceptionLogUtil.logException('MessagingSessionTrigger', strContext, 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
        String strToAddresses = System.Label.Daily_Limit_Notification_Email_List;
        List<String> list_ToAddresses = strToAddresses.split(';');
        
        String strEmailSubject = 'Messaging Session Trigger Exception: ' + ex.getMessage();
        String strEmailBody = 'Messaging Session Trigger Exception:\n\nCaused by: ' + ex.getTypeName() + ': ' + ex.getMessage() + '\n\n' + ex.getStackTraceString();
        
        Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
        objEmail.setSubject(strEmailSubject);
        objEmail.setPlainTextBody(strEmailBody);
        objEmail.setToAddresses(list_ToAddresses);
        if(OrganizationUtilities.canSendEmails()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{objEmail});
        }
    }
    
}