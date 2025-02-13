public with sharing class UR_ReaserachCSVDataQueue  implements Queueable {

    private Set<Id> csvDadaIds;
	private Set<Id> projectIds;
       
    public UR_ReaserachCSVDataQueue(Set<Id> inputCsvIds, Set<Id> inputProjectIds){
        csvDadaIds = inputCsvIds;
		projectIds = inputProjectIds;
    }
   
    public void execute(QueueableContext context) { 
        UR_ResearchCSVDataTriggerHelper.moveDataIntoResearchUploadInfo(csvDadaIds, projectIds);
    }
}