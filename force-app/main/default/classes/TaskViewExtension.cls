public class TaskViewExtension {
	public Task theTask { get; private set; }
	public string caseNumber { get; private set; }

	public TaskViewExtension(ApexPages.StandardController controller) {
		caseNumber = '';
		theTask = (Task) controller.getRecord();
		theTask = [SELECT Id, WhatId, CallObject FROM Task WHERE id = :theTask.id];
		String whatId = theTask.WhatId;
		if (whatId != null && whatId.indexOf('500') == 0) {
			Case theCase = [SELECT Id, CaseNumber FROM case WHERE id = :whatId];
			caseNumber = theCase.CaseNumber;
		}
	}
}