/**
 * @name         TaxResAutomatedCustomerCommSchedule
 * @author       Anand Singh
 * @Date         23rd Sept 2021
 * @description  This is the Schedular class which call the batch class TaxResAutomatedCustomerCommBatch
 * @test class   TaxResAutomatedCustomerCommBatchTest.cls
 **/
public class TaxResAutomatedCustomerCommSchedule implements Schedulable {
    
    /**
 * @Author      : Anand Singh
 * @Description : describle execute method.
 * @Parm        : Object of SchedulableContext.
 * @Return      : void
 **/
  public void execute(SchedulableContext ctx) {
    TaxResAutomatedCustomerCommBatch objCommBatch = new TaxResAutomatedCustomerCommBatch();
    Database.executeBatch(objCommBatch, 10);
}

}