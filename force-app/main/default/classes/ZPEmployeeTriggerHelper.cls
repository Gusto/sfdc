/**
    Created by : Aurobind Ravichandran
    Created Date : 10/30/2020 
**/
public class ZPEmployeeTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Set<String> set_CompanyIds;
	private static Set<String> set_CompanyIdsForResidenceStates;
	private static Map<String, String> map_EmpIdResidenceStateAdded;
	private static Map<String, String> map_EmpIdResidenceStateRemoved;
	private static Map<String, Account> map_Accounts;
	private static Map<String, Contact> map_Contacts;
	private static Map<String, Map<String, String>> map_CompanyIdstoEmployeesWithState;

	public ZPEmployeeTriggerHelper() {
	}

	/**** Process ZP Employees (After Insert) ****/
	public void processAfterInsert(Map<Id, ZP_Employee__c> map_Employees) {
		Map<String, Account> map_AccountsToUpdate = new Map<String, Account>();
		Map<String, Contact> map_ContactsToUpdate = new Map<String, Contact>();

		// Create data collections
		setDataCollections(null, map_Employees.values());
		getAccountsMap();
		getContactsMap();
		updateAccountInformation(map_Employees.values());

		for (ZP_Employee__c objEmployee : map_Employees.values()) {
			if (
				String.isNotBlank(objEmployee.Id__c) &&
				(map_EmpIdResidenceStateAdded.containsKey(objEmployee.Id__c) ||
				map_EmpIdResidenceStateRemoved.containsKey(objEmployee.Id__c))
			) {
				Contact objContact = processResidenceStatesOnContact(objEmployee);

				if (objContact != null && String.isNotBlank(objEmployee.Id__c)) {
					map_ContactsToUpdate.put(objEmployee.Id__c, processResidenceStatesOnContact(objEmployee));
				}

				Account objUpdatedAcc = String.isNotBlank(objEmployee.Company_Id__c)
					? processResidenceStatesOnAccount(objEmployee)
					: null;
				if (objUpdatedAcc != null && String.isNotBlank(objEmployee.Company_Id__c)) {
					map_AccountsToUpdate.put(objEmployee.Company_Id__c, objUpdatedAcc);
				}
			}
		}

		if (!map_AccountsToUpdate.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> list_SaveResults = Database.update(map_AccountsToUpdate.values(), false);
			Utils.processSaveResult(
				list_SaveResults,
				map_AccountsToUpdate.values(),
				'ZP_Company_Id__c',
				true,
				'ZPEmployeeTriggerHelper-ProcessResidenceState'
			);
		}
		
		if (!map_ContactsToUpdate.isEmpty()) {
			ContactTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> list_SaveResults = Database.update(map_ContactsToUpdate.values(), false);
			Utils.processSaveResult(
				list_SaveResults,
				map_ContactsToUpdate.values(),
				'Employee_Id__c',
				true,
				'ZPEmployeeTriggerHelper-ProcessResidenceState'
			);
		}
	}

	/**** Process ZP Employees (After Update) ****/
	public void processAfterUpdate(Map<Id, ZP_Employee__c> map_OldEmployees, Map<Id, ZP_Employee__c> map_Employees) {
		Map<String, Account> map_AccountsToUpdate = new Map<String, Account>();
		Map<String, Contact> map_ContactsToUpdate = new Map<String, Contact>();

		// Create data collections
		setDataCollections(map_OldEmployees, map_Employees.values());
		getAccountsMap();
		getContactsMap();
		updateAccountInformation(map_Employees.values());

		for (ZP_Employee__c objEmployee : map_Employees.values()) {
			if (
				String.isNotBlank(objEmployee.Id__c) &&
				(map_EmpIdResidenceStateAdded.containsKey(objEmployee.Id__c) ||
				map_EmpIdResidenceStateRemoved.containsKey(objEmployee.Id__c))
			) {
				Contact objContact = processResidenceStatesOnContact(objEmployee);

				if (objContact != null && String.isNotBlank(objEmployee.Id__c)) {
					map_ContactsToUpdate.put(objEmployee.Id__c, processResidenceStatesOnContact(objEmployee));
				}

				Account objUpdatedAcc = String.isNotBlank(objEmployee.Company_Id__c)
					? processResidenceStatesOnAccount(objEmployee)
					: null;
				if (objUpdatedAcc != null && String.isNotBlank(objEmployee.Company_Id__c)) {
					map_AccountsToUpdate.put(objEmployee.Company_Id__c, objUpdatedAcc);
				}
			}
		}

		if (!map_AccountsToUpdate.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> list_SaveResults = Database.update(map_AccountsToUpdate.values(), false);
			Utils.processSaveResult(
				list_SaveResults,
				map_AccountsToUpdate.values(),
				'ZP_Company_Id__c',
				true,
				'ZPEmployeeTriggerHelper-ProcessResidenceState'
			);
		}
		
		if (!map_ContactsToUpdate.isEmpty()) {
			ContactTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> list_SaveResults = Database.update(map_ContactsToUpdate.values(), false);
			Utils.processSaveResult(
				list_SaveResults,
				map_ContactsToUpdate.values(),
				'Employee_Id__c',
				true,
				'ZPEmployeeTriggerHelper-ProcessResidenceState'
			);
		}
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Add or Update Residence State on Contact
	 * @Parm        : ZP Employee record
	 * @Return      : updated Contact record
	 **/
	private Contact processResidenceStatesOnContact(ZP_Employee__c objEmployee) {
		Contact objContact;
		if (map_Contacts.containsKey(objEmployee.Id__c)) {
			objContact = map_Contacts.get(objEmployee.Id__c);
			Map<String, String> map_EmployeeIdToState;
			if (
				map_CompanyIdstoEmployeesWithState != null &&
				map_CompanyIdstoEmployeesWithState.containsKey(objEmployee.Company_Id__c)
			) {
				map_EmployeeIdToState = map_CompanyIdstoEmployeesWithState.get(objEmployee.Company_Id__c);
			}
			
			if (map_EmpIdResidenceStateAdded.containsKey(objEmployee.Id__c)) {
				if (map_EmployeeIdToState != null) {
					map_EmployeeIdToState.put(objEmployee.Id__c, objEmployee.Residence_State__c);
				}

				objContact.Residence_State__c = objEmployee.Residence_State__c;
			} else {
				if (map_EmployeeIdToState != null && map_EmployeeIdToState.containsKey(objEmployee.Id__c)) {
					map_EmployeeIdToState.remove(objEmployee.Id__c);
				}

				objContact.Residence_State__c = '';
			}

			map_CompanyIdstoEmployeesWithState.put(objEmployee.Company_Id__c, map_EmployeeIdToState);
		}
		return objContact;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Add or Update Residence State on Account
	 * @Parm        : ZP Employee record, Map of updated Accounts
	 * @Return      : updated Account record
	 **/
	private Account processResidenceStatesOnAccount(ZP_Employee__c objEmployee) {
		Account objAcc;

		if (String.isBlank(objEmployee.Company_Id__c)) {
			return null;
		}

		if (map_CompanyIdstoEmployeesWithState.containsKey(objEmployee.Company_Id__c)) {
			Map<String, String> map_EmployeeIdToState = map_CompanyIdstoEmployeesWithState.get(
				objEmployee.Company_Id__c
			);

			objAcc = map_Accounts.containsKey(objEmployee.Company_Id__c)
				? map_Accounts.get(objEmployee.Company_Id__c)
				: null;
			
			if (objAcc != null) {
				if (map_EmployeeIdToState == null || map_EmployeeIdToState.isEmpty()) {
					objAcc.Resident_States__c = '';
				} else {
					Set<String> set_ResidenceStatesForAccount = new Set<String>(map_EmployeeIdToState.values());
					objAcc.Resident_States__c = String.join(new List<String>(set_ResidenceStatesForAccount), ';');
				}
			}
		}

		return objAcc;
	}

	/**** update account information ****/
	private void updateAccountInformation(List<ZP_Employee__c> list_employees) {
		Map<String, String> map_AccountUpdateResults = new Map<String, String>();

		if (set_CompanyIds.size() > 0) {
			Set<String> set_HIStates = getHIStates();
			Map<String, String> map_StateNameAbbreviation = getStateNameAbreviationMap();

			Map<String, Account> map_AccountsForUpdate = new Map<String, Account>();
			AggregateResult[] groupedResults = [
				SELECT COUNT(Id) empCount, Company_Id__c, Work_State__c
				FROM ZP_Employee__c
				WHERE Company_Id__c IN :set_CompanyIds AND Deleted_at__c = NULL
				GROUP BY Company_Id__c, Work_State__c
			];
			
			for (AggregateResult ar : groupedResults) {
				String strCompanyId = '' + ar.get('Company_Id__c');
				String strState = '' + ar.get('Work_State__c');
				if (!map_Accounts.containsKey(strCompanyId))
					continue;

				Account objAccountForUpdate = map_Accounts.get(strCompanyId);
				if (!map_AccountsForUpdate.containsKey(strCompanyId)) {
					objAccountForUpdate.No_Of_Employees_Filling_State__c = 0;
					objAccountForUpdate.No_of_EEs_in_HI_State__c = 0;
				}

				if (set_HIStates.contains(strState)) {
					objAccountForUpdate.No_of_EEs_in_HI_State__c += (Decimal) ar.get('empCount');
				}

				if (
					String.isNotBlank(objAccountForUpdate.BillingState) &&
					map_StateNameAbbreviation.containsKey(objAccountForUpdate.BillingState)
				) {
					if (strState == map_StateNameAbbreviation.get(objAccountForUpdate.BillingState)) {
						objAccountForUpdate.No_Of_Employees_Filling_State__c = (Decimal) ar.get('empCount');
					}
				}
				map_AccountsForUpdate.put(strCompanyId, objAccountForUpdate);
			}

			for (Account objAccount : map_Accounts.values()) {
				if (!map_AccountsForUpdate.containsKey(objAccount.Zp_Company_Id__c)) {
					objAccount.No_Of_Employees_Filling_State__c = 0;
					objAccount.No_of_EEs_in_HI_State__c = 0;
					map_AccountsForUpdate.put(objAccount.Zp_Company_Id__c, objAccount);
				}
			}

			if (map_AccountsForUpdate.size() > 0) {
				AccountTriggerHelper.skipTrigger = true;
				List<Database.SaveResult> list_SaveResults = Database.update(map_AccountsForUpdate.values(), false);
				map_AccountUpdateResults = Utils.processSaveResult(
					list_SaveResults,
					map_AccountsForUpdate.values(),
					'ZP_Company_ID__c',
					true,
					'ZPEmployeeTriggerHelper-UpdateAccountInformation'
				);
			}
		}
	}

	/**** get HI State list ****/
	public static Set<String> getHIStates() {
		Set<String> set_HiStates = new Set<String>();
		
		for (HI_Opportunity_Router_State__c objHIOpportunityRouter : [
			SELECT Id, State__c
			FROM HI_Opportunity_Router_State__c
			WHERE State__c != NULL
		]) {
			set_HiStates.add(objHIOpportunityRouter.State__c);
		}
		
		return set_HiStates;
	}

	/**** get Accounts ****/
	private void getAccountsMap() {
		map_Accounts = new Map<String, Account>();
		
		for (Account objAccount : [
			SELECT Id, ZP_Company_Id__c, BillingState, Resident_States__c
			FROM Account
			WHERE ZP_Company_Id__c IN :set_CompanyIds OR ZP_Company_Id__c IN :set_CompanyIdsForResidenceStates
		]) {
			map_Accounts.put(objAccount.ZP_Company_Id__c, objAccount);
		}
	}
	/**
	 * @Author      : Neha Dabas
	 * @Description : Fetch Contact records based on Employee Ids
	 * @Parm        : null
	 * @Return      : null
	 **/
	private void getContactsMap() {
		map_Contacts = new Map<String, Contact>();
		map_CompanyIdstoEmployeesWithState = new Map<String, Map<String, String>>();

		for (Contact objContact : [
			SELECT Id, Employee_Id__c, Residence_State__c, Account.ZP_Company_Id__c
			FROM Contact
			WHERE
				Employee_Id__c != NULL
				AND Account.ZP_Company_Id__c != NULL
				AND Account.ZP_Company_Id__c IN :set_CompanyIdsForResidenceStates
		]) {
			if (
				map_EmpIdResidenceStateAdded.containsKey(objContact.Employee_Id__c) ||
				map_EmpIdResidenceStateRemoved.containsKey(objContact.Employee_Id__c)
			) {
				map_Contacts.put(objContact.Employee_Id__c, objContact);
			}

			Map<String, String> map_EmployeeIdToState;
			
			if (map_CompanyIdstoEmployeesWithState.containsKey(objContact.Account.ZP_Company_Id__c)) {
				map_EmployeeIdToState = map_CompanyIdstoEmployeesWithState.get(objContact.Account.ZP_Company_Id__c);
			} else {
				map_EmployeeIdToState = new Map<String, String>();
			}

			map_EmployeeIdToState.put(objContact.Employee_Id__c, objContact.Residence_State__c);
			map_CompanyIdstoEmployeesWithState.put(objContact.Account.ZP_Company_Id__c, map_EmployeeIdToState);
		}
	}

	/**** get state name abreviation mapping ****/
	private Map<String, String> getStateNameAbreviationMap() {
		List<State_Name_to_abbreviations_Mapping__c> stateNameMappingList = State_Name_to_abbreviations_Mapping__c.getall()
			.values();
		Map<String, String> map_StateNameAbbreviation = new Map<String, String>();

		if (stateNameMappingList.size() > 0) {
			for (State_Name_to_abbreviations_Mapping__c objStateNameAbreviation : stateNameMappingList) {
				if (!map_StateNameAbbreviation.containsKey(objStateNameAbreviation.State_Name__c))
					map_StateNameAbbreviation.put(
						objStateNameAbreviation.State_Name__c,
						objStateNameAbreviation.State_Abbreviation__c
					);
			}
		}
		return map_StateNameAbbreviation;
	}

	/**** set data collections ****/
	private void setDataCollections(Map<Id, ZP_Employee__c> map_OldEmployees, List<ZP_Employee__c> list_Employee) {
		set_CompanyIds = new Set<String>();
		set_CompanyIdsForResidenceStates = new Set<String>();
		map_EmpIdResidenceStateRemoved = new Map<String, String>();
		map_EmpIdResidenceStateAdded = new Map<String, String>();

		for (ZP_Employee__c objEmployee : list_Employee) {
			ZP_Employee__c objOldEmployee = (map_OldEmployees != null) ? map_OldEmployees.get(objEmployee.Id) : null;

			if (String.isNotBlank(objEmployee.Company_Id__c)) {
				if (
					objOldEmployee == null ||
					objOldEmployee.Deleted_at__c != objEmployee.Deleted_At__c ||
					objOldEmployee.Work_State__c != objEmployee.Work_State__c
				) {
					set_CompanyIds.add(objEmployee.Company_Id__c);
				}

				//insert
				if (objOldEmployee == null && String.isNotBlank(objEmployee.Residence_State__c)) {
					set_CompanyIdsForResidenceStates.add(objEmployee.Company_Id__c);
					map_EmpIdResidenceStateAdded.put(objEmployee.Id__c, objEmployee.Residence_State__c);
				} else if (objOldEmployee != null) {
					if (objEmployee.Residence_State__c != objOldEmployee.Residence_State__c) {
						//update
						set_CompanyIdsForResidenceStates.add(objEmployee.Company_Id__c);
						//Residence State removed
						if (String.isBlank(objEmployee.Residence_State__c)) {
							map_EmpIdResidenceStateRemoved.put(
								objEmployee.Id__c,
								objEmployee.Residence_State__c
							);
						} else if (String.isBlank(objOldEmployee.Residence_State__c)) {
							//Residence State Added
							map_EmpIdResidenceStateAdded.put(objEmployee.Id__c, objEmployee.Residence_State__c);
						} else {
							//Residence State changed
							map_EmpIdResidenceStateAdded.put(objEmployee.Id__c, objEmployee.Residence_State__c);
							map_EmpIdResidenceStateRemoved.put(
								objEmployee.Id__c,
								objOldEmployee.Residence_State__c
							);
						}
					}
					if (
						objOldEmployee.Deleted_at__c != objEmployee.Deleted_At__c &&
						String.isNotBlank(objEmployee.Residence_State__c)
					) {
						set_CompanyIdsForResidenceStates.add(objEmployee.Company_Id__c);
						if (objEmployee.Deleted_At__c != null) {
							map_EmpIdResidenceStateRemoved.put(
								objEmployee.Id__c,
								objEmployee.Residence_State__c
							);
						} else if (objEmployee.Deleted_At__c == null) {
							map_EmpIdResidenceStateAdded.put(objEmployee.Id__c, objEmployee.Residence_State__c);
						}
					}
				}
			}
		}
	}
}