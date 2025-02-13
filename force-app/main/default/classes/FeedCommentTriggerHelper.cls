/**
Created by : AKS
Created Date : 10/11/2019
**/
public class FeedCommentTriggerHelper {
    
    public static boolean skipTrigger = false;
    public static integer counter=0; 
    
    public void OnBeforeInsert(List<FeedComment> feeds)
    { 
        counter++;  
    }
    
    public void OnAfterInsert(Map<ID, FeedComment> newFeedMap)
    {
        
        counter++;
        UpdateOrderCommunication(newFeedMap.values());
    }
    
    public void OnBeforeUpdate(Map<ID, FeedComment>  oldFeedMap, Map<ID, FeedComment> newFeedMap)
    {
        counter++;
    }
    
    public void OnAfterUpdate(Map<ID, FeedComment>  oldFeedMap, Map<ID, FeedComment> newFeedMap)
    {
        UpdateOrderCommunication(newFeedMap.values());
    }
    
    public void OnBeforeDelete(FeedComment[] feedToDelete, Map<ID, FeedComment> oldFeedMap){
        counter++;
    }
    
    public void OnAfterDelete(FeedComment[] deletedFeeds, Map<ID, FeedComment> oldFeedMap){
        counter++;
        
    }
    
    public void OnUndelete(FeedComment[] restoredFeeds){
        counter++;
    }

    //Update Order object Communication required when any order related checklist 
    //get post comment where Order owner and facilitator is tagged
    private static void UpdateOrderCommunication(List<FeedComment> lstFeedComment){
        //get All parent id if they are checklist
        //get Parent object key Prefix
        Set<Id> setParentId=new Set<Id>();
        Set<Id> setfeedId=new Set<Id>();
        string parentPrefix=FeedItemTriggerHelper.getObjectKeyPrefix('Order_Facilitator_Checklist__c');
        for(FeedComment fd:lstFeedComment){
            if(string.valueof(fd.parentId).IndexOf(parentPrefix)==0 && fd.CommentType=='TextComment'){
                setParentId.add(fd.parentId);
                setfeedId.add(fd.Id);
            }
        }
        if(setParentId!=null && setParentId.size()>0){
            map<Id,Order> mapOrder=new Map<Id,Order>();
            mapOrder=FeedItemTriggerHelper.GetOrderDetail(setParentId);
            //make a call on feed Item object
            if(mapOrder!=null && mapOrder.size()>0){
                List<Order> lstUpdateOrder=new List<Order>();
                for(FeedComment fd:lstFeedComment){
                    if(setfeedId.contains(fd.Id)){
                        //get related Order 
                        Order objOrder=mapOrder.get(fd.parentid);
                        if(objOrder!=null){
                            string strAdvocateName=objOrder.Order_Owner_Name__c;
                            string strFacilitatorName=objOrder.Facilitator_Name__c;
                            string feedBody=fd.CommentBody;
                            //@Neha Dabas, 8th April 2020, Desc: Update Communication Required field based on Facilitator or Advocate
                            if(String.isNotBlank(feedBody)){
								Boolean blnIsUpdated = false;
								if(String.isNotBlank(strAdvocateName) && feedBody.indexOf('@'+strAdvocateName)>-1){
									blnIsUpdated = true;
									objOrder.Communication_Required__c=true;
								}
								if(String.isNotBlank(strFacilitatorName) && feedBody.indexOf('@'+strFacilitatorName)>-1 ){
									blnIsUpdated = true;
									objOrder.Communication_Required_Fac__c=true;
								}
								if(blnIsUpdated){
									lstUpdateOrder.add(objOrder);
								}
                            }
                        }
                    }
                }
                if(lstUpdateOrder!=null && lstUpdateOrder.size()>0){
                    OrderTriggerHelper.skipTrigger=true;
                    update lstUpdateOrder;
                    OrderTriggerHelper.skipTrigger=false;
                }
            }
        }
        
    }
}