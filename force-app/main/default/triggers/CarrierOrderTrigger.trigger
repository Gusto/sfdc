/**
 * Created by brent.johnson on 1/10/17.
 * 
 * Last Modified BY: PR on Jan/27/2019
 * Commented out the dispatcher calling code
 */

trigger CarrierOrderTrigger on Carrier_Order__c (before insert, after insert, before update, after update, after delete, after undelete) {

    if (CarrierOrderTriggerHelper.skipTrigger ||
            FeatureManagement.checkPermission('Bypass_Triggers')) {
        return;
    }

    new CarrierOrderTriggerHelper().run();
}