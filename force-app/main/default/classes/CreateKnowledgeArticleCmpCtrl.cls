public class CreateKnowledgeArticleCmpCtrl {
    
    public class ChatRequestWrapper {
        public List<ChatMessage> body;
    }
    
    public class ChatMessage {
        public String role;
        public String content;
    }
    
    @AuraEnabled
    public static String createKnowledgeArticle(Id caseId) {
        String res = '';
        try {
            // Retrieve the latest LiveChatTranscript record related to the given Case ID
            LiveChatTranscript latestTranscript = [SELECT Id, CaseId, Case.CaseNumber, Body FROM LiveChatTranscript WHERE CaseId = :caseId ORDER BY CreatedDate DESC LIMIT 1];
            
            if (latestTranscript == null || String.isEmpty(latestTranscript.Body)) {
                System.debug('No chat transcript found or body is empty');
                return 'No chat transcript found or body is empty';
            }
            
            // Prepare the payload using the wrapper class
            ChatRequestWrapper requestWrapper = new ChatRequestWrapper();
            requestWrapper.body = new List<ChatMessage>();
            
            ChatMessage systemMessage = new ChatMessage();
            systemMessage.role = 'system';
            systemMessage.content = 'Please generate a knowledge article based on the following conversation between an agent and a customer. The article should explain the steps, solutions, or troubleshooting advice provided by the agent, and it should be clear, concise, and easy to understand. Use headings, bullet points, and numbered lists with HTML tags where applicable for easy reference. The article should cover the following: A clear title that summarizes the main topic, An introduction that briefly explains the purpose of the article, Detailed steps or instructions as given by the agent. Any additional helpful information, tips, or FAQs related to the topic. A conclusion or final note summarizing the key takeaway for the customer.';
            requestWrapper.body.add(systemMessage);
            
            ChatMessage userMessage = new ChatMessage();
            userMessage.role = 'user';
            userMessage.content = latestTranscript.Body;
            requestWrapper.body.add(userMessage);
            
            // Convert to JSON
            String payload = JSON.serialize(requestWrapper);
            
            // Perform the HTTP callout
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('http://ai-chat-summary-api.us-w2.cloudhub.io/chat-summary'); // Replace with actual endpoint
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(payload);
            
            HttpResponse response = http.send(request);
            System.debug('Callout successful: ' + response.getStatusCode());
            System.debug('Callout successful: ' + response.getBody());
            
            if (response.getStatusCode() == 200) {
                System.debug('Callout successful: ' + response.getBody());
                res = response.getBody();
                
               String articleId = createKnowledgeArticle('', '', '');
            } else {
                System.debug('Callout failed with status code: ' + response.getStatusCode() + ' and body: ' + response.getBody());
            }
          
        } catch (Exception e) {
            createLog('createKnowledgeArticle', caseId, e);
            System.debug('Error in sendLatestChatTranscript: ' + e.getMessage());
        }
        return res;
    }
    
    private static String createKnowledgeArticle(String title, String summary, String content) {
        String articleId = '';
        
        try {
            // Create a new Knowledge Article
           /* Knowledge__kav ka = new Knowledge__kav();
            ka.Title = 'Salesforce CRM';
            ka.UrlName = 'salesforce-crm';
            ka.Summary = 'Salesforce Cloud CRM';
            ka.Language = 'en_US';
            insert ka;
            
            System.debug('Knowledge Article created with ID: ' + ka.Id);
        	articleId = ka.Id;*/
        } catch (Exception e) {
            System.debug('Error creating Knowledge Article: ' + e.getMessage());
        }
        
        return articleId;
    }
    
    private static void createLog(String methodName, Id caseId, Exception thisException){
        String className = CreateKnowledgeArticleCmpCtrl.class.getName();
        ExceptionLogUtil.logException(className, methodName, caseId, thisException);
    }
}