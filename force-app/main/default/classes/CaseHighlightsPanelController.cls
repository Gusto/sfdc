/*
 * Created By Praveen Sethu, Jun 19th, 2019
 * it is used to fetch key account information and use for routing purposes
 */
public without sharing class CaseHighlightsPanelController {
	public static final String TYPE_TAX_RES = 'Tax Res';
	public static final String CASE_STATUS_READY_FOR_DATA_CAPTURE = 'Ready for Data Capture';
	public static final String ROUTE_TO_SALES = 'Route to Sales';

	/*
	 * Wrapper Class to share data
	 * between Apex and LWC.
	 */
	public class CaseHighlightsPanelResponseWrapper {
		/* All variables that are exposed to LWC are annotated as @AuraEnabled */

		/* Indicates if transaction is success or failure */
		@AuraEnabled
		public Boolean blnIsSuccess;

		/* If there are any exceptions, exception message will be returned back to the UI */
		@AuraEnabled
		public String strErrorMessage;

		/* Returns Case object along with related Account and Contact data  */
		@AuraEnabled
		public Case objCase;

		/* Parameterized Constructor - Instantiates an object of this nested wrapper class */
		public CaseHighlightsPanelResponseWrapper(Case objCase, Boolean blnIsSuccess, String strErrorMessage) {
			this.objCase = objCase;
			this.blnIsSuccess = blnIsSuccess;
			this.strErrorMessage = strErrorMessage;
		}
	}

	@AuraEnabled
	public static Case_Reason_Classification__c returnCaseReasonClassification(String idCaseReason) {
		if (String.isNotBlank(idCaseReason)) {
			try {
				return [
					SELECT Id, Type__c, Class__c, Task_Us__c, Survey_Eligible__c, Priority__c, Do_not_Auto_Solve__c
					FROM Case_Reason_Classification__c
					WHERE Id = :idCaseReason AND Active__c = TRUE
				];
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'CaseHighlightsPanelController',
					'returnCaseReasonClassification',
					objException.getMessage(),
					objException.getStackTraceString() +
					' case reason: ' +
					idCaseReason
				);
				return null;
			}
		}
		return null;
	}

	@AuraEnabled
	public static Case_Reason_Classification__c returnCaseReasonClassificationFromLabel(String strCaseReasonLabel, String strRecordType) {
		try {
			if (strRecordType != 'Generic Routing') {
				return [
					SELECT Id, Type__c, Class__c, Task_Us__c, Survey_Eligible__c, Priority__c, Do_not_Auto_Solve__c
					FROM Case_Reason_Classification__c
					WHERE Name = :strCaseReasonLabel AND Type__c = :strRecordType AND Active__c = TRUE
				];
			} else {
				return [
					SELECT Id, Type__c, Class__c, Task_Us__c, Survey_Eligible__c, Priority__c, Do_not_Auto_Solve__c
					FROM Case_Reason_Classification__c
					WHERE Name = :strCaseReasonLabel AND Active__c = TRUE
				];
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('CaseHighlightsPanelController', 'returnCaseReasonClassificationFromLabel', objException.getMessage(), objException.getStackTraceString());
			return null;
		}
	}

	/* Updating routing case reason classication */
	@AuraEnabled
	public static CaseHighlightsPanelResponseWrapper updateCaseRoutingClassification(
		Case objCase,
		String strTypeName,
		Id idRoutingCaseReasonClassification,
		String strClassName,
		String strRoutingReasonClassification
	) {
		try {
			Boolean blnOwnerSet = false;
			String strOldCaseType = objCase?.Type;
			String strOldCaseStatus = objCase?.Status;
			
			if (!String.isBlank(strTypeName)) {
				strTypeName = strTypeName == CaseUtils.TYPE_SALES ? CaseUtils.TYPE_SALES_CASES : strTypeName;
				if (Schema.SObjectType.Case.getRecordTypeInfosByName().get(strTypeName) != null) {
					// Setting Type to Default value based on Record Type
					objCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(strTypeName).getRecordTypeId();
					objCase.Case_Pillar__c = objCase.Sub_Pillar__c = objCase.WFM_Queue_Tag__c = objCase.Pillar_Key__c = objCase.Sub_Pillar_Key__c = '';
				}
			}
            //Set default case status according to support process (BTE-3629)
            Case defaultStatusCase = (Case)Case.sObjectType.newSObject(objCase.RecordTypeId, true);
            objCase.Status = defaultStatusCase.Status;
			
			// Get case reason classification
			List<Case_Reason_Classification__c> list_caseReasonClassification = [
				SELECT Id, Generic_Routing_Reason__c, Queue_Override__c, Default_Type__c, Case_Type_Pillar__c, Support_Level__c, Specialization__c
				FROM Case_Reason_Classification__c
				WHERE Id = :idRoutingCaseReasonClassification
			];
			// Check if list is not empty
			if (!list_caseReasonClassification.isEmpty()) {
				Case_Reason_Classification__c objReasonClassification = list_caseReasonClassification.get(0);
				// Check if it is a generic routing reason and queue override is not blank
				if (objReasonClassification.Generic_Routing_Reason__c && !String.isBlank(objReasonClassification.Queue_Override__c)) {
					List<Group> list_queueGroupList = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :objReasonClassification.Queue_Override__c];
					if (!list_queueGroupList.isEmpty()) {
						objCase.OwnerId = list_queueGroupList.get(0).Id;
						blnOwnerSet = true;
					}
				}
			}
			if (strRoutingReasonClassification == ROUTE_TO_SALES) {
				objCase.Status = CaseUtils.STATUS_ACTIVE;
			}

			// Run assignment rules only when case owner is not previosuly set
			if (!blnOwnerSet && strClassName != 'Class 0') {
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule = true;
				objCase.setOptions(dmo);
			}

			
			if (!String.isBlank(strTypeName) && Schema.SObjectType.Case.getRecordTypeInfosByName().get(strTypeName) != null) {

				Case_Reason_Classification__c objReasonClassification = list_caseReasonClassification.get(0);
				if (objReasonClassification.Default_Type__c == Label.Engagement_RecordType_Name) {
					objCase.Support_Level__c = objReasonClassification.Support_Level__c;
					objCase.Type = objReasonClassification.Case_Type_Pillar__c;
					objCase.Specialization__c = objReasonClassification.Specialization__c;
					objCase.Answer_IQ_Eligible__c = false;
				} else {
					objCase.Type = objReasonClassification.Default_Type__c;
				}					
				if (objCase.Type == TYPE_TAX_RES && strOldCaseType != TYPE_TAX_RES) {
					objCase.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
				}
				if (strTypeName == CaseUtils.TYPE_SALES_CASES) {
					objCase.Status = CaseUtils.STATUS_ACTIVE;
				}

				if (strTypeName == CaseUtils.TYPE_MODERN_BANK) {
					if (strOldCaseStatus == CaseUtils.STATUS_IN_PROGRESS) {
						objCase.Status = CaseUtils.STATUS_WORKING;
					} else if (strOldCaseStatus == CaseUtils.STATUS_OPEN) {
						objCase.Status = CaseUtils.STATUS_ACTIVE;
					}
				}
			}
			objCase.Routing_Case_Reason_Classification__c = idRoutingCaseReasonClassification;
			objCase.Class__c = strClassName;
			objCase.Send_Survey__c = false;
			objCase.Routing_Case_Reason__c = strRoutingReasonClassification;

			if (objCase.Specialization__c == CaseUtils.SPANISH_SPECIALIZATION) {
				objCase.Case_In_Route__c = true;
			} else {
				objCase.Case_In_Route__c = false;
			}

			// Set Dedicated Support
			if (CaseUtils.checkForDedicateUser()) {
				objCase.Reviewed_by_Dedicated_Support__c = true;
			}

			// Changing Toggle to skip ValidationRule(Prevent_Case_Owner_Change) when case is Re-Routed
			objCase.Toggle__c = !objCase.Toggle__c;
			if (objCase.RecordTypeId == CaseUtils.RECTYPE_GEP_CX && strOldCaseStatus == CaseUtils.STATUS_OPEN) {
				objCase.status = CaseUtils.STATUS_ASSIGNED;
			} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_GEP_CX && strOldCaseStatus == CaseUtils.STATUS_IN_PROGRESS){
				objCase.status = CaseUtils.STATUS_ACTIVE;
			} else if (objCase.RecordTypeId == CaseUtils.R_D_TAX_CREDITS && strOldCaseStatus == CaseUtils.STATUS_IN_PROGRESS){
				objCase.status = CaseUtils.STATUS_IN_PROCESS;
			}
			update objCase;
			Case objCaseToReturn = [SELECT Id, CaseNumber, Owner.Name FROM Case WHERE Id = :objCase.Id];
			return new CaseHighlightsPanelResponseWrapper(objCaseToReturn, true, '');
		} catch (Exception objException) {
			//Skip validation rule errors since they come from bad user input
			if (!objException.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || Test.isRunningTest()) {
				ExceptionLogUtil.logException(
					'CaseHighlightsPanelController',
					'updateCaseRoutingClassification',
					objException.getMessage(),
					objException.getStackTraceString() +
					'\n routing case reason written: ' +
					objCase.Routing_Case_Reason__c +
					'\n classification chosen: ' +
					objCase.Routing_Case_Reason_Classification__c
				);
			}
			return new CaseHighlightsPanelResponseWrapper(null, false, objException.getMessage());
		}
	}
}