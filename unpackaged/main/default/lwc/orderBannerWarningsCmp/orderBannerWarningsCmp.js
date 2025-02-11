import { LightningElement, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import getQueueRecord from "@salesforce/apex/OrderBannerController.getQueueRecord";
import PT_No_available_capacity from "@salesforce/label/c.PT_No_available_capacity";
import PT_No_Reps_with_enough_Capacity from "@salesforce/label/c.PT_No_Reps_with_enough_Capacity";
import PT_No_Reps_with_the_right_skills_have_capacity from "@salesforce/label/c.PT_No_Reps_with_the_right_skills_have_capacity";
import PT_Team_is_at_capacity from "@salesforce/label/c.PT_Team_is_at_capacity";
import Id from "@salesforce/user/Id";
import checkRoleProfileOfUser from "@salesforce/apex/OrderBannerController.checkRoleProfileOfUser";

const FIELDS = ["Order.Total_Time_Commitment__c", "Order.Id", "Order.Status", "Order.First_Check_Date__c", "Order.Bulk_Migration__c", "Order.Closed_Owner_Division__c"];

export default class OrderBannerWarningsCmp extends LightningElement {
	@api recordId;
	idUser = Id;
	objOrderRecord;

	@api label = {
		PT_No_available_capacity,
		PT_No_Reps_with_enough_Capacity,
		PT_No_Reps_with_the_right_skills_have_capacity,
		PT_Team_is_at_capacity
	};

	blnBannerOne = false;
	blnBannerTwo = false;
	blnBannerThree = false;
	blnBannerFour = false;
	blnDisplayBannerOne = false;
	blnDisplayBannerOthers = false;

	@wire(getRecord, { recordId: "$recordId", fields: FIELDS })
	orderRecord({ error, data }) {
		if (data) {
			this.objOrderRecord = data;
			this.checkConditions();
		} else if (error) {
			console.error("Error fetching Order:", error);
		}
	}

	connectedCallback() {
		checkRoleProfileOfUser({ idUser: this.idUser })
			.then((result) => {
				if (result.blnRoleProfileForBannerOne === true) {
					this.blnDisplayBannerOne = true;
				}
				if (result.blnRoleProfileForBannerOthers === true) {
					this.blnDisplayBannerOthers = true;
				}
			})
			.catch((error) => {
				console.error("Error in checkRoleProfileOfUser:", error);
			});
	}

	checkConditions() {
		const totalTimeCommitment = this.objOrderRecord.fields.Total_Time_Commitment__c.value;
		const recordId = this.objOrderRecord.fields.Id.value;
		const status = this.objOrderRecord.fields.Status.value;
		const firstCheckDate = this.objOrderRecord.fields.First_Check_Date__c.value;
		const closedOwnerDivision = this.objOrderRecord.fields.Closed_Owner_Division__c.value;
		getQueueRecord({ decTotalTimeCommitment: totalTimeCommitment, idOrder: Id, strOrderStatus: status, dtFirstCheckDate: firstCheckDate, strClosedOwnerDivision: closedOwnerDivision })
			.then((result) => {
				if (result.blnUsedCapacityMoreThanLimit === true) {
					this.blnBannerOne = true;
					console.log("Show banner 1::" + this.blnBannerOne);
				}

				if (result.blnNoRepsWithEnoughCapacity === true) {
					this.blnBannerTwo = true;
					console.log("Show banner 2::" + this.blnBannerTwo);
				}

				if (result.blnRtmPtTeamHasCapacity === true) {
					this.blnBannerThree = true;
					console.log("Show banner 3::" + this.blnBannerThree);
				}

				if (result.blnPtTeamIsAtCapacity === true) {
					this.blnBannerFour = true;
					console.log("Show banner 4::" + this.blnBannerFour);
				}
			})
			.catch((error) => {
				console.error("Error in getQueueRecord:", error);
			});
	}
}