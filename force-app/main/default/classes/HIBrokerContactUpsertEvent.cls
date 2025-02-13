public with sharing class HIBrokerContactUpsertEvent extends PlatformEventAbstract {

	/**
	 * @description Deserialize json body and create Brokrage account record
	 * @author Nigam Goyal | 07-12-2024
	 * @param list_Payloads
	 **/
	public override void processPayloads(List<String> list_Payloads) {
		List<Account> list_Accounts = new List<Account>();
		Set<String> set_brokerContactIds = new Set<String>();
		try {
			Set<String> set_BrokerageIds = new Set<String>();
			for (String strPayload : list_Payloads) {
				PayloadBody objPayload = (PayloadBody) JSON.deserialize(strPayload, PayloadBody.class);
				if(objPayload.broker_agency_uuid != null){
					set_BrokerageIds.add(objPayload.broker_agency_uuid);
				}
                set_brokerContactIds.add(objPayload.broker_contact_uuid);
			}
			Map<String,Id> map_BrokerageIdWithAccountId = getBrokerageIdWithAccountIdMap(set_BrokerageIds);
			List<Contact> list_Contacts = new List<Contact>();
			for (String strPayload : list_Payloads) {
				PayloadBody objPayload = (PayloadBody) JSON.deserialize(strPayload, PayloadBody.class);
				if (!map_BrokerageIdWithAccountId.containsKey(objPayload.broker_agency_uuid)) {
					continue;
				}
				if(objPayload.broker_contact_uuid == null){
					continue;
				}
				Contact objContact = new Contact();
				objContact.Broker_Contact_ID__c = objPayload.broker_contact_uuid;
				objContact.AccountId = map_BrokerageIdWithAccountId.get(objPayload.broker_agency_uuid);
				objContact.FirstName = objPayload.name.first_name;
				objContact.LastName = objPayload.name.last_name;
				objContact.Phone = objPayload.phone;
				objContact.Email = objPayload.email;
                objContact.RecordTypeId = cache.getRecordTypeId('Contact', 'Broker Contact');
				list_Contacts.add(objContact);
			}
			List<Database.UpsertResult> list_UpsertResults = Database.upsert(list_Contacts, Contact.Broker_Contact_ID__c, false);
			handleUpsertBTRetry(list_UpsertResults, list_Contacts, 'Broker_Contact_ID__c', list_Payloads);
		} catch (Exception ex) {
            system.debug('set_brokerContactIds '+set_brokerContactIds);
			onError(ex, list_Payloads, set_brokerContactIds, HIEventUtil.HI_BROKER_CONTACT_UPSERT_EVENT, null);
		}
	}

	private static Map<String,Id> getBrokerageIdWithAccountIdMap(Set<String> set_brokerageIds) {
        Map<String,Id> map_BrokerageIdWithAccountId = new Map<String,Id>();
		for(Account objAccount : [SELECT Id, Brokerage_ID__c FROM Account WHERE Brokerage_ID__c IN :set_brokerageIds]){
			map_BrokerageIdWithAccountId.put(objAccount.Brokerage_ID__c, objAccount.Id);
		}
        return map_BrokerageIdWithAccountId;
    }

	public class PayloadBody {
		 public String broker_agency_uuid;
		 public String broker_contact_uuid;
		 public Name name;
		 public String phone;
		 public String user_identifier;
		 public String email;
	}

	public class Name {
		public String first_name;
		public String last_name;
	}
}