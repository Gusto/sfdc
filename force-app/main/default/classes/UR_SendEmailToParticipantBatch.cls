/**
 * @name         UR_SendEmailToParticipantBatch
 * @author       Bhagat Singh
 * @Date         18 Oct 2021
 * @description  This class send Email to Participants
 * @test class   UR_SendEmailToParticipantBatchTest.cls
 **/
public with sharing class UR_SendEmailToParticipantBatch implements Database.Batchable<sObject>, Database.Stateful {
	public Id idProjectMaster;
	public static String strSendEmail = 'Send Email';
	public static String strProcessEmail = 'Process Email';
	public static String strFailEmail = 'Fail';

	/**
	 * @Author      : Bhagat Singh
	 * @Description : start method
	 * @Parm        : Object of BatchableContext
	 * @Return      : Object of QueryLocator
	 **/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String strQuery = 'SELECT Id, E_Mail_Status__c FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :idProjectMaster AND E_Mail_Status__c = :strSendEmail ';

		return Database.getQueryLocator(strQuery);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : execute method
	 * @Parm        : List of Research_Project_Detail__c records
	 * @Return      : void
	 **/
	public void execute(Database.BatchableContext BC, List<Research_Project_Detail__c> list_Participants) {
		if (list_Participants.size() > 0) {
			Research_Project_Detail__c objRPD = list_Participants[0];
			objRPD.E_Mail_Status__c = strProcessEmail;
			update objRPD;
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : finish method
	 * @Parm        : Object of BatchableContext
	 * @Return      : void
	 **/
	public void finish(Database.BatchableContext BC) {
		// Creating a exception log record only if there are errors in processing a batch of records.
		AsyncApexJob objJob = [
			SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
			FROM AsyncApexJob
			WHERE Id = :BC.getJobId()
		];
		String strSubject = 'UR_SendEmailToParticipantBatch ' + objJob.Status;
		String strBody =
			'Records processed ' +
			objJob.TotalJobItems +
			' with ' +
			objJob.NumberOfErrors +
			' failures.';

		if (objJob.NumberOfErrors > 0) {
			ExceptionLogUtil.logException('UR_SendEmailToParticipantBatch', 'execute', strSubject, strBody);
		}   	
	}
}