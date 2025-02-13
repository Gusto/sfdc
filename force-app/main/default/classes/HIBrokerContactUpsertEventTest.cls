/**
 * @description       : To cover the test cases of HIBrokerContactUpsertEvent
 * @author            : Nigam Goyal
 * @last modified on  : 10-11-2024
 * @last modified by  : Nigam Goyal
**/
@isTest
public class HIBrokerContactUpsertEventTest {

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
        list_Accounts.add(objAccount1);
        insert list_Accounts;
    }

    // Test for HIBrokerContactUpsertEvent: processing payloads
    @isTest
    static void testHIBrokerContactUpsertEvent_ProcessPayloads() {
        // Create test payload
        String strpayload1 = '{"broker_agency_uuid": "057ba234-641c-4803-af97-86d2ff92af87", "broker_contact_uuid": "broker_contact_1", "name": {"first_name": "John", "last_name": "Doe"}, "phone": "1234567890", "email": "john.doe@test.com"}';
        String strpayload2 = '{"broker_agency_uuid": "1234a234-641c-4803-af97-43142314124s", "broker_contact_uuid": "broker_contact_2", "name": {"first_name": "Jane", "last_name": "Smith"}, "phone": "0987654321", "email": "jane.smith@test.com"}';
        List<String> listPayloads = new List<String>{strpayload1, strpayload2};

        // Instantiate the class
        HIBrokerContactUpsertEvent objBrokerEvent = new HIBrokerContactUpsertEvent();

        // Call the method to process the payloads
        Test.startTest();
        objBrokerEvent.processPayloads(listPayloads);
        Test.stopTest();

        // Verify list_Contacts were created
        List<Contact> list_Contacts = [SELECT Id, FirstName, LastName, Email, Broker_Contact_ID__c FROM Contact WHERE Broker_Contact_ID__c IN ('broker_contact_1', 'broker_contact_2')];
        System.assertEquals(2, list_Contacts.size(), 'contacts should have been created or updated');
        System.assertEquals('John', list_Contacts[0].FirstName);
        System.assertEquals('Jane', list_Contacts[1].FirstName);
    }

    // Test for HIEventTriggerHandler: processing platform events
    @isTest
    static void testHIEventTriggerHandler_ProcessHIEvents() {
        // Create test HI_Event__e records
        List<HI_Event__e> list_HiEvents = new List<HI_Event__e>{
            new HI_Event__e(BT_Event_Processor__c = 'HIBrokerContactUpsertEvent', Payload__c = '{"broker_agency_uuid": "057ba234-641c-4803-af97-86d2ff92af87", "broker_contact_uuid": "broker_contact_1", "name": {"first_name": "John", "last_name": "Doe"}, "phone": "1234567890", "email": "john.doe@test.com"}'),
            new HI_Event__e(BT_Event_Processor__c = 'HIBrokerContactUpsertEvent', Payload__c = '{"broker_agency_uuid": "1234a234-641c-4803-af97-43142314124s", "broker_contact_uuid": "broker_contact_2", "name": {"first_name": "Jane", "last_name": "Smith"}, "phone": "0987654321", "email": "jane.smith@test.com"}')
        };

        // Simulate event trigger
        Test.startTest();
        HIEventTriggerHandler.processHIEvents(list_HiEvents);
        Test.stopTest();

        // Verify that list_Contacts were created or updated
        List<Contact> list_Contacts = [SELECT Id, FirstName, LastName, Email, Broker_Contact_ID__c FROM Contact WHERE Broker_Contact_ID__c IN ('broker_contact_1', 'broker_contact_2')];
        System.assertEquals(2, list_Contacts.size(), 'Two contacts should have been created or updated');
    }

    // Test for onError logic in PlatformEventAbstract
    @isTest
    static void testOnError() {
        // Setup error payload
        List<String> list_ErrorPayloads = new List<String>{'{"broker_agency_uuid": "invalid_uuid"}'};
        Set<String> set_Ids = new Set<String>{'broker_contact_1'};
        List<String> list_errors = new List<String>{'error on contact 1'};

        // Instantiate the class
        PlatformEventAbstract objPlatformEvent = new HIBrokerContactUpsertEvent();

        // Simulate an error and retryable exception handling
        Test.startTest();
        try {
            Exception objexception = new System.MathException();
            objexception.setMessage('Test Exception');
            objPlatformEvent.onError(objexception, list_ErrorPayloads, set_Ids, 'HIBrokerContactUpsertEvent', list_errors);
        } catch (EventBus.RetryableException e) {
            System.assertEquals('Test Exception', e.getMessage(), 'Retryable exception should have been thrown with the test message.');
        }
        Test.stopTest();

        // Verify that the BT_Retry_Processor__c record was created
        List<BT_Retry_Processor__c> list_RetryProcessors = [SELECT Id, Error__c, UUID__c FROM BT_Retry_Processor__c WHERE UUID__c = 'broker_contact_1'];
        System.assertEquals(1, list_RetryProcessors.size(), 'One retry processor record should have been created.');
    }
}