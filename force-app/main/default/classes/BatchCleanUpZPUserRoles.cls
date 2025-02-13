/**
 * @Author       :   Debasmita Rawooth
 * @CreatedDate  :   05/27/2021
 * @Desc         :   Batch Job to process the Queued and Errored ZP_User_Role records
 * @TestClass    :   BatchCleanUpZPUserRolesTest
 **/
public class BatchCleanUpZPUserRoles implements Database.Batchable<sObject>, Database.Stateful {
	String strQuery;
	List<String> list_ZPUserRoleFields = new List<String>();
	Set<Id> set_prioritizedRoleIds = new Set<Id>();

	public BatchCleanUpZPUserRoles(string strQuery) {
		strQuery = strQuery;
	}

	public BatchCleanUpZPUserRoles() {
	}

	// New constructor to accept set of prioritized roles to be processed. This is called from ZPUserRoleTriggerHelper to process prioritized roles.
	// The set of prioritized roles is passed to the queable class to process the prioritized roles in a separate queued job.
	public BatchCleanUpZPUserRoles(Set<Id> set_prioritizedRoleIds) {
		this.set_prioritizedRoleIds = set_prioritizedRoleIds;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		if (String.isBlank(strQuery)) {
			strQuery = 'SELECT Id FROM ZP_User_Role__c WHERE Processing_State__c IN (\'Queued\',\'Error\') ORDER BY Company_Id__c NULLS FIRST';
		}
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<ZP_User_Role__c> list_ZPUserRoles) {
		//process the user role of records in the current chunk of the batch job
		processUserRoles(list_ZPUserRoles);
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new BatchConvertZPUserRoleLeads(), 1);
	}

	/**
	 * @Description : Common method to process the ZP_User_Role records by the batch and queuable job both.
	 * @Parm        : List of ZP_User_Role records
	 * @Return      : N/A
	 **/
	public void processUserRoles(List<ZP_User_Role__c> list_ZPUserRoles) {
		try {
			if (!list_ZPUserRoles.isEmpty()) {
				if (list_ZPUserRoleFields.isEmpty()) {
					list_ZPUserRoleFields = new List<String>(ZP_User_Role__c.SObjectType.getDescribe().fields.getMap().keySet());
				}

				// re-query records to get updated data as record context would have changed since the time batch apex was executed.
				List<ZP_User_Role__c> list_UserRolesToProcess = Database.query(
					'SELECT ' + String.join(list_ZPUserRoleFields, ',') + ' FROM ZP_User_Role__c WHERE Processing_State__c IN (\'Queued\',\'Error\') AND Id IN :list_ZPUserRoles FOR UPDATE'
				);

				LeadTriggerHelper.skiptrigger = true;
				ZPUserRoleTriggerHelper objZPUserRoleHelper = new ZPUserRoleTriggerHelper();
				objZPUserRoleHelper.processUserRoleInformation(list_UserRolesToProcess); //process zp user roles information
				LeadTriggerHelper.skiptrigger = false;

				//skip trigger and run update to stamp lookup fields, processing state and message
				ZPUserRoleTriggerHelper.skipTrigger = true;
				update list_UserRolesToProcess;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('BatchCleanUpZPUserRoles', 'processUserRoles', null, objException);
		}
	}

	public class BatchCleanUpZPUserRolesQueuable implements Queueable {
		public BatchCleanUpZPUserRoles objBatchClass;
		Set<Id> set_prioritizedRoleIds;

		/**
		 * @Description : Constructor of inner class to initialize the set of prioritized roles to the queable class
		 * @Parm        : An instance of BatchCleanUpZPUserRoles, the outer class
		 * @Return      : N/A
		 **/
		public BatchCleanUpZPUserRolesQueuable(BatchCleanUpZPUserRoles objBatchClass) {
			this.objBatchClass = objBatchClass;
			this.set_prioritizedRoleIds = objBatchClass.set_prioritizedRoleIds;
		}

		/**
		 * @Description : Execute method of queable interface as entry point of queued job. Called from ZPUserRoleTriggerHelper to process prioritized roles.
		 * @Parm        : An instance of a queable context
		 * @Return      : N/A
		 **/
		public void execute(QueueableContext context) {
			// process the user role of records in the current chunk of the queued job
			if (set_prioritizedRoleIds != null && !set_prioritizedRoleIds.isEmpty()) {
				List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();
				for (Id idRole : set_prioritizedRoleIds) {
					list_ZPUserRoles.add(new ZP_User_Role__c(Id = idRole));
				}
				objBatchClass.processUserRoles(list_ZPUserRoles);
			}
		}
	}
}