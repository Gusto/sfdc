/**
 * @author Praveen Sethu
 * @since 07/14/2022
 * Trigger Trigger Helper class that takes care of business functionalities like linking invoice to company accounts.
 * Test class: PaymentInvoiceTriggerHandlerTest
 **/
public without sharing class PaymentInvoiceTriggerHelper {
	Map<String, Account> map_CompanyIdToAccount = new Map<String, Account>();
	Map<Id, Account> map_AccountsWithFirstInvoice = new Map<Id, Account>();

	Map<String, String> map_RatePlanToPrices = new Map<String, String>();
	Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();
	public final static String PRIORITY_SUPPORT_SERVICE = 'Priority Support and HR Services';
	public final static String COMPANY_DOES_NOT_EXIST = 'Company does not exist';
	public final static String FIRST_INVOICE_NO_ACCOUNT_JOIN_DATE = 'First Invoice No Account Join Date';
	public final static String TIER_OR_ADD_ON_CHANGE_NO_TIER_UPSELL = 'Tier or Add On Change No Tier Upsell';

	/*** Process Before Insert  ***/
	public void processBeforeInsert(List<Payment_Invoice__c> list_NewInvoices) {
		createCollectionsBefore(list_NewInvoices, null);
		for (Payment_Invoice__c objInvoice : list_NewInvoices) {
			setAccount(objInvoice, map_CompanyIdToAccount);
			setPricing(objInvoice);
			setInvoiceMonth(objInvoice);
		}
	}

	/*** Process Before Insert  ***/
	public void processAfterInsert(List<Payment_Invoice__c> list_NewInvoices) {
		// create collections & populate maps
		createCollectionsAfter(list_NewInvoices, null);

		updateFirstDayOfFirstMonth();

		// All DML statements start here
		if (!map_AccountsToUpdate.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			update map_AccountsToUpdate.values();
			AccountTriggerHelper.skipTrigger = false;
		}
	}

	/*** Process Before Insert  ***/
	public void processBeforeUpdate(List<Payment_Invoice__c> list_NewInvoices) {
		createCollectionsBefore(list_NewInvoices, null);
		for (Payment_Invoice__c objInvoice : list_NewInvoices) {
			setAccount(objInvoice, map_CompanyIdToAccount);
			setPricing(objInvoice);
			setInvoiceMonth(objInvoice);
		}
	}

	/*** Process Before Insert  ***/
	public void processAfterUpdate(List<Payment_Invoice__c> list_NewInvoices) {
		// create collections & populate maps
		createCollectionsAfter(list_NewInvoices, null);

		updateFirstDayOfFirstMonth();

		// All DML statements start here
		if (!map_AccountsToUpdate.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			update map_AccountsToUpdate.values();
			AccountTriggerHelper.skipTrigger = false;
		}
	}

	/**
	 * @description Populates collection variables needed for after insert context
	 * @author      Praveen Sethu
	 * @param       list_NewInvoices = List of New Invoices
	 * @param       map_OldInvoices = Map of Old Invoices
	 * @return      NA
	 **/
	private void createCollectionsAfter(List<Payment_Invoice__c> list_NewInvoices, Map<Id, Payment_Invoice__c> map_OldInvoices) {
		Set<String> set_CompanyIds = new Set<String>{};

		// Create data collections
		for (Payment_Invoice__c objInvoice : list_NewInvoices) {
			if (String.isNotBlank(objInvoice.Company_Id__c)) {
				set_CompanyIds.add(objInvoice.Company_Id__c);
			}
		}

		// account query with sub query of payment incvoices with minimum first day of invoice month
		for (Account objAccnt : [
			SELECT
				Id,
				ZP_Company_ID__c,
				First_Day_of_Initial_Invoice_Month__c,
				First_Month_Invoice_Generated__c,
				Name,
				Upsell_Opp_Open__c,
				Joined_Date_Panda__c,
				(
					SELECT Id, Period_End_Date__c, First_Day_of_Invoice_Month__c
					FROM Payment_Invoices__r
					WHERE Needs_Refund__c = FALSE AND First_Day_of_Invoice_Month__c != NULL
					ORDER BY First_Day_of_Invoice_Month__c ASC
					LIMIT 1
				)
			FROM Account
			WHERE ZP_Company_ID__c IN :set_CompanyIds
		]) {
			map_AccountsWithFirstInvoice.put(objAccnt.Id, objAccnt);
		}
	}

	/**
	 * @description Before Context : Create data collections to be used across functions
	 * @author Praveen Sethu
	 * @param map_OldInvoices Trigger.new
	 * @param list_NewInvoices  Trigger.oldMap
	 * @return Map of Company ID to Account
	 */
	private void createCollectionsBefore(List<Payment_Invoice__c> list_NewInvoices, Map<Id, Payment_Invoice__c> map_OldInvoices) {
		Set<String> set_CompanyIds = new Set<String>{};
		// Create data collections
		for (Payment_Invoice__c objInvoice : list_NewInvoices) {
			if (String.isNotBlank(objInvoice.Company_Id__c)) {
				set_CompanyIds.add(objInvoice.Company_Id__c);
			}
		}

		for (Account objAccnt : [
			SELECT
				Id,
				ZP_Company_ID__c,
				Name,
				First_Month_Invoice_Generated__c,
				Upsell_Opp_Open__c,
				Joined_Date_Panda__c,
				(SELECT Id, Period_End_Date__c FROM Payment_Invoices__r WHERE Paid__c = TRUE ORDER BY Period_End_Date__c DESC LIMIT 1),
				(SELECT Id FROM Opportunities WHERE RecordTypeId = :OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			FROM Account
			WHERE ZP_Company_ID__c IN :set_CompanyIds
		]) {
			map_CompanyIdToAccount.put(objAccnt.ZP_Company_ID__c, objAccnt);
		}

		for (Pricebook2 objPricebook : [SELECT Id, Name, Rate_Plan_Id__c FROM Pricebook2 WHERE Rate_Plan_Id__c != NULL AND IsActive = TRUE]) {
			map_RatePlanToPrices.put(objPricebook.Rate_Plan_Id__c, objPricebook.Name);
		}
	}

	/**
	 * @description Set Account__c lookup value on Payment_Invoice__c
	 * @author Praveen Sethu
	 * @param  objInvoice `Payment_Invoice__c` record
	 */
	private void setAccount(Payment_Invoice__c objInvoice, Map<String, Account> map_CompanyIdToAccount) {
		if (map_CompanyIdToAccount.containsKey(objInvoice.Company_Id__c)) {
			Account objAcc = map_CompanyIdToAccount.get(objInvoice.Company_Id__c);
			System.debug('objAcc:' + objAcc);
			//System.debug('objAcc.Opportunities:' + objAcc.Opportunities.isEmpty());
			objInvoice.Account__c = objAcc.Id;

			if (objAcc.First_Month_Invoice_Generated__c && !objAcc.Upsell_Opp_Open__c && !objAcc.Opportunities.isEmpty()) {
				objInvoice.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
				objInvoice.Message__c = TIER_OR_ADD_ON_CHANGE_NO_TIER_UPSELL;
			} else {
				objInvoice.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				objInvoice.Message__c = null;
			}
		} else {
			objInvoice.Account__c = null;
			objInvoice.Processing_State__c = IntegrationUtils.ERROR_STATE;
			objInvoice.Message__c = COMPANY_DOES_NOT_EXIST;
		}
	}

	/**
	 * @description Maps Rate Plan Id from Zuora and sets the right Pricing on Invoice
	 * @author Praveen Sethu
	 * @param  objInvoice `Payment_Invoice__c` record
	 */
	private void setPricing(Payment_Invoice__c objInvoice) {
		if (String.isNotBlank(objInvoice.Rate_Plan_Id__c) && map_RatePlanToPrices.containsKey(objInvoice.Rate_Plan_Id__c)) {
			objInvoice.Pricing__c = map_RatePlanToPrices.get(objInvoice.Rate_Plan_Id__c);
		}
	}

	/**
	 * @description Parse start and end date and set invoice month
	 * @author Praveen Sethu
	 * @param  objInvoice `Payment_Invoice__c` record
	 */
	private void setInvoiceMonth(Payment_Invoice__c objInvoice) {
		if (objInvoice.Period_Start_Date__c != null) {
			Date dtStartDate = objInvoice.Period_Start_Date__c;
			String strYear = '' + dtStartDate.year();
			String strMonth = dtStartDate.month() < 10 ? '0' + dtStartDate.month() : '' + dtStartDate.month();
			objInvoice.For_Month__c = strYear + '-' + strMonth;
		}
	}

	/**
	 * @description Updates First Day of First Invoice Month on Account
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	private void updateFirstDayOfFirstMonth() {
		for (Account objAcc : map_AccountsWithFirstInvoice.values()) {
			if (!objAcc.Payment_Invoices__r.isEmpty()) {
				objAcc = map_AccountsToUpdate.containsKey(objAcc.Id) ? map_AccountsToUpdate.get(objAcc.Id) : objAcc;

				Payment_Invoice__c objInvoice = objAcc.Payment_Invoices__r.get(0);

				if (objInvoice.First_Day_of_Invoice_Month__c != objAcc.First_Day_of_Initial_Invoice_Month__c) {
					objAcc.First_Day_of_Initial_Invoice_Month__c = objInvoice.First_Day_of_Invoice_Month__c;
					map_AccountsToUpdate.put(objAcc.Id, objAcc);
				}
			}
		}
	}
}