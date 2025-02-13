/**
Created by : Aurobind Ravichandran
Created Date : 3/30/2017
**/
public class FeedItemTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;
	public static boolean skipPartnerPublishing = false;

	public static string dataLoadCreatedById = '';
	public static dateTime dataLoadCreatedDate = null;

	public void OnBeforeInsert(List<FeedItem> feeds) {
		counter++;
		if (feeds.size() == 1) {
			for (FeedItem item : feeds) {
				if (dataLoadCreatedById != '') {
					item.CreatedById = dataLoadCreatedById;
				}
				if (dataLoadCreatedDate != null) {
					item.createdDate = dataLoadCreatedDate;
				}
			}
		}
	}

	public void OnAfterInsert(Map<Id, FeedItem> newFeedMap) {
		counter++;
		if (Label.MissionTransition == 'Live' || Test.isRunningTest()) {
			insertIntoZendeskIntegrationLog(newFeedMap.values());
			Set<Id> caseIdSet = new Set<Id>();
			List<Case> caseToUpdate = new List<Case>();
			for (FeedItem m : newFeedMap.values()) {
				String parentId = m.ParentId;
				if (parentId.IndexOf('500') == 0 && m.Type == 'TextPost') {
					caseIdSet.add(m.ParentId);
				}
			}
			if (caseIdSet.size() > 0) {
				for (Case c : [SELECT Id, Case_Updated__c FROM Case WHERE Id IN :caseIdSet AND IsClosed = FALSE]) {
					c.Case_Updated__c = System.now();
					caseToUpdate.add(c);
				}

				if (caseToUpdate.size() > 0) {
					caseTriggerHelper.skipTrigger = true;
					update caseToUpdate;
				}
			}
		}
		UpdateOrderCommunication(newFeedMap.values());
		/**
		 * Author: Alex
		 * Date: 9/15/2020
		 * Desc: if feed item's parent is a chat transcript, copy and paste it on Case
		 */
		List<FeedItem> list_ChatPosts = new List<FeedItem>();
		List<Id> list_ChatIds = new List<Id>();
		Map<Id, Id> map_ChatToCase = new Map<Id, Id>();

		for (FeedItem f : newFeedMap.values()) {
			String strParentId = String.valueOf(f.ParentId);
			if (strParentId.startsWith('570')) {
				list_ChatPosts.add(f);
				list_ChatIds.add(f.ParentId);
			}
		}
		List<LiveChatTranscript> list_Chats = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id IN :list_ChatIds];
		for (LiveChatTranscript chat : list_Chats) {
			map_ChatToCase.put(chat.Id, chat.CaseId);
		}
		List<FeedItem> list_PostsToCopy = new List<FeedItem>();

		for (FeedItem f : list_ChatPosts) {
			FeedItem newPost = new FeedItem(
				ParentId = map_ChatToCase.get(f.ParentId),
				Body = f.Body,
				LinkUrl = f.LinkUrl,
				LastEditById = f.LastEditById,
				LastEditDate = f.LastEditDate,
				RelatedRecordId = f.RelatedRecordId,
				Status = f.Status,
				Title = f.Title,
				Type = f.Type,
				Visibility = f.Visibility,
				IsRichText = f.IsRichText
			);

			list_PostsToCopy.add(newPost);
		}
		if (!list_PostsToCopy.isEmpty()) {
			insert list_PostsToCopy;
		}
	}

	public void OnBeforeUpdate(Map<ID, FeedItem> oldFeedMap, Map<ID, FeedItem> newFeedMap) {
		counter++;
	}

	public void OnAfterUpdate(Map<ID, FeedItem> oldFeedMap, Map<ID, FeedItem> newFeedMap) {
		counter++;
		insertIntoZendeskIntegrationLog(newFeedMap.values());
		UpdateOrderCommunication(newFeedMap.values());
	}

	public void OnBeforeDelete(FeedItem[] feedToDelete, Map<ID, FeedItem> oldFeedMap) {
		counter++;
	}

	public void OnAfterDelete(FeedItem[] deletedFeeds, Map<ID, FeedItem> oldFeedMap) {
		counter++;
	}

	public void OnUndelete(FeedItem[] restoredFeeds) {
		counter++;
	}

	private void insertIntoZendeskIntegrationLog(List<FeedItem> feedList) {
		List<Zendesk_Integration_Queue__c> queueList = new List<Zendesk_Integration_Queue__c>();
		Set<Id> caseIdSet = new Set<Id>();
		Map<Id, Case> caseIdMap = new Map<Id, Case>();
		for (FeedItem m : feedList) {
			String parentId = m.ParentId;
			if (parentId.IndexOf('500') == 0 && m.Type == 'TextPost') {
				caseIdSet.add(m.ParentId);
			}
		}
		if (caseIdSet.size() > 0) {
			caseIdMap = new Map<Id, Case>([SELECT Id, Shared_With__c, Status, Partner_Record_Id__c FROM Case WHERE Id IN :caseIdSet]);
		}
		for (FeedItem m : feedList) {
			String parentId = m.ParentId;

			if (parentId.IndexOf('500') == 0 && m.Type == 'TextPost') {
				Zendesk_Integration_Queue__c queue = new Zendesk_Integration_Queue__c();
				Case cse = caseIdMap.get(m.ParentId);
				if (cse.Shared_With__c == 'ApIntego' && UserInfo.getName() != 'AP Intego' && skipPartnerPublishing == false) {
					queue.Case_Id__c = m.ParentId;
					queue.Object_Id__c = m.Id;
					queue.Object_Type__c = 'Chatter';
					queue.Zendesk_Instance__c = 'ApIntego';
					queue.Processing_State__c = 'Queued';
					queue.Zendesk_Id__c = cse.Partner_Record_Id__c;

					queueList.add(queue);
				}
			}
		}

		if (queueList.size() > 0) {
			insert queueList;
		}
	}
	//Update Order object Communication required when any order related checklist
	//get post where Order owner and facilitator is tagged
	private static void UpdateOrderCommunication(List<FeedItem> lstFeedItem) {
		//get All parent id if they are checklist
		//get Parent object key Prefix
		Set<Id> setParentId = new Set<Id>();
		Set<Id> setfeedId = new Set<Id>();
		String parentPrefix = getObjectKeyPrefix('Order_Facilitator_Checklist__c');
		for (FeedItem fd : lstFeedItem) {
			if (String.valueof(fd.parentId).IndexOf(parentPrefix) == 0 && fd.Type == 'TextPost') {
				setParentId.add(fd.parentId);
				setfeedId.add(fd.Id);
			}
		}
		if (setParentId != null && setParentId.size() > 0) {
			Map<Id, Order> mapOrder = new Map<Id, Order>();
			mapOrder = GetOrderDetail(setParentId);
			//make a call on feed Item object
			if (mapOrder != null && mapOrder.size() > 0) {
				List<Order> lstUpdateOrder = new List<Order>();
				for (FeedItem fd : lstFeedItem) {
					if (setfeedId.contains(fd.Id)) {
						//get related Order
						Order objOrder = mapOrder.get(fd.parentid);
						if (objOrder != null) {
							String strAdvocateName = objOrder.Order_Owner_Name__c;
							String strFacilitatorName = objOrder.Facilitator_Name__c;
							String feedBody = fd.Body;
							if (String.isNotBlank(feedBody)) {
								//@Neha Dabas, 8th April 2020, Desc: Update Communication Required field based on Facilitator or Advocate
								Boolean blnIsUpdated = false;
								if (String.isNotBlank(strAdvocateName) && feedBody.indexOf('@' + strAdvocateName) > -1) {
									blnIsUpdated = true;
									objOrder.Communication_Required__c = true;
								}
								if (String.isNotBlank(strFacilitatorName) && feedBody.indexOf('@' + strFacilitatorName) > -1) {
									blnIsUpdated = true;
									objOrder.Communication_Required_Fac__c = true;
								}
								if (blnIsUpdated) {
									lstUpdateOrder.add(objOrder);
								}
							}
						}
					}
				}
				if (lstUpdateOrder != null && lstUpdateOrder.size() > 0) {
					OrderTriggerHelper.skipTrigger = true;
					update lstUpdateOrder;
					OrderTriggerHelper.skipTrigger = false;
				}
			}
		}
	}

	public static Map<Id, Order> GetOrderDetail(Set<Id> setParentId) {
		Map<Id, Order> mapOrder = new Map<Id, Order>();
		for (Order ord : [
			SELECT Communication_Required__c, Communication_Required_Fac__c, Id, OwnerId, Order_Owner_Name__c, Facilitator_Name__c, (SELECT Id, Order__c FROM Order_Facilitator_Checklists__r)
			FROM Order
			WHERE Id IN (SELECT Order__c FROM Order_Facilitator_Checklist__c WHERE Id IN :setParentId)
		]) {
			if (ord.Order_Facilitator_Checklists__r != null && ord.Order_Facilitator_Checklists__r.size() > 0) {
				for (Order_Facilitator_Checklist__c fc : ord.Order_Facilitator_Checklists__r) {
					mapOrder.put(fc.Id, ord);
				}
			}
		}
		return mapOrder;
	}

	public static String getObjectKeyPrefix(String objName) {
		Schema.DescribeSObjectResult sObjType = Utils.getSObjectDescribe(objName);
		return (sObjType.getKeyPrefix());
	}
}