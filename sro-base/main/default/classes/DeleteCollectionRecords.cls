global with sharing class DeleteCollectionRecords {
    @InvocableMethod(label='Delete Collection Records [USF Collection Processor]' category='Util' iconName='resource:CollectionProcessorsSVG:colproc')
    global static List <Results> deleteCollectionRecords(List<Requests> requestList) {

        // Infuse the Target colleciton with the Fields in the Source collection 
        List<Results> responseWrapper = new List<Results>();

        // creates a map with Strings as keys, and another Map as value 
        // (this second map has an API Name as key, and an SObjectField as value)
        Map<String, Map<String, SObjectField>> sobjectTypeMap = new Map<String, Map<String, SObjectField>>();

        for (Requests curRequest : requestList) {
            
            // prepare the response
            Results response = new Results();

            // load inputs from request
            List<SObject> sourceCollection = curRequest.sourceCollection;
            List<SObject> targetCollection = curRequest.targetCollection;

            String sourceUniqueID = curRequest.sourceUniqueID;
            String targetUniqueId = curRequest.targetUniqueID;

            // create the output collection
            List<SObject> outputCollection = new List<SObject>();

                    // TEST DATA
                    /*
                    List<SObject> outputCollection = new List<SObject>();

                    List <Product2> targetCollection = new List<Product2>();
                    Product2 prodTarget = new Product2(Name='Test Product 1',ProductCode='TST1',USD__c=1.00);
                    targetCollection.add(prodTarget);
                    System.debug('Target Collection' + targetCollection);

                    List <Product2> sourceCollection = new List<Product2>();
                    Product2 prodSource1 = new Product2(Name='',ProductCode='TST1',EUR__c=4.00,GBP__c=3.00);
                    sourceCollection.add(prodSource1);
                    Product2 prodSource2 = new Product2(Name='',ProductCode='TST2',USD__c=10.00);
                    sourceCollection.add(prodSource2);
                    System.debug('Source Collection' + sourceCollection);

                    // turn api name string into list of fields
                    String fieldsToMask = 'USD__c,EUR__c,GBP__c';
                    Boolean invertMask = false;
                    System.debug('Get Fields: ' + sourceCollection.getSObjectType().getDescribe().fields.getMap().values());

                    //List<String> fieldsToMaskArray = fieldsToMask.replaceAll('[^a-zA-Z0-9\\,\\_\\.]', '').split(',');
                    

                    String sourceUniqueID = 'ProductCode';
                    String targetUniqueID = 'ProductCode';

                    Boolean skipNullValues = true;

                    Map<String, Map<String, SObjectField>> sobjectTypeMap = new Map<String, Map<String, SObjectField>>();
                    */
                    
            if (sourceCollection != null && !sourceCollection.isEmpty() && 
                targetCollection != null && !targetCollection.isEmpty()) {

                Map<String, Sobject> sourceMap = new Map<String, Sobject>();
                string sourceObjectType = string.valueOf(sourceCollection[0].getSObjectType());
                string targetObjectType = string.valueOf(targetCollection[0].getSObjectType());
                
                // add the source collection to the Object Type map 
                if(!sobjectTypeMap.containsKey(sourceObjectType)){
                    Schema.SObjectType s = sourceCollection[0].getSObjectType();
                    Map<String, SObjectField> sourceFieldMap = s.getDescribe().fields.getMap();
                    sobjectTypeMap.put(string.valueOf(s), sourceFieldMap);
                }
                
                // add the target collection to the Object Type map
                if(!sobjectTypeMap.containsKey(targetObjectType)){
                    Schema.SObjectType s = targetCollection[0].getSObjectType();
                    Map<String, SObjectField> sourceFieldMap = s.getDescribe().fields.getMap();
                    sobjectTypeMap.put(string.valueOf(s), sourceFieldMap);
                }

                // load the Source map with the Unique ID for later comparison with the Target map
                if(sobjectTypeMap.containsKey(sourceObjectType)){
                    Schema.SobjectField sourceCurField = sobjectTypeMap.get(sourceObjectType).get(sourceUniqueID);
                    
                    // Loop over the source collection
                    for(sObject sourceRecord : sourceCollection){
                        
                        //grab the value of the Unique ID field
                        String sourceCurrentFieldValue = (String)sourceRecord.get(sourceCurField);
                        
                        //as long as the unique value isnt blank, put it in the sourceMap map to be used later
                        if (sourceCurrentFieldValue != null && sourceCurrentFieldValue != '') {
                            sourceMap.put(sourceCurrentFieldValue, sourceRecord);
                        }
                    }
                }

                // load the Target map with the Unique ID for comparison with the Source map
                if(sobjectTypeMap.containsKey(targetObjectType)){
                            
                    //puts the target collection into a map so we can compare with the source collection
                    Map<String, sObject> targetMap = new Map<String, sObject>();
                    
                    // The key to the map is the api name of the field
                    Schema.SobjectField targetCurField = sobjectTypeMap.get(targetObjectType).get(targetUniqueID);
                    
                    for(sObject targetRecord : targetCollection){
                        String targetCurFieldValue = (String)targetRecord.get(targetCurField);

                        //as long as the unique value isnt blank, put it in the targetMap map to be used later
                        if (targetCurFieldValue != null && targetCurFieldValue != ''){
                            targetMap.put(targetCurFieldValue, targetRecord);
                        }  
                    }

                    // perform operations from the Target collection
                    for(sObject targetRecord : targetCollection){
                        // get the unique ID from the target collection
                        String targetFieldValue = targetRecord.get(targetUniqueID).toString();
                        
                        // if the source collection doesn't have the value, add the target collection record
                        // to the output collection
                        if (!sourceMap.containsKey(targetFieldValue)){
                            outputCollection.add(targetRecord);
                        }
                        
                    }
                }
            }

            response.outputCollection = outputCollection;
            responseWrapper.add(response);
        }

        return responseWrapper;
    }

    global class Requests {
        @InvocableVariable()
        global List<SObject> targetCollection;

        @InvocableVariable(description='The Target Record Unique ID (Field API Name) you want to compare against the Source Unique ID' required=true)
        global String targetUniqueID;  

        @InvocableVariable()
        global List<SObject> sourceCollection;

        @InvocableVariable(description='The Source Record Unique ID (Field API Name) you want to compare against the Target Unique ID' required=true)
        global String sourceUniqueID;
    }

    global class Results {

        public Results() {
            outputCollection = new List<SObject>();
        }
        @InvocableVariable
        global String errors;

        @InvocableVariable
        global List<SObject> outputCollection;
    }
}