/**
 * @name         : LWC_ContactUserInformationController
 * @author       : Dhir Kumar
 * @date         : 10-07-2020
 * @description  : Apex controller for contactUserInfoPopover,caseContactHeaderPopOver,caseContactHeaderCmp components
 * @test classes : LWC_ContactUserInformationCont_Test
**/
public without sharing class LWC_ContactUserInformationController {
    /**
     * @Author      : Dhir Kumar
     * @Description : It will query the case record
     * @Parm        : strId - record id
     * @Return      : Map<String, SObject>
    **/
    @AuraEnabled
    public static Map<String, SObject> queryCase(String strId) {
        Map<String, SObject> map_CaseRecordByParameter = new Map<String, SObject>();
        if (String.isNotBlank(strId)) {
            try {
                Id idCaseId = (Id) strId;
                String strSObjectType = idCaseId.getSObjectType().getDescribe().getName();
                
                if (strSObjectType.equals('LiveChatTranscript')) {
                    List<LiveChatTranscript> list_LiveChatTranscripts = [SELECT
                                                                         Id,
                                                                         CaseId
                                                                         FROM LiveChatTranscript
                                                                         WHERE Id = :strId];
                    
                    if (!list_LiveChatTranscripts.isEmpty()) {
                        strId = list_LiveChatTranscripts[0].CaseId;
                    }
                }
                
                List<Case> list_Cases = [SELECT 
                                         Id,
                                         Subject,
                                         CaseNumber,
                                         ContactId,
                                         AccountId,
                                         OwnerId,
                                         Status,
                                         RecordTypeId,
                                         RecordType.Name,
                                         Panda_Company_URL__c,
                                         Account_Company_Id__c,
                                         Contact_Employee_Id__c,
                                         Assigned_by_Play_Mode__c,
                                         Contact.Name,
                                         Contact.Email,
                                         Contact.Phone,
                                         Contact.Contractor_Id__c,
                                         Contact_User_Id__c
                                         FROM Case
                                         WHERE Id = :strId];
                
                if (!list_Cases.isEmpty()) {
                    map_CaseRecordByParameter.put('CaseRec', list_Cases[0]);
                }
            } catch(Exception ex) {
                ExceptionLogUtil.logException(
                    'LWC_ContactUserInformationController',
                    'queryCase',
                    ex.getMessage(),
                    ex.getStackTraceString()
                );
            }
        }
        
        return map_CaseRecordByParameter;
    }
    
    /**
     * @Author      : Dhir Kumar
     * @Description : This method is to get the ZP User roles and related informatoin to show as contact on the UI.
     * @Parm        : idCase - case id
     * @Return      : UserRoleInformation - Wrapper of UserRoleInformation
    **/
    @AuraEnabled
    public static UserRoleInformation getUserInformation(Id idCase) {
        UserRoleInformation objUserRoleInformation = new UserRoleInformation();
        try {
            Map<String, UserRoleInfo> map_CompanyUserRole = new Map<String, UserRoleInfo>();
            Map<String, UserRoleInfo> map_FirmUserRole = new Map<String, UserRoleInfo>();
            Set<String> set_Companies = new Set<String>();
            Set<String> set_Accountants = new Set<String>();
            
            if (idCase != null) {
                String strSObjectType = idCase.getSObjectType().getDescribe().getName();
                if (strSObjectType.equals('LiveChatTranscript')) {
                    List<LiveChatTranscript> list_LiveChatTranscripts = [SELECT
                                                                         Id,
                                                                         CaseId
                                                                         FROM LiveChatTranscript
                                                                         WHERE Id = :idCase];
                    
                    if (!list_LiveChatTranscripts.isEmpty()) {
                        idCase = list_LiveChatTranscripts[0].CaseId;
                    }
                }
                
                List<ZP_User__c> list_ZPUsers = new List<ZP_User__c>();
                List<ZP_User_Role__c> list_ZPUserRoles = new List<ZP_User_Role__c>();
                List<Case> list_Cases = [SELECT 
                                         Contact.ZP_User_Id__c,
                                         Contact.Name,
                                         SuppliedEmail
                                         FROM Case
                                         WHERE Id = :idCase];
                
                if (!list_Cases.isEmpty()) {
                    list_ZPUsers = [SELECT 
                                    Id,
                                    Email__c,
                                    Deleted_At__c
                                    FROM ZP_User__c
                                    WHERE Email__c = :list_Cases[0].SuppliedEmail
                                    AND Deleted_At__c = null
                                    LIMIT 1];
                    
                    if (!list_ZPUsers.isEmpty()) {
                        list_ZPUserRoles = [SELECT
                                            Id,
                                            Type__c,
                                            First_Name__c,
                                            Last_Name__c,
                                            Accounting_Firm_Id__c,
                                            Employee_Id__c,
                                            Contractor_Id__c,
                                            Billing_Admin__c,
                                            Company_Id__c,
                                            Is_Primary__c,
                                            Collaborator_Type__c,
                                            User_Permissions__c
                                            FROM ZP_User_Role__c
                                            WHERE User_Id__c = :list_Cases[0].Contact.ZP_User_Id__c
                                            AND Deleted_At__c = null];
                    }
                    
                    for (ZP_User_Role__c objZPUserRole : list_ZPUserRoles) {
                        if (String.isNotBlank(objZPUserRole.Company_Id__c)) {
                            set_Companies.add(objZPUserRole.Company_Id__c);
                        }
                        if (String.isNotBlank(objZPUserRole.Accounting_Firm_Id__c)) {
                            set_Accountants.add(objZPUserRole.Accounting_Firm_Id__c);
                        }
                    }
                    
                    Map<String, Account> map_Company = new Map<String, Account>();
                    Map<String, Account> map_Accountant = new Map<String, Account>();
                    if (!set_Companies.isEmpty()) {
                        map_Company = getCompanyMap(set_Companies);
                    }
                    if (!set_Accountants.isEmpty()) {
                        map_Accountant = getAccountantMap(set_Accountants);
                    }
                    
                    for (ZP_User_Role__c objZPUserRole : list_ZPUserRoles) {
                        UserRoleInfo objUserRoleInfoWrapper = new UserRoleInfo();
                        
                        if (String.isNotBlank(objZPUserRole.Company_Id__c)) {
                            if (map_CompanyUserRole.containsKey(objZPUserRole.Company_Id__c)) {
                                objUserRoleInfoWrapper = map_CompanyUserRole.get(objZPUserRole.Company_Id__c);
                            }
                            objUserRoleInfoWrapper.strPandaURL = 'companies/' + objZPUserRole.Company_Id__c;
                            
                            objUserRoleInfoWrapper.strZPCompanyId = objZPUserRole.Company_Id__c;
                            if (map_Company.containsKey(objZPUserRole.Company_Id__c)) {
                                Account objCompAcct = map_Company.get(objZPUserRole.Company_Id__c);
                                objUserRoleInfoWrapper.strCompanyName = objCompAcct.Name;
                                objUserRoleInfoWrapper.strCompanyId = objCompAcct.Id;
                                if (String.isNotBlank(objCompAcct.Concierge_Group_Id__c)) {
                                    objUserRoleInfoWrapper.strConciergeGroupId = 'Concierge Pod: ' + objCompAcct.Concierge_Group_Id__c + ' <br/> ';
                                    objUserRoleInfoWrapper.strConciergeGroupName = objCompAcct.Concierge_Group__c;
                                }
                                
                                if (String.isNotBlank(objCompAcct.Tier__c)) {
                                    objUserRoleInfoWrapper.strTier = 'Tier: ' + objCompAcct.Tier__c + ' <br/> ';
                                }
                            }
                        }
                        
                        if (String.isNotBlank(objZPUserRole.Contractor_Id__c)) {
                            if (map_CompanyUserRole.containsKey(objZPUserRole.Contractor_Id__c)) {
                                objUserRoleInfoWrapper = map_CompanyUserRole.get(objZPUserRole.Contractor_Id__c);
                            }
                            objUserRoleInfoWrapper.strContractorURL = 'contractors/' + objZPUserRole.Contractor_Id__c;
                        }
                        
                        if (String.isNotBlank(objZPUserRole.Accounting_Firm_Id__c)) {
                            if (map_FirmUserRole.containsKey(objZPUserRole.Accounting_Firm_Id__c)) {
                                objUserRoleInfoWrapper = map_FirmUserRole.get(objZPUserRole.Accounting_Firm_Id__c);
                            }
                            objUserRoleInfoWrapper.strPandaURL = 'accounting_firms/' + objZPUserRole.Accounting_Firm_Id__c;
                            
                            objUserRoleInfoWrapper.strZPFirmId = objZPUserRole.Accounting_Firm_Id__c;
                            if (map_Accountant.containsKey(objZPUserRole.Accounting_Firm_Id__c)) {
                                Account objAccountantAcct = map_Accountant.get(objZPUserRole.Accounting_Firm_Id__c);
                                objUserRoleInfoWrapper.strFirmName = objAccountantAcct.Name;
                                objUserRoleInfoWrapper.strCompanyId = objAccountantAcct.Id;
                                if (String.isNotBlank(objAccountantAcct.Concierge_Group_Id__c)) {
                                    objUserRoleInfoWrapper.strConciergeGroupId = 'Concierge Pod ' + objAccountantAcct.Concierge_Group_Id__c + ' <br/> ';
                                    objUserRoleInfoWrapper.strConciergeGroupName = objAccountantAcct.Concierge_Group__c;
                                }
                                
                                if (String.isNotBlank(objAccountantAcct.AM_Tier__c)) {
                                    objUserRoleInfoWrapper.strTier = 'Partner Tier: ' + objAccountantAcct.AM_Tier__c + ' <br/> ';
                                }
                            }
                        }
                        
                        objUserRoleInfoWrapper.strFirstName = objZPUserRole.First_Name__c;
                        objUserRoleInfoWrapper.strLastName = objZPUserRole.Last_Name__c;
                        
                        if (objZPUserRole.Type__c == 'Role::PayrollAdmin') {
                            objUserRoleInfoWrapper.blnPayrollAdmin = true;
                            if (objZPUserRole.Is_Primary__c) {
                                objUserRoleInfoWrapper.blnPrimaryPayrollAdmin = true;
                            }
                        }
                        if (objZPUserRole.Type__c == 'Role::Employee') {
                            objUserRoleInfoWrapper.blnEmployee = true;
                        }
                        if (objZPUserRole.Type__c == 'Role::Contractor') {
                            objUserRoleInfoWrapper.blnContractor = true;
                        }
                        if (objZPUserRole.Type__c == 'Role::Signatory') {
                            objUserRoleInfoWrapper.blnSignatory = true;
                        }
                        if (objZPUserRole.Type__c == 'Role::Accountant') {
                            objUserRoleInfoWrapper.blnAccountant = true;
                        }
                        if (objZPUserRole.Billing_Admin__c == true) {
                            objUserRoleInfoWrapper.blnBillingAdmin = true;
                        }
                        
                        if (String.isNotBlank(objZPUserRole.User_Permissions__c)) {
                            String strPermissions;
                            for (String strPermission : objZPUserRole.User_Permissions__c.split(',')) {
                                if (String.isBlank(strPermissions)) {
                                    strPermissions = '<b>' + getTitleString(strPermission) + '</b><br/>';
                                } else {
                                    strPermissions += '<b>' + getTitleString(strPermission) + '</b><br/>';
                                }
                            }    
                            objUserRoleInfoWrapper.strPermission = strPermissions;
                        }
                        
                        if (String.isNotBlank(objZPUserRole.Company_Id__c)) {
                            map_CompanyUserRole.put(objZPUserRole.Company_Id__c, objUserRoleInfoWrapper);
                        }
                        if (String.isNotBlank(objZPUserRole.Accounting_Firm_Id__c)) {
                            map_FirmUserRole.put(objZPUserRole.Accounting_Firm_Id__c, objUserRoleInfoWrapper);
                        }
                    }
                    
                    objUserRoleInformation.list_CompanyInfo = map_CompanyUserRole.values();
                    objUserRoleInformation.list_FirmInfo = map_FirmUserRole.values();
                    objUserRoleInformation.map_CompanyUserRole = map_CompanyUserRole;
                    objUserRoleInformation.map_FirmUserRole = map_FirmUserRole;
                }
            }
        } catch(Exception ex) {
            ExceptionLogUtil.logException(
                'LWC_ContactUserInformationController',
                'getUserInformation',
                ex.getMessage(),
                ex.getStackTraceString()
            );
        }
        
        return objUserRoleInformation;
    }
    
    /**
     * @Author      : Dhir Kumar
     * @Description : This method will get the accounts on the basis of company ID from ZP user Role
     * @Parm        : set_Companies - Set of ZP User Ids
     * @Return      : Map<String, Account> - Map of Accounts by ZP Company  Id.
    **/
    public static Map<String, Account> getCompanyMap(Set<String> set_Companies) {
        Map<String, Account> map_Company = new Map<String, Account>();
        for (Account objAccount : [SELECT 
                                   Id,
                                   Name,
                                   ZP_Company_Id__c,
                                   ZP_Firm_ID__c,
                                   Concierge_Group__c,
                                   Concierge_Group_Id__c,
                                   Tier__c,
                                   RecordType.Name
                                   FROM Account
                                   WHERE ZP_Company_Id__c IN :set_Companies]) {
                                       map_Company.put(objAccount.ZP_Company_Id__c, objAccount);
                                   }
        return map_Company;
    }
    
    /**
     * @Author      : Dhir Kumar
     * @Description : This method will get the accounts on the basis of Firm ID from ZP user Role
     * @Parm        : set_Accountant - set of ZP User Ids
     * @Return      : Map<String, Account> - Map of Accounts by ZP Firm Id.
    **/
    public static Map<String, Account> getAccountantMap(Set<String> set_Accountants) {
        Map<String, Account> map_Accountant = new Map<String, Account>();
        for (Account objAccount : [SELECT Id,
                                   Name,
                                   ZP_Company_Id__c,
                                   ZP_Firm_ID__c,
                                   Concierge_Group__c,
                                   Concierge_Group_Id__c,
                                   AM_Tier__c,
                                   RecordType.Name
                                   FROM Account
                                   WHERE ZP_Firm_ID__c IN :set_Accountants]) {
                                       map_Accountant.put(objAccount.ZP_Firm_ID__c, objAccount);
                                   }
        return map_Accountant;
    }
    
    /**
     * @Author      : Dhir Kumar
     * @Description : This method will alter the data into capital and will join them into string
     * @Parm        : strParameter
     * @Return      : String
    **/
    public static String getTitleString(String strParameter) {
        strParameter = strParameter.toLowerCase().replaceAll('_', ' ');
        List<String> list_Pieces = new List<String>();
        
        for (String strPiece : strParameter.split(' ')) {
            // Capitalize each piece
            strPiece = strPiece.capitalize();
            list_Pieces.add(strPiece);
        }
        
        return String.join(list_Pieces, ' ');
    }
    
    /**
     * @Author      : Dhir Kumar
     * @Description : This method will Perform the DML operation on the Case and relate it to Account selected from the UI.
     * @Parm        : blnIsReroute - boolean flag to reroute, idCase - case id, strCompanyFirmId - Account Id
     * @Return      : Case object
    **/
    @AuraEnabled
    public static Case updateAccount(Boolean blnIsReroute, Id idCase, String strCompanyFirmId) {
        try {
            if (idCase != null) {
                String strSObjectType = idCase.getSObjectType().getDescribe().getName();
                if (strSObjectType.equals('LiveChatTranscript')) {
                    List<LiveChatTranscript> list_LiveChatTranscripts = [SELECT
                                                                         Id,
                                                                         CaseId
                                                                         FROM LiveChatTranscript
                                                                         WHERE Id = :idCase];
                    
                    if (!list_LiveChatTranscripts.isEmpty()) {
                        idCase = list_LiveChatTranscripts[0].CaseId;
                    }
                }
                
                if (String.isNotBlank(strCompanyFirmId)) {
                    List<Account> list_Accounts = [SELECT Id FROM Account WHERE Id = :strCompanyFirmId];

                    if (!list_Accounts.isEmpty()) {
                        Case objTempCase = new Case(Id = idCase);
                        objTempCase.AccountId = list_Accounts[0].Id;
                        objTempCase.Related_Account_Touchpoint__c = true; 
                        if (blnIsReroute) {
                            Database.DMLOptions objDMLOptions = new Database.DMLOptions();
                            objDMLOptions.assignmentRuleHeader.useDefaultRule = true;
                            objTempCase.setOptions(objDMLOptions);
                            update objTempCase;
                            return [SELECT
                                    Id,
                                    CaseNumber,
                                    Owner.Name
                                    FROM Case WHERE Id = :idCase];
                        } else {
                            update objTempCase;
                        }
                    }
                }
            }
        } catch(Exception ex) {
            ExceptionLogUtil.logException(
                'LWC_ContactUserInformationController',
                'updateAccount',
                ex.getMessage(),
                ex.getStackTraceString()
            );
        }
        
        return null;
    }
    
    /**
     * @Author      : Dhir Kumar
     * @Description : This method will Perform the DML operation on the Case and relate it to Account selected from the UI.
     * @Parm        : idCase - case id, strContactId - Contact Id
     * @Return      : Case object
    **/
    @AuraEnabled
    public static Case updateContactOnSave(Id idCase, String strContactId) {
        try {
            if (idCase != null) {
                String strSObjectType = idCase.getSObjectType().getDescribe().getName();
                if (strSObjectType.equals('LiveChatTranscript')) {
                    List<LiveChatTranscript> list_LiveChatTranscripts = [SELECT
                                                                         Id,
                                                                         CaseId
                                                                         FROM LiveChatTranscript
                                                                         WHERE Id = :idCase];
                    
                    if (!list_LiveChatTranscripts.isEmpty()) {
                        idCase = list_LiveChatTranscripts[0].CaseId;
                    }
                }
                
                if (String.isNotBlank(strContactId)) {
                    List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE Id = :strContactId];

                    if (!list_Contacts.isEmpty()) {
                        Case objCase = new Case(
                            Id = idCase,
                            ContactId = list_Contacts[0].Id
                        );
                        update objCase;
                        
                        return [SELECT 
                                Id,
                                Contact.Name,
                                Contact_Employee_Id__c,
                                Panda_Company_URL__c,
                                Account_Company_Id__c,
                                Contact_User_Id__c
                                FROM Case
                                WHERE Id = :objCase.Id];
                    }
                }
            }
        } catch(Exception ex) {
            ExceptionLogUtil.logException(
                'LWC_ContactUserInformationController',
                'updateContactOnSave',
                ex.getMessage(),
                ex.getStackTraceString()
            );
        }
        
        return null;
    }
    
    /**
     * @name         : UserRoleInformation
     * @author       : Dhir Kumar
     * @date         : 10-07-2020
     * @description  : Wrapper class for UserRoleInformation
     * @test classes : LWC_ContactUserInformationCont_Test
    **/
    public class UserRoleInformation {
        @AuraEnabled public List<UserRoleInfo> list_CompanyInfo { get; set; }
        @AuraEnabled public List<UserRoleInfo> list_FirmInfo { get; set; }
        @AuraEnabled public Map<String, UserRoleInfo> map_CompanyUserRole { get; set; }
        @AuraEnabled public Map<String, UserRoleInfo> map_FirmUserRole { get; set; }
    }
    
    /**
     * @name         : UserRoleInfo
     * @author       : Dhir Kumar
     * @date         : 10-07-2020
     * @description  : Wrapper class for UserRoleInfo
     * @test classes : LWC_ContactUserInformationCont_Test
    **/
    public class UserRoleInfo {
        @AuraEnabled public String strZPCompanyId { get; set; }
        @AuraEnabled public String strCompanyId { get; set; }
        @AuraEnabled public String strCompanyName { get; set; }
        @AuraEnabled public string strConciergeGroupId { get;set; }
        @AuraEnabled public string strTier{ get;set; }
        @AuraEnabled public string strConciergeGroupName { get;set; }
        @AuraEnabled public String strZPFirmId { get;set; }
        @AuraEnabled public String strFirmId { get;set; }
        @AuraEnabled public String strFirmName { get;set; }
        @AuraEnabled public String strFirstName { get;set; }
        @AuraEnabled public String strLastName { get;set; }
        @AuraEnabled public String strPhone { get;set; }
        @AuraEnabled public String strPermission{ get;set; } 
        @AuraEnabled public Boolean blnPayrollAdmin { get;set; }
        @AuraEnabled public Boolean blnPrimaryPayrollAdmin { get;set; }
        @AuraEnabled public Boolean blnAccountant { get;set; }
        @AuraEnabled public Boolean blnContractor { get;set; }
        @AuraEnabled public Boolean blnEmployee { get;set; }
        @AuraEnabled public Boolean blnSignatory { get;set; }
        @AuraEnabled public Boolean blnBillingAdmin { get;set; }
        @AuraEnabled public String strPandaURL { get; set; }
        @AuraEnabled public String strContractorURL{ get;set; }

        /**
         @Added By: David (Dato) Tsamalashvili
         @Date: April 10, 2020
         @Desc: BT-7428 - All role names where rendered in UI since default values where null.
                    Setting boolean default values.
        */
        public UserRoleInfo() {
            this.blnPayrollAdmin = false;
            this.blnPrimaryPayrollAdmin = false;
            this.blnAccountant = false;
            this.blnContractor = false;
            this.blnEmployee = false;
            this.blnSignatory = false;
            this.blnBillingAdmin = false;
        }
    }
}