public class TexttoLookupController {
    @AuraEnabled
    public static Id Confirm(String lookupFieldName , String textFieldName , String sObjectApi , String Toggle , List<String> dict , Boolean Overwrite){
        System.debug('this is toggle value:' + Toggle);
        System.debug('Lookup value'+ lookupFieldName);
        System.debug('textFieldName'+ textFieldName);
        TexttoLookupBatch batch = new TexttoLookupBatch(sObjectApi, textFieldName, lookupFieldName , toggle , dict ,Overwrite);
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
@AuraEnabled    
public static String getLatestCSVFile() {
    Id loggedInUserId = UserInfo.getUserId();
    List<ContentVersion> cvList = [
        SELECT Id, Title, VersionData
        FROM ContentVersion
        WHERE OwnerId = :loggedInUserId And Title LIKE 'Text_Lookup_Result%'
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    if (!cvList.isEmpty()) {
        System.debug(cvList[0].VersionData);
        return cvList[0].VersionData.toString();
    } else {
        return null;
    }
}
}