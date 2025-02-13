/**
Created by : Aurobind Ravichandran
Created Date : 5/10/2019
Purpose : Class is used in the NPRNOrderNotificationComponent which is used in
            in the email template when a benefit order is created for New Plan or Renewed Fulfillment
**/
public class NPRNOrderNotificationComponentController {
    //variables set to pass values to component
    public Id caseRecordId { get; set; }
	public Id oppId { get; set; }
	public Date oppEffDate { get; set; }
	public String conName { get; set; }
	public String benefitOwnerName { get; set; }
	public String waitingPeriod { get; set; }
	public Integer medicalCarrierSubmissionDays { get; set; }
	public Integer noOfCarriers { get; set; }
	public String tags { get; private set; }
	public boolean renewalMinimumDaysMet { get; private set; }
	public boolean blnIsSpecialEnrolled { get; set; }
	public boolean blnIsRenewalSpecialistAssigned { get; set; }
	public boolean blnIsAdvisingIncludedInSignature { get; set; }
	public static Configuration_Settings__c objConfig { get; set; }
	public static String RENEWAL_MACRO { get; set; }
	public static String NEWPLAN_MACRO { get; set; }

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Reterive custom setting and email macro.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static {
		objConfig = Utils.ORG_WIDE_CONFIG_SETTINGS;
		RENEWAL_MACRO = 'RENEWAL_END_OF_YEAR';
		NEWPLAN_MACRO = 'NEWPLAN_END_OF_YEAR';
		for (Email_Macro__c objEM : [
			SELECT Body__c, Macro_Identifier__c
			FROM Email_Macro__c
			WHERE
				Macro_Identifier__c != null
				AND (Macro_Identifier__c = :RENEWAL_MACRO
				OR Macro_Identifier__c = :NEWPLAN_MACRO)
		]) {
			if (objEM.Macro_Identifier__c.equalsIgnoreCase(RENEWAL_MACRO)) {
				RENEWAL_MACRO = objEM.Body__c;
			} else if (objEM.Macro_Identifier__c.equalsIgnoreCase(NEWPLAN_MACRO)) {
				NEWPLAN_MACRO = objEM.Body__c;
			}
		}
	}
    
    /**
     * Constructor 
     **/
    public NPRNOrderNotificationComponentController(){
        renewalMinimumDaysMet = false;
        blnIsSpecialEnrolled = false;
        blnIsRenewalSpecialistAssigned = false;
        blnIsAdvisingIncludedInSignature = false;
    }
    
    /**
     * Method to return opportunity information to display conditional logic in the component 
     **/
    public Opportunity getOpp(){
        Opportunity opp = new Opportunity();
        if(oppId!=NULL){
            //DS[29-09-2020]: https://app.asana.com/0/1195411211351298/1195479036025509
            opp = [
                SELECT
                    Id,
                    Owner.FirstName,
                    RecordType.Name,
                    HI_Effective_Date__c,
                    Owner_Role_Name__c,
                    OwnerId,
                    (
                        SELECT Id, Special_Enrollment__c, OwnerId
                        FROM Benefit_Orders__r
                        WHERE
                            RecordType.Name IN (
                                :BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN,
                                :BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL
                            )
                    )
                FROM Opportunity
                WHERE Id = :oppId
            ];

            Date effDate = opp.HI_Effective_Date__c;

            //For renewal if difference between current date and effective date is > or < different contenet is displayed in the component
            if((effDate-21) > system.today()){
                renewalMinimumDaysMet = true;
            } else {
                renewalMinimumDaysMet = false;
            }

            if (opp.Benefit_Orders__r != null && opp.Benefit_Orders__r.size() > 0) {
                if (opp.Benefit_Orders__r[0].Special_Enrollment__c != null) {
                    blnIsSpecialEnrolled = opp.Benefit_Orders__r[0].Special_Enrollment__c;
                }

                if (
                    String.isNotBlank(opp.Owner_Role_Name__c) &&
                    opp.Owner_Role_Name__c == FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST
                ) {
                    blnIsRenewalSpecialistAssigned = true;
                } else if (
                    String.isBlank(opp.Owner_Role_Name__c) ||
                    (String.isNotBlank(opp.Owner_Role_Name__c) &&
                    opp.Owner_Role_Name__c == FWManageRoleUtil.ROLE_BENEFITS_DESIGNER)
                ) {
                    blnIsAdvisingIncludedInSignature = true;
                }
            }
        }
        getPolicyInfoList();
        
        return opp;
    }
    
    /**
     * Method to return a list of object to display plans by carrier and benefit type 
     * Method creates a nested list of Benefit Type > carrier > plan list
     **/
    public List<BenefitTypePolicyInfo> getPolicyInfoList(){
        map<String,BenefitTypePolicyInfo> benPolicyMap= new map<string,BenefitTypePolicyInfo>();
        Set<String> carrierSet = new Set<String>();
        if(oppId!=NULL){
            boolean medicalProcessed = false;
            //benTypePolicyList = new List<BenefitTypePolicyInfo>();
            List<Policy__c> polList = new List<Policy__c>([Select id,Carrier_Order__r.Benefit_Order__r.Owner.Name,Is_Base__c,Contribution_for_EEs__c,Contribution_Scheme_Type__c,Contribution_for_Dependents__c,Is_Selected__c,Name,Coverage_Effective_Date__c,Expiration_Date__c,Carrier__r.Name,Plan_Type__c,Benefit_Type__c,Carrier_Order__r.Submission_Deadline__c,Opportunity__r.HI_Effective_Date__c,Carrier__r.PY_or_CY_Deductible__c, Waiting_Period__c FROM Policy__c WHERE Is_Selected__c=TRUE and Opportunity__c=:oppId order by Benefit_Type__c ASC,Is_Base__c Desc ]);
            //gets the tags for display logic for principal and beam
            tags += getTags(polList);
            for(Policy__c policy:polList){
                //variable for display logic if if more carriers exist
                carrierSet.add(policy.Carrier__r.Name);
                //declare a variable and get the value if it exists 
                BenefitTypePolicyInfo policyInfo = new BenefitTypePolicyInfo();
                if(benPolicyMap.containsKey(policy.Benefit_Type__c)){
                    policyInfo = benPolicyMap.get(policy.Benefit_Type__c);
                }
                policyInfo.benefitType = policy.Benefit_Type__c;
                //create a list of carrier plans for each benefit type
                List<CarrierPlanInfo> carrierPlans = new List<CarrierPlanInfo>();
                if(policyInfo.carrierPlans!=null){
                    carrierPlans = policyInfo.carrierPlans;
                }
                // this is a critical variable to prevent duplicate carrier plans from being added
                boolean carrierExists = false;
                CarrierPlanInfo carPlan = new CarrierPlanInfo();
                carPlan.numberOfPlans=0;
                for(CarrierPlanInfo cPlanInfo : carrierPlans){
                    if(cPlanInfo.CarrierName==policy.Carrier__r.Name){
                        carPlan = cPlanInfo;
                        carrierExists = true;
                    }
                }
                carPlan.CarrierName = policy.Carrier__r.Name;
                List<String> plansList = new List<String>();
                if(carPlan.plansList!=null){
                    plansList = carPlan.plansList;
                }
                plansList.add(policy.Name);
                carPlan.plansList = plansList;
                if(carPlan.numberOfPlans<plansList.size()){
                    carPlan.numberOfPlans = plansList.size();
                }
                carPlan.waitingPeriod = policy.Waiting_Period__c;
                // For medial alone we just need to set the values if it is a base plan
                // For rest of the benefit types base plan check is not needed.
                //if( (policy.Benefit_Type__c=='Medical' && policy.Is_Base__c==true) || policy.Benefit_Type__c!='Medical' ){
                if( (policy.Benefit_Type__c=='Medical' && medicalProcessed==false) || policy.Benefit_Type__c!='Medical' ){
                    if(policy.Benefit_Type__c=='Medical'){
                        carPlan.basePlanName=policy.Name;
                        medicalProcessed = true;
                    }
                    carPlan.contributionScheme = policy.Contribution_Scheme_Type__c;
                    carPlan.employeeContribution = policy.Contribution_for_EEs__c;
                    carPlan.dependentContribution = policy.Contribution_for_Dependents__c;
                    carPlan.py_dy_deductible = policy.Carrier__r.PY_or_CY_Deductible__c;
                    carPlan.carrierSubmissionDeadlineDays=0;
                    if(policy.Carrier_Order__r.Submission_Deadline__c!=null){
                        carPlan.carrierSubmissionDeadlineDays=policy.Carrier_Order__r.Submission_Deadline__c.daysBetween(system.today());
                        if(policy.Benefit_Type__c=='Medical'){
                            medicalCarrierSubmissionDays = carPlan.carrierSubmissionDeadlineDays;
                        }
                    }
                    if(policy.Benefit_Type__c=='Flexible Spending Account - Medical' || policy.Benefit_Type__c=='Flexible Spending Account - Dependent Care'){
                        policyInfo.benefitType='FSA/DCA';
                        benPolicyMap.put('FSA/DCA',policyInfo);
                    } else {
                        benPolicyMap.put(policy.Benefit_Type__c,policyInfo);
                    }
                }
                //check is needed so that we dont add the plans for the carrier again and again
                if(carrierExists==false){
                    carrierPlans.add(carPlan);
                }
                policyInfo.carrierPlans = carrierPlans;
                
                
                
            }
            
        }
        noOfCarriers = carrierSet.size();
        return benPolicyMap.values();
    }    
    
    /**
     * Method to return tags given the policy list
     * Tags are used to conditional render data in the component
     **/
    private String getTags(List<Policy__c> polList){
        String tags='';
        Set<String> principalBenTypeSet = new Set<String>();
        Set<String> beamBenTypeSet = new Set<String>();
        for(Policy__c pol : polList){
            String carrierName = pol.Carrier__r.Name;
            if(carrierName.indexOf('Principal')==0){
                principalBenTypeSet.add(pol.Benefit_Type__c);
            }
            if(carrierName.indexOf('Beam')==0){
                beamBenTypeSet.add(pol.Benefit_Type__c);
            }
        }
        if(principalBenTypeSet.contains('Vision') && principalBenTypeSet.size()==1 ){
            tags +='PrincipalVisionOnly;';
        } else if(principalBenTypeSet.contains('Vision') && principalBenTypeSet.size()>1 ){
            tags +='PrincipalVisionAndOtherBenTypes;';
        }
        if(principalBenTypeSet.size()>0 && principalBenTypeSet.contains('Dental')){
            tags +='PrincipalDental;';
        }
        if(beamBenTypeSet.size()>0 && beamBenTypeSet.contains('Dental')){
            tags +='BeamDental;';
        }
        if(beamBenTypeSet.size()>0 && beamBenTypeSet.contains('Vision')){
            tags +='BeamVision;';
        }
        return tags;
    }
    
    /**
     * Inner class to define the nested structure of benefit type, carrier and plan list
     **/
    public class BenefitTypePolicyInfo {
        public String benefitType{get; set;}
        public List<CarrierPlanInfo> carrierPlans{get; set;}
    }
    
    public class CarrierPlanInfo{
        public String carrierName{get; set;}
        public List<String> plansList{get; set;}
        public String contributionScheme{get; set;}
        public String employeeContribution{get; set;}
        public String dependentContribution{get; set;}
        public String basePlanName{get; set;}
        public Integer numberOfPlans{get; set;}
        public String py_dy_deductible{get; set;}
        public String waitingPeriod{get; set;}
        public Integer carrierSubmissionDeadlineDays{get; set;}
    }   

}