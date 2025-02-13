global class ScheduleToCreateCarrierOrderAgainstBO implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        OrderUtils.createCarrierOrderAgainstBO();
   }
}