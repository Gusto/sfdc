/**
 * Author: Alex
 * Date: 8/20/2020
 * Desc: query helper class for IVRRoutingLogTriggerHelper
 */
public class IVRRoutingLogQueryHelper {
    public static List<Case> list_CasesFromIVR;

    public static List<Case> getCases(List<Id> list_IVRId) {
        if(list_CasesFromIVR == null) {
            list_CasesFromIVR = queryCases(list_IVRId);
        }
        
        return list_CasesFromIVR;
    }

    public static List<Case> queryCases(List<Id> list_IVRId) {
        List<Case> list_Cases = new List<Case>();
        for(Case c : [SELECT Id, IVR_Routing_Log__c FROM Case WHERE IVR_Routing_Log__c IN: list_IVRId]) {
            list_Cases.add(c);
        }
        
        return list_Cases;
    }
}