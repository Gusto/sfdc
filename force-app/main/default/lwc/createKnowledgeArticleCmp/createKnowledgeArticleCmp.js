import { LightningElement, api } from 'lwc';
import createKnowledgeArticle from '@salesforce/apex/CreateKnowledgeArticleCmpCtrl.createKnowledgeArticle';

export default class CreateKnowledgeArticleCmp extends LightningElement {
    @api recordId;
    articleContent;
    isShowSpinnner;

    // connectedCallback(){
    //     createKnowledgeArticle({
    //         'caseId': this.caseId
    //     }).then(result=>{
    //         console.log('result### ', result);
    //     }).catch(error=>{

    //     })
    // }

    async connectedCallback() {
        this.isShowSpinnner = true;
        try {
            // Await the creation of the knowledge article using the provided recordId
            let result = await createKnowledgeArticle({
                'caseId': this.recordId
            });

            result = JSON.parse(result);

            this.isShowSpinnner = false;

            // Log the result to the console
            console.log('Knowledge article result:', result);
            console.log('Knowledge article result:', result.ai_summary);
            debugger;
            // Optionally, process the result (e.g., storing the response or setting properties)
            if (result) {
                // Example: You can store the result in a property if needed
                this.articleContent = result.ai_summary; // Example property to hold the summary
                console.log('Knowledge article articleContent:', this.articleContent);

                let aiSummaryEle = this.template.querySelector('[data-id="aisummary"]');
                //aiSummaryEle.innerHTML = this.articleContent;
                aiSummaryEle.innerHTML = '<div class="ai-summary" data-id="aisummary"> <title>Debit Card Troubleshooting Guide</title> <style> body { font-family: Arial, sans-serif; line-height: 1.6; margin: 20px; padding: 20px; border: 1px solid #ddd; border-radius: 5px; background-color: #f9f9f9; } h1 { font-size: 2em; text-align: center; color: #333; } h2 { font-size: 1.5em; color: #555; } h3 { font-size: 1.2em; color: #666; } ul { list-style-type: disc; margin-left: 20px; } p { margin: 10px 0; } </style> <h1><strong>Debit Card Troubleshooting Guide</strong></h1> <p>This article aims to provide you with step-by-step instructions and tips to help you troubleshoot common issues related to your debit card. Whether you\'re looking to unlock, activate, or reorder your card, or if you have questions regarding your card\'s transactions, this guide will assist you.</p> <h2>Step-by-Step Troubleshooting Instructions</h2> <p>When seeking assistance with your debit card, you may be prompted with several options. Here\'s how to resolve common issues:</p> <ol> <li><strong>Unlocking Your Debit Card:</strong> <ul> <li>Choose the \'unlock\' option from the available menu.</li> <li>Follow the prompts to verify your identity.</li> <li>If required, enter any necessary information such as your Social Security Number or account details.</li> <li>Your card should be unlocked shortly after completing verification.</li> </ul> </li> <li><strong>Activating Your Debit Card:</strong> <ul> <li>Select the \'activate\' option.</li> <li>Provide the card number and any additional information requested.</li> <li>Confirmation will be sent via email or SMS once the activation is successful.</li> </ul> </li> <li><strong>Reordering Your Card:</strong> <ul> <li>Choose the \'reorder\' option.</li> <li>Indicate whether your card was lost, stolen, or damaged.</li> <li>Follow the steps for cancellation of your current card.</li> <li>Request a new card and provide any required shipping information.</li> </ul> </li> <li><strong>Setting Up a Virtual Card:</strong> <ul> <li>Select the \'virtual card\' option.</li> <li>Follow the on-screen instructions to create a new virtual card.</li> <li>Ensure you have linked your virtual card to your existing account.</li> </ul> </li> <li><strong>Card Balance or Limits Inquiries:</strong> <ul> <li>Choose the option for \'Card balance or limits.\'</li> <li>Authenticate as needed to access your account information.</li> <li>Review your current balance and any transaction limits displayed.</li> </ul> </li> <li><strong>Transaction Issues:</strong> <ul> <li>Select \'Transaction issue or dispute.\' </li> <li>Provide details about the transaction in question.</li> <li>Follow the instructions to submit a dispute if needed.</li> </ul> </li> <li><strong>ATM or PIN Number Assistance:</strong> <ul> <li>Choose \'ATM or PIN number\' option.</li> <li>Request assistance for ATM-related queries or PIN reset options.</li> <li>Verify your identity as prompted.</li> </ul> </li> <li><strong>Help with Something Else:</strong> <ul> <li>If you need help with other inquiries, select \'Help with something else.\'</li> <li>Describe your issue to the customer service representative.</li> </ul> </li> </ol> <h2>Additional Helpful Information &amp; Tips</h2> <ul> <li>If you\'re unable to resolve the issue through the automated steps, don\'t hesitate to contact customer support directly.</li> <li>Keep your account information and card details handy for quicker assistance.</li> <li>Check your email and phone notifications for any updates related to your card status.</li> </ul> <h2>FAQs</h2> <ul> <li><strong>What if I forget my PIN?</strong><br> Use the PIN recovery option or contact customer service for help.</li> <li><strong>How long does it take to receive a new debit card?</strong><br> Generally, it takes 5-7 business days for delivery upon ordering.</li> </ul> <h2>Conclusion</h2> <p>In summary, by following the outlined steps above, you can quickly troubleshoot common issues related to your debit card. Remember to always keep your personal information secure and reach out to customer support if you encounter any difficulties. Your financial security is our top priority!</p> </div>';
            }
        } catch (error) {
            this.isShowSpinnner = false;
            // Log the error if the promise is rejected
            console.error('Error occurred while fetching the knowledge article:', error);
        }
    }
    
    
}