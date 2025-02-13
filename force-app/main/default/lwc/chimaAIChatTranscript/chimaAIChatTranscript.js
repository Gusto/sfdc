import { LightningElement, track, wire, api } from "lwc";
import currentUserId from "@salesforce/user/Id";
import chimaAISupportFeedback from "@salesforce/apex/ChimaAIPreChatController.chimaAISupportFeedback";
import getChimaAIConversationDetails from "@salesforce/apex/ChimaAIPreChatController.getChimaAIConversationDetails";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { reduceErrors } from "c/ldsUtils";

const RATING_OPTIONS = [
	{ dynamicId: "None", value: 0 },
	{ dynamicId: "CoPilot's response was accurate", value: 1 },
	{ dynamicId: "CoPilot linked an incorrect / unrelated article", value: 2 },
	{ dynamicId: "CoPilot linked article was correct, but the generated response was wrong", value: 3 },
	{ dynamicId: "CoPilot's response and article linked are both correct, but the content in the linked article is incorrect/outdated", value: 4 }
];
export default class ChimaAIChatTranscript extends LightningElement {
	@api recordId;

	@track chatMessages = [];
	@track rendered = false;

	message_Id = 0;
	isDisplayChat = false;
	intervalRef;
	isLoading = true;
	isLastInteractionFeedbackGiven;

	@wire(getChimaAIConversationDetails, { strLiveChatTranscriptId: "$recordId" })
	wiredContacts({ error, data }) {
		if (data) {
			if (!data) return;

			this.chatMessages = [];

			for (let resultObj of data) {
				if (resultObj.User_Question__c) {
					this.chatMessages.push({
						sender: false,
						receiver: true,
						content: resultObj.User_Question__c,
						senderName: resultObj.CreatedBy.Name,
						initialMessage: false,
						messageId: resultObj.Interaction_Id__c,
						ratingValue: Number(resultObj.Rating__c),
						feedbackValue: resultObj.Feedback__c,
						advancedSupportFeedbackValue: resultObj.Advanced_Support_Feedback__c,
						advancedSupportRating: resultObj.Advanced_Support_Rating__c ? Number(resultObj.Advanced_Support_Rating__c) : 0,
						isDisplayFeedback: resultObj.Advanced_Support_Rating__c ? true : false
					});
				}

				let ratingOptions = [];
				let advancedSupportRatingOption = [];

				RATING_OPTIONS.forEach((ratingObj) => {
					if (resultObj.Rating__c && resultObj.Rating__c == ratingObj.value) {
						ratingOptions.push({
							dynamicId: ratingObj.dynamicId,
							value: ratingObj.value,
							selected: true
						});
					} else {
						ratingOptions.push({
							dynamicId: ratingObj.dynamicId,
							value: ratingObj.value,
							selected: false
						});
					}

					if (resultObj.Advanced_Support_Rating__c && resultObj.Advanced_Support_Rating__c == ratingObj.value) {
						advancedSupportRatingOption.push({
							dynamicId: ratingObj.dynamicId,
							value: ratingObj.value,
							selected: true
						});
					} else {
						advancedSupportRatingOption.push({
							dynamicId: ratingObj.dynamicId,
							value: ratingObj.value,
							selected: false
						});
					}
				});

				if (resultObj.AI_Response__c) {
					let isShowFeedback = true;

					if(resultObj.AI_Response__c && resultObj.AI_Response__c.includes('CX Co-Pilot is not available at this moment')){
						isShowFeedback = false;
					}

					this.chatMessages.push({
						sender: true,
						receiver: false,
						content: resultObj.AI_Response__c,
						contentURL: resultObj.AI_Response_Article_URL__c == "Not available" ? null : resultObj.AI_Response_Article_URL__c,
						displayRating: isShowFeedback ? true : false,
						dynamicRating: ratingOptions,
						advancedSupportRatingOption: advancedSupportRatingOption,
						senderName: "CX Co-Pilot",
						initialMessage: false,
						messageId: resultObj.Interaction_Id__c,
						isRatingDisable: resultObj.Rating__c ? true : false,
						ratingValue: Number(resultObj.Rating__c),
						isDisplayFeedback: (resultObj.Advanced_Support_Rating__c && isShowFeedback) ? true : false,
						feedbackValue: resultObj.Feedback__c,
						isSubmitted: resultObj.Advanced_Support_Rating__c ? true : false,
						advancedSupportFeedbackValue: resultObj.Advanced_Support_Feedback__c,
						advancedSupportRating: resultObj.Advanced_Support_Rating__c ? Number(resultObj.Advanced_Support_Rating__c) : 0
					});
				}
			}

			if (this.chatMessages && this.chatMessages.length > 0) {
				this.isDisplayChat = true;

				let lastChatTranscript = this.chatMessages[this.chatMessages.length - 1];
				let lastDataInteractionDetail = data[data.length - 1];

				if (
					lastDataInteractionDetail.Chat_Transcript__r 
					&& currentUserId == lastDataInteractionDetail.Chat_Transcript__r.OwnerId
					&& lastDataInteractionDetail.AI_Response__c
					&& !lastDataInteractionDetail.AI_Response__c.includes('CX Co-Pilot is not available at this moment')
				) {
					let ratingVal = lastChatTranscript.advancedSupportRating;

					if (ratingVal) {
						this.isLastInteractionFeedbackGiven = true;
					}

					let isDisableTab = ratingVal ? false : true;

					this.handleTabLockUnlock(isDisableTab);
				} else {
					this.handleTabLockUnlock(false);
				}
			}

			this.isLoading = false;
		} else if (error) {
			this.isLoading = false;
		}
	}

	handleUnlockRecord() {
		let lastTranscript = this.chatMessages[this.chatMessages.length - 1];

		let ratingVal = lastTranscript.advancedSupportRating;
		let isSubmitted = lastTranscript.isSubmitted;
		let blnOverride = true;

		if ((ratingVal && isSubmitted) || blnOverride) {
			this.isLastInteractionFeedbackGiven = true;

			this.handleTabLockUnlock(false);
		} else {
			const event = new ShowToastEvent({
				title: "Error",
				message: "Please rate the last Co-Pilot response",
				variant: "error",
				mode: "dismissable"
			});

			this.dispatchEvent(event);
		}
	}

	async setRating(event) {
		const conversation_id = event.target.dataset.conversationid;
		const rating_value = Number(event.target.value);

		for (let chatMessageobj of this.chatMessages) {
			if (chatMessageobj.messageId == conversation_id) {
				chatMessageobj.advancedSupportRating = rating_value;
				chatMessageobj.isDisplayFeedback = rating_value != 0;
			}
		}
	}

	handleFeedbackChange(event) {
		const conversation_id = event.target.dataset.feedbackid;
		let coversationValue = event.target.value;

		for (let chatMessageObj of this.chatMessages) {
			if (chatMessageObj.messageId == conversation_id) {
				chatMessageObj.advancedSupportFeedbackValue = coversationValue;
				break;
			}
		}
	}

	handleFeedbackSubmit(event) {
		this.isLoading = true;
		const conversation_id = event.target.dataset.feedbacksubmitid;

		for (let chatMessageObj of this.chatMessages) {
			if (chatMessageObj.messageId == conversation_id) {
				if (chatMessageObj.advancedSupportRating != 0) {
					chimaAISupportFeedback({
						intRating: chatMessageObj.advancedSupportRating,
						strQuestionId: conversation_id,
						componentType: "cx",
						strFeedback: chatMessageObj.advancedSupportFeedbackValue,
						strTranscriptId: this.recordId
					})
						.then((response) => {
							if (response == "SUCCESS") {
								chatMessageObj.isSubmitted = true;

								const event = new ShowToastEvent({
									title: "Feedback submitted successfully!",
									message: "",
									variant: "success",
									mode: "dismissable"
								});
								this.dispatchEvent(event);

								let lastTranscript = this.chatMessages[this.chatMessages.length - 1];

								if (conversation_id == lastTranscript.messageId) {
									this.isLastInteractionFeedbackGiven = true;

									this.handleTabLockUnlock(false);
								}
							} else {
								const event = new ShowToastEvent({
									title: "Error",
									message: response,
									variant: "error",
									mode: "dismissable"
								});
								this.dispatchEvent(event);

								// In case of exception - allow user to close the tab
								this.handleTabLockUnlock(false);
							}

							this.isLoading = false;
						})
						.catch((error) => {
							let errorMessages = reduceErrors(error);

							if (Array.isArray(errorMessages)) {
								errorMessages = errorMessages.join();
							}

							this.isLoading = false;

							const event = new ShowToastEvent({
								title: "Error",
								message: errorMessages,
								variant: "error",
								mode: "dismissable"
							});

							this.dispatchEvent(event);

							// In case of exception - allow user to close the tab
							this.handleTabLockUnlock(false);
						});
				}

				break;
			}
		}
	}

	get isChatMessagesLoaded() {
		return this.chatMessages && this.chatMessages.length > 0;
	}

	renderedCallback() {
		if (this.chatMessages && this.chatMessages.length > 0 && !this.rendered) {
			// find the last element of chatMessages
			let lastElement = this.chatMessages[this.chatMessages.length - 1];
			let messageId = lastElement.messageId;
			let lastFeedback = this.template.querySelector('[data-feedbacksubmitid="' + messageId + '"]');
			let lastConversation = this.template.querySelector('[data-conversationid="' + messageId + '"]');
			// take the last submitted feedback if available or take the last conversation
			let containerChoosen = lastFeedback ? lastFeedback : lastConversation;
			if (containerChoosen) {
				this.rendered = true;
				containerChoosen.scrollIntoView({ behavior: "smooth", block: "end" });
			}
		}
	}

	handleTabLockUnlock(isDisabledTab){
		const tabDisableEvent = new CustomEvent("tabdisable", {
			detail: {
				isDisabled: isDisabledTab
			}
		});

		this.dispatchEvent(tabDisableEvent);
	}
}