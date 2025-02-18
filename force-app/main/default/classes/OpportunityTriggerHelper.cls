/**
 * @description Opportunity Trigger Logic
 * @author Sourav Mitra
 * @since 10/07/2020
 * @see OpportunityTriggerHelperTest
 * @see OpportunityTriggerHandlerTest
 * @see OpportunityTriggerHandler
 * @group Opportunity
 */
public without sharing class OpportunityTriggerHelper {
	public static boolean skipTrigger = false;
	//Added by AKS dated 5th Jan 21 to populate Region based on UW sate
	public static Map<String, String> map_StateNameAbbreviations = OpportunityUtil.getStateNameAbbreviations(); // * TODO: Delete this class variable and reference OppUtil directly below
	public static List<Region_Setting__mdt> list_RegionSettings = OpportunityUtil.getRegionSettings(); // * TODO: Delete this variable and reference OppUtil directly below
	public static String RECERTIFICATION_TEAM_QUEUE_ID = GlobalQueryHelper.getQueueIdByName('Recertification Team');
	public static Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults() != null ? Tier_Config__c.getOrgDefaults() : new Tier_Config__c();
	// Get New Price & Effective Date From Custom Label
	Decimal decNewBYOBPrice = Decimal.valueOf(System.Label.BYB_New_Price);
	Date dtBYOBEffectiveDate = Date.parse(System.Label.BYB_New_Price_Effective_At);
	public static Boolean blnTierUpsellOpp = false;
	public static final String ROLE_ACCOUNTANT = 'Accountant';
	public static final String ROLE_EMPLOYEE = 'Employee';
	public static final String UPSELL_OPP_SUFFIX = ' - Cross sell EOR';
	public static final String TIER_UPSELL_OPP_SUFFIX = ' - Tier Upsell';
	public static final String TAXCREDITS_TYPE_NEW_BUSINESS = 'New Business';
	public static final String TAXCREDITS_TYPE_PARTNERSHIP = 'Partnership';
	public static final String TAXCREDITS_PREFIX_RD = 'R&D';
	//Lirik - Migration for BOR to BO -- Start ---
	// make the private variable to public (populated from BenefitOrderHelperFunctions class)

	public static Map<Id, Benefit_Order__c> benefitOrderMap = new Map<Id, Benefit_Order__c>();
	public static final String INTEGRATION_USERS = System.Label.Integration_Users;
	public static Map<Id, List<UserAccountTeamMember>> map_UserAccountTeamMembers = new Map<Id, List<UserAccountTeamMember>>();
	public static final String HI_SALES_ALL_ROLES = Test.isRunningTest() ? 'Integration Users' : System.Label.Benefits_Roles;
	public static Set<Id> set_RenewalOppIds = new Set<Id>();
	public static Set<Id> set_OpptyIdsClosed = new Set<Id>();
	public static final String CUSTOMER_CONTACT = 'Customer Contact';
	public static Map<Id, Map<String, Set<Id>>> map_contactRolesByOppId = new Map<Id, Map<String, Set<Id>>>();
	public static final Integer INTERNATIONAL_PAYROLL_CLOSE_DATE_DAYS = Integer.valueOf(System.Label.International_Payroll_Close_Date_Days);
	public static List<ID> list_OpportunitiesToCreateBOBYB = new List<ID>();

	/**
	 * @description populate the Opportunity Stage
	 * <br>This method is only called from BenefitOrderHelperFunctions, not in an Opportunity trigger context
	 * @author Sourav Mitra
	 * @param  objOpp               Opportunity record
	 * @param  strTTFRecordTypeName Transition to Fulfillment Record TYpe Name (TODO: use DeveloperName)
	 * @param  listUpdateOpps       Opportunities to Update?
	 * @param  listBusinessHours    All business hours
	 */
	public static void populateOpportunityStage(Opportunity objOpp, String strTTFRecordTypeName, List<Opportunity> listUpdateOpps, List<BusinessHours> listBusinessHours) {
		Set<String> set_TTFRecTyps = new Set<String>{ 'Benefits New Plan', 'Benefits Change', 'Benefits Renewal', 'Benefits BYB' };
		if (set_TTFRecTyps.contains(strTTFRecordTypeName)) {
			objOpp.Send_Order_TimeStamp__c = System.now();
			Decimal decSLAqualHr = TransitiontoFulfilmentTriggerHelper.calculateBusinessHoursOpp(listBusinessHours, objOpp);
			String strOppStageName = 'Closed Won';
			if (strTTFRecordTypeName == 'Benefits New Plan' && objOpp.Account.Joined_Date_Panda__c == null) {
				strOppStageName = 'Pending PR';
			}
			Date dtClose = System.today();
			if (strTTFRecordTypeName == 'Benefits New Plan' && (strOppStageName == 'Closed Won' || strOppStageName == 'Pending PR')) {
				if (objOpp.Verifying_Eligibility_Start__c != null) {
					dtClose = Date.valueOf(objOpp.Verifying_Eligibility_Start__c);
				}
			} else {
				if (objOpp.Signing_Forms_Completed_Timestamp__c != null) {
					dtClose = Date.valueOf(objOpp.Signing_Forms_Completed_Timestamp__c);
				}
			}

			listUpdateOpps.add(
				new Opportunity(
					Id = objOpp.Id,
					Order_Generated__c = true,
					Transition_To_Fulfillment_Created__c = true,
					StageName = strOppStageName,
					Sales_Time_To_Handoff__c = decSLAqualHr,
					CloseDate = dtClose,
					Send_Order_TimeStamp__c = objOpp.Send_Order_TimeStamp__c
				)
			);
		}
	}

	@future
	public static void syncOpptyWithPaymentInvoiceFuture(Set<Id> oppIdSet) {
		//syncOpptyWithPaymentInvoice(oppIdSet);
		OpportunityHelper.syncPaymentInvoiceValuesToOppty(oppIdSet);
	}

	public static void syncOpptyWithPaymentInvoice(Set<Id> set_OppIds) {
		// Variable Declaration
		Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();
		List<OpportunityLineItem> list_OppLineItemsToDelete = new List<OpportunityLineItem>();
		List<OpportunityLineItem> list_OppLineItemsToUpsert = new List<OpportunityLineItem>();
		Boolean blnPricingChanged;
		Map<String, Pricebook2> map_Pricebooks = PricebookQueryHelper.getActivePricebooksMap();

		// query all pricebook entries
		Set<String> set_Products = new Set<String>{ OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE, OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR, OpportunityUtil.INTERNATIONAL_CONTRACTOR_ADD_ON_PRODUCT };
		for (String strProductName : PricebookQueryHelper.payrollProductNameSet) {
			set_Products.add(strProductName);
		}

		PricebookQueryHelper.getPriceBookEntryRecords(set_Products);

		for (Opportunity objOpp : [
			SELECT
				Id,
				NumberOfEmployees__c,
				Number_of_Contractors__c,
				AccountId,
				Pricebook2Id,
				Pricebook2.Name,
				Additional_Opportunity_Services__c,
				International_Contractors__c,
				International_Employees__c,
				Payment_Invoice__r.Pricing__c,
				Payment_Invoice__r.Employee_Count__c,
				Payment_Invoice__r.Contractor_Count__c,
				toLabel(Payment_Invoice__r.Additional_Invoiced_Services__c),
				Payment_Invoice__r.Payment_Plan_Name__c,
				Payment_Invoice__r.International_Contractors__c,
				Payment_Invoice__r.International_Employees__c,
				Payment_Invoice__r.Priority_Support__c,
				(SELECT Id, Quantity, Discount, Product2.Name, OpportunityId, PricebookEntry.Pricebook2Id, PricebookEntryId FROM OpportunityLineItems)
			FROM Opportunity
			WHERE Id IN :set_OppIds
		]) {
			blnPricingChanged = false;
			// Check to see if the pricing on the invoice is different then the opportunity
			String strPricing = String.isNotBlank(objOpp.Payment_Invoice__r.Pricing__c) ? objOpp.Payment_Invoice__r.Pricing__c : objOpp.Payment_Invoice__r.Payment_Plan_Name__c;
			if (String.isNotBlank(strPricing) && map_Pricebooks.containsKey(strPricing) && objOpp.Pricebook2.Name != strPricing) {
				blnPricingChanged = true;
				objOpp.Pricebook2Id = map_Pricebooks.get(strPricing).Id;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// get opportunity pricebook
			Pricebook2 objPriceBook = OpportunityUtil.getPriceBookById(objOpp.Pricebook2Id);

			// sync additional services between payment invoice and opportunity
			if (objOpp.Additional_Opportunity_Services__c != objOpp.Payment_Invoice__r.Additional_Invoiced_Services__c) {
				objOpp.Additional_Opportunity_Services__c = objOpp.Payment_Invoice__r.Additional_Invoiced_Services__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// sync number of international contractors between invoice and opportunity
			if (objOpp.International_Contractors__c != objOpp.Payment_Invoice__r.International_Contractors__c) {
				objOpp.International_Contractors__c = objOpp.Payment_Invoice__r.International_Contractors__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// sync number of international employees between invoice and opportunity
			if (objOpp.International_Employees__c != objOpp.Payment_Invoice__r.International_Employees__c) {
				objOpp.International_Employees__c = objOpp.Payment_Invoice__r.International_Employees__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// sync number of employees between invoice and opportunity
			if (objOpp.NumberOfEmployees__c != objOpp.Payment_Invoice__r.Employee_Count__c) {
				objOpp.NumberOfEmployees__c = objOpp.Payment_Invoice__r.Employee_Count__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// sync number of contracrors between invoice and opportunity
			if (objOpp.Number_of_Contractors__c != objOpp.Payment_Invoice__r.Contractor_Count__c) {
				objOpp.Number_of_Contractors__c = objOpp.Payment_Invoice__r.Contractor_Count__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// Create map of Product Names to Opportunity Line Items
			Map<String, OpportunityLineItem> map_ProductNameToOppLineItem = new Map<String, OpportunityLineItem>();
			for (OpportunityLineItem objOppLineItem : objOpp.OpportunityLineItems) {
				map_ProductNameToOppLineItem.put(objOppLineItem.Product2.Name, objOppLineItem);
			}

			// if pricing changes, delete all existing opportunity line items
			if (blnPricingChanged) {
				list_OppLineItemsToDelete.addAll(objOpp.OpportunityLineItems);
			}

			// create list of additional services
			String strAdditionalOpportunityServices = String.isBlank(objOpp.Additional_Opportunity_Services__c) ? '' : objOpp.Additional_Opportunity_Services__c;
			List<String> list_AdditionalServices = strAdditionalOpportunityServices.split(';');

			// iterate through each pricebook entry of the pricebook
			for (PricebookEntry objPBE : objPriceBook.PriceBookEntries) {
				// get each product
				String strProdName = objPBE.Product2?.Name;
				String strProductType = objPBE.Product2?.Product_Type__c;
				String strProductCategory = objPBE.Product2?.Product_Category__c;

				// product name and product category are required
				if (String.isNotBlank(strProdName) && String.isNotBlank(strProductType)) {
					// Decide quantity based on product type
					Decimal decQuantity = 0;
					if (strProductType == OpportunityUtil.PRODUCT_TYPE_MONTHLY) {
						decQuantity = 1;
					} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_EMPLOYEES) {
						decQuantity = objOpp.NumberOfEmployees__c != null && objOpp.NumberOfEmployees__c > 0 ? objOpp.NumberOfEmployees__c : 0;
					} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_CONTRACTORS) {
						decQuantity = objOpp.Number_of_Contractors__c != null && objOpp.Number_of_Contractors__c > 0 ? objOpp.Number_of_Contractors__c : 0;
					} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_INTERNATIONAL_CONTRACTORS) {
						decQuantity = objOpp.International_Contractors__c != null && objOpp.International_Contractors__c > 0 ? objOpp.International_Contractors__c : 0;
					} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_INTERNATIONAL_EMPLOYESS) {
						decQuantity = objOpp.International_Employees__c != null && objOpp.International_Employees__c > 0 ? objOpp.International_Employees__c : 0;
					}

					if (strProductCategory == OpportunityUtil.PRODUCT_CATEGORY_PAYROLL) {
						// if product category is payroll, create/update opportunity line item
						syncPayrollOppLineItemWithPaymentInvoice(
							strProdName,
							strProductType,
							strProductCategory,
							decQuantity,
							objPBE,
							objOpp,
							blnPricingChanged,
							map_ProductNameToOppLineItem,
							list_OppLineItemsToUpsert,
							list_OppLineItemsToDelete
						);
					} else if (String.isNotBlank(strProductCategory)) {
						// if product category is in additional services, create/update opportunity line item
						if (list_AdditionalServices.contains(strProductCategory)) {
							syncPayrollOppLineItemWithPaymentInvoice(
								strProdName,
								strProductType,
								strProductCategory,
								decQuantity,
								objPBE,
								objOpp,
								blnPricingChanged,
								map_ProductNameToOppLineItem,
								list_OppLineItemsToUpsert,
								list_OppLineItemsToDelete
							);
						} else {
							// if product category is not in additional services, delete opportunity line item
							if (map_ProductNameToOppLineItem.containsKey(strProdName) && !blnPricingChanged) {
								list_OppLineItemsToDelete.add(map_ProductNameToOppLineItem.get(strProdName));
							}
						}
					}
				}
			}
		}
		// Skipping Opportunity Trigger
		TriggerHandler.bypass('OpportunityTriggerHandler');
		if (!list_OppLineItemsToDelete.isEmpty()) {
			delete list_OppLineItemsToDelete;
		}

		if (!map_OpptysToUpdate.isEmpty()) {
			update map_OpptysToUpdate.values();
		}

		if (!list_OppLineItemsToUpsert.isEmpty()) {
			upsert list_OppLineItemsToUpsert;
		}
		TriggerHandler.clearBypass('OpportunityTriggerHandler');
	}

	/**
	 * Code for building Line Items during invoicing
	 * @author Unknown
	 * @param  strProductName               Method only checks 'Company','Contractor','Active Employee'
	 * @param  objOpp                       The parent Opportunity
	 * @param  blnPricingChanged            Has the pricing changed?
	 * @param  map_ProductNameToOppLineItem OppLineItems by Product Name
	 * @param  list_OppLineItemsToUpsert    running list of OLIs to upsert
	 * @param  list_OppLineItemsToDelete    running list of OLIs to delete
	 */
	public static void syncPayrollOppLineItemWithPaymentInvoice(
		String strProductName,
		String strProductType,
		String strProductCategory,
		Decimal decQuantity,
		PricebookEntry objPricebookEntry,
		Opportunity objOpp,
		Boolean blnPricingChanged,
		Map<String, OpportunityLineItem> map_ProductNameToOppLineItem,
		List<OpportunityLineItem> list_OppLineItemsToUpsert,
		List<OpportunityLineItem> list_OppLineItemsToDelete
	) {
		OpportunityLineItem objOppLineItem = new OpportunityLineItem(OpportunityId = objOpp.Id);
		Boolean blnProductLineExists = false;

		// Grab Opportunity Line Item if it exists
		if (map_ProductNameToOppLineItem.containsKey(strProductName)) {
			blnProductLineExists = true;
			objOppLineItem = map_ProductNameToOppLineItem.get(strProductName);
		}
		if (strProductCategory == 'Payroll' && strProductType == 'Monthly') {
			if (!blnProductLineExists) {
				list_OppLineItemsToUpsert.add(buildOppLineItem(objOpp.Id, objPricebookEntry, decQuantity));
			} else {
				if (blnPricingChanged) {
					list_OppLineItemsToUpsert.add(buildOppLineItem(objOpp.Id, objPricebookEntry, decQuantity));
				} else {
					if (objOppLineItem.Quantity != decQuantity) {
						objOppLineItem.Quantity = decQuantity;
						objOppLineItem.UnitPrice = objPricebookEntry.UnitPrice;
					}
					list_OppLineItemsToUpsert.add(objOppLineItem);
				}
			}
		} else {
			// Opportunity EE/Con Quantity = 0 AND Opportunity Line Exists -> Delete Line
			if (decQuantity == 0 && blnProductLineExists) {
				list_OppLineItemsToDelete.add(objOppLineItem);
			}
			// Invoice EE/Con Quantity != 0 OR Opportunity EE/Con Quantity != 0 AND Opportunity Line Doesnt Exist -> Create Line
			if (decQuantity > 0 && !blnProductLineExists) {
				list_OppLineItemsToUpsert.add(buildOppLineItem(objOpp.Id, objPricebookEntry, decQuantity));
			}
			// Opportunity EE/Con Quantity !0 AND Opportunity Line Exists
			if (decQuantity > 0 && blnProductLineExists) {
				if (blnPricingChanged) {
					list_OppLineItemsToUpsert.add(buildOppLineItem(objOpp.Id, objPricebookEntry, decQuantity));
				} else {
					// Opportunity Pricing Not Changed AND Quantity Different -> Update Line
					if (objOppLineItem.Quantity != decQuantity) {
						objOppLineItem.Quantity = decQuantity;
						objOppLineItem.UnitPrice = objPricebookEntry.UnitPrice;
					}
					list_OppLineItemsToUpsert.add(objOppLineItem);
				}
			}
		}
	}

	//********************* New Code ************************************************

	// All accounts in current context
	public Map<Id, Account> map_Accounts;
	// Map of accounts to update in DB
	public Map<Id, Account> map_AccountsToUpdate;
	// Map of Contacts to update in DB
	public Map<Id, Contact> map_ContactsToUpdate;
	// Map of Benefit Orders to update in DB
	public Map<Id, Benefit_Order__c> map_BenefitOrdersToUpdate;
	//Map of Tickets to be updated in the DB
	public Map<Id, Ticket__c> map_TicketsToUpdate;
	//Map of Ardius Opportunities
	public Map<Id, Opportunity> map_ArdiusOpportunities;

	// All Users
	public Map<Id, User> map_Users;

	public Map<Id, Payment_Invoice__c> map_PaymentInvoices;
	public Map<String, Partner_Referral_Source__c> map_SourceNameToPartnerReferral;
	public Map<Id, List<Zp_User_Role__c>> map_AccountIdToZPUserRoles;
	public List<OpportunityContactRole> list_TempContactRoles;
	public List<Ticket__c> list_TicketsToUpdate;
	public Map<Id, Account_Related_Tracking__c> map_AccIdToTrackingToUpsert;
	public Map<Id, Map<String, PriceBookEntry>> map_PBIdToMapOfProdNameToPBE;
	public Map<Id, List<Case>> map_OpptyIdToBenefitsCases;
	public Map<Id, List<Benefit_Order__c>> map_OpptyIdToBenefitsOrders;
	public Map<Id, List<Renewal_Survey__c>> map_OpptyIdToRenewalSurveys;
	public Map<Id, List<Opportunity_Related_Tracking__c>> map_OpptyIdToOpptyRelatedTrackings;
	public Map<Id, List<OpportunitySplit>> map_OpportunitySplit = new Map<Id, List<OpportunitySplit>>();
	public Set<Id> set_BulkMigrationIds;
	public Set<Id> set_InvoiceOpptyIds;
	public Set<Id> set_OLIToBeUpdatedIds;
	public Set<Id> set_OpptyIdPolicies;
	public Map<Id, Map<String, OpportunityLineItem>> map_OpptyIdToMapofLineItem;
	public Map<Id, List<Task>> map_OpptyIdToTasks;
	public Map<Id, Opportunity> map_OppsToBeUpdated;
	public Map<Id, List<Benefit_Order__c>> map_OpptyIdToOpenBenefitsOrders;
	public Map<Id, List<Case>> map_OpptyIdToCasesWithIntegrationId;
	public Set<Id> set_ClosedLostOppIds = new Set<Id>();
	public Set<Id> set_ReopenedOppIds = new Set<Id>();

	// Opportunity Products
	public List<OpportunityLineItem> list_OLIToBeUpserted;
	public List<OpportunityLineItem> list_OLIToBeDeleted;

	// Map of Accounts and Renewal Submission Deadline
	public Map<Id, Date> map_AccIdToDeadlineDateMap;
	// Custom field api names on Carrier/Carrier Detail
	public String strGroupVarNum1ApiName = '';
	public String strGroupVarNum2ApiName = '';

	Map<Id, Policy__c> map_OpportunityWithUWState;

	//This map contains value as : Map<ZP_Company_Id, Map<ZP_User_Id, Role>>
	public Map<String, Map<String, String>> map_CompanyIdToUserIdWithHIRole;
	//This map contains value as : Map<ZP_User_Id, ContactId>
	public Map<String, Id> map_ZPUserIdToConactId;

	public Map<String, Decimal> map_AdvisingUserIdCap = new Map<String, Decimal>();
	public static Map<String, String> map_AdvisingUserIdsWithSkillType = new Map<String, String>();
	public static Map<String, Set<String>> map_HashOfAdvisingSkillWithUsers = new Map<String, Set<String>>();
	public static Map<String, Decimal> map_AdvisingUserIdOppCount = new Map<String, Decimal>();
	public static Map<Id, Opportunity> map_RenewalOpptyToBeUpdated = new Map<Id, Opportunity>();
	public static Map<Id, Opportunity> map_MultiEINOpptyToBeUpdated = new Map<Id, Opportunity>();
	public static Set<Id> set_AccountsWithSpecialEnrollment = new Set<Id>();
	public static Map<Id, Id> map_OppToOwnerId = new Map<Id, Id>();
	public List<Ticket__c> list_RecertificationTickets;
	public List<OpportunitySplit> list_OpportunitySplitUpdate = new List<OpportunitySplit>();
	public List<OpportunitySplit> list_OpportunitySplitDelete = new List<OpportunitySplit>();
	public Map<Id, Account> map_AccountsForRouting = new Map<Id, Account>();
	public Set<Id> set_OpportunityIdsToRoute = new Set<Id>();
	public List<Opportunity> list_OpptysToInsert = new List<Opportunity>();
	public static Set<Id> set_TierUpsellAccountIdsToRoute = new Set<Id>();
	public Set<Id> set_EmployeeNumberUpdatedOpps = new Set<Id>();
	public Set<Id> set_AccIdForSubmissionDate;
	public Set<Id> set_AmountUpdatedOpps = new Set<Id>();

	/**
	 * @description Map of all Users by Id
	 * @author David Schach
	 * @return   lazy-loaded map of all users by Id
	 */
	public Map<Id, User> map_AllUsers {
		get {
			if (map_AllUsers == null) {
				map_AllUsers = GlobalQueryHelper.queryActiveUsers();
			}
			return map_AllUsers;
		}
		set;
	}

	/**
	 * @description Lazy-load Lead_Randomize values
	 * <br>TODO: Change this to getting the value for the current user
	 * @author David Schach
	 * @return   the orgDefault `Lead_Randomize__c` value
	 */
	public Lead_Randomize__c objRandomize {
		get {
			if (objRandomize == null) {
				objRandomize = Lead_Randomize__c.getOrgDefaults();
			}
			return objRandomize;
		}
		set;
	}

	/**
	 * @description OpportunityTriggerHelper constructor
	 */
	public OpportunityTriggerHelper() {
		map_Accounts = new Map<Id, Account>();
		map_AccountsToUpdate = new Map<Id, Account>();
		map_ContactsToUpdate = new Map<Id, Contact>();
		map_TicketsToUpdate = new Map<Id, Ticket__c>();
		map_ArdiusOpportunities = new Map<Id, Opportunity>();
		map_Users = new Map<Id, User>();
		map_PaymentInvoices = new Map<Id, Payment_Invoice__c>();
		map_SourceNameToPartnerReferral = new Map<String, Partner_Referral_Source__c>();
		map_AccountIdToZPUserRoles = new Map<Id, List<Zp_User_Role__c>>();
		list_TempContactRoles = new List<OpportunityContactRole>();
		map_AccIdToTrackingToUpsert = new Map<Id, Account_Related_Tracking__c>();
		map_PBIdToMapOfProdNameToPBE = new Map<Id, Map<String, PriceBookEntry>>();
		list_OLIToBeUpserted = new List<OpportunityLineItem>();
		list_OLIToBeDeleted = new List<OpportunityLineItem>();
		list_TicketsToUpdate = new List<Ticket__c>();

		map_AccIdToDeadlineDateMap = new Map<Id, Date>();
		map_OpportunityWithUWState = new Map<Id, Policy__c>();
		map_OpptyIdToBenefitsCases = new Map<Id, List<Case>>();
		map_OpptyIdToBenefitsOrders = new Map<Id, List<Benefit_Order__c>>();
		map_OpptyIdToRenewalSurveys = new Map<Id, List<Renewal_Survey__c>>();
		set_BulkMigrationIds = new Set<Id>();
		map_OpptyIdToOpptyRelatedTrackings = new Map<Id, List<Opportunity_Related_Tracking__c>>();
		map_OpptyIdToMapofLineItem = new Map<Id, Map<String, OpportunityLineItem>>();
		set_InvoiceOpptyIds = new Set<Id>();
		map_BenefitOrdersToUpdate = new Map<Id, Benefit_Order__c>();
		set_OpptyIdPolicies = new Set<Id>();
		map_OpptyIdToTasks = new Map<Id, List<Task>>();
		map_OppsToBeUpdated = new Map<Id, Opportunity>();
		set_OLIToBeUpdatedIds = new Set<Id>();
		map_CompanyIdToUserIdWithHIRole = new Map<String, Map<String, String>>();
		map_ZPUserIdToConactId = new Map<String, Id>();
		map_OpptyIdToOpenBenefitsOrders = new Map<Id, List<Benefit_Order__c>>();
		map_OpptyIdToCasesWithIntegrationId = new Map<Id, List<Case>>();
		set_ClosedLostOppIds = new Set<Id>();
		set_ReopenedOppIds = new Set<Id>();
		map_AdvisingUserIdCap = new Map<String, Decimal>();
		map_AdvisingUserIdsWithSkillType = new Map<String, String>();
		map_HashOfAdvisingSkillWithUsers = new Map<String, Set<String>>();
		map_AdvisingUserIdOppCount = new Map<String, Decimal>();
		map_MultiEINOpptyToBeUpdated = new Map<Id, Opportunity>();
		map_RenewalOpptyToBeUpdated = new Map<Id, Opportunity>();
		set_AccountsWithSpecialEnrollment = new Set<Id>();
		list_RecertificationTickets = new List<Ticket__c>();
	}

	/**** Process Opportunities (Before Insert) ****/
	public void processBeforeInsert(List<Opportunity> list_Opportunities) {
		createCollectionsBefore(list_Opportunities, null);
		OpportunityHelper.validateAcquisitionOpportunity(list_Opportunities);
		OpportunityHelper.updateOpportunityOnBeforeTrigger(list_Opportunities, true);
		for (Opportunity objOppty : list_Opportunities) {

			populateFirstAPDDateMissed(objOppty, null);
			setBigDeskBenOps(objOppty, null);
			setStage(objOppty, null);
			setCommit(objOppty, null);
			setCloseDateInfo(objOppty, null);
			setNameAndType(objOppty, null);
			setPricebook(objOppty);
			setAdditionalServices(objOppty);
			setMiscellaneous(objOppty, null);
			copyDescription(objOppty, null);
			updateOwner(objOppty);
			updateOwnerRoleInfo(objOppty, null);
			updateMDRInfo(objOppty, null);
			updateEmployeeCounts(objOppty, null);
			OpportunityHelper.updateEmployeeCounts(objOppty, null, map_Accounts.get(objOppty.AccountId));
			complexityScoringAdvisingFulfillment(objOppty);
			updateOnboardingSteps(objOppty);
			processLeadSource(objOppty, null);
			updateRenewalSubmissionDeadline(objOppty);
			updateUWStateCarrier(objOppty);
			updateClosedOwnerRole(objOppty, null);
			populateRegion(objOppty, null);
			updateBenefitOptOutFields(objOppty, null);
			setAdvisorAssignment(objOppty, null);
			populateLatestBlockedTimestamp(objOppty, null);
			checkRequiredValuesForAdvisingAssignment(objOppty, null);
			populateRecommendationSentTimestamp(objOppty, null);
			updateBYOBOpportunity(objOppty, null);
			handleCreateTierUpsellOpportunity(objOppty);
			reAssignOpportunity(objOppty, null);
			updateLeadPassOnHIOpportunity(objOppty, null);
			updateArdiusOppReferralCode(objOppty);
			validateArdiusDuplicateOpportunity(objOppty);
			routeICPOpportunity(objOppty);
			populateCompanyInfoCompleteDT(objOppty, null);
			handleGrowthExpansionValidation(objOppty, null);
			routeTaxCreditsOpportunity(objOppty, null);
			populateOnboardingCompleteDT(objOppty, null);
			OpportunityHelper.updateCloseDateToMatchAPD(objOppty, null);
		}
	}

	/**** Process Opportunities (After Insert) ****/
	public void processAfterInsert(List<Opportunity> list_Opportunities) {
		List<OpportunityContactRole> list_ContactRolesToCreate = new List<OpportunityContactRole>();
		List<Case> list_CasesToCreate = new List<Case>();
		List<Opportunity_Related_Tracking__c> list_OpptyTrackingToCreate = new List<Opportunity_Related_Tracking__c>();
		// Opportunity Stage History records to be created
		List<Opportunity_Stage_History__c> list_StageHistoryToCreate = new List<Opportunity_Stage_History__c>();
		List<Opportunity> list_opptyToCreateQASheet = new List<Opportunity>();
		List<OpportunityLineItem> list_OLIToBeInserted = new List<OpportunityLineItem>();

		List<Opportunity> list_AcquisitionOpptyToPorcessed = new List<Opportunity>();
		createCollectionsAfter(list_Opportunities, null);

		// Not refactored/re-written yet
		BenefitOrderHelperFunctions objBOCreationUtil = new BenefitOrderHelperFunctions();
		objBOCreationUtil.createBenefitOrder(list_Opportunities, null, null, benefitOrderMap);

		for (Opportunity objOppty : list_Opportunities) {
			rollUpValuesToAccounts(objOppty, null);
			calculateResellerMetrics(objOppty, null);
			syncLineItems(objOppty, null);
			updateLastClientAddDate(objOppty, null);
			assignOwnerToRenewalOpportunity(objOppty, null);
			setHIOwnerOnAccount(objOppty, null);
			checkRoutingCriteria(objOppty);

			list_TempContactRoles = createContactRoles(objOppty, null);
			if (!list_TempContactRoles.isEmpty()) {
				list_ContactRolesToCreate.addAll(list_TempContactRoles);
			}

			List<Case> list_TempCases = createCases(objOppty);
			if (!list_TempCases.isEmpty()) {
				list_CasesToCreate.addAll(list_TempCases);
			}

			//create Opportunity Related Tracking Object upon insert
			Opportunity_Related_Tracking__c objTracking = createOpptyRelatedTracking(objOppty);
			if (objTracking != null) {
				list_OpptyTrackingToCreate.add(objTracking);
			}

			Opportunity_Stage_History__c objHistory = createStageHistory(objOppty, null);
			if (objHistory != null) {
				list_StageHistoryToCreate.add(objHistory);
			}

			if (QASheetHelper.set_opptyRecordTypeIds.contains(objOppty.RecordTypeId)) {
				list_opptyToCreateQASheet.add(objOppty);
			}

			if (set_TierUpsellAccountIdsToRoute.contains(objOppty.AccountId)) {
				set_OpportunityIdsToRoute.add(objOppty.Id);
			}

			if (OpportunityUtil.isBenefits(objOppty) && objOppty.NumberOfEmployees__c != null && objOppty.NumberOfEmployees__c > 0) {
				list_OLIToBeInserted.addAll(createBenefitsOpportunityLineItems(objOppty));
			}

			if (objOppty.RecordTypeId == OpportunityHelper.ACQUISITION_OPPTY_RT_ID) {
				list_AcquisitionOpptyToPorcessed.add(objOppty);
			}
		}

		System.debug('list_AcquisitionOpptyToPorcessed232: ' + list_AcquisitionOpptyToPorcessed);
		System.debug('OpportunityHelper.blnLineItemUpdated: ' + OpportunityHelper.blnLineItemUpdated);
		if (!list_AcquisitionOpptyToPorcessed.isEmpty() && !OpportunityHelper.blnLineItemUpdated) {
			OpportunityHelper.createCollections();
			OpportunityHelper.createOpportunityLineItems(list_AcquisitionOpptyToPorcessed, null);
		}

		if (!map_AccountsForRouting.isEmpty()) {
			if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
				System.enqueueJob(new HIRoutingQueueable(map_AccountsForRouting));
			}
		}

		// Send opportunties to Routing Tool for Routing
		if (!set_OpportunityIdsToRoute.isEmpty()) {
			new SendOpportunityToRingLead(set_OpportunityIdsToRoute).sendOpportunityToRingLead();
		}

		// ********** Start : DML ************
		// Opportunity Products (Opportunity Line Items)
		if (!list_OLIToBeUpserted.isEmpty()) {
			TriggerHandler.bypass('OpportunityTriggerHandler');
			upsert list_OLIToBeUpserted;
			TriggerHandler.clearBypass('OpportunityTriggerHandler');
		}

		// Opportunity Products (Opportunity Line Items) to be inserted without bypassing OpportunityTriggerHandler
		if (!list_OLIToBeInserted.isEmpty()) {
			insert list_OLIToBeInserted;
		}

		// Account Related Tracking
		if (!map_AccIdToTrackingToUpsert.isEmpty()) {
			upsert map_AccIdToTrackingToUpsert.values() Unique_Account_Id__c;
		}

		// Contacts
		if (!map_ContactsToUpdate.isEmpty()) {
			Boolean blnPreviousSkipTriggerFlag = ContactTriggerHelper.skipTrigger;
			ContactTriggerHelper.skipTrigger = true;
			update map_ContactsToUpdate.values();
			ContactTriggerHelper.skipTrigger = blnPreviousSkipTriggerFlag;
		}

		// Cases
		if (!list_CasesToCreate.isEmpty()) {
			insert list_CasesToCreate;
		}

		// Opportunity Contact Roles
		if (!list_ContactRolesToCreate.isEmpty()) {
			insert list_ContactRolesToCreate;
		}

		// Opportunity Related Tracking
		if (!list_OpptyTrackingToCreate.isEmpty()) {
			upsert list_OpptyTrackingToCreate Unique_Opp_Id__c;
		}

		// Opportunity Stage History
		if (!list_StageHistoryToCreate.isEmpty()) {
			insert list_StageHistoryToCreate;
		}

		// Accounts
		if (!map_AccountsToUpdate.isEmpty()) {
			update map_AccountsToUpdate.values();
		}

		// QA Sheet Creation
		if (!list_opptyToCreateQASheet.isEmpty()) {
			QASheetHelper.createOrUpdateQASheet(list_opptyToCreateQASheet);
		}

		//Advising Assignment
		if (!map_RenewalOpptyToBeUpdated.isEmpty()) {
			Boolean blnAccountSkipTrigger = CaseTriggerHelper.skipTrigger;
			CaseTriggerHelper.skipTrigger = true;
			update map_RenewalOpptyToBeUpdated.values();
			CaseTriggerHelper.skipTrigger = blnAccountSkipTrigger;
		}

		new ProductDiscountHelper().collectCompanyOpportunitiesForDiscounts(list_Opportunities, null);
		if (!list_CasesToCreate.isEmpty() && !list_ContactRolesToCreate.isEmpty() && !set_RenewalOppIds.isEmpty()) {
			createCaseTeamMembers(set_RenewalOppIds, list_CasesToCreate, list_ContactRolesToCreate);
		}

		// ********** Stop : AfterInsert ************
	}

	/**** Process Opportunities (Before Update) ****/
	public void processBeforeUpdate(List<Opportunity> list_Opportunities, Map<Id, Opportunity> map_OldOppty) {
		Map<Id, Opportunity> map_Oppty = (Map<Id, Opportunity>) Trigger.newMap;

		// Revisit merging of collection methods
		createCollectionsBefore(list_Opportunities, map_OldOppty);
		//OpportunityHelper.validateAcquisitionOpportunity(list_Opportunities);

		OpportunityHelper.checkAccessOfOpportunity(list_Opportunities);
		for (Opportunity objOppty : list_Opportunities) {
			Opportunity objOldOppty = map_OldOppty.get(objOppty.Id);
			populateFirstAPDDateMissed(objOppty, objOldOppty);
			setBigDeskBenOps(objOppty, objOldOppty);
			setNameAndType(objOppty, objOldOppty);
			setStage(objOppty, objOldOppty);
			setSandlerBusinessProcess(objOppty, objOldOppty);
			updateEmployeeCounts(objOppty, objOldOppty);
			OpportunityHelper.updateEmployeeCounts(objOppty, objOldOppty, map_Accounts.get(objOppty.AccountId));
			setCloseDateInfo(objOppty, objOldOppty);
			updateOwnerRoleInfo(objOppty, objOldOppty);
			benefitsSetupLastUpdated(objOppty, objOldOppty);
			handleBenefitsApplication(objOppty, objOldOppty);
			setCommit(objOppty, objOldOppty);
			updateOnboardingSteps(objOppty);
			copyDescription(objOppty, objOldOppty);
			setMiscellaneous(objOppty, objOldOppty);
			processLeadSource(objOppty, objOldOppty);
			updateMDRInfo(objOppty, objOldOppty);
			complexityScoringAdvisingFulfillment(objOppty);
			updateClosedOwnerRole(objOppty, objOldOppty);
			updateRenewalSubmissionDeadline(objOppty);
			updateUWStateCarrier(objOppty);
			updateMDRActivity(objOppty);
			populateRegion(objOppty, objOldOppty);
			updateBenefitOptOutFields(objOppty, objOldOppty);
			setAdvisingBlockedReason(objOppty, objOldOppty);
			populateLatestBlockedTimestamp(objOppty, objOldOppty);
			checkRequiredValuesForAdvisingAssignment(objOppty, objOldOppty);
			populateRecommendationSentTimestamp(objOppty, objOldOppty);
			updateBYOBOpportunity(objOppty, objOldOppty);
			populateAdvisorAssignmentTimestamp(objOppty, objOldOppty);
			populateOBPRETimestamp(objOppty, objOldOppty);
			updateTierUpsellOpportunity(objOppty, objOldOppty);
			updateTierUpsellInvoiceAmount(objOppty, objOldOppty);
			reAssignOpportunity(objOppty, objOldOppty);
			sendSlackNotifications(objOppty, objOldOppty);
			syncClosedDateWithJoinedDate(objOppty, objOldOppty);
			handleTierUpsellUpdate(objOppty, objOldOppty);
			updateLeadPassOnHIOpportunity(objOppty, objOldOppty);
			resetBenefitsFundingType(objOppty, objOldOppty);
			populateCompanyInfoCompleteDT(objOppty, objOldOppty);
			routeTaxCreditsOpportunity(objOppty, objOldOppty);
			populateOnboardingCompleteDT(objOppty, objOldOppty);
			OpportunityHelper.updateCloseDateToMatchAPD(objOppty, objOldOppty);
		}

		updateBenefitsFundingType(map_Oppty);

		// * TODO: Not refactored/re-written yet. This can be moved to run asynchronously
		BenefitOrderHelperFunctions objBOCreationUtil = new BenefitOrderHelperFunctions();
		objBOCreationUtil.createBenefitOrder(list_Opportunities, map_OldOppty, null, benefitOrderMap);
	}

	/**** Process Opportunities (After Update) ****/
	public void processAfterUpdate(List<Opportunity> list_Opportunities, Map<Id, Opportunity> map_OldOppty) {
		Map<Id, Case> map_BenefitsCasesIdRecordToUpdate = new Map<Id, Case>();
		//List<Case> list_BenefitsCasesToUpdate = new List<Case>();
		//List<Benefit_Order__c> list_BenefitOrdersToUpdate = new List<Benefit_Order__c>();
		List<Renewal_Survey__c> list_RenewalSurveysToUpdate = new List<Renewal_Survey__c>();
		List<Task> list_TasksToCreate = new List<Task>();
		List<Opportunity_Related_Tracking__c> list_OpptyTrackingToUpsert = new List<Opportunity_Related_Tracking__c>();
		// Opportunity Stage History records to be created
		List<Opportunity_Stage_History__c> list_StageHistoryToCreate = new List<Opportunity_Stage_History__c>();

		List<Field_History__c> list_fieldHistories = new List<Field_History__c>();

		List<OpportunitySplit> list_OpportunitySplitCreate = new List<OpportunitySplit>();

		Boolean blnRunInvoice = false;
		List<OpportunityContactRole> list_ContactRolesToCreate = new List<OpportunityContactRole>();

		createCollectionsAfter(list_Opportunities, map_OldOppty);

		if (!set_InvoiceOpptyIds.isEmpty()) {
			blnRunInvoice = true;
			if (System.isFuture() || System.isBatch() || System.isQueueable()) {
				//syncOpptyWithPaymentInvoice(set_InvoiceOpptyIds);
				OpportunityHelper.syncPaymentInvoiceValuesToOppty(set_InvoiceOpptyIds);
			} else {
				syncOpptyWithPaymentInvoiceFuture(set_InvoiceOpptyIds);
			}
		}
		//logic to create opportunity splits if split record does not exist for Opportunity Owner
		if (map_OppToOwnerId != null && !map_OppToOwnerId.values().isEmpty()) {
			list_OpportunitySplitCreate = createOpportunitySplits(map_OppToOwnerId);
		}

		if (!list_OpportunitySplitCreate.isEmpty()) {
			Map<String, String> map_InsertDMLErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResults = Database.insert(list_OpportunitySplitCreate, false);
			map_InsertDMLErrors = Utils.processSaveResult(list_SaveResults, list_OpportunitySplitCreate, 'Id', true, 'OpportunityTriggerHelper-CreateSplits');
		}

		for (Opportunity objOppty : list_Opportunities) {
			Opportunity objOldOppty = map_OldOppty.get(objOppty.Id);
			rollUpValuesToAccounts(objOppty, objOldOppty);
			calculateResellerMetrics(objOppty, objOldOppty);
			assignOwnerToRenewalOpportunity(objOppty, objOldOppty);
			updateMultiEINOppsWithOwner(objOppty, objOldOppty);
			//BSS-65
			updateOffersHealthInsurance(objOppty, objOldOppty);
			// If invoice is not run, then use sync line items to update opportunity products
			if (!blnRunInvoice) {
				syncLineItems(objOppty, objOldOppty);
			}

			list_TempContactRoles = createContactRoles(objOppty, objOldOppty);
			if (!list_TempContactRoles.isEmpty()) {
				list_ContactRolesToCreate.addAll(list_TempContactRoles);
			}

			updateBenefitOrders(objOppty, objOldOppty);
			updateLastClientAddDate(objOppty, objOldOppty);
			// Create BDO Benefits Opportunities
			createBDOOpportunities(objOppty, objOldOppty);

			//If Opportunity Owner is changed after Opp goes CW then perform this logic
			if (map_OppToOwnerId.containsKey(objOppty.Id)) {
				syncOpportunitySplits(objOppty);
			}

			List<Case> list_TempCases = updateCaseOwner(objOppty);
			if (!list_TempCases.isEmpty()) {
				map_BenefitsCasesIdRecordToUpdate.putAll(list_TempCases);
			}

			list_TempCases = populateCloseDateOnCustomerCase(objOppty, objOldOppty);
			if (!list_TempCases.isEmpty()) {
				map_BenefitsCasesIdRecordToUpdate.putAll(list_TempCases);
			}

			list_TempCases = updateCaseNotes(objOppty);
			if (!list_TempCases.isEmpty()) {
				map_BenefitsCasesIdRecordToUpdate.putAll(list_TempCases);
			}

			List<Renewal_Survey__c> list_TempSurveys = updateSurveyOwner(objOppty);
			if (!list_TempSurveys.isEmpty()) {
				list_RenewalSurveysToUpdate.addAll(list_TempSurveys);
			}

			List<Task> list_TempTasks = createTaskOnResellerAccounts(objOppty, objOldOppty);
			if (!list_TempTasks.isEmpty()) {
				list_TasksToCreate.addAll(list_TempTasks);
			}

			//upsert Opportunity Related Tracking Objects upon update
			list_OpptyTrackingToUpsert = upsertOpptyRelatedTracking(objOppty, objOldOppty);
			Opportunity_Stage_History__c objHistory = createStageHistory(objOppty, objOldOppty);
			if (objHistory != null) {
				list_StageHistoryToCreate.add(objHistory);
			}

			list_fieldHistories.addAll(UtilitiesFactory.createHistoryTracking(objOppty, objOldOppty, 'Opportunity'));

			//Added by Debas for BSS-111
			Opportunity objBYOBOpportunity = createBYOBOpportunity(objOppty, objOldOppty);
			if (objBYOBOpportunity != null) {
				list_OpptysToInsert.add(objBYOBOpportunity);
			}

			Ticket__c objTicket = createRecertificationTickets(objOppty, objOldOppty);
			if (objTicket != null) {
				list_RecertificationTickets.add(objTicket);
			}
			if ((objOppty.Original_Firm__c != null && objOppty.Original_Firm__c != objOppty.AccountId) || 
			(objOppty.Original_Firm__c == null && objOppty.LeadSource == OpportunityUtil.ADDED_BY_ACCOUNTANT)) {
				updateCohortDateOnResellerAccount(objOppty, objOldOppty);
			}
		}
		updateArdiusTicketAsClosedLost();

		//Update quantity on OpportunityLineItems if Employees count changed on Opportunity
		if (!set_EmployeeNumberUpdatedOpps.isEmpty()) {
			updateBenefitsOppLineItemQuantity(set_EmployeeNumberUpdatedOpps, list_Opportunities);
		}

		// ********** Start : DML ************

		// Not refactored/re-written yet
		if (!set_BulkMigrationIds.isEmpty()) {
			OrderTriggerHelper.UpdateOrderBulkMigrationRequest(set_BulkMigrationIds);
		}

		// Contacts
		if (!map_ContactsToUpdate.isEmpty()) {
			Boolean blnPreviousSkipTriggerFlag = ContactTriggerHelper.skipTrigger;
			ContactTriggerHelper.skipTrigger = true;
			update map_ContactsToUpdate.values();
			ContactTriggerHelper.skipTrigger = blnPreviousSkipTriggerFlag;
		}

		// List of Cases
		if (!map_BenefitsCasesIdRecordToUpdate.isEmpty()) {
			update map_BenefitsCasesIdRecordToUpdate.values();
		}

		// Opportunity Contact Roles
		if (!list_ContactRolesToCreate.isEmpty()) {
			insert list_ContactRolesToCreate;
		}

		// Benefit Orders
		if (!map_BenefitOrdersToUpdate.isEmpty()) {
			update map_BenefitOrdersToUpdate.values();
		}

		// Not refactored/re-written yet
		if (!set_OpptyIdPolicies.isEmpty()) {
			processPolicyInformation(set_OpptyIdPolicies);
		}

		// Renewal Surveys
		if (!list_RenewalSurveysToUpdate.isEmpty()) {
			update list_RenewalSurveysToUpdate;
		}

		// New Tasks
		if (!list_TasksToCreate.isEmpty()) {
			insert list_TasksToCreate;
		}

		// Creating new or updating existing Opportunity Related Tracking
		if (!list_OpptyTrackingToUpsert.isEmpty()) {
			TriggerHandler.bypass('OpportunityTriggerHandler');
			upsert list_OpptyTrackingToUpsert;
			TriggerHandler.clearBypass('OpportunityTriggerHandler');
		}

		// Upsert Opportunity Products (Opportunity Line Items)
		if (!list_OLIToBeUpserted.isEmpty()) {
			TriggerHandler.bypass('OpportunityTriggerHandler');
			upsert list_OLIToBeUpserted;
			TriggerHandler.clearBypass('OpportunityTriggerHandler');
		}

		// Delete Opportunity Products (Opportunity Line Items)
		if (!list_OLIToBeDeleted.isEmpty()) {
			TriggerHandler.bypass('OpportunityTriggerHandler');
			// Changes by Praveen - To avoid delete same opp line items in two different lists.
			// syncOpptyWithPaymentInvoice - deletes same opp line items
			// deleting same opp line items in two different lists causes INVALID_CROSS_REFERENCE_KEY_ERROR
			Database.delete(list_OLIToBeDeleted, false);
			TriggerHandler.clearBypass('OpportunityTriggerHandler');
		}

		if (!list_OpportunitySplitUpdate.isEmpty()) {
			Map<String, String> map_UpdateDMLErrors = new Map<String, String>();
			List<Database.SaveResult> list_SaveResults = Database.update(list_OpportunitySplitUpdate, false);
			map_UpdateDMLErrors = Utils.processSaveResult(list_SaveResults, list_OpportunitySplitUpdate, 'Id', true, 'OpportunityTriggerHelper-UpdateSplits');
		}
		if (!list_OpportunitySplitDelete.isEmpty()) {
			Database.delete(list_OpportunitySplitDelete);
		}
		// Insert new Stage History
		if (!list_StageHistoryToCreate.isEmpty()) {
			insert list_StageHistoryToCreate;
		}

		if (!map_OppsToBeUpdated.isEmpty()) {
			TriggerHandler.bypass('OpportunityTriggerHandler');
			update map_OppsToBeUpdated.values();
			forceLineItemCreate(map_OppsToBeUpdated.values());
			TriggerHandler.clearBypass('OpportunityTriggerHandler');
		}

		// List of Accounts
		if (!map_AccountsToUpdate.isEmpty()) {
			update map_AccountsToUpdate.values();
		}

		//List of MultiEIN Opportunities
		if (!map_RenewalOpptyToBeUpdated.isEmpty()) {
			Boolean blnAccountSkipTrigger = CaseTriggerHelper.skipTrigger;
			CaseTriggerHelper.skipTrigger = true;
			update map_RenewalOpptyToBeUpdated.values();
			CaseTriggerHelper.skipTrigger = blnAccountSkipTrigger;
		}

		//Insert Field history records
		if (!list_fieldHistories.isEmpty()) {
			insert list_fieldHistories;
		}

		if (!list_OpptysToInsert.isEmpty()) {
			insert list_OpptysToInsert;
		}

		if (!list_RecertificationTickets.isEmpty()) {
			Boolean blnSkipTicketTrigger = TicketTriggerHelper.skipTrigger;
			TicketTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> list_SaveResults = Database.insert(list_RecertificationTickets, false);
			Map<String, String> map_TicketInsertErrors = Utils.processSaveRecords(
				list_SaveResults,
				list_RecertificationTickets,
				'Opportunity__c',
				true,
				'OpportunityTriggerHelper',
				'processAfterUpdate'
			);
			TicketTriggerHelper.skipTrigger = blnSkipTicketTrigger;
		}

		if (!map_TicketsToUpdate.IsEmpty()) {
			update map_TicketsToUpdate.values();
		}

		new ProductDiscountHelper().collectCompanyOpportunitiesForDiscounts(list_Opportunities, map_OldOppty);

		AccountRelatedTrackingTriggerHelper.skipTrigger = true;
		// Account Related Tracking
		if (!map_AccIdToTrackingToUpsert.isEmpty()) {
			upsert map_AccIdToTrackingToUpsert.values() Unique_Account_Id__c;
		}
		// ********** Stop : AfterUpdate ************
	}

	/**** Before Context : Create data collections to be used across functions ****/
	public void createCollectionsBefore(List<Opportunity> list_Opportunities, Map<Id, Opportunity> map_OldOppty) {
		Set<Id> set_AccountIds = new Set<Id>();
		// Initiatlizing with users that might need to be referenced additionally
		Set<Id> set_OwnerIds = new Set<Id>{ (Id) Label.DE_HI_Owner_Exclude, (Id) Label.HI_Owner, UserInfo.getUserId() };
		Set<Id> set_InvoiceIds = new Set<Id>();
		Set<String> set_LeadSources = new Set<String>();
		Set<Id> set_BenefitsAccountIds = new Set<Id>();
		Set<Id> set_AccIdForUWSate = new Set<Id>();
		Set<Id> set_OwnerChangedIds = new Set<Id>();
		set_OpportunityIdsToRoute = new Set<Id>();
		set_AmountUpdatedOpps = new Set<Id>();
		set_AccIdForSubmissionDate = new Set<Id>();

		// Create data collections
		for (Opportunity objOppty : list_Opportunities) {
			Opportunity objOldOppty = (map_OldOppty != null ? map_OldOppty.get(objOppty.Id) : null);

			if (objOppty.AccountId != null) {
				if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID && (objOppty.Submission_Deadline__c == null || objOppty.UW_State_PY__c == null)) {
					if (objOppty.Submission_Deadline__c == null) {
						set_AccIdForSubmissionDate.add(objOppty.AccountId);
					}

					if (objOppty.UW_State_PY__c == null) {
						set_AccIdForUWSate.add(objOppty.AccountId);
					}

					set_BenefitsAccountIds.add(objOppty.AccountId);
				}
				set_AccountIds.add(objOppty.AccountId);
			}

			if (objOppty.Sold_By__c != null) {
				set_AccountIds.add(objOppty.Sold_By__c);
			}

			if (objOppty.Referred_By__c != null) {
				set_AccountIds.add(objOppty.Referred_By__c);
			}

			//No need to check, as we will filter out records in the query
			set_OwnerIds.add(objOppty.OwnerId);

			if (objOldOppty != null) {
				set_OwnerIds.add(objOldOppty.OwnerId);

				if (objOppty.OwnerId != objOldOppty.OwnerId) {
					set_OwnerChangedIds.add(objOppty.Id);
				}

				if (objOldOppty.Sold_By__c != null) {
					set_AccountIds.add(objOldOppty.Sold_By__c);
				}

				if (objOldOppty.Referred_By__c != null) {
					set_AccountIds.add(objOldOppty.Referred_By__c);
				}
			}

			if (objOppty.Payment_Invoice__c != null) {
				set_InvoiceIds.add(objOppty.Payment_Invoice__c);
			}

			if (String.isNotBlank(objOppty.LeadSource) && (objOldOppty == null || objOppty.LeadSource != objOldOppty.LeadSource)) {
				set_LeadSources.add(objOppty.LeadSource);
			}

			//Collect opportunities if Amount is changed
			if (OpportunityUtil.isBenefits(objOppty) && objOldOppty != null && objOppty.Amount != 0 && objOppty.Amount != objOldOppty.Amount) {
				set_AmountUpdatedOpps.add(objOppty.Id);
			}
		}

		// Creating map of Accounts
		if (!set_AccountIds.isEmpty()) {
			map_Accounts = new Map<Id, Account>(queryAccounts(set_AccountIds));
		}

		// Creating map of Owner Users
		if (!set_OwnerIds.isEmpty()) {
			map_Users = GlobalQueryHelper.getUsersByIdMap(set_OwnerIds);
		}

		// Creating map of Payment Invoices
		if (!set_InvoiceIds.isEmpty()) {
			map_PaymentInvoices = new Map<Id, Payment_Invoice__c>(queryPaymentInvoices(set_InvoiceIds));
		}

		// Creating map of Payment Invoices
		if (!set_LeadSources.isEmpty()) {
			List<Partner_Referral_Source__c> list_Temp = queryPartnerReferralSources(set_LeadSources);
			for (Partner_Referral_Source__c objPartnerRefSrc : list_Temp) {
				if (String.isNotBlank(objPartnerRefSrc.Source_Name__c)) {
					map_SourceNameToPartnerReferral.put(objPartnerRefSrc.Source_Name__c.toLowerCase(), objPartnerRefSrc);
				}
			}
		}

		// Creating map of account and renewal submission deadline
		if (!set_BenefitsAccountIds.isEmpty()) {
			createSubmissionDeadlineMap(set_BenefitsAccountIds, set_AccIdForSubmissionDate, set_AccIdForUWSate);
		}

		// Creating map of opportunity and taskes
		if (!set_OwnerChangedIds.isEmpty()) {
			List<Task> list_Tasks = queryTasks(set_OwnerChangedIds);
			for (Task objTask : list_Tasks) {
				List<Task> list_TempTasks = map_OpptyIdToTasks.containsKey(objTask.WhoId) ? map_OpptyIdToTasks.get(objTask.WhoId) : new List<Task>();
				list_TempTasks.add(objTask);
				map_OpptyIdToTasks.put(objTask.WhoId, list_TempTasks);
			}
		}
	}

	/**** After Context : Create data collections to be used across functions ****/
	public void createCollectionsAfter(List<Opportunity> list_Opportunities, Map<Id, Opportunity> map_OldOppty) {
		Set<Id> set_AccountIdsForUserRoles = new Set<Id>();
		Set<Id> set_AccountIds = new Set<Id>();
		Set<Id> set_OpptyOwnerChange = new Set<Id>();
		Set<Id> set_OpptyRenewalSurveyIds = new Set<Id>();
		Set<Id> set_MigrationReqOpptys = new Set<Id>();
		Set<Id> set_StageChangeOpptys = new Set<Id>();
		Set<Id> set_LineItemOpptys = new Set<Id>();
		Set<Id> set_OpptyIds = new Set<Id>();
		// Initiatlizing with users that might need to be referenced additionally
		Set<Id> set_OwnerIds = new Set<Id>{ Label.DE_HI_Owner_Exclude, Label.HI_Owner, UserInfo.getUserId() };
		Set<String> set_ZPCompanyId = new Set<String>();
		Set<Id> set_OpptyNotesChangeIds = new Set<Id>();
		Set<Id> set_ClosedLostReopenedOppIds = new Set<Id>();
		Set<String> set_BenefitsCaseRecordTypeIds = new Set<String>{
			OpportunityUtil.BENEFITS_CHANGE_CASE_RT_ID,
			OpportunityUtil.BENEFITS_RENEWAL_CASE_RT_ID,
			OpportunityUtil.BENEFITS_NEWPLAN_CASE_RT_ID,
			OpportunityUtil.BENEFITS_BOR_CASE_RT_ID
		};
		Set<String> set_ClosedBOStatuses = new Set<String>{ BenefitOrderUtil.STATUS_FULFILLED, BenefitOrderUtil.STATUS_CLOSED_ADMIN, BenefitOrderUtil.STATUS_CANCELLED };
		Set<String> set_MultiEINOpporunities = new Set<String>();
		Map<String, String> map_OpptyToOwnerIds = new Map<String, String>();
		Set<String> set_UWStatesPreviousYear = new Set<String>();
		//Set<Boolean> set_BigDeskBenOps = new Set<Boolean>();
		//Set<String> set_SkillsHash = new Set<String>();
		Set<String> set_MonthYears = new Set<String>();
		Set<Decimal> set_Months = new Set<Decimal>();
		Set<Decimal> set_Years = new Set<Decimal>();
		Set<Id> set_OpptysForTicket = new Set<Id>();
		map_OppToOwnerId = new Map<Id, Id>();
		Set<Id> set_AccOwnerIds = new Set<Id>();
		Set<Id> set_ReopenOppIds = new Set<Id>();
		set_EmployeeNumberUpdatedOpps = new Set<Id>();
		// Create data collections
		for (Opportunity objOppty : list_Opportunities) {
			Opportunity objOldOppty = (map_OldOppty != null ? map_OldOppty.get(objOppty.Id) : null);
			set_OpptyIds.add(objOppty.Id);

			//Collect opportunities whose Employees count is changed
			if (objOldOppty != null && OpportunityUtil.isBenefits(objOppty) && objOppty.NumberOfEmployees__c != objOldOppty.NumberOfEmployees__c) {
				set_EmployeeNumberUpdatedOpps.add(objOppty.Id);
			}

			if (objOppty.AccountId != null) {
				set_AccountIds.add(objOppty.AccountId);

				if (OpportunityUtil.isBenefits(objOppty) || OpportunityUtil.isCustomerSuccess(objOppty) || OpportunityUtil.isTierUpsell(objOppty)) {
					set_AccountIdsForUserRoles.add(objOppty.AccountId);
				}

				if (String.isNotBlank(objOppty.ZP_Company_ID_from_Account__c)) {
					set_ZPCompanyId.add(objOppty.ZP_Company_ID_from_Account__c);
				}
			}
			if (objOppty.Sold_By__c != null) {
				set_AccountIds.add(objOppty.Sold_By__c);
			}

			if (objOppty.Referred_By__c != null) {
				set_AccountIds.add(objOppty.Referred_By__c);
			}

			set_OwnerIds.add(objOppty.OwnerId);
			if (objOldOppty != null) {
				set_OwnerIds.add(objOldOppty.OwnerId);
			}

			if (
				(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID ||
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID) &&
				objOppty.PriceBook2Id != null &&
				!map_PBIdToMapOfProdNameToPBE.containsKey(objOppty.PriceBook2Id)
			) {
				PriceBook2 objPB = OpportunityUtil.getPriceBookById(objOppty.PriceBook2Id);

				Map<String, PriceBookEntry> map_Temp = new Map<String, PriceBookEntry>();
				for (PriceBookEntry objPBE : objPB.PriceBookEntries) {
					map_Temp.put(objPBE.Product2.Name, objPBE);
				}

				map_PBIdToMapOfProdNameToPBE.put(objPB.Id, map_Temp);
			}

			if (objOldOppty != null) {
				if (
					(objOppty.OwnerId != objOldOppty.OwnerId || (objOppty.StageName != objOldOppty.StageName && objOldOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE)) &&
					(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
				) {
					set_OpptyOwnerChange.add(objOppty.Id);
				}

				if (objOldOppty.Sold_By__c != null) {
					set_AccountIds.add(objOldOppty.Sold_By__c);
				}

				if (objOldOppty.Referred_By__c != null) {
					set_AccountIds.add(objOldOppty.Referred_By__c);
				}

				if (
					objOppty.Notes__c != objOldOppty.Notes__c &&
					(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
				) {
					set_OpptyNotesChangeIds.add(objOppty.Id);
				}

				if (objOppty.OwnerId != objOldOppty.OwnerId && objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
					set_OpptyRenewalSurveyIds.add(objOppty.Id);
				}

				if (objOppty.Bulk_Migration__c != null && objOppty.Amount != objOldOppty.Amount && objOppty.Amount != objOldOppty.Amount) {
					set_MigrationReqOpptys.add(objOppty.Id);
				}

				if (objOppty.StageName != objOldOppty.StageName) {
					set_StageChangeOpptys.add(objOppty.Id);
					if (OpportunityUtil.set_OppCloseStageName?.contains(objOldOppty.StageName) && !OpportunityUtil.set_OppCloseStageName?.contains(objOppty.StageName)) {
						set_ReopenOppIds.add(objOppty.Id);
					}
				}

				if (
					objOppty.RecordTypeId != OpportunityUtil.COMPANY_OPPTY_RT_ID &&
					objOppty.RecordTypeId != OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
					objOppty.RecordTypeId != OpportunityUtil.ACQUISITION_OPPTY_RT_ID
				) {
					if (objOppty.NumberOfEmployees__c != objOldOppty.NumberOfEmployees__c && (objOldOppty.NumberOfEmployees__c == null || objOldOppty.NumberOfEmployees__c == 0)) {
						set_OpptyIdPolicies.add(objOppty.Id);
					}
				}

				if (objOppty.Payment_Invoice__c != null && (objOppty.Payment_Invoice__c != objOldOppty.Payment_Invoice__c) && objOppty.RecordTypeId != OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID) {
					set_InvoiceOpptyIds.add(objOppty.Id);
				}

				if (
					(objOppty.StageName != objOldOppty.StageName &&
					objOppty.StageName != OpportunityUtil.CLOSED_ADMIN_STAGE) ||
					(objOppty.NumberOfEmployees__c != objOldOppty.NumberOfEmployees__c ||
					objOppty.Number_of_Contractors__c != objOldOppty.Number_of_Contractors__c) ||
					(objOppty.Pricebook2Id != objOldOppty.Pricebook2Id) ||
					(objOppty.International_Contractors__c != objOldOppty.International_Contractors__c) ||
					(objOppty.International_Employees__c != objOldOppty.International_Employees__c) ||
					(objOppty.Additional_Opportunity_Services__c != objOldOppty.Additional_Opportunity_Services__c) && objOppty.RecordTypeId != OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID
				) {
					set_LineItemOpptys.add(objOppty.Id);
				}

				if (
					objOppty.StageName != objOldOppty.StageName &&
					(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				) {
					if (objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE || objOppty.StageName == OpportunityUtil.CLOSED_ADMIN_STAGE) {
						set_ClosedLostOppIds.add(objOppty.Id);
						set_ClosedLostReopenedOppIds.add(objOppty.Id);
					} else if (objOldOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE || objOldOppty.StageName == OpportunityUtil.CLOSED_ADMIN_STAGE) {
						set_ReopenedOppIds.add(objOppty.Id);
						set_ClosedLostReopenedOppIds.add(objOppty.Id);
					}
				}

				if (
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID &&
					objOppty.Needs_Recertification__c != objOldOppty.Needs_Recertification__c &&
					objOppty.Needs_Recertification__c
				) {
					set_OpptysForTicket.add(objOppty.Id);
				}

				if (objOppty.OwnerId != objOldOppty.OwnerId && objOppty.IsClosed) {
					map_OppToOwnerId.put(objOppty.Id, objOppty.OwnerId);
				}
			}

			if (OpportunityUtil.isEligibleForAdvisorAssignment(objOppty, objOldOppty)) {
				if (objOppty.HI_Effective_Date__c != null) {
					set_Months.add(objOppty.HI_Effective_Date__c.Month());
					set_Years.add(objOppty.HI_Effective_Date__c.Year());
					set_MonthYears.add(objOppty.HI_Effective_Date__c.Month() + '~' + objOppty.HI_Effective_Date__c.Year());
				}

				if (String.isNotBlank(objOppty.UW_State_PY__c)) {
					set_UWStatesPreviousYear.add(objOppty.UW_State_PY__c);
				}

				//set_BigDeskBenOps.add(objOppty.Big_Desk_BenOps__c);
				if (objOppty.Is_Multi_EIN__c) {
					if (String.isNotBlank(objOppty.Parent_Opportunity__c)) {
						set_MultiEINOpporunities.add(objOppty.Parent_Opportunity__c);
					} else {
						set_MultiEINOpporunities.add(objOppty.Id);
					}
				}

				map_OpptyToOwnerIds.put(objOppty.Id, objOppty.OwnerId);
			}

			if (
				objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID &&
				objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE &&
				objOldOppty.StageName != OpportunityUtil.CLOSED_LOST_STAGE
			) {
				map_ArdiusOpportunities.put(objOppty.Id, objOppty);
			}
			if (
				objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID &&
				objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE &&
				objOldOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE
			) {
				set_OpptyIdsClosed.add(objOppty.Id);
			}
		}

		// Creating map of Accounts
		if (!set_AccountIds.isEmpty()) {
			map_Accounts = new Map<Id, Account>(queryAccounts(set_AccountIds));
		}

		// query over benefits opportunities and get account owner ids during opportunity insert
		for (Opportunity objOppty : list_Opportunities) {
			Opportunity objOldOppty = (map_OldOppty != null ? map_OldOppty.get(objOppty.Id) : null);

			if (objOldOppty == null && OpportunityUtil.set_BenefitRTChangeEmployees.contains(objOppty.RecordTypeId)) {
				if (map_Accounts.containsKey(objOppty.AccountId)) {
					Account objAcc = map_Accounts.get(objOppty.AccountId);
					if (objAcc.OwnerId != null) {
						set_AccOwnerIds.add(objAcc.OwnerId);
					}
				}
			}
		}

		if (!set_AccOwnerIds.isEmpty()) {
			// Build a map of user Id and list of user account team members (used in HI Sales Routing)
			for (UserAccountTeamMember objAccTeamMember : AccountUtil.queryUserAccountTeamMembers(set_AccOwnerIds)) {
				List<UserAccountTeamMember> list_UserAccTeamMembers = new List<UserAccountTeamMember>();
				if (map_UserAccountTeamMembers.containsKey(objAccTeamMember.OwnerId)) {
					list_UserAccTeamMembers = map_UserAccountTeamMembers.get(objAccTeamMember.OwnerId);
				}

				list_UserAccTeamMembers.add(objAccTeamMember);
				map_UserAccountTeamMembers.put(objAccTeamMember.OwnerId, list_UserAccTeamMembers);
			}
		}

		// Creating map of Owner Users
		if (!set_OwnerIds.isEmpty()) {
			map_Users = GlobalQueryHelper.getUsersByIdMap(set_OwnerIds);
		}
		//create map of opportunity Split Record
		if (!map_OppToOwnerId.keyset().isEmpty()) {
			for (OpportunitySplit objSplit : [
				SELECT Id, SplitPercentage, SplitOwnerId, SplitTypeId, OpportunityId
				FROM OpportunitySplit
				WHERE OpportunityId IN :map_OppToOwnerId.keySet() AND SplitTypeId = :OpportunityUtil.getSplitType(OpportunityUtil.SPLIT_TYPE_REVENUE)
			]) {
				List<OpportunitySplit> list_Splits = map_OpportunitySplit.containsKey(objSplit.OpportunityId) ? map_OpportunitySplit.get(objSplit.OpportunityId) : new List<OpportunitySplit>();
				// Add the split to the appropriate list
				list_Splits.add(objSplit);
				// Update the map with the new list
				map_OpportunitySplit.put(objSplit.OpportunityId, list_Splits);
			}
		}

		// Creating map of Account Id to it's associated ZP User Role records
		if (!set_AccountIdsForUserRoles.isEmpty()) {
			List<Zp_User_Role__c> list_ZPUserRoles = queryZPUserRoles(set_AccountIdsForUserRoles);

			for (Zp_User_Role__c objZPUserRole : list_ZPUserRoles) {
				if (!map_AccountIdToZPUserRoles.containsKey(objZPUserRole.Company_Account__c)) {
					map_AccountIdToZPUserRoles.put(objZPUserRole.Company_Account__c, new List<Zp_User_Role__c>{ objZPUserRole });
				} else {
					map_AccountIdToZPUserRoles.get(objZPUserRole.Company_Account__c).add(objZPUserRole);
				}
			}
		}

		// This block of code initialize two Map 1) map_CompanyIdToUserIdWithHIRole, 2) map_ZPUserIdToConactId
		if (!set_ZPCompanyId.isEmpty()) {
			Set<String> set_ZPUserId = new Set<String>();
			Map<String, String> map_UserIdToHIRole = new Map<String, String>();
			map_CompanyIdToUserIdWithHIRole = new Map<String, Map<String, String>>();

			//Pass set set_ZPCompanyId and get HI_Benefits_Admin__c records.
			//Add value in map_CompanyIdToUserIdWithHIRole as : Map<Company_Id__c, Map<ZP_User_Id__c,'Benefits Admin'>
			List<HI_Benefits_Admin__c> list_HIBenefitsAdmin = queryHIBenefitsAdmin(set_ZPCompanyId);
			for (HI_Benefits_Admin__c objHIBenefitsAdmin : list_HIBenefitsAdmin) {
				set_ZPUserId.add(objHIBenefitsAdmin.ZP_User_Id__c);

				if (!map_CompanyIdToUserIdWithHIRole.containsKey(objHIBenefitsAdmin.Company_Id__c)) {
					map_UserIdToHIRole = new Map<String, String>();
				} else {
					map_UserIdToHIRole = map_CompanyIdToUserIdWithHIRole.get(objHIBenefitsAdmin.Company_Id__c);
				}

				map_UserIdToHIRole.put(objHIBenefitsAdmin.ZP_User_Id__c, HIBenefitsUtil.BENEFIT_ADMIN);
				map_CompanyIdToUserIdWithHIRole.put(objHIBenefitsAdmin.Company_Id__c, map_UserIdToHIRole);
			}

			//Pass set set_ZPCompanyId and get HI_Benefits_Admin__c records.
			//Add value in map_CompanyIdToUserIdWithHIRole as : Map<Company_Id__c, Map<ZP_User_Id__c,'Benefits Signatory'>
			List<HI_Benefits_Signatory__c> list_HIBenefitsSignatory = queryHIBenefitsSignatory(set_ZPCompanyId);
			for (HI_Benefits_Signatory__c objHIBenefitsSignatory : list_HIBenefitsSignatory) {
				set_ZPUserId.add(objHIBenefitsSignatory.ZP_User_Id__c);

				if (!map_CompanyIdToUserIdWithHIRole.containsKey(objHIBenefitsSignatory.Company_Id__c)) {
					map_UserIdToHIRole = new Map<String, String>();
				} else {
					map_UserIdToHIRole = map_CompanyIdToUserIdWithHIRole.get(objHIBenefitsSignatory.Company_Id__c);
				}

				//If same (company_id & user_id) avaiabe in HI_Benefits_Signatory__c and HI_Benefits_Admin__c object then preference goes to HI_Benefits_Admin__c
				if (map_UserIdToHIRole.size() == 0 || !map_UserIdToHIRole.containsKey(objHIBenefitsSignatory.ZP_User_Id__c)) {
					map_UserIdToHIRole.put(objHIBenefitsSignatory.ZP_User_Id__c, HIBenefitsUtil.BENEFIT_SIGNATORY);
					map_CompanyIdToUserIdWithHIRole.put(objHIBenefitsSignatory.Company_Id__c, map_UserIdToHIRole);
				}
			}

			//Pass set of ZP_User_Id__c and get contact records.
			//Then add value in map_ZPUserIdToConactId as : Map<ZP_User_Id__c, contact.Id>.
			map_ZPUserIdToConactId = new Map<String, Id>();
			if (set_ZPUserId.size() > 0) {
				List<Contact> list_Contact = queryContact(set_ZPUserId);
				for (Contact objContact : list_Contact) {
					map_ZPUserIdToConactId.put(objContact.ZP_User_Id__c, objContact.Id);
				}
			}
		}

		if (!set_OpptyOwnerChange.isEmpty()) {
			List<Case> list_Cases = queryCases(set_OpptyOwnerChange);
			for (Case objCase : list_Cases) {
				List<Case> list_TempCases = map_OpptyIdToBenefitsCases.containsKey(objCase.Opportunity__c) ? map_OpptyIdToBenefitsCases.get(objCase.Opportunity__c) : new List<Case>();
				list_TempCases.add(objCase);
				map_OpptyIdToBenefitsCases.put(objCase.Opportunity__c, list_TempCases);
			}
		}

		if (!set_OpptyNotesChangeIds.isEmpty()) {
			List<Case> list_Cases = queryCases(set_OpptyNotesChangeIds);
			for (Case objCase : list_Cases) {
				List<Case> list_TempCases = map_OpptyIdToBenefitsCases.containsKey(objCase.Opportunity__c) ? map_OpptyIdToBenefitsCases.get(objCase.Opportunity__c) : new List<Case>();
				list_TempCases.add(objCase);
				map_OpptyIdToBenefitsCases.put(objCase.Opportunity__c, list_TempCases);
			}
		}

		if (!set_OpptyIds.isEmpty()) {
			List<Benefit_Order__c> list_Orders = queryBenefitOrders(set_OpptyIds);
			for (Benefit_Order__c objOrder : list_Orders) {
				List<Benefit_Order__c> list_TempOrders = map_OpptyIdToBenefitsOrders.containsKey(objOrder.Opportunity__c)
					? map_OpptyIdToBenefitsOrders.get(objOrder.Opportunity__c)
					: new List<Benefit_Order__c>();
				list_TempOrders.add(objOrder);
				map_OpptyIdToBenefitsOrders.put(objOrder.Opportunity__c, list_TempOrders);
			}
		}

		if (!set_OpptyRenewalSurveyIds.isEmpty()) {
			List<Renewal_Survey__c> list_Surveys = queryRenewalSurveys(set_OpptyRenewalSurveyIds);
			for (Renewal_Survey__c objSurvey : list_Surveys) {
				List<Renewal_Survey__c> list_TempSurveys = map_OpptyIdToRenewalSurveys.containsKey(objSurvey.Opportunity__c)
					? map_OpptyIdToRenewalSurveys.get(objSurvey.Opportunity__c)
					: new List<Renewal_Survey__c>();
				list_TempSurveys.add(objSurvey);
				map_OpptyIdToRenewalSurveys.put(objSurvey.Opportunity__c, list_TempSurveys);
			}
		}

		if (!set_MigrationReqOpptys.isEmpty()) {
			List<Order> list_Orders = queryOrders(set_MigrationReqOpptys);
			for (Order objOrder : list_Orders) {
				set_BulkMigrationIds.add(objOrder.Bulk_Migration__c);
			}
		}

		if (!set_StageChangeOpptys.isEmpty()) {
			List<Opportunity_Related_Tracking__c> list_OpptyRelatedTrackings = queryOpptyRelatedTracking(set_StageChangeOpptys);
			for (Opportunity_Related_Tracking__c objTracking : list_OpptyRelatedTrackings) {
				List<Opportunity_Related_Tracking__c> list_TempTrackings = map_OpptyIdToOpptyRelatedTrackings.containsKey(objTracking.Opportunity__c)
					? map_OpptyIdToOpptyRelatedTrackings.get(objTracking.Opportunity__c)
					: new List<Opportunity_Related_Tracking__c>();
				list_TempTrackings.add(objTracking);
				map_OpptyIdToOpptyRelatedTrackings.put(objTracking.Opportunity__c, list_TempTrackings);
			}
		}

		if (!set_LineItemOpptys.isEmpty()) {
			List<OpportunityLineItem> list_LineItems = queryOpptyLineItems(set_LineItemOpptys);
			for (OpportunityLineItem objLineItem : list_LineItems) {
				Map<String, OpportunityLineItem> map_TempLineItem = map_OpptyIdToMapofLineItem.containsKey(objLineItem.OpportunityId)
					? map_OpptyIdToMapofLineItem.get(objLineItem.OpportunityId)
					: new Map<String, OpportunityLineItem>();
				map_TempLineItem.put(objLineItem.Product2.Name, objLineItem);
				map_OpptyIdToMapofLineItem.put(objLineItem.OpportunityId, map_TempLineItem);
			}
			// when tier is premium and list of product is blank since company product is set to zero
			for (Id idOppty : set_LineItemOpptys) {
				if (!map_OpptyIdToMapofLineItem.containsKey(idOppty)) {
					map_OpptyIdToMapofLineItem.put(idOppty, new Map<String, OpportunityLineItem>());
				}
			}
		}

		if (!set_ClosedLostReopenedOppIds.isEmpty()) {
			List<Case> list_Cases = queryCases(set_ClosedLostReopenedOppIds);

			for (Case objCase : list_Cases) {
				if (objCase.Integration_Id__c?.startsWith('hippo-') && objCase.Status != CaseUtils.STATUS_CLOSED && set_BenefitsCaseRecordTypeIds?.contains(objCase.RecordTypeId)) {
					List<Case> list_TempCases = map_OpptyIdToCasesWithIntegrationId.containsKey(objCase.Opportunity__c)
						? map_OpptyIdToCasesWithIntegrationId.get(objCase.Opportunity__c)
						: new List<Case>();
					list_TempCases.add(objCase);
					map_OpptyIdToCasesWithIntegrationId.put(objCase.Opportunity__c, list_TempCases);
				} else {
					continue;
				}
			}
		}

		if (!set_ClosedLostReopenedOppIds.isEmpty()) {
			List<Benefit_Order__c> list_Orders = queryBenefitOrders(set_ClosedLostReopenedOppIds);
			for (Benefit_Order__c objOrder : list_Orders) {
				if (!set_CLosedBOStatuses.contains(objOrder.Order_Status__c)) {
					List<Benefit_Order__c> list_TempOrders = map_OpptyIdToOpenBenefitsOrders.containsKey(objOrder.Opportunity__c)
						? map_OpptyIdToOpenBenefitsOrders.get(objOrder.Opportunity__c)
						: new List<Benefit_Order__c>();
					list_TempOrders.add(objOrder);
					map_OpptyIdToOpenBenefitsOrders.put(objOrder.Opportunity__c, list_TempOrders);
				} else {
					continue;
				}
			}
		}

		//Creating Map of Order Allocation of Advising
		if (!set_Months.isEmpty() && !set_Years.isEmpty()) {
			map_AdvisingUserIdCap = FWManageRoleUtil.getAdvisingCapDetailsForRamping(set_Months, set_Years, new Set<Id>{ FWManageRoleUtil.ADVISING_BOA_RT_ID });

			map_HashOfAdvisingSkillWithUsers = FWManageRoleUtil.getAdvisingUserSkills(set_UWStatesPreviousYear, FWManageRoleUtil.set_AdvisorRoles);

			if (!map_HashOfAdvisingSkillWithUsers.isEmpty()) {
				map_AdvisingUserIdsWithSkillType = FWManageRoleUtil.map_UserIdsWithSkillType;
			}

			if (!map_AdvisingUserIdsWithSkillType.isEmpty()) {
				List<Opportunity> list_ActiveOpps = queryActiveOpportunitiesBasedOnUsers(
					map_AdvisingUserIdsWithSkillType.keySet(),
					new Set<String>{ OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID },
					new Set<String>{ OpportunityUtil.CLOSED_ADMIN_STAGE }
				);

				//set intial userId with count
				for (String strkey : map_AdvisingUserIdsWithSkillType.keySet()) {
					for (String objMonthYear : set_MonthYears) {
						map_AdvisingUserIdOppCount.put(strkey + '~' + objMonthYear, 0);
					}
				}

				if (!list_ActiveOpps.isEmpty()) {
					for (Opportunity objOpp : list_ActiveOpps) {
						String strKey = objOpp.OwnerId + '~' + objOpp.HI_Effective_Date__c.Month() + '~' + objOpp.HI_Effective_Date__c.Year();

						if (map_AdvisingUserIdOppCount.containsKey(strKey)) {
							map_AdvisingUserIdOppCount.put(strKey, map_AdvisingUserIdOppCount.get(strKey) + 1);
						}
					}
				}
			}
		}

		if (!set_MultiEINOpporunities.isEmpty()) {
			List<Opportunity> list_MultiEINOpps = queryMultiEINOpportunities(set_MultiEINOpporunities, new Set<String>{ OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID });

			for (Opportunity objOpp : list_MultiEINOpps) {
				if (
					(set_MultiEINOpporunities.contains(objOpp.Id) || set_MultiEINOpporunities.contains(objOpp.Parent_Opportunity__c)) &&
					!map_OpptyToOwnerIds.isEmpty() &&
					!map_OpptyToOwnerIds.containsKey(objOpp.Id)
				) {
					map_MultiEINOpptyToBeUpdated.put(objOpp.Id, objOpp);
				}
			}
		}

		if (!set_OpptysForTicket.isEmpty()) {
			List<Case> list_Cases = queryCases(set_OpptysForTicket);
			for (Case objCase : list_Cases) {
				List<Case> list_TempCases = map_OpptyIdToBenefitsCases.containsKey(objCase.Opportunity__c) ? map_OpptyIdToBenefitsCases.get(objCase.Opportunity__c) : new List<Case>();
				list_TempCases.add(objCase);
				map_OpptyIdToBenefitsCases.put(objCase.Opportunity__c, list_TempCases);
			}
		}

		if (map_ArdiusOpportunities.keySet() != null && !map_ArdiusOpportunities.keySet().IsEmpty()) {
			list_TicketsToUpdate = queryArdiusTickets(map_ArdiusOpportunities.keySet());
		}
		if (!set_ReopenOppIds.isEmpty()) {
			map_contactRolesByOppId = queryOpportunityContactsByRole(set_ReopenOppIds);
		}
	}

	/**
	 * @author      Deepika Saini
	 * @description Create Recertification ticket for renewal
	 * @param       objOppty New Opportunity
	 * @param       objOldOppty Old Opportunity
	 **/
	public Ticket__c createRecertificationTickets(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID && objOppty.Needs_Recertification__c != objOldOppty.Needs_Recertification__c && objOppty.Needs_Recertification__c) {
			Ticket__c objTicket = new Ticket__c();
			objTicket.Renewal_Date__c = objOppty.Renewal_Date__c;
			objTicket.Team__c = TicketUtil.TICKET_TEAM_ADVISING;
			objTicket.Escalation_Reason__c = TicketUtil.TICKET_REASON_RECERTIFICATION;
			objTicket.Carrier__c = objOppty.UW_Carrier_Previous_Year__c;

			if (String.isNotBlank(objOppty.UW_State_PY__c)) {
				objTicket.States__c = Utils.getStateCode(objOppty.UW_State_PY__c);
			}

			objTicket.Opportunity__c = objOppty.Id;
			objTicket.OwnerId = RECERTIFICATION_TEAM_QUEUE_ID;
			objTicket.Account__c = objOppty.AccountId;
			objTicket.Skip_Assignment__c = true;
			objTicket.RecordTypeId = TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID;

			if (map_OpptyIdToBenefitsCases.containsKey(objOppty.Id)) {
				List<Case> list_TempCases = map_OpptyIdToBenefitsCases.get(objOppty.Id);

				for (Case objCase : list_TempCases) {
					if (objCase.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_CASE_RT_ID && objCase.Integration_Id__c?.startsWith('hippo-') && objCase.Status != CaseUtils.STATUS_CLOSED) {
						objTicket.Case__c = objCase.Id;
						if (objCase.ContactId == null || String.isBlank(objCase.ContactEmail)) {
							objTicket.Recert_Status__c = TicketUtil.EMAIL_AUTOMATION_FAILED;
						}
						break;
					}
				}
			}

			return objTicket;
		}

		return null;
	}

	/**** Update MDR Activity on Opportunity ****/
	public void updateMDRActivity(Opportunity objOppty) {
		if (map_OpptyIdToTasks.containsKey(objOppty.OwnerId)) {
			List<Task> list_Tasks = map_OpptyIdToTasks.get(objOppty.OwnerId);

			for (Task objTask : list_Tasks) {
				String strTaskType = objTask.Type != null ? objTask.Type : '';

				if (
					(objTask.RecordType.DeveloperName == TaskUtil.TASK_DEMO_RT_ID || objTask.RecordType.DeveloperName == TaskUtil.TASK_CALL_RT_ID) &&
					(objTask.Status == TaskUtil.TASK_STATUS_CONNECT ||
					objTask.Status == TaskUtil.TASK_STATUS_COMPLETE)
				) {
					objOppty.MDR_Activity__c = true;
				}

				if (objTask.RecordType.DeveloperName == TaskUtil.TASK_DEMO_RT_ID || strTaskType.indexOf(TaskUtil.TASK_DEMO_RT_ID) > -1) {
					objOppty.MDR_Demo_Booked__c = true;
				}
			}
		}
	}

	/**** Create new opportunity line items ****/
	public void forceLineItemCreate(List<Opportunity> list_Opptys) {
		list_OLIToBeUpserted = new List<OpportunityLineItem>();
		// Create map of product name and list of pricebook entries
		for (Opportunity objOppty : list_Opptys) {
			PriceBook2 objPB = OpportunityUtil.getPriceBookById(objOppty.PriceBook2Id);
			Map<String, PriceBookEntry> map_Temp = new Map<String, PriceBookEntry>();
			for (PriceBookEntry objPBE : objPB.PriceBookEntries) {
				map_Temp.put(objPBE.Product2.Name, objPBE);
			}

			map_PBIdToMapOfProdNameToPBE.put(objPB.Id, map_Temp);
		}

		for (Opportunity objOppty : list_Opptys) {
			syncLineItems(objOppty, null);
		}

		if (!list_OLIToBeUpserted.isEmpty()) {
			upsert list_OLIToBeUpserted;
		}
	}

	/**** Create Opportunity Stage History record ****/
	public Opportunity_Stage_History__c createStageHistory(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOldOppty == null || objOppty.StageName != objOldOppty.StageName) {
			Opportunity_Stage_History__c objHistory = new Opportunity_Stage_History__c();
			objHistory.Opportunity__c = objOppty.Id;
			objHistory.End_Time__c = Datetime.now();
			objHistory.To_Stage__c = objOppty.StageName;

			if (objOldOppty == null) {
				objHistory.Start_Time__c = Datetime.now();
				objHistory.Opportunity_Creation__c = true;
			} else {
				objHistory.From_Stage__c = objOldOppty.StageName;
				objHistory.Start_Time__c = objOldOppty.Stage_Change_Date_Time__c;
			}
			return objHistory;
		}
		return null;
	}

	/*** Returns list of benefits cases related to an Oppty ***/
	public List<Case> updateCaseOwner(Opportunity objOppty) {
		List<Case> list_BenefitsCasesToUpdate = new List<Case>();
		if (map_OpptyIdToBenefitsCases.containsKey(objOppty.Id)) {
			List<Case> list_TempCases = map_OpptyIdToBenefitsCases.get(objOppty.Id);
			for (Case objCase : list_TempCases) {
				if (objCase.OwnerId != objOppty.OwnerId) {
					objCase.OwnerId = objOppty.OwnerId;
					list_BenefitsCasesToUpdate.add(objCase);
				}
			}
		}
		return list_BenefitsCasesToUpdate;
	}

	/**
	 * @author      Pravesh Rana
	 * @description Sync Notes__c field from Opp to Related case
	 * @param       Opportunity object instance
	 * @return      list of case
	 **/
	public List<Case> updateCaseNotes(Opportunity objOppty) {
		List<Case> list_BenefitsCasesToUpdate = new List<Case>();

		if (objOppty != null && map_OpptyIdToBenefitsCases.containsKey(objOppty.Id)) {
			List<Case> list_TempCases = map_OpptyIdToBenefitsCases.get(objOppty.Id);

			for (Case objCase : list_TempCases) {
				if (objCase.Notes__c != objOppty.Notes__c) {
					objCase.Notes__c = objOppty.Notes__c;
					list_BenefitsCasesToUpdate.add(objCase);
				}
			}
		}

		return list_BenefitsCasesToUpdate;
	}

	/*** Returns list of renewal surveys related to an Oppty ***/
	public List<Renewal_Survey__c> updateSurveyOwner(Opportunity objOppty) {
		List<Renewal_Survey__c> list_Surveys = new List<Renewal_Survey__c>();
		if (map_OpptyIdToRenewalSurveys.containsKey(objOppty.Id)) {
			List<Renewal_Survey__c> list_TempSurveys = map_OpptyIdToRenewalSurveys.get(objOppty.Id);
			for (Renewal_Survey__c objSurvey : list_TempSurveys) {
				if (objSurvey.OwnerId != objOppty.OwnerId) {
					objSurvey.OwnerId = objOppty.OwnerId;
					list_Surveys.add(objSurvey);
				}
			}
		}
		return list_Surveys;
	}

	/**
	 * @author      Deepika Saini
	 * @description Update Advising Owner for Multi EIN Records
	 * @param       objOppty New Opportunity
	 * @param       objOldOppty Old Opportunity
	 **/
	public void updateMultiEINOppsWithOwner(Opportunity objOppty, Opportunity objOldOppty) {
		if (
			OpportunityUtil.isEligibleForAdvisorAssignment(objOppty, objOldOppty) &&
			objOppty.Is_Multi_EIN__c &&
			!map_RenewalOpptyToBeUpdated.isEmpty() &&
			map_RenewalOpptyToBeUpdated.containsKey(objOppty.Id)
		) {
			for (Opportunity objRelOppty : map_MultiEINOpptyToBeUpdated.values()) {
				if (objRelOppty.Parent_Opportunity__c == objOppty.Id || objRelOppty.Id == objOppty.Parent_Opportunity__c || objRelOppty.Parent_Opportunity__c == objOppty.Parent_Opportunity__c) {
					objRelOppty.OwnerId = map_RenewalOpptyToBeUpdated.get(objOppty.Id).OwnerId;
					objRelOppty.Owner_Role_Name__c = map_RenewalOpptyToBeUpdated.get(objOppty.Id).Owner_Role_Name__c;
					objRelOppty.Advisor_Assignment__c = objOppty.Advisor_Assignment__c;
					objRelOppty.Advising_Assignment_Message__c = OpportunityUtil.MSG_ASSIGNEMENT_PROCESSED_AS_PER_SKILLS;
					map_RenewalOpptyToBeUpdated.put(objRelOppty.Id, objRelOppty);
				}
			}
		}
	}

	/**
	 * @description Creating to tasks to indicate thaat the company processed their first payroll
	 * @param  objOppty    objOppty description
	 * @param  objOldOppty objOldOppty description
	 * @return             created Tasks
	 */
	public List<Task> createTaskOnResellerAccounts(Opportunity objOppty, Opportunity objOldOppty) {
		List<Task> list_TasksToCreate = new List<Task>();

		if (objOldOppty.Joined_Date_Panda__c == null && objOppty.Joined_Date_Panda__c != null) {
			Id idResellerAcct = objOppty.Sold_by__c != null ? objOppty.Sold_by__c : objOppty.Referred_by__c;

			if (idResellerAcct != null && map_Accounts.containsKey(idResellerAcct)) {
				String strSubject = objOppty.AccountName__c + ' just processed payroll';
				list_TasksToCreate.add(
					new Task(
						Subject = strSubject,
						Type = TaskUtil.TASK_TYPE_EMAIL,
						Priority = TaskUtil.TASK_PRIORITY_LOW,
						Description = strSubject,
						Status = TaskUtil.TASK_STATUS_OPEN,
						ActivityDate = Date.today(),
						RecordTypeId = TaskUtil.TASK_STANDARD_RT_ID,
						WhatId = idResellerAcct,
						OwnerId = map_Accounts.get(idResellerAcct).OwnerId
					)
				);
			}
		}
		return list_TasksToCreate;
	}

	/*** Update or Insert Opportunity Related Tracking ***/
	public List<Opportunity_Related_Tracking__c> upsertOpptyRelatedTracking(Opportunity objOppty, Opportunity objOldOppty) {
		List<Opportunity_Related_Tracking__c> list_OpptyRelatedTrackings = new List<Opportunity_Related_Tracking__c>();
		if (objOppty.StageName != objOldOppty.StageName) {
			if (map_OpptyIdToOpptyRelatedTrackings.containsKey(objOppty.Id)) {
				List<Opportunity_Related_Tracking__c> list_TempTrackings = map_OpptyIdToOpptyRelatedTrackings.get(objOppty.Id);
				for (Opportunity_Related_Tracking__c objTracking : list_TempTrackings) {
					if ((objTracking.First_Stage_Change_Date__c == null && objTracking.Opp_Stage_Changed__c == false)) {
						objTracking.Opp_Stage_Changed__c = true;
						list_OpptyRelatedTrackings.add(objTracking);
					}
				}
			} else {
				list_OpptyRelatedTrackings.add(createOpptyRelatedTracking(objOppty));
			}
		}
		return list_OpptyRelatedTrackings;
	}

	/**
	 * @description pdate Benefit Orders
	 * @param  objOppty    objOppty description
	 * @param  objOldOppty objOldOppty description
	 */
	public void updateBenefitOrders(Opportunity objOppty, Opportunity objOldOppty) {
		Set<Id> set_BOIdsForClosedTickets = new Set<Id>();
		if (
			objOppty.Benefits_Current_Setup_Step__c != objOldOppty.Benefits_Current_Setup_Step__c &&
			objOppty.Benefits_Current_Setup_Step__c == BenefitOrderUtil.OPPTY_BENEFITS_SETUP_AWAIT_OFFERINGS_STEP &&
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID &&
			(objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE && objOppty.Async_Renewal__c || objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE) &&
			map_OpptyIdToBenefitsOrders.containsKey(objOppty.Id)
		) {
			List<Benefit_Order__c> list_BenefitOrders = map_OpptyIdToBenefitsOrders.get(objOppty.Id);
			for (Benefit_Order__c objOrder : list_BenefitOrders) {
				if (
					objOrder.RecordTypeId == BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID ||
					objOrder.RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID ||
					objOrder.RecordTypeId == BenefitOrderUtil.RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID
				) {
					if (
						objOppty.Benefits_Current_Setup_Step__c == 'Answering Survey' &&
						objOppty.StageName == 'SAL' &&
						objOrder.RecordTypeId == BenefitOrderUtil.RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID
					) {
						objOrder.Order_Status__c = 'New';
					} else if (
						objOrder.Order_Status__c == 'New' &&
						objOppty.StageName == 'Alignment In Progress' &&
						objOppty.Benefits_Current_Setup_Step__c == 'Awaiting Offerings' &&
						objOrder.RecordTypeId == BenefitOrderUtil.RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID
					) {
						objOrder.Order_Status__c = 'Ready for alignment';
					} else if (
						objOrder.Order_Status__c != 'Canceled' &&
						objOrder.Order_Status__c != 'Closed Lost' &&
						objOrder.Order_Status__c != 'Closed Admin' &&
						objOrder.Order_Status__c != 'Denied' &&
						objOrder.RecordTypeId != BenefitOrderUtil.RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID
					) {
						objOrder.Order_Status__c = 'With Advising';
					}

					map_BenefitOrdersToUpdate.put(objOrder.Id, objOrder);
				}
			}
		}

		if (
			(objOppty.AccountId != objOldOppty.AccountId ||
			objOppty.HI_Effective_Date__c != objOldOppty.HI_Effective_Date__c ||
			objOppty.Waiting_Period__c != objOldOppty.Waiting_Period__c ||
			(objOppty.Benefits_Current_Setup_Step__c == 'Dismissed' &&
			objOppty.Benefits_Current_Setup_Step__c != objOldOppty.Benefits_Current_Setup_Step__c)) && map_OpptyIdToBenefitsOrders.containsKey(objOppty.Id)
		) {
			List<Benefit_Order__c> list_Orders = map_OpptyIdToBenefitsOrders.get(objOppty.Id);

			for (Benefit_Order__c objOrder : list_Orders) {
				if (objOppty.AccountId != objOldOppty.AccountId) {
					objOrder.Account__c = objOppty.AccountId;
				}

				if (objOppty.HI_Effective_Date__c != objOldOppty.HI_Effective_Date__c && objOrder.Closed__c == false) {
					objOrder.Coverage_Effective_Date__c = objOppty.HI_Effective_Date__c;
					if (objOrder.Coverage_Effective_Date__c != null && objOrder.Push_Rate_Reason__c == null) {
						objOrder.Push_Rate_Reason__c = 'Other';
					}
				}

				if (objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.DISMISSED_SETUP_STEP && objOppty.Benefits_Current_Setup_Step__c != objOldOppty.Benefits_Current_Setup_Step__c) {
					objOrder.Order_Status__c = OpportunityUtil.CLOSED_LOST_STAGE;

					if (String.isBlank(objOrder.Status_Detail__c)) {
						objOrder.Status_Detail__c = OpportunityUtil.DISMISSED_STAGE_DETAIL;
					}

					set_BOIdsForClosedTickets.add(objOrder.Id);
				}

				map_BenefitOrdersToUpdate.put(objOrder.Id, objOrder);
			}
		}

		if (
			(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID) &&
			map_OpptyIdToBenefitsOrders != null &&
			map_OpptyIdToBenefitsOrders.containsKey(objOppty.Id) &&
			objOppty.Maestro__c != objOldOppty.Maestro__c
		) {
			List<Benefit_Order__c> list_Orders = map_OpptyIdToBenefitsOrders.get(objOppty.Id);
			for (Benefit_Order__c objOrder : list_Orders) {
				objOrder.Maestro__c = objOppty.Maestro__c;
				map_BenefitOrdersToUpdate.put(objOrder.Id, objOrder);
			}
		}

		if (set_BOIdsForClosedTickets.size() > 0) {
			Map<Id, Ticket__c> map_OpenTicketsWithBO = BenefitOrderUtil.fetchOpenTicketsRelatedToBO(set_BOIdsForClosedTickets);
			for (Id idTicket : map_OpenTicketsWithBO.keySet()) {
				Ticket__c objTicket = map_OpenTicketsWithBO.get(idTicket);
				objTicket.Close_Reason__c = Label.Dismissed_Ticket_Closed_Reason;
				objTicket.Status__c = TicketUtil.TICKET_STATUS_CLOSED;
			}

			update map_OpenTicketsWithBO.values();
		}
	}

	/**
	 * @description Sync (Create/Update/Delete) Opportunity Products
	 * @param  objOppty    objOppty description
	 * @param  objOldOppty objOldOppty description
	 */
	public void syncLineItems(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnSkipLineItemCreation = false;
		/*** Deletes Line Items when Pricing on Oppty does not match with Pricing on Account (runs after update) ****/
		// if (
		// 	objOldOppty != null &&
		// 	objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
		// 	(objOldOppty.StageName != objOppty.StageName &&
		// 	objOppty.StageName != OpportunityUtil.CLOSED_ADMIN_STAGE) &&
		// 	!objOppty.Is_Invoiced__c &&
		// 	map_Accounts.containsKey(objOppty.AccountId)
		// ) {
		// 	Account objAccnt = map_Accounts.get(objOppty.AccountId);
		// 	PriceBook2 objAccntPriceBook = OpportunityUtil.getPriceBookByName(objAccnt.Pricing__c);

		// 	if (objAccntPriceBook != null && objOppty.PriceBook2Id != objAccntPriceBook.Id && map_OpptyIdToMapofLineItem.containsKey(objOppty.Id)) {
		// 		blnSkipLineItemCreation = true;
		// 		Opportunity objOpptyClone = objOppty.clone(true, true, false, false);
		// 		objOpptyClone.PriceBook2Id = objAccntPriceBook.Id;
		// 		map_OppsToBeUpdated.put(objOppty.Id, objOpptyClone);
		// 		for (OpportunityLineItem objLineItem : map_OpptyIdToMapofLineItem.get(objOppty.Id).values()) {
		// 			list_OLIToBeDeleted.add(objLineItem);
		// 		}
		// 	}
		// }

		// if (
		// 	!blnSkipLineItemCreation &&
		// 	objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
		// 	objOppty.StageName != OpportunityUtil.CLOSED_ADMIN_STAGE &&
		// 	objOppty.Pricebook2Id != null &&
		// 	!objOppty.Locked__c &&
		// 	map_PBIdToMapOfProdNameToPBE.containsKey(objOppty.Pricebook2Id)
		// ) {
		// 	// get opportunity pricebook
		// 	Pricebook2 objPriceBook = OpportunityUtil.getPriceBookById(objOppty.Pricebook2Id);
		// 	// create list of additional services
		// 	String strAdditionalOpportunityServices = String.isBlank(objOppty.Additional_Opportunity_Services__c) ? '' : objOppty.Additional_Opportunity_Services__c;
		// 	List<String> list_AdditionalServices = strAdditionalOpportunityServices.split(';');

		// 	// if pricing changes, create a new entry to map of opportunity and opportunity line items
		// 	if (objOldOppty != null && objOppty.PriceBook2Id != objOldOppty.Pricebook2Id && !map_OpptyIdToMapofLineItem.containsKey(objOppty.Id)) {
		// 		map_OpptyIdToMapofLineItem.put(objOppty.Id, new Map<String, OpportunityLineItem>{});
		// 	}

		// 	for (PricebookEntry objPBE : objPriceBook.PriceBookEntries) {
		// 		// get each product
		// 		String strProdName = objPBE.Product2?.Name;
		// 		String strProductType = objPBE.Product2?.Product_Type__c;
		// 		String strProductCategory = objPBE.Product2?.Product_Category__c;

		// 		// product name and product category are required
		// 		if (String.isNotBlank(strProdName) && String.isNotBlank(strProductType)) {
		// 			// Decide quantity based on product type
		// 			Decimal decQuantity = 0;
		// 			if (strProductType == OpportunityUtil.PRODUCT_TYPE_MONTHLY) {
		// 				decQuantity = 1;
		// 			} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_EMPLOYEES) {
		// 				decQuantity = objOppty.NumberOfEmployees__c != null && objOppty.NumberOfEmployees__c > 0 ? objOppty.NumberOfEmployees__c : 0;
		// 			} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_CONTRACTORS) {
		// 				decQuantity = objOppty.Number_of_Contractors__c != null && objOppty.Number_of_Contractors__c > 0 ? objOppty.Number_of_Contractors__c : 0;
		// 			} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_INTERNATIONAL_CONTRACTORS) {
		// 				decQuantity = objOppty.International_Contractors__c != null && objOppty.International_Contractors__c > 0 ? objOppty.International_Contractors__c : 0;
		// 			} else if (strProductType == OpportunityUtil.PRODUCT_TYPE_INTERNATIONAL_EMPLOYESS) {
		// 				decQuantity = objOppty.International_Employees__c != null && objOppty.International_Employees__c > 0 ? objOppty.International_Employees__c : 0;
		// 			}

		// 			// Company Opportunity Product
		// 			if (strProductCategory == OpportunityUtil.PRODUCT_CATEGORY_PAYROLL) {
		// 				if (strProductType == OpportunityUtil.PRODUCT_TYPE_MONTHLY) {
		// 					// Monthly Base Fee
		// 					if (objOldOppty == null || (map_OpptyIdToMapofLineItem.containsKey(objOppty.Id) && !map_OpptyIdToMapofLineItem.get(objOppty.Id).containsKey(strProdName))) {
		// 						list_OLIToBeUpserted.add(new OpportunityLineItem(OpportunityId = objOppty.Id, PriceBookEntryId = objPBE.Id, UnitPrice = objPBE.UnitPrice, Quantity = decQuantity));
		// 					}
		// 				} else {
		// 					createOrUpdateLineItems(objOppty, objOldOppty, strProdName, decQuantity);
		// 				}
		// 			} else if (String.isNotBlank(strProductCategory)) {
		// 				// Additional Services Opportunity Product
		// 				if (list_AdditionalServices.contains(strProductCategory)) {
		// 					createOrUpdateLineItems(objOppty, objOldOppty, strProdName, decQuantity);
		// 				} else if (map_OpptyIdToMapofLineItem.containsKey(objOppty.Id) && map_OpptyIdToMapofLineItem.get(objOppty.Id).containsKey(strProdName)) {
		// 					OpportunityLineItem objLineItem = map_OpptyIdToMapofLineItem.get(objOppty.Id).get(strProdName);
		// 					list_OLIToBeDeleted.add(objLineItem);
		// 				}
		// 			}
		// 		}
		// 	}
		// }
	}

	/**
	 * @description Generic method to create or update line items
	 * @author      Praveen Sethu
	 * @param       Opportunity objOppty - Trigger.new opportunity
	 * @param       Opportunity objOldOppty - Trigger.old opportunity
	 * @param       String strProductName - Product name
	 * @param       String decQuantity - Quantity on line item
	 * @param       String blnQuantityChanged - Indicates if value changed on field
	 * @return      NA
	 **/
	public void createOrUpdateLineItems(Opportunity objOppty, Opportunity objOldOppty, String strProductName, Decimal decQuantity) {
		PriceBookEntry objPBE = map_PBIdToMapOfProdNameToPBE.get(objOppty.Pricebook2Id).get(strProductName);
		if (
			objPBE != null &&
			(objOldOppty == null || (map_OpptyIdToMapofLineItem.containsKey(objOppty.Id) && !map_OpptyIdToMapofLineItem.get(objOppty.Id).containsKey(strProductName))) &&
			decQuantity != null &&
			decQuantity > 0
		) {
			list_OLIToBeUpserted.add(new OpportunityLineItem(OpportunityId = objOppty.Id, PriceBookEntryId = objPBE.Id, UnitPrice = objPBE.UnitPrice, Quantity = decQuantity));
		} else if (objOldOppty != null && map_OpptyIdToMapofLineItem.containsKey(objOppty.Id) && map_OpptyIdToMapofLineItem.get(objOppty.Id).containsKey(strProductName)) {
			OpportunityLineItem objLineItem = map_OpptyIdToMapofLineItem.get(objOppty.Id).get(strProductName);

			if (decQuantity == null || decQuantity == 0) {
				list_OLIToBeDeleted.add(objLineItem);
			} else if (objPBE != null && decQuantity != null && decQuantity > 0 && decQuantity != objLineItem.Quantity) {
				objPBE = map_PBIdToMapOfProdNameToPBE.get(objOppty.Pricebook2Id).get(strProductName);
				objLineItem.Quantity = decQuantity;
				objLineItem.UnitPrice = objPBE.UnitPrice;
				// Ensuring we are not adding duplicate Line Item Ids
				if (objLineItem.Id != null && !set_OLIToBeUpdatedIds.contains(objLineItem.Id)) {
					list_OLIToBeUpserted.add(objLineItem);
					set_OLIToBeUpdatedIds.add(objLineItem.Id);
				}
			}
		}
	}

	/**
	 * @description Sets reseller account for metrics calculation
	 * @author      Praveen Sethu
	 * @param       objOppty - Trigger new object & objOldOppty - Trigger old object
	 * @return      NA
	 **/
	public void calculateResellerMetrics(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnRecalculate = false;
		// opp insert
		if (objOldOppty == null) {
			// if sold by or referred by is not null - calculate reseller metrics
			if (objOppty.Sold_By__c != null || objOppty.Referred_By__c != null) {
				blnRecalculate = true;
			}
		} else {
			// if sold by or referred by changes or stage changes to CW or CL - culate reseller metrics
			if (
				(objOppty.Sold_By__c != objOldOppty.Sold_By__c) ||
				(objOppty.Referred_By__c != objOldOppty.Referred_By__c) ||
				(objOppty.StageName != objOldOppty.StageName && (objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE || objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE))
			) {
				blnRecalculate = true;
			}
		}

		// if recalculate flag is true - set re calculate metrics on sold by and referred
		if (blnRecalculate) {
			// set sold by account for update
			if (objOppty.Sold_By__c != null) {
				Account objSoldByAccount = map_AccountsToUpdate.containsKey(objOppty.Sold_By__c) ? map_AccountsToUpdate.get(objOppty.Sold_By__c) : map_Accounts.get(objOppty.Sold_By__c);
				if (objSoldByAccount != null) {
					objSoldByAccount.Calculate_Reseller_Metrics__c = true;
					map_AccountsToUpdate.put(objSoldByAccount.Id, objSoldByAccount);
				}
			}

			// Add old sold by account and set calculate metrics to true
			if (objOldOppty != null && objOldOppty.Sold_By__c != null && map_Accounts.containsKey(objOldOppty.Sold_By__c)) {
				Account objOldSoldBy = map_Accounts.get(objOldOppty.Sold_By__c);
				objOldSoldBy.Calculate_Reseller_Metrics__c = true;
				map_AccountsToUpdate.put(objOldSoldBy.Id, objOldSoldBy);
			}

			// set referred by account for update
			if (objOppty.Referred_By__c != null) {
				Account objReferredByAcc = map_AccountsToUpdate.containsKey(objOppty.Referred_By__c) ? map_AccountsToUpdate.get(objOppty.Referred_By__c) : map_Accounts.get(objOppty.Referred_By__c);
				if (objReferredByAcc != null) {
					objReferredByAcc.Calculate_Reseller_Metrics__c = true;
					map_AccountsToUpdate.put(objReferredByAcc.Id, objReferredByAcc);
				}
			}

			// Add old referred by account and set calculate metrics to true
			if (objOldOppty != null && objOldOppty.Referred_By__c != null && map_Accounts.containsKey(objOldOppty.Referred_By__c)) {
				Account objOldReferredBy = map_Accounts.get(objOldOppty.Referred_By__c);
				objOldReferredBy.Calculate_Reseller_Metrics__c = true;
				map_AccountsToUpdate.put(objOldReferredBy.Id, objOldReferredBy);
			}
		}
	}

	/**** Roll-Up values from Opportunity level to Account level for accounts tied to the Opportunity ****/
	public void rollUpValuesToAccounts(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);
		User objOwner = map_AllUsers.get(objOppty.OwnerId);
		// upsert account related tracking
		if (objOppty.Sold_By__c != null || objOppty.Referred_By__c != null) {
			if (objOppty.Sold_By__c != null && map_Accounts.containsKey(objOppty.Sold_By__c) && (objOldOppty == null || objOppty.Sold_By__c != objOldOppty.Sold_By__c)) {
				Account objSoldByAcc = map_Accounts.get(objOppty.Sold_By__c);
				Account_Related_Tracking__c objAccTrack = new Account_Related_Tracking__c(Unique_Account_Id__c = objSoldByAcc.Id, Account__c = objSoldByAcc.Id);

				objAccTrack.Last_Client_Change_Date__c = Datetime.now();

				map_AccIdToTrackingToUpsert.put(objSoldByAcc.Id, objAccTrack);
			}

			if (objOppty.Referred_By__c != null && map_Accounts.containsKey(objOppty.Referred_By__c) && (objOldOppty == null || objOppty.Referred_By__c != objOldOppty.Referred_By__c)) {
				Account objReferredByAcc = map_Accounts.get(objOppty.Referred_By__c);
				Account_Related_Tracking__c objAccTrack = new Account_Related_Tracking__c(Unique_Account_Id__c = objReferredByAcc.Id, Account__c = objReferredByAcc.Id);

				objAccTrack.Last_Client_Change_Date__c = Datetime.now();

				map_AccIdToTrackingToUpsert.put(objReferredByAcc.Id, objAccTrack);
			}
		}

		if (objOldOppty == null) {
			// Update Partner Status (for Company Opportunity that is Closed Won)
			if ((objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) && objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE) {
				if (objOppty.Sold_By__c != null && map_Accounts.containsKey(objOppty.Sold_By__c)) {
					Account objAccnt = map_Accounts.get(objOppty.Sold_By__c);
					objAccnt.Partner_Status__c = 'Active Partner';
					objAccnt.Last_Client_CW_Date__c = Date.today();
					map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
				}
				if (objOppty.Referred_By__c != null && map_Accounts.containsKey(objOppty.Referred_By__c)) {
					Account objAccnt = map_Accounts.get(objOppty.Referred_By__c);
					objAccnt.Partner_Status__c = 'Active Partner';
					objAccnt.Last_Client_CW_Date__c = Date.today();
					map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
				}
			} else if (blnTierUpsellOpp && objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && !objOppty.isClosed) {
				Account objAccnt = map_Accounts.get(objOppty.AccountId);
				objAccnt.Upsell_Opp_Open__c = true;
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}

			// sync benefits setup steps completed from opportunity to account
			if (objOppty.Set_Up_Steps_Completed__c != null && objOppty.Set_Up_Steps_Completed__c > 0) {
				Account objAccnt = map_AccountsToUpdate.containsKey(objOppty.AccountId) ? map_AccountsToUpdate.get(objOppty.AccountId) : map_Accounts.get(objOppty.AccountId);
				if (objAccnt != null) {
					objAccnt.Set_Up_Steps_Completed__c = objOppty.Set_Up_Steps_Completed__c;
					map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
				}
			}
		} else if (objOldOppty != null && map_Accounts.containsKey(objOppty.AccountId)) {
			Account objAccnt = map_Accounts.get(objOppty.AccountId);
			/**** Updates Benefits Notes on Account ****/
			if (
				String.isNotBlank(objOppty.Benefits_Notes__c) &&
				objOppty.IsClosed == false &&
				objOppty.Benefits_Notes__c != objOldOppty.Benefits_Notes__c &&
				map_Accounts.containsKey(objOppty.AccountId) &&
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			) {
				objAccnt.Benefits_Notes__c = objOppty.Benefits_Notes__c;
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}

			/*** Update Initiated_NP_Flow__c on Account ****/
			if (
				String.isBlank(objAccnt.Initiated_NP_Flow__c) &&
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID &&
				objOldOppty.Selecting_Employee_Eligibility_Start__c == null &&
				objOppty.Selecting_Employee_Eligibility_Start__c != null &&
				String.isNotBlank(objOppty.Users_Email__c)
			) {
				objAccnt.Initiated_NP_Flow__c = objOppty.Users_Email__c;
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}

			/*** Sync Big Desk CSM Pitch Status on Account ****/
			if (String.isNotBlank(objOppty.Big_Desk_CSM_Pitch_Status__c) && objOppty.Big_Desk_CSM_Pitch_Status__c != objAccnt.Big_Desk_CSM_Pitch_Status__c) {
				objAccnt.Big_Desk_CSM_Pitch_Status__c = objOppty.Big_Desk_CSM_Pitch_Status__c;
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}

			// sync benefits setup steps completed from opportunity to account
			if (objOppty.Set_Up_Steps_Completed__c != objAccnt.Set_Up_Steps_Completed__c && objOppty.Set_Up_Steps_Completed__c != objOldOppty.Set_Up_Steps_Completed__c) {
				objAccnt.Set_Up_Steps_Completed__c = objOppty.Set_Up_Steps_Completed__c;
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}
		}

		// Track the account in some collection for DML
		if (objOppty.AccountId != null) {
			Account objAccnt = map_Accounts.get(objOppty.AccountId);

			// Update the most recent Payroll Oppty owner at the account level for Distribution Engine (Insert or when owner is changed)
			if (
				objOwner != null &&
				(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) &&
				objOwner.UserRoleId != null &&
				!UserUtils.isAdminIntgUser(objOppty.OwnerId) &&
				(objAccnt.Payroll_Opp_Owner__c != objOwner.Name ||
				objAccnt.Payroll_Opp_Owner_Role__c != objOwner.UserRole.Name)
			) {
				objAccnt.Payroll_Opp_Owner__c = objOwner.Name;
				objAccnt.Payroll_Opp_Owner_Role__c = objOwner.UserRole.Name;
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}

			// If Account has a Benefits Opportunity set Has Benefits Oppty flag on Account to TRUE
			if (
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) &&
				(objOldOppty == null ||
				objOppty.RecordTypeId != objOldOppty.RecordTypeId)
			) {
				objAccnt.Has_Benefits_Oppty__c = true;
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}
		}
		//checking of any open upsell tier.
		if (objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID) {
			boolean blnIntlPayrollOpenUpsellTier = false;
			boolean blnOpenUpsellTier = false;
			boolean blnExistingOpenUpsellTier = false;
			boolean blnExistingIntlPayrollOpenUpsellTier = false;
			Account objAccnt = map_Accounts.get(objOppty.AccountId);

			if (!objOppty.isClosed) {
				if (objOppty.Upsell_Tier__c != null && objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
					blnIntlPayrollOpenUpsellTier = true;
				} else if (!objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
					blnOpenUpsellTier = true;
				}
			}

			//checking if any existing Cross-Sell and Upsell is open.
			if (objAccnt.Opportunities != null && !objAccnt.Opportunities.isEmpty()) {
				for (Opportunity objExistingOpp : objAccnt.Opportunities) {
					if (objExistingOpp.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && !objExistingOpp.isClosed) {
						if (objExistingOpp.Upsell_Tier__c != null && objExistingOpp.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
							//specific check for the Employer of Record Cross-Sell and Upsell.
							blnExistingIntlPayrollOpenUpsellTier = true;
						} else if (!objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
							blnExistingOpenUpsellTier = true;
						}
					}
				}
			}

			//Indicates the types of Cross-Sell and Upsell opportunities that are Open
			/**
			 * If an Open Cross-Sell and Upsell has a Upsell Tier of Employer of Record, then Employer of Record.
			 * If an Open Cross-Sell and Upsell has a Upsell Tier of Tier or Tier then Cross-Sell and Upsell.
			 * If an Open Cross-Sell and Upsell has a Upsell Tier of Tier or Tier, there is another Open Cross-Sell and Upsell with an Upsell Tier of Employer of Record, then Employer of Record and Cross-Sell and Upsell.
			 * If there are no Open Cross-Sell and Upsell opportunities, then the field has no values.
			 */

			if ((blnIntlPayrollOpenUpsellTier || blnExistingIntlPayrollOpenUpsellTier) && (blnExistingOpenUpsellTier || blnOpenUpsellTier)) {
				if (objAccnt.Upsell_Tier_Opps_Open__c != OpportunityUtil.INTERNATIONAL_PAYROLL_AND_TIER_UPSELL) {
					objAccnt.Upsell_Tier_Opps_Open__c = OpportunityUtil.INTERNATIONAL_PAYROLL_AND_TIER_UPSELL;
					map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
				}
			} else if ((blnIntlPayrollOpenUpsellTier || blnExistingIntlPayrollOpenUpsellTier) && !blnExistingOpenUpsellTier && !blnOpenUpsellTier) {
				if (objAccnt.Upsell_Tier_Opps_Open__c != AccountUtil.EMPLOYER_OF_RECORD) {
					objAccnt.Upsell_Tier_Opps_Open__c = AccountUtil.EMPLOYER_OF_RECORD;
					map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
				}
			} else if (!blnIntlPayrollOpenUpsellTier && !blnExistingIntlPayrollOpenUpsellTier && (blnExistingOpenUpsellTier || blnOpenUpsellTier)) {
				if (objAccnt.Upsell_Tier_Opps_Open__c != OpportunityUtil.TIER_UPSELL) {
					objAccnt.Upsell_Tier_Opps_Open__c = OpportunityUtil.TIER_UPSELL;
					map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
				}
			} else if (String.isNotBlank(objAccnt.Upsell_Tier_Opps_Open__c)) {
				//Indicates the types of Cross-Sell and Upsell opportunities that are Open
				objAccnt.Upsell_Tier_Opps_Open__c = '';
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}
		}
	}

	/**** Create Opportunity Related Tracking for Opportunity if applicable ****/
	public Opportunity_Related_Tracking__c createOpptyRelatedTracking(Opportunity objOppty) {
		Opportunity_Related_Tracking__c objTracking = new Opportunity_Related_Tracking__c();
		objTracking.Opportunity__c = objTracking.Unique_Opp_Id__c = objOppty.Id;
		objTracking.Created_At__c = objOppty.CreatedDate;
		return objTracking;
	}

	/**** Create case(s) tied to Opportunity if applicable ****/
	public List<Case> createCases(Opportunity objOppty) {
		List<Case> listCases = new List<Case>();

		if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
			Case objCase = new Case();
			objCase.AccountId = objOppty.AccountId;
			objCase.Opportunity__c = objOppty.Id;
			// 'Hippo'
			objCase.Origin = OpportunityUtil.HIPPO_ORIGIN;

			/* Assigning the first Oppportunity Contact Role contact to case.
			 Benfits Admin/Benefits Signatory ideally should be populated otherwise payroll admins.*/
			if (!list_TempContactRoles.isEmpty()) {
				objCase.ContactId = list_TempContactRoles[0].ContactId;
			}

			if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID) {
				objCase.RecordTypeId = OpportunityUtil.BENEFITS_CHANGE_CASE_RT_ID;
				objCase.Subject = 'Gusto benefits change';
				objCase.Description = 'Gusto benefits change';
				objCase.Integration_Id__c = 'hippo-Benefits_Change-' + objOppty.Id;
			}

			if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
				set_RenewalOppIds.add(objOppty.Id);
				objCase.RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_CASE_RT_ID;
				objCase.Subject = 'Gusto benefits renewal';
				objCase.Description = 'Gusto benefits renewal';
				objCase.Integration_Id__c = 'hippo-Benefits_Renewal-' + objOppty.Id;
				objCase.UW_State_PY__c = objOppty.UW_State_PY__c;
				objCase.UW_Carrier_PY__c = objOppty.UW_Carrier_PY__c;
				objCase.UW_Carrier_Previous_Year__c = objOppty.UW_Carrier_Previous_Year__c;

				if (objOppty.Async_Renewal__c && benefitOrderMap.containsKey(objOppty.Id)) {
					Benefit_Order__c objOrder = benefitOrderMap.get(objOppty.Id);

					// Additional alignment Case
					Case objAlignmentCase = new Case(
						AccountId = objOppty.AccountId,
						Origin = OpportunityUtil.HIPPO_ORIGIN,
						OwnerId = objOrder.OwnerId,
						Opportunity__c = objOppty.Id,
						RecordTypeId = OpportunityUtil.BENEFITS_RENEWAL_CASE_RT_ID,
						Subject = 'Gusto Benefits Renewal Alignment',
						Description = 'Gusto Benefits Renewal Alignment',
						Type = 'Benefits Renewal alignment',
						Status = 'new',
						Priority = 'Medium',
						Requires_Action__c = true,
						Benefit_Order__c = objOrder.Id
					);
					listCases.add(objAlignmentCase);
				}
			}

			Database.DMLOptions objDMO = new Database.DMLOptions();
			objDMO.assignmentRuleHeader.useDefaultRule = true;

			objCase.setOptions(objDMO);
			listCases.add(objCase);
		}

		return listCases;
	}

	/**** Add Contact Roles to the Opportunity ****/
	public List<OpportunityContactRole> createContactRoles(Opportunity objOppty, Opportunity objOldOppty) {
		List<OpportunityContactRole> list_ContactRoles = new List<OpportunityContactRole>();
		Boolean blnHIBenefitAdminFound = false;
		Integer intPrimaryRoleIndex = 0;
		Map<String, Set<Id>> map_ContactRoles = !map_contactRolesByOppId.isEmpty() && map_contactRolesByOppId.ContainsKey(objOppty.Id)
			? map_contactRolesByOppId.get(objOppty.Id)
			: new Map<String, Set<Id>>();
		if (
			(objOppty != null && objOldOppty == null) ||
			(objOldOppty != null &&
			objOppty.StageName != objOldOppty.StageName &&
			OpportunityUtil.set_OppCloseStageName.contains(objOldOppty.StageName) &&
			!OpportunityUtil.set_OppCloseStageName.contains(objOppty.StageName))
		) {
			if (OpportunityUtil.isBenefits(objOppty) || OpportunityUtil.isCustomerSuccess(objOppty) || OpportunityUtil.isTierUpsell(objOppty)) {
				if (map_AccountIdToZPUserRoles.containsKey(objOppty.AccountId)) {
					// Iterating Zp User Roles for the Account to create Opportunity Contact Roles
					for (Zp_User_Role__c objZPUserRole : map_AccountIdToZPUserRoles.get(objOppty.AccountId)) {
						Boolean isContactRoleAlreadyExist = map_ContactRoles?.containsKey(objZPUserRole.Role_Name__c) &&
							map_ContactRoles.get(objZPUserRole.Role_Name__c)?.contains(objZPUserRole.Contact__c)
							? true
							: false;
						//If Role Name is equals to 'Benefits Admin' or  'Benefits Signatory' then skip it.
						//Because we will process these two in "HI Benefits Admin" and "HI Benefits Signatory".
						if (!isContactRoleAlreadyExist) {
							if (
								String.isNotBlank(objZPUserRole.Role_Name__c) &&
								objZPUserRole.Role_Name__c != HIBenefitsUtil.BENEFIT_ADMIN &&
								objZPUserRole.Role_Name__c != HIBenefitsUtil.BENEFIT_SIGNATORY
							) {
								list_ContactRoles.add(new OpportunityContactRole(OpportunityId = objOppty.Id, ContactId = objZPUserRole.Contact__c, Role = objZPUserRole.Role_Name__c));
							} else if (
								objZPUserRole.Role_Name__c == ZPUserRoleTriggerHelper.PRIMARY_PAYROLL_ADMIN ||
								objZPUserRole.Role_Name__c == ZPUserRoleTriggerHelper.PAYROLL_ADMIN ||
								objZPUserRole.Role_Name__c == ZPUserRoleTriggerHelper.ACCOUNTANT ||
								objZPUserRole.Role_Name__c == ZPUserRoleTriggerHelper.SIGNATORY
							) {
								list_ContactRoles.add(new OpportunityContactRole(OpportunityId = objOppty.Id, ContactId = objZPUserRole.Contact__c, Role = objZPUserRole.Role_Name__c));
							}
						}
					}
				}

				if (String.isNotBlank(objOppty.ZP_Company_ID_from_Account__c) && map_CompanyIdToUserIdWithHIRole.containsKey(objOppty.ZP_Company_ID_from_Account__c)) {
					intPrimaryRoleIndex = list_ContactRoles.size();
					Id idContact = null;

					//Process OpportunityContactRole, when Role Name is equals to 'Benefits Admin' or  'Benefits Signatory'.
					Map<String, String> map_UserIdWithHIRole = map_CompanyIdToUserIdWithHIRole.get(objOppty.ZP_Company_ID_from_Account__c);
					for (String strZPUserId : map_UserIdWithHIRole.keySet()) {
						if (String.isNotBlank(strZPUserId) && map_ZPUserIdToConactId.containsKey(strZPUserId)) {
							idContact = map_ZPUserIdToConactId.get(strZPUserId);
							Boolean isContactRoleAlreadyExistForZpUser = map_ContactRoles?.containsKey(map_UserIdWithHIRole.get(strZPUserId)) &&
								map_ContactRoles.get(map_UserIdWithHIRole.get(strZPUserId))?.contains(idContact)
								? true
								: false;
							if (!isContactRoleAlreadyExistForZpUser) {
								if (!blnHIBenefitAdminFound) {
									intPrimaryRoleIndex = intPrimaryRoleIndex + 1;
								}

								if (HIBenefitsUtil.BENEFIT_ADMIN == map_UserIdWithHIRole.get(strZPUserId)) {
									blnHIBenefitAdminFound = true;
								}
								list_ContactRoles.add(new OpportunityContactRole(OpportunityId = objOppty.Id, IsPrimary = false, ContactId = idContact, Role = map_UserIdWithHIRole.get(strZPUserId)));
							}
						}
					}
				}
			}
		}
		//Define one contact role as a Primary.
		if (list_ContactRoles.size() > 0) {
			if (blnHIBenefitAdminFound) {
				list_ContactRoles[intPrimaryRoleIndex - 1].IsPrimary = true;
			} else {
				list_ContactRoles[0].IsPrimary = true;
			}
		}
		return list_ContactRoles;
	}

	/**
	 * @description Update Closed Owner Role when Opportunity is closed
	 * @param  objOppty    new Opportunity
	 * @param  objOldOppty old Opportunity
	 */
	public void updateClosedOwnerRole(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty.IsClosed && (objOldOppty == null || !objOldOppty.IsClosed) && map_Users.containsKey(objOppty.OwnerId)) {
			objOppty.Closed_By_Opportunity_Owner_Role__c = map_Users.get(objOppty.OwnerId).UserRole.Name;
		}
	}

	/**** Process Lead Source to update Sold By/BizDev Partner fields ****/
	public void processLeadSource(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);
		// Company Opportunity
		if ((objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) && String.isNotBlank(objOppty.LeadSource)) {
			// Populate Sold By
			if (objOppty.Sold_By__c == null) {
				if (objOppty.LeadSource.containsIgnoreCase('bench')) {
					objOppty.Sold_By__c = OpportunityUtil.benchAccountId;
				} else if (objOppty.LeadSource.containsIgnoreCase('clarus')) {
					objOppty.Sold_By__c = OpportunityUtil.clarusAccountId;
				}
			}

			// Populate BizDev Partner if it's blank or if Lead Source has changed
			if ((objOppty.BizDev_Partner__c == null || objOppty.LeadSource != objOldOppty.LeadSource) && map_SourceNameToPartnerReferral.containsKey(objOppty.LeadSource.toLowerCase())) {
				objOppty.BizDev_Partner__c = map_SourceNameToPartnerReferral.get(objOppty.LeadSource.toLowerCase()).BizDev_Account__c;
			}
		}

		if (objOldOppty == null) {
			// Opportunity added by Partner Program
			if (objOppty.Sold_By__c != null && String.isBlank(objOppty.LeadSource) && objOppty.RecordTypeId != OpportunityUtil.CUSTOMER_SUCCESS_RT_ID) {
				objOppty.LeadSource = OpportunityUtil.ADDED_BY_ACCOUNTANT;
			}

			// Benefits Opportunity created by App
			if (String.isBlank(objOppty.LeadSource)) {
				if (
					(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) && (String.isNotBlank(objOppty.Source_ID__c) && UserUtils.isAdminIntgUser(UserInfo.getUserId()))
				) {
					objOppty.LeadSource = OpportunityUtil.APP_GENERATED;
				} else if (
					(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
					objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) && !UserUtils.isAdminIntgUser(UserInfo.getUserId())
				) {
					User objUser = map_Users.get(UserInfo.getUserId());
					if (String.isNotBlank(objUser?.UserRole?.Name)) {
						for (Role_Lead_Source_Map__mdt objRoleLeadSource : Role_Lead_Source_Map__mdt.getAll().values()) {
							if (objRoleLeadSource.MasterLabel == objUser.UserRole.Name) {
								objOppty.LeadSource = objRoleLeadSource.Lead_Source__c;
								break;
							}
						}
					}

					if (String.isBlank(objOppty.LeadSource)) {
						objOppty.LeadSource = OpportunityUtil.MANUAL;
					}
				}
			}
		}
	}

	/**** Update Remaining Onboarding Steps ****/
	public void updateOnboardingSteps(Opportunity objOppty) {
		String strNextSteps = '';

		if (!objOppty.ZP_Add_Company_Addresses__c) {
			strNextSteps += 'Add Company Addresses, ';
		}

		if (!objOppty.ZP_Add_Employees__c) {
			strNextSteps += 'Add Employees, ';
		}

		if (!objOppty.ZP_Set_Up_Federal_Taxes__c) {
			strNextSteps += 'Set Up Federal Taxes, ';
		}

		if (!objOppty.ZP_Set_Up_State_Taxes__c) {
			strNextSteps += 'Set Up State Taxes, ';
		}

		if (!objOppty.ZP_Set_Up_Bank_Account__c) {
			strNextSteps += 'Set Up Bank Account, ';
		}

		if (!objOppty.ZP_Select_a_Payroll_Schedule__c) {
			strNextSteps += 'Select a Payroll Schedule, ';
		}

		if (!objOppty.ZP_Report_Previous_Paystubs__c && objOppty.Is_Historical__c) {
			strNextSteps += 'Report Previous Paystubs, ';
		}

		if (!objOppty.ZP_Add_Signatory__c) {
			strNextSteps += 'Add Signatory, ';
		}

		if (!objOppty.ZP_Sign_Company_Forms__c) {
			strNextSteps += 'Sign Company Forms, ';
		}

		if (!objOppty.ZP_Verify_Company_Bank_Account__c) {
			strNextSteps += 'Verify Company Bank Account, ';
		}

		if (!objOppty.ZP_Enter_Unpaid_Tax_Liabilities__c && objOppty.Is_Historical__c) {
			strNextSteps += 'Enter Unpaid Tax Liabilities, ';
		}

		if (strNextSteps.endsWith(', ')) {
			strNextSteps = strNextSteps.removeEnd(', ');
		}

		objOppty.Remaining_Onboarding_Steps__c = strNextSteps;

		// Update Next Onboarding Step on Contact
		updateNextOnBoardingStep(objOppty.Id, strNextSteps);
	}

	/**
	 * 	* @description Update Next Onboarding Step on Contact
	 *  * @param  opportunityId Opportunity Id
	 *  * @param  nextOnBoardingStep Next Onboarding Step
	 */
	public static void updateNextOnBoardingStep(String opportunityId, String nextOnBoardingStepCommaSeparated) {
		// Query to get the OpportunityContactRole with the given OpportunityId
		List<OpportunityContactRole> contactRoles = [SELECT Contact.Id, Contact.Name, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :opportunityId AND IsPrimary = TRUE LIMIT 1];
		OpportunityContactRole contactRole = null;
		if (!contactRoles.isEmpty()) {
			contactRole = contactRoles[0];
		} else {
			return;
		}

		// Check if a contact exists
		if (contactRole != null && contactRole.Contact != null) {
			// Set the Next_OnBoarding_Step__c field on the Contact object
			Contact contactToUpdate = contactRole.Contact;
			contactToUpdate.Next_OnBoarding_Step__c = getNextOnboardingSteps(nextOnBoardingStepCommaSeparated);

			// Try to update the contact and handle any errors
			try {
				ContactTriggerHelper.SkipTrigger = true;
				update contactToUpdate;
				ContactTriggerHelper.SkipTrigger = false;
			} catch (DmlException e) {
				Exception_Log__c objLog = new Exception_Log__c(
					Type__c = 'ERROR',
					Class_Name__c = 'OpporunityTriggerHelper',
					Method_Name__c = 'updateNextOnBoardingStep',
					Record_ID__c = opportunityId,
					Message__c = e.getMessage()
				);
			}
		}
	}

	// Get the next onboarding step from the comma separated list
	private static String getNextOnboardingSteps(String nextOnBoardingStepCommaSeparated) {
		String defaultValue = 'Onboarding Steps Completed';
		if (String.isBlank(nextOnBoardingStepCommaSeparated)) {
			return defaultValue;
		}
		List<String> parts = nextOnBoardingStepCommaSeparated.split(',');
		if (parts != null && parts.size() > 0) {
			return parts[0].trim();
		} else {
			return defaultValue;
		}
	}
	/**** Scoring complexity of Benefits Renewal (Advising Fulfillment) ****/
	public void complexityScoringAdvisingFulfillment(Opportunity objOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
			Integer intCounter = 0;

			//Check for TADA
			if (objOppty.FSA_Renewal__c || objOppty.DCA_Renewal__c) {
				intCounter += 2;
			}
			if (objOppty.HSA_Renewal__c) {
				intCounter++;
			}

			//Check for Lines of Coverage
			if (objOppty.Medical_Renewal__c) {
				intCounter++;
			}
			if (objOppty.Dental_Renewal__c) {
				intCounter++;
			}
			if (objOppty.Vision_Renewal__c) {
				intCounter++;
			}
			if (objOppty.Short_Term_Disability_Renewal__c) {
				intCounter++;
			}
			if (objOppty.Life_Renewal__c) {
				intCounter++;
			}
			if (objOppty.Long_Term_Disability_Renewal__c) {
				intCounter++;
			}
			if (objOppty.Voluntary_Life__c) {
				intCounter++;
			}

			objOppty.AF_Complexity_Scoring__c = intCounter;
		}
	}

	/**** Create default OpportnuityLineItems on Benefits opportunities records insert ****/
	public List<OpportunityLineItem> createBenefitsOpportunityLineItems(Opportunity objOppty) {
		Map<String, List<String>> map_OppRectypeProducts = new Map<String, List<String>>();
		Set<String> set_Products = new Set<String>();
		List<OpportunityLineItem> list_BenefitsOppLineItems = new List<OpportunityLineItem>();
		Map<String, PriceBookEntry> map_PricebookEntries = new Map<String, PriceBookEntry>();
		map_OppRectypeProducts = OpportunityUtil.getBenefitsDefaultProductsMetadata();

		if (!map_OppRectypeProducts.isEmpty() && map_OppRectypeProducts.containsKey(objOppty.Opportunity_Record_Type_Name__c)) {
			set_Products.addAll(map_OppRectypeProducts.get(objOppty.Opportunity_Record_Type_Name__c));
		}

		if (!set_Products.isEmpty()) {
			map_PricebookEntries = PricebookQueryHelper.getPriceBookEntryRecords(set_Products);
		}

		if (!map_PricebookEntries.isEmpty()) {
			for (String strProductName : set_Products) {
				String strKey = objOppty.Pricebook2Id + '-' + strProductName;
				if (map_PricebookEntries.containsKey(strKey)) {
					PriceBookEntry objBenefitsSalesPaymentPlan = map_PricebookEntries.get(strKey);
					list_BenefitsOppLineItems.add(buildOppLineItem(objOppty.Id, objBenefitsSalesPaymentPlan, objOppty.NumberOfEmployees__c));
				}
			}
		}
		return list_BenefitsOppLineItems;
	}

	/**** Update Benefits opportunity Employees field count on OpportunityLineItem ****/
	public void updateBenefitsOppLineItemQuantity(Set<Id> set_EmployeeNumberUpdatedOpps, List<Opportunity> list_Opportunities) {
		Map<Id, Opportunity> map_Oppty = new Map<Id, Opportunity>(list_Opportunities);
		Map<Id, List<OpportunityLineItem>> map_ExistingLineItems = new Map<Id, List<OpportunityLineItem>>();

		// First query what we have in the database and build a map of opportunity Id and list of line items
		for (OpportunityLineItem objItem : queryOpptyLineItems(set_EmployeeNumberUpdatedOpps)) {
			if (!map_ExistingLineItems.containsKey(objItem.OpportunityId)) {
				map_ExistingLineItems.put(objItem.OpportunityId, new List<OpportunityLineItem>());
			}
			map_ExistingLineItems.get(objItem.OpportunityId).add(objItem);
		}

		// Now iterate over the opportunities and create line items for those that don't have any AND delete line items for those that have more than one
		for (Id idOppty : set_EmployeeNumberUpdatedOpps) {
			Opportunity objOppty = map_Oppty.get(idOppty);
			if (objOppty != null) {
				// delete operation if employees is 0
				if ((objOppty.NumberOfEmployees__c == null || objOppty.NumberOfEmployees__c == 0)) {
					if (map_ExistingLineItems.containsKey(objOppty.Id)) {
						list_OLIToBeDeleted.addAll(map_ExistingLineItems.get(objOppty.Id));
					}
				} else {
					List<OpportunityLineItem> list_LineItemsToUpsert = createBenefitsOpportunityLineItems(objOppty);
					Map<Id, OpportunityLineItem> map_ExistingPricebookEntries = new Map<Id, OpportunityLineItem>();
					// Build of map of pricebook entry Id and line item - createBenefitsOpportunityLineItems is called to know the actual pricebook entry that we need to create
					for (OpportunityLineItem objLineItem : list_LineItemsToUpsert) {
						map_ExistingPricebookEntries.put(objLineItem.PricebookEntryId, objLineItem);
					}

					// Iterate over existing line items and update quantity and unit price
					if (map_ExistingLineItems.containsKey(objOppty.Id)) {
						for (OpportunityLineItem objExistingLineItem : map_ExistingLineItems.get(objOppty.Id)) {
							// if line item is found in map_ExistingPricebookEntries - then update the quantity and unit price
							objExistingLineItem.Quantity = objOppty.NumberOfEmployees__c;
							objExistingLineItem.UnitPrice = objExistingLineItem.PricebookEntry.UnitPrice;
							list_OLIToBeUpserted.add(objExistingLineItem);
						}
					} else {
						// If no line item is found - add all the line items to be upserted (newly created)
						list_OLIToBeUpserted.addAll(map_ExistingPricebookEntries.values());
					}
				}
			}
		}
	}

	/**** Reset Benefits opportunity Fundinng Type field to blank if no product on opportunity ****/
	public void resetBenefitsFundingType(Opportunity objOppty, Opportunity objOldOppty) {
		if (
			OpportunityUtil.isBenefits(objOppty) &&
			objOldOppty != null &&
			objOppty.Amount == 0 &&
			objOppty.Amount != objOldOppty.Amount &&
			objOppty.RecordTypeId != OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID
		) {
			objOppty.Funding_Type__c = '';
		}
	}

	/**** Update Benefits opportunity Funding Type ****/
	public void updateBenefitsFundingType(Map<Id, Opportunity> map_Oppty) {
		Map<String, List<String>> map_OppRectypeProducts = new Map<String, List<String>>();
		List<String> list_FullyFundedOppTypes = new List<String>{ OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID, OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID, OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID };

		for (OpportunityLineItem objOLI : queryOpptyLineItems(set_AmountUpdatedOpps)) {
			Opportunity objOpp = map_Oppty.get(objOLI.OpportunityId);
			if (objOLI.Product2Id != null && OpportunityUtil.LEVEL_FUNDED_BOR.equals(objOLI.Product2.Name)) {
				objOpp.Funding_Type__c = OpportunityUtil.LEVEL_FUNDED_TYPE;
			} else if (list_FullyFundedOppTypes.contains(objOpp.RecordTypeId)) {
				objOpp.Funding_Type__c = OpportunityUtil.FULLY_INSURED_TYPE;
			} else {
				objOpp.Funding_Type__c = '';
			}
		}
	}

	/**** Update Number of Employees ****/
	public void updateEmployeeCounts(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOldOppty != null) {
			if (
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID ||
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID) &&
				objOppty.Completed__c != null &&
				objOldOppty.Completed__c == null
			) {
				objOppty.EE_Active_Count_At_Win__c = objOppty.NumberOfEmployees__c;
				objOppty.Benefits_Flow_Completed_Count__c = objOppty.Benefits_Flow_Completed_Count__c == null ? 1 : objOppty.Benefits_Flow_Completed_Count__c + 1;
			}

			//Update number of EE on benefits opp if CL to CW or CL to open status - BT-13031
			if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) {
				//validate stage change
				if (
					objOldOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE &&
					objOppty.StageName != objOldOppty.StageName &&
					objOppty.StageName != OpportunityUtil.ORDER_LOST_STAGE &&
					objOppty.StageName != OpportunityUtil.CLOSED_ADMIN_STAGE &&
					objOppty.AccountId != null &&
					map_Accounts.containsKey(objOppty.AccountId)
				) {
					Account objAccnt = map_Accounts.get(objOppty.AccountId);
					objOppty.NumberOfEmployees__c = objAccnt.Number_Of_Active_Employees__c;
				}
			}
		}

		// Company Opportunity : Copying Payment Invoice info to Opportunity
		// if (
		// 	(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID ||
		// 	objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) &&
		// 	objOppty.Payment_Invoice__c != null &&
		// 	map_PaymentInvoices.containsKey(objOppty.Payment_Invoice__c) &&
		// 	String.isNotBlank(objOppty.Source_ID__c) &&
		// 	(objOldOppty == null ||
		// 	objOppty.Payment_Invoice__c != objOldOppty.Payment_Invoice__c)
		// ) {
		// 	Payment_Invoice__c objInvoice = map_PaymentInvoices.get(objOppty.Payment_Invoice__c);
		// 	objOppty.EE_Active_Count_At_Win__c = objInvoice.Employee_Count__c;
		// 	objOppty.NumberOfEmployees__c = objInvoice.Employee_Count__c;
		// 	objOppty.Number_of_Contractors__c = objInvoice.Contractor_Count__c;
		// }

		if (objOppty.AccountId != null) {
			Account objAccnt = map_Accounts.get(objOppty.AccountId);

			// Sync Number of Employees, Number of Contractors and Pricing when opportunity is updated from Closed Lost to Closed Won
			// if (
			// 	objOldOppty != null &&
			// 	objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID &&
			// 	objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE &&
			// 	objOldOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE
			// ) {
			// 	objOppty.NumberOfEmployees__c = objAccnt.Number_of_Active_Employees__c;
			// 	objOppty.Number_of_Contractors__c = objAccnt.Number_of_Active_Contractors__c;
			// }

			// Benefits BoR Flow is Completed for Pending PR
			if (
				objOldOppty != null &&
				objOppty.Closed_Won_Eligible__c &&
				!objOldOppty.Closed_Won_Eligible__c &&
				objOppty.StageName == OpportunityUtil.PENDING_PR_STAGE &&
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID &&
				objOppty.Signing_Forms_Completed_Timestamp__c != null
			) {
				if (objAccnt.Number_of_Active_Employees__c != null && objAccnt.Number_of_Active_Employees__c != 0) {
					objOppty.NumberOfEmployees__c = objAccnt.Number_of_Active_Employees__c;
					objOppty.EE_Active_Count_At_Win__c = objAccnt.Number_of_Active_Employees__c;
				}
				objOppty.Benefits_Flow_Completed_Count__c = objOppty.Benefits_Flow_Completed_Count__c == null ? 1 : objOppty.Benefits_Flow_Completed_Count__c + 1;
			}

			// Set number of employees on insert for benefits opportunity
			if (
				objOldOppty == null &&
				objOppty != null &&
				(objOppty.NumberOfEmployees__c == null ||
				objOppty.NumberOfEmployees__c == 0) &&
				objAccnt.Number_of_Active_Employees__c != null &&
				objAccnt.Number_of_Active_Employees__c > 0 &&
				OpportunityUtil.set_BenefitRTChangeEmployees.contains(objOppty.RecordTypeId)
			) {
				objOppty.NumberOfEmployees__c = objAccnt.Number_of_Active_Employees__c;
			}

			if (objOldOppty == null && objOppty.RecordTypeId == OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID) {
				objOppty.NumberOfEmployees__c = objAccnt.Number_of_Active_Employees__c;
				objOppty.Number_of_Contractors__c = objAccnt.Number_of_Active_Contractors__c;
			}
		}

		// Track employees when Won
		if (objOldOppty == null || objOppty.IsWon != objOldOppty.IsWon) {
			if (objOppty.IsWon) {
				objOppty.EE_Active_Count_At_Win__c = objOppty.NumberOfEmployees__c;
			} else {
				objOppty.EE_Active_Count_At_Win__c = null;
			}
		}
	}

	/**** Update MDR related info ****/
	public void updateMDRInfo(Opportunity objOppty, Opportunity objOldOppty) {
		User objOwner = map_Users.get(objOppty.OwnerId);
		User objOldOwner = objOldOppty != null ? map_Users.get(objOldOppty.OwnerId) : null;

		// If Current Owner is MDR and (Is Insert or If Owner has changed)
		if (
			objOwner != null &&
			objOwner.UserRoleId != null &&
			objOwner.UserRole.Name.containsIgnoreCase('mdr') &&
			objOldOwner != null &&
			(objOldOppty == null ||
			objOppty.OwnerId != objOldOppty.OwnerId)
		) {
			objOppty.MDR__c = objOppty.OwnerId;
			objOppty.MDR_Lead_Owner_Role__c = objOwner.UserRole.Name;

			// Setting only on Insert and if previous owner was not MDR
			if (objOldOppty == null || (objOldOwner.UserRoleId != null && !objOldOwner.UserRole.Name.containsIgnoreCase('mdr'))) {
				objOppty.MDR_Received__c = Datetime.now();
			}
		}

		// On Update if ownership is changed and Old Owner is MDR and new Owner is not MDR
		// 03-11-2020 Yuvraj 		Added null check for userroleid
		if (objOldOppty != null && objOppty.OwnerId != objOldOppty.OwnerId && objOldOwner != null && objOldOwner.UserRoleId != null) {
			objOppty.Previous_Owner_Role__c = objOldOwner.UserRole.Name;
			objOppty.OldOwner_Email__c = objOldOwner.Email;

			if (
				objOwner != null &&
				objOwner.UserRoleId != null &&
				!objOwner.UserRole.Name.containsIgnoreCase('mdr') &&
				objOldOwner.UserRoleId != null &&
				objOldOwner.UserRole.Name.containsIgnoreCase('mdr')
			) {
				objOppty.MDR_Passed__c = Datetime.now();
			}
		}
	}

	/**** Update Owner ****/
	public void updateOwner(Opportunity objOppty) {
		User objOwner = map_Users.get(objOppty.OwnerId);

		if (
			objOwner != null &&
			objOwner.Is_Api_Integration__c &&
			(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
		) {
			objOppty.OwnerId = (Id) Label.Advising_Team_User;
		}

		// update hi owner on benefits opportunity
		if (
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
			((objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) &&
			objOppty.Type != OpportunityUtil.OPPTY_TYPE_RENEWAL_BYB)
		) {
			if (objOppty.AccountId != null && map_Accounts.containsKey(objOppty.AccountId) && map_Accounts.get(objOppty.AccountId).HI_Owner__c != null) {
				Account objAcc = map_Accounts.get(objOppty.AccountId);

				if (objAcc.HI_Owner__c != null && map_AllUsers.containsKey(objAcc.HI_Owner__c)) {
					User objHIOwner = map_AllUsers.get(objAcc.HI_Owner__c);
					String strHIOwnerRole = objHIOwner?.UserRole?.Name;

					if (HI_SALES_ALL_ROLES.containsIgnoreCase(strHIOwnerRole)) {
						objOppty.OwnerId = map_Accounts.get(objOppty.AccountId).HI_Owner__c;
					}
				}
			}
		}
	}

	/**** Update Owner Role related info ****/
	public void updateOwnerRoleInfo(Opportunity objOppty, Opportunity objOldOppty) {
		User objOwner = map_AllUsers.containsKey(objOppty.OwnerId) ? map_AllUsers.get(objOppty.OwnerId) : null;

		if (objOwner != null) {
			// Add Owner's manager if available on User and not populated on Opportunity when Opportunity Is Won
			if (objOppty.IsWon && objOppty.Owner_Manager__c == null && objOwner.ManagerId != null) {
				objOppty.Owner_Manager__c = objOwner.ManagerId;
			}

			// Insert or if owner has changed
			if (objOldOppty == null || (objOppty.OwnerId != objOldOppty.OwnerId) || (objOppty.StageName != objOldOppty.StageName && objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE)) {
				// If Owner has a UserRole
				if (objOwner.UserRoleId != null) {
					objOppty.Owner_Role__c = objOwner.UserRole.Name;

					// Only Populated for Sales Opportunities at Insert
					if (objOldOppty == null && OpportunityUtil.isSales(objOppty)) {
						objOppty.Original_Created_by_Role__c = objOwner.UserRole.Name;
					}
				}

				objOppty.Owner_Department__c = objOwner.Department != null ? objOwner.Department : '';
				objOppty.Owner_Division__c = objOwner.Division != null ? objOwner.Division : '';
				objOppty.Owner_Title__c = objOwner.Title != null ? objOwner.Title : '';
			}
		}
	}

	/**** Copy and truncate value of Description as needed ****/
	public void copyDescription(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOldOppty == null || objOppty.Description != objOldOppty.Description) {
			if (String.isNotBlank(objOppty.Description) && objOppty.Description.length() > 255) {
				objOppty.Description_Copy__c = objOppty.Description.substring(0, 255);
			} else {
				objOppty.Description_Copy__c = objOppty.Description;
			}
		}
	}

	/**** Set some additional fields ****/
	public void setMiscellaneous(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);
		if (objOppty.Set_Up_Steps_Completed__c != null && (objOldOppty == null || (objOldOppty != null && objOppty.Set_Up_Steps_Completed__c != objOldOppty.Set_Up_Steps_Completed__c))) {
			objOppty.Setup_Steps_Completed_HT__c = objOppty.Set_Up_Steps_Completed__c;
		}

		// Benefits Renewal
		if (
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID &&
			((objOldOppty == null && objOppty.Renewal_Date__c != null) || (objOldOppty != null && objOppty.Renewal_Date__c != objOldOppty.Renewal_Date__c))
		) {
			objOppty.HI_Effective_Date__c = objOppty.Renewal_Date__c;
		}

		// Company Opportunity
		if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) {
			// Sold By and/or Referred By populated
			if (
				objOppty.Joined_Date_Panda__c != null &&
				objOppty.Joined_Date_Panda__c.daysBetween(Date.today()) <= 30 &&
				((objOppty.Sold_By__c != null && objOldOppty != null && objOldOppty.Sold_By__c == null) ||
				(objOppty.Referred_By__c != null &&
				objOldOppty != null &&
				objOldOppty.Referred_By__c == null))
			) {
				objOppty.Send_Slack_to_Reseller__c = true;
			}
		}

		// Benefits BOR (When Signing_Forms_Completed_Timestamp__c is populated)
		if (
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID &&
			objOppty.Signing_Forms_Completed_Timestamp__c != null &&
			(objOldOppty == null ||
			objOldOppty.Signing_Forms_Completed_Timestamp__c == null)
		) {
			objOppty.Initial_BoR_Forms_Signed_DateTime__c = objOppty.Signing_Forms_Completed_Timestamp__c;
		}

		if (objOldOppty != null) {
			// Qualify opportunity
			if (objOppty.Probability >= OpportunityUtil.QUALIFY_PROBABILITY && objOppty.Oppty_Qualified_Flag__c == 'No') {
				objOppty.Oppty_Qualified_Date__c = Date.today();
				objOppty.Oppty_Qualified_Flag__c = 'Yes';
			}
			// ROE Exception Timestamp
			if (objOppty.ROE_Exception__c != objOldOppty.ROE_Exception__c) {
				objOppty.ROE_Exception_Date__c = Datetime.now();
			}
		}
	}

	/**
	 * @description Set Setting Advisor Assignment field for Big desk Opportunities
	 * @author      Deepika Saini
	 * @param       objOppty New Opportunity
	 * @param       objOldOppty Old Opportunity
	 **/
	public void setAdvisorAssignment(Opportunity objOppty, Opportunity objOldOppty) {
		//Insert
		if (objOldOppty == null) {
			//Set default Advisor Assignment
			if (!OpportunityUtil.SKIP_BIG_DESK_ASSIGNMENT && objOppty.Big_Desk_BenOps__c) {
				if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
					objOppty.Advisor_Assignment__c = OpportunityUtil.BIG_DESK_ADVISOR_ASSIGNMENT;
				}
			}
		}
	}

	/**** Setting Stage Name ****/
	public void setStage(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);
		// To keep track of present value of Stage
		String strStage = objOppty.StageName;
		// Insert
		if (objOldOppty == null) {
			// Setting default stage
			if (String.isBlank(objOppty.StageName)) {
				// SAL
				if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
					objOppty.StageName = OpportunityUtil.MQL_STAGE;
				} else if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) {
					// Raw
					objOppty.StageName = OpportunityUtil.DEFAULT_HI_SALES_STAGE;
				} else if (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) {
					// SAL
					objOppty.StageName = OpportunityUtil.NEW_STAGE;
				}
			}

			if (objOppty.Async_Renewal__c) {
				// Alignment In Progress
				if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
					objOppty.StageName = OpportunityUtil.ALIGNMENT_SALES_STAGE;
				}
			} else {
				// SAL
				if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID) {
					objOppty.StageName = OpportunityUtil.SAL_STAGE;
				}
			}

			// BT-38060 - Set Stage to 'ER Confirm' when Benefits Current Setup Step is 'Completed' or 'Complete'
			if (
				objOppty.Benefits_Current_Setup_Step__c != null &&
				((OpportunityUtil.set_BenefitRTUpdateStage.contains(objOppty.RecordTypeId) &&
				(objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP ||
				objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETE_BENEFITSCURRENTSTEP)) ||
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID &&
				objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.FORMSSIGNED_BENEFITSCURRENTSTEP))
			) {
				objOppty.StageName = OpportunityUtil.ER_CONFIRM_STAGE;
				objOppty.ER_Confirm_TimeStamp__c = Datetime.now();
			}
		} else {
			// Update
			if (
				(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) &&
				!objOppty.IsClosed &&
				objOppty.ZP_Company_Suspended__c &&
				!objOldOppty.ZP_Company_Suspended__c
			) {
				objOppty.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
				objOppty.Stage_Detail__c = OpportunityUtil.UNQUALIFIED_STAGE_DETAIL;
			}
			// ER Confirm Logic
			if (objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE) {
				if (
					(objOppty.Benefits_Current_Setup_Step__c != objOldOppty.Benefits_Current_Setup_Step__c &&
					((objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID &&
					objOppty.StageName != OpportunityUtil.ER_CONFIRM_STAGE &&
					objOppty.StageName != OpportunityUtil.PENDING_PR_STAGE &&
					objOppty.Benefits_Current_Setup_Step__c != null &&
					(objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP ||
					objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETE_BENEFITSCURRENTSTEP)) ||
					((objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID) &&
					(objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP ||
					objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETE_BENEFITSCURRENTSTEP)))) ||
					(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID &&
					objOppty.StageName != OpportunityUtil.PENDING_PR_STAGE &&
					objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.FORMSSIGNED_BENEFITSCURRENTSTEP &&
					objOldOppty.Benefits_Current_Setup_Step__c != OpportunityUtil.FORMSSIGNED_BENEFITSCURRENTSTEP)
				) {
					objOppty.StageName = OpportunityUtil.ER_CONFIRM_STAGE;
					objOppty.ER_Confirm_TimeStamp__c = Datetime.now();
					// Slack Notifications not enabled for BOR Sales team
					if (objOppty.RecordTypeId != OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) {
						objOppty.SlackNotificationPending__c = true;
					}
				}
			}

			if (
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID &&
				objOppty.Benefits_Current_Setup_Step__c != 'Completed' &&
				objOppty.Benefits_Current_Setup_Step__c != 'Complete'
			) {
				if (objOppty.Recommendation_Sent_Start__c != null && (objOldOppty == null || objOppty.Recommendation_Sent_Start__c != objOldOppty.Recommendation_Sent_Start__c)) {
					objOppty.StageName = OpportunityUtil.RECOMMENDATION_SENT_STAGE;
				}

				if (
					objOppty.Selecting_Offerings_Start__c != null &&
					objOppty.Benefits_Current_Setup_Step__c != 'Closed Won' &&
					objOppty.StageName != OpportunityUtil.CLOSED_LOST_STAGE &&
					objOppty.StageName != OpportunityUtil.CLOSED_ADMIN_STAGE &&
					objOppty.Selecting_Offerings_Start__c != objOldOppty.Selecting_Offerings_Start__c
				) {
					objOppty.StageName = OpportunityUtil.ENGAGED_STAGE;
				}
			}
		}

		// Dismissed
		if (
			objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.DISMISSED_SETUP_STEP &&
			(objOldOppty == null ||
			objOppty.Benefits_Current_Setup_Step__c != objOldOppty.Benefits_Current_Setup_Step__c)
		) {
			if (OpportunityUtil.isBenefits(objOppty) && !objOppty.Keep_Opportunity_Open_On_Dismissal__c) {
				if (objOppty.Order_Generated__c) {
					objOppty.StageName = OpportunityUtil.ORDER_LOST_STAGE;
				} else {
					objOppty.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
				}
				// Benefit Application Dismissed
				if (objOldOppty != null && String.isBlank(objOldOppty.Stage_Detail__c)) {
					objOppty.Stage_Detail__c = OpportunityUtil.DISMISSED_STAGE_DETAIL;
				}
			}
		}

		if (
			objOppty.Closed_Won_Eligible__c &&
			objOppty.StageName == OpportunityUtil.PENDING_PR_STAGE &&
			((objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID && objOppty.Signing_Forms_Completed_Timestamp__c != null) ||
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
		) {
			objOppty.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		}

		if (strStage != objOppty.StageName) {
			objOppty.Stage_Change_Date_Time__c = Datetime.now();
		}
	}

	/**** Setting Commit Flag ****/
	public void setCommit(Opportunity objOppty, Opportunity objOldOppty) {
		// Probability >= 90
		if (objOppty.Probability >= OpportunityUtil.COMMIT_PROBABILITY && objOppty.Oppty_Commit_Flag__c != OpportunityUtil.CHOICE_YES && (objOldOppty == null || !objOldOppty.IsClosed)) {
			objOppty.Oppty_Commit_Flag__c = OpportunityUtil.CHOICE_YES;
		}
	}

	/**** Setting sandler field ****/
	public void setSandlerBusinessProcess(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);
		if (
			(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) &&
			String.isNotBlank(objOppty.StageName) &&
			objOppty.StageName != objOldOppty.StageName &&
			OpportunityUtil.map_StageSandlerMapping.containsKey(objOppty.StageName)
		) {
			objOppty.Sandler_Business_Process__c = OpportunityUtil.map_StageSandlerMapping.get(objOppty.StageName);
		}
	}

	/**** Setting Close date ****/
	public void setCloseDateInfo(Opportunity objOppty, Opportunity objOldOppty) {
		Account objAccnt = objOppty.AccountId != null ? map_Accounts.get(objOppty.AccountId) : new Account();
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);

		// Insert
		if (objOldOppty == null) {
			// Default : TODAY + 30 days
			if (objOppty.CloseDate == null) {
				objOppty.CloseDate = Date.today().addDays(OpportunityUtil.DEFAULT_CLOSEDAYS);
			}

			// BizDev Opportunity : TODAY + 80 days
			if (objOppty.RecordTypeId == OpportunityUtil.BIZDEV_OPPTY_RT_ID) {
				objOppty.CloseDate = Date.today().addDays(OpportunityUtil.BIZDEV_CLOSEDAYS);
			}

			// Dismissed
			if (
				objOppty.Benefits_Current_Setup_Step__c == OpportunityUtil.DISMISSED_SETUP_STEP &&
				(objOldOppty == null ||
				objOppty.Benefits_Current_Setup_Step__c != objOldOppty.Benefits_Current_Setup_Step__c)
			) {
				objOppty.CloseDate = Date.today();
			}

			// Customer Success
			if (OpportunityUtil.isCustomerSuccess(objOppty)) {
				objOppty.CloseDate = Date.today().addDays(30);
			}

			/* Set only when Running User is an Admin/Integration user <<!!This might only be for Integration users!!>>
			 Last day of current month */
			if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID) {
				objOppty.CloseDate = Date.today().addMonths(1).toStartofMonth().addDays(-1);
			}

			if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID && objOppty.Type != OpportunityUtil.OPPTY_TYPE_RENEWAL_BYB) {
				objOppty.CloseDate = Date.today().addMonths(1).toStartofMonth().addDays(-1);
			}

			if (objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID) {
				Date dtToday = System.today();
				Integer intNumberOfDays = Date.daysInMonth(dtToday.year(), dtToday.month());
				objOppty.CloseDate = Date.newInstance(dtToday.year(), dtToday.month(), intNumberOfDays);
			}

			if (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == 'Winback') {
				objOppty.CloseDate = Date.today().addDays(90);
			}
		} else {
			// Update
			if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) {
				// If Account Join Date > opportunity Close Date then update the Close Date to match Account Join Date
				if (
					objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE &&
					objOppty.StageName != objOldOppty.StageName &&
					(objAccnt.Joined_Date_Panda__c != null &&
					objAccnt.Joined_Date_Panda__c > objOppty.CloseDate)
				) {
					objOppty.CloseDate = objAccnt.Joined_Date_Panda__c;
				}

				if (!objOppty.IsClosed && objOppty.ZP_Company_Suspended__c && !objOldOppty.ZP_Company_Suspended__c) {
					objOppty.CloseDate = Date.today();
				}
			}

			if (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == 'Winback' && objOppty.CloseDate != objOppty.CreatedDate.addDays(90)) {
				objOppty.CloseDate = objOppty.CreatedDate.addDays(90).date();
			}

			if (
				objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE &&
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID ||
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			) {
				if (objOldOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE || objOldOppty.StageName == OpportunityUtil.ORDER_LOST_STAGE) {
					objOppty.CloseDate = objOldOppty.closeDate;
				} else if (objOppty.StageName != objOldOppty.StageName) {
					objOppty.CloseDate = Date.today();
				}
			}

			if (
				objOppty.Closed_Won_Eligible__c &&
				!objOldOppty.Closed_Won_Eligible__c &&
				objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE &&
				objOldOppty.StageName == OpportunityUtil.PENDING_PR_STAGE &&
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID &&
				objOppty.Signing_Forms_Completed_Timestamp__c != null))
			) {
				objOppty.CloseDate = objAccnt.Joined_Date_Panda__c >= Date.today() ? objAccnt.Joined_Date_Panda__c : Date.today();
			}

			if (
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID &&
				objOppty.Verifying_Eligibility_Start__c != null &&
				objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
				objOppty.Verifying_Eligibility_Start__c != objOldOppty.Verifying_Eligibility_Start__c
			) {
				objOppty.CloseDate = objOppty.Verifying_Eligibility_Start__c.date() >= System.today() ? objOppty.Verifying_Eligibility_Start__c.date() : System.today();
			}

			if (objOppty.Dismissed__c != objOldOppty.Dismissed__c) {
				objOppty.Application_Started__c = objOppty.Dismissed__c;

				if (objOppty.Dismissed__c != null && objOppty.StageName != OpportunityUtil.ORDER_LOST_STAGE) {
					objOppty.CloseDate = objOppty.Dismissed__c.date() >= System.today() ? objOppty.Dismissed__c.date() : System.today();
				}
			}

			if (objOppty.Completed__c != objOldOppty.Completed__c) {
				objOppty.Application_Started__c = objOppty.Completed__c;

				if (objOppty.Completed__c != null && objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE) {
					if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
						objOppty.CloseDate = objOppty.Completed__c.date() >= System.today() ? objOppty.Completed__c.date() : System.today();
					}

					if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID) {
						objOppty.CloseDate = objOppty.Completed__c.date() >= System.today() ? objOppty.Completed__c.date() : System.today();
					}
				}
			}
		}

		if (objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE && (objOldOppty == null || objOppty.StageName != objOldOppty.StageName)) {
			// Do not overwrite close date when verifying eligibility date is populated
			if (
				objOppty.Verifying_Eligibility_Start__c == null &&
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID ||
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			) {
				objOppty.CloseDate = Date.today();
			}

			objOppty.Closed_Won_Date__c = objOppty.CloseDate;
		}

		// Opportunity Stage is Closed Lost
		if (
			(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) &&
			objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE &&
			(objOldOppty == null ||
			objOppty.StageName != objOldOppty.StageName)
		) {
			objOppty.CloseDate = Date.today();
		}

		// Setting the last day of the Financial Quarter for the Close Date
		if (objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE && objOppty.Closed_Date_Quarter_Last_Day__c == null && objOppty.CloseDate != null) {
			{
				objOppty.Closed_Date_Quarter_Last_Day__c = OpportunityUtil.quarterLastDay(objOppty.CloseDate);
			}
		}
	}

	/**** Setting Type and Name ****/
	public void setNameAndType(Opportunity objOppty, Opportunity objOldOppty) {
		// Is Insert or if either Account or Sold By has changed
		if (objOldOppty == null || objOppty.AccountId != objOldOppty.AccountId || objOppty.Sold_By__c != objOldOppty.Sold_By__c) {
			// Type = 'Direct BOR', Name = <<Account Name>> + 'Benefits BoR'
			if (OpportunityUtil.map_OpptyRTToDefaultValues.containsKey(objOppty.RecordTypeId)) {
				List<String> list_Temp = OpportunityUtil.map_OpptyRTToDefaultValues.get(objOppty.RecordTypeId);
				// Company Opportunity - Partner
				if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID && objOppty.Sold_By__c != null) {
					objOppty.Type = list_Temp[1];
				} else {
					// All other scenarios
					objOppty.Type = (String.IsNotBlank(objOppty.Touch_Type__c) &&
						objOppty.Touch_Type__c == OpportunityUtil.HI_EBBP_CREATION &&
						String.isNotBlank(objOppty.Type))
						? objOppty.Type
						: list_Temp[0];
				}

				if (objOppty.AccountId != null && map_Accounts.containsKey(objOppty.AccountId)) {
					objOppty.Name = (String.IsNotBlank(objOppty.Touch_Type__c) &&
						objOppty.Touch_Type__c == OpportunityUtil.HI_EBBP_CREATION &&
						String.isNotBlank(objOppty.Name))
						? objOppty.Name
						: StringUtils.getOppName(map_Accounts.get(objOppty.AccountId).Name, list_Temp[2]);
				} else {
					objOppty.Name = (String.IsNotBlank(objOppty.Touch_Type__c) &&
						objOppty.Touch_Type__c == OpportunityUtil.HI_EBBP_CREATION &&
						String.isNotBlank(objOppty.Name))
						? objOppty.Name
						: list_Temp[2];
				}
			} else if (
				objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID &&
				objOppty.AccountId != null &&
				map_Accounts.containsKey(objOppty.AccountId) &&
				objOldOppty == null &&
				String.isNotBlank(objOppty.Tax_Year__c) &&
				String.isNotBlank(objOppty.Type)
			) {
				// new code
				Account objAccount = map_Accounts.get(objOppty.AccountId);
				switch on objOppty.Type {
					when 'Existing Business' {
						objOppty.Name = objAccount?.Name + ' ' + '-' + ' ' + 'R&D Existing Business ' + objOppty.Tax_Year__c;
					}
					when 'Expansion' {
						objOppty.Name = objAccount?.Name + ' ' + '-' + ' ' + 'R&D Expansion ' + objOppty.Tax_Year__c;
					}
					when 'New Business' {
						objOppty.Name = objAccount?.Name + ' ' + '-' + ' ' + TAXCREDITS_PREFIX_RD + ' ' + TAXCREDITS_TYPE_NEW_BUSINESS + ' ' + objOppty.Tax_Year__c;
					}
					when 'Partnership' {
						objOppty.Name = objAccount?.Name + ' ' + '-' + ' ' + TAXCREDITS_PREFIX_RD + ' ' + TAXCREDITS_TYPE_PARTNERSHIP + ' ' + objOppty.Tax_Year__c;
					}
					when else {
						objOppty.Name = objAccount?.Name + ' ' + '-' + ' ' + 'R&D ' + objOppty.Type;
					}
				}
			} else if (
				objOppty.RecordTypeId == OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID &&
				objOppty.AccountId != null &&
				map_Accounts.containsKey(objOppty.AccountId) &&
				objOldOppty == null &&
				String.isNotBlank(objOppty.Type)
			) {
				Account objAccount = map_Accounts.get(objOppty.AccountId);
				String strType = String.isNotBlank(objOppty.Type) ? objOppty.Type : 'Growth Expansion';
				objOppty.Name = objAccount?.Name + ' - ' + strType;
			} else if (
				objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID &&
				objOppty.AccountId != null &&
				map_Accounts.containsKey(objOppty.AccountId) &&
				objOldOppty == null &&
				String.isNotBlank(objOppty.Type)
			) {
				Account objAccount = map_Accounts.get(objOppty.AccountId);
				String strType = '';
				if (String.isNotBlank(objOppty.Type)) {
					strType = objOppty.Type;
				} else {
					strType = 'New Business';
				}
				objOppty.Name = objAccount?.Name + ' - ' + strType;
			}
		}
	}

	/**** Setting Pricebook ****/
	public void setPricebook(Opportunity objOppty) {
		if (objOppty.PriceBook2Id == null) {
			// Company Opportunity
			// if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
			// 	Account objAccount = map_Accounts.get(objOppty.AccountId);
			// 	// Pricebook set based on Pricing field on related Account
			// 	if (objAccount != null && objAccount.Pricing__c != null && OpportunityUtil.getPriceBookByName(objAccount.Pricing__c) != null) {
			// 		objOppty.PriceBook2Id = OpportunityUtil.getPriceBookByName(objAccount.Pricing__c).Id;
			// 	} else if (OpportunityUtil.getPriceBookByName(objTierConfig.New_Price_1__c) != null) {
			// 		// Setting Default pricebook if applicable
			// 		objOppty.PriceBook2Id = OpportunityUtil.getPriceBookByName(objTierConfig.New_Price_1__c).Id;
			// 	}
			// } else
			if (OpportunityUtil.set_ArdiusRecordTypeIds.contains(objOppty.RecordTypeId)) {
				// Pricebook set based on Tier field on related Account
				Account objAccount = map_Accounts.get(objOppty.AccountId);
				objOppty.PriceBook2Id = OpportunityUtil.getTierPricebookId(objOppty.RecordTypeId, objAccount?.Tier__c, true);
			} else if (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) {
				if (OpportunityUtil.getPriceBookByName('Payroll Product Catalog') != null) {
					objOppty.PriceBook2Id = OpportunityUtil.getPriceBookByName('Payroll Product Catalog').Id;
				}
			} else if (OpportunityUtil.getPriceBookByName(System.Label.Benefits_Default_Payment_Plan) != null) {
				// Others
				objOppty.PriceBook2Id = OpportunityUtil.getPriceBookByName(System.Label.Benefits_Default_Payment_Plan).Id;
			}
		}
	}

	/**
	 * @author      Praveen Sethu
	 * @description Setting Additional Services on Company Opportunity
	 * @param       Trigger new Opportunity
	 **/
	public void setAdditionalServices(Opportunity objOppty) {
		// Company Opportunity
		if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) {
			Account objAccount = map_Accounts.get(objOppty.AccountId);
			objOppty.Additional_Opportunity_Services__c = objAccount.Additional_Services__c;
		}
	}

	/*** Update Submission Deadline on Renewal Opportunities ***/
	public void updateRenewalSubmissionDeadline(Opportunity objOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID && objOppty.AccountId != null && objOppty.Submission_Deadline__c == null) {
			Configuration_Settings__c objConfig = Utils.ORG_WIDE_CONFIG_SETTINGS;
			Map<Id, QA_Sheet__c> map_recentQASheetByAccountId = new Map<Id, QA_Sheet__c>(fetchRecentQASheet(set_AccIdForSubmissionDate));

			if (
				objOppty.HI_Effective_Date__c != null &&
				map_recentQASheetByAccountId.containsKey(objOppty.AccountId) &&
				set_AccIdForSubmissionDate.contains(objOppty.AccountId) &&
				objConfig.Special_Enrollment_Deadline_Date__c != null &&
				objConfig.HI_Effective_date__c == objOppty.HI_Effective_Date__c
			) {
				objOppty.Submission_Deadline__c = objConfig.Special_Enrollment_Deadline_Date__c;
				objOppty.Special_Enrollment__c = true;
			}

			if (objOppty.Submission_Deadline__c == null && map_AccIdToDeadlineDateMap.containsKey(objOppty.AccountId)) {
				objOppty.Submission_Deadline__c = map_AccIdToDeadlineDateMap.get(objOppty.AccountId);
			}
		}
	}

	/*** Update Under writing State and Carrier Information from Policy ***/
	public void updateUWStateCarrier(Opportunity objOppty) {
		if (objOppty.UW_State_PY__c == null && map_OpportunityWithUWState.containsKey(objOppty.AccountId)) {
			Policy__c objPolicy = map_OpportunityWithUWState.get(objOppty.AccountId);
			objOppty.UW_State_PY__c = objPolicy.State__r.Name;

			if (objPolicy.Benefit_Type__c == 'Medical' && objPolicy.Carrier__c != null) {
				objOppty.UW_Carrier_PY__c = objPolicy.Carrier__r.Name;
				objOppty.UW_Carrier_Previous_Year__c = objPolicy.Carrier__c;
			}
		}
	}

	/***By AKS Dated 5th Jan 21 -Update Region and Calendly URL based on Under writing State ***/
	public void populateRegion(Opportunity objOppty, Opportunity objOldOppty) {
		String strStateName = null;
		if (objOppty != null) {
			//Default set to null
			if (objOppty.UW_State_PY__c != null && (objOldOppty == null || (objOppty.UW_State_PY__c != objOldOppty.UW_State_PY__c))) {
				strStateName = objOppty.UW_State_PY__c;
			}
			//Logic should not run for California State
			if (String.isNotBlank(strStateName) && strStateName != OpportunityUtil.STATE_CALIFORNIA && map_StateNameAbbreviations.containsKey(strStateName) != null) {
				String strStateAbbreviations = map_StateNameAbbreviations.get(strStateName);
				if (String.isNotBlank(strStateAbbreviations)) {
					//get All Region From meta date to compare with state abbreviations
					for (Region_Setting__mdt rt : list_RegionSettings) {
						if (rt.States__c.indexOf(strStateAbbreviations) > -1) {
							objOppty.Region__c = rt.Region_Name__c;
						}
					}
				}
			}
		}
	}

	/*** Creating a map of Account and Renewal Submission Deadline ***/
	public void createSubmissionDeadlineMap(Set<Id> set_BenefitsAccountIds, Set<Id> set_AccIdForSubmissionDate, Set<Id> set_AccIdForUWSate) {
		Set<Id> set_CarrierIds = new Set<Id>();
		List<Policy__c> list_MedicalPolicies = new List<Policy__c>();
		// A map of Opportunity's Carrier Id to Carrier Object
		Map<Id, Carrier__c> map_Carriers = new Map<Id, Carrier__c>();
		// Map of Carrier Id to External Id
		Map<Id, String> map_CarrierIdExternalId = new Map<Id, String>();
		// Map of Carrier External Id to Effective Date (Effective Date = Policy Coverage Effective Date + 1)
		Map<String, Date> map_CarrierExternalIdEffectiveDate = new Map<String, Date>();
		// Map of Carrier External Id to Carrier Version Detail
		Map<String, Carrier_Version_Detail__c> map_CarrierVersion = new Map<String, Carrier_Version_Detail__c>();

		List<Policy__c> list_AllPolicies = queryPolicies(set_BenefitsAccountIds);

		// Iterate over each policy and check if each policy is selected and if the policy has a valid carrier
		// Check if Policy's Coverage Effective Date is less than today and expiration date is greater than today
		for (Policy__c objPolicy : list_AllPolicies) {
			if (
				objPolicy.Is_Selected__c &&
				objPolicy.Expiration_Date__c != null &&
				objPolicy.Carrier__c != null &&
				objPolicy.Coverage_Effective_Date__c <= Date.today() &&
				objPolicy.Expiration_Date__c >= Date.today()
			) {
				if (!set_AccIdForSubmissionDate.isEmpty() && set_AccIdForSubmissionDate.contains(objPolicy.Account__c) && objPolicy.Benefit_Type__c == 'Medical') {
					// Set of Opportunities' Carriers
					set_CarrierIds.add(objPolicy.Carrier__c);
					// List of Opportunities Unexpired Medical Policies
					list_MedicalPolicies.add(objPolicy);
				}

				if (objPolicy.State__c != null && !set_AccIdForUWSate.isEmpty() && set_AccIdForUWSate.contains(objPolicy.Account__c)) {
					// Giving Priority to Medical
					if (objPolicy.Benefit_Type__c == 'Medical') {
						map_OpportunityWithUWState.put(objPolicy.Account__c, objPolicy);
					}

					if (!map_OpportunityWithUWState.containsKey(objPolicy.Account__c)) {
						if (String.isBlank(objPolicy.Opportunity__r.UW_State_PY__c)) {
							map_OpportunityWithUWState.put(objPolicy.Account__c, objPolicy);
						}
					}
				}
			}
		}

		if (!set_CarrierIds.isEmpty()) {
			// Query Benefit Opportunities' Carrier Details
			map_Carriers = new Map<Id, Carrier__c>(queryCarriers(set_CarrierIds));
			if (!map_Carriers.isEmpty()) {
				// Build a map of Carrier Id to Carrier External Id
				for (Carrier__c objCarrier : map_Carriers.values()) {
					map_CarrierIdExternalId.put(objCarrier.Id, objCarrier.Id__c);
				}

				// Build a map of Carrier External Id to Effective Date
				// Effective Date is calculated by adding 1 day to previous policy's expiration date
				for (Policy__c objPolicy : list_AllPolicies) {
					if (objPolicy.Carrier__c != null && objPolicy.Expiration_Date__c != null && map_CarrierIdExternalId.containsKey(objPolicy.Carrier__c)) {
						map_CarrierExternalIdEffectiveDate.put(map_CarrierIdExternalId.get(objPolicy.Carrier__c), objPolicy.Expiration_Date__c.addDays(1));
					}
				}

				// If map of carrier external Id to effective date is not empty, fetch a map of Carrier Version Detail Records
				if (!map_CarrierExternalIdEffectiveDate.isEmpty()) {
					map_CarrierVersion = Utils.getCarrierVersion(map_CarrierExternalIdEffectiveDate);
				}
			}

			for (Policy__c objPolicy : list_MedicalPolicies) {
				// Effective Date = Expiration Date + 1
				Date dtEffectiveDate = objPolicy.Expiration_Date__c.addDays(1);
				// Get Carrier External Id from Map
				String strCarrierExternalId = '';

				if (map_CarrierIdExternalId.containsKey(objPolicy.Carrier__c)) {
					strCarrierExternalId = map_CarrierIdExternalId.get(objPolicy.Carrier__c);
				}

				// Fetch both Carrier and Carrier Detail Records
				Carrier_Version_Detail__c carrierDetail = (String.isNotBlank(strCarrierExternalId) &&
					map_CarrierVersion != null &&
					map_CarrierVersion.containsKey(strCarrierExternalId))
					? map_CarrierVersion.get(strCarrierExternalId)
					: null;

				Carrier__c objCarrier = objPolicy.Carrier__c != null && map_Carriers.containsKey(objPolicy.Carrier__c) ? map_Carriers.get(objPolicy.Carrier__c) : null;

				// Giving Preference to Carrier Detail - Declare a generic SObject
				Sobject objCarrierDetail;

				// Check if Carrier detail is not null, use carrier detail, else use carrier
				if (carrierDetail != null) {
					objCarrierDetail = carrierDetail;
				} else if (objCarrier != null) {
					objCarrierDetail = objCarrier;
				} else {
					continue;
				}

				setGroupVariablesAPIName(objCarrierDetail);
				Integer intGroupVarNum1 = objCarrierDetail.get(strGroupVarNum1ApiName) != null ? Integer.valueOf(objCarrierDetail.get(strGroupVarNum1ApiName)) : null;

				// Check if Carrier Detail/Carrier record has Group Submission Event and Check if Group Submission Event is Same
				if (objCarrierDetail.get('Group_Submission_Event__c') != null) {
					if (String.valueOf(objCarrierDetail.get('Group_Submission_Event__c')).equalsIgnoreCase('same')) {
						setSubmissionDeadlineMap(OpportunityUtil.checkWeekendDate(dtEffectiveDate), objPolicy.Account__c);
					} else if (objCarrierDetail.get(strGroupVarNum1ApiName) != null) {
						// Check Carrier Detail/Carrier record has Group Submission Event and Check if Group Submission Event has a variation
						if (String.valueOf(objCarrierDetail.get('Group_Submission_Event__c')).equalsIgnoreCase('Before Month')) {
							setSubmissionDeadlineMap(OpportunityUtil.checkWeekendDate(calculateBeforeMonthDate(objCarrierDetail, dtEffectiveDate)), objPolicy.Account__c);
						} else if (String.valueOf(objCarrierDetail.get('Group_Submission_Event__c')).equalsIgnoreCase('After Month')) {
							setSubmissionDeadlineMap(OpportunityUtil.checkWeekendDate(calculateAfterMonthDate(objCarrierDetail, dtEffectiveDate)), objPolicy.Account__c);
						} else if (String.valueOf(objCarrierDetail.get('Group_Submission_Event__c')).equalsIgnoreCase('Before Days')) {
							setSubmissionDeadlineMap(OpportunityUtil.checkWeekendDate(dtEffectiveDate.addDays(-intGroupVarNum1)), objPolicy.Account__c);
						} else if (String.valueOf(objCarrierDetail.get('Group_Submission_Event__c')).equalsIgnoreCase('After Days')) {
							setSubmissionDeadlineMap(OpportunityUtil.checkWeekendDate(dtEffectiveDate.addDays(intGroupVarNum1)), objPolicy.Account__c);
						}
					}
				}
			}
		}
	}

	/*** Creates a map of Account and Submission Deadline ***/
	public void setSubmissionDeadlineMap(Date dtDeadline, Id idAccount) {
		if (map_AccIdToDeadlineDateMap.containsKey(idAccount)) {
			if (map_AccIdToDeadlineDateMap.get(idAccount) > dtDeadline) {
				map_AccIdToDeadlineDateMap.put(idAccount, dtDeadline);
			}
		} else {
			map_AccIdToDeadlineDateMap.put(idAccount, dtDeadline);
		}
	}

	/*** Handles when Group Submission Event is Before Month ***/
	public Date calculateBeforeMonthDate(SObject objCarrierDetail, Date dtEffectiveDate) {
		Date dtSubmissionDeadline = dtEffectiveDate;
		Integer intGroupVarNum1 = objCarrierDetail.get(strGroupVarNum1ApiName) != null ? Integer.valueOf(objCarrierDetail.get(strGroupVarNum1ApiName)) : null;
		Integer intGroupVarNum2 = objCarrierDetail.get(strGroupVarNum2ApiName) != null ? Integer.valueOf(objCarrierDetail.get(strGroupVarNum2ApiName)) : null;

		if (intGroupVarNum2 == null && intGroupVarNum1 != null) {
			if (dtEffectiveDate.day() == 1) {
				dtEffectiveDate = dtEffectiveDate.addMonths(-1);
				dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum1);
			} else {
				dtEffectiveDate = dtEffectiveDate.toStartOfMonth().addMonths(-1);
				dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum1);
			}
		} else {
			if (dtEffectiveDate.day() == 1) {
				if (intGroupVarNum1 != null && intGroupVarNum1 == 1) {
					dtSubmissionDeadline = dtEffectiveDate.addDays(-1);
				} else {
					dtEffectiveDate = dtEffectiveDate.addMonths(-1);
					dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum1);
				}
			} else {
				if (intGroupVarNum2 != null && intGroupVarNum2 < 15) {
					dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum2);
				} else {
					dtEffectiveDate = dtEffectiveDate.addMonths(-1);
					dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum2);
				}
			}
		}
		return dtSubmissionDeadline;
	}

	/**** Handles when Group Submission Event is After Month ****/
	public Date calculateAfterMonthDate(SObject objCarrierDetail, Date dtEffectiveDate) {
		Date dtSubmissionDeadline = dtEffectiveDate;
		Integer intGroupVarNum1 = objCarrierDetail.get(strGroupVarNum1ApiName) != null ? Integer.valueOf(objCarrierDetail.get(strGroupVarNum1ApiName)) : null;
		Integer intGroupVarNum2 = objCarrierDetail.get(strGroupVarNum2ApiName) != null ? Integer.valueOf(objCarrierDetail.get(strGroupVarNum2ApiName)) : null;

		if (intGroupVarNum2 == null && intGroupVarNum1 != null) {
			if (dtEffectiveDate.day() == 1) {
				dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum1);
			} else {
				dtEffectiveDate = dtEffectiveDate.addMonths(1).toStartOfMonth();
				dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum1);
			}
		} else {
			if (dtEffectiveDate.day() == 1) {
				dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum1);
			} else {
				dtSubmissionDeadline = Date.newInstance(dtEffectiveDate.year(), dtEffectiveDate.month(), intGroupVarNum2);
			}
		}
		return dtSubmissionDeadline;
	}

	/**** Set different api names for Carrier and Carrier Version Detail records ****/
	public void setGroupVariablesAPIName(sObject objCarrierDetail) {
		if ('Carrier__c'.equalsIgnoreCase(Id.valueOf(String.valueOf(objCarrierDetail.Id)).getSObjectType().getDescribe().getName())) {
			strGroupVarNum1ApiName = 'Group_Variation_Number__c';
			strGroupVarNum2ApiName = 'Group_Variation_Number_2__c';
		} else {
			strGroupVarNum1ApiName = 'Group_Variation_Number1__c';
			strGroupVarNum2ApiName = 'Group_Variation_Number2__c';
		}
	}

	/**** Handle Benefits Application ****/
	public void handleBenefitsApplication(Opportunity objOppty, Opportunity objOldOppty) {
		if (
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID && (objOppty.Benefits_Current_Setup_Step__c == 'Completed' || objOppty.Benefits_Current_Setup_Step__c == 'Complete')
		) {
			objOppty.Benefits_Flow_Completed_Count__c = objOppty.Benefits_Flow_Completed_Count__c == null ? 1 : objOppty.Benefits_Flow_Completed_Count__c + 1;
		}

		if (
			(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID &&
			objOppty.Benefits_Current_Setup_Step__c == 'Selecting Base Plan' &&
			(objOldOppty.Benefits_Current_Setup_Step__c == 'Verifying Eligibility' ||
			objOldOppty.Benefits_Current_Setup_Step__c == 'Completed')) ||
			(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID &&
			objOppty.Benefits_Current_Setup_Step__c == 'Selecting Offerings' &&
			objOldOppty.Benefits_Current_Setup_Step__c == 'Completed') ||
			(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID &&
			objOppty.Benefits_Current_Setup_Step__c == 'Awaiting Offerings' &&
			objOldOppty.Benefits_Current_Setup_Step__c == 'Completed')
		) {
			if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID) {
				objOppty.Collecting_Company_Information_End__c = null;
				objOppty.Collecting_Company_Information_Start__c = null;
				objOppty.Completed__c = null;
				objOppty.Dismissed__c = null;
				objOppty.Reviewing_Summary_End__c = null;
				objOppty.Reviewing_Summary_Start__c = null;
				objOppty.Selecting_Base_Plan_End__c = null;
				objOppty.Selecting_Base_Plan_Start__c = null;
				objOppty.Selecting_Complementary_Plans_End__c = null;
				objOppty.Selecting_Complementary_Plans_Start__c = null;
				objOppty.Selecting_Non_Medical_Plans_End__c = null;
				objOppty.Selecting_Non_Medical_Plans_Start__c = null;
				objOppty.Verifying_Eligibility_End__c = null;
				objOppty.Verifying_Eligibility_Start__c = null;
			}
			if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
				objOppty.Awaiting_Education_End__c = null;
				objOppty.Awaiting_Education_Start__c = null;
				objOppty.Completed__c = null;
				objOppty.Dismissed__c = null;
				objOppty.Reviewing_Summary_Start__c = null;
				objOppty.Selecting_Offerings_Start__c = null;
			}
			if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID) {
				objOppty.Reviewing_Summary_End__c = null;
				objOppty.Reviewing_Summary_Start__c = null;
				objOppty.Completed__c = null;
				objOppty.Dismissed__c = null;
				objOppty.Selecting_Offerings_End__c = null;
				objOppty.Selecting_Offerings_Start__c = null;
			}
		}

		if (
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID &&
			(objOppty.Selecting_Employee_Eligibility__c != objOldOppty.Selecting_Employee_Eligibility__c ||
			objOppty.Selecting_Employee_Eligibility_Start__c != objOldOppty.Selecting_Employee_Eligibility_Start__c)
		) {
			objOppty.Application_Started__c = objOppty.Selecting_Employee_Eligibility__c;
		}

		if (objOppty.Answering_Survey_Start__c != objOldOppty.Answering_Survey_Start__c) {
			objOppty.Application_Started__c = objOppty.Answering_Survey_Start__c;
		}
	}

	/**** Update Most Latest relevant Timestamp on Benefits Setup Last Updated ****/
	public void benefitsSetupLastUpdated(Opportunity objOppty, Opportunity objOldOppty) {
		dateTime dtm = null;
		if (
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID &&
			(objOppty.Selecting_Enrollment_Periods_Start__c != objOldOppty.Selecting_Enrollment_Periods_Start__c ||
			objOppty.Selecting_Enrollment_Periods_End__c != objOldOppty.Selecting_Enrollment_Periods_End__c ||
			objOppty.Selecting_Employee_Eligibility__c != objOldOppty.Selecting_Employee_Eligibility__c ||
			objOppty.Selecting_Employee_Eligibility_Start__c != objOldOppty.Selecting_Employee_Eligibility_Start__c ||
			objOppty.Selecting_Employee_Eligibility_End__c != objOldOppty.Selecting_Employee_Eligibility_End__c ||
			objOppty.Receiving_Medical_Education_Start__c != objOldOppty.Receiving_Medical_Education_Start__c ||
			objOppty.Receiving_Medical_Education_End__c != objOldOppty.Receiving_Medical_Education_End__c ||
			objOppty.Selecting_Base_Tier_Start__c != objOldOppty.Selecting_Base_Tier_Start__c ||
			objOppty.Selecting_Base_Tier_End__c != objOldOppty.Selecting_Base_Tier_End__c ||
			objOppty.Selecting_Base_Plan_Start__c != objOldOppty.Selecting_Base_Plan_Start__c ||
			objOppty.Selecting_Base_Plan_End__c != objOldOppty.Selecting_Base_Plan_End__c ||
			objOppty.Selecting_Complementary_Plans_Start__c != objOldOppty.Selecting_Complementary_Plans_Start__c ||
			objOppty.Selecting_Complementary_Plans_End__c != objOldOppty.Selecting_Complementary_Plans_End__c ||
			objOppty.Selecting_Non_Medical_Plans_Start__c != objOldOppty.Selecting_Non_Medical_Plans_Start__c ||
			objOppty.Selecting_Non_Medical_Plans_End__c != objOldOppty.Selecting_Non_Medical_Plans_End__c ||
			objOppty.Collecting_Company_Information_Start__c != objOldOppty.Collecting_Company_Information_Start__c ||
			objOppty.Collecting_Company_Information_End__c != objOldOppty.Collecting_Company_Information_End__c ||
			objOppty.Reviewing_Summary_End__c != objOldOppty.Reviewing_Summary_End__c ||
			objOppty.Reviewing_Summary_Start__c != objOldOppty.Reviewing_Summary_Start__c ||
			objOppty.Verifying_Eligibility_Start__c != objOldOppty.Verifying_Eligibility_Start__c ||
			objOppty.Verifying_Eligibility_End__c != objOldOppty.Verifying_Eligibility_End__c)
		) {
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Enrollment_Periods_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Enrollment_Periods_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Employee_Eligibility__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Employee_Eligibility_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Employee_Eligibility_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Receiving_Medical_Education_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Receiving_Medical_Education_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Base_Tier_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Base_Tier_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Base_Plan_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Base_Plan_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Complementary_Plans_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Complementary_Plans_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Non_Medical_Plans_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Selecting_Non_Medical_Plans_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Collecting_Company_Information_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Collecting_Company_Information_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Reviewing_Summary_End__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Reviewing_Summary_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Verifying_Eligibility_Start__c, dtm);
			dtm = OpportunityUtil.greaterTime(objOppty.Verifying_Eligibility_End__c, dtm);
			objOppty.Benefits_Setup_Last_Updated__c = dtm;
		}
	}

	/**
	 * @description Given the Opp and PBE and Quantity, assemble a new OpportunityLineItem
	 * @author David Schach
	 * @param  id_objOppId  OpportunityId
	 * @param  objPriceBook PricebookEntryId
	 * @param  dec_Quantity Line Item Quantity
	 * @return              `OpportunityLineItem` record
	 */
	public static OpportunityLineItem buildOppLineItem(Id id_objOppId, PricebookEntry objPriceBook, Decimal dec_Quantity) {
		OpportunityLineItem objLineItem = new OpportunityLineItem(OpportunityId = id_objOppId);
		objLineItem.Quantity = dec_Quantity;
		objLineItem.PriceBookEntryId = objPriceBook.Id;
		objLineItem.UnitPrice = objPriceBook.UnitPrice;
		objLineItem.Discount = 0;
		return objLineItem;
	}

	/*** Process Policy Information ***/
	public static void processPolicyInformation(Set<Id> set_OpptyIds) {
		Map<Id, Policy__c> map_Polciies = new Map<Id, Policy__c>(
			[
				SELECT
					Account__c,
					Benefit_Type__c,
					Carrier_Order__c,
					Carrier__c,
					Contribution_for_Dependents__c,
					Contribution_for_EEs__c,
					Contribution_Scheme_Type__c,
					Coverage_Effective_Date__c,
					CreatedById,
					CreatedDate,
					Dental__c,
					Expiration_Date__c,
					Group_Number__c,
					Id,
					IsDeleted,
					Is_Base__c,
					Is_Renewal__c,
					Is_Selected__c,
					LastModifiedById,
					LastModifiedDate,
					LastReferencedDate,
					LastViewedDate,
					Medical__c,
					Name,
					Opportunity__c,
					OwnerId,
					Plan_Document_Link__c,
					Plan_Tier__c,
					Plan_Type__c,
					Policy_Number__c,
					State__c,
					SystemModstamp,
					The_Power_of_One__c,
					Visible__c,
					Vision__c,
					Waiting_Period__c
				FROM Policy__c
				WHERE Opportunity__c IN :set_OpptyIds
			]
		);
		PolicyHelper.forceLineItemLogic = true;
		PolicyHelper.validateOppLineItemsAndPerformDML(map_Polciies.values(), map_Polciies);
	}

	/**
	 * @author      Praveen Sethu
	 * @description Re-assign ardius & company opportunities
	 * @param        Trigger new Opportunity
	 **/
	public void reAssignOpportunity(Opportunity objOppty, Opportunity objOldOppty) {
		// Re-assign any opportunity linked to embedded company
		if (
			objOppty != null &&
			objOppty.AccountId != null &&
			map_Accounts.containsKey(objOppty.AccountId) &&
			(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.EMBEDDED_COMPANY_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
		) {
			Account objAcc = map_Accounts.get(objOppty.AccountId);
			Id idHerokuUser = (Id) System.Label.Heroku_User;
			if (objAcc.RecordTypeId == AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID && UserUtils.isAdminIntgUser(idHerokuUser)) {
				objOppty.OwnerId = idHerokuUser;
			} else if (
				!Test.isRunningTest() &&
				objOldOppty != null &&
				objOppty.OwnerId != objOldOppty.OwnerId &&
				INTEGRATION_USERS.contains(objOppty.OwnerId) &&
				!INTEGRATION_USERS.contains(objOldOppty.OwnerId) &&
				(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID ||
				objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			) {
				// Re-assign company opportunity if it flips from rep to integration user
				objOppty.OwnerId = objOldOppty.OwnerId;
			}
		}
	}

	/**
	 * @author      Praveen Sethu
	 * @description Set Slack Notification Field which will trigger slack notifications through Workato
	 * @param        Trigger new Opportunity
	 **/
	public void sendSlackNotifications(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);
		// check if owner changes and slack notification hasn't been posted
		// send slack notifications only for company opportuniites
		if (objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) {
			if ((objOldOppty == null || (objOppty.OwnerId != objOldOppty.OwnerId)) && objOppty.Slack_Notification_Posted__c == false && map_Users.containsKey(objOppty.OwnerId)) {
				String strOwnerRole = map_Users.get(objOppty.OwnerId)?.UserRole?.Name;

				if (String.isNotBlank(strOwnerRole) && strOwnerRole.containsIgnoreCase(OpportunityUtil.PARTNER_ROLE) && (objOppty.Sold_By__c != null || objOppty.Referred_By__c != null)) {
					objOppty.Slack_Notification__c = OpportunityUtil.SLACK_NOTIFY_PARTNER;
					objOppty.Slack_Notification_Posted__c = false;
				}
			} else if (
				objOppty.Set_Up_Steps_Completed__c >= OpportunityUtil.MMPR_SET_UP_STEPS &&
				objOppty.Slack_Notification_Posted__c == false &&
				objOppty.NumberOfEmployees__c >= OpportunityUtil.MMPR_EE_SIZE
			) {
				objOppty.Slack_Notification__c = OpportunityUtil.SLACK_NOTIFY_MDR;
				objOppty.Slack_Notification_Posted__c = false;
			}
		}
	}

	/**
	 * @author      Anurag Gautam
	 * @description Sync Opportunity Closed date so that when a Payroll Opportunity moves to 'Closed Won' the 'Close Date' matches the 'Closed Won Date'. And this is being set from the Joined date from panda.
	 * @param       Trigger new Opportunity
	 * @param       Trigger old Opportunity
	 **/
	public void syncClosedDateWithJoinedDate(Opportunity objOppty, Opportunity objOldOppty) {
		if (
			(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) &&
			objOppty.Joined_Date_Panda__c != null &&
			objOppty.Joined_Date_Panda__c != objOldOppty.Joined_Date_Panda__c &&
			objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE
		) {
			objOppty.CloseDate = objOppty.Joined_Date_Panda__c;
		}
	}

	/**
	 * @author      Anurag Gautam
	 * @description Sync Opportunity Closed date so that when a Payroll Opportunity moves to 'Closed Won' the 'Close Date' matches the 'Closed Won Date'. And this is being set from the Joined date from panda.
	 * @param       Trigger new Opportunity
	 * @param       Trigger old Opportunity
	 **/
	public void updateTierUpsellCloseDate(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOldOppty.Upsell_Tier__c != objOppty.Upsell_Tier__c && !objOppty.IsClosed) {
			if (
				objOppty.Upsell_Tier__c != null &&
				!objOldOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD) &&
				objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)
			) {
				objOppty.CloseDate = objOppty.CreatedDate.date().addDays(INTERNATIONAL_PAYROLL_CLOSE_DATE_DAYS);
			} else if (objOppty.Upsell_Tier__c != null && objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
				objOppty.CloseDate = objOppty.CreatedDate.date().addDays(90);
			} else if (objOppty.Upsell_Tier__c != null && !objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
				objOppty.CloseDate = objOppty.CreatedDate.date().addDays(45);
			}
		}
	}

	/**
	 * @author      Praveen Sethu
	 * @description Create Employer and Client BDO Benefifts Opportunities based on Onboarding data
	 * @param       Trigger new Opportunity
	 * @param       Trigger old Opportunity
	 **/
	public void createBDOOpportunities(Opportunity objOppty, Opportunity objOldOppty) {
		// Create Client BDO opportunity only when Initiated by Accountant flag has a value
		// Client BDO - Benefits New Plan Opportunity
		if (
			(objOppty.Currently_Offer_Health_Benefits__c != objOldOppty.Currently_Offer_Health_Benefits__c && objOppty.Currently_Offer_Health_Benefits__c == 'NOT_YET') ||
			(objOppty.Contribution_to_EE_Health_Coverage_cost__c != objOldOppty.Contribution_to_EE_Health_Coverage_cost__c &&
			objOppty.Contribution_to_EE_Health_Coverage_cost__c == 'COMPANY_SPONSORED_HEALTH_INSURANCE') && String.isNotBlank(objOppty.Initiated_by_Accountant__c)
		) {
			// Check for open opportuniiy and create Benefits New Plan Opportunity

			if (String.isNotBlank(objOppty.Which_Gusto_benefits_interested_in__c) && objOppty.Which_Gusto_benefits_interested_in__c.contains('HEALTH_INSURANCE')) {
				createBenefitsOpportunity(objOppty.AccountId, OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID, objOppty, OpportunityUtil.CLIENT_BDO);
			}
		}

		// Employer BDO - Benefits New PlanOpportunity
		if (
			objOppty.Interest_in_adding_benefits_to_Gusto__c != objOldOppty.Interest_in_adding_benefits_to_Gusto__c &&
			(objOppty.Currently_Offer_Health_Benefits__c != 'Yes' ||
			objOppty.Currently_Offer_Health_Benefits__c != 'True') &&
			(objOppty.Interest_in_adding_benefits_to_Gusto__c == 'SMALL_GROUP_HEALTH_INSURANCE' ||
			objOppty.Interest_in_adding_benefits_to_Gusto__c == 'LEARNING_MORE') &&
			String.isBlank(objOppty.Initiated_by_Accountant__c)
		) {
			createBenefitsOpportunity(objOppty.AccountId, OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID, objOppty, OpportunityUtil.EMPLOYER_BDO);
		}

		// Employer BDO and Client BDO - Benefits BoR Opportunity
		if (
			(objOppty.Currently_Offer_Health_Benefits__c != objOldOppty.Currently_Offer_Health_Benefits__c &&
			String.isNotBlank(objOppty.Currently_Offer_Health_Benefits__c) &&
			(objOppty.Currently_Offer_Health_Benefits__c == 'Yes' ||
			objOppty.Currently_Offer_Health_Benefits__c == 'True'))
		) {
			// Check for open opportuniiy and create Benefits BoR Opportunity
			// Set Lead Source based on Initiated by Accountant flag
			String strLeadSource = String.isNotBlank(objOppty.Initiated_by_Accountant__c) ? OpportunityUtil.CLIENT_BDO : OpportunityUtil.EMPLOYER_BDO;
			createBenefitsOpportunity(objOppty.AccountId, OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID, objOppty, strLeadSource);
		}
	}

	/**
	 * @author      Praveen Sethu
	 * @description Checks if open benefits opportunity is created for the account of a specific record type and Create new opportunity if not present
	 * @param       Id Account Id
	 * @param       Id Record Type Id of the Benefits opportunity
	 * @param		objOppty - Opportunity trigger context
	 **/
	public void createBenefitsOpportunity(Id idAccount, Id idRecordType, Opportunity objOppty, String strLeadSource) {
		Boolean blnOpptyPresent = false;
		Decimal decEmployees = 0;
		if (idAccount != null && map_Accounts.containsKey(idAccount)) {
			Account objAcc = map_Accounts.get(idAccount);
			// Set Number of Employees to either Active Employees or Lead employees whichever is greater than 2
			if (objAcc.Number_of_Active_Employees__c != null && objAcc.Number_of_Active_Employees__c > 2) {
				decEmployees = objAcc.Number_of_Active_Employees__c;
			} else if (objAcc.NumberOfEmployees != null && objAcc.NumberOfEmployees > 2) {
				decEmployees = objAcc.NumberOfEmployees;
			}
			for (Opportunity objOpp : objAcc.Opportunities) {
				if (objOpp.RecordTypeId == idRecordType && !objOpp.IsClosed) {
					blnOpptyPresent = true;
					break;
				}
			}
		}

		// Create Benefits  Opportunity ONLY if existing opportunity is not present & if employees is greater than 2
		if (!blnOpptyPresent && decEmployees > 2) {
			list_OpptysToInsert.add(
				new Opportunity(
					RecordTypeId = idRecordType,
					AccountId = idAccount,
					StageName = OpportunityUtil.DEFAULT_HI_SALES_STAGE,
					LeadSource = strLeadSource,
					Which_Gusto_benefits_interested_in__c = objOppty.Which_Gusto_benefits_interested_in__c,
					When_to_start_offering_benefits__c = objOppty.When_to_start_offering_benefits__c,
					Who_to_contact__c = objOppty.Who_to_contact__c,
					Initiated_by_Accountant__c = objOppty.Initiated_by_Accountant__c,
					Currently_Offer_Health_Benefits__c = objOppty.Currently_Offer_Health_Benefits__c,
					Want_to_switch_brokers__c = objOppty.Want_to_switch_brokers__c,
					Existing_Health_Benefits_Renewal_Date__c = objOppty.Existing_Health_Benefits_Renewal_Date__c,
					Open_to_Switching_Broker__c = objOppty.Open_to_Switching_Broker__c,
					NumberofEmployees__c = decEmployees,
					Contribution_to_EE_Health_Coverage_cost__c = objOppty.Contribution_to_EE_Health_Coverage_cost__c,
					Interest_in_adding_benefits_to_Gusto__c = objOppty.Interest_in_adding_benefits_to_Gusto__c
				)
			);
		}
	}

	/**
	 * @author      Praveen Sethu
	 * @description Updates Last Client Add Date on Reseller Account
	 * @param       Trigger new Opportunity
	 * @param       Trigger old Opportunity
	 **/
	public void updateLastClientAddDate(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty != null && objOppty.Sold_By__c != null && (objOldOppty == null || (objOppty.Sold_By__c != objOldOppty.Sold_By__c))) {
			if (map_Accounts.containsKey(objOppty.Sold_By__c)) {
				Account objSoldByAcct = map_Accounts.get(objOppty.Sold_By__c);

				if (objSoldByAcct.Last_Client_Add_Date__c == null || objSoldByAcct.Last_Client_Add_Date__c < Date.today()) {
					objSoldByAcct.Last_Client_Add_Date__c = Date.today();
					map_AccountsToUpdate.put(objSoldByAcct.Id, objSoldByAcct);
				}
			}
		}
	}

	/**** Query Accounts ****/
	public static List<Account> queryAccounts(Set<Id> set_AccountIds) {
		/** To avoid getting Inline query has too many rows for direct assignment  exception - Using FOR Loop ***/
		List<Account> list_Accounts = new List<Account>();
		for (Account objAccnt : [
			SELECT
				Id,
				Name,
				Tier__c,
				Current_MRR__c,
				Account_Owner_Role__c,
				RecordTypeId,
				Upsell_Opp_Open__c,
				Upsell_Tier_Opps_Open__c,
				Pricing__c,
				Number_of_Active_Employees__c,
				NumberOfEmployees,
				Number_of_Active_Contractors__c,
				NumberOfEmployees_Lead__c,
				OwnerId,
				Initiated_NP_Flow__c,
				Joined_Date_Panda__c,
				CreatedDate,
				First_Client_Create_Date__c,
				SAL_to_First_Client_Add__c,
				Is_Active_Customer__c,
				Reward_Eligible__c,
				Sold_By__r.Discount__c,
				Discount__c,
				HI_Owner__c,
				Sold_by__c,
				Referred_by__c,
				Benefits_Email_Opt_Out__c,
				Apply_To_All_Clients__c,
				Big_Desk_Sandbox_BenOps__c,
				Big_Desk_CSM_Pitch_Status__c,
				Last_Client_Add_Date__c,
				BillingState,
				ZP_Company_ID__c,
				Additional_Services__c,
				Priority_Support__c,
				ARR__c,
				Payroll_Opp_Owner__c,
				Payroll_Opp_Owner_Role__c,
				Set_Up_Steps_Completed__c,
				NumberOf_Closed_Payroll_Opps_Sold_By__c,
				Number_Of_Open_Payroll_Opps_Sold_By__c,
				No_Of_Closed_Lost_Sold_By__c,
				Product_Experiments__c,
				ZP_Company_Overall_Status__c,
				International_Contractors__c,
				International_Employees__c,
				Premium_Tier_Discount__c,
				Medical_Deductions__c,
				Benefits_Effective_Date__c,
				BillingStateCode,
				Big_Desk_Pilot_Customer__c,
				HI_Active_Benefits__c,
				Cohort_Date__c,
				(
					SELECT Id, No_of_adds_current_Q__c, Q_Tracking__c, No_Of_Change_No_Of_Clients__c, Unique_Account_Id__c
					FROM Account_Related_Trackings__r
					WHERE Unique_Account_Id__c != NULL
					ORDER BY CreatedDate
					LIMIT 1
				),
				(SELECT Id, ZP_User_Role__c FROM Contacts),
				(
					SELECT
						Id,
						RecordTypeId,
						IsClosed,
						IsWon,
						CreatedDate,
						CloseDate,
						StageName,
						Upsell_Tier__c,
						Referral_Code__c,
						Tax_Year__c,
						ROE_Exception__c,
						Source_Id__c,
						OwnerId,
						Type,
						Owner.IsActive
					FROM Opportunities
					ORDER BY CreatedDate DESC
				)
			FROM Account
			WHERE Id IN :set_AccountIds
		]) {
			list_Accounts.add(objAccnt);
		}

		return list_Accounts;
	}

	/**** Query Payment Invoices ****/
	public static List<Payment_Invoice__c> queryPaymentInvoices(Set<Id> set_InvoiceIds) {
		return [
			SELECT
				Id,
				Volume_Discount__c,
				Employee_Count__c,
				Contractor_Count__c,
				Amount__c,
				Discount__c,
				Pricing__c,
				toLabel(Additional_Invoiced_Services__c),
				International_Contractors__c,
				International_Employees__c,
				Account__c,
				Account__r.Sold_By__c,
				Account__r.Reward_Eligible__c,
				Payment_Plan__c
			FROM Payment_Invoice__c
			WHERE Id IN :set_InvoiceIds
		];
	}

	/**
	 * @description           Query Partner Referral Sources
	 *
	 * @param set_LeadSources Partner Referral Source Source Names
	 * @return                `List<Partner_Referral_Source__c>`
	 */
	public static List<Partner_Referral_Source__c> queryPartnerReferralSources(Set<String> set_LeadSources) {
		return [SELECT Id, BizDev_Account__c, Source_Name__c FROM Partner_Referral_Source__c WHERE Source_Name__c IN :set_LeadSources];
	}

	/**** Query ZP User Roles (add role filters) ****/
	public static List<Zp_User_Role__c> queryZPUserRoles(Set<Id> set_AccountIds) {
		Set<String> set_ApplicableRoles = Utils.getRolesSet('Company_Benefits', 'OpportunityTriggerHelper');

		return [
			SELECT Company_Account__c, Contact__c, Role_Name__c
			FROM Zp_User_Role__c
			WHERE Company_Account__c IN :set_AccountIds AND Role_Name__c IN :set_ApplicableRoles AND Contact__c != NULL AND Deleted_At__c = NULL
		];
	}

	/**** Query Policies ****/
	public static List<Policy__c> queryPolicies(Set<Id> set_BenefitsAccountIds) {
		return [
			SELECT
				Id,
				Account__c,
				Is_Selected__c,
				Coverage_Effective_Date__c,
				Expiration_Date__c,
				Benefit_Type__c,
				Visible__c,
				Carrier__c,
				Opportunity__c,
				State__r.Name,
				Opportunity__r.UW_State_PY__c,
				Carrier__r.Name
			FROM Policy__c
			WHERE Account__c IN :set_BenefitsAccountIds
		];
	}

	/**** Query Carriers ****/
	public static List<Carrier__c> queryCarriers(Set<Id> set_CarrierIds) {
		return [
			SELECT Id, Id__c, New_Plan_Submission_Event__c, New_Plan_Variation_Num1__c, New_Plan_Variation_Num2__c, Group_Submission_Event__c, Group_Variation_Number__c, Group_Variation_Number_2__c
			FROM Carrier__c
			WHERE Id IN :set_CarrierIds
		];
	}

	/**** Query Benefit Orders ****/
	public static List<Benefit_Order__c> queryBenefitOrders(Set<Id> set_OpptyBenefitOrderIds) {
		return [
			SELECT Id, OwnerId, Account__c, Opportunity__c, Order_Status__c, RecordTypeId, Closed__c, RecordType.Name, Coverage_Effective_Date__c, Push_Rate_Reason__c, Status_Detail__c
			FROM Benefit_Order__c
			WHERE Opportunity__c IN :set_OpptyBenefitOrderIds
			ORDER BY CreatedDate DESC
		];
	}

	/**** Query Cases ****/
	public static List<Case> queryCases(Set<Id> set_OpptyIds) {
		return [
			SELECT Id, RecordTypeId, OwnerId, Status, Opportunity__c, Region__c, Notes__c, Integration_Id__c, Onboarding_Close_DateTime__c, ContactId, ContactEmail
			FROM Case
			WHERE
				Opportunity__c != NULL
				AND Opportunity__c IN :set_OpptyIds
				AND IsClosed = FALSE
				AND Integration_Id__c != NULL
				AND Integration_Id__c LIKE 'hippo-%'
				AND ((Type != 'Benefits Renewal alignment'
				AND RecordType.Name IN ('Benefits Renewal Case', 'Benefits Change Case'))
				OR RecordType.Name IN ('Benefits Renewal Case', 'Benefits Change Case', 'Benefits New Plan Case', 'Benefits BoR'))
		];
	}

	/**** Create a map of Opportunity of Renewal Survey ****/
	public static List<Renewal_Survey__c> queryRenewalSurveys(Set<Id> set_OpptyRenewalSurveyIds) {
		return [SELECT Id, OwnerId, Opportunity__c FROM Renewal_Survey__c WHERE Opportunity__c IN :set_OpptyRenewalSurveyIds];
	}

	/**** Query Orders ****/
	public static List<Order> queryOrders(Set<Id> set_MigrationReqOpptys) {
		return [SELECT Bulk_Migration__c FROM Order WHERE Bulk_Migration__c != NULL AND OpportunityId IN :set_MigrationReqOpptys];
	}

	/**** Query Opportunity Related Tracking ****/
	public static List<Opportunity_Related_Tracking__c> queryOpptyRelatedTracking(Set<Id> set_StageChangeOpptys) {
		return [SELECT Id, Opportunity__c, Unique_Opp_Id__c, Opp_Stage_Changed__c, First_Stage_Change_Date__c FROM Opportunity_Related_Tracking__c WHERE Opportunity__c IN :set_StageChangeOpptys];
	}

	/*** Query Oppty Line Items ****/
	public static List<OpportunityLineItem> queryOpptyLineItems(Set<Id> set_LineItemOpptys) {
		return [
			SELECT Id, OpportunityId, PricebookEntryId, Product2Id, Product2.Name, Quantity, Discount, Opportunity.NumberOfEmployees__c, UnitPrice, PricebookEntry.UnitPrice
			FROM OpportunityLineItem
			WHERE OpportunityId IN :set_LineItemOpptys
		];
	}

	/*** Query Oppty Tasks ***/
	public static List<Task> queryTasks(Set<Id> set_OwnerChangedIds) {
		Set<String> set_UserRoleIds = UserUtils.getUserRoleIds(
			new Set<String>{
				LeadUtil.LABEL_SDR_MM_MGR_USR_ROLE,
				LeadUtil.LABEL_SDR_MM_USR_ROLE,
				LeadUtil.LABEL_BDR_USR_ROLE,
				LeadUtil.LABEL_SDR_PARTNER_MGR_USR_ROLE,
				LeadUtil.LABEL_SDR_PARTNER_USR_ROLE
			}
		);
		return [
			SELECT Id, WhoId, WhatId, OwnerId, Lead__c, IsClosed, Type, CreatedBy.UserRoleId, LastModifiedBy.UserRoleId, Status, RecordType.DeveloperName
			FROM Task
			WHERE RecordTypeId IN :TaskUtil.set_MDRTaskRecTypes AND WhatId IN :set_OwnerChangedIds AND CreatedBy.UserRoleId IN :set_UserRoleIds
		];
	}

	/*** Query Opportunities based on User ids ***/
	public static List<Opportunity> queryActiveOpportunitiesBasedOnUsers(Set<String> set_UserIds, Set<String> set_RecordTypes, Set<String> set_StageNames) {
		return [
			SELECT Id, OwnerId, Is_Multi_EIN__c, HI_Effective_Date__c
			FROM Opportunity
			WHERE HI_Effective_Date__c != NULL AND OwnerId != NULL AND OwnerId IN :set_UserIds AND RecordTypeId = :set_RecordTypes AND StageName NOT IN :set_StageNames
		];
	}

	/*** Query Opportunities based on isMultiEIn ***/
	public static List<Opportunity> queryMultiEINOpportunities(Set<String> set_MultiEINOpporunities, Set<String> set_RecordTypes) {
		return [
			SELECT Id, OwnerId, Is_Multi_EIN__c, HI_Effective_Date__c, Parent_Opportunity__c
			FROM Opportunity
			WHERE
				HI_Effective_Date__c != NULL
				AND RecordTypeId = :set_RecordTypes
				AND (Id IN :set_MultiEINOpporunities
				OR Parent_Opportunity__c IN :set_MultiEINOpporunities)
				AND Is_Multi_EIN__c = TRUE
		];
	}

	/*** Query HI Benefits Admin Data ***/
	public static List<HI_Benefits_Admin__c> queryHIBenefitsAdmin(Set<String> set_CompanyId) {
		return [SELECT Id, Company_Id__c, ZP_User_Id__c FROM HI_Benefits_Admin__c WHERE Company_Id__c IN :set_CompanyId AND Deleted_At__c = NULL AND Company_Id__c != NULL AND ZP_User_Id__c != NULL];
	}

	/**
	 * @description         Query HI Benefits Signatory Data
	 *
	 * @param set_CompanyIds Set of companyIDs
	 * @return              `List<HI_Benefits_Signatory__c>` queried records
	 */
	public static List<HI_Benefits_Signatory__c> queryHIBenefitsSignatory(Set<String> set_CompanyIds) {
		return [
			SELECT Id, Company_Id__c, ZP_User_Id__c
			FROM HI_Benefits_Signatory__c
			WHERE Company_Id__c IN :set_CompanyIds AND Deleted_At__c = NULL AND Company_Id__c != NULL AND ZP_User_Id__c != NULL
		];
	}

	/*** Query Contact Data ***/
	public static List<Contact> queryContact(Set<String> set_UserId) {
		return [SELECT Id, Name, AccountId, Account.ZP_Company_ID__c, ZP_User_Id__c FROM Contact WHERE ZP_User_Id__c IN :set_UserId AND ZP_User_Id__c != NULL];
	}

	/**
	 * @description Populate Close Date on customer case if there are no Benefit Orders on CLosed Lost Opportunity
	 * @author Neha Dabas
	 * @param  objOpp    new instance after change
	 * @param  objOldOpp old instance before change
	 * @return           list of cases with close date populated.
	 */
	public List<Case> populateCloseDateOnCustomerCase(Opportunity objOpp, Opportunity objOldOpp) {
		List<Case> list_CasesToUpdate = new List<Case>();
		String strRecordTypeName = Cache.getRecordTypeDeveloperName('Opportunity', objOpp.RecordTypeId);

		Configuration_Settings__c objConfig = Utils.ORG_WIDE_CONFIG_SETTINGS;
		Integer intNoOfBusinessHoursToClose = Integer.valueOf(objConfig.Business_Hours_to_Close_Customer_Case__c != null ? objConfig.Business_Hours_to_Close_Customer_Case__c : 0);

		DateTime dtCloseDateTime = Utils.addOrSubtractBusinessHoursToDate(System.now(), intNoOfBusinessHoursToClose);

		String strValidIntegrationId = 'hippo-' + strRecordTypeName + '-' + objOpp.Id;

		// idealy there should be just one case with Integration Id starting with Hippo, we are looping over cases just to make sure we pick correct case
		if (map_OpptyIdToCasesWithIntegrationId.containsKey(objOpp.Id)) {
			for (Case objCase : map_OpptyIdToCasesWithIntegrationId.get(objOpp.Id)) {
				if (objCase.Integration_Id__c.equalsIgnoreCase(strValidIntegrationId)) {
					if (set_ReopenedOppIds.contains(objCase.Opportunity__c)) {
						objCase.Onboarding_Close_DateTime__c = null;
						list_CasesToUpdate.add(objCase);
					} else if (set_ClosedLostOppIds.contains(objCase.Opportunity__c) && !map_OpptyIdToOpenBenefitsOrders.containsKey(objOpp.Id)) {
						objCase.Onboarding_Close_DateTime__c = dtCloseDateTime;
						list_CasesToUpdate.add(objCase);
					}

					break;
				}
			}
		}

		return list_CasesToUpdate;
	}

	/**
	 * @description    Populate Benefits Opt Out fields from Sold By Account.
	 *
	 * @author         Prashant Bhat
	 * @param objOppty new instance after change
	 * @param objOldOppty old instance before change
	 */
	public void updateBenefitOptOutFields(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);
		if (
			(objOldOppty == null ||
			objOppty.Sold_By__c != objOldOppty.Sold_By__c) &&
			objOppty.Sold_By__c != null &&
			(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) &&
			map_Accounts.containsKey(objOppty.Sold_By__c)
		) {
			Account objAcc = map_Accounts.get(objOppty.Sold_By__c);
			if (String.isNotBlank(objAcc.Benefits_Email_Opt_Out__c) && objAcc.Apply_To_All_Clients__c) {
				objOppty.Benefits_Opt_Out__c = objAcc.Benefits_Email_Opt_Out__c;
			}
		}
	}

	//Set Big_Desk_BenOps__c field on Opportunity
	public void setBigDeskBenOps(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID && objOppty.AccountId != null && map_Accounts != null && map_Accounts.containsKey(objOppty.AccountId)) {
			Account objAccount = map_Accounts.get(objOppty.AccountId);
			if (objOldOppty == null) {
				objOppty.Big_Desk_BenOps__c = objAccount.Big_Desk_Sandbox_BenOps__c;
			} else if (objOppty.AccountId != objOldOppty.AccountId) {
				objOppty.Big_Desk_BenOps__c = objAccount.Big_Desk_Sandbox_BenOps__c;
			}
		}
	}
	/**
	 * @author      Prity Kumari
	 * @description Populate First APD Date Missed
	 * @param        objOppty New Opportunity
	 * @param        objOldOppty Old Opportunity
	 **/
	public void populateFirstAPDDateMissed(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOldOppty == null) {
			if (objOppty.Anchor_Pay_Date__c != null && objOppty.First_APD_Date__c == null) {
				objOppty.First_APD_Date__c = objOppty.Anchor_Pay_Date__c;
			}
		} else {
			if (
				(objOldOppty.Anchor_Pay_Date__c == null) &&
				(objOppty.Anchor_Pay_Date__c != null) &&
				(objOppty.Anchor_Pay_Date__c != objOldOppty.Anchor_Pay_Date__c) &&
				(objOldOppty.First_APD_Date__c == null)
			) {
				objOppty.First_APD_Date__c = objOppty.Anchor_Pay_Date__c;
			}
		}
	}

	/**
	 * @author      Deepika Saini
	 * @description Assign the Renewal Opportunity to Advising
	 * @param       objOppty New Opportunity
	 *  @param      objOldOppty Old Opportunity
	 **/
	public void assignOwnerToRenewalOpportunity(Opportunity objOppty, Opportunity objOldOppty) {
		if (OpportunityUtil.isEligibleForAdvisorAssignment(objOppty, objOldOppty)) {
			Opportunity objRelOppty = new Opportunity(Id = objOppty.Id);
			Set<String> set_EligibleUserIds = new Set<String>();
			Boolean blnIsOnwerChanged = false;
			Boolean blnIsCapacityFull = false;
			String strKey = objOppty.HI_Effective_Date__c?.Month() + '~' + objOppty.HI_Effective_Date__c?.Year();
			set_EligibleUserIds = getEligibleUserIdAsPerSkills(objOppty, objOppty.Big_Desk_BenOps__c);

			if (!set_EligibleUserIds.isEmpty()) {
				List<String> list_LowestActiveOppCountUsers = getEligibleUsersWithLowestCount(set_EligibleUserIds, strKey, map_AdvisingUserIdOppCount);

				if (list_LowestActiveOppCountUsers != null && list_LowestActiveOppCountUsers.size() > 0) {
					objRelOppty.OwnerId = list_LowestActiveOppCountUsers.get(0);
					objRelOppty.Advising_Assignment_Message__c = OpportunityUtil.MSG_ASSIGNEMENT_PROCESSED_AS_PER_SKILLS + ' for ' + strKey;
					blnIsOnwerChanged = true;
				} else {
					objRelOppty.Advising_Assignment_Message__c = OpportunityUtil.MSG_USERS_CAPACITY_IS_FULL + ' for ' + strKey;
					blnIsCapacityFull = true;
				}
			}

			//Big Desk Opportunity Assigned to non Big Desk Advising User, if BigDesk User does not have capacity
			if (!blnIsOnwerChanged && objOppty.Big_Desk_BenOps__c) {
				set_EligibleUserIds = getEligibleUserIdAsPerSkills(objOppty, false);

				if (!set_EligibleUserIds.isEmpty()) {
					List<String> list_LowestActiveOppCountUsers = getEligibleUsersWithLowestCount(set_EligibleUserIds, strKey, map_AdvisingUserIdOppCount);

					if (list_LowestActiveOppCountUsers != null && list_LowestActiveOppCountUsers.size() > 0) {
						objRelOppty.OwnerId = list_LowestActiveOppCountUsers.get(0);
						objRelOppty.Advising_Assignment_Message__c = OpportunityUtil.MSG_BIGDESK_OPP_ASSIGNED_TO_NON_BIGDESK_USER + ' for ' + strKey;
						blnIsOnwerChanged = true;
					} else {
						objRelOppty.Advising_Assignment_Message__c = OpportunityUtil.MSG_USERS_CAPACITY_IS_FULL + ' for ' + strKey;
						blnIsCapacityFull = true;
					}
				}
			}

			if (blnIsOnwerChanged) {
				if (!map_AdvisingUserIdsWithSkillType.isEmpty() && map_AdvisingUserIdsWithSkillType.containsKey(objRelOppty.OwnerId)) {
					objRelOppty.Owner_Role_Name__c = map_AdvisingUserIdsWithSkillType.get(objRelOppty.OwnerId);
				}

				map_AdvisingUserIdOppCount.put(objRelOppty.OwnerId + '~' + strkey, map_AdvisingUserIdOppCount.get(objRelOppty.OwnerId + '~' + strkey) + 1);
			} else if (!blnIsCapacityFull) {
				objRelOppty.Advising_Assignment_Message__c = OpportunityUtil.MSG_NO_ADVISING_ASSIGNMENT_USER_ELIGIBLE;
			}

			map_RenewalOpptyToBeUpdated.put(objRelOppty.Id, objRelOppty);
		}
	}

	/**
	 * @author      Deepika Saini
	 * @description Get the Eligilble User With Lowest count of Opportunities
	 * @param       set_OppEligibleUserIds Set of UserIDs
	 * @param       strkey Key for value of Map
	 * @param       map_UserIdCount UserId, Count of Opportunity
	 * @return      `List<String>` List of User ids
	 **/
	public List<String> getEligibleUsersWithLowestCount(Set<String> set_OppEligibleUserIds, String strkey, Map<String, Decimal> map_UserIdCount) {
		List<String> list_EligibleUsers = new List<String>();

		if (map_UserIdCount.size() > 0) {
			Decimal intLowestCount;

			for (String objUserId : set_OppEligibleUserIds) {
				if (map_AdvisingUserIdCap.containsKey(objUserId + '~' + strKey) && map_AdvisingUserIdOppCount.get(objUserId + '~' + strKey) >= map_AdvisingUserIdCap.get(objUserId + '~' + strKey)) {
					continue;
				}

				if (!map_UserIdCount.isEmpty() && map_UserIdCount.containsKey(objUserId + '~' + strKey)) {
					Decimal intTemp = map_UserIdCount.get(objUserId + '~' + strKey);

					if (intLowestCount == null) {
						intLowestCount = intTemp;
						list_EligibleUsers.add(objUserId);
						continue;
					}

					if (intLowestCount > intTemp) {
						intLowestCount = intTemp;
						list_EligibleUsers = new List<String>();
						list_EligibleUsers.add(objUserId);
					}
				}
			}
		}

		return list_EligibleUsers;
	}

	/**
	 * @author      Deepika Saini
	 * @description Get the Eligilble User as Per skills
	 * @param       objOpp opportunity record
	 * @param       blnBigDesk Is Big Desk or not
	 * @return      Set<String> Set of User ids
	 **/
	private Set<String> getEligibleUserIdAsPerSkills(Opportunity objOpp, Boolean blnBigDesk) {
		Set<String> set_EligibleUserIds = new Set<String>();
		String strHashSkills = '';

		if (String.isNotBlank(objOpp.UW_State_PY__c)) {
			strHashSkills = '#' + objOpp.UW_State_PY__c;
		}

		if (blnBigDesk && objOpp.Advisor_Assignment__c == OpportunityUtil.BIG_DESK_ADVISOR_ASSIGNMENT) {
			strHashSkills += '#true';
		} else {
			strHashSkills += '#false';
		}

		if (!map_HashOfAdvisingSkillWithUsers.isEmpty() && map_HashOfAdvisingSkillWithUsers.containsKey(strHashSkills)) {
			set_EligibleUserIds = map_HashOfAdvisingSkillWithUsers.get(strHashSkills);
		}

		return set_EligibleUserIds;
	}

	/**
	 * @description Set Last Blocked Timestamp on Opportunity when Advising Blocked Reason has an update
	 * @author      Neha Dabas
	 * @since        June 17, 2021
	 */
	private void populateLatestBlockedTimestamp(Opportunity objOpp, Opportunity objOldOpp) {
		if (String.isNotBlank(objOpp.Advising_Blocked_Reason__c) && (objOldOpp == null || objOpp.Advising_Blocked_Reason__c != objOldOpp.Advising_Blocked_Reason__c)) {
			objOpp.Last_Blocked_Timestamp__c = System.now();
		}
	}

	/**
	 * @description Set Advising Blocked Reason on Opportunity when Needs Recertification is true
	 * @author     	Deepika Saini
	 * @since       Feb 23, 2021
	 */
	private void setAdvisingBlockedReason(Opportunity objOpp, Opportunity objOldOpp) {
		if (objOpp.Needs_Recertification__c && objOpp.Needs_Recertification__c != objOldOpp.Needs_Recertification__c) {
			objOpp.Advising_Blocked_Reason__c = OpportunityUtil.PENDING_RECERT;
		}
	}

	/**
	 * @description Set Advising Assignment Message on Opportunity when Required fields are empty
	 * @author      Deepika Saini
	 * @since       June 23, 2021
	 */
	private void checkRequiredValuesForAdvisingAssignment(Opportunity objOpp, Opportunity objOldOpp) {
		if (objOpp.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
			if (objOpp.HI_Effective_Date__c == null) {
				objOpp.Advising_Assignment_Message__c = OpportunityUtil.MSG_COVERAGE_EFFECTIVE_DATE_IS_MISSING;
			} else if (objOpp.UW_State_PY__c == null) {
				objOpp.Advising_Assignment_Message__c = OpportunityUtil.MSG_UW_STATE_PY_IS_MISSING;
			}
		}
	}

	/**
	 * @description Set Recommendation Sent Timestamp on Opportunity when Stage is changed to Recommendation Sent for the first time
	 * @author      Neha Dabas
	 * @since       July 20, 2021
	 */
	private void populateRecommendationSentTimestamp(Opportunity objOpp, Opportunity objOldOpp) {
		if (objOpp.Recommendation_Sent_Start__c == null && objOpp.StageName == OpportunityUtil.RECOMMENDATION_SENT_STAGE && (objOldOpp == null || objOpp.StageName != objOldOpp.StageName)) {
			objOpp.Recommendation_Sent_Start__c = System.now();
		}
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description BSS-65 - Updates Offers_Health_Insurance__c field on Account based on the field value on Opportunity
	 * @param       objOppty New Opportunity
	 * @param       objOldOppty Old Opportunity
	 **/
	public void updateOffersHealthInsurance(Opportunity objOppty, Opportunity objOldOppty) {
		Boolean blnAcquisitionNewBusiness = (objOppty.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOppty.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS);
		if (objOppty.AccountId != null) {
			Account objAccnt = map_Accounts.get(objOppty.AccountId);

			if (
				(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || blnAcquisitionNewBusiness) &&
				objOldOppty != null &&
				String.isNotBlank(objOppty.Offers_Health_Insurance__c) &&
				objOldOppty.Offers_Health_Insurance__c != objOppty.Offers_Health_Insurance__c
			) {
				objAccnt.Offers_Health_Insurance__c = objOppty.Offers_Health_Insurance__c;
				map_AccountsToUpdate.put(objAccnt.Id, objAccnt);
			}
		}
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description BSS-111 - Creates BYOB Opp when a BOR Opp gets Closed lost
	 * @param       objOppty New Opportunity
	 * @param       objOldOppty Old Opportunity
	 * @return      new BYOB Opportunity
	 **/
	public Opportunity createBYOBOpportunity(Opportunity objOppty, Opportunity objOldOppty) {
		Account objAccount = objOppty.AccountId != null ? map_Accounts.get(objOppty.AccountId) : new Account();
		Opportunity objOpportunity;

		// BYB Opportunity Stage is Closed Lost
		if (
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID &&
			objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE &&
			objOldOppty != null &&
			objOldOppty.StageName != objOppty.StageName &&
			objOppty.Stage_Detail__c != null &&
			objOppty.Stage_Detail__c.equalsIgnoreCase(OpportunityUtil.BENEFITS_BYOB_STAGE_DETAIL) &&
			objOppty.Stage_Detail_2__c != null &&
			objOppty.Stage_Detail_2__c.equalsIgnoreCase(OpportunityUtil.BENEFITS_BYOB_STAGE_DETAIL2)
		) {
			objOpportunity = new Opportunity();
			objOpportunity.RecordTypeId = OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID;
			objOpportunity.LeadSource = OpportunityUtil.BOR_LOST_REASON;
			if (objAccount != null) {
				objOpportunity.AccountId = objAccount.Id;
			}

			if (OpportunityUtil.map_OpptyRTToDefaultValues.containsKey(objOpportunity.RecordTypeId)) {
				setNameAndType(objOpportunity, null);
			}

			objOpportunity.StageName = OpportunityUtil.DEFAULT_HI_SALES_STAGE;
			if (objAccount != null && objAccount.Number_of_Active_Employees__c != null) {
				objOpportunity.NumberOfEmployees__c = objAccount.Number_of_Active_Employees__c;
			}
			if (objAccount != null && String.isNotBlank(objAccount.BillingState)) {
				objOpportunity.HI_Opportunity_Assignment_State__c = objAccount.BillingState;
			}
			objOpportunity.OwnerId = objOppty.OwnerId;
			if (objAccount != null && String.isNotBlank(objAccount.ZP_Company_ID__c)) {
				objOpportunity.ZP_Company_ID__c = objAccount.ZP_Company_ID__c;

				if (String.isBlank(objOpportunity.Source_ID__c)) {
					objOpportunity.Source_ID__c = 'BYB - ' + objAccount.ZP_Company_ID__c;
				}
			}
			Date dtToday = System.today();
			Integer intNumOfDays = Date.daysInMonth(dtToday.year(), dtToday.month());
			Date dtLastDayOfMonth = Date.newInstance(dtToday.year(), dtToday.month(), intNumOfDays);

			objOpportunity.CloseDate = dtLastDayOfMonth;
		}
		return objOpportunity;
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description BSS-146 - BYB Opportunity Updates
	 * @param       objOppty New Opportunity
	 * @param       objOldOppty Old Opportunity
	 **/
	public void updateBYOBOpportunity(Opportunity objOppty, Opportunity objOldOppty) {
		// Check BYOB Opportunity to Update specific fields
		if (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID) {
			if (objOldOppty == null) {
				Account objAccount = objOppty.AccountId != null ? map_Accounts.get(objOppty.AccountId) : new Account();
				if (objAccount != null) {
					objOppty.AccountId = objAccount.Id;
				}

				if (!OpportunityUtil.blnIsLoggedInUserWorkatoIntUser()) {
					objOppty.StageName = (String.IsNotBlank(objOppty.Touch_Type__c) &&
						(objOppty.Touch_Type__c == OpportunityUtil.HI_EBBP_CREATION ||
						objOppty.Touch_Type__c == OpportunityUtil.HI_BAT_CREATION) &&
						String.IsNotBlank(objOppty.StageName))
						? objOppty.StageName
						: OpportunityUtil.DEFAULT_HI_SALES_STAGE;
				}

				if (objAccount != null && objAccount.Number_of_Active_Employees__c != null) {
					objOppty.NumberOfEmployees__c = objAccount.Number_of_Active_Employees__c;
				}
				if (objAccount != null && String.isNotBlank(objAccount.BillingState)) {
					objOppty.HI_Opportunity_Assignment_State__c = objAccount.BillingState;
				}
				if (objAccount != null && String.isNotBlank(objAccount.ZP_Company_ID__c)) {
					objOppty.ZP_Company_ID__c = objAccount.ZP_Company_ID__c;

					if (String.isBlank(objOppty.Source_ID__c)) {
						objOppty.Source_ID__c = 'BYB - ' + objAccount.ZP_Company_ID__c + ' - ' + Utils.getRandomIntValue(5);
					}
				}
				Date dtToday = System.today();
				Integer intNumOfDays = Date.daysInMonth(dtToday.year(), dtToday.month());
				Date dtLastDayOfMonth = Date.newInstance(dtToday.year(), dtToday.month(), intNumOfDays);

				objOppty.CloseDate = (String.IsNotBlank(objOppty.Touch_Type__c) &&
					(objOppty.Touch_Type__c == OpportunityUtil.HI_EBBP_CREATION ||
					objOppty.Touch_Type__c == OpportunityUtil.HI_BAT_CREATION) &&
					objOppty.CloseDate != null)
					? objOppty.CloseDate
					: dtLastDayOfMonth;
			} else {
				if (objOppty.Amount != null && objOppty.Amount != objOldOppty.Amount) {
					objOppty.Price_at_Closed_Won__c = objOppty.Amount;
				}
			}
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Set Advisor Assignment Timestamp when Owner Role is Advisor
	 * @param         List of Tickets
	 * @return       N/A
	 **/
	private void populateAdvisorAssignmentTimestamp(Opportunity objOpp, Opportunity objOldOpp) {
		if (
			objOpp.Owner_Role_Name__c == FWManageRoleUtil.ROLE_ADVISOR &&
			(objOldOpp == null ||
			objOpp.Owner_Role_Name__c != objOldOpp.Owner_Role_Name__c) &&
			objOpp.Dedicated_Advisor_Assignment_Timestamp__c == null
		) {
			objOpp.Dedicated_Advisor_Assignment_Timestamp__c = System.now();
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Set OB PRE Timestamp when Outbound PRE Result is set to Complete
	 * @param         List of Tickets
	 * @return       N/A
	 **/
	private void populateOBPRETimestamp(Opportunity objOpp, Opportunity objOldOpp) {
		if (
			objOpp.Outbound_PRE_Result__c != objOldOpp.Outbound_PRE_Result__c &&
			objOpp.Outbound_PRE_Result__c == OpportunityUtil.OUTBOUND_PRE_COMPLETE &&
			objOpp.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID
		) {
			objOpp.OB_PRE_Timestamp__c = System.now();
		}
	}

	/* @author      Praveen Sethu
	 * @description Handles creation of Cross-Sell and Upsell opportunity. Sets amount on Cross-Sell and Upsell as the revenue difference between upsell and current tier
	 * @param       objOppty New Opportunity
	 * @return      new Cross-Sell and Upsell Opportunity
	 **/
	public Opportunity handleCreateTierUpsellOpportunity(Opportunity objOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID) {
			String strUpsellPricebookName = null;
			Decimal decSalesPrice = 0;
			Account objAccount = objOppty.AccountId != null ? map_Accounts.get(objOppty.AccountId) : new Account();
			String strAccountPricing = AccountUtil.map_TierPaymentPlan.containsKey(objAccount.Tier__c?.toLowerCase())
				? AccountUtil.map_TierPaymentPlan.get(objAccount.Tier__c.toLowerCase())
				: (objAccount.Pricing__c != null ? objAccount.Pricing__c : null);
			Map<String, Pricebook2> map_Pricebooks = PricebookQueryHelper.getActivePricebooksMap();
			List<String> list_OpptyAddtionalServices = new List<String>();
			Decimal decPremiumTierDiscountUpsellTier = 0;
			Decimal decPremiumTierDiscountCurrentTier = 0;
			String strAccountAdditionalServices = objAccount.Additional_Services__c;
			Boolean blnInternationalPayroll = false;

			// Setting Pricebook2Id on Cross-Sell and Upsell Opportunity
			if (String.isNotBlank(objOppty.Upsell_Tier__c)) {
				// If upsell tier starts with simple - use the simple plan pricebook
				if (objOppty.Upsell_Tier__c.startsWithIgnoreCase(AccountUtil.SIMPLE_TIER) && map_Pricebooks.containsKey(AccountUtil.SIMPLE_PAYMENT_PLAN)) {
					objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.SIMPLE_PAYMENT_PLAN).Id;
					strUpsellPricebookName = AccountUtil.SIMPLE_PAYMENT_PLAN;
				} else if (objOppty.Upsell_Tier__c.startsWithIgnoreCase(AccountUtil.PLUS_TIER) && map_Pricebooks.containsKey(AccountUtil.PLUS_PAYMENT_PLAN)) {
					// If the upsell tier starts with plus, use the plus pricebook
					objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.PLUS_PAYMENT_PLAN).Id;
					strUpsellPricebookName = AccountUtil.PLUS_PAYMENT_PLAN;

					// If upsell tier contains priority support, set additional services and set priority support to true
					if (objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.PRIORITY_SUPPORT)) {
						list_OpptyAddtionalServices.add(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT);
					}
				} else if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.PREMIUM_TIER) && map_Pricebooks.containsKey(AccountUtil.PREMIUM_PAYMENT_PLAN)) {
					// If the upsell tier starts with premium, use the premium pricebook
					objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.PREMIUM_PAYMENT_PLAN).Id;
					strUpsellPricebookName = AccountUtil.PREMIUM_PAYMENT_PLAN;
					// add premium tier discount for the upsell tier
					decPremiumTierDiscountUpsellTier = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
				} else if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.LEGACY_PREMIUM_TIER) && map_Pricebooks.containsKey(AccountUtil.LEGACY_PREMIUM_PAYMENT_PLAN)) {
					// If the upsell tier starts with legacy premium, use the legacy premium pricebook
					objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.LEGACY_PREMIUM_PAYMENT_PLAN).Id;
					strUpsellPricebookName = AccountUtil.LEGACY_PREMIUM_PAYMENT_PLAN;
					// add legacy premium tier discount for the upsell tier
					decPremiumTierDiscountUpsellTier = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
				} else if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.CRB_PREMIUM_TIER) && map_Pricebooks.containsKey(AccountUtil.CRB_PREMIUM_PAYMENT_PLAN)) {
					// If the upsell tier starts with CRB premium, use the CRB premium pricebook
					objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.CRB_PREMIUM_PAYMENT_PLAN).Id;
					strUpsellPricebookName = AccountUtil.CRB_PREMIUM_PAYMENT_PLAN;
					// add CRB premium tier discount for the upsell tier
					decPremiumTierDiscountUpsellTier = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
				} else if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.MULTI_EIN_PREMIUM_TIER) && map_Pricebooks.containsKey(AccountUtil.MULTI_EIN_PREMIUM_PAYMENT_PLAN)) {
					// If the upsell tier starts with MULTI EIN premium, use the MULTI EIN premium pricebook
					objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.MULTI_EIN_PREMIUM_PAYMENT_PLAN).Id;
					strUpsellPricebookName = AccountUtil.MULTI_EIN_PREMIUM_PAYMENT_PLAN;
					// add MULTI EIN premium tier discount for the upsell tier
					decPremiumTierDiscountUpsellTier = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
				} else if (objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
					// get international Cross-Sell and Upsell pricebook and if account's tier is blank then consider pricebook as a simple.
					if (String.isBlank(objAccount.Tier__c)) {
						objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.SIMPLE_PAYMENT_PLAN).Id;
						strUpsellPricebookName = AccountUtil.SIMPLE_PAYMENT_PLAN;
					} else {
						if (objAccount.Tier__c.equalsIgnoreCase(AccountUtil.SIMPLE_TIER)) {
							objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.SIMPLE_PAYMENT_PLAN).Id;
							strUpsellPricebookName = AccountUtil.SIMPLE_PAYMENT_PLAN;
						} else if (objAccount.Tier__c.equalsIgnoreCase(AccountUtil.PLUS_TIER)) {
							objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.PLUS_PAYMENT_PLAN).Id;
							strUpsellPricebookName = AccountUtil.PLUS_PAYMENT_PLAN;
						} else if (objAccount.Tier__c.equalsIgnoreCase(AccountUtil.PREMIUM_TIER)) {
							objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.PREMIUM_PAYMENT_PLAN).Id;
							strUpsellPricebookName = AccountUtil.PREMIUM_PAYMENT_PLAN;
						} else if (objAccount.Tier__c.equalsIgnoreCase(AccountUtil.LEGACY_PREMIUM_TIER)) {
							objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.LEGACY_PREMIUM_PAYMENT_PLAN).Id;
							strUpsellPricebookName = AccountUtil.LEGACY_PREMIUM_PAYMENT_PLAN;
						} else if (objAccount.Tier__c.equalsIgnoreCase(AccountUtil.CRB_PREMIUM_TIER)) {
							objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.CRB_PREMIUM_PAYMENT_PLAN).Id;
							strUpsellPricebookName = AccountUtil.CRB_PREMIUM_PAYMENT_PLAN;
						} else if (objAccount.Tier__c.equalsIgnoreCase(AccountUtil.MULTI_EIN_PREMIUM_TIER)) {
							objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.MULTI_EIN_PREMIUM_PAYMENT_PLAN).Id;
							strUpsellPricebookName = AccountUtil.MULTI_EIN_PREMIUM_PAYMENT_PLAN;
						}
					}
				} else if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
					objOppty.Pricebook2Id = null;
					strUpsellPricebookName = '';
				} else {
					// check for old tiers
					for (String strTier : AccountUtil.map_TierPaymentPlan.keySet()) {
						if (objOppty.Upsell_Tier__c.startsWithIgnoreCase(strTier)) {
							objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.map_TierPaymentPlan.get(strTier)).Id;
							strUpsellPricebookName = AccountUtil.map_TierPaymentPlan.get(strTier);
							break;
						}
					}
				}

				// If the upsell tier contains Employer of Record, set additional services to Employer of Record
				if (objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
					list_OpptyAddtionalServices.add(AccountUtil.EMPLOYER_OF_RECORD);
					// Assign International Employee to 1 if Account does not have International Employees
					objOppty.International_Employees__c = objAccount.International_Employees__c == null || objAccount.International_Employees__c == 0 ? 1 : objAccount.International_Employees__c;
					blnInternationalPayroll = true;
				}

				// If the upsell tier contains Employer of Record, set additional services to Employer of Record
				if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
					list_OpptyAddtionalServices.add(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT);
					// Assign International Employee to 1 if Account does not have International Employees
					objOppty.International_Contractors__c = objAccount.International_Contractors__c == null ||
						objAccount.International_Contractors__c == 0
						? 1
						: objAccount.International_Contractors__c;
				}

				// get value from account addittional services
				if (String.isNotBlank(strAccountAdditionalServices)) {
					for (String strService : strAccountAdditionalServices.split(';')) {
						if (!list_OpptyAddtionalServices.contains(strService)) {
							list_OpptyAddtionalServices.add(strService);
						}
					}
				}
			}

			if (objAccount.Sold_By__c != null && objAccount.Reward_Eligible__c && objAccount.Sold_By__r.Discount__c != null) {
				objOppty.Discount__c = objAccount.Sold_By__r.Discount__c;
			}
			// create Source Id for the Cross-Sell and Upsell
			if (objOppty.Upsell_Tier__c != null && objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
				objOppty.Source_ID__c = String.isBlank(objOppty.Source_ID__c) && String.isNotBlank(objAccount.ZP_Company_ID__c)
					? objAccount.ZP_Company_ID__c + '-tierupsellintl-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year()
					: null; // month-year
				objOppty.Name = objAccount.Name != null ? objAccount.Name + UPSELL_OPP_SUFFIX : null;
				objOppty.Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
			} else if (objOppty.Upsell_Tier__c != null && objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
				objOppty.Source_ID__c = String.isBlank(objOppty.Source_ID__c) && String.isNotBlank(objAccount.ZP_Company_ID__c)
					? objAccount.ZP_Company_ID__c + '-CrossSellICP-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year()
					: String.isNotBlank(objOppty.Source_ID__c) ? objOppty.Source_ID__c : null; // month-year
				objOppty.Name = objAccount.Name != null ? objAccount.Name + AccountUtil.ICP_OPP_SUFFIX : null;
				//objOppty.Additional_Opportunity_Services__c = AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT;
			} else {
				objOppty.Source_ID__c = String.isBlank(objOppty.Source_ID__c) && String.isNotBlank(objAccount.ZP_Company_ID__c)
					? objAccount.ZP_Company_ID__c + '-tierupsell-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year()
					: null; // month-year
				objOppty.Name = objAccount.Name != null ? objAccount.Name + TIER_UPSELL_OPP_SUFFIX : null;
				objOppty.Additional_Opportunity_Services__c = String.join(list_OpptyAddtionalServices, ';');
			}

			// Account tier is blank then Employer of Record Cross-Sell and Upsell's current tier will be Simple
			if (
				String.isBlank(objAccount.Tier__c) &&
				objOppty.Upsell_Tier__c != null &&
				(objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD) || objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT))
			) {
				objOppty.Current_Tier__c = 'Simple';
			} else {
				objOppty.Current_Tier__c = objAccount.Tier__c;
			}

			objOppty.NumberOfEmployees__c = objAccount.Number_of_Active_Employees__c;
			objOppty.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c;
			objOppty.Sold_By__c = objAccount.Sold_By__c;

			//objOppty.StageName = blnInternationalPayroll ? OpportunityUtil.NEW_STAGE : OpportunityUtil.QUALIFIED_STAGE;
			//objOppty.StageName = OpportunityUtil.NEW_STAGE;
			if (objOppty.Upsell_Tier__c != null && !objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
				objOppty.StageName = OpportunityUtil.NEW_STAGE;
			}
			objOppty.ZP_Company_ID__c = objAccount.ZP_Company_Id__c;
			objOppty.International_Contractors__c = objAccount.International_Contractors__c;

			// add premium tier discount if current tier is premium
			if (String.isNotBlank(objOppty.Current_Tier__c) && objOppty.Current_Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER)) {
				// add premium tier discount for the current tier
				decPremiumTierDiscountCurrentTier = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
			}
			// Calculating MRR based on current Pricing on the Account
			// MRR will always be 0 for Employer of Record Cross-Sell and Upsell
			if (
				objOppty.Upsell_Tier__c != null &&
				(objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD) || objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT))
			) {
				objOppty.MRR__c = 0;
			} else {
				objOppty.MRR__c = OpportunityUtil.calculateMRROppNew(
					objOppty.NumberOfEmployees__c,
					objOppty.Number_of_Contractors__c,
					objAccount.International_Employees__c,
					objAccount.International_Contractors__c,
					objAccount.Additional_Services__c,
					objOppty.Discount__c,
					decPremiumTierDiscountCurrentTier,
					strAccountPricing
				);
			}

			// Calculating MRR based on Pricing from Upsell Tier
			// if upsell tier is Employer of Record then use upsell tier for the amount calculation or else use Additional_Opportunity_Services__c
			String strAdditionalServicesToCalculateAmount = '';
			if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
				strAdditionalServicesToCalculateAmount = AccountUtil.EMPLOYER_OF_RECORD;
			} else {
				strAdditionalServicesToCalculateAmount = objOppty.Additional_Opportunity_Services__c;
			}

			decSalesPrice = OpportunityUtil.calculateMRROppNew(
				objOppty.NumberOfEmployees__c,
				objOppty.Number_of_Contractors__c,
				objOppty.International_Employees__c,
				objOppty.International_Contractors__c,
				strAdditionalServicesToCalculateAmount,
				objOppty.Discount__c,
				decPremiumTierDiscountUpsellTier, // premium tier discount
				strUpsellPricebookName
			);

			// Amount is the difference between amount calculated using upsell tier minus amount calculated using current pricing on the Account
			objOppty.Amount = decSalesPrice - (objOppty.MRR__c != null ? objOppty.MRR__c : 0);

			/**objOppty.CloseDate = String.isNotBlank(objOppty.Upsell_Tier__c) && objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)
				? System.Today().addDays(EMPLOYER_OF_RECORD)
				: System.Today().addDays(45); **/

			if (String.isNotBlank(objOppty.Upsell_Tier__c)) {
				if (objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
					objOppty.CloseDate = System.Today().addDays(INTERNATIONAL_PAYROLL_CLOSE_DATE_DAYS);
				} else if (objOppty.Upsell_Tier__c == AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT) {
					objOppty.CloseDate = System.Today().addDays(90);
				} else if (!objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
					objOppty.CloseDate = System.Today().addDays(45);
				}
			}

			objOppty.Product_Experiments_Opportunity__c = objAccount.Product_Experiments__c;
		}
		blnTierUpsellOpp = true;
		return objOppty;
	}

	/* @author      Prity Kumari
	 * @description BTA-481 - Populate Cross-Sell and Upsell Values
	 * @param       objOppty New Opportunity
	 * @return      new Cross-Sell and Upsell Opportunity
	 **/
	public Opportunity updateTierUpsellOpportunity(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && !objOppty.IsClosed) {
			Account objAccount = objOppty.AccountId != null ? map_Accounts.get(objOppty.AccountId) : new Account();
			/**objOppty.Source_ID__c = String.isBlank(objOppty.Source_ID__c) && String.isNotBlank(objAccount.ZP_Company_ID__c)
				? objAccount.ZP_Company_ID__c + '-tierupsell-' + System.today().month() + '-' + System.today().year()
				: objOppty.Source_ID__c; // month-year **/
			// updating Cross-Sell and Upsell source Id
			if (objOppty.Upsell_Tier__c != null && objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
				objOppty.Source_ID__c = String.isBlank(objOppty.Source_ID__c) && String.isNotBlank(objAccount.ZP_Company_ID__c)
					? objAccount.ZP_Company_ID__c + '-tierupsellintl-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year()
					: String.isNotBlank(objOppty.Source_ID__c) ? objOppty.Source_ID__c : null; // month-year
			} else if (objOppty.Upsell_Tier__c != null && objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
				objOppty.Source_ID__c = String.isBlank(objOppty.Source_ID__c) && String.isNotBlank(objAccount.ZP_Company_ID__c)
					? objAccount.ZP_Company_ID__c + '-CrossSellICP-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year()
					: String.isNotBlank(objOppty.Source_ID__c) ? objOppty.Source_ID__c : null; // month-year
			} else {
				objOppty.Source_ID__c = String.isBlank(objOppty.Source_ID__c) && String.isNotBlank(objAccount.ZP_Company_ID__c)
					? objAccount.ZP_Company_ID__c + '-tierupsell-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year()
					: String.isNotBlank(objOppty.Source_ID__c) ? objOppty.Source_ID__c : null; // month-year
			}

			objOppty.ZP_Company_ID__c = objOppty.ZP_Company_ID__c != objAccount.ZP_Company_Id__c ? objAccount.ZP_Company_Id__c : objOppty.ZP_Company_ID__c;
			objOppty.Name = String.isBlank(objOppty.Name) && String.isNotBlank(objAccount.Name) ? objAccount.Name + ' - Cross sell EOR' : objOppty.Name;
		}
		return objOppty;
	}

	/* @author      Praveen Sethu
	 * @description Handles update on Cross-Sell and Upsell opportunity
	 * @param       Trigger.new opportunity
	 * @param       Trigger.old opportunity
	 **/
	public void handleTierUpsellUpdate(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID) {
			updateTierUpsellCloseDate(objOppty, objOldOppty);
			reCalculateUpsellAmount(objOppty, objOldOppty);
		}
	}

	/* @author      Praveen Sethu
	 * @description Handle data changing on Cross-Sell and Upsell opportunity and updates the Amount
	 * @param       Trigger.new opportunity
	 * @param       Trigger.old opportunity
	 **/
	public void reCalculateUpsellAmount(Opportunity objOppty, Opportunity objOldOppty) {
		// looking for any change in data that impact Amount on Cross-Sell and Upsell opportunity (like Upsell tier, additional services, etc.)
		if (objOppty.Upsell_Tier__c != objOldOppty.Upsell_Tier__c && String.isNotBlank(objOppty.Upsell_Tier__c) && !objOppty.IsClosed && map_Accounts.containsKey(objOppty.AccountId)) {
			// Get list of active pricebooks
			Decimal decAccountantDiscount = 0;
			Decimal decPremiumTierDiscount = 0;
			Map<String, Pricebook2> map_Pricebooks = PricebookQueryHelper.getActivePricebooksMap();
			String strUpsellPricebookName = null;
			for (String strTier : AccountUtil.map_TierPaymentPlan.keySet()) {
				if (objOppty.Upsell_Tier__c.startsWithIgnoreCase(strTier)) {
					objOppty.Pricebook2Id = map_Pricebooks.get(AccountUtil.map_TierPaymentPlan.get(strTier)).Id;
					strUpsellPricebookName = AccountUtil.map_TierPaymentPlan.get(strTier);
					break;
				}
			}

			Account objAccount = map_Accounts.get(objOppty.AccountId);
			// get accountant discount from sold by reseller account
			if (objAccount.Sold_By__c != null && objAccount.Reward_Eligible__c && objAccount.Sold_By__r.Discount__c != null) {
				decAccountantDiscount = objAccount.Sold_By__r.Discount__c;
			}
			// add premium tier discount if upsell tier is premium
			if (objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER)) {
				decPremiumTierDiscount = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
			}

			// update additional services based on upsell tier
			Set<String> set_AdditionalServices = String.isBlank(objOppty.Additional_Opportunity_Services__c)
				? new Set<String>()
				: new Set<String>(objOppty.Additional_Opportunity_Services__c.split(';'));

			if (objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.PRIORITY_SUPPORT)) {
				set_AdditionalServices.add(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT);
			} else {
				set_AdditionalServices.remove(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT);
			}

			if (objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
				set_AdditionalServices.add(AccountUtil.EMPLOYER_OF_RECORD);
				objOppty.International_Employees__c = objAccount.International_Employees__c == null || objAccount.International_Employees__c == 0 ? 1 : objAccount.International_Employees__c;
			} else if (objOppty.Upsell_Tier__c.containsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
				set_AdditionalServices.add(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT);
				objOppty.International_Contractors__c = objAccount.International_Contractors__c == null || objAccount.International_Contractors__c == 0 ? 1 : objAccount.International_Contractors__c;
			} else {
				set_AdditionalServices.remove(AccountUtil.EMPLOYER_OF_RECORD);
				objOppty.International_Employees__c = 0;
			}

			String strAdditionalServicesToCalculateAmount = '';
			if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
				strAdditionalServicesToCalculateAmount = AccountUtil.EMPLOYER_OF_RECORD;
				objOppty.Additional_Opportunity_Services__c = AccountUtil.EMPLOYER_OF_RECORD;
			} else if (objOppty.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT)) {
				//objOppty.Additional_Opportunity_Services__c = AccountUtil.INTERNATIONAL_CONTRACTOR_PAYMENT;
			} else {
				strAdditionalServicesToCalculateAmount = objOppty.Additional_Opportunity_Services__c;
				objOppty.Additional_Opportunity_Services__c = String.join(new List<String>(set_AdditionalServices), ';');
			}

			// recalculate amount
			Decimal decSalesPrice = 0;

			decSalesPrice = OpportunityUtil.calculateMRROppNew(
				objOppty.NumberOfEmployees__c,
				objOppty.Number_of_Contractors__c,
				objOppty.International_Employees__c,
				objOppty.International_Contractors__c,
				strAdditionalServicesToCalculateAmount,
				decAccountantDiscount,
				decPremiumTierDiscount,
				strUpsellPricebookName
			);

			objOppty.Amount = decSalesPrice - (objOppty.MRR__c != null ? objOppty.MRR__c : 0);
		}
	}

	/* @author      Todd Dowdy
	 * @description BTA-481 - Populate Cross-Sell and Upsell Values
	 * @param       objOpp New Opportunity, objOldOpp Old Opportunity
	 * @return      new Cross-Sell and Upsell Opportunity
	 **/
	public void updateTierUpsellInvoiceAmount(Opportunity objOpp, Opportunity objOldOpp) {
		if (
			objOpp.Payment_Invoice__c != null &&
			map_PaymentInvoices.containsKey(objOpp.Payment_Invoice__c) &&
			objOpp.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
			objOldOpp.Payment_Invoice__c != objOpp.Payment_Invoice__c
		) {
			// Get Discount from Sold By Reseller Account
			Decimal decAccountantDiscount = 0;
			Decimal decPremiumTierDiscount = 0;
			Account objAccount = objOpp.AccountId != null ? map_Accounts.get(objOpp.AccountId) : new Account();
			if (objAccount.Sold_By__c != null && objAccount.Reward_Eligible__c && objAccount.Sold_By__r.Discount__c != null) {
				decAccountantDiscount = objAccount.Sold_By__r.Discount__c;
			}

			Payment_Invoice__c objInvoice = map_PaymentInvoices.get(objOpp?.Payment_Invoice__c);

			// add premium tier discount if invoice tier is premium
			if (String.isNotBlank(objInvoice.Payment_Plan__c) && objInvoice.Payment_Plan__c.containsIgnoreCase(AccountUtil.PREMIUM_TIER)) {
				decPremiumTierDiscount = objAccount.Premium_Tier_Discount__c != null ? objAccount.Premium_Tier_Discount__c : 0;
			}

			if (objInvoice?.Amount__c != null && objInvoice?.Amount__c > 0) {
				Decimal decSalesPrice = 0;
				decSalesPrice = OpportunityUtil.calculateMRROppNew(
					objInvoice.Employee_Count__c,
					objInvoice.Contractor_Count__c,
					objInvoice.International_Employees__c,
					objInvoice.International_Contractors__c,
					objInvoice.Additional_Invoiced_Services__c,
					decAccountantDiscount,
					decPremiumTierDiscount,
					objInvoice.Pricing__c
				);
				if (objOpp.Amount != decSalesPrice - objOpp.MRR__c) {
					objOpp.Amount = decSalesPrice - (objOpp.MRR__c != null ? objOpp.MRR__c : 0);
				}

				//setting amount to zero if it's in negative
				if (objOpp.Amount < 0) {
					objOpp.Amount = 0;
				}
			}

			// Set fields from Invoice to opportunity
			objOpp.NumberOfEmployees__c = objInvoice.Employee_Count__c;
			objOpp.Number_of_Contractors__c = objInvoice.Contractor_Count__c;
			objOpp.Additional_Opportunity_Services__c = objInvoice.Additional_Invoiced_Services__c;
			objOpp.International_Employees__c = objInvoice.International_Employees__c;
			objOpp.International_Contractors__c = objInvoice.International_Contractors__c;

			// update pricebook and upsell tier based on invoice pricing
			String strUpsellTier = '';
			Map<String, Pricebook2> map_Pricebooks = PricebookQueryHelper.getActivePricebooksMap();
			if (String.isNotBlank(objInvoice.Pricing__c) && map_Pricebooks.containsKey(objInvoice.Pricing__c)) {
				objOpp.Pricebook2Id = map_Pricebooks.get(objInvoice.Pricing__c).Id;
				strUpsellTier = map_Pricebooks.get(objInvoice.Pricing__c).Product_Tier__c;
			}
			// append upsell tier based on invoice additional services
			if (String.isNotBlank(objInvoice.Additional_Invoiced_Services__c)) {
				if (objInvoice.Additional_Invoiced_Services__c.containsIgnoreCase(OpportunityUtil.ADD_SERVICES_PRIORITY_SUPPORT)) {
					strUpsellTier += ' with ' + AccountUtil.PRIORITY_SUPPORT;
				}

				if (objInvoice.Additional_Invoiced_Services__c.containsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
					strUpsellTier += ' and ' + AccountUtil.EMPLOYER_OF_RECORD;
				}
			}
			objOpp.Upsell_Tier__c = strUpsellTier;

			//setting amount to zero if it's in negative
			if (objOpp.Amount < 0) {
				objOpp.Amount = 0;
			}
		}
	}

	/* @author      Prity Kumari
	 * @description BTA-620 - Create Opportunity Split
	 * @param       objOpp New Opportunity, objOldOpp Old Opportunity
	 **/
	public list<OpportunitySplit> createOpportunitySplits(Map<Id, Id> map_OppToOwnerId) {
		list<OpportunitySplit> list_OpportunitySplitCreate = new List<OpportunitySplit>();
		for (Id idOpp : map_OppToOwnerId.keySet()) {
			// Check if the opportunity owner has a split record
			Boolean hasSplitRecord = false;
			for (OpportunitySplit objSplit : map_OpportunitySplit.get(idOpp)) {
				if (objSplit.SplitOwnerId == map_OppToOwnerId.get(idOpp)) {
					hasSplitRecord = true;
					break;
				}
			}
			if (!hasSplitRecord) {
				OpportunitySplit objNewSplit = new OpportunitySplit();
				objNewSplit.OpportunityId = idOpp;
				objNewSplit.SplitOwnerId = map_OppToOwnerId.get(idOpp);
				objNewSplit.SplitTypeId = OpportunityUtil.getSplitType(OpportunityUtil.SPLIT_TYPE_REVENUE);
				objNewSplit.SplitPercentage = 0.0;
				list_OpportunitySplitCreate.add(objNewSplit);
			}
		}
		return list_OpportunitySplitCreate;
	}

	/* @author      Prity Kumari
	 * @description BTA-620 - Update & Delete Opportunity Split
	 * @param       objOpp New Opportunity
	 **/
	public void syncOpportunitySplits(Opportunity objOpportunity) {
		list_OpportunitySplitUpdate = new List<OpportunitySplit>();
		list_OpportunitySplitDelete = new List<OpportunitySplit>();
		for (OpportunitySplit objSplit : map_OpportunitySplit.get(objOpportunity.Id)) {
			if (objSplit.SplitOwnerId == objOpportunity.OwnerId && objSplit.SplitPercentage != 100) {
				objSplit.SplitPercentage = 100;
				list_OpportunitySplitUpdate.add(objSplit);
			} else if (objSplit.SplitOwnerId != objOpportunity.OwnerId && objSplit.SplitPercentage == 100) {
				objSplit.SplitPercentage = 0;
				list_OpportunitySplitUpdate.add(objSplit);
				list_OpportunitySplitDelete.add(objSplit);
			} else if (objSplit.SplitOwnerId != objOpportunity.OwnerId && objSplit.SplitPercentage == 0) {
				list_OpportunitySplitDelete.add(objSplit);
			}
		}
	}

	/* @description Add opportunity Ids to be sent to routing tool for routing
	 * @param       objOppty New Opportunity
	 * @return      NAs
	 **/
	public void checkRoutingCriteria(Opportunity objOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && objOppty.Upsell_Tier__c == AccountUtil.EMPLOYER_OF_RECORD) {
			Account objAccount = map_Accounts.get(objOppty.AccountId);

			if (objAccount.Joined_Date_Panda__c != null) {
				set_OpportunityIdsToRoute.add(objOppty.Id);
			}
		}
	}

	/* @author      Praveen Sethu
	 * @description Set HI Owner on Account.
	 * @param       objOppty New Opportunity, objOldOppty Old Opportunity
	 * @return      NA
	 **/
	public void setHIOwnerOnAccount(Opportunity objOppty, Opportunity objOldOppty) {
		Account objAcc = map_Accounts.get(objOppty.AccountId);
		// send oppty for routing during oppty insert and record type is benefits new plan or (Benefit BoR or benefits byob and type is not renewal byb)
		if (
			objOldOppty == null &&
			(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
			((objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) &&
			objOppty.Type != OpportunityUtil.OPPTY_TYPE_RENEWAL_BYB)) &&
			objAcc != null &&
			objAcc.ZP_Company_Overall_Status__c != AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED && // do not trigger routing for suspended accounts
			objAcc.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID // set hi owner only on company accounts
		) {
			// Get lower and uppper threshold values from custom labels
			String strBrokerThreshold = System.Label.Broker_Threshold;
			String strNewPlanThreshold = System.Label.New_Plan_Threshold;
			Boolean blnSendForRouting = false;
			Boolean blnSkipRouting = false;
			String strRecordType = 'Benefits Opportunity';

			Integer intBrokerLowerThreshold = Integer.valueOf(strBrokerThreshold.split('/')[0]);
			Integer intBrokerHigherThreshold = Integer.valueOf(strBrokerThreshold.split('/')[1]);
			Integer intNewPlanLowerThreshold = Integer.valueOf(strNewPlanThreshold.split('/')[0]);
			Integer intNewPlanHigherThreshold = Integer.valueOf(strNewPlanThreshold.split('/')[1]);
			Opportunity objLatestOppty = null;
			Boolean blnROEExceptionFound = false;

			// assume aligned rep is not found
			Boolean blnAlignedRepFound = false;
			// type prefix before routing reason
			String strType = (objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID || objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) ? 'Broker' : 'New Plan';
			// Assign HI Owner based on Number of Employees and Role Names

			// assume if hi owner is not active
			Boolean blnHIOwnerActive = false;

			if (objAcc.HI_Owner__c != null && map_Users?.containsKey(objAcc.HI_Owner__c)) {
				User objHIOwner = map_Users.get(objAcc.HI_Owner__c);
				if (String.isNotBlank(objHIOwner?.UserRole?.Name)) {
					if (HI_SALES_ALL_ROLES.containsIgnoreCase(objHIOwner.UserRole.Name)) {
						blnHIOwnerActive = true;
					}
				}
			}

			//Check if there is a benefit oppty created in last 90 days which is closed won. If yes, do not route HI Owner
			if (objAcc != null && !objAcc.Opportunities.isEmpty()) {
				objLatestOppty = objAcc.Opportunities.get(0);
				for (Opportunity objOpp : objAcc.Opportunities) {
					if (OpportunityUtil.set_BenefitRTChangeEmployees.contains(objOpp.RecordTypeId)) {
						if (objOpp.CloseDate != null && objOpp.CloseDate > System.today().addDays(-90) && objOpp.IsWon) {
							return;
						}
						// Check if ROE exeption is Requested or Approved
						if (objOpp.ROE_Exception__c == AccountUtil.ROE_EXCEPTION_REQUESTED || objOpp.ROE_Exception__c == AccountUtil.ROE_EXCEPTION_APPROVED) {
							blnROEExceptionFound = true;
						}
					}
				}
			}

			// Conditions that require skipping routing
			// Overall Status is New and HI owner is Active = Skip Routing
			if (objAcc.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW && blnHIOwnerActive) {
				blnSkipRouting = true;
			} else if ((objLatestOppty != null && objAcc.HI_Active_Benefits__c && objLatestOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) || objAcc.Big_Desk_Pilot_Customer__c) {
				blnSkipRouting = true;
			} else if (blnHIOwnerActive) {
				blnSkipRouting = true;
			} else if (
				(objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
				objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) &&
				String.isNotBlank(objAcc.BillingStateCode) &&
				HI_Oppty_Router_State__mdt.getInstance(objAcc.BillingStateCode) == null
			) {
				// if new plan or bor opportunity - account billing state should be HI supported state
				blnSkipRouting = true;
			}

			if (!blnSkipRouting) {
				if (objAcc.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW) {
					// check if account owner has user account team memebrs
					if (map_UserAccountTeamMembers.containsKey(objAcc.OwnerId)) {
						// Iterate over account team members
						for (UserAccountTeamMember objAccTeamMember : map_UserAccountTeamMembers.get(objAcc.OwnerId)) {
							if (
								strType == AccountUtil.HI_TYPE_BROKER &&
								objAccTeamMember.TeamMemberRole == AccountUtil.HI_BROKER_REP ||
								strType == AccountUtil.HI_TYPE_NEW_PLAN &&
								objAccTeamMember.TeamMemberRole == AccountUtil.HI_NEW_PLAN_REP
							) {
								// update hi routing reason based on current value of HI Owner field
								if (objAcc.HI_Owner__c == null) {
									objAcc.HI_Routing_Reason__c = strType + ' - ' + strRecordType + ' - HI Owner null value updated to aligned ' + objAccTeamMember.TeamMemberRole;
								} else if (objAcc.HI_Owner__c != objAccTeamMember.UserId) {
									objAcc.HI_Routing_Reason__c = strType + ' - ' + strRecordType + ' - HI Owner replaced and updated to aligned ' + objAccTeamMember.TeamMemberRole;
								}
								objAcc.HI_Owner__c = objAccTeamMember.UserId;
								objAcc.Skip_Validation_For_Routing__c = true;
								AccountUtil.blnHIOwnerRouting = true;
								map_AccountsToUpdate.put(objAcc.Id, objAcc);
								blnAlignedRepFound = true;
								break;
							}
						}
					}
					// Send to ringlead if no aligned rep is found
					if (!blnAlignedRepFound) {
						blnSendForRouting = true;
					}
				} else if (objAcc.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_ACTIVE) {
					// If overall status is active - do not check for alignment and send for routing before checking few conditions
					if (
						objAcc.Medical_Deductions__c ||
						objAcc.Benefits_Effective_Date__c != null ||
						HI_Oppty_Router_State__mdt.getInstance(objAcc.BillingStateCode) != null ||
						objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID
					) {
						blnSendForRouting = true;
					}
				}

				if (blnSendForRouting) {
					// If no aligned rep is found, send account to ringlead and update hi routing reason
					if (objAcc.HI_Owner__c == null) {
						objAcc.HI_Routing_Reason__c = strType + ' - ' + strRecordType + ' - HI Owner null value and send to Routing Tool';
					} else {
						objAcc.HI_Routing_Reason__c = strType + ' - ' + strRecordType + ' - HI Owner replaced and send to Routing Tool';
					}
					map_AccountsForRouting.put(objAcc.Id, objAcc);
					map_AccountsToUpdate.put(objAcc.Id, objAcc);
				}
			}
		}
	}

	/* @author      Deepesh Rao
	 * @description query ardius tickets based on opportunity Id
	 * @param      set<Id> set_ArdiusOpportunityIds
	 **/
	public List<Ticket__c> queryArdiusTickets(Set<Id> set_ArdiusOpportunityIds) {
		return [
			SELECT Id, Status__c, Lost_Detail__c, Lost_Detail2__c, Opportunity__c
			FROM Ticket__c
			WHERE Opportunity__c IN :set_ArdiusOpportunityIds AND RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID AND Status__c != :TicketUtil.TICKET_STATUS_CLOSED
		];
	}

	/* @author      Deepesh Rao
	 * @description SIFA-451 - Mark Ardius ticket as Lost, if opportunity is closed Lost
	 * @param       objOpp New Opportunity, objOldOpp Old Opportunity
	 **/
	public void updateArdiusTicketAsClosedLost() {
		for (Ticket__c objTicket : list_TicketsToUpdate) {
			objTicket.Status__c = TicketUtil.TICKET_STATUS_LOST;
			objTicket.Lost_Detail__c = map_ArdiusOpportunities?.get(objTicket.Opportunity__c)?.Stage_Detail__c;
			objTicket.Lost_Detail2__c = map_ArdiusOpportunities?.get(objTicket.Opportunity__c)?.Stage_Detail_2__c;
			map_TicketsToUpdate.put(objTicket.Id, objTicket);
		}
	}

	/* @author      Atul Hinge
	 * @description SIFA-556 - Mark Ardius ticket as New, if  Opportunity status is moved from Closed Lost to Closed Won
	 * @param       objOpp New Opportunity, objOldOpp Old Opportunity
	 **/
	public void updateArdiusTicketAsNew(Set<Id> set_ArdiusOpportunityIds) {
		List<Ticket__c> list_TicketsToReopen = [
			SELECT Id, Status__c, Lost_Detail__c, Lost_Detail2__c, Opportunity__c
			FROM Ticket__c
			WHERE Opportunity__c IN :set_ArdiusOpportunityIds AND RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID AND Status__c = :TicketUtil.TICKET_STATUS_LOST
		];
		for (Ticket__c objTicket : list_TicketsToReopen) {
			objTicket.Status__c = TicketUtil.TICKET_STATUS_NEW;
			objTicket.Lost_Detail__c = '';
			objTicket.Lost_Detail2__c = '';
			map_TicketsToUpdate.put(objTicket.Id, objTicket);
		}
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description BSS-1767 - NP,BOR and BYB Opportunity Updates for Lead Pass fields
	 * @param       objOppty New Opportunity
	 * @param       objOldOppty Old Opportunity
	 **/
	public void updateLeadPassOnHIOpportunity(Opportunity objOppty, Opportunity objOldOppty) {
		// Check if Opportunity is of New Plan, BOR or BYOB record types
		if (
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID ||
			objOppty.RecordTypeId == OpportunityUtil.BENEFITS_BYOB_OPPTY_RT_ID
		) {
			String strUserRoleName = UserUtils.getUserRoleName(UserInfo.getUserId());
			List<String> list_HIRoles = OpportunityUtil.HI_SALES_CS_ROLES.split(',');
			List<String> list_HIStages = OpportunityUtil.HI_LEAD_PASS_STAGES.split(',');
			if (objOldOppty == null && list_HIRoles.contains(strUserRoleName) && objOppty.Sent_to_Gusto_User__c == null) {
				objOppty.Sent_to_Gusto_User__c = UserInfo.getUserId();
				objOppty.HI_Lead_Pass_Role__c = strUserRoleName;
			} else if (
				objOldOppty != null &&
				objOldOppty.StageName != objOppty.StageName &&
				list_HIStages.contains(objOppty.StageName) &&
				objOppty.Sent_to_Gusto_User__c != null &&
				objOppty.HI_Accepted_Lead_Pass__c == null
			) {
				objOppty.HI_Accepted_Lead_Pass__c = System.today();
			}
		}
	}

	/**
	 * @author	Ajay Krishna P U
	 * @description	Ardius Opportunities Referral code are populated from Old company related opportunites
	 * @param objNewOpportunity New version of Opportunity
	 */
	private void updateArdiusOppReferralCode(Opportunity objNewOpportunity) {
		if (
			OpportunityUtil.set_ArdiusExtendedRecordTypeIds.contains(objNewOpportunity.RecordTypeId) &&
			objNewOpportunity.Referral_Code__c == null &&
			objNewOpportunity.AccountId != null &&
			this.map_Accounts.containsKey(objNewOpportunity.AccountId)
		) {
			String strRefferalCode = null;
			String strTaxYear = null;
			for (Opportunity objRelOpportunity : this.map_Accounts.get(objNewOpportunity.AccountId).Opportunities) {
				if (OpportunityUtil.set_ArdiusExtendedRecordTypeIds.contains(objRelOpportunity.RecordTypeId) && objRelOpportunity.Referral_Code__c != null) {
					if (strRefferalCode == null) {
						strRefferalCode = objRelOpportunity.Referral_Code__c;
						strTaxYear = objRelOpportunity.Tax_Year__c;
					} else if (objRelOpportunity.Tax_Year__c != null && (strTaxYear == null || strTaxYear < objRelOpportunity.Tax_Year__c)) {
						strRefferalCode = objRelOpportunity.Referral_Code__c;
						strTaxYear = objRelOpportunity.Tax_Year__c;
					}
				}
			}

			objNewOpportunity.Referral_Code__c = strRefferalCode;
		}
	}

	/**
	 * @description             Validate whether the new Ardius opportunity is duplicate
	 * Expected to be called from Before Insert trigger
	 * Duplicate logic: There should only one Ardius opportunity is allowed for an Account and a tax Year
	 * @param objNewOpportunity New Version of Opportunity
	 */
	private void validateArdiusDuplicateOpportunity(Opportunity objNewOpportunity) {
		if (OpportunityUtil.set_ArdiusExtendedRecordTypeIds.contains(objNewOpportunity.RecordTypeId) && objNewOpportunity.AccountId != null && map_Accounts.containskey(objNewOpportunity.AccountId)) {
			for (Opportunity objAccountRelatedOpportunity : this.map_Accounts.get(objNewOpportunity.AccountId).Opportunities) {
				//If there are any Ardius opportunity with same tax year --> Block Insert operation
				if (OpportunityUtil.set_ArdiusExtendedRecordTypeIds.contains(objAccountRelatedOpportunity.RecordTypeId) && objNewOpportunity.Tax_Year__c == objAccountRelatedOpportunity.Tax_Year__c) {
					objNewOpportunity.addError(String.format(Label.Ardius_Duplicate_Opportunity_Error_Message, new List<String>{ objAccountRelatedOpportunity.Id }));
					break;
				}
			}
		}
	}

	/**
	 * @description: Route ICP opportunity to EOR or Tier upsell owner if open opp is found. If not found - send to RingLead
	 * @param objNewOpportunity New Version of Opportunity
	 */
	public void routeICPOpportunity(Opportunity objNewOpportunity) {
		// check if ICP opportunity is created
		// If CSM user is creating the opportunity, then assign to the CSM user
		if (
			objNewOpportunity.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID &&
			objNewOpportunity.Upsell_Tier__c == OpportunityUtil.INTERNATIONAL_CONTRACTOR_PAYMENT &&
			!OpportunityUtil.CSM_ROLE_IDS.contains(UserInfo.getUserRoleId())
		) {
			Account objAccount = map_Accounts.get(objNewOpportunity.AccountId);
			Id idOwner = null;

			// Iterate over accounts' opportunities.
			// If check if EOR opportunity is found - Assign to the EOR owner
			// If EOR opportunity is not found, then assign to Tier upsell opportunity owner
			for (Opportunity objOppty : objAccount.Opportunities) {
				if (objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && objOppty.Upsell_Tier__c == AccountUtil.EMPLOYER_OF_RECORD && !objOppty.IsClosed) {
					// Assign to open EOR opportunity owner
					idOwner = objOppty.OwnerId;
					break;
				} else if (objOppty.RecordTypeId == OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID && !objOppty.IsClosed) {
					// Assign to tier upsell owner
					idOwner = objOppty.OwnerId;
				}
			}
			// Id is not generated in before insert context - so add opportunity Account Id
			if (idOwner == null) {
				set_TierUpsellAccountIdsToRoute.add(objNewOpportunity.AccountId);
			} else {
				objNewOpportunity.OwnerId = idOwner;
			}
		}
	}

	/**
	 * Validates Growth/Expansion opportunities based on business rules.
	 * @param objOppty The new Opportunity object.
	 * @param objOldOppty The existing Opportunity object before the update (null if new).
	 *
	 */
	public void handleGrowthExpansionValidation(Opportunity objOppty, Opportunity objOldOppty) {
		// On create validation
		if (objOldOppty == null) {
			// Check if account is not suspended and it has closed won acquisition opportunity
			Account objAccount = map_Accounts.get(objOppty.AccountId);
			if (objAccount != null && objOppty.RecordTypeId == OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID) {
				Boolean blnWonAcquistionOppty = false;
				Boolean blnOpenAcqusitionOppty = false;
				Boolean blnOpenUpsellCrossSellOppty = false;
				for (Opportunity objOpptyQuery : objAccount.Opportunities) {
					// Set flags to indicate if account has closed won & open acquisition opportunity and open growth expansion opportunity
					if (objOpptyQuery.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOpptyQuery.IsWon) {
						blnWonAcquistionOppty = true;
					}

					if (objOpptyQuery.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && !objOpptyQuery.IsClosed) {
						blnOpenAcqusitionOppty = true;
					}

					if (objOpptyQuery.RecordTypeId == OpportunityUtil.GROWTH_EXPANSION_OPPTY_RT_ID && !objOpptyQuery.IsClosed && objOpptyQuery.Type == OpportunityUtil.TYPE_UPSELL_CROSS_SELL) {
						blnOpenUpsellCrossSellOppty = true;
					}
				}
				// All error messages for different scenarios - validations related when type = upsell/cross-sell
				if (objOppty.Type == OpportunityUtil.TYPE_UPSELL_CROSS_SELL) {
					if (objAccount.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED) {
						objOppty.addError('Upsell/Cross-sell opportunities cannot be created for suspended accounts.');
						return;
					}

					if (!blnWonAcquistionOppty) {
						objOppty.addError('An upsell/cross-sell opportunity can be created only if the account has a Closed Won Acquisition opportunity.');
						return;
					}

					if (blnOpenUpsellCrossSellOppty) {
						objOppty.addError('A new upsell/cross-sell opportunity cannot be created if an open upsell/cross-sell opportunity already exists." ');
						return;
					}
				} else {
					if (!blnWonAcquistionOppty && !blnOpenAcqusitionOppty) {
						objOppty.addError('Growth/Expansion opportunity can be created only if the account has a Closed Won or Open Acquisition opportunity.');
						return;
					}
				}
			}
		}
	}

	/**
	 * @author      Deepika Saini
	 * @description This method used to Create Team Members
	 * @param       set_RenewalOppIds
	 * 				list_CasesToCreate
	 * 				list_ContactRolesToCreate
	 * @return      NA
	 */
	public void createCaseTeamMembers(Set<Id> set_RenewalOppIds, List<Case> list_CasesToCreate, List<OpportunityContactRole> list_ContactRolesToCreate) {
		Id caseTeamRoleId;
		Map<Id, List<OpportunityContactRole>> map_OppIdsContactRole = new Map<Id, List<OpportunityContactRole>>();
		List<CaseTeamMember> list_CaseTeamMembers = new List<CaseTeamMember>();
		for (OpportunityContactRole objOppContactRole : list_ContactRolesToCreate) {
			if (objOppContactRole.Role == HIBenefitsUtil.BENEFIT_ADMIN || objOppContactRole.Role == HIBenefitsUtil.BENEFIT_SIGNATORY) {
				if (!map_OppIdsContactRole.isEmpty() && map_OppIdsContactRole.containskey(objOppContactRole.OpportunityId)) {
					map_OppIdsContactRole.get(objOppContactRole.OpportunityId).add(objOppContactRole);
				} else {
					map_OppIdsContactRole.put(objOppContactRole.OpportunityId, new List<OpportunityContactRole>{ objOppContactRole });
				}
			}
		}
		Map<String, CaseTeamRole> map_CaseTeamRole = GlobalQueryHelper.getCaseTeamRole();
		for (Case objCase : list_CasesToCreate) {
			if (
				objCase.RecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_CASE_RT_ID &&
				objCase.ContactId != null &&
				set_RenewalOppIds.contains(objCase.Opportunity__c) &&
				map_OppIdsContactRole.containsKey(objCase.Opportunity__c) &&
				map_CaseTeamRole.containsKey(CUSTOMER_CONTACT)
			) {
				for (OpportunityContactRole objOppContactRole : map_OppIdsContactRole.get(objCase.Opportunity__c)) {
					CaseTeamMember objCaseTeam = new CaseTeamMember(MemberId = objOppContactRole.ContactId, ParentId = objCase.Id, TeamRoleId = map_CaseTeamRole.get(CUSTOMER_CONTACT).Id);
					list_CaseTeamMembers.add(objCaseTeam);
				}
			}
		}
		if (!list_CaseTeamMembers.isEmpty()) {
			insert list_CaseTeamMembers;
		}
	}

	/**
	 * @author      Deepika Saini
	 * @description This method used to Query Contact Roles
	 * @param       opportunityIdSet
	 * @return      NA
	 */
	public static Map<Id, Map<String, Set<Id>>> queryOpportunityContactsByRole(Set<Id> opportunityIdSet) {
		Map<Id, Map<String, Set<Id>>> map_contactRolesById = new Map<Id, Map<String, Set<Id>>>();
		for (OpportunityContactRole oppContactRole : [SELECT Id, OpportunityId, ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE OpportunityId IN :opportunityIdSet]) {
			Map<String, Set<Id>> map_ContactRoles = new Map<String, Set<Id>>();
			if (map_contactRolesById.containsKey(oppContactRole.OpportunityId)) {
				map_ContactRoles = map_contactRolesById.get(oppContactRole.OpportunityId);
			}
			Set<Id> set_oppContactId = new Set<Id>();
			if (map_ContactRoles.containsKey(oppContactRole.Role)) {
				set_oppContactId = map_ContactRoles.get(oppContactRole.Role);
			}
			set_oppContactId.add(oppContactRole.ContactId);
			map_ContactRoles.put(oppContactRole.Role, set_oppContactId);
			map_contactRolesById.put(oppContactRole.OpportunityId, map_ContactRoles);
		}

		return map_contactRolesById;
	}

	/**
	 * @author      Jai Aswani
	 * @description BBO-1960 - Update Reference for Marking 'Special Enrollment' as TRUE on Renewal Opportunities
	 * @param       set_AccountIds Set of AccountIDs
	 **/
	private static Map<Id, QA_Sheet__c> fetchRecentQASheet(Set<Id> set_AccountIds) {
		List<QA_Sheet__c> list_recentQASheet = new List<QA_Sheet__c>();
		Map<Id, QA_Sheet__c> map_recentQASheetByAccountId = new Map<Id, QA_Sheet__c>();

		list_recentQASheet = [
			SELECT Id, Special_Enrollment__c, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName
			FROM QA_Sheet__c
			WHERE
				Opportunity__r.RecordTypeId IN :OpportunityUtil.set_NewPlanRenewalBenefitRT
				AND Opportunity__r.AccountId IN :set_AccountIds
				AND Special_Enrollment__c = 'Y'
				AND Opportunity__r.StageName = :OpportunityUtil.CLOSED_WON_STAGE
			ORDER BY Opportunity__r.AccountId, CreatedDate DESC
		];

		for (QA_Sheet__c recordQASheet : list_recentQASheet) {
			if (!map_recentQASheetByAccountId.containsKey(recordQASheet.Opportunity__r.AccountId)) {
				map_recentQASheetByAccountId.put(recordQASheet.Opportunity__r.AccountId, recordQASheet);
			}
		}
		return map_recentQASheetByAccountId;
	}

	/**
	 * @description       Populate Company Info complete Date for Ardius tax credits opportunity
	 *
	 * @param objOppty    New version of Opportunity
	 * @param objOldOppty Old version of Opportunity
	 */
	private void populateCompanyInfoCompleteDT(Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID && (objOldOppty == null || objOppty.Company_Information_Complete__c != objOldOppty.Company_Information_Complete__c)) {
			objOppty.Collecting_Company_Information_Start__c = objOppty.Company_Information_Complete__c ? DateTime.now() : null;
			objOppty.Collecting_Company_Information_End__c = objOppty.Company_Information_Complete__c ? Utils.addBusinessDays(DateTime.now().date(), 4) : null;
			//Reopen opportunity if Company info complete is true
			if (objOppty.Company_Information_Complete__c && objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE) {
				objOppty.StageName = OpportunityUtil.NEW_STAGE;
			}
		}

		//Reopen opportunity if Onboarding complete is true
		if (
			objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID &&
			objOppty.StageName == OpportunityUtil.CLOSED_LOST_STAGE &&
			objOppty.Onboarding_Complete__c &&
			(objOldOppty == null ||
			objOppty.Onboarding_Complete__c != objOldOppty.Onboarding_Complete__c)
		) {
			objOppty.StageName = OpportunityUtil.NEW_STAGE;
		}
	}

	/**
	 * @description       Route current tax credits opportunity to previous tax year opportunity owner
	 * @param objOppty    New version of Opportunity
	 * @param objOldOppty Old version fo the Opportunity
	 */
	private void routeTaxCreditsOpportunity(Opportunity objOppty, Opportunity objOldOppty) {
		if (
			objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID &&
			objOppty.Enable_Ring_Lead_Routing__c &&
			(objOldOppty == null ||
			objOppty.Enable_Ring_Lead_Routing__c != objOldOppty.Enable_Ring_Lead_Routing__c) &&
			objOppty.AccountId != null &&
			objOppty.Tax_Year__c != null
		) {
			Account objAccount = map_Accounts?.get(objOppty.AccountId);

			String strPreviousTaxYear;
			try {
				Integer intTaxYear = Integer.valueOf(objOppty.Tax_Year__c);
				intTaxYear--;
				strPreviousTaxYear = String.valueOf(intTaxYear);
			} catch (Exception objEx) {
				return;
			}

			Id idPreviousTaxYearOpptyOwner;
			for (Opportunity objRelOppty : objAccount?.Opportunities) {
				if (objOppty.Id != objRelOppty.Id && objRelOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID && objRelOppty.Tax_Year__c == strPreviousTaxYear) {
					idPreviousTaxYearOpptyOwner = objRelOppty.Owner.IsActive ? objRelOppty.OwnerId : null;
					break;
				}
			}

			if (idPreviousTaxYearOpptyOwner != null) {
				objOppty.OwnerId = idPreviousTaxYearOpptyOwner;
			}
		}
	}

	/**
	 * @author      Debasmita Rawooth
	 * @description [BSS-2970] Cohort Date field update on reseller account.
	 * @param       objOppty New Opportunity
	 * @param       objOldOppty Old Opportunity
	 **/
	public void updateCohortDateOnResellerAccount(Opportunity objOppty, Opportunity objOldOppty) {
		if(objOppty.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID 
		&& objOldOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE 
		&& objOppty.StageName == OpportunityUtil.CLOSED_WON_STAGE && objOppty.Sold_By__c != null) {
			Account objAcc = map_Accounts.get(objOppty.Sold_By__c);
			if(objAcc.Cohort_Date__c == null && objAcc.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
			   objAcc.Cohort_Date__c = objOppty.Closed_Won_Date__c;
			   map_AccountsToUpdate.put(objAcc.Id, objAcc);
			}
		}
	}

	
	/**
	 * @description       Populate Onboarding Completed Date for Ardius tax credits opportunity
	 * @param objOppty    New version of Opportunity
	 * @param objOldOppty Old version of Opportunity
	 */
	private void populateOnboardingCompleteDT (Opportunity objOppty, Opportunity objOldOppty) {
		if (objOppty.RecordTypeId == OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID && (objOldOppty == null || objOppty.Onboarding_Complete__c != objOldOppty.Onboarding_Complete__c)) {
			objOppty.Onboarding_Completed_Date__c = objOppty.Onboarding_Complete__c ? DateTime.now() : null;
		}
	}
}