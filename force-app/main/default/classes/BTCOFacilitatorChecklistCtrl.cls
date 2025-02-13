/**
 * @name         BTCOFacilitatorChecklistCtrl
 * @author       Deepika, Bhagat
 * @date         24-01-2020
 * @description  Facilitator 1 will check if any of the check list document is completed or not
 * @test class   BTCOFacilitatorChecklistCtrlTest
 **/
public class BTCOFacilitatorChecklistCtrl {
	//>>>>>>>>>>Varible assignment>>>>>>>>>>>>>>>>
	//List of Wrapper which is used to display the all the checkboxes on the UI with respective of Benefit type and CheckList Name
	/**
        map_ChecklistWrapper[Document NAme, Wrapper]
        and Wrapper=  [DocumentName,map<Benefit Type, BorChekclist>, facilitator notes]
     */
	public Map<String, BORChecklistWrapper> map_ChecklistWrapper { get; set; } //set of Benefit type which should be shown on the screen
	public Set<String> set_BenefitTypeName { get; set; } //Carrier order to update Facilitator Plan Build
	public Set<String> set_borChecklistName { get; set; } //BOR Checklist Name Set
	public Carrier_Order__c objCarrierOrder { get; set; } //Check the Count of checklist
	public integer intChecklistExit {
		get {
			return map_ChecklistWrapper.size();
		}
	} //check error exist
	public Boolean isErrorExist { get; set; }
	public map<String, Set<String>> map_DocCategory { get; set; }
	public set<String> set_DocCategory { get; set; }
	public String str_benefitOrder = 'Medical;Dental;Vision;Life;' + Utils.BENEFIT_TYPE_LTD + ';' + Utils.BENEFIT_TYPE_STD;
	public set<string> set_ExcludeCO = Utils.setCOExclude;
	public boolean blnDisableCheckList { get; set; }
	public boolean blnIsParent { get; set; }
	public boolean isFacilitator2PlanBuildRequired { get; set; }
	public boolean isChecklistForEnrollmentReview { get; set; }
	public boolean blnOpenTicketExist { get; set; }
	Map<String, Map<String, List<BOR_Checklist__c>>> map_childChecklistWrapper = new Map<String, Map<String, List<BOR_Checklist__c>>>();
	Map<Id, Set<String>> map_childCOwithBenefitType = new Map<Id, Set<String>>(); //key=Carrier_Order__c, value=List<Benefit_Types__c>
	public Map<Id, boolean> map_reqCheckList = new Map<Id, boolean>();
	public Map<Id, boolean> map_enReqCheckList = new Map<Id, boolean>();
	public boolean blnParentChildEqualCheckList { get; set; }
	public boolean blnIncompleteCheckList { get; set; }
	public Map<Id, boolean> map_parentChildNotes = new Map<Id, boolean>();
	public Map<Id, boolean> map_childCORequiredDoc = new Map<Id, boolean>();
	public Map<Id, boolean> map_childCOEnrollmentReqDoc = new Map<Id, boolean>();
	public Set<String> set_parentBenefitTypeName { get; set; } //Carrier order to update Facilitator Plan Build
	//<<<<<<<<<<<Varible assignment END<<<<<<<<<<<

	//>>>>>>>>>>>>>>>>>>>>>Constructor of the Page>>>>>>>>>>>>>>>>>>>>>>>>
	public BTCOFacilitatorChecklistCtrl() {
		blnIncompleteCheckList = false;
		blnParentChildEqualCheckList = true;
		map_parentChildNotes = new Map<Id, boolean>();
		map_reqCheckList = new Map<Id, boolean>();
		map_enReqCheckList = new Map<Id, boolean>();
		map_childCORequiredDoc = new Map<Id, boolean>();
		map_childCOEnrollmentReqDoc = new Map<Id, boolean>();
		blnDisableCheckList = false;
		blnOpenTicketExist = false;
		blnIsParent = false;
		isFacilitator2PlanBuildRequired = false;
		isChecklistForEnrollmentReview = false;
		set_BenefitTypeName = new Set<String>();
		set_parentBenefitTypeName = new Set<String>();
		Set<String> set_existingBenefitType = new Set<String>();
		set_borChecklistName = new Set<String>();
		map_DocCategory = new Map<String, Set<String>>();
		set_DocCategory = new Set<String>();
		set_DocCategory.add('Required for Plan/Policy Build');
		set_DocCategory.add('Required for Enrollment Review');
		set_DocCategory.add('Nice to Have (Order CAN push withOut)');

		map_ChecklistWrapper = new Map<String, BORChecklistWrapper>();
		objCarrierOrder = new Carrier_Order__c();
		isErrorExist = false;
		// Carrier Order Id get from the URL
		objCarrierOrder.Id = Apexpages.currentPage().getParameters().get('id');
		string strReadonly = Apexpages.currentPage().getParameters().get('readonly');
		if (strReadonly == 'true') {
			blnDisableCheckList = true;
		}
		if (String.isNotBlank(objCarrierOrder.Id)) {
			// Get all the BOR CheckList For for Current Carrier
			List<BOR_Checklist__c> lst_BORCheckList = [
				SELECT
					id,
					Name,
					BOR_Checkpoints__c,
					Carrier_Order_Line_Item__r.Benefit_Types__c,
					IsCheckPointImplemented__c,
					BOR_Checkpoints__r.BOR_Checklist_Name__c,
					Facilitator_Notes__c,
					Check_List_Name__c,
					Carrier_Order_Line_Item__r.Carrier_Order__c,
					Carrier_Order_Line_Item__r.Carrier_Order__r.Facilitator_2_Plan_Build__c,
					Carrier_Order_Line_Item__r.Carrier_Order__r.Resign_Required__c,
					Carrier_Order_Line_Item__r.Carrier_Order__r.Is_Multi_EIN__c,
					Carrier_Order_Line_Item__r.Carrier_Order__r.Parent_Carrier_Order__c,
					Carrier_Order_Line_Item__r.Carrier_Order__r.Resign_Required_Reason__c,
					Carrier_Order_Line_Item__r.Carrier_Order__r.Contribution_per_the_ER__c,
					Carrier_Order_Line_Item__r.Carrier_Order__r.Implementation_Stage__c,
					BOR_Checkpoints__r.Sequence__c,
					BOR_Checkpoints__r.Mandatory__c,
					BOR_Checkpoints__r.Optional_Checklist__c
				FROM BOR_Checklist__c
				WHERE Carrier_Order_Line_Item__r.Carrier_Order__c = :objCarrierOrder.Id AND Carrier_Order_Line_Item__r.Carrier_Order__r.Implementation_Stage__c NOT IN :set_ExcludeCO
				ORDER BY BOR_Checkpoints__r.Sequence__c
			];

			if (lst_BORCheckList != null && !lst_BORCheckList.isEmpty()) {
				//Get the value of some fields from Carrier Order
				objCarrierOrder.Is_Multi_EIN__c = lst_BORCheckList[0].Carrier_Order_Line_Item__r.Carrier_Order__r.Is_Multi_EIN__c;
				objCarrierOrder.Parent_Carrier_Order__c = lst_BORCheckList[0].Carrier_Order_Line_Item__r.Carrier_Order__r.Parent_Carrier_Order__c;
				objCarrierOrder.Implementation_Stage__c = lst_BORCheckList[0].Carrier_Order_Line_Item__r.Carrier_Order__r.Implementation_Stage__c;
				objCarrierOrder.Facilitator_2_Plan_Build__c = lst_BORCheckList[0].Carrier_Order_Line_Item__r.Carrier_Order__r.Facilitator_2_Plan_Build__c;
				objCarrierOrder.Resign_Required__c = lst_BORCheckList[0].Carrier_Order_Line_Item__r.Carrier_Order__r.Resign_Required__c;
				objCarrierOrder.Resign_Required_Reason__c = lst_BORCheckList[0].Carrier_Order_Line_Item__r.Carrier_Order__r.Resign_Required_Reason__c;
				// objCarrierOrder.Contribution_per_the_ER__c = lst_BORCheckList[0].Carrier_Order_Line_Item__r.Carrier_Order__r.Contribution_per_the_ER__c;
				//Check if this is part of Multi EIN and Parent
				if (objCarrierOrder.Is_Multi_EIN__c == true && objCarrierOrder.Parent_Carrier_Order__c == null) {
					blnIsParent = true;
				}
				//get Any Open Ticket related to CO
				List<Ticket__c> lst_TicketTemp = [
					SELECT Id, Carrier_Order__c, status__c
					FROM Ticket__c
					WHERE Carrier_Order__c = :objCarrierOrder.Id AND status__c != 'Closed'
					LIMIT 1
				];
				if (lst_TicketTemp != null && lst_TicketTemp.size() > 0) {
					blnOpenTicketExist = true;
				}

				for (BOR_Checklist__c objBORChecklist : lst_BORCheckList) {
					//Get Empty wrapper
					BORChecklistWrapper objChecklistWrapper = null;
					//Add the Benefit Type values in the set Such as Medical,Dental,Vision
					if (!set_existingBenefitType.contains(objBORChecklist.Carrier_Order_Line_Item__r.Benefit_Types__c)) {
						set_existingBenefitType.add(objBORChecklist.Carrier_Order_Line_Item__r.Benefit_Types__c);
					}

					/*Add value in the wrapper(DocName,Facilitor Notes, MAp<Benefittype, BORChecklist>)
                    Example(Docs: COBRA status,'notes',Map<Medical,bOR checklist record>)
                    */
					if (!map_ChecklistWrapper.isEmpty() && map_ChecklistWrapper.containsKey(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c)) {
						objChecklistWrapper = map_ChecklistWrapper.get(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c);
					} else {
						set_borChecklistName.add(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c);
						objChecklistWrapper = new BORChecklistWrapper(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c, objBORChecklist.Facilitator_Notes__c);
					}
					objChecklistWrapper.assignBORChecklistWrapper(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c, objBORChecklist);

					/*Add value in the Map(DocName,Wrapper)
                    Example(Docs: COBRA status,Wrapper)
                    */
					map_ChecklistWrapper.put(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c, objChecklistWrapper);

					//Categorize documents
					if (objBORChecklist.BOR_Checkpoints__r.Mandatory__c == true && objBORChecklist.BOR_Checkpoints__r.Optional_Checklist__c == false) {
						categorizeDocument('Required for Plan/Policy Build', objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c);
					} else if (objBORChecklist.BOR_Checkpoints__r.Mandatory__c == false && objBORChecklist.BOR_Checkpoints__r.Optional_Checklist__c == false) {
						categorizeDocument('Required for Enrollment Review', objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c);
					} else {
						categorizeDocument('Nice to Have (Order CAN push withOut)', objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c);
					}
				}
			} else {
				Cache.displayErrorMessage('Carrier order does not have any checklist', ApexPages.Severity.ERROR);
			}
		} else {
			Cache.displayErrorMessage('Page not loaded properly. Please try again.', ApexPages.Severity.ERROR);
		}

		checkRequireDocument(set_existingBenefitType);

		if (blnIsParent) {
			fetchChildCarrierOrder(objCarrierOrder.Id, true);
			set_parentBenefitTypeName = set_BenefitTypeName;
		} else if (objCarrierOrder.Parent_Carrier_Order__c != null) {
			blnParentChildEqualCheckList = false;
			set_parentBenefitTypeName = getParentCOBenefitTypeName(objCarrierOrder.Parent_Carrier_Order__c);
			fetchChildCarrierOrder(objCarrierOrder.Parent_Carrier_Order__c, false);
		}

		// >>>> Check Parent and Child CO have same BenefitType. <<<<
		for (Id key : map_childCOwithBenefitType.keySet()) {
			boolean reqFlag = true;
			boolean reqEnFlag = true;
			boolean isCLIMatch = true;

			if (key != objCarrierOrder.Id) {
				for (String strValue : map_childCOwithBenefitType.get(key)) {
					if (!set_parentBenefitTypeName.contains(strValue)) {
						isCLIMatch = false;
						blnParentChildEqualCheckList = false;
					}

					// >>>> If Parent and Child CO have different BenefitType. <<<
					if (map_childCORequiredDoc.containsKey(key) && map_childCORequiredDoc.get(key) == false) {
						// >>>> If Child CO have at least one check-list marked as false. <<<
						reqFlag = false;
						blnIncompleteCheckList = true;
					}
					if (map_childCOEnrollmentReqDoc.containsKey(key) && map_childCOEnrollmentReqDoc.get(key) == false) {
						// >>>> If Child CO have at least one check-list marked as false. <<<<
						reqEnFlag = false;
					}
				}
			}

			// >>>> If parent and child CO have same CLI <<<
			map_parentChildNotes.put(key, isCLIMatch);
			map_reqCheckList.put(key, reqFlag);
			map_enReqCheckList.put(key, reqEnFlag);
		}
	}

	public void checkRequireDocument(Set<String> benefitOrder) {
		// >>>> Set default order of Benefit Type Name as : [Medical;Dental;Vision;Life;LTD;STD] <<<
		for (String strOrder : str_benefitOrder.split(';')) {
			if (benefitOrder.contains(strOrder) && !set_BenefitTypeName.contains(strOrder)) {
				set_BenefitTypeName.add(strOrder);
			}
		}

		// >>>> Check document exit on the basis of document category. <<<
		if (!map_DocCategory.containsKey('Required for Plan/Policy Build')) {
			map_DocCategory.put('Required for Plan/Policy Build', new Set<String>());
		}
		if (!map_DocCategory.containsKey('Required for Enrollment Review')) {
			map_DocCategory.put('Required for Enrollment Review', new Set<String>());
		}
		if (!map_DocCategory.containsKey('Nice to Have (Order CAN push withOut)')) {
			map_DocCategory.put('Nice to Have (Order CAN push withOut)', new Set<String>());
		}
	}

	// >>>> This method categorize checkList on Required and Optional section. <<<
	public void categorizeDocument(String key, String value) {
		if (map_DocCategory.containsKey(key)) {
			Set<String> docCategorySet = map_DocCategory.get(key);
			if (!docCategorySet.contains(value)) {
				docCategorySet.add(value);
				map_DocCategory.put(key, docCategorySet);
			}
		} else {
			Set<String> docCategorySet = new Set<String>();
			docCategorySet.add(value);
			map_DocCategory.put(key, docCategorySet);
		}
	}

	//<<<<<<<<<<<<<<<<<<<<Constructor of the Page ENDs<<<<<<<<<<<<<<<<<<<<

	//>>>>>>>>>>>>>>>Wrapper Classes>>>>>>>>>>>>>>>>>>>
	public class BORChecklistWrapper {
		public String strMasterBORChecklistName { get; set; }
		public String strFacilitatorNotes { get; set; }
		public Map<String, BOR_Checklist__c> map_ChecklistWithBenefitType { get; set; }
		public BORChecklistWrapper(String strMasterBORChecklistName, String strFacilitatorNotes) {
			this.strMasterBORChecklistName = strMasterBORChecklistName;
			this.strFacilitatorNotes = strFacilitatorNotes;
			this.map_ChecklistWithBenefitType = new Map<String, BOR_Checklist__c>();
		}
		public void assignBORChecklistWrapper(String strMasterBORChecklistName, BOR_Checklist__c objBORChecklist) {
			if (null != objBORChecklist && String.isNotBlank(objBORChecklist.Carrier_Order_Line_Item__r.Benefit_Types__c)) {
				this.map_ChecklistWithBenefitType.put(objBORChecklist.Carrier_Order_Line_Item__r.Benefit_Types__c, objBORChecklist);
			}
		}
	}
	//>>>>>>>>>>>>>>>Wrapper Classes>>>>>>>>>>>>>>>>>>>

	//>>>>>>>>>>>>>>>Save Completed value on the BOR checklist object>>>>>>>>>>>>>>>>>>>>
	public pageReference saveDocument() {
		ApexPages.getMessages().clear();
		boolean isChildCOStatusChange = false;
		isErrorExist = false;
		if (!map_ChecklistWrapper.isEmpty()) {
			//Map <Document Name, Facilitator notes data>
			Map<String, String> map_DocumentNameWithNotes = new Map<String, String>();
			// List of BOR checklist to Update
			List<BOR_Checklist__c> lst_borChecklistToUpdate = new List<BOR_Checklist__c>();
			isFacilitator2PlanBuildRequired = true;
			isChecklistForEnrollmentReview = true;

			//if the Resign Required field is Yes then Resign Required Reason is mandatory to fill
			if (objCarrierOrder.Resign_Required__c == 'Yes' && String.isBlank(objCarrierOrder.Resign_Required_Reason__c)) {
				Cache.displayErrorMessage('Please Select Resign Required Reason', ApexPages.Severity.ERROR);
				isErrorExist = true;
				return null;
			}

			/*iterate all the Map with wrapper values to get the list of BOR CHecklist to update and 
            Map with <Document Name, Facilitator notes data>
            */
			for (String objDocName : map_ChecklistWrapper.keySet()) {
				if (String.isNotBlank(map_ChecklistWrapper.get(objDocName).strFacilitatorNotes)) {
					map_DocumentNameWithNotes.put(objDocName, map_ChecklistWrapper.get(objDocName).strFacilitatorNotes);
				}
				lst_borChecklistToUpdate.addAll(map_ChecklistWrapper.get(objDocName).map_ChecklistWithBenefitType.values());
			}

			/*iterate all the list of BOR CHecklist to update and add the facilitator notes as per Documnet Name
			 */
			Set<String> set_RequiredDoc = map_DocCategory.get('Required for Plan/Policy Build');
			Set<String> set_EnrollmentRequiredDoc = map_DocCategory.get('Required for Enrollment Review');
			for (BOR_Checklist__c objBORChecklist : lst_borChecklistToUpdate) {
				//Check All doc collect for Plan review or not
				if (isFacilitator2PlanBuildRequired && !objBORChecklist.IsCheckPointImplemented__c && set_RequiredDoc.contains(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c)) {
					isFacilitator2PlanBuildRequired = false;
				}
				//Check All doc collect for Enrollment review or not
				if (isChecklistForEnrollmentReview && !objBORChecklist.IsCheckPointImplemented__c && set_EnrollmentRequiredDoc.contains(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c)) {
					isChecklistForEnrollmentReview = false;
				}
				if (!map_DocumentNameWithNotes.isEmpty() && map_DocumentNameWithNotes.containsKey(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c)) {
					objBORChecklist.Facilitator_Notes__c = map_DocumentNameWithNotes.get(objBORChecklist.BOR_Checkpoints__r.BOR_Checklist_Name__c);
				}
			}

			//if the all the checklist is completed then Facilitator 2 Plan Build is required
			if (isFacilitator2PlanBuildRequired && String.isBlank(objCarrierOrder.Facilitator_2_Plan_Build__c)) {
				Cache.displayErrorMessage('Please Select Facilitator 2 Plan Build', ApexPages.Severity.ERROR);
				isErrorExist = true;
				return null;
			}

			//Update the BOR Checklist
			if (!lst_borChecklistToUpdate.isEmpty()) {
				updateListOfSobject(lst_borChecklistToUpdate);
				//Update staus if no open ticket exist
				if (!isErrorExist && blnOpenTicketExist == false) {
					//Update the Carrier order With field Facilitator plan Bulid
					if (objCarrierOrder.Implementation_Stage__c == 'Collecting Documents' && isFacilitator2PlanBuildRequired == true) {
						if (blnIncompleteCheckList == false || blnParentChildEqualCheckList == true) {
							objCarrierOrder.Implementation_Stage__c = 'Ready for Implementing Plans';
							isChildCOStatusChange = true;
						}
						objCarrierOrder.Checklist_For_Plan_Build__c = true;
					}

					if (isFacilitator2PlanBuildRequired == false) {
						objCarrierOrder.Checklist_For_Plan_Build__c = false;
					}

					if (isChecklistForEnrollmentReview == true) {
						objCarrierOrder.Checklist_For_Enrollment_Review__c = true;
					} else {
						objCarrierOrder.Checklist_For_Enrollment_Review__c = false;
					}
					update objCarrierOrder;
				}
			}

			// >>>> If Current-CO is parent then IF block will execute. <<<<
			// >>>> If Current-CO is child and there is no pending document on Parent and child CO then ELSE-IF block will execute. <<<
			if (blnIsParent) {
				syncParentCOWithChild();
			} else if (objCarrierOrder.Parent_Carrier_Order__c != null && (blnIncompleteCheckList == false || blnParentChildEqualCheckList == true) && isChildCOStatusChange == true) {
				UpdateAllCOStatus(objCarrierOrder.Parent_Carrier_Order__c);
			}
		}
		return null;
	}
	//>>>>>>>>>>>>>>>Save complete document>>>>>>>>>>>>>>>>>>>
	//>>>>>>>>>>>>>>>Update BOR Checklist<<<<<<<<<<<<
	public void updateListOfSobject(List<sObject> lst_borChecklistToUpdate) {
		Savepoint objSavePoint = Database.setSavepoint();
		String strErrorMessage;
		Boolean isAnyRecordFailed = false;
		Database.SaveResult[] lst_UpdateResult = Database.update(lst_borChecklistToUpdate, false);
		// Iterate through each returned result
		for (Database.SaveResult objResult : lst_UpdateResult) {
			if (!objResult.isSuccess()) {
				isAnyRecordFailed = true;
				for (Database.Error objError : objResult.getErrors()) {
					strErrorMessage += objError.getMessage() + ';';
				}
				Database.rollback(objSavePoint);
				if (String.isNotBlank(strErrorMessage)) {
					Cache.displayErrorMessage(strErrorMessage, ApexPages.Severity.ERROR);
					isErrorExist = true;
					ExceptionLogUtil.logException('BTCOFacilitatorChecklistCtrl', 'Update BOR Checklist', strErrorMessage, 'Medium');
				}
			}
		}
		if (!isAnyRecordFailed) {
			Cache.displayErrorMessage('Records Successfully Updated.', ApexPages.Severity.CONFIRM);
		}
	}
	//>>>>>>>>>>>>>>>Update BOR Checklist>>>>>>>>>>>>>>>>>>>

	public void fetchChildCarrierOrder(Id objId, boolean isCurrentCOIsParent) {
		// >>>>  Get all the child carrier order checkList. <<<<
		// >>>> Create a Map, eg: map_childChecklistWrapper. Here key is "Benefit_Types__c" and value is List of "BOR_Checklist__c". <<<<
		map_childCOwithBenefitType = new Map<Id, Set<String>>();
		map_childChecklistWrapper = new Map<String, Map<String, List<BOR_Checklist__c>>>();

		String strQuery =
			'SELECT id, Name, BOR_Checkpoints__c, Carrier_Order_Line_Item__r.Benefit_Types__c,  ' +
			'IsCheckPointImplemented__c, BOR_Checkpoints__r.BOR_Checklist_Name__c, Facilitator_Notes__c,  ' +
			'Check_List_Name__c, Carrier_Order_Line_Item__r.Carrier_Order__c,  ' +
			'Carrier_Order_Line_Item__r.Carrier_Order__r.Facilitator_2_Plan_Build__c,  ' +
			'Carrier_Order_Line_Item__r.Carrier_Order__r.Resign_Required__c,  ' +
			'Carrier_Order_Line_Item__r.Carrier_Order__r.Is_Multi_EIN__c,  ' +
			'Carrier_Order_Line_Item__r.Carrier_Order__r.Parent_Carrier_Order__c,  ' +
			'Carrier_Order_Line_Item__r.Carrier_Order__r.Resign_Required_Reason__c, ' +
			'Carrier_Order_Line_Item__r.Carrier_Order__r.Contribution_per_the_ER__c, ' +
			'Carrier_Order_Line_Item__r.Carrier_Order__r.Implementation_Stage__c, ' +
			'BOR_Checkpoints__r.Sequence__c, BOR_Checkpoints__r.Mandatory__c,  ' +
			'BOR_Checkpoints__r.Optional_Checklist__c ' +
			'FROM BOR_Checklist__c  ';
		if (isCurrentCOIsParent) {
			strQuery = strQuery + ' WHERE Carrier_Order_Line_Item__r.Carrier_Order__r.Parent_Carrier_Order__c= :objId ';
		} else {
			strQuery = strQuery + ' WHERE ( Carrier_Order_Line_Item__r.Carrier_Order__r.Parent_Carrier_Order__c= :objId ' + ' OR Carrier_Order_Line_Item__r.Carrier_Order__c= :objId ) ';
		}
		strQuery = strQuery + 'AND Carrier_Order_Line_Item__r.Carrier_Order__r.Implementation_Stage__c not in:set_ExcludeCO ' + 'ORDER BY BOR_Checkpoints__r.Sequence__c ';
		List<BOR_Checklist__c> lst_BORCheckList = Database.query(strQuery);

		Set<String> set_RequiredDoc = map_DocCategory.get('Required for Plan/Policy Build');
		Set<String> set_EnrollmentRequiredDoc = map_DocCategory.get('Required for Enrollment Review');
		for (BOR_Checklist__c boObj : lst_BORCheckList) {
			//Assigned default value of Map.
			if (!map_childCORequiredDoc.containsKey(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c)) {
				map_childCORequiredDoc.put(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c, true);
			}
			if (!map_childCOEnrollmentReqDoc.containsKey(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c)) {
				map_childCOEnrollmentReqDoc.put(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c, true);
			}

			Map<String, List<BOR_Checklist__c>> map_checkList = null;
			List<BOR_Checklist__c> boList = new List<BOR_Checklist__c>();
			if (map_childChecklistWrapper.containsKey(boObj.Carrier_Order_Line_Item__r.Benefit_Types__c)) {
				map_checkList = map_childChecklistWrapper.get(boObj.Carrier_Order_Line_Item__r.Benefit_Types__c);
			} else {
				map_checkList = new Map<String, List<BOR_Checklist__c>>();
			}

			if (map_checkList.containsKey(boObj.Check_List_Name__c)) {
				boList = map_checkList.get(boObj.Check_List_Name__c);
			} else {
				boList = new List<BOR_Checklist__c>();
			}
			boList.add(boObj);
			map_checkList.put(boObj.Check_List_Name__c, boList);
			map_childChecklistWrapper.put(boObj.Carrier_Order_Line_Item__r.Benefit_Types__c, map_checkList);

			// >>>> If Current-CO is parent OR child-CO having missing document then this block of code will execute. <<<
			// >>>> Else If Current-CO is child then this block of code always execute.<<<
			if (isCurrentCOIsParent == false || !set_BenefitTypeName.contains(boObj.Carrier_Order_Line_Item__r.Benefit_Types__c)) {
				// >>>> This block of maintain two Map<Id,Boolean>, for required doc on child-CO. <<<
				// >>>> map_childCORequiredDoc , set_EnrollmentRequiredDoc. <<<
				if (set_RequiredDoc.contains(boObj.BOR_Checkpoints__r.BOR_Checklist_Name__c)) {
					if (map_childCORequiredDoc.containsKey(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c)) {
						if (map_childCORequiredDoc.get(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c)) {
							map_childCORequiredDoc.put(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c, boObj.IsCheckPointImplemented__c);
						}
					} else {
						map_childCORequiredDoc.put(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c, boObj.IsCheckPointImplemented__c);
					}
				}

				if (set_EnrollmentRequiredDoc.contains(boObj.BOR_Checkpoints__r.BOR_Checklist_Name__c)) {
					// >>>> Check required document in child CO <<<<
					if (map_childCOEnrollmentReqDoc.containsKey(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c)) {
						if (map_childCOEnrollmentReqDoc.get(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c)) {
							map_childCOEnrollmentReqDoc.put(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c, boObj.IsCheckPointImplemented__c);
						}
					} else {
						map_childCOEnrollmentReqDoc.put(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c, boObj.IsCheckPointImplemented__c);
					}
				}
			}

			// >>>> This block of code create a Map as: key = Carrier_Order__c, value = List<Benefit_Types__c> <<<<
			Set<String> set_benefitType = new Set<String>();
			if (map_childCOwithBenefitType.containsKey(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c)) {
				set_benefitType = map_childCOwithBenefitType.get(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c);
			}
			if (set_benefitType.size() == 0 || !set_benefitType.contains(boObj.Carrier_Order_Line_Item__r.Benefit_Types__c)) {
				set_benefitType.add(boObj.Carrier_Order_Line_Item__r.Benefit_Types__c);
				map_childCOwithBenefitType.put(boObj.Carrier_Order_Line_Item__r.Carrier_Order__c, set_benefitType);
			}
		}
	}

	// >>>> This method will execute, when Current-CO is a Parent. This method sync parent-CO with Child-CO. <<<<
	public void syncParentCOWithChild() {
		List<BOR_Checklist__c> lst_childBORCheckList = new List<BOR_Checklist__c>();
		for (String docCategory : set_DocCategory) {
			for (String docName : map_DocCategory.get(docCategory)) {
				for (String benfitType : set_parentBenefitTypeName) {
					if (map_ChecklistWrapper.containsKey(docName)) {
						BORChecklistWrapper wrapperObj = map_ChecklistWrapper.get(docName);
						if (wrapperObj != null && wrapperObj.map_ChecklistWithBenefitType.containsKey(benfitType)) {
							BOR_Checklist__c parentBORObj = wrapperObj.map_ChecklistWithBenefitType.get(benfitType);

							// >>>> sync child check list records - Start <<<<<
							if (map_childChecklistWrapper.containsKey(parentBORObj.Carrier_Order_Line_Item__r.Benefit_Types__c)) {
								Map<String, List<BOR_Checklist__c>> map_checkList = map_childChecklistWrapper.get(parentBORObj.Carrier_Order_Line_Item__r.Benefit_Types__c);
								if (map_checkList.containsKey(parentBORObj.Check_List_Name__c)) {
									for (BOR_Checklist__c childBOObj : map_checkList.get(parentBORObj.Check_List_Name__c)) {
										childBOObj.IsCheckPointImplemented__c = parentBORObj.IsCheckPointImplemented__c;

										if (
											map_parentChildNotes.containsKey(childBOObj.Carrier_Order_Line_Item__r.Carrier_Order__c) &&
											map_parentChildNotes.get(childBOObj.Carrier_Order_Line_Item__r.Carrier_Order__c) == true
										) {
											// If parent and child CO have same CLI.
											childBOObj.Facilitator_Notes__c = parentBORObj.Facilitator_Notes__c;
										}
										lst_childBORCheckList.add(childBOObj);
									}
								}
							}
							// >>>> sync child check list records - End  <<<<<<<
						}
					}
				}
			}
		}

		if (lst_childBORCheckList.size() > 0) {
			update lst_childBORCheckList;
		}

		if (map_childCOwithBenefitType.size() > 0) {
			List<Carrier_Order__c> lst_ChildCO = new List<Carrier_Order__c>();
			for (Id key : map_childCOwithBenefitType.keySet()) {
				Carrier_Order__c objCO = new Carrier_Order__c(Id = key);
				objCO.Implementation_Stage__c = objCarrierOrder.Implementation_Stage__c;

				// >>>>Parent CO benefit-type is superset of Child CO benefit-type then this block of code will execute.<<<<
				// >>>>OR There is no pending document in Child-CO.<<<<
				// >>>>-----Start---<<<<
				if (map_reqCheckList.get(key)) {
					objCO.Checklist_For_Plan_Build__c = true;
				} else {
					objCO.Checklist_For_Plan_Build__c = false;
				}
				if (map_enReqCheckList.get(key)) {
					objCO.Checklist_For_Enrollment_Review__c = true;
				} else {
					objCO.Checklist_For_Enrollment_Review__c = false;
				}
				// >>>>-----End---<<<<

				// >>>>Always update from parent to child. <<<<
				objCO.Facilitator_2_Plan_Build__c = objCarrierOrder.Facilitator_2_Plan_Build__c;
				objCO.Resign_Required__c = objCarrierOrder.Resign_Required__c;
				objCO.Resign_Required_Reason__c = objCarrierOrder.Resign_Required_Reason__c;
				lst_ChildCO.add(objCO);
			}
			update lst_ChildCO;
		}
	}

	// >>>>This method will execute, when Current-CO is a Child-CO. <<<<
	// >>>>This method update status on Parent and Child CO<<<<
	public void UpdateAllCOStatus(Id parentCOId) {
		if (map_childCOwithBenefitType.size() > 0) {
			List<Carrier_Order__c> lst_ChildCO = new List<Carrier_Order__c>();
			for (Id key : map_childCOwithBenefitType.keySet()) {
				if (key != objCarrierOrder.Id) {
					Carrier_Order__c objCO = new Carrier_Order__c(Id = key);
					objCO.Implementation_Stage__c = objCarrierOrder.Implementation_Stage__c;
					if (map_reqCheckList.containsKey(key) && map_reqCheckList.get(key)) {
						objCO.Checklist_For_Plan_Build__c = true;
					}
					if (map_enReqCheckList.containsKey(key) && map_enReqCheckList.get(key)) {
						objCO.Checklist_For_Enrollment_Review__c = true;
					}
					lst_ChildCO.add(objCO);
				}
			}
			update lst_ChildCO;
		}
	}

	// >>>>This method return List<Benefit_Types__c> of Parent-CO. <<<
	// >>>>This method will execute, when Current-CO is a Child-CO. <<<<
	public Set<String> getParentCOBenefitTypeName(Id objCOId) {
		Set<String> set_benefitType = new Set<String>();
		List<Carrier_Order_Line_Item__c> lst_CLI = [SELECT id, Benefit_Types__c FROM Carrier_Order_Line_Item__c WHERE Carrier_Order__c = :objCOId];
		for (Carrier_Order_Line_Item__c cliObj : lst_CLI) {
			set_benefitType.add(cliObj.Benefit_Types__c);
		}
		return set_benefitType;
	}
}