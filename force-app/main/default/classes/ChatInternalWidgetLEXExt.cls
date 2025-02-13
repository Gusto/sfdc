/**
 * @name         : ChatInternalWidgetLEXExt
 * @author       : Ankit CS
 * @date         : 06-30-2021
 * @description  : Apex controller for ChatInternalWidgetLEX VF page.
 * @test classes : SearchRelatedChatsControllerTest, ChatInternalWidgetLEXExtTest
**/
global with sharing class ChatInternalWidgetLEXExt {
    global LiveChatTranscript objChat { get; set; }
    global ChatInternalWidgetLEXExt(ApexPages.StandardController stdCtrl) {
        objChat = new LiveChatTranscript();
    }

    private static List<String> list_Queues = new List<String> {
        'Contractor Full-Stack Internal Chatters', 
        'Contractor Payroll Internal Chatters', 
        'Vendor SME PRC Internal Chat', 
        'Vendor SME FSC Internal Chat'
    };

    /**
     * @Author      : Ankit CS
     * @Description : Getter method for Case_Reason__c
     * @Parm        : NA
     * @Return      : Id- Case Reason Id
    **/
    global Id getCaseReasonId() {
        return objChat.Case_Reason__c;
    }

    /**
     * @Author      : Ankit CS
     * @Description : To fetch the associated CaseId if the user is on a Chat Transcript record page.
     * @Parm        : idChat - Record Id of the LiveChatTranscript
     * @Return      : LiveChatTranscript record
    **/
    @RemoteAction
    global static InternalChatWrapper queryCaseInfo(Id idChat) {
        List<LiveChatTranscript> list_Chat = [SELECT Case.CaseNumber, CaseId, Case.Origin FROM LiveChatTranscript WHERE Id = :idChat];
        InternalChatWrapper objWrapper = new InternalChatWrapper();
        if (!list_Chat.isEmpty()) {
            objWrapper.objLiveChatTranscript = list_Chat[0];
            List<Internal_Chat_Cut_off_Time__mdt> list_CutoffTimeMetadata = queryCutOffTimeMetadata(list_Chat[0].Case.Origin);
            if (!list_CutoffTimeMetadata.isEmpty()) {
                objWrapper.objCutoffTime = list_CutoffTimeMetadata[0];
            }
            
            objWrapper = checkQueuesForUser(UserInfo.getUserId(), objWrapper);
        }

        return objWrapper;
    }

    /**
     * @Author      : Ankit CS
     * @Description : To query the case fields based on record id.
     * @Parm        : idCaseId - Record Id of the Case
     * @Return      : Case
    **/
    @RemoteAction
    global static InternalChatWrapper getCaseInfoById(Id idCaseId) {
        InternalChatWrapper objWrapper = new InternalChatWrapper();
        List<Case> list_Cases = [SELECT Id, Origin FROM Case WHERE Id = :idCaseId];
        if (!list_Cases.isEmpty()) {
            objWrapper.objCase = list_Cases[0];
            List<Internal_Chat_Cut_off_Time__mdt> list_CutoffTimeMetadata = queryCutOffTimeMetadata(list_Cases[0].Origin);
            if (!list_CutoffTimeMetadata.isEmpty()) {
                objWrapper.objCutoffTime = list_CutoffTimeMetadata[0];
            }

            objWrapper = checkQueuesForUser(UserInfo.getUserId(), objWrapper);
        }
        return objWrapper;
    }

    /**
     * @Author      : Ankit CS
     * @Description : To query the active Internal_Chat_Cut_off_Time__mdt matching the Case Origin
     * @Parm        : strCaseOrigin - Case Origin
     * @Return      : List<Internal_Chat_Cut_off_Time__mdt>
    **/
    global static List<Internal_Chat_Cut_off_Time__mdt> queryCutOffTimeMetadata(String strCaseOrigin) {
        if (Test.isRunningTest()) {
            List<Internal_Chat_Cut_off_Time__mdt> list_CutoffTimeMetadata
                = ChatInternalWidgetLEXExtTest.initializeCutoffTimeMetadata(strCaseOrigin);
            return list_CutoffTimeMetadata;
        } else { 
            return [SELECT 
                    Id, 
                    Case_Origin__c,
                    Cut_off_Time__c,
                    Message__c,
                    IsActive__c,
                    User_Roles_to_Exclude__c
                    FROM Internal_Chat_Cut_off_Time__mdt
                    WHERE IsActive__c = true
                    AND Case_Origin__c = :strCaseOrigin
                   ];
        }
    }

    /**
     * @Author      : Ankit CS
     * @Description : To stores parameters in the Platform Cache which will be used in the lightning components.
     * @Parm        : strQuestion - Question entered by the agent
     *                strFocusedTab - Id of the original tab
     * @Return      : Success/ Failure
    **/
    @RemoteAction
    global static String createSessionCache(String strQuestion, String strFocusedTab) {
        String strResult = 'Failure';
        if (String.isNotBlank(strQuestion) && String.isNotBlank(strFocusedTab)) {
            Cache.Session.put('local.CustomComponentsCache.question', strQuestion);
            Cache.Session.put('local.CustomComponentsCache.originalTabId', strFocusedTab);
            if (Cache.Session.contains('local.CustomComponentsCache.question') 
                && Cache.Session.contains('local.CustomComponentsCache.originalTabId')) {
                strResult = 'Success';
            }
        }
       return strResult; 
    }

    /**
     * @Author      : Ankit CS
     * @Description : This method checks if the User is in the queues or not.
     * @Parm        : idUser - User Id
     * @Return      : InternalChatWrapper
    **/
    global static InternalChatWrapper checkQueuesForUser(Id idUser, InternalChatWrapper objWrapper) {
        Map<Id, Group> map_Groups = new Map<Id, Group>([SELECT Id, Name FROM Group WHERE Name IN :list_Queues]);

        List<GroupMember> list_GroupMembers = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember 
                                               WHERE UserOrGroupId = :idUser
                                               AND GroupId IN :map_Groups.keySet()];

        for (GroupMember objMember : list_GroupMembers) {
            String strQueueName = map_Groups.get(objMember.GroupId).Name;
            if (strQueueName == 'Contractor Payroll Internal Chatters') {
                objWrapper.blnIsPRCContractor = true;
            }

            if (strQueueName == 'Contractor Full-Stack Internal Chatters') {
                objWrapper.blnIsFSCContractor = true;
            }

            if (strQueueName == 'Vendor SME PRC Internal Chat' || strQueueName == 'Vendor SME FSC Internal Chat') {
                objWrapper.blnIsVendorSME = true;
            }
        }
        
        return objWrapper; 
    }

    /**
    * @name         : InternalChatWrapper
    * @author       : Ankit CS
    * @date         : 09-23-2021
    * @description  : Wrapper for Internal Chat data
    * @test classes : ChatInternalWidgetLEXExtTest
    **/
    global class InternalChatWrapper {
        global Case objCase = new Case();
        global Internal_Chat_Cut_off_Time__mdt objCutoffTime;
        global LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript();
        global Boolean blnIsPRCContractor = false;
        global Boolean blnIsFSCContractor = false;
        global Boolean blnIsVendorSME = false;
    }
}