trigger TaxOpsTaskQETrigger on Tax_Ops_Task_QE__c (after delete, after insert, after undelete,
after update, before delete, before insert, before update) {

  TaxOpsTaskQETriggerHelper handler = new TaxOpsTaskQETriggerHelper();

  if(!TaxOpsTaskQETriggerHelper.skipTrigger){
    if(Trigger.isInsert && Trigger.isBefore){
      handler.OnBeforeInsert(Trigger.new);
    }
    else if(Trigger.isInsert && Trigger.isAfter){
      handler.OnAfterInsert(Trigger.new);
    }

    else if(Trigger.isUpdate && Trigger.isBefore){
      handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.newMap);
    }
    else if(Trigger.isUpdate && Trigger.isAfter){
      handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.newMap);
    }

    else if(Trigger.isDelete && Trigger.isBefore){
      handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }
    else if(Trigger.isDelete && Trigger.isAfter){
      handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }

    else if(Trigger.isUnDelete){
      handler.OnUndelete(Trigger.new);
    }  
  }
  
}