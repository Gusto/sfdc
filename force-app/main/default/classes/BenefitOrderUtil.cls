/**
    Created by : Praveen Sethu
    Created Date : 10/28/2020
    Description: Benefit Order related Utilities for reuse
**/
public class BenefitOrderUtil {
	public static final String STATUS_APPROVED = 'Approved';
	public static final String STATUS_APPROVED_PENDING_EE_AUDIT = 'Approved Pending EE Audit';
	public static final String STATUS_FULFILLED = 'Fulfilled';
	public static final String STATUS_CLOSED_ADMIN = 'Closed Admin';
	public static final String STATUS_CANCELLED = 'Canceled';
	public static final String STATUS_CLOSED_LOST = 'Closed Lost';
	public static final String STATUS_DENIED = 'Denied';
	public static final String STATUS_ALIGNEMENT_DENIED = 'Alignment Denied';
	public static final String STATUS_ALIGNEMENT_APPROVED_POST_RENEWAL = 'Alignment Approved Post Renewal';
	public static final String STATUS_ALIGNEMENT_APPROVED = 'Alignment Approved';
	public static final String STATUS_BLOCKED = 'Blocked';
	public static final String STATUS_QUALIFICATION = 'Qualification';
	public static final String STATUS_READY_FOR_QUALIFICATION = 'Ready for Qualification';
	public static final String STATUS_READY_FOR_OE_PREP = 'Ready for OE Prep';
	public static final String ORDER_TYPE_TERMINATED_ORDER = 'Terminated Order';
	public static final String BO_STAGE_DETAIL_READY_FOR_TADA_SETUP = 'Ready for TAdA Setup';
	public static final String STATUS_PENDING_ER_SIGNATURE = 'Pending ER Signature';

	public static final String OPPTY_BENEFITS_SETUP_AWAIT_OFFERINGS_STEP = 'Awaiting Offerings';
	public static final List<String> COMPLETED_ORDER_STATUSES = new List<String>{
		STATUS_FULFILLED,
		STATUS_CANCELLED,
		STATUS_CLOSED_LOST,
		STATUS_CLOSED_ADMIN
	};

	public static Set<String> set_ClosedOrderStatusForBOAndAlignementBO = new Set<String>{
		STATUS_DENIED,
		STATUS_CANCELLED,
		STATUS_CLOSED_ADMIN,
		STATUS_ALIGNEMENT_APPROVED,
		STATUS_ALIGNEMENT_DENIED,
		STATUS_ALIGNEMENT_APPROVED_POST_RENEWAL
	};

	public static Set<String> set_ClosedOrderStatusForBO = new Set<String>{
		STATUS_CANCELLED,
		STATUS_CLOSED_ADMIN,
		STATUS_CLOSED_LOST
	};

	public static Set<String> set_ClosedOrderStatusForBOToShowData = new Set<String>{
		STATUS_BLOCKED,
		STATUS_APPROVED,
		STATUS_CLOSED_LOST,
		STATUS_FULFILLED,
		STATUS_CLOSED_ADMIN,
		STATUS_CANCELLED
	};
	// Record Type Ids
	public static final Id RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID = Cache.getRecordTypeId(
		'Benefit_Order__c',
		'Renewal Alignment'
	);
	public static final Id RENEWAL_BENEFIT_ORDER_RT_ID = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
	public static final Id CHANGE_BENEFIT_ORDER_RT_ID = Cache.getRecordTypeId('Benefit_Order__c', 'Change');
	public static final Id BOR_BENEFIT_ORDER_RT_ID = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
	public static final Id NEW_PLAN_BENEFIT_ORDER_RT_ID = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
	public static final Id BYB_BENEFIT_ORDER_RT_ID = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BYB');

	public static final String RENEWAL_QA_SHEET_RT_NAME = 'Benefit_Renewal';
	public static final String NEW_PLAN_QA_SHEET_RT_NAME = 'Benefit_New_Plan';
	public static final String CHANGE_QA_SHEET_RT_NAME = 'Benefit_Change';

	public static final String BENEFIT_ORDER_RT_NEW_PLAN = 'New Plan';
	public static final String BENEFIT_ORDER_RT_RENEWAL = 'Renewal';
	public static final String BENEFIT_ORDER_RT_CHANGE = 'Change';
	public static final String BENEFIT_ORDER_RT_BENEFITS_BOR = 'Benefits BoR';
	public static final String BENEFIT_ORDER_RT_RENEWAL_ALIGNMENT = 'Renewal Alignment';

	public static final String MSQ_CLOSE_OPEN_TICKET_FIRST = 'There is an open ticket associated to this order. Please ensure all tickets are closed before Fulfilling/Canceling order';
	public final static String QUEUE_PREFIX = '00G';
	public static final Id LOGGED_IN_USER_ID = UserInfo.getUserId();
	public static final String  BYB_RENEWAL = 'BYB Renewal';
	public static final String STATUS_READY_FOR_INTRO = 'Ready for Intro';
	public static final String PRIORITY_REASON_EFFECTIVE_DATE = 'Upcoming Effective Date';

	//Tiers
	public static Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
	public static String strCORE =  objTierConfig.Old_Tier_1__c;
	public static String strCOMPLETE =  objTierConfig.Old_Tier_2__c;
	public static String strCONCIERAGE = objTierConfig.Old_Tier_3__c;
	public static String strSIMPLE = objTierConfig.New_Tier_1__c;
	public static String strPLUS = objTierConfig.New_Tier_2__c;
	public static String strPLUS_AND_SUPPORT_PRIOR = 'Plus & Priority Support';
	public static final String BO_ORDER_TYPE_BOR = 'BOR';
	public static final String BO_ORDER_TYPE_BOR_AND_TADA = 'BOR + TAdA';
	public static final String BO_ORDER_TYPE_BOR_TADA_ONLY = 'BOR TAdA Only';

    //Integration ID for BO Cases
    public static final String BO_CASE_INTEGRATION_ID_BYB = 'hippo-Benefits_BYB-';


	/**
	 * @Author      : Deepika Saini
	 * @Description : fetch the open Tickets related to BenefitOrder
	 * @Parm        : set_BenefitOrdersId : set of Benefit Orders Id
	 * @Return      : list of ticket
	 **/
	public static Map<Id, Ticket__c> fetchOpenTicketsRelatedToBO(Set<Id> set_BenefitOrdersId) {
		Map<Id, Ticket__c> map_OpenTicketsWithBO = new Map<Id, Ticket__c>();
		String strTicketQuery = '';

		if (!set_BenefitOrdersId.isEmpty()) {
			for (Ticket__c objTicket : [
				SELECT Id, Benefit_Order__c
				FROM Ticket__c
				WHERE
					Benefit_Order__c != NULL
					AND Status__c != NULL
					AND Benefit_Order__c IN :set_BenefitOrdersId
					AND Status__c != :TicketUtil.TICKET_STATUS_CLOSED
					AND RecordTypeId IN :TicketUtil.set_BenefitsOnboardingRelatedTickets
			]) {
				if (
					!map_OpenTicketsWithBO.isEmpty() &&
					map_OpenTicketsWithBO.containsKey(objTicket.Benefit_Order__c)
				) {
					continue;
				}
				map_OpenTicketsWithBO.put(objTicket.Benefit_Order__c, objTicket);
			}
		}

		return map_OpenTicketsWithBO;
	}
}