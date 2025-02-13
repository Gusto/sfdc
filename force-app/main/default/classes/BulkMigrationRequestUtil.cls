/**
 *  @author AKS
 *  @since 04/27/2022
 *  @description Bulk Migration Request related Utilities for reuse
 */

public without sharing class BulkMigrationRequestUtil {
	public static final String BULK_MIGRATION_STATUS_COMPLETED = 'Completed';
	public static final String STATUS_CLOSED_PAYROLL_RUN = 'Closed: Payroll Run';
	public static final String STATUS_CLOSED_CANCELED = 'Closed: Canceled';
	public static final String STATUS_CLOSED = 'Closed';

	/**
	 * By:Pawan
	 * Date Created :22-Apr-2023
	 * Desc :  logBulkMigrationRequestEmailAlerts : Email message record creation for BMR object
	 */
	@InvocableMethod(label='BulkMigrationRequest Update Email Message' description='Email notifications on BulkMigrationRequest.')
	public static void logBulkMigrationRequestEmailAlerts(List<Id> list_BulkMigrationRequestIds) {
		Map<Id, String> map_BMRIdTemplateName = new Map<Id, String>();
		Map<Id, Messaging.SingleEmailMessage> map_BMRIdEmailRec = new Map<Id, Messaging.SingleEmailMessage>();
		Map<Id, EmailMessage> map_BMRIdEmailMessage = new Map<Id, EmailMessage>();
		Map<string, EmailTemplate> map_BulkIdTemplate = new Map<String, EmailTemplate>();
		Map<Id, Messaging.SingleEmailMessage> map_BulkIdEmailRec = new Map<Id, Messaging.SingleEmailMessage>();
		Map<String, Id> map_TemplateNameId = new Map<String, Id>();
		Map<string, EmailMessage> map_HtmlEmailMessage = new Map<string, EmailMessage>();
		if (list_BulkMigrationRequestIds == null || list_BulkMigrationRequestIds.isEmpty()) {
			return;
		}
		for (EmailMessage objEmailMessage : [
			SELECT Id, HtmlBody, Subject, ToAddress, RelatedToId, ParentId, Email_Template_Name__c
			FROM EmailMessage
			WHERE RelatedToId IN :list_BulkMigrationRequestIds
			ORDER BY CreatedDate DESC
		]) {
			if (!map_BMRIdEmailMessage.containsKey(objEmailMessage.RelatedToId)) {
				map_BMRIdEmailMessage.put(objEmailMessage.RelatedToId, objEmailMessage);
				map_BMRIdTemplateName.put(objEmailMessage.RelatedToId, objEmailMessage.Email_Template_Name__c);
			}
		}
		for (EmailTemplate objEmailTemplate : [SELECT Id, body, DeveloperName, HTMLValue, subject FROM EmailTemplate WHERE DeveloperName IN :map_BMRIdTemplateName.values()]) {
			map_TemplateNameId.put(objEmailTemplate.DeveloperName, objEmailTemplate.Id);
			map_BulkIdTemplate.put(objEmailTemplate.DeveloperName, objEmailTemplate);
		}
		Map<Id, Bulk_Migration_Request__c> map_BulkIdRec = new Map<Id, Bulk_Migration_Request__c>(
			[
				SELECT Id, OwnerId, Bulk_Migration_Owner__c, Assignment_Error_Message__c, Primary_Point_of_Contact__c, Facilitator__c, Facilitator__r.email, Bulk_Migration_Owner__r.email
				FROM Bulk_Migration_Request__c
				WHERE Id IN :list_BulkMigrationRequestIds
			]
		);
		for (Bulk_Migration_Request__c objBulk : map_BulkIdRec.values()) {
			Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
			objMail.TargetObjectId = objBulk.Primary_Point_of_Contact__c;
			objMail.TemplateId = map_TemplateNameId.get(map_BMRIdTemplateName.get(objBulk.Id));
			objMail.WhatId = objBulk.Id;
			objMail.setSaveAsActivity(false);
			objMail.setTreatTargetObjectAsRecipient(true);
			map_BMRIdEmailRec.put(objBulk.Id, objMail);
		}
		if (!Test.isRunningTest()) {
			try {
				Savepoint objSavePoint = Database.setSavepoint();
				Messaging.sendEmail(map_BMRIdEmailRec.values());
				Database.rollback(objSavePoint);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('BulkMigrationRequestUtil', 'logBulkMigrationRequestEmailAlerts', ex);
			}
		}
		for (Bulk_Migration_Request__c objBulk : map_BulkIdRec.values()) {
			if (map_BMRIdEmailRec.containsKey(objBulk.Id) && map_BMRIdEmailMessage.containsKey(objBulk.Id)) {
				Messaging.SingleEmailMessage objEmail = map_BMRIdEmailRec.get(objBulk.Id);
				EmailMessage objEmailMessage = map_BMRIdEmailMessage.get(objBulk.Id);
				objEmailMessage.HtmlBody = objEmail.getPlainTextBody();
				objEmailMessage.Subject = objEmail.getSubject();
				if (objEmail.getToAddresses() != null && !objEmail?.getToAddresses()?.isEmpty()) {
					objEmailMessage.ToAddress = String.join(objEmail.getToAddresses(), ',');
				}
				map_BMRIdEmailMessage.put(objBulk.Id, objEmailMessage);
			}
		}
		update map_BMRIdEmailMessage.values();
	}
}