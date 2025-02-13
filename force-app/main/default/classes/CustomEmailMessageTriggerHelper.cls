/**
 * @name         CustomEmailMessageTriggerHelper
 * @author       Sanjay Paryani
 * @date         01/16/2020
 * @description
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class CustomEmailMessageTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Boolean blnIsCarrierOpsEmail = false;
	public static Id IdCarrierContactsAccount = System.label.Carrier_Account_Id;

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Before insert of Email_Message__c this method will execute.
	 * @Parm        : List of Email_Message__c records
	 * @Return      : NA
	 */
	public void onBeforeInsert(List<Email_Message__c> list_NewEmailMsg) {
		processRecord(list_NewEmailMsg, null);
	}

	public void OnAfterInsert(Map<ID, Email_Message__c> newMessageMap) {
		if (skipTrigger == false && blnIsCarrierOpsEmail == false) {
			processInsertedCustomEmails(newMessageMap.keyset());
		} else if (skipTrigger == false && blnIsCarrierOpsEmail == true) {
			processInsertedCarrierOpsEmails(newMessageMap.keyset());
		}
		if (skipTrigger == false) {
			processsBORCaseLinkedWithCustomEmail(newMessageMap.keyset());
		}
	}

	public void onBeforeUpdate(Map<Id, Email_Message__c> map_OldEmailMsg, Map<Id, Email_Message__c> map_NewEmailMsg) {
		processRecord(map_NewEmailMsg.values(), map_OldEmailMsg);
	}

	public void processInsertedCarrierOpsEmails(Set<Id> set_InsertedCustomEmailIDs) {
		DateTime dtPastHour = system.now().addHours(-1);
		Set<String> set_UniqueMessageIdentifier = new Set<String>();
		List<Email_Message__c> list_EmailsToUpdate = new List<Email_Message__c>();

		for (Email_Message__c objEM : [SELECT ID, Message_Identifier__c, Createddate FROM Email_Message__c WHERE Createddate >= :dtPastHour AND ID NOT IN :set_InsertedCustomEmailIDs]) {
			if (String.isNotBlank(objEM.Message_Identifier__c)) {
				set_UniqueMessageIdentifier.add(objEM.Message_Identifier__c);
			}
		}
		if (!set_UniqueMessageIdentifier.isEmpty()) {
			for (Email_Message__c objEM : [SELECT ID, Message_Identifier__c, Archived__c FROM Email_Message__c WHERE ID IN :set_InsertedCustomEmailIDs]) {
				if (!set_UniqueMessageIdentifier.isEmpty() && set_UniqueMessageIdentifier.contains(objEM.Message_Identifier__c)) {
					objEM.Archived__c = true;
					list_EmailsToUpdate.add(objEM);
				}
			}
		}
		// Update list of emails
		if (list_EmailsToUpdate.size() > 0) {
			update list_EmailsToUpdate;
		}
	}

	public void processInsertedCustomEmails(Set<Id> set_InsertedCustomEmailIDs) {
		Map<String, Account> map_AccountNames = new Map<String, Account>();
		Map<Id, Email_Message__c> map_InsertedMessages = new Map<Id, Email_Message__c>();
		Set<String> set_InsertedPossibleMatches = new Set<String>();
		Map<Id, Email_Message__c> map_CaseToEmailMessages = new Map<Id, Email_Message__c>();
		Map<Id, Email_Message__c> map_CaseToExistingEmailMessages = new Map<Id, Email_Message__c>();
		List<Email_Message__c> list_EmailsToUpdate = new List<Email_Message__c>();
		Integer intCounter = 0;
		Boolean blnIsUpdate = false;

		try {
			for (Email_Message__c objEmail : [
				SELECT Id, Account_List__c, Account__c, Ignore_from_Search__c, Possible_Match__c, Linked_Accounts__c, Parent_Case__c, Subject__c, Archived__c, Is_Gusto_Email__c
				FROM Email_Message__c
				WHERE ID IN :set_InsertedCustomEmailIDs AND Parent_Case__c != NULL
			]) {
				map_InsertedMessages.put(objEmail.Id, objEmail);
				if (objEmail.Parent_Case__c != null) {
					map_CaseToEmailMessages.put(objEmail.Parent_Case__c, objEmail);
				}
				if (String.isNotBlank(objEmail.Possible_Match__c)) {
					set_InsertedPossibleMatches.add(objEmail.Possible_Match__c.toLowerCase() + '%');
				}
			}

			for (Email_Message__c objEM : [
				SELECT ID, Parent_Case__c
				FROM Email_Message__c
				WHERE Parent_Case__c != NULL AND Parent_Case__c IN :map_CaseToEmailMessages.keySet() AND ID NOT IN :set_InsertedCustomEmailIDs
			]) {
				map_CaseToExistingEmailMessages.put(objEM.Parent_Case__c, objEM);
			}

			if (set_InsertedPossibleMatches.size() > 0) {
				for (Account objAccount : [
					SELECT ID, Name
					FROM Account
					WHERE Name != NULL AND Id != :IdCarrierContactsAccount AND Is_Active_Customer__c = TRUE AND Name LIKE :set_InsertedPossibleMatches
				]) {
					map_AccountNames.put(objAccount.Name, objAccount);
				}
			}

			if (map_AccountNames.values().size() > 0 && map_InsertedMessages.values().size() > 0) {
				for (Email_Message__c objEM : map_InsertedMessages.values()) {
					Id idAccount;
					if (
						objEM.Parent_Case__c != null &&
						objEM.Possible_Match__c != null &&
						objEM.Account__c == null &&
						objEM.Account_List__c == null &&
						(objEM.Ignore_from_Search__c == false || (objEM.Ignore_from_Search__c == true && objEM.Is_Gusto_Email__c == true)) &&
						objEM.Linked_Accounts__c == null
					) {
						objEM.Account_List__c = '';
						intCounter = 0;
						for (Account objAcc : map_AccountNames.values()) {
							//Account_List__c field can hold only 13 IDs due to 255 character limit.
							if (intCounter > 12)
								break;
							if (objEM.Possible_Match__c.containsIgnoreCase(objAcc.Name) || objAcc.Name.containsIgnoreCase(objEM.Possible_Match__c)) {
								idAccount = objAcc.Id;
								objEM.Account_List__c = objEM.Account_List__c + objAcc.id + ';';
								intCounter++;
							}
						}

						if (intCounter == 1) {
							objEM.Account__c = idAccount;
						}
						if (map_CaseToExistingEmailMessages != null && map_CaseToExistingEmailMessages.values().size() > 0 && map_CaseToExistingEmailMessages.containsKey(objEM.Parent_Case__c)) {
							objEM.Ignore_from_Search__c = true;
						}
						blnIsUpdate = true;
					}
					if (blnIsUpdate)
						list_EmailsToUpdate.add(objEM);
				}
			}
			if (list_EmailsToUpdate.size() > 0) {
				update list_EmailsToUpdate;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException(
				'CustomEmailMessageTriggerHelper',
				'processInsertedCustomEmails',
				'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(),
				objEx.getStackTraceString()
			);
		}
	}

	public void processsBORCaseLinkedWithCustomEmail(Set<Id> set_InsertedCustomEmailIDs) {
		Map<Id, Email_Message__c> map_InsertedMessages = new Map<Id, Email_Message__c>();
		Map<Id, Email_Message__c> map_CaseToEmailMessages = new Map<Id, Email_Message__c>();
		Map<String, Carrier_Order__c> map_AccountGroupToCarrierOrder = new Map<String, Carrier_Order__c>();
		Map<String, List<Carrier_Order__c>> map_GroupNumberToCarrierOrder = new Map<String, List<Carrier_Order__c>>();
		Set<Id> set_AccountId = new Set<Id>();
		Set<String> set_PossibleGroupNumberId = new Set<String>();
		Set<String> set_NotMatchedGroupNumber = new Set<String>();
		List<Case> list_CasesToBeUpdated = new List<Case>();
		List<Email_Message__c> list_EmailsToUpdate = new List<Email_Message__c>();
		try {
			for (Email_Message__c objEmailMessage : [
				SELECT Id, Account_List__c, Account__c, Ignore_from_Search__c, Possible_Match__c, Linked_Accounts__c, Parent_Case__c, Subject__c, Possible_Group_Number__c
				FROM Email_Message__c
				WHERE
					ID IN :set_InsertedCustomEmailIDs
					AND Parent_Case__c != NULL
					AND Parent_Case__r.RecordType.Name = 'Benefits BoR'
					AND Parent_Case__r.Origin = 'Email'
					AND To_Address__c = 'bor-transfer@gusto.com'
					AND Parent_Case__r.Carrier_Order__c = NULL
					AND Parent_Case__r.Direction__c = 'Inbound'
					AND Parent_Case__r.AccountId = NULL
					AND Parent_Case__r.Benefit_Order__c = NULL
			]) {
				map_InsertedMessages.put(objEmailMessage.Id, objEmailMessage);
				if (objEmailMessage.Parent_Case__c != null) {
					map_CaseToEmailMessages.put(objEmailMessage.Parent_Case__c, objEmailMessage);
				}
				if (String.isNotBlank(objEmailMessage.Account__c)) {
					set_AccountId.add(objEmailMessage.Account__c);
				}
				if (String.isNotBlank(objEmailMessage.Possible_Group_Number__c)) {
					set_PossibleGroupNumberId.add(objEmailMessage.Possible_Group_Number__c);
				} else {
					//When Possible Group number is empty
					Email_Message__c objTempEmailMessage = new Email_Message__c(Id = objEmailMessage.Id);
					objTempEmailMessage.Is_Group_Number_Not_Matched__c = true;
					list_EmailsToUpdate.add(objTempEmailMessage);
				}
			}

			if (!set_PossibleGroupNumberId.isEmpty()) {
				set_NotMatchedGroupNumber = set_PossibleGroupNumberId;
				String strQuery = 'SELECT Id, Benefit_Order__c,Benefit_Order__r.Account__c , Group_Number__c, Benefit_Order__r.Opportunity__c ';
				strQuery += 'FROM Carrier_Order__c WHERE RecordType.Name =\'Benefits BoR\' ';
				strQuery += 'AND (Group_Number__c LIKE :set_PossibleGroupNumberId ';
				if (!set_AccountId.isEmpty()) {
					strQuery += ' OR Benefit_Order__r.Account__c IN :set_AccountId';
				}
				strQuery += ')';

				for (Carrier_Order__c objCO : Database.query(strQuery)) {
					map_AccountGroupToCarrierOrder.put(objCO.Group_Number__c + '::' + objCO.Benefit_Order__r.Account__c, objCO);
					List<Carrier_Order__c> objCOTemp = new List<Carrier_Order__c>();
					if (map_GroupNumberToCarrierOrder.containsKey(objCO.Group_Number__c)) {
						objCOTemp = map_GroupNumberToCarrierOrder.get(objCO.Group_Number__c);
					}
					objCOTemp.add(objCO);
					map_GroupNumberToCarrierOrder.put(objCO.Group_Number__c, objCOTemp);
					set_NotMatchedGroupNumber.remove(objCO.Group_Number__c);
				}
			}
			if (!map_AccountGroupToCarrierOrder.isEmpty() || !map_GroupNumberToCarrierOrder.isEmpty()) {
				for (Email_Message__c objEmailMessage : map_InsertedMessages.values()) {
					String strAccountIdWithGroupNumber = objEmailMessage.Possible_Group_Number__c + '::' + objEmailMessage.Account__c;
					Case objCase = new Case(id = objEmailMessage.Parent_Case__c);
					if (String.isNotBlank(strAccountIdWithGroupNumber) && !map_AccountGroupToCarrierOrder.isEmpty() && map_AccountGroupToCarrierOrder.containsKey(strAccountIdWithGroupNumber)) {
						Carrier_Order__c objTempCO = map_AccountGroupToCarrierOrder.get(strAccountIdWithGroupNumber);
						objCase.Benefit_Order__c = objTempCO.Benefit_Order__c;
						objCase.Carrier_Order__c = objTempCO.Id;
						objCase.AccountId = objTempCO.Benefit_Order__r.Account__c;
						objCase.Opportunity__c = objTempCO.Benefit_Order__r.Opportunity__c;
						list_CasesToBeUpdated.add(objCase);
					}
				}
			}
			if (list_CasesToBeUpdated.size() > 0) {
				update list_CasesToBeUpdated;
			}
			//if Group nUmber not matched then smark the custom email message as  Is_Group_Number_Not_Matched__c as true
			if (!set_NotMatchedGroupNumber.isEmpty()) {
				for (Email_Message__c objEmailMessage : map_InsertedMessages.values()) {
					if (String.isNotBlank(objEmailMessage.Possible_Group_Number__c) && set_NotMatchedGroupNumber.contains(objEmailMessage.Possible_Group_Number__c)) {
						Email_Message__c objTempEmailMessage = new Email_Message__c(id = objEmailMessage.Id);
						objTempEmailMessage.Is_Group_Number_Not_Matched__c = true;
						list_EmailsToUpdate.add(objTempEmailMessage);
					}
				}
			}
			if (!list_EmailsToUpdate.isEmpty()) {
				update list_EmailsToUpdate;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException(
				'CustomEmailMessageTriggerHelper',
				'processsBORCaseLinkedWithCustomEmail',
				'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(),
				objEx.getStackTraceString()
			);
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Set Archived_Date_Time__c, if Email_Message__c records is Archived__c.
	 * @Parm        : List of new Email_Message__c records
	 * 				: Map of old Email_Message__c records
	 * @Return      : NA
	 */
	public void processRecord(List<Email_Message__c> list_NewEmailMsg, Map<Id, Email_Message__c> map_OldEmailMsg) {
		try {
			Email_Message__c objOldEmailMsg = new Email_Message__c();
			for (Email_Message__c objNewEmailMsg : list_NewEmailMsg) {
				objOldEmailMsg = new Email_Message__c();
				if (map_OldEmailMsg != null && map_OldEmailMsg.size() > 0 && map_OldEmailMsg.containsKey(objNewEmailMsg.Id)) {
					objOldEmailMsg = map_OldEmailMsg.get(objNewEmailMsg.Id);
				}

				if (objNewEmailMsg.Archived__c && (objOldEmailMsg.Id == null || objNewEmailMsg.Archived__c != objOldEmailMsg.Archived__c)) {
					objNewEmailMsg.Archived_Date_Time__c = Datetime.now();
				}
			}
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('CustomEmailMessageTriggerHelper', 'processRecord', objExp.getMessage(), objExp.getStackTraceString());
		}
	}
}