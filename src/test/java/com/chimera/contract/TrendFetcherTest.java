package com.chimera.contract;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Contract tests for TrendFetcher skill.
 * 
 * Spec Reference: specs/technical.md Section 3.1 (skill_trend_fetcher)
 * These tests validate the strict contract for trend data returned from TrendFetcher.fetchTrends()
 * 
 * Status: FAILING - Classes TrendFetcher and TrendResponse not yet implemented
 */
@DisplayName("TrendFetcher Contract Tests")
public class TrendFetcherTest {

    private TrendFetcher trendFetcher;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setup() {
        // FAILING: TrendFetcher class not yet implemented
        this.trendFetcher = new TrendFetcher();
        this.objectMapper = new ObjectMapper();
    }

    @Test
    @DisplayName("fetchTrends returns non-null trends list")
    void testFetchTrendsReturnsNonNullList() {
        // Arrange
        TrendFetcherRequest request = new TrendFetcherRequest(
            taskId = "task_001",
            campaignId = "campaign_001",
            correlationId = "corr_123",
            keywords = List.of("AI", "technology"),
            regions = List.of("US", "EU"),
            platforms = List.of("twitter", "news"),
            limit = 10
        );

        // Act
        // FAILING: TrendFetcher.fetchTrends() method not implemented
        TrendResponse response = trendFetcher.fetchTrends(request);

        // Assert
        assertNotNull(response, "TrendResponse must not be null");
        assertNotNull(response.trends(), "Trends list must not be null");
        assertFalse(response.trends().isEmpty(), "Trends list should contain results");
    }

    @Test
    @DisplayName("Each trend has required fields: topic and score in valid range")
    void testTrendContractRequiredFields() {
        // Arrange
        TrendFetcherRequest request = new TrendFetcherRequest(
            taskId = "task_001",
            campaignId = "campaign_001",
            correlationId = "corr_123",
            keywords = List.of("fintech"),
            regions = List.of("US"),
            platforms = List.of("twitter"),
            limit = 5
        );

        // Act
        TrendResponse response = trendFetcher.fetchTrends(request);

        // Assert
        assertNotNull(response.trends(), "Trends list must not be null");
        
        // Validate each trend in the response
        for (Trend trend : response.trends()) {
            // Topic must be non-empty string
            assertNotNull(trend.topic(), "Trend topic must not be null");
            assertFalse(trend.topic().isBlank(), "Trend topic must not be blank");
            
            // Score must be between 0 and 1 (inclusive)
            assertNotNull(trend.score(), "Trend score must not be null");
            assertTrue(
                trend.score() >= 0.0 && trend.score() <= 1.0,
                "Trend score must be between 0.0 and 1.0, found: " + trend.score()
            );
            
            // Sentiment must be one of: positive, neutral, negative
            assertNotNull(trend.sentiment(), "Trend sentiment must not be null");
            assertTrue(
                List.of("positive", "neutral", "negative").contains(trend.sentiment()),
                "Trend sentiment must be positive, neutral, or negative"
            );
            
            // Discovered timestamp must be set
            assertNotNull(trend.discoveredAt(), "Trend discoveredAt must not be null");
        }
    }

    @Test
    @DisplayName("TrendResponse JSON serialization test using Jackson")
    void testTrendResponseJacksonSerialization() throws Exception {
        // Arrange
        Trend sampleTrend = new Trend(
            trendId = "trend_001",
            topic = "AI Innovation",
            platform = "twitter",
            region = "US",
            score = 0.87,
            sentiment = "positive",
            engagementCount = 15000,
            mentionCount = 3200,
            discoveredAt = Instant.now()
        );

        TrendResponse response = new TrendResponse(
            executionId = "exec_001",
            taskId = "task_001",
            correlationId = "corr_123",
            status = "success",
            trends = List.of(sampleTrend),
            actualCost = 0.05
        );

        // Act - Serialize to JSON
        String jsonString = objectMapper.writeValueAsString(response);
        assertNotNull(jsonString, "JSON serialization must not return null");
        assertFalse(jsonString.isBlank(), "JSON serialization must not be empty");

        // Assert - Deserialize back from JSON
        TrendResponse deserializedResponse = objectMapper.readValue(jsonString, TrendResponse.class);
        
        // Verify round-trip serialization
        assertEquals(response.executionId(), deserializedResponse.executionId(), 
            "Execution ID must match after deserialization");
        assertEquals(response.taskId(), deserializedResponse.taskId(), 
            "Task ID must match after deserialization");
        assertEquals(response.correlationId(), deserializedResponse.correlationId(), 
            "Correlation ID must match after deserialization");
        assertEquals(response.status(), deserializedResponse.status(), 
            "Status must match after deserialization");
        
        // Verify trends list preserved
        assertEquals(response.trends().size(), deserializedResponse.trends().size(), 
            "Trends list size must match after deserialization");
        
        Trend originalTrend = response.trends().get(0);
        Trend deserializedTrend = deserializedResponse.trends().get(0);
        
        assertEquals(originalTrend.topic(), deserializedTrend.topic(), 
            "Trend topic must match after deserialization");
        assertEquals(originalTrend.score(), deserializedTrend.score(), 0.001, 
            "Trend score must match after deserialization (within tolerance)");
        assertEquals(originalTrend.sentiment(), deserializedTrend.sentiment(), 
            "Trend sentiment must match after deserialization");
    }

    @Test
    @DisplayName("TrendResponse contains correlation_id for observability tracing")
    void testTrendResponseIncludesCorrelationId() {
        // Arrange
        String expectedCorrelationId = "corr_abc_123_xyz";
        TrendFetcherRequest request = new TrendFetcherRequest(
            taskId = "task_001",
            campaignId = "campaign_001",
            correlationId = expectedCorrelationId,
            keywords = List.of("blockchain"),
            regions = List.of("EU"),
            platforms = List.of("news"),
            limit = 5
        );

        // Act
        TrendResponse response = trendFetcher.fetchTrends(request);

        // Assert
        assertNotNull(response, "TrendResponse must not be null");
        assertNotNull(response.correlationId(), "Correlation ID must not be null in response");
        assertEquals(expectedCorrelationId, response.correlationId(), 
            "Correlation ID must be propagated from request to response");
    }

    @Test
    @DisplayName("TrendResponse includes audit log entries")
    void testTrendResponseIncludesAuditLog() {
        // Arrange
        TrendFetcherRequest request = new TrendFetcherRequest(
            taskId = "task_001",
            campaignId = "campaign_001",
            correlationId = "corr_123",
            keywords = List.of("machine-learning"),
            regions = List.of("APAC"),
            platforms = List.of("twitter", "reddit"),
            limit = 10
        );

        // Act
        TrendResponse response = trendFetcher.fetchTrends(request);

        // Assert
        assertNotNull(response, "TrendResponse must not be null");
        assertNotNull(response.auditLog(), "Audit log must not be null");
        assertFalse(response.auditLog().isEmpty(), "Audit log should contain entries");
        
        // Verify audit log structure
        for (AuditLogEntry entry : response.auditLog()) {
            assertNotNull(entry.timestamp(), "Audit entry timestamp must not be null");
            assertNotNull(entry.action(), "Audit entry action must not be null");
            assertFalse(entry.action().isBlank(), "Audit entry action must not be blank");
        }
    }

    /**
     * Record class for trend data.
     * FAILING: This class must be implemented in production code.
     * Spec Reference: specs/technical.md Section 4.1 - Agent Status Schema
     */
    record Trend(
        String trendId,
        String topic,
        String platform,
        String region,
        double score,
        String sentiment,
        int engagementCount,
        int mentionCount,
        Instant discoveredAt
    ) {}

    /**
     * Record class for TrendFetcher request payload.
     * FAILING: This class must be implemented in production code.
     */
    record TrendFetcherRequest(
        String taskId,
        String campaignId,
        String correlationId,
        List<String> keywords,
        List<String> regions,
        List<String> platforms,
        int limit
    ) {}

    /**
     * Record class for TrendFetcher response payload.
     * FAILING: This class must be implemented in production code.
     * Spec Reference: specs/technical.md Section 3.1 - Execution Result Schema
     */
    record TrendResponse(
        String executionId,
        String taskId,
        String correlationId,
        String status,
        List<Trend> trends,
        double actualCost
    ) {
        List<AuditLogEntry> auditLog() {
            // FAILING: Audit log must be implemented
            return List.of();
        }
    }

    /**
     * Audit log entry for traceability.
     * FAILING: This class must be implemented in production code.
     */
    record AuditLogEntry(
        Instant timestamp,
        String action
    ) {}

}
