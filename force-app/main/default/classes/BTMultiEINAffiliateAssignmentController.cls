/*
    BY: PR
    Date: April 1, 2020
    Descirption: 
*/
public with sharing class BTMultiEINAffiliateAssignmentController {
	//list used for affiliates
	public List<AccountWrapper> list_AccWrapper { get; set; }
	// to add or remove selected companies
	public Integer intSelectedCompanyIndx { get; set; }
	/* AccountsWrapper Section */
	public Map<Id, AccountWrapper> map_SelectedAccounts { get; set; }
	public String strAccName { get; set; } // to search accounts by name
	public String strZPCompanyId { get; set; } // to search accounts by ZPCompanyId
	public Integer intSize { get; set; }
	public Integer intNoOfRecords { get; set; }
	//public List<SelectOption> paginationSizeOptions{get;set;}
	public static final Integer intQUERY_LIMIT = 10000;
	public static final Integer intPAGE_SIZE = 10;
	public Id idAcccountToBeRemoved { get; set; }
	public Benefit_Order__c objBenefitOrder { get; set; }
	public ApexPages.StandardSetController setCon { get; set; } //StandardSetController to fetch accounts
	public String strExistingAccountId { get; set; }
	Map<Id, Carrier_Order__c> map_parentCarrierOrder = new Map<Id, Carrier_Order__c>(); //key=Carrier__c, value=Carrier_Order__c
	public String strRecordtype { get; set; }
	public String strErrorMsg { get; set; }
	set<string> set_RemovedAccountIds = new Set<string>();
	static String strCLOSEDWON = 'Closed Won';

	public BTMultiEINAffiliateAssignmentController(ApexPages.StandardController sc) {
		strExistingAccountId = '';
		strErrorMsg = '';

		objBenefitOrder = (Benefit_Order__c) sc.getRecord();

		strRecordtype = ApexPages.CurrentPage().getparameters().get('rtnam');
		if (String.isBlank(strRecordtype)) {
			strRecordtype = 'Benefits BoR';
		}
		getBenefitDetails();
	}

	public void getBenefitDetails() {
		if (objBenefitOrder == null || objBenefitOrder.Id == null) {
			strErrorMsg = 'Page not loaded properly.';
		} else {
			List<Benefit_Order__c> benefitList = [
				SELECT Id, Name, Is_Multi_EIN__c, Account__c, Account__r.Name, Account__r.ParentId, OwnerId
				FROM Benefit_Order__c
				WHERE Id = :objBenefitOrder.Id
			];
			if (benefitList.size() > 0) {
				objBenefitOrder = benefitList[0];
				if (benefitList.get(0).Is_Multi_EIN__c == true) {
					if (objBenefitOrder.Account__r.ParentId != null) {
						strErrorMsg = objBenefitOrder.Name + ' is not the parent Multi-EIN record. Affiliates can only be managed from the parent Benefit Order record.';
					}
				}
			} else {
				strErrorMsg = 'Not able to find Benefit Order. Please reload the page again.';
				return;
			}

			map_parentCarrierOrder = new Map<Id, Carrier_Order__c>();
			List<Carrier_Order__c> lst_parentCarrierOrder = [
				SELECT Id, OwnerId, Carrier__c, Name, CreatedDate, Parent_Carrier_Order__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c = :objBenefitOrder.Id
			];
			for (Carrier_Order__c coObj : lst_parentCarrierOrder) {
				if (coObj.Carrier__c != null && !map_parentCarrierOrder.containsKey(coObj.Carrier__c)) {
					map_parentCarrierOrder.put(coObj.Carrier__c, coObj);
				}
			}
			lst_parentCarrierOrder.clear();
		}

		list_AccWrapper = new List<AccountWrapper>();
		if (String.isNotBlank(strErrorMsg)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, strErrorMsg));
			setCon = new ApexPages.StandardSetController(new List<Account>());
		} else {
			fetchAccountRecord();
		}
	}

	public void fetchAccountRecord() {
		Id currentAccountId = objBenefitOrder.Account__c;
		//get only those accounts which have orders associated with them
		Set<String> setOpportunityStatusToInclude = new Set<String>{ strCLOSEDWON };
		Set<String> setBenefitOderStatusToExclude = new Set<String>{ 'Canceled', 'Closed Lost', 'Fulfilled' };

		String strAccountQuery =
			'SELECT Id,Name,ParentId,(SELECT Id,Parent_Benefit_Order__c, Account__c, Transition_to_Fulfillment__c, Is_Multi_EIN__c,OwnerId FROM Benefit_Orders__r) ' +
			' FROM Account WHERE Id !=: currentAccountId AND ';
		strAccountQuery +=
			' RecordType.Name =\'Company\' AND ZP_Company_Overall_Status__c =\'Active\' AND Id IN (SELECT Account__c FROM Benefit_Order__c WHERE ' +
			' Opportunity__r.RecordType.Name =\'Benefits BoR\' AND Opportunity__r.Order_Generated__c=true AND ' +
			' Opportunity__r.StageName = :strCLOSEDWON AND Is_Multi_EIN__c = false AND ' +
			' Order_Status__c NOT IN:setBenefitOderStatusToExclude) AND ParentId = null AND ZP_Company_Id__c != NULL ';

		if (String.isNotBlank(strAccName)) {
			strAccountQuery += ' AND  Name Like \'%' + strAccName + '%\'';
		}
		if (String.isNotBlank(strZPCompanyId)) {
			strAccountQuery += ' AND ZP_Company_ID__c Like \'%' + strZPCompanyId + '%\'';
		}
		strAccountQuery += ' LIMIT :intQUERY_LIMIT ';
		setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strAccountQuery));

		// sets the number of records to show in each page view
		setCon.setPageSize(intPAGE_SIZE);

		initializeAccountWrapper();
	}

	//indicates whether there are more records after the current page set.
	public Boolean hasNext {
		get {
			return setCon.getHasNext();
		}
		set;
	}

	//indicates whether there are more records before the current page set.
	public Boolean hasPrevious {
		get {
			return setCon.getHasPrevious();
		}
		set;
	}

	//returns the page number of the current page set
	public Integer pageNumber {
		get {
			return setCon.getPageNumber();
		}
		set;
	}

	//return total number of pages for page set
	public Integer getTotalPages() {
		Decimal totalSize = setCon.getResultSize();
		Decimal pageSize = setCon.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(System.RoundingMode.CEILING);
	}

	//returns the first page of the page set
	public void first() {
		setCon.first();
		initializeAccountWrapper();
	}

	//returns the last page of the page set
	public void last() {
		setCon.last();
		initializeAccountWrapper();
	}

	//returns the previous page of the page set
	public void previous() {
		setCon.previous();
		initializeAccountWrapper();
	}

	//returns the next page of the page set
	public void next() {
		setCon.next();
		initializeAccountWrapper();
	}
	//init accounts
	public void initializeAccountWrapper() {
		boolean blnIsPageLoad = false;
		if ((list_AccWrapper == null || list_AccWrapper.size() == 0) && (map_SelectedAccounts == null || map_SelectedAccounts.size() == 0)) {
			blnIsPageLoad = true;
		}

		list_AccWrapper = new List<AccountWrapper>();
		map<Id, Account> map_alreadyRelatedAffiliates = new Map<Id, Account>();

		if (blnIsPageLoad) {
			strExistingAccountId = '';
			Integer indx1 = 0;
			map_SelectedAccounts = new Map<ID, AccountWrapper>();
			for (Account objAcc : [SELECT Id, Name, ParentId FROM Account WHERE ParentId = :objBenefitOrder.Account__c]) {
				map_SelectedAccounts.put(objAcc.Id, new AccountWrapper(objAcc, true, indx1));
				strExistingAccountId = strExistingAccountId + ';' + objAcc.Id;
				indx1++;
			}
		}

		Integer indx = 0;
		if (map_SelectedAccounts == null) {
			map_SelectedAccounts = new Map<ID, AccountWrapper>();
		}
		for (Account objAcc : (List<Account>) setCon.getRecords()) {
			if (map_SelectedAccounts != null && map_SelectedAccounts.containsKey(objAcc.id)) {
				list_AccWrapper.add(new AccountWrapper(objAcc, true, indx));
			} else {
				list_AccWrapper.add(new AccountWrapper(objAcc, false, indx));
			}
			indx++;
		}
	}

	// to add selected companies to map_SelectedAccounts
	public void selectCompany() {
		if (list_AccWrapper != null && list_AccWrapper.size() > intSelectedCompanyIndx) {
			AccountWrapper objSelectedAcc = list_AccWrapper[intSelectedCompanyIndx];

			//deselect account
			if (!objSelectedAcc.blnIsSelected && map_SelectedAccounts.containsKey(objSelectedAcc.objAccount.Id)) {
				map_SelectedAccounts.remove(objSelectedAcc.objAccount.Id);
				set_RemovedAccountIds.add(objSelectedAcc.objAccount.Id);
			} else if (objSelectedAcc.blnIsSelected) {
				//select account
				if (map_SelectedAccounts == null)
					map_SelectedAccounts = new Map<Id, AccountWrapper>();
				map_SelectedAccounts.put(objSelectedAcc.objAccount.Id, objSelectedAcc);
				if (set_RemovedAccountIds.contains(objSelectedAcc.objAccount.Id)) {
					set_RemovedAccountIds.remove(objSelectedAcc.objAccount.Id);
				}
			}
		}
	}
	/*
	 * REmove selected account from map
	 */
	public void removeAccount() {
		if (idAcccountToBeRemoved != null && map_SelectedAccounts != null && map_SelectedAccounts.containsKey(idAcccountToBeRemoved)) {
			map_SelectedAccounts.remove(idAcccountToBeRemoved);
			set_RemovedAccountIds.add(idAcccountToBeRemoved);
			initializeAccountWrapper();
		}
	}

	/*
	 * Fetch Accounts based on search criteria
	 */
	public void searchAccounts() {
		fetchAccountRecord();
	}

	//this method gets called on click of "Save" button
	public pagereference saveChildAccount() {
		PageReference pageRef = null;
		try {
			map<Id, Account> map_ToUpdateAffiliatesAccounts = new Map<Id, Account>();
			map<Id, Benefit_Order__c> map_ToUpdateRelationShipBOs = new Map<Id, Benefit_Order__c>();
			Map<Id, Carrier_Order__c> map_ToUpdateRelationShipCOs = new Map<Id, Carrier_Order__c>();
			map<Id, Transition_to_Fulfillment__c> map_Transition = new Map<Id, Transition_to_Fulfillment__c>();

			//Affiliate assignment logic
			if (map_SelectedAccounts.size() > 0) {
				//Account relationship Update Logic
				Set<Id> set_newlyAddedAccountId = new Set<Id>();

				for (Id idAcc : map_SelectedAccounts.keySet()) {
					if (map_SelectedAccounts.get(idAcc).objAccount.ParentId == null) {
						map_ToUpdateAffiliatesAccounts.put(idAcc, new Account(Id = idAcc, ParentId = objBenefitOrder.Account__c));
						set_newlyAddedAccountId.add(idAcc);
					}
				}

				//DML on Account to update parent Child relationship
				Set<Id> set_benefitOrderId = new Set<Id>();

				//updating newly introduced Affiliate's Account and BO related records
				for (Id accountKey : map_SelectedAccounts.keySet()) {
					AccountWrapper wrapperObj = map_SelectedAccounts.get(accountKey);
					for (Benefit_Order__c benefitObj : wrapperObj.objAccount.Benefit_Orders__r) {
						if (set_newlyAddedAccountId.contains(accountKey)) {
							benefitObj.OwnerId = objBenefitOrder.OwnerId;
							benefitObj.Parent_Benefit_Order__c = objBenefitOrder.Id;
							benefitObj.Is_Multi_EIN__c = true;
							map_ToUpdateRelationShipBOs.put(benefitObj.Id, benefitObj);
						}
						set_benefitOrderId.add(benefitObj.Id);

						if (benefitObj.Transition_to_Fulfillment__c != null) {
							map_Transition.put(benefitObj.Transition_to_Fulfillment__c, new Transition_to_Fulfillment__c(Id = benefitObj.Transition_to_Fulfillment__c, Multi_EIN__c = 'Y'));
						}
					}
				}

				if (objBenefitOrder.Is_Multi_EIN__c == false) {
					objBenefitOrder.Is_Multi_EIN__c = true;
					map_ToUpdateRelationShipBOs.put(objBenefitOrder.Id, objBenefitOrder);
				}

				Map<Id, Carrier_Order__c> map_childCarrierOrder = new Map<Id, Carrier_Order__c>();
				List<Carrier_Order__c> lst_childCarrierOrder = [
					SELECT Id, Carrier__c, Name, OwnerId, Is_Multi_EIN__c, CreatedDate, Parent_Carrier_Order__c
					FROM Carrier_Order__c
					WHERE Benefit_Order__c IN :set_benefitOrderId
				];
				for (Carrier_Order__c coObj : lst_childCarrierOrder) {
					if (coObj.Carrier__c != null && !map_parentCarrierOrder.containsKey(coObj.Carrier__c)) {
						if (map_childCarrierOrder.containsKey(coObj.Carrier__c)) {
							Carrier_Order__c carrierObj = map_childCarrierOrder.get(coObj.Carrier__c);
							if (coObj.CreatedDate < carrierObj.CreatedDate) {
								map_childCarrierOrder.remove(coObj.Carrier__c);
								map_childCarrierOrder.put(coObj.Carrier__c, coObj);
							}
						} else {
							map_childCarrierOrder.put(coObj.Carrier__c, coObj);
						}
					}
				}
				for (Id key : map_childCarrierOrder.keySet()) {
					map_parentCarrierOrder.put(key, map_childCarrierOrder.get(key));
				}

				for (Carrier_Order__c coObj : lst_childCarrierOrder) {
					if (map_parentCarrierOrder.containsKey(coObj.Carrier__c)) {
						Carrier_Order__c parentCarrierObj = map_parentCarrierOrder.get(coObj.Carrier__c);
						if (parentCarrierObj.Id != coObj.Id) {
							coObj.OwnerId = parentCarrierObj.OwnerId;
							coObj.Parent_Carrier_Order__c = parentCarrierObj.Id;
						}
					}
					coObj.Is_Multi_EIN__c = true;
					map_ToUpdateRelationShipCOs.put(coObj.Id, coObj);
				}

				/*BY:PR, Date:May/19/2020, Desc:loop on parent CarrierOrders to update Multi-EIN checkbox to true
				 *	Jira: https://app.asana.com/0/1149920908637905/1175886296669793/f
				 */
				for (Carrier_Order__c coObj : map_parentCarrierOrder.values()) {
					coObj.Is_Multi_EIN__c = true;
					map_ToUpdateRelationShipCOs.put(coObj.Id, coObj);
				}
			} else if (set_RemovedAccountIds.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select at least one record.'));
				return null;
			}

			//Affiliate removal logic
			if (set_RemovedAccountIds.size() > 0) {
				for (String strAccountId : set_RemovedAccountIds) {
					map_ToUpdateAffiliatesAccounts.put(strAccountId, new Account(id = strAccountId, ParentId = null));
				}

				for (Benefit_Order__c objBO : [
					SELECT Id, Is_Multi_EIN__c, Parent_Benefit_Order__c, Transition_to_Fulfillment__c
					FROM Benefit_Order__c
					WHERE Opportunity__r.AccountId IN :set_RemovedAccountIds
				]) {
					objBO.Is_Multi_EIN__c = false;
					objBO.Parent_Benefit_Order__c = null;
					map_ToUpdateRelationShipBOs.put(objBO.Id, objBO);

					if (objBO.Transition_to_Fulfillment__c != null) {
						map_Transition.put(objBO.Transition_to_Fulfillment__c, new Transition_to_Fulfillment__c(Id = objBO.Transition_to_Fulfillment__c, Multi_EIN__c = 'N'));
					}
				}

				for (Carrier_Order__c objCO : [
					SELECT Id, Is_Multi_EIN__c, Parent_Carrier_Order__c
					FROM Carrier_Order__c
					WHERE Benefit_Order__r.Opportunity__r.AccountId IN :set_RemovedAccountIds
				]) {
					objCO.Is_Multi_EIN__c = false;
					objCO.Parent_Carrier_Order__c = null;
					map_ToUpdateRelationShipCOs.put(objCO.Id, objCO);
				}

				//handle scenario where If no affiliates are left, we want to update the Parent Company BO and CO multi-ein indicating fields
				if (map_SelectedAccounts.size() == 0 && objBenefitOrder.Is_Multi_EIN__c == true) {
					objBenefitOrder.Is_Multi_EIN__c = false;
					map_ToUpdateRelationShipBOs.put(objBenefitOrder.Id, objBenefitOrder);

					for (Carrier_Order__c objCO : map_parentCarrierOrder.values()) {
						objCO.Is_Multi_EIN__c = false;
						map_ToUpdateRelationShipCOs.put(objCO.Id, objCO);
					}
				}
			}

			//updating removed affiliates related account
			if (map_ToUpdateAffiliatesAccounts.size() > 0) {
				update map_ToUpdateAffiliatesAccounts.values();
			}

			//updating removed affilaites related Benefit Order records
			if (map_ToUpdateRelationShipBOs.size() > 0) {
				update map_ToUpdateRelationShipBOs.values();
			}

			//updating removed affilaites related Carrier Order records
			if (map_ToUpdateRelationShipCOs.size() > 0) {
				update map_ToUpdateRelationShipCOs.values();
			}

			//updating removed affilaites related Carrier Order records
			if (map_Transition.size() > 0) {
				update map_Transition.values();
			}

			pageRef = new PageReference('/' + objBenefitOrder.Id);
			pageRef.setRedirect(true);
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex + ''));
			return null;
		}
		return pageRef;
	}

	public pagereference cancelBO() {
		PageReference pageRef = new PageReference('/' + objBenefitOrder.Id);
		return pageRef;
	}

	/*
	 * WRapper for showing Accounts on TTF if it is a multi-ein or same login
	 */
	public class AccountWrapper {
		public Account objAccount { get; set; }
		public Boolean blnIsSelected { get; set; }
		public Integer intIndex { get; private set; }

		public AccountWrapper(Account objAcc, Boolean isSelect, Integer indx) {
			objAccount = objAcc;
			blnIsSelected = isSelect;
			intIndex = indx;
		}
	}
}