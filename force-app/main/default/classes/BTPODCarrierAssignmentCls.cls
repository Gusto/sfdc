/**
 * @name         BTPODCarrierAssignmentCls
 * @author       Deepika
 * @date         01/11/2019
 * @description  Users can assign the carriers as a POD 1, POD 2, POD 3
 **/
public class BTPODCarrierAssignmentCls {
	public List<SelectOption> lst_PODNames { get; set; }
	//get the POD Name Which user has selected
	public String strSelectedPOD { get; set; }
	//get the List of unassigned Carriers
	public List<CarrierWrapper> lst_UnassignedCarrier { get; set; }
	//get the List of Selected Pod's Carriers
	public List<CarrierWrapper> lst_SelectedAssignedCarrier { get; set; }

	//Static variable to set the Page size
	public static final Integer INT_PAGE_SIZE = 100;
	// StandardSetController To show Unassgined Carriers in Pagination
	public ApexPages.StandardSetController objSetConForUnAssignedCarriers { get; set; }
	// StandardSetController To show Assigned Carriers in Pagination
	public ApexPages.StandardSetController objSetConForAssignedCarriers { get; set; }
	// Instance used for the pagination of Available/Unassigned Carriers
	public Pagination objUnassignedCarrierPagination { get; set; }
	// Instance used for the pagination of Assigned Carriers
	public Pagination objAssignedCarrierPagination { get; set; }

	//list of Unselected States
	public list<System.SelectOption> lst_UnselectedStateValues { get; set; }
	//list of selected States
	public List<System.SelectOption> lst_SelectedStateValues { get; set; }

	//Carrier Name that user Searched in the UI
	public String strSearchName { get; set; }
	//List of Unique Carrier Names
	public List<String> lst_CarrierNamesAutoPopulate { get; set; }
	//Map  used to store the count of records and sum of complexity Score
	public Map<String, Map<String, Integer>> map_CountAndTotalComplexity { get; set; }

	// Carrier Names which are not include in the pod Selection
	Set<String> set_NameNotAllowed = new Set<String>{ 'Other', '%Main Page%' };
	// set the initial field name to sort as Name ASC
	String strFieldNameToSort = 'Name';
	String strDirectionToSort = 'ASC';

	public BTPODCarrierAssignmentCls() {
		lst_UnassignedCarrier = new List<CarrierWrapper>();
		lst_SelectedAssignedCarrier = new List<CarrierWrapper>();
		strSelectedPOD = '';
		map_CountAndTotalComplexity = new Map<String, Map<String, Integer>>();
		//Unique Name
		lst_CarrierNamesAutoPopulate = new List<String>();
		lst_PODNames = new List<SelectOption>();
		lst_PODNames.add(new SelectOption('', '-Select POD-'));
		lst_PODNames.addAll(Cache.getFieldPickListValues('Carrier__c', 'BT_Facilitator_POD__c'));
		//set the Intial Count for Number of record and sum of complexity as 0 for Unassigned
		intialSetCount('Unassigned');

		// get the state
		lst_UnselectedStateValues = Cache.getFieldPickListValues('Carrier__c', 'State__c');
		lst_SelectedStateValues = new List<System.SelectOption>();

		//Get the Unique Carrier Name
		for (AggregateResult objCarrier : [SELECT Name FROM Carrier__c WHERE State__c != NULL AND Partner_Type__c != 'TAdA' AND (NOT Name LIKE :set_NameNotAllowed) GROUP BY Name]) {
			lst_CarrierNamesAutoPopulate.add(String.valueOf(objCarrier.get('Name')));
		}
	}

	//set the Intial Count for Number of record and sum of complexity as 0
	public void intialSetCount(String strPod) {
		Map<String, Integer> map_Temp = new Map<String, Integer>();
		map_Temp.put('SumOfComplexity', 0);
		map_Temp.put('TotalRecord', 0);
		map_CountAndTotalComplexity.put(strPod, map_Temp);
	}

	//count the reocrd of unassigned and complexity scorce of the carriers
	public void countAndSumComplexity(List<Carrier__c> lst_Carrier, String strPod) {
		Integer intNoOfRecords = lst_Carrier.size();
		Integer intSumOfComplexity = 0;
		for (Carrier__c objCarrier : lst_Carrier) {
			if (String.isNotBlank(objCarrier.BoR_Complexity__c))
				intSumOfComplexity += Integer.valueOf(objCarrier.BoR_Complexity__c);
		}
		Map<String, Integer> map_Temp = new Map<String, Integer>();
		if (!map_CountAndTotalComplexity.isEmpty()) {
			if (map_CountAndTotalComplexity.containsKey(strPod))
				map_Temp = map_CountAndTotalComplexity.get(strPod);
		}
		map_Temp.put('SumOfComplexity', intSumOfComplexity);
		map_Temp.put('TotalRecord', intNoOfRecords);
		map_CountAndTotalComplexity.put(strPod, map_Temp);
	}

	public void selectPOD() {
		searchCarrier();
		lst_SelectedAssignedCarrier = new List<CarrierWrapper>();

		if (String.isNotBlank(strSelectedPOD) && strSelectedPOD != 'Unassigned') {
			//set the Intial Count for Number of record and sum of complexity as 0 for Selected pod
			intialSetCount(strSelectedPOD);

			// If the pagination(Selected POD) have value of Sorted field name and direction, then Save in Tempory Value to re assign the same
			if (objAssignedCarrierPagination != null) {
				if (String.isNotBlank(objAssignedCarrierPagination.strFieldNameToSort))
					strFieldNameToSort = objAssignedCarrierPagination.strFieldNameToSort;
				if (String.isNotBlank(objAssignedCarrierPagination.strDirectionToSort))
					strDirectionToSort = objAssignedCarrierPagination.strDirectionToSort;
			}
			String strQueryToExecute = 'SELECT Id, Name, State__c, BT_Facilitator_POD__c, BoR_Complexity__c FROM Carrier__c WHERE BT_Facilitator_POD__c = :strSelectedPOD ORDER BY ';
			strQueryToExecute += strFieldNameToSort + ' ' + strDirectionToSort;
			List<Carrier__c> lst_CarrierWithSelectedPOD = Database.query(strQueryToExecute);
			if (!lst_CarrierWithSelectedPOD.isEmpty()) {
				countAndSumComplexity(lst_CarrierWithSelectedPOD, strSelectedPOD);
				objSetConForAssignedCarriers = new ApexPages.StandardSetController(lst_CarrierWithSelectedPOD);
				objAssignedCarrierPagination = new pagination(objSetConForAssignedCarriers, lst_SelectedAssignedCarrier);
				// If the pagination(Selected POD) have value of Sorted field name and direction, then Save in Tempory Value to re assign the same
				objAssignedCarrierPagination.strFieldNameToSort = strFieldNameToSort;
				objAssignedCarrierPagination.strDirectionToSort = strDirectionToSort;
				objSetConForAssignedCarriers.setPageSize(INT_PAGE_SIZE);

				lst_SelectedAssignedCarrier = objAssignedCarrierPagination.fetchCarriers();
			}
		}
	}

	//remove the Carrier name and State field(used for Search) from the UI
	public void resetSearch() {
		strSearchName = '';
		lst_SelectedStateValues.clear();
		searchCarrier();
		ApexPages.getMessages().clear();
	}

	// Search the Carrier name(multiple using ,) and State name(active only)
	public PageReference searchCarrier() {
		String Query = 'Select Id, Name, State__c, BT_Facilitator_POD__c, BoR_Complexity__c From Carrier__c  ';
		Query += 'Where ( State__c != null AND Partner_Type__c != \'TAdA\' AND (NOT Name LIKE  :set_NameNotAllowed) AND BT_Facilitator_POD__c = \'Unassigned\')';

		if (String.isNotBlank(strSearchName)) {
			strSearchName = strSearchName.trim();
			//Split the Carrier name using comma
			List<String> lst_CarrierNames = strSearchName.split(',');
			if (!lst_CarrierNames.isEmpty()) {
				Integer i = 1;
				for (String searchName : lst_CarrierNames) {
					if (i == 1) {
						Query += ' and (Name like \'%' + searchName + '%\'';
						i++;
					} else {
						Query += ' or Name like \'%' + searchName + '%\'';
					}
				}
				Query += ') ';
			}
		}

		if (!lst_SelectedStateValues.isEmpty()) {
			Query += 'and  State__c in(';
			for (SelectOption selState : lst_SelectedStateValues) {
				Query += '\'' + selState.getValue() + '\',';
			}
			Query = Query.removeEnd(',');
			Query += ') ';
		}

		// If the pagination(Selected POD) have value of Sorted field name and direction, then Save in Tempory Value to re assign the same
		if (objUnassignedCarrierPagination != null) {
			if (String.isNotBlank(objUnassignedCarrierPagination.strFieldNameToSort))
				strFieldNameToSort = objUnassignedCarrierPagination.strFieldNameToSort;
			if (String.isNotBlank(objUnassignedCarrierPagination.strDirectionToSort))
				strDirectionToSort = objUnassignedCarrierPagination.strDirectionToSort;
		}

		String strSortFullExp = strFieldNameToSort + ' ' + strDirectionToSort;

		Query += ' ORDER BY ' + strSortFullExp;
		lst_UnassignedCarrier.clear();
		List<Carrier__c> lst_UnassignedCarrierWithSearch = Database.query(Query);
		if (!lst_UnassignedCarrierWithSearch.isEmpty()) {
			countAndSumComplexity(lst_UnassignedCarrierWithSearch, 'Unassigned');
			objSetConForUnAssignedCarriers = new ApexPages.StandardSetController(lst_UnassignedCarrierWithSearch);
			objUnassignedCarrierPagination = new pagination(objSetConForUnAssignedCarriers, lst_UnassignedCarrier);
			objUnassignedCarrierPagination.strFieldNameToSort = strFieldNameToSort;
			objUnassignedCarrierPagination.strDirectionToSort = strDirectionToSort;
			objSetConForUnAssignedCarriers.setPageSize(INT_PAGE_SIZE);

			lst_UnassignedCarrier = objUnassignedCarrierPagination.fetchCarriers();
		}

		return null;
	}

	/**Method used to update the Selected carrier in Selected POD */
	public void addCarriersToPOD() {
		ApexPages.getMessages().clear();
		if (!lst_UnassignedCarrier.isEmpty()) {
			List<Carrier__c> lst_CarriersToUpdate = new List<Carrier__c>();
			for (CarrierWrapper objCarrierWrapper : lst_UnassignedCarrier) {
				if (objCarrierWrapper.isChecked) {
					Carrier__c objTempCarrier = objCarrierWrapper.objCarrier;
					objTempCarrier.BT_Facilitator_POD__c = strSelectedPOD;
					lst_CarriersToUpdate.add(objTempCarrier);
				}
			}
			if (!lst_CarriersToUpdate.isEmpty()) {
				updateCarrier(lst_CarriersToUpdate, 'addCarriersToPOD');
				searchCarrier();
				selectPOD();
			} else {
				Cache.displayErrorMessage('Select the Carrier to assign ' + strSelectedPOD, ApexPages.Severity.ERROR);
			}
		}
	}

	/**Method used to update the Selected carrier from the Selected POD to Unassigned */
	public void removeCarriersFromPOD() {
		ApexPages.getMessages().clear();
		if (!lst_SelectedAssignedCarrier.isEmpty()) {
			List<Carrier__c> lst_CarriersToUpdate = new List<Carrier__c>();
			for (CarrierWrapper objCarrierWrapper : lst_SelectedAssignedCarrier) {
				if (objCarrierWrapper.isChecked) {
					Carrier__c objTempCarrier = objCarrierWrapper.objCarrier;
					objTempCarrier.BT_Facilitator_POD__c = 'Unassigned';
					lst_CarriersToUpdate.add(objTempCarrier);
				}
			}
			if (!lst_CarriersToUpdate.isEmpty()) {
				//update Carrier
				updateCarrier(lst_CarriersToUpdate, 'removeCarriersFromPOD');
				searchCarrier();
				selectPOD();
			} else {
				Cache.displayErrorMessage('Select the Carrier to remove from ' + strSelectedPOD, ApexPages.Severity.ERROR);
			}
		}
	}

	//update Carrier BT POD Facilities Field of the Carrier
	public void updateCarrier(List<Carrier__c> lst_CarriersToUpdate, String strProcessingCarriers) {
		Savepoint objSavePoint = Database.setSavepoint();
		String strErrorMessage;
		Database.SaveResult[] lst_UpdateResult = Database.update(lst_CarriersToUpdate, false);
		// Iterate through each returned result
		for (Database.SaveResult objResult : lst_UpdateResult) {
			if (!objResult.isSuccess()) {
				for (Database.Error objError : objResult.getErrors()) {
					strErrorMessage += objError.getMessage() + ';';
				}
				Database.rollback(objSavePoint);
				if (String.isNotBlank(strErrorMessage)) {
					Cache.displayErrorMessage(strErrorMessage, ApexPages.Severity.ERROR);
					ExceptionLogUtil.logException('BTPODCarrierAssignmentCls', strProcessingCarriers, strErrorMessage, 'Medium');
				}
			}
		}
	}

	//Wrapper Class used to get the selected and unselected record of Carrier
	public class CarrierWrapper {
		public Boolean isChecked { get; set; }
		public Carrier__c objCarrier { get; set; }
		public CarrierWrapper(Carrier__c objCarrier) {
			this.objCarrier = objCarrier;
			this.isChecked = false;
		}
	}

	//Class to maintain the pagination
	public class pagination {
		public ApexPages.StandardSetController objsetCon { get; set; }
		public List<CarrierWrapper> lst_CarrierForProcessing { get; set; }
		public pagination(ApexPages.StandardSetController stdApexPageCon, List<CarrierWrapper> lst_Carrier) {
			this.objsetCon = stdApexPageCon;
			this.lst_CarrierForProcessing = lst_Carrier;
		}
		public String strDirectionToSort = 'ASC';
		public String sortExp = 'name';
		public String strFieldNameToSort {
			get {
				return sortExp;
			}
			set {
				//if the column is clicked on then switch between Ascending and Descending modes
				if (value == sortExp)
					strDirectionToSort = (strDirectionToSort == 'ASC') ? 'DESC' : 'ASC';
				else
					strDirectionToSort = 'ASC';
				sortExp = value;
			}
		}
		public String getstrDirectionToSort() {
			//if not column is selected
			if (strFieldNameToSort == null || strFieldNameToSort == '')
				return 'ASC';
			else
				return strDirectionToSort;
		}
		public void setstrDirectionToSort(String value) {
			strDirectionToSort = value;
		}

		/** indicates whether there are more records after the current page set.*/
		public Boolean hasNext {
			get {
				return objsetCon.getHasNext();
			}
			set;
		}

		/** indicates whether there are more records before the current page set.*/
		public Boolean hasPrevious {
			get {
				return objsetCon.getHasPrevious();
			}
			set;
		}

		/** returns the page number of the current page set*/
		public Integer pageNumber {
			get {
				return objsetCon.getPageNumber();
			}
			set;
		}

		public Integer getTotalRecord() {
			Decimal decTotalSize = 0;
			if (objsetCon != null) {
				decTotalSize = objsetCon.getResultSize();
			}
			return (Integer) decTotalSize.round(System.RoundingMode.CEILING);
		}

		/** return total number of pages for page set*/
		public Integer getTotalPages() {
			Decimal decTotalSize = objsetCon.getResultSize();
			Decimal decPageSize = objsetCon.getPageSize();
			Decimal decPages = decTotalSize / decPageSize;
			return (Integer) decPages.round(System.RoundingMode.CEILING);
		}

		/** returns the first page of the page set*/
		public void first() {
			objsetCon.first();
			resetList();
		}

		/** returns the last page of the page set*/
		public void last() {
			objsetCon.last();
			resetList();
		}

		/** returns the previous page of the page set*/
		public void previous() {
			objsetCon.previous();
			resetList();
		}

		/** returns the next page of the page set*/
		public void next() {
			objsetCon.next();
			resetList();
		}
		public void resetList() {
			fetchCarriers();
		}
		public List<CarrierWrapper> fetchCarriers() {
			lst_CarrierForProcessing.clear();
			for (Carrier__c objCarrier : (List<Carrier__c>) objsetCon.getRecords()) {
				lst_CarrierForProcessing.add(new CarrierWrapper(objCarrier));
			}
			return lst_CarrierForProcessing;
		}
	}
}