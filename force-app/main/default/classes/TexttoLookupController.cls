public class TexttoLookupController {
    @AuraEnabled
    public static Id Confirm(String lookupFieldName , String textFieldName , String sObjectApi , String Toggle , List<String> dict){
        System.debug('this is toggle value:' + Toggle);
        System.debug('Lookup value'+ lookupFieldName);
        System.debug('textFieldName'+ textFieldName);
        TexttoLookupBatch batch = new TexttoLookupBatch(sObjectApi, textFieldName, lookupFieldName , toggle , dict);
        Id batchJobId = Database.executeBatch(batch,20);
        Return batchJobId;
    }
    @AuraEnabled
    public static List<AsyncApexJob> getJobDetails(String jobId){
        try {
            List<AsyncApexJob> asyncJobList = [SELECT Id, Status, JobItemsProcessed, TotalJobItems,
                                                NumberOfErrors FROM AsyncApexJob where Id =: jobId ];
            return asyncJobList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}