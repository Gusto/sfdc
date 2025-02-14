import { LightningElement, wire, track, api } from "lwc";
import chimaAISupportConversation from "@salesforce/apex/ChimaAIPreChatController.chimaAISupportConversation";
import displayCoPilot from "@salesforce/apex/ChimaAIPreChatController.displayCoPilot";
import getChatButtonLst from "@salesforce/apex/ChimaAIPreChatController.getChatButtonLst";
import { getRecord } from "lightning/uiRecordApi";
import USER_ID from "@salesforce/user/Id"; //this is how you will retreive the USER ID of current in user.
import NAME_FIELD from "@salesforce/schema/User.Name";
import { loadStyle } from "lightning/platformResourceLoader";
import chimaAIStyles from "@salesforce/resourceUrl/chimaAIStyles";
import chimaAISupportFeedback from "@salesforce/apex/ChimaAIPreChatController.chimaAISupportFeedback";
import createAIInteraction from "@salesforce/apex/ChimaAIPreChatController.createAIInteraction";
import handleUpdateLiveChatTranscriptOnAIInteraction from "@salesforce/apex/ChimaAISupportAuraCtrl.handleUpdateLiveChatTranscriptOnAIInteraction";
import getLiveChatTranscriptDetail from "@salesforce/apex/ChimaAISupportAuraCtrl.getLiveChatTranscriptDetail";
import updateAIInteractionTimer from "@salesforce/apex/ChimaAIPreChatController.updateAIInteractionTimer";
import createErrorLog from "@salesforce/apex/ChimaAIPreChatController.createErrorLog";
import updateAgentFeedback from "@salesforce/apex/ChimaAISupportAuraCtrl.updateAgentFeedback";
import getTodayLiveChatTranscripts from "@salesforce/apex/ChimaAIPreChatController.getTodayLiveChatTranscripts";
import { getFocusedTabInfo } from "lightning/platformWorkspaceApi";
import { reduceErrors } from "c/ldsUtils";

const CHIMA_RATING = [
	{ dynamicId: "None", value: 0 },
	{ dynamicId: "CoPilot's response was accurate", value: 1 },
	{ dynamicId: "CoPilot linked an incorrect / unrelated article", value: 2 },
	{ dynamicId: "CoPilot linked article was correct, but the generated response was wrong", value: 3 },
	{ dynamicId: "CoPilot's response and article linked are both correct, but the content in the linked article is incorrect/outdated", value: 4 }
];

const GREETING_MESSAGE = "Greetings, How can I help?";
const CX_COPILOT = "CX Co-Pilot";
export default class ChimaAISupportLWC extends LightningElement {
	@api recId;

	queueOption = [];

	selectedQueueId = "";

	isShowIframe;

	interactionIds = [];

	isDisplayEndChatFeedback;
	selectedRating;
	feedback;
	agentName;
	liveAgentSessionKey;
	selectedCaseRecId;
	intervalId;
	isShowSpinner = false;
	isShowLoadMoreComments;
	@track previousChatTranscipts = [];

	options = [
		{ label: "1", value: "1" },
		{ label: "2", value: "2" },
		{ label: "3", value: "3" },
		{ label: "4", value: "4" },
		{ label: "5", value: "5" }
	];

	get iframeSRC() {
		return "/apex/ChimaChatInternalWidget?recordId=" + this.selectedCaseRecId;
	}

	get isDisplayQueueDropdown() {
		return this.recId && this.recId.startsWith("500");
	}

	get isNotDisplayQueueDropdown() {
		return !this.recId || (this.recId && !this.recId.startsWith("500"));
	}

	get containerStyle(){
		return (this.isShowIframe || this.isDisplayEndChatFeedback) ? 'height: 72vh;' : 'height: 72vh;overflow-y: auto;';
	}

	handleIframeLoaded() {
		let selectedQueueId = this.selectedQueueId;

		const iframe = this.template.querySelector('[data-id="iframeid"]');
		iframe.contentWindow.postMessage(selectedQueueId, "*");
	}

	hideIframe() {
		this.isShowIframe = false;
	}

	hideChatWindow() {
		const ele = this.template.querySelector('[data-id="chatcontainer"]');
		ele.style.visibility = "hidden";
	}

	displayIframe() {
		this.isShowIframe = true;
	}

	displayChatWindow() {
		const ele = this.template.querySelector('[data-id="chatcontainer"]');
		ele.style.visibility = "visible";
	}

	handleCancel() {
		this.isDisplayEndChatFeedback = false;

		this.startNewChat();
		this.displayChatWindow();
	}

	handleFeedbackSave() {
		this.isShowSpinner = true;

		updateAgentFeedback({
			strChatKey: this.liveAgentSessionKey,
			strFeedback: this.feedback,
			strInteractionRating: this.selectedRating
		})
			.then((result) => {
				this.isDisplayEndChatFeedback = false;

				this.displayChatWindow();
				this.startNewChat();
				this.isShowSpinner = false;
			})
			.catch((error) => {
				this.isDisplayEndChatFeedback = false;
				this.startNewChat();

				let errorMessages = reduceErrors(error);

				if (Array.isArray(errorMessages)) {
					errorMessages = errorMessages.join();
				}

				this.isShowSpinner = false;
			});
	}

	@wire(getChatButtonLst)
	wiredGetChatButtonLst({ error, data }) {
		if (data) {
			for (let chatButtonObj of data) {
				if (chatButtonObj.DeveloperName == "Payroll_Internal" || chatButtonObj.DeveloperName == "Vendor_SME_PRC_Internal") {
					this.queueOption.push({ label: "Payroll", value: chatButtonObj.Id });
					this.selectedQueueId = chatButtonObj.Id;
				} else if (chatButtonObj.DeveloperName == "Benefits_Internal") {
					this.queueOption.push({ label: "Benefits", value: chatButtonObj.Id });
				}
			}
		}
	}

	connectedCallback() {
		loadStyle(this, chimaAIStyles);

		displayCoPilot()
			.then((result) => {
				this.displayCoPilot = result;
				const displayCoPilotEvent = new CustomEvent("displaycopilot", {
					detail: { result }
				});
				// Fire the custom event
				this.dispatchEvent(displayCoPilotEvent);

				this.handleIframeListener();

				if (this.displayCoPilot) {
					this.handleLoadComments();

					getFocusedTabInfo().then((tabInfo) => {
						let caseId = null;
						if (tabInfo && tabInfo.recordId) {
							caseId = tabInfo.recordId.startsWith("500") ? tabInfo.recordId : null;
						}

						let aiInteraction = {
							Page_Source__c: tabInfo && tabInfo.url ? tabInfo.url : window.location.href,
							Case__c: caseId,
							Type__c: "Co-Pilot Load"
						};

						createAIInteraction({
							objInteractionToInsert: aiInteraction
						})
							.then((response) => {})
							.catch((error) => {});
					});
				}
			})
			.catch((error) => {
				this.error = error;
			});
	}

	handleLoadComments(){
		this.isShowSpinner = true;

		let interactionIds = [];
		
		for(let chatMessageObj of this.chatMessages){
			if(chatMessageObj.interactionId){
				interactionIds.push(chatMessageObj.interactionId);
			}
		}

		getTodayLiveChatTranscripts({
			'strInteractionIds': interactionIds
		})
		.then((result) => {
			this.previousChatTranscipts = result;

			if(this.previousChatTranscipts && this.previousChatTranscipts.length > 0){
				this.isShowLoadMoreComments = true;
			}
			this.isShowSpinner = false;
		}).catch((error) => {
			this.isShowSpinner = false;
		})
	}

	@track chatMessages = [
		// Add chat message objects here
	];
	@track userQuestion = "";
	@track isLoading = false;
	@track userName;
	@track inputQuestion = "";
	@track displayCoPilot = false;
	@track rating = 0;
	@track message_Id = 0;

	chatMessages = [
		...this.chatMessages,
		{
			sender: true,
			receiver: false,
			content: "Greetings, How can I help?",
			contentURL: null,
			senderName: "CX Co-Pilot",
			timestamp: null,
			typing: false,
			initialMessage: true,
			messageId: this.message_Id,
			displayRating: false,
			dynamicRating: CHIMA_RATING,
			isShowFeedback: false
		}
	];

	@wire(getRecord, {
		recordId: USER_ID,
		fields: [NAME_FIELD]
	})
	wireuser({ error, data }) {
		if (data) {
			this.userName = data.fields.Name.value;
		}
	}

	handleQuestionChange(event) {
		this.userQuestion = event.target.value;
	}

	handleIframeListener() {
		window.addEventListener(
			"message",
			(event) => {
				if (!event || (event.data.type != "CHAT_ESTABLISHED" && event.data.type != "CHAT_CLOSED" && event.data.type != "CHAT_BACK")) {
					return;
				}

				try {
					if (event.data.type == "CHAT_ESTABLISHED") {
						this.handleUpdateLiveChatTranscriptOnAIInteractionFunction(event.data.liveAgentSessionKey);
					} else if (event.data.type == "CHAT_CLOSED") {
						this.liveAgentSessionKey = event.data.liveAgentSessionKey;
						this.handleGetLiveChatTranscriptDetail(event.data.liveAgentSessionKey);
						this.hideIframe();

						this.feedback = "";
						this.selectedRating = "";

						this.isDisplayEndChatFeedback = true;
					} else if (event.data.type == "CHAT_BACK") {
						this.hideIframe();
						this.displayChatWindow();
					}
				} catch (objException) {
					let errorMessages = reduceErrors(error);

					if (Array.isArray(errorMessages)) {
						errorMessages = errorMessages.join();
					}

					createErrorLog({
						strErrorMessage: errorMessages
					})
						.then((result) => {})
						.catch((error) => {});
				}
			},
			false
		);
	}

	handleGetLiveChatTranscriptDetail(liveAgentSessionKey) {
		getLiveChatTranscriptDetail({
			strChatKey: liveAgentSessionKey
		})
			.then((result) => {
				if (result && result.length > 0) {
					this.agentName = result[0].Owner.Name;
				}
			})
			.catch((error) => {
				let errorMessages = reduceErrors(error);

				if (Array.isArray(errorMessages)) {
					errorMessages = errorMessages.join();
				}
			});
	}

	handleUpdateLiveChatTranscriptOnAIInteractionFunction(liveAgentSessionKey) {
		handleUpdateLiveChatTranscriptOnAIInteraction({
			strChatKey: liveAgentSessionKey,
			lst_AIInteractionDetailIds: this.interactionIds
		})
			.then((result) => {})
			.catch((error) => {
				let errorMessages = reduceErrors(error);

				if (Array.isArray(errorMessages)) {
					errorMessages = errorMessages.join();
				}
			});
	}

	//handle enter key press
	handleKeyDown(event) {
		if (event.keyCode === 13) {
			// Enter key is pressed

			let userQuestionTrim = this.userQuestion ? this.userQuestion.trim() : '';

			if(!(userQuestionTrim)){
				return;
			}

			this.inputQuestion = this.userQuestion;
			this.userQuestion = "";
			let location = window.location.href;
			let isPoppedOut = location && location.includes("popout") ? true : false;

			if (!isPoppedOut) {
				getFocusedTabInfo().then((tabInfo) => {
					this.handleSendMessage(tabInfo);
				});
			} else {
				this.handleSendMessage({ url: location, recordId: null });
			}
		}
	}

	async handleSendMessage(tabInfo) {
		this.autoScroll();
		this.isLoading = true;
		this.message_Id = this.message_Id + 1;

		//add user question to chatMessages array
		this.chatMessages = [
			...this.chatMessages,
			{
				sender: false,
				receiver: true,
				content: this.inputQuestion,
				contentURL: null,
				senderName: this.userName,
				timestamp: new Date(),
				typing: false,
				initialMessage: false,
				messageId: this.message_Id,
				displayRating: false,
				dynamicRating: CHIMA_RATING,
				isShowFeedback: false
			}
		];

		//auto scroll to the user question
		this.autoScroll();
		this.message_Id = this.message_Id + 1;
		//add a blank message to the chatMessages array
		this.chatMessages = [
			...this.chatMessages,
			{
				sender: true,
				receiver: false,
				content: "",
				contentURL: null,
				senderName: "CX Co-Pilot",
				timestamp: null,
				typing: true,
				initialMessage: false,
				messageId: this.message_Id,
				displayRating: false,
				dynamicRating: CHIMA_RATING,
				isShowFeedback: false,
				timer: 60
			}
		];
		//auto scroll to the Chima GPT typing message
		this.autoScroll();

		this.intervalId = setInterval(() => {
			let currentTimer = this.chatMessages[this.chatMessages.length - 1].timer - 1;

			if (currentTimer < 0) {
				clearInterval(this.intervalId);
				return;
			}

			this.chatMessages[this.chatMessages.length - 1].timer = currentTimer;
		}, 1000);

		// Make the Apex method call to get the answer based on userQuestion
		try {
			const answerResponse = await chimaAISupportConversation({ strInputQuestion: this.inputQuestion, strRecordURL: tabInfo.url, strRecordId: tabInfo.recordId });

			clearInterval(this.intervalId);

			let currentTimer = this.chatMessages[this.chatMessages.length - 1].timer;

			if (currentTimer >= 0) {
				this.handleUpdateTimer(answerResponse.strAIInteractionId, 60 - currentTimer);
			}

			// Remove the blank message from the chatMessages array
			this.chatMessages.pop();
			// Add the received answer to chatMessages array
			this.message_Id = this.message_Id - 1;
			this.chatMessages = [
				...this.chatMessages,
				{
					sender: true,
					interactionId: answerResponse.strAIInteractionId,
					receiver: false,
					content: answerResponse.answer,
					contentURL: answerResponse.answerURL == "Not available" ? null : answerResponse.answerURL,
					senderName: "CX Co-Pilot",
					timestamp: new Date(),
					typing: false,
					initialMessage: false,
					messageId: answerResponse.conversation_id,
					displayRating: true,
					dynamicRating: CHIMA_RATING,
					isShowFeedback: false,
					isShowQueueDropdown: false,
					isDisplayRatingDropdown: !answerResponse.blnHasError,
					isShowAskToChatWithSupport: answerResponse.blnHasError,
					timer: currentTimer
				}
			];

			// Clear the userQuestion input
			this.isLoading = false;
			//auto scroll to the answer from Chima
			this.autoScroll();
		} catch {
			// Remove the blank message from the chatMessages array
			this.chatMessages.pop();

			// Add the received answer to chatMessages array
			this.message_Id = this.message_Id - 1;
			this.chatMessages = [
				...this.chatMessages,
				{
					sender: true,
					interactionId: "",
					receiver: false,
					content: "CX Co-Pilot AI is not available at this moment. You can try again or talk with captain.",
					contentURL: false,
					senderName: "CX Co-Pilot",
					timestamp: new Date(),
					typing: false,
					initialMessage: false,
					messageId: "",
					displayRating: true,
					dynamicRating: [],
					isShowFeedback: false,
					isShowQueueDropdown: false,
					isShowAskToChatWithSupport: true
				}
			];

			// Clear the userQuestion input
			this.isLoading = false;
			//auto scroll to the answer from Chima
			this.autoScroll();
		}
	}

	get disabled() {
		return this.isLoading;
	}

	handleUpdateTimer(interactionId, calloutProcessingTime) {
		updateAIInteractionTimer({
			strAIInteractionId: interactionId,
			intCalloutProcessingTime: calloutProcessingTime
		})
			.then((result) => {})
			.catch((error) => {
				let errorMessages = reduceErrors(error);

				if (Array.isArray(errorMessages)) {
					errorMessages = errorMessages.join();
				}

				const event = new ShowToastEvent({
					title: "Error",
					message: errorMessages,
					variant: "error"
				});
				this.dispatchEvent(event);
			});
	}

	autoScroll() {
		setTimeout(() => {
			let containerChoosen = this.template.querySelector(".content");
			let lastItem = containerChoosen.querySelector("li:last-child");
			lastItem.scrollIntoView({ behavior: "smooth" });
		}, 200);
	}

	autoScrollEnd(messageId) {
		setTimeout(() => {
			let containerChoosen = this.template.querySelector('[data-listid="' + messageId + '"]');
			containerChoosen.scrollIntoView({ behavior: "smooth", block: "end" });

			let containerChoosenScroll = this.template.querySelector(".autoscroll");
			let maxScrollTop = containerChoosenScroll.scrollHeight - containerChoosenScroll.clientHeight;
			containerChoosenScroll.scrollTop = Math.min(containerChoosenScroll.scrollTop + 70, maxScrollTop);
		}, 200);
	}

	@api
	startNewChat() {
		if (!this.isLoading) {
			this.chatMessages = [
				{
					sender: true,
					receiver: false,
					content: "Greetings, How can I help?",
					contentURL: null,
					senderName: "CX Co-Pilot",
					timestamp: null,
					typing: false,
					initialMessage: true,
					messageId: this.message_Id,
					displayRating: false,
					dynamicRating: CHIMA_RATING,
					isShowFeedback: false
				}
			];

			if (this.queueOption && this.queueOption.length > 0) {
				this.selectedQueueId = this.queueOption[0].value;
			}

			this.userQuestion = "";
			this.inputQuestion = "";
			this.rating = 0;
			this.message_Id = 0;
			
			this.isPreviousChatLoaded = false;
			
			this.previousChatTranscipts = [];
			this.handleLoadComments();
		}
	}

	isPreviousChatLoaded = false;

	handleAddPreviosuChatTranscripts(){
		if(!this.isPreviousChatLoaded){
			this.isPreviousChatLoaded = true;

			this.chatMessages.unshift({
				isLastChatHistory: true,
				isPreviousInteraction: true 
			});
		}else{
			this.chatMessages.shift();
		}

		let addTranscripts = [];

		let chatLength = this.previousChatTranscipts.length;
		let offset = chatLength < 10 ? 0 : chatLength - 10;

		while(offset < chatLength){
			addTranscripts.unshift(this.previousChatTranscipts[ chatLength - 1]);
			this.previousChatTranscipts.pop();
			chatLength--;
		}
		
		for(let resultObj of addTranscripts){
			let ratingOptions = [];

			CHIMA_RATING.forEach((ratingObj) => {
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
			});
			
			if (resultObj.AI_Response__c) {
				let isShowFeedback = true;

				if(resultObj.AI_Response__c && resultObj.AI_Response__c.includes('CX Co-Pilot is not available at this moment')){
					isShowFeedback = false;
				}

				this.chatMessages.unshift({
					sender: true,
					receiver: false,
					content: resultObj.AI_Response__c,
					contentURL: resultObj.AI_Response_Article_URL__c == "Not available" ? null : resultObj.AI_Response_Article_URL__c,
					displayRating: isShowFeedback,
					isDisplayRatingDropdown: isShowFeedback,
					dynamicRating: ratingOptions,
					senderName: "CX Co-Pilot",
					initialMessage: false,
					messageId: resultObj.Interaction_Id__c,
					isRatingDisable: resultObj.Rating__c ? true : false,
					ratingValue: resultObj.Rating__c ? Number(resultObj.Rating__c) : 0,
					isShowFeedback: true,
					feedbackValue: resultObj.Feedback__c,
					isPreviousInteraction: true,
					timestamp: resultObj.CreatedDate,
					timer: resultObj.Callout_Processing_Time__c ? 60 - resultObj.Callout_Processing_Time__c : '' 
				});
			}
			
			if (resultObj.User_Question__c) {
				this.chatMessages.unshift({
					sender: false,
					receiver: true,
					content: resultObj.User_Question__c,
					contentURL: null,
					displayRating: false,
					isDisplayRatingDropdown: false,
					senderName: this.userName,
					initialMessage: false,
					messageId: resultObj.Interaction_Id__c,
					isRatingDisable: false,
					ratingValue: 0,
					isShowFeedback: false,
					feedbackValue: resultObj.Feedback__c,
					timestamp: '',
					timer: ''
				});
			}
		}

		this.addGreetingMessage(true);

		if(this.previousChatTranscipts.length == 0){
			this.isShowLoadMoreComments = false;
			this.previousChatTranscipts = [];
		}
	}

	addGreetingMessage(isPreviousInteraction){
		let greetingChatMessage = {
			sender: true,
			content: GREETING_MESSAGE,
			senderName: CX_COPILOT,
			initialMessage: true,
			messageId: this.message_Id,
			isPreviousInteraction: isPreviousInteraction
		};

		this.chatMessages.unshift(greetingChatMessage);
	}

	handleFeedbackSubmit(event) {
		this.isLoading = true;

		const conversation_id = event.target.dataset.convbtnid;
		

		let ele = this.template.querySelector('[data-conversationid="' + conversation_id + '"]');

		if (!ele) {
			for (let chatMessageObj of this.chatMessages) {
				if (chatMessageObj.messageId == conversation_id) {
					chatMessageObj.isShowAskToChatWithSupport = true;
					chatMessageObj.isShowError = false;
					chatMessageObj.errorMessage = "";
					return;
				}
			}
		}
		const rating_value = ele.value;

		if (rating_value == 0) {
			let errorEle = this.template.querySelector('[data-errorid="' + conversation_id + '"]');
			errorEle.style.display = "block";

			return;
		} else {
			let errorEle = this.template.querySelector('[data-errorid="' + conversation_id + '"]');
			errorEle.style.display = "none";
		}

		ele.disabled = true;

		this.rating = rating_value;

		let feedbackEle = this.template.querySelector('[data-feedbacktxt="' + conversation_id + '"]');
		feedbackEle.disabled = true;

		let feedbackSubEle = this.template.querySelector('[data-convbtnid="' + conversation_id + '"]');
		feedbackSubEle.style.display = "none";

		chimaAISupportFeedback({
			intRating: Number(this.rating),
			strQuestionId: conversation_id,
			componentType: "cx",
			strFeedback: feedbackEle.value,
			strTranscriptId: ""
		})
			.then((response) => {
				this.isLoading = false;
				if (response == "SUCCESS") {
					for (let chatMessageObj of this.chatMessages) {
						if (chatMessageObj.messageId == conversation_id) {
							chatMessageObj.isShowAskToChatWithSupport = true;
							chatMessageObj.isShowError = false;
							chatMessageObj.errorMessage = "";
							break;
						}
					}

					this.autoScrollEnd(conversation_id);
				} else {
					this.handleFeedbackUpdateError(conversation_id, ele, feedbackEle, feedbackSubEle, response);
					this.autoScrollEnd(conversation_id);
				}
			})
			.catch((error) => {
				let errorMessages = reduceErrors(error);

				if (Array.isArray(errorMessages)) {
					errorMessages = errorMessages.join();
				}
				this.isLoading = false;
				this.handleFeedbackUpdateError(conversation_id, ele, feedbackEle, feedbackSubEle, errorMessages);
				this.autoScrollEnd(conversation_id);
			});
	}

	handleFeedbackUpdateError(conversation_id, ele, feedbackEle, feedbackSubEle, errorMessages) {
		for (let chatMessageObj of this.chatMessages) {
			if (chatMessageObj.messageId == conversation_id) {
				chatMessageObj.isShowError = true;
				chatMessageObj.errorMessage = errorMessages;
				if (!chatMessageObj.isShowQueueDropdown) chatMessageObj.isShowAskToChatWithSupport = true;
				break;
			}
		}

		ele.disabled = false;
		feedbackEle.disabled = false;
		feedbackSubEle.style.display = "inline-flex";
	}

	hanldeNoClick(event) {
		let messageId = event.target.dataset.messageid;

		for (let chatMessageObj of this.chatMessages) {
			if (chatMessageObj.messageId == messageId) {
				chatMessageObj.isShowAskToChatWithSupport = false;
				chatMessageObj.isShowQueueDropdown = false;
				break;
			}
		}
	}

	hanldeYesClick(event) {
		let messageId = event.target.dataset.messageid;

		for (let chatMessageObj of this.chatMessages) {
			if (chatMessageObj.messageId == messageId) {
				chatMessageObj.isShowAskToChatWithSupport = false;
				chatMessageObj.isShowQueueDropdown = true;
				break;
			}
		}
	}

	handleQueueChange(event) {
		this.selectedQueueId = event.target.value;
	}

	handleSubmit() {
		let interactionIds = [];

		for (let chatMessage of this.chatMessages) {
			if (chatMessage.interactionId) {
				interactionIds.push(chatMessage.interactionId);
			}
		}

		this.interactionIds = interactionIds;
		this.selectedCaseRecId = this.recId;

		this.displayIframe();
		this.hideChatWindow();
	}

	handleRatingInteractionChange(event) {
		this.selectedRating = event.detail.value;
	}

	handleRatingFeedbackChange(event) {
		this.feedback = event.target.value;
	}
}