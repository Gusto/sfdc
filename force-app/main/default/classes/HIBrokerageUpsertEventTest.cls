/**
 * @description       : Test class for HIBrokerageUpsertEvent
 * @author            : Nigam Goyal
 * @last modified on  : 07-15-2024
 * @last modified by  : Nigam Goyal
**/
@isTest
public class HIBrokerageUpsertEventTest {
    /**
    * @description test brokrage account creation through HI_Event platform event
    * @author Nigam Goyal | 07-15-2024 
    **/
    @isTest
    static void testCreateBrokerage() {
        String strPayloadJSON = JSON.serialize( new Map<String,Object>{
            'id' => '2b8f462b-b054-4fb9-9ba6-0dad8b35474e',
            'event_type' => 'broker_create',
            'name' => 'Test Brokerage 2',
            'tax_id' => '83-1352484',
            'created_at' => '2021-02-01T13:2300.429-07:00'
        });

        HI_Event__e objHIEvent = new HI_Event__e(
            Payload__c = strPayloadJSON,
            BT_Event_Processor__c = 'HIBrokerageUpsertEvent'
        ); 

        Test.startTest();
        Database.SaveResult objSaveResult = EventBus.publish(objHIEvent);
        Test.stopTest();
       
        System.assert(objSaveResult.isSuccess(), 'Should have published the event');

        List<Account> list_brokerageAccounts = [SELECT Id, Name FROM Account WHERE Name = 'Test Brokerage 2'];
        System.assertEquals(1, list_brokerageAccounts.size(), 'Should have created one Brokerage');
    }

    /**
    * @description test brokrage account creation through multiple HI_Event platform events
    * @author Nigam Goyal | 07-15-2024 
    **/
    @isTest
    static void testCreateBrokerageWithMultipleEvents() {
        String strPayloadJSON1 = JSON.serialize( new Map<String,Object>{
            'id' => '2b8f462b-b054-4fb9-9ba6-0dad8b35474e',
            'event_type' => 'broker_create',
            'name' => 'Test Brokerage 4',
            'tax_id' => '83-1352484',
            'created_at' => '2021-02-01T13:2300.429-07:00'
        });

        String strPayloadJSON2 = JSON.serialize( new Map<String,Object>{
            'id' => '2b8f462b-b054-4fb9-9ba6-0dad8b35474e',
            'event_type' => 'broker_create',
            'name' => 'Test Brokerage 4',
            'tax_id' => '83-1352484',
            'created_at' => '2021-02-01T13:2300.429-07:00'
        });

        HI_Event__e objHIEvent = new HI_Event__e(
            Payload__c = strPayloadJSON1,
            BT_Event_Processor__c = 'HIBrokerageUpsertEvent'
        );

        HI_Event__e objHIEvent2 = new HI_Event__e(
            Payload__c = strPayloadJSON2,
            BT_Event_Processor__c = 'HIBrokerageUpsertEvent'
        );

        List<HI_Event__e> list_HIEvents = new List<HI_Event__e>{objHIEvent, objHIEvent2};
        Test.startTest();
        List<Database.SaveResult> list_SRs = EventBus.publish(list_HIEvents);
        Test.stopTest();
        System.assert(list_SRs[0].isSuccess(), 'Should have published the event');

        List<Account> list_brokerages = [SELECT Id, Name FROM Account WHERE Name = 'Test Brokerage 4'];
        System.assertEquals(1, list_brokerages.size(), 'Should have created one Brokerage');
    }

    /**
    * @description Test Create Brokerage without name field in payload, should throw exception and no account should be created
    * @author Nigam Goyal | 07-15-2024 
    **/
    @isTest
    static void testCreateBrokerageException() {
        String strPayloadJSON = JSON.serialize( new Map<String,Object>{
            'id' => '2b8f462b-b054-4fb9-9ba6-0dad8b35474e',
            'event_type' => 'broker_create',
            'name' => null,
            'tax_id' => '83-1352484',
            'created_at' => '2021-02-01T13:2300.429-07:00'
        });

        HI_Event__e objHIEvent = new HI_Event__e(
            Payload__c = strPayloadJSON,
            BT_Event_Processor__c = 'HIBrokerageUpsertEvent'
        );

        Test.startTest();
        try{
            Database.SaveResult objSaveResult = EventBus.publish(objHIEvent);
        }catch(Exception ex){
            HIBrokerageUpsertEvent objHIBrokerageUpsertEvent = new HIBrokerageUpsertEvent();
            objHIBrokerageUpsertEvent.onError(ex, New List<String>{JSON.serialize(objHIEvent)}, New Set<String>{'2b8f462b-b054-4fb9-9ba6-0dad8b35474e'}, 'HIBrokerageUpsertEvent', New List<String>{'Error creating account'});
        }
        Test.stopTest();
       
        List<Account> list_brokerages = [SELECT Id, Name FROM Account];
        System.assertEquals(0, list_brokerages.size(), 'No account should be created');
    }
}