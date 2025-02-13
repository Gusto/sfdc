/*
 * Created On   :   23 September 2019
 * Description  :   1) Controller for creating and editing OrderFacilitatorChecklist records for Advocate
 *                  2) Facilitator can update the checklist based on checklist progress and add comments
 *                  3) Advocate can also add comments to checklist
 */
public without sharing class CreateEditOrderFacilitatorChecklistCtrl {
	private Id idOrder; // Associated Order Object
	public Order objOrder { get; private set; }
	public List<OrderChecklistWrapper> lstOrderChklstWrapper { get; set; }
	public Id idloggedInUser { get; private set; }
	public Boolean isAuthUser { get; private set; }
	public Boolean isDelegatedAdvocate { get; private set; }
	private Set<Id> setDelegatedAdvocates;
	public Integer intIndxToBeRemoved { get; set; } // Index of checklist element that has to be removed
	public Boolean bool_IsNewChkToBeRemoved { get; set; } // set to Yes if checklist entity to be removed is a new record, otherwise No.
	public static final String BLOCKED_REASON_1 = 'Blocked';
	public List<Order_Facilitator_Checklist__c> lstOrderFacilitatorChkLst { get; private set; }
	private Map<String, Order_Facilitator_Checklist__c> mapMasterToOrderChecklist;
	public List<OrderChecklistWrapper> lstNewOrderChk { get; set; }
	public boolean selectAll { get; set; }

	public Boolean bool_CopyButtonVisible { get; set; } // true if there is a BMR associated and checklists are being created for the first time

	private List<Order_Facilitator_Checklist__c> lstChecklistToUpsert;
	public Boolean blnAllCheckListCompleted { get; set; }
	public Boolean blnAssignToFacilitator { get; set; }
	public Boolean blnAssignToAdvocate { get; set; }
	public Order objFollowUpOrder { get; private set; }
	public Set<String> set_CompanyId { get; set; }
	public List<ZP_Company_Onboarding_Funnel__c> list_RelatedZPCOFRecords = new List<ZP_Company_Onboarding_Funnel__c>();
	public List<Order> list_BMROrders = new List<Order>();
	/*Constructor*/
	public CreateEditOrderFacilitatorChecklistCtrl(ApexPages.StandardController stdCtrl) {
		blnAllCheckListCompleted = false;
		blnAssignToFacilitator = false;
		blnAssignToAdvocate = false;
		objFollowUpOrder = new Order();
		set_CompanyId = new Set<String>();
		list_RelatedZPCOFRecords = new List<ZP_Company_Onboarding_Funnel__c>();
		objOrder = (Order) stdCtrl.getRecord();
		if (null != objOrder)
			idOrder = objOrder.Id;

		selectAll = false;

		IdloggedInUser = UserInfo.getUserId();
		isAuthUser = false;

		bool_CopyButtonVisible = false;

		//check if logged in user is a part of PAyroll Transfer Advocate Group
		List<GroupMember> members = [
			SELECT Id, UserOrGroupId
			FROM GroupMember
			WHERE GroupId IN (SELECT Id FROM Group WHERE DeveloperName = 'Payroll_Transfer_Checklist_Access')
		];

		if (null != members && members.size() > 0) {
			setDelegatedAdvocates = new Set<Id>();
			for (GroupMember mem : members) {
				if (mem.UserOrGroupId == IdloggedInUser) {
					isAuthUser = true;
					isDelegatedAdvocate = true;
				}
				setDelegatedAdvocates.add(mem.UserOrGroupId);
			}
		}
		initializeData();
		lstNewOrderChk = new List<OrderChecklistWrapper>();

		//[BS 11 Nov 2020] create set_CompanyId and use thid set to update related ZP_Company_Onboarding_Funnel__c records.
		if (String.isNotBlank(objOrder.Zp_Company_ID__c)) {
			set_CompanyId.add(objOrder.Zp_Company_ID__c);
		}

		//get all the orders associated with BMRs which donot have checklists defined
		list_BMROrders = new List<Order>();
		if (objOrder.Bulk_Migration__c != null && objOrder.Total_Checklists_Count__c == 0) {
			Id id_BMR = objOrder.Bulk_Migration__c;
			for (Order objRelatedOrder : [
				SELECT Id, Blocked_Reason__c, Zp_Company_ID__c, Bulk_Migration__c, Assign_Facilitator__c, Assign_to_Advocate__c, Checklist_Completed__c
				FROM Order
				WHERE Bulk_Migration__c = :id_BMR AND Total_Checklists_Count__c = 0 AND Id != :idOrder
			]) {
				list_BMROrders.add(objRelatedOrder);
				if (String.isNotBlank(objRelatedOrder.Zp_Company_ID__c)) {
					set_CompanyId.add(objRelatedOrder.Zp_Company_ID__c);
				}
			}
		}
	}
	/*
	 * Initialize data
	 */
	private void initializeData() {
		//if no order associated then check for orderId in pageParams
		if (null == idOrder && ApexPages.currentPage().getParameters().containsKey('orderId')) {
			idOrder = ApexPages.currentPage().getParameters().get('orderId');
		}
		if (null == idOrder) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There must be an associated order.'));
			return;
		}

		//Fetch Order
		List<Order> list_Orders = [
			SELECT
				Blocked_Reason__c,
				Assign_Facilitator__c,
				Assign_to_Advocate__c,
				Checklist_Completed__c,
				Facilitator_Follow_Up_Date__c,
				Jira_Link__c,
				Facilitator_Follow_Up_Notes__c,
				Facilitator_Follow_Up_Date_Reason__c,
				Checklist_Status__c,
				Facilitator_Work_Start_DateTime__c,
				Data_Entry_Assist__c,
				Zp_Company_ID__c,
				OwnerId,
				Bulk_Migration__c,
				Total_Checklists_Count__c
			FROM Order
			WHERE Id = :idOrder
			FOR UPDATE
		];

		if (list_Orders != null && list_Orders.size() > 0) {
			objOrder = list_Orders[0];

			objFollowUpOrder.Facilitator_Follow_Up_Date__c = objOrder.Facilitator_Follow_Up_Date__c;
			objFollowUpOrder.Facilitator_Follow_Up_Date_Reason__c = objOrder.Facilitator_Follow_Up_Date_Reason__c;
			objFollowUpOrder.Jira_Link__c = objOrder.Jira_Link__c;
			objFollowUpOrder.Facilitator_Follow_Up_Notes__c = objOrder.Facilitator_Follow_Up_Notes__c;
			objFollowUpOrder.Blocked_Reason__c = objOrder.Blocked_Reason__c;

			//[BS: 28 Oct 2020] - Preserve previous state of Assign to Facilitator & Assign to Advocate field.
			if (objOrder.Assign_Facilitator__c) {
				blnAssignToFacilitator = true;
			}
			if (objOrder.Assign_to_Advocate__c) {
				blnAssignToAdvocate = true;
			}
			//Check if user is either Advocate or Facilitator otherwise throw authorization error
			if (IdloggedInUser == objOrder.OwnerId || IdloggedInUser == objOrder.Data_Entry_Assist__c) {
				isAuthUser = true;
			}

			fetchChecklistDataAndConstructWrapper();
		}
	}

	private void fetchChecklistDataAndConstructWrapper() {
		if (null != objOrder) {
			//fetch Order FAcilitator Chekclist records
			String fChlistQuery = 'SELECT Is_Checked__c,Checklist_Name__c,Is_Blocked__c, Is_Completed__c,Order__c,Order__r.Zp_Company_ID__c,Sequence__c FROM Order_Facilitator_Checklist__c WHERE Order__c = :idOrder';

			if ((IdloggedInUser != objOrder.OwnerId && (setDelegatedAdvocates == null || (setDelegatedAdvocates != null && !setDelegatedAdvocates.contains(IdloggedInUser)))) || !isAuthUser) {
				//fetch only selected checklists
				fChlistQuery += ' AND Is_Checked__c = true';
			}
			fChlistQuery += ' ORDER BY Sequence__c NULLS LAST';
			lstOrderFacilitatorChkLst = Database.query(fChlistQuery);
			//When there are no existing records in Order Facilitator then fetch them from master Checlist obj for the first time
			if (null == lstOrderFacilitatorChkLst || lstOrderFacilitatorChkLst.size() == 0) {
				//If there is bulk migration and there are no checklist records on Order then save and copy button should be visible
				if (objOrder.Bulk_Migration__c != null)
					bool_CopyButtonVisible = true;

				//Fetch BOR Master records
				List<BOR_Master_Checklist__c> list_MasterChkList = [
					SELECT BOR_Checklist_Name__c, BOR_Checklist_Status__c, Sequence__c
					FROM BOR_Master_Checklist__c
					WHERE BOR_Checklist_Status__c = 'Active' AND REcordType.Name = 'Payroll'
					ORDER BY Sequence__c ASC
				];

				//Construct Wrapper
				if (list_MasterChkList != null && list_MasterChkList.size() > 0) {
					lstOrderChklstWrapper = new List<OrderChecklistWrapper>();
					Integer indx = 0;
					for (BOR_Master_Checklist__c mCheck : list_MasterChkList) {
						Order_Facilitator_Checklist__c fCheck = new Order_Facilitator_Checklist__c(
							Checklist_Name__c = mCheck.BOR_Checklist_Name__c,
							Order__c = idOrder,
							Sequence__c = mCheck.Sequence__c
						);
						lstOrderChklstWrapper.add(new OrderChecklistWrapper(fCheck, null, indx, objOrder, setDelegatedAdvocates));
						indx++;
					}
				}
			} else {
				// Order_Facilitator checklist records are existing
				loadFeedItems();
			}
			checkIsAllCheckListCompleted();
		}
	}

	/*
	 * Get the feed for Order Facilitator Checklist
	 */
	public void loadFeedItems() {
		lstOrderChklstWrapper = new List<OrderChecklistWrapper>();
		Map<Id, List<Order_Facilitator_Checklist__Feed>> map_ChecklistFeed = new Map<Id, List<Order_Facilitator_Checklist__Feed>>();
		if (!lstOrderFacilitatorChkLst.isEmpty()) {
			Set<Id> set_OrderChecklistId = new Set<Id>();
			for (Order_Facilitator_Checklist__c fCheck : lstOrderFacilitatorChkLst) {
				set_OrderChecklistId.add(fCheck.Id);
			}

			//fetch feedItems
			Set<Id> set_UserId = new Set<Id>{ objOrder.OwnerId };
			if (null != objOrder.Data_Entry_Assist__c) {
				set_UserId.add(objOrder.Data_Entry_Assist__c);
			}
			if (null != setDelegatedAdvocates && setDelegatedAdvocates.size() > 0) {
				set_UserId.addAll(setDelegatedAdvocates);
			}

			List<Order_Facilitator_Checklist__Feed> list_FeedItems = [
				SELECT
					Id,
					Type,
					CreatedDate,
					CreatedById,
					CreatedBy.Name,
					ParentId,
					Body,
					Title,
					LikeCount,
					CommentCount,
					(
						SELECT Id, CommentBody, CreatedDate, CreatedById, CreatedBy.Name, CommentType
						FROM FeedComments
						ORDER BY CreatedDate DESC
					)
				FROM Order_Facilitator_Checklist__Feed
				WHERE ParentId IN :set_OrderChecklistId AND Type = 'TextPost' AND CreatedById IN :set_UserId
				ORDER BY CreatedDate DESC, Id DESC
			];

			if (!list_FeedItems.isEmpty()) {
				for (Order_Facilitator_Checklist__Feed objFeed : list_FeedItems) {
					List<Order_Facilitator_Checklist__Feed> lstFeed = new List<Order_Facilitator_Checklist__Feed>();
					if (map_ChecklistFeed.containsKey(objFeed.ParentId))
						lstFeed = map_ChecklistFeed.get(objFeed.ParentId);

					lstFeed.add(objFeed);
					map_ChecklistFeed.put(objFeed.ParentId, lstFeed);
				}
			}
		}
		Integer indx = 0;
		for (Order_Facilitator_Checklist__c objCheckList : lstOrderFacilitatorChkLst) {
			List<Order_Facilitator_Checklist__Feed> list_ChkFeed;
			if (objCheckList.Id != null && map_ChecklistFeed.containsKey(objCheckList.Id)) {
				list_ChkFeed = map_ChecklistFeed.get(objCheckList.Id);
			}

			lstOrderChklstWrapper.add(new OrderChecklistWrapper(objCheckList, list_ChkFeed, indx, objOrder, setDelegatedAdvocates));
			indx++;
		}
	}

	public Boolean boolErrorMessage { get; private set; }

	/*
	 * Save Order Facilitator Checklist and refresh current page.
	 */
	public PageReference saveChecklistNRefresh() {
		if (missingRequiredField()) {
			return null;
		}

		PageReference ref = new PageReference('/apex/CreateEditOrderFAcilitatorChecklist?orderId=' + idOrder);
		saveChecklists();
		ref.setRedirect(true);
		return ref;
	}
	/*
	 * Save Order Facilitator Checklist
	 */
	public void saveChecklists() {
		try {
			if (missingRequiredField()) {
				return;
			}

			Integer lastIndex = 0;
			if (null != lstOrderChklstWrapper && lstOrderChklstWrapper.size() > 0) {
				for (OrderChecklistWrapper wrapper : lstOrderChklstWrapper) {
					if (wrapper.objOrderChkLst.Sequence__c == null) {
						lastIndex++;
						wrapper.objOrderChkLst.Sequence__c = lastIndex;
					} else {
						lastIndex = Integer.valueOf(wrapper.objOrderChkLst.Sequence__c);
					}
				}
			}
			if (null != lstNewOrderChk) {
				for (OrderChecklistWrapper objNewOrderChk : lstNewOrderChk) {
					if (String.isNotBlank(objNewOrderChk.objOrderChkLst.Checklist_Name__c)) {
						lastIndex++;

						objNewOrderChk.objOrderChkLst.Is_Checked__c = true;
						objNewOrderChk.objOrderChkLst.Sequence__c = lastIndex;
						lstOrderChklstWrapper.add(objNewOrderChk);
					}
				}
			}

			if (null != lstOrderChklstWrapper && lstOrderChklstWrapper.size() > 0) {
				lstChecklistToUpsert = new List<Order_Facilitator_Checklist__c>();

				for (OrderChecklistWrapper wrapper : lstOrderChklstWrapper) {
					Order_Facilitator_Checklist__c objCheck = wrapper.objOrderChkLst;
					lstChecklistToUpsert.add(objCheck);
				}

				if (lstChecklistToUpsert.size() > 0) {
					//In Order object, we are using a Roll-Up Summary field, named as Total Checklists Count. Eg: COUNT(Order Facilitator Checklist).
					//That's why once Order_Facilitator_Checklist__c record is created/updated, then by-default OrderTrigger will executed.
					OrderTriggerHelper.skipTrigger = true;
					Database.upsert(lstChecklistToUpsert);
					OrderTriggerHelper.skipTrigger = false;

					//[BS: 10 Nov 2020] create set_CompanyId.
					if (set_CompanyId.size() > 0) {
						List<ZP_Company_Onboarding_Funnel__c> list_ZPCOFRecords = new List<ZP_Company_Onboarding_Funnel__c>();
						list_RelatedZPCOFRecords = new List<ZP_Company_Onboarding_Funnel__c>();

						for (ZP_Company_Onboarding_Funnel__c objZPCOFunnel : [
							SELECT
								Id,
								Company_Id__c,
								Payroll_Schedule_Completed__c,
								Previous_Paystubs_Completed__c,
								Sign_All_Forms_Completed__c,
								Add_Signatory_Completed__c,
								Verify_Bank_Info_Completed__c,
								Create_User_Account_Completed__c,
								Add_Addresses_Completed__c,
								Add_Employees_Completed__c,
								Federal_Tax_Setup_Completed__c,
								State_Setup_Completed__c,
								Add_Bank_Info_Completed__c,
								Historical_Liabilities_Completed__c,
								ran_payroll_at__c
							FROM ZP_Company_Onboarding_Funnel__c
							WHERE Company_Id__c != NULL AND Company_Id__c IN :set_CompanyId
						]) {
							if (String.isNotBlank(objOrder.Zp_Company_ID__c) && objZPCOFunnel.Company_Id__c == objOrder.Zp_Company_ID__c) {
								list_ZPCOFRecords.add(objZPCOFunnel);
							} else {
								list_RelatedZPCOFRecords.add(objZPCOFunnel);
							}
						}

						//Update ZP_Company_Onboarding_Funnel__c record related to current order(Open order on UI)
						if (list_ZPCOFRecords.size() > 0 && list_RelatedZPCOFRecords.size() == 0) {
							ZPCompanyOnboardingFunnelTriggerHelper.blnSkipOrderStatusFilter = true;
							ZPCompanyOnboardingFunnelTriggerHelper.checkOnboardingSteps(list_ZPCOFRecords, null);
							ZPCompanyOnboardingFunnelTriggerHelper.blnSkipOrderStatusFilter = false;
						}

						//Merge Current order funnel record (list_ZPCOFRecords) into list_RelatedZPCOFRecords. So we will update list of records in one transaction.
						if (list_RelatedZPCOFRecords.size() > 0) {
							list_RelatedZPCOFRecords.addAll(list_ZPCOFRecords);
						}
					}
				}
			}

			fetchChecklistDataAndConstructWrapper();
			boolErrorMessage = false;
			lstNewOrderChk = new List<OrderChecklistWrapper>();

			//[BS: 22 Oct 202] Add below mentioned line of code.
			//---------Start---------
			if (IdloggedInUser == objOrder.OwnerId || IdloggedInUser == objOrder.Data_Entry_Assist__c) {
				if (IdloggedInUser == objOrder.OwnerId && objOrder.Assign_Facilitator__c) {
					//Re-assignement
					objOrder.Assign_to_Advocate__c = false;
				} else if (IdloggedInUser == objOrder.Data_Entry_Assist__c) {
					//Re-assignement
					if (objOrder.Assign_to_Advocate__c && objFollowUpOrder.Facilitator_Follow_Up_Date__c == null) {
						objOrder.Assign_Facilitator__c = false;
					}

					//Reset with previous field value.
					if (objOrder.Assign_to_Advocate__c && !blnAssignToAdvocate && objFollowUpOrder.Facilitator_Follow_Up_Date__c != null) {
						objOrder.Assign_to_Advocate__c = blnAssignToAdvocate;
					}
				}

				if (blnAllCheckListCompleted) {
					objOrder.Checklist_Completed__c = true;
				} else {
					objOrder.Checklist_Completed__c = false;
				}

				if (IdloggedInUser == objOrder.Data_Entry_Assist__c) {
					if (objFollowUpOrder.Facilitator_Follow_Up_Date__c != null) {
						objOrder.Assign_to_Advocate__c = blnAssignToAdvocate;
					}
					if (!blnAllCheckListCompleted) {
						objOrder.Facilitator_Follow_Up_Date__c = objFollowUpOrder.Facilitator_Follow_Up_Date__c;
						objOrder.Facilitator_Follow_Up_Date_Reason__c = objFollowUpOrder.Facilitator_Follow_Up_Date_Reason__c;
						objOrder.Jira_Link__c = objFollowUpOrder.Jira_Link__c;
						objOrder.Facilitator_Follow_Up_Notes__c = objFollowUpOrder.Facilitator_Follow_Up_Notes__c;
						objOrder.Blocked_Reason__c = objFollowUpOrder.Blocked_Reason__c;
					} else {
						objOrder.Facilitator_Follow_Up_Date__c = null;
						objOrder.Facilitator_Follow_Up_Date_Reason__c = null;
						objOrder.Blocked_Reason__c = null;
						objOrder.Jira_Link__c = objFollowUpOrder.Jira_Link__c;
						objOrder.Facilitator_Follow_Up_Notes__c = objFollowUpOrder.Facilitator_Follow_Up_Notes__c;
					}

					if (objFollowUpOrder.Facilitator_Follow_Up_Date__c == null && objOrder.Assign_to_Advocate__c) {
						objOrder.Facilitator_Follow_Up_Date_Reason__c = null;
					}
				}

				update objOrder;
			}
			String strMessage = getEndDateMessage();
			if (String.isNotBlank(strMessage)) {
				createAnalyticsTimeTracker(strMessage);
			}
			//---------End---------
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			ExceptionLogUtil.logException('CreateEditOrderFacilitatorChecklistCtrl', 'saveChecklists', e.getMessage(), e.getStackTraceString());
			boolErrorMessage = true;
		}
	}
	/*
	 * Remove checklist record from WrapperList
	 */
	public PageReference removeChecklist() {
		PageReference ref;
		try {
			//If it is an existing checklist record
			if (!bool_IsNewChkToBeRemoved && intIndxToBeRemoved < lstOrderChklstWrapper.size()) {
				ref = new PageReference('/apex/CreateEditOrderFAcilitatorChecklist?orderId=' + idOrder);
				Order_Facilitator_Checklist__c objChk = lstOrderChklstWrapper[intIndxToBeRemoved].objOrderChkLst;
				// If checklist row being removed is existing in database, then note its Id.
				if (objChk.Id != null) {
					delete objChk;
				}
				ref.setRedirect(true);
			} else if (bool_IsNewChkToBeRemoved && null != lstNewOrderChk && lstNewOrderChk.size() > intIndxToBeRemoved) {
				//Id it is a new checklist record (not inserted yet)
				lstNewOrderChk.remove(intIndxToBeRemoved);
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		return ref;
	}
	/*
	 * Add new checklist record to WrapperList
	 */
	public void addNewCheckList() {
		Order_Facilitator_Checklist__c objChkLst = new Order_Facilitator_Checklist__c(Order__c = idOrder, Is_Checked__c = true);
		lstNewOrderChk.add(new OrderChecklistWrapper(objChkLst, null, lstNewOrderChk.size(), objOrder, setDelegatedAdvocates));
	}

	public Integer intWrapIndex { get; set; }
	public String strFieldName { get; set; }
	/*
	 * To make sure only one is selected out of Blocked and Completed
	 */
	public void toggleComplete() {
		if (null != lstOrderChklstWrapper && lstOrderChklstWrapper.size() > intWrapIndex) {
			OrderChecklistWrapper objWrap = lstOrderChklstWrapper[intWrapIndex];

			if ('Completed'.equalsIgnoreCase(strFieldName) && objWrap.objOrderChkLst.Is_Completed__c && objWrap.objOrderChkLst.Is_Blocked__c) {
				objWrap.objOrderChkLst.Is_Blocked__c = false;
			}
			if ('Blocked'.equalsIgnoreCase(strFieldName) && objWrap.objOrderChkLst.Is_Blocked__c && objWrap.objOrderChkLst.Is_Completed__c) {
				objWrap.objOrderChkLst.Is_Completed__c = false;
			}
		}
		checkIsAllCheckListCompleted();
	}
	/*
	 * Wrapper class for displaying order facilitator checklist data
	 */
	public class OrderChecklistWrapper {
		public Order_Facilitator_Checklist__c objOrderChkLst { get; set; }
		private List<Order_Facilitator_Checklist__Feed> lstFeed;
		public Integer indx { get; set; }

		public String strLastAdvocateComment { get; private set; }
		public String strLastFacilitatorComment { get; private set; }

		private DateTime latestTimestampAdv, latestTimestampFac;

		public OrderChecklistWrapper(Order_Facilitator_Checklist__c objOrderCheck, List<Order_Facilitator_Checklist__Feed> lstFeeds, Integer indx, Order objOrder, Set<Id> setDelegatedAdvocates) {
			objOrderChkLst = objOrderCheck;
			this.indx = indx;

			//Get latest comments for Advocate and Facilitator if Checklist and Feed are existing
			if (null != objOrderChkLst.Id) {
				lstFeed = lstFeeds;
				if (null != lstFeeds && !lstFeeds.isEmpty()) {
					Map<Id, Order_Facilitator_Checklist__Feed> mapIDFeedItem = new Map<Id, Order_Facilitator_Checklist__Feed>(lstFeeds);
					List<FeedComment> lstFeedCmnt = new List<FeedComment>();
					//reference dates to get latest comment
					latestTimestampAdv = DateTime.newInstance(2000, 1, 1);
					latestTimestampFac = DateTime.newInstance(2000, 1, 1);

					for (Order_Facilitator_Checklist__Feed fi : lstFeeds) {
						//Advocate has created feed
						if ((fi.CreatedById == objOrder.OwnerId || (null != setDelegatedAdvocates && setDelegatedAdvocates.contains(fi.CreatedById))) && latestTimestampAdv < fi.CreatedDate) {
							strLastAdvocateComment = fi.body;
							latestTimestampAdv = fi.CreatedDate;
						}
						//Facilitator has created feed which is latest
						if (objOrder.Data_Entry_assist__c != objOrder.OwnerId && fi.CreatedById == objOrder.Data_Entry_assist__c && latestTimestampFac < fi.CreatedDate) {
							if (null != setDelegatedAdvocates && setDelegatedAdvocates.contains(objOrder.Data_Entry_assist__c))
								continue;

							strLastFacilitatorComment = fi.body;
							latestTimestampFac = fi.CreatedDate;
						}
						if (null != fi.FeedComments)
							lstFeedCmnt.addAll(fi.FeedComments);
					}
					if (lstFeedCmnt.size() > 0) {
						for (FeedComment comment : lstFeedCmnt) {
							//Advocate has created feed and this is the latest feed
							if (
								(comment.CreatedById == objOrder.OwnerId || (null != setDelegatedAdvocates && setDelegatedAdvocates.contains(comment.CreatedById))) &&
								latestTimestampAdv < comment.CreatedDate
							) {
								strLastAdvocateComment = comment.CommentBody;
								latestTimestampAdv = comment.CreatedDate;
							}
							//Facilitator is not same as Advocate and Facilitator has commented which is latest
							if (objOrder.Data_Entry_assist__c != objOrder.OwnerId && comment.CreatedById == objOrder.Data_Entry_assist__c && latestTimestampFac < comment.CreatedDate) {
								if (null != setDelegatedAdvocates && setDelegatedAdvocates.contains(objOrder.Data_Entry_assist__c))
									continue;

								strLastFacilitatorComment = comment.CommentBody;
								latestTimestampFac = comment.CreatedDate;
							}
						}
					}
				}
			}
			if (null == lstFeed)
				lstFeed = new List<Order_Facilitator_Checklist__Feed>();
		}
	}
	/*
	 * Select all checklist records in WrapperList
	 */
	public void selectAllchecklists() {
		if (null != lstOrderChklstWrapper && lstOrderChklstWrapper.size() > 0) {
			for (OrderChecklistWrapper wrap : lstOrderChklstWrapper) {
				wrap.objOrderChkLst.is_Checked__c = selectAll;
			}
		}
	}
	/*
	 * Save checklists and copy checklists to all other orders with same BMR
	 */
	public PageReference saveAndCopychecklists() {
		PageReference ref;
		try {
			if (missingRequiredField()) {
				return null;
			}
			ref = new PageReference('/apex/CreateEditOrderFAcilitatorChecklist?orderId=' + idOrder);
			ref.setRedirect(true);

			saveChecklists(); // save checklists

			//Copy checklists on other orders
			if (null != objOrder && null != objOrder.Bulk_Migration__c) {
				createChecklistForBMROrders();
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		return ref;
	}

	/*
	 * Description : Create checklists for all the Orders on associated BMR if there is a related BMR on current Order
	 */
	private void createChecklistForBMROrders() {
		//If user select the checklist on UI.
		if (null != lstChecklistToUpsert && lstChecklistToUpsert.size() > 0) {
			//Is current Order related to any BMR then list_BMROrders size should be greater than zero.
			if (null != list_BMROrders && list_BMROrders.size() > 0) {
				//Iterate over orders to create new checklist records
				List<Order_Facilitator_Checklist__c> list_ChkLstToInsert = new List<Order_Facilitator_Checklist__c>();
				for (Order objOrd : list_BMROrders) {
					for (Order_Facilitator_Checklist__c objChkLst : lstChecklistToUpsert) {
						Order_Facilitator_Checklist__c objNewChk = new Order_Facilitator_Checklist__c();
						objNewChk.Checklist_Name__c = objChkLst.Checklist_Name__c;
						objNewChk.Sequence__c = objChkLst.Sequence__c;
						objNewChk.Order__c = objOrd.Id;
						objNewChk.Is_Blocked__c = objChkLst.Is_Blocked__c;
						objNewChk.Is_Checked__c = objChkLst.Is_Checked__c;
						objNewChk.Is_Completed__c = objChkLst.Is_Completed__c;
						objNewChk.Completed_Username__c = objChkLst.Completed_Username__c;
						objNewChk.Completed_Timestamp__c = objChkLst.Completed_Timestamp__c;
						objNewChk.Blocked_Username__c = objChkLst.Blocked_Username__c;
						objNewChk.Blocked_Timestamp__c = objChkLst.Blocked_Timestamp__c;
						list_ChkLstToInsert.add(objNewChk);
					}
					//[BS : 29 Oct 2020]
					objOrd.Assign_Facilitator__c = objOrder.Assign_Facilitator__c;
					objOrd.Checklist_Completed__c = objOrder.Checklist_Completed__c;
					if (objOrder.Assign_Facilitator__c) {
						objOrd.No_Of_Times_Assign_to_Facilitator__c = 1;
						objOrd.Last_Assigned_To_Facilitator__c = Datetime.now();
						objOrd.Ready_For_Facilitator_Assigned_Timestamp__c = Datetime.now();
						objOrd.Checklist_Status_Change_Date_Time__c = Datetime.now();
					}
				}

				//In Order object, we are using a Roll-Up Summary field, named as Total Checklists Count. Eg: COUNT(Order Facilitator Checklist).
				//That's why once Order_Facilitator_Checklist__c record is created/updated, then by-default OrderTrigger will executed.
				OrderTriggerHelper.skipTrigger = true;

				//Skip OrderFacilitatorChecklistTrigger to avoid recursion and insert checklist records
				Boolean oldVal = OrderFacilitatorChecklistTriggerHelper.skipTrigger;
				OrderFacilitatorChecklistTriggerHelper.skipTrigger = true;
				insert list_ChkLstToInsert;
				OrderFacilitatorChecklistTriggerHelper.skipTrigger = oldVal;

				//[BS : 29 Oct 2020] - update Assign_Facilitator__c field in related BMR order.
				update list_BMROrders;
				OrderTriggerHelper.skipTrigger = false;

				//Update ZP_Company_Onboarding_Funnel__c record related to current order BMR family
				if (list_RelatedZPCOFRecords.size() > 0) {
					ZPCompanyOnboardingFunnelTriggerHelper.blnSkipOrderStatusFilter = true;
					ZPCompanyOnboardingFunnelTriggerHelper.checkOnboardingSteps(list_RelatedZPCOFRecords, null);
					ZPCompanyOnboardingFunnelTriggerHelper.blnSkipOrderStatusFilter = false;
				}
			}
		}
	}
	/*
	 * By ND, 26 Nov 2019,
	 * Desc : To set Facilitator_Work_Start_DateTime__c on Order to keep track of the first time Facilitator accesses checklists. This marks that Facilitator has started working on Order.
	 */
	public void checkFirstTimeFacilitatorAccess() {
		if (
			null != objOrder &&
			IdloggedInUser == objOrder.Data_Entry_Assist__c &&
			null != lstOrderFacilitatorChkLst &&
			lstOrderFacilitatorChkLst.size() > 0 &&
			null == objOrder.Facilitator_Work_Start_DateTime__c
		) {
			objOrder.Facilitator_Work_Start_DateTime__c = system.now();

			Boolean preVal = OrderTriggerHelper.skipTRigger;
			OrderTriggerHelper.skipTRigger = true;
			update objOrder;
			OrderTriggerHelper.skipTRigger = preVal;
		}
	}

	/*
    //[BS: 22 Oct 2020]
    //If logged in user match with Order Owner then "Assign to Facilitator" checkbox will be visible on screen.
    //If logged in user match with Facilitator then "Assign to Advocate" checkbox will be visible on screen.
    //If logged in user match with Facilitator and Order Owner then only "Assign to Facilitator" checkbox will be visible on screen.
    */
	public String getEndDateMessage() {
		String strMsg = '';
		if (blnAllCheckListCompleted) {
			strMsg = 'Checklist Completed';
		} else if (IdloggedInUser == objOrder.Data_Entry_Assist__c && objOrder.Assign_to_Advocate__c) {
			strMsg = 'Assigned to Advocate';
		} else if (IdloggedInUser == objOrder.Data_Entry_Assist__c && objOrder.Facilitator_Follow_Up_Date__c != null) {
			strMsg = 'Follow Up date is set';
		}
		return strMsg;
	}

	//[BS: 22 Oct 2020]
	//This method check all check list status.
	public void checkIsAllCheckListCompleted() {
		if (lstOrderChklstWrapper.size() > 0) {
			blnAllCheckListCompleted = true;
			for (OrderChecklistWrapper objWrap : lstOrderChklstWrapper) {
				blnAllCheckListCompleted = objWrap.objOrderChkLst.Is_Completed__c;
				if (!blnAllCheckListCompleted) {
					break;
				}
			}

			if (blnAllCheckListCompleted) {
				////[BS : 6 Nov 2020] Rest value on UI
				if (IdloggedInUser == objOrder.OwnerId) {
					objOrder.Assign_Facilitator__c = blnAssignToFacilitator;
				} else if (IdloggedInUser == objOrder.Data_Entry_Assist__c) {
					objOrder.Assign_to_Advocate__c = blnAssignToAdvocate;
					objFollowUpOrder.Facilitator_Follow_Up_Date__c = objOrder.Facilitator_Follow_Up_Date__c;
					objFollowUpOrder.Facilitator_Follow_Up_Date_Reason__c = objOrder.Facilitator_Follow_Up_Date_Reason__c;
					objFollowUpOrder.Facilitator_Follow_Up_Notes__c = objOrder.Facilitator_Follow_Up_Notes__c;
					objFollowUpOrder.Blocked_Reason__c = objOrder.Blocked_Reason__c;
				}
			}
		}
	}

	//[BS: 22 Oct 2020]
	//This method create or update Analytics Time Tracker record.
	public void createAnalyticsTimeTracker(String strMessage) {
		try {
			Id idsObj = objOrder.Id;
			if (String.isNotBlank(idsObj)) {
				Analytics_Time_Tracker__c objTracker = new Analytics_Time_Tracker__c();
				List<Analytics_Time_Tracker__c> list_Tracker = [
					SELECT Id, Benefit_Order__c, Carrier_Order__c, Order__c, Duration__c, End_Date__c, Event_Type__c, Metric_Type__c, Record_Id__c, Start_Date__c, Description__c
					FROM Analytics_Time_Tracker__c
					WHERE CreatedById = :IdloggedInUser AND Start_Date__c != NULL AND End_Date__c = NULL AND Order__c = :idsObj
					ORDER BY CreatedDate DESC
				];

				if (list_Tracker.size() > 0) {
					objTracker = list_Tracker[0];
					objTracker.End_Date__c = DateTime.now();
					objTracker.Description__c = strMessage;

					update objTracker;
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('CreateEditOrderFacilitatorChecklistCtrl', 'createAnalyticsTimeTracker', ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void reAssignOrder() {
		//On click of reassign action event, this method refresh the VF page.
	}

	public boolean missingRequiredField() {
		Boolean blnIsMissingField = false;
		if (!blnAllCheckListCompleted && idloggedInUser == objOrder.Data_Entry_Assist__c) {
			//If login user is a Facilitator.
			if (objFollowUpOrder.Facilitator_Follow_Up_Date__c != null && objFollowUpOrder.Facilitator_Follow_Up_Date__c == Date.today() && String.isBlank(objFollowUpOrder.Blocked_Reason__c)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please enter a Blocked Reason if follow up date is today.'));
				blnIsMissingField = true;
			} else if (
				objFollowUpOrder.Facilitator_Follow_Up_Date__c != null &&
				objFollowUpOrder.Facilitator_Follow_Up_Date__c > Date.today() &&
				objFollowUpOrder.Facilitator_Follow_Up_Date_Reason__c == null
			) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please enter facilitator follow up date reason if follow up date is in the future.'));
				blnIsMissingField = true;
			} else if (
				objFollowUpOrder.Facilitator_Follow_Up_Date__c != null &&
				objFollowUpOrder.Facilitator_Follow_Up_Date__c > Date.today() &&
				objFollowUpOrder.Facilitator_Follow_Up_Date_Reason__c != null &&
				objFollowUpOrder.Facilitator_Follow_Up_Date_Reason__c == 'EPD JIRA' &&
				String.isBlank(objFollowUpOrder.Jira_Link__c)
			) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please enter Jira Number.'));
				blnIsMissingField = true;
			}
		}

		return blnIsMissingField;
	}
}