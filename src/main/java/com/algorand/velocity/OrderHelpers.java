package com.algorand.velocity;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.HashSet;
import java.util.Set;
import java.util.Comparator;
import com.algorand.sdkutils.utils.TypeDef;

public class OrderHelpers {
    // Error with more details when an invalid preferred order is detected
    public void verboseException(List<TypeDef> properties, List<String> preferredOrder) {
        String template = "Errored with the following parameters\n"
                                        + "Properties: %s\n"
                                        + "Preferred order: %s";

        List<String> propertyNames = new ArrayList<String>();

        for (TypeDef property : properties) {
            propertyNames.add(property.getPropertyName());
        }
        
        String verboseFeedback = String.format(template, propertyNames.toString(), preferredOrder.toString());
        System.out.println(verboseFeedback);
    }

    // Throw an exception if the preferred order is invalid
    private void guardAgainstInvalidPreferredOrder(List<TypeDef> properties, List<String> preferredOrder) throws IllegalArgumentException {
        Set<String> bucket = new HashSet<>(preferredOrder);

        for (TypeDef prop : properties) {
            String nameToCheck = prop.getPropertyName();

            if (!bucket.remove(nameToCheck)) {
                verboseException(properties, preferredOrder);
                throw new IllegalArgumentException("Invalid preferred order. Order must include every prop.");
            }
        }

        if (!bucket.isEmpty()) {
            verboseException(properties, preferredOrder);
            throw new IllegalArgumentException("Invalid preferred order. Too many props included.");
        }
    }

    // Order properties in a preferred order
    public List<TypeDef> propertiesWithOrdering(ArrayList<TypeDef> properties, String[] preferredOrderArray) {
        List<String> preferredOrder = Arrays.asList(preferredOrderArray);
        this.guardAgainstInvalidPreferredOrder(properties, preferredOrder);

        List<TypeDef> reordered = new ArrayList<TypeDef>(properties);
        reordered.sort(new Comparator<TypeDef>() {
            @Override
            public int compare(TypeDef prop1, TypeDef prop2) {
                return preferredOrder.indexOf(prop1.getPropertyName()) - preferredOrder.indexOf(prop2.getPropertyName());
            }
        });

        return reordered;
    }
}
