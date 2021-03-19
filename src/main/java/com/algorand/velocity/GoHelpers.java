package com.algorand.velocity;

public class GoHelpers {
    /**
     * Map the generated query type to the hand written type.
     * @param input generated query type.
     * @return backwards compatible with written type.
     */
    public String queryTypeMapper(String input) {
        switch(input) {
            case "SearchForAccounts":               return "SearchAccounts";
            case "GetStatus":                       return "Status";
            case "GetPendingTransactionsByAddress": return "PendingTransactionInformationByAddress";
            case "GetPendingTransactions":          return "PendingTransactions";
            default:                                return input;
        }
    }

    /**
     * Map the generated return type to the hand written type.
     * @param input generated return type.
     * @return backwards compatible with hand written type.
     */
    public String returnTypeMapper(String input) {
        switch(input) {
            case "NodeStatusResponse":          return "NodeStatus";
            case "PendingTransactionResponse":  return "PendingTransactionInfo";
            default: return input;
        }
    }

    //public string
}
