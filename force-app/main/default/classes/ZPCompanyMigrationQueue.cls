public with sharing class ZPCompanyMigrationQueue implements Queueable {
	private List<ZP_Company_Migration__c> list_ZPCompMigrations;

	public ZPCompanyMigrationQueue(List<ZP_Company_Migration__c> list_InputMigrations) {
		list_ZPCompMigrations = list_InputMigrations;
	}

	public void execute(QueueableContext context) {
		ZPCompanyMigrationTriggerHelper.queue = true;
		if (list_ZPCompMigrations.size() > 0) {
			update list_ZPCompMigrations;
		}
	}
}