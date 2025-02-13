/**
 * @name         BTCOFacilitatorSideViewCtrl
 * @author       Anand Singh
 * @date         05-02-2020
 * @description
 **/
public class BTCOFacilitatorSideViewCtrl {
	public Carrier_Order__c objCarrierOrder { get; set; }
	public string strCarrierOrderId { get; set; }
	public List<Carrier_Order__c> list_CarrierOrder;
	public List<Carrier_Order__c> list_MultiEINCarrierOrders { get; set; }
	public integer intDayInProcess { get; set; }
	public boolean blnShowDocButton { get; set; }
	static String strCO_STAGE_PLANS_CONFIRMED = 'Plans Confirmed';
	static String strCO_STAGE_READY_IMPLEMENTATION_PLANS = 'Ready for Implementing Plans';
	static String strCO_STAGE_IMPLEMENTATION_PLANS = 'Implementing Plans'; // Plan Review
	static String strCO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS = 'Enrollment Review Entry in Progress'; // Enrollment Review
	static String strCO_STAGE_READY_SEND_ENROLLMENTREVIEW = 'Ready to Send Enrollment Review';
	static String strCO_STAGE_ENROLLMENT_REVIEWSENT = 'Enrollment Review Sent';
	static String strCO_STAGE_ENROLLMENT_CONFIRMED = 'Enrollment Confirmed';
	static String strCO_STAGE_IMPLEMENTING_TADAPLANS = 'Implementing TAdA Plans';
	static String strCO_STAGE_READYFORBALANCECLCTN = 'Ready for Balance Collection';
	static String strCO_STAGE_BALANCECLCTN = 'Balance Collection';
	static String strCO_STAGE_TRNSFERRINGBALANCES = 'Transferring Balances';
	static String strCO_STAGE_FULFILLED = 'Fulfilled';
	public list<SelectOption> list_Views { get; set; }
	public string strSelectedView { get; set; }
	public String strSectionName { get; set; }
	public boolean blnIsTaskCompleted { get; set; }
	public Boolean blnShowRejectButton { get; set; }
	public Boolean blnErrorInFacilitator2 { get; set; }
	date dtLastFollowUpdateDate;
	public Set<String> set_StagesForEnrollmentReviewNotes { get; set; }
	public Boolean blnShowEnrollmentReviewNotes { get; set; }
	public Boolean blnShowPlanReviewNotesInReadOnly { get; set; }
	public String strCOBTRecordTypeId { get; set; }

	public BTCOFacilitatorSideViewCtrl(ApexPages.StandardController controller) {
		set_StagesForEnrollmentReviewNotes = new Set<String>{
			strCO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS,
			strCO_STAGE_READY_SEND_ENROLLMENTREVIEW,
			strCO_STAGE_ENROLLMENT_REVIEWSENT,
			strCO_STAGE_ENROLLMENT_CONFIRMED,
			strCO_STAGE_IMPLEMENTING_TADAPLANS,
			strCO_STAGE_READYFORBALANCECLCTN,
			strCO_STAGE_BALANCECLCTN,
			strCO_STAGE_TRNSFERRINGBALANCES,
			strCO_STAGE_FULFILLED
		};
		blnShowEnrollmentReviewNotes = false;
		blnShowPlanReviewNotesInReadOnly = false;
		blnShowRejectButton = false;
		blnErrorInFacilitator2 = false;
		blnIsTaskCompleted = false;
		strSectionName = '';
		strCOBTRecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		strCarrierOrderId = controller.getId();
		getCarrierOrderDetails();
		// To get all the Multi-EIN carrier orders if current page CO is a multi-ein order.
		fetchMultiEINCarrierOrders();
	}

	public void getCarrierOrderDetails() {
		objCarrierOrder = new Carrier_Order__c();
		intDayInProcess = 0;
		blnShowDocButton = true;
		list_Views = new List<SelectOption>();
		Id idLoggedInUser = UserInfo.getUserId();
		if (string.isNotBlank(strCarrierOrderId)) {
			list_CarrierOrder = [
				SELECT
					id,
					Implementation_Stage__c,
					Total_Number_Of_Documents__c,
					Carrier__r.Contribution_Scheme__c,
					Percent_Of_Documents_Completed__c,
					Number_Of_Collected_Documents__c,
					OwnerId,
					Carrier__r.Waiting_Period_Notes__c,
					Benefit_Order__c,
					Group_Number__c,
					Benefit_Order__r.Age__c,
					Facilitator_2_Plan_Review__c,
					Facilitator_2_Enrollment_Review_Notes__c,
					Facilitator_2_Plan_Review_Notes__c,
					Facilitator_2_Enrollment_Review__c,
					Benefit_Order__r.Hippo_Link__c,
					Benefit_Order__r.Qualification_Follow_Up_Date__c,
					Carrier__c,
					Carrier__r.Name,
					Carrier__r.Termination_Effective_Date__c,
					Benefit_Order__r.Name,
					Follow_Up_Notes__c,
					Facilitator_2_Plan_Build__c,
					Plan_Review_Completed_Date_Time__c,
					Enrollment_Review_Completed_Date_Time__c,
					Follow_Up_Date__c,
					GDrive_Link__c,
					Is_Multi_EIN__c,
					Parent_Carrier_Order__c,
					Total_of_Enrollees__c,
					Facilitator_1_Notes__c,
					(
						SELECT Id, Carrier_Order__c, CaseNumber, Subject
						FROM Cases__r
						WHERE Carrier_Order__c != NULL
						ORDER BY createddate DESC
					),
					(
						SELECT Id, Carrier_Order__c, Name, Escalation_Reason__c, Owner.Name, OwnerId, CreatedDate, status__c
						FROM Tickets__r
						ORDER BY createddate DESC
					)
				FROM Carrier_Order__c
				WHERE Id = :strCarrierOrderId
			]; //WHERE 	Status__c != 'Closed'
			if (list_CarrierOrder != null && list_CarrierOrder.size() > 0) {
				objCarrierOrder = list_CarrierOrder[0];

				//PLANS_CONFIRMED = Enrollment Review. READY_IMPLEMENTATION_PLANS = Plan Review
				if (objCarrierOrder.Implementation_Stage__c == strCO_STAGE_PLANS_CONFIRMED) {
					strSectionName = 'Enrollment Review';
				} else if (objCarrierOrder.Implementation_Stage__c == strCO_STAGE_READY_IMPLEMENTATION_PLANS) {
					strSectionName = 'Plan Review';
				}
				// If CO stage is Implementing Plans and Facilitator_2_Plan_Build__c is selected as Yes
				// and logged in user is a facilitator 2 plan reviewer then show the Reject Plan Build Required button.
				if (
					objCarrierOrder.Implementation_Stage__c == strCO_STAGE_IMPLEMENTATION_PLANS &&
					objCarrierOrder.Facilitator_2_Plan_Build__c != 'Y' &&
					idLoggedInUser == objCarrierOrder.Facilitator_2_Plan_Review__c
				) {
					blnShowRejectButton = true;
				} else
					blnShowRejectButton = false;

				if (set_StagesForEnrollmentReviewNotes.contains(objCarrierOrder.Implementation_Stage__c)) {
					blnShowEnrollmentReviewNotes = true;
				} else
					blnShowEnrollmentReviewNotes = false;

				if (objCarrierOrder.Implementation_Stage__c == strCO_STAGE_ENROLLMENT_REVIEW_IN_PROGRESS) {
					blnShowPlanReviewNotesInReadOnly = true;
				} else if (objCarrierOrder.Implementation_Stage__c == strCO_STAGE_IMPLEMENTATION_PLANS) {
					blnShowPlanReviewNotesInReadOnly = false;
				}
				dtLastFollowUpdateDate = objCarrierOrder.Follow_Up_Date__c;
				//If stage is "Ready for document collection" then accept me button should be visible
				if (objCarrierOrder.Implementation_Stage__c == 'Ready for Document Collection') {
					blnShowDocButton = false;
				}
				intDayInProcess = 0;
				//if(objCarrierOrder.Benefit_Order__r.Qualification_Follow_Up_Date__c!=null){
				//intDayInProcess=objCarrierOrder.Benefit_Order__r.Qualification_Follow_Up_Date__c.daysBetween(date.today());
				//

				if (objCarrierOrder.Benefit_Order__r.Age__c != null && objCarrierOrder.Benefit_Order__r.Age__c > 0) {
					intDayInProcess = integer.valueof(objCarrierOrder.Benefit_Order__r.Age__c);
				}
				//}

				list_Views = new List<SelectOption>();
				if (
					objCarrierOrder.OwnerId == idLoggedInUser &&
					idLoggedInUser != objCarrierOrder.Facilitator_2_Plan_Review__c &&
					idLoggedInUser != objCarrierOrder.Facilitator_2_Enrollment_Review__c
				) {
					list_Views.add(new SelectOption('FAC1', 'Facilitator 1'));
					strSelectedView = 'FAC1';
				} else if (
					objCarrierOrder.OwnerId != idLoggedInUser &&
					(idLoggedInUser == objCarrierOrder.Facilitator_2_Plan_Review__c ||
					idLoggedInUser == objCarrierOrder.Facilitator_2_Enrollment_Review__c)
				) {
					list_Views.add(new SelectOption('FAC2', 'Facilitator 2'));
					strSelectedView = 'FAC2';
				} else {
					list_Views.add(new SelectOption('FAC1', 'Facilitator 1'));
					list_Views.add(new SelectOption('FAC2', 'Facilitator 2'));
					strSelectedView = 'FAC1';
				}
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Carrier Order not found'));
			}
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Select Carrier order to get detail'));
		}
	}

	public PageReference saveCO() {
		CarrierOrderTriggerHelper.skipTrigger = true;
		update objCarrierOrder;
		CarrierOrderTriggerHelper.skipTrigger = false;
		return null;
	}
	public PageReference UpdateStatus() {
		try {
			blnShowDocButton = true;
			List<Carrier_Order__c> list_UpdateCOStage = new List<Carrier_Order__c>();
			objCarrierOrder.Implementation_Stage__c = 'Collecting Documents';
			list_UpdateCOStage.add(objCarrierOrder);
			//In case of Multi EIN get all related CO and update stage
			if (objCarrierOrder.Is_Multi_EIN__c == true && objCarrierOrder.Parent_Carrier_Order__c == null) {
				for (Carrier_Order__c co : [
					SELECT Id, Implementation_Stage__c
					FROM Carrier_Order__c
					WHERE Parent_Carrier_Order__c = :objCarrierOrder.id
				]) {
					co.Implementation_Stage__c = 'Collecting Documents';
					list_UpdateCOStage.add(co);
				}
			}
			update list_UpdateCOStage;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
		}
		return null;
	}

	public PageReference saveForFacilitator2() {
		blnErrorInFacilitator2 = false;
		if (objCarrierOrder.Follow_Up_Date__c != null && dtLastFollowUpdateDate != objCarrierOrder.Follow_Up_Date__c) {
			if (objCarrierOrder.Follow_Up_Date__c > system.today().addDays(2)) {
				objCarrierOrder.Follow_Up_Date__c = null;
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Follow Up Date: has to be under 2 days.'));
				blnErrorInFacilitator2 = true;
				return null;
			}
		}

		if (blnIsTaskCompleted) {
			if (objCarrierOrder.Implementation_Stage__c == 'Implementing Plans') {
				objCarrierOrder.Implementation_Stage__c = 'Ready to Send Plan Review';
				objCarrierOrder.Plan_Review_Completed_Date_Time__c = System.now();
			} else if (objCarrierOrder.Implementation_Stage__c == 'Enrollment Review Entry in Progress') {
				if (objCarrierOrder.Total_of_Enrollees__c == null) {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Please fill in the Total # of Enrollees to complete this order'));
					blnErrorInFacilitator2 = true;
					return null;
				} else {
					objCarrierOrder.Implementation_Stage__c = 'Ready to Send Enrollment Review';
					objCarrierOrder.Enrollment_Review_Completed_Date_Time__c = System.now();
				}
			}
		}
		if (!blnErrorInFacilitator2) {
			try {
				update objCarrierOrder;
			} catch (Exception ex) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
			}
		}

		return null;
	}

	public void fetchMultiEINCarrierOrders() {
		list_MultiEINCarrierOrders = new List<Carrier_Order__c>();
		if (objCarrierOrder != null && objCarrierOrder.Is_Multi_EIN__c) {
			for (Carrier_Order__c co : [
				SELECT ID, Benefit_Types__c, Parent_Carrier_Order__c, Benefit_Order__c, Benefit_Order__r.Name, Name
				FROM Carrier_Order__c
				WHERE (Id = :objCarrierOrder.Parent_Carrier_Order__c OR Parent_Carrier_Order__c = :objCarrierOrder.Id) AND RecordTypeId = :strCOBTRecordTypeId
			]) {
				if (objCarrierOrder.Id != co.Id) {
					list_MultiEINCarrierOrders.add(co);
				}
			}
		}
	}

	public void rejectCOByFacilitator2() {
		objCarrierOrder.Facilitator_2_Plan_Build__c = 'Y';
		objCarrierOrder.Facilitator_2_Plan_Review__c = null;
		objCarrierOrder.Implementation_Stage__c = 'Ready for Implementing Plans';
		objCarrierOrder.Order_Rejected_Timestamp__c = system.now();

		try {
			update objCarrierOrder;
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
		}
	}
}