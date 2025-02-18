/**
 * @author Praveen Sethu
 * @since 11/26/2020
 * @author David Schach
 * Trigger Handler class that delegates tasks from ZPBenefitTrigger
 **/
public without sharing class ZPBenefitTriggerHandler extends TriggerHandler {
	private List<ZP_Benefit__c> newRecords;
	private List<ZP_Benefit__c> oldRecords;
	private Map<Id, ZP_Benefit__c> newRecordsMap;
	private Map<Id, ZP_Benefit__c> oldRecordsMap;

	/**
	 * Constructor
	 */
	public ZPBenefitTriggerHandler() {
		super('ZPBenefitTriggerHandler');
		this.newRecords = (List<ZP_Benefit__c>) Trigger.new;
		this.oldRecords = (List<ZP_Benefit__c>) Trigger.old;
		this.newRecordsMap = (Map<Id, ZP_Benefit__c>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, ZP_Benefit__c>) Trigger.oldMap;
	}

	/**
	 * @description Handles Before Insert Context
	 * @author Praveen Sethu
	 */
	public override void beforeInsert() {
		try {
			Map<String, Account> map_CompanyIdToAccount = createCollectionsBefore(newRecords, null);
			for (ZP_Benefit__c objBenefit : newRecords) {
				setAccountInfo(objBenefit, map_CompanyIdToAccount);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ZPBenefitTriggerHandler', 'beforeInsert', null, objException);
		}
	}

	/**
	 * @description Handles Before Update Context
	 * @author Praveen Sethu
	 */
	public override void beforeUpdate() {
		try {
			Map<String, Account> map_CompanyIdToAccount = createCollectionsBefore(newRecords, oldRecordsMap);
			for (ZP_Benefit__c objBenefit : newRecords) {
				setAccountInfo(objBenefit, map_CompanyIdToAccount);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ZPBenefitTriggerHandler', 'beforeUpdate', null, objException);
		}
	}

	/**
	 * @description              Before Context : Create data collections to be used across functions
	 *
	 * @author Praveen Sethu
	 * @param list_NewZPBenefits Trigger.new
	 * @param map_OldZPBenefits  Trigger.oldMap
	 * @return Map of Company ID to Account
	 */
	private Map<String, Account> createCollectionsBefore(List<ZP_Benefit__c> list_NewZPBenefits, Map<Id, ZP_Benefit__c> map_OldZPBenefits) {
		Map<String, Account> map_CompanyIdToAccount = new Map<String, Account>();
		Set<String> set_CompanyIds = new Set<String>();
		// Create data collections
		for (ZP_Benefit__c objBenefit : list_NewZPBenefits) {
			ZP_Benefit__c objOldBenefit = (map_OldZPBenefits != null ? map_OldZPBenefits.get(objBenefit.Id) : null);
			if (String.isNotBlank(objBenefit.Company_Id__c)) {
				set_CompanyIds.add(objBenefit.Company_Id__c);
			}
		}

		if (!set_CompanyIds.isEmpty()) {
			List<Account> list_Accounts = [SELECT Id, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :set_CompanyIds];
			for (Account objAccnt : list_Accounts) {
				map_CompanyIdToAccount.put(objAccnt.ZP_Company_ID__c, objAccnt);
			}
		}
		return map_CompanyIdToAccount;
	}

	/**
	 * @description Set Account__c lookup value on ZP_Benefit__c
	 * @author Praveen Sethu
	 * @param  objBenefit `ZP_Benefit__c` record
	 */
	private void setAccountInfo(ZP_Benefit__c objBenefit, Map<String, Account> map_CompanyIdToAccount) {
		objBenefit.Account__c = map_CompanyIdToAccount.containsKey(objBenefit.Company_Id__c) ? map_CompanyIdToAccount.get(objBenefit.Company_Id__c).Id : null;
	}
}