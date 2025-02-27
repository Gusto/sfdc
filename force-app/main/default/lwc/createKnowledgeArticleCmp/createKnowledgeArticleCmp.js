import { LightningElement, api } from 'lwc';
import createKnowledgeArticle from '@salesforce/apex/CreateKnowledgeArticleCmpCtrl.createKnowledgeArticle';

export default class CreateKnowledgeArticleCmp extends LightningElement {
    @api recordId;
    articleContent ;

    // connectedCallback(){
    //     createKnowledgeArticle({
    //         'caseId': this.caseId
    //     }).then(result=>{
    //         console.log('result### ', result);
    //     }).catch(error=>{

    //     })
    // }

    async connectedCallback() {
        try {
            // Await the creation of the knowledge article using the provided recordId
            let result = await createKnowledgeArticle({
                'caseId': this.recordId
            });

            result = JSON.parse(result);

            // Log the result to the console
            console.log('Knowledge article result:', result);
            console.log('Knowledge article result:', result.ai_summary);
            debugger;
            // Optionally, process the result (e.g., storing the response or setting properties)
            if (result) {
                // Example: You can store the result in a property if needed
                this.articleContent = result.ai_summary; // Example property to hold the summary
                console.log('Knowledge article articleContent:', this.articleContent);

            }
        } catch (error) {
            // Log the error if the promise is rejected
            console.error('Error occurred while fetching the knowledge article:', error);
        }
    }
    
    
}