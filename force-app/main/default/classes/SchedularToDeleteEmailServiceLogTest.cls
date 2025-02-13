/*
    @Author -Gaurav Khare
    @CreateDate 20-Jan-2020
    @Description - Test class for SchedularToDeleteEmailServiceLog
*/
@isTest
public class SchedularToDeleteEmailServiceLogTest {
    @isTest static void executeTest(){
        SchedulableContext sc = null;
        SchedularToDeleteEmailServiceLog tsc = new SchedularToDeleteEmailServiceLog();
        tsc.execute(sc);
    }  
}