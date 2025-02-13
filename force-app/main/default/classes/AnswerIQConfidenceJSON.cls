public class AnswerIQConfidenceJSON {
	public cls_Confirm_Case_Reason[] Confirm_Case_Reason;
	public class cls_Confirm_Case_Reason {
		public boolean confident;
		public String tag; //Account Access or Password Issue
	}
	public static AnswerIQConfidenceJSON parse(String json) {
		return (AnswerIQConfidenceJSON) System.JSON.deserialize(json, AnswerIQConfidenceJSON.class);
	}
}