/**
 * @name         : FireCaseAssignmentRule
 * @author       : Pradeep Chary
 * @date         : 02-03-2023
 * @description  : Fire Case Assignment Rule from Flows
 * @test classes : FireCaseAssignmentRuleTest
**/
public class FireCaseAssignmentRule {
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Fires Case Assignment Rules for Cases whose Owners are as Input
     * @Parm        : list_Input - User Ids
    **/
    @InvocableMethod(label='Fire Case Assignment Rule' description='Trigger Case Assignment Rules Invocable.')
    public static void triggerCaseAssignmentRule(List<CaseAssignmentInput> list_Input) {
        List<Id> list_UserIds = new List<Id>();
        CaseAssignmentInput objInput = list_Input.get(0);
        list_UserIds.add(objInput.idUser);
        futureTriggerCaseAssignmentRule(list_UserIds, objInput.blnPostMessage, objInput.strMessage);
    }
    
    @future
    public static void futureTriggerCaseAssignmentRule(List<Id> list_UserIds, Boolean blnPostMessage, String strMessage) {
        List<Case> list_CasesToUpdate = new List<Case>();
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        List<User> list_Users = [SELECT Id, IsActive FROM User WHERE Id IN :list_UserIds];
        Boolean blnUserActive = list_Users[0].IsActive;
        
        String strOpen = CaseUtils.STATUS_OPEN;
        String strClosed = CaseUtils.STATUS_CLOSED;
        String strSolved = CaseUtils.STATUS_SOLVED;
        String strAwaitingExternalSupport = CaseUtils.STATUS_AWAITING_EXTERNAL_SUPPORT;
        String strAwaitingInternalSupport = CaseUtils.STATUS_AWAITING_INTERNAL_SUPPORT;
        String strAwaitingResponse = CaseUtils.STATUS_AWAITING_RESPONSE;
        String strTaxRes = CaseUtils.RECTYPE_NAME_TAXRES;
        
        String strQuery = 'SELECT Id FROM Case WHERE OwnerId IN :list_UserIds ';
        
        if (!blnUserActive) {
            strQuery = strQuery + 'AND Status = :strOpen ';
        }
        
        strQuery = strQuery + 'AND Status != :strClosed AND Status != :strSolved ' +
            'AND Status != :strAwaitingExternalSupport AND Status != :strAwaitingInternalSupport ' +
            'AND Status != :strAwaitingResponse AND IsClosed != TRUE ' +
            'AND RecordType.DeveloperName != :strTaxRes';
        
        List<Case> list_Cases = Database.query(strQuery);
        
        List<PostToChatterInvocable.PostToChatterInput> list_PostToChatterInput = new List<PostToChatterInvocable.PostToChatterInput>();
        
        for (Case objCase : list_Cases) {
            objCase.setOptions(dmo);
            list_CasesToUpdate.add(objCase);
            
            if (blnPostMessage) {
                PostToChatterInvocable.PostToChatterInput objPostToChatterInput = new PostToChatterInvocable.PostToChatterInput();
                objPostToChatterInput.idTargetRecord = objCase.Id;
                objPostToChatterInput.strText = strMessage;
                list_PostToChatterInput.add(objPostToChatterInput);
            }
        }
        
        try {
            update list_CasesToUpdate;
        } catch (Exception objException) {
            ExceptionLogUtil.logException(
                'FireCaseAssignmentRule',
                'futureTriggerCaseAssignmentRule',
                objException.getMessage(),
                objException.getStackTraceString());
        }
        
        if (!list_PostToChatterInput.isEmpty()) {
            PostToChatterInvocable.postChatter(list_PostToChatterInput);
        }
    }
    
    /**
     * @Name        : CaseAssignmentInput
     * @Author      : Pradeep Chary
     * @Description : Inputs for User Flow to fire Case Assignment Rule
     * @Date        : 02-03-2023
    **/
    public class CaseAssignmentInput {
        @InvocableVariable(
            required=true
            label='User Id'
            description='Id of the Current User'
        )
        public Id idUser;
        
        @InvocableVariable(
            required=true
            label='Post to Chatter?'
            description='Mark True for Chatter Post'
        )
        public Boolean blnPostMessage;
        
        @InvocableVariable(
            required=false
            label='Post Message'
            description='Message for the Chatter Body'
        )
        public String strMessage;
        
        public CaseAssignmentInput() {}
    }
}