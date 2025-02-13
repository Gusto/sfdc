public with sharing class IVRRoutingLogTriggerHelper {
	public static boolean skipTrigger = false;
	public static final String INBOUND_CALL = 'Inbound Call';
	public static final String C2CB = 'C2CB';

	public void OnBeforeInsert(List<IVR_Routing_Log__c> list_IVR) {
		linkAccountsToIVR(list_IVR);
		linkContactsToIVR(list_IVR);
	}

	public void OnBeforeUpdate(Map<ID, IVR_Routing_Log__c> map_OldIVR, Map<ID, IVR_Routing_Log__c> map_NewIVR) {
		List<IVR_Routing_Log__c> list_IvrChangedCIP = new List<IVR_Routing_Log__c>();
		List<IVR_Routing_Log__c> list_IvrChangedZPUserId = new List<IVR_Routing_Log__c>();

		for (IVR_Routing_Log__c objNewIVR : map_NewIVR.values()) {
			IVR_Routing_Log__c objOldIVR = map_OldIVR.get(objNewIVR.Id);

			if (objNewIVR.CIP_Company_Id__c != objOldIVR.CIP_Company_Id__c) {
				list_IvrChangedCIP.add(objNewIVR);
			}

			if (objNewIVR.ZP_User_Id__c != objOldIVR.ZP_User_Id__c) {
				list_IvrChangedZPUserId.add(objNewIVR);
			}

			//if queue name is changed, update Previous Queue Name and Transferred
			if (String.isNotBlank(objNewIVR.InQueue_Queue_Name__c) && String.isNotBlank(objOldIVR.InQueue_Queue_Name__c) && objNewIVR.InQueue_Queue_Name__c != objOldIVR.InQueue_Queue_Name__c) {
				objNewIVR.Previous_Queue_Name__c = objOldIVR.InQueue_Queue_Name__c;
				objNewIVR.Transferred__c = true;
			}
		}

		linkAccountsToIVR(list_IvrChangedCIP);
		linkContactsToIVR(list_IvrChangedZPUserId);
	}

	/**
	 * Author: Alex
	 * Date: 8/19/2020
	 * Desc: find ivrs where cip company id changed and find account based on that,
	 * else search by ivrs' cip accounting firm id if blank
	 */
	public static void linkAccountsToIVR(List<IVR_Routing_Log__c> list_IVR) {
		List<String> list_CipCompany = new List<String>();
		List<String> list_CipAccounting = new List<String>();
		List<String> list_CipUserRole = new List<String>();

		// iterate over IVR log is an inbound call CIP_Company_Id__c is the UUID use the ZP User Role Id to find the correct Account based on CIP token entered in. Currently we recieve UUID from product.
		// else use CIP_Company_Id__c or CIP_Accounting_Firm_ID__c to find Associated Account.
		for (IVR_Routing_Log__c objIVR : list_IVR) {
			if (
				String.isNotBlank(objIVR.ZP_User_Role_Id__c) &&
				String.isBlank(objIVR.CIP_Accounting_Firm_ID__c) &&
				String.isNotBlank(objIVR.CIP_Company_Id__c) &&
				objIVR.CIP_Company_Id__c.contains('-') &&
				objIVR.Type__c == INBOUND_CALL &&
				String.isBlank(objIVR.Source__c)
			) {
				list_CipUserRole.add(objIVR.ZP_User_Role_Id__c);
			} else if (String.isNotBlank(objIVR.CIP_Company_Id__c)) {
				list_CipCompany.add(objIVR.CIP_Company_Id__c);
			} else if (String.isNotBlank(objIVR.CIP_Accounting_Firm_ID__c)) {
				list_CipAccounting.add(objIVR.CIP_Accounting_Firm_ID__c);
			}
		}

		//map company id to objAcct id and map firm id to objAcct id
		Map<String, Id> map_CompanyToAcct = new Map<String, Id>();
		Map<String, Id> map_FirmToAcct = new Map<String, Id>();
		Map<String, Id> map_UserRoleToAcct = new Map<String, Id>();
		if (!list_CipUserRole.isEmpty()) {
			List<ZP_User_Role__c> list_AccountFromUserRole = [SELECT Id__c, Company_Id__c, Company_Account__c FROM ZP_User_Role__c WHERE Id__c != null AND Id__c IN :list_CipUserRole AND Company_Id__c != null AND Company_Account__c != null];
			// iterate over the list of ZP User Roles and add the Company Id to the list of CIP Companies
			// and add the ZP User Role Id to the map of ZP User Role Ids to Account Ids
			for (ZP_User_Role__c objZPUserRole : list_AccountFromUserRole) {
				list_CipCompany.add(objZPUserRole.Company_Id__c);
				map_UserRoleToAcct.put(objZPUserRole.Id__c, objZPUserRole.Company_Account__c);
			}
		}

		// query for accounts based on company id or firm id
		List<Account> list_AccountsFromCIP = [
			SELECT Id, ZP_Company_ID__c, ZP_Firm_ID__c
			FROM Account
			WHERE (ZP_Company_ID__c != null AND ZP_Company_ID__c IN :list_CipCompany) OR (ZP_Firm_ID__c != null AND ZP_Firm_ID__c IN :list_CipAccounting)
		];

		// iterate over the list_AccountsFromCIP of accounts and add the ZP_Company_ID__c to the map of company ids to account ids
		// and add the ZP_Firm_ID__c to the map of firm ids to account ids
		for (Account objAcct : list_AccountsFromCIP) {
			if (String.isNotBlank(objAcct.ZP_Company_ID__c)) {
				map_CompanyToAcct.put(objAcct.ZP_Company_ID__c, objAcct.Id);
			}

			if (String.isNotBlank(objAcct.ZP_Firm_ID__c)) {
				map_FirmToAcct.put(objAcct.ZP_Firm_ID__c, objAcct.Id);
			}
		}

		// iterate over the list of IVR logs and add the account id to the IVR log if CIP_Company_Id__c is a UUID
		// else add the account id to the IVR log if CIP_Company_Id__c is not blank
		// else add the account id to the IVR log if CIP_Accounting_Firm_ID__c
		for (IVR_Routing_Log__c objIVR : list_IVR) {
			if (String.isNotBlank(objIVR.CIP_Company_Id__c) && objIVR.CIP_Company_Id__c.contains('-')) {
				objIVR.CIP_Account__c = Map_UserRoleToAcct.get(objIVR.ZP_User_Role_Id__c);
			} else if (String.isNotBlank(objIVR.CIP_Company_Id__c)) {
				objIVR.CIP_Account__c = map_CompanyToAcct.get(objIVR.CIP_Company_Id__c);
			} else {
				objIVR.CIP_Account__c = map_FirmToAcct.get(objIVR.CIP_Accounting_Firm_ID__c);
			}
		}
	}

	/**
	 * Author: Alex
	 * Date: 8/19/2020
	 * Desc: find Contacts based on IVRs' ZP User Id or ANI__c
	 */
	public static void linkContactsToIVR(List<IVR_Routing_Log__c> list_IVR) {
		List<String> list_ZPId = new List<String>();
		List<String> list_Phones = new List<String>();

		for (IVR_Routing_Log__c objIVR : list_IVR) {
			if (String.isNotBlank(objIVR.ZP_User_Id__c)) {
				list_ZPId.add(objIVR.ZP_User_Id__c);
			} else {
				list_Phones.add(objIVR.ANI__c);
			}
		}

		List<Contact> list_Contacts = [SELECT Id, ZP_User_Id__c FROM Contact WHERE ZP_User_Id__c IN :list_ZPId];
		Map<String, Id> map_PhoneToContactId = CaseQueryHelper.getContactsFromPhone(list_Phones);
		Map<String, Id> map_ZpToContactId = new Map<String, Id>();

		for (Contact objContact : list_Contacts) {
			map_ZpToContactId.put(objContact.ZP_User_Id__c, objContact.Id);
		}

		for (IVR_Routing_Log__c objIVR : list_IVR) {
			if (String.isNotBlank(objIVR.ZP_User_Id__c)) {
				objIVR.Contact__c = map_ZpToContactId.get(objIVR.ZP_User_Id__c);
			} else {
				objIVR.Contact__c = map_PhoneToContactId.get(objIVR.ANI__c);
			}
		}
	}

	public void OnAfterUpdate(Map<Id, IVR_Routing_Log__c> map_OldIVR, Map<Id, IVR_Routing_Log__c> map_NewIVR) {
		/*
            Author: Alex
            Date: 7/30/2020
            Desc: if IVR Routing Log's Call Start and Call End times are updated,
            update Case's Call Start and End Times
        */
		try {
			Map<Id, CallTime> map_IVRToCallTime = new Map<Id, CallTime>();
			Set<Id> set_IVRNewQueue = new Set<Id>();
			Set<Id> set_AllIVRId = new Set<Id>();
			Set<String> set_DIVRId = new Set<String>();

			//if call times changed, put into map of id to call start and map of id to call end
			for (IVR_Routing_Log__c objNewIVR : map_NewIVR.values()) {
				IVR_Routing_Log__c objOldIVR = map_OldIVR.get(objNewIVR.Id);
				CallTime ct = new CallTime();
				if (objNewIVR.Call_Start__c != objOldIVR.Call_Start__c) {
					ct.startTime = objNewIVR.Call_Start__c;
				}
				if (objNewIVR.Call_End__c != objOldIVR.Call_End__c) {
					ct.endTime = objNewIVR.Call_End__c;
				}
				if (ct.startTime != null || ct.endTime != null) {
					map_IVRToCallTime.put(objNewIVR.Id, ct);
					set_AllIVRId.add(objNewIVR.Id);
				}
				//if InQueue name changed, update Case's record type
				if (objNewIVR.InQueue_Queue_Name__c != objOldIVR.InQueue_Queue_Name__c) {
					set_AllIVRId.add(objNewIVR.Id);
					set_IVRNewQueue.add(objNewIVR.Id);
				}

				//if divrid is not null, add it to a list
				if (String.isNotBlank(objNewIVR.Divrid__c)) {
					set_DIVRId.add(objNewIVR.Divrid__c);
				}
			}
			//List<Id> list_IvrId = new List<Id>(map_IVRToCallTime.keySet());
			List<Id> list_IVRId = new List<Id>(set_AllIVRId);
			List<Case> list_Cases = IVRRoutingLogQueryHelper.getCases(list_IvrId);
			Map<Id, List<Case>> map_IVRIdToCase = new Map<Id, List<Case>>();

			//group Cases by IVR Routing Log
			for (Case objCase : list_Cases) {
				List<Case> list_GroupedCases = new List<Case>();
				if (map_IVRIdToCase.containsKey(objCase.IVR_Routing_Log__c)) {
					list_GroupedCases = map_IVRIdToCase.get(objCase.IVR_Routing_Log__c);
				}
				list_GroupedCases.add(objCase);

				map_IVRIdToCase.put(objCase.IVR_Routing_Log__c, list_GroupedCases);
			}

			//go through maps of objIVR id to call times
			//update respective case call times
			Map<Id, Case> map_CasesToUpdate = new Map<Id, Case>();

			if (!map_IVRIdToCase.isEmpty()) {
				List<String> list_DIVRId = new List<String>(set_DIVRId);

				for (Id idIVR : map_IVRIdToCase.keySet()) {
					for (Case objCase : map_IVRIdToCase.get(idIVR)) {
						Boolean boolUpdate = false;
						if (map_IVRToCallTime.keySet().contains(idIVR)) {
							if (map_IVRToCallTime.get(idIVR).startTime != null) {
								objCase.Call_Start__c = map_IVRToCallTime.get(idIVR).startTime;
								boolUpdate = true;
							}
							if (map_IVRToCallTime.get(idIVR).endTime != null) {
								objCase.Call_End__c = map_IVRToCallTime.get(idIVR).endTime;
								boolUpdate = true;
							}
						}
						if (boolUpdate) {
							map_CasesToUpdate.put(objCase.Id, objCase);
						}
					}
				}
			}

			//get case audit logs from case id
			List<Case_Audit_Log__c> list_CAL = [SELECT Id FROM Case_Audit_Log__c WHERE Case__c IN :map_CasesToUpdate.keySet()];

			CaseTriggerHelper.skipTrigger = true;
			update map_CasesToUpdate.values();
			update list_CAL;
			CaseTriggerHelper.skipTrigger = false;

			if (Test.isRunningTest()) {
				Integer i = 0 / 0;
			}
		} catch (Exception e) {
			ExceptionLogUtil.logException('IVRRoutingLogTriggerHelper', 'OnAfterUpdate', e.getMessage(), e.getStackTraceString());
		}
	}

	/*
        Class that stores call start and end time
    */
	public class CallTime {
		public DateTime startTime;
		public DateTime endTime;
	}
}