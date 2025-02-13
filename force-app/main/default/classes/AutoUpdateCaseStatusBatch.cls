/**
 * @author      	Todd Dowdy
 * @description 	Batch Class querying valid cases with Auto_Close_Date_Time__c or Auto_Solve_Date_Time__c in the past hour to update cases.
 * 					If the cases has an auto solve date time in the past hour we will update the status and Date time solve field if necessary.
 * 					If the cases are ready to be auto closed we will update status to closed and update record type to read only.
 * @see				AutoUpdateCaseStatusBatchTest
 **/

public class AutoUpdateCaseStatusBatch implements Database.Batchable<sObject>, Schedulable {
	public static DateTime dtmNow = System.now();
	public static DateTime dtmMinusOneHour = System.Now().addHours(-2);
	public static Set<String> set_RTRequireConfirmCaseReason = new Set<String>{
		CaseUtils.RECTYPE_PAYROLL_CARE,
		CaseUtils.RECTYPE_BENEFITS_CARE,
		CaseUtils.RECTYPE_MODERN_BANK,
		CaseUtils.RECTYPE_R_D_TAX_CREDITS,
		CaseUtils.RECTYPE_ENGAGEMENT
	};
	//Added set_EngagementRelatedRecordTypes for EngagementRelatedRecordTypes
	public static Set<String> set_EngagementRelatedRecordTypes = new Set<String>{ CaseUtils.RECTYPE_PAYROLL_CARE, CaseUtils.RECTYPE_ENGAGEMENT };
	public static Map<Id, String> map_RTIdToCloseResolution = new Map<Id, String>{ CaseUtils.RECTYPE_R_D_TAX_CREDITS => CaseUtils.RESOLUTION_CUSTOMER_UNRESPONSIVE };
	public List<Case_Reason_Classification__c> list_NoActionCaseReasons = new List<Case_Reason_Classification__c>();

	public AutoUpdateCaseStatusBatch() {
		list_NoActionCaseReasons = CaseQueryHelper.queryCaseReason(CaseUtils.STR_AUTO_SOLVED_CASE_REASON);
	}
	public Database.QueryLocator start(Database.BatchableContext bc) {
		// Parse custom label with gmt time zone for SOQL DateTime fields
		String strStartDT = dtmMinusOneHour.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
		String strEndDT = dtmNow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
		String strAutoUpdateQuery = Label.AutoUpdateCaseBatch;

		if (String.isNotBlank(strAutoUpdateQuery)) {
			strAutoUpdateQuery = strAutoUpdateQuery.replace('{System.now().addHours(-1)}', strStartDT);
			strAutoUpdateQuery = strAutoUpdateQuery.replace('{System.now()}', strEndDT);

			return Database.getQueryLocator(strAutoUpdateQuery);
		} else {
			ExceptionLogUtil.logException('AutoUpdateCaseStatusBatch', 'execute', 'AutoUpdateCaseBatch Custom Label is Empty', '');
			return null;
		}
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		try {
			List<Case> list_Cases = (List<Case>) scope;
			Map<Id, Case> map_UpdateCases = new Map<Id, Case>();
			List<String> list_ConsolidatedDMLErrors = new List<String>();
			CaseTriggerHelper.context = 'AutoUpdateCaseStatusBatch';

			for (Case objCase : list_Cases) {
				if (objCase.RecordTypeId != null) {
					if (
						(objCase.Status == CaseUtils.STATUS_SOLVED ||
						objCase.Status == CaseUtils.STATUS_CLOSED) &&
						objCase.Auto_Close_Date_Time__c >= dtmMinusOneHour &&
						objCase.Auto_Close_Date_Time__c <= dtmNow &&
						!set_EngagementRelatedRecordTypes.contains(objCase.RecordTypeId) //Added to bypass for EngagementRelatedRecordTypes
					) {
						if (objCase.Status == CaseUtils.STATUS_SOLVED) {
							objCase.Status = CaseUtils.STATUS_CLOSED;
						}

						if (objCase.Status == CaseUtils.STATUS_CLOSED) {
							if (objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE) {
								objCase.RecordTypeId = CaseUtils.RECTYPE_PAYROLL_CARE_READ_ONLY;
							} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_BENEFITS_CARE) {
								objCase.RecordTypeId = CaseUtils.RECTYPE_BENEFITS_CARE_READ_ONLY;
							} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_MODERN_BANK) {
								objCase.RecordTypeId = CaseUtils.RECTYPE_MODERN_BANK_READ_ONLY;
							} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLLOPS_AUDIT) {
								objCase.RecordTypeId = CaseUtils.RECTYPE_PAYROLLOPS_AUDIT_READ_ONLY;
							} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
								objCase.RecordTypeId = CaseUtils.RECTYPE_TAXRES_READ_ONLY;
							} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_RISK_ASSURANCE) {
								objCase.RecordTypeId = CaseUtils.RECTYPE_RISK_ASSURANCE_READ_ONLY;
							} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_SALES_CASES) {
								objCase.RecordTypeId = CaseUtils.RECTYPE_SALES_CASES_CLOSED;
							}

							map_UpdateCases.put(objCase.Id, objCase);
						}

						//Populate Close Resolution If Case is auto closed and resolution was not selected
						Boolean blnIsUpdate = autoPopulateCloseResolution(objCase);
						if (blnIsUpdate) {
							map_UpdateCases.put(objCase.Id, objCase);
						}
					}

					if (
						objCase.Status == CaseUtils.STATUS_AWAITING_RESPONSE &&
						objCase.Auto_Solve_Date_Time__c >= dtmMinusOneHour &&
						objCase.Auto_Solve_Date_Time__c <= dtmNow &&
						objCase.Do_not_Auto_Solve__c == false &&
						!set_EngagementRelatedRecordTypes.contains(objCase.RecordTypeId) //Added to bypass for EngagementRelatedRecordTypes
					) {
						objCase.Status = CaseUtils.STATUS_SOLVED;
						if (objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE || objCase.RecordTypeId == CaseUtils.RECTYPE_BENEFITS_CARE) {
							if (String.isBlank(objCase.Confirm_Case_Reason__c) && !list_NoActionCaseReasons.isEmpty()) {
								Case_Reason_Classification__c objCaseReason = list_NoActionCaseReasons[0];
								objCase.Confirm_Case_Reason__c = CaseUtils.STR_AUTO_SOLVED_CASE_REASON;
								objCase.Confirm_Case_Reason_Classification__c = objCaseReason.Id;
								Id idUpdatedRecordType = RecordTypes.getRecordTypeIdFromName('Case', objCaseReason.Type__c);
								if (idUpdatedRecordType != null) {
									objCase.RecordTypeId = idUpdatedRecordType;
									objCase.Type = objCaseReason.Type__c;
								}
							}

							if (String.isBlank(objCase.Audience__c)) {
								objCase.Audience__c = CaseUtils.AUDIENCE_OTHER;
							}
						}

						if (set_RTRequireConfirmCaseReason.contains(objCase.RecordTypeId)) {
							objCase.Automation_Message__c = 'Auto Solve Email Alert';
							objCase.Automation_Status__c = 'Started';
							if (!CaseUtils.set_EngagementRecordTypes.contains(objCase.RecordTypeId)) {
								objCase.Date_Time_Solved__c = System.now();
							}
						}
						map_UpdateCases.put(objCase.Id, objCase);
					}
					/* Description: Added below Criteria to Update Case Status to Closed from Awaiting Response*/
					if (
						objCase.Status == CaseUtils.STATUS_AWAITING_RESPONSE &&
						objCase.Auto_Close_Date_Time__c >= dtmMinusOneHour &&
						objCase.Auto_Close_Date_Time__c <= dtmNow &&
						set_EngagementRelatedRecordTypes.contains(objCase.RecordTypeId) &&
						!list_NoActionCaseReasons.isEmpty()
					) {
						objCase.Status = CaseUtils.STATUS_CLOSED;
						// Add a Auto Solved case reason only if Confirm Case Reason is blank
						if (String.isBlank(objCase.Confirm_Case_Reason__c)) {
							Case_Reason_Classification__c objCaseReason = list_NoActionCaseReasons[0];
							objCase.Confirm_Case_Reason__c = CaseUtils.STR_AUTO_SOLVED_CASE_REASON;
							objCase.Confirm_Case_Reason_Classification__c = objCaseReason.Id;
						}
						// Add Audience only if it is blank
						if (String.isBlank(objCase.Audience__c)) {
							objCase.Audience__c = CaseUtils.AUDIENCE_OTHER;
						}
						if (set_RTRequireConfirmCaseReason.contains(objCase.RecordTypeId)) {
							objCase.Automation_Message__c = 'Auto Solve Email Alert';
							objCase.Automation_Status__c = 'Started';
						}
						//BTE-4205 - Automate Auto-Solve Status on Case
						if(objCase.Auto_Solve_Status__c == CaseUtils.AUTO_SOLVE_STATUS_ATTEMPTED){
							objCase.Auto_Solve_Status__c = CaseUtils.STATUS_SOLVED;
						}
						map_UpdateCases.put(objCase.Id, objCase);
					}
					if (
						objCase.Status == CaseUtils.STATUS_AWAITING_INTERNAL_SUPPORT &&
						objCase.Follow_Up_Date_Time__c >= dtmMinusOneHour &&
						objCase.Follow_Up_Date_Time__c <= dtmNow &&
						objCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT
					) {
						objCase.Status = CaseUtils.STATUS_IN_PROGRESS;
						objCase.Follow_Up_Date_Time__c = null;
						map_UpdateCases.put(objCase.Id, objCase);
					}
				}
			}
			if (!map_UpdateCases.isEmpty()) {
				List<Database.SaveResult> list_UpdateResults = Database.update(map_UpdateCases.values(), false);
				list_ConsolidatedDMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_UpdateResults, 'Update'));
			}

			if (!list_ConsolidatedDMLErrors.isEmpty()) {
				//Create exception log when errors occur.
				ExceptionLogUtil.logException(UserInfo.getUserId(), 'AutoUpdateCaseStatusBatch', 'processDML', list_ConsolidatedDMLErrors, '');
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('AutoUpdateCaseStatusBatch', 'execute', ex);
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :bc.getJobId()];
		if (objAsyncJob.NumberOfErrors > 0) {
			Utils.processBatchFinish(objAsyncJob, '', false);
		}
	}

	public void execute(SchedulableContext sc) {
		Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = objConfigSettings?.AutoUpdateCaseStatusBatchSize__c != null ? (Integer) objConfigSettings.AutoUpdateCaseStatusBatchSize__c : 20;

		Database.executeBatch(new AutoUpdateCaseStatusBatch(), intBatch);
	}

	/**
	 * @description   Auto populate a Case resolution if case is closed and Resolution was not selected.
	 * Note: The function may modify parameter @objCase
	 * @author Ajay Krishna P U
	 * @param objCase Case Object
	 * @return        `Boolean` true if @objCase have modified
	 */
	@testVisible
	private Boolean autoPopulateCloseResolution(Case objCase) {
		Boolean blnIsUpdate = false;

		//Case is closed But Resolution is not populated yet
		if (
			objCase.Status == CaseUtils.STATUS_CLOSED &&
			objCase.Case_Resolution__c == null &&
			objCase.RecordTypeId != null &&
			map_RTIdToCloseResolution != null &&
			map_RTIdToCloseResolution.containsKey(objCase.RecordTypeId)
		) {
			objCase.Case_Resolution__c = map_RTIdToCloseResolution.get(objCase.RecordTypeId);
			blnIsUpdate = true;
		}

		return blnIsUpdate;
	}
}