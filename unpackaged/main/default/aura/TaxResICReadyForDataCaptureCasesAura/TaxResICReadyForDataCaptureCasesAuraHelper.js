({
	pollLWC : function(component, event, helper) {     
        //execute callApexMethod() again after 5 sec each   
        window.setInterval(helper.callLWCMethod(component), 
            5000); 
    },
    callLWCMethod : function (component){    
        component.find('lwcICCases').getCaseDetails();
    }
})