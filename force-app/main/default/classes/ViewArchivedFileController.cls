/**
 * ViewArchivedFileController
 *
 * This Apex controller is designed to handle the retrieval and presentation of archived files and associated email data.
 * It includes nested wrapper classes to structure the response data for use in Lightning components.
 *
 * Test class to run: ViewArchivedFileControllerTest
 *
 * Key functionalities:
 * - Encapsulates email data and associated file attachments.
 * - Provides a structured response format for Lightning components.
 */
public without sharing class ViewArchivedFileController {
	// Wrapper class to hold the response data
	public class ResponseWrapper {
		@AuraEnabled
		public List<EmailWrapper> list_Emails = new List<EmailWrapper>(); // List of email wrappers

		@AuraEnabled
		public List<NEILON__File__c> list_RecordAttachments = new List<NEILON__File__c>(); // List of record attachments

		@AuraEnabled
		public String strObjectType; // Object type of the record

		// Constructor to initialize the response wrapper with email wrappers and record attachments
		public ResponseWrapper(List<EmailWrapper> list_Emails, List<NEILON__File__c> list_RecordAttachments, String strObjectType) {
			this.list_Emails = list_Emails;
			this.list_RecordAttachments = list_RecordAttachments;
			this.strObjectType = strObjectType;
		}
	}

	// Wrapper class to hold email data and associated files
	public class EmailWrapper {
		@AuraEnabled
		public String strFromName; // Sender's name

		@AuraEnabled
		public String strToEmailAddress; // Recipient's email address

		@AuraEnabled
		public DateTime dtMessageDate; // Date and time of the email

		@AuraEnabled
		public Boolean blnIncoming; // Flag to indicate if the email is incoming

		@AuraEnabled
		public List<NEILON__File__c> list_Files; // List of files associated with the email

		@AuraEnabled
		public Id idEmailMessage; // ID of the email message

		// Constructor to initialize the email wrapper with all parameters
		public EmailWrapper(Id idEmailMessage, String strFromName, String strToEmailAddress, DateTime dtMessageDate, Boolean blnIncoming, List<NEILON__File__c> list_Files) {
			this.idEmailMessage = idEmailMessage;
			this.strFromName = strFromName;
			this.strToEmailAddress = strToEmailAddress;
			this.dtMessageDate = dtMessageDate;
			this.blnIncoming = blnIncoming;
			this.list_Files = list_Files;
		}
	}

	/**
	 * @description Apex method to get attachments related to a record.
	 * This method retrieves email messages related to a given record ID and their associated files.
	 * It returns a ResponseWrapper containing the email messages and their files.
	 *
	 * @param {Id} idRecord - The ID of the record to retrieve attachments for.
	 * @return {ResponseWrapper} - A wrapper object containing the list of email messages and their associated files.
	 */
	@AuraEnabled(cacheable=true)
	public static ResponseWrapper getAttachments(Id idRecord) {
		List<EmailWrapper> list_EmailWrappers = new List<EmailWrapper>(); // List to hold email wrappers

		Set<Id> set_EmailIds = new Set<Id>(); // Set to hold email IDs
		Map<Id, List<NEILON__File__c>> map_EmailFiles = new Map<Id, List<NEILON__File__c>>(); // Map to hold email files

		// Query to get email messages related to the record
		for (EmailMessage objMessage : [SELECT Id, Name, FromName, Incoming, ToAddress, MessageDate FROM EmailMessage WHERE ParentId = :idRecord ORDER BY MessageDate DESC]) {
			EmailWrapper objEmailWrapper = new EmailWrapper(objMessage.Id, objMessage.FromName, objMessage.ToAddress, objMessage.MessageDate, objMessage.Incoming, new List<NEILON__File__c>());
			list_EmailWrappers.add(objEmailWrapper);
			set_EmailIds.add(objMessage.Id);
		}

		// Query to get files associated with the email messages
		for (NEILON__File__c objFile : [
			SELECT Id, Name, NEILON__Parent_Id__c, NEILON__Size_Text__c, NEILON__Size__c, NEILON__Content_Type__c
			FROM NEILON__File__c
			WHERE NEILON__Parent_Id__c IN :set_EmailIds
		]) {
			if (!map_EmailFiles.containsKey(objFile.NEILON__Parent_Id__c)) {
				map_EmailFiles.put(objFile.NEILON__Parent_Id__c, new List<NEILON__File__c>());
			}
			map_EmailFiles.get(objFile.NEILON__Parent_Id__c).add(objFile);
		}

		// Associate files with the corresponding email wrappers
		for (EmailWrapper objEmailWrapper : list_EmailWrappers) {
			if (map_EmailFiles.containsKey(objEmailWrapper.idEmailMessage)) {
				objEmailWrapper.list_Files = map_EmailFiles.get(objEmailWrapper.idEmailMessage);
			}
		}

		// Query to get record attachments
		List<NEILON__File__c> list_RecordAttachments = [
			SELECT Id, Name, NEILON__Parent_Id__c, NEILON__Size_Text__c, NEILON__Size__c, NEILON__Content_Type__c
			FROM NEILON__File__c
			WHERE NEILON__Parent_Id__c = :idRecord
		];

		// Return the response wrapper with email wrappers and record attachments
		return new ResponseWrapper(list_EmailWrappers, list_RecordAttachments, idRecord.getSObjectType().getDescribe().getLabel());
	}
}