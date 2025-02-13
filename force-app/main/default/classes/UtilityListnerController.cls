/* 
    Description: used by utility listner component. Fetches case Origin and it is Phone or Chat.
    It launches Post Tab automatically
    Author: Praveen Sethu
    Date: 09/16/2020
*/

public with sharing class UtilityListnerController {
    
    @AuraEnabled
    public static Case getCaseDetails(Id idCase) {
        return  [
            SELECT
              Id,
              Origin
            FROM
              Case
            WHERE
              Id = :idCase
        ];
    }
}