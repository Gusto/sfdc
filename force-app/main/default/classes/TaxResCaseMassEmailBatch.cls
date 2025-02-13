/**
 * @name         TaxResCaseMassEmailBatch
 * @author       Bhagat Singh
 * @date         24 Aug 2020
 * @description  This batch update the case records and also send email to the related contact.
 * @test class   TaxResCaseMassEmailCtrlTest
 **/
public class TaxResCaseMassEmailBatch implements Database.Batchable<Sobject>, Database.Stateful {
	public Map<String, String> map_FieldToUpdate = new Map<String, String>();
	public Set<Id> set_CasesToUpdate = new Set<Id>();
	public Id idSelectedEmailTemplate = null;
	public Id idBatchRunByUser = null;
	public Id idOWDEmail = null;
	public String strBatchRunByUserName = '';
	public boolean blnIsSuccess = true;
	//Method to get the data to be proceesed
	public database.Querylocator Start(Database.BatchableContext bc) {
		//Before start of batch clear the message from user record.
		//set "Running Mass Email Batch?" and "Mass Email Status Message" flag on custom setting(Batch_Email_Settings__c).
		if (idBatchRunByUser != null) {
			TaxResCaseMassEmailCtrl.saveMassEmailStatus(idBatchRunByUser, true, '');
		}
		blnIsSuccess = true;

		//Fetch Org wide email address id.
		List<OrgWideEmailAddress> list_SupportEmailAddress = GlobalQueryHelper.getOrgWideEmailByAdd('support@gusto.com');
		if (list_SupportEmailAddress != null && list_SupportEmailAddress.size() > 0) {
			idOWDEmail = list_SupportEmailAddress[0].Id;
		}

		String query =
			'SELECT Id, Case_Reference__c, ContactId, Subject, CaseNumber, Contact.FirstName, LSI_Mass_Emails_Sent__c,' +
			' Next_Steps__c,Mass_Email_Step__c,Type,Status,Routing_Case_Reason__c, Confirm_Case_Reason__c,Area_Impacted__c, ' +
			' Customer_Journey__c,Root_Cause__c,Sub_Root_Cause__c FROM Case ';

		if (set_CasesToUpdate != null && set_CasesToUpdate.size() > 0 && idSelectedEmailTemplate != null && map_FieldToUpdate != null && map_FieldToUpdate.size() > 0 && idBatchRunByUser != null) {
			query = query + ' WHERE ContactId!=null AND Id IN :set_CasesToUpdate ';
		} else {
			//Do not process any case record.
			query = query + ' LIMIT 0 ';
		}
		return Database.getQueryLocator(query);
	}

	//Method to execute the batch
	public void execute(Database.BatchableContext bc, Sobject[] scope) {
		TaxResCaseMassEmailBatch.skipTrigger(true);
		String strProcessCaseIds = '\nProcess Case Ids : ';
		try {
			List<Case> list_Case = new List<Case>();
			List<Messaging.SingleEmailMessage> list_EmailMessage = new List<Messaging.SingleEmailMessage>();
			if (scope != null && scope.size() > 0) {
				for (Sobject sObj : scope) {
					Case objCase = (Case) sObj;
					strProcessCaseIds = strProcessCaseIds + objCase.id + ', ';

					//Send email to case related contact.
					Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
					mail.setTemplateId(idSelectedEmailTemplate);
					mail.setTargetObjectId(objCase.ContactId);
					mail.setWhatId(objCase.Id);
					mail.setSaveAsActivity(true);
					if (idOWDEmail != null) {
						mail.setOrgWideEmailAddressId(idOWDEmail);
					}
					list_EmailMessage.add(mail);

					//set case fields as per the map
					for (String fieldName : map_FieldToUpdate.keySet()) {
						objCase.put(fieldName, map_FieldToUpdate.get(fieldName));
					}
					objCase.LSI_Mass_Emails_Sent__c = (objCase.LSI_Mass_Emails_Sent__c == null) ? 1 : (objCase.LSI_Mass_Emails_Sent__c + 1);
					list_Case.add(objCase);
				}

				if (list_EmailMessage.size() > 0) {
					Messaging.SendEmailResult[] results = Messaging.sendEmail(list_EmailMessage);

					if (results[0].success && list_Case.size() > 0) {
						update list_Case;
					}
				}
			}
		} catch (Exception objExcep) {
			ExceptionLogUtil.logException('TaxResCaseMassEmailBatch', 'sendEmail', objExcep.getMessage(), objExcep.getStackTraceString() + '    ' + strProcessCaseIds);
			UtilitiesFactory.sendExceptionEmail(objExcep, 'Send Mass Email Failure', 'Login user Name : ' + strBatchRunByUserName + '\nLogin user id : ' + idBatchRunByUser + strProcessCaseIds);
			blnIsSuccess = false;
		}
		TaxResCaseMassEmailBatch.skipTrigger(false);
	}

	//Method to be called after the excute
	public void finish(Database.BatchableContext bc) {
		//set "Running Mass Email Batch?" and "Mass Email Status Message" flag on custom setting(Batch_Email_Settings__c).
		if (idBatchRunByUser != null) {
			if (blnIsSuccess) {
				TaxResCaseMassEmailCtrl.saveMassEmailStatus(idBatchRunByUser, false, 'Emails sent successfully.');
			} else {
				TaxResCaseMassEmailCtrl.saveMassEmailStatus(idBatchRunByUser, false, 'There was an error encountered while sending emails. Please reach out to your administrator.');
			}
		}
	}

	//Skip trigger.
	public static void skipTrigger(Boolean blnFlag) {
		ContactTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		AccountRelatedTrackingTriggerHelper.skipTrigger = blnFlag;
		TaskTriggerHelper.skipTrigger = blnFlag;
		EmailMessageTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
	}
}