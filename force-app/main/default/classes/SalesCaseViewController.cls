public with sharing class SalesCaseViewController {
	public static Boolean blnTestException = false;

	@AuraEnabled
	public static void doRouting(Id idCase, String strCaseType) {
		try {
			if (blnTestException) {
				Integer intException = 0 / 0;
			}
			List<Case> list_Cases = [
				SELECT
					Id,
					AccountId,
					Subject,
					Description,
					Reason,
					Status,
					Case_Reason_L1__c,
					Case_Reason_L2__c,
					Case_Reason_L3__c,
					Origin,
					ContactEmail,
					Status_Detail__c,
					Requires_Action__c,
					Zendesk_Id__c,
					Reviewed_by_Dedicated_Support__c,
					Type,
					RecordTypeId,
					RecordType.name
				FROM Case
				WHERE Id = :idCase
			];
			if (!list_Cases.isEmpty() && String.isNotEmpty(strCaseType)) {
				CaseUtils.caseRouting(strCaseType, list_Cases[0]);
			}
		} catch (Exception e) {
			ExceptionLogUtil.logException('SalesCaseViewController', 'doRouting', e.getMessage(), e.getStackTraceString());
			if (!Test.isRunningTest()) {
				throw new AuraHandledException(e.getMessage());
			}
		}
	}
}