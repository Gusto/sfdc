/*************************************************************************************************************
 * @name			CloseOutAbondonedCasesBatch
 * @author			Dhir Kumar
 * @created			12 / 10 / 2020
 * @description
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	--------------------	----------------------------------------------
 * @version		1.0		2020-10-12		Dhir Kumar
 **************************************************************************************************************/
global class CloseOutAbandonedCasesBatch implements Database.Batchable<sObject> {
	global Database.QueryLocator start(Database.BatchableContext bc) {
		// collect the batches of records or objects to be passed to execute
		String strQuery =
			'SELECT Id, RecordTypeId, RecordType.Name, (SELECT Id, OwnerId FROM Tasks WHERE Type = \'Call\'), Call_Connected__c FROM Case ' +
			' WHERE Owner.Name = \'Phone Routing\'' +
			' AND Call_Connected__c = false ' +
			' AND Origin = \'Phone\'';

		return Database.getQueryLocator(strQuery);
	}

	global void execute(Database.BatchableContext bc, List<Case> list_cases) {
		// process each batch of records
		List<Case> list_UpdateCloseCase = new List<Case>();
		List<Case> list_UpdateCase = new List<Case>();

		Map<String, Id> map_RecordTypeNameToRecordTypeId = new Map<String, Id>();
		for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Case']) {
			map_RecordTypeNameToRecordTypeId.put(rt.Name, rt.id);
		}

		for (Case caseRecord : list_cases) {
			if (caseRecord.Tasks.isEmpty()) {
				if (map_RecordTypeNameToRecordTypeId.containsKey(caseRecord.RecordType.Name) && map_RecordTypeNameToRecordTypeId.containsKey(caseRecord.RecordType.Name + ' - Read Only')) {
					caseRecord.RecordTypeId = map_RecordTypeNameToRecordTypeId.get(caseRecord.RecordType.Name + ' - Read Only');
				}
				caseRecord.Closed_Reason__c = 'Abandoned Call';
				caseRecord.Send_Survey__c = false;
			}
			caseRecord.Status = 'Closed';
			list_UpdateCase.add(caseRecord);
		}
		try {
			// Update the Records
			CaseTriggerHelper.skipTrigger = true;
			update list_UpdateCase;
		} catch (Exception e) {
			ExceptionLogUtil.logException('CloseOutAbandonedCasesBatch', 'execute', e.getMessage(), e.getStackTraceString());
		}
	}
	

	global void finish(Database.BatchableContext bc) {
		// execute any post-processing operations
	}
}