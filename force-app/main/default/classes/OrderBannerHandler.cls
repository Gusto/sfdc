/**
 * @description  Get Onboarding Steps from Order
 * @author       Tejashwini Nanduri
 * @date         11-5-2024
 * @see          
 **/

public without sharing class OrderBannerHandler {
    
public class BannerVisibilityResult {
        @AuraEnabled public Boolean blnRoleProfileForBanner1;
        @AuraEnabled public Boolean blnRoleProfileForBanner234;
        //@AuraEnabled public Boolean blnNoProfileFound;

        public BannerVisibilityResult(Boolean banner1, Boolean banner234) {
            this.blnRoleProfileForBanner1 = banner1;
            this.blnRoleProfileForBanner234 = banner234;
            //this.blnNoProfileFound = noProfile;
        }
    }

    @AuraEnabled
    public static BannerVisibilityResult checkRoleProfileOfUser(Id userId) {
        Boolean blnRoleProfileForBanner1 = false;
        Boolean blnRoleProfileForBanner234 = false;
        Boolean blnNoProfileFound = false;

        String strUserRole = UserUtils.getUserRoleName(userId);
        String strUserProfile = UserUtils.getProfileName(userId);
        System.debug('User Role: ' + strUserRole);
        System.debug('User Profile: ' + strUserProfile);

        String strRoleValues = '1,2';
        String strProfileValues = '1,2';
        String strRolesForBanners234 = '1,2';
        String strProfilesForBanners234 = '1,2';

        List<String> listRoles = strRoleValues.split(',');
        List<String> listProfiles = strProfileValues.split(',');
        List<String> listRolesBanner = strRolesForBanners234.split(',');
        List<String> listProfilesBanner = strProfilesForBanners234.split(',');

        System.debug('Roles List: ' + listRoles);
        System.debug('Profiles List: ' + listProfiles);
        System.debug('Roles List for Banners 234: ' + listRolesBanner);
        System.debug('Profiles List for Banners 234: ' + listProfilesBanner);

        if (listRoles.contains(strUserRole) || listProfiles.contains(strUserProfile)) {
            blnRoleProfileForBanner1 = true;
            System.debug('blnRoleProfileForBanner1: ' + blnRoleProfileForBanner1);
        }
        if (listRolesBanner.contains(strUserRole) || listProfilesBanner.contains(strUserProfile)) {
            blnRoleProfileForBanner234 = true;
            System.debug('blnRoleProfileForBanner234: ' + blnRoleProfileForBanner234);
        }
        /*if (!blnRoleProfileForBanner1 && !blnRoleProfileForBanner234){
            blnNoProfileFound = true;
            System.debug('blnNoProfileFound: ' + blnNoProfileFound);
        }*/

        return new BannerVisibilityResult(blnRoleProfileForBanner1, blnRoleProfileForBanner234);
    }

    public class QueueResult {
        @AuraEnabled public Boolean blnUsedCapacityMoreThan80;
        @AuraEnabled public Boolean blnNoRepsWithEnoughCapacity;
        @AuraEnabled public Boolean blnPtTeamIsAtCapacity;
        @AuraEnabled public Boolean blnRtmPtTeamHasCapacity;


        public QueueResult(Boolean blnUsedCapacityMoreThan80, Boolean noRepsWithEnoughCapacity , Boolean ptTeamIsAtCapacity, Boolean rtmPtTeamHasCapacity) {
            this.blnUsedCapacityMoreThan80 = blnUsedCapacityMoreThan80;
            this.blnNoRepsWithEnoughCapacity = noRepsWithEnoughCapacity;
            this.blnPtTeamIsAtCapacity = ptTeamIsAtCapacity;
            this.blnRtmPtTeamHasCapacity = rtmPtTeamHasCapacity;
        }
    }

    @AuraEnabled
    public static QueueResult getQueueRecord(Decimal totalTimeCommitment, String orderStatus,  Date firstCheckDate, String closedOwnerDivision) {
        Decimal decUsedCapacityPercentage = 0;
        Boolean blnUsedCapacityMoreThan80 = false;
        Boolean blnNoRepsWithEnoughCapacity = false;
        Boolean blnPtTeamIsAtCapacity = false;
        Boolean blnRtmPtTeamHasCapacity =false;
        Decimal decTotalAvailableCapacity = 0;
        
        if (firstCheckDate != null && closedOwnerDivision != null) {
			system.debug('inside if');
            // Fetching Queue Record based on firstCheckDate
            List<GradientWorks__Queue__c> queueRecords = [
                SELECT Id
                FROM GradientWorks__Queue__c
                WHERE Order_Assignment_Start_Date__c <= :firstCheckDate
                AND Order_Assignment_End_Date__c >= :firstCheckDate
                LIMIT 1
            ];
            
            system.debug('queueRecords'+ queueRecords);

            if (!queueRecords.isEmpty()) {
                Id queueId = queueRecords[0].Id;

                // Team Capacity Record basing on the closed owner division with help of the queue recordId

                List<PT_Order_Team_Capacity__c> listTeamCapacityRecords = [
                    SELECT Available_Capacity__c, Reserve_Available_Capacity__c, Max_Capacity__c, Used_Capacity__c
                    FROM PT_Order_Team_Capacity__c
                    WHERE GradientWorks_Queue__c = :queueId AND Team_Division_Names__c = :closedOwnerDivision
                    LIMIT 1
                ];

                system.debug('teamCapacityRecords' + listTeamCapacityRecords);
                
                // Queue User Records
                List<GradientWorks__QueueUser__c> listGradientWorkQueueUserRecords = [SELECT Id, GradientWorks__Queue__c, GradientWorks__Available_Capacity__c, GradientWorks__User__c FROM GradientWorks__QueueUser__c WHERE GradientWorks__Queue__c =: queueId];
                system.debug('gradientWorkQueueUserRecords' + listGradientWorkQueueUserRecords);

                Set<Id> setUserIds = new Set<Id>();
                for(GradientWorks__QueueUser__c queueUser : listGradientWorkQueueUserRecords){
                    setUserIds.add(queueUser.GradientWorks__User__c);
                }

                system.debug('set' + setUserIds);

                String strUserSkills = '1,2';
                List<String> listSkills = strUserSkills.split(',');
                
                // Getting all User records where Class_Queue__c matches any value in the listSkills
                List<User> listUserRecords = [SELECT Id, Class_Queue__c 
                                              FROM User 
                                              WHERE Id IN :setUserIds 
                                              AND Class_Queue__c IN :listSkills];
                
                System.debug('Filtered User Records: ' + listUserRecords);

                Set<Id> setFilteredUserIds = new Set<Id>();

                // Loop through the filtered user records and add each user Id to the set
                for (User userRecord : listUserRecords) {
                    setFilteredUserIds.add(userRecord.Id);
                }
                System.debug('Set of Filtered User IDs: ' + setFilteredUserIds);

                List<GradientWorks__QueueUser__c> listFilteredGradientWorkQueueUserRecords = [SELECT Id, GradientWorks__Queue__c, GradientWorks__Available_Capacity__c, GradientWorks__User__c FROM GradientWorks__QueueUser__c WHERE GradientWorks__User__c IN: setFilteredUserIds AND GradientWorks__Queue__c =: queueId];
                system.debug('filteredgradientWorkQueueUserRecords' + listFilteredGradientWorkQueueUserRecords);
                
                if (!listTeamCapacityRecords.isEmpty()) {
                    PT_Order_Team_Capacity__c teamCapacity = listTeamCapacityRecords[0];
                    decTotalAvailableCapacity = (teamCapacity.Available_Capacity__c ?? 0) + (teamCapacity.Reserve_Available_Capacity__c ?? 0);
                    
                    //Calculating the PT team used capacity 
                    if (teamCapacity.Max_Capacity__c != 0) {
                        decUsedCapacityPercentage = (teamCapacity.Used_Capacity__c / teamCapacity.Max_Capacity__c) * 100;
                    }
                } 

                System.debug('decTotalAvailableCapacity::'+decTotalAvailableCapacity);
                System.debug('totalTimeCommitment::'+totalTimeCommitment);
                
                if (decUsedCapacityPercentage > 80) {
                    blnUsedCapacityMoreThan80 = true;
                }
                if (decTotalAvailableCapacity > totalTimeCommitment) {
                        Integer intIndividualCapacityCount = 0;
                        Integer filteredIndividualCapacityCount = 0;

                        //Checking all the individual available capacities
                        for (GradientWorks__QueueUser__c gwqUser : listGradientWorkQueueUserRecords) {
                            if (gwqUser.GradientWorks__Available_Capacity__c > totalTimeCommitment) {
                                intIndividualCapacityCount++;
                                system.debug('individualCapacityCount' + intIndividualCapacityCount); 
                            }
                        }
                        system.debug('individualCapacityCount' + intIndividualCapacityCount);
                        blnNoRepsWithEnoughCapacity = (intIndividualCapacityCount == 0);

                        for(GradientWorks__QueueUser__c fileteredQueueUser : listFilteredGradientWorkQueueUserRecords){
                                 if(fileteredQueueUser.GradientWorks__Available_Capacity__c > totalTimeCommitment){
                                    filteredIndividualCapacityCount++;
                                }
                        }
                        system.debug('filteredIndividualCapacityCount' + filteredIndividualCapacityCount);
                        blnRtmPtTeamHasCapacity = (filteredIndividualCapacityCount == 0);
                        
                }else if(decTotalAvailableCapacity < totalTimeCommitment){
                    blnPtTeamIsAtCapacity = true;
                }
                
            }
        }
        System.debug('blnUsedCapacityMoreThan80::'+blnUsedCapacityMoreThan80);
        System.debug('blnNoRepsWithEnoughCapacity::'+blnNoRepsWithEnoughCapacity);
        System.debug('blnRtmPtTeamHasCapacity::'+blnRtmPtTeamHasCapacity);
        System.debug('blnPtTeamIsAtCapacity::'+blnPtTeamIsAtCapacity);

        return new QueueResult(blnUsedCapacityMoreThan80, blnNoRepsWithEnoughCapacity, blnPtTeamIsAtCapacity, blnRtmPtTeamHasCapacity);
    }

    
}