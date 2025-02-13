trigger CarrierOrderLineItemTrigger on Carrier_Order_Line_Item__c (after insert, after update, after delete) {

    if (CarrierOrderLineItemTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) { 
        return;
    }

    new CarrierOrderLineItemTriggerHelper().run();
}