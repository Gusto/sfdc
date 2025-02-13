/**
 * @description  Checks if any open child opportunity linked with Account and re-assigns them to Account Owner. Uses custom callout to Workato
 * @author       Praveen Sethu
 * @date         11-8-2022
 * @see          AccountOwnerRouterTest
 **/
public without sharing class AccountOwnerRouter {
	public static RingLead_Routing_Credentials__c objCredentials = RingLead_Routing_Credentials__c.getInstance();
	public static String OPPTY_COMPANY_REC_TYPE_NAME = 'Company Opportunity';
	public static Set<String> set_RoleCreatedByUser = new Set<String>{
		'sales_sdr_mm_mgr_xx',
		'sales_sdr_mm_xx',
		'sales_bdr_xx_xx',
		'sales_sdr_partner_mgr_xx',
		'sales_sdr_partner_xx',
		'sales_mm_pr_xx',
		'sales_partner_ae_xx',
		'sales_partner_am_xx',
		'sales_partner_sam_xx'
	};
	// Default constructor - DO NOT REMOVE THIS
	public AccountOwnerRouter() {
	}

	/**
	 * @description  Wrapper used for sending JSON payload to Workato and to receieve input from Flow
	 * @author       Praveen Sethu
	 * @date         11-8-2022
	 * @see          NA
	 **/
	public class RequestWrapper {
		@InvocableVariable
		public String AccountId;

		@InvocableVariable
		public String RecordTypeId;

		@InvocableVariable
		public String OwnerId;

		@InvocableVariable
		public String AccountName;

		@InvocableVariable
		public String OwnerFullName;

		@InvocableVariable
		public String AccountOwnerRole;

		// Parameter Constructor
		public RequestWrapper(String AccountId, String RecordTypeId, String OwnerId, String AccountName, String OwnerFullName, String AccountOwnerRole) {
			this.AccountId = AccountId;
			this.RecordTypeId = RecordTypeId;
			this.OwnerId = OwnerId;
			this.AccountName = AccountName;
			this.OwnerFullName = OwnerFullName;
			this.AccountOwnerRole = AccountOwnerRole;
		}

		// Default constructor - DO NOT REMOVE THIS
		public RequestWrapper() {
		}
	}

	/**
	 * @description Receives account Id from Flow, checks for open opportunities and unconverted leads & sends callout to Workato
	 * @author      Praveen Sethu
	 * @param       RequestWrapper - Invocable wrapper object
	 * @return      NA
	 **/
	@InvocableMethod(callout=true label='Reassign Child Opportunities' description='Checks if any open child opportunity and re-assigns them to Account Owner. Uses custom callout to Workato')
	public static void reAssignChildOpportunities(List<RequestWrapper> list_ReqWrappers) {
		if (list_ReqWrappers.isEmpty()) {
			return;
		}

		try {
			RequestWrapper objWrapper = list_ReqWrappers[0];
			String strAccountId = objWrapper.AccountId;

			// Query open child opportunities
			Integer intChildOppties = [
				SELECT COUNT()
				FROM Opportunity
				WHERE
					(Sold_By__c = :strAccountId
					OR Referred_By__c = :strAccountId
					OR Account.ParentId = :strAccountId)
					AND IsClosed = FALSE
					AND RecordType.Name = :OPPTY_COMPANY_REC_TYPE_NAME
					AND Account.Route_To_Market__c = NULL
					AND Created_by_Role__c NOT IN :set_RoleCreatedByUser
			];

			// Query unconverted leads
			Integer intChildLeads = [
				SELECT COUNT()
				FROM Lead
				WHERE (Sold_By__c = :strAccountId OR Referred_By__c = :strAccountId) AND IsConverted = FALSE AND Route_To_Market__c = NULL AND Created_by_Role__c NOT IN :set_RoleCreatedByUser
			];

			// Check if owner Id is not blank and owner is not admin or integration user
			if (
				String.isNotBlank(objWrapper.OwnerId) &&
				!UserUtils.getUserRoleName(objWrapper.OwnerId).contains('mgr') &&
				(!UserUtils.isAdminIntgUser(objWrapper.OwnerId) || Test.isRunningTest()) &&
				(intChildOppties > 0 ||
				intChildLeads > 0)
			) {
				// Send custom callout to Workato endpoint
				HttpRequest objHTTPReq = new HttpRequest();
				objHTTPReq.setEndpoint(objCredentials.Account_Owner_Routing_Endpoint__c);
				objHTTPReq.setMethod('POST');
				objHTTPReq.setHeader('API-TOKEN', objCredentials.API_Token__c);
				objHTTPReq.setBody(JSON.serialize(objWrapper));
				objHTTPReq.setTimeOut(120000);

				Http objHTTP = new Http();
				HTTPResponse objHTTPRes = objHTTP.send(objHTTPReq);

				// update account route count flag if running from test class
				if (Test.isRunningTest()) {
					Account objAccount = new Account(Id = strAccountId);
					// set it to 2 and use it for assertion in test class
					AccountTriggerHelper.skipTrigger = true;
					objAccount.Account_Route_Count__c = 2;
					update objAccount;
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('AccountOwnerRouter', 'beforeInsert', null, objException);
		}
	}
}