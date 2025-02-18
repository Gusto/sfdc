/**
 * @name         ZPCompanyMigrationTriggerHelper
 * @test class   ZPCompanyMigrationTriggerHelperTest
 * @author       Aurobind Ravichandran
 * @date         3/27/2017
 * @description  Trigger helper for ZP Company Migration via kafka topic zenpayroll.company_migration
 */
public class ZPCompanyMigrationTriggerHelper {
	public List<CaseTeamRole> list_CaseTeamRoles = Utils.queryCaseTeamRoles('Customer Contact');
	public static Boolean queue = false;
	public static Boolean skipTrigger = false;
	public static Boolean blnManualInitiation = false;

	public static Map<String, Map<String, String>> map_CaseTeamMembers;
	public static Map<String, Opportunity> map_Opportunities;
	public static Map<String, Order> map_Orders;
	public static Map<String, Account> map_AccountIds;
	public static Map<Id, List<AccountContactRelation>> map_AccountIdToContRels;
	public static String PAYROLL_ADMIN = 'Payroll Admin';
	public static String PRIMARY_PAYROLL_ADMIN = 'Primary Payroll Admin';

	//Pattern to match valid date format in JSON
	private final static Pattern DATE_PATTERN = Pattern.compile('((?:19|20)\\d\\d)-(0?[1-9]|1[012])-([12][0-9]|3[01]|0?[1-9])');

	/**
	 * @Author      : Anand K Singh
	 * @Description : Handles Before Insert Context
	 * @Parm        : list_Tasks - List of ZP_Company_Migration__c from Trigger.new
	 * @Return      : N/A
	 **/
	public void processBeforeInsert(List<ZP_Company_Migration__c> list_ZPCompanyMigrations) {
		runProcess(list_ZPCompanyMigrations, 'OnBeforeInsert');
	}

	/**
	 * @Author      : Anand K Singh
	 * @Description : Handles After Insert Context
	 * @Parm        : list_Tasks - List of ZP_Company_Migration__c from Trigger.new
	 * @Return      : N/A
	 **/
	public void processAfterInsert(List<ZP_Company_Migration__c> list_ZPCompanyMigrations) {
		queueProcess(list_ZPCompanyMigrations);
	}

	/**
	 * @Author      : Anand K Singh
	 * @Description : Handles Before Update Context
	 * @Parm        : map_NewTasks - Map of ZP_Company_Migration__c Id and ZP_Company_Migration__c Object from Trigger.newMap
	 * @Parm        : map_OldTasks - Map of ZP_Company_Migration__c Id and ZP_Company_Migration__c Object from Trigger.oldMap
	 * @Return      : N/A
	 **/

	public void processBeforeUpdate(Map<ID, ZP_Company_Migration__c> map_NewZPCompanyMigrations, Map<ID, ZP_Company_Migration__c> map_OldZPCompanyMigrations) {
		runProcess(map_NewZPCompanyMigrations.values(), 'OnBeforeUpdate');
	}

	/**
	 * @Author      : Anand K Singh
	 * @Description : Handles After Update Context
	 * @Parm        : map_NewTasks - Map of ZP_Company_Migration__c Id and ZP_Company_Migration__c Object from Trigger.newMap
	 * @Parm        : map_OldTasks - Map of ZP_Company_Migration__c Id and ZP_Company_Migration__c Object from Trigger.oldMap
	 * @Return      : N/A
	 **/
	public void processAfterUpdate(Map<ID, ZP_Company_Migration__c> map_NewZPCompanyMigrations, Map<ID, ZP_Company_Migration__c> map_OldZPCompanyMigrations) {
		queueProcess(map_NewZPCompanyMigrations.values());
	}

	/**
	 * @Author      : Anand K Singh
	 * @Description : Process will run via this method
	 * @Parm        : list_Tasks - List of ZP_Company_Migration__c
	 * @Parm        : strEventType - String variable for Event type
	 * @Return      : N/A
	 **/
	private void runProcess(List<ZP_Company_Migration__c> list_ZPCompanyMigrationsTemp, String strEventType) {
		try {
			for (ZP_Company_Migration__c objZPCompanyMigration : list_ZPCompanyMigrationsTemp) {
				objZPCompanyMigration.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}

			if (queue == true) {
				createCollections(list_ZPCompanyMigrationsTemp);
				processInformation(list_ZPCompanyMigrationsTemp);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'ZPCompanyMigrationTriggerHelper',
				strEventType,
				objException.getMessage(),
				objException.getStackTraceString() +
				'. line number: ' +
				objException.getLineNumber()
			);
		}
	}

	/**
	 * @Author      : Anand K Singh
	 * @Description : Process will queue via this method
	 * @Parm        : list_Tasks - List of ZP_Company_Migration__c
	 * @Return      : N/A
	 **/
	private void queueProcess(List<ZP_Company_Migration__c> list_ZPCompanyMigrationsTemp) {
		if (queue == false) {
			ZPCompanyMigrationQueue objZPCompanyMigrationJob = new ZPCompanyMigrationQueue(list_ZPCompanyMigrationsTemp);
			ID idZPCompanyMigrationJob = System.enqueueJob(objZPCompanyMigrationJob);
		}
	}

	/**
	 * @Author      : Anand K Singh
	 * @Description : Map the Object field of order and ZP_Company_Migration__c
	 * @Parm        : Object of ZP_Company_Migration__c
	 * @Parm        : Id of AccountId
	 * @Parm        : map_opportunities - Map of Opportunity Company id and Opportunity Object
	 * @Parm        : map_Orders - Map of Exeternal Id and Order Object
	 * @Return      : Order Object
	 **/
	private Order mapOrderFields(ZP_Company_Migration__c objMigrationInfo, Id idAccount, Map<String, Opportunity> map_opportunities, Map<String, Order> map_Orders) {
		Order objOrder = new Order();

		if (map_Orders.containsKey(objMigrationInfo.External_Key__c)) {
			objOrder = map_Orders.get(objMigrationInfo.External_Key__c);
		}
		//BSS-981: Restrict AIC field updates to insert
		if (objOrder.Id == null) {
			objOrder.Active_Employee_Count__c = objMigrationInfo.Active_Employee_Count__c;
			objOrder.Contractor_Count__c = objMigrationInfo.Contractor_Count__c;
			objOrder.Inactive_Employee_Count__c = objMigrationInfo.Inactive_Employee_Count__c;
		} else {
			if (objOrder.Active_Employee_Count__c == null || objOrder.Active_Employee_Count__c == 0) {
				objOrder.Active_Employee_Count__c = objMigrationInfo.Active_Employee_Count__c;
			}

			if (objOrder.Contractor_Count__c == null || objOrder.Contractor_Count__c == 0) {
				objOrder.Contractor_Count__c = objMigrationInfo.Contractor_Count__c;
			}

			if (objOrder.Inactive_Employee_Count__c == null || objOrder.Inactive_Employee_Count__c == 0) {
				objOrder.Inactive_Employee_Count__c = objMigrationInfo.Inactive_Employee_Count__c;
			}
		}
		objOrder.AccountId = idAccount;
		objOrder.Additional_Information__c = objMigrationInfo.Additional_Information__c;
		objOrder.Agent_Email__c = objMigrationInfo.Agent_Email__c;
		objOrder.Agent_Name__c = objMigrationInfo.Agent_Name__c;
		objOrder.Benefits_List__c = objMigrationInfo.Benefits_List__c;
		objOrder.Deductions_List__c = objMigrationInfo.Deductions_List__c;
		objOrder.States__c = objMigrationInfo.Employee_States__c;
		objOrder.External_Key__c = objMigrationInfo.External_Key__c;
		objOrder.Id__c = objMigrationInfo.ID__c;
		objOrder.Has_Benefits__c = objMigrationInfo.Has_Benefits__c;
		objOrder.Has_Deductions__c = objMigrationInfo.Has_Deductions__c;
		objOrder.Has_Reimbursements__c = objMigrationInfo.Has_Reimbursements__c;
		objOrder.Migration_State__c = objMigrationInfo.Migration_State__c;
		objOrder.Pay_Schedules__c = objMigrationInfo.Pay_Schedule__c;
		objOrder.Pay_Schedule_2__c = objMigrationInfo.Pay_Schedule_2__c;
		objOrder.Reimbursements_List__c = objMigrationInfo.Reimbursements_List__c;
		objOrder.Tax_Payer_Type__c = objMigrationInfo.Tax_Payer_Type__c;
		objOrder.RecordTypeId = ZPCompanyMigrationUtil.COMPANYMIGRATION_ORDER_RT_ID;
		objOrder.EffectiveDate = System.today();
		objOrder.Xero_Migration_Selection__c = objMigrationInfo.Created_by__c;
		objOrder = processAdditionalData(objOrder, objMigrationInfo);
		objOrder.Previous_Payroll_Provider_Collect_Option__c = objMigrationInfo.Previous_Payroll_Provider_Collect_Option__c;
		objOrder.COVID_19_relief_programs__c = objMigrationInfo.COVID_19_relief_programs__c;
		objOrder.Type = ZPCompanyMigrationUtil.TYPE_NEW_CUSTOMER_ONBOARDING;

		// If Pay_Date_Extension_Reason__c is populated in an update scenario, it means the first check date is manually updated on an order.
		if (String.isBlank(objOrder.Pay_Date_Extension_Reason__c)) {
			objOrder.First_Check_Date__c = objMigrationInfo.First_Check_Date__c;
		}
		if (map_Orders.containsKey(objMigrationInfo.External_Key__c) == false) {
			objOrder.Status = 'Drafted';
		}
		if (
			objMigrationInfo.Deleted_At__c != null &&
			(!map_Orders.containsKey(objMigrationInfo.External_Key__c) || ZPCompanyMigrationUtil.STATUS_CLOSED_PAYROLL_RUN != map_Orders.get(objMigrationInfo.External_Key__c).Status)
		) {
			objOrder.Status = ZPCompanyMigrationUtil.STATUS_CLOSED_CANCELED;
		}
		if (map_opportunities.containsKey(objMigrationInfo.Company_Id__c)) {
			objOrder.OpportunityId = map_opportunities.get(objMigrationInfo.Company_Id__c).Id;
		}

		objOrder.Which_Health_Benefits_Currently_Offered__c = objMigrationInfo.Which_Health_Benefits_Currently_Offered__c;
		objOrder.Other_Health_Benefits_Currently_Offered__c = objMigrationInfo.Other_Health_Benefits_Currently_Offered__c;
		objOrder.Financial_Health_Benefits__c = objMigrationInfo.Financial_Health_Benefits__c;
		objOrder.Transportation_Benefits__c = objMigrationInfo.Transportation_Benefits__c;
		objOrder.Other_Financial_Benefits_Currently_Offer__c = objMigrationInfo.Other_Financial_Benefits_Currently_Offer__c;
		objOrder.Custom_Deductions__c = objMigrationInfo.Custom_Deductions__c;
		objOrder.Previous_Payroll_Provider__c = objMigrationInfo.Previous_Payroll_Provider__c;

		return objOrder;
	}

	/**
	 * @Author      : Anand K Singh
	 * @Description : process the information which get from 3rd party
	 * @Parm        : List of ZP_Company_Migration__c
	 * @Return      : N/A
	 **/
	private void processInformation(List<ZP_Company_Migration__c> list_ZPCompanyMigrations) {
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_MigrationKeys = new Set<String>();
		Set<String> set_IgnoredProcessingStates = new Set<String>{ IntegrationUtils.DEAD_STATE, IntegrationUtils.BACKLOG };
		List<Case> list_UpsertCases = new List<Case>();
		Map<String, ZP_Company_Migration__c> map_zpCompanyMigration = new Map<String, ZP_Company_Migration__c>();
		List<Order> list_Orders = new List<Order>();
		Map<String, String> map_DMLCaseUpsertErrors = new Map<String, String>();
		Map<String, String> map_DMLOrderUpsertErrors = new Map<String, String>();
		Map<String, String> map_cases = new Map<String, String>();
		List<CaseTeamMember> list_TeamMembers = new List<CaseTeamMember>();
		List<Case> list_CaseUpdate = new List<Case>();
		Database.DMLOptions objDMLOptions = new Database.DMLOptions();
		objDMLOptions.assignmentRuleHeader.useDefaultRule = true;

		for (ZP_Company_Migration__c objZPCompanyMigration : list_ZPCompanyMigrations) {
			if (set_IgnoredProcessingStates.contains(objZPCompanyMigration.Processing_State__c)) {
				continue;
			}
			if (!map_AccountIds.containsKey(objZPCompanyMigration.Company_Id__c)) {
				if (objZPCompanyMigration.Deleted_At__c == null) {
					setProcessingState(IntegrationUtils.BACKLOG, 'Company does not exist', objZPCompanyMigration);
				}
				continue;
			}
			if (String.isNotBlank(objZPCompanyMigration.Message__c) && objZPCompanyMigration.Message__c.containsIgnoreCase('Order End Date can\'t be earlier than Order Start Date.: Order End Date')) {
				setProcessingState(IntegrationUtils.DEAD_STATE, objZPCompanyMigration.Message__c, objZPCompanyMigration);
				continue;
			}
			if (objZPCompanyMigration.Migration_State__c == 'Completed' && blnManualInitiation == false) {
				continue;
			}
			if (objZPCompanyMigration.Processing_State__c != IntegrationUtils.QUEUED_STATE) {
				objZPCompanyMigration.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}

			Case objCase = new Case();
			String strAccountId = map_AccountIds.get(objZPCompanyMigration.Company_Id__c)?.Id;
			objCase.RecordTypeId = ZPCompanyMigrationUtil.RECTYPE_PAYROLL_TRANSFER_CASE;
			objCase.Origin = 'Panda';
			objCase.Type = 'Payroll Transfer';
			objCase.AccountId = strAccountId;
			objCase.Integration_Key__c = objZPCompanyMigration.External_Key__c;

			if (map_AccountIdToContRels.containsKey(strAccountId)) {
				AccountContactRelation objAccountContactRelation = map_AccountIdToContRels.get(strAccountId)?.get(0);
				objCase.ContactId = objAccountContactRelation?.ContactId;
			}

			objCase.Subject = map_AccountIds.get(objZPCompanyMigration.Company_Id__c)?.Name;
			if (map_Opportunities.containsKey(objZPCompanyMigration.Company_Id__c)) {
				objCase.Opportunity__c = map_Opportunities.get(objZPCompanyMigration.Company_Id__c).id;
			}

			objCase.setOptions(objDMLOptions);
			list_UpsertCases.add(objCase);
		}

		// Upserting cases
		if (list_UpsertCases.size() > 0) {
			List<Database.UpsertResult> saveResult = database.upsert(list_UpsertCases, case.Fields.Integration_Key__c, false);
			map_DMLCaseUpsertErrors = Utils.processUpsertResult(saveResult, list_UpsertCases, 'Integration_Key__c', true, 'ZPCompanyMigrationTriggerHepler-processInformation::CaseUpsert');

			for (Case objCase : list_UpsertCases) {
				map_cases.put(objCase.Integration_Key__c, objCase.id);
			}
		}

		for (ZP_Company_Migration__c objZPCompanyMigration : list_ZPCompanyMigrations) {
			if (
				objZPCompanyMigration.Processing_State__c == IntegrationUtils.DEAD_STATE ||
				objZPCompanyMigration.Processing_State__c == IntegrationUtils.ERROR_STATE ||
				objZPCompanyMigration.Processing_State__c == IntegrationUtils.BACKLOG
			) {
				continue;
			}

			String strCaseId = map_cases.get(objZPCompanyMigration.External_Key__c);
			Map<String, String> map_ExistingTeamCases = map_CaseTeamMembers.get(objZPCompanyMigration.External_Key__c);
			String strAccountId = map_AccountIds.get(objZPCompanyMigration.Company_Id__c)?.Id;

			if (map_AccountIdToContRels.containsKey(strAccountId)) {
				List<AccountContactRelation> list_AccountContactRelations = map_AccountIdToContRels.get(strAccountId);
				if (list_AccountContactRelations.size() > 0) {
					for (AccountContactRelation objAccountContactRelation : list_AccountContactRelations) {
						if (map_ExistingTeamCases.containsKey(objAccountContactRelation.ContactId)) {
							continue;
						}
						CaseTeamMember member = new CaseTeamMember();
						member.ParentId = strCaseId;
						member.MemberId = objAccountContactRelation.ContactId;
						member.TeamRoleId = list_CaseTeamRoles.get(0).Id;
						list_TeamMembers.add(member);
					}
				}
			}

			if (map_AccountIds.containsKey(objZPCompanyMigration.Company_Id__c)) {
				Order objOrder = mapOrderFields(objZPCompanyMigration, map_AccountIds.get(objZPCompanyMigration.Company_Id__c)?.Id, map_Opportunities, map_Orders);
				objOrder.Case__c = strCaseId;
				list_Orders.add(objOrder);
				map_zpCompanyMigration.put('ZPCOMPANYMIGRATION' + objZPCompanyMigration.ID__c, objZPCompanyMigration);
			}

			setProcessingState(IntegrationUtils.PROCESSED_STATE, ZPCompanyMigrationUtil.MSG_PROCESSED, objZPCompanyMigration);
		}

		//Inserting Case Team Members for upserted cases
		if (list_TeamMembers.size() > 0) {
			Database.insert(list_TeamMembers, false);
		}

		// Inserting Orders
		if (list_Orders.size() > 0) {
			List<Database.UpsertResult> list_saveResults = database.upsert(list_Orders, Order.Fields.ID__c, false);
			map_DMLOrderUpsertErrors = Utils.processUpsertResult(list_saveResults, list_Orders, 'ID__c', true, 'ZPCompanyMigrationTriggerHepler-processInformation::InsertingOrders');
		}

		for (Order objOrder : list_Orders) {
			if (objOrder.Case__c != null) {
				Case objCase = new Case(Id = objOrder.Case__c);
				objCase.Order__c = objOrder.Id;
				// Link Contact Id on Case with Primary Contact from TTF
				if (objOrder.Transition_to_Fulfillment__r.Contact__c != null) {
					objCase.ContactId = objOrder.Transition_to_Fulfillment__r.Contact__c;
				}
				list_CaseUpdate.add(objCase);
			}
		}

		if (list_CaseUpdate.size() > 0) {
			Database.update(list_CaseUpdate);
		}

		// Error out the ZP Company Migration record if any DML fails
		for (ZP_Company_Migration__c objZPCompanyMigration : list_ZPCompanyMigrations) {
			if (map_DMLCaseUpsertErrors.containsKey(objZPCompanyMigration.External_Key__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLCaseUpsertErrors.get(objZPCompanyMigration.External_Key__c), objZPCompanyMigration);
				continue;
			}
			if (map_DMLOrderUpsertErrors.containsKey(objZPCompanyMigration.ID__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLOrderUpsertErrors.get(objZPCompanyMigration.ID__c), objZPCompanyMigration);
				continue;
			}
		}
	}

	/**
     * @Author      : Aurobind Ravichandran
     * @Description : Sets processing state for staging record
     * @Parm        : String to specify processing state.
                    : String to specify any success or error message.
                    : Object of Zp_Company_Migration__c record.                  
     * @Return      : Object of Zp_Company_Migration__c record.
     **/
	private Zp_Company_Migration__c setProcessingState(String strProcessingState, String strMessage, Zp_Company_Migration__c objZPCompanyMigration) {
		objZPCompanyMigration.Processing_State__c = strProcessingState;
		objZPCompanyMigration.Message__c = String.isNotBlank(strMessage) && strMessage.length() > 255 ? strMessage.subString(0, 255) : strMessage;
		objZPCompanyMigration.Last_Processed__c = System.now();
		return objZPCompanyMigration;
	}

	/**
     * @Author      : Bhagat Singh
     * @Description : Process Additional Data JSON and copy information to Order records.
     * @Parm        : Object of Order record.
                    : Object of objMigrationInfo record.
     * @Return      : Object of Order record.
     **/
	public static Order processAdditionalData(Order objOrder, ZP_Company_Migration__c objMigrationInfo) {
		if (String.isNotBlank(objMigrationInfo.Additional_Data__c)) {
			ZPCompanyAdditionalDataJSON objAdditionalData = (ZPCompanyAdditionalDataJSON) JSON.deserialize(objMigrationInfo.Additional_Data__c, ZPCompanyAdditionalDataJSON.class);

			if (objAdditionalData != null) {
				objOrder.Industry_Title__c = objAdditionalData.industry_title;
				objOrder.NAICS_Code__c = objAdditionalData.naics_code;
				objOrder.SIC_Codes__c = objAdditionalData.sic_codes;
				objOrder.Cannot_Find_Industry__c = false;

				if (String.isNotBlank(objAdditionalData.cannot_find_industry) && objAdditionalData.cannot_find_industry == 'true') {
					objOrder.Cannot_Find_Industry__c = true;
				}

				objOrder.Custom_Description__c = objAdditionalData.custom_description;
				objOrder.Primary_Contact_Same_As_Payroll_Runner__c = objAdditionalData.primary_contact_same_as_payroll_runner;
				objOrder.Number_Of_Pay_Schedules__c = objAdditionalData.number_of_pay_schedules;

				if (String.isNotBlank(objAdditionalData.last_expected_pay_date)) {
					Matcher objMatcher = DATE_PATTERN.matcher(objAdditionalData.last_expected_pay_date);

					if (objMatcher.matches()) {
						objOrder.Last_Expected_Pay_Date__c = Date.valueOf(objAdditionalData.last_expected_pay_date);
					}
				}

				objOrder.Direct_Deposit_Speed__c = objAdditionalData.direct_deposit_speed;
				objOrder.Has_Remote_Employees__c = objAdditionalData.has_remote_employees;
				objOrder.Registered_As_Employer_In_Work_States__c = objAdditionalData.registered_as_employer_in_work_states;
				objOrder.Employee_Payment_Method__c = objAdditionalData.employee_payment_method;
				objOrder.Employees_With_Multiple_Tax_Jurisdiction__c = objAdditionalData.employees_with_multiple_tax_jurisdictions;
				objOrder.Invite_Employees_Via_Email__c = objAdditionalData.invite_employees_via_email;
				objOrder.Invite_Dismissed_Employees_Via_Email__c = objAdditionalData.invite_dismissed_employees_via_email;
				objOrder.Pay_Contractors_With_Payroll_Provider__c = objAdditionalData.pay_contractors_with_payroll_provider;
				objOrder.Contractor_Payment_Method__c = objAdditionalData.contractor_payment_method;
				objOrder.Pay_International_Contractors__c = objAdditionalData.pay_international_contractors;
				objOrder.Contractor_Countries__c = objAdditionalData.contractor_countries;
				objOrder.Invite_Contractors_Via_Email__c = objAdditionalData.invite_contractors_via_email;
				objOrder.Time_Off_Offered__c = objAdditionalData.time_off_offered;
				objOrder.Track_PTO_Policies__c = objAdditionalData.track_pto_policies;
				objOrder.New_Health_Benefits__c = objAdditionalData.new_health_benefits;
				objOrder.Employees_With_Tax_Exemptions__c = objAdditionalData.employees_with_tax_exemptions;
				objOrder.Team_Invitation_Preference__c = objAdditionalData.how_do_you_want_us_to_sign_in_to_your_account;
			}
		}

		return objOrder;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Handle all data retrival operations.
	 * @Parm        : list_ZPCompanyMigrations [list of company migration records]
	 * @Return      : N/A
	 **/
	public void createCollections(List<ZP_Company_Migration__c> list_ZPCompanyMigrations) {
		map_CaseTeamMembers = new Map<String, Map<String, String>>();
		map_Opportunities = new Map<String, Opportunity>();
		map_Orders = new Map<String, Order>();
		map_AccountIds = new Map<String, Account>();
		map_AccountIdToContRels = new Map<Id, List<AccountContactRelation>>();

		Set<String> set_CompanyIds = new Set<String>();
		Set<Id> set_AccountIds = new Set<Id>();

		for (ZP_Company_Migration__c objMigration : list_ZPCompanyMigrations) {
			if (String.isNotBlank(objMigration.Company_Id__c)) {
				set_CompanyIds.add(objMigration.Company_Id__c);
			}

			if (String.isNotBlank(objMigration.External_Key__c)) {
				map_CaseTeamMembers.put(objMigration.External_Key__c, new Map<String, String>());
			}
		}

		//Order query
		for (Order ord : [
			SELECT
				Id,
				Status,
				External_Key__c,
				Pay_Date_Extension_Reason__c,
				First_Check_Date__c,
				Active_Employee_Count__c,
				Contractor_Count__c,
				Inactive_Employee_Count__c,
				Transition_To_Fulfillment__r.Contact__c
			FROM Order
			WHERE External_Key__c IN :map_CaseTeamMembers.keyset()
		]) {
			map_Orders.put('' + ord.External_Key__c, ord);
		}

		//Team Members Query
		for (Case objCase : [SELECT Id, Integration_Key__c, (SELECT Id, MemberId FROM TeamMembers) FROM Case WHERE Integration_Key__c IN :map_CaseTeamMembers.keyset()]) {
			Map<String, String> teamMap = new Map<String, String>();

			if (objCase.TeamMembers != null) {
				for (CaseTeamMember member : objCase.TeamMembers) {
					teamMap.put(member.memberId, member.memberId);
				}
			}

			map_CaseTeamMembers.put(objCase.Integration_Key__c, teamMap);
		}

		//Opportunity query
		for (Opportunity objOpp : [
			SELECT Id, StageName, IsClosed, IsWon, Name, ZP_Company_ID__c, Source_Id__c
			FROM Opportunity
			WHERE
				ZP_Company_ID__c IN :set_CompanyIds
				AND (RecordTypeId = :ZPCompanyMigrationUtil.COMPANY_OPPORTUNITY_RT_ID
				OR (RecordTypeId = :ZPCompanyMigrationUtil.ACQUISITION_OPPTY_RT_ID
				AND Type = :ZPCompanyMigrationUtil.OPP_TYPE_NEW_BUSINESS))
			ORDER BY createddate ASC
		]) {
			map_Opportunities.put('' + objOpp.ZP_Company_ID__c, objOpp);
		}

		//Account query
		for (Account objAccount : [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :set_CompanyIds]) {
			map_AccountIds.put(objAccount.ZP_Company_ID__c, objAccount);
			set_AccountIds.add(objAccount.Id);
		}

		//AccountContactRelation query
		for (AccountContactRelation objConRel : [SELECT Id, ContactId, AccountId, Roles FROM AccountContactRelation WHERE AccountId IN :set_AccountIds]) {
			if (objConRel.Roles != null && (objConRel.Roles.contains(PAYROLL_ADMIN) || objConRel.Roles.contains(PRIMARY_PAYROLL_ADMIN))) {
				if (map_AccountIdToContRels.containsKey(objConRel.AccountId)) {
					List<AccountContactRelation> list_AccountContactRelations = map_AccountIdToContRels.get(objConRel.AccountId);
					list_AccountContactRelations.add(objConRel);
					map_AccountIdToContRels.put(objConRel.AccountId, list_AccountContactRelations);
				} else {
					map_AccountIdToContRels.put(objConRel.AccountId, new List<AccountContactRelation>{ objConRel });
				}
			}
		}
	}
}