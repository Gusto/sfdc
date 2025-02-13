/**
* @name         BenefitOrderHelper
* @author       Aurobind Ravichandran
* @date         06/23/2017
* @description  
* @revisions    Date ------------ Name ------------ Comments
*               30/12/2019      Pravesh         Replace the Method of Creating the Carrier Order with the common method 
                                                to create Co (in CarroerOrderHelperFunction)
                30/12/2019      Deepika         Added the logic to Update the application stage of the BO (BOR record type)
                30/12/2019      Deepika         Restrict the Creation of QA sheet only to new, change and renewal Record Type of BO               
**/
public class BenefitOrderHelper extends TriggerHandler {
	//public static String strRecursiveCheck = '';
	public static boolean skipTaskCreation = false;
	public static boolean medicalCarrierSwitch = false;
	public static boolean anxillaryCarrierSwitch = false;
	public static Integer counter = 0;
	public static boolean skipTrigger = false;
	public static boolean newOrder = false;
	public static boolean statusHistoryProcessed = false;
	public static Map<Id, Account> map_accounts;
	public static Map<Id, Opportunity> map_OpportunityRecords;
	public static Map<String, Id> map_Queue;
	public static Set<Integer> set_Months;
	public static Set<Integer> set_Years;
	public static Map<Id, User> map_userIdRec = new Map<Id, User>();
	//BY:PR, Related: Flex Project, Desc: populated from "NPRU_TicketButtonOnBODetailExt & NPRU_TicketButtonOnCODetailExt"
	public static boolean blnIsInvalidIAReassignmentOnTicketCreation = false;
	public static final Id BO_REC_TYPE_ID_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
	public static final Id BO_REC_TYPE_ID_RENEWAL = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
	public static final Id BO_REC_TYPE_ID_CHANGE = Cache.getRecordTypeId('Benefit_Order__c', 'Change');
	public static final Id BO_REC_TYPE_ID_BOR = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
	public static final Id BO_REC_TYPE_ID_BYB = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB');
	public static final Id BO_REC_TYPE_ID_ALIGNMENT = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal Alignment');
	public static final Id CO_REC_TYPE_ID_BOR = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
	public static final String BENEFIT_BYOB_QUEUE_ID = GlobalQueryHelper.getQueueIdByName('Benefits BYOB');
	public static final Id CASE_REC_TYPE_ID_BYB = CaseUtils.RECTYPE_BYB;
	public static final Id CASE_REC_TYPE_ID_BOR = CaseUtils.RECTYPE_BOR;
	public static final Id CASE_REC_TYPE_ID_RENEWAL = CaseUtils.RECTYPE_RENEWAL;
	public static final Id CASE_REC_TYPE_ID_NEW_PLAN = CaseUtils.RECTYPE_NEW_PLAN;
	public static final Id CASE_REC_TYPE_ID_CHANGE = CaseUtils.RECTYPE_CHANGE;
	public static final String CASE_TYPE_BENEFITS_RENEWAL = 'Benefits Renewal';
	public static final String BO_STATUS_CANCELED = 'Canceled';
	public static final String BO_STATUS_OE_VERIFICATION = 'OE Verification/Checking Participation';
	public static Map<Id, Id> map_RenewalSpecialistOpps = new Map<Id, Id>();
	public static final Map<String, String> map_RecordTypesInfo = Cache.getAllRecordTypeMap('Benefit_Order__c');
	public static List<Case> list_CaseToUpserts = new List<Case>();
	//this variable is use to identify the orders for which the case notification needs to be sent
	public static Set<Id> set_BOIdsCaseNotificationToSend = new Set<Id>();
	public static Map<Id, Set<Id>> map_OppSecondaryContacts = new Map<Id, Set<Id>>();
	public static Map<Id, Opportunity> map_CaseOpportunities = new Map<Id, Opportunity>();
	//Added by lirik 16th July 2019 if opportunity do not have Policy then email should not go.
	public static Map<Id, Integer> map_CountPoliciesOnOpportunity = new Map<Id, Integer>();
	public static Map<Id, Set<String>> map_OppContactRoleEmails = new Map<Id, Set<String>>();
	public static Map<Id, Contact> map_CaseContacts = new Map<Id, Contact>();
	public static String strBouncedEmail = 'The target object email address is currently marked as bounced';
	public static String strBlankEmail = 'The target object\'s email address "null" is not valid';
	public static String strClosedStatus = 'Closed';
	public static String STR_ERROR = 'There are open connect-broker Benefits BYB cases attached to this benefit order. Please merge all connect-broker cases attached to this benefit order into the onboarding case.';
	public static Set<String> set_BYBBOOrderStatus = new Set<String>{
		BenefitOrderUtil.STATUS_FULFILLED,
		BenefitOrderUtil.STATUS_CANCELLED,
		BenefitOrderUtil.STATUS_CLOSED_ADMIN,
		BenefitOrderUtil.STATUS_CLOSED_LOST
	};

	public BenefitOrderHelper() {
		super('BenefitOrderHelper');
	}

	public override void beforeInsert() {
		map_accounts = new Map<id, Account>();
		map_OpportunityRecords = new Map<id, Opportunity>();
		map_Queue = new Map<String, Id>();
		if (skipTrigger == false) {
			counter += 1;

			List<Benefit_Order__c> newBenefitOrders = (List<Benefit_Order__c>) Trigger.new;
			Map<Id, Benefit_Order__c> oldBenefitOrderMap = (Map<Id, Benefit_Order__c>) Trigger.oldMap;
			callOnbeforeInsert(newBenefitOrders, oldBenefitOrderMap);
		}
	}

	//Create seperate method to call from VF page(Assign owner functionality)
	public static List<Benefit_Order__c> callOnbeforeInsert(List<Benefit_Order__c> newBenefitOrders, Map<Id, Benefit_Order__c> oldBenefitOrderMap) {
		List<Benefit_Order__c> lstUpdatedBO = new List<Benefit_Order__c>();
		List<Benefit_Order__c> lstRenewaldBO = new List<Benefit_Order__c>();
		Set<Id> set_OppRenewalId = new Set<Id>();
		map_Queue = new Map<String, Id>();
		//this should be the first method to be called to cached all the required data.
		cacheData(newBenefitOrders);

		List<sobject> updateUserRolesSet = new List<sobject>();

		if (newBenefitOrders == null) {
			return null;
		}

		Map<Id, Benefit_Order__c> acctIdBOMap = new Map<Id, Benefit_Order__c>();
		Set<String> oppRecordType = new Set<String>();
		//Lirik- Migration for BOR to BO -- Start ---
		Set<String> set_BTIds = new Set<String>();
		//Lirik- Migration for BOR to BO -- End ---
		set_Months = new Set<Integer>();
		set_Years = new Set<Integer>();
		for (Benefit_Order__c boRecord : newBenefitOrders) {
			setBigDeskBenOps(boRecord, map_OpportunityRecords);

			if (boRecord.Account__c != null) {
				//Lirik - Migration for BOR to BO -- Start ---
				if (boRecord.RecordTypeId != BO_REC_TYPE_ID_BOR && boRecord.RecordTypeId != BO_REC_TYPE_ID_BYB) {
					lstUpdatedBO.add(boRecord);
					acctIdBOMap.put(boRecord.Account__c, boRecord);

					if (!map_OpportunityRecords.isEmpty() && map_OpportunityRecords.containsKey(boRecord.Opportunity__c)) {
						if (
							String.valueOf(map_OpportunityRecords.get(boRecord.Opportunity__c).OwnerId).startsWith('005') &&
							map_OpportunityRecords.get(boRecord.Opportunity__c).Owner_Role_Name__c == FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST
						) {
							map_RenewalSpecialistOpps.put(boRecord.Opportunity__c, map_OpportunityRecords.get(boRecord.Opportunity__c).OwnerId);
						}
					}
				}

				//Lirik - Migration for BOR to BO -- Start ---
			}

			if (boRecord.RecordTypeId == BO_REC_TYPE_ID_NEW_PLAN) {
				oppRecordType.add('Benefits New Plan');
			} else if (boRecord.RecordTypeId == BO_REC_TYPE_ID_RENEWAL) {
				oppRecordType.add('Benefits Renewal');
				if(boRecord.Opportunity__c != null){
					set_OppRenewalId.add(boRecord.Opportunity__c);
					lstRenewaldBO.add(boRecord);
				}
			} else if (boRecord.RecordTypeId == BO_REC_TYPE_ID_BOR) {
				//Lirik- Migration for BOR to BO -- Start ---
				set_BTIds.add(boRecord.BoR_Id__c);
				/*This is the temperory code which will change in new process, as there was a master child relation between opportunity and
				 bor transfer object so for that we are just mapping the Opportunity owner to benefit order for BOR record type*/
				if (!map_OpportunityRecords.isEmpty() && map_OpportunityRecords.containsKey(boRecord.Opportunity__c))
					boRecord.OwnerId = map_OpportunityRecords.get(boRecord.Opportunity__c).OwnerId;
			} else if (boRecord.RecordTypeId == BO_REC_TYPE_ID_BYB) {
				boRecord.OwnerId = BENEFIT_BYOB_QUEUE_ID;
			}
			//Lirik- Migration for BOR to BO -- End ---
			if (
				boRecord.Order_Status__c == 'Fulfilled' ||
				boRecord.Order_Status__c == 'Denied' ||
				boRecord.Order_Status__c == 'Canceled' ||
				boRecord.Order_Status__c == 'Closed Lost' ||
				boRecord.Order_Status__c == 'Closed Admin'
			)
				boRecord.End_Date__c = System.today();

			boRecord.Push_Rate_Count__c = 0;
			//Added by AKS dated 9th Oct 2020
			//Update original Coverage Effective date which was missing while developement of FW Workforce
			setOrderValuesOnInsert(boRecord);
		}
		//Lirik- Migration for BOR to BO -- Start ---
		if (!set_BTIds.isEmpty()) {
			Map<String, HI_BoR_Transfer__c> mapHIBoRTransfer = new Map<String, HI_BoR_Transfer__c>();
			for (HI_BoR_Transfer__c transferObj : [SELECT Id, Id__c, Status__c FROM HI_BoR_Transfer__c WHERE Id__c IN :set_BTIds]) {
				mapHIBoRTransfer.put(transferObj.Id__c, transferObj);
			}
			if (!mapHIBoRTransfer.isEmpty()) {
				BenefitOrderHelperFunctions.updateBoRApplicationStatus(mapHIBoRTransfer, newBenefitOrders);
			}
		}
		//Lirik- Migration for BOR to BO -- End ---

		//SOQL TO GET QUEUE TO BE ASSIGNED TO BENEFIT ORDER RECORDS (REQUIRED DURING CONVERSION OF WORKFLOW RULES)
		//Restricting the assignment logic to the BOR record type
		if (!lstUpdatedBO.isEmpty()) {
			FWAssignmentUtil controller = new FWAssignmentUtil();
			lstUpdatedBO = controller.processAdvocateAssignmentForBO(lstUpdatedBO, false, map_accounts, oppRecordType, acctIdBOMap, map_RenewalSpecialistOpps);
		}
		if(!lstRenewaldBO.isEmpty() && !set_OppRenewalId.isEmpty()){
			requiresActionAssignment(lstRenewaldBO, set_OppRenewalId);
		}

		return lstUpdatedBO;
	}

	public override void afterInsert() {
		if (skipTrigger == false) {
			List<Benefit_Order__c> newBenefitOrders = (List<Benefit_Order__c>) Trigger.new;
			Map<Id, Benefit_Order__c> oldBenefitOrderMap = (Map<Id, Benefit_Order__c>) Trigger.oldMap;
			Map<Id, Benefit_Order__c> newBenefitOrderMap = (Map<Id, Benefit_Order__c>) Trigger.newMap;
			if (newBenefitOrders == null) {
				return;
			}
			processCases(newBenefitOrders);

			QASheetHelper.createOrUpdateQASheet(newBenefitOrders);

			/*BY:PR, Date: Dec 30,2019, Desc: In order to consolidate "Carrier Order" related code at one place we have moved the related code to 
                                            "CarrierOrderHelperFunctions" class
            */
			CarrierOrderHelperFunctions coCreationUtilInstance = new CarrierOrderHelperFunctions();
			coCreationUtilInstance.createCarrierOrdersAgainstBO(newBenefitOrders, oldBenefitOrderMap, map_OpportunityRecords);
			trackBenefitOrderStatusChanges(null, newBenefitOrders);
			processCaseEmailFunctionality(newBenefitOrders);
		}
	}

	public override void beforeUpdate() {
		map_accounts = new Map<id, Account>();
		map_OpportunityRecords = new Map<id, Opportunity>();
		map_Queue = new Map<String, Id>();
		if (skipTrigger == false) {
			counter += 1;
			List<Benefit_Order__c> newBenefitOrders = (List<Benefit_Order__c>) Trigger.new;
			Map<Id, Benefit_Order__c> oldBenefitOrderMap = (Map<Id, Benefit_Order__c>) Trigger.oldMap;
			//this should be the first method to be called to cached all the required data.
			cacheData(newBenefitOrders);

			if (newBenefitOrders == null) {
				return;
			}
			checkOpenConnectBroker(newBenefitOrders, oldBenefitOrderMap);
			checkOpenTicketLinkedToBO(newBenefitOrders, oldBenefitOrderMap, (Map<Id, Benefit_Order__c>) Trigger.newMap);
			//Lirik - Not in USE - Migration for BOR to BO -- End ---
			updateFieldsBOOnBeforeUpdate(newBenefitOrders, oldBenefitOrderMap, map_OpportunityRecords);
			updateAcctCoverageEffDateAndWaitingPeriod(newBenefitOrders, oldBenefitOrderMap);
			updateEffectivedateChanged(newBenefitOrders, oldBenefitOrderMap); // Deepak Tyagi, Dec 27, 2018 Desc: Updating the IsCoverageEffectiveDateChanged checkbox

			//@Neha 6th April 2020, Desc: Map to hold Previous Status Mapping for BO
			Map<String, String> map_OrderStatusMapping = new Map<String, String>{
				'With Sales' => 'Qualification',
				'With Advising' => 'Qualification',
				'Ready for Qualification' => 'Qualification',
				'Ready for OE Prep' => 'Pre-Submission',
				'OE Prep' => 'Pre-Submission',
				'OE' => 'Pre-Submission',
				'OE Extended' => 'Pre-Submission',
				'OE Verification/Checking Participation' => 'Pre-Submission',
				'Ready for Submission Prep' => 'Pre-Submission',
				'Submission Prep' => 'Pre-Submission',
				'Ready for Confirmation' => 'Post-Submission',
				'Pending Confirmation' => 'Post-Submission',
				'Pending Carrier Approval' => 'Post-Submission',
				'Approved' => 'Post-Submission'
			};

			for (Benefit_Order__c boRecord : newBenefitOrders) {
				setBigDeskBenOps(boRecord, map_OpportunityRecords);

				if (
					oldBenefitOrderMap.containsKey(boRecord.id) &&
					boRecord.Coverage_Effective_Date__c != null &&
					boRecord.Coverage_Effective_Date__c != oldBenefitOrderMap.get(boRecord.id).Coverage_Effective_Date__c
				) {
					if (boRecord.Push_Rate_Count__c == null) {
						boRecord.Push_Rate_Count__c = 1;
					} else {
						boRecord.Push_Rate_Count__c = 1 + boRecord.Push_Rate_Count__c;
					}
				}
				//@Neha 6th April 2020, Set previous order status based on Previous Status
				String strPrevStatus = oldBenefitOrderMap.get(boRecord.id).Order_Status__c;
				if (boRecord.Order_Status__c != null && boRecord.Order_Status__c != strPrevStatus && strPrevStatus != null && map_OrderStatusMapping.containsKey(strPrevStatus)) {
					boRecord.Previous_Order_Status__c = map_OrderStatusMapping.get(strPrevStatus);
				}
			}
			benefitOrderOpportunityIsChanged(oldBenefitOrderMap, newBenefitOrders);
			trackBenefitOrderStatusChanges(oldBenefitOrderMap, newBenefitOrders);
			UtilitiesFactory.setHistoryTracking((List<SObject>) newBenefitOrders, (Map<Id, SObject>) oldBenefitOrderMap, 'Benefit_Order');
		}
		btAdvocateAssignment((List<Benefit_Order__c>) Trigger.new, (Map<Id, Benefit_Order__c>) Trigger.oldMap);

		if (TicketTriggerHelper.blnUpdateBOStatusAsFulfilled) {
			Map<Id, Benefit_Order__c> map_NewBOs = (Map<Id, Benefit_Order__c>) Trigger.newMap;
			TicketTriggerHelper.setBOStatusAsFulfilled(map_NewBOs);
			TicketTriggerHelper.blnUpdateBOStatusAsFulfilled = false;
		}
	}

	public override void afterUpdate() {
		if (skipTrigger == false) {
			List<Benefit_Order__c> newBenefitOrders = (List<Benefit_Order__c>) Trigger.new;
			Map<Id, Benefit_Order__c> oldBenefitOrderMap = (Map<Id, Benefit_Order__c>) Trigger.oldMap;
			Map<Id, Benefit_Order__c> newBenefitOrderMap = (Map<Id, Benefit_Order__c>) Trigger.newMap;
			if (newBenefitOrders == null) {
				return;
			}
			updateOpportnitylost(oldBenefitOrderMap, newBenefitOrderMap);
			updateCarrierOrder(newBenefitOrderMap, oldBenefitOrderMap);
			updateCaseStatus(oldBenefitOrderMap, newBenefitOrderMap);
			updateEnrollmentDatesonCarrierOrder(oldBenefitOrderMap, newBenefitOrderMap);
			changeTicketOwnership((List<Benefit_Order__c>) Trigger.new, (Map<Id, Benefit_Order__c>) Trigger.oldMap);
		}
		//we are updating the case owner whether the skip trigger is true or false in case of BO owner change
		changeCaseOwnership((List<Benefit_Order__c>) Trigger.new, (Map<Id, Benefit_Order__c>) Trigger.oldMap);
		updateBoRCaseOwner((List<Benefit_Order__c>) Trigger.new, (Map<Id, Benefit_Order__c>) Trigger.oldMap);
	}

	/**BY:PR, Date: Feb/4/19, Desc:  */
	private static void btAdvocateAssignment(List<Benefit_Order__c> newBenefitOrders, Map<Id, Benefit_Order__c> oldBenefitOrderMap) {
		if (newBenefitOrders != null && newBenefitOrders.size() > 0) {
			list<Benefit_Order__c> list_toAssignOwnerEligibleBO = new List<Benefit_Order__c>();
			for (Benefit_Order__c objBO : newBenefitOrders) {
				if (objBO.RecordTypeId != BO_REC_TYPE_ID_BOR) {
					continue;
				}
				Benefit_Order__c objOldBO = oldBenefitOrderMap.get(objBO.Id);

				if (objOldBO.Type__c == null && objBO.Type__c != null) {
					list_toAssignOwnerEligibleBO.add(objBO);
				}
			}

			if (list_toAssignOwnerEligibleBO.size() > 0) {
				BTAssignmentUtil controller = new BTAssignmentUtil();
				// SJay - 08/11/2020 - Added boolean parameter to function call
				controller.processBOForAdvocateAssignment(list_toAssignOwnerEligibleBO, false);
			}
		}
	}

	//method caches all the data required for processing
	//Opportunity, Account
	private static void cacheData(List<Benefit_Order__c> benefitOrderList) {
		Set<Id> accountIdSet = new Set<Id>();
		Set<Id> opportunityIdSet = new Set<Id>();
		//By :Prashant :14-04-2020 :https://app.asana.com/0/1165890935117693/1171118283817959
		if (benefitOrderList != null) {
			for (Benefit_Order__c order : benefitOrderList) {
				if (order.Account__c != null)
					accountIdSet.add(order.Account__c);

				if (order.Opportunity__c != null)
					opportunityIdSet.add(order.Opportunity__c);
			}
		}

		if (accountIdSet.size() > 0)
			map_accounts = BenefitOrderHelperFunctions.getAccountsByAccountId(accountIdSet);

		if (opportunityIdSet.size() > 0)
			map_OpportunityRecords = BenefitOrderHelperFunctions.getOppsByOppId(opportunityIdSet);
		Set<String> queueNames = new Set<String>{ 'Renewal Benefits Operations', 'New Plan Benefits Operations', 'Change Benefit Operations' };
		map_Queue = GlobalQueryHelper.getNameQueueMap(queueNames);
	}

	//updates case status - validated
	public static void updateCaseStatus(Map<Id, Benefit_Order__c> map_BenefitOrderOld, Map<Id, Benefit_Order__c> map_BenefitOrderNew) {
		List<Case> list_Cases = new List<Case>();
		List<Case> list_CasesToUpdate = new List<Case>();
		List<Account> list_AccountsToUpdate = new List<Account>();
		Set<Id> set_OrderIds = new Set<Id>();
		Set<String> set_BOOrderStatus = new Set<String>{
			BenefitOrderUtil.STATUS_FULFILLED,
			BenefitOrderUtil.STATUS_CANCELLED,
			BenefitOrderUtil.STATUS_CLOSED_ADMIN,
			BenefitOrderUtil.STATUS_CLOSED_LOST,
			BenefitOrderUtil.STATUS_DENIED,
			BenefitOrderUtil.STATUS_ALIGNEMENT_DENIED,
			BenefitOrderUtil.STATUS_ALIGNEMENT_APPROVED_POST_RENEWAL,
			BenefitOrderUtil.STATUS_ALIGNEMENT_APPROVED
		};

		Boolean blnUpdateCase;
		Boolean blnUpdateAccount;
		Set<Id> set_FulfilledBOIds = new Set<Id>();
		Set<Id> set_ClosedLostBOIds = new Set<Id>(), set_ReopenedBOIds = new Set<Id>();
		Set<String> set_OpenCaseStatuses = new Set<String>{ CaseUtils.STATUS_OPEN, CaseUtils.STATUS_NEW };

		Set<String> set_ClosedBOStatuses = new Set<String>{ BenefitOrderUtil.STATUS_FULFILLED, BenefitOrderUtil.STATUS_CLOSED_ADMIN, BenefitOrderUtil.STATUS_CANCELLED, BenefitOrderUtil.STATUS_CLOSED_LOST };

		Configuration_Settings__c objConfig = Utils.ORG_WIDE_CONFIG_SETTINGS;
		Integer intNoOfBusinessHoursToClose = Integer.valueOf(objConfig.Business_Hours_to_Close_Customer_Case__c != null ? objConfig.Business_Hours_to_Close_Customer_Case__c : 0);
		DateTime dtCloseDateTime = Utils.addOrSubtractBusinessHoursToDate(System.now(), intNoOfBusinessHoursToClose);
		Set<Id> set_UniqueAccountIds = new Set<Id>();
		if (map_BenefitOrderNew != null) {
			for (Benefit_Order__c objBO : map_BenefitOrderNew.values()) {
				Benefit_Order__c objOldBO = map_BenefitOrderOld.get(objBO.Id);

				if (objBO.Order_Status__c != objOldBO.Order_Status__c) {
					set_OrderIds.add(objBO.Id);
					if (set_BYBBOOrderStatus.contains(objBO.Order_Status__c)) {
						set_FulfilledBOIds.add(objBO.Id);
					}

					blnUpdateAccount = false;
					if (objBO.Account__c != null) {
						Account objAccount = new Account(Id = objBO.Account__c);

						if (objBO.Order_Status__c == BenefitOrderUtil.STATUS_FULFILLED) {
							blnUpdateAccount = true;
							objAccount.Benefits_Customer__c = true;
						} else if (objBO.Order_Status__c != BenefitOrderUtil.STATUS_FULFILLED && objOldBO.Order_Status__c == BenefitOrderUtil.STATUS_FULFILLED) {
							blnUpdateAccount = true;
							objAccount.Benefits_Customer__c = false;
						}

						if (blnUpdateAccount = true && !set_UniqueAccountIds.contains(objAccount.Id)) {
							set_UniqueAccountIds.add(objAccount.Id);
							list_AccountsToUpdate.add(objAccount);
						}
					}

					/*
					 * Author	: Neha
					 * Date		: 02/26/2021
					 * Desc		: Set or Reset Onboarding Close Date on Case based on Benefit Order Status and Opportunity Stage
					 */
					if (
						objBO.Order_Status__c != objOldBO.Order_Status__c &&
						(objBO.RecordTypeId == BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID ||
						objBO.RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID ||
						objBO.RecordTypeId == BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID ||
						objBO.RecordTypeId == BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID ||
						objBO.RecordTypeId == BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID)
					) {
						if (set_ClosedBOStatuses.contains(objBO.Order_Status__c) && !set_ClosedBOStatuses.contains(objOldBO.Order_Status__c)) {
							set_ClosedLostBOIds.add(objBO.Id);
						} else if (set_ClosedBOStatuses.contains(objOldBO.Order_Status__c) && !set_ClosedBOStatuses.contains(objBO.Order_Status__c)) {
							set_ReopenedBOIds.add(objBO.Id);
						}
					}
				}
			}
		}

		if (!set_OrderIds.isEmpty()) {
			for (Case objCase : [
				SELECT
					Id,
					Status,
					Send_Survey__c,
					Type,
					ContactId,
					Benefit_Order__r.Order_Status__c,
					IsClosed,
					Onboarding_Close_DateTime__c,
					Integration_Id__c,
					Benefit_Order__r.RecordTypeId,
                	Benefit_Order__r.End_Date__c,
					Benefit_Order__c,
					Opportunity__c,
					Opportunity__r.RecordType.DeveloperName,
					Opportunity__r.IsClosed,
					Carrier_Order__c,
					RecordTypeId
				FROM Case
				WHERE Benefit_Order__c != NULL AND Benefit_Order__c IN :set_OrderIds
			]) {
				blnUpdateCase = false;
				if (objCase.Integration_Id__c != null && objCase.Integration_Id__c.contains('hippo')) {
					String strDeveloperName = objCase.Opportunity__r.RecordType.DeveloperName;
					if (strDeveloperName.equalsIgnoreCase('Benefits_BYOB')) {
						strDeveloperName = 'Benefits_BYB';
					}
					String strValidIntegrationId = 'hippo-' + strDeveloperName + '-' + objCase.Opportunity__c;
					if (objCase.Integration_Id__c.equalsIgnoreCase(strValidIntegrationId)) {
						if (set_ReopenedBOIds.contains(objCase.Benefit_Order__c)) {
							objCase.Onboarding_Close_DateTime__c = null;
							blnUpdateCase = true;
						} else if (set_ClosedLostBOIds.contains(objCase.Benefit_Order__c) && (objCase.Opportunity__c == null || objCase.Opportunity__r.IsClosed == true)) {
							objCase.Onboarding_Close_DateTime__c = dtCloseDateTime;
							blnUpdateCase = true;
						}
					}
					if (objCase.IsClosed == false && set_BOOrderStatus.contains(objCase.Benefit_Order__r.Order_Status__c)) {
						blnUpdateCase = true;
						// Send Survey is not set as true of carrier order case
						if (
							objCase.Benefit_Order__r.Order_Status__c == BenefitOrderUtil.STATUS_FULFILLED &&
							objCase.Type != CaseUtils.TYPE_BENEFITS_RENEWAL_ALLIGNMENT &&
							objCase.Type != CaseUtils.TYPE_CARRIER_SUBMISSION &&
							objCase.Type != CaseUtils.TYPE_BENEFITS_BOR_CARRIER &&
							objCase.ContactId != null
						) {
							objCase.Send_Survey__c = true;
						}

						if (
							objCase.Benefit_Order__r.RecordTypeId != BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID &&
							objCase.Benefit_Order__r.RecordTypeId != BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID &&
							objCase.Benefit_Order__r.RecordTypeId != BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID &&
							objCase.Benefit_Order__r.RecordTypeId != BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID &&
							objCase.Benefit_Order__r.RecordTypeId != BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID
						) {
							objCase.Status = CaseUtils.STATUS_CLOSED;
						}
						if (objCase.Benefit_Order__r.RecordTypeId  == BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID) {
							Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
							if(objConfigSettings.Send_BYB_Survey_After__c != null && objCase.Benefit_Order__r.End_Date__c != null && objCase.ContactId != null){
								Integer intDay = objCase.Benefit_Order__r.End_Date__c.day();
								Integer intMonth = objCase.Benefit_Order__r.End_Date__c.month();
								Integer intYear = objCase.Benefit_Order__r.End_Date__c.year();
								Datetime dtmOnboardingCloseDateTime = DateTime.newInstance(intYear, intMonth, intDay);
								dtmOnboardingCloseDateTime = dtmOnboardingCloseDateTime.addDays(Integer.valueOf(objConfigSettings.Send_BYB_Survey_After__c));
								objCase.Onboarding_Close_DateTime__c = dtmOnboardingCloseDateTime;
							}else{
								objCase.Send_Survey__c = false;
							}
						}

					} else if (objCase.IsClosed == true && !set_BOOrderStatus.contains(objCase.Benefit_Order__r.Order_Status__c)) {
						blnUpdateCase = true;
						objCase.Status = CaseUtils.STATUS_OPEN;
					}
				} else {
					if (objCase.Status != CaseUtils.STATUS_CLOSED && set_FulfilledBOIds.contains(objCase.Benefit_Order__c) && objCase.Benefit_Order__r.RecordTypeId == BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID) {
						blnUpdateCase = true;
						objCase.Status = CaseUtils.STATUS_CLOSED;
					}
				}

				if (blnUpdateCase) {
					list_CasesToUpdate.add(objCase);
				}
			}

			if (list_CasesToUpdate.size() > 0) {
				Boolean blnCaseTriggerFlag = CaseTriggerHelper.SkipTrigger;
				CaseTriggerHelper.SkipTrigger = true;
				update list_CasesToUpdate;
				CaseTriggerHelper.SkipTrigger = blnCaseTriggerFlag;
			}
		}

		if (!list_AccountsToUpdate.isEmpty()) {
			Boolean blnAccountTriggerFlag = AccountTriggerHelper.SkipTrigger;
			AccountTriggerHelper.SkipTrigger = true;
			update list_AccountsToUpdate;
			AccountTriggerHelper.SkipTrigger = blnAccountTriggerFlag;
		}
	}

	// Updates opportunity status - validated
	public static void updateOpportnitylost(Map<Id, Benefit_Order__c> map_OldBenefitOrder, Map<Id, Benefit_Order__c> map_NewBenefitOrder) {
		List<Opportunity> list_Opps = new List<Opportunity>();
		Map<Id, Benefit_Order__c> map_OpportunityWithBOs = new Map<Id, Benefit_Order__c>();
		Set<Id> set_OppIds = new Set<Id>();
		Set<Id> set_UpdateClosedOpps = new Set<Id>();

		if (map_NewBenefitOrder != null) {
			for (Benefit_Order__c objBO : map_NewBenefitOrder.values()) {
				Benefit_Order__c objOldBO = map_OldBenefitOrder.get(objBO.Id);

				if (objBO.Opportunity__c != null) {
					if (
						objBO.Order_Status__c != null &&
						objBO.Order_Status__c != objOldBO.Order_Status__c &&
						(!BenefitOrderUtil.set_ClosedOrderStatusForBOAndAlignementBO.isEmpty() && BenefitOrderUtil.set_ClosedOrderStatusForBOAndAlignementBO.contains(objBO.Order_Status__c))
					) {
						set_OppIds.add(objBO.Opportunity__c);
						map_OpportunityWithBOs.put(objBO.Opportunity__c, objBO);
					}

					if (
						objBO.Order_Status__c != objOldBO.Order_Status__c &&
						(!BenefitOrderUtil.set_ClosedOrderStatusForBO.isEmpty() &&
						(BenefitOrderUtil.set_ClosedOrderStatusForBO.contains(objOldBO.Order_Status__c) && !BenefitOrderUtil.set_ClosedOrderStatusForBO.contains(objBO.Order_Status__c))) &&
						(objBO.RecordTypeId == BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID ||
						objBO.RecordTypeId == BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID)
					) {
						set_UpdateClosedOpps.add(objBO.Opportunity__c);
						map_OpportunityWithBOs.put(objBO.Opportunity__c, objBO);
					}
				}
			}
		}

		list_Opps = new List<Opportunity>();

		if (set_OppIds.size() > 0) {
			for (Id idOpp : set_OppIds) {
				if (map_OpportunityWithBOs.containskey(idOpp)) {
					Opportunity objOppty = map_OpportunityRecords.get(idOpp);
					Benefit_Order__c objBO = map_OpportunityWithBOs.get(idOpp);
					Date dtFourMonthDate = objOppty.CloseDate.toStartofMonth().addMonths(4);

					if (objBO.RecordTypeId == BenefitOrderUtil.RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID) {
						if (
							objBO.Order_Status__c == BenefitOrderUtil.STATUS_ALIGNEMENT_APPROVED ||
							objBO.Order_Status__c == BenefitOrderUtil.STATUS_ALIGNEMENT_DENIED ||
							objBO.Order_Status__c == BenefitOrderUtil.STATUS_ALIGNEMENT_APPROVED_POST_RENEWAL
						) {
							if (objOppty.StageName == OpportunityUtil.ALIGNMENT_SALES_STAGE) {
								objOppty.StageName = OpportunityUtil.ALIGNMENT_COMPLETE_STAGE;
							} else if (objOppty.StageName == OpportunityUtil.ALIGNMENT_IN_PROGESS_PC_STAGE) {
								objOppty.StageName = OpportunityUtil.OPP_READY_FOR_DEFAULT_STAGE;
							}
						}
					} else {
						String strOppSourceId = 'Id__c => ' + objOppty.Id__c + ',Source_ID__c =>' + objOppty.Source_ID__c;

						if (objBO.Order_Status__c == BenefitOrderUtil.STATUS_CANCELLED && System.today() <= dtFourMonthDate) {
							objOppty.StageName = OpportunityUtil.ORDER_LOST_STAGE;
							objOppty.Order_Lost_Date__c = System.now();

							if (String.isBlank(objOppty.Stage_Detail__c)) {
								objOppty.Stage_Detail__c = objBO.Status_Detail__c;
							}

							objOppty.Source_ID__c = null;
							objOppty.Id__c = null;

							if (objOppty.Id_And_Source_Id__c == null) {
								objOppty.Id_And_Source_Id__c = strOppSourceId;
							}
						} else if (objBO.Order_Status__c == BenefitOrderUtil.STATUS_CLOSED_ADMIN && System.today() <= dtFourMonthDate) {
							objOppty.StageName = OpportunityUtil.CLOSED_ADMIN_STAGE;

							if (String.isBlank(objOppty.Stage_Detail__c)) {
								objOppty.Stage_Detail__c = objBO.Status_Detail__c;
							}

							objOppty.Source_ID__c = null;
							objOppty.Id__c = null;

							if (objOppty.Id_And_Source_Id__c == null) {
								objOppty.Id_And_Source_Id__c = strOppSourceId;
							}
						}
					}

					list_Opps.add(objOppty);
				}
			}
		}

		//Update the Opportunity as close won if bo again active from canceled
		if (!set_UpdateClosedOpps.isEmpty()) {
			for (Id objOppId : set_UpdateClosedOpps) {
				if (map_OpportunityWithBOs.containsKey(objOppId)) {
					Opportunity objOppty = map_OpportunityRecords.get(objOppId);
					Benefit_Order__c objBO = map_OpportunityWithBOs.get(objOppId);
					Date dtFourMonthDate = objOppty.CloseDate.toStartofMonth().addMonths(4);

					if (set_UpdateClosedOpps.contains(objOppty.Id) && System.today() <= dtFourMonthDate) {
						objOppty.StageName = OpportunityUtil.CLOSED_WON_STAGE;
						objOppty.Order_Lost_Date__c = null;

						if (objOppty.Id_And_Source_Id__c != null) {
							Map<String, String> map_OppsIdAndSourceId = new Map<String, String>();
							map_OppsIdAndSourceId = UtilitiesFactory.readStringAsMap(objOppty.Id_And_Source_Id__c);

							if (!map_OppsIdAndSourceId.isEmpty()) {
								if (map_OppsIdAndSourceId.containsKey(OpportunityUtil.FIELD_SOURCE_ID))
									objOppty.Source_ID__c = map_OppsIdAndSourceId.get(OpportunityUtil.FIELD_SOURCE_ID);

								if (map_OppsIdAndSourceId.containsKey(OpportunityUtil.FIELD_ID))
									objOppty.Id__c = map_OppsIdAndSourceId.get(OpportunityUtil.FIELD_ID);
							}
						}

						list_Opps.add(objOppty);
					}
				}
			}
		}

		if (list_Opps != null && list_Opps.size() > 0) {
			update list_Opps;
		}
	}

	/* validated
	BY : Deepak Tyagi
	Date : Dec 24 2018
	JIRA :
	Description : Updating the IsCoverageEffectiveDateChanged checkbox when "Coverage Effective Date" or "Push Rate Reason" fields get updated
	*/
	private static void updateEffectivedateChanged(List<Benefit_Order__c> newBenefitOrders, Map<id, Benefit_Order__c> oldOrderMap) {
		if (newBenefitOrders != null) {
			for (Benefit_Order__c order : newBenefitOrders) {
				Benefit_Order__c oldOrder = oldOrderMap.get(order.id);
				if (
					order.Coverage_Effective_Date__c != oldOrder.Coverage_Effective_Date__c &&
					oldOrder.Coverage_Effective_Date__c != null &&
					(order.RecordTypeId == BO_REC_TYPE_ID_NEW_PLAN ||
					order.RecordTypeId == BO_REC_TYPE_ID_RENEWAL) &&
					String.isBlank(order.Push_Rate_Reason__c) &&
					order.IsCoverageEffectiveDateChanged__c == false
				) {
					order.IsCoverageEffectiveDateChanged__c = true;
				} else if (
					(order.RecordTypeId == BO_REC_TYPE_ID_NEW_PLAN ||
					order.RecordTypeId == BO_REC_TYPE_ID_RENEWAL) &&
					String.isNotBlank(order.Push_Rate_Reason__c) &&
					String.isBlank(oldOrder.Push_Rate_Reason__c) &&
					order.IsCoverageEffectiveDateChanged__c == true
				) {
					order.IsCoverageEffectiveDateChanged__c = false;
				}
			}
		}
	}

	/* validated
    BY : PR
    Date : May 31 2017
    Ticket : Complexity Score
    Description : Updating the related Carrier Order in case "Order Status" or "Coverage Effective Date" fields get updated
    */
	public static void updateCarrierOrder(Map<id, Benefit_Order__c> newOrderMap, Map<id, Benefit_Order__c> oldBOMap) {
		if (newOrderMap == null || newOrderMap.size() == 0) {
			return;
		}
		/**
        Updated By:- Deepika Saini
        Reason:- Implementation Stage should not be chnaged in Carrier Order if stage is 
        'Ready for Submission Prep','Submission Prep','Ready for Confirmation','Pending Confirmation','Pending Item',
        'Approved','Canceled','Ready for Qualification','Qualification','Closed Admin'
         */
		Set<String> set_ImplementationStageNotChanged = new Set<String>{
			'Ready for Submission Prep',
			'Submission Prep',
			'Ready for Confirmation',
			'Pending Confirmation',
			'Pending Item',
			'Approved',
			'Canceled',
			'Closed Admin',
			CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION,
			CarrierOrderUtil.IMPLEMENTATION_STAGE_EARLY_SUBMISSION
		};
		Set<string> benefitOrderIdSet = new Set<string>();
		Map<Id, Benefit_Order__c> BOMap = new Map<Id, Benefit_Order__c>();
		Map<Id, Carrier_Order__c> map_CarrierOrder = new Map<Id, Carrier_Order__c>();
		Set<Id> set_BOIdsEffectiveDateChange = new Set<Id>();
		Set<Id> set_BOIdsQualificationDateChange = new Set<Id>();
		Set<Id> set_BOIdsQualificationStatus = new Set<Id>();
		Map<Id, Benefit_Order__c> map_TadaBOIdAndRecordWithOwnerChange = new Map<Id, Benefit_Order__c>();

		for (Benefit_Order__c newBO : newOrderMap.values()) {
			Benefit_Order__c oldBORec;

			if (oldBOMap != null && oldBOMap.keyset().size() > 0 && oldBOMap.containsKey(newBO.Id)) {
				oldBORec = oldBOMap.get(newBO.Id);
			}
			//Logic for BOR only
			if (newBO.RecordTypeId == BO_REC_TYPE_ID_BOR) {
				//In BO (BOR type), When Qualifier click on Qualify Order
				if (oldBORec != null && oldBORec.Qualification_Follow_Up_Date__c == null && oldBORec.Qualification_Follow_Up_Date__c != newBO.Qualification_Follow_Up_Date__c) {
					benefitOrderIdSet.add(newBO.Id);
					set_BOIdsQualificationDateChange.add(newBO.Id);
				}
				//In BO (BOR type), When Qualifier click on Accept Order
				if (
					oldBORec != null &&
					oldBORec.UW_Owner__c == null &&
					oldBORec.UW_Owner__c != newBO.UW_Owner__c &&
					oldBORec.Order_Status__c != newBO.Order_Status__c &&
					newBO.Order_Status__c == 'Qualification'
				) {
					benefitOrderIdSet.add(newBO.Id);
					set_BOIdsQualificationStatus.add(newBO.Id);
				}
				//By:PR, Date: April/5/2020, Desc: Storing TAdA BO records for which later we will update Tada CO record's Owner
				if (oldBORec != null && oldBORec.OwnerId != newBO.OwnerId && newBO.Type__c != null && newBO.Type__c.indexOf('TAdA') > -1) {
					map_TadaBOIdAndRecordWithOwnerChange.put(newBO.Id, newBO);
					benefitOrderIdSet.add(newBO.Id);
				}
			}

			if (oldBORec != null && oldBORec.Coverage_Effective_Date__c != newBO.Coverage_Effective_Date__c) {
				benefitOrderIdSet.add(newBO.Id);
				set_BOIdsEffectiveDateChange.add(newBO.Id);
			}

			if (oldBORec != null && oldBORec.Order_Status__c != newBO.Order_Status__c) {
				benefitOrderIdSet.add(newBO.Id);
			}

			if (
				oldBORec != null &&
				oldBORec.Order_Status__c != newBO.Order_Status__c &&
				(newBO.Order_Status__c == 'Denied' ||
				newBO.Order_Status__c == 'Canceled' ||
				newBO.Order_Status__c == 'Closed Admin' ||
				newBO.Order_Status__c == 'Closed Lost' ||
				newBO.Order_Status__c == 'OE' ||
				newBO.Order_Status__c == 'OE Prep' ||
				newBO.Order_Status__c == 'OE Extended' ||
				newBO.Order_Status__c == 'OE Verification/Checking Participation')
			) {
				benefitOrderIdSet.add(newBO.Id);
			}
		}

		if (benefitOrderIdSet.size() > 0) {
			Map<Id, Carrier_Order__c> map_CarrierOrderToUpdate = new Map<Id, Carrier_Order__c>();
			Map<Id, Carrier_Order__c> map_COIdsForFac1Assignment = new Map<Id, Carrier_Order__c>();
			Map<Id, Carrier_Order__c> map_TADACOIdsForStatusChange = new Map<Id, Carrier_Order__c>();
			Set<String> set_ToExcludeOrderStatus = new Set<String>{ 'Canceled', 'Approved', 'Closed Admin', 'Blocked' };

			map_CarrierOrder = BenefitOrderHelperFunctions.getCarrierOrderMap(newOrderMap.keySet());

			Set<String> set_QueueName = new Set<String>{ 'Carrier Implementation Queue' };
			Map<String, Id> map_Queue = GlobalQueryHelper.getNameQueueMap(set_QueueName);

			if (!map_CarrierOrder.isEmpty()) {
				for (Carrier_Order__c co : map_CarrierOrder.values()) {
					//logic for new Renewal and change only
					if (benefitOrderIdSet.contains(co.Benefit_Order__c)) {
						if (
							newOrderMap.containsKey(co.Benefit_Order__c) &&
							(newOrderMap.get(co.Benefit_Order__c).Order_Status__c == 'Denied' ||
							newOrderMap.get(co.Benefit_Order__c).Order_Status__c == BO_STATUS_CANCELED ||
							newOrderMap.get(co.Benefit_Order__c).Order_Status__c == 'Closed Admin' ||
							newOrderMap.get(co.Benefit_Order__c).Order_Status__c == 'Closed Lost' ||
							((newOrderMap.get(co.Benefit_Order__c).Order_Status__c == 'OE' ||
							newOrderMap.get(co.Benefit_Order__c).Order_Status__c == 'OE Prep' ||
							newOrderMap.get(co.Benefit_Order__c).Order_Status__c == 'OE Extended' ||
							newOrderMap.get(co.Benefit_Order__c).Order_Status__c == BO_STATUS_OE_VERIFICATION)))
						) {
							co.Additional_Details__c = newOrderMap.get(co.Benefit_Order__c).Additional_Details__c;
							string strPreviousCOStageName = co.Implementation_Stage__c;
							//Carrier Order implementation stage should not be changed if that stage is present in set
							if (!set_ImplementationStageNotChanged.contains(co.Implementation_Stage__c)) {
								co.Implementation_Stage__c = newOrderMap.get(co.Benefit_Order__c).Order_Status__c;
							} else if (
								newOrderMap.get(co.Benefit_Order__c).Order_Status__c == BO_STATUS_CANCELED &&
								(newOrderMap.get(co.Benefit_Order__c).RecordTypeId == BO_REC_TYPE_ID_NEW_PLAN ||
								newOrderMap.get(co.Benefit_Order__c).RecordTypeId == BO_REC_TYPE_ID_RENEWAL ||
								newOrderMap.get(co.Benefit_Order__c).RecordTypeId == BO_REC_TYPE_ID_CHANGE)
							) {
								//For https://app.asana.com/0/1199605183564487/1199605183564496/f
								co.Implementation_Stage__c = BO_STATUS_CANCELED;
							}
							//If CO get cancelled by Mass update Stage from CO level then no need to set back to Stage detail from BO Satatus detail
							//Changes by DS dated 13th May 2020
							if (strPreviousCOStageName != BO_STATUS_CANCELED) {
								co.Stage_Detail__c = newOrderMap.get(co.Benefit_Order__c).Status_Detail__c;
							}
						}
						if (set_BOIdsEffectiveDateChange.contains(co.Benefit_Order__c)) {
							co.Effective_Date_Changed_on__c = System.now();

							if (newOrderMap.containsKey(co.Benefit_Order__c) && co.Submitted_Completed_Datetime__c != null) {
								co.Effective_Date_Change__c = true;
							}
						}

						if (co.Benefit_Order__r.RecordTypeId == BO_REC_TYPE_ID_BOR) {
							if (
								set_BOIdsQualificationDateChange.contains(co.Benefit_Order__c) &&
								co.RecordTypeId == CO_REC_TYPE_ID_BOR &&
								!set_ToExcludeOrderStatus.contains(co.Implementation_Stage__c)
							) {
								if ((co.Carrier__r.Partner_Type__c == '' || co.Carrier__r.Partner_Type__c != CarrierOrderUtil.PARTNER_TYPE_TADA) && co.OwnerId == map_Queue.get(CarrierOrderUtil.CARRIER_IMPLEMENTATION_QUEUE)) {
									map_COIdsForFac1Assignment.put(co.Id, co);
								} else {
									map_TADACOIdsForStatusChange.put(co.Id, co);
								}
							}
							if (set_BOIdsQualificationStatus.contains(co.Benefit_Order__c) && co.RecordTypeId == CO_REC_TYPE_ID_BOR) {
								co.Implementation_Stage__c = 'Qualification';
							}
							//BY:PR, Date: April/5/2020, Desc: Updating Tada CO owner with BO Owner[advocate]
							if (map_TadaBOIdAndRecordWithOwnerChange.containsKey(co.Benefit_Order__c) && co.Carrier__r.Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA) {
								co.OwnerId = map_TadaBOIdAndRecordWithOwnerChange.get(co.Benefit_Order__c).OwnerId;
								String preFix = String.valueOf(co.OwnerId).left(3).toLowercase();
								if ((co.Initial_Owner__c == null || HICarrierInformationTriggerHelper.isBOInsert) && preFix == '005') {
									co.Initial_Owner__c = co.OwnerId;
								}
							}
						}
						map_CarrierOrderToUpdate.put(co.Id, co);
					}
				}

				//Facilitator 1 Assignment for BOR Benefit Order
				if (!map_COIdsForFac1Assignment.isEmpty()) {
					BTAssignmentUtil objBTFacilitatorAssignement = new BTAssignmentUtil();
					List<Carrier_Order__c> lst_COWithFAC1Owner = objBTFacilitatorAssignement.processCOForFacilitator1Assignment(
						map_COIdsForFac1Assignment.values(),
						map_TADACOIdsForStatusChange.values()
					);

					if (!lst_COWithFAC1Owner.isEmpty()) {
						for (Carrier_Order__c objCarrierOrder : lst_COWithFAC1Owner) {
							if (!map_CarrierOrderToUpdate.isEmpty() && map_CarrierOrderToUpdate.containsKey(objCarrierOrder.Id)) {
								Carrier_Order__c objTempCarrierOrder = map_CarrierOrderToUpdate.get(objCarrierOrder.Id);
								if (objTempCarrierOrder.Carrier__r.Partner_Type__c  == '' || objTempCarrierOrder.Carrier__r.Partner_Type__c != CarrierOrderUtil.PARTNER_TYPE_TADA) {
									objTempCarrierOrder.OwnerId = objCarrierOrder.OwnerId;
									objTempCarrierOrder.Initial_Owner__c = objCarrierOrder.Initial_Owner__c;
									//[DS]24-03-2020 Carrier Order Start Date for Benefits BOR
									objTempCarrierOrder.Start_Date__c = objCarrierOrder.Start_Date__c;
									objTempCarrierOrder.OOO_Timestamp__c = objCarrierOrder.OOO_Timestamp__c;
								}
								objTempCarrierOrder.Implementation_Stage__c = objCarrierOrder.Implementation_Stage__c;
								map_CarrierOrderToUpdate.put(objCarrierOrder.Id, objTempCarrierOrder);
							} else {
								map_CarrierOrderToUpdate.put(objCarrierOrder.Id, objCarrierOrder);
							}
						}
					}
				}
			}

			if (map_CarrierOrderToUpdate.size() > 0) {
				if (counter > 1) {
					CarrierOrderTriggerHelper.skipTrigger = true;
				}

				Map<String, String> errorOppMap = Utils.doDMLAndReturnAllErrors(
					'Update', // type of DML operation
					'Benefit_Order__c', // Return map key
					map_CarrierOrderToUpdate.values(), // sObject list
					false, // all or none flag
					true, // log the error
					'BenefitOrderTriggerHelper-UpdateCarrierOrder'
				);

				for (Benefit_Order__c boOrder : newOrderMap.values()) {
					if (errorOppMap.containsKey(boOrder.id)) {
						boOrder.addError(errorOppMap.get(boOrder.id));
					}
				}
			}
		}
	}

	/* important to be validated*/
	public static void changeCaseOwnership(list<Benefit_Order__c> newBenefitOrderList, Map<id, Benefit_Order__c> oldBOMap) {
		Map<Id, Benefit_Order__c> benefitOrderMap = new Map<Id, Benefit_Order__c>();

		Set<Id> set_BOOwnerId = new Set<Id>();
		if (newBenefitOrderList == null) {
			return;
		}
		for (Benefit_Order__c order : newBenefitOrderList) {
			Benefit_Order__c old = oldBOMap.get(order.id);
			String ownerId = order.OwnerId;
			if (order.OwnerId != old.OwnerId && ownerId.indexOf('00G') < 0) {
				//get onwer id of the Benefits BoR
				if (String.valueOf(order.OwnerId).startsWith('005') && order.RecordTypeId == BO_REC_TYPE_ID_BOR) {
					set_BOOwnerId.add(order.OwnerId);
				}
				benefitOrderMap.put(order.id, order);
			}
		}

		if (benefitOrderMap.keyset().size() > 0) {
			//Lirik - Migrate BOR to BO --Start--
			List<Case> caseList = [
				SELECT Id, OwnerId, Status, Opportunity__c, Benefit_Order__c, recordtypeId, Order_Owner_Name__c, Order_Owner_Calendly_Link__c, Order_Owner_Phone__c, Isclosed, Carrier_Order__c
				FROM Case
				WHERE
					Benefit_Order__c != NULL
					AND Carrier_Order__c = NULL
					AND Benefit_Order__c IN :benefitOrderMap.keySet()
					AND recordType.Name IN ('Benefits New Plan Case', 'Benefits Renewal Case', 'Benefits Change Case', 'Benefits BoR')
			];
			//Lirik - Migrate BOR to BO --End--

			for (Case cse : caseList) {
				if (benefitOrderMap.containsKey(cse.Benefit_Order__c)) {
					//this is ticket reassignment then update all Case except related to "Benefit BOR"
					if (blnIsInvalidIAReassignmentOnTicketCreation) {
						if (cse.RecordTypeId != CASE_REC_TYPE_ID_BOR)
							cse.OwnerId = benefitOrderMap.get(cse.Benefit_Order__c).OwnerId;
					} else if (!cse.Isclosed) {
						//if not from ticket reassignment then update only open cases
						cse.OwnerId = benefitOrderMap.get(cse.Benefit_Order__c).OwnerId;
					}
				}

				if (cse.RecordTypeId == CASE_REC_TYPE_ID_BOR && !cse.Isclosed) {
					User objUser = map_userIdRec.get(cse.OwnerId);
					if (objUser != null && objUser.Id != null) {
						cse.Order_Owner_Name__c = objUser.FirstName;
						cse.Order_Owner_Calendly_Link__c = objUser.Calendar_Link__c;
						String str_unformattedPhone = objUser.Phone;
						if (String.isNotBlank(str_unformattedPhone)) {
							str_unformattedPhone = str_unformattedPhone.replace('(', '').replace(')', '').replace('-', '').replace(' ', '');
							cse.Order_Owner_Phone__c = str_unformattedPhone.subString(0, 3) + '-' + str_unformattedPhone.subString(3, 6) + '-' + str_unformattedPhone.subString(6, 10);
						}
					}
				}
			}
			if (caseList.size() > 0) {
				boolean caseTriggerFlag = CaseTriggerHelper.skipTrigger;
				CaseTriggerHelper.skipTrigger = true;
				update caseList;
				CaseTriggerHelper.skipTrigger = caseTriggerFlag;
			}
		}
	}

	// creates cases when benefit orders are created when there is no parent benefit order and the order type is not benefit change
	// In the case of renewal case already exists and the existing case is updated
	// For all case types an email notification is sent
	public static void processCases(List<Benefit_Order__c> newBenefitOrderList) {
		//Database.DMLOptions dmo = new Database.DMLOptions();
		//dmo.assignmentRuleHeader.useDefaultRule= true;
		Set<Id> oppIdSet = new Set<Id>();
		Set<Id> boIdSet = new Set<Id>();
		if (newBenefitOrderList == null || newBenefitOrderList.size() == 0) {
			return;
		}

		//@DS for BT Signature Case
		Set<Id> set_BOOwnerId = new Set<Id>();

		//boolean isChildBenefitOrder = false;
		for (Benefit_Order__c bo : newBenefitOrderList) {
			if (bo.opportunity__c != null) {
				oppIdSet.add(bo.opportunity__c);
			}

			if (bo.Parent_Benefit_Order__c == null && bo.RecordTypeId != BO_REC_TYPE_ID_CHANGE) {
				set_BOIdsCaseNotificationToSend.add(bo.id);
			}

			//get onwer id of the Benefits BoR
			if (String.valueOf(bo.OwnerId).startsWith('005') && bo.RecordTypeId == BO_REC_TYPE_ID_BOR) {
				set_BOOwnerId.add(bo.OwnerId);
			}

			boIdSet.add(bo.Id);
		}
		Map<Id, Benefit_Order__c> newBenefitOrderMap = new Map<Id, Benefit_Order__c>(newBenefitOrderList);
		Map<Id, Benefit_Order__c> boRelatedOppMap = new Map<Id, Benefit_Order__c>();
		Map<Id, Transition_to_Fulfillment__c> ttfOppMap = new Map<Id, Transition_to_Fulfillment__c>();
		Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
		for (Opportunity opp : [
			SELECT
				Id,
				OwnerId,
				owner.Email,
				owner.name,
				owner.firstname,
				owner.lastname,
				Big_Desk_BenOps__c,
				Maestro__c,
				Owner_Role_Name__c,
				(SELECT Id, Owner.Email, owner.firstname, Carrier_Order__c, RecordTypeId FROM Cases__r),
				(
					SELECT Id, Opportunity__c, Contact__r.Owner.Email, Contact__c, Contact__r.Email, Broker_Point_of_Contact__r.Name, Broker_Point_of_Contact__r.Email
					FROM NP_Complexity_Scorings__r
					WHERE RecordTypeId IN (
						:TransitiontoFulfilmentUtil.strTTFBenChangeRecTypeId,
						:TransitiontoFulfilmentUtil.strTTFBenNewPlanRecTypeId,
						:TransitiontoFulfilmentUtil.strBenRenewalRecTypeId,
						:TransitiontoFulfilmentUtil.strBenBorRecTypeId
					)
				),
				(SELECT Id, Opportunity__c, Opportunity__r.OwnerId, owner.firstname FROM Benefit_Orders__r WHERE Id IN :boIdSet),
				(SELECT Id FROM Policies__r WHERE Is_Selected__c = TRUE)
			FROM Opportunity
			WHERE Id IN :oppIdSet
		]) {
			for (Benefit_Order__c boRecs : opp.Benefit_Orders__r) {
				boRelatedOppMap.put(boRecs.Id, boRecs);
			}

			for (Transition_to_Fulfillment__c ttfRecs : opp.NP_Complexity_Scorings__r) {
				ttfOppMap.put(ttfRecs.Opportunity__c, ttfRecs);
				map_CaseContacts.put(ttfRecs.Contact__c, ttfRecs.Contact__r);
			}
			map_CaseOpportunities.put(opp.Id, opp);
			map_CountPoliciesOnOpportunity.put(opp.Id, opp.Policies__r.size());
		}

		Map<Id, Case> opportunityCaseMap = new Map<Id, Case>();
		for (Case c : [
			SELECT Id, Status, Opportunity__c, Benefit_Order__c, Carrier_Order__c, RecordTypeId, OwnerId, Origin
			FROM Case
			WHERE
				Opportunity__c IN :oppIdSet
				AND Opportunity__c != NULL
				AND Type != 'Benefits Renewal alignment'
				AND recordType.Name IN ('Benefits New Plan Case', 'Benefits Renewal Case', 'Benefits Change Case')
				AND IsClosed = FALSE
				AND Origin = 'Hippo'
		]) {
			opportunityCaseMap.put(c.Opportunity__c, c);
		}

		List<OpportunityContactRole> lst_OppContactRole = [
			SELECT Id, OpportunityId, ContactId, Role, IsPrimary, Check_Additional_POC__c, Contact.Email
			FROM OpportunityContactRole
			WHERE OpportunityId IN :oppIdSet
		];
		Map<Id, Id> map_OppContatid = new Map<Id, Id>();
		for (OpportunityContactRole objOppCRole : lst_OppContactRole) {
			//In case off Second BOR We will always get only one opp contact role on opportunity
			map_OppContatid.put(objOppCRole.OpportunityId, objOppCRole.ContactId);
			if (objOppCRole.Check_Additional_POC__c == true) {
				Set<Id> setContactIds = new Set<Id>();
				//Get contacts for which Additional POC is checked
				if (!map_OppSecondaryContacts.isEmpty() && map_OppSecondaryContacts.containsKey(objOppCRole.OpportunityId)) {
					setContactIds = map_OppSecondaryContacts.get(objOppCRole.OpportunityId);
				}
				setContactIds.add(objOppCRole.ContactId);
				map_OppSecondaryContacts.put(objOppCRole.OpportunityId, setContactIds);

				//Create Map of Opp and ContactRole Email
				Set<String> set_Emails = new Set<String>();
				if (map_OppContactRoleEmails.containsKey(objOppCRole.OpportunityId)) {
					if (objOppCRole.Contact.Email != null) {
						set_Emails = map_OppContactRoleEmails.get(objOppCRole.OpportunityId);
					}
				}

				set_Emails.add(objOppCRole.Contact.Email);
				map_OppContactRoleEmails.put(objOppCRole.OpportunityId, set_Emails);
			}
		}

		Set<Case> caseSetUpdate = new Set<Case>();
		List<Case> caseListInsert = new List<Case>();
		for (Benefit_Order__c bo : newBenefitOrderList) {
			if (bo.opportunity__c != null) {
				Id primaryContactId = null;
				if (ttfOppMap.containsKey(bo.opportunity__c)) {
					primaryContactId = ttfOppMap.get(bo.opportunity__c).contact__c;
				}
				if (string.isBlank(primaryContactId) && map_OppContatid.size() > 0) {
					primaryContactId = map_OppContatid.get(bo.opportunity__c);
				}
				if (opportunityCaseMap.containsKey(bo.opportunity__c)) {
					Case c = opportunityCaseMap.get(bo.opportunity__c);
					c.Benefit_Order__c = bo.Id;

					if (primaryContactId != null) {
						c.ContactId = primaryContactId;
					}
					if (bo.RecordTypeId == BO_REC_TYPE_ID_NEW_PLAN || bo.RecordTypeId == BO_REC_TYPE_ID_RENEWAL || bo.RecordTypeId == BO_REC_TYPE_ID_CHANGE) {
						//***
						c.ownerId = bo.ownerId; //Assign BO Owner as the case of the Case Owner
						c.Origin = 'Hippo';
						if (ttfOppMap != null && ttfOppMap.keySet() != null && ttfOppMap.ContainsKey(c.Opportunity__c)) {
							c.ContactId = ttfOppMap.get(c.Opportunity__c).Contact__c;
						}
					}
					caseSetUpdate.add(c);
				} else {
					Case cse = new Case();
					cse.AccountId = bo.Account__c;
					cse.ContactId = primaryContactId;
					cse.Origin = 'Hippo';

					if (bo.RecordTypeId == BO_REC_TYPE_ID_RENEWAL) {
						cse.RecordTypeId = CASE_REC_TYPE_ID_RENEWAL;
						cse.Subject = 'Gusto benefits renewal';
						cse.Description = 'Gusto benefits renewal';
						// SJay - 08/19/2020 - Added Integration Id to make customer cases unique and easy to identify.
						cse.Integration_Id__c = 'hippo-Benefits_Renewal-' + bo.Opportunity__c;
						if (boRelatedOppMap.containsKey(bo.Id)) {
							cse.ownerId = boRelatedOppMap.get(bo.Id).Opportunity__r.OwnerId;
						}
					} else if (bo.RecordTypeId == BO_REC_TYPE_ID_NEW_PLAN) {
						cse.ownerId = bo.ownerId; //Assign BO Owner as the case of the Case Owner
						cse.RecordTypeId = CASE_REC_TYPE_ID_NEW_PLAN;
						cse.Subject = 'Gusto New Plan benefits';
						cse.Description = 'Gusto New Plan benefits';
						// SJay - 08/19/2020 - Added Integration Id to make customer cases unique and easy to identify.
						cse.Integration_Id__c = 'hippo-Benefits_New_Plan-' + bo.Opportunity__c;
					} else if (bo.RecordTypeId == BO_REC_TYPE_ID_CHANGE) {
						cse.RecordTypeId = CASE_REC_TYPE_ID_CHANGE;
						cse.Subject = 'Gusto benefits change';
						cse.Description = 'Gusto benefits change';
						cse.ownerId = bo.ownerId; //Assign BO Owner as the case of the Case Owner
						// Neha - 08/21/2020 - Added Integration Id to make customer cases unique and easy to identify.
						cse.Integration_Id__c = 'hippo-Benefits_Change-' + bo.Opportunity__c;
						if (boRelatedOppMap.containsKey(bo.Id)) {
							cse.ownerId = boRelatedOppMap.get(bo.Id).Opportunity__r.OwnerId;
						}
					} else if (bo.RecordTypeId == BO_REC_TYPE_ID_ALIGNMENT) {
						cse.RecordTypeId = CASE_REC_TYPE_ID_RENEWAL;
						cse.Subject = 'Gusto Benefits Renewal Alignment ';
						cse.Description = 'Gusto Benefits Renewal Alignment ';
						cse.Type = 'Benefits Renewal alignment';
						cse.OwnerId = bo.OwnerId;
						cse.Status = 'new';
						cse.Priority = 'Medium';
					} else if (bo.RecordTypeId == BO_REC_TYPE_ID_BYB) {
						cse.RecordTypeId = CASE_REC_TYPE_ID_BYB;
						cse.Subject = 'Broker Integration - Next steps';
						cse.Description = 'Broker Integration - next steps';
						cse.Type = 'BYOB';
						cse.OwnerId = bo.OwnerId;
						cse.Status = 'new';
						cse.Priority = 'Medium';
						cse.Origin = null;
						cse.Integration_Id__c = BenefitOrderUtil.BO_CASE_INTEGRATION_ID_BYB + bo.Opportunity__c;
						if (ttfOppMap.containsKey(bo.opportunity__c)) {
							cse.Broker_POC_Name__c = ttfOppMap.get(bo.opportunity__c).Broker_Point_of_Contact__r.Name;
							cse.Broker_POC_Email__c = ttfOppMap.get(bo.opportunity__c).Broker_Point_of_Contact__r.Email;
						}
					} else if (bo.RecordTypeId == BO_REC_TYPE_ID_BOR) {
						//Lirik- Migration for BOR to BO -- Start ---
						cse.RecordTypeId = CASE_REC_TYPE_ID_BOR;
						cse.Subject = 'Welcome to Benefits with Gusto!';
						cse.Description = 'Welcome to Benefits with Gusto!';
						cse.Type = 'BOR';
						cse.Status = 'new';
						cse.Priority = 'Medium';
						cse.OwnerId = bo.OwnerId;
						// Added Integration Id to make customer cases unique and easy to identify.
						cse.Integration_Id__c = 'hippo-Benefits_BoR-' + bo.Opportunity__c;
						User objUser = map_userIdRec.get(bo.OwnerId);
						if (objUser != null && objUser.Id != null) {
							cse.Order_Owner_Name__c = objUser.FirstName;
							cse.Order_Owner_Calendly_Link__c = objUser.Calendar_Link__c;
							String str_unformattedPhone = objUser.Phone;
							if (String.isNotBlank(str_unformattedPhone)) {
								str_unformattedPhone = str_unformattedPhone.replace('(', '').replace(')', '').replace('-', '').replace(' ', '');
								cse.Order_Owner_Phone__c = str_unformattedPhone.subString(0, 3) + '-' + str_unformattedPhone.subString(3, 6) + '-' + str_unformattedPhone.subString(6, 10);
							}
						}
						//cse.setOptions(dmo);
					}
					cse.Benefit_Order__c = bo.Id;
					cse.Opportunity__c = bo.Opportunity__c;
					caseListInsert.add(cse);
				}
			}
		}

		if (caseSetUpdate.size() > 0) {
			list_CaseToUpserts.addAll(caseSetUpdate);
		}

		if (caseListInsert.size() > 0) {
			list_CaseToUpserts.addAll(caseListInsert);
		}
	}

	public static void processCaseEmailFunctionality(List<Benefit_Order__c> list_NewBenefitOrders) {
		if (!list_CaseToUpserts.isEmpty()) {
			List<Case> list_CasesEmailNotification = new List<Case>();
			Map<Id, Set<Id>> map_BORCustomerCaseWithSecContacts = new Map<Id, Set<Id>>();
			Boolean blnCaseSkipTrigger = CaseTriggerHelper.skipTrigger;
			CaseTriggerHelper.skipTrigger = true;

			if (!CarrierOrderTriggerHelper.blnCaseCreatedFromCO) {
				try {
					upsert list_CaseToUpserts;
				} catch (Exception objEx) {
					ExceptionLogUtil.logException('BenefitOrderHelper', 'processCaseEmailFunctionality', objEx.getMessage(), objEx.getStackTraceString(), '. line number: ' + objEx.getLineNumber());
				}
			}

			for (Case objCase : list_CaseToUpserts) {
				if (set_BOIdsCaseNotificationToSend.contains(objCase.benefit_order__c) && objCase.Carrier_Order__c == null) {
					list_CasesEmailNotification.add(objCase);
				}
				if (
                    (objCase.RecordTypeId == CASE_REC_TYPE_ID_BOR ||
                     objCase.RecordTypeId == CASE_REC_TYPE_ID_RENEWAL ||
                     objCase.RecordTypeId == CASE_REC_TYPE_ID_NEW_PLAN ||
                     objCase.RecordTypeId == CASE_REC_TYPE_ID_CHANGE) &&
					!map_OppSecondaryContacts.isEmpty() &&
					map_OppSecondaryContacts.containsKey(objCase.Opportunity__c) &&
					!map_OppSecondaryContacts.get(objCase.Opportunity__c).isEmpty()
				) {
					map_BORCustomerCaseWithSecContacts.put(objCase.Id, map_OppSecondaryContacts.get(objCase.Opportunity__c));
				}
			}

			if (!map_BORCustomerCaseWithSecContacts.isEmpty()) {
				createCaseTeamMember(map_BORCustomerCaseWithSecContacts);
			}

			if (list_CasesEmailNotification.size() > 0) {
				String strErrorIfExist = sendEmailOnCaseCreation(list_CasesEmailNotification, map_CaseOpportunities, map_CaseContacts, map_CountPoliciesOnOpportunity, map_OppContactRoleEmails);
			}

			CaseTriggerHelper.skipTrigger = blnCaseSkipTrigger;
		}
	}

	/*
	 * @Description : Get existing CaseTeamMember
	 * @Parm        : set_CaseIds[case ids]
	 * @Return      : Map of case ids with se of MemberIds
	 */
	public static Map<Id, Set<Id>> fetchCaseTeamMember(Set<Id> set_CaseIds) {
		Map<Id, Set<Id>> map_CaseIdCaseTeamMembers = new Map<Id, Set<Id>>();
		for (CaseTeamMember objMember : [SELECT Id, MemberId, ParentId FROM CaseTeamMember WHERE ParentId = :set_CaseIds]) {
			Set<Id> list_MemberIds = new Set<Id>();
			if (map_CaseIdCaseTeamMembers.containsKey(objMember.ParentId)) {
				list_MemberIds = (map_CaseIdCaseTeamMembers.get(objMember.ParentId));
			}

			list_MemberIds.add(objMember.MemberId);
			map_CaseIdCaseTeamMembers.put(objMember.ParentId, list_MemberIds);
		}

		return map_CaseIdCaseTeamMembers;
	}

	private static void createCaseTeamMember(Map<Id, Set<Id>> map_BORCustomerCaseWithSecContact) {
		Map<Id, Set<Id>> map_CaseIdCaseTeamMembers = fetchCaseTeamMember(map_BORCustomerCaseWithSecContact.keySet());
		Set<Id> set_MemberIds = new Set<Id>();
		//Fetch case team role
		List<CaseTeamRole> lstCaseTeamRole = Database.query('SELECT Id FROM CaseTeamRole WHERE Name = \'Customer Contact\'');
		Id idCaseTRole;
		if (null != lstCaseTeamRole && lstCaseTeamRole.size() > 0)
			idCaseTRole = lstCaseTeamRole[0].Id;
		List<CaseTeamMember> lstCaseTeamMembersToInsert = new List<CaseTeamMember>();
		//Create case team members for each contact
		for (Id idObjCase : map_BORCustomerCaseWithSecContact.keySet()) {
			set_MemberIds = new Set<Id>();
			if (map_CaseIdCaseTeamMembers.containsKey(idObjCase)) {
				set_MemberIds = map_CaseIdCaseTeamMembers.get(idObjCase);
			}

			for (Id idContact : map_BORCustomerCaseWithSecContact.get(idObjCase)) {
				if (!set_MemberIds.contains(idContact)) {
					lstCaseTeamMembersToInsert.add(new CaseTeamMember(ParentId = idObjCase, TeamRoleId = idCaseTRole, MemberId = idContact));
				}
			}
		}
		Database.Insert(lstCaseTeamMembersToInsert);
	}

	/* validated
BY : Akash
Date : Feb 5 2019
Ticket : Enhancement
Description : Converted Process Builder - 'Open Enrollment Dates/ Sync from Benefit Order to Carrier Order' into Trigger

*/
	//PB --[Benefit Order] Helper
	public static void updateAcctCoverageEffDateAndWaitingPeriod(List<Benefit_Order__c> newOrderList, Map<id, Benefit_Order__c> oldOrderMap) {
		if (oldOrderMap != null) {
			Map<Id, Opportunity> boOppMap = new Map<Id, Opportunity>();
			Map<Id, Id> boIdOppIDSet = new Map<Id, Id>();
			for (Benefit_Order__c boRec : newOrderList) {
				if (oldOrderMap.get(boRec.Id).Opportunity__c != boRec.Opportunity__c) {
					boIdOppIDSet.put(boRec.Opportunity__c, boRec.Id);
				}
			}

			for (Opportunity opp : map_OpportunityRecords.values()) {
				boOppMap.put(boIdOppIDSet.get(opp.Id), opp);
			}

			for (Benefit_Order__c boRecord : newOrderList) {
				if (boOppMap.containsKey(boRecord.Id)) {
					boRecord.Account__c = boOppMap.get(boRecord.Id).AccountId;
					if (boRecord.Coverage_Effective_Date__c == null) {
						boRecord.Coverage_Effective_Date__c = boOppMap.get(boRecord.Id).HI_Effective_Date__c;
					}
				}
				if ((oldOrderMap.get(boRecord.Id).Account__c != boRecord.Account__c) || (oldOrderMap.get(boRecord.Id).RecordTypeId != boRecord.RecordTypeId)) {
					String c = '-' + boRecord.RecordType.Name;
					string strAccName = boOppMap.containskey(boRecord.Id) ? boOppMap.get(boRecord.Id).Account.Name : '';
					if (strAccName != null && c != null && (strAccName.length() + c.length()) > 80) {
						boRecord.Name = strAccName.subString(0, (strAccName.length() - c.length())) + '-' + boRecord.RecordType.Name;
					} else {
						boRecord.Name = strAccName + c;
					}
				}
			}
		}
	}

	//validated
	//PB Name --Open Enrollment Dates/ Sync from Benefit Order to Carrier Order -- Populating Open_Enrollment_Start_Date__c,Open_Enrollment_End_Date__c
	//PB Name --Coverage Effective Date/ Set Benefit Order Policies -- Updating coverage effective date on policy
	public static void updateEnrollmentDatesonCarrierOrder(Map<id, Benefit_Order__c> oldOrderMap, Map<id, Benefit_Order__c> newOrderMap) {
		//By:Prashant:14-04-2020 :added Null Check https://app.asana.com/0/1165890935117693/1171118283817959
		if (newOrderMap != null && !newOrderMap.isEmpty()) {
			Map<Id, Benefit_Order__c> benfitOrderDateChangeMap = new Map<Id, Benefit_Order__c>();
			list<Carrier_Order__c> updatedCarrierOrders = new List<Carrier_Order__c>();

			// for effective Date on policy
			Map<Id, Benefit_Order__c> boEffectiveDateMap = new Map<Id, Benefit_Order__c>();
			List<Policy__c> updatePolicyList = new List<Policy__c>();

			for (Benefit_Order__c bo : newOrderMap.values()) {
				if (bo.Open_Enrollment_Start_Date__c != null && bo.Open_Enrollment_Start_Date__c != oldOrderMap.get(bo.Id).Open_Enrollment_Start_Date__c) {
					benfitOrderDateChangeMap.put(bo.id, bo);
				}

				if (bo.Open_Enrollment_End_Date__c != null && bo.Open_Enrollment_End_Date__c != oldOrderMap.get(bo.Id).Open_Enrollment_End_Date__c) {
					benfitOrderDateChangeMap.put(bo.id, bo);
				}

				// for Effective date set on opp policies
				if (bo.Opportunity__c != null && bo.Coverage_Effective_Date__c != null && oldOrderMap.get(bo.Id).Coverage_Effective_Date__c != bo.Coverage_Effective_Date__c) {
					boEffectiveDateMap.put(bo.Opportunity__c, bo);
				}
			}
			if (!benfitOrderDateChangeMap.isEmpty() || !boEffectiveDateMap.isEmpty()) {
				Map<Id, Carrier_Order__c> map_CarrierOrder = BenefitOrderHelperFunctions.getCarrierOrderMap(newOrderMap.keySet());

				for (Carrier_Order__c carrierOrderRec : map_CarrierOrder.values()) {
					if (benfitOrderDateChangeMap.containsKey(carrierOrderRec.Benefit_Order__c)) {
						carrierOrderRec.Open_Enrollment_Start_Date__c = newOrderMap.get(carrierOrderRec.Benefit_Order__c).Open_Enrollment_Start_Date__c;
						carrierOrderRec.Open_Enrollment_End_Date__c = newOrderMap.get(carrierOrderRec.Benefit_Order__c).Open_Enrollment_End_Date__c;
						updatedCarrierOrders.add(carrierOrderRec);
					}
				}
				if (updatedCarrierOrders.Size() > 0) {
					boolean carrierOrderFlag = CarrierOrderTriggerHelper.skipTrigger;
					CarrierOrderTriggerHelper.skipTrigger = true;
					update updatedCarrierOrders;
					CarrierOrderTriggerHelper.skipTrigger = carrierOrderFlag;
				}
				// update effective date on policies
				if (boEffectiveDateMap.size() > 0) {
					for (Policy__c policyRecord : [SELECT Opportunity__c, Coverage_Effective_Date__c FROM Policy__c WHERE Opportunity__c IN :boEffectiveDateMap.Keyset() AND Is_Selected__c = TRUE]) {
						if (boEffectiveDateMap.containsKey(policyRecord.Opportunity__c)) {
							policyRecord.Coverage_Effective_Date__c = boEffectiveDateMap.get(policyRecord.Opportunity__c).Coverage_Effective_Date__c;
							updatePolicyList.add(policyRecord);
						}
					}
					if (updatePolicyList.size() > 0) {
						boolean policyHelperFlag = PolicyHelper.skipTrigger;
						PolicyHelper.skipTrigger = true;
						update updatePolicyList;
						PolicyHelper.skipTrigger = policyHelperFlag;
					}
				}
			}
		}
	}

	/*
	BY : Anurag Gautam
	Date : 10/03/2022
	Ticket : Bug
	Description : Converted Process Builder - '[Benefit Order] Helper' into Trigger

	*/
	public static void benefitOrderOpportunityIsChanged(Map<id, Benefit_Order__c> oldOrderMap, List<Benefit_Order__c> newOrderList) {
		if (newOrderList == null) {
			return;
		}

		if (oldOrderMap != null) {
			for (Benefit_Order__c boRecord : newOrderList) {
				if (oldOrderMap.get(boRecord.Id).Opportunity__c != boRecord.Opportunity__c) {
					if (map_OpportunityRecords != null) {
						boRecord.Account__c = map_OpportunityRecords.get(boRecord.Opportunity__c).AccountId;
						if (boRecord.Coverage_Effective_Date__c == null) {
							boRecord.Coverage_Effective_Date__c = map_OpportunityRecords.get(boRecord.Opportunity__c).HI_Effective_Date__c;
						}
					}
				}

				if ((oldOrderMap.get(boRecord.Id).Account__c != boRecord.Account__c) || (oldOrderMap.get(boRecord.Id).RecordTypeId != boRecord.RecordTypeId)) {
					if (map_accounts != null && map_accounts.get(boRecord.Account__c) != null) {
						String recordTypeName = map_RecordTypesInfo.get(boRecord.RecordTypeId);
						String accountName = map_accounts.get(boRecord.Account__c).Name;
						if (accountName != null) {
							if ((recordTypeName + accountName).length() < 80) {
								boRecord.Name = accountName + '-' + recordTypeName;
							} else {
								if (accountName.length() >= 80) {
									accountName = accountName.subString(0, (80 - recordTypeName.length()));
									boRecord.Name = accountName + '-' + recordTypeName;
								}
							}
						} else {
							boRecord.Name = recordTypeName;
						}
					}
				}
			}
		}
	}

	/* validated
    BY : Akash
    Date : Feb 5 2019
    Ticket : Enhancement
    Description : Converted Process Builder - 'Track Benefit Order Status Changes' into Trigger
    
    */
	public static void trackBenefitOrderStatusChanges(Map<id, Benefit_Order__c> oldOrderMap, List<Benefit_Order__c> newOrderList) {
		if (newOrderList == null) {
			return;
		}

		List<Benefit_Order_Status_Change_History__c> createBenefitOrderStatusHistoryList = new List<Benefit_Order_Status_Change_History__c>();
		Set<Id> boidSet = new Set<Id>();
		for (Benefit_Order__c bo : newOrderList) {
			if (boidSet.contains(bo.id))
				continue;

			boidSet.add(bo.id);
			Benefit_Order__c oldOrder = null;
			if (oldOrderMap != null && oldOrderMap.containsKey(bo.Id))
				oldOrder = oldOrderMap.get(bo.Id);

			Benefit_Order_Status_Change_History__c historyObj = new Benefit_Order_Status_Change_History__c();
			if (oldOrder == null) {
				historyObj.End_Time__c = System.now();
				historyObj.Benefit_Order__c = bo.Id;
				historyObj.Start_Time__c = System.now();
				historyObj.To_Status__c = bo.Order_Status__c;
				createBenefitOrderStatusHistoryList.add(historyObj);
			} else if (bo.Order_Status__c != oldOrder.Order_Status__c && bo.Order_Status__c != null && bo.Status_Change_Date_Time__c != null) {
				historyObj.End_Time__c = System.now();
				historyObj.From_Status__c = oldOrder.Order_Status__c;
				historyObj.Benefit_Order__c = bo.Id;
				historyObj.Start_Time__c = bo.Status_Change_Date_Time__c;
				historyObj.To_Status__c = bo.Order_Status__c;
				bo.Status_Change_Date_Time__c = System.now();

				createBenefitOrderStatusHistoryList.add(historyObj);
			} else if (bo.Order_Status__c != oldOrder.Order_Status__c) {
				bo.Status_Change_Date_Time__c = System.now();
			}
		}

		if (!createBenefitOrderStatusHistoryList.isEmpty())
			insert createBenefitOrderStatusHistoryList;
	}

	/* validated
	 * Workflow Conversion method for before insert
	 */
	public static void setOrderValuesOnInsert(Benefit_Order__c boRecord) {
		//WORKFLOW CONVERSION -- WORKFLOW NAME - Close Benefit Order Date- 21 FEB 2019
		if (
			boRecord.Order_Status__c == 'Fulfilled' ||
			boRecord.Order_Status__c == 'Denied' ||
			boRecord.Order_Status__c == 'Canceled' ||
			boRecord.Order_Status__c == 'Closed Lost' ||
			boRecord.Order_Status__c == 'Closed Admin'
		) {
			boRecord.End_Date__c = system.today();
		}

		// WORKFLOW CONVERSION -- WORKFLOW NAME - Order is Fulfilled Date- 21 FEB 2019
		if (boRecord.Fulfilled__c) {
			boRecord.Order_Fulfilled_Timestamp__c = System.now();
		}

		// WORKFLOW CONVERSION -- WORKFLOW NAME - Reopen Benefit OrdervDate- 21 FEB 2019
		if (boRecord.Coverage_Effective_Date__c != null) {
			boRecord.Original_Effective_Date__c = boRecord.Coverage_Effective_Date__c;
		}
	}

	/* Validated
	 * Workflow Conversion method for before update
	 */
	public static void updateFieldsBOOnBeforeUpdate(List<Benefit_Order__c> newBenefitOrders, Map<Id, Benefit_Order__c> oldBenefitOrderMap, Map<Id, Opportunity> oppMap) {
		List<Opportunity> list_BorOpportunity = new List<Opportunity>();
		for (Benefit_Order__c boRecord : newBenefitOrders) {
			Benefit_Order__c oldBo = oldBenefitOrderMap.get(boRecord.Id);
			if (boRecord.RecordTypeId == BO_REC_TYPE_ID_BOR) {
				if (boRecord.Order_Status__c != oldBo.Order_Status__c && boRecord.Order_Status__c == 'Plan Review Sent') {
					boRecord.Plan_Reviews_Sent_Date__c = System.now();
				} else if (boRecord.Order_Status__c != oldBo.Order_Status__c && boRecord.Order_Status__c == 'Enrollment Review Sent') {
					boRecord.Enrollment_Review_Sent_Date__c = System.now();
				}
			}

			if (boRecord.Order_Status__c == 'Qualification' && boRecord.Qualification_Follow_Up_Date__c != null && oldBo.Qualification_Follow_Up_Date__c != boRecord.Qualification_Follow_Up_Date__c) {
				boRecord.Order_Status__c = 'Ready For Qualification';
			}
			// WORKFLOW CONVERSION -- WORKFLOW NAME - Block Date- 21 FEB 2019
			if (boRecord.Blocked__c && boRecord.Blocked__c != oldBo.Blocked__c) {
				boRecord.Unblocked_Date__c = null;
				boRecord.Blocked_Date__c = system.today();
			}
			// WORKFLOW CONVERSION -- WORKFLOW NAME - Close Benefit Order Date- 21 FEB 2019
			if (
				boRecord.Order_Status__c != oldBo.Order_Status__c &&
				(boRecord.Order_Status__c == 'Fulfilled' ||
				boRecord.Order_Status__c == 'Denied' ||
				boRecord.Order_Status__c == 'Canceled' ||
				boRecord.Order_Status__c == 'Closed Lost' ||
				boRecord.Order_Status__c == 'Closed Admin')
			) {
				boRecord.End_Date__c = System.today();
				if (boRecord.RecordTypeId == BO_REC_TYPE_ID_BOR) {
					Opportunity objOpp = new Opportunity();
					objOpp.id = boRecord.Opportunity__c;
					objOpp.BOR_Implementation_End_Date__c = System.today();
					list_BorOpportunity.add(objOpp);
				}
			}

			// WORKFLOW CONVERSION -- WORKFLOW NAME - Order is Fulfilled Date- 21 FEB 2019
			if (boRecord.Fulfilled__c && boRecord.Fulfilled__c != oldBo.Fulfilled__c) {
				boRecord.Order_Fulfilled_Timestamp__c = System.now();
			}

			//WORKFLOW CONVERSION -- WORKFLOW NAME - Order is Unfulfilled Date- 21 FEB 2019
			if (!boRecord.Fulfilled__c && boRecord.Fulfilled__c != oldBo.Fulfilled__c) {
				boRecord.Order_Fulfilled_Timestamp__c = null;
			}

			// WORKFLOW CONVERSION -- WORKFLOW NAME - Reopen Benefit Order Date- 21 FEB 2019
			if (boRecord.Closed__c == false && boRecord.Closed__c != oldBo.Closed__c) {
				boRecord.End_Date__c = null;
			}

			// WORKFLOW CONVERSION -- WORKFLOW NAME - Unblock Date- 21 FEB 2019
			if (boRecord.Blocked__c != oldBo.Blocked__c && boRecord.Blocked__c == false) {
				boRecord.Unblocked_Date__c = system.today();
			}
			/* WFLW Update EE at Fulfillment */
			if (boRecord.Order_Status__c != oldBo.Order_Status__c && boRecord.Order_Status__c == 'Fulfilled' && boRecord.Opportunity__c != null && oppMap.containsKey(boRecord.Opportunity__c)) {
				boRecord.EE_at_Fulfillment__c = oppMap.get(boRecord.Opportunity__c).Account.EE_Active_Count_Panda__c;
			}
		}

		if (list_BorOpportunity.size() > 0) {
			Boolean blnSkipTrigger = OpportunityTriggerHelper.skipTrigger;
			OpportunityTriggerHelper.skipTrigger = blnSkipTrigger;
			update list_BorOpportunity;
			OpportunityTriggerHelper.skipTrigger = blnSkipTrigger;
		}
	}

	// sets the value for handoff email - validated
	public static void checkEmailHandOff(List<Case> list_CasesToSendForHandoff) {
		boolean caseTriggerFlag = CaseTriggerHelper.skipTrigger;
		CaseTriggerHelper.skipTrigger = true;
		update list_CasesToSendForHandoff;
		CaseTriggerHelper.skipTrigger = caseTriggerFlag;
	}

	// Sends email to the case contact when a new order is created - validated
	public static String sendEmailOnCaseCreation(
		List<Case> caseListInsert,
		Map<Id, Opportunity> oppMap,
		Map<Id, Contact> conMap,
		Map<Id, Integer> mapCountPolicyOnOpp,
		Map<Id, Set<String>> map_OppToCCEmails
	) {
		List<Case> list_CasesToUpdate = new List<Case>();
		String strErrorIfExist = '';
		Map<Id, Id> map_CaseRecIdWithVFEmailTemplate = new Map<Id, Id>();
		Map<String, Id> map_OrgWideAddresses = new Map<String, Id>();
		List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
		for (EmailTemplate temp : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'NewPlanEmailFromCase' OR DeveloperName = 'RenewalEmailFromCase']) {
			if (temp.DeveloperName == 'NewPlanEmailFromCase') {
				map_CaseRecIdWithVFEmailTemplate.put(CASE_REC_TYPE_ID_NEW_PLAN, temp.Id);
			}
			if (temp.DeveloperName == 'RenewalEmailFromCase') {
				map_CaseRecIdWithVFEmailTemplate.put(CASE_REC_TYPE_ID_RENEWAL, temp.Id);
			}
		}
		for (OrgWideEmailAddress owea : [SELECT Id, displayname FROM OrgWideEmailAddress WHERE Address = 'newplans@gusto.com' OR Address = 'renewals@gusto.com']) {
			map_OrgWideAddresses.put(owea.displayname, owea.Id);
		}
		for (Case caseRec : caseListInsert) {
			//Check Policy is exist on opportunity associated with case or not
			Integer NoOfPolicy = mapCountPolicyOnOpp.get(caseRec.Opportunity__c);
			if (
				caseRec.RecordTypeId != null &&
				map_CaseRecIdWithVFEmailTemplate.containsKey(caseRec.RecordTypeId) &&
				(caseRec.RecordTypeId == CASE_REC_TYPE_ID_NEW_PLAN ||
				caseRec.RecordTypeId == CASE_REC_TYPE_ID_RENEWAL ||
				caseRec.RecordTypeId == CASE_REC_TYPE_ID_CHANGE) &&
				caseRec.ownerId != null &&
				string.valueOf(caseRec.OwnerId).startsWith('005') &&
				(oppMap.containsKey(caseRec.Opportunity__c)) &&
				// SJay - 03/23/2020 - Commented to include Send Handoff Emails which are false and only check this once email is sent successfully.
				caseRec.Origin == 'Hippo' &&
				(NoOfPolicy != null &&
				NoOfPolicy > 0)
			) {
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				List<String> toAddressList = new List<String>();
				List<String> ccAddressList = new List<String>();
				if (conMap.containsKey(caseRec.ContactId) && conMap.get(caseRec.ContactId).Email != null) {
					toAddressList.add(conMap.get(caseRec.ContactId).Email);
				}
				//SJay - 2/24/2020 - Commented out this line as the emails are getting the From address set as this Opp Owner's email.
				//mail.setSenderDisplayName(oppMap.get(caseRec.Opportunity__c).owner.firstname+' '+oppMap.get(caseRec.Opportunity__c).owner.lastname);
				if (caseRec.RecordTypeId == CASE_REC_TYPE_ID_NEW_PLAN) {
					mail.setReplyTo(Label.NewPlanFulfillmentFromEmail);
					// SJay - 5/20/2020 - Added code to set from address from org wide addresses
					if (map_OrgWideAddresses.containsKey('New Plans'))
						mail.setOrgWideEmailAddressId(map_OrgWideAddresses.get('New Plans'));
				} else if (caseRec.RecordTypeId == CASE_REC_TYPE_ID_RENEWAL) {
					mail.setReplyTo(Label.RenewedFulfillmentFromEmail);
					// SJay - 5/20/2020 - Added code to set from address from org wide addresses
					if (map_OrgWideAddresses.containsKey('Benefits Renewals'))
						mail.setOrgWideEmailAddressId(map_OrgWideAddresses.get('Benefits Renewals'));
					//Remove the signature for renewal benefit order

					if (oppMap.get(caseRec.Opportunity__c).Owner_Role_Name__c == null || oppMap.get(caseRec.Opportunity__c).Owner_Role_Name__c == FWManageRoleUtil.ROLE_BENEFITS_DESIGNER) {
						mail.setUseSignature(false);
					}
				}

				mail.setTargetObjectId(caseRec.contactId);
				mail.setWhatId(caseRec.Id);
				mail.setSaveAsActivity(true);
				mail.setTemplateId(map_CaseRecIdWithVFEmailTemplate.get(caseRec.RecordTypeId));

				if (caseRec.Opportunity__c != null && map_OppToCCEmails != null && map_OppToCCEmails.containsKey(caseRec.Opportunity__c)) {
					Set<String> set_CCEmails = map_OppToCCEmails.get(caseRec.Opportunity__c);
					if (set_CCEmails.size() > 0) {
						mail.setCcAddresses(new List<String>(set_CCEmails));
					}
				}

				mails.add(mail);
				// SJay - 03/23/2020 - Changed functionality to handle single email at a time and if any error then log it else set the send handoff email.
				Messaging.sendEmailResult[] sendEmailResults;
				sendEmailResults = Messaging.sendEmail(mails, false);

				for (Messaging.SendEmailResult smr : sendEmailResults) {
					if (smr.isSuccess()) {
						if (caseRec.ownerId != null && string.valueOf(caseRec.OwnerId).startsWith('005')) {
							caseRec.Send_Handoff_Email__c = true;
						}
						list_CasesToUpdate.add(caseRec);
					} else {
						for (Messaging.Sendemailerror sendEmailError : smr.getErrors()) {
							strErrorIfExist = sendEmailError.Message;
						}
						if (!strErrorIfExist.contains(strBlankEmail) && !strErrorIfExist.contains(strBouncedEmail)) {
							ExceptionLogUtil.logException('BenefitOrderHelper', 'sendEmailOnCaseCreation', strErrorIfExist, 'High');
						}
						return strErrorIfExist;
					}
				}
			}
			mails.clear();
		}

		if (!list_CasesToUpdate.isEmpty()) {
			checkEmailHandOff(list_CasesToUpdate);
		}

		return strErrorIfExist;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : updating the Ticket owner, in case of BO owner change
	 * @Parm        : list_NewBenefitOrders - list of New Benefit Orders
					  map_BenefitOrderOld - Map of Old Benefit Orders
	 * @Return      : null
	**/
	public static void changeTicketOwnership(List<Benefit_Order__c> list_NewBenefitOrders, Map<Id, Benefit_Order__c> map_BenefitOrderOld) {
		Map<Id, Benefit_Order__c> map_BosToBeProcessed = new Map<Id, Benefit_Order__c>();
		List<Ticket__c> list_TicketsToBeUpdated = new List<Ticket__c>();
		Set<String> set_OldOwnerIds = new Set<String>();

		if (list_NewBenefitOrders == null) {
			return;
		}

		for (Benefit_Order__c objNewBenefitOrder : list_NewBenefitOrders) {
			Benefit_Order__c objOldBenefitOrder = map_BenefitOrderOld.get(objNewBenefitOrder.Id);
			String strOwnerId = objNewBenefitOrder.OwnerId;
			String strOldOwnerId = objOldBenefitOrder.OwnerId;

			if (objNewBenefitOrder.OwnerId != objOldBenefitOrder.OwnerId && !strOwnerId.startsWith(BenefitOrderUtil.QUEUE_PREFIX) && !strOldOwnerId.startsWith(BenefitOrderUtil.QUEUE_PREFIX)) {
				map_BosToBeProcessed.put(objNewBenefitOrder.Id, objNewBenefitOrder);
				set_OldOwnerIds.add(objOldBenefitOrder.OwnerId);
			}
		}

		if (!map_BosToBeProcessed.isEmpty() && !set_OldOwnerIds.isEmpty()) {
			for (Ticket__c objTicket : [
				SELECT Id, OwnerId, Status__c, Benefit_Order__c, Benefit_Order__r.RecordTypeId
				FROM Ticket__c
				WHERE
					Benefit_Order__c != NULL
					AND Status__c != NULL
					AND OwnerId != NULL
					AND Benefit_Order__c IN :map_BosToBeProcessed.keySet()
					AND Status__c != :TicketUtil.TICKET_STATUS_CLOSED
					AND OwnerId IN :set_OldOwnerIds
			]) {
				if (map_BosToBeProcessed.containsKey(objTicket.Benefit_Order__c)) {
					objTicket.OwnerId = map_BosToBeProcessed.get(objTicket.Benefit_Order__c).OwnerId;

					if (objTicket.Benefit_Order__r.RecordTypeId != BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID) {
						objTicket.Owner_Role_Type__c = TicketUtil.TICKET_OWNER_ROLE_TYPE_CORE;
					}

					list_TicketsToBeUpdated.add(objTicket);
				}
			}

			if (!list_TicketsToBeUpdated.isEmpty()) {
				Boolean blnTicketTriggerFlag = TicketTriggerHelper.skipTrigger;
				Boolean blnFeedTriggerFlag = FeedItemTriggerHelper.skipTrigger;

				TicketTriggerHelper.skipTrigger = true;
				FeedItemTriggerHelper.skipTrigger = true;
				update list_TicketsToBeUpdated;
				FeedItemTriggerHelper.skipTrigger = blnFeedTriggerFlag;
				TicketTriggerHelper.skipTrigger = blnTicketTriggerFlag;
			}
		}
	}

	public static void setBigDeskBenOps(Benefit_Order__c objBO, Map<Id, Opportunity> map_Opportunities) {
		if (objBO.Opportunity__c != null && objBO.RecordTypeId == BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID && map_Opportunities != null && map_Opportunities.containsKey(objBO.Opportunity__c)) {
			objBO.Big_Desk_BenOps__c = map_Opportunities.get(objBO.Opportunity__c).Big_Desk_BenOps__c;
		}
		if (
			objBO.Opportunity__c != null &&
			map_Opportunities != null &&
			map_Opportunities.containsKey(objBO.Opportunity__c) &&
			(objBO.RecordTypeId == BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID ||
			objBO.RecordTypeId == BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID ||
			objBO.RecordTypeId == BenefitOrderUtil.CHANGE_BENEFIT_ORDER_RT_ID)
		) {
			objBO.Maestro__c = map_Opportunities.get(objBO.Opportunity__c).Maestro__c;
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : check if there is any open ticket with BO, if yes retrict the user to update the status update
	 * @Parm        : list_NewBenefitOrders - list of New Benefit Orders
					  map_BenefitOrdersOld - Map of Old Benefit Orders
					  map_BenefitOrdersNew - Map of New Benefit Orders
	 * @Return      : null
	**/
	public static void checkOpenTicketLinkedToBO(List<Benefit_Order__c> list_NewBenefitOrders, Map<Id, Benefit_Order__c> map_BenefitOrdersOld, Map<Id, Benefit_Order__c> map_BenefitOrdersNew) {
		Set<Id> set_BenefitOrdersToBeProcessed = new Set<Id>();
		if (list_NewBenefitOrders == null) {
			return;
		}

		for (Benefit_Order__c objNewBenefitOrder : list_NewBenefitOrders) {
			Benefit_Order__c objOldBenefitOrder = map_BenefitOrdersOld.get(objNewBenefitOrder.Id);
			String strOrderStatus = objNewBenefitOrder.Order_Status__c;

			if (objNewBenefitOrder.Order_Status__c != objOldBenefitOrder.Order_Status__c && BenefitOrderUtil.COMPLETED_ORDER_STATUSES.contains(strOrderStatus)) {
				set_BenefitOrdersToBeProcessed.add(objNewBenefitOrder.Id);
			}
		}

		if (!set_BenefitOrdersToBeProcessed.isEmpty()) {
			Map<Id, Ticket__c> map_OpenTicketsWithBO = BenefitOrderUtil.fetchOpenTicketsRelatedToBO(set_BenefitOrdersToBeProcessed);

			for (Id idBO : map_OpenTicketsWithBO.keySet()) {
				if (!map_BenefitOrdersNew.isEmpty() && map_BenefitOrdersNew.containsKey(idBO)) {
					Benefit_Order__c objBO = map_BenefitOrdersNew.get(idBO);
					objBO.addError(BenefitOrderUtil.MSQ_CLOSE_OPEN_TICKET_FIRST);
				}
			}
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : This method reset the Case Owner when Benefit Order Assign to "Benefit Transfer Advocate".
	 * @Parm        : List of New Benefit Order
	 * 				: Map of Old Benefit Order
	 * @Return      : void
	 **/
	public static void updateBoRCaseOwner(list<Benefit_Order__c> list_NewBOs, Map<Id, Benefit_Order__c> map_OldBOs) {
		Map<Id, Id> map_BOIdWithOwnerId = new Map<Id, Id>();
		List<Case> list_UpdateCases = new List<Case>();
		for (Benefit_Order__c objBO : list_NewBOs) {
			Benefit_Order__c objOldBO = map_OldBOs.get(objBO.Id);

			if (objBO.RecordTypeId == BO_REC_TYPE_ID_BOR && objOldBO.Type__c == null && objBO.Type__c != null && objBO.OwnerId != objOldBO.OwnerId) {
				map_BOIdWithOwnerId.put(objBO.Id, objBO.OwnerId);
			}
		}

		if (map_BOIdWithOwnerId.size() > 0) {
			Set<Id> set_BOIds = map_BOIdWithOwnerId.keySet();
			for (Case objCase : [
				SELECT Id, Status, OwnerId, Benefit_Order__c
				FROM Case
				WHERE RecordTypeId = :CASE_REC_TYPE_ID_BOR AND Benefit_Order__c IN :set_BOIds AND Integration_Id__c LIKE 'hippo%'
			]) {
				if (map_BOIdWithOwnerId.containsKey(objCase.Benefit_Order__c)) {
					objCase.OwnerId = map_BOIdWithOwnerId.get(objCase.Benefit_Order__c);
					list_UpdateCases.add(objCase);
				}
			}
		}

		if (list_UpdateCases.size() > 0) {
			CaseTriggerHelper.skipTrigger = true;
			update list_UpdateCases;
			CaseTriggerHelper.skipTrigger = false;
		}
	}

	/**
	 * @Author      : Udit Jain
	 * @Description : This method is used to map the Required Action on BO based on the Case's Requires Action for Renewal
	 * @Parm        : List of Renewal Benefit Order
	 * 				: Set of Renewal Opportunity Ids
	 * @Return      : void
	 **/
	public static void requiresActionAssignment(List<Benefit_Order__c> list_RenewalOrders, Set<Id> set_OppRenewalId){
		Map<Id, Case> map_OpptyCases = new Map<Id, Case>();
		for (Case objCase : [
			SELECT Id, Requires_Action__c, Status, Opportunity__c, Opportunity__r.RecordTypeId, Benefit_Order__c, Carrier_Order__c, RecordTypeId, OwnerId, Origin, Integration_Id__c
			FROM Case
			WHERE
				Opportunity__c != NULL
				AND Opportunity__c IN :set_OppRenewalId
				AND Opportunity__r.RecordTypeId =: OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID
				AND Type =: CASE_TYPE_BENEFITS_RENEWAL
				AND RecordTypeId =: CaseUtils.RECTYPE_RENEWAL
				AND Integration_Id__c != NULL 
				AND Integration_Id__c LIKE 'hippo-Benefits_Renewal%'
		]) {
			map_OpptyCases.put(objCase.Opportunity__c, objCase);
		}

		for(Benefit_Order__c objBO : list_RenewalOrders){
			if(!map_OpptyCases.isEmpty() && map_OpptyCases.containsKey(objBO.Opportunity__c)){
				objBO.Requires_Action__c = map_OpptyCases.get(objBO.Opportunity__c).Requires_Action__c;
			}
		}
	}
	
	/**
	 * @Author      : Bhagat Singh
	 * @Description : This method work for Benefit order having record type 'Benefits BYB' and moved to fulfilled or cancelled stage
	 *              : If connect-broker Benefits BYB cases having blank Audience or blank Case Reason then we throw error message.
	 * @Parm        : List of new Benefit Order
	 *              : Map of old Benefit Order
	 * @Return      : void
	 **/
	public static void checkOpenConnectBroker(List<Benefit_Order__c> list_BOs, Map<Id, Benefit_Order__c> map_OldBOs) {
		Set<Id> set_FulfilledBOIds = new Set<Id>();
		if (map_OldBOs != null) {
			Map<Id,Boolean> mapBOIdWithOpenCase = new Map<Id,Boolean>();
			for (Benefit_Order__c objBO : list_BOs) {
				Benefit_Order__c objOldBO = map_OldBOs.get(objBO.Id);
				if (objOldBO.RecordTypeId == BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID && objBO.Order_Status__c != objOldBO.Order_Status__c && set_BYBBOOrderStatus.contains(objBO.Order_Status__c)) {
					set_FulfilledBOIds.add(objBO.Id);					
				}
			}

			if (!set_FulfilledBOIds.isEmpty()) {
				for (Case objCase : [SELECT Id, Status, Benefit_Order__c, RecordTypeId, Audience__c, Integration_Id__c, Reason 
									FROM Case
									WHERE Status !=: strClosedStatus AND Benefit_Order__c != null 
									AND Benefit_Order__c IN :set_FulfilledBOIds AND Integration_Id__c = null 
									AND (Audience__c = null OR Reason = null) 
				]) {
					mapBOIdWithOpenCase.put(objCase.Benefit_Order__c, true);
				}
			}

			if (!mapBOIdWithOpenCase.isEmpty()) {
				for (Benefit_Order__c objBO : list_BOs) {
					if (mapBOIdWithOpenCase.containsKey(objBO.Id)) {
						objBO.addError(STR_ERROR);
					}
				}
			}
		}
	}
}