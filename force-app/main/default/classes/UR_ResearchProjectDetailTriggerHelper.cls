/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<UR_ResearchProjectDetailTriggerHelper>>
 * Description...........: <<Helper Class Of UR_ResearchProjectDetailTgr>>
 *-------------------------------------------------------------------------------*/

public with sharing class UR_ResearchProjectDetailTriggerHelper {
	public static boolean skipTrigger = false;
	public void OnBeforeInsert(List<Research_Project_Detail__c> newProjectDetail) {
		UpdateIncentiveAmount(newProjectDetail, false, null);
	}

	public void OnAfterInsert(Map<ID, Research_Project_Detail__c> newProjectDetailMap) {
		set<Id> setProjectId = new Set<Id>();
		for (Research_Project_Detail__c rpd : newProjectDetailMap.values()) {
			setProjectId.add(rpd.Research_Project_Master__c);
		}
		if (setProjectId != null && setProjectId.size() > 0) {
			UpdateProjectStatus(setProjectId, true);
		}
	}

	public void OnBeforeUpdate(Map<ID, Research_Project_Detail__c> oldProjectDetailMap, Map<ID, Research_Project_Detail__c> newProjectDetailMap) {
		UdateParticipantStatus(newProjectDetailMap.values(), oldProjectDetailMap);
		UpdateIncentiveAmount(newProjectDetailMap.values(), true, oldProjectDetailMap);
	}

	public void OnAfterUpdate(Map<ID, Research_Project_Detail__c> oldProjectDetailMap, Map<ID, Research_Project_Detail__c> newProjectDetailMap) {
		List<Research_Project_Detail__c> lstResPartDetail = new List<Research_Project_Detail__c>();
		for (Research_Project_Detail__c rpd : newProjectDetailMap.values()) {
			if (oldProjectDetailMap.get(rpd.Id).E_Mail_Status__c != 'Process Email' && rpd.E_Mail_Status__c == 'Process Email') {
				lstResPartDetail.add(rpd);
			}
		}
		if (lstResPartDetail != null && lstResPartDetail.size() > 0) {
			sendParticipantsEmail(lstResPartDetail);
		}
	}

	public void OnBeforeDelete(Research_Project_Detail__c[] projectDetailToDelete, Map<ID, Research_Project_Detail__c> oldProjectDetailMap) {
	}

	public void OnAfterDelete(Research_Project_Detail__c[] deletedProjectDetail, Map<ID, Research_Project_Detail__c> oldProjectDetailMap) {
		ContactTriggerHelper.skipTrigger = false;
		set<Id> setProjectId = new Set<Id>();
		for (Research_Project_Detail__c rpd : deletedProjectDetail) {
			setProjectId.add(rpd.Research_Project_Master__c);
		}
		if (setProjectId != null && setProjectId.size() > 0) {
			UpdateProjectStatus(setProjectId, false);
		}
	}

	public void OnUndelete(Research_Project_Detail__c[] restoredProjectDetail) {
	}

	//This method create map of all part status
	public void UdateParticipantStatus(List<Research_Project_Detail__c> lstRPD, Map<Id, Research_Project_Detail__c> mapOld) {
		Map<string, integer> mapStatus = new Map<String, Integer>{
			'Reserved' => 1,
			'Contacted' => 2,
			'Replied' => 3,
			'Disqualified' => 4,
			'Invited' => 5,
			'Scheduled' => 6,
			'Confirmed' => 7,
			'Attended' => 8,
			'No Show' => 9
		};
		for (Research_Project_Detail__c rpd : lstRPD) {
			//Get Old value
			Research_Project_Detail__c oldRpd = mapOld.get(rpd.Id);

			if (oldRpd.Research_Participant_Status__c != rpd.Research_Participant_Status__c) {
				//Get old Value number and New value number
				integer oldNumber = mapStatus.get(oldRpd.Research_Participant_Status__c);
				integer newNumber = mapStatus.get(rpd.Research_Participant_Status__c);
				//For time being I have commented code to check other funcctionality
				//if(newNumber<oldNumber){
				//rpd.addError('You can not set previous status');
				//}
			}
		}
	}

	// If participants status is not equals to Attended then this method reset the incentive account as : 0
	public void UpdateIncentiveAmount(List<Research_Project_Detail__c> lstRPD, boolean isUpdate, Map<ID, Research_Project_Detail__c> oldProjectDetailMap) {
		Research_Project_Detail__c oldObj = null;
		for (Research_Project_Detail__c rpd : lstRPD) {
			if (isUpdate == true && rpd.Research_Participant_Status__c != 'Attended') {
				rpd.Incentive__c = 0;
			}
			//Copy participants Comment first word into sort comment for sorting
			if (rpd.Comment__c != null) {
				rpd.Sort_Comment__c = rpd.Comment__c.split(' ')[0];
			}

			if (isUpdate) {
				oldObj = oldProjectDetailMap.get(rpd.Id);
				if (rpd.Applicable_for_Incentive__c == true) {
					if (rpd.Applicable_for_Incentive__c != oldObj.Applicable_for_Incentive__c) {
						rpd.Incentive_Date__c = Date.today();
					} else if (rpd.Proposed_Incentive__c != oldObj.Proposed_Incentive__c) {
						rpd.Incentive_Date__c = Date.today();
					}
				}
			} else if (rpd.Applicable_for_Incentive__c) {
				rpd.Incentive_Date__c = Date.today();
			}

			if (rpd.E_Mail_Status__c != null && rpd.E_Mail_Status__c != 'Fail') {
				rpd.Send_Email_Error__c = '';
			}
		}
	}

	//Change project Status from Initiated to "In progress" if any record;
	//Change Status back to "Initiated" is there is no record in participant
	public void UpdateProjectStatus(Set<id> setProjectId, boolean isInsert) {
		List<Research_Project_Master__c> lstUpdateProject = new List<Research_Project_Master__c>();
		if (isInsert == true) {
			for (Research_Project_Master__c rpm : [
				SELECT id, Project_Status__c
				FROM Research_Project_Master__c
				WHERE Project_Status__c = 'Initiated' AND id IN :setProjectId
			]) {
				rpm.Project_Status__c = 'In-Progress';
				lstUpdateProject.add(rpm);
			}
		}
		if (isInsert == false) {
			//check all project whether we do have any project detail or not
			for (Research_Project_Master__c rpm : [
				SELECT id, Project_Status__c, (SELECT id FROM Research_Project_Details__r)
				FROM Research_Project_Master__c
				WHERE Project_Status__c = 'In-Progress' AND id IN :setProjectId
			]) {
				//If There is no record left then change status
				/*This code was giving issue "Aggregate query has too many rows for direct assignment"
                 if(rpm.Research_Project_Details__r.size()==0){
                     rpm.Project_Status__c='Initiated';
                     lstUpdateProject.add(rpm);
                 }
				*/
				boolean partExist = false;
				for (Research_Project_Detail__c r : rpm.Research_Project_Details__r) {
					partExist = true;
				}
				if (partExist == false) {
					rpm.Project_Status__c = 'Initiated';
					lstUpdateProject.add(rpm);
				}
			}
		}
		if (lstUpdateProject != null && lstUpdateProject.size() > 0) {
			update lstUpdateProject;
		}
	}

	public void sendParticipantsEmail(List<Research_Project_Detail__c> lstResPartDetail) {
		boolean isSuccessFlag = false;
		if (lstResPartDetail != null && lstResPartDetail.size() > 0) {
			List<Research_Project_Detail__c> lstUpdatePart = new List<Research_Project_Detail__c>();
			Map<Id, Id> mapProjectDetails = new Map<Id, Id>();
			List<Messaging.SingleEmailMessage> mail = new List<Messaging.SingleEmailMessage>();
			for (Research_Project_Detail__c rpd : lstResPartDetail) {
				Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
				msg.setWhatId(rpd.Id);
				msg.setTargetObjectId(rpd.Contact__c);
				if (string.isNotBlank(UR_UtilityCtrl.strReplyEmail)) {
					msg.setReplyTo(UR_UtilityCtrl.strReplyEmail);
				}

				if (String.isNotBlank(rpd.E_Mail_Template_Id__c)) {
					msg.setTemplateId(rpd.E_Mail_Template_Id__c);
				} else {
					msg.setHtmlBody('emailBody');
					msg.setSubject('strSubject');
				}
				msg.setSaveAsActivity(true);

				if (UR_UtilityCtrl.orgWideEmail_NoReply != null) {
					msg.setOrgWideEmailAddressId(UR_UtilityCtrl.orgWideEmail_NoReply);
				}
				mail.add(msg);
				//Update Participant Status
				Research_Project_Detail__c objUpdate = new Research_Project_Detail__c(id = rpd.Id);
				objUpdate.Email_Type__c = rpd.Email_Type__c;
				objUpdate.E_Mail_Status__c = 'Email Sent';
				objUpdate.Research_Participant_Status__c = rpd.Research_Participant_Status__c;
				objUpdate.Incentive__c = rpd.Incentive__c;
				objUpdate.Proposed_Incentive__c = rpd.Proposed_Incentive__c;
				lstUpdatePart.add(objUpdate);
				mapProjectDetails.put(rpd.Id, rpd.Research_Project_Master__c);
			}
			if (mail.size() > 0) {
				try {
					skipTrigger(true);
					EmailMessageTriggerHelper.skipTrigger = true;
					Messaging.sendEmail(mail);
					EmailMessageTriggerHelper.skipTrigger = false;
					skipTrigger(false);
					isSuccessFlag = true;
				} catch (Exception ex) {
					isSuccessFlag = false;
					Set<Id> setProjectId = new Set<Id>();
					for (Research_Project_Detail__c objUpdate : lstUpdatePart) {
						objUpdate.E_Mail_Status__c = 'Fail';
						objUpdate.Send_Email_Error__c = ex.getMessage() + '';
						if (mapProjectDetails.containsKey(objUpdate.Id) && String.isNotBlank(mapProjectDetails.get(objUpdate.Id))) {
							setProjectId.add(mapProjectDetails.get(objUpdate.Id));
						}
					}

					List<Research_Project_Master__c> lstProjectMaster = new List<Research_Project_Master__c>();
					for (Id projectId : setProjectId) {
						lstProjectMaster.add(new Research_Project_Master__c(Id = projectId, Closed_Send_Email_Error_Message__c = false));
					}
					if (lstProjectMaster.size() > 0) {
						UR_ProjectMasterTriggerHelper.skipTrigger = true;
						update lstProjectMaster;
						UR_ProjectMasterTriggerHelper.skipTrigger = false;
					}
				}
			}

			//Now "Research Participant Status" will update, once email successully send.
			if (isSuccessFlag) {
				String strPartStatus = '';
				String finalStatus = '';
				for (Research_Project_Detail__c objUpdate : lstUpdatePart) {
					// "Research Participant Status" should not be changed, if participant is Attended and some incentive amount is given to it.
					if (objUpdate.Research_Participant_Status__c != 'Attended') {
						strPartStatus = objUpdate.Email_Type__c;
						if (String.isNotBlank(strPartStatus) && UR_UtilityCtrl.emailStatusMap.containsKey(strPartStatus) && String.isNotBlank(UR_UtilityCtrl.emailStatusMap.get(strPartStatus))) {
							finalStatus = UR_UtilityCtrl.emailStatusMap.get(strPartStatus);
							if (String.isNotBlank(finalStatus)) {
								objUpdate.Research_Participant_Status__c = finalStatus;
							}
						}
					}
				}
			}

			//Update Selected Participant Status
			if (lstUpdatePart != null && lstUpdatePart.size() > 0) {
				UR_ResearchProjectDetailTriggerHelper.skipTrigger = true;
				update lstUpdatePart;
				UR_ResearchProjectDetailTriggerHelper.skipTrigger = false;
			}
		}
	}

	public void skipTrigger(Boolean flag) {
		ContactTriggerHelper.skipTrigger = flag;
		AccountTriggerHelper.skipTrigger = flag;
	}
}