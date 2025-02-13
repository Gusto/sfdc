/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<UR_ViewScheduleEmailCtrl>>
 * Description...........: <<This class View all the schedule email related to UX project>>
 *-------------------------------------------------------------------------------*/
public with sharing class UR_ViewScheduleEmailCtrl {
	public String currentRecordId { get; set; }
	public Research_Project_Master__c objProject { get; set; }
	public boolean isEditable { get; set; }
	public List<ViewScheduleEmail> scheduleJobList { get; set; }
	public String scheduleJobId { get; set; }
	public String participantJobId { get; set; }
	public String scheduleContactId { get; set; }
	public Map<Id, EmailTemplate> scheduleTemplateMap = new Map<Id, EmailTemplate>();
	public String viewEmailSubject { get; set; }
	public String viewEmailBody { get; set; }
	public String viewTemplateId { get; set; }
	public String deletedJobId { get; set; }
	public String deletedParticipantId { get; set; }
	public Research_Schedule_Email__c scheduleEmail { get; set; }
	public String reScheduleJobId { get; set; }

	public UR_ViewScheduleEmailCtrl(ApexPages.StandardController controller) {
		scheduleEmail = new Research_Schedule_Email__c();
		currentRecordId = ApexPages.CurrentPage().getparameters().get('projectId');
		deletedJobId = ApexPages.CurrentPage().getparameters().get('deletedJobId');
		deletedParticipantId = ApexPages.CurrentPage().getparameters().get('deletedParticipantId');
		String removeFlag = ApexPages.CurrentPage().getparameters().get('remove');
		if (String.isNotBlank(removeFlag)) {
			if (removeFlag == 'participant') {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, '1 participant removed from scheduled email.'));
			} else if (removeFlag == 'job') {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Schedule email successfully cancelled.'));
			}
		}
		String emailStatus = ApexPages.CurrentPage().getparameters().get('emailstatus');
		if (String.isNotBlank(emailStatus)) {
			if (emailStatus == 'Success') {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Email successfully send.'));
			} else if (emailStatus == 'Fail') {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Email failed.'));
			}
		}
		isEditable = UR_UtilityCtrl.IsEditAccess(currentRecordId);
		objProject = new Research_Project_Master__c(id = currentRecordId);
		fetchScheduleJob();
	}
	public void fetchScheduleJob() {
		String strStatus = 'Schedule';
		Date dateObj = Date.today();
		String timeObj = DateTime.now().hour() + '';
		Set<String> timeObjSet = new Set<String>();
		for (Integer iCount = Integer.valueOf(timeObj); iCount <= 23; iCount++) {
			timeObjSet.add(iCount + '');
		}
		Id projectId = objProject.Id;
		scheduleJobList = new List<ViewScheduleEmail>();
		scheduleTemplateMap = new Map<Id, EmailTemplate>();
		Integer intTimeObj = DateTime.now().hour();
		for (Research_Schedule_Email__c scheduleObj : [
			SELECT
				Id,
				(
					SELECT id, Company_Name__c, Contact_Email__c, Contact_Name__c, Company_Id__c, Contact_Id__c, Schedule_Email_Status__c, Error_Message__c
					FROM Research_Schedule_Email_Participants__r
					WHERE Id != :deletedParticipantId
				),
				Schedule_Email_Template_Id__c,
				Schedule_Email_Date__c,
				Schedule_Email_Time__c,
				Schedule_Email_Type__c,
				createddate,
				Total_Scheduled_Email__c,
				Total_Participant__c,
				createdby.Name,
				Total_Fail_Email__c
			FROM Research_Schedule_Email__c
			WHERE
				UXR_Scout__c = :projectId
				AND Id != :deletedJobId
				AND (((Total_Scheduled_Email__c > 0
				OR Total_Participant__c = 0)
				AND Schedule_Email_Date__c >= :dateObj
				AND (Schedule_Email_Date__c > :dateObj
				OR Schedule_Email_Time__c IN :timeObjSet))
				OR Total_Fail_Email__c > 0
				OR (Total_Scheduled_Email__c > 0
				AND Schedule_Email_Date__c <= :dateObj))
		]) {
			ViewScheduleEmail viewEmailObj = new ViewScheduleEmail();

			//[BS: 11 Sep 2020] issue description: Aggregate query has too many rows for direct assignment, use FOR loop.
			//Comment below mentioned line of code. Because size() method throw error for large set of "inner query result".
			//viewEmailObj.totoalContact = scheduleObj.Research_Schedule_Email_Participants__r.size();
			viewEmailObj.scheduleJob = scheduleObj;
			viewEmailObj.failEmail = Integer.valueOf(scheduleObj.Total_Fail_Email__c);
			viewEmailObj.emailTemplateId = scheduleObj.Schedule_Email_Template_Id__c;
			for (Research_Schedule_Email_Participant__c scObj : scheduleObj.Research_Schedule_Email_Participants__r) {
				viewEmailObj.participantList.add(scObj);
			}

			//[BS: 11 Sep 2020] Bug fix : add 4 line of code.
			if (viewEmailObj.participantList != null) {
				viewEmailObj.totoalContact = viewEmailObj.participantList.size();
			} else {
				viewEmailObj.totoalContact = 0;
			}

			//[BS: 7 Oct 2020] Check is complete scheduled email job will falied.
			if (scheduleObj.Schedule_Email_Date__c < dateObj && scheduleObj.Total_Scheduled_Email__c > 0 && scheduleObj.Total_Scheduled_Email__c == scheduleObj.Total_Participant__c) {
				viewEmailObj.blnJobFail = true;
			} else if (
				scheduleObj.Schedule_Email_Date__c == dateObj &&
				String.isNotBlank(scheduleObj.Schedule_Email_Time__c) &&
				Integer.valueOf(scheduleObj.Schedule_Email_Time__c) < intTimeObj &&
				scheduleObj.Total_Scheduled_Email__c > 0 &&
				scheduleObj.Total_Scheduled_Email__c == scheduleObj.Total_Participant__c
			) {
				viewEmailObj.blnJobFail = true;
			}
			scheduleJobList.add(viewEmailObj);
			scheduleTemplateMap.put(scheduleObj.Schedule_Email_Template_Id__c, null);
		}

		if (scheduleTemplateMap.size() > 0) {
			Set<Id> teplateIdSet = scheduleTemplateMap.keySet();
			for (EmailTemplate templateObj : [SELECT id, Name, HtmlValue, Subject FROM EmailTemplate WHERE Id IN :teplateIdSet]) {
				scheduleTemplateMap.put(templateObj.Id, templateObj);
			}
		}

		for (ViewScheduleEmail viewEmailObj : scheduleJobList) {
			if (scheduleTemplateMap.containsKey(viewEmailObj.emailTemplateId) && scheduleTemplateMap.get(viewEmailObj.emailTemplateId) != null) {
				EmailTemplate templateObj = scheduleTemplateMap.get(viewEmailObj.emailTemplateId);
				viewEmailObj.emailHtmlBody = templateObj.HtmlValue;
				viewEmailObj.emailSubject = templateObj.Subject;
			}
		}
	}

	public class ViewScheduleEmail {
		public Integer totoalContact { get; set; }
		public Integer failEmail { get; set; }
		public Research_Schedule_Email__c scheduleJob { get; set; }
		public String emailTemplateId { get; set; }
		public String emailSubject { get; set; }
		public String emailHtmlBody { get; set; }
		public Boolean blnJobFail { get; set; }

		public List<Research_Schedule_Email_Participant__c> participantList { get; set; }
		public ViewScheduleEmail() {
			participantList = new List<Research_Schedule_Email_Participant__c>();
			blnJobFail = false;
		}
	}

	public PageReference cancelSchedulejob() {
		PageReference pageRef = null;
		try {
			if (String.isNotBlank(scheduleJobId)) {
				List<Research_Schedule_Email__c> scheduleEmailList = [SELECT id, Schedule_Email_Date__c, Schedule_Email_Time__c FROM Research_Schedule_Email__c WHERE Id = :scheduleJobId];
				if (scheduleEmailList.size() > 0) {
					Integer intHour = Integer.valueOf(scheduleEmailList[0].Schedule_Email_Time__c);
					Time myTime = Time.newInstance(intHour, 0, 0, 0);
					DateTime scheduledDateTime = DateTime.newInstance(scheduleEmailList[0].Schedule_Email_Date__c, myTime);
					String jobName = 'UXR_Schedule_Email_' + scheduledDateTime;

					List<Research_Schedule_Email__c> otherScheduleEmailList = [
						SELECT Id
						FROM Research_Schedule_Email__c
						WHERE Id != :scheduleJobId AND Schedule_Email_Date__c = :scheduleEmailList[0].Schedule_Email_Date__c AND Schedule_Email_Time__c = :scheduleEmailList[0].Schedule_Email_Time__c
					];

					List<CronTrigger> scheduleJobList = [SELECT id, CronJobDetail.name FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
					if (scheduleEmailList.size() > 0 && !Test.isRunningTest()) {
						delete scheduleEmailList;
						pageRef = new PageReference('/apex/UR_ViewScheduleEmail?projectId=' + objProject.Id + '&deletedParticipantId=' + '&deletedJobId=' + scheduleJobId + '&remove=job');
						pageRef.setRedirect(true);
					}
					if (scheduleJobList.size() > 0 && otherScheduleEmailList.size() == 0) {
						System.abortJob(scheduleJobList[0].id);
					}
				}
			}
			Integer recordCount = scheduleEmailCount(scheduleJobId);
			if (recordCount == null || recordCount == 0) {
				pageRef = new PageReference('/apex/UR_ViewEmail?projectId=' + objProject.Id);
				pageRef.setRedirect(true);
			}
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
			pageRef = null;
		}
		return pageRef;
	}

	public PageReference removeParticipant() {
		PageReference pageRef = null;
		try {
			if (String.isNotBlank(participantJobId)) {
				List<Research_Schedule_Email_Participant__c> list_SEParticipant = [
					SELECT id
					FROM Research_Schedule_Email_Participant__c
					WHERE Id = :participantJobId
				];
				if (list_SEParticipant.size() > 0) {
					delete list_SEParticipant;
				}
				pageRef = new PageReference('/apex/UR_ViewScheduleEmail?projectId=' + objProject.Id + '&deletedParticipantId=' + participantJobId + '&deletedJobId=' + '&remove=participant');
				pageRef.setRedirect(true);
			}
			Integer recordCount = scheduleEmailCount(null);
			if (recordCount == null || recordCount == 0) {
				pageRef = new PageReference('/apex/UR_ViewEmail?projectId=' + objProject.Id);
				pageRef.setRedirect(true);
			}
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
			pageRef = null;
		}
		return pageRef;
	}

	public void showEmailBody() {
		if (String.isNotBlank(viewTemplateId)) {
			EmailTemplate templateObj = scheduleTemplateMap.get(viewTemplateId);
			viewEmailBody = templateObj.HtmlValue;
			if (String.isNotBlank(viewEmailBody)) {
				viewEmailBody = viewEmailBody.replace('\n\r', '<br/>');
				viewEmailBody = viewEmailBody.replace(UR_ManageParticipantCtrl.UL_TAG, UR_ManageParticipantCtrl.UL_SLDS_TAG);
				viewEmailBody = viewEmailBody.replace(UR_ManageParticipantCtrl.OL_TAG, UR_ManageParticipantCtrl.OL_SLDS_TAG);
			}
			viewEmailSubject = templateObj.Subject;
		}
	}

	public Integer scheduleEmailCount(Id scheduleJobId) {
		Date dateObj = Date.today();
		String timeObj = DateTime.now().hour() + '';
		Set<String> timeObjSet = new Set<String>();
		for (Integer iCount = Integer.valueOf(timeObj); iCount <= 23; iCount++) {
			timeObjSet.add(iCount + '');
		}
		Id projectId = objProject.Id;
		Integer recordCount = [
			SELECT COUNT()
			FROM Research_Schedule_Email__c
			WHERE
				UXR_Scout__c = :projectId
				AND Id != :scheduleJobId
				AND (((Total_Scheduled_Email__c > 0
				OR Total_Participant__c = 0)
				AND Schedule_Email_Date__c >= :dateObj
				AND (Schedule_Email_Date__c > :dateObj
				OR Schedule_Email_Time__c IN :timeObjSet))
				OR Total_Fail_Email__c > 0)
		];

		return recordCount;
	}

	public PageReference resendEmail() {
		PageReference pageRef = null;
		string strPartId = ApexPages.CurrentPage().getparameters().get('strPartId');
		String emailStatus = '';
		if (String.isNotBlank(strPartId)) {
			List<Research_Schedule_Email_Participant__c> lstResearchProjectDetail = [
				SELECT
					id,
					Research_Schedule_Email__r.UXR_Scout__c,
					Research_Project_Detail__r.Contact__c,
					Research_Project_Detail__c,
					Schedule_Email_Status__c,
					Research_Schedule_Email__r.Schedule_Email_Type__c,
					Research_Schedule_Email__r.Schedule_Email_Template_Id__c,
					Research_Project_Detail__r.Research_Participant_Status__c
				FROM Research_Schedule_Email_Participant__c
				WHERE Id = :strPartId
			];
			if (lstResearchProjectDetail.size() > 0) {
				try {
					UR_ScheduleEmail scheduleObj = new UR_ScheduleEmail();
					scheduleObj.sendEmail(lstResearchProjectDetail[0]);

					//When email successfully send.
					lstResearchProjectDetail[0].Schedule_Email_Status__c = 'Success';
					lstResearchProjectDetail[0].Error_Message__c = '';
					update lstResearchProjectDetail[0];

					emailStatus = 'Success';
					if (lstResearchProjectDetail[0].Research_Project_Detail__r.Research_Participant_Status__c != 'Attended') {
						String strPartStatus = lstResearchProjectDetail[0].Research_Schedule_Email__r.Schedule_Email_Type__c;
						if (String.isNotBlank(strPartStatus)) {
							String finalStatus = UR_UtilityCtrl.emailStatusMap.get(strPartStatus);
							if (String.isNotBlank(finalStatus)) {
								Research_Project_Detail__c objUpdate = new Research_Project_Detail__c(id = lstResearchProjectDetail[0].Research_Project_Detail__c);
								objUpdate.Research_Participant_Status__c = finalStatus;
								update objUpdate;
							}
						}
					}
				} catch (Exception ex) {
					lstResearchProjectDetail[0].Schedule_Email_Status__c = 'Fail';
					lstResearchProjectDetail[0].Error_Message__c = ex.getMessage();
					update lstResearchProjectDetail[0];
					emailStatus = 'Fail';
				}
			}
			pageRef = new PageReference('/apex/UR_ViewScheduleEmail?projectId=' + objProject.Id + '&emailstatus=' + emailStatus);
			pageRef.setRedirect(true);
		}
		return pageRef;
	}

	public PageReference reScheduleEmail() {
		PageReference pageRef = null;
		Boolean isValidScheduleDateTime = checkValidScheduleeDateTime();
		if (isValidScheduleDateTime == true && String.isNotBlank(reScheduleJobId)) {
			Research_Schedule_Email__c reScheduleEmailObj = new Research_Schedule_Email__c();
			List<Research_Schedule_Email__c> list_ScheduleEmail = [SELECT Id, Schedule_Email_Date__c, Schedule_Email_Time__c FROM Research_Schedule_Email__c WHERE Id = :reScheduleJobId];
			if (list_ScheduleEmail.size() > 0) {
				reScheduleEmailObj = list_ScheduleEmail[0];

				//Abort previous schedule job.
				Integer intHour = Integer.valueOf(reScheduleEmailObj.Schedule_Email_Time__c);
				Time myTime = Time.newInstance(intHour, 0, 0, 0);
				DateTime previousScheduledDateTime = DateTime.newInstance(reScheduleEmailObj.Schedule_Email_Date__c, myTime);
				DateTime currentDateTime = System.now();
				if (currentDateTime > previousScheduledDateTime) {
					String jobName = 'UXR_Schedule_Email_' + previousScheduledDateTime;
					List<CronTrigger> scheduleJobList = [
						SELECT id, CronJobDetail.name
						FROM CronTrigger
						WHERE CronJobDetail.Name = :jobName
					];
					if (scheduleJobList.size() > 0) {
						System.abortJob(scheduleJobList[0].Id);
					}
				}

				//Rest schedule email job.
				reScheduleEmailObj.Id = reScheduleJobId;
				reScheduleEmailObj.Schedule_Email_Date__c = scheduleEmail.Schedule_Email_Date__c;
				reScheduleEmailObj.Schedule_Email_Time__c = scheduleEmail.Schedule_Email_Time__c;
				update reScheduleEmailObj;

				pageRef = new PageReference('/apex/UR_ViewScheduleEmail?projectId=' + objProject.Id);
				pageRef.setRedirect(true);
			}
		}
		return pageRef;
	}

	public Boolean checkValidScheduleeDateTime() {
		Boolean isValidScheduleDateTime = true;
		if (scheduleEmail.Schedule_Email_Date__c == null || scheduleEmail.Schedule_Email_Time__c == null) {
			isValidScheduleDateTime = false;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please enter a valid schedule email date and time.'));
		} else {
			isValidScheduleDateTime = true;
		}

		if (isValidScheduleDateTime == true && scheduleEmail.Schedule_Email_Date__c != null && scheduleEmail.Schedule_Email_Time__c != null) {
			DateTime currentDateTime = System.now();
			Integer intHour = Integer.valueOf(scheduleEmail.Schedule_Email_Time__c);
			Time myTime = Time.newInstance(intHour, 0, 0, 0);
			DateTime scheduledDateTime = DateTime.newInstance(scheduleEmail.Schedule_Email_Date__c, myTime);
			if (currentDateTime < scheduledDateTime) {
				isValidScheduleDateTime = true;
			} else {
				isValidScheduleDateTime = false;
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select future date and time to schedule an email.'));
			}
		}
		return isValidScheduleDateTime;
	}
}