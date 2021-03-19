package com.algorand.velocity;

public class GoHelpers {
    /**
     * Map the generated query type to the hand written type.
     * @param input generated query type.
     * @return backwards compatible hand written type.
     */
    public String queryTypeMapper(String  input) {
        switch(input) {
            case "SearchForAccounts":               return "SearchAccounts";
            case "GetStatus":                       return "Status";
            case "GetPendingTransactionsByAddress": return "PendingTransactionInformationByAddress";
            case "GetPendingTransactions":          return "PendingTransactions";
            default:                                return input;
        }
    }

}
