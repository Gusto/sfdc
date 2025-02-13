import { LightningElement, wire, track } from "lwc";
import chimaBenefitAISupportConversation from "@salesforce/apex/ChimaAIPreChatController.chimaBenefitAISupportConversation";
import { getRecord } from "lightning/uiRecordApi";
import USER_ID from "@salesforce/user/Id"; //this is how you will retreive the USER ID of current in user.
import NAME_FIELD from "@salesforce/schema/User.Name";
import { loadStyle } from "lightning/platformResourceLoader";
import chimaAIStyles from "@salesforce/resourceUrl/chimaAIStyles";
import chimaAISupportFeedback from "@salesforce/apex/ChimaAIPreChatController.chimaAISupportFeedback";
import hasChimaAIBenfitsCoPilot from "@salesforce/customPermission/Chima_AI_Benefits_Co_Pilot";
import { reduceErrors } from "c/ldsUtils";

export default class ChimaAIBenefitCoPilotLWC extends LightningElement {
	@track chatMessages = [
		// Add chat message objects here
	];

	@track userQuestion = "";
	@track isLoading = false;
	@track userName;
	@track inputQuestion = "";
	@track rating = 0;
	@track message_Id = 0;

	chatMessages = [
		...this.chatMessages,
		{
			sender: true,
			receiver: false,
			content: "Greetings, How can I help?",
			contentURL: null,
			senderName: "Benefits Co-Pilot",
			timestamp: null,
			typing: false,
			initialMessage: true,
			messageId: this.message_Id,
			displayRating: false,
			dynamicRating: [
				{ dynamicId: "star5-" + this.message_Id, value: 5, isIcon: true },
				{ dynamicId: "star1-" + this.message_Id, value: 1, isIcon: false },
				{ dynamicId: "star2-" + this.message_Id, value: 2, isIcon: false },
				{ dynamicId: "star3-" + this.message_Id, value: 3, isIcon: false },
				{ dynamicId: "star4-" + this.message_Id, value: 4, isIcon: false }
			]
		}
	];

	isFirstTime = true;
	selectedTopic = "Base Model";
	#handleKeyDown;
	#handleQuestionChange;

	get specificTopicOptions() {
		return [
			{ label: "Base Model", value: "Base Model" },
			{ label: "SOS", value: "SOS" },
			{ label: "Carrier", value: "Carrier" },
			{ label: "SIC", value: "SIC" }
		];
	}

	get isChimaAIBenfitsCoPilotEnabled() {
		return hasChimaAIBenfitsCoPilot;
	}

	get disabled() {
		return this.isLoading;
	}

	@wire(getRecord, {
		recordId: USER_ID,
		fields: [NAME_FIELD]
	})
	wireuser({ error, data }) {
		if (data) {
			this.userName = data.fields.Name.value;
		}
	}

	connectedCallback() {
		loadStyle(this, chimaAIStyles);
	}

	disconnectedCallback() {
		this.handleDisconnectInputListener();
	}

	renderedCallback() {
		if (this.isFirstTime) {
			this.isFirstTime = false;
			this.handleAddInputListener();
		}
	}

	handleAddInputListener() {
		this.#handleKeyDown = this.handleKeyDown.bind(this);
		this.#handleQuestionChange = this.handleQuestionChange.bind(this);

		if (this.isChimaAIBenfitsCoPilotEnabled) {
			this.template.querySelector('[data-id="chatInputId"]').addEventListener("keydown", this.#handleKeyDown);
			this.template.querySelector('[data-id="chatInputId"]').addEventListener("input", this.#handleQuestionChange);
		}
	}

	handleDisconnectInputListener() {
		this.template.querySelector('[data-id="chatInputId"]').removeEventListener("keydown", this.#handleKeyDown);

		this.template.querySelector('[data-id="chatInputId"]').removeEventListener("input", this.#handleQuestionChange);
	}

	handleQuestionChange(event) {
		event.stopPropagation();
		this.userQuestion = event.target.value;
	}

	handleSpecificTopicChange(event) {
		this.selectedTopic = event.detail.value;
	}

	//handle enter key press
	handleKeyDown(event) {
		event.stopPropagation();
		if (event.keyCode === 13) {
			// Enter key is pressed
			this.inputQuestion = this.userQuestion;
			this.userQuestion = "";
			this.handleSendMessage();
		}
	}

	async handleSendMessage() {
		//this.autoScroll();
		this.isLoading = true;
		this.message_Id = this.message_Id + 1;
		//add user question to chatMessages array
		// this.chatMessages = [
		// 	...this.chatMessages,
		// 	{
		// 		sender: false,
		// 		receiver: true,
		// 		content: this.inputQuestion,
		// 		contentURL: null,
		// 		senderName: this.userName,
		// 		timestamp: new Date(),
		// 		typing: false,
		// 		initialMessage: false,
		// 		messageId: this.message_Id,
		// 		displayRating: false,
		// 		dynamicRating: [
		// 			{ dynamicId: "star5-" + this.message_Id, value: 5, isIcon: true },
		// 			{ dynamicId: "star1-" + this.message_Id, value: 1, isIcon: false },
		// 			{ dynamicId: "star2-" + this.message_Id, value: 2, isIcon: false },
		// 			{ dynamicId: "star3-" + this.message_Id, value: 3, isIcon: false },
		// 			{ dynamicId: "star4-" + this.message_Id, value: 4, isIcon: false }
		// 		]
		// 	}
		// ];

		this.chatMessages.push({
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
			dynamicRating: [
				{ dynamicId: "star5-" + this.message_Id, value: 5, isIcon: true },
				{ dynamicId: "star1-" + this.message_Id, value: 1, isIcon: false },
				{ dynamicId: "star2-" + this.message_Id, value: 2, isIcon: false },
				{ dynamicId: "star3-" + this.message_Id, value: 3, isIcon: false },
				{ dynamicId: "star4-" + this.message_Id, value: 4, isIcon: false }
			]
		});

		//auto scroll to the user question
		//this.autoScroll();
		this.message_Id = this.message_Id + 1;
		this.chatMessages.push({
			sender: true,
			receiver: false,
			content: "",
			contentURL: null,
			senderName: "Benefits Co-Pilot",
			timestamp: null,
			typing: true,
			initialMessage: false,
			messageId: this.message_Id,
			displayRating: false,
			dynamicRating: [
				{ dynamicId: "star5-" + this.message_Id, value: 5, isIcon: true },
				{ dynamicId: "star1-" + this.message_Id, value: 1, isIcon: false },
				{ dynamicId: "star2-" + this.message_Id, value: 2, isIcon: false },
				{ dynamicId: "star3-" + this.message_Id, value: 3, isIcon: false },
				{ dynamicId: "star4-" + this.message_Id, value: 4, isIcon: false }
			]
		});
		//auto scroll to the Chima GPT typing message
		this.autoScroll(true);

		// Make the Apex method call to get the answer based on userQuestion
		const answerResponse = await chimaBenefitAISupportConversation({
			objChimaBenefitAIConversation: {
				strInputQuestion: this.inputQuestion,
				model: this.selectedTopic
			}
		});

		console.log("answerResponse### ", answerResponse);

		// Remove the blank message from the chatMessages array
		this.chatMessages.pop();
		// Add the received answer to chatMessages array
		this.message_Id = this.message_Id - 1;

		let supportURLs = [];
		let knowledgeArticleCounter = 1;

		for (let supportURL of [answerResponse.support_url_1, answerResponse.support_url_2, answerResponse.support_url_3]) {
			if (supportURL && supportURL != "Not available") {
				let linkURL = supportURL;

				if (!linkURL.startsWith("http")) {
					linkURL = "https://" + linkURL;
				}

				supportURLs.push({
					linkName: "Knowledge Article " + knowledgeArticleCounter++,
					linkURL: linkURL
				});
			}
		}

		this.chatMessages = [
			...this.chatMessages,
			{
				sender: true,
				receiver: false,
				content: answerResponse.answer,
				contentURLs: supportURLs,
				isContentURLExist: supportURLs.length,
				senderName: "Benefits Co-Pilot",
				timestamp: new Date(),
				typing: false,
				initialMessage: false,
				messageId: answerResponse.conversation_id,
				displayRating: true,
				dynamicRating: [
					{ dynamicId: "star5-" + answerResponse.conversation_id, value: 5, isIcon: true },
					{ dynamicId: "star1-" + answerResponse.conversation_id, value: 1, isIcon: false },
					{ dynamicId: "star2-" + answerResponse.conversation_id, value: 2, isIcon: false },
					{ dynamicId: "star3-" + answerResponse.conversation_id, value: 3, isIcon: false },
					{ dynamicId: "star4-" + answerResponse.conversation_id, value: 4, isIcon: false }
				]
			}
		];

		// Clear the userQuestion input
		this.isLoading = false;
		//auto scroll to the answer from Chima
		this.autoScroll(false);
	}

	autoScroll(isScrollToBottom) {
		setTimeout(() => {
			let containerChoosen = this.template.querySelector(".content");
			if (!isScrollToBottom) {
				let lastItem = containerChoosen.querySelector("li:last-child");
				lastItem.scrollIntoView({ behavior: "smooth" });
			} else {
				containerChoosen.scrollIntoView({ behavior: "smooth", block: "end" });
			}
		}, 200);
	}

	invokeUtilityBarAPI(methodName, methodArgs) {
		return new Promise((resolve, reject) => {
			const apiEvent = new CustomEvent("internalapievent", {
				bubbles: true,
				composed: true,
				cancelable: false,
				detail: {
					category: "utilityBarAPI",
					methodName: methodName,
					methodArgs: methodArgs,
					callback: (err, response) => {
						if (err) {
							return reject(err);
						}
						return resolve(response);
					}
				}
			});

			window.dispatchEvent(apiEvent);
		});
	}

	async setRating(event) {
		this.isLoading = true;

		const conversation_id = event.target.dataset.conversationid;
		const rating_value = event.target.dataset.valueid;
		const dynamicId = event.target.dataset.id;
		this.rating = rating_value;
		const elementType = event.target.dataset.elementtype;

		//Disable selection after rating is submitted.
		for (let i = 1; i <= 5; i++) {
			let disableInput = this.template.querySelector('[data-id="star' + i + "-" + conversation_id + '"]');

			if (disableInput) {
				disableInput.disabled = true;
			}
		}

		//set selected rating color
		if (this.rating) {
			const selectedRatingElement = this.template.querySelector('[data-id="' + dynamicId + '"]');
			if (selectedRatingElement) {
				if (elementType == "icon") {
					selectedRatingElement.classList.add("selected-rating-icon-color");
				} else {
					selectedRatingElement.classList.add("selected-rating-button");
				}
			}
		}

		// const response = await 
		chimaAISupportFeedback({ 
			intRating: Number(this.rating), 
			strQuestionId: conversation_id,
			componentType: "benefits", 
			strFeedback: "", 
			strTranscriptId: "",
			blnIsRetry: false 
		}).then((response) => {
			if (response == "SUCCESS") {
				for (let chatMessageObj of this.chatMessages) {
					if (chatMessageObj.messageId == conversation_id) {
						chatMessageObj.isShowError = false;
						chatMessageObj.errorMessage = "";
						break;
					}
				}
			}else {
				this.handleFeedbackUpdateError(conversation_id, response);
			}

			this.isLoading = false;
		})
		.catch((error) => {
			let errorMessages = reduceErrors(error);

			if (Array.isArray(errorMessages)) {
				errorMessages = errorMessages.join();
			}
			this.isLoading = false;
			this.handleFeedbackUpdateError(conversation_id, errorMessages);
		})
	}

	handleFeedbackUpdateError(conversation_id, errorMessages) {
		for (let chatMessageObj of this.chatMessages) {
			if (chatMessageObj.messageId == conversation_id) {
				chatMessageObj.isShowError = true;
				chatMessageObj.errorMessage = errorMessages;
				break;
			}
		}

		for (let i = 1; i <= 5; i++) {
			let disableInput = this.template.querySelector('[data-id="star' + i + "-" + conversation_id + '"]');

			if (disableInput) {
				disableInput.disabled = false;
			}
		}
	}

	async startNewChat() {
		if (!this.isLoading) {
			this.chatMessages = [
				{
					sender: true,
					receiver: false,
					content: "Greetings, How can I help?",
					contentURL: null,
					senderName: "Benefits Co-Pilot",
					timestamp: null,
					typing: false,
					initialMessage: true,
					messageId: this.message_Id,
					displayRating: false,
					dynamicRating: [
						{ dynamicId: "star1-" + this.message_Id, value: 1 },
						{ dynamicId: "star2-" + this.message_Id, value: 2 },
						{ dynamicId: "star3-" + this.message_Id, value: 3 },
						{ dynamicId: "star4-" + this.message_Id, value: 4 },
						{ dynamicId: "star5-" + this.message_Id, value: 5 }
					]
				}
			];
		}
	}
}