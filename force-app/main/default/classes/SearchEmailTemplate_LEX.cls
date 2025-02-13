/**
 * Author: Dhir Kumar
 * Date: 12/9/2020
 * Desc: Controller for searchEmailTemplate LWC
 */
public with sharing class SearchEmailTemplate_LEX {
	@AuraEnabled
	public static EmailTemplate displayTemplatebyName(String strTemplateIdValue) {
		if (strTemplateIdValue != '' && strTemplateIdValue != 'undefined') {
			return [
				SELECT Id, Name, Description, Subject, FolderId, Body, BrandTemplateId, TemplateStyle, DeveloperName, Encoding, HtmlValue
				FROM EmailTemplate
				WHERE Id = :strTemplateIdValue
			];
		}
		return null;
	}

	/**
	 * Author: Midhuna KB
	 * Date: 13-01-2021
	 * Description: Get the list of all email folders
	 **/
	@AuraEnabled
	public static Map<String, List<Object>> fetchAllEmailTemplateFolders() {
		Map<String, String> map_EmailTemplateFolderName = new Map<String, String>(); // Map EmailTemplateFolder Id to folder Name
		Map<String, List<Object>> map_Response = new Map<String, List<Object>>(); // Map Folder Name to List of Email Templates in that folder

		//get list of email template folders that the current user has access to
		for (Folder objFolder : [
			SELECT Id, Name, UserRecordAccess.hasReadAccess
			FROM Folder
			WHERE Type = 'Email'
			ORDER BY Name ASC
		]) {
			if (objFolder.UserRecordAccess.hasReadAccess) {
				map_EmailTemplateFolderName.put(objFolder.Id, objFolder.Name);
			}
		}

		//get list of email templates for each folder
		if (!map_EmailTemplateFolderName.isEmpty()) {
			for (EmailTemplate objEmailTemplate : [
				SELECT Id, Name, Description, FolderId
				FROM EmailTemplate
				WHERE FolderId IN :map_EmailTemplateFolderName.keySet()
				ORDER BY Name ASC
			]) {
				if (map_EmailTemplateFolderName.containsKey(objEmailTemplate.FolderId)) {
					if (map_Response.containsKey(objEmailTemplate.FolderId + '-' + map_EmailTemplateFolderName.get(objEmailTemplate.FolderId))) {
						List<Object> list_EmailTemplates = map_Response.get(objEmailTemplate.FolderId + '-' + map_EmailTemplateFolderName.get(objEmailTemplate.FolderId));
						list_EmailTemplates.add(objEmailTemplate);
						map_Response.put(objEmailTemplate.FolderId + '-' + map_EmailTemplateFolderName.get(objEmailTemplate.FolderId), list_EmailTemplates);
					} else {
						map_Response.put(objEmailTemplate.FolderId + '-' + map_EmailTemplateFolderName.get(objEmailTemplate.FolderId), new List<object>{ objEmailTemplate });
					}
				}
			}
		}

		return map_Response;
	}

	/**
	 * get the previous email's subject. If there was no previous email, get the case's subject
	 */
	@AuraEnabled
	public static Map<String, Object> fetchLastEmailSubject(String strRecordId) {
		Map<String, Object> map_Response = new Map<String, Object>();
		List<EmailMessage> list_EmailMessages = [
			SELECT Id, Subject, HtmlBody, FromAddress, FromName, MessageDate, ToAddress
			FROM EmailMessage
			WHERE ParentId = :strRecordId
			ORDER BY LastModifiedDate DESC
			LIMIT 1
		];

		if (!list_EmailMessages?.isEmpty()) {
			String strSubject = list_EmailMessages[0].Subject;
			if (strSubject.startsWith('Re: ')) {
				map_Response.put('strSubject', list_EmailMessages[0].Subject);
			} else {
				map_Response.put('strSubject', 'Re: ' + list_EmailMessages[0].Subject);
			}

			map_Response.put('strId', list_EmailMessages[0].Id);
		} else {
			Case objCase = [SELECT Id, Subject FROM Case WHERE Id = :strRecordId];
			if (objCase != null) {
				map_Response.put('strSubject', objCase.Subject);
			} else {
				map_Response.put('strSubject', '');
			}
		}
		return map_Response;
	}
}