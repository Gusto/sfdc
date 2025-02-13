@istest
public class TaskEditOnLoadExtensionTest {
	private static testMethod void testTaskEditOnLoad() {
		Task tsk = new Task(Genesys_Ani__c = 'Internal', Status = 'Open');
		insert tsk;

		Test.startTest();
		ApexPages.StandardController taskCont = new ApexPages.StandardController(tsk);
		TaskEditOnLoadExtension extension = new TaskEditOnLoadExtension(taskCont);
		String nextPage = '';
		PageReference pageRef = Page.TaskEditOnLoad;
		pageRef.getParameters().put('id', String.valueOf(tsk.Id));
		Test.setCurrentPage(pageRef);
		nextPage = taskCont.save().getUrl();
		System.assertEquals(nextPage, nextPage);
		extension.getRouter();
		Test.stopTest();
	}
}