global with sharing class MapCollectionFields {
    @InvocableMethod(label='Map Collection Field [USF Collection Processor]' category='Util' iconName='resource:CollectionProcessorsSVG:colproc')
    global static List <Results> mapCollectionfields(List<Requests> requestList) {
        List<Results> responseWrapper = new List<Results>();

        for (Requests curRequest : requestList) {
            Results response = new Results();
            List<SObject> inputCollection = curRequest.inputCollection;
            List<String> fieldCollection = curRequest.fieldValueCollection;

            List<SObject> outputCollection = new List<SObject>();

            if (inputCollection != null && !inputCollection.isEmpty() && fieldCollection != null && !fieldCollection.isEmpty()) {
                for (SObject acc : inputCollection) {
                    outputCollection.add(acc.clone(true));
                }

                Integer i = 0;
                for (SObject acc : outputCollection) {
                    try {
                        acc.put(curRequest.fieldAPIName,curRequest.fieldValueCollection[i++]);
                        //putType(acc, curRequest.fieldAPIName, fieldTypesMap.get(curFieldName), fieldNameToValueMap.get(curFieldName));
                    } catch (Exception ex) {
                        response.errors += ex.getMessage();
                    }
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
        @InvocableVariable(required=true)
        global List<SObject> inputCollection;

        @InvocableVariable(description='API name of the field' required=true)
        global String fieldAPIName;

        @InvocableVariable(description='List of values to map to the records' required=true)
        global List<String> fieldValueCollection;

        //@InvocableVariable(required=true)
        //global String keyValuePairs;

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