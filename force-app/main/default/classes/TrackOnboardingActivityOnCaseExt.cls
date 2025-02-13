/**
 * Created By        :   Neha
 * Created Date      :   6-Nov-2020
 * Test Classes      :   TrackOnboardingActivityOnCaseExtTest
 * Desciption        :   Controller for Console component to identify active case and update its status accordingly.
 *                       For an active case tab, Status = 'In Progress'
 *                       For an inactive case tab or closed tab, Status='Open'
 */
public with sharing class TrackOnboardingActivityOnCaseExt {
	private Id idLoggedInUser;
	private Set<String> set_ValidCaseRecTypes;
	static final String CASE_RECTYPE_NEW_PLAN = 'Benefits New Plan Case',
		CASE_RECTYPE_RENEWAL = 'Benefits Renewal Case',
		CASE_RECTYPE_CHANGE = 'Benefits Change Case',
		CASE_STATUS_NEW = 'New',
		CASE_STATUS_OPEN = 'Open',
		CASE_STATUS_INPROGRESS = 'In Progress',
		CASE_STATUS_RESPONSE_RECEIVED = 'Response Received';

	public TrackOnboardingActivityOnCaseExt(ApexPages.StandardController controller) {
		idLoggedInUser = UserInfo.getUserId();
		set_ValidCaseRecTypes = new Set<String>{ CASE_RECTYPE_NEW_PLAN, CASE_RECTYPE_RENEWAL, CASE_RECTYPE_CHANGE };
	}
	/*
	 * Flip case status to In Progress
	 */
	public void updateCaseStatusToInProgress() {
		try {
			String strFocussedCaseId = ApexPages.currentPage().getParameters().containsKey('moveToInProgressId') ? ApexPages.currentPage().getParameters().get('moveToInProgressId') : '';
			if (String.isNotBlank(strFocussedCaseId)) {
				Id idFocussedCase = Id.valueOf(strFocussedCaseId);
				Set<String> set_ValidStatus = new Set<String>{ CASE_STATUS_NEW, CASE_STATUS_OPEN, CASE_STATUS_RESPONSE_RECEIVED };
				List<Case> list_Case = [
					SELECT Id, RecordType.Name
					FROM Case
					WHERE Id = :idFocussedCase AND RecordType.Name IN :set_ValidCaseRecTypes AND Status IN :set_ValidStatus AND OwnerId = :idLoggedInUser
				];

				if (list_Case != null && !list_Case.isEmpty()) {
					list_Case[0].Status = CASE_STATUS_INPROGRESS;
					update list_Case[0];
				}
			}
		} catch (Exception objExc) {
			ExceptionLogUtil.logException('Error', 'TrackOnboardingActivityOnCaseExt', 'updateCaseStatusToInProgress', objExc.getMessage(), objExc.getStackTraceString());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExc.getMessage()));
		}
	}
	/*
	 * Flip case status to Open
	 */
	public void updateCaseStatusToOpen() {
		try {
			String strCaseId = ApexPages.currentPage().getParameters().containsKey('moveToOpenId') ? ApexPages.currentPage().getParameters().get('moveToOpenId') : '';
			if (String.isNotBlank(strCaseId)) {
				Id idCase = Id.valueOf(strCaseId);
				List<Case> list_Case = [
					SELECT Id, RecordType.Name, Subject, OwnerId, Status
					FROM Case
					WHERE Id = :idCase AND RecordType.Name IN :set_ValidCaseRecTypes AND Status = :CASE_STATUS_INPROGRESS AND OwnerId = :idLoggedInUser
				];

				if (list_Case != null && !list_Case.isEmpty()) {
					list_Case[0].Status = CASE_STATUS_OPEN;
					update list_Case[0];
				}
			}
		} catch (Exception objExc) {
			ExceptionLogUtil.logException('Error', 'TrackOnboardingActivityOnCaseExt', 'updateCaseStatusToOpen', objExc.getMessage(), objExc.getStackTraceString());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExc.getMessage()));
		}
	}
}