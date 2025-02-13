public with sharing class OrderDetailsExtension {
    
    public Order theOrderObj{get;set;}
    
    public OrderDetailsExtension(apexPages.standardController sc) {

        theOrderObj = new Order();
        getOrderInformation(sc.getId());

    }

    private void getOrderInformation(string orderId){
        if(orderId != null){

            list<Order> lst_tempOrder = [select id,Opportunity.Owner.Name,Opportunity.StageName,Opportunity.Description,Opportunity.ZP_Add_Company_Addresses__c, Opportunity.ZP_Add_Employees__c,Opportunity.ZP_Set_Up_State_Taxes__c,
                                        Opportunity.ZP_Set_Up_Federal_Taxes__c, Opportunity.ZP_Set_Up_Bank_Account__c,Opportunity.ZP_Select_a_Payroll_Schedule__c,Opportunity.ZP_Report_Previous_Paystubs__c,
                                        Opportunity.ZP_Add_Signatory__c,Opportunity.ZP_Sign_Company_Forms__c,Opportunity.ZP_Verify_Company_Bank_Account__c,Opportunity.ZP_Enter_Unpaid_Tax_Liabilities__c FROM
                                        Order WHERE Id =: orderId limit 1];
            if(lst_tempOrder.size()>0){
                theOrderObj = lst_tempOrder.get(0);
            }
        }
    }
}