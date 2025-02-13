({
    // Checks if the class exist and triggers a click
    handleOpenSplitView : function(component, event, helper) {
        // Open Split View
        let splitViewClass = document.getElementsByClassName('split-toggle slds-split-view__toggle-button slds-is-closed')[0];
        if(splitViewClass) {
            splitViewClass.click();
        }
    }
})