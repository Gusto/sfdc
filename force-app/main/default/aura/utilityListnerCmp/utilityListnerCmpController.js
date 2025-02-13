({
    getAllUtilityInfo: function (component, event, helper) {
        let map_utilityIdToLabelMap = {};
        var utilityBarAPI = component.find("utilitybar");
        var eventHandler = function(response){  
            let utilMap = component.get('v.map_utilityIdToLabelMap');
            if(utilMap) {
                if(utilMap[response.utilityId] === 'Phone' || utilMap[response.utilityId] === 'On Queue' || utilMap[response.utilityId] === 'Available') {
                    var cmpChild = component.find("splitViewListener");
                    if(cmpChild) {
                        cmpChild.openSplitViewMethod();
                    }
                }
            }
        };

        // Iterate over all utilities and create an event handler
        utilityBarAPI.getAllUtilityInfo().then(function (response) {
            response.forEach(eachUtility => {
                map_utilityIdToLabelMap[eachUtility.id] = eachUtility.utilityLabel;
                if(eachUtility.utilityVisible && (eachUtility.utilityLabel === 'Phone' || eachUtility.utilityLabel === 'Available' || eachUtility.utilityLabel === 'On Queue')) {
                    var cmpChild = component.find("splitViewListener");
                    if(cmpChild) {
                        cmpChild.openSplitViewMethod();
                    }
                }
                utilityBarAPI.onUtilityClick({
                    eventHandler: eventHandler,
                    utilityId: eachUtility.id
                }).then(function (result) {
                }).catch(function (error) {
                    console.error('error in utilityListener - get all utility info ', error);
                });
            });
        })
        .catch(function (error) {
            console.error(error);
        });
        component.set('v.map_utilityIdToLabelMap' , map_utilityIdToLabelMap);
    },

    /* Checks if Case Origin is Phone or Chat */
    handleDoInit: function(component, event, helper) {
        // Default Post Tab only on Case Pages on not on LiveChatTranscript
        if(!window.location.href.includes('LiveChatTranscript')) {
            var actionAPI = component.find("quickActionAPI");
            var args = {};
            // Always default to Post Tab irrespe
            args = {actionName: "FeedItem.TextPost", recordId: component.get("v.recordId")};
            actionAPI.selectAction(args).then(function(result){}).catch(function(e){
                if(e.errors){
                    console.error('error in utility listener ', e.errors);   
                }
            }); 
        }
    }
})