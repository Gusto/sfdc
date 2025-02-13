/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<>>
 * Description...........: <<Helper Class Of Survey Trigger>>
 *-------------------------------------------------------------------------------*/

public with sharing class UR_SurveyTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;

	public void OnBeforeInsert(List<Research_Survey__c> survey) {
	}

	public void OnAfterInsert(Map<ID, Research_Survey__c> newSurveyMap) {
		UdateStatusOnSurveyResponse(newSurveyMap.values());
	}

	public void OnBeforeUpdate(Map<ID, Research_Survey__c> oldSurveyMap, Map<ID, Research_Survey__c> newSurveyMap) {
		counter++;
	}

	public void OnAfterUpdate(Map<ID, Research_Survey__c> oldSurveyMap, Map<ID, Research_Survey__c> newSurveyMap) {
	}

	public void OnBeforeDelete(Research_Survey__c[] SurveyToDelete, Map<ID, Research_Survey__c> oldSurveyMap) {
		counter++;
	}

	public void OnAfterDelete(Research_Survey__c[] deletedSurvey, Map<ID, Research_Survey__c> oldSurveyMap) {
	}

	public void OnUndelete(Research_Survey__c[] restoredSurvey) {
		counter++;
	}

	//This method update participant status.
	private void UdateStatusOnSurveyResponse(List<Research_Survey__c> lstResponse) {
		set<string> setProjectPartId = new Set<string>();
		for (Research_Survey__c rsp : lstResponse) {
			if (rsp.Research_Project_Detail__c != null) {
				setProjectPartId.add(rsp.Research_Project_Detail__c);
			}
		}

		if (setProjectPartId != null && setProjectPartId.size() > 0) {
			List<Research_Project_Detail__c> lstRpd = new List<Research_Project_Detail__c>();
			for (Research_Project_Detail__c rpd : [
				SELECT id, Research_Participant_Status__c
				FROM Research_Project_Detail__c
				WHERE Id IN :setProjectPartId AND Research_Participant_Status__c = 'Invited'
			]) {
				rpd.Research_Participant_Status__c = 'Replied';
				lstRpd.add(rpd);
			}
			if (lstRpd != null && lstRpd.size() > 0) {
				update lstRpd;
			}
		}
	}
}