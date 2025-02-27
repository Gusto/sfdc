public class HackathonJJAO {
    public static Map<String, String> mapResponses = getMapResponses();
    
    public static Map<String, String> getMapResponses(){
        Map<String, String> mapResponsesTemp = new Map<String, String>();
        mapResponsesTemp.put('Check for EE Benefits Changes','<span>Yes, there have been recent member level benefits changes for the Happy Gusto Company One. Here are the relevant cases:</span><ol><li ><span >Subject: Happy Gusto Company One. : Cody Brehm : Principal : Member Updates</span><ul><li ><span >Employee: Cody Brehm</span></li><li ><span >Date of Change: 02-10-2025</span></li><li ><span >Description: The last name was updated from Brehm to Lyda. COBRA has been activated.</span></li></ul></li><li ><span >Subject: Happy Gusto Company One. : Customer-Aa M : UnitedHealthcare : QLE</span><ul><li ><span >Employee: Customer-Aa P M</span></li><li ><span >Date of Change: 08-15-2024</span></li><li ><span >Description: Enrolled the newborn child (NG) in UnitedHealthcare plans due to the qualifying life event (Birth of a Child).</span></li></ul></li><li ><span >Subject: Happy Gusto Company One. : Customer-Aa M : Blue Cross Blue Shield : QLE</span><ul><li ><span >Employee: Customer-Aa P M</span></li><li ><span >Date of Change: 08-15-2024</span></li><li ><span >Description: Enrolled the newborn child (NG) in Blue Cross Blue Shield plans due to the qualifying life event (Birth of a Child).</span></li></ul></li></ol>');
        mapResponsesTemp.put('Check for Issues From Most Recent Onboarding', '<span >Here are the issues and requests for additional information that arose during the onboarding process for the most recent Benefit Order for Happy Gusto Company One:</span><ol>    <li >        <span >Ticket: Enrollment Sync Failed</span>        <ul>            <li >                <span >Employee: Customer-Aa P M</span>            </li>            <li >                <span >Carrier: Alegeus</span>            </li>            <li >                <span >Issue: The enrollment sync for the employee&apos;s Health Savings Account (HSA) failed.</span>            </li>            <li >                <span >Request: Additional documentation was needed to complete the enrollment.</span>            </li>            <li >                <span >Record ID: 500R700000E3lFFIAZ</span>            </li>        </ul>    </li>    <li >        <span >QC Error: Confirmation Error</span>        <ul>            <li >                <span >Employee: Customer-MDS</span>            </li>            <li >                <span >Carrier: UnitedHealthcare</span>            </li>            <li >                <span >Issue: A mismatch between Gusto and the carrier regarding the latest Open Enrollment selections.</span>            </li>            <li >                <span >Request: Documentation needed to verify the employee&apos;s selections.</span>            </li>            <li >                <span >Record ID: 500R700000AkOciIAF</span>            </li>        </ul>    </li>    <li >        <span >Ticket: Documentation Request</span>        <ul>            <li >                <span >Employee: Customer-MDS</span>            </li>            <li >                <span >Carrier: Principal</span>            </li>            <li >                <span >Issue: Additional documentation was requested for benefits related to the employee&apos;s recent changes.</span>            </li>            <li >                <span >Request: An itemized statement showing service dates, services rendered, and amounts charged was required.</span>            </li>            <li >                <span >Record ID: 500R700000AxhklIAB</span>            </li>        </ul>    </li></ol><span >These issues reflect the need for precise documentation and effective communication with carriers during the onboarding process.</span>');
        mapResponsesTemp.put('Get Record Links', '<span >Certainly! Here are the links to the records related to the unlocked enrollment request for Customer-Aa M Bn:</span><ol><li><span >Case Record:</span><span ><br></span><a href=\"https://gusto.lightning.force.com/lightning/r/Case/500R700000BiqXhIAJ/view\"><span>View Case Record</span></a></li></ol><span >This link will take you directly to the case record where the request to unlock the enrollment was made.</span>');
        mapResponsesTemp.put('Check for Unlocked Enrollments', '<span >Yes, there have been recent requests to unlock employee enrollments for the Happy Gusto Company One. Here are the details:</span><ol><li <span >Employee: Customer-Aa M Bn</span><ul><li ><span >Request Date: 06-13-2024</span></li><li ><span >Reason for Unlocking: The employee requested to make changes to their selections during Open Enrollment as they needed more information on the plan offerings while they were out of town on vacation.</span></li><li ><span >Context: The HR representative communicated that the employee was on vacation until the following Wednesday and wanted to complete their enrollment by the end of the extended deadline (06-20-2024). The enrollment was successfully unlocked to allow the employee to make the necessary changes.</span></li></ul></li></ol><span >This interaction highlights the importance of flexibility during Open Enrollment periods and the responsiveness of the support team to accommodate employee needs.</span>');
        mapResponsesTemp.put('Check for Known Carrier Data Mismatches', '<span >Yes, the Happy Gusto Company One has had issues flagged via cases with subjects containing &lsquo;reconciliation audit&rsquo;. Here are the details:</span><ol><li ><span >Subject: Happy Gusto Company One. : Customer-Jn Aries : UnitedHealthcare : Reconciliation Incorrect Open Enrollment</span><ul><li ><span >Employee: Customer-Jn Aries</span></li><li ><span >Plan Name: UHC Choice Plus Direct - $500 - CWWY platinum</span></li><li ><span >Date of Discrepancy: 05-29-2024</span></li><li ><span >Description: There is a mismatch between Gusto and the carrier on the latest Open Enrollment selections.</span></li><li ><span >Record ID: 500R700000AkOciIAF</span></li></ul></li><li ><span >Subject: Happy Gusto Company One. : CB Berry : UnitedHealthcare : Reconciliation Incorrect QLE Enrollment</span><ul><li ><span >Employee: CB Berry</span></li><li ><span >Plan Name: UHC Choice Plus Direct - $4,000 - CWWJ silver</span></li><li ><span >Date of Discrepancy: 05-29-2024</span></li><li ><span >Description: There is a mismatch between Gusto and the carrier on the latest Qualifying Life Event selections.</span></li><li ><span >Record ID: 500R700000BWjV3IAL</span></li></ul></li></ol><span >These cases highlight discrepancies in enrollment information between Gusto and the respective carriers.</span>');
		mapResponsesTemp.put('Account Summary', '<span >Account Overview: Happy Gusto Company One</span><ul><li ><span >Tier: Plus</span></li><li ><span >Number of Active Employees: 20</span></li><li ><span >States of Operation: AR, CA, CO, CT, FL, GA, HI, IA, LA, MD, MA, MI, MN, MO, MT, NJ, NY, NC, OH, PA, SC, TX, VA, WA, WI, AL</span></li><li ><span >Active Benefits: The company offers various benefits including medical, dental, vision, short-term disability, and long-term disability.</span></li></ul><span >Recent Issues and Discrepancies:</span><ol><li ><span >DIFOT Status: Not met. Some lines of coverage have not been approved before the effective date.</span></li><li ><span >Open Enrollment Concerns: There have been inquiries regarding the enrollment process, particularly for employees like Customer-Aa M Bn who needed their benefits unlocked for changes.</span></li><li ><span >Claims and Documentation Issues: There are ongoing discrepancies with claims related to employees, specifically for Customer-MDS, indicating that certain claims were denied due to insufficient documentation.</span></li><li ><span >Carrier Communication: Multiple tickets indicate issues with carrier orders, including requests for additional documentation and confirmation of enrollments which have not yet been resolved.</span></li></ol><span >Specific Dates of Issues Surfaced:</span><ul><li ><span >The discrepancies regarding employee enrollments and claims have been noted in communications dating back to early June 2024 and ongoing into late August 2024.</span></li></ul>');
		mapResponsesTemp.put('Check for Recent Benefit Changes', '<span >The Happy Gusto Company One has requested several changes to their benefits, as indicated by the following opportunities and tickets:</span><ol><li ><span >Opportunity for Benefits Change:</span><ul><li><span >Record Type: Benefits Change</span></li><li><span >Description: The group has been looking to adjust their benefits during the renewal period, specifically for the UnitedHealthcare plans.</span></li><li><span >Record ID: 006R7000007HesMIAS</span></li></ul></li><li ><span >Ticket on Benefit Order:</span><ul><li><span >Issue: A request was made to change the waiting period for coverage. This is crucial for ensuring that employees have timely access to their benefits.</span></li><li><span >Carrier: UnitedHealthcare</span></li><li><span >Record ID: 500R700000BMDhtIAH</span></li></ul></li><li ><span >Ticket on Opportunity:</span><ul><li><span >Issue: There was a request for changes to the contribution scheme related to the Principal plans. This adjustment is necessary to align with the group&apos;s financial strategies.</span></li><li><span >Record ID: 500R700000BMDhuIAH</span></li></ul></li><li ><span >Ticket requesting changes to the waiting period:</span><ul><li><span >Description: The group is looking to modify the waiting period for new hires to ensure they receive benefits promptly.</span></li><li><span >Record ID: 500R700000BMDhuIAH</span></li></ul></li></ol><span >These records highlight the group&apos;s proactive approach to managing their employee benefits, focusing on ensuring that their employees are adequately covered and that the benefits align with their operational needs.</span>');
        return mapResponsesTemp;
    }
    @AuraEnabled
    public static List<SObject> getPennyAcctions(String recordId, String strRecordTypeName, String strObjectName){
        System.debug(recordId + ':' + strRecordTypeName + ':' + strObjectName);
        String stringLike = '%'+strRecordTypeName+'%';
        List<Hackathon_JJAO__mdt> list_metadata = [SELECT id, 
                                                   Action_Name__c, 
                                                   Record_Type_Name__c, Object__c, Description__c, Parent_Action_Name__c
                                                   FROM Hackathon_JJAO__mdt 
                                                   WHERE Object__c =: strObjectName
                                                   AND Record_Type_Name__c LIKE: stringLike];
        
        
        list_metadata.addAll([SELECT id, 
                              Action_Name__c, 
                              Record_Type_Name__c, Object__c,Description__c , Parent_Action_Name__c
                              FROM Hackathon_JJAO__mdt 
                              WHERE Object__c = null AND ID NOT IN:list_metadata ]);
        
        list_metadata.addAll([SELECT id, 
                              Action_Name__c, 
                              Record_Type_Name__c, Object__c, Description__c  , Parent_Action_Name__c
                              FROM Hackathon_JJAO__mdt 
                              WHERE Object__c =: strObjectName 
                              AND Record_Type_Name__c = null AND ID NOT IN:list_metadata]);
        return list_metadata;
        
    }
    
    @AuraEnabled
    public static List<Object> callGTP(Id promptId, List<String> prevResponse){
        System.debug('promptId:'+promptId);
        Hackathon_JJAO__mdt mtd_metadata = [SELECT id, 
                                             Action_Name__c, 
                                             Record_Type_Name__c, Object__c, Prompt__c
                                             FROM Hackathon_JJAO__mdt 
                                             WHERE Id =: promptId];
        Datetime start = System.Now();
        //Making chatGPT Call
        //Getting data
        //Adding promtp from metadata
        //Adding previousResponse in case there are any
        //Mocking response
        System.debug('mtd_metadata:'+mtd_metadata);
		List<String> response = new List<String>();
        System.debug('mapResponses:'+mapResponses);
        response.add(mapResponses.get(mtd_metadata.Action_Name__c));
        while (System.Now().getTime() < start.getTime() + 2000) {
        } //Delay
        return response;
    }

}