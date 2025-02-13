/**
 * @name         DeleteUserRolesAndSkillsBatch
 * @test class   DeleteUserRolesAndSkillsTest
 * @author       Deepika Saini
 * @date         17th May 2021
 * @description  Delete User Roles And Skills of Inactive users.
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class DeleteUserRolesAndSkillsBatch implements Schedulable, Database.Batchable<SObject>, Database.Stateful {
	public Boolean blnBatchSuccess = true;
	public List<User_Role__c> list_UserRolesToBeDeleted = new List<User_Role__c>();
	public Set<Id> set_UsersIds = new Set<Id>();

	public static void sendEmailOnBatchFailed() {
		String strToAddresses = System.Label.Daily_Limit_Notification_Email_List;
		List<String> list_ToAddresses = strToAddresses.split(';');
		String strEmailSubject = 'Delete User Roles And Skills Batch failed.';
		String strEmailBody = 'Hello Admin, \n\n Delete User Roles And Skills Batch failed. \n Please check Exception Logs.';

		Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
		objEmail.setSubject(strEmailSubject);
		objEmail.setPlainTextBody(strEmailBody);
		objEmail.setToAddresses(list_ToAddresses);
		if(OrganizationUtilities.canSendEmails()){
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ objEmail });	
		}
	}

	public void execute(SchedulableContext objSC) {
		DeleteUserRolesAndSkillsBatch objBatch = new DeleteUserRolesAndSkillsBatch();
		Database.executeBatch(objBatch, 1000);
	}

	public Database.querylocator start(Database.BatchableContext objBC) {
		Set<Id> set_UserRolesId = new Set<Id>();

		for (User_Role__c objUserRole : [
			SELECT Id, User__c
			FROM User_Role__c
			WHERE User__c != null AND User__r.Inactive_User_Date_Time__c != null AND User__r.IsActive = FALSE AND User__r.Inactive_User_Date_Time__c >= YESTERDAY
		]) {
			list_UserRolesToBeDeleted.add(objUserRole);
			set_UserRolesId.add(objUserRole.Id);
			set_UsersIds.add(objUserRole.User__c);
		}

		String strQuery = 'SELECT Id ' + 'FROM User_Skill__c ' + 'WHERE User_Role__c != null ' + 'AND User_Role__c IN :set_UserRolesId';

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext objBatch, List<User_Skill__c> list_UserSkillsToBeDeleted) {
		try {
			if (list_UserSkillsToBeDeleted != null && list_UserSkillsToBeDeleted.size() > 0) {
				delete list_UserSkillsToBeDeleted;
			}

			if (Test.isRunningTest() && DeleteUserRolesAndSkillsTest.blnRunCatchTest == true) {
				throw new EmailException('Error while Deleting User Skills for testing');
			}
		} catch (Exception objExp) {
			blnBatchSuccess = false;
			ExceptionLogUtil.logException(
				'DeleteUserRolesAndSkillsBatch',
				'execute method',
				'Error while Deleting User Skills (WHERE Inactive_User_Date_Time__c >= YESTERDAY)' +
				' - ' +
				objExp.getMessage(),
				'high'
			);
		}
	}

	public void finish(Database.BatchableContext objBC) {
		try {
			UserRoleTriggerHelper.skipTrigger = true;
			delete list_UserRolesToBeDeleted;
			UserRoleTriggerHelper.skipTrigger = false;

			if (Test.isRunningTest() && DeleteUserRolesAndSkillsTest.blnRunCatchTest == true) {
				throw new EmailException('Error while Deleting User Skills for testing');
			}
		} catch (Exception objExp) {
			blnBatchSuccess = false;
			ExceptionLogUtil.logException(
				'DeleteUserRolesAndSkillsBatch',
				'finish method',
				'Error while Deleting User Roles (WHERE Inactive_User_Date_Time__c >= YESTERDAY)' +
				' - ' +
				objExp.getMessage(),
				'high'
			);
		}

		try {
			UserUtils.updateRequireRoutingOnBOCO(set_UsersIds);
		} catch (Exception objExp) {
			blnBatchSuccess = false;
			ExceptionLogUtil.logException(
				'DeleteUserRolesAndSkillsBatch',
				'finish method',
				'Error while Updating Requires Routing on Benefit Order and Carrier Order.' +
				' - ' +
				objExp.getMessage(),
				'high'
			);
		}

		if (!blnBatchSuccess) {
			sendEmailOnBatchFailed();
		}
	}
}