/**
 * @description       : To Handle Associate Broker Contacts to Customer Accounts Insertion, Updation and Deletion Event
 * @author            : Jai Aswani
 * @last modified on  : 27-11-2024
 * @last modified by  : Jai Aswani
 **/
public with sharing class HIBrokerContactRoleUpsertEvent extends PlatformEventAbstract {

    /**
	 * @description Deserialize json body and Upserts and deletes AccountContactRelation record
	 * @author Jai | 07-12-2024
	 * @param list_Payloads
	 **/
	public override void processPayloads(List<String> list_Payloads) {
        Map<String, PayloadBody> map_PayLoadsByBrokerContactId = new Map<String, PayloadBody>();
		try {
			Set<String> set_BrokerageIds = new Set<String>(); 
            Map<String, PayloadBody> map_PayLoadsByCompanyIdContactId = new Map<String, PayloadBody>();
			for (String strPayload : list_Payloads) {
                PayloadBody objPayload = (PayloadBody) JSON.deserialize(strPayload, PayloadBody.class);
                if(String.isNotBlank(objPayload.broker_contact_uuid) && String.isNotBlank(objPayload.broker_contact_uuid)) {
                    map_PayLoadsByBrokerContactId.put(objPayload.broker_contact_uuid, objPayload);
                    map_PayLoadsByCompanyIdContactId.put(objPayload.company_id + objPayload.broker_contact_uuid, objPayload);
                }
			}

            manageAccountContactRelation(map_PayLoadsByBrokerContactId, map_PayLoadsByCompanyIdContactId, list_Payloads);
		} catch (Exception ex) {
            onError(ex, list_Payloads, map_PayLoadsByBrokerContactId.keySet(), HIEventUtil.HI_BROKER_CONTACT_ROLE_UPSERT_EVENT, null);
		}
	}

	private void manageAccountContactRelation(Map<String, PayloadBody> map_PayLoadsByBrokerContactId, Map<String, PayloadBody> map_PayLoadsByCompanyIdContactId, List<String> list_Payloads) {
        List<Contact> list_Contact = [SELECT Id FROM Contact WHERE Broker_Contact_ID__c IN :map_PayLoadsByBrokerContactId.keySet() WITH SYSTEM_MODE];
        if(!list_Contact.isEmpty()) {
            List<AccountContactRelation> list_AccountContactRelations = [SELECT Id, Roles, AccountId, Account.ZP_Company_ID__c, Contact.Broker_Contact_ID__c, ContactId FROM AccountContactRelation WHERE Contact.Broker_Contact_ID__c IN :map_PayLoadsByBrokerContactId.keySet() WITH SYSTEM_MODE];
            Map<String, AccountContactRelation> mapOfAccountContactRelation = new Map<String, AccountContactRelation>(); 
            List<AccountContactRelation> list_upsertAccountContactRelation = new List<AccountContactRelation>();
            List<AccountContactRelation> list_deleteAccountContactRelation = new List<AccountContactRelation>();
            for(AccountContactRelation accountContactRelationRecord : list_AccountContactRelations) {
                mapOfAccountContactRelation.put(accountContactRelationRecord.Account.ZP_Company_ID__c + accountContactRelationRecord.Contact.Broker_Contact_ID__c, accountContactRelationRecord);
            }
            for(PayloadBody payloadRecord: map_PayLoadsByCompanyIdContactId.values()) {
                Boolean blnIsAccountContactRecordFound = mapOfAccountContactRelation.containsKey(payloadRecord.company_id + payloadRecord.broker_contact_uuid);
                AccountContactRelation objAccountContactRecord = mapOfAccountContactRelation.get(payloadRecord.company_id + payloadRecord.broker_contact_uuid);
                if(blnIsAccountContactRecordFound) {
                    if(payloadRecord.roles == null || payloadRecord.roles.isEmpty()) {
                        list_deleteAccountContactRelation.add(objAccountContactRecord);                      
                    }
                    else {
                        List<String> list_accountContactRoles = objAccountContactRecord.Roles != null ? objAccountContactRecord.Roles?.split(';') : new List<String>();
                        Boolean isListSame = payloadRecord.roles.size() > list_accountContactRoles.size() ? compareLists(payloadRecord.roles, list_accountContactRoles) : compareLists(list_accountContactRoles, payloadRecord.roles);

                        if(!isListSame) {
                            objAccountContactRecord.Roles = String.join(payloadRecord.roles,';');
                            list_upsertAccountContactRelation.add(objAccountContactRecord);
                        }
                    }
                }
                else if(!blnIsAccountContactRecordFound && !payloadRecord.roles.isEmpty()) {
                    Account objAccountToLink = new Account(ZP_Company_ID__c = payloadRecord.company_id);
                    Contact objContactToLink = new Contact(Broker_Contact_ID__c = payloadRecord.broker_contact_uuid);
                    list_upsertAccountContactRelation.add( new AccountContactRelation (Account = objAccountToLink, Contact = objContactToLink, Roles = String.join(payloadRecord.roles,';')));
                }
            }
            delete as system list_deleteAccountContactRelation;
            List<Database.UpsertResult> list_UpsertResults = Database.upsert(list_upsertAccountContactRelation, false);
			handleUpsertBTRetry(list_UpsertResults, list_upsertAccountContactRelation, 'Contact.Broker_Contact_ID__c', list_Payloads);
        }
        else {
            throw new HIBrokerContactRoleUpsertEventException('No Contacts found based on broker_contact_uuid');
        }
	}
    /**
	 * @description Compare list values and indicate if they are same or not
	 * @author Jai | 07-12-2024
	 * @param List<String> list1
     * @param List<String> list2
	 **/
    private Boolean compareLists(List<String> list1, List<String> list2) {
        Set<String> set_one = new Set<String>(list1);
        Set<String> set_two = new Set<String>(list2);

        for(String stringValue : set_one){
            if(!set_two.contains(stringValue) ){
                return false;
            }
        }
        return true;
    }

    
	public class PayloadBody {
        public String broker_agency_uuid;
        public String broker_contact_uuid;
        public Name name;
        public List<String> roles;
        public String phone;
        public String user_identifier;
        public String email;
        public String company_id;
    }
    public class Name {
        public String first_name;
        public String last_name;
    }

    public class HIBrokerContactRoleUpsertEventException extends Exception {}
}