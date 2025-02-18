/**
 * @description  This class contains subscription preferences related logic
 * to be used as as a common utility for preference related activities on Account/Contact/Lead
 * @author       Aviinandaan Dutta
 * @date         04-24-2023
 * @see          SubscriptionCenterUtilTest
 **/

public class SubscriptionCenterUtil implements Queueable, Database.AllowsCallouts {
	public static final String MARKETING_EMAIL_OPT_OUT = 'Marketing Email Opt Out';
	public static final String BIZ_NEWSLETTER = 'Biz Newsletter';
	public static final String FEATURE_ANNOUNCEMENTS = 'Feature Announcements';
	public static final String BENEFIT_ANNOUNCEMENTS = 'Benefit Announcements';
	public static final String FINANCIAL_PRODUCTS = 'Financial Products';
	public static final String DEALS_PROMOS = 'Deals and Promos';
	public static final String REFERRALS = 'Referrals';
	public static final String CSAT = 'CSAT';
	public static final String SURVEY = 'Survey';
	public static final String UX_RESEARCH = 'UX Research';
	public static final String OUTREACH = 'Outreach';
	public static final String ACCOUNT_PARTNER_NEWS = 'Account Partner News';
	public static final List<String> LIST_ANNOUNCEMENTS = new List<String>{ BIZ_NEWSLETTER, FEATURE_ANNOUNCEMENTS, BENEFIT_ANNOUNCEMENTS, FINANCIAL_PRODUCTS };
	public static final List<String> LIST_DEALS_REFERRALS = new List<String>{ DEALS_PROMOS, REFERRALS };
	public static final List<String> LIST_CSAT = new List<String>{ CSAT, SURVEY, UX_RESEARCH };
	public static final String INTEGRATION_USERS = System.Label.Integration_Users;
	public static final String SUBSCRIPTION_PREFERENCE = 'Customer_Subscriptions__c';

	public static Map<Id, String> map_subscriptionCalloutRequests = new Map<Id, String>();
	public Map<Id, String> map_subscriptionCalloutRequestsRemaining = new Map<Id, String>();
	public SubscriptionCenterUtil(Map<Id, String> map_subscriptionCalloutRequestsRemaining) {
		this.map_subscriptionCalloutRequestsRemaining = map_subscriptionCalloutRequestsRemaining;
	}

	/**
	 * @Description : Utility method to generate applicable set of subscriptions based on selections made
	 * @Parm        : Set of current subscription values, Set of prior subscription values
	 * @Return      : Void
	 **/
	public static String getApplicableSubscriptionPreferences(Set<String> set_newSubscriptionValues, Set<String> set_oldSubscriptionValues, Boolean blnIsInsert) {
		String strDependentSubscriptions = '';
		if (blnIsInsert && set_newSubscriptionValues.isEmpty()) {
			// Include all values on record insert (Ignore values marked as opt out)
			List<String> list_DefaultPreferences = new List<String>();
			for (Subscription_Category__mdt objCategory : Subscription_Category__mdt.getAll().values()) {
				if (objCategory.Is_Opt_Out__c == false && String.isNotBlank(objCategory.Subscription_Values__c)) {
					list_DefaultPreferences.addAll(objCategory.Subscription_Values__c.split(','));
				}
			}
			return String.join(list_DefaultPreferences, ';');
		}
		// insert scenario completed - all below code will be used when contact or lead is updated

		// If subscription values contain opt out, return opt out value
		// Build opt out set of strings
		List<String> list_OptOutValues = new List<String>();
		for (Subscription_Category__mdt objCategory : Subscription_Category__mdt.getAll().values()) {
			if (objCategory.Is_Opt_Out__c == true && String.isNotBlank(objCategory.Subscription_Values__c)) {
				list_OptOutValues.addAll(objCategory.Subscription_Values__c.split(','));
			}
		}

		// If any opt out value is found in the picklist, return the opt out value
		for (String strSubscription : set_newSubscriptionValues) {
			if (list_OptOutValues.contains(strSubscription)) {
				return strSubscription;
			}
		}

		// Build 2 maps (1 is a map of subscription category to picklist & 2 is a map of picklist value to subscription category)
		Map<String, String> map_SubscriptionCategories = new Map<String, String>();
		Map<String, String> map_SubscriptionValues = new Map<String, String>();
		for (Subscription_Category__mdt objCategory : Subscription_Category__mdt.getAll().values()) {
			if (String.isNotBlank(objCategory.Subscription_Values__c)) {
				map_SubscriptionCategories.put(objCategory.Category__c, objCategory.Subscription_Values__c);

				for (String strSubscription : objCategory.Subscription_Values__c.split(',')) {
					map_SubscriptionValues.put(strSubscription, objCategory.Category__c);
				}
			}
		}

		Set<String> set_SubscriptionsToReturn = new Set<String>();
		Set<String> set_CategoriesToSkip = new Set<String>();

		for (String strOldSubscription : set_oldSubscriptionValues) {
			if (!set_newSubscriptionValues.contains(strOldSubscription)) {
				// if a subscription value is present in the old set and not present in the new set - the subscription value is getting removed
				String strCategory = map_SubscriptionValues.get(strOldSubscription);
				if (String.isNotBlank(strCategory)) {
					set_CategoriesToSkip.add(strCategory);
				}
			}
		}

		// Build the subscription value to return
		for (String strSubscription : set_newSubscriptionValues) {
			// if the subscription is part of a category, include all values from the category
			if (map_SubscriptionValues.containsKey(strSubscription)) {
				String strCategory = map_SubscriptionValues.get(strSubscription);
				if (set_CategoriesToSkip.contains(strCategory)) {
					continue;
				}
				if (map_SubscriptionCategories.containsKey(strCategory)) {
					// Add values from the category
					for (String strCategoryValue : map_SubscriptionCategories.get(strCategory).split(',')) {
						set_SubscriptionsToReturn.add(strCategoryValue);
					}
				}
			}
			set_SubscriptionsToReturn.add(strSubscription);
		}

		// Convert from set of strings to list of strings
		List<String> list_SubscriptionsToReturn = new List<String>();
		list_SubscriptionsToReturn.addAll(set_SubscriptionsToReturn);

		return String.join(list_SubscriptionsToReturn, ';');
	}

	/**
	 * @Description : Utility method to generate callout requests and enque job to perform the callouts
	 * @Parm        : Generic list of records that need to be called out , Type of records
	 * @Return      : N/A
	 **/
	public static void calloutSubscription(List<sObject> list_objectsToCallout, Schema.SObjectType objObjectType) {
		Boolean blnContactRequest = false;
		List<Contact> list_contactsToCallout = new List<Contact>();
		Map<String, Set<String>> map_zpUserAndUserRole = new Map<String, Set<String>>();

		// build a map pf user Id and user role Id only if the context object is Contact
		if (objObjectType == Schema.Contact.getSObjectType()) {
			blnContactRequest = true;
			list_contactsToCallout = (List<Contact>) list_objectsToCallout;
			for (Contact objContact : list_contactsToCallout) {
				if (String.isNotBlank(objContact.ZP_User_Id__c)) {
					map_zpUserAndUserRole.put(objContact.ZP_User_Id__c, null);
				}
			}
			for (ZP_User_Role__c objUserRole : [SELECT Id__c, User_Id__c FROM ZP_User_Role__c WHERE User_Id__c IN :map_zpUserAndUserRole.keySet()]) {
				if (map_zpUserAndUserRole.containsKey(objUserRole.User_Id__c) && map_zpUserAndUserRole.get(objUserRole.User_Id__c) != null) {
					map_zpUserAndUserRole.get(objUserRole.User_Id__c).add(objUserRole.Id__c);
				} else {
					map_zpUserAndUserRole.put(objUserRole.User_Id__c, new Set<String>{ objUserRole.Id__c });
				}
			}
		}
		// Build a map of subscription category and picklist values
		Map<String, Subscription_Category__mdt> map_SubscriptionCategories = new Map<String, Subscription_Category__mdt>();
		for (Subscription_Category__mdt objCategory : Subscription_Category__mdt.getAll().values()) {
			map_SubscriptionCategories.put(objCategory.Category__c, objCategory);
		}
		for (SObject objSObject : list_objectsToCallout) {
			// Build list of requests to serialize - Each request is for each targeted system
			List<Map<String, Object>> list_Requests = new List<Map<String, Object>>();

			// Iterate over all targeted systems and build JSON array to send subscription data to each target system
			for (Subscription_Target_System__mdt objTargetSystem : Subscription_Target_System__mdt.getAll().values()) {
				// only process target systems with object name as Contact
				if (objTargetSystem.Object__c != objObjectType.getDescribe().getLabel()) {
					continue;
				}

				// Create new request object for each targeted system
				Map<String, Object> objRequest = new Map<String, Object>();
				objRequest.put('target', objTargetSystem.Target_System__c.toLowerCase());

				// Build a boolean flag to indicate if contact has at least one user role
				Boolean blnUserRoleAvailable = false;

				// Get user role Ids only if related object is Contact
				if (blnContactRequest) {
					blnUserRoleAvailable =
						map_zpUserAndUserRole.containsKey((String) objSObject.get('ZP_User_Id__c')) &&
						map_zpUserAndUserRole.get((String) objSObject.get('ZP_User_Id__c')) != null &&
						!map_zpUserAndUserRole.get((String) objSObject.get('ZP_User_Id__c')).isEmpty();
				}

				Boolean blnUniqueIdentifierFound = false;
				//  If unique identifer on target system is user role, make sure contact has user roles
				if (blnUserRoleAvailable && objTargetSystem.Unique_Identifier__c == 'User Role Id') {
					objRequest.put('zpUserRoleIds', new List<String>(map_zpUserAndUserRole.get((String) objSObject.get('ZP_User_Id__c'))));
					blnUniqueIdentifierFound = true;
				} else if (String.isNotBlank(objTargetSystem.Field_Name__c)) {
					String strValue = (String) objSObject.get(objTargetSystem.Field_Name__c);
					if (String.isNotBlank(strValue)) {
						objRequest.put(objTargetSystem.Field_Name__c.toLowerCase(), strValue);
						blnUniqueIdentifierFound = true;
					}
				}

				// if the unique identifier field on contact is not available, skip the targeted system
				if (!blnUniqueIdentifierFound) {
					continue;
				}

				Boolean blnCategoryAvailable = false;
				if (String.isNotBlank((String) objSObject.get(SUBSCRIPTION_PREFERENCE)) && String.isNotBlank(objTargetSystem.Interested_Categories__c)) {
					// Iterate over each interested category
					for (String strEachCategory : objTargetSystem.Interested_Categories__c.split(',')) {
						// get the subscription category record from the Map
						Subscription_Category__mdt objCategory = map_SubscriptionCategories.get(strEachCategory);
						// if the category is available and has an integration field, add to request
						if (objCategory != null && String.isNotBlank(objCategory.Integration_Field__c) && String.isNotBlank(objCategory.Subscription_Values__c)) {
							blnCategoryAvailable = true;
							Boolean blnValue = false;
							// get subscription picklist values from each category
							List<String> list_Subscriptions = objCategory.Subscription_Values__c.split(',');
							// Iterate over each subscription field on Contact and check if its available in the subscription list mapped to each category
							for (String strSubscription : String.valueOf(objSObject.get(SUBSCRIPTION_PREFERENCE)).split(';')) {
								if (list_Subscriptions.contains(strSubscription.trim())) {
									blnValue = true;
								}
							}
							objRequest.put(objCategory.Integration_Field__c, blnValue);
						}
					}
				}
				// if at least one category is available, add to list of requests to be sent to Mulesoft.
				if (blnCategoryAvailable) {
					list_Requests.add(objRequest);
				}
			}
			System.debug('JSON request ' + JSON.serializePretty(list_Requests));
			if (!list_Requests.isEmpty()) {
				map_subscriptionCalloutRequests.put((Id) objSObject.get('Id'), JSON.serializePretty(list_Requests));
			}
		}

		if (!map_subscriptionCalloutRequests.isEmpty()) {
			Id idQueueJobId = System.enqueueJob(new SubscriptionCenterUtil(map_subscriptionCalloutRequests));
		}
	}

	/**
	 * @Description : Execute method of queable interface as entry point of queued job.
	 * 				  It performs the callouts within allowed limit and chains new job if there are remaining callouts
	 * @Parm        : An instance of a queable context
	 * @Return      : N/A
	 **/
	public void execute(QueueableContext context) {
		map_subscriptionCalloutRequestsRemaining = performCallout(map_subscriptionCalloutRequestsRemaining);
		if (!map_subscriptionCalloutRequestsRemaining.isEmpty() && !Test.isRunningTest()) {
			Id idQueueJobId = System.enqueueJob(new SubscriptionCenterUtil(map_subscriptionCalloutRequestsRemaining));
		}
	}

	/**
	 * @Description : Helper method to perform the callouts.
	 * 				  Callouts are made within allowed limit and the remaining requests are returned to be handed over to subsequent job
	 * @Parm        : Map of recordId and corresponding request body
	 * @Return      : N/A
	 **/
	public static Map<Id, String> performCallout(Map<Id, String> map_subscriptionCalloutRequestsToProcess) {
		Map<Id, String> map_requestsRemaining = new Map<Id, String>();
		for (Id idContactId : map_subscriptionCalloutRequestsToProcess.keySet()) {
			if (Limits.getLimitCallouts() > 0) {
				HttpRequest objRequest = new HttpRequest();
				objRequest.setEndpoint('callout:Subscription_API_Mulesoft');
				objRequest.setMethod('PATCH');
				objRequest.setBody(map_subscriptionCalloutRequestsToProcess.get(idContactId));
				objRequest.setHeader('Content-Type', 'application/json');
				HTTPResponse objResponse = new HTTPResponse();
				Http http = new Http();
				objResponse = http.send(objRequest);
				if (Test.isRunningTest()) {
					return new Map<Id, String>{ idContactId => String.valueOf(objResponse.getStatusCode()) };
				}
				if (objResponse.getStatusCode() == 200) {
				} else {
					Map<String, object> map_responseBody = new Map<String, object>();
					if (String.isNotBlank(objResponse.getBody())) {
						map_responseBody = (Map<String, object>) JSON.deserializeUntyped(objResponse.getBody());
					}
					String message = '';
					if (map_responseBody.containsKey('error')) {
						message = String.valueOf(map_responseBody.get('error'));
					}
					ExceptionLogUtil.logExceptionWithId('SubscriptionCenterUtil', 'performCallout', 'Callout failed :: ' + message, '', new Set<String>{ idContactId });
				}
			} else {
				map_requestsRemaining.put(idContactId, map_subscriptionCalloutRequestsToProcess.get(idContactId));
			}
		}
		return map_requestsRemaining;
	}

	/**
	 * @description Inner class to implement mock test of callouts
	 **/
	public class HttpClientMockResponse implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse mockResponse = new HttpResponse();
			mockResponse.setStatusCode(200);
			return mockResponse;
		}
	}
}