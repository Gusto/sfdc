/**
 * @description       : To cover the test cases of HIBrokerContactRoleUpsertEvent
 * @author            : Jai Aswani
 * @last modified on  : 26-11-2024
 * @last modified by  : Jai Aswani
**/
@isTest
public class HIBrokerContactRoleUpsertEventTest {

    // Test setup data for HIEvent processing
    @testSetup
    static void setupData() {
        // Create test Accounts for Brokerages
        List<Account> list_Accounts = new List<Account>();
        Account objAccount = new TestDataFactory.AccountBuilder()
        .setName('Brokerage 1')
        .setRecordTypeId(cache.getRecordTypeId('Account', 'Brokerage'))
        .setBillingStreet('Testing Avenue 1')
        .setBillingPostalCode('123456')
        .setPhone('19992344444')
        .setShippingStreet('Testing Avenue 1')
        .setShippingPostalCode('123455')
        .setBrokerageId('057ba234-641c-4803-af97-86d2ff92af87')
        .build();
        objAccount.ZP_Company_ID__c = '234345343453';
        list_Accounts.add(objAccount);

        Account objAccount1 = new TestDataFactory.AccountBuilder()
        .setName('Brokerage 2')
        .setRecordTypeId(cache.getRecordTypeId('Account', 'Brokerage'))
        .setBillingStreet('Testing Avenue 1')
        .setBillingPostalCode('123456')
        .setPhone('19992344444')
        .setShippingStreet('Testing Avenue 1')
        .setShippingPostalCode('123455')
        .setBrokerageId('1234a234-641c-4803-af97-43142314124s')
        .build();
        objAccount1.ZP_Company_ID__c = '34579359343';
        list_Accounts.add(objAccount1);
        insert list_Accounts;
        
        Contact objContact = new TestDataFactory.ContactBuilder()
			.setFirstName('Artoo')
			.setLastName('Detoo')
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setEmail('testuser@abccompany.com')
			.build();
        objContact.Broker_Contact_ID__c = 'broker_contact_1';
		insert objContact;
    }

    // Test for HIBrokerContactRoleUpsertEvent: processing payloads
    @isTest
    static void testHIBrokerContactRoleUpsertEvent_ProcessPayloads() {
        // Create test payload
        String strpayload1 = '{"roles":["Primary Broker Contact","Member-level implementation contact(s)","Group-level implementation contact(s)"],"broker_agency_uuid": "057ba234-641c-4803-af97-86d2ff92af87", "broker_contact_uuid": "broker_contact_1", "name": {"first_name": "John", "last_name": "Doe"}, "phone": "1234567890", "email": "john.doe@test.com", "company_id":"34579359343"}';
        List<String> listPayloads = new List<String>{strpayload1};

        // Instantiate the class
        HIBrokerContactRoleUpsertEvent objBrokerEvent = new HIBrokerContactRoleUpsertEvent();

        // Call the method to process the payloads
        Test.startTest();
        objBrokerEvent.processPayloads(listPayloads);
        Test.stopTest();
        
        List<AccountContactRelation> list_AccountContactRelation = [SELECT Id FROM AccountContactRelation WHERE Contact.Broker_Contact_ID__c = 'broker_contact_1' AND Account.ZP_Company_ID__c = '34579359343'];
        System.assertEquals(1, list_AccountContactRelation.size(), 'New AccountContactRelation creation has been failed');
        
        
        strpayload1 = '{"roles":["Member-level implementation contact(s)","Group-level implementation contact(s)"],"broker_agency_uuid": "057ba234-641c-4803-af97-86d2ff92af87", "broker_contact_uuid": "broker_contact_1", "name": {"first_name": "John", "last_name": "Doe"}, "phone": "1234567890", "email": "john.doe@test.com", "company_id":"34579359343"}';
        listPayloads = new List<String>{strpayload1};

        objBrokerEvent.processPayloads(listPayloads);
       
        
        list_AccountContactRelation = [SELECT Id, Roles FROM AccountContactRelation WHERE Contact.Broker_Contact_ID__c = 'broker_contact_1' AND Account.ZP_Company_ID__c = '34579359343'];
        System.assertEquals(list_AccountContactRelation[0].roles,'Member-level implementation contact(s);Group-level implementation contact(s)', 'Account Contact Relation Roles not updated');
        
        strpayload1 = '{"roles":null,"broker_agency_uuid": "057ba234-641c-4803-af97-86d2ff92af87", "broker_contact_uuid": "broker_contact_1", "name": {"first_name": "John", "last_name": "Doe"}, "phone": "1234567890", "email": "john.doe@test.com", "company_id":"34579359343"}';
        listPayloads = new List<String>{strpayload1};
            
        
        objBrokerEvent.processPayloads(listPayloads);
        
        list_AccountContactRelation = new List<AccountContactRelation>();
        list_AccountContactRelation = [SELECT Id FROM AccountContactRelation WHERE Contact.Broker_Contact_ID__c = 'broker_contact_1' AND Account.ZP_Company_ID__c = '34579359343'];
        
        System.assertEquals(0, list_AccountContactRelation.size(), 'Account Contact relation deletion failed');
        
    }

    // Test for onError logic in PlatformEventAbstract
    @isTest
    static void testOnError() {
        
        String strpayload1 = '{"roles":["Primary Broker Contact","Member-level implementation contact(s)","Group-level implementation contact(s)"],"broker_agency_uuid": "057ba234-641c-4803-af97-86d2ff92af87", "broker_contact_uuid": "broker_contact_3", "name": {"first_name": "John", "last_name": "Doe"}, "phone": "1234567890", "email": "john.doe@test.com", "company_id":"34579359343"}';
        List<String> listPayloads = new List<String>{strpayload1};
            
        // Instantiate the class
        HIBrokerContactRoleUpsertEvent objBrokerEvent = new HIBrokerContactRoleUpsertEvent();

        // Call the method to process the payloads
        Test.startTest();
        objBrokerEvent.processPayloads(listPayloads);
        Test.stopTest();
      
        // Verify that the BT_Retry_Processor__c record was created
        List<BT_Retry_Processor__c> list_RetryProcessors = [SELECT Id, Error__c, UUID__c FROM BT_Retry_Processor__c WHERE UUID__c = 'broker_contact_3'];
        System.assertEquals(1, list_RetryProcessors.size(), 'One retry processor record should have been created.');
    }
}