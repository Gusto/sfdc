/*
 * Created By   :   Neha
 * Created Date :   19-Nov-2020
 * Description  :   Unit Test for TrackOnboardingActivityOnCaseExt
 */

@isTest
private class TrackOnboardingActivityOnCaseExtTest {

    static testMethod void testUpdateCaseStatusToInProgress(){
        Case objCase = new Case(Status='New',Subject='Testing Case Activity', Priority='Low', RecordTypeId = Cache.getRecordTypeId('Case','Benefits New Plan Case'));
        insert objCase;

        Test.startTest();
            PageReference objRef = new PageReference('/TrackOnboardingActivityOnCase');
            Test.setCurrentPageReference(objRef);
            ApexPages.currentPage().getParameters().put('moveToInProgressId',objCase.Id);
            ApexPages.StandardController objStd = new ApexPages.StandardController(objCase);
            TrackOnboardingActivityOnCaseExt objExt = new TrackOnboardingActivityOnCaseExt(objStd);
            objExt.updateCaseStatusToInProgress();
        Test.stopTest();
        system.assert([SELECT count() FROM Case WHERE Id = :objCase.Id AND Status = 'In Progress'] == 1);
    }
    static testMethod void testUpdateCaseStatusToOpen(){
        Case objCase = new Case(Status='In Progress',Subject='Testing Case Activity', Priority='Low', RecordTypeId = Cache.getRecordTypeId('Case','Benefits New Plan Case'));
        insert objCase;

        Test.startTest();
            PageReference objRef = new PageReference('/TrackOnboardingActivityOnCase');
            Test.setCurrentPageReference(objRef);
            ApexPages.currentPage().getParameters().put('moveToOpenId',objCase.Id);
            ApexPages.StandardController objStd = new ApexPages.StandardController(objCase);
            TrackOnboardingActivityOnCaseExt objExt = new TrackOnboardingActivityOnCaseExt(objStd);
            objExt.updateCaseStatusToOpen();
        Test.stopTest();
        system.assert([SELECT count() FROM Case WHERE Id = :objCase.Id AND Status = 'Open'] == 1);
    }
    static testMethod void testWithoutCaseId(){
        Case objCase = new Case(Status='In Progress',Subject='Testing Case Activity', Priority='Low', RecordTypeId = Cache.getRecordTypeId('Case','Benefits New Plan Case'));
        insert objCase;

        Test.startTest();
            ApexPages.StandardController objStd = new ApexPages.StandardController(objCase);
            TrackOnboardingActivityOnCaseExt objExt = new TrackOnboardingActivityOnCaseExt(objStd);
            objExt.updateCaseStatusToOpen();
            system.assert([SELECT count() FROM Case WHERE Id = :objCase.Id AND Status = 'Open'] == 0);
            objExt.updateCaseStatusToInProgress();
        Test.stopTest();
    }
}