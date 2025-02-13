/*************************************************************************************************************
 * name			AnswersAuraComponentController
 * author			Dhir Kumar
 * created			30 / 06 / 2020
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	-------------	----------------------------------------------
 * version		1.0		2020-06-30		Dhir Kumar	    To Implement the functionality of the case active tab from the subtab.
 **************************************************************************************************************/
public class AnswersAuraComponentController {
	/* Wrapeper Class */
	public class WrapperResponse {
		@AuraEnabled
		public String strResponseData;

		@AuraEnabled
		public Boolean blnIsSuccess;

		@AuraEnabled
		public String strResponseMessage;

		@AuraEnabled
		public Case objCase;

		public wrapperResponse(String responseData, Boolean blnIsSuccess, String strResponseMessage) {
			this.strResponseData = strResponseData;
			this.blnIsSuccess = blnIsSuccess;
			this.strResponseMessage = strResponseMessage;
		}
	}

	/*********************************************************************************************************
	 * name			    getAnswers
	 * author			Dhir
	 * @created			30 / 06 / 2020
	 * param			String primaryCaseId : CaseId, list_CaseStatuses : Should not update to In Progress status for these values
	 * return			null
	 **********************************************************************************************************/
	@AuraEnabled
	public static WrapperResponse getAnswers(String idPrimaryCase, List<String> list_CaseStatuses) {
		WrapperResponse objWrapperResponse;
		if (idPrimaryCase != null) {
			// Fetch Case list
			list<Case> list_cases = [SELECT Id, RecordTypeId, RecordType.Name, Subject, OwnerId, Status FROM Case WHERE Id = :idPrimaryCase];
			// Check if the size is more than zero
			if (list_cases.size() > 0) {
				// Check if record type matches Payroll Care or Benefits Care
				if (
					list_cases[0].RecordType.Name.indexOf('Payroll Care') > -1 ||
					list_cases[0].RecordType.Name.indexOf('Benefits Care') > -1
				) {
					// Check if the status does not match specific values
					if (
						!list_CaseStatuses.contains(list_cases[0].Status) &&
						list_cases[0].OwnerId == UserInfo.getUserId()
					) {
						try {
							if (list_cases[0].RecordTypeId != CaseUtils.RECTYPE_TAXRES) {
								// Set case status to In Progress
								list_cases[0].Status = 'In Progress';
							}

							// update Case
							update list_cases;
							// Set success flag to true, return case object
							objWrapperResponse = new wrapperResponse('', true, 'Record Updated');
							objWrapperResponse.objCase = list_cases[0];
						} catch (Exception objException) {
							//Skip validation rule errors since they come from bad user input
							if (!objException.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
								ExceptionLogUtil.logException('AnswersAuraComponentController', 'getAnswers', objException.getMessage(), objException.getStackTraceString());
							}
							
							objWrapperResponse = new wrapperResponse('', false, 'Error : ' + objException.getMessage());
						}
					} else {
						objWrapperResponse = new wrapperResponse('', false, 'Record criteria does not match');
					}
				}
			}
		}
		return objWrapperResponse;
	}

	/* If user has multiple tabs opened, update other case statuses to Open */
	@AuraEnabled
	public static wrapperResponse checkAllPrimaryTabStatus(List<String> list_caseId) {
		WrapperResponse objWrapperResponse;
		// Check if list of cases are not null and size greater than 0
		if (list_caseId != null && list_caseId.size() > 0) {
			String strQuery = String.join(list_caseId, ',');
			List<Case> list_casesToUpdate = new List<Case>();
			if (!String.isBlank(strQuery)) {
				List<String> set_caseId = strQuery.split(',');
				// Fetch list of cases matching Payroll Care, Benefits Care and Tax Res
				list<Case> list_cases = [SELECT Id, RecordType.Name, Subject, OwnerId, Status FROM Case WHERE Id IN :set_caseId AND RecordType.Name IN ('Payroll Care', 'Benefits Care')];
				// If list size is greater than 0, iterate over list, check if case status is In Progress
				if (list_cases.size() > 0) {
					for (Case objCase : list_cases) {
						// Check if case is In Progress and user owns the case
						if (objCase.Status == 'In Progress' && objCase.OwnerId == UserInfo.getUserId()) {
							// Set case status to Open
							objCase.Status = 'Open';
							// Add to list of cases to be updated
							list_casesToUpdate.add(objCase);
						}
					}
					// if the list of cases to update is not empty, update cases
					if (list_casesToUpdate.size() > 0) {
						try {
							// update cases
							update list_casesToUpdate;
							objWrapperResponse = new WrapperResponse('', true, 'Record Updated');
						} catch (Exception objException) {
							ExceptionLogUtil.logException('AnswersAuraComponentController', 'checkAllPrimaryTabStatus', objException.getMessage(), objException.getStackTraceString());
							objWrapperResponse = new WrapperResponse('', false, 'Error : ' + objException.getMessage());
						}
					} else {
						objWrapperResponse = new WrapperResponse('', false, 'Record criteria does not match');
					}
				} else {
					objWrapperResponse = new WrapperResponse('', false, 'Record criteria does not match');
				}
			}
		}
		return objWrapperResponse;
	}

	/* When Users Close Tab, Update Case Status to Open */
	@AuraEnabled
	public static wrapperResponse checkClosedTabStatus(String idCloseTabCase) {
		// Get the id of the tab that is closed
		wrapperResponse objWrapperResponse;
		// Check if it is not null
		if (idCloseTabCase != null) {
			// Fetch list of case matching close case Id
			list<Case> list_cases = [
				SELECT Id, RecordType.Name, Subject, OwnerId, Status, Case_In_Route__c
				FROM Case
				WHERE Id = :idCloseTabCase AND RecordType.Name IN ('Payroll Care', 'Benefits Care')
			];
			// If the list is greater than 0 and case owner id is logged in user id, update status to Open
			if (list_cases.size() > 0) {
				if (list_cases[0].Status == 'In Progress' && list_cases[0].OwnerId == UserInfo.getUserId()) {
					list_cases[0].Status = 'Open';
					try {
						update list_cases;
						objWrapperResponse = new wrapperResponse('', true, 'Record Updated');
					} catch (Exception objException) {
						ExceptionLogUtil.logException('AnswersAuraComponentController', 'checkClosedTabStatus', objException.getMessage(), objException.getStackTraceString());
						objWrapperResponse = new wrapperResponse('', false, 'Error : ' + objException.getMessage());
					}
				} else if (list_cases[0].Case_In_Route__c) {
					try {
						// Update Case In Route to false
						list_cases[0].Case_In_Route__c = false;
						update list_cases;
						objWrapperResponse = new wrapperResponse('', true, 'Record Updated');
					} catch (Exception objException) {
						//If exception occurs make another attempt to update the records
						CaseTriggerHelper.skipTrigger = true;
						update list_cases;
						CaseTriggerHelper.skipTrigger = false;
						ExceptionLogUtil.logException('AnswersAuraComponentController', 'checkClosedTabStatus', objException.getMessage(), objException.getStackTraceString());
						objWrapperResponse = new wrapperResponse('', false, 'Error : ' + objException.getMessage());
					}
				} else {
					objWrapperResponse = new wrapperResponse('', false, 'Record criteria does not match');
				}
			}
		}
		return objWrapperResponse;
	}
}