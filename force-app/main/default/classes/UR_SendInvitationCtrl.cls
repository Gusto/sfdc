public class UR_SendInvitationCtrl {
	public static void sendInviteToProjectTeam(Set<Id> eventIdSet) {
		try {
			if (eventIdSet.size() > 0) {
				List<Event> eventList = [
					SELECT id, StartDateTime, OwnerId, UR_Calendly_Id__c, UR_Custom_End_Time__c, whatId, Subject, UR_Modified_Event__c, UR_Meeting_Cancelled__c
					FROM Event
					WHERE id IN :eventIdSet
				];

				if (eventList.size() > 0) {
					// Event and Research_Project_Detail__c Map.
					Map<Id, Event> eventObjMap = new Map<Id, Event>();
					Map<Id, Id> parentObjMap = new Map<Id, Id>();
					for (Event eventObj : eventList) {
						if (eventObj.whatId != null) {
							parentObjMap.put(eventObj.Id, eventObj.whatId);
							eventObjMap.put(eventObj.Id, eventObj);
						}
					}

					// Research_Project_Detail__c and Research_Project_Master__c Map.
					Map<Id, Id> projectMasterMap = new Map<Id, Id>();
					Set<Id> projectMasterSet = new Set<Id>();
					for (Research_Project_Detail__c projectDetailObj : [SELECT id, Research_Project_Master__c FROM Research_Project_Detail__c WHERE id IN :parentObjMap.values()]) {
						projectMasterMap.put(projectDetailObj.id, projectDetailObj.Research_Project_Master__c);
						projectMasterSet.add(projectDetailObj.Research_Project_Master__c);
					}

					if (projectMasterMap.size() > 0) {
						//Number_of_Participants_to_Add_to_Project__c
						Map<Id, Research_Project_Master__c> projectMasterObjMap = new Map<Id, Research_Project_Master__c>(
							[
								SELECT
									id,
									Name,
									Additional_Participant_Status__c,
									Calendly_EventId__c,
									Primary_calendly_URL__c,
									Researcher_Name__c,
									Description__c,
									Project_End_Date__c,
									How_long_will_your_interviews_be__c,
									Incentive_Amount__c,
									NDA_URL__c,
									Number_of_Expected_Participant__c,
									Customer_Types__c,
									Plan_to_offer_incentives__c,
									Product_Area__c,
									Project_Brief_URL__c,
									Project_Id__c,
									Project_Leads__c,
									Project_Status__c,
									Survey_Id__c,
									Screener_URL__c,
									Project_Start_Date__c,
									Time_for_Post_interview_discussion__c,
									Total_Participants_In_Research__c,
									Total_Project_Incentive__c,
									Type_of_Research__c,
									UX_Research_Plan_URL__c,
									Type_of_people_are_you_hoping_to_contact__c,
									Zoom_link_for_participant_interviews__c,
									Zoom_link_for_post_interview_discussions__c
								FROM Research_Project_Master__c
								WHERE Id IN :projectMasterSet
							]
						);

						// Research_Project_Master__c and Research_Project_Teams__c Map.
						Map<Id, List<Research_Project_Teams__c>> projectTeamMap = new Map<Id, List<Research_Project_Teams__c>>();
						for (Research_Project_Teams__c projectTeamObj : [
							SELECT
								id,
								Research_Project_Master__c,
								Research_Project_Master__r.Owner.Email,
								Research_Project_Master__r.OwnerId,
								Project_Role__c,
								User__c,
								User__r.Email,
								Invite_for_Interviews__c
							FROM Research_Project_Teams__c
							WHERE Research_Project_Master__c IN :projectMasterMap.values()
						]) {
							if (projectTeamMap.containsKey(projectTeamObj.Research_Project_Master__c)) {
								List<Research_Project_Teams__c> temp = projectTeamMap.get(projectTeamObj.Research_Project_Master__c);
								temp.add(projectTeamObj);
								projectTeamMap.put(projectTeamObj.Research_Project_Master__c, temp);
							} else {
								List<Research_Project_Teams__c> temp = new List<Research_Project_Teams__c>();
								temp.add(projectTeamObj);
								projectTeamMap.put(projectTeamObj.Research_Project_Master__c, temp);
							}
						}

						Set<String> emailTempate = new Set<String>();
						emailTempate.add('Cancelled_Invitation');
						emailTempate.add('Update_Invitation');
						emailTempate.add('UXR_Notification_Invitation_to_Session');
						Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();
						for (EmailTemplate templateObj : [SELECT id, developername, name, Subject, HtmlValue, Body FROM EmailTemplate WHERE developername IN :emailTempate]) {
							templateMap.put(templateObj.developername, templateObj);
						}

						List<Messaging.Email> emailList = new List<Messaging.Email>();
						Messaging.SingleEmailMessage mail = null;
						Id projectDetailId = null;
						Id projectMasterId = null;
						for (Event eventObj : eventObjMap.values()) {
							projectDetailId = parentObjMap.get(eventObj.id);
							projectMasterId = projectMasterMap.get(projectDetailId);
							String attendee = '';
							String ownerEmail = '';
							Id ownerId = eventObj.OwnerId;
							Boolean isMemberExist = false;
							for (Research_Project_Teams__c rsProject : projectTeamMap.get(projectMasterId)) {
								if (rsProject.User__C != null) {
									isMemberExist = true;
									if (rsProject.Invite_for_Interviews__c) {
										attendee = attendee + '; ' + rsProject.User__r.Email;
									}
									ownerEmail = rsProject.Research_Project_Master__r.Owner.Email;
									ownerId = rsProject.Research_Project_Master__r.OwnerId;
								}
							}
							if (isMemberExist && String.isNotBlank(attendee)) {
								attendee = attendee.subString(1, attendee.length());
							}

							mail = new Messaging.SingleEmailMessage();
							List<String> toAddresses = attendee.split(';');
							Set<String> toAddressesSet = new Set<String>(toAddresses);
							toAddresses.clear();
							toAddresses.addAll(toAddressesSet);

							mail.setToAddresses(toAddresses);

							String mailSubject = '';
							String mailHTMLBody = '';

							if (eventObj.UR_Meeting_Cancelled__c) {
								mailSubject = templateMap.get('Cancelled_Invitation').subject;
								mailHTMLBody = templateMap.get('Cancelled_Invitation').HtmlValue;
							} else if (eventObj.UR_Modified_Event__c) {
								mailSubject = templateMap.get('Update_Invitation').subject;
								mailHTMLBody = templateMap.get('Update_Invitation').HtmlValue;
							} else {
								mailSubject = templateMap.get('UXR_Notification_Invitation_to_Session').subject;
								mailHTMLBody = templateMap.get('UXR_Notification_Invitation_to_Session').HtmlValue;
							}

							if (projectMasterObjMap.containsKey(projectMasterId)) {
								mailSubject = mapMergeFieldValue(mailSubject, projectMasterObjMap.get(projectMasterId));
								mailHTMLBody = mapMergeFieldValue(mailHTMLBody, projectMasterObjMap.get(projectMasterId));
								mailHTMLBody = mailHTMLBody.replace('[Attendee List]', '[' + attendee + ']');
							}

							String eventTimeStr = '<b>Start Date:</b> ' + eventObj.StartDateTime.format() + '<br/><br/>';
							eventTimeStr = eventTimeStr + '<b>End Date:</b> ' + eventObj.UR_Custom_End_Time__c.format() + '<br/><br/>';
							mailHTMLBody = eventTimeStr + mailHTMLBody;

							mail.setSubject(mailSubject);
							mail.setHTMLBody(mailHTMLBody);
							if (string.isNotBlank(UR_UtilityCtrl.strReplyEmail)) {
								mail.setReplyTo(UR_UtilityCtrl.strReplyEmail);
							}
							mail.setSaveAsActivity(false);
							if (UR_UtilityCtrl.orgWideEmail_NoReply != null) {
								mail.setOrgWideEmailAddressId(UR_UtilityCtrl.orgWideEmail_NoReply);
							}
							mail.setTargetObjectId(ownerId);

							Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
							attach.filename = 'meeting.ics';
							attach.ContentType = 'text/calendar; charset=utf-8; method=REQUEST';
							attach.inline = true;
							attach.body = getEmailBody(eventObj, attendee, ownerEmail);
							mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attach });
							emailList.add(mail);
						}

						UR_UtilityCtrl.skipTriggerLogic();
						Messaging.SendEmailResult[] er = Messaging.sendEmail(emailList);
					}
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_SendInvitationCtrl', 'sendInviteToProjectTeam', ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static Blob getEmailBody(Event eventObj, String attendee, String ownerEmail) {
		String txtInvite = '';
		txtInvite += 'BEGIN:VCALENDAR\n';
		txtInvite += 'PRODID:-//Microsoft Corporation//Outlook 12.0 MIMEDIR//EN\n';
		txtInvite += 'VERSION:2.0\n';
		txtInvite += 'METHOD:REQUEST\n';
		txtInvite += 'BEGIN:VEVENT\n';
		txtInvite += 'DESCRIPTION:' + eventObj.subject + '\n';
		txtInvite += 'DTSTAMP;TZID=GMT:' + DateTime.now().formatGMT('yyyyMMdd\'T\'HHmmssZ') + '\n';
		txtInvite += 'DTSTART;TZID=GMT:' + eventObj.StartDateTime.formatGMT('yyyyMMdd\'T\'HHmmssZ') + '\n';
		txtInvite += 'DTEND;TZID=GMT:' + eventObj.UR_Custom_End_Time__c.formatGMT('yyyyMMdd\'T\'HHmmssZ') + '\n';
		txtInvite += 'PRIORITY:5\n';
		txtInvite += 'SEQUENCE:0\n';
		txtInvite += 'UID:' + eventObj.Id + '\n';
		txtInvite += 'LOCATION:\n';
		txtInvite += 'SUMMARY:' + eventObj.Subject + '\n';
		for (String attendeeName : attendee.split(';')) {
			txtInvite += 'ATTENDEE:' + attendeeName + '\n';
		}
		txtInvite += 'ORGANIZER:mailto:' + ownerEmail + '\n';
		txtInvite += 'RSVP:YES\n';
		txtInvite += 'END:VEVENT\n';
		txtInvite += 'END:VCALENDAR\n';

		return Blob.valueOf(txtInvite);
	}

	public static string mapMergeFieldValue(String mailHTMLBody, Research_Project_Master__c obj) {
		if (String.isNotBlank(mailHTMLBody)) {
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Id}', obj.id + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Name}', obj.Name + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Additional_Participant_Status__c}', obj.Additional_Participant_Status__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Calendly_EventId__c}', obj.Calendly_EventId__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Primary_calendly_URL__c}', obj.Primary_calendly_URL__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Researcher_Name__c}', obj.Researcher_Name__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Description__c}', obj.Description__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Project_End_Date__c}', obj.Project_End_Date__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.How_long_will_your_interviews_be__c}', obj.How_long_will_your_interviews_be__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Incentive_Amount__c}', obj.Incentive_Amount__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.NDA_URL__c}', obj.NDA_URL__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Number_of_Expected_Participant__c}', obj.Number_of_Expected_Participant__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Customer_Types__c}', obj.Customer_Types__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Plan_to_offer_incentives__c}', obj.Plan_to_offer_incentives__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Product_Area__c}', obj.Product_Area__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Project_Brief_URL__c}', obj.Project_Brief_URL__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Project_Id__c}', obj.Project_Id__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Project_Leads__c}', obj.Project_Leads__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Project_Status__c}', obj.Project_Status__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Survey_Id__c}', obj.Survey_Id__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Screener_URL__c}', obj.Screener_URL__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Project_Start_Date__c}', obj.Project_Start_Date__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Time_for_Post_interview_discussion__c}', obj.Time_for_Post_interview_discussion__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Time_for_Post_interview_discussion__c}', obj.Time_for_Post_interview_discussion__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Total_Participants_In_Research__c}', obj.Total_Participants_In_Research__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Total_Project_Incentive__c}', obj.Total_Project_Incentive__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Type_of_Research__c}', obj.Type_of_Research__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.UX_Research_Plan_URL__c}', obj.UX_Research_Plan_URL__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Type_of_people_are_you_hoping_to_contact__c}', obj.Type_of_people_are_you_hoping_to_contact__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Zoom_link_for_participant_interviews__c}', obj.Zoom_link_for_participant_interviews__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Zoom_link_for_post_interview_discussions__c}', obj.Zoom_link_for_post_interview_discussions__c + '');
			mailHTMLBody = mailHTMLBody.replace('{!Research_Project_Master__c.Link}', URL.getSalesforceBaseUrl().toExternalForm() + '/' + obj.Id);
		}
		return mailHTMLBody;
	}
}