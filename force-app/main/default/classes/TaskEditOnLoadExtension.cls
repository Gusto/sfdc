public with sharing class TaskEditOnLoadExtension {
	public Task theTask { get; set; }

	public TaskEditOnLoadExtension(ApexPages.StandardController controller) {
		theTask = (Task) controller.getRecord();
		theTask = [SELECT Id, Genesys_Ani__c, isClosed FROM Task WHERE Id = :theTask.id];
	}

	public PageReference getRouter() {
		PageReference p;
		if (theTask.Genesys_Ani__c == 'Internal' && theTask.isClosed == false) {
			p = new PageReference('/' + theTask.id + '/e?retURL=%2F' + theTask.id);
		} else {
			p = new PageReference('/apex/TaskDetailOnLoad?=' + theTask.id + '/e?retURL=%2F' + '/apex/TaskDetailOnLoad?=' + theTask.id);
		}
		return p;
	}
}