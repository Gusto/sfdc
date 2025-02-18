import { LightningElement, api } from 'lwc';
import chimaAISupportConversation from "@salesforce/apex/ChimaAIPreChatController.chimaAISupportConversation";
import updateAIInteractionTimer from "@salesforce/apex/ChimaAIPreChatController.updateAIInteractionTimer";
import { getFocusedTabInfo } from "lightning/platformWorkspaceApi";
import { reduceErrors } from "c/ldsUtils";

const GREETING_MESSAGE = "Greetings, How can I help?";
const CX_COPILOT = "CX Co-Pilot"
export default class DisplayAiChatContainer extends LightningElement {
    chatMessages = [];
    message_Id = 0;
    isLoading;
    selectedQueueId;
    queueOption;
    inputQuestion;

    connectedCallback(){
        this.addGreetingMessage();
    }

    addGreetingMessage(){
		let greetingChatMessage = {
			sender: true,
			content: GREETING_MESSAGE,
			senderName: CX_COPILOT,
			initialMessage: true,
			messageId: this.message_Id,
		};

		this.chatMessages.push(greetingChatMessage);
	}

    @api
    startNewChat() {
        if (!this.isLoading) {
            this.chatMessages = [];
                
            this.addGreetingMessage();

            if (this.queueOption && this.queueOption.length > 0) {
                this.selectedQueueId = this.queueOption[0].value;
            }

            this.inputQuestion = "";
            this.message_Id = 0;
        }
    }

    handleSubmitPrompt(event){
        this.inputQuestion = event.detail.question;

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

    handleChimaCalloutTimeout(){
        this.intervalId = setInterval(() => {
            let currentTimer = this.chatMessages[this.chatMessages.length - 1].timer - 1;

            if (currentTimer < 0) {
                clearInterval(this.intervalId);
                return;
            }

            this.chatMessages[this.chatMessages.length - 1].timer = currentTimer;
        }, 1000);
    }

    async handleSendMessage(tabInfo) {
        this.autoScroll();
        this.isLoading = true;
        this.message_Id = this.message_Id + 1;
    
        //add user question to chatMessages array
        this.chatMessages = [
            ...this.chatMessages,
            {
                receiver: true,
                content: this.inputQuestion,
                senderName: this.userName,
                timestamp: new Date(),
                messageId: this.message_Id
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
                content: "",
                senderName: "CX Co-Pilot",
                typing: true,
                messageId: this.message_Id,
                timer: 60
            }
        ];
            
        //auto scroll to the Chima GPT typing message
        this.autoScroll();

        this.handleChimaCalloutTimeout();
    
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
                    content: answerResponse.answer,
                    contentURL: answerResponse.answerURL == "Not available" ? null : answerResponse.answerURL,
                    senderName: CX_COPILOT,
                    timestamp: new Date(),
                    messageId: answerResponse.conversation_id,
                    displayRating: true,
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
                    content: "CX Co-Pilot AI is not available at this moment. You can try again or talk with captain.",
                    senderName: "CX Co-Pilot",
                    timestamp: new Date(),
                    messageId: "",
                    displayRating: true,
                    dynamicRating: [],
                    isShowAskToChatWithSupport: true
                }
            ];
    
            // Clear the userQuestion input
            this.isLoading = false;
            //auto scroll to the answer from Chima
            this.autoScroll();
        }
    }

    handleUpdateTimer(interactionId, calloutProcessingTime) {
        updateAIInteractionTimer({
            strAIInteractionId: interactionId,
            intCalloutProcessingTime: calloutProcessingTime
        }) .then((result) => {})
        .catch((error) => {
            this.displayErrorMessage(error);
        });
    }

    displayErrorMessage(error){
        let errorMessages = reduceErrors(error);

        if (Array.isArray(errorMessages)) {
            errorMessages = errorMessages.join();
        }

        this.showToast("Error", errorMessages, "error");
    }

    showToast(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });

        this.dispatchEvent(event);
    }

    handleFeedbackSubmit(event) {
        console.log('handleFeedbackSubmit### ', event.target.dataset.id);
        console.log('handleFeedbackSubmit### ', event.detail);
        this.isLoading = true;

        const conversation_id = event.target.dataset.conversationid;
        
        let ele = this.template.querySelector('[data-conversationid="' + conversation_id + '"]');

        let obj = this.chatMessages.find(chatMessageObj => chatMessageObj.messageId === conversation_id);

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

        const rating_value = event.detail.rating;

        ele.disableRating();

        chimaAISupportFeedback({
            intRating: Number(rating_value),
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
                    this.handleFeedbackUpdateError(conversation_id, ele, response);
                    this.autoScrollEnd(conversation_id);
                }
            })
            .catch((error) => {
                let errorMessages = reduceErrors(error);

                if (Array.isArray(errorMessages)) {
                    errorMessages = errorMessages.join();
                }
                this.isLoading = false;
                this.handleFeedbackUpdateError(conversation_id, ele, errorMessages);
                this.autoScrollEnd(conversation_id);
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

    handleFeedbackUpdateError(conversation_id, ele, errorMessages) {
        for (let chatMessageObj of this.chatMessages) {
            if (chatMessageObj.messageId == conversation_id) {
                chatMessageObj.isShowError = true;
                chatMessageObj.errorMessage = errorMessages;
                if (!chatMessageObj.isShowQueueDropdown) chatMessageObj.isShowAskToChatWithSupport = true;
                break;
            }
        }

        ele.enableRating();
    }
}