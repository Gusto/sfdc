/*
 * Description: Contains methods to send and save the QLE RFI Case
 * Author: Omar Benitez
 * Date: 10/31/2024
 */
public without sharing class CaseQLERFIController {
    /*
     * @description Method to send the first RFI
     * @param objCaseForUpdate Case object to update
     */
	@AuraEnabled
	public static void sendFirstRFI(Case objCaseForUpdate) {
		try {
			Case objCase = [
				SELECT
					Id,
					ContactEmail,
					RFI_Type__c,
					RecordType.Name,
					RecordTypeId,
					Termination_Date__c,
					MF_Coverage_End_Date__c,
					Generation_Reason__c,
					Audit_Action__c,
					Doc_Request_Status__c,
					Type,
					RFI_Status__c,
					Anticipated_Effective_Date__c,
					Contact.ZP_User_Id__c,
					Submission_Method__c,
					Special_Instructions__c,
					Follow_Up_Date__c,
					SuppliedEmail,
					carrier__r.Submission_Email__c,
					Contact.Email,
					Status,
					Status_Detail__c,
					Requires_Action__c,
					Google_Drive_URL__c,
					Carrier__c,
					Description,
					Follow_Up_Method__c,
					Benefit_Order__c,
					Opportunity__c,
					LastModifiedDate,
					Open_Enrollment_Start__c,
					Open_Enrollment_End__c,
					Benefit_Order_Submission_Deadline__c,
					Related_to_Incident__c,
					Covid_19_Note_s__c,
					Benefit_Order__r.Name,
					Form_Fully_Mapped__c,
					Form_Fits_Dependents__c,
					Missing_Form_Attributes__c,
					Subscription_End_Date__c,
					Notes__c,
					Event_timestamp__c,
					Company_Name__c,
					ContactId,
					Integration_Id__c,
					Enrollment_Message__c,
					QLE_RFI_Type__c,
					Contact.Name,
					Contact.LastName,
					Contact.FirstName,
					Insufficient_Proof_Reason__c,
					RFI_3rd_Business_Day__c,
					RFI_6th_Business_Day__c,
					RFI_9th_Business_Day__c,
					Case_Reference__c,
					OwnerId,
					Reviewed_by_Dedicated_Support__c,
					Fulfillment_Type__c,
					Fulfillment_Sub_Type__c,
					Benefit_Types__c,
					HI_Integration_Error_Message__c
				FROM Case
				WHERE Id = :objCaseForUpdate.Id
			];
			objCase.Insufficient_Proof_Reason__c = objCaseForUpdate.Insufficient_Proof_Reason__c;
			objCase.QLE_RFI_Type__c = objCaseForUpdate.QLE_RFI_Type__c;
			objCase.RFI_Type__c = objCaseForUpdate.RFI_Type__c;

			objCase.RFI_Status__c = QLERFIAutomateEmailUtils.STATUS_RFI_1;
			objCase.Automated_RFI_Flow__c = true;
			objCase.Status = QLERFIAutomateEmailUtils.STATUS_PENDING;
			Date dtNextBusinessDay = System.today();
			objCase.RFI_3rd_Business_Day__c = Utils.getBusinessDayFromDate(dtNextBusinessDay, 3);
			objCase.RFI_6th_Business_Day__c = Utils.getBusinessDayFromDate(objCase.RFI_3rd_Business_Day__c, 3);
			objCase.RFI_9th_Business_Day__c = Utils.getBusinessDayFromDate(objCase.RFI_6th_Business_Day__c, 3);
			Map<Id, String> map_UserSignatures = OEEmailAutomationHelper.fetchUserSignature(new Set<Id>{ objCase.OwnerId });
			Messaging.SingleEmailMessage objEM = QLERFIAutomateEmailUtils.createEmailRecord(objCase, 1, map_UserSignatures);
			EmailMessage objEmailMessage = QLERFIAutomateEmailUtils.createEmailMessageRecord(objEM, objCase, 1);

			if (objEM != null) {
				Messaging.SendEmailResult[] objSendMails = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ objEM });
				if (objSendMails[0].success) {
					insert objEmailMessage;
				}
			}
			updateCase(objCase);
		} catch (Exception objExp) {
			throw new AuraHandledException(objExp.getMessage());
		}
	}
    /*
     * @description Method to update the case
     * @param objCase Case object to update
     */
	@AuraEnabled
	public static void updateCase(Case objCase) {
		try {
			update objCase;
		} catch (Exception objExp) {
			throw new AuraHandledException(objExp.getMessage());
		}
	}
}