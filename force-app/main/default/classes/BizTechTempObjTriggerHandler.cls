public class BizTechTempObjTriggerHandler {
	public static boolean skipTrigger = false;

	public void OnAfterUpdate(Map<ID, BizTech_Temp_Obj__c> oldBizTechMap, Map<ID, BizTech_Temp_Obj__c> newBizTechMap) {
		Set<Id> set_QueuedBizTechRecords = new Set<Id>();
		for (BizTech_Temp_Obj__c objBizTech : newBizTechMap.Values()) {
			BizTech_Temp_Obj__c objBizTechOld = oldBizTechMap.get(objBizTech.Id);

			if (objBizTech.Status__c != objBizTechOld.Status__c && objBizTech.Status__c == 'Queued') {
				set_QueuedBizTechRecords.add(objBizTech.Id);
			}
		}

		if (set_QueuedBizTechRecords.size() > 0) {
			BTEmailScripts.createEmailCasesV2(set_QueuedBizTechRecords);
		}
	}
}