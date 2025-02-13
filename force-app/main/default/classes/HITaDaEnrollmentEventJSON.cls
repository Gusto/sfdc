public class HITaDaEnrollmentEventJSON {
	public String error_message;
	public EnrollmentInfo enrollment;
	public RecentQLEInfo[] recent_qles;
	public HIEnrollmentEventUtility.EnrollmentSourceInfo enrollment_source;
	public HIEnrollmentEventUtility.CompanyInfo company;
	public HIEnrollmentEventUtility.DependentInfo[] dependents;
	public String benefits_url;
	public String enrollments_url;
	public TadaInfo tada;
	public HIEnrollmentEventUtility.EmployeeInfo employee;

	public class EnrollmentSource {
		public String type;
		public String event_type;
		public String file_upload_urls;
	}

	public class TadaInfo {
		public FSAInfo fsa;
		public FSAInfo dca;
		public HSAInfo hsa;
	}

	public class FSAInfo {
		public BenefitItem benefit_items;
		public Policy[] policies;
		public String provider_key;
	}

	public class HSAInfo {
		public HSASelection hsa_selection;
		public HSABenefit hsa_benefit;
		public String provider_key;
	}

	public class HSABenefit {
		public String benefit_type;
		public Long id;
		public String name;
		public Long company_id;
		public String effective_date;
		public String expiration_date;
		public String status;
		public String url;
	}

	public class BenefitItem {
		public SubscriptionInfo current;
		public List<SubscriptionInfo> overlapping;
		public List<SubscriptionInfo> previous;
	}

	public class Policy {
		public Long id;
		public String name;
		public String benefit_type;
		public Long company_alegeus_id;
		public Boolean visible;
		public String termination_policy;
		public String url;
		public String uuid;
	}

	public class HSASelection {
		public Long id;
		public Long employee_id;
		public Long hsa_benefit_id;
		public Double max_countribution_cents;
		public String url;
		public String uuid;
		public String effective_date;
		public String ops_owner;
	}

	public class SubscriptionInfo {
		public Long id;
		public Long policy_id;
		public String benefit_type;
		public String start_date;
		public String end_date;
		public String processing_status;
		public Long enrollment_id;
		public Long employee_id;
		public Long employee_alegeus_id;
		public Set<String> dependent_ids;
		public String url;
		public String uuid;
		public String estimated_start_date;
		public String ops_owner;
	}

	public class EnrollmentInfo {
		public Long id;
		public Long employee_id;
		public String url;
	}

	public class RecentQLEInfo {
		public Long id;
		public String event;
		public String date_of_event;
		public String[] file_upload_urls;
		public String url;
	}
}