public with sharing class UserAndRecordIds{
    public Id userId;
    public Set<Id> recordIds;
    public static Map<Id, Set<Id>> convertToMap(List<UserAndRecordIds> userRecordList) {

        if (userRecordList == null)
            return null;

        Map<Id, Set<Id>> userRecordMap = new Map<Id, Set<Id>>();
        for (UserAndRecordIds userRecord : userRecordList) {
            if (userRecord.userId != null) {
                userRecordMap.put(userRecord.userId, new Set<Id>());
            }
            if (userRecord.recordIds != null) {
                userRecordMap.get(userRecord.userId).addAll(userRecord.recordIds);
            }
        }
        return userRecordMap;
    }
}
      