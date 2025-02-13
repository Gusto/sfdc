public with sharing class OnboardingAdvocateViewCtrl {
	public list<BoStatWarpper> lstBOStatsWrapper { get; set; }
	public list<CustomerCommWrapper> lstCustomerCommWrapper { get; set; }
	public list<CustomerCommWrapper> lstCarrierCommWrapper { get; set; }
	public list<TicketWrapper> lstTicketWrapper { get; set; }
	private static string strCurrentUserId = UserInfo.getUserId();
	//This is declared to create date type filter field on VF page
	public Benefit_Order__c objBenefitOrder { get; set; }
	public list<ProcessStepsWrapper> lstProcessWrapper { get; set; }
	public string custActive { get; set; }
	public string carActive { get; set; }

	//public List<Benefit_Order__c> lstBOCohortView{get;set;} //Show benefit orders on cohort view as per filters
	public List<ProcessStepsWrapper> lstBOCohortView { get; set; } //Show benefit orders on cohort view as per filters

	public List<SelectOption> lstOrderStatus { get; set; } // unselected benefit order status values in search filter
	public List<string> lstSelectedOrderStatus { get; set; } // to get selected BO status
	public String strReportFilterJson { get; set; } // report filter condition in JSON form
	public String strReportId { get; set; } // report Id for cohort funnel

	private List<SelectOption> lstAllBOStatus;

	// public List<Benefit_Order__c> lstBOBusinessView{get;set;} //Show benefit orders on book of business view
	public List<ProcessStepsWrapper> lstBOBusinessView { get; set; } //Show benefit orders on book of business view
	public List<COBusinessViewWrapper> lstCOBusinessView { get; set; } //Show carrier orders on book of business view

	public string boActive { get; set; }
	public string coActive { get; set; }

	public string createdActive { get; set; }
	public string ownedActive { get; set; }
	public string closedActive { get; set; }

	public integer intNoOfTicketCreated { get; set; }
	public integer intNoOfTicketOnwed { get; set; }
	public integer intNoOfTicketClosed { get; set; }

	private set<string> setExcludeBOStatus = new Set<string>{ 'Fulfilled', 'Canceled', 'Closed Lost', 'Closed Admin' }; //,'Ready for Alignment','Alignment Approved','Alignment Denied','Alignment Approved Post Renewal'};  Added Alignment RecType related order statuses
	private set<string> setExcludeCOStage = new Set<string>{ 'Canceled', 'Approved', 'Approved Pending EE Audit', 'Closed Admin', 'Closed Admin' };

	//For Termination Carrier Order
	public List<TerminationCOWrapper> lstTerminationWrapper { get; set; }
	public integer intNoOfOpenTerminated { get; set; }
	public integer intNoOfCancelTerminated { get; set; }

	public string openTActive { get; set; }
	public string cancelTActive { get; set; }

	public OnboardingAdvocateViewCtrl(ApexPages.StandardController standardController) {
		//initialize and assign default value
		objBenefitOrder = new Benefit_Order__c();
		PopulateBOFilterDate();

		//Get report Id for Cohort Funnel Chart
		Report cohortReport = [SELECT COUNT() FROM Report WHERE DeveloperName = 'Onboarding_Advocate_Cohort_Funnel' LIMIT 1] > 0
			? [SELECT Id, DeveloperName FROM Report WHERE DeveloperName = 'Onboarding_Advocate_Cohort_Funnel' LIMIT 1]
			: null;
		if (null != cohortReport) {
			strReportId = cohortReport.Id;
		}

		//For Dynamic column changes
		initializeFieldselection();
	}
	/* Dynamic Column Changes */
	// to show all the available column/fields for user to see Key=ObjectName Value = List of selectOption(fieldAPINAme,FieldLabel)
	public Map<String, List<SelectOption>> mapLstAllFields { get; set; }
	// selected columns/fields Key=ObjectName + ViewName  Value = List of APIName of selected fields
	public Map<String, List<String>> mapLstSelectedFields { get; set; }
	// selected columns/fields Key=ObjectName Value = List of all APINAme of fields
	public Map<String, Map<String, String>> mapAllFields { get; set; }

	public String currentObjName { get; set; }
	public String currentView { get; set; }

	private Map<String, String> mapObjToQueryFields; // ObjectNAme----> comma separated fieldAPINames
	/*
	 *Create select option list for given object
	 */
	private List<SelectOption> getAllFields(string objectName) {
		List<SelectOption> lstAllFields = new List<SelectOption>();
		if (null != mapAllFields && mapAllFields.size() > 0) {
			if (mapAllFields.containsKey(objectName)) {
				Map<String, String> mapNameLabel = mapAllFields.get(objectName);
				String fieldStr = '';
				for (String fieldAPIName : mapNameLabel.keySet()) {
					lstAllFields.add(new SelectOption(fieldAPIName, mapNameLabel.get(fieldAPIName)));

					fieldStr += fieldAPIName + ',';
				}
				fieldStr += 'Id';
				mapObjToQueryFields.put(objectName, fieldStr);
			}
		}

		return lstAllFields;
	}
	/*
	 * Save Field_Preference record
	 */
	public PageReference savePreference() {
		try {
			String key = currentView + ' ' + currentObjName;
			if (String.isNotBlank(currentObjName) && String.isNotBlank(currentView) && null != mapLstSelectedFields && mapLstSelectedFields.containsKey(key)) {
				List<String> lstSelectedFields = mapLstSelectedFields.get(currentView + ' ' + currentObjName);
				if (lstSelectedFields.size() == 0) {
					//some fields must be selected
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select atLeast one column.'));
					return null;
				} else if (lstSelectedFields.size() > 10) {
					//Maximum 10 fields can be selected
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot select more than 10 Columns.'));
					return null;
				}
				Field_Preference__c objColumnPref = new Field_Preference__c();
				//based on preferences make query and see whether record is exits or not
				List<Field_Preference__c> lstPref = [
					SELECT id
					FROM Field_Preference__c
					WHERE User__c = :strCurrentUserId AND Object_Name__c = :currentObjName AND View_Name__c = :currentView
					LIMIT 1
				];
				if (lstPref != null && lstPref.size() > 0) {
					objColumnPref = new Field_Preference__c(Id = lstPref[0].Id);
				}
				objColumnPref.Object_Name__c = currentObjName;
				objColumnPref.View_Name__c = currentView;
				objColumnPref.User__c = strCurrentUserId;
				//Construct Field_c which has selected values
				objColumnPref.Fields__c = String.join(lstSelectedFields, ';');
				upsert objColumnPref;

				//Initialize All
				initializeFieldselection();
			}
		} catch (Exception objExcep) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExcep.getMessage()));
			return null;
		}
		return null;
	}
	/*
	 *Fetch existing Field_Preference or create a new for logged in user and Current Object and Current View/Page
	 */
	private void initializeFieldselection() {
		mapLstAllFields = new Map<String, List<SelectOption>>();
		mapLstSelectedFields = new Map<String, List<String>>();

		mapObjToQueryFields = new Map<String, String>();

		mapAllFields = Cache.getDependentPicklistValues(Field_Preference__c.Fields__c);
		mapLstAllFields.put('Benefit_Order__c', getAllFields('Benefit_Order__c'));
		mapLstAllFields.put('Carrier_Order__c', getAllFields('Carrier_Order__c'));

		Map<String, List<String>> mapViewToObject = new Map<String, List<String>>();
		mapViewToObject.put('OA Cohort', new List<String>{ 'Benefit_Order__c' });
		mapViewToObject.put('OA Business', new List<String>{ 'Benefit_Order__c' });
		mapViewToObject.put('OA ProcessSteps', new List<String>{ 'Benefit_Order__c' });
		mapViewToObject.put('OACO Business', new List<String>{ 'Carrier_Order__c' });

		if (null != mapViewToObject && mapViewToObject.size() > 0 && mapViewToObject.Values() != null && mapViewToObject.Values().size() > 0) {
			//Fetch field preferences for current user
			List<Field_Preference__c> lstColPref = new List<Field_Preference__c>();

			// All the object names
			Set<String> setObjNames = new Set<String>();
			for (String key : mapViewToObject.keySet()) {
				setObjNames.addAll(mapViewToObject.get(key));
			}

			lstColPref = [
				SELECT Id, Fields__c, Object_Name__c, User__c, View_Name__c
				FROM Field_Preference__c
				WHERE User__c = :strCurrentUserId AND View_Name__c IN :mapViewToObject.keySet() AND Object_Name__c IN :setObjNames
			];

			if (lstColPref.size() > 0) {
				// User Preference is already defined
				for (Field_Preference__c objPref : lstColPref) {
					// set selectedFields list map
					if (!mapLstSelectedFields.containsKey(objPref.View_Name__c + ' ' + objPref.Object_Name__c)) {
						mapLstSelectedFields.put(objPref.View_Name__c + ' ' + objPref.Object_Name__c, objPref.Fields__c.split(';'));
					}
				}
			}
			// Check if for any view+Object conbination, Preference is not defined

			for (String view : mapViewToObject.keySet()) {
				for (String objName : mapViewToObject.get(view)) {
					// set objects map
					Field_Preference__c objPref;
					String objectFields = '';
					if ('Benefit_Order__c'.equalsIgnoreCase(objName)) {
						//If there is no field pref record then get show default fields for Benefit Order
						objectFields = String.valueOf(Configuration_Settings__c.getInstance().OADefaultBOColumns__c);
						// In case of process steps we have differet default set of data
						if (view == 'OA ProcessSteps') {
							objectFields = String.valueOf(Configuration_Settings__c.getInstance().OADefaultBOProcessStepsColumns__c);
						}
					} //If there is no field pref record then get show default fields for CArrier Order
					if ('Carrier_Order__c'.equalsIgnoreCase(objName)) {
						//Set of fields length was more than 255 that why we have hard coded in code
						//objectFields=String.valueOf(Configuration_Settings__c.getInstance().OADefaultCOColumns__c);
						//Original Fiedls
						// objectFields='Name;Order_Type__c;Implementation_Stage__c;Benefit_Order__c;Follow_Up_Date__c;Submission_Deadline_Date__c;Confirmation_Owner__c;Case_Requires_Action__c;Follow_Up_Notes__c;Parent__c;Effective_Date__c;Ownerid;Benefit_Types__c;LastModifiedById;Stage_Duration__c;Stage_Timestamp__c;LastModifiedDate;Order_Assignment__c;Benefit_Order__r.Order_Status__c;Status_Change_Date_Time__c;Stage_Detail__c';
						//Show At a time only 10 column modified by AKS dated 30th Sept 2019
						objectFields = 'Name;Implementation_Stage__c;Submission_Deadline_Date__c;Ownerid;Follow_Up_Date__c;Benefit_Order__c;Case_Requires_Action__c;Effective_Date__c;Order_Assignment__c;Benefit_Types__c';
					}
					objPref = new Field_Preference__c(User__c = strCurrentUserId, View_Name__c = view, Object_Name__c = objName, Fields__c = objectFields);

					// set selectedFields list map
					if (!mapLstSelectedFields.containsKey(view + ' ' + objName)) {
						mapLstSelectedFields.put(view + ' ' + objName, objectFields.split(';'));
					}
				}
			}
		}
	}
	/* Dynamic Column Changes */
	//Populate First and last day month in benefor order stats.
	private void PopulateBOFilterDate() {
		Date startDate = Date.Today();
		Date firstDate = startDate.toStartOfMonth();
		Integer numberDays = date.daysInMonth(firstDate.Year(), firstDate.Month());
		objBenefitOrder.Coverage_Effective_Date__c = firstDate;
		objBenefitOrder.Blocked_Date__c = firstDate.addDays(numberDays - 1);

		//Fetch all the order status picklist values for benefit Order
		lstAllBOStatus = Cache.getFieldPickListValues('Benefit_Order__c', 'Order_Status__c');
	}
	public PageReference CallOnOnboardingAdvocateActionView() {
		custActive = 'active';
		carActive = null;
		//For benefit Order Stats
		RetriveBenefitOrderStatData();
		//For Customer Communication
		RetriveCustomerCommunication();
		//For Carrier Communication
		RetriveCarrierCommunication();

		//For Ticket
		createdActive = 'active';
		ownedActive = null;
		closedActive = null;
		countTicket();
		ShowTicketCreatedByMe();

		//For All Benefot Order Process Steps
		RetriveAllAssignedBenefitOrder();

		//For Terminated
		CountTerminatedCO();
		ShowOpenTerminated();
		return null;
	}

	public PageReference ShowCustomerCommunication() {
		custActive = 'active';
		carActive = null;
		return null;
	}
	public PageReference ShowCarrierCommunication() {
		custActive = null;
		carActive = 'active';
		return null;
	}

	public PageReference ShowBenefitOrderPanel() {
		boActive = 'active';
		coActive = null;
		return null;
	}
	public PageReference ShowCarrierOrderPanel() {
		coActive = 'active';
		boActive = null;
		return null;
	}

	public PageReference RetriveBenefitOrderStatData() {
		try {
			lstBOStatsWrapper = new List<BoStatWarpper>();
			if (objBenefitOrder.Coverage_Effective_Date__c != null && objBenefitOrder.Blocked_Date__c != null) {
				map<string, List<Benefit_Order__c>> mapStatusListBO = new Map<string, List<Benefit_Order__c>>();
				for (Benefit_Order__c objBO : [
					SELECT
						Id,
						Order_Status__c,
						(
							SELECT Id, Benefit_Order__c, Benefit_Order__r.Name, Duration_In_Day_s__c, createddate, From_Status__c, To_Status__c
							FROM Benefit_Order_Status_Change_History__r
							ORDER BY createddate DESC
							LIMIT 1
						)
					FROM Benefit_Order__c
					WHERE
						RecordType.DeveloperName != 'Renewal_Alignment'
						AND Ownerid = :strCurrentUserId
						AND Order_Status__c NOT IN :setExcludeBOStatus
						AND Coverage_Effective_Date__c >= :objBenefitOrder.Coverage_Effective_Date__c
						AND Coverage_Effective_Date__c <= :objBenefitOrder.Blocked_Date__c
					ORDER BY Order_Status__c
				]) {
					if (mapStatusListBO.containsKey(objBO.Order_Status__c) == true) {
						mapStatusListBO.get(objBO.Order_Status__c).add(objBO);
					} else {
						mapStatusListBO.put(objBO.Order_Status__c, new List<Benefit_Order__c>{ objBO });
					}
				}
				if (mapStatusListBO != null && mapStatusListBO.size() > 0) {
					for (string sts : mapStatusListBO.keySet()) {
						//Iterate this loop to calculate average
						integer boCount = 0;
						decimal boSum = 0;
						decimal avg = 0;
						string oldestBO = null;
						string oldestBOName = null;
						decimal noOfOldestdays = 0;
						for (Benefit_Order__c bo : mapStatusListBO.get(sts)) {
							boCount = boCount + 1;
							if (bo.Benefit_Order_Status_Change_History__r != null && bo.Benefit_Order_Status_Change_History__r.size() > 0) {
								Benefit_Order_Status_Change_History__c bHistory = bo.Benefit_Order_Status_Change_History__r[0];
								if (bHistory != null) {
									oldestBO = bHistory.Benefit_Order__c;
									oldestBOName = bHistory.Benefit_Order__r.Name;
									noOfOldestdays = bHistory.Duration_In_Day_s__c;
									boSum = boSum + bHistory.Duration_In_Day_s__c;
								}
							}
						}
						if (oldestBOName != null) {
							avg = (boSum / boCount).setScale(2);
							BoStatWarpper bp = new BoStatWarpper();
							bp.strBoStatus = sts;
							bp.strNumberOfBO = boCount;
							bp.strAverage = string.valueof(avg);
							bp.strOldestBOId = oldestBO;
							bp.strOldestBOName = oldestBOName;
							bp.oldestNoOfday = noOfOldestdays;
							lstBOStatsWrapper.add(bp);
						}
					}
				} else {
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Benefit Order Stat is not available for this Coverage Effective Date range');
					ApexPages.addMessage(myMsg);
					return null;
				}
			} else {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Please select Coverage Effective Date to show stat');
				ApexPages.addMessage(myMsg);
				return null;
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	//**Carrier Communication Start**/
	public PageReference RetriveCarrierCommunication() {
		try {
			lstCarrierCommWrapper = new List<CustomerCommWrapper>();
			set<string> setExcludeCOStatus = new Set<string>{ 'Approved', 'Canceled', 'Closed Lost', 'Closed Admin' };
			string query = 'select id,CaseNumber,Benefit_Order__c,Incoming_Email_Received_Date__c,';
			query = query + ' Incoming_Email_Received__c,Carrier_Order__c,Carrier_Order__r.Name,Carrier_Order__r.Implementation_Stage__c, ';
			query = query + ' Benefit_Order__r.Name,Benefit_Order__r.Coverage_Effective_Date__c from case where ';
			query = query + ' (RecordType.DeveloperName=\'Benefits_New_Plan_Case\' or RecordType.DeveloperName=\'Benefits_Change_Case\'';
			query = query + '  or RecordType.DeveloperName=\'Benefits_Renewal_Case\') and Type=\'Carrier Submission\'';
			query = query + '  and Benefit_Order__c!=null and Carrier_Order__c!=null and Carrier_Order__r.Implementation_Stage__c not in:setExcludeCOStatus ';
			query = query + '  and Benefit_Order__r.OwnerId=:strCurrentUserId and Incoming_Email_Received__c=true and Requires_Action__c=true ';
			query = query + ' order by Incoming_Email_Received_Date__c asc  limit 1000';

			lstCarrierCommWrapper.addAll(PopulateCommunicationWrapper(database.query(query)));
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}
	//**Carrier Communication End**/

	//**Customer Communication Start***//
	public PageReference RetriveCustomerCommunication() {
		try {
			lstCustomerCommWrapper = new List<CustomerCommWrapper>();
			string query = 'select id,CaseNumber,ContactId,Requires_Action__c,Contact.Name,Benefit_Order__c,';
			query = query + ' Benefit_Order__r.Name,Benefit_Order__r.Order_Status__c,';
			query = query + ' Benefit_Order__r.Coverage_Effective_Date__c,Incoming_Email_Received_Date__c,Incoming_Email_Received__c from case where ';
			query = query + ' (RecordType.DeveloperName=\'Benefits_New_Plan_Case\' or RecordType.DeveloperName=\'Benefits_Change_Case\'';
			query = query + '  or RecordType.DeveloperName=\'Benefits_Renewal_Case\') and Type!=\'Carrier Submission\'';
			query = query + '  and ContactId!=null and Benefit_Order__c!=null and ownerId=:strCurrentUserId and ';
			query = query + '  Requires_Action__c=true  order by Incoming_Email_Received_Date__c asc limit 1000';
			lstCustomerCommWrapper.addAll(PopulateCommunicationWrapper(database.query(query)));
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}
	private list<CustomerCommWrapper> PopulateCommunicationWrapper(List<Case> lstCase) {
		list<CustomerCommWrapper> tempWrap = new List<CustomerCommWrapper>();
		for (Case objCase : lstCase) {
			integer nod = 0;
			if (objCase.Incoming_Email_Received_Date__c != null) {
				nod = getNoOfdays(objCase.Incoming_Email_Received_Date__c, Date.Today());
			}
			CustomerCommWrapper cw = new CustomerCommWrapper();
			cw.objCase = objCase;
			// cw.strEffectiveDate=string.valueOf(objCase.Benefit_Order__r.Coverage_Effective_Date__c);
			cw.intDaySinceLastReceived = nod;
			tempWrap.add(cw);
		}
		return tempWrap;
	}
	//Update NDA status on Participant level
	public PageReference updateRequireStatus() {
		string strCaseId = ApexPages.CurrentPage().getparameters().get('strCaseId');
		if (lstCustomerCommWrapper != null && lstCustomerCommWrapper.size() > 0) {
			List<Case> lstCase = new List<Case>();
			for (CustomerCommWrapper cw : lstCustomerCommWrapper) {
				if (strCaseId != null && strCaseId == cw.objCase.Id) {
					Case objCase = new Case(Id = strCaseId);
					objCase.Requires_Action__c = false;
					lstCase.add(objCase);
				}
			}
			if (lstCase != null && lstCase.size() > 0) {
				update lstCase;
			}
		}
		RetriveCustomerCommunication();
		return null;
	}

	//**Customer Communication End***//
	//**Ticket Start ****/

	public PageReference ShowTicketCreatedByMe() {
		createdActive = 'active';
		ownedActive = null;
		closedActive = null;
		RetriveTickets('created');
		return null;
	}
	public PageReference ShowTicketOwnedByMe() {
		createdActive = null;
		ownedActive = 'active';
		closedActive = null;
		RetriveTickets('owned');
		return null;
	}
	public PageReference ShowClosedTicket() {
		createdActive = null;
		ownedActive = null;
		closedActive = 'active';
		RetriveTickets('closed');
		return null;
	}
	private void countTicket() {
		intNoOfTicketCreated = 0;
		intNoOfTicketClosed = 0;
		intNoOfTicketOnwed = 0;

		intNoOfTicketCreated = [SELECT COUNT() FROM Ticket__c WHERE Benefit_Order__c != NULL AND CreatedById = :strCurrentUserId AND Status__c != 'Closed'];
		intNoOfTicketOnwed = [SELECT COUNT() FROM Ticket__c WHERE OwnerId = :strCurrentUserId AND Status__c != 'Closed'];
		intNoOfTicketClosed = [
			SELECT COUNT()
			FROM Ticket__c
			WHERE Benefit_Order__c != NULL AND Status__c = 'Closed' AND CreatedById = :strCurrentUserId AND Closed_By__c != :strCurrentUserId AND Closed_Within_7_Days__c = TRUE
		];
	}
	private void RetriveTickets(string dataType) {
		try {
			lstTicketWrapper = new List<TicketWrapper>();
			string query = 'select id,Status__c,Benefit_Order__c,Benefit_Order__r.name,Createddate,LastModifieddate,';
			query = query + ' Benefit_Order__r.Coverage_Effective_Date__c,Escalation_Reason__c,Escalation_Reason_Detail__c,Name,';
			query = query + ' Description__c, Reporting_Team__c from Ticket__c where Name!=null ';
			if (dataType == 'created') {
				query = query + '  and Benefit_Order__c!=null and CreatedById=:strCurrentUserId and Status__c!=\'Closed\'';
			}
			if (dataType == 'owned') {
				query = query + ' and ownerId=:strCurrentUserId and Status__c!=\'Closed\'';
			}
			if (dataType == 'closed') {
				query = query + ' and Benefit_Order__c!=null and Status__c=\'Closed\' and CreatedById=:strCurrentUserId and Closed_By__c!=:strCurrentUserId and Closed_Within_7_Days__c=true';
			}
			query = query + ' order by Createddate ASC limit 1000';

			for (Ticket__c objTicket : Database.query(query)) {
				integer nod = 0;
				if (objTicket.Createddate != null) {
					nod = getNoOfdays(objTicket.Createddate, Date.Today());
				}
				TicketWrapper cw = new TicketWrapper();
				cw.objTicket = objTicket;
				cw.intDaySinceLastCreated = nod;
				cw.strEffectiveDate = string.valueOf(objTicket.Benefit_Order__r.Coverage_Effective_Date__c);
				cw.strLastModifiedDate = string.valueOf(date.newinstance(objTicket.LastModifiedDate.year(), objTicket.LastModifiedDate.month(), objTicket.LastModifiedDate.day()));
				lstTicketWrapper.add(cw);
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
	}
	//***Ticket End*****/

	//******** Process Steps Start
	public PageReference RetriveAllAssignedBenefitOrder() {
		try {
			lstProcessWrapper = new List<ProcessStepsWrapper>();
			set<id> setAwaitingBOId = new Set<Id>();
			set<id> setSubmissionBOId = new Set<Id>();
			set<id> setReadyForConBOId = new Set<Id>();
			for (Carrier_Order__c co : [
				SELECT Benefit_Order__c, Implementation_Stage__c
				FROM Carrier_Order__c
				WHERE
					(Implementation_Stage__c = 'Awaiting Routing'
					OR (Implementation_Stage__c = 'Ready for Submission Prep'
					AND Submission_Date_within_5_days__c = TRUE
					AND Days_In_Current_Status__c >= 14)
					OR Implementation_Stage__c = 'Ready for Confirmation')
					AND Ownerid = :strCurrentUserId
			]) {
				if (co.Implementation_Stage__c == 'Awaiting Routing') {
					setAwaitingBOId.add(co.id);
				}
				if (co.Implementation_Stage__c == 'Ready for Submission Prep') {
					setSubmissionBOId.add(co.id);
				}
				if (co.Implementation_Stage__c == 'Ready for Confirmation') {
					setReadyForConBOId.add(co.id);
				}
			}

			String strProcessQuery = 'SELECT ';
			//get All carrier order where Implementation_Stage is Awaiting Routing
			strProcessQuery += mapObjToQueryFields.get('Benefit_Order__c');
			strProcessQuery += ' FROM Benefit_Order__c';
			strProcessQuery = strProcessQuery + ' where RecordType.DeveloperName!=\'Renewal_Alignment\' and ';
			strProcessQuery = strProcessQuery + ' ownerId=:strCurrentUserId  and (Order_Status__c=\'Ready for OE Prep\' or Order_Status__c=\'OE Prep\' or ';
			strProcessQuery = strProcessQuery + ' (Order_Status__c=\'Ready for Qualification\' and Days_In_Current_Status__c>=7) or ((Order_Status__c=\'OE\' or ';
			strProcessQuery = strProcessQuery + ' Order_Status__c=\'OE Extended\')) or ';
			strProcessQuery = strProcessQuery + ' Order_Status__c=\'OE Verification/Checking Participation\' or Order_Status__c=\'Approved\'  or ';
			strProcessQuery = strProcessQuery + ' (Order_Status__c=\'Awaiting routing\' or Id in :setAwaitingBOId) or ((Order_Status__c=\'With Sales\' or ';
			strProcessQuery = strProcessQuery + ' Order_Status__c=\'With Advising\') and Days_In_Current_Status__c>=4) or Order_Status__c=\'Blocked\' or ';
			strProcessQuery = strProcessQuery + ' (Order_Status__c=\'Ready for Submission Prep\' and Id in :setSubmissionBOId) or ';
			strProcessQuery = strProcessQuery + ' (Order_Status__c=\'Ready for confirmation\' and Days_In_Current_Status__c>=7 and Id in :setReadyForConBOId)) ';
			strProcessQuery = strProcessQuery + ' order by Order_Status__c ASC limit 1000 ';

			for (Benefit_Order__c objBO : database.query(strProcessQuery)) {
				ProcessStepsWrapper pw = new ProcessStepsWrapper();
				pw.rowColor = 'None';

				if (objBO.Submission_Deadline__c != null && objBO.Order_Status__c != 'Approved' && objBO.Order_Status__c != 'Ready for confirmation') {
					dateTime submissionDate = datetime.newInstance(objBO.Submission_Deadline__c.year(), objBO.Submission_Deadline__c.month(), objBO.Submission_Deadline__c.day());
					integer daysBetween = getNoOfdays(DateTime.Now(), submissionDate);
					if (daysBetween >= 4) {
						pw.rowColor = 'greenColor';
					}
					if (daysBetween == 3) {
						pw.rowColor = 'yellowColor';
					}
					if (daysBetween <= 2) {
						pw.rowColor = 'redColor';
					}
				}
				pw.objOrder = objBO;
				lstProcessWrapper.add(pw);
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}
	//******* Process Steps End

	private integer getNoOfdays(Datetime dFrom, Datetime dTo) {
		integer nod = 0;
		Date fromDate = date.newinstance(dFrom.year(), dFrom.month(), dFrom.day());
		Date toDate = date.newinstance(dTo.year(), dTo.month(), dTo.day());
		nod = fromDate.daysBetween(toDate);
		return nod;
	}
	//For Stat
	public class BoStatWarpper {
		public string strBoStatus { get; set; }
		public integer strNumberOfBO { get; set; }
		public decimal oldestNoOfday { get; set; }
		public string strAverage { get; set; }
		public string strOldestBOId { get; set; }
		public string strOldestBOName { get; set; }
	}

	//For Customer Communication
	public class CustomerCommWrapper {
		public integer intDaySinceLastReceived { get; set; }
		public string strEffectiveDate { get; set; }
		public Case objCase { get; set; }
	}

	//For Tickets
	public class TicketWrapper {
		public integer intDaySinceLastCreated { get; set; }
		public string strEffectiveDate { get; set; }
		public string strLastModifiedDate { get; set; }
		public Ticket__c objTicket { get; set; }
	}
	//For Process Steps
	public class ProcessStepsWrapper {
		public string rowColor { get; set; }
		public Benefit_Order__c objOrder { get; set; }
		public string strImplementationFollowUpDate { get; set; }
		public string strCoverageEffectiveDate { get; set; }
		public string strSubmissionDeadline { get; set; }
		public string strOpenEnrollmentStartDate { get; set; }
		public string strOpenEnrollmentEndDate { get; set; }
		public string strStatusChangeDateTime { get; set; }
		public string strLastModifiedDate { get; set; }
		public string strBenefitsFlowCompletedTimestamp { get; set; }
	}

	//For CO BusinessView Steps
	public class COBusinessViewWrapper {
		public string rowColor { get; set; }
		public Carrier_Order__c objOrder { get; set; }
	}

	/*
	 * Created By   : Neha Dabas
	 * Date         : 19 Aug 2019
	 * Description  : To get page contents for cohert view on page Load
	 */
	public PageReference callOnOnboardingAdvocateCohortView() {
		initializeSearchFilters();
		ShowBO();
		return null;
	}
	/*
	 * Created By   : Neha Dabas
	 * Date         : 23 Aug 2019
	 * Description  : To get page contents for book of business view on page Load
	 */
	public PageReference callOnOnboardingAdvocateBusinessView() {
		ShowBenefitOrderPanel();
		retriveBOCohortStatData('Business');
		RetriveCOBusinessView();
		return null;
	}
	/*
	 * Created By   : Neha Dabas
	 * Date         : 22 Aug 2019
	 * Description  : To Initialize Benefit Order Filter fields
	 */
	private void initializeSearchFilters() {
		lstSelectedOrderStatus = new List<string>();
		Date startDate = Date.Today();

		Date lastDate = startDate.addMonths(1).toStartOfMonth(); // set to Start date of next month

		Integer numberDays = date.daysInMonth(lastDate.Year(), lastDate.Month());
		/* Search Filters for Open Benefit Orders*/
		//As per new change default date would be next month first date to last date
		objBenefitOrder.Coverage_Expiration_Date__c = lastDate; // Used for Coverage Effective Date From
		objBenefitOrder.Follow_Up_Date__c = lastDate.addDays(numberDays - 1); // Used for Coverage Effective Date To

		objBenefitOrder.Unblocked_Date__c = null; // Used for Submission Deadline From
		objBenefitOrder.End_Date__c = null; // Used for Submission Deadline To

		/* Search filter for funnel chart */
		//As per new change default date would be next month first date to last date
		objBenefitOrder.Original_Effective_Date__c = lastDate; // Used for Coverage Effective Date From
		objBenefitOrder.Qualification_Follow_Up_Date__c = lastDate.addDays(numberDays - 1); // Used for Coverage Effective Date To
		createFilterJSON();

		//Reinit selected order status
		//Construct the selectList shown on UI excluding the close Order status values
		if (null != lstAllBOStatus) {
			lstOrderStatus = new List<SelectOption>();

			for (SelectOption status : lstAllBOStatus) {
				if (setExcludeBOStatus.contains(status.getLabel()) || status.getLabel().containsIgnoreCase('Alignment'))
					continue;
				lstOrderStatus.add(status);
			}
		}
	}
	/*
	 * Created By   : Neha Dabas
	 * Date         : 20 Aug 2019
	 * Description  : To load benefit orders for cohort view
	 */
	public PageReference ShowBO() {
		retriveBOCohortStatData('Cohort');
		return null;
	}
	/*
	 * Created By   : Neha Dabas
	 * Date         : 20 Aug 2019
	 * Description  : To fetch benefit orders for cohort view
	 */
	private void retriveBOCohortStatData(String source) {
		try {
			String strBOQuery = 'SELECT ';
			//' Follow_Up_Date__c,Name,Requires_Action__c,Coverage_Effective_Date__c,Follow_Up_Notes__c,Submission_Deadline__c,Type__c,Order_Status__c,Open_Enrollment_Start_Date__c,Open_Enrollment_End_Date__c,Status_Change_Date_Time__c,LastModifiedDate FROM Benefit_Order__c';
			strBOQuery += mapObjToQueryFields.get('Benefit_Order__c');

			strBOQuery += ' FROM Benefit_Order__c';

			String strWHEREClause = ' WHERE RecordType.DeveloperName != \'Renewal_Alignment\' ';

			if ('Cohort'.equalsIgnoreCase(source)) {
				//Date Range Validation for date filters
				if (
					null != objBenefitOrder.Coverage_Expiration_Date__c &&
					null != objBenefitOrder.Follow_Up_Date__c &&
					objBenefitOrder.Coverage_Expiration_Date__c > objBenefitOrder.Follow_Up_Date__c
				) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a valid coverage effective date range'));
					return;
				}
				if (null != objBenefitOrder.Unblocked_Date__c && null != objBenefitOrder.End_Date__c && objBenefitOrder.Unblocked_Date__c > objBenefitOrder.End_Date__c) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a valid submission deadline date range'));
					return;
				}
				if (objBenefitOrder.Coverage_Expiration_Date__c != null && objBenefitOrder.Follow_Up_Date__c != null) {
					Date dateFrom = objBenefitOrder.Coverage_Expiration_Date__c;
					Date dateTO = objBenefitOrder.Follow_Up_Date__c;
					strWHEREClause += ' AND (Coverage_Effective_Date__c >=:dateFrom AND Coverage_Effective_Date__c <=:dateTO )';
				}
				if (objBenefitOrder.Unblocked_Date__c != null && objBenefitOrder.End_Date__c != null) {
					Date dateFrom1 = objBenefitOrder.Unblocked_Date__c;
					Date dateTO1 = objBenefitOrder.End_Date__c;
					strWHEREClause += ' AND (Submission_Deadline__c >=:dateFrom1 and Submission_Deadline__c <=:dateTO1 )';
				}

				if (lstSelectedOrderStatus != null && lstSelectedOrderStatus.size() > 0) {
					strWHEREClause += ' AND Order_Status__c IN :lstSelectedOrderStatus';
				}
			}
			strWHEREClause += ' AND Order_Status__c NOT IN :setExcludeBOStatus';

			strWHEREClause += ' AND OwnerId =:strCurrentUserId';

			strBOQuery = strBOQuery + strWHEREClause + ' ORDER BY Coverage_Effective_Date__c ASC limit 1000';

			if ('Cohort'.equalsIgnoreCase(source)) {
				//Fetch benefit orders based on search criteria
				lstBOCohortView = new List<ProcessStepsWrapper>();
				lstBOCohortView.addAll(BindWarpper(Database.query(strBOQuery)));

				if (lstBOCohortView.size() == 0) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Benefit Orders are not available for this selection.'));
					return;
				}
			} else if ('Business'.equalsIgnoreCase(source)) {
				lstBOBusinessView = new List<ProcessStepsWrapper>();
				lstBOBusinessView.addAll(BindWarpper(Database.query(strBOQuery)));
				if (lstBOBusinessView.size() == 0) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You donot own any Benefit Orders.'));
					return;
				}
			}
		} catch (Exception objExcep) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, objExcep.getMessage() + objExcep.getStacktraceString()));
		}
	}
	public void RetriveCOBusinessView() {
		try {
			lstCOBusinessView = new List<COBusinessViewWrapper>();
			String strCOQuery = 'SELECT ';
			strCOQuery += mapObjToQueryFields.get('Carrier_Order__c');
			strCOQuery += ' ,Owner.Name,Audit_Owner__r.Name,Benefit_Order__r.Name,Parent__r.Name,Confirmation_Owner__r.Name,LastModifiedBy.Name FROM Carrier_Order__c ';
			String strWHEREClause = ' WHERE Benefit_Order__r.OwnerId =:strCurrentUserId and Implementation_Stage__c not in:setExcludeCOStage ';
			strCOQuery = strCOQuery + strWHEREClause + ' ORDER BY Effective_Date__c ASC limit 1000';

			for (Carrier_Order__c co : Database.query(strCOQuery)) {
				COBusinessViewWrapper objCoWrapper = new COBusinessViewWrapper();
				objCoWrapper.rowColor = 'None';
				if (co.Submission_Deadline_Date__c != null) {
					dateTime submissionDate = datetime.newInstance(co.Submission_Deadline_Date__c.year(), co.Submission_Deadline_Date__c.month(), co.Submission_Deadline_Date__c.day());
					integer daysBetween = getNoOfdays(DateTime.Now(), submissionDate);
					if (daysBetween >= 4) {
						objCoWrapper.rowColor = 'greenColor';
					}
					if (daysBetween == 3) {
						objCoWrapper.rowColor = 'yellowColor';
					}
					if (daysBetween <= 2) {
						objCoWrapper.rowColor = 'redColor';
					}
				}
				objCoWrapper.objOrder = co;
				lstCOBusinessView.add(objCoWrapper);
			}
			if (lstCOBusinessView.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You donot have any carrier orders.'));
				return;
			}
		} catch (Exception objExcep) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, objExcep.getMessage() + objExcep.getStacktraceString()));
		}
	}
	private List<ProcessStepsWrapper> BindWarpper(List<Benefit_Order__c> lstBO) {
		List<ProcessStepsWrapper> tempWrapper = new List<ProcessStepsWrapper>();
		for (Benefit_Order__c objBO : lstBO) {
			ProcessStepsWrapper pw = new ProcessStepsWrapper();
			pw.rowColor = 'None';
			if (objBO.Submission_Deadline__c != null && objBO.Order_Status__c != 'Approved' && objBO.Order_Status__c != 'Ready for confirmation') {
				dateTime submissionDate = datetime.newInstance(objBO.Submission_Deadline__c.year(), objBO.Submission_Deadline__c.month(), objBO.Submission_Deadline__c.day());
				integer daysBetween = getNoOfdays(DateTime.Now(), submissionDate);
				if (daysBetween >= 4) {
					pw.rowColor = 'greenColor';
				}
				if (daysBetween == 3) {
					pw.rowColor = 'yellowColor';
				}
				if (daysBetween <= 2) {
					pw.rowColor = 'redColor';
				}
			}
			pw.strImplementationFollowUpDate = string.valueOf(objBO.Follow_Up_Date__c);
			pw.strCoverageEffectiveDate = string.valueOf(objBO.Coverage_Effective_Date__c);
			pw.strSubmissionDeadline = string.valueOf(objBO.Submission_Deadline__c);
			pw.strOpenEnrollmentStartDate = string.valueOf(objBO.Open_Enrollment_Start_Date__c);
			pw.strOpenEnrollmentEndDate = string.valueOf(objBO.Open_Enrollment_End_Date__c);
			pw.strStatusChangeDateTime = string.valueOf(date.newinstance(objBO.Status_Change_Date_Time__c.year(), objBO.Status_Change_Date_Time__c.month(), objBO.Status_Change_Date_Time__c.day()));
			pw.strLastModifiedDate = string.valueOf(date.newinstance(objBO.LastModifiedDate.year(), objBO.LastModifiedDate.month(), objBO.LastModifiedDate.day()));
			pw.strBenefitsFlowCompletedTimestamp = null;
			if (objBO.Benefits_Flow_Completed_Timestamp__c != null) {
				pw.strBenefitsFlowCompletedTimestamp = String.valueOf(
					Date.newinstance(objBO.Benefits_Flow_Completed_Timestamp__c.year(), objBO.Benefits_Flow_Completed_Timestamp__c.month(), objBO.Benefits_Flow_Completed_Timestamp__c.day())
				);
			}
			pw.objOrder = objBO;
			tempWrapper.add(pw);
		}
		return tempWrapper;
	}

	/*
	 * Created By   : Neha Dabas
	 * Date         : 23 Aug 2019
	 * Description  : To construct dynamic report filter
	 */
	public PageReference createFilterJSON() {
		List<Map<String, Object>> lstFilterJSON = new List<Map<String, Object>>();

		if (null != objBenefitOrder.Original_Effective_Date__c) {
			Map<String, Object> mapCondition = new Map<String, Object>();
			mapCondition.put('column', 'Benefit_Order__c.Coverage_Effective_Date__c');
			mapCondition.put('operator', 'greaterOrEqual');
			mapCondition.put('value', objBenefitOrder.Original_Effective_Date__c);
			lstFilterJSON.add(mapCondition);
		}
		if (null != objBenefitOrder.Qualification_Follow_Up_Date__c) {
			Map<String, Object> mapCondition = new Map<String, Object>();
			mapCondition.put('column', 'Benefit_Order__c.Coverage_Effective_Date__c');
			mapCondition.put('operator', 'lessOrEqual');
			mapCondition.put('value', objBenefitOrder.Qualification_Follow_Up_Date__c);
			lstFilterJSON.add(mapCondition);
		}
		strReportFilterJson = JSON.serialize(lstFilterJSON);

		return null;
	}

	/* Function to call on Terminated CO*/
	public PageReference ShowOpenTerminated() {
		openTActive = 'active';
		cancelTActive = null;
		PopulateTerminatedCO('open');
		return null;
	}
	public PageReference ShowCancelTerminated() {
		openTActive = null;
		cancelTActive = 'active';
		PopulateTerminatedCO('cancel');
		return null;
	}
	private void CountTerminatedCO() {
		intNoOfOpenTerminated = 0;
		intNoOfCancelTerminated = 0;
		for (Carrier_Order__c co : [
			SELECT Id, Implementation_Stage__c, Order_End_date_within_5_days__c
			FROM Carrier_Order__c
			WHERE Benefit_Order__r.OwnerId = :strCurrentUserId
		]) {
			if (co.Implementation_Stage__c != 'Canceled') {
				intNoOfOpenTerminated = intNoOfOpenTerminated + 1;
			}
			if (co.Implementation_Stage__c == 'Canceled' && co.Order_End_date_within_5_days__c == true) {
				intNoOfCancelTerminated = intNoOfCancelTerminated + 1;
			}
		}
	}
	private void PopulateTerminatedCO(string sType) {
		lstTerminationWrapper = new List<TerminationCOWrapper>();
		set<string> setImp = new Set<string>{ 'Canceled' };

		string query = 'select id,Name,Benefit_Order__c,Benefit_Order__r.Name,Implementation_Stage__c,';
		query = query + ' Parent__c,Parent__r.Name,Effective_Date__c,Term_Submission_Date__c from Carrier_Order__c ';
		query = query + ' where Benefit_Order__r.OwnerId=:strCurrentUserId ';
		if (sType == 'open') {
			query = query + ' and Implementation_Stage__c not in:setImp';
		}
		if (sType == 'cancel') {
			query = query + ' and Implementation_Stage__c =\'Canceled\' and Order_End_date_within_5_days__c=true';
		}
		query = query + ' order by Effective_Date__c ASC limit 1000';

		for (Carrier_Order__c co : Database.query(query)) {
			TerminationCOWrapper tw = new TerminationCOWrapper();
			tw.objCO = co;
			tw.strEffectiveDate = string.valueOf(co.Effective_Date__c);
			tw.strTerminationSubmissionDate = string.valueOf(co.Term_Submission_Date__c);
			lstTerminationWrapper.add(tw);
		}
	}

	public class TerminationCOWrapper {
		public Carrier_Order__c objCO { get; set; }
		public string strEffectiveDate { get; set; }
		public string strTerminationSubmissionDate { get; set; }
	}
}