package com.algorand.velocity;

public class GoHelpers {
    // Set this to true to disable backwards compatibility mapping.
    private static final boolean disableMapping = false;

    /**
     * Map the generated query type to the hand written type.
     * @param input generated query type.
     * @return backwards compatible with written type.
     */
    public String queryTypeMapper(String input) {
        if (disableMapping) return input;
        switch(input) {
            case "SearchForAccounts":               return "SearchAccounts";
            case "GetStatus":                       return "Status";
            case "GetBlock":                        return "Block";
            case "GetVersion":                      return "Versions";
            case "GetSupply":                       return "Supply";
            case "GetPendingTransactionsByAddress": return "PendingTransactionsByAddress";
            case "GetPendingTransactions":          return "PendingTransactions";
            case "RawTransaction":                  return "SendRawTransaction";
            case "WaitForBlock":                    return "StatusAfterBlock";
            case "TransactionParams":               return "SuggestedParams";
            default:                                return input;
        }
    }

    /**
     * Map the generated return type to the hand written type.
     * @param input generated return type.
     * @return backwards compatible with hand written type.
     */
    public String returnTypeMapper(String input) {
        if (disableMapping) return input;
        switch(input) {
            case "SupplyResponse":              return "Supply";
            case "NodeStatusResponse":          return "NodeStatus";
            case "PendingTransactionResponse":  return "PendingTransactionInfo";
            default: return input;
        }
    }

    /**
     * Map the generated query parameter type to the hand written type.
     * @param queryType the query which the input is for. This value has gone through the queryTypeMapper!
     * @param input generated query parameter type.
     * @return backwards compatible with hand written type.
     */
    public String queryParamTypeNameMapper(String queryType, String input) {
        if (disableMapping) return input;
        switch (queryType) {
            // TODO Build Fields
            case "SearchAccounts": {
                switch(input) {
                    case "Next":            return "NextToken";
                    case "ApplicationID":   return "ApplicationId";
                    case "AuthAddr":        return "AuthAddress";
                }
                return input;
            }
            case "SearchForTransactions":
            case "SearchForAssets":
            case "LookupAccountTransactions":
            case "LookupAssetBalances":
            case "LookupAssetTransactions": {
                switch(input) {
                    case "Address":         return "AddressString";
                    case "ApplicationID":   return "ApplicationId";
                    case "Txid":            return "TXID";
                    case "Next":            return "NextToken";
                }
                return input;
            }
            case "SearchForApplications": {
                switch(input) {
                    case "ApplicationID":   return "ApplicationId";
                }
                return input;
            }
        }
        return input;
    }

    public String modelParamNameMapper(String property) {
        switch(property) {
            case "TxType": return "Type";
            case "Txn": return "Transaction";
            case "Build_number": return "BuildNumber";
            case "Commit_hash":  return "CommitHash";
            case "Genesis_id": return "GenesisID";
            case "Genesis_hash_b64":  return "GenesisHash";
        }
        return property;
    }

}
