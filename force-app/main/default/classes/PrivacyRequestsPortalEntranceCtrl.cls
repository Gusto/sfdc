/***************************************************
Purpose : This class controls the PrivacyRequestsPortalEntrance page
Written By : Alex
Test Classes : PrivacyRequestTests, PrivacyRequestsPortalCtrlTest
****************************************************/
public without sharing class PrivacyRequestsPortalEntranceCtrl {
    public String strConfirmationCode {get; set;}
    public String strEmail {get; set;}
    private static Integer intCookieTimeout = 600;

    /*
    Search for open case where email and confirmation code match
    Written By : Alex X
    */
    public List<Case> getCase() {
        return [SELECT Id, Confirmation_Code__c, Status FROM Case WHERE Privacy_Requester_Email__c =: strEmail AND RecordType.Name = 'Privacy Request' AND IsClosed = FALSE LIMIT 1];
    }
    
    /*
    This method takes in a string and encrypts it with AES128
    Written by: Alex
    */

    public static String encryptString(String strStringToEncrypt) {
        Configuration_Settings__c configSettings = Configuration_Settings__c.getOrgDefaults();
        String aesCookieKey = configSettings.Privacy_Requests_Cookie_Key__c;
        Blob blobEncryptedString = Crypto.encryptWithManagedIV('AES128', EncodingUtil.base64decode(aesCookieKey), Blob.valueOf(strStringToEncrypt));
        String strEncodedString = EncodingUtil.base64Encode(blobEncryptedString);
        return strEncodedString;
    }

    /*
    This method takes in an encrypted String and decrypts it
    Written by: Alex
    */
    public static String decryptString(String strStringToDecrypt) {
        Configuration_Settings__c configSettings = Configuration_Settings__c.getOrgDefaults();
        String aesCookieKey = configSettings.Privacy_Requests_Cookie_Key__c;
        Blob blobDecodedString = EncodingUtil.base64Decode(strStringToDecrypt);
        Blob blobDecrypted = Crypto.decryptWithManagedIV('AES128', EncodingUtil.base64Decode(aesCookieKey), blobDecodedString);
        String strDecryptedString = blobDecrypted.toString();
        return strDecryptedString;
    }

    /*
    After user enters confirmation and email address,
    if the confirmation code matches, continue
    else return error

    if it verifies, write a cookie.
    cookie value: is what we data mine
    going to have to encrypt it.
    going to have to use email and confirmation
    email + delimiter + confirmation then encrypt this string
    use crypto class, store as a custom setting
    Written By : Alex X
    */
    public PageReference submit() {
        List<Case> list_QueriedCase = getCase();
        
        if(!list_QueriedCase.isEmpty()) {
            Case queriedCase = list_QueriedCase[0];
            if(strConfirmationCode == queriedCase.Confirmation_Code__c) {
                PageReference ref = new PageReference('/apex/PrivacyRequestsPortal?id=' + queriedCase.Id);
                Cookie cookie_Auth = new Cookie('prAuth', encryptString(strEmail + '$$' + strConfirmationCode),null,intCookieTimeout,true);
                ApexPages.currentPage().setCookies(new List<Cookie>{cookie_Auth});
                ref.setRedirect(true);

                if(queriedCase.Status == 'New') {
                    Case thisCase = new Case(
                        Id = queriedCase.Id,
                        Status = 'Email Confirmed'
                    );
                    update thisCase;
                }
                
                return ref;
            }
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email address or Confirmation Code was incorrect.'));
                return null;
            }
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No open request found.'));
            return null;
        }
    }

}