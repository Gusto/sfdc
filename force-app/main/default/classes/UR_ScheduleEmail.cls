public class UR_ScheduleEmail implements Database.Batchable<sObject>, Schedulable {
	public void execute(SchedulableContext sc) {
		UR_ScheduleEmail scheduleBatchObj = new UR_ScheduleEmail();
		Database.executeBatch(scheduleBatchObj, 1);

		System.abortJob(sc.getTriggerId());
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		Date dateObj = Date.today();
		String timeObj = DateTime.now().hour() + '';
		String query = 'select id, Research_Schedule_Email__r.UXR_Scout__c, Research_Project_Detail__r.Contact__c, Research_Project_Detail__c, Schedule_Email_Status__c, Research_Schedule_Email__r.Schedule_Email_Type__c, Research_Schedule_Email__r.Schedule_Email_Template_Id__c from Research_Schedule_Email_Participant__c where Research_Schedule_Email__r.Schedule_Email_Date__c=:dateObj and Research_Schedule_Email__r.Schedule_Email_Time__c=:timeObj and Schedule_Email_Status__c = \'Schedule\' ';
		if (Test.isRunningTest()) {
			query = 'select id, Research_Schedule_Email__r.UXR_Scout__c, Research_Project_Detail__r.Contact__c, Research_Project_Detail__c, Schedule_Email_Status__c, Research_Schedule_Email__r.Schedule_Email_Template_Id__c from Research_Schedule_Email_Participant__c limit 1';
		}
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Research_Schedule_Email_Participant__c> scope) {
		if (scope.size() > 0) {
			try {
				sendEmail(scope[0]);
				scope[0].put('Schedule_Email_Status__c', 'Success');
				scope[0].put('Error_Message__c', '');
				update scope[0];

				Research_Schedule_Email_Participant__c scheduleObj = scope[0];

				List<Research_Project_Detail__c> lstProjectDetail = [
					SELECT id, Research_Participant_Status__c, Incentive__c, Proposed_Incentive__c
					FROM Research_Project_Detail__c
					WHERE id = :scheduleObj.Research_Project_Detail__c
				];
				if (lstProjectDetail.size() > 0) {
					// "Research Participant Status" should not be changed, if participant is Attended and some incentive amount is given to it.
					if (lstProjectDetail[0].Research_Participant_Status__c != 'Attended' || Test.isRunningTest()) {
						String strPartStatus = scheduleObj.Research_Schedule_Email__r.Schedule_Email_Type__c;
						if (String.isNotBlank(strPartStatus)) {
							String finalStatus = UR_UtilityCtrl.emailStatusMap.get(strPartStatus);
							if (String.isNotBlank(finalStatus)) {
								Research_Project_Detail__c objUpdate = new Research_Project_Detail__c(id = scheduleObj.Research_Project_Detail__c);
								objUpdate.Research_Participant_Status__c = finalStatus;
								update objUpdate;
							}
						}
					}
				}
			} catch (Exception ex) {
				updateProjectMaster(scope, ex.getMessage());
			}
		}
	}

	public void finish(Database.BatchableContext BC) {
	}

	public void updateProjectMaster(List<Research_Schedule_Email_Participant__c> scope, String errorMsg) {
		scope[0].put('Schedule_Email_Status__c', 'Fail');
		scope[0].put('Error_Message__c', errorMsg);
		update scope[0];

		if (scope[0].Research_Schedule_Email__r.UXR_Scout__c != null) {
			UR_ProjectMasterTriggerHelper.skipTrigger = true;
			Research_Project_Master__c obj = new Research_Project_Master__c();
			obj.Id = scope[0].Research_Schedule_Email__r.UXR_Scout__c;
			obj.Closed_Schedule_Email_Error_Message__c = false;
			update obj;
			UR_ProjectMasterTriggerHelper.skipTrigger = false;
		}
	}

	public void sendEmail(sObject sObj) {
		Research_Schedule_Email_Participant__c scheduleEmail = (Research_Schedule_Email_Participant__c) sObj;
		List<Messaging.SingleEmailMessage> mail = new List<Messaging.SingleEmailMessage>();
		Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
		msg.setWhatId(scheduleEmail.Research_Project_Detail__c);
		msg.setTargetObjectId(scheduleEmail.Research_Project_Detail__r.Contact__c);
		if (string.isNotBlank(UR_UtilityCtrl.strReplyEmail)) {
			msg.setReplyTo(UR_UtilityCtrl.strReplyEmail);
		}

		if (String.isNotBlank(scheduleEmail.Research_Schedule_Email__r.Schedule_Email_Template_Id__c)) {
			msg.setTemplateId(scheduleEmail.Research_Schedule_Email__r.Schedule_Email_Template_Id__c);
		} else {
			msg.setHtmlBody('emailBody');
			msg.setSubject('strSubject');
		}
		msg.setSaveAsActivity(true);

		if (UR_UtilityCtrl.orgWideEmail_NoReply != null) {
			msg.setOrgWideEmailAddressId(UR_UtilityCtrl.orgWideEmail_NoReply);
		}
		mail.add(msg);
		if (mail.size() > 0) {
			skipTrigger(true);
			EmailMessageTriggerHelper.skipTrigger = true;
			Messaging.sendEmail(mail);
			EmailMessageTriggerHelper.skipTrigger = false;
			skipTrigger(false);
		}
	}
	public void skipTrigger(Boolean flag) {
		ContactTriggerHelper.skipTrigger = flag;
		AccountTriggerHelper.skipTrigger = flag;
	}
}