/**
 * @description  Used for Gusto Gcorp-V2 Chatbot for checking contact and account info
 * @see          ChatBotGcorpControllerTest
 **/
public class ChatBotGcorpController {
	/**
	 * @description  Invocable class to share output with bot
	 * @see          ChatBotGcorpControllerTest
	 **/
	public class Output {
		@InvocableVariable(required=true)
		public Boolean blnIsAccountAvailable;

		@InvocableVariable(required=true)
		public Boolean blnIsAccountAvailableAndPayrollRun;

		@InvocableVariable
		public Contact objContact;

		@InvocableVariable
		public Id idAccount;
	}

	/**
	 * @description  Invocable class to get input from bot
	 * @see          ChatBotGcorpControllerTest
	 **/
	public class Input {
		@InvocableVariable
		public ID routableID;
		
		@InvocableVariable(required=true)
		public String visitorEmail;
	}

	/**
	 * @description Gets customer info & returns if account has joined date
	 * @param       list_Inputs - List of objects of Input type
	 * @return      List of objects of type Output
	 **/
	@InvocableMethod(label='Check Customer Info Gcorp')
	public static List<Output> getCustomerInfo(List<Input> list_Inputs) {
		List<Output> list_Output = new List<Output>();
		Set<String> set_VisitorEmails = new Set<String>();
		Map<Id, String> map_TranscriptIdVisitorEmail = new Map<Id, String>();
		Map<Id, String> map_AccountIdVisitorEmail = new Map<Id, String>();
		Map<String, Contact> map_VistorEmailContactMap = new Map<String, Contact>();
		Map<String, Id> map_VistorEmailAccountIdMap = new Map<String, Id>();

		for (Input objInput : list_Inputs) {
			set_VisitorEmails.add(objInput.visitorEmail);
			map_TranscriptIdVisitorEmail.put(objInput.routableID, objInput.visitorEmail);
		}

		for (Contact objContact : [
			SELECT Id, Email, AccountId, Account.Joined_Date_Panda__c, Account.Name, FirstName, LastName, Phone
			FROM Contact
			WHERE Email IN :set_VisitorEmails
			ORDER BY CreatedDate DESC
		]) {
			map_VistorEmailContactMap.put(objContact.Email, objContact); //keeping only the first contact per visitor email
			if (String.isNotBlank(objContact.AccountId)) {
				map_AccountIdVisitorEmail.put(objContact.AccountId, objContact.Email);
				map_VistorEmailAccountIdMap.put(objContact.Email, objContact.AccountId);
			}
		}

		for (Input objInput : list_Inputs) {
			Contact objExistingContact = map_VistorEmailContactMap.get(objInput.visitorEmail);

			Output objOutput = new Output();

			if (objExistingContact == null) {
				objOutput.blnIsAccountAvailable = false;
				objOutput.blnIsAccountAvailableAndPayrollRun = false;
				list_Output.add(objOutput);
			} else {
				objOutput.objContact = objExistingContact;
				if (!String.isBlank(objExistingContact.AccountId)) {
					objOutput.idAccount = objExistingContact.AccountId;
					objOutput.blnIsAccountAvailable = true;
					if (objExistingContact.Account.Joined_Date_Panda__c != null) {
						objOutput.blnIsAccountAvailable = false;
						objOutput.blnIsAccountAvailableAndPayrollRun = true;
					} else {
						objOutput.blnIsAccountAvailableAndPayrollRun = false;
					}
				} else {
					objOutput.blnIsAccountAvailable = false;
				}
				list_Output.add(objOutput);
			}
		}

		return list_Output;
	}
}