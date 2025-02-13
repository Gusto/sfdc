public class BORAdditionalInformationJSON{
    public cls_administrators administrators;
    public String title;	//President
    public Integer effective_month;	//1
    public String effective_month_same_as_medical;	//yes
    public class cls_administrators {
        public String fsa;	//Zenefits
        public String dca;	//Zenefits
        public String hsa;	//Zenefits
        public String commuter;	//Zenefits
    }
    public static BORAdditionalInformationJSON parse(String json){
        return (BORAdditionalInformationJSON) System.JSON.deserialize(json, BORAdditionalInformationJSON.class);
    }
}