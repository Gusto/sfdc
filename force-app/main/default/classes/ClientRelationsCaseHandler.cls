/**
 * Author: Aslam Juneid
 * Description: Handles the logics for Client Relations cases.
 */
public class ClientRelationsCaseHandler {

    /**
     * Author: Aslam Juneid
     * Description: Creates a new Client Relations Case based on the provided email message, case, and owner ID.
     * @param objEmailMessage - The email message containing case details.
     * @param objCase - The existing case to associate with.
     * @param ownerId - The ID of the user to assign the new case to.
     * @return Case - The newly created Client Relations Case.
     */
    public static Case getClientRelationsCase(EmailMessage objEmailMessage, Case objCase, Id ownerId) {
        return new Case(
            Subject = getCaseSubject(objEmailMessage.Subject),
            Description = objEmailMessage.TextBody,
            Origin = 'Email',
            Status = 'New',
            AccountId = objCase.AccountId,
            ContactId = objCase.ContactId,
            Escalation_Channel__c = 'NPS Detractor',
            OwnerId = ownerId,
            RecordTypeId = EmailMessageUtil.RECTYPE_CLIENT_RELATIONS
        );
    }

    /**
     * Author: Aslam Juneid
     * Description: Checks if the provided email message and case qualify for creating a Client Relations Case.
     * @param objEmailMessage - The email message to check.
     * @param objCase - The case to check.
     * @return Boolean - True if qualified, otherwise false.
     */
    public static Boolean isQualified(EmailMessage objEmailMessage, Case objCase) {
        return isSubjectQualified(objEmailMessage) &&
               isIncoming(objEmailMessage) &&
               hasParentId(objEmailMessage) &&
               isCaseQualified(objCase) &&
               isSentToClientRelations(objEmailMessage);
    }

    /**
     * Author: Aslam Juneid
     * Description: Checks if the email subject contains a valid reference.
     * @param objEmailMessage - The email message to check.
     * @return Boolean - True if the subject is qualified, otherwise false.
     */
    static Boolean isSubjectQualified(EmailMessage objEmailMessage) {
        return String.isNotBlank(objEmailMessage.Subject) &&
               objEmailMessage.Subject.contains('ref:');
    }

    /**
     * Author: Aslam Juneid
     * Description: Checks if the email is sent to the Client Relations email address.
     * @param objEmailMessage - The email message to check.
     * @return Boolean - True if the email is sent to Client Relations, otherwise false.
     */
    static Boolean isSentToClientRelations(EmailMessage objEmailMessage) {
        return objEmailMessage.ToAddress != null && objEmailMessage.ToAddress.contains(Label.Client_Relations_Email);
    }

    /**
     * Author: Aslam Juneid
     * Description: Checks if the email message is incoming.
     * @param objEmailMessage - The email message to check.
     * @return Boolean - True if the email is incoming, otherwise false.
     */
    static Boolean isIncoming(EmailMessage objEmailMessage) {
        return objEmailMessage.Incoming;
    }

    /**
     * Author: Aslam Juneid
     * Description: Checks if the email message has a parent case ID.
     * @param objEmailMessage - The email message to check.
     * @return Boolean - True if the email has a parent ID, otherwise false.
     */
    static Boolean hasParentId(EmailMessage objEmailMessage) {
        return objEmailMessage.ParentId != null;
    }

    /**
     * Author: Aslam Juneid
     * Description: Checks if the existing case is not already of the Client Relations record type.
     * @param objCase - The case to check.
     * @return Boolean - True if the case is qualified, otherwise false.
     */
    static Boolean isCaseQualified(Case objCase) {
        return objCase.RecordTypeId != EmailMessageUtil.RECTYPE_CLIENT_RELATIONS;
    }

    /**
     * Author: Aslam Juneid
     * Description: Cleans up the email subject by removing reference text in the format [ ref:!<some_id>:ref ].
     * @param emailSubject - The original email subject.
     * @return String - The cleaned email subject.
     */
    static String getCaseSubject(String emailSubject) {

        String updatedSubject = emailSubject;
        // Regular expression to match the pattern [ ref:!<some_id>:ref ]
        Integer startIndex = updatedSubject.indexOf('[ ref:');
        Integer endIndex = updatedSubject.indexOf(':ref ]', startIndex);

        if (startIndex != -1 && endIndex != -1) {
            // Extract the part to be removed
            String refText = updatedSubject.substring(startIndex, endIndex + 6);
            // Remove the reference text from the subject
            updatedSubject = updatedSubject.replace(refText, '').trim();
        }
        return updatedSubject;
    }
}