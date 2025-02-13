/**
 * Handler using 2021 Trigger Handler format
 * @author David Schach
 */
public with sharing class HRWorkerInformationTriggerHandler extends TriggerHandler {
	private List<HR_Worker_Information__c> newRecords;
	private List<HR_Worker_Information__c> oldRecords;
	private Map<Id, HR_Worker_Information__c> newRecordsMap;
	private Map<Id, HR_Worker_Information__c> oldRecordsMap;

	public HRWorkerInformationTriggerHandler() {
		super('HRWorkerInformationTriggerHandler');
		this.newRecords = (List<HR_Worker_Information__c>) Trigger.new;
		this.oldRecords = (List<HR_Worker_Information__c>) Trigger.old;
		this.newRecordsMap = (Map<Id, HR_Worker_Information__c>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, HR_Worker_Information__c>) Trigger.oldMap;
	}

	/**** Handles After Insert Context ****/
	public override void afterInsert() {
		assignManager(newRecords, null);
	}

	/**** Handles After Insert Context ****/
	public override void afterUpdate() {
		assignManager(newRecords, oldRecordsMap);
	}

	private void assignManager(List<HR_Worker_Information__c> newRecords, Map<Id, HR_Worker_Information__c> oldRecordsMap) {
		list<HR_Worker_Information__c> list_managerAssignmentInfo = new List<HR_Worker_Information__c>();

		for (HR_Worker_Information__c objNewRec : newRecords) {
			if (objNewRec.Employee_Id__c != null && objNewRec.Manager_ID__c != null && (oldRecordsMap == null || objNewRec.Manager_ID__c != oldRecordsMap.get(objNewRec.id).Manager_ID__c)) {
				list_managerAssignmentInfo.add(objNewRec);
			}
		}

		if (list_managerAssignmentInfo.size() > 0) {
			Map<String, String> map_employeeIdManagerId = new Map<String, String>();
			Set<String> set_allEmployeeIDs = new Set<String>();

			for (HR_Worker_Information__c objHRWorkInfo : list_managerAssignmentInfo) {
				if (objHRWorkInfo.Manager_ID__c != null && objHRWorkInfo.Employee_Id__c != null) {
					map_employeeIdManagerId.put(objHRWorkInfo.Employee_Id__c, objHRWorkInfo.Manager_ID__c);
					set_allEmployeeIDs.add(objHRWorkInfo.Manager_ID__c);
					set_allEmployeeIDs.add(objHRWorkInfo.Employee_Id__c);
				}
			}

			if (map_employeeIdManagerId.keyset().size() > 0) {
				List<User> list_employeeRecords = new List<User>();
				Map<String, Id> map_managerIdUserId = new Map<String, Id>();
				Map<String, Id> map_employeeNumberUserId = new Map<String, Id>();

				for (User objUserUsr : [SELECT Id, ManagerId, EmployeeNumber, Email FROM User WHERE EmployeeNumber IN :set_allEmployeeIDs]) {
					if (map_employeeIdManagerId.containsKey(objUserUsr.EmployeeNumber)) {
						list_employeeRecords.add(objUserUsr);
					}

					if (objUserUsr.EmployeeNumber != null) {
						map_employeeNumberUserId.put(objUserUsr.EmployeeNumber, objUserUsr.Id);
					}
				}

				for (User objUserUsr : list_employeeRecords) {
					if (objUserUsr.EmployeeNumber != null && map_employeeIdManagerId.containsKey(objUserUsr.EmployeeNumber)) {
						String strHrManagerId = map_employeeIdManagerId.get(objUserUsr.EmployeeNumber);
						objUserUsr.ManagerId = map_employeeNumberUserId.get(strHrManagerId);
					}
				}

				update list_employeeRecords;
			}
		}
	}
}