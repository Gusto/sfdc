public with sharing class KnowledgeFooterController {    
    
    //public list<articleDetail> articleKnowledgeDetailList{get;set;}
    public string searchStr{get;set;}
    public String primaryCaseId{get;set;}
    public string selectedSortFilter{get;set;}
    public List<String> aticlesTitleList{get; set;}
    boolean isPageLoad;
    
    public ApexPages.StandardSetController articleController{get; set;} 
    
    public KnowledgeFooterController(apexPages.standardController sc){
        selectedSortFilter = 'Title: A to Z';
        isPageLoad = true;        
        getKnowledgeArticle();
    }
    
    public void getKnowledgeArticle(){
        articleKnowledgeDetailList = new list<articleDetail>();
        aticlesTitleList = new list<string>();           
        //populateArticleDetails();
    }
    
    
    public void populateArticleDetails(){
        
        string queryStr = 'Select id,Article_Category__c,Description__c,External_Id__c, UrlName, FirstPublishedDate, '+
                                    ' Title,KnowledgeArticleId From Help__kav  WHERE PublishStatus = \'online\'  ';
        
        boolean searchFromCase = false;
        //for the first time on page load we want to show relevent article records
        list<Case> caseList = new list<Case>();
        if(primaryCaseId != null && string.isBlank(searchStr) && isPageLoad){
            caseList = [select id, Subject,Routing_Case_Reason__c from Case where id=:primaryCaseId];
            if(caseList.size()>0){
                searchStr = caseList.get(0).Subject;
                searchFromCase = true;
            }
        }
        
        string tempSearchString = searchStr;
        
        if(tempSearchString != null){
            tempSearchString = '% '+tempSearchString+'%';
            string firstWord = searchStr+'%';
            queryStr +=  ' and (Title Like:tempSearchString or Title Like: firstWord ) ';
            
            if(searchFromCase && caseList.size()>0){
                if(caseList.get(0).Routing_Case_Reason__c != null && caseList.get(0).Routing_Case_Reason__c.length()>0){
                    string crrStr = '% '+caseList.get(0).Routing_Case_Reason__c+'%';
                    string crrFirstWord = caseList.get(0).Routing_Case_Reason__c+'%';
                    queryStr +=  ' and (Title Like:tempSearchString or Title Like: firstWord or Title like:crrStr or Title like: crrFirstWord ) ';
                }
                else{
                    queryStr +=  ' and (Title Like:tempSearchString or Title Like: firstWord ) ';
                }
            }
            else{
                queryStr +=  ' and (Title Like:tempSearchString or Title Like: firstWord ) ';
            }
        }
                                     
        queryStr += ' and language=\'en_US\' ';
        
        if(selectedSortFilter == 'Title: A to Z'){
            queryStr += ' Order By Title ASC ';
        }
        else if(selectedSortFilter == 'Title: Z to A'){
            queryStr += ' Order By Title Desc ';
        }/*
        else if(selectedSortFilter == 'Published Date'){
            queryStr += ' Order By FirstPublishedDate ASC ';
        }*/
        else if(selectedSortFilter == 'External'){
            queryStr += ' and Article_Category__c != \'Internal\' Order By Title ASC ';
        }
        else if(selectedSortFilter == 'Internal'){
            queryStr += ' and Article_Category__c = \'Internal\' Order By Title ASC ';
        } 
        
        string autocompleteQueryStr = 'select id,Title from Help__kav where PublishStatus=\'online\' and language=\'en_US\' ';
        if(selectedSortFilter == 'External'){
            autocompleteQueryStr += ' and Article_Category__c != \'Internal\' Order By Title ASC ';
        }
        else if(selectedSortFilter == 'Internal'){
            autocompleteQueryStr += ' and Article_Category__c = \'Internal\' Order By Title ASC ';
        }        
        
        aticlesTitleList = new list<string>();
        for(Help__kav rec: database.query(autocompleteQueryStr)){
            aticlesTitleList.add(rec.title);
        }
        
               
        
        articleController = new ApexPages.StandardSetController(Database.getQueryLocator(queryStr)); 
        articleController.setPageSize(9);
        
        /*for(Help__kav rec: Database.query(queryStr)){
            articleDetail tempRec = new articleDetail(rec.Article_Category__c,rec.Description__c, rec.External_Id__c,
                                                    rec.title, rec.KnowledgeArticleId, rec.id );
            if(rec.Article_Category__c != null){
                articleKnowledgeDetailList.add(tempRec);
            }         
        }*/
        
        if(searchFromCase){
            searchStr = null;
        }
        
        isPageLoad = false;
    }
    
    public void searchArticle(){
        if(!string.isBlank(searchStr)){
            populateArticleDetails();
        }
    }
    
    
    
    public class articleDetail{
        
        public string articleCategory{get;set;}
        public string description{get;set;}
        public string externalId{get;set;}
        public string title{get;set;}
        public id kaId{get;set;}
        public id recId{get;set;}
        
        public articleDetail(string articleCat, string des, string extId, string titl, id kaIdd, id idd){
            articleCategory = articleCat;
            description = des.replaceAll('</p>','</p><br/>');            
            externalId = extId;
            title = titl;
            kaId = kaIdd;
            recId = idd;
        }        
    }
    
    public List<articleDetail> articleKnowledgeDetailList{  
        get{  
            if(articleController != null){
                list<articleDetail> templist = new list<articleDetail>();
                for(Help__kav rec: (list<Help__kav>)articleController.getRecords()){
                    articleDetail tempRec = new articleDetail(rec.Article_Category__c,rec.Description__c, rec.UrlName,
                                                    rec.title, rec.KnowledgeArticleId, rec.id );
		            if(rec.Article_Category__c != null){
		                templist.add(tempRec);
		            }
                }
                
                return  templist;
            }   
            else  
                return null ;  
        }  
        set;
    } 
    
    public Boolean hasNext{  
        get{  
            return articleController.getHasNext();  
        }  
        set;  
    }  
    public Boolean hasPrevious{  
        get{  
            return articleController.getHasPrevious();  
        }  
        set;  
    }  
    public Integer pageNumber{  
        get{  
            return articleController.getPageNumber();  
        }  
        set;  
    }  
    public void previous(){  
        articleController.previous();  
    } 
     
    public void next(){  
        articleController.next();  
    } 
    
}