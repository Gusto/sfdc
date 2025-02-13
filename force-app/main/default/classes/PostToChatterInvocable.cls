/**
 * @name            : PostToChatterInvocable
 * @author          : Alex Xiong
 * @date            : 03-08-2021
 * @description     : Class for Flows to post chatter messages on records. Uses ConnectAPI to link to other records
 * @test classes    : PostToChatterInvocableTest
 */
public class PostToChatterInvocable {
    /**
     * @Author:			Alex Xiong
     * @Description:	A method used by Flows to post a chatter message on a record. Can include another record to mention.
     * @Parms:			- idRecordTarget: Id of the record to post the chatter on
     * 					- strText: Body of the chatter post.
     * 					- idRecordToMention: Id of the record to mention in the chatter.
     */
    @InvocableMethod(label='Post Chatter' description='Posts a chatter message on a record.')
    public static void postChatter(List<PostToChatterInput> list_Input) {
        List<ConnectApi.BatchInput> list_BatchInputs = new List<ConnectApi.BatchInput>();

        for (PostToChatterInput objInput : list_Input) {
            ConnectApi.FeedItemInput objFeedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MessageBodyInput objMessageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput objTextSegmentInput = new ConnectApi.TextSegmentInput();
            ConnectApi.EntityLinkSegmentInput objEntityLinkSegment = new ConnectApi.EntityLinkSegmentInput();
            
            objMessageBodyInput.MessageSegments = new List<ConnectApi.MessageSegmentInput>();
            objTextSegmentInput.Text = objInput.strText;
            objMessageBodyInput.MessageSegments.add(objTextSegmentInput);

            if (String.isNotBlank(objInput.idRecordToMention)) {
                objEntityLinkSegment.entityId = objInput.idRecordToMention;
                objMessageBodyInput.MessageSegments.add(objEntityLinkSegment);
            }

            objFeedItemInput.Body = objMessageBodyInput;
            objFeedItemInput.FeedElementType = ConnectApi.FeedElementType.FeedItem;
            objFeedItemInput.SubjectId = objInput.idTargetRecord;

            ConnectApi.BatchInput objBatchInput = new ConnectApi.BatchInput(objFeedItemInput);
            list_BatchInputs.add(objBatchInput);
        }

        if (!list_BatchInputs.isEmpty() && !Test.isRunningTest()) {
            ConnectApi.BatchResult[] list_BatchResults = ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), list_BatchInputs);
        }
    }
    
    /**
     * @name            : PostToChatterInput
     * @author          : Alex Xiong
     * @date            : 03-08-2021
     * @description     : Inputs for PostToChatterInvocable.postChatter()
     */
    public class PostToChatterInput {
        @InvocableVariable(label='Target record' description='Id of record to post chatter on')
        public Id idTargetRecord;

        @InvocableVariable(label='Text body' description='Body of the chatter message')
        public String strText;

        @InvocableVariable(label='Record to mention' description='Id of record to mention')
        public Id idRecordToMention;
    }
}