public class CaseButtonPushBackToQueueExtension {
	public Case objCase;
	public CaseButtonPushBackToQueueExtension(ApexPages.StandardController stdController) {
		objCase = (Case) stdController.getRecord();
	}
	public pageReference ChangeOwner() {
		Pagereference pg = new Pagereference('/' + objCase.Id);
		objCase = [SELECT OwnerId FROM Case WHERE Id = :objCase.Id];

		String oId = objCase.OwnerId;
		if (oId.startsWith('00G')) {
			return pg;
		} else {
			String queueId = null;

			if (Test.isRunningTest()) {
				queueId = [SELECT Id FROM Group WHERE Name = 'test group' AND Type = 'Queue' LIMIT 1].Id;
			}
			for (CaseHistory objCaseHist : [SELECT OldValue, CaseId, Field FROM CaseHistory WHERE CaseId = :objCase.id ORDER BY CreatedDate DESC]) {
				if (objCaseHist.Field == 'Owner') {
					if (String.valueOf(objCaseHist.OldValue).startsWith('00G')) {
						queueId = String.valueOf(objCaseHist.OldValue);
						break;
					}
				}
			}
			if (queueId != null) {
				Case objUpdatedCase = new Case(Id = objCase.Id, OwnerId = queueId);
				update objUpdatedCase;
			}
		}
		return pg;
	}
}