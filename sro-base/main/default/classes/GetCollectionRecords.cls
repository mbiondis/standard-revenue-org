global with sharing class GetCollectionRecords {
    @InvocableMethod(label='Get Collection Records [USF Collection Processor]' category='Util' iconName='resource:CollectionProcessorsSVG:colproc')
    global static List <Results> getCollectionRecords(List<Requests> requestList) {

        // Infuse the Target colleciton with the Fields in the Source collection 
        List<Results> responseWrapper = new List<Results>();

        // creates a map with Strings as keys, and another Map as value 
        // (this second map has an API Name as key, and an SObjectField as value)
        Map<String, Map<String, SObjectField>> sobjectTypeMap = new Map<String, Map<String, SObjectField>>();

        for (Requests curRequest : requestList) {
            
            // prepare the response
            Results response = new Results();

            // load inputs from request
            List<SObject> inputCollection = curRequest.inputCollection;

            List<String> ids = curRequest.ids;
            String fieldToQuery = curRequest.fieldToQuery;
            Boolean findRecordsIn = curRequest.findRecordsIn != null ? curRequest.findRecordsIn : true;
       
            /*        // TEST DATA
                    List <Product2> inputCollection = new List<Product2>();
                    Product2 prod_1 = new Product2(Name='Test Product 1',ProductCode='TST1',USD__c=1.00);
                    inputCollection.add(prod_1);
                    Product2 prod_2 = new Product2(Name='Test Product 2',ProductCode='TST2',USD__c=5.00);
                    inputCollection.add(prod_2);
                    Product2 prod_3 = new Product2(Name='Test Product 3',ProductCode='TST3',USD__c=5.00);
                    inputCollection.add(prod_3);

                    System.debug('Input Collection' + inputCollection);

                    // turn api name string into list of fields
                    String fieldToQuery = 'ProductCode';
                    Boolean findRecordsIn = true;
                    List<String> ids = new List<String>{'TST2'};
            */        

            // create the output collection
            List<SObject> outputCollection = new List<SObject>();
                        
            if (inputCollection != null && !inputCollection.isEmpty()) {

                // create a map to bind the Input Collection to the Field to Query
                Map<String, Sobject> recordMap = new Map<String, Sobject>();
                string objectType = string.valueOf(inputCollection[0].getSObjectType());

                // add the source collection to the Object Type map 
                if(!sobjectTypeMap.containsKey(objectType)){
                    Schema.SObjectType s = inputCollection[0].getSObjectType();
                    Map<String, SObjectField> fieldMap = s.getDescribe().fields.getMap();
                    sobjectTypeMap.put(string.valueOf(s), fieldMap);
                }

                if(sobjectTypeMap.containsKey(objectType)){
                    for(sObject inputRecord : inputCollection){
                        //grab the value of the Field To Query
                        String currentFieldValue = (String)inputRecord.get(fieldToQuery);
                            
                        //as long as the unique value isn't blank, put it in the sourceMap map to be used later
                        if (currentFieldValue != null && currentFieldValue != '') {
                            recordMap.put(currentFieldValue, inputRecord);
                        }
                    }
                }

                if(findRecordsIn){
                    for(String id : ids){
                        if(recordMap.containsKey(id)){
                            outputCollection.add(recordMap.get(id));
                        }
                    }
                }
                else{
                    for(sObject inputRecord : inputCollection){
                        if(!ids.contains(string.valueOf(inputRecord.get(fieldToQuery)))){
                            outputCollection.add(inputRecord);
                        }
                    }
                }
                
            }

            System.debug('Output Collection' + outputCollection);

            response.outputCollection = outputCollection;
            responseWrapper.add(response);
        }

        return responseWrapper;
    }

    global class Requests {
        @InvocableVariable()
        global List<SObject> inputCollection;

        @InvocableVariable(description='Field to query on' required=true)
        global String fieldToQuery;

        @InvocableVariable(description='If true, finds records in the ids collection')
        global Boolean findRecordsIn;

        @InvocableVariable(description='Collection of ids to match to the fieldToQuery' required=true)
        global List<String> ids;

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