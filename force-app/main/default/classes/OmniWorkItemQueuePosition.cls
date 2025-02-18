public with sharing class OmniWorkItemQueuePosition {
    // controls flow to methods (skill vs queue based) 
    // returns -1 for invalid input  
    public static Integer getNumberOfItemsWaiting(Boolean isSkillBasedRouting, String skillOrQueueApiName){
        Integer itemsInQueue = -1;
        if(isSkillBasedRouting){
            itemsInQueue = OmniWorkItemQueuePosition.getNumberOfItemsWaitingForSkill(skillOrQueueApiName);
        }else{
            itemsInQueue = OmniWorkItemQueuePosition.getNumberOfItemsWaitingForQueue(skillOrQueueApiName);
        }
        return itemsInQueue;
    }

    // controls flow to methods (skill vs queue based) 
    // returns -1 for invalid input 
    public static Integer getQueuePosition(Boolean isSkillBasedRouting, String skillOrQueueApiName, String recordId){
        Integer itemsInQueue = -1;
        if(isSkillBasedRouting){
            itemsInQueue = OmniWorkItemQueuePosition.getQueuePositionForSkill(skillOrQueueApiName, recordId);
        }else{
            itemsInQueue = OmniWorkItemQueuePosition.getQueuePositionForQueue(skillOrQueueApiName, recordId);
        }
        return itemsInQueue;
    }


    public static Integer getNumberOfItemsWaitingForSkill(String skillApiName){
        Integer itemsWaiting = -1;
         List<PendingServiceRouting> pendingServiceRoutingList = OmniWorkItemQueuePosition.getPendingServiceRoutingListBySkill(skillApiName);                    
        if(pendingServiceRoutingList.size() > 0){
            itemsWaiting = pendingServiceRoutingList.size();
        }

        return itemsWaiting;

    }

    public static Integer getQueuePositionForSkill(String skillApiName, String recordId){
        Integer queuePosition = -1;
         List<PendingServiceRouting> pendingServiceRoutingList = OmniWorkItemQueuePosition.getPendingServiceRoutingListBySkill(skillApiName);                    
        if(pendingServiceRoutingList.size() > 0){
            queuePosition = 0;
            for(PendingServiceRouting thisPendingServiceRouting : pendingServiceRoutingList){
                if(thisPendingServiceRouting.WorkItemId == recordId){
                    break;
                }else{
                    queuePosition++;
                }
            }
        }

        return queuePosition;

    }

    // provides a list of pending service routing records sorted by priorty and the created date
    // this can be used to determine the position of a work item that is waiting to be routed to an agent
    private static List<PendingServiceRouting> getPendingServiceRoutingListBySkill(String skillApiName){
               List<Id> skillRequirementIdList = new List<Id>();
    
        // get the skill(s) required to check for availablity
        List<Skill> skillList = [SELECT Id
                                    FROM Skill 
                                    WHERE DeveloperName = :skillApiName
                                    AND IsDeleted = FALSE
                                    ];

        List<SkillRequirement> skillRequirementList = [SELECT RelatedRecordId 
                                                        FROM SkillRequirement
                                                        WHERE SkillId IN :skillList];


        // make a list of related pending service requirement records
        for(SkillRequirement thisSkillRequirement : skillRequirementList){
            skillRequirementIdList.add(thisSkillRequirement.RelatedRecordId);
        }

        List<PendingServiceRouting> pendingServiceRoutingList = [SELECT WorkItemId 
                                                                    FROM PendingServiceRouting 
                                                                    WHERE RoutingType = 'SkillsBased' 
                                                                    AND Id IN :skillRequirementIdList
                                                                    ORDER BY RoutingPriority ASC, CreatedDate ASC ];
        return pendingServiceRoutingList;
    }



    public static Integer getNumberOfItemsWaitingForQueue(String queueApiName){
        Integer itemsInQueue = -1;
        List<PendingServiceRouting> pendingServiceRoutingList = OmniWorkItemQueuePosition.getPendingServiceRoutingListByQueue(queueApiName);
        if(pendingServiceRoutingList.size() > 0){
            itemsInQueue = pendingServiceRoutingList.size();
        }

        return itemsInQueue;
    }

    public static Integer getQueuePositionForQueue(String queueApiName, String recordId){
        Integer queuePosition = -1;
            List<PendingServiceRouting> pendingServiceRoutingList = OmniWorkItemQueuePosition.getPendingServiceRoutingListByQueue(queueApiName);                    
        if(pendingServiceRoutingList.size() > 0){
            queuePosition = 0;
            for(PendingServiceRouting thisPendingServiceRouting : pendingServiceRoutingList){
                if(thisPendingServiceRouting.WorkItemId == recordId){
                    break;
                }else{
                    queuePosition++;
                }
            }
        }

        return queuePosition;
    }

    private static List<PendingServiceRouting> getPendingServiceRoutingListByQueue(String queueApiName){
        Group queueRecord = [SELECT Id 
                                FROM Group
                                WHERE Name = :queueApiName
                                AND Type = 'Queue'
                                LIMIT 1];

        List<PendingServiceRouting> pendingServiceRoutingList = [SELECT WorkItemId, RoutingPriority, CreatedDate
                                                                    FROM PendingServiceRouting 
                                                                    WHERE GroupId = :queueRecord.Id
                                                                    AND RoutingType = 'QueueBased'
                                                                    ORDER BY RoutingPriority ASC, CreatedDate ASC ];
        return pendingServiceRoutingList;
    }
}