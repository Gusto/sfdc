public with sharing class OmniAgentAvailability {
    // controls flow to methods (skill vs queue based) We did not include agent based routing since 
    public static Boolean checkAgentAvailability(Boolean isSkillBasedRouting, String skillOrQueueApiName){
        Boolean isAvailable = FALSE;
        if(isSkillBasedRouting){
            isAvailable = OmniAgentAvailability.checkAgentAvailabilityForSkill(skillOrQueueApiName);
        }else{
            isAvailable = OmniAgentAvailability.checkAgentAvailabilityForQueue(skillOrQueueApiName);
        }
        return isAvailable;
    }

    public static Boolean checkAgentAvailabilityForQueue(String queueApiName){
        List<Id> skillUserIdList = new List<Id>();
        Boolean isAgentAvailable = FALSE;
        Group queueRecord = [SELECT Id 
                                FROM Group
                                WHERE Name = :queueApiName
                                AND Type = 'Queue'
                                LIMIT 1];

        List<GroupMember> queueMemberList = [SELECT UserOrGroupId 
                                                FROM GroupMember 
                                                WHERE GroupId = :queueRecord.Id];
            
        for (GroupMember thisQueueMember : queueMemberList) {
                skillUserIdList.add(thisQueueMember.UserOrGroupId);
        }

        List<UserServicePresence> activeUserPresenceList = OmniAgentAvailability.getActiveUserPresence(skillUserIdList);

        if(activeUserPresenceList.size() > 0){
            isAgentAvailable = TRUE;
        }

        return isAgentAvailable;
    }

    public static Boolean checkAgentAvailabilityForSkill(String skillApiName){
        List<Id> skillUserIdList = new List<Id>();
        Boolean isAgentAvailable = FALSE;
        // get the skill(s) required to check for availablity
        List<Skill> skillList = [SELECT Id
                                    FROM Skill 
                                    WHERE DeveloperName = :skillApiName
                                    AND IsDeleted = FALSE
                                    ];


        skillUserIdList.addAll(OmniAgentAvailability.getSkilledUsers(skillList));
        skillUserIdList.addAll(OmniAgentAvailability.getSkilledProfileUsers(skillList));
        
        List<UserServicePresence> activeUserPresenceList = OmniAgentAvailability.getActiveUserPresence(skillUserIdList);

        if(activeUserPresenceList.size() > 0){
            isAgentAvailable = TRUE;
        }

        return isAgentAvailable;

    }

    // given a list of skills fetch a list of users with that skill
    private static list<Id> getSkilledUsers(List<Skill> skillList){
        List<Id> skillUserIdList = new List<Id>();

        List<SkillUser> skilledUserList = [SELECT UserId
                                                FROM SkillUser
                                                WHERE SkillId IN :skillList
                                                AND IsDeleted = FALSE
                                                ];


        for(SkillUser thisSkilledUser : skilledUserList){
            skillUserIdList.add(thisSkilledUser.Id);
        }

        return skillUserIdList;
    }

    // given a list of skills fetch a list of profiles with that skill and then 
    // find a list of active users with that profile
    private static list<Id> getSkilledProfileUsers(List<Skill> skillList){
        List<Id> skillUserIdList = new List<Id>();
        List<Id> skillProfileIdList = new List<Id>();

        List<SkillProfile> skillProfileList = [SELECT ProfileId
                                                    FROM SkillProfile
                                                    WHERE SkillId IN :skillList
                                                    AND IsDeleted = FALSE
                                                ];

        for(SkillProfile thisSkillProfile : skillProfileList){
            skillProfileIdList.add(thisSkillProfile.ProfileId);
        }


        List<User> skilledProfileUserList = [SELECT Id
                                            FROM User
                                            WHERE ProfileId IN :skillProfileIdList
                                            AND IsActive = TRUE
                                            ];

        for(User thisSkilledProfileUser : skilledProfileUserList){
            skillUserIdList.add(thisSkilledProfileUser.Id);
        }

        return skillUserIdList;
    }

    private static List<UserServicePresence> getActiveUserPresence(List<Id> skillUserIdList){

        List<UserServicePresence> userPresenceList = [SELECT UserId, StatusStartDate, StatusEndDate, StatusDuration, ServicePresenceStatusId, ConfiguredCapacity
                                                        FROM UserServicePresence
                                                        WHERE IsAway = FALSE AND IsCurrentState = TRUE
                                                        AND UserId IN :skillUserIdList];

        return userPresenceList;
    }
}