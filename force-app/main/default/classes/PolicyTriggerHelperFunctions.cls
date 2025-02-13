public class PolicyTriggerHelperFunctions {
	public static Map<Id, List<Policy__c>> getSelectedPoliciesByOpportunityId(Set<Id> opptyIdSet) {
		Map<Id, List<Policy__c>> oppPoicyMap = new Map<Id, List<Policy__c>>();

		for (Opportunity opp : [SELECT Id, (SELECT Id, State__c, State__r.Abbreviation__c, Carrier__c FROM Policies__r WHERE Is_Selected__c = TRUE) FROM Opportunity WHERE Id IN :opptyIdSet]) {
			List<Policy__c> policyList = new List<Policy__c>();
			if (oppPoicyMap.containsKey(opp.Id)) {
				policyList = oppPoicyMap.get(opp.Id);
			}
			if (opp.Policies__r != null) {
				for (Policy__c pol : opp.Policies__r) {
					policyList.add(pol);
				}
			}

			oppPoicyMap.put(opp.Id, policyList);
		}

		return oppPoicyMap;
	}
}