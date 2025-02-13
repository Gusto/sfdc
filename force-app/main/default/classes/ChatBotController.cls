/**
 * @description  Used for Gusto Sales Chatbot for checking account info
 * @author       Nigam Goyal
 * @see          ChatBotControllerTest
 **/
public with sharing class ChatBotController {
	/**
	 * @description  Invocable class to share output with bot
	 * @author       Nigam Goyal
	 * @see          ChatBotControllerTest
	 **/
	public class PayrollOutput {
		@InvocableVariable(required=true)
		public Boolean blnIsAccountAvailable;

		@InvocableVariable(required=true)
		public Boolean blnIsAccountAvailableAndPayrollRun;
	}

	/**
	 * @description  Invocable class to get input from bot
	 * @author       Nigam Goyal
	 * @see          ChatBotControllerTest
	 **/
	public class TranscriptInput {
		@InvocableVariable(required=true)
		public ID routableID;
	}

	/**
	 * @description Gets customer info & returns if account has joined date
	 * @author      Nigam Goyal
	 * @param       list_Transcripts - List of chat transcripts
	 * @return      List of invocable classes of type PayrollOutput
	 **/
	@InvocableMethod(label='Check Customer Info')
	public static List<PayrollOutput> getCustomerInfo(List<TranscriptInput> list_Transcripts) {
		List<PayrollOutput> list_PayrollOutput = new List<PayrollOutput>();
		PayrollOutput objPayrollOutput = new PayrollOutput();
		Set<Id> set_RoutableIds = new Set<Id>();
		Set<Id> set_AccountIds = new Set<Id>();

		for (TranscriptInput objTranscript : list_Transcripts) {
			set_RoutableIds.add(objTranscript.routableID);
		}

		Map<Id, LiveChatTranscript> map_TranscriptRecords = new Map<Id, LiveChatTranscript>([SELECT Id, Name, AccountId FROM LiveChatTranscript WHERE Id IN :set_RoutableIds]);

		if (map_TranscriptRecords.isEmpty()) {
			return list_PayrollOutput;
		}
		for (LiveChatTranscript objTranscriptRecord : map_TranscriptRecords.values()) {
			if (!String.isblank(objTranscriptRecord.AccountId)) {
				set_AccountIds.add(objTranscriptRecord.AccountId);
			}
		}
		Map<Id, Account> map_AccountRecords = new Map<Id, Account>([SELECT Id, Name, Joined_Date_Panda__c FROM Account WHERE Id IN :set_AccountIds]);

		for (LiveChatTranscript objTranscriptRecord : map_TranscriptRecords.values()) {
			if (!String.isblank(objTranscriptRecord.AccountId)) {
				objPayrollOutput.blnIsAccountAvailable = true;
				if (map_AccountRecords.containsKey(objTranscriptRecord.AccountId) && map_AccountRecords.get(objTranscriptRecord.AccountId).Joined_Date_Panda__c != null) {
					objPayrollOutput.blnIsAccountAvailable = false;
					objPayrollOutput.blnIsAccountAvailableAndPayrollRun = true;
				} else {
					objPayrollOutput.blnIsAccountAvailableAndPayrollRun = false;
				}
			} else {
				objPayrollOutput.blnIsAccountAvailable = false;
			}
			list_PayrollOutput.add(objPayrollOutput);
		}
		return list_PayrollOutput;
	}
}