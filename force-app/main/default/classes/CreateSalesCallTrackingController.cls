/**
 * Created By        :   Sanjay
 * Created Date      :   6-Nov-2020
 * Desciption        :   Controller for Console component to capture pure cloud call events and find appropriate Benefit Order
 * Test Classes      :   CreateSalesCallTrackingControllerTest
 */
public class CreateSalesCallTrackingController {
	public Sales_Call_Tracking__c objCallTracking { get; set; }
	public String strIntegrationID { get; set; }
	public User objCurrentUser { get; set; } //benefits fulfillment profile can see this page
	public Id idLoggedInUser { get; set; }
	public string strPhoneNumber { get; set; }
	public Benefit_Order__c objBO { get; set; }
	public Set<string> set_BOClosedStatus { get; set; }
	public List<Benefit_Order__c> list_OpenBenefitOrders { get; set; }
	public List<Benefit_Order__c> list_SearchedBenefitOrders { get; set; }
	public Boolean blnShowSearchedBOSection { get; set; }
	public string strCurrentPageRecord { get; set; }
	public String strCallType { get; set; }
	public Boolean blnIsAuthorizedUser { get; private set; }
	private Boolean blnContactIdentified;
	public static final String INTEGRATION_ID_PREFIX = 'hippo-%',
		CANCELLED_BO_STATUS = 'Canceled',
		CLOSEDLOST_BO_STATUS = 'Closed Lost',
		FULFILLED_BO_STATUS = 'Fulfilled',
		APPROVED_BO_STATUS = 'Approved',
		CLOSEDADMIN_BO_STATUS = 'Closed Admin',
		CALL_TYPE_OUTBOUND = 'Outbound',
		CALL_TYPE_INBOUND = 'Inbound',
		BENEFIT_ORDER = 'Benefit_Order__c';

	public CreateSalesCallTrackingController(ApexPages.StandardController controller) {
		// Get page parameters passed by NICE integration
		strPhoneNumber = apexPages.currentPage().getParameters().get('ani');
		strIntegrationID = ApexPages.currentPage().getParameters().get('_c');
		blnShowSearchedBOSection = false;
		idLoggedInUser = UserInfo.getuserId();
		objCurrentUser = GlobalQueryHelper.getUserInfoById(idLoggedInUser);
		blnIsAuthorizedUser = false;
		List<AllSmartCalling__mdt> list_mdtSmartCall = [
			SELECT MasterLabel, QualifiedApiName, Object_Name__c, Profile_Name__c, Role_Name__c
			FROM AllSmartCalling__mdt
			WHERE Object_Name__c = :BENEFIT_ORDER
		];
		if (
			list_mdtSmartCall != null &&
			!list_mdtSmartCall.isEmpty() &&
			String.isNotBlank(list_mdtSmartCall[0].Profile_Name__c) &&
			list_mdtSmartCall[0].Profile_Name__c.containsIgnoreCase(objCurrentUser.Profile.Name)
		) {
			blnIsAuthorizedUser = true;
		}

		set_BOClosedStatus = new Set<string>{ CANCELLED_BO_STATUS, CLOSEDLOST_BO_STATUS, CLOSEDADMIN_BO_STATUS, FULFILLED_BO_STATUS, APPROVED_BO_STATUS };

		objCallTracking = new Sales_Call_Tracking__c();
		if (String.isNotBlank(strIntegrationID)) {
			objCallTracking.Genesys_Integration_Id__c = strIntegrationID;
		}

		blnContactIdentified = false;
	}
	/*
	 * Search Benefit Orders based on selected Account
	 */
	public void searchForBenefitOrders() {
		list_SearchedBenefitOrders = new List<Benefit_Order__c>();

		try {
			list_SearchedBenefitOrders = [
				SELECT
					Id,
					Name,
					Account__r.Name,
					Coverage_Effective_Date__c,
					Renewal_Date__c,
					(
						SELECT ContactId
						FROM Cases__r
						WHERE Integration_Id__c != NULL AND Integration_Id__c LIKE :INTEGRATION_ID_PREFIX AND Carrier_Order__c = NULL
						LIMIT 1
					)
				FROM Benefit_Order__c
				WHERE Account__c = :objCallTracking.Account__c
			];
			if (list_SearchedBenefitOrders.size() > 1) {
				blnShowSearchedBOSection = true;
			} else if (list_SearchedBenefitOrders.size() == 1) {
				blnShowSearchedBOSection = false;
				objBO = new Benefit_Order__c();
				objBO = list_SearchedBenefitOrders.get(0);
			}
		} catch (Exception objExc) {
			ExceptionLogUtil.logException('Error', 'CreateSalesCallTrackingController', 'searchForBenefitOrders', objExc.getMessage(), objExc.getStackTraceString());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExc.getMessage()));
		}
	}
	/*
	 * On call connect event, check if incoming call number matches to any Contact and if there is any Open Benefit Order for that Contact's account
	 * Otherwise get all Open Benefit Orders owned by logged in user
	 */
	public void callEvent() {
		try {
			if (String.isNotBlank(strPhoneNumber)) {
				strPhoneNumber = strPhoneNumber.removeStart('+1');
				String phoneQueryStr = '%' + strPhoneNumber + '%';

				List<Contact> list_MatchingContacts = new List<Contact>();
				List<Benefit_Order__c> list_MatchingBenefitOrders = new List<Benefit_Order__c>();
				list_OpenBenefitOrders = new List<Benefit_Order__c>();

				// Check for contacts matching the incoming call number
				list_MatchingContacts = [SELECT Id, AccountId FROM Contact WHERE Normalized_Phone__c LIKE :phoneQueryStr];

				// Check if there are any open Benefit Orders related to the contact calling
				if (list_MatchingContacts != null && list_MatchingContacts.size() > 0) {
					objBO = new Benefit_Order__c();
					list_MatchingBenefitOrders = [
						SELECT
							Id,
							Account__c,
							Name,
							Coverage_Effective_Date__c,
							Renewal_Date__c,
							(
								SELECT ContactId
								FROM Cases__r
								WHERE Integration_Id__c != NULL AND Integration_Id__c LIKE :INTEGRATION_ID_PREFIX AND Carrier_Order__c = NULL
								LIMIT 1
							)
						FROM Benefit_Order__c
						WHERE Account__c = :list_MatchingContacts.get(0).AccountId AND Order_Status__c NOT IN :set_BOClosedStatus
						ORDER BY Coverage_Effective_Date__c DESC, Renewal_Date__c DESC
					];
					if (!list_MatchingBenefitOrders.isEmpty()) {
						blnContactIdentified = true;
						objBO = list_MatchingBenefitOrders.get(0);
					}
				}

				// If there are no matching records found then show all the open Benefit Orders that are owned  by the advocate
				if (list_MatchingBenefitOrders.size() == 0) {
					list_OpenBenefitOrders = [
						SELECT
							ID,
							Name,
							Account__r.Name,
							Coverage_Effective_Date__c,
							Renewal_Date__c,
							(
								SELECT ContactId
								FROM Cases__r
								WHERE Integration_Id__c != NULL AND Integration_Id__c LIKE :INTEGRATION_ID_PREFIX AND Carrier_Order__c = NULL
								LIMIT 1
							)
						FROM Benefit_Order__c
						WHERE OwnerId = :idLoggedInUser AND Order_Status__c NOT IN :set_BOClosedStatus
						ORDER BY Name ASC, Coverage_Effective_Date__c DESC, Renewal_Date__c DESC
					];
				}
			}
		} catch (Exception objExc) {
			ExceptionLogUtil.logException('Error', 'CreateSalesCallTrackingController', 'callEvent', objExc.getMessage(), objExc.getStackTraceString());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExc.getMessage()));
		}
	}
	/*
	 * On Call Disconnect Event, create a Sales Call tracking record or update the existing one.
	 */
	public void onCallEnd() {
		try {
			if (String.isNotBlank(strIntegrationId) && String.isNotBlank(strCallType)) {
				Sales_Call_Tracking__c objSalesCallTracking = new Sales_Call_Tracking__c(
					Genesys_Integration_Id__c = strIntegrationId,
					Owner__c = idLoggedInUser,
					Call_End_Time__c = System.now(),
					Is_PureCloud_Call__c = true,
					Call_Type__c = strCallType
				);

				String strActiveRecordId = ApexPages.currentPage().getParameters().get('activeRecordId');
				if (
					CALL_TYPE_OUTBOUND.equalsIgnoreCase(strCallType) &&
					String.isNotBlank(strActiveRecordId) &&
					BENEFIT_ORDER.equalsIgnoreCase(Id.valueOf(strActiveRecordId).getSObjectType().getDescribe().getName())
				) {
					objSalesCallTracking.Benefit_Order__c = strActiveRecordId;
				} else if (CALL_TYPE_INBOUND.equalsIgnoreCase(strCallType) && blnContactIdentified == true && objBO != null) {
					objSalesCallTracking.Benefit_Order__c = objBO.Id;
				}

				if (String.isNotBlank(objSalesCallTracking.Benefit_Order__c)) {
					List<Benefit_Order__c> list_BenefitOrders = [
						SELECT Id, RecordType.Name
						FROM Benefit_Order__c
						WHERE Id = :objSalesCallTracking.Benefit_Order__c
						LIMIT 1
					];

					if (!list_BenefitOrders.isEmpty()) {
						objSalesCallTracking.RecordTypeId = SalesCallTrackingUtil.BO_RT_NAME_WITH_SALES_CALL_TRACKING_RT_IDS?.get(list_BenefitOrders[0].RecordType.Name);
					}

					List<Case> list_CustomerCase = [
						SELECT Id
						FROM Case
						WHERE Integration_Id__c != NULL AND Integration_Id__c LIKE :INTEGRATION_ID_PREFIX AND Benefit_Order__c = :objSalesCallTracking.Benefit_Order__c AND Carrier_Order__c = NULL
						LIMIT 1
					];
					if (list_CustomerCase != null && !list_CustomerCase.isEmpty()) {
						objSalesCallTracking.Case__c = list_CustomerCase[0].Id;
					}
				}

				upsert objSalesCallTracking Genesys_Integration_Id__c;
			}
		} catch (Exception objExc) {
			ExceptionLogUtil.logException('Error', 'CreateSalesCallTrackingController', 'onCallEnd', objExc.getMessage(), objExc.getStackTraceString());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExc.getMessage()));
		}
	}
}