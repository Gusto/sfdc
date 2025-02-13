/*
 * Handles data flow and user operations on PTForecastCreationAndAssignment page
 */
public with sharing class PTForecastCreationAssignmentExtension {
	public Benefit_Order_Allocation__c objBOARef { get; set; } // to show calendar
	public Payroll_Transfer_FBOS_Forecast__c foreCastObj { get; set; } //stores users selected year

	public List<ForecastWrapper> lstForecastWrap { get; set; } // all forecast records and their indices for selected year

	public boolean bln_openForeCastDetailPanel { get; set; } //to toggle cap grid
	public boolean bln_showAddForecast { get; set; } //to toggle add forecast button

	public List<UserAssignmentWrapper> lstUserAssignmentWrap { get; set; } // to hold user assignment for selected month and year

	public List<SelectOption> lstMonths { get; set; } // to show months as a selectList for User assignment
	public String selectedMonth { get; set; } // selected value of Month
	public ForecastWrapper objSelectedFBOS { get; set; } // selected forecast wrapper record for user assignment

	public List<SelectOption> lstFBOSRecordTypes { get; set; } // to show record types for FBOS Forecast
	public String strSelectedFBOSRecordType { get; set; } //selected value of FBOS record type
	public Map<Id, String> mapFBOSRecTypeIDName { get; set; } // key = recordTypeId for FBOS Forecast and value is corresponding Name
	private String idBOARecTypePayroll; // recordTypeId for Payroll REcord type of BOA

	private Map<String, Integer> mapMonthNameToValue = new Map<String, Integer>{
		'January' => 1,
		'February' => 2,
		'March' => 3,
		'April' => 4,
		'May' => 5,
		'June' => 6,
		'July' => 7,
		'August' => 8,
		'September' => 9,
		'October' => 10,
		'November' => 11,
		'December' => 12
	};
	private Boolean boolIsFBOSValid = true;

	public Boolean boolIsAuthUser { get; set; } // to check if user has access to BOA and FBOS objects

	private List<Payroll_Transfer_FBOS_Forecast__c> lst_foreCastObj;

	public Map<Integer, Integer> mapWeeklyAssignedCount { get; set; } // to show already assigned orders count
	//BY:PR, Date:Dec-11-2020, Desc: get the ID
	static Id idFbos_RTId_Facilitator = Cache.getRecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Facilitator');
	//Cache.getRecordTypeName('Payroll_Transfer_FBOS_Forecast__c',strSelectedFBOSRecordType)

	//Added by AKS dated 3rd Dec 2020
	public boolean blnIsFacilitator { get; set; }
	public integer intTotalCountofOrdersAdvocate { get; set; }
	public Map<Integer, Integer> map_WeeklyUnAssignedAIC { get; set; }
	//constructor
	public PTForecastCreationAssignmentExtension(apexPages.StandardController sc) {
		blnIsFacilitator = false;
		//To check if looged in user is authorized to access forecasts and user assignment
		boolIsAuthUser = true;
		Schema.DescribeSObjectResult drFBOS = Schema.sObjectType.Payroll_Transfer_FBOS_Forecast__c;
		Schema.DescribeSObjectResult drBOA = Schema.sObjectType.Benefit_Order_Allocation__c;
		String strAuthMsg = '';
		if (!drFBOS.isCreateable() || !drFBOS.isAccessible() || !drFBOS.isUpdateable()) {
			boolIsAuthUser = false;
			strAuthMsg = 'You are not authorized to access Payroll Transfer Forecast';
		}
		if (!drBOA.isCreateable() || !drBOA.isAccessible() || !drBOA.isUpdateable()) {
			boolIsAuthUser = false;
			strAuthMsg += String.isBlank(strAuthMsg) ? 'You are not authorized to access Benefit Order Allocation' : ' and Benefit Order Allocation';
		}
		if (!boolIsAuthUser) {
			ApexPages.AddMessage(new apexPages.Message(apexPages.Severity.ERROR, strAuthMsg + '. Please make sure you have necessary permissions.'));
			return;
		}
		String strUserRole; // Page parameters passed for user role

		//Read page params
		if (ApexPages.currentPage().getParameters().containsKey('userRole')) {
			strUserRole = ApexPages.currentPage().getParameters().get('userRole');
		}

		foreCastObj = new Payroll_Transfer_FBOS_Forecast__c(id = sc.getId());

		bln_showAddForecast = false;
		lstForecastWrap = new List<ForecastWrapper>();
		lstUserAssignmentWrap = new List<UserAssignmentWrapper>();

		lst_foreCastObj = new List<Payroll_Transfer_FBOS_Forecast__c>();
		if (foreCastObj.id != null) {
			lst_ForeCastObj = [SELECT id, Year__c, RecordTypeId FROM Payroll_Transfer_FBOS_Forecast__c WHERE id = :foreCastObj.id LIMIT 1];
			if (lst_ForeCastObj.size() > 0) {
				foreCastObj = new Payroll_Transfer_FBOS_Forecast__c();
				foreCastObj.Year__c = lst_ForeCastObj.get(0).Year__c;
			}
		} else {
			//If Id not present then fetch records for current year
			foreCastObj = new Payroll_Transfer_FBOS_Forecast__c();
			foreCastObj.Year__c = String.valueOf(system.today().year());
		}
		//Fetch record types for Payroll Forecast
		lstFBOSRecordTypes = new List<SelectOption>();
		mapFBOSRecTypeIDName = new Map<Id, String>();
		List<Schema.RecordTypeInfo> lstRecordTypes = Payroll_Transfer_FBOS_Forecast__c.SObjectType.getDescribe().getRecordTypeInfos();
		if (null != lstRecordTypes && lstRecordTypes.size() > 0) {
			for (Schema.RecordTypeInfo rt : lstRecordTypes) {
				Id idRecType = rt.getRecordTypeId();
				String strRecTypeName = rt.getName();
				mapFBOSRecTypeIDName.put(idRecType, strRecTypeName);
				if (!'Master'.equalsIgnoreCase(strRecTypeName))
					lstFBOSRecordTypes.add(new SelectOption(idRecType, strRecTypeName));

				if (
					String.isnotBlank(strUserRole) &&
					strUserRole.contains(strRecTypeName) // if user role is specified via page params, get corresponding record type
				)
					strSelectedFBOSRecordType = idRecType;
			}

			if (String.isBlank(strSelectedFBOSRecordType))
				strSelectedFBOSRecordType = lstFBOSRecordTypes[0].getValue();

			foreCastObj.RecordTypeId = strSelectedFBOSRecordType;
		}

		//Fetch record type info for BOA
		idBOARecTypePayroll = Benefit_Order_Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Payroll').getRecordTypeId();

		getForecastRecord();

		bln_openForeCastDetailPanel = true;
	}
	/*//Added by AKS dated 3rd Dec 2012
    public PageReference RedirectToFacilitatorInventory(){
        PageReference pg=new PageReference('/apex/PTFacilitator_Inventory_Capacity');
        pg.setRedirect(true);
        return pg;
    }*/
	// we are retreving forecast records
	public void getForecastRecord() {
		//Added by AKS Dated 3rd Dec 2020
		blnIsFacilitator = false;
		//BY:PR, Date:Dec-11-2020, Desc: introduced the static variable to compare
		if (string.isNotBlank(strSelectedFBOSRecordType) && strSelectedFBOSRecordType == idFbos_RTId_Facilitator) {
			//Cache.getRecordTypeName('Payroll_Transfer_FBOS_Forecast__c',strSelectedFBOSRecordType)=='Facilitator'
			blnIsFacilitator = true;
		}
		if (string.isBlank(foreCastObj.Year__c)) {
			bln_showAddForecast = false;
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Year field can not be blank.'));
			return;
		} else {
			bln_showAddForecast = true;
		}
		objBOARef = new Benefit_Order_Allocation__c(Week_Start_Date__c = Date.newInstance(Integer.valueOf(foreCastObj.Year__c), system.today().month(), 1));
		lst_foreCastObj = new List<Payroll_Transfer_FBOS_Forecast__c>();
		list<Payroll_Transfer_FBOS_Forecast__c> lst_tempForeCast = [
			SELECT
				id,
				FBOS_Forecast__c,
				Fifth_Week_Cap__c,
				First_week_cap__c,
				Forecast_Multiplier__c,
				Fourth_Week_Cap__c,
				Month__c,
				Second_week_cap__c,
				Third_week_cap__c,
				Total_Month_Cap__c,
				Year__c,
				RecordType.NAme,
				RecordTypeId
			FROM Payroll_Transfer_FBOS_Forecast__c
			WHERE Year__c = :foreCastObj.Year__c AND RecordTypeId = :strSelectedFBOSRecordType
			ORDER BY Month__c ASC
		];

		if (lst_tempForeCast.size() > 0) {
			lst_foreCastObj = lst_tempForeCast;
		}

		if (lst_tempForeCast.size() >= 12) {
			bln_showAddForecast = false;
		}
		initForecastWrapperList(lst_foreCastObj);

		bln_openForeCastDetailPanel = true;
	}
	/*
	 * populate forecastWRapper list
	 */
	private void initForecastWrapperList(List<Payroll_Transfer_FBOS_Forecast__c> lst_foreCastObj) {
		//populate wrapper list
		lstForecastWrap = new List<ForecastWrapper>();
		// mapDaysCountPerWeekForMonths = new Map<String,Map<Integer,Integer>>();
		for (Integer indx = 0; indx < lst_foreCastObj.size(); indx++) {
			Payroll_Transfer_FBOS_Forecast__c objFCST = lst_foreCastObj[indx];
			ForecastWrapper fwrap = new ForecastWrapper(indx, objFCST);
			fwrap.calcWeekDetailsForEachMonth();
			lstForecastWrap.add(fwrap);
		}
	}

	//inserting new line
	public void insertNewForecastRecord() {
		lstForecastWrap.add(new ForecastWrapper(lstForecastWrap.size(), new Payroll_Transfer_FBOS_Forecast__c(Year__c = foreCastObj.Year__c, RecordTypeId = strSelectedFBOSRecordType)));

		if (lstForecastWrap.size() == 12) {
			bln_showAddForecast = false;
		}
	}
	public Integer intIndxToBeUpdated { get; set; }
	//On change of month in FBOS
	public void onMonthChange() {
		ForecastWrapper fwrap = lstForecastWrap[intIndxToBeUpdated];
		fwrap.calcWeekDetailsForEachMonth();
	}
	//removing selected line
	public Integer intIndxToBeRemoved { get; set; }
	private Set<Id> setForecastsToBeDeleted = new Set<Id>(); // Ids for forecast records that are to be deleted
	public void removeForecastRecord() {
		try {
			// If forecast row being removed is existing in database, then note its Id.
			if (lstForecastWrap[intIndxToBeRemoved].objForecast.Id != null) {
				setForecastsToBeDeleted.add(lstForecastWrap[intIndxToBeRemoved].objForecast.Id);
				Payroll_Transfer_FBOS_Forecast__c objFBOSToDelete = lstForecastWrap[intIndxToBeRemoved].objForecast;

				//delete corresponding BOAs
				List<Benefit_Order_Allocation__c> lstBOA = Database.query('SELECT Id FROM Benefit_Order_Allocation__c WHERE Payroll_Transfer_FBOS_Forecast__c IN :setForecastsToBeDeleted');
				if (null != lstBOA && lstBOA.size() > 0) {
					Map<Id, Benefit_Order_Allocation__c> mapBOA = new Map<Id, Benefit_Order_Allocation__c>(lstBOA);
					setForecastsToBeDeleted.addAll(mapBOA.keySet()); // delete corresponsing BOA records as well
				}

				Database.delete(new List<Id>(setForecastsToBeDeleted), false);

				//reset setForecastsToBeDeleted
				setForecastsToBeDeleted = new Set<Id>();
			}
			//remove deleted row from wrapperList
			lstForecastWrap.remove(intIndxToBeRemoved);

			//reassign indices to the wrapper instances
			Integer indx = 0;
			for (ForecastWrapper wrap : lstForecastWrap) {
				wrap.intIndx = indx;
				indx++;
			}
			if (lstForecastWrap.size() < 12 && !bln_showAddForecast) {
				bln_showAddForecast = true;
			}
		} catch (Exception exp) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, exp.getMessage()));
		}
	}

	//upsert the forecast records displayed on screen
	public void upsertForecastRecords() {
		boolIsFBOSValid = true;
		list<Payroll_Transfer_FBOS_Forecast__c> lst_toUpsertForecastRecords = new List<Payroll_Transfer_FBOS_Forecast__c>();
		set<string> set_months = new Set<string>{ 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' };

		for (ForecastWrapper foreCastWrap : lstForecastWrap) {
			Payroll_Transfer_FBOS_Forecast__c foreCastRec = foreCastWrap.objForecast;
			foreCastRec.Year__c = foreCastObj.Year__c;

			if (foreCastRec.Month__c != null) {
				//set unique identifier
				foreCastRec.Forecast_Unique_Identifier__c = foreCastRec.RecordTypeId + '' + foreCastRec.Year__c + '' + foreCastRec.Month__c;

				if (set_months.contains(foreCastRec.Month__c)) {
					lst_toUpsertForecastRecords.add(foreCastRec);
					set_months.remove(foreCastRec.Month__c);
				} else {
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Duplicate month in a single year is not allowed.'));
					boolIsFBOSValid = false;
					return;
				}
			} else {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Month value is required to save the forecast.'));
				boolIsFBOSValid = false;
				return;
			}
		}
		try {
			if (lst_toUpsertForecastRecords.size() > 0) {
				validateFBOSRecords(lstForecastWrap);
				if (boolIsFBOSValid) {
					upsert lst_toUpsertForecastRecords;
					initForecastWrapperList(lst_toUpsertForecastRecords);
				} else
					return;
			}
		} catch (exception ex) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, ex.getMessage()));
			return;
		}
		ApexPages.AddMessage(new apexPages.Message(apexPages.Severity.INFO, 'Forecast saved successfully.'));
	}
	/*
	 * Validate forecast records
	 * Neha Dabas, 10 September 2019
	 */
	private void validateFBOSRecords(List<ForecastWrapper> lstFWrap) {
		if (null != lstFWrap && lstFWrap.size() > 0) {
			for (ForecastWrapper foreCastWrap : lstFWrap) {
				Payroll_Transfer_FBOS_Forecast__c objFCast = foreCastWrap.objForecast;
				Integer intWkTotal = 0;
				intWkTotal += objFCast.First_Week_Cap__c != null ? Integer.valueOF(objFCast.First_Week_Cap__c) : 0;
				intWkTotal += objFCast.Second_Week_Cap__c != null ? Integer.valueOF(objFCast.Second_Week_Cap__c) : 0;
				intWkTotal += objFCast.Third_Week_Cap__c != null ? Integer.valueOF(objFCast.Third_Week_Cap__c) : 0;
				intWkTotal += objFCast.Fourth_Week_Cap__c != null ? Integer.valueOF(objFCast.Fourth_Week_Cap__c) : 0;
				intWkTotal += objFCast.Fifth_Week_Cap__c != null ? Integer.valueOF(objFCast.Fifth_Week_Cap__c) : 0;

				if (intWkTotal != foreCastWrap.intTotalMonthCap) {
					ApexPages.AddMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Number of orders distributed in weeks donot match with Total Month Cap for ' + objFCast.Month__c));
					boolIsFBOSValid = false;
				}
			}
		}
	}
	/*
	 * Fetch Advocate records and construct the UserAssignmentCap
	 * Neha Dabas, 6 September 2019
	 */
	public void fetchAdvocates() {
		intTotalCountofOrdersAdvocate = 0;
		lstUserAssignmentWrap = new List<UserAssignmentWrapper>();
		mapWeeklyAssignedCount = new Map<Integer, Integer>{ 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 };
		//check if month vaue is selected
		if (String.isBlank(selectedMonth)) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Please select a month to proceed with User Assignment.'));
			return;
		}
		Integer intMon;
		Integer indxFBOS = Integer.valueOf(selectedMonth);
		if (lstForecastWrap.size() >= indxFBOS) {
			objSelectedFBOS = lstForecastWrap[indxFBOS];
			intMon = mapMonthNameToValue.get(objSelectedFBOS.objForecast.Month__c);
		}
		Payroll_Transfer_FBOS_Forecast__c objForecast = objSelectedFBOS.objForecast;
		Integer intYear = Integer.valueOf(objForecast.Year__c);
		Id selectedFBOSID = objForecast.Id;

		//Set calendar to first day of selected month
		objBOARef.Week_Start_Date__c = Date.newInstance(intYear, intMon, 1);

		//Fetch existing Benefit_Order_Allocation records for selected month and year
		String strRecTpeName = mapFBOSRecTypeIDName.get(strSelectedFBOSRecordType);
		String strBOAQuery = 'SELECT Open_Order_Employee_Count__c,Inactive_Employee_Count__c,Contractor_Count__c,Role_Type__c,Open_Order_Count__c,User_Role__r.User__c,User_Role__r.User__r.FirstName,User_Role__r.User__r.LastName,Month__c,Payroll_Transfer_FBOS_Forecast__c,User__c,User_Role__c,Week_End_Date__c,Week_Order_Capacity__c,Week_Start_Date__c,Working_days__c,Year__c FROM Benefit_Order_Allocation__c WHERE Month__c =:intMon AND Year__c=:intYear AND Payroll_Transfer_FBOS_Forecast__c = :selectedFBOSID AND RecordType.Name=\'Payroll\' AND Role_Type__c= :strRecTpeName ORDER BY Week_Start_Date__c ASC,User_Role__r.User__r.Name ASC';

		List<Benefit_Order_Allocation__c> lstBOAllocation = Database.query(strBOAQuery);

		Set<Id> setUserId = new Set<Id>();
		Map<Id, Map<Date, Benefit_Order_Allocation__c>> mapUserToBOA = new Map<Id, Map<Date, Benefit_Order_Allocation__c>>(); //segregate BOA records based on user
		//To keep track of existing user records
		Integer existingBOACount = 0;
		if (!lstBOAllocation.isEmpty()) {
			existingBOACount = lstBOAllocation.size();

			for (Benefit_Order_Allocation__c BOAlloc : lstBOAllocation) {
				setUserId.add(BOAlloc.User_Role__r.User__c); // Id of users for which there are records in BOA

				Map<Date, Benefit_Order_Allocation__c> mapBOA;
				if (mapUserToBOA.containsKey(BOAlloc.User_Role__r.User__c)) {
					mapBOA = mapUserToBOA.get(BOAlloc.User_Role__r.User__c);
				} else
					mapBOA = new Map<Date, Benefit_Order_Allocation__c>();

				mapBOA.put(BOAlloc.Week_Start_Date__c, BOAlloc);
				mapUserToBOA.put(BOAlloc.User_Role__r.User__c, mapBOA);
			}
			//Construct AssignmentWrapper
			for (Id userId : mapUserToBOA.keySet()) {
				lstUserAssignmentWrap.add(new UserAssignmentWrapper(mapUserToBOA.get(userId), objSelectedFBOS.mapWeekDetails, mapWeeklyAssignedCount, strRecTpeName));
			}

			//Added by AKS Dated 7th Dec 2020. Calculate Total Assigned Orders for Advocate
			if (blnIsFacilitator == false && mapWeeklyAssignedCount != null && mapWeeklyAssignedCount.size() > 0) {
				for (integer iCount : mapWeeklyAssignedCount.keySet()) {
					intTotalCountofOrdersAdvocate = intTotalCountofOrdersAdvocate + mapWeeklyAssignedCount.get(iCount);
				}
			}
		}

		//Fetch users
		List<User_Skill__c> lstUsers = new List<User_Skill__c>();
		String strUserRoleName = 'Advocate'.equalsIgnoreCase(strRecTpeName) ? 'Payroll Transfer Advocate' : 'Payroll Transfer Facilitator';
		String strUserQuery = 'SELECT User_Role__r.User__r.FirstName,User_Role__r.User__r.LastName,User_Role__r.User__c,User_Role__c FROM User_Skill__c WHERE  User_Role__r.User__r.IsActive = true';
		if (null != setUserId && setUserId.size() > 0) {
			strUserQuery += ' AND User_Role__r.User__c NOT IN :setUserId';
		}
		if (String.isNotBlank(strUserRoleName)) {
			strUserQuery += ' AND Skill__r.Role__r.Name = :strUserRoleName';
		}
		strUserQuery += ' Order By User_Role__r.User__r.Name ASC';

		lstUsers = Database.query(strUserQuery);
		Map<Id, User_Skill__c> mapUserIdToSkills = new Map<Id, User_Skill__c>(); // to make sure only one entry is created for each user.

		Map<Integer, Integer> mapWkAssignedOrders = new Map<Integer, Integer>{ 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }; // to keep track of how many orders have been distributed amongst users per week

		if (!lstUsers.isEmpty() && null != objSelectedFBOS) {
			for (User_Skill__c userSkl : lstUsers) {
				mapUserIdToSkills.put(userSkl.User_Role__r.User__c, userSkl);
			}
			Integer intNoOfAdvocates = lstBOAllocation.isEmpty() ? mapUserIdToSkills.size() : 0;
			Integer indx = 0;
			for (User_Skill__c userSkl : mapUserIdToSkills.values()) {
				UserAssignmentWrapper uWrap = new UserAssignmentWrapper(
					indx,
					userSkl,
					objSelectedFBOS.objForecast,
					intNoOfAdvocates,
					objSelectedFBOS.mapDaysInWeek,
					objSelectedFBOS.mapWeekDetails,
					idBOARecTypePayroll,
					strRecTpeName,
					mapWkAssignedOrders
				);
				lstUserAssignmentWrap.add(uWrap);
				indx++;
			}
			if (existingBOACount == 0) {
				for (Integer wk : objSelectedFBOS.mapDaysInWeek.keySet()) {
					Integer wkForecast = 0;
					Payroll_Transfer_FBOS_Forecast__c objFCast = objSelectedFBOS.objForecast;
					if (wk == 1 && null != objFCast.First_week_cap__c) {
						wkForecast = Integer.valueOf(objFCast.First_week_cap__c);
					}
					if (wk == 2 && null != objFCast.Second_week_cap__c) {
						wkForecast = Integer.valueOf(objFCast.Second_week_cap__c);
					}
					if (wk == 3 && null != objFCast.Third_week_cap__c) {
						wkForecast = Integer.valueOf(objFCast.Third_week_cap__c);
					}
					if (wk == 4 && null != objFCast.Fourth_week_cap__c) {
						wkForecast = Integer.valueOf(objFCast.Fourth_week_cap__c);
					}
					if (wk == 5 && null != objFCast.Fifth_week_cap__c) {
						wkForecast = Integer.valueOf(objFCast.Fifth_week_cap__c);
					}

					if (mapWkAssignedOrders.get(wk) < wkForecast && lstUserAssignmentWrap.size() > 0) {
						Integer orderIndx = 0, remainingOrders = wkForecast - mapWkAssignedOrders.get(wk);
						Integer userIndx = 0;
						while (orderIndx < remainingOrders) {
							if (userIndx == lstUserAssignmentWrap.size()) {
								userIndx = 0;
							}
							Benefit_Order_Allocation__c objBOAWk = lstUserAssignmentWrap[userIndx].mapWeekToBOA.get(wk);
							objBOAWk.Week_Order_Capacity__c += 1;
							lstUserAssignmentWrap[userIndx].mapWeekToBOA.put(wk, objBOAWk);

							orderIndx++;

							userIndx++;
						}
					}
				}
			}
		}
		//Get Unassigned AIC Count for facilitator
		if (blnIsFacilitator == true) {
			fetchOrders();
		}
	}
	/*
	 * Show user assignment section
	 * Neha Dabas, 6 September 2019
	 */
	public void showUserAssignmentSection() {
		upsertForecastRecords(); // first save the forecast BOS records

		if (boolIsFBOSValid) {
			bln_openForeCastDetailPanel = false;

			//Populate months list based on FBOS Wrapper List
			initMonthsForBOA();
		}
	}
	private void initMonthsForBOA() {
		//Populate months list based on FBOS Wrapper List
		lstMonths = new List<SelectOption>();
		if (!lstForecastWrap.isEmpty()) {
			Integer intCurrMonth = system.now().month();
			selectedMonth = '';
			for (ForecastWrapper fWrap : lstForecastWrap) {
				lstMonths.add(new SelectOption('' + fWrap.intIndx, fWrap.objForecast.Month__c));

				Integer intforeCastMonth = mapMonthNameToValue.get(fWrap.objForecast.Month__c);
				if (intCurrMonth == intforeCastMonth) {
					selectedMonth = '' + fWrap.intIndx;
				}
			}
			if (String.isBlank(selectedMonth))
				selectedMonth = lstMonths[0].getValue();
			fetchAdvocates();

			//Get All Orders
			if (blnIsFacilitator == true) {
				fetchOrders();
			}
		}
	}
	//Added by AKS Dated 7th Dec 2020 to calulate Unassigned Count for facilitator

	private void fetchOrders() {
		map_WeeklyUnAssignedAIC = new Map<Integer, Integer>();
		List<Order> list_Order = [
			SELECT id, OwnerId, Owner.Name, Data_Entry_Assist__c, Status, Total_AIC_Count__c, Facilitator_Due_Date__c, Contractor_Count__c, Inactive_Employee_Count__c, Active_Employee_Count__c
			FROM Order
			WHERE
				Facilitator_Due_Date__c >= :objSelectedFBOS.dtStartDateOfMonth
				AND Facilitator_Due_Date__c <= :objSelectedFBOS.dtEndDateOfMonth
				AND Assign_Facilitator__c = TRUE
				AND Data_Entry_Assist__c = NULL
		];
		//Calculate Weekly unAssigned AIC Count
		for (integer intWeek : objSelectedFBOS.mapWeekDetails.keySet()) {
			Map<string, date> map_Weekdate = objSelectedFBOS.mapWeekDetails.get(intWeek);
			//Get Start Date of the Week
			Date dtStartDateofTheWeek = map_Weekdate.get('Start');
			//get End date of the week
			Date dtEndDateofTheWeek = map_Weekdate.get('End');

			integer intTotalUnAssignedAICCount = 0;
			for (Order objOrder : list_Order) {
				if (objOrder.Facilitator_Due_Date__c >= dtStartDateofTheWeek && objOrder.Facilitator_Due_Date__c <= dtEndDateofTheWeek) {
					intTotalUnAssignedAICCount = intTotalUnAssignedAICCount + integer.valueof(objOrder.Total_AIC_Count__c);
				}
			}

			//Add Total UnAssigned AIC
			map_WeeklyUnAssignedAIC.put(intWeek, intTotalUnAssignedAICCount);
		}
		//BY:AKS, Date: Dec-14-2020, Desc: Check for 5th week data
		if (map_WeeklyUnAssignedAIC != null && map_WeeklyUnAssignedAIC.containsKey(5) == false) {
			map_WeeklyUnAssignedAIC.put(5, 0);
		}
	}
	/*
	 * Show FBOS Details
	 * Neha Dabas, 6 September 2019
	 */
	public void showFBOSSection() {
		bln_openForeCastDetailPanel = true;
	}

	/*
	 * Save Benefit Order Allocation records
	 * Neha Dabas, 9 September 2019
	 */
	public void upsertBOARecords() {
		try {
			// validate forecast record before updating in database
			boolIsFBOSValid = true;
			validateFBOSRecords(new List<ForecastWrapper>{ objSelectedFBOS });
			if (boolIsFBOSValid) {
				update objSelectedFBOS.objForecast;
			} else {
				return;
			}
			if (validateBOARecords()) {
				List<Benefit_Order_Allocation__c> lstBOAToUpsert = new List<Benefit_Order_Allocation__c>();
				for (UserAssignmentWrapper objUWrap : lstUserAssignmentWrap) {
					lstBOAToUpsert.addAll(objUWrap.mapWeekToBOA.values());
				}
				if (lstBOAToUpsert.size() > 0) {
					upsert lstBOAToUpsert;
					ApexPages.AddMessage(new ApexPages.Message(apexPages.Severity.INFO, 'User Assignment Saved Successfuly. '));
				}
			}
		} catch (Exception objExc) {
			ApexPages.AddMessage(new ApexPages.Message(apexPages.Severity.ERROR, objExc.getMessage()));
		}
	}
	/*
	 * Validate BOA details
	 * Neha Dabas, 10 September 2019
	 */
	private Boolean validateBOARecords() {
		Boolean bolValid = true;
		if (null != lstUserAssignmentWrap && lstUserAssignmentWrap.size() > 0) {
			Map<Integer, Decimal> mapTotalOrdersPerWk = new Map<Integer, Decimal>();
			for (UserAssignmentWrapper objUWrap : lstUserAssignmentWrap) {
				for (Integer wk : objUWrap.mapWeekToBOA.keySet()) {
					Decimal total = 0;
					if (mapTotalOrdersPerWk.containsKey(wk)) {
						total = mapTotalOrdersPerWk.get(wk);
					}
					total += objUWrap.mapWeekToBOA.get(wk).Week_Order_Capacity__c;
					mapTotalOrdersPerWk.put(wk, total);
				}
			}
			Payroll_Transfer_FBOS_Forecast__c objFCST = objSelectedFBOS.objForecast;

			if (null != objFCST.First_Week_Cap__c && mapTotalOrdersPerWk.get(1) != objFCST.First_Week_Cap__c) {
				ApexPages.AddMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Total of Order Forecast for Week 1 should be equal to First Week Cap.'));
				bolValid = false;
			}
			if (null != objFCST.Second_Week_Cap__c && mapTotalOrdersPerWk.get(2) != objFCST.Second_Week_Cap__c) {
				ApexPages.AddMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Total of Order Forecast for Week 2 should be equal to Second Week Cap.'));
				bolValid = false;
			}
			if (null != objFCST.Third_Week_Cap__c && mapTotalOrdersPerWk.get(3) != objFCST.Third_Week_Cap__c) {
				ApexPages.AddMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Total of Order Forecast for Week 3 should be equal to Third Week Cap.'));
				bolValid = false;
			}
			if (null != objFCST.Fourth_Week_Cap__c && mapTotalOrdersPerWk.get(4) != objFCST.Fourth_Week_Cap__c) {
				ApexPages.AddMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Total of Order Forecast for Week 4 should be equal to Fourth Week Cap.'));
				bolValid = false;
			}
			if (null != objFCST.Fifth_Week_Cap__c && mapTotalOrdersPerWk.get(5) != objFCST.Fifth_Week_Cap__c) {
				ApexPages.AddMessage(new ApexPages.Message(apexPages.Severity.ERROR, 'Total of Order Forecast for Week 5 should be equal to Fifth Week Cap.'));
				bolValid = false;
			}
		}
		return bolValid;
	}
	/*
	 * On change of year in BOA section, fetch both Forecast and BOA details
	 * Neha Dabas, 9 September 2019
	 */
	public void getForeCastAndBOARecords() {
		lstUserAssignmentWrap = new List<UserAssignmentWrapper>();
		getForecastRecord();
		if (lstForecastWrap == null || lstForecastWrap.size() == 0) {
			return;
		}
		initMonthsForBOA();
		bln_openForeCastDetailPanel = false;
	}
	/*
	 * Wrapper to facilitate dynamic row addition and removal
	 * Neha Dabas, 4 September 2019
	 */
	public class ForecastWrapper {
		public Integer intIndx { get; set; }
		public Payroll_Transfer_FBOS_Forecast__c objForecast { get; set; }
		public Map<Integer, Integer> mapDaysInWeek { get; set; }
		public Map<Integer, Map<String, Date>> mapWeekDetails { get; set; }
		//Added by AKS dated 7th Dec 2020
		public Date dtStartDateOfMonth { get; set; }
		public Date dtEndDateOfMonth { get; set; }
		public Integer intTotalMonthCap {
			get {
				Integer totalOrders;
				try {
					if (null != objForecast.FBOS_Forecast__c) {
						totalOrders = Math.round(objForecast.FBOS_Forecast__c * objForecast.Forecast_Multiplier__c / 100);
						//Set week cap automatically for the first time considering the number of working days in that week
						if (
							null == objForecast.First_Week_Cap__c &&
							null == objForecast.Second_Week_Cap__c &&
							null == objForecast.Third_Week_Cap__c &&
							null == objForecast.Fourth_Week_Cap__c &&
							null == objForecast.Fifth_Week_Cap__c
						) {
							//Calculate total working days in month
							Integer intTotalWorkingDays = 0;
							if (mapDaysInWeek.size() > 0) {
								for (Integer wrkingDay : mapDaysInWeek.values()) {
									intTotalWorkingDays += wrkingDay;
								}
								//Calculate no. of orders to be processed per working day
								Integer intOrderPerDay = totalOrders / intTotalWorkingDays;

								Integer intDistributedOrders = 0;
								if (intOrderPerDay > 0) {
									//Distribute orders based on week capacity
									objForecast.First_Week_Cap__c = mapDaysInWeek.get(1) * intOrderPerDay;
									objForecast.Second_Week_Cap__c = mapDaysInWeek.get(2) * intOrderPerDay;
									objForecast.Third_Week_Cap__c = mapDaysInWeek.get(3) * intOrderPerDay;
									objForecast.Fourth_Week_Cap__c = mapDaysInWeek.get(4) * intOrderPerDay;

									intDistributedOrders = Integer.valueOf(
										objForecast.First_Week_Cap__c + objForecast.Second_Week_Cap__c + objForecast.Third_Week_Cap__c + objForecast.Fourth_Week_Cap__c
									);

									if (mapDaysInWeek.containsKey(5)) {
										objForecast.Fifth_Week_Cap__c = mapDaysInWeek.get(5) * intOrderPerDay;
										intDistributedOrders += Integer.valueOf(objForecast.Fifth_Week_Cap__c);
									}
								} else {
									objForecast.First_Week_Cap__c = 0;
									objForecast.Second_Week_Cap__c = 0;
									objForecast.Third_Week_Cap__c = 0;
									objForecast.Fourth_Week_Cap__c = 0;
									objForecast.Fifth_Week_Cap__c = 0;
								}
								//distribute remaining orders amongst weeks
								while (intDistributedOrders < totalOrders) {
									if (intOrderPerDay != 0 || mapDaysInWeek.get(1) >= objForecast.First_Week_Cap__c) {
										objForecast.First_Week_Cap__c += 1;
										intDistributedOrders++;
									}
									if (intDistributedOrders < totalOrders && (intOrderPerDay != 0 || mapDaysInWeek.get(2) >= objForecast.Second_Week_Cap__c)) {
										objForecast.Second_Week_Cap__c += 1;
										intDistributedOrders++;
									}
									if (intDistributedOrders < totalOrders && (intOrderPerDay != 0 || mapDaysInWeek.get(3) >= objForecast.Third_Week_Cap__c)) {
										objForecast.Third_Week_Cap__c += 1;
										intDistributedOrders++;
									}
									if (intDistributedOrders < totalOrders && (intOrderPerDay != 0 || mapDaysInWeek.get(4) >= objForecast.Fourth_Week_Cap__c)) {
										objForecast.Fourth_Week_Cap__c += 1;
										intDistributedOrders++;
									}
									if (intDistributedOrders < totalOrders && mapDaysInWeek.containsKey(5) && (intOrderPerDay != 0 || mapDaysInWeek.get(5) >= objForecast.Fifth_Week_Cap__c)) {
										objForecast.Fifth_Week_Cap__c += 1;
										intDistributedOrders++;
									}
								}
							}
						}
					}
				} catch (exception ex) {
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, ex.getMessage()));
				}
				return totalOrders;
			}
			set;
		}

		public Integer intNoOfWeeks {
			get {
				if (null != mapDaysInWeek) {
					return mapDaysInWeek.size();
				}
				return 0;
			}
			set;
		}
		public ForecastWrapper() {
		}
		public ForecastWrapper(Integer indx, Payroll_Transfer_FBOS_Forecast__c objFCast) {
			intIndx = indx;
			objForecast = objFCast;
			mapWeekDetails = new Map<Integer, Map<String, Date>>();
			mapDaysInWeek = new Map<Integer, Integer>();
			if (null == objForecast.Forecast_Multiplier__c)
				objForecast.Forecast_Multiplier__c = 100; // Set multiplier to 100 by default
		}

		public void calcWeekDetailsForEachMonth() {
			if (null != objForecast.Month__c && null != objForecast.Year__c) {
				mapWeekDetails = new Map<Integer, Map<String, Date>>();
				mapDaysInWeek = new Map<Integer, Integer>();
				Map<String, Integer> mapMonthNameToValue = new Map<String, Integer>{
					'January' => 1,
					'February' => 2,
					'March' => 3,
					'April' => 4,
					'May' => 5,
					'June' => 6,
					'July' => 7,
					'August' => 8,
					'September' => 9,
					'October' => 10,
					'November' => 11,
					'December' => 12
				};
				Integer selectedMon = mapMonthNameToValue.get(objForecast.Month__c);
				Integer year = Integer.valueOf(objForecast.Year__c);

				Map<String, Integer> mapWeekDay = new Map<String, Integer>{ 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6, 'Sun' => 7 };
				Map<Integer, Integer> mapWeekDayNextVal = new Map<Integer, Integer>{ 1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 1, 6 => 1, 7 => 1 };

				Date dtFirstDay = Date.newInstance(year, selectedMon, 1); // First day of selected month
				dtStartDateOfMonth = dtFirstDay;

				Integer intDaysInMon = Date.daysInMonth(year, selectedMon); // #days in selected month
				Date dtLastDay = Date.newInstance(year, selectedMon, intDaysInMon); // last day of month
				dtEndDateOfMonth = dtLastDay;

				DateTime fdDateTime = DateTime.newInstance(dtFirstDay, Time.newInstance(0, 0, 0, 0)); // datetime value of first day

				String dayOfWeek = fdDateTime.format('E'); // day of week for 1st day ie. Mon,Tue,Wed etc

				Integer intWkDay = mapWeekDay.get(dayOfWeek); // day of week value ie. 1,2,3...etc
				Integer indx = 0, intWkNumber = 1; //indx is used to identify start of a week and count for no. of working days in a week

				// if 1st day of month is a weekend then start with first monday of that month
				if (intWkDay > 5) {
					Integer daysToNxtMonday = 7 - intWkDay + 1;
					intWkDay = 1;
					dtFirstDay = dtFirstDay.addDays(daysToNxtMonday);
				}

				// loop iterates till end of month
				while (dtFirstDay <= dtLastDay) {
					if (indx == 0 && intWkDay < 6) {
						//WeekStart
						mapWeekDetails.put(intWkNumber, new Map<String, Date>{ 'Start' => dtFirstDay });
					}
					//current day is friday or last day of month
					if (intwkDay == 5 || dtFirstDay == dtLastDay) {
						Map<String, Date> mapDates = mapWeekDetails.get(intWkNumber);
						mapDates.put('End', dtFirstDay);
						mapWeekDetails.put(intWkNumber, mapDates);
						//Integer noOfDaysInWk = mapDates.get('Start').daysBetween(dtFirstDay);
						mapDaysInWeek.put(intWkNumber, indx + 1);
						// Re initialize loop variables for next week
						intWkNumber++;
						indx = 0;
						intwkDay = 1;
						dtFirstDay = Date.newInstance(dtFirstDay.year(), dtFirstDay.month(), dtFirstDay.day() + 3);
					} else {
						indx++;
						dtFirstDay = Date.newInstance(dtFirstDay.year(), dtFirstDay.month(), dtFirstDay.day() + 1);
						intwkDay = mapWeekDayNextVal.get(intwkDay);
					}
				}
			}
		}
	}
	/*
	 * Wrapper to hold user assignment details
	 * Neha Dabas, 6 September 2019
	 */
	public class UserAssignmentWrapper {
		public Map<Integer, Benefit_Order_Allocation__c> mapWeekToBOA { get; set; }
		public Map<Integer, integer> map_weekToAICCount { get; set; } //AIC count = active employee count + inactive E count + contractor Count

		public String strUserName { get; set; }

		public UserAssignmentWrapper() {
		}
		public UserAssignmentWrapper(
			Integer indx,
			User_Skill__c userSkl,
			Payroll_Transfer_FBOS_Forecast__c objFCast,
			Integer totalAdvocateCount,
			Map<Integer, Integer> mapDaysCountPerWeek,
			Map<Integer, Map<String, Date>> mapStartNEndDatePerWeek,
			Id idBOARecTypePayroll,
			String strRoleType,
			Map<Integer, Integer> mapDistributedOrders
		) {
			strUserName = userSkl.User_Role__r.User__r.FirstName + ' ' + userSkl.User_Role__r.User__r.LastName;

			if (null != objFCast && null != objFCast.Id) {
				// Just to check if this is a valid and saved FBOS record
				mapWeekToBOA = new Map<Integer, Benefit_Order_Allocation__c>();
				map_weekToAICCount = new Map<Integer, Integer>();
				Map<String, Integer> mapMonthNameToValue = new Map<String, Integer>{
					'January' => 1,
					'February' => 2,
					'March' => 3,
					'April' => 4,
					'May' => 5,
					'June' => 6,
					'July' => 7,
					'August' => 8,
					'September' => 9,
					'October' => 10,
					'November' => 11,
					'December' => 12
				};

				for (Integer wk : mapStartNEndDatePerWeek.keySet()) {
					Benefit_Order_Allocation__c objBOA = new Benefit_Order_Allocation__c(
						User__c = userSkl.User_Role__r.User__c,
						User_Role__c = userSkl.User_Role__c,
						Payroll_Transfer_FBOS_Forecast__c = objFCast.Id,
						Working_days__c = mapDaysCountPerWeek.get(wk),
						Week_Start_Date__c = mapStartNEndDatePerWeek.get(wk).get('Start'),
						Week_End_Date__c = mapStartNEndDatePerWeek.get(wk).get('End'),
						Month__c = mapMonthNameToValue.get(objFCast.Month__c),
						Year__c = Integer.valueOf(objFCast.Year__c),
						RecordTypeId = idBOARecTypePayroll,
						Role_Type__c = strRoleType,
						Week_Order_Capacity__c = 0
					);
					if (0 != totalAdvocateCount) {
						Integer wkForecast = 0;
						if (wk == 1 && null != objFCast.First_week_cap__c) {
							wkForecast = Integer.valueOf(objFCast.First_week_cap__c);
						}
						if (wk == 2 && null != objFCast.Second_week_cap__c) {
							wkForecast = Integer.valueOf(objFCast.Second_week_cap__c);
						}
						if (wk == 3 && null != objFCast.Third_week_cap__c) {
							wkForecast = Integer.valueOf(objFCast.Third_week_cap__c);
						}
						if (wk == 4 && null != objFCast.Fourth_week_cap__c) {
							wkForecast = Integer.valueOf(objFCast.Fourth_week_cap__c);
						}
						if (wk == 5 && null != objFCast.Fifth_week_cap__c) {
							wkForecast = Integer.valueOf(objFCast.Fifth_week_cap__c);
						}
						objBOA.Week_Order_Capacity__c = wkForecast / totalAdvocateCount;
						mapDistributedOrders.put(wk, mapDistributedOrders.get(wk) + Integer.valueOf(objBOA.Week_Order_Capacity__c));
					}

					map_weekToAICCount.put(wk, 0);
					mapWeekToBOA.put(wk, objBOA);
				}
			}
		}
		public UserAssignmentWrapper(Map<Date, Benefit_Order_Allocation__c> mapBOA, Map<Integer, Map<String, Date>> mapStartNEndDatePerWeek, Map<Integer, Integer> mapTotalAssignedCount, String role) {
			if (!mapBOA.isEmpty() && null != mapStartNEndDatePerWeek && mapStartNEndDatePerWeek.size() > 0) {
				mapWeekToBOA = new Map<Integer, Benefit_Order_Allocation__c>();
				map_weekToAICCount = new Map<Integer, Integer>();
				Benefit_Order_Allocation__c objBOAReference = mapBOA.values()[0];
				strUserName = objBOAReference.User_Role__r.User__r.FirstName + ' ' + objBOAReference.User_Role__r.User__r.LastName;
				//Construct BOA records map
				for (Integer wk : mapStartNEndDatePerWeek.keySet()) {
					if (mapStartNEndDatePerWeek.get(wk).containsKey('Start')) {
						Date dtStart = mapStartNEndDatePerWeek.get(wk).get('Start');
						// If BOA record exists for this week
						if (mapBOA.containsKey(dtStart)) {
							mapWeekToBOA.put(wk, mapBOA.get(dtStart));
							integer aicCount = integer.valueOf(
								(mapBOA.get(dtStart).Open_Order_Employee_Count__c != null ? mapBOA.get(dtStart).Open_Order_Employee_Count__c : 0) +
									(mapBOA.get(dtStart).Inactive_Employee_Count__c != null ? mapBOA.get(dtStart).Inactive_Employee_Count__c : 0) +
									(mapBOA.get(dtStart).Contractor_Count__c != null ? mapBOA.get(dtStart).Contractor_Count__c : 0)
							);
							map_weekToAICCount.put(wk, aicCount);

							if ('Advocate'.equalsIgnoreCase(role)) {
								Integer wkTotal = mapTotalAssignedCount.get(wk) + Integer.valueOf(mapBOA.get(dtStart).Open_Order_Count__c);
								mapTotalAssignedCount.put(wk, wkTotal);
							} else if ('Facilitator'.equalsIgnoreCase(role)) {
								Integer wkTotal = mapTotalAssignedCount.get(wk);
								mapTotalAssignedCount.put(wk, wkTotal + aicCount);
							}
						} else {
							//Create new BOA for this week
							Benefit_Order_Allocation__c objBOA = new Benefit_Order_Allocation__c();
							objBOA.User__c = objBOAReference.User_Role__r.User__c;
							objBOA.User_Role__c = objBOAReference.User_Role__c;
							objBOA.Month__c = objBOAReference.Month__c;
							objBOA.Year__c = objBOAReference.Year__c;
							objBOA.Payroll_Transfer_FBOS_Forecast__c = objBOAReference.Payroll_Transfer_FBOS_Forecast__c;
							objBOA.Week_Start_Date__c = dtStart;
							objBOA.Week_End_Date__c = mapStartNEndDatePerWeek.get(wk).get('End');
							objBOA.Week_Order_Capacity__c = 0;
							objBOA.Working_days__c = objBOA.Week_Start_Date__c.daysBetween(objBOA.Week_End_Date__c);
							mapWeekToBOA.put(wk, objBOA);
							map_weekToAICCount.put(wk, 0);
						}
					}
				}
			}
		}
	}
}