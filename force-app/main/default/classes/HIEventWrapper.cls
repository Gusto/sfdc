public class HIEventWrapper {
	public string jsonString;
    public Sobject objHiGroupEvent;
    
    public HIEventWrapper(String jsonString,Sobject objHiGroupEvent){
        this.jsonString=jsonString;
        this.objHiGroupEvent=objHiGroupEvent;
    }
}