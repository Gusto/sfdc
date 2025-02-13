public with sharing class GFTicketQueue implements Queueable{
    
    private List<GF_Ticket__c> GFTickets;
        
    public GFTicketQueue(List<GF_Ticket__c> inputGFTickets){
        GFTickets= inputGFTickets;
    }
    
    public void execute(QueueableContext context) {
        GFTicketTriggerHelper.blnQueue=true;
        if(GFTickets.size() > 0){ 
            update GFTickets;
        }
    }
}