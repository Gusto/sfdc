public without sharing class IkbSearchController {

    //public List<articleInfo> articleList { get; private set; }
    public String articleDescription { get; private set; }
	public String articleTitle { get; private set; }
    
    public IkbSearchController(){
        
    }
    
    public void initAction(){
        
    }
    
    public List<articleInfo> getArticleList(){
        List<articleInfo> articleInfoList = new List<articleInfo>();
        List<Help__kav> helpKavList = new List<Help__kav>();
        
        	helpKavList = new List<Help__kav>([Select Id,ArticleType,External_Id__c,Status__c, Article_Id__c, Title,Summary,PublishStatus,Description__c from Help__kav where External_Id__c like 'Internal%' ]);
	   
        for(Help__kav helpkav : helpKavList){
            articleInfo article = new articleInfo();
            article.articleId = helpkav.Article_Id__c; 
            article.subject = helpkav.Title; 
            articleInfoList.add(article);
        }
		
		return articleInfoList;
    }
    
    public pageReference viewArticle(){
        String articleId = ApexPages.currentPage().getParameters().get('articleId');
        List<Help__kav> helpKavList = new List<Help__kav>([Select Id,ArticleType,External_Id__c,Status__c, Article_Id__c, Title,Summary,PublishStatus,Description__c from Help__kav where Article_Id__c=:articleId]);
        if(helpKavList.size()>0){
            articleDescription = helpKavList[0].Description__c;
            articleTitle = helpKavList[0].Title;
        }
        return null;
    }
    
    public class articleInfo{ 
        public String articleId { get; private set; }
        public String subject { get; private set; }
    }
    
}