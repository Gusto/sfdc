/**
 * @description PartnerProgramCompanyData Trigger Handler
 * @author      Ajay Krishna P U
 * @since       2023-04-17
 * @see 		PartnerProgramCompanyTriggerHelperTest
 */
public without sharing class PartnerProgramCompanyDataTriggerHandler extends TriggerHandler {
	private List<Partner_Program_Company_Data__c> list_NewRecords;
	private List<Partner_Program_Company_Data__c> list_OldRecords;
	private Map<Id, Partner_Program_Company_Data__c> map_NewRecords;
	private Map<Id, Partner_Program_Company_Data__c> map_OldRecords;

	public static Boolean blnTestException = false;

	/**
	 * @description Constructor initializes the handler context.
	 */
	public PartnerProgramCompanyDataTriggerHandler() {
		super('PartnerProgramCompanyDataTriggerHandler');
		this.list_NewRecords = (List<Partner_Program_Company_Data__c>) Trigger.new;
		this.list_OldRecords = (List<Partner_Program_Company_Data__c>) Trigger.old;
		this.map_NewRecords = (Map<Id, Partner_Program_Company_Data__c>) Trigger.newMap;
		this.map_OldRecords = (Map<Id, Partner_Program_Company_Data__c>) Trigger.oldMap;
	}

	/**
	 * @description After Insert
	 */
	public override void afterInsert() {
		try {
			PartnerProgramCompanyDataTriggerHelper objHelper = new PartnerProgramCompanyDataTriggerHelper();
			objHelper.processAfterInsert(map_NewRecords);

			checkThrowException();
		} catch (Exception objException) {
			ExceptionLogUtil.logException('PartnerProgramCompanyDataTriggerHandler', 'afterInsert', null, objException);
		}
	}

	/**
	 * @description After Update
	 */
	public override void afterUpdate() {
		try {
			PartnerProgramCompanyDataTriggerHelper objHelper = new PartnerProgramCompanyDataTriggerHelper();
			objHelper.processAfterUpdate(map_OldRecords, map_NewRecords);

			checkThrowException();
		} catch (Exception objException) {
			ExceptionLogUtil.logException('PartnerProgramCompanyDataTriggerHandler', 'afterUpdate', null, objException);
		}
	}

	/**
	 * @description After Delete
	 */
	public override void afterDelete() {
		try {
			PartnerProgramCompanyDataTriggerHelper objHelper = new PartnerProgramCompanyDataTriggerHelper();
			objHelper.processAfterDelete(map_OldRecords);

			checkThrowException();
		} catch (Exception objException) {
			ExceptionLogUtil.logException('PartnerProgramCompanyDataTriggerHandler', 'afterDelete', null, objException);
		}
	}

	/**
	 * @description After Un Delete
	 */
	public override void afterUnDelete() {
		try {
			PartnerProgramCompanyDataTriggerHelper objHelper = new PartnerProgramCompanyDataTriggerHelper();
			objHelper.processAfterUnDelete(map_NewRecords);

			checkThrowException();
		} catch (Exception objException) {
			ExceptionLogUtil.logException('PartnerProgramCompanyDataTriggerHandler', 'afterUnDelete', null, objException);
		}
	}

	/**
	 * @description To Test Exception
	 * Mainly to cover catch block of all operations.
	 * @exception throws exception if blnTestException
	 */
	private void checkThrowException() {
		if (blnTestException) {
			Integer intException = 0 / 0;
		}
	}
}