/*
 * @name         : OrderBannerController
 * @author       : Debasmita Rawooth
 * @date         : 05-11-2024
 * @description  : Controller for orderBannerWarningCmp
 * @test classes : OrderBannerControllerTest
 */

public without sharing class OrderBannerController {
	public class BannerVisibilityResult {
		@AuraEnabled
		public Boolean blnRoleProfileForBannerOne;
		@AuraEnabled
		public Boolean blnRoleProfileForBannerOthers;

		public BannerVisibilityResult(Boolean blnBannerOne, Boolean blnBannerOthers) {
			this.blnRoleProfileForBannerOne = blnBannerOne;
			this.blnRoleProfileForBannerOthers = blnBannerOthers;
		}
	}

	/*
	 * @author      : Debasmita Rawooth
	 * @description : Check if current user has the correct role or profile to view the banners.
	 */
	@AuraEnabled
	public static BannerVisibilityResult checkRoleProfileOfUser(Id idUser) {
		Boolean blnRoleProfileForBannerOne = false;
		Boolean blnRoleProfileForBannerOthers = false;

		String strUserRole = UserUtils.getUserRoleName(idUser);
		String strUserProfile = UserUtils.getProfileName(idUser);

		List<String> list_RolesForBannerOne = System.Label.PT_Roles_Banner1.split(',');
		List<String> list_ProfilesForBannerOne = System.Label.PT_Profiles_Banner1.split(',');
		List<String> list_RolesForBannerOthers = System.Label.PT_Roles_BannerOther.split(',');
		List<String> list_ProfilesForBannerOthers = System.Label.PT_Profiles_BannerOther.split(',');

		if (list_RolesForBannerOne.contains(strUserRole) || list_ProfilesForBannerOne.contains(strUserProfile)) {
			blnRoleProfileForBannerOne = true;
		}
		if (list_RolesForBannerOthers.contains(strUserRole) || list_ProfilesForBannerOthers.contains(strUserProfile)) {
			blnRoleProfileForBannerOthers = true;
		}

		return new BannerVisibilityResult(blnRoleProfileForBannerOne, blnRoleProfileForBannerOthers);
	}

	/*
	 * @author      : Debasmita Rawooth
	 * @description : Wrapper for sending capacity details
	 */
	public class QueueResult {
		@AuraEnabled
		public Boolean blnUsedCapacityMoreThanLimit;
		@AuraEnabled
		public Boolean blnNoRepsWithEnoughCapacity;
		@AuraEnabled
		public Boolean blnPtTeamIsAtCapacity;
		@AuraEnabled
		public Boolean blnRtmPtTeamHasCapacity;

		public QueueResult(Boolean blnUsedCapacityMoreThanLimit, Boolean blnNoRepsWithEnoughCapacity, Boolean blnPtTeamIsAtCapacity, Boolean blnRtmPtTeamHasCapacity) {
			this.blnUsedCapacityMoreThanLimit = blnUsedCapacityMoreThanLimit;
			this.blnNoRepsWithEnoughCapacity = blnNoRepsWithEnoughCapacity;
			this.blnPtTeamIsAtCapacity = blnPtTeamIsAtCapacity;
			this.blnRtmPtTeamHasCapacity = blnRtmPtTeamHasCapacity;
		}
	}

	/*
	 * @author      : Debasmita Rawooth
	 * @description : Logic to determine banner visibility.
	 */
	@AuraEnabled
	public static QueueResult getQueueRecord(Decimal decTotalTimeCommitment, String strOrderStatus, Date dtFirstCheckDate, String strClosedOwnerDivision) {
		Decimal decUsedCapacityPercentage = 0;
		Boolean blnUsedCapacityMoreThanLimit = false;
		Boolean blnNoRepsWithEnoughCapacity = false;
		Boolean blnPtTeamIsAtCapacity = false;
		Boolean blnRtmPtTeamHasCapacity = false;
		Decimal decTotalAvailableCapacity = 0;

		if (dtFirstCheckDate != null && strClosedOwnerDivision != null) {
			// Fetching Gradient Queue Record based on firstCheckDate
			List<GradientWorks__Queue__c> list_queueRecords = [
				SELECT Id
				FROM GradientWorks__Queue__c
				WHERE Order_Assignment_Start_Date__c <= :dtFirstCheckDate AND Order_Assignment_End_Date__c >= :dtFirstCheckDate
				LIMIT 1
			];

			if (!list_queueRecords.isEmpty()) {
				Id idQueue = list_queueRecords[0].Id;

				// Fetching Team Capacity Record basing on the closed owner division with help of the queue recordId
				List<PT_Order_Team_Capacity__c> list_teamCapacityRecords = [
					SELECT Available_Capacity__c, Reserve_Available_Capacity__c, Max_Capacity__c, Used_Capacity__c
					FROM PT_Order_Team_Capacity__c
					WHERE GradientWorks_Queue__c = :idQueue AND Team_Division_Names__c = :strClosedOwnerDivision
					LIMIT 1
				];

				List<String> list_skills = System.Label.PT_UserSkills.split(',');

				// Fetching all Queue User Records
				List<GradientWorks__QueueUser__c> list_gradientWorkQueueUserRecords = [
					SELECT Id, GradientWorks__Queue__c, GradientWorks__Available_Capacity__c, GradientWorks__User__c, GradientWorks__User__r.Class_Queue__c
					FROM GradientWorks__QueueUser__c
					WHERE GradientWorks__Queue__c = :idQueue
				];

				List<GradientWorks__QueueUser__c> list_filteredGradientWorkQueueUserRecords = new List<GradientWorks__QueueUser__c>();
				for (GradientWorks__QueueUser__c objUserRecord : list_gradientWorkQueueUserRecords) {
					if (list_skills.contains(objUserRecord.GradientWorks__User__r.Class_Queue__c)) {
						list_filteredGradientWorkQueueUserRecords.add(objUserRecord);
					}
				}

				if (!list_teamCapacityRecords.isEmpty()) {
					PT_Order_Team_Capacity__c objTeamCapacity = list_teamCapacityRecords[0];
					if (objTeamCapacity.Available_Capacity__c != null && objTeamCapacity.Reserve_Available_Capacity__c != null) {
						decTotalAvailableCapacity = (objTeamCapacity.Available_Capacity__c + objTeamCapacity.Reserve_Available_Capacity__c);
					}

					//Calculating the PT team used capacity
					if (objTeamCapacity.Max_Capacity__c != 0) {
						decUsedCapacityPercentage = (objTeamCapacity.Used_Capacity__c / objTeamCapacity.Max_Capacity__c) * 100;
					}
				}

				if (decUsedCapacityPercentage > Integer.valueOf(System.Label.PT_Team_Capacity_Percentage)) {
					blnUsedCapacityMoreThanLimit = true;
				}
				if (decTotalAvailableCapacity > decTotalTimeCommitment) {
					Integer intIndividualCapacityCount = 0;
					Integer intFilteredIndividualCapacityCount = 0;

					//Checking all the individual available capacities
					for (GradientWorks__QueueUser__c objGWQUser : list_gradientWorkQueueUserRecords) {
						if (objGWQUser.GradientWorks__Available_Capacity__c > decTotalTimeCommitment) {
							intIndividualCapacityCount++;
						}
					}
					blnNoRepsWithEnoughCapacity = (intIndividualCapacityCount == 0);

					for (GradientWorks__QueueUser__c objFileteredQueueUser : list_filteredGradientWorkQueueUserRecords) {
						if (objFileteredQueueUser.GradientWorks__Available_Capacity__c > decTotalTimeCommitment) {
							intFilteredIndividualCapacityCount++;
						}
					}
					blnRtmPtTeamHasCapacity = (intFilteredIndividualCapacityCount == 0);
				} else if (decTotalAvailableCapacity < decTotalTimeCommitment) {
					blnPtTeamIsAtCapacity = true;
				}
			}
		}

		return new QueueResult(blnUsedCapacityMoreThanLimit, blnNoRepsWithEnoughCapacity, blnPtTeamIsAtCapacity, blnRtmPtTeamHasCapacity);
	}
}