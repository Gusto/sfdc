public class HackathonJJAO {
    public static Map<String, String> mapResponses = getMapResponses();
    
    public static Map<String, String> getMapResponses(){
        Map<String, String> mapReponsesTemp = new Map<String, String>();
        mapReponsesTemp.put('Check for EE Benefits Changes', '<span>Yes, there have been recent member level benefits changes for the Happy Gusto Company One. Here are the relevant cases:</span>\n<ol>\n    <li style=\"list-style-type:decimal;color:#24292f;\">\n        <span style=\"color:#24292f;background-color:#ffffff;\">Subject: Happy Gusto Company One. : Cody Brehm : Principal : Member Updates</span>\n        <ul>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Employee: Cody Brehm</span>\n            </li>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Date of Change: 02-10-2025</span>\n            </li>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Description: The last name was updated from Brehm to Lyda. COBRA has been activated.</span>\n            </li>\n        </ul>\n    </li>\n    <li style=\"list-style-type:decimal;color:#24292f;\">\n        <span style=\"color:#24292f;background-color:#ffffff;\">Subject: Happy Gusto Company One. : Customer-Aa M : UnitedHealthcare : QLE</span>\n        <ul>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Employee: Customer-Aa P M</span>\n            </li>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Date of Change: 08-15-2024</span>\n            </li>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Description: Enrolled the newborn child (NG) in UnitedHealthcare plans due to the qualifying life event (Birth of a Child).</span>\n            </li>\n        </ul>\n    </li>\n    <li style=\"list-style-type:decimal;color:#24292f;\">\n        <span style=\"color:#24292f;background-color:#ffffff;\">Subject: Happy Gusto Company One. : Customer-Aa M : Blue Cross Blue Shield : QLE</span>\n        <ul>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Employee: Customer-Aa P M</span>\n            </li>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Date of Change: 08-15-2024</span>\n            </li>\n            <li style=\"list-style-type:circle;color:#24292f;\">\n                <span style=\"color:#24292f;background-color:#ffffff;\">Description: Enrolled the newborn child (NG) in Blue Cross Blue Shield plans due to the qualifying life event (Birth of a Child).</span>\n            </li>\n        </ul>\n    </li>\n</ol>');
        return mapReponsesTemp;
    }
    @AuraEnabled
    public static List<SObject> getPennyAcctions(String recordId, String strRecordTypeName, String strObjectName){
        System.debug(recordId + ':' + strRecordTypeName + ':' + strObjectName);
        List<Hackathon_JJAO__mdt> list_metadata = [SELECT id, 
                                                   Action_Name__c, 
                                                   Record_Type_Name__c, Object__c  
                                                   FROM Hackathon_JJAO__mdt 
                                                   WHERE Object__c =: strObjectName
                                                   AND Record_Type_Name__c =:strRecordTypeName];
        
        
        list_metadata.addAll([SELECT id, 
                              Action_Name__c, 
                              Record_Type_Name__c, Object__c  
                              FROM Hackathon_JJAO__mdt 
                              WHERE Object__c = null]);
        
        list_metadata.addAll([SELECT id, 
                              Action_Name__c, 
                              Record_Type_Name__c, Object__c  
                              FROM Hackathon_JJAO__mdt 
                              WHERE Object__c =: strObjectName 
                              AND Record_Type_Name__c = null]);
        return list_metadata;
        
    }
    
    @AuraEnabled
    public static List<Object> callGTP(Id promptId, List<Object> prevResponse){
        System.debug('promptId:'+promptId);
        Hackathon_JJAO__mdt mtd_metadata = [SELECT id, 
                                             Action_Name__c, 
                                             Record_Type_Name__c, Object__c, Prompt__c
                                             FROM Hackathon_JJAO__mdt 
                                             WHERE Id =: promptId];
        Datetime start = System.Now();
        //Making chatGPT Call
        //Getting data
        //Adding promtp from metadata
        //Adding previousResponse in case there are any
        //Mocking response
        System.debug('mtd_metadata:'+mtd_metadata);
		List<String> response = new List<String>();
        System.debug('mapResponses:'+mapResponses);
        response.add(mapResponses.get(mtd_metadata.Action_Name__c));
        while (System.Now().getTime() < start.getTime() + 2000) {
        } //Delay
        return response;
    }

}