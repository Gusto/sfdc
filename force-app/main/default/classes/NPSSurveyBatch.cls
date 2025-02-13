/**
    * Author: Midhuna KB
    * Date: 02/02/2021
    * Desc: Batch to update contact records               
    **/
    public with sharing class NPSSurveyBatch implements Database.Batchable<sObject> {
        public Database.QueryLocator start(Database.BatchableContext bc) {
            //Query for active NPS settings
            //put their categories into a list to query for those contacts
            List<String> list_NPSCats = new List<String>();
            List<NPS_Survey_Setting__mdt> list_NPSSetting = [SELECT Customer_Category__c, Months_until_next_survey__c FROM NPS_Survey_Setting__mdt WHERE Is_Active__c = TRUE];
            for (NPS_Survey_Setting__mdt objNPS : list_NPSSetting) {
                list_NPSCats.add(objNPS.Customer_Category__c);
            }
            
            String strQuery = 'SELECT Id, NPS_Survey_Criteria__c, NPS_Status__c, NPS_Survey_Date__c,'+
                                ' Account.RecordTypeId, NPS_Customer_Category_Formula__c, '+
                                ' Account.Joined_Date_Panda__c, Account.Cohort_Date__c '+
                                ' FROM Contact '+
                                ' WHERE NPS_Customer_Category_Formula__c IN :list_NPSCats '+
                                ' AND (NPS_Survey_Date__c = TODAY '+
                                ' OR (NPS_Survey_Date__c = null '+
                                ' AND ( '+
                                '   (Account.Joined_Date_Panda__c >= TODAY AND Account.RecordType.Name = \'Company\') '+ 
                                '   OR (Account.Cohort_Date__c >= TODAY AND Account.RecordType.Name = \'Reseller\') '+
                                '   )))';

            return Database.getQueryLocator(strQuery);
        }

        public void execute(Database.BatchableContext bc, List<Contact> scope) {
            //Associate categories with their months 
            List<NPS_Survey_Setting__mdt> list_NPSSetting = [SELECT Customer_Category__c, Months_until_next_survey__c FROM NPS_Survey_Setting__mdt WHERE Is_Active__c = TRUE];
            Map<String, Decimal> map_NPSCategoryToMonths = new Map<String, Decimal>();
            if (!list_NPSSetting.isEmpty()) {
                for (NPS_Survey_Setting__mdt objNPS : list_NPSSetting) {
                    map_NPSCategoryToMonths.put(objNPS.Customer_Category__c, objNPS.Months_until_next_survey__c);
                }

                /**
                 * for each contact, 
                 * if NPS_Survey_Criteria__c is true, set NPS_Status__c to Queued
                 * else, set NPS_Status__c to Doesn't meet criteria
                 * if Contact's category is a key in map_NPSCategoryToMonths, then set NPS_Survey_Date__c to today + that category's Months_until_next_survey__c
                 */
                List<Contact> list_Contacts = new List<Contact>();

                for (Contact objContact : scope) {               
                    if (objContact.NPS_Survey_Date__c == null) {
                        if (map_NPSCategoryToMonths.containsKey(objContact.NPS_Customer_Category_Formula__c)) {
                            objContact.NPS_Survey_Date__c = AccountUtil.populateSurveyRandomDate(objContact);
                            list_Contacts.add(objContact);
                        }                       
                    } else {
                        if (objContact.NPS_Survey_Criteria__c == true) {
                            objContact.NPS_Status__c = 'Queued';
                        } else {
                            objContact.NPS_Status__c = 'Doesn\'t meet criteria';
                        }

                        if (map_NPSCategoryToMonths.containsKey(objContact.NPS_Customer_Category_Formula__c)) {
                            objContact.NPS_Survey_Date__c = System.today().addMonths((Integer) map_NPSCategoryToMonths.get(objContact.NPS_Customer_Category_Formula__c));
                        }
                        list_Contacts.add(objContact);
                    }                
                }
                if (!list_Contacts.isEmpty()) {
                    try {
                        ContactTriggerHelper.skipTrigger = true; 
                        update list_Contacts;
                    } catch(Exception objException) {
                        ExceptionLogUtil.logException('NPSSurveyBatch', 'execute', objException.getMessage(), objException.getStackTraceString());
                    }
                }
            }
        }

        public void finish(Database.BatchableContext bc) {
        }
    }