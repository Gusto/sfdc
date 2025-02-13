/**
 * @name         OnboardingPlayModeUtility
 * @author       Neha Dabas
 * @date         4th May 2020
 * @description  To hold common methods related to Play mode logic
 * @test class   UpdateCarrierPlayInformationCtrlTest,CarrierOrderTriggerHelperTest,DisplayEditTTConfirmationExtTest
 * @revisions    Date ------------ Name ------------ Comments  
 */
public with sharing class OnboardingPlayModeUtility {
    static final String ORDER_EVENT = 'Order', AUDIT_EVENT = 'Audit';
    /*
     * Description  : Calculate the playable date for Carrier Orders using the Play Citeria based on Carriers
     * Author       : Neha Dabas
    */
    public static List<Carrier_Order__c> setFirstPlayDateForCarrierOrders(String strEventType,List<Carrier_Order__c> list_CO) {
        if(list_CO == NULL || list_CO.isEmpty()){
            return list_CO;
        }
        // Fetch Carrier Play information for combination of EventType and PlaymodeType also Carrier if applicable
        Set<Id> set_CarrierIds = new Set<Id>();
        for(Carrier_Order__c objCO : list_CO){
            if((strEventType.equalsIgnoreCase(ORDER_EVENT) && objCO.Implementation_Stage__c == 'Ready for Confirmation')
                || (strEventType.equalsIgnoreCase(AUDIT_EVENT) && objCO.Implementation_Stage__c == 'Approved Pending EE Audit')){
                set_CarrierIds.add(objCO.Carrier__c);
            }
        }
        Map<String, List<Carrier_Play_Information__c>> map_CarrierToPlayInformation = getCarrierPlayInformation(strEventType,'First Play',set_CarrierIds,NULL,NULL);
        //Iterate over Carrier Orders to check if they statisfy the Play Mode Eligibility Criteria specified in Carrier_Play_Information table
        if(!map_CarrierToPlayInformation.isEmpty()){
            for(Carrier_Order__c objCO : list_CO){
                if((strEventType.equalsIgnoreCase(ORDER_EVENT) && objCO.Implementation_Stage__c == 'Ready for Confirmation')
                || (strEventType.equalsIgnoreCase(AUDIT_EVENT) && objCO.Implementation_Stage__c == 'Approved Pending EE Audit')){
                    List<Carrier_Play_Information__c> list_CarrierPlayInfo;
                    if(map_CarrierToPlayInformation.containsKey(objCo.Carrier__c)){
                        list_CarrierPlayInfo = map_CarrierToPlayInformation.get(objCo.Carrier__c);
                    }
                    if(!list_CarrierPlayInfo.isEmpty()){
                        Boolean blnBefore = false;
                        Integer intDaysToCompare = System.today().day();
                        if(System.today() < objCO.Effective_Date__c){
                            blnBefore = true;

                            if(checkDatesAtleast1MonthApart(system.today(),objCO.Effective_Date__c)){
                                intDaysToCompare = 1;
                            }
                        }
                        Carrier_Play_Information__c objApplicablePlayInfo;
                        for(Carrier_Play_Information__c objPlayInfo : list_CarrierPlayInfo) 
                        {
                            if(blnBefore && objPlayInfo.Before_After__c.containsIgnoreCase('Before')
                                && ((intDaysToCompare >= objPlayInfo.From__c && intDaysToCompare <= objPlayInfo.To__c) || ( objPlayInfo.From__c == NULL && objPlayInfo.To__c == NULL))){
                                objApplicablePlayInfo = objPlayInfo;
                                break;
                            }
                            else if(!blnBefore && ('BeforeOnward'.equalsIgnoreCase(objPlayInfo.Before_After__c) || 'After'.equalsIgnoreCase(objPlayInfo.Before_After__c))){
                                objApplicablePlayInfo = objPlayInfo;
                                break;
                            }
                        }

                        if(objApplicablePlayInfo != NULL){
                            Integer intDaysToAdd = Integer.valueOf(objApplicablePlayInfo.Number_of_Days__c);
                            if(ORDER_EVENT.equalsIgnoreCase(strEventType)){ // Carrier Order is playable
                                objCO.Order_Playable_Date__c = system.today().addDays(intDaysToAdd);
                            }
                            else if(AUDIT_EVENT.equalsIgnoreCase(strEventType)){ // Carrier Order is playable
                                if(blnBefore){ // if Approved Pending EE Audit date is before Coverage Effective Date then add the number of days to effective date to get new Playable Date
                                    objCO.Audit_Playable_Date__c = objCO.Effective_Date__c.addDays(intDaysToAdd);
                                }
                                else{ //Add the number of days to Approved Pending EE Audit date to get new playable date
                                    objCO.Audit_Playable_Date__c = system.today().addDays(intDaysToAdd);
                                }
                            }
                        }
                    }
                }
            }
        }
        return list_CO;
    }
    /*
     * Description  :   Check if two dates are atleast 1 month apart or not.
     *              :   Primarily written to check if Order is submitted more than a month before coverage effective date. 
     *              :   Eg. If today is 20th May and Coverage Effective Date is anytime in July or later then always the 1st - 15th record should be picked from configuration
     * Author       :   Neha Dabas
     */
    public static Boolean checkDatesAtleast1MonthApart(Date dtToCompare, Date dtFutureDate){
        Date dt2MonthsLater = dtToCompare.addMonths(2);

        Date dtFirstDay2MonthsLater = Date.newInstance(dt2MonthsLater.year(),dt2MonthsLater.month(),1);

        if(dtFutureDate >= dtFirstDay2MonthsLater){
            return true;
        }
        return false;
    }
    /*
     * Description  :   Fetch Carrier Play Information to determine the Play Citeria based on Carriers
     * Author       :   Neha Dabas
     */
    public static Map<String, List<Carrier_Play_Information__c>> getCarrierPlayInformation(String strEventType,String strPlayModeType,Set<Id> set_CarrierIds,Integer intDayToCmp,String strBefAftr) {

        Map<String, List<Carrier_Play_Information__c>> map_CarrierToPlayInformation = new Map<String, List<Carrier_Play_Information__c>>();        
        
        String strCarrierPlayInfoQuery ='SELECT Before_After__c,Carrier__c,Carrier__r.Carrier_Unique_Name__c,From__c,To__c,Number_of_Days__c,Event_Type__c,Play_Mode_Type__c'+
                                        ' FROM	Carrier_Play_Information__c'+
                                        ' WHERE Event_Type__c = :strEventType AND Play_Mode_Type__c = :strPlayModeType';
        
        if(set_CarrierIds == NULL || set_CarrierIds.isEmpty()){
            strCarrierPlayInfoQuery += ' AND Carrier__c = NULL';
        }
        else strCarrierPlayInfoQuery += ' AND Carrier__c IN :set_CarrierIds';

        if(intDayToCmp != NULL){
            if('BeforeOnward'.equalsIgnoreCase(strBefAftr)){
                strCarrierPlayInfoQuery += ' AND Before_After__c = :strBefAftr';
            }
            else strCarrierPlayInfoQuery += ' AND  From__c <= :intDayToCmp AND To__c >= :intDayToCmp ';
        }
        //iterate over CArrier play information records to arrange them based on Carrier
        for(Carrier_Play_Information__c objPlayInfo : Database.query(strCarrierPlayInfoQuery)) 
        {
            String strMapKey = 'None';
            if(objPlayInfo.Carrier__c != NULL){
                strMapKey =objPlayInfo.Carrier__c;
            }
            List<Carrier_Play_Information__c> list_CarrierPlayInfo;

            if(map_CarrierToPlayInformation.containsKey(strMapKey)) {
                list_CarrierPlayInfo = map_CarrierToPlayInformation.get(strMapKey);
            } 
            else{
                list_CarrierPlayInfo = new list<Carrier_Play_Information__c>();
            }
            list_CarrierPlayInfo.add(objPlayInfo);
            map_CarrierToPlayInformation.put(strMapKey, list_CarrierPlayInfo);    
        }
        return map_CarrierToPlayInformation;
    }
}