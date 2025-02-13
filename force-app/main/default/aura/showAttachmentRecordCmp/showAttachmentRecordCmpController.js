({
    init: function(cmp, evt, hlp) {
        // getting the pagereference to get the values passed
        var myPageRef = cmp.get("v.pageReference");

        // getting the values 
        var attId = myPageRef && myPageRef.state ? myPageRef.state.c__Id : "";
        var url = myPageRef && myPageRef.state ? myPageRef.state.c__url : "";
        
        // Setting the values in the properties
        cmp.set("v.idRecord", attId);
        cmp.set("v.strUrl", url);
    },
})