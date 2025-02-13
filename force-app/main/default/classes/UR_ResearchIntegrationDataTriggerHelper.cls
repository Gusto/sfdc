/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<>>
 * Description...........: <<Helper Class Of Research Integration Trigger>>
 *-------------------------------------------------------------------------------*/

public with sharing class UR_ResearchIntegrationDataTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;

	public void OnBeforeInsert(List<Research_Integration_Data__c> resIntegration) {
	}

	public void OnAfterInsert(Map<ID, Research_Integration_Data__c> newResIntegrationMap) {
		ProcessData(newResIntegrationMap.values());
	}

	public void OnBeforeUpdate(Map<ID, Research_Integration_Data__c> oldResIntegrationMap, Map<ID, Research_Integration_Data__c> newResIntegrationMap) {
		counter++;
	}

	public void OnAfterUpdate(Map<ID, Research_Integration_Data__c> oldResIntegrationMap, Map<ID, Research_Integration_Data__c> newResIntegrationMap) {
	}

	public void OnBeforeDelete(Research_Integration_Data__c[] resIntegrationToDelete, Map<ID, Research_Integration_Data__c> oldResIntegrationMap) {
		counter++;
	}

	public void OnAfterDelete(Research_Integration_Data__c[] deletedResIntegration, Map<ID, Research_Integration_Data__c> oldResIntegrationMap) {
	}

	public void OnUndelete(Research_Integration_Data__c[] restoredResIntegration) {
		counter++;
	}

	//This method parse Calendly response.
	public void ProcessData(List<Research_Integration_Data__c> lstResponse) {
		List<Research_Integration_Data__c> lstResponseCal = new List<Research_Integration_Data__c>();
		List<Research_Integration_Data__c> lstResponseSurvey = new List<Research_Integration_Data__c>();
		for (Research_Integration_Data__c ret : lstResponse) {
			if (ret.Integration_Type__c == 'Calendly Data') {
				lstResponseCal.add(ret);
			}
			if (ret.Integration_Type__c == 'Survey Response') {
				lstResponseSurvey.add(ret);
			}
		}
		if (lstResponseSurvey != null && lstResponseSurvey.size() > 0) {
			CreateSurveyResponse(lstResponseSurvey);
		}
		if (lstResponseCal != null && lstResponseCal.size() > 0) {
			CreateEvent(lstResponseCal);
		}
	}

	//Create Survey Response
	public static void CreateSurveyResponse(List<Research_Integration_Data__c> lstResponse) {
		try {
			string csvAsString = null;
			if (lstResponse != null && lstResponse.size() > 0) {
				for (Research_Integration_Data__c ret : lstResponse) {
					if (ret.Integration_Type__c == 'Survey Response') {
						csvAsString = ret.Data__c;
					}
				}
			}
			if (string.isNotBlank(csvAsString)) {
				List<List<String>> parsedCSV = new List<List<String>>();
				parsedCSV = UR_UtilityCtrl.parseCSV(csvAsString, true);
				List<Research_Survey__c> lstResearchSurvey = new List<Research_Survey__c>();

				List<Research_Survey_Response__c> lstRespponse = new List<Research_Survey_Response__c>();
				transient Map<string, Research_Survey__c> mapSurvey = new Map<string, Research_Survey__c>();
				transient Map<string, string> mapSurveyResponse = new Map<string, string>();
				List<String> forthHeader = new List<String>();
				if (parsedCSV.size() > 3) {
					//Parse 4th Row to get participant Id
					forthHeader = parsedCSV.get(3);
				}

				if (forthHeader != null && forthHeader.size() > 0) {
					integer partLocationId = null;
					transient Map<integer, string> mapQuestionCode;
					//First Header
					List<String> firstHeader = parsedCSV.get(0);
					mapQuestionCode = new Map<integer, string>();
					for (Integer inCols = 0; inCols < firstHeader.size(); inCols++) {
						if (inCols > 16) {
							mapQuestionCode.put(inCols, firstHeader[inCols]);
							//get Participant Id Location
							if (firstHeader[inCols] == 'sID') {
								partLocationId = inCols;
							}
						}
					}
					string participantId = forthHeader[partLocationId].Trim();

					//Get Project id
					string projectId = [SELECT Id, Research_Project_Master__c FROM Research_Project_Detail__c WHERE id = :participantId].Research_Project_Master__c;

					if (projectId != null) {
						for (Research_Survey__c rs : [
							SELECT id, Recorded_Date__c, Response_Id__c, Research_Project_Detail__c, (SELECT Id, Survey_Answers__c, Survey_Question_Code__c FROM Research_Survey_Responses__r)
							FROM Research_Survey__c
							WHERE Project_Id__c = :projectId
						]) {
							mapSurvey.put(rs.Response_Id__c, rs);

							for (Research_Survey_Response__c rsp : rs.Research_Survey_Responses__r) {
								mapSurveyResponse.put(rs.Id + '~' + rsp.Survey_Question_Code__c, rsp.Id);
							}
						}
					}

					//Second Header
					//Get all header map of question code and Qaution text
					transient map<string, string> mapQuestCodeText = new Map<string, string>();
					List<String> secondHeader = parsedCSV.get(1);
					for (Integer inCols = 0; inCols < secondHeader.size(); inCols++) {
						if (inCols > 16) {
							if (mapQuestionCode.get(inCols) != null) {
								mapQuestCodeText.put(mapQuestionCode.get(inCols), secondHeader[inCols]);
							}
						}
					}

					//Ignore third header and pars all header
					transient map<string, Map<string, string>> mapPartQuestAnswer = new Map<string, Map<string, string>>();
					transient map<string, string> mapQuestAnswer = new Map<string, string>();

					for (integer intRows = 3; intRows < parsedCSV.size(); intRows++) {
						List<string> lstString = new List<string>();
						lstString = parsedCSV[intRows];
						//get Participant id
						//string partId=lstString[lstString.size()-1].Trim();
						string partId = lstString[partLocationId].Trim();

						//get Response Id
						string responseId = lstString[8].Trim();

						Datetime dtm = null;
						if (string.isNotBlank(lstString[7])) {
							dtm = DateTime.valueof(lstString[7].Trim());
						}

						//Save data in Research Survey
						Research_Survey__c objSurvey = new Research_Survey__c();
						//Based on response Id check whether Record exist or not
						if (mapSurvey.get(responseId) != null) {
							objSurvey = mapSurvey.get(responseId);
						}
						objSurvey.Research_Project_Detail__c = partId;
						objSurvey.Recorded_Date__c = null;
						objSurvey.Recorded_Date__c = dtm;
						objSurvey.Response_Id__c = responseId;
						lstResearchSurvey.add(objSurvey);

						mapQuestAnswer = new Map<string, string>();
						for (integer intCol = 0; intCol < lstString.size(); intCol++) {
							string mapKey = mapQuestionCode.get(intCol);
							//Pick after 16th all column
							if (intCol > 16) {
								mapQuestAnswer.put(mapKey.Trim(), lstString[intCol]);
							}
						}

						if (String.isNotBlank(partId)) {
							partId = partId.Trim();
							if (partId.length() == 18) {
								partId = partId.subString(0, 15);
							}
						}
						mapPartQuestAnswer.put(partId.Trim(), mapQuestAnswer);
					}
					//Insert data in Research object
					Map<string, string> mapResearchSurveyParId = new Map<string, string>();
					if (lstResearchSurvey != null && lstResearchSurvey.size() > 0) {
						upsert lstResearchSurvey;
						//Create Map of Participant Id and Research Survey Id
						for (Research_Survey__c rs : lstResearchSurvey) {
							string strPartId = rs.Research_Project_Detail__c;
							if (String.isNotBlank(strPartId)) {
								strPartId = strPartId.Trim();
								if (strPartId.length() == 18) {
									strPartId = strPartId.subString(0, 15);
								}
							}
							mapResearchSurveyParId.put(strPartId, rs.id);
						}
					}

					if (mapPartQuestAnswer != null && mapPartQuestAnswer.size() > 0) {
						DateTime dtm = null;
						for (string strPartId : mapPartQuestAnswer.keySet()) {
							strPartId = strPartId.Trim();
							if (strPartId != 'sID') {
								//get Map of question answer
								Map<string, string> mapQuestionAnswer = mapPartQuestAnswer.get(strPartId);
								for (string strQ : mapQuestionAnswer.keySet()) {
									if (strQ.Trim() != 'sID') {
										//get Question based question code
										string strQuestion = mapQuestCodeText.get(strQ.Trim());

										//We might be get blank question.
										if (String.isNotBlank(strQuestion)) {
											//Get Answer of question
											string answer = mapQuestionAnswer.get(strQ).Trim();

											//get Research Survey id
											string resSurveyId = mapResearchSurveyParId.get(strPartId);
											//Check Same question if exits under same survey then update detail
											string strResponseId = mapSurveyResponse.get(resSurveyId + '~' + strQ.Trim());

											Research_Survey_Response__c rsr = new Research_Survey_Response__c();
											if (string.isNotBlank(strResponseId)) {
												rsr = new Research_Survey_Response__c(id = strResponseId);
											}
											if (String.isNotBlank(answer) && answer.contains('"')) {
												answer = answer.replace('"', '');
											}
											rsr.Survey_Answers__c = answer;
											//Replace double quote (") from questions if any
											rsr.Survey_Questions__c = strQuestion.replace('"', '');
											rsr.Survey_Question_Code__c = strQ;
											rsr.Research_Survey__c = resSurveyId;
											lstRespponse.add(rsr);
										}
									}
								}
							}
						}
					}
					if (lstRespponse != null && lstRespponse.size() > 0) {
						upsert lstRespponse;
						updateResearchIntegrationStatus(lstResponse[0].Id, 'Success', 'Success');
					}
					//After process delete from integration table
					//delete [select id from Research_Integration_Data__c where Integration_Type__c='Survey Response'];
				} else {
					updateResearchIntegrationStatus(lstResponse[0].Id, 'Failed', 'Data do not have any response');
				}
			} else {
				if (lstResponse != null && lstResponse.size() > 0) {
					updateResearchIntegrationStatus(lstResponse[0].Id, 'Failed', 'Blank Value');
				}
			}
		} catch (Exception ex) {
			if (lstResponse != null && lstResponse.size() > 0) {
				updateResearchIntegrationStatus(lstResponse[0].Id, 'Failed', ex.getLineNumber() + ' Response format is not correct - ' + ex.getMessage());
			}
		}
	}

	//This method create new event
	public static void CreateEvent(List<Research_Integration_Data__c> lstRep) {
		try {
			//get project Id and Email in map
			set<string> partId = new Set<string>();
			set<string> projectId = new Set<string>();
			set<string> setMeetingId = new Set<string>();
			for (Research_Integration_Data__c rs : lstRep) {
				partId.add(rs.Participant_Id__c);
				projectId.add(rs.Project_Id__c);
				setMeetingId.add(rs.Meeting_Id__c);
			}
			//Get All user list to hwo email need to sent
			Set<Id> setUserId = new Set<Id>();

			//Get project participant Id based on email
			Map<string, Research_Project_Detail__c> mapEmailPartId = new Map<string, Research_Project_Detail__c>();
			for (Research_Project_Detail__c rpd : [
				SELECT Id, Research_Project_Master__c, Research_Project_Master__r.OwnerId, Research_Project_Master__r.Time_for_Post_interview_discussion__c, Contact__r.Email
				FROM Research_Project_Detail__c
				WHERE Project_Id__c IN :projectId AND Contact__r.Email IN :partId
			]) {
				setUserId.add(rpd.Research_Project_Master__r.OwnerId);
				mapEmailPartId.put(rpd.Contact__r.Email, rpd);
			}
			//get User detail from project Team of related project
			for (Research_Project_Teams__c rpt : [
				SELECT User__c
				FROM Research_Project_Teams__c
				WHERE Research_Project_Master__r.Project_Id__c IN :projectId
			]) {
				setUserId.add(rpt.User__c);
			}

			if (mapEmailPartId != null && mapEmailPartId.size() > 0) {
				//Get All Meeting based on meeting Id
				Map<string, Event> mapEvent = new Map<string, Event>();
				for (Event evt : [SELECT Id, UR_Calendly_Id__c FROM Event WHERE UR_Calendly_Id__c IN :setMeetingId]) {
					mapEvent.put(evt.UR_Calendly_Id__c, evt);
				}

				List<Event> lstEvent = new List<Event>();
				List<Research_Project_Detail__c> projectDetailsToUpdate = new List<Research_Project_Detail__c>();

				for (Research_Integration_Data__c rs : lstRep) {
					Research_Project_Detail__c tempRpd = mapEmailPartId.get(rs.Participant_Id__c);

					Event evt = new Event();
					//UPdate Meeting Event in case of update request
					if (mapEvent != null && mapEvent.size() > 0) {
						Event objEVT = mapEvent.get(rs.Meeting_Id__c);
						evt = new Event(Id = objEVT.Id);
						evt.UR_Modified_Event__c = true;
					}
					evt.Subject = rs.Subject__c;
					if (tempRpd != null) {
						evt.whatId = tempRpd.Id;
					}
					evt.StartDateTime = rs.Event_Start_Date__c;
					evt.EndDateTime = rs.Event_End_Date__c;
					integer mnt = 30;
					//Default buffer time will be 30 mnt.But can be change during project configuration
					if (tempRpd != null && tempRpd.Research_Project_Master__r.Time_for_Post_interview_discussion__c != null) {
						mnt = integer.valueof(tempRpd.Research_Project_Master__r.Time_for_Post_interview_discussion__c.left(2));
					}
					evt.UR_Custom_End_Time__c = rs.Event_End_Date__c.addMinutes(mnt);
					evt.UR_Calendly_Id__c = rs.Meeting_Id__c;
					evt.UR_Meeting_Cancelled__c = rs.Cancelled__c;
					lstEvent.add(evt);

					//Update Project participant Detail
					//Changes as per Ashweej on 11th feb morning call.
					Research_Project_Detail__c objResProjectDetail = new Research_Project_Detail__c(id = evt.whatId);
					objResProjectDetail.Research_Participant_Status__c = 'Scheduled';
					DateTime dT = rs.Event_Start_Date__c;
					objResProjectDetail.Date_of_Attended__c = date.newinstance(dT.year(), dT.month(), dT.day());
					//In case of Cancellation make this field blank
					if (evt.UR_Meeting_Cancelled__c == true) {
						objResProjectDetail.Date_of_Attended__c = null;
						objResProjectDetail.Research_Participant_Status__c = 'Canceled';
					}

					projectDetailsToUpdate.add(objResProjectDetail);
				}
				if (lstEvent != null && lstEvent.size() > 0) {
					upsert lstEvent;

					//Update all Research Project Details records
					if (!projectDetailsToUpdate.isEmpty()) {
						update projectDetailsToUpdate;
					}

					updateResearchIntegrationStatus(lstRep[0].Id, 'Success', 'Success');
					Set<Id> eventIdSet = new Set<Id>();
					for (Event eventObj : lstEvent) {
						eventIdSet.add(eventObj.Id);
					}
					UR_SendInvitationCtrl.sendInviteToProjectTeam(eventIdSet);
					//After process delete from integration table
					//delete [select id from Research_Integration_Data__c where Integration_Type__c='Calendly Data'];
				}
			} else {
				if (lstRep != null && lstRep.size() > 0) {
					updateResearchIntegrationStatus(lstRep[0].Id, 'Failed', ' Response format is not correct or value is missing');
				}
			}
		} catch (Exception ex) {
			if (lstRep != null && lstRep.size() > 0) {
				updateResearchIntegrationStatus(lstRep[0].Id, 'Failed', ' Response format is not correct - ' + ex.getMessage());
			}
		}
	}
	//updateResearchIntegrationStatus(objId, status, msg)
	public static void updateResearchIntegrationStatus(Id objId, String status, String msg) {
		if (objId != null) {
			Research_Integration_Data__c obj = new Research_Integration_Data__c();
			obj.Id = objId;
			obj.Integration_Status__c = status;
			obj.Message__c = msg;
			update obj;
		}
	}
}