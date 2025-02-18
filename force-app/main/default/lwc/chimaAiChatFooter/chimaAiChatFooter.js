import { api, LightningElement } from 'lwc';

export default class ChimaAiChatFooter extends LightningElement {
    @api isLoading;

    userQuestion = '';

    startNewChat(){
        this.dispatchEvent(new CustomEvent("newchat"));
    }

    handleQuestionChange(event) {
		this.userQuestion = event.target.value;
	}

    //handle enter key press
	handleKeyDown(event) {
		if (event.keyCode === 13) {
			// Enter key is pressed

			let userQuestionTrim = this.userQuestion ? this.userQuestion.trim() : '';

			if(!(userQuestionTrim)){
				return;
			}

            this.dispatchEvent(
                new CustomEvent(
                    'promptsubmit',
                    {
                        "detail": {
                            "question": this.userQuestion
                        }
                    }
                )
            )

            this.userQuestion = "";
		}
	}
}