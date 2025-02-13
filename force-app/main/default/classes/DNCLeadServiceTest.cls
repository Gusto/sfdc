@istest
public class DNCLeadServiceTest {

    @isTest
    static void testGetLeadData() {
        Lead l = new Lead();
        l.FirstName = 'Test';
        l.LastName = 'Test';
        l.Company = 'Test';
        l.phone = '8888888888';
        l.Email = 'test@gusto.com';
        insert l;
        
        DNCLeadService.doGet();
    }


    @isTest
    static void testPostLeadData() {
        Lead l = new Lead();
        l.FirstName = 'Test';
        l.LastName = 'Test';
        l.Company = 'Test';
        l.phone = '8888888888';
        l.Email = 'test@gusto.com';
        insert l;
        
        List<DNCLeadService.leadUpdateInfo> updateList = new List<DNCLeadService.leadUpdateInfo>();
        DNCLeadService.leadUpdateInfo info = new DNCLeadService.leadUpdateInfo();
        info.id = l.id;
        info.activityExists = 'true';
        info.doNotCall = 'true';
        updateList.add(info);
        DNCLeadService.doPost(updateList);
    }    
}