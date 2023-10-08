public with sharing class objectQuery {
    public class Option {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        public Option(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getOptions() {
        List<Option> options = new List<Option>();
        List<String> objectApiNames = new List<String>();

        for(Schema.SObjectType objType : Schema.getGlobalDescribe().Values()) {
            objectApiNames.add(objType.getDescribe().getName());
        }

        objectApiNames.sort();

        for(String apiName : objectApiNames) {
            options.add(new Option(apiName, apiName));
        }

        return options;
    }









@AuraEnabled
    public static List<String> fetchFieldAPIName(String sObjectName) {
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
     /*   if(sObjectType == null) {
            System.debug('The SObject ' + sObjectName + ' does not exist.');
            return null;
        } */
        // Get the SObject fields
        Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
        // Create a list to store the field API names
        List<String> fieldAPINames = new List<String>();
        // Iterate over each field and add the API name to the list
        for(String fieldName : fieldMap.keySet()) {
            fieldAPINames.add(fieldName);
        }
        system.debug(fieldAPINames);
        return fieldAPINames;
    }
}