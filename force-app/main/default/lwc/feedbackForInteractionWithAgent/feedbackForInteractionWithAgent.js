import { LightningElement } from 'lwc';

const FEEDBACK_RATING = [
    { label: "1", value: "1" },
    { label: "2", value: "2" },
    { label: "3", value: "3" },
    { label: "4", value: "4" },
    { label: "5", value: "5" }
];

export default class FeedbackForInteractionWithAgent extends LightningElement {
    selectedRating;
    feedback;
    options = FEEDBACK_RATING;

    handleCancel(){
        this.dispatchEvent(new CustomEvent("cancel"));
    }

    handleSave(){
        this.dispatchEvent(
            new CustomEvent(
                "save",
                { 
                    "detail": {
                        "rating": this.selectedRating,
                        "feedback": this.feedback
                    }
                } 
            )
        );
    }

    handleRatingInteractionChange(event) {
		this.selectedRating = event.detail.value;
	}

    handleRatingFeedbackChange(event) {
		this.feedback = event.target.value;
	}
}