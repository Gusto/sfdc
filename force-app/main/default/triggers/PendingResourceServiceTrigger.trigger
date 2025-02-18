trigger PendingResourceServiceTrigger on PendingServiceRouting (before insert) {
    for(PendingServiceRouting psr: trigger.new){
        if(psr.IsPreferredUserRequired == false){
            system.debug('***** psr'+psr); 
            psr.IsPreferredUserRequired = true;
        }
    }
}