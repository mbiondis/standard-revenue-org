global with sharing class UpsertCollectionRecords {
    @InvocableMethod(label='Upsert Collection Records [USF Collection Processor]' category='Util' iconName='resource:CollectionProcessorsSVG:colproc')
    global static List <Results> upsertCollectionRecords(List<Requests> requestList) {

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

            String fieldsToMask = curRequest.fieldsToMask;
            Boolean invertMask = curRequest.invertMask != null ? curRequest.invertMask : false;
            
            Boolean skipNullValues = curRequest.skipNullValues != null ? curRequest.skipNullValues : false;

            String sourceUniqueID = curRequest.sourceUniqueID;
            String targetUniqueId = curRequest.targetUniqueID;
            
            String actionTypeField = curRequest.actionTypeField;

            // create the output collection
            List<SObject> outputCollection = new List<SObject>();
            List<SObject> updatedCollection = new List<SObject>();
            List<SObject> insertedCollection = new List<SObject>();

                    // TEST DATA
                    /*
                    List<Product2> outputCollection = new List<Product2>();
                    List<Product2> updatedCollection = new List<Product2>();
                    List<Product2> insertedCollection = new List<Product2>();
                    
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
                    String actionTypeField = 'RecordAction__c';

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

                    // turn api name string into list of fields
                    List<String> fieldsToCopy = new List<String>();

                    if(fieldsToMask == null && fieldsToMask == ''){
                        System.debug('Fields to Mask NOT FOUND');
                        //List<String> fieldsToCopy = sourceCollection.getSObjectType().getDescribe().fields.getMap().values();
                    }
                    else{
                        System.debug('Fields to Mask FOUND');
                        fieldsToCopy = fieldsToMask.replaceAll('[^a-zA-Z0-9\\,\\_\\.]', '').split(',');
                    }
                    System.debug('Fields to Copy: ' + fieldsToCopy);

                    // perform operations from the Target collection
                    for(Product2 targetRecord : targetCollection){
                    //for(sObject targetRecord : targetCollection){
                        // get the unique ID from the target collection
                        String targetFieldValue = targetRecord.get(targetUniqueID).toString();
                        
                        // if the source collection has the value, copy the value from the source collection
                        // and paste it into the target collection
                        if (sourceMap.containsKey(targetFieldValue)){

                            for(String fieldApiName : fieldsToCopy){

                                if(!(sourceMap.get(targetFieldValue).get(fieldApiName) == null && 
                                    targetRecord.get(fieldApiName) != null &&
                                    skipNullValues)){
                                        targetRecord.put(fieldApiName, sourceMap.get(targetFieldValue).get(fieldApiName));
                                        if(actionTypeField != null & actionTypeField != ''){
                                            targetRecord.put(actionTypeField, 'Update');
                                        }
                                    }
                            }

                            updatedCollection.add(targetRecord);
                            
                        }
                        System.debug('Target Record: ' + targetRecord);
                        outputCollection.add(targetRecord);
                    }

                    // perform operations from the Source collection
                    //for(sObject sourceRecord : sourceCollection){
                    for(Product2 sourceRecord : sourceCollection){
                        
                        String sourceFieldValue = sourceRecord.get(sourceUniqueID).toString();
                        
                        if (!targetMap.containsKey(sourceFieldValue)){

                            SObject tempRecord = sourceRecord.clone(false,true);
                            //Product2 tempRecord = sourceRecord.clone(false, true);

                            if(actionTypeField != null & actionTypeField != ''){
                                tempRecord.put(actionTypeField, 'Create');
                            }
                            targetCollection.add(tempRecord);

                            outputCollection.add(tempRecord);
                            insertedCollection.add(tempRecord);
                            
                        }  
                    }
                    System.debug('Source Collection: ' + sourceCollection);
                    System.debug('Target Collection: ' + targetCollection);
                    System.debug('Output Collection: ' + outputCollection);
                    System.debug('Updated Collection: ' + updatedCollection);
                    System.debug('Inserted Collection: ' + insertedCollection);
                }
            }

            // if the target collection is empty, copy all the source records
            else if((sourceCollection != null && !sourceCollection.isEmpty()) && 
                    (targetCollection == null ||  targetCollection.isEmpty())){
                
                for(sObject sourceRecord : sourceCollection){
                    outputCollection.add(sourceRecord.clone(false,true));
                    insertedCollection.add(sourceRecord.clone(false,true));
                }
            }
            // if the source collection is empty, copy all the target records
            else if((sourceCollection == null || sourceCollection.isEmpty()) && 
                    (targetCollection != null && !targetCollection.isEmpty())){
                
                for(sObject targetRecord : targetCollection){
                    outputCollection.add(targetRecord);
                }

            }

            response.outputCollection = outputCollection;
            responseWrapper.add(response);
        }

        return responseWrapper;
    }


    private static String stripQuotes(String str) {
        if (str != null) {
            return str.removeEnd('"').removeStart('"');
        } else {
            return null;
        }
    }

    private static void putType(SObject obj, String fieldName, String fieldType, String fieldValue) {
        System.debug('fieldName, fieldType, fieldValue: '+fieldName+', '+fieldType+', '+fieldValue);
        if (fieldType != 'Boolean' && (fieldValue == null || fieldValue == '')) {
            obj.put(fieldName, null);
        } else if (fieldType == 'Date') {
            obj.put(fieldName, Date.valueOf(CollectionProcessorsUtils.getFormattedValue(fieldValue.toLowerCase(), fieldType.toLowerCase())));
        } else if (fieldType == 'Datetime') {
            obj.put(fieldName, Datetime.valueOf(CollectionProcessorsUtils.getFormattedValue(fieldValue.toLowerCase(), fieldType.toLowerCase())));
        } else if (fieldType == 'Boolean') {
            obj.put(fieldName, fieldValue == null ? false : Boolean.valueOf(fieldValue));
        } else if (fieldType == 'Currency' || fieldType == 'Double') {
            if (fieldValue != null && fieldValue != '') {
                obj.put(fieldName, Decimal.valueOf(fieldValue));
            }
        } else if (fieldType == 'JSON') {
            obj.put(fieldName, JSON.serialize(fieldValue));
            
        } else if (fieldType == 'Time')
        {
            string[] timeParts = fieldValue.split(':');
            obj.put(fieldName, Time.newInstance(Integer.valueOf(timeParts[0]), Integer.valueOf(timeparts[1]), 0, 0));
        } else {
            obj.put(fieldName, fieldValue);
        }
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

        @InvocableVariable(description='Comma-separated list of fields to be used as a mask (use API names)')
        global String fieldsToMask;

        @InvocableVariable(description='If true, the fields will be masked out of the update operation')
        global Boolean invertMask;

        @InvocableVariable(description='If false, null values will be written to the target collection')
        global Boolean skipNullValues;

        @InvocableVariable(description='(Optional) Field on the target collection to store either "Update" or "Create"')
        global String actionTypeField;
    }

    global class Results {

        public Results() {
            outputCollection = new List<SObject>();
            updatedCollection = new List<SObject>();
            insertedCollection = new List<SObject>();
        }
        @InvocableVariable
        global String errors;

        @InvocableVariable
        global List<SObject> outputCollection;

        @InvocableVariable
        global List<SObject> updatedCollection;

        @InvocableVariable
        global List<SObject> insertedCollection;
    }
}