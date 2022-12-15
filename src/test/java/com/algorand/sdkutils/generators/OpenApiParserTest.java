package com.algorand.sdkutils.generators;

import com.algorand.sdkutils.listeners.Publisher;
import com.algorand.sdkutils.listeners.Subscriber;
import com.algorand.sdkutils.utils.QueryDef;
import com.algorand.sdkutils.utils.StructDef;
import com.algorand.sdkutils.utils.TypeDef;
import com.fasterxml.jackson.databind.JsonNode;
import com.google.common.collect.ImmutableList;
import net.bytebuddy.asm.Advice;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.net.URI;
import java.net.URL;
import java.nio.file.Paths;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class OpenApiParserTest {
    private InputStream getInputStreamForResource(String resource) {
        ClassLoader loader = getClass().getClassLoader();
        return loader.getResourceAsStream(resource);
    }


    @Test
    public void basicTest() throws Exception {
        // Given - mock subscriber listening to all events while parsing "petstore.json"
        Subscriber subscriber = mock(Subscriber.class);
        InputStream istream = getInputStreamForResource("petstore.json");
        Publisher publisher = new Publisher();
        publisher.subscribeAll(subscriber);

        // When - we receive events
        JsonNode node = Utils.getRoot(istream);
        OpenApiParser parser = new OpenApiParser(node, publisher);
        parser.parse();

        // Then - verify that some of the expected events

        // 'onEvent(evt, StructDef)` is called as expected
        List<String> expectedStructs = ImmutableList.of("ApiResponse", "Category", "Pet", "Tag", "Order", "User");
        ArgumentCaptor<StructDef> structDefArgumentCaptor = ArgumentCaptor.forClass(StructDef.class);
        verify(subscriber, times(expectedStructs.size()))
                .onEvent(any(), structDefArgumentCaptor.capture());

        assertThat(structDefArgumentCaptor.getAllValues())
                .extracting("name")
                .containsAll(expectedStructs);

        // 'onEvent(evt)' - called 26 times, once for each END_QUERY (20) and END_MODEL (6).
        verify(subscriber, times(26))
                .onEvent(any());

        // 'onEvent(evt, []String)` - called 14 times, once for each NEW_QUERY.
        List<String> expectedQueries = ImmutableList.of(
                "POST:/pet/{petId}/uploadImage",
                "POST:/pet",
                "PUT:/pet",
                "GET:/pet/findByStatus",
                "GET:/pet/findByTags",
                "GET:/pet/{petId}",
                "POST:/pet/{petId}",
                "DELETE:/pet/{petId}",
                "POST:/store/order",
                "GET:/store/order/{orderId}",
                "DELETE:/store/order/{orderId}",
                "GET:/store/inventory",
                "POST:/user/createWithArray",
                "POST:/user/createWithList",
                "GET:/user/{username}",
                "PUT:/user/{username}",
                "DELETE:/user/{username}",
                "GET:/user/login",
                "GET:/user/logout",
                "POST:/user"
        );
        ArgumentCaptor<QueryDef> queryDefArgumentCaptor = ArgumentCaptor.forClass(QueryDef.class);
        verify(subscriber, times(expectedQueries.size()))
                .onEvent(any(), queryDefArgumentCaptor.capture());

        assertThat(queryDefArgumentCaptor.getAllValues())
                .extracting(queryDef -> queryDef.method.toUpperCase() + ":" + queryDef.path)
                .containsAll(expectedQueries);

        // Property, Path param, Query param, Body
        verify(subscriber, times(52))
                .onEvent(any(), any(TypeDef.class));
    }
}