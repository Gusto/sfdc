/*
 * Description : Handler to handle trigger events on Order Facilitator Checklist
 */
public with sharing class OrderFacilitatorChecklistTriggerHelper {
	public static Boolean skipTrigger = false;
	/*
	 * Description : Called on BeforeInsert event
	 */
    public void onBeforeInsert(List<Order_Facilitator_Checklist__c> lstOrderChklst){
    	//set timestamp for blocked and checked chekclists
    	setTimestamps(lstOrderChklst,NULL);
    }
    /*
	 * Description : Called on BeforeUpdate event
	 */
    public void onBeforeUpdate(List<Order_Facilitator_Checklist__c> lstOrderChklst,Map<Id,Order_Facilitator_Checklist__c> oldChkLstValues){
    	//set timestamp for blocked and checked chekclists
    	setTimestamps(lstOrderChklst,oldChkLstValues);
    	
    }
    /*
	 * Description : Set timestamps when Checklist is marked as completed or Blocked and tracks the user who made this change
	 */
    private void setTimestamps(List<Order_Facilitator_Checklist__c> lstOrderChklst,Map<Id,Order_Facilitator_Checklist__c> oldChkLstValues){
    	String userFullName = userInfo.getFirstName()+' '+userInfo.getLastName();
    	Map<Id,String> mapOrderNotification;
    	for(Order_Facilitator_Checklist__c check:lstOrderChklst){
    		Order_Facilitator_Checklist__c oldChk;
    		if(NULL != oldChkLstValues && oldChkLstValues.size() > 0 && oldChkLstValues.containsKey(check.Id)){
    			oldChk = oldChkLstValues.get(check.Id);
    		}	
			//Checklist is marked as blocked
			if(check.Is_Blocked__c && ((oldChk != NULL && !oldChk.Is_Blocked__c) || NULL == oldChk)){
				check.Blocked_Timestamp__c = system.now();
				check.Blocked_Username__c = userFullName;
			}
			
			//Checklist is marked as completed
			if(check.Is_Completed__c && ((oldChk != NULL && !oldChk.Is_Completed__c) || NULL == oldChk)){
				check.Completed_Timestamp__c = system.now();
				check.Completed_Username__c = userFullName;
				
				//For Added Employees and Added Historical Payrolls checklists, call function to update case.Order_Notification__c field
				if('* Added Employees'.equalsIgnoreCase(check.Checklist_Name__c) || '* Added Historical Payrolls + QA\'d'.equalsIgnoreCase(check.Checklist_Name__c)){
						if (NULL == mapOrderNotification) mapOrderNotification = new Map<Id,String>();
						String strNotification = '* Added Employees'.equalsIgnoreCase(check.Checklist_Name__c) ? 'Employees Onboarded' : 'Payroll History';
						mapOrderNotification.put(check.Order__c,strNotification);
					}
				}
    	}
    	
    	if(NULL != mapOrderNotification){
    		Set<Id> setOrderId = mapOrderNotification.keySet();
    		//get orders related to chekclists which satisfy the notification criteria
    		// SJAY - 12/03/2020 - Commented dynamic query and replacing it with a regular SOQL query.
    		//List<Order> lstOrder = Database.Query('SELECT Id,Case__c,Bulk_Migration__c FROM Order WHERE Bulk_Migration__c = null AND Case__c != NULL AND Id IN :setOrderId');
    		List<Order> lstOrder  = [SELECT Id,Case__c,Bulk_Migration__c FROM Order WHERE Bulk_Migration__c = null AND Case__c != NULL AND Id IN :setOrderId];
    		
            if(NULL != lstOrder && lstOrder.size() > 0){
                // SJAY - 12/03/2020 - Commented call to OrderTriggerHelper method and instead calling method  locally. 
    			//OrderTriggerHelper handler = new OrderTriggerHelper();
    			//handler.updateCaseForNotification(lstOrder,mapOrderNotification);
				
                updateCaseForNotification(lstOrder,mapOrderNotification);
    		}
    	}
    }
    
    /*
	* Update Case based on which notification has to be sent out to customer
	* Paramters: lstOrders is list of orders, mapOrderNotification is map with Key as OrderId and value as notification criteria
	*/
    public void updateCaseForNotification(List<Order> lstOrders,Map<Id,String> mapOrderNotification){
        if(NULL != lstOrders && lstOrders.size() > 0 && NULL != mapOrderNotification && mapOrderNotification.size() > 0){
            List<Case> lstCaseToUpdate = new List<Case>();
            
            //Update related case for non Bulk Orders
            for(Order objOrder : lstOrders){
                if(objOrder.Bulk_Migration__c == NULL && mapOrderNotification.containsKey(objOrder.Id)){
                    lstCaseToUpdate.add(new Case(Id = objOrder.Case__c,Order_Notification__c=mapOrderNotification.get(objOrder.Id)));
                }
            }
            
            if(lstCaseToUpdate.size() > 0){
                //skip Case trigger
                CaseTriggerHelper.skipTrigger = true;
                update lstCaseToUpdate;
                CaseTriggerHelper.skipTrigger = false;
            }
        }
    }    
    
}