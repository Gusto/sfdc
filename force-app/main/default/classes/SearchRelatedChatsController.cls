/**
 * @name         : SearchRelatedChatsController
 * @author       : Ankit CS
 * @date         : 06-30-2021
 * @description  : Apex controller for searchRelatedChatsWrapper and searchRelatedChatsCmp.
 * @test classes : SearchRelatedChatsControllerTest
**/
public class SearchRelatedChatsController {
    //boolean for testing exception
    public static Boolean blnTestException = false;
    /**
     * @Author      : Ankit CS
     * @Description : Fetch the values from Platform Cache
     * @Return      : SessionCacheWrapper
    **/
    @AuraEnabled
    public static SessionCacheWrapper getSessionCache(){
        try {
            SessionCacheWrapper objWrapper = new SessionCacheWrapper();
            if (Cache.Session.contains('local.CustomComponentsCache.question')) {
                objWrapper.strQuestion = (String) Cache.Session.get('local.CustomComponentsCache.question');
            }
            if (Cache.Session.contains('local.CustomComponentsCache.originalTabId')) {
                objWrapper.strFocusedCase = (String) Cache.Session.get('local.CustomComponentsCache.originalTabId');
            }

            if (blnTestException == true) {
                Integer intZero = 0/0;
            }

            return objWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @Author      : Ankit CS
     * @Description : Fetch the list of related ChatTranscripts
     * @Parm        : strQuestion - Text entered by the agent in the search bar
     * @Return      : List<LiveChatTranscript>
    **/
    @AuraEnabled
    public static List<LiveChatTranscript> fetchRelatedChats(String strQuestion){
        try {
            //throw exception if boolean is true
            if (blnTestException == true) {
                Integer intZero = 0/0;
            }

            strQuestion = '*' + strQuestion + '*';
            List<List<SObject>> list_Results =  [FIND :strQuestion IN ALL FIELDS RETURNING LiveChatTranscript(Id, Name,
                                                 Question__c, Requested_By__r.Name, Owner.Name, Requested_By__c, OwnerId
                                                 WHERE RecordType.Name = 'Internal' ORDER BY CreatedDate DESC)];
            if (!list_Results.isEmpty()) {
                return (List<LiveChatTranscript>)list_Results[0];
            } else {
                return new List<LiveChatTranscript>();
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class SessionCacheWrapper {
        @AuraEnabled
        public String strQuestion;
        @AuraEnabled
        public String strFocusedCase;
    }
}