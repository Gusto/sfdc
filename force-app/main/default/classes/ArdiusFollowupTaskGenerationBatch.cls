/**
 * @description Ardius Followup task processing batch
 * @author      Ajay Krishna P U
 * @since       2024-12-23
 * @see 		ArdiusFollowupTaskGenerationBatchTest
 */
public without sharing class ArdiusFollowupTaskGenerationBatch implements Database.Batchable<SObject>, Schedulable {
	public final static String TASK_TEMP_TYPE_FOLLOW_UP = 'Ardius Followup Task';
	public final static String TASK_TEMP_SUB_ONBOARDING_STALLED = 'Onboarding Stalled';
	public final static String OBJ_OPPORTUNITY = 'Opportunity';

	private String strQuery;

	/**
	 * @description Default constractor
	 */
	public ArdiusFollowupTaskGenerationBatch() {
	}

	/**
	 * @description    To run batch based on custom query.
	 * @param strQuery Custom Query to run batch
	 */
	public ArdiusFollowupTaskGenerationBatch(String strQuery) {
		this.strQuery = strQuery;
	}

	/**
	 * @description      Batch start method
	 * @param objContext Batch Context
	 * @return           `Database.QueryLocator`
	 */
	public Database.QueryLocator start(Database.BatchableContext objContext) {
		if (String.isNotBlank(strQuery)) {
			return Database.getQueryLocator(strQuery);
		}

		return Database.getQueryLocator(
			[
				SELECT
					Id,
					Company_Information_Complete__c,
					Onboarding_Complete__c,
					Collecting_Company_Information_End__c
				FROM Opportunity
				WHERE RecordTypeId = :OpportunityUtil.R_D_TAX_CREDITS_OPPTY_RT_ID AND Company_Information_Complete__c = TRUE AND Onboarding_Complete__c = FALSE AND Collecting_Company_Information_End__c = TODAY
			]
		);
	}

	/**
	 * @description      Batch job execute method
	 * @param objContext batch Context
	 * @param list_Opportunities List of Opportunities to process
	 */
	public void execute(Database.BatchableContext objContext, List<Opportunity> list_Opportunities) {
		List<TaskTemplateUtil.TemplateType> list_TaskTemplateTypes = new List<TaskTemplateUtil.TemplateType>();
		for (Opportunity objOpportunity : list_Opportunities) {
			list_TaskTemplateTypes.add(new TaskTemplateUtil.TemplateType(objOpportunity.Id, TASK_TEMP_TYPE_FOLLOW_UP, TASK_TEMP_SUB_ONBOARDING_STALLED, new Map<String, String>()));
		}

		if (list_TaskTemplateTypes.isEmpty()) {
			return;
		}

		List<Task> list_TaskToInsert = TaskTemplateUtil.generateTasks(list_TaskTemplateTypes, OBJ_OPPORTUNITY);
		List<Database.SaveResult> list_SaveResults = Database.insert(list_TaskToInsert, false);
		Utils.processSaveResult(list_SaveResults, list_TaskToInsert, null, true, 'ArdiusFollowupTaskGenerationBatch - execute');
	}

	/**
	 * @description Batch finish method
	 * @param objContext Batch context
	 */
	public void finish(Database.BatchableContext objContext) {
	}

	/**
	 * @description Schedulable Execute method
	 * @param objContext
	 */
	public void execute(SchedulableContext objContext) {
		Integer intBatchSize = Integer.valueOf(Ardius_Configuration__c.getInstance().Ardius_Followup_Task_Batch_Size__c ?? 50);
		Database.executeBatch(new ArdiusFollowupTaskGenerationBatch(), intBatchSize);
	}
}