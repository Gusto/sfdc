public with sharing class TaxResCaseScheduler implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        TaxResCaseAgencyInfoAgathaSyncBatch batchController = new TaxResCaseAgencyInfoAgathaSyncBatch();
        
        if(!test.isRunningTest())
            Database.executeBatch(batchController, 1);
    }
}