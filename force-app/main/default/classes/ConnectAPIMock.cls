/**
 * @name         : ConnectAPIMock
 * @author       : Alex Xiong
 * @date         : 03-03-2021
 * @description  : Mocking ConnectAPI results in test classes.
 * @test classes : CaseMassUpdateLightningControllerTest
 **/
global class ConnectAPIMock {
	global static Integer getFeedCount() {
		ConnectApi.FeedElementPage elements = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(
			null,
			ConnectApi.FeedType.RECORD,
			'me'
		);
		return elements.elements.size();
	}
}