/**
* @name         PTPayrollRunNotificationScheduler
* @author       Pravesh Rana
* @date         10/21/2019
* @description  Schedules the Payroll notifications
* @test class   PTPayrollRunNotificationSchedulerTest
* @revisions    Date ------------ Name ------------ Comments
*               12/16/2019        SJay              Added PayrollTransferTimeTrackingBatch scheduler here.
*               04/30/2020        Neha Dabas        Run BTCarrierOrderAnalyticsBatch and BTBenefitOrderAnalyticsBatch.  
**/
public with sharing class PTPayrollRunNotificationScheduler implements Schedulable {
   public void execute(SchedulableContext SC) {
      OrderTriggerHelper.updateOrderNotificationOnCase(); 
      OrderTriggerHelper.UpdateOrderNotificationForFinalStepOnCase();
       
      PayrollTransferTimeTrackingBatch ptTimeTrackingBatch = new PayrollTransferTimeTrackingBatch();
      database.executeBatch(ptTimeTrackingBatch);

      //Run Analytics batches for Benefits Transfer Carrier Order and Benefit Order
      BTBenefitOrderAnalyticsBatch btBOBatch = new BTBenefitOrderAnalyticsBatch();
      database.executeBatch(btBOBatch);
      BTCarrierOrderAnalyticsBatch btCOBatch = new BTCarrierOrderAnalyticsBatch();
      database.executeBatch(btCOBatch);

      //Run Batch to Create/Update Rate verification cases
      //CreateRateVerificationCaseBatch rvBatch = new CreateRateVerificationCaseBatch();
      //database.executeBatch(rvBatch);
   }
}