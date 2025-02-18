import { LightningElement, api } from 'lwc';

export default class ChimaAiFeedbackRating extends LightningElement {
    @api isDisableRating;
    @api defaultRating
    @api defaultFeedback;

    rating = [
        { dynamicId: "None", value: 0 },
        { dynamicId: "CoPilot's response was accurate", value: 1 },
        { dynamicId: "CoPilot linked an incorrect / unrelated article", value: 2 },
        { dynamicId: "CoPilot linked article was correct, but the generated response was wrong", value: 3 },
        { dynamicId: "CoPilot's response and article linked are both correct, but the content in the linked article is incorrect/outdated", value: 4 }
    ];

    connectedCallback(){
        this.handleDefaultRating();
    }

    handleDefaultRating(){
        if(this.defaultRating){
            for(let ratingObj of this.rating){
                if(this.defaultRating == ratingObj.value){
                    ratingObj.selected = true;
                }
            }
        }else{
            this.rating[0].selected = true;
        }
    }

    handleFeedbackSubmit(){
        let feedbackRatingEle = this.template.querySelector('[data-conversationid="rating"]');
        let feedbackEle = this.template.querySelector('[data-conversationid="feedback"]');

        if(feedbackRatingEle && feedbackEle){
            let feedbackRating = feedbackRatingEle.value;
            let feedbackText = feedbackEle.value;

            if (feedbackRating == 0) {
                let errorEle = this.template.querySelector('[data-errorid="' + conversation_id + '"]');
                errorEle.style.display = "block";
    
                return;
            } else {
                let errorEle = this.template.querySelector('[data-errorid="' + conversation_id + '"]');
                errorEle.style.display = "none";
            }

            this.dispatchEvent( 
                new CustomEvent(
                    'feedbacksubmit',
                    {
                        detail: {
                            'rating': feedbackRating,
                            'feedback': feedbackText
                        }
                    }
                )
            );
        }
    }

    @api
    disableRating(){
        let feedbackRatingEle = this.template.querySelector('[data-conversationid="rating"]');
        let feedbackEle = this.template.querySelector('[data-conversationid="feedback"]');
        let submitbtnEle = this.template.querySelector('[data-conversationid="submitbtn"]');

        if(feedbackRatingEle && feedbackEle && submitbtnEle){
            feedbackRatingEle.disabled = true;
            feedbackEle.disabled = true;
            submitbtnEle.style.display = 'none';
        }
    }

    @api
    enableRating(){
        let feedbackRatingEle = this.template.querySelector('[data-conversationid="rating"]');
        let feedbackEle = this.template.querySelector('[data-conversationid="feedback"]');
        let submitbtnEle = this.template.querySelector('[data-conversationid="submitbtn"]');

        if(feedbackRatingEle && feedbackEle && submitbtnEle){
            feedbackRatingEle.disabled = false;
            feedbackEle.disabled = false;
            submitbtnEle.style.display = 'inline-flex';
        }
    }
}