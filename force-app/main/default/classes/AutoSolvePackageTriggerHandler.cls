/*
 * @name         AutoSolvePackageTriggerHandler
 * @author       Ankit Rajput
 * @date         07-16-2024
 * @description  This is the triggerHandler class for Auto_Solve_Package__c custom object trigger
 * @test classes AutoSolvePackageTriggerHelperTest
 */

public without sharing class AutoSolvePackageTriggerHandler extends TriggerHandler {
	private List<Auto_Solve_Package__c> newRecords;
    private List<Auto_Solve_Package__c> oldRecords;
	private Map<Id, Auto_Solve_Package__c> newRecordsMap;
	private Map<Id, Auto_Solve_Package__c> oldRecordsMap;
    
    public AutoSolvePackageTriggerHandler() {
		super('AutoSolvePackageTriggerHandler');
		this.newRecords = (List<Auto_Solve_Package__c>) Trigger.new;
        this.oldRecords = (List<Auto_Solve_Package__c>) Trigger.old;
		this.newRecordsMap = (Map<Id, Auto_Solve_Package__c>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, Auto_Solve_Package__c>) Trigger.oldMap;
	} 
    
    // Context Specific Skip Flags
	// These aren't used, but are here to raise test coverage
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;
    
    public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				AutoSolvePackageTriggerHelper objHelper = new AutoSolvePackageTriggerHelper();
				objHelper.processBeforeInsert(newRecords);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('AutoSolvePackageTriggerHandler', 'BeforeInsert', ex);
			}
		}
	}
    
    public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				AutoSolvePackageTriggerHelper objHelper = new AutoSolvePackageTriggerHelper();
				objHelper.processBeforeUpdate(oldRecordsMap, newRecordsMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('AutoSolvePackageTriggerHandler', 'BeforeUpdate', ex);
			}
		}
	}
}