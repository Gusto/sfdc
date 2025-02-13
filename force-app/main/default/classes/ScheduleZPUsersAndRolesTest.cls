@isTest
public class ScheduleZPUsersAndRolesTest {
    @isTest
    public static void testScheduler() {
        Configuration_Settings__c cs = new Configuration_Settings__c();
        cs.Batch_Size__c = 5;
        insert cs;

        String Cron_Sched = '0 0 * * * ?';
        ScheduleZPUsersAndRoles sch = new ScheduleZPUsersAndRoles();
        String jobID = system.schedule('ConciergeAccountScheduler Job', Cron_Sched, sch);
    }
}