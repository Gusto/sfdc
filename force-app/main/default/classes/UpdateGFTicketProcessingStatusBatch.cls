/**
 * @name         : UpdateGFTicketProcessingStatusBatch
 * @date         : 08-30-2023
 * @description  : Update GF Ticket process state error records to queued
 **/
public class UpdateGFTicketProcessingStatusBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext BC) {
		//Retrieve GF Ticket records where the processing state is error
		String query = 'SELECT Id FROM GF_Ticket__c WHERE Processing_State__c = \'Error\'';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<GF_Ticket__c> list_GFTicket) {
		//Update the processing state of each GF Ticket record to Queued
		for (GF_Ticket__c objGFTicket : list_GFTicket) {
			objGFTicket.Processing_State__c = 'Queued';
		}

		if (!list_GFTicket.isEmpty()) {
			try {
				//Update GF Ticket Records
				update list_GFTicket;
			} catch (Exception objException) {
				ExceptionLogUtil.logException('UpdateGFTicketProcessingStatusBatch', 'execute', objException);
			}
		}
	}

	public void finish(Database.BatchableContext BC) {
	}
}