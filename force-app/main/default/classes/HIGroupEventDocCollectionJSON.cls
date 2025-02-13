/**
 * @name         HIGroupEventDocCollectionJSON
 * @author       Deepika Saini
 * @date         02-11-2021
 * @description  JSON structure for HIGroupEvent.Event_Info for document_collection_status events
 * @test classes HIGroupEventDocCollectionStatusTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class HIGroupEventDocCollectionJSON {
	public String event_id;
	public String company_id;
	public String application_id;
	public String application_type;
	public String event_type;
	public String documents_status;
	public String created_at;
}