/**
 *  @author Sahil Goyal
 *  @since 11/20/2024
 *  @version 1.0
 *  @description Test class for CaseEmailAutoSolveAIQueueable
 **/
@isTest
public class CaseEmailAutoSolveAIQueueableTest {
        @TestSetup
        static void setup() {
                //Engagement case created to cover the code of BTE-4057
                Case testCase = new TestDataFactory.CaseBuilder()
                        .setRecordTypeId('Engagement')
                        .setType('Benefits')
                        .setSubject('Inc’s payroll will be blocked in 13 days')
                        .setOrigin('Email')
                        .setDirection('Inbound')
                        .setStatus('New')
                        .setSuppliedEmail('test2@gusto.com')
                        .setDescription(
                                'Hello Test! I am hoping you are able to help me out. Our payroll for the end of the month is blocked until this issue is resolved. While we do have a little time!'
                        )
                        .build();

                insert testCase;

                // Set up custom settings
                Chima_AI_Config__c config = new Chima_AI_Config__c(
                        Mulesoft_AI_Email_AutoSolve_Endpoint__c = 'https://testendpoint.com',
                        Mulesoft_Authorization__c = EncodingUtil.base64Encode(Blob.valueOf('username:password'))
                );
                insert config;
        }

        @isTest
        static void testExecuteWithValidResponse() {
                // Fetch the Case record
                Case testCase = [SELECT Id FROM Case LIMIT 1];

                // Set up HTTP mock
                Test.setMock(HttpCalloutMock.class, new CaseEmailAutoSolveAIQueueableTest.MockHttpResponseGenerator());

                // Enqueue the Queueable class
                Test.startTest();
                System.debug('testCase.Id: ' + testCase.Id);
                System.enqueueJob(new CaseEmailAutoSolveAIQueueable(testCase.Id));
                Test.stopTest();

                // Assert that the InternalAISolveEmailConversation__c record was created
                InternalAISolveEmailConversation__c emailConversation = [SELECT Case__c FROM InternalAISolveEmailConversation__c WHERE Case__c = :testCase.Id];
                System.assertNotEquals(null, emailConversation, 'InternalAISolveEmailConversation__c record should be created.');
                System.assertEquals(testCase.Id, emailConversation.Case__c, 'The Case__c field should match the test Case ID.');
        }

        @isTest
        static void testExecuteWithErrorResponse() {
                // Fetch the Case record
                Case testCase = [SELECT Id FROM Case LIMIT 1];

                // Set up HTTP mock for an error response
                Test.setMock(HttpCalloutMock.class, new CaseEmailAutoSolveAIQueueableTest.MockHttpErrorResponseGenerator());

                // Enqueue the Queueable class
                Test.startTest();
                System.enqueueJob(new CaseEmailAutoSolveAIQueueable(testCase.Id));
                Test.stopTest();

                // Assert that no InternalAISolveEmailConversation__c record was created
                List<InternalAISolveEmailConversation__c> conversations = [SELECT Case__c, Use_Case__c FROM InternalAISolveEmailConversation__c WHERE Case__c = :testCase.Id];
                System.assertEquals(0, conversations.size(), 'No InternalAISolveEmailConversation__c record should be created for an error response.');

                List<Exception_Log__c> expLog = [SELECT Id, Record_ID__c FROM Exception_Log__c];
                System.assertEquals(false, expLog.isEmpty(), 'Exception_Log__c record should be created for an error response.');
        }

        @isTest
        static void testExecuteWithNonExistentCase() {
                // Enqueue the Queueable class with a non-existent Case ID
                Test.startTest();
                System.enqueueJob(new CaseEmailAutoSolveAIQueueable('5008C000005KauMQAS'));
                Test.stopTest();

                // No assertion needed for database as there are no records to verify; log validation can be done via ExceptionLogUtil test.
        }

        // Mock HTTP response for a valid response
        private class MockHttpResponseGenerator implements HttpCalloutMock {
                Id testCaseId = [SELECT Id FROM Case LIMIT 1].Id;

                public HTTPResponse respond(HTTPRequest req) {
                        HttpResponse res = new HttpResponse();
                        res.setStatusCode(200);
                        res.setBody(
                                '{ "avg_questions_similarities": 0.6675377345773638, "case_id": "' +
                                        testCaseId +
                                        '", "contact_classification": "Contact Support", "contact_classification_explanation": "The email indicates a potentially urgent issue with payroll being blocked", "creation_timestamp": "2024-09-18T17:1113.000+0000", "execution_time": 30.133455753326416, "first_user_email": "Inc’s payroll will be blocked in 13 days Hello Test! I am hoping you are able to help me out. Our payroll for the end of the month is blocked until this issue is resolved. While we do have a little time!", "max_questions_similarities": 0.751000003921088, "request_summary": "The user is seeking assistance to resolve an issue that is blocking their payroll for the end of the month. They need help to address this problem before the payroll deadline in 13 days.", "response": "If your payroll is blocked due to insufficient funds, Log in to your Gusto account. 2. Check for any notifications on your Home page that indicate payroll is blocked due to insufficient funds. Check Bank Account", "response_confidence": 5, "response_explanation": "The selected sections provide a comprehensive guide to resolving a payroll blockage due to insufficient funds, which aligns with the users intent to resolve the issue before the payroll deadline.", "response_perplexity_score": 1.065798163332142, "return_response": true, "selected_recipes": [ "blocked_payroll" ], "specific_intent": "Resolution of payroll blockage issue before the end of the month deadline", "use_case": "Resolve Payroll Blockage Issue", "use_macro": "YES", "valid_request": "valid_request", "valid_request_explanation": "The email contains a request for assistance with an issue related to payroll being blocked." }'
                        );
                        return res;
                }
        }

        // Mock HTTP response for an error response
        private class MockHttpErrorResponseGenerator implements HttpCalloutMock {
                public HTTPResponse respond(HTTPRequest req) {
                        HttpResponse res = new HttpResponse();
                        res.setStatusCode(401);
                        res.setBody('{"error": "Authentication denied."}');
                        return res;
                }
        }
}