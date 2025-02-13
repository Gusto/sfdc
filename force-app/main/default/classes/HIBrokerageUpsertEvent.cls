/**
 * @description       : To Handle Brokerage Upsert Event
 * @author            : Nigam Goyal
 * @last modified on  : 07-12-2024
 * @last modified by  : Nigam Goyal
 **/
public with sharing class HIBrokerageUpsertEvent extends PlatformEventAbstract {
	/**
	 * @description Deserialize json body and create Brokrage account record
	 * @author Nigam Goyal | 07-12-2024
	 * @param list_Payloads
	 **/
	public override void processPayloads(List<String> list_Payloads) {
		List<Account> list_Accounts = new List<Account>();
		Set<String> set_Brokerage_IDs = new Set<String>();
		try {
			for (String strPayload : list_Payloads) {
				PayloadBody objPayload = (PayloadBody) JSON.deserialize(strPayload, PayloadBody.class);
				if (!set_Brokerage_IDs.contains(objPayload.id)) {
					set_Brokerage_IDs.add(objPayload.id);
					Account objAccount = new Account();
					objAccount.Name = objPayload.name;
					objAccount.Brokerage_ID__c = objPayload.id;
					objAccount.FEIN__c = objPayload.tax_id;
					objAccount.RecordTypeId = cache.getRecordTypeId('Account', 'Brokerage');
					list_Accounts.add(objAccount);
				}
			}

			List<Database.UpsertResult> list_UpsertResults = Database.upsert(list_Accounts, Account.Brokerage_ID__c, false);
			handleUpsertBTRetry(list_UpsertResults, list_Accounts, 'Brokerage_ID__c', list_Payloads);
		} catch (Exception ex) {
			onError(ex, list_Payloads, set_Brokerage_IDs, HIEventUtil.HI_BROKERAGE_UPSERT_EVENT, null);
		}
	}

	public class PayloadBody {
		public String id;
		public String event_type;
		public String name;
		public String tax_id;
		public String created_at;
	}
}