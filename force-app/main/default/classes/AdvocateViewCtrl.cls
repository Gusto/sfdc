public without sharing class AdvocateViewCtrl {
	public String strCurrentUserId { get; set; }
	private static String strCurrentUserName = UserInfo.getName();
	public List<CustomerCommWrapper> lstCustomerCommWrapper { get; set; }
	public List<TicketWrapper> lstTicketWrapper { get; set; }
	public List<OrderWrapper> lstFinalStageWrapper { get; set; }
	public List<OrderWrapper> lstExceptionRequestOrdersWrapper { get; set; }
	public List<OrderWrapper> lstBlockedCheckListWrapper { get; set; }
	public List<OrderWrapper> lstInternalCommunication { get; set; }
	public List<OrderWrapper> List_AssigntoAdvocateWrapper { get; set; }
	public List<OrderWrapper> lstOrderCohortView { get; set; }
    

	public Order objOrderTemp { get; set; }
	public List<OrderStatWarpper> lstOrderStatsWrapper { get; set; }
	public List<SelectOption> lstOrderStatus { get; set; }
	public List<String> lstSelectedOrderStatus { get; set; } // to get selected Order status
	public boolean IsFacilitator { get; set; }

	public String strCohortReportFilterJson { get; set; } // report filter condition in JSON form
	public String strCohortReportId { get; set; } // report ID for cohort funnel

	public String strBMRReportFilterJson { get; set; } // report filter condition in JSON form
	public String strBMRReportId { get; set; } // report ID for cohort funnel

	public String intComActive { get; set; }
	public String salesComActive { get; set; }

	//Exclude closed Status
	private Set<String> setExcludeStatus = new Set<String>{ 'Closed: Canceled', 'Closed: Payroll Run', 'Activated' };
	private set<String> set_ExcludedOrdersStatuses = new Set<String>{ 'Closed: Canceled', 'Closed: Payroll Run', 'Closed: Duplicate' };
	private set<String> setOrderStats;
    
    private Set<Id> pastDateOrders = new Set<Id>();
     private  Set<Id> futureDateOrders = new Set<Id>();

	/* Dynamic Column Changes */
	// to show all the available column/fields for user to see Key=ObjectName Value = List of selectOption(fieldAPINAme,FieldLabel)
	public Map<String, List<SelectOption>> mapLstAllFields { get; set; }
	// selected columns/fields Key=ObjectName + ViewName  Value = List of APIName of selected fields
	public Map<String, List<String>> mapLstSelectedFields { get; set; }
	// selected columns/fields Key=ObjectName Value = List of all APINAme of fields
	public Map<String, Map<String, String>> mapAllFields { get; set; }

	private Map<String, String> mapObjToQueryFields;
	public String currentObjName { get; set; }
	public String currentView { get; set; }

	public List<SelectOption> lstBMROptions { get; set; }
	public List<SelectOption> lstBMROptionsVal { get; set; }

	public List<String> lstSelectedBMR { get; set; }
	public List<String> lstSelectedBMRVal { get; set; }
	private map<String, String> mapBMRNameId;

	public Boolean isManager { get; set; }
	public List<SelectOption> list_NonManagerUsers { get; set; }
	private map<String, String> map_UserName;

	public List<OrderWrapper> List_OrderOOOWarpper { get; set; }
	public boolean blnFACOOO { get; set; }

	public boolean blnSaveBtnClicked { get; set; }

	private Date date_FirstChkDateOldVal, date_FinalChkDateOldVal;
	public String idSelectedOrder { get; set; }
	public Boolean blnSelectedOrderFlag { get; set; }
	public static final String LABEL_USER_ROLES_PAYROLL_TRANSFER = System.Label.PT_Account_Overview_User_Options;
	public static string GROUP_NAME_PTACCOUNTOVERVIEWMANAGERS = 'PT Account Overview Manager Access';

	//Gets all the active users in a map
	public static Map<Id, User> map_UserIdToUserMap {
		get {
			if (map_UserIdToUserMap == null) {
				map_UserIdToUserMap = GlobalQueryHelper.queryActiveUsers();
			}
			return map_UserIdToUserMap;
		}
		private set;
	}

	public AdvocateViewCtrl() {
		isManager = false;
		blnSelectedOrderFlag = false;
		blnSaveBtnClicked = false;
		//Default value would be logged in user
		strCurrentUserId = UserInfo.getUserId();

		//Get report ID for Cohort Funnel Chart
		for (Report objReport : [SELECT ID, DeveloperName FROM Report WHERE DeveloperName IN ('Advocate_Cohort_Funnel', 'Advocate_BMR_Funnel')]) {
			if (objReport.DeveloperName == 'Advocate_Cohort_Funnel') {
				strCohortReportId = objReport.ID;
			}

			if (objReport.DeveloperName == 'Advocate_BMR_Funnel') {
				strBMRReportId = objReport.ID;
			}
		}

		// To identify the managers with access to PT Account Overview
		isManager = getPTAccountOverviewManagerAccess();
		// To show all active users in pickList whose role is either "Payroll Transfer Fulfillment Team" or the specific Task Us roles mentioned in the label.
		getPTUsersForUIAccess();
	}

	/**
	 * @description Check if user option to be displayed in UI for PT Account Overview page.
	 * @author      Sanjay Paryani
	 * @param       NA
	 * @return      NA
	 **/
	public void getPTUsersForUIAccess() {
		List<String> list_PTUserRoles = new List<String>();
		list_PTUserRoles = LABEL_USER_ROLES_PAYROLL_TRANSFER.split(';');
		list_NonManagerUsers = new List<SelectOption>();
		map_UserName = new Map<String, String>();

		List<String> list_nonManagers = new List<String>();
		for (User objUser : map_UserIdToUserMap.values()) {
			if (list_PTUserRoles.contains(objUser.UserRole.DeveloperName)) {
				map_UserName.put(objUser.Id, objUser.Name);
				list_nonManagers.add(objUser.Name + '~' + objUser.Id);
			}
		}
		list_nonManagers.sort();
		for (String str : list_nonManagers) {
			list_NonManagerUsers.add(new SelectOption(str.split('~')[1], str.split('~')[0]));
		}
	}

	/**
	 * @description Check if the user is added to the PT Account Overview Group for manager level access
	 * @author      Sanjay Paryani
	 * @param       NA
	 * @return      Boolean
	 **/
	public static Boolean getPTAccountOverviewManagerAccess() {
		Set<Id> set_UserIdsFromGroup = new Set<Id>();
		Set<Id> set_RoleIdsFromGroup = new Set<Id>();
		Map<String, Set<Id>> map_AllPTAccountOverviewManagers = new Map<String, Set<Id>>();
		map_AllPTAccountOverviewManagers = GlobalQueryHelper.getGroupMembersByName(GROUP_NAME_PTACCOUNTOVERVIEWMANAGERS);
		if (map_AllPTAccountOverviewManagers != null && map_AllPTAccountOverviewManagers.size() > 0) {
			// This will give you the roles/groups present in the PT group.
			set_RoleIdsFromGroup = map_AllPTAccountOverviewManagers?.get('00G');
			// This will give you the users present in the PT group.
			set_UserIdsFromGroup.addAll(map_AllPTAccountOverviewManagers?.get('005'));
		}

		if (set_UserIdsFromGroup.size() > 0 && set_UserIdsFromGroup.contains(UserInfo.getUserId())) {
			return true;
		} else {
			// This will give you the users present in the roles that are present in a group.
			AggregateResult[] objResult = [
				SELECT COUNT(Id) usercount
				FROM User
				WHERE UserRoleId IN (SELECT RelatedId FROM Group WHERE Type = 'Role' AND Id IN :set_RoleIdsFromGroup) AND Id = :UserInfo.getUserId()
			];
			Object objUserCount = objResult?.get(0).get('usercount');

			if (objUserCount != null && (Integer) objUserCount > 0) {
				return true;
			} else {
				return false;
			}
		}
	}

	//By:AKS, Date:Nov/12/19, Desc: Introduced to resolve Managers not seeing information related to Advo. & facili.
	private void RetriveCurrentUserName() {
		if (map_UserName != null && map_UserName.size() > 0) {
			strCurrentUserName = map_UserName.get(strCurrentUserId);
		}
	}

	//By AKS Dated 28th Oct -  Out of the office Functionality for FAC
	public PageReference CallOnOOOView() {
		blnFACOOO = false;
		RetriveCurrentUserName();
		checkLoggedInUserRole();
		RetriveFacOrders();
		return null;
	}
	//By AKS Dated 28th Oct -  Out of the office Functionality for FAC
	private void RetriveFacOrders() {
		List_OrderOOOWarpper = new List<OrderWrapper>();
		List<Order> List_OrderTemp = [
			SELECT
				ID,
				OrderNumber,
				AccountId,
				Account.Name,
				OOO_Notes__c,
				Reassign_Facilitator_For_OOO__c,
				Status,
				OwnerId,
				Owner.Name,
				Bulk_Migration__c,
				Bulk_Migration__r.Name,
				Facilitator_Due_Date__c
			FROM Order
			WHERE Status NOT IN :set_ExcludedOrdersStatuses AND CheckList_Completed__c = FALSE AND Data_Entry_Assist__c = :strCurrentUserId
			ORDER BY Status ASC
			LIMIT 1000
		];

		if (List_OrderTemp != null && List_OrderTemp.size() > 0) {
			for (Order ord : List_OrderTemp) {
				OrderWrapper ow = new OrderWrapper();
				ow.blnPreviousOOOStage = ord.Reassign_Facilitator_For_OOO__c;
				ow.objOrder = ord;
				if (ord.Facilitator_Due_Date__c != null) {
					ow.strFacDueDate = String.valueOf(ord.Facilitator_Due_Date__c);
				}
				List_OrderOOOWarpper.add(ow);
			}
		}
		if (List_OrderOOOWarpper.size() == 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no order(s) available for assignment'));
		}
	}
	//By AKS Dated 28th Oct -  Out of the office Functionality for FAC
	private void SaveOOO() {
		if (List_OrderOOOWarpper != null && List_OrderOOOWarpper.size() > 0) {
			List<Order> List_OrderUpdate = new List<Order>();
			for (OrderWrapper ow : List_OrderOOOWarpper) {
				if (ow.objOrder.Reassign_Facilitator_For_OOO__c || ow.blnPreviousOOOStage != ow.objOrder.Reassign_Facilitator_For_OOO__c) {
					ow.blnPreviousOOOStage = ow.objOrder.Reassign_Facilitator_For_OOO__c;
					List_OrderUpdate.add(ow.objOrder);
				}
			}

			if (List_OrderUpdate != null && List_OrderUpdate.size() > 0) {
				boolean blnSkipOldval = OrderTriggerHelper.skipTrigger;
				OrderTriggerHelper.skipTrigger = true;
				update List_OrderUpdate;
				OrderTriggerHelper.skipTrigger = blnSkipOldval;
			}
		}
	}
	//By AKS Dated 28th Oct -  Out of the office Functionality for FAC
	public PageReference SaveOOONotes() {
		try {
			SaveOOO();
			Cache.displayErrorMessage('Successfully Saved.', ApexPages.Severity.CONFIRM);
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}
	//By AKS Dated 28th Oct -  Out of the office Functionality for FAC
	public PageReference ReasignBOOnOOO() {
		try {
			SaveOOO();
			//Mark Out of the office
			Boolean blnUserSkipTriger = UserTriggerHelper.skipTrigger;
			UserTriggerHelper.skipTrigger = true;
			User objUser = new User(Id = userinfo.getuserid());
			objUser.Out_Of_Office__c = true;
			objUser.Last_OOO_Modified_Timestamp__c = Datetime.now();
			update objUser;
			UserTriggerHelper.skipTrigger = blnUserSkipTriger;
			blnSaveBtnClicked = true;
			CallOnOOOView();
			Cache.displayErrorMessage('Reassignment is completed.', ApexPages.Severity.CONFIRM);
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	public PageReference CallOnAdvocateActionView() {
		RetriveCurrentUserName();
		checkLoggedInUserRole();
		RetriveCustomerCommunication();
		ShowInternalCom();
		RetriveTickets();
		RetriveOrderData('finalStage');
		RetriveOrderData('exRequest');
		RetriveOrderData('blockedCheckList');
		RetriveOrderData('assignToAdvocate');
		return null;
	}

	public void ShowInternalCom() {
		intComActive = 'active';
		salesComActive = null;
		RetriveInternalAndSalesCommunications('internal');
	}

	public void ShowSalesCom() {
		intComActive = null;
		salesComActive = 'active';
		RetriveInternalAndSalesCommunications('sales');
	}

	public PageReference CallOnAdvocateCohortView() {
		RetriveCurrentUserName();
		checkLoggedInUserRole();
		PopulateOrderStatusList();
		PopulateDate();
		initializeFieldselection('cohort');
		ShowCohortStats();
		RetriveOrderDynamicData('cohort');
		return null;
	}

	//For Dynamic report
	private void createFilterJSON(String strView) {
		strBMRReportFilterJson = null;
		strCohortReportFilterJson = null;
		List<Map<String, Object>> lstFilterJSON = new List<Map<String, Object>>();

		if (!IsFacilitator) {
			Map<String, Object> mapCondition = new Map<String, Object>();
			mapCondition.put('column', 'Order.Order_Owner_Name__c');
			mapCondition.put('operator', 'equals');
			mapCondition.put('value', strCurrentUserName);
			lstFilterJSON.add(mapCondition);
		}
		if (IsFacilitator) {
			Map<String, Object> mapCondition = new Map<String, Object>();
			mapCondition.put('column', 'Order.Data_Entry_Assist__c.Name');
			mapCondition.put('operator', 'equals');
			mapCondition.put('value', strCurrentUserName);
			lstFilterJSON.add(mapCondition);
		}

		if (null != objOrderTemp.First_Check_Date__c) {
			Map<String, Object> mapCondition = new Map<String, Object>();
			mapCondition.put('column', 'Order.First_Check_Date__c');
			mapCondition.put('operator', 'greaterOrEqual');
			mapCondition.put('value', objOrderTemp.First_Check_Date__c);
			lstFilterJSON.add(mapCondition);
		}
		if (null != objOrderTemp.Follow_Up_Date__c) {
			Map<String, Object> mapCondition = new Map<String, Object>();
			mapCondition.put('column', 'Order.First_Check_Date__c');
			mapCondition.put('operator', 'lessOrEqual');
			mapCondition.put('value', objOrderTemp.Follow_Up_Date__c);
			lstFilterJSON.add(mapCondition);
		}
		if (strView == 'BMR' && lstSelectedBMR != null && lstSelectedBMR.size() > 0) {
			Map<String, Object> mapCondition = new Map<String, Object>();
			mapCondition.put('column', 'Order.Bulk_Migration_Name__c');
			mapCondition.put('operator', 'equals');
			String bmrName;
			for (String st : lstSelectedBMR) {
				if (bmrName == null) {
					bmrName = mapBMRNameId.get(st);
				} else {
					bmrName = bmrName + ',' + mapBMRNameId.get(st);
				}
			}
			mapCondition.put('value', bmrName);
			lstFilterJSON.add(mapCondition);
		}

		if (strView == 'cohort') {
			strCohortReportFilterJson = JSON.serialize(lstFilterJSON);
		}
		if (strView == 'BMR' && lstSelectedBMR != null && lstSelectedBMR.size() > 0) {
			strBMRReportFilterJson = JSON.serialize(lstFilterJSON);
		}
	}

	public PageReference CallOnAdvocateBMR_MultiFEINview() {
		RetriveCurrentUserName();
		checkLoggedInUserRole();
		lstSelectedBMR = new List<String>();
		lstSelectedBMRVal = new List<String>();
		PopulateOrderStatusList();
		PopulateDate();
		RetriveBMR(true, true);
		initializeFieldselection('BMR');
		createFilterJSON('BMR');
		RetriveOrderStatData('BMR');
		RetriveBMR(true, false);
		RetriveOrderDynamicData('BMR');
		return null;
	}

	public PageReference ShowCohortStats() {
		createFilterJSON('cohort');
		RetriveOrderStatData('cohort');
		return null;
	}

	public PageReference ShowBMRStats() {
		RetriveBMR(false, true);
		createFilterJSON('BMR');
		RetriveOrderStatData('BMR');
		return null;
	}

	private void RetriveBMR(boolean onPageLoad, boolean forStat) {
		if (forStat) {
			lstBMROptions = new List<SelectOption>();
			mapBMRNameId = new Map<String, String>();
		}
		if (!forStat) {
			lstBMROptionsVal = new List<SelectOption>();
		}
		//get All Open Bulk Migration
		Date dtFromStat = objOrderTemp.First_Check_Date__c;
		Date dtToStat = objOrderTemp.Follow_Up_Date__c;

		Date dtFromOrderDisplay = objOrderTemp.Work_Start_Date__c;
		Date dtToOrderDisplay = objOrderTemp.Requested_Pay_Date__c;

		String strQuery = 'SELECT ID,Name,(SELECT ID FROM Orders__r) FROM Bulk_Migration_Request__c';
		strQuery = strQuery + '  where Bulk_Migration_Status__c!=\'Completed\' AND Requested_First_Check_Date__c!=null';
		if (!IsFacilitator) {
			strQuery = strQuery + ' AND OwnerId=:strCurrentUserId';
		} else {
			strQuery = strQuery + ' AND Facilitator__c=:strCurrentUserId ';
		}
		Boolean bool_StatDateSelectionChanged = false; //@By: ND, Nov 18 2019, To Preselect the BMRs when date selection is changed on BMRView
		if (forStat) {
			strQuery = strQuery + ' AND Requested_First_Check_Date__c>=:dtFromStat AND Requested_First_Check_Date__c<=:dtToStat';

			//@By: ND, Nov 18 2019, To Preselect the BMRs when date selection is changed on BMRView
			//check if date selection is changed? If yes then preselect all BMRs
			if (date_FirstChkDateOldVal != dtFromStat || date_FinalChkDateOldVal != dtToStat) {
				bool_StatDateSelectionChanged = true;
			}

			date_FirstChkDateOldVal = dtFromStat;
			date_FinalChkDateOldVal = dtToStat;
		}
		if (!forStat) {
			strQuery = strQuery + ' AND Requested_First_Check_Date__c>=:dtFromOrderDisplay AND Requested_First_Check_Date__c<=:dtToOrderDisplay';
		}
		strQuery = strQuery + ' ORDER BY Name';

		for (Bulk_Migration_Request__c bmc : Database.Query(strQuery)) {
			//Bind only those BMR where associted order has some value
			if (bmc.Orders__r.size() > 0) {
				if (forStat) {
					lstBMROptions.add(new SelectOption(bmc.Id, bmc.Name));
					mapBMRNameId.put(bmc.Id, bmc.Name);

					//Be default add all
					if (onPageLoad || bool_StatDateSelectionChanged) {
						if (null == lstSelectedBMR)
							lstSelectedBMR = new List<String>();
						lstSelectedBMR.add(bmc.Id);
					}
				}
				if (!forStat) {
					lstBMROptionsVal.add(new SelectOption(bmc.Id, bmc.Name));
					if (onPageLoad) {
						lstSelectedBMRVal.add(bmc.Id);
					}
				}
			}
		}

		//If There is no record found then initiliaze selected List
		if (forStat && lstBMROptions.size() == 0) {
			lstSelectedBMR = new List<String>();
		}
		if (!forStat && lstBMROptionsVal.size() == 0) {
			lstSelectedBMRVal = new List<String>();
		}
	}
	private void checkLoggedInUserRole() {
		IsFacilitator = false;
		blnFACOOO = false;
		for (User_Skill__c us : [
			SELECT Skill__c, Skill__r.Role__r.Name, User_Role__r.User__r.Out_Of_Office__c
			FROM User_Skill__c
			WHERE
				User_Role__r.User__c = :strCurrentUserId
				AND Skill__c != NULL
				AND Skill__r.Role__r.Name != NULL
				AND (Skill__r.Role__r.Name = 'Payroll Transfer Advocate'
				OR Skill__r.Role__r.Name = 'Payroll Transfer Facilitator')
		]) {
			blnFACOOO = us.User_Role__r.User__r.Out_Of_Office__c;
			String strRoleName = us.Skill__r.Role__r.Name;
			//If they have only as a Facilitator role. If it both then it will be treat as non Facilitator
			if (strRoleName.indexOf('Facilitator') > -1 && strRoleName.indexOf('Advocate') == -1) {
				IsFacilitator = true;
			}
		}
		//By AKS Dated 28th Oct -  Out of the office Functionality for FAC
		if (blnFACOOO && !blnSaveBtnClicked) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please update your out of the office status before start working'));
		}
	}

	/*
	 *Create SELECT option List for given object
	 */
	private List<SelectOption> getAllFields(String objectName) {
		List<SelectOption> lstAllFields = new List<SelectOption>();

		if (null != mapAllFields && mapAllFields.size() > 0) {
			if (mapAllFields.containsKey(objectName)) {
				Map<String, String> mapNameLabel = mapAllFields.get(objectName);
				String fieldStr = '';
				for (String fieldAPIName : mapNameLabel.keySet()) {
					lstAllFields.add(new SelectOption(fieldAPIName, mapNameLabel.get(fieldAPIName)));

					fieldStr += fieldAPIName + ',';
				}
				fieldStr += 'ID';
				mapObjToQueryFields.put(objectName, fieldStr);
			}
		}
		return lstAllFields;
	}

	private void initializeFieldselection(String viewType) {
		mapLstAllFields = new Map<String, List<SelectOption>>();
		mapLstSelectedFields = new Map<String, List<String>>();

		mapObjToQueryFields = new Map<String, String>();

		mapAllFields = Cache.getDependentPickListValues(Field_Preference__c.Order_Fields__c);
		mapLstAllFields.put('Order', getAllFields('Order'));

		Map<String, List<String>> mapViewToObject = new Map<String, List<String>>();
		if (viewType == 'cohort') {
			mapViewToObject.put('Adv Cohort', new List<String>{ 'Order' });
		}
		if (viewType == 'BMR') {
			mapViewToObject.put('Adv BMR', new List<String>{ 'Order' });
		}

		if (null != mapViewToObject && mapViewToObject.size() > 0 && mapViewToObject.Values() != null && mapViewToObject.Values().size() > 0) {
			//Fetch field preferences for current user
			List<Field_Preference__c> lstColPref = new List<Field_Preference__c>();

			// All the object names
			Set<String> setObjNames = new Set<String>();
			for (String key : mapViewToObject.keySet()) {
				setObjNames.addAll(mapViewToObject.get(key));
			}

			lstColPref = [
				SELECT ID, Order_Fields__c, Object_Name__c, User__c, View_Name__c
				FROM Field_Preference__c
				WHERE User__c = :strCurrentUserId AND View_Name__c IN :mapViewToObject.keySet() AND Object_Name__c IN :setObjNames
			];

			if (lstColPref.size() > 0) {
				// User Preference is already defined
				for (Field_Preference__c objPref : lstColPref) {
					// set selectedFields List map
					if (!mapLstSelectedFields.containsKey(objPref.View_Name__c + ' ' + objPref.Object_Name__c)) {
						mapLstSelectedFields.put(objPref.View_Name__c + ' ' + objPref.Object_Name__c, objPref.Order_Fields__c.split(';'));
					}
				}
			}
			// Check if for any view+Object conbination, Preference is not defined

			for (String view : mapViewToObject.keySet()) {
				for (String objName : mapViewToObject.get(view)) {
					// set objects map
					Field_Preference__c objPref;
					String objectFields = '';
					if ('Order'.equalsIgnoreCase(objName)) {
						//Default column
						if (viewType == 'cohort') {
							objectFields = 'OrderNumber;Status;Follow_Up_Date__c;Case__c;First_Check_Date__c;Facilitator_Due_Date__c;Payroll_Run_Date__c;Requires_Action__c;Follow_Up_Notes__c;Data_Entry_Assist__c';
						}
						if (viewType == 'BMR') {
							objectFields = 'Bulk_Migration__c;Bulk_Migration__r.Type__c;OrderNumber;Status;Follow_Up_Date__c;Case__c;Facilitator_Due_Date__c;First_Check_Date__c;Requires_Action__c';
						}
					}
					objPref = new Field_Preference__c(User__c = strCurrentUserId, View_Name__c = view, Object_Name__c = objName, Order_Fields__c = objectFields);
					// set selectedFields List map
					if (!mapLstSelectedFields.containsKey(view + ' ' + objName)) {
						mapLstSelectedFields.put(view + ' ' + objName, objectFields.split(';'));
					}
				}
			}
		}
	}
	/* Dynamic Column Changes */

	public PageReference saveCohortPreference() {
		return savePreference('cohort');
	}
	public PageReference saveBMRPreference() {
		return savePreference('BMR');
	}
	private PageReference savePreference(String viewType) {
		try {
			String key = currentView + ' ' + currentObjName;
			if (String.isNotBlank(currentObjName) && String.isNotBlank(currentView) && null != mapLstSelectedFields && mapLstSelectedFields.containsKey(key)) {
				List<String> lstSelectedFields = mapLstSelectedFields.get(currentView + ' ' + currentObjName);
				if (lstSelectedFields.size() == 0) {
					//some fields must be selected
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please SELECT atLeast one column.'));
					return null;
				} else if (lstSelectedFields.size() > 10) {
					//Maximum 10 fields can be selected
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot SELECT more than 10 Columns.'));
					return null;
				}
				Field_Preference__c objColumnPref = new Field_Preference__c();
				//based on preferences make strQuery AND see whether record is exits or not
				List<Field_Preference__c> lstPref = [SELECT Id FROM Field_Preference__c WHERE User__c = :strCurrentUserId AND Object_Name__c = :currentObjName AND View_Name__c = :currentView LIMIT 1];
				if (lstPref != null && lstPref.size() > 0) {
					objColumnPref = new Field_Preference__c(ID = lstPref[0].ID);
				}
				objColumnPref.Object_Name__c = currentObjName;
				objColumnPref.View_Name__c = currentView;
				objColumnPref.User__c = strCurrentUserId;
				//Construct Field_c which has selected values
				objColumnPref.Order_Fields__c = String.join(lstSelectedFields, ';');
				upsert objColumnPref;

				//Initialize All
				initializeFieldselection(viewType);
			}
		} catch (Exception objExcep) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExcep.getMessage()));
			return null;
		}
		return null;
	}

	private void PopulateOrderStatusList() {
		lstSelectedOrderStatus = new List<String>();
		setOrderStats = new Set<String>();
		lstOrderStatus = new List<SelectOption>();
		List<SelectOption> lstOrderTempStatus = Cache.getFieldPickListValues('Order', 'Status');
		if (lstOrderTempStatus != null && lstOrderTempStatus.size() > 0) {
			for (SelectOption status : lstOrderTempStatus) {
				if (!setExcludeStatus.contains(status.getLabel())) {
					lstOrderStatus.add(status);
					setOrderStats.add(status.getValue());
				}
			}
		}
	}

	public PageReference ShowCohortOrders() {
		return RetriveOrderDynamicData('cohort');
	}
	public PageReference ShowBMROrders() {
		RetriveBMR(false, false);
		return RetriveOrderDynamicData('BMR');
	}

	private PageReference RetriveOrderDynamicData(String viewType) {
		try {
			lstOrderCohortView = new List<OrderWrapper>();
			Date dtFirstFrom = objOrderTemp.Work_Start_Date__c;
			Date dtFirstTo = objOrderTemp.Requested_Pay_Date__c;

			Date dtPayrollRunDateFrom = objOrderTemp.Payroll_Run_Date__c;
			Date dtPayrollRunDateTo = objOrderTemp.Account_Approved_Date__c;
			if (dtPayrollRunDateFrom > dtPayrollRunDateTo) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please SELECT a valid Payroll Run date range'));
				return null;
			}
			if (dtFirstFrom > dtFirstTo) {
				if (IsFacilitator) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please SELECT a valid Facilitator Due date range'));
				} else {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please SELECT a valid First Check date range'));
				}
				return null;
			}

			if (viewType == 'BMR' && lstSelectedBMRVal.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please SELECT BMR to show associated orders'));
				return null;
			}

			String strQuery = 'SELECT ';
			strQuery = strQuery + mapObjToQueryFields.get('Order');
			strQuery = strQuery + ' , Account.Name,Case__r.CaseNumber,Bulk_Migration__r.Name,Bulk_Migration__r.Bulk_Case__c,';
			strQuery = strQuery + ' Bulk_Migration__r.Bulk_Case__r.CaseNumber, Bulk_Case__r.CaseNumber,LastModifiedBy.Name,Data_Entry_Assist__r.Name FROM Order WHERE ';
			strQuery = strQuery + ' Status NOT IN :set_ExcludedOrdersStatuses';

			if (!IsFacilitator) {
				strQuery = strQuery + ' AND (Ownerid=:strCurrentUserId OR (Bulk_Migration__c!=null AND Bulk_Migration__r.Ownerid=:strCurrentUserId)) ';
			} else {
				strQuery = strQuery + ' AND (Data_Entry_Assist__c=:strCurrentUserId OR (Bulk_Migration__c!=null AND Bulk_Migration__r.Facilitator__c=:strCurrentUserId))';
			}

			if (viewType == 'cohort') {
				strQuery = strQuery + ' AND Bulk_Migration__c=null';
			}

			if (viewType == 'BMR') {
				strQuery = strQuery + ' AND Bulk_Migration__c in:lstSelectedBMRVal';
			}

			strQuery = strQuery + ' AND RecordType.DeveloperName=\'Company_Migration\' ';
			if (dtFirstFrom != null && dtFirstTo != null) {
				if (IsFacilitator) {
					strQuery = strQuery + ' AND Facilitator_Due_Date__c>=:dtFirstFrom AND Facilitator_Due_Date__c<=:dtFirstTo';
				} else {
					strQuery = strQuery + ' AND First_Check_Date__c>=:dtFirstFrom AND First_Check_Date__c<=:dtFirstTo';
				}
			}
			if (dtPayrollRunDateFrom != null && dtPayrollRunDateTo != null) {
				strQuery = strQuery + ' AND Payroll_Run_Date__c>=:dtPayrollRunDateFrom AND Payroll_Run_Date__c<=:dtPayrollRunDateTo';
			}
			if (lstSelectedOrderStatus != null && lstSelectedOrderStatus.size() > 0) {
				strQuery = strQuery + ' AND Status IN :lstSelectedOrderStatus';
			}

			//@By: AKS, BS, Nov 11 2020, To sort by Payroll Run Date
			strQuery = strQuery + ' ORDER BY Payroll_Run_Date__c LIMIT 1000';

			lstOrderCohortView = PopulateOrderWrapper(Database.Query(strQuery), null);
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}
	private PageReference RetriveOrderStatData(String viewType) {
		try {
			lstOrderStatsWrapper = new List<OrderStatWarpper>();
			Date dtFrom = objOrderTemp.First_Check_Date__c;
			date dtTo = objOrderTemp.Follow_Up_Date__c;
			if (dtFrom > dtTo) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please SELECT a valid First Check date range'));
				return null;
			}
			if (viewType == 'BMR' && lstSelectedBMR.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please SELECT BMR to show Order Stats'));
				return null;
			}

			//if(objOrderTemp.First_Check_Date__c!=null && objOrderTemp.Follow_Up_Date__c!=null){
			map<String, List<Order>> mapStatusListOrder = new Map<String, List<Order>>();

			String strQuery = 'SELECT Id,Status,Account.Name,(SELECT ID, Name,Duration_in_Day_s__c, Order__c,Order__r.OrderNumber, End_Time__c, From_Status__c, Start_Time__c, ';
			strQuery = strQuery + ' To_Status__c,Order__r.Account.Name FROM Order_Status_Change_History__r ORDER BY CreatedDate DESC LIMIT 1) FROM Order WHERE ';
			strQuery = strQuery + ' Status in:setOrderStats AND Status NOT IN :set_ExcludedOrdersStatuses';
			if (!IsFacilitator) {
				strQuery = strQuery + ' AND Ownerid=:strCurrentUserId ';
			} else {
				strQuery = strQuery + ' AND Data_Entry_Assist__c = :strCurrentUserId ';
			}
			if (viewType == 'cohort') {
				strQuery = strQuery + ' AND Bulk_Migration__c=null';
			}
			if (viewType == 'BMR') {
				strQuery = strQuery + ' AND Bulk_Migration__c IN:lstSelectedBMR';
			}
			strQuery = strQuery + ' AND RecordType.DeveloperName=\'Company_Migration\'';
			if (objOrderTemp.First_Check_Date__c != null && objOrderTemp.Follow_Up_Date__c != null) {
				strQuery = strQuery + ' AND First_Check_Date__c>=:dtFrom AND First_Check_Date__c<=:dtTo ';
			}
			strQuery = strQuery + ' ORDER BY Status ';

			for (Order objOrder : Database.Query(strQuery)) {
				if (mapStatusListOrder.containsKey(objOrder.Status)) {
					mapStatusListOrder.get(objOrder.Status).add(objOrder);
				} else {
					mapStatusListOrder.put(objOrder.Status, new List<Order>{ objOrder });
				}
			}
			if (mapStatusListOrder != null && mapStatusListOrder.size() > 0) {
				for (String sts : mapStatusListOrder.keySet()) {
					//Iterate this loop to calculate average
					integer orderCount = 0;
					decimal orderSum = 0;
					decimal avg = 0;
					String oldestOrder = null;
					String oldestOrderName = null;
					String orderAccountName = null;
					decimal noOfOldestdays = 0;
					for (Order bo : mapStatusListOrder.get(sts)) {
						orderCount = orderCount + 1;
						if (bo.Order_Status_Change_History__r != null && bo.Order_Status_Change_History__r.size() > 0) {
							Order_Status_Change_History__c orderHistory = bo.Order_Status_Change_History__r[0];
							if (orderHistory != null) {
								oldestOrder = orderHistory.Order__c;
								orderAccountName = orderHistory.Order__r.Account.Name;
								oldestOrderName = orderHistory.Order__r.OrderNumber;
								noOfOldestdays = orderHistory.Duration_in_Day_s__c;
								orderSum = (orderHistory.Duration_in_Day_s__c != null) ? (orderSum + orderHistory.Duration_In_Day_s__c) : (orderSum + 0);
							}
						}
					}
					if (oldestOrderName != null) {
						avg = (orderSum / orderCount).setScale(2);
						OrderStatWarpper bp = new OrderStatWarpper();
						bp.strOrderStatus = sts;
						bp.strNumberOfOrder = orderCount;
						bp.strAverage = String.valueof(avg);
						bp.strOldestOrderId = oldestOrder;
						bp.strOldestOrderName = oldestOrderName;
						bp.oldestNoOfday = noOfOldestdays;
						bp.strAccountName = orderAccountName;
						lstOrderStatsWrapper.add(bp);
					}
				}
			} else {
				String message = 'Order Stats table is not available for the selected First Check Date range';
				if (viewType == 'BMR') {
					message = 'BMR Stats table is not available for the selected First Check Date range';
				}
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, message);
				ApexPages.addMessage(myMsg);
				return null;
			}
			/*}else{
                 ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'Please SELECT First Check in Date to show Stats');
                ApexPages.addMessage(myMsg);
                return null;
            }*/
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	//***Start Internal Customer***/
	private void RetriveInternalAndSalesCommunications(String comType) {
		lstInternalCommunication = new List<OrderWrapper>();
		Set<ID> setFacilitatorId = new Set<ID>();
		Map<ID, Id> mapCheckListOrderId = new Map<ID, Id>();
		//In case of internal communication
		if (comType == 'internal') {
			//get All related Facilitator
			String strQuery = 'SELECT Id,Order__c,Order__r.Account.Name,Order__r.Account.ZP_Company_ID__c,Order__r.Communication_Required__c,Order__r.Communication_Required_Fac__c,Order__r.ownerId,Order__r.Data_Entry_Assist__c FROM Order_Facilitator_CheckList__c ';
			strQuery = strQuery + ' WHERE  Order__r.RecordType.DeveloperName=\'Company_Migration\' ';
            strQuery = strQuery + getOrderDateFilter();

			ID idLoggedInUser = (ID) strCurrentUserId;
			//@Neha 8th April 2020, Add Communication Required field based on whether logged in user is Facilitator or Advocate
			if (!IsFacilitator) {
				strQuery = strQuery + ' AND Order__r.Communication_Required__c=true AND Order__r.ownerId=:idLoggedInUser';
			} else {
				strQuery = strQuery + ' AND Order__r.Communication_Required_Fac__c=true AND Order__r.Data_Entry_Assist__c=:idLoggedInUser';
			}
			for (Order_Facilitator_CheckList__c fc : Database.Query(strQuery)) {
				mapCheckListOrderId.put(fc.Id, fc.Order__c);
				if (!IsFacilitator) {
					if (fc.Order__r.Data_Entry_Assist__c != null) {
						setFacilitatorId.add(fc.Order__r.Data_Entry_Assist__c);
					}
				} else {
					setFacilitatorId.add(fc.Order__r.ownerId);
				}
			}
		}
		//For Sales Communication
		if (comType == 'sales') {
			//get All related Facilitator
			String strQuery = 'SELECT Id,ownerId,Data_Entry_Assist__c FROM Order  ';
			strQuery = strQuery + ' WHERE  RecordType.DeveloperName=\'Company_Migration\'';
			strQuery = strQuery + getOrderDateFilterOrderQuery();
			if (!IsFacilitator) {
				strQuery = strQuery + ' AND OwnerId=:strCurrentUserId';
			} else {
				strQuery = strQuery + 'AND Data_Entry_Assist__c=:strCurrentUserId';
			}
			//Commented by AKs dated 3rd Nov 2020 all logic have been moved on Due date
			//strQuery = strQuery + ' ORDER BY Payroll_Run_Date__c ASC limit 1000 ';
			strQuery = strQuery + ' ORDER BY Facilitator_Due_Date__c ASC LIMIT 1000 ';

			for (Order od : Database.Query(strQuery)) {
				//Just to resue same code in every case
				mapCheckListOrderId.put(od.Id, od.Id);
				if (!IsFacilitator) {
					if (od.Data_Entry_Assist__c != null) {
						setFacilitatorId.add(od.Data_Entry_Assist__c);
					}
				} else {
					setFacilitatorId.add(od.ownerId);
				}
			}
		}

		//get latest comment
		if (mapCheckListOrderId != null && mapCheckListOrderId.size() > 0) {
			map<ID, DateTime> mapOrderRecentComment = new Map<ID, DateTime>();
			//strCurrentUserName='Ashveej Shivashankar'; //need to remove after testing
			//This we have created because for every parent we need to get latest comment
			//Check in feed
			set<ID> setAlreadyFeedItemAdded = new Set<ID>();
			set<Id> setParentId = mapCheckListOrderId.keySet();
			String feedItemQuery = 'SELECT Id,Body,createddate,Type,parentid FROM FeedItem where type=\'TextPost\' AND ParentId in:setParentId ';
			if (comType == 'internal') {
				feedItemQuery = feedItemQuery + ' AND InsertedById in:setFacilitatorId';
			}
			feedItemQuery = feedItemQuery + ' ORDER BY createddate DESC ';

			for (FeedItem fc : Database.Query(feedItemQuery)) {
				if (!setAlreadyFeedItemAdded.contains(fc.ParentId)) {
					if (String.isNotBlank(fc.Body) && String.valueof(fc.Body).indexOf(strCurrentUserName) > -1) {
						mapOrderRecentComment.put(mapCheckListOrderId.get(fc.ParentId), fc.createddate);
					}
					setAlreadyFeedItemAdded.add(fc.ParentId);
				}
			}
			//Check in feed Comment
			set<ID> setAlreadyFeedCommentAdded = new Set<ID>();
			String strFeedCommentQuery = 'SELECT ID,ParentId,createddate,CommentBody,InsertedById FROM FeedComment ';
			strFeedCommentQuery = strFeedCommentQuery + ' where ParentId in:setParentId  AND CommentType=\'TextComment\' ';
			if (comType == 'internal') {
				strFeedCommentQuery = strFeedCommentQuery + ' AND InsertedById in:setFacilitatorId';
			}
			strFeedCommentQuery = strFeedCommentQuery + ' ORDER BY createddate DESC ';

			for (FeedComment fc : Database.Query(strFeedCommentQuery)) {
				if (!setAlreadyFeedCommentAdded.contains(fc.ParentId)) {
					if (String.valueof(fc.CommentBody).indexOf(strCurrentUserName) > -1) {
						mapOrderRecentComment.put(mapCheckListOrderId.get(fc.ParentId), fc.createddate);
					}
					setAlreadyFeedCommentAdded.add(fc.ParentId);
				}
			}
			if (mapOrderRecentComment != null && mapOrderRecentComment.size() > 0) {
				//@Neha 8th April 2020, Add Communication Required field for Facilitator
				for (Order ord : [
					SELECT
						Facilitator_Due_Date__c,
						Communication_Required__c,
						Communication_Required_Fac__c,
						Account.name,
						OwnerId,
						Owner.Name,
						Account.ZP_Company_ID__c,
						Type,
						Status,
						ID,
						OrderNumber,
						Bulk_Migration__c,
						Bulk_Migration__r.Name,
						Payroll_Run_Date__c,
						Data_Entry_Assist__c,
						Data_Entry_Assist__r.Name
					FROM Order
					WHERE Id IN :mapOrderRecentComment.keySet()
				]) {
					integer nod = 0;
					Datetime recentComment = mapOrderRecentComment.get(ord.Id);
					if (recentComment != null) {
						nod = getNoOfdays(recentComment, System.now());
						if (nod < 0) {
							nod = 0;
						}
					}
					//In case of sales comments should be within 7 days
					if (comType == 'internal' || (comType == 'sales' && nod <= 7)) {
						OrderWrapper cw = new OrderWrapper();
						cw.objOrder = ord;
						cw.strRunDateFormat = String.valueOf(ord.Payroll_Run_Date__c);
						if (ord.Facilitator_Due_Date__c != null) {
							cw.strDueDateFormat = String.valueOf(ord.Facilitator_Due_Date__c);
						}
						cw.noc = nod;
						lstInternalCommunication.add(cw);
					}
				}
			}
		}
	}
	public PageReference updateInternalCommRequire() {
		String strOrderId = ApexPages.CurrentPage().getparameters().get('strOrderId');
		if (lstInternalCommunication != null && lstInternalCommunication.size() > 0) {
			List<Order> lstOrder = new List<Order>();
			for (OrderWrapper cw : lstInternalCommunication) {
				if (strOrderId != null && strOrderId == cw.objOrder.ID) {
					Order objO = new Order(ID = strOrderId);

					//@Neha 8th April 2020, Update Communication Required field based on whether logged in user is Fac or Advocate
					if (!IsFacilitator) {
						objO.Communication_Required__c = false;
					} else {
						objO.Communication_Required_Fac__c = false;
					}
					lstOrder.add(objO);
				}
			}
			if (lstOrder != null && lstOrder.size() > 0) {
				OrderTriggerHelper.skipTrigger = true;
				update lstOrder;
			}
		}
		RetriveInternalAndSalesCommunications('internal');
		return null;
	}

	//***Start Account in Final Stages ***//
	private void RetriveOrderData(String tableType) {
		try {
            
        /*String strOrderQuery = 'SELECT Id, First_Check_Date__c FROM Order WHERE Id IN (SELECT Order__c FROM Case WHERE RecordType.DeveloperName=\'Payroll_Transfer_Case\')';
        Map<Id, Date> orderDateMap = new Map<Id, Date>();

        for (Order ord : Database.query(strOrderQuery)) {
            orderDateMap.put(ord.Id, ord.First_Check_Date__c);
        }

        Set<Id> pastDateOrders = new Set<Id>();
        Set<Id> futureDateOrders = new Set<Id>();
        Date today = Date.today();

        for (Id orderId : orderDateMap.keySet()) {
            Date firstCheckDate = orderDateMap.get(orderId);
            system.debug('firstCheckDate' + firstCheckDate);
            if (firstCheckDate != null && firstCheckDate > today) {
                system.debug('1002');
                futureDateOrders.add(orderId); 
            } else {
                pastDateOrders.add(orderId);
            }
        }*/
            
			String strQuery = 'SELECT Id,CheckList_Completed__c,Last_Assigned_to_Advocate__c,CheckList_Status__c,';
			strQuery = strQuery + ' OwnerId,Owner.Name,AccountId,Transition_to_Fulfillment__c,Account.name,Account.ZP_Company_ID__c,Type,Status,OrderNumber,Name,Follow_Up_Date__c,';
			strQuery = strQuery + ' Follow_Up_Notes__c,Facilitator_Follow_Up_Date__c, Facilitator_Follow_Up_Notes__c,Case__c,Case__r.CaseNumber,Bulk_Migration__c,Bulk_Migration__r.Name,';
			strQuery = strQuery + ' Facilitator_Due_Date__c,Payroll_Run_Date__c,First_Check_Date__c, Requires_Action__c,Data_Entry_Assist__c,LastModifiedDate, ';
			if (tableType == 'blockedCheckList' || tableType == 'assignToAdvocate') {
				strQuery =
					strQuery + ' (SELECT ID, Is_Blocked__c,Blocked_Timestamp__c,LastModifiedDate FROM Order_Facilitator_CheckLists__r WHERE Is_Blocked__c =true ORDER BY Blocked_Timestamp__c ASC ),';
			}
			strQuery = strQuery + ' Data_Entry_Assist__r.Name,Account_Approved_Date__c FROM Order WHERE OrderNumber!=null AND RecordType.DeveloperName=\'Company_Migration\'';

			if (!IsFacilitator) {
				strQuery = strQuery + ' AND OwnerId=:strCurrentUserId';
			} else {
				strQuery = strQuery + 'AND Data_Entry_Assist__c=:strCurrentUserId';
			}

			if (tableType == 'finalStage') {
				strQuery = strQuery + '  AND ( Status=\'Onboarding Steps 8 - 9\' or Status=\'Onboarding Step 10\') AND Days_in_steps_8_to_10__c<=3';
			}
			if (tableType == 'exRequest') {
				strQuery = strQuery + getOrderDateFilterOrderQuery();
				strQuery = strQuery + '  AND Transition_to_Fulfillment__r.RecordType.DeveloperName=\'Payroll_Transfer\'';
				strQuery = strQuery + '   AND Transition_to_Fulfillment__r.TTF_Status__c=\'PT Approved\' AND ';
				//strQuery = strQuery + '   Transition_to_Fulfillment__r.Exception_Request__c=\'Yes\'';
				strQuery = strQuery + '   Exception_Request__c=true';
			}
			if (tableType == 'blockedCheckList') {
				strQuery = strQuery + getOrderDateFilterOrderQuery();
				strQuery = strQuery + '  AND ID in (SELECT Order__c FROM Order_Facilitator_CheckList__c WHERE Is_Blocked__c=true)';
			}
			if (tableType == 'assignToAdvocate') {
				strQuery = strQuery + getOrderDateFilterOrderQuery();
				strQuery = strQuery + '  AND Assign_to_Advocate__c=true AND CheckList_Completed__c=false';
			}

			//Commented aby AKS dated 3rd Nov 20202 because all logic have been moved on Fac Due date
			//strQuery = strQuery + ' ORDER BY Payroll_Run_Date__c ASC limit 1000';
			strQuery = strQuery + ' ORDER BY Facilitator_Due_Date__c ASC LIMIT 1000';

			if (tableType == 'finalStage') {
				lstFinalStageWrapper = new List<OrderWrapper>();
				lstFinalStageWrapper = PopulateOrderWrapper(Database.Query(strQuery), tableType);
			}
			if (tableType == 'exRequest') {
				lstExceptionRequestOrdersWrapper = new List<OrderWrapper>();
				lstExceptionRequestOrdersWrapper = PopulateOrderWrapper(Database.Query(strQuery), tableType);
			}
			if (tableType == 'blockedCheckList') {
				lstBlockedCheckListWrapper = new List<OrderWrapper>();
				lstBlockedCheckListWrapper = PopulateOrderWrapper(Database.Query(strQuery), tableType);
			}
			//Added by AKS dated 3rd Nov 2020
			if (tableType == 'assignToAdvocate') {
				List_AssigntoAdvocateWrapper = new List<OrderWrapper>();
				List_AssigntoAdvocateWrapper = PopulateOrderWrapper(Database.Query(strQuery), tableType);
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
	}

	private List<OrderWrapper> PopulateOrderWrapper(List<Order> lstOrder, String tableType) {
		List<OrderWrapper> tempWrap = new List<OrderWrapper>();
		for (Order objOrder : lstOrder) {
			OrderWrapper cw = new OrderWrapper();
			cw.objOrder = objOrder;
			cw.strRunDateFormat = String.valueOf(objOrder.Payroll_Run_Date__c);
			cw.strDueDateFormat = String.valueOf(objOrder.Facilitator_Due_Date__c);
			cw.strFirstCheckDateFormat = String.valueOf(objOrder.First_Check_Date__c);
			cw.strLastModifiedDate = String.valueOf(date.newinstance(objOrder.LastModifiedDate.year(), objOrder.LastModifiedDate.month(), objOrder.LastModifiedDate.day()));
			cw.strFollowUpDate = String.valueOf(objOrder.Follow_Up_Date__c);
			cw.strAccountApprovedDate = String.valueOf(objOrder.Account_Approved_Date__c);
			cw.strFacilitatorFollowUp = String.valueOf(objOrder.Facilitator_Follow_Up_Date__c);
			cw.noc = 0;
			cw.daySince = 0;
			if (tableType == 'blockedCheckList' || tableType == 'assignToAdvocate') {
				cw.noc = objOrder.Order_Facilitator_CheckLists__r.size();
				//In case of blocked CheckList
				if (tableType == 'blockedCheckList') {
					if (cw.noc > 0) {
						cw.daySince = getNoOfdays(objOrder.Order_Facilitator_CheckLists__r[0].Blocked_Timestamp__c, system.now());
					}
				}
				if (tableType == 'assignToAdvocate') {
					cw.daySince = getNoOfdays(objOrder.Last_Assigned_to_Advocate__c, system.now());
				}
			}
			tempWrap.add(cw);
		}
		return tempWrap;
	}
	//***End Account in Final Stages ***//

	//**Customer Communication Start***//
	/*public PageReference RetriveCustomerCommunication() {
    try {
        lstCustomerCommWrapper = new List<CustomerCommWrapper>();
        
        // Fetch Orders to check First_Check_Date__c
        String strOrderQuery = 'SELECT Id, First_Check_Date__c FROM Order WHERE Id IN (SELECT Order__c FROM Case WHERE RecordType.DeveloperName=\'Payroll_Transfer_Case\')';
        Map<Id, Date> orderDateMap = new Map<Id, Date>();

        for (Order ord : Database.query(strOrderQuery)) {
            orderDateMap.put(ord.Id, ord.First_Check_Date__c);
        }

        // Build query dynamically
        String strQuery = 'SELECT Id, CaseNumber, ContactId, Requires_Action__c, Contact.Name, AccountId, Account.Name, Account.ZP_Company_ID__c,';
        strQuery += ' Order__c, Order__r.OrderNumber, Order__r.Status, Order__r.Facilitator_Due_Date__c, Order__r.Payroll_Run_Date__c, Order__r.Bulk_Migration__c,';
        strQuery += ' Order__r.Bulk_Migration__r.Name, Incoming_Email_Received_Date__c, Incoming_Email_Received__c FROM Case WHERE ';
        strQuery += ' RecordType.DeveloperName=\'Payroll_Transfer_Case\' AND Type!=\'Document Mapping\' ';
        strQuery += ' AND ContactId!=null AND Requires_Action__c=true ';
        strQuery += ' AND ownerId=:strCurrentUserId';

        // Prepare list of order Ids whose First_Check_Date__c is in the past
        Set<Id> pastDateOrders = new Set<Id>();
        Date today = Date.today();

        for (Id orderId : orderDateMap.keySet()) {
            if (orderDateMap.get(orderId) != null && orderDateMap.get(orderId) <= today) {
                pastDateOrders.add(orderId);
            }
        }

        // Apply status check only for past-date orders
        if (!pastDateOrders.isEmpty()) {
            strQuery += ' AND (Order__r.First_Check_Date__c = NULL OR Order__c IN :pastDateOrders)';
            strQuery += ' AND Order__r.Status NOT IN :set_ExcludedOrdersStatuses';
        }

        strQuery += ' ORDER BY Incoming_Email_Received_Date__c ASC LIMIT 1000';

        lstCustomerCommWrapper.addAll(PopulateCommunicationWrapper(Database.Query(strQuery)));

    } catch (Exception e) {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
    }
    return null;
}*/
     public PageReference RetriveCustomerCommunication() {
    try {
        lstCustomerCommWrapper = new List<CustomerCommWrapper>();
		/*String strOrderQuery = 'SELECT Id, First_Check_Date__c FROM Order WHERE Id IN (SELECT Order__c FROM Case WHERE RecordType.DeveloperName=\'Payroll_Transfer_Case\')';
        Map<Id, Date> orderDateMap = new Map<Id, Date>();

        for (Order ord : Database.query(strOrderQuery)) {
            orderDateMap.put(ord.Id, ord.First_Check_Date__c);
        }

        Set<Id> pastDateOrders = new Set<Id>();
        Set<Id> futureDateOrders = new Set<Id>();
        Date today = Date.today();

        for (Id orderId : orderDateMap.keySet()) {
            Date firstCheckDate = orderDateMap.get(orderId);
            system.debug('firstCheckDate' + firstCheckDate);
            if (firstCheckDate != null && firstCheckDate > today) {
                system.debug('1117');
                futureDateOrders.add(orderId); 
            } else {
                pastDateOrders.add(orderId);
            }
        }*/

        String strQuery = 'SELECT Id, CaseNumber, ContactId, Requires_Action__c, Contact.Name, AccountId, Account.Name, Account.ZP_Company_ID__c,';
        strQuery += ' Order__c, Order__r.OrderNumber, Order__r.Status, Order__r.First_Check_Date__c, Order__r.Facilitator_Due_Date__c,';
        strQuery += ' Order__r.Payroll_Run_Date__c, Order__r.Bulk_Migration__c, Order__r.Bulk_Migration__r.Name,';
        strQuery += ' Incoming_Email_Received_Date__c, Incoming_Email_Received__c FROM Case WHERE ';
        strQuery += ' RecordType.DeveloperName=\'Payroll_Transfer_Case\' AND Type!=\'Document Mapping\' ';
        strQuery += ' AND ContactId!=null AND Requires_Action__c=true ';
        strQuery += ' AND ownerId=:strCurrentUserId';
		strQuery += getOrderDateFilter();
        /*if (!pastDateOrders.isEmpty() && !futureDateOrders.isEmpty()) {
            strQuery += ' AND ( Order__c IN :futureDateOrders ';
            strQuery += ' OR (Order__c IN :pastDateOrders AND Order__r.Status NOT IN :set_ExcludedOrdersStatuses) )';
        }
        
        else if (!pastDateOrders.isEmpty()) {
            system.debug('1139');
            strQuery += ' AND Order__c IN :pastDateOrders AND Order__r.Status NOT IN :set_ExcludedOrdersStatuses';
        }else if (!futureDateOrders.isEmpty()) {
            system.debug('1141');
            strQuery += ' AND Order__c IN :futureDateOrders';
        }*/

        strQuery += ' ORDER BY Incoming_Email_Received_Date__c ASC LIMIT 1000';

        System.debug('Final Query: ' + strQuery);
        lstCustomerCommWrapper.addAll(PopulateCommunicationWrapper(Database.Query(strQuery)));
		system.debug('lstCustomerCommWrapper' +  lstCustomerCommWrapper);
    } catch (Exception e) {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
        System.debug('Error: ' + e.getMessage());
    }
    return null;
}

	private List<CustomerCommWrapper> PopulateCommunicationWrapper(List<Case> lstCase) {
		List<CustomerCommWrapper> tempWrap = new List<CustomerCommWrapper>();
		for (Case objCase : lstCase) {
			integer nod = 0;
			if (objCase.Incoming_Email_Received_Date__c != null) {
				nod = getNoOfdays(objCase.Incoming_Email_Received_Date__c, System.now());
				if (nod < 0) {
					nod = 0;
				}
			}
			CustomerCommWrapper cw = new CustomerCommWrapper();
			cw.objCase = objCase;
			cw.intDaySinceLastReceived = nod;
			cw.strRunDate = String.valueOf(objCase.order__r.Payroll_Run_Date__c);
			cw.strDueDate = String.valueOf(objCase.order__r.Facilitator_Due_Date__c);
			tempWrap.add(cw);
		}
		return tempWrap;
	}
	public PageReference updateRequireStatus() {
		String strCaseId = ApexPages.CurrentPage().getparameters().get('strCaseId');
		if (lstCustomerCommWrapper != null && lstCustomerCommWrapper.size() > 0) {
			List<Case> lstCase = new List<Case>();
			for (CustomerCommWrapper cw : lstCustomerCommWrapper) {
				if (strCaseId != null && strCaseId == cw.objCase.ID) {
					Case objCase = new Case(ID = strCaseId);
					objCase.Requires_Action__c = false;
					lstCase.add(objCase);
				}
			}
			if (lstCase != null && lstCase.size() > 0) {
				CaseTriggerHelper.skipTrigger = true;
				update lstCase;
			}
		}
		RetriveCustomerCommunication();
		return null;
	}

	//**Customer Communication End***//
	//**Ticket Start**//
	private void RetriveTickets() {
		try {
			Configuration_Settings__c configRec = Configuration_Settings__c.getOrgDefaults();

			lstTicketWrapper = new List<TicketWrapper>();
			//In case of tikcet show  all ticket where created by logged in user. Owner can be any one
			String strQuery = 'SELECT Id,Account__c,Account__r.name,Status__c,Order__c,Order__r.OrderNumber,Order__r.Account.Name, ';
			strQuery = strQuery + ' Order__r.Facilitator_Due_Date__c,Order__r.Bulk_Migration__c,RecordTypeId,RecordType.Name,Createddate,LastModifieddate,';
			strQuery = strQuery + ' Order__r.Bulk_Migration__r.Name,Escalation_Reason__c,Escalation_Reason_Detail__c,Name,';
			strQuery = strQuery + ' Description__c, Reporting_Team__c FROM Ticket__c where ';
			strQuery = strQuery + '  (RecordType.DeveloperName=\'Payroll_Sales_Escalation\' or RecordType.DeveloperName=\'Risk_Assurance\')';
			strQuery = strQuery + ' AND CreatedById=:strCurrentUserId AND Status__c!=\'Closed\' AND Status__c!=\'Complete\' ';
			if (configRec.Payroll_Transfer_Ticket_Created_Days__c != null && configRec.Payroll_Transfer_Ticket_Created_Days__c > 0) {
				dateTime nDaysOld = System.now().addDays(-integer.valueOf(configRec.Payroll_Transfer_Ticket_Created_Days__c));
				strQuery = strQuery + ' AND CreatedDate >: nDaysOld ';
			}
			strQuery = strQuery + ' ORDER BY Createddate ASC limit 1000';

			for (Ticket__c objTicket : Database.Query(strQuery)) {
				integer nod = 0;
				if (objTicket.Createddate != null) {
					nod = getNoOfdays(objTicket.Createddate, system.now());
					if (nod < 0) {
						nod = 0;
					}
				}
				TicketWrapper cw = new TicketWrapper();
				cw.objTicket = objTicket;
				cw.intDaySinceLastCreated = nod;
				lstTicketWrapper.add(cw);
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
	}

	private integer getNoOfdays(Datetime dFrom, Datetime dTo) {
		integer nod = 0;
		if (dFrom != null && dTo != null) {
			Date fromDate = date.newinstance(dFrom.year(), dFrom.month(), dFrom.day());
			Date toDate = date.newinstance(dTo.year(), dTo.month(), dTo.day());
			nod = fromDate.daysBetween(toDate);
		}

		return nod;
	}

	//For Customer Communication
	public class CustomerCommWrapper {
		public integer intDaySinceLastReceived { get; set; }
		public String strRunDate { get; set; }
		//Added by AKS dated 2nd Nov for Due date
		public String strDueDate { get; set; }
		public Case objCase { get; set; }
	}

	//For Tickets
	public class TicketWrapper {
		public integer intDaySinceLastCreated { get; set; }
		public Ticket__c objTicket { get; set; }
	}

	//For Orders
	public class OrderWrapper {
		public Order objOrder { get; set; }
		public integer noc { get; set; }
		public integer daySince { get; set; }
		public String strRunDateFormat { get; set; }
		//Added by AKS dated 2nd Nov for Due date
		public String strDueDateFormat { get; set; }
		public String strFirstCheckDateFormat { get; set; }
		public String strLastModifiedDate { get; set; }
		public String strFollowUpDate { get; set; }
		public String strAccountApprovedDate { get; set; }
		public String strFacilitatorFollowUp { get; set; }
		public Boolean blnPreviousOOOStage { get; set; }
		public String strFacDueDate { get; set; }
	}

	//For Stat
	public class OrderStatWarpper {
		public String strOrderStatus { get; set; }
		public integer strNumberOfOrder { get; set; }
		public decimal oldestNoOfday { get; set; }
		public String strAverage { get; set; }
		public String strOldestOrderId { get; set; }
		public String strOldestOrderName { get; set; }
		public String strAccountName { get; set; }
	}

	private void PopulateDate() {
		objOrderTemp = new Order();
	}

	//[BS: 24 Nov 2020] BMR OOO logic.
	public void selectBMRRecord() {
		ID idSelectedOrderBMR = null;
		String strOOONotes = '';
		if (String.isNotBlank(idSelectedOrder)) {
			//Get selected Order related values. Eg: BMR ID AND Notes.
			for (OrderWrapper objOW : List_OrderOOOWarpper) {
				if (objOW.objOrder.ID == idSelectedOrder) {
					idSelectedOrderBMR = objOW.objOrder.Bulk_Migration__c;
					strOOONotes = objOW.objOrder.OOO_Notes__c;
				}
			}
			//Sync All the BRM, related selected order.
			for (OrderWrapper objOW : List_OrderOOOWarpper) {
				if (objOW.objOrder.Bulk_Migration__c == idSelectedOrderBMR) {
					objOW.objOrder.Reassign_Facilitator_For_OOO__c = blnSelectedOrderFlag;
					if (String.isNotBlank(strOOONotes) && String.isBlank(objOW.objOrder.OOO_Notes__c)) {
						objOW.objOrder.OOO_Notes__c = strOOONotes;
					}
				}
			}
		}
	}
     private String getOrderDateFilter() {
    	String filter = '';
        String strOrderQuery = 'SELECT Id, First_Check_Date__c, Status,Case__c FROM Order WHERE Case__c IN (SELECT id FROM Case WHERE RecordType.DeveloperName=\'Payroll_Transfer_Case\')';
        Map<Id, Date> orderDateMap = new Map<Id, Date>();

        for (Order ord : Database.query(strOrderQuery)) {
            orderDateMap.put(ord.Id, ord.First_Check_Date__c);
        }

        //Set<Id> pastDateOrders = new Set<Id>();
        //Set<Id> futureDateOrders = new Set<Id>();
        Date today = Date.today();

        for (Id orderId : orderDateMap.keySet()) {
            Date firstCheckDate = orderDateMap.get(orderId);
            system.debug('firstCheckDate' + firstCheckDate);
            if (firstCheckDate != null && firstCheckDate > today) {
                system.debug('1117');
                futureDateOrders.add(orderId); 
            } else {
                pastDateOrders.add(orderId);
            }
        }

    if (!pastDateOrders.isEmpty() && !futureDateOrders.isEmpty()) {
        filter += ' AND (Order__c IN :futureDateOrders ';
        filter += ' OR (Order__c IN :pastDateOrders AND Order__r.Status NOT IN :set_ExcludedOrdersStatuses) )';
    } else if (!pastDateOrders.isEmpty()) {
        filter += ' AND Order__c IN :pastDateOrders AND Order__r.Status NOT IN :set_ExcludedOrdersStatuses';
    } else if (!futureDateOrders.isEmpty()) {
        filter += ' AND Order__c IN :futureDateOrders';
    }
	system.debug('filter' + filter);
    return filter;
}
    
    private String getOrderDateFilterOrderQuery() {
    String filter = '';
        String strOrderQuery = 'SELECT Id, First_Check_Date__c, Status,Case__c FROM Order WHERE Case__c IN (SELECT id FROM Case WHERE RecordType.DeveloperName=\'Payroll_Transfer_Case\')';
        Map<Id, Date> orderDateMap = new Map<Id, Date>();

        for (Order ord : Database.query(strOrderQuery)) {
            orderDateMap.put(ord.Id, ord.First_Check_Date__c);
        }

        //Set<Id> pastDateOrders = new Set<Id>();
        //Set<Id> futureDateOrders = new Set<Id>();
        Date today = Date.today();

        for (Id orderId : orderDateMap.keySet()) {
            Date firstCheckDate = orderDateMap.get(orderId);
            system.debug('firstCheckDate' + firstCheckDate);
            if (firstCheckDate != null && firstCheckDate > today) {
                system.debug('1117');
                futureDateOrders.add(orderId); 
            } else {
                pastDateOrders.add(orderId);
            }
        }

    if (!pastDateOrders.isEmpty() && !futureDateOrders.isEmpty()) {
        filter += ' AND (Id IN :futureDateOrders ';
        filter += ' OR (Id IN :pastDateOrders AND Status NOT IN :set_ExcludedOrdersStatuses) )';
    } else if (!pastDateOrders.isEmpty()) {
        filter += ' AND Id IN :pastDateOrders AND Status NOT IN :set_ExcludedOrdersStatuses';
    } else if (!futureDateOrders.isEmpty()) {
        filter += ' AND Id IN :futureDateOrders';
    }
	system.debug('filter' + filter);
    return filter;
}
}