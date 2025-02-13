trigger ZPCompanyTaxCodeEINTrigger on ZP_Company_Tax_Code_EIN__c (before insert, before update) {

  ZPCompanyTaxCodeEINTriggerHelper handler = new ZPCompanyTaxCodeEINTriggerHelper(Trigger.isExecuting, Trigger.size);

  if(Trigger.isInsert && Trigger.isBefore){
    handler.OnBeforeInsert(Trigger.new);
  }

  else if(Trigger.isUpdate && Trigger.isBefore){
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.new, Trigger.newMap);
  }
}