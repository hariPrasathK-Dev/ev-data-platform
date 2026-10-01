import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.filter.*;
import org.apache.hadoop.hbase.util.Bytes;

import java.io.IOException;
import java.util.*;

/**
 * HBase Java API Demo: High Utilization Station Finder
 * 
 * Application: EV Charging Station Availability Analytics
 * Purpose: Find charging stations with high utilization (>80%) to identify
 *          stations needing capacity expansion or those experiencing congestion
 * 
 * Demonstrates:
 * - HBase connection management
 * - Table scanning with filters
 * - SingleColumnValueFilter usage
 * - Result processing and data extraction
 * - Statistical analysis of results
 */
public class HighUtilizationStationFinder {
    
    private static final String TABLE_NAME = "ev_charging_stations";
    private static final double UTILIZATION_THRESHOLD = 0.8; // 80%
    
    // Column Family and Qualifier names
    private static final byte[] CF_STATION = Bytes.toBytes("cf_station");
    private static final byte[] CF_METRICS = Bytes.toBytes("cf_metrics");
    private static final byte[] CF_PRICING = Bytes.toBytes("cf_pricing");
    private static final byte[] CF_TEMPORAL = Bytes.toBytes("cf_temporal");
    
    private static final byte[] COL_NAME = Bytes.toBytes("name");
    private static final byte[] COL_CITY = Bytes.toBytes("city");
    private static final byte[] COL_NETWORK = Bytes.toBytes("network");
    private static final byte[] COL_LOCATION_TYPE = Bytes.toBytes("location_type");
    
    private static final byte[] COL_UTILIZATION_RATE = Bytes.toBytes("utilization_rate");
    private static final byte[] COL_PORTS_AVAILABLE = Bytes.toBytes("ports_available");
    private static final byte[] COL_PORTS_TOTAL = Bytes.toBytes("ports_total");
    private static final byte[] COL_WAIT_TIME = Bytes.toBytes("wait_time_mins");
    private static final byte[] COL_STATION_STATUS = Bytes.toBytes("station_status");
    
    private static final byte[] COL_CURRENT_PRICE = Bytes.toBytes("current_price");
    private static final byte[] COL_TIMESTAMP = Bytes.toBytes("timestamp");
    private static final byte[] COL_HOUR = Bytes.toBytes("hour");
    private static final byte[] COL_IS_PEAK_HOUR = Bytes.toBytes("is_peak_hour");
    
    /**
     * Station data holder class
     */
    static class StationRecord {
        String rowKey;
        String stationName;
        String city;
        String network;
        String locationType;
        double utilizationRate;
        int portsAvailable;
        int portsTotal;
        int waitTime;
        String stationStatus;
        double currentPrice;
        String timestamp;
        String hour;
        boolean isPeakHour;
        
        @Override
        public String toString() {
            return String.format(
                "Station: %s | City: %s | Network: %s | Location: %s\n" +
                "  Utilization: %.1f%% | Available: %d/%d ports | Wait: %d mins\n" +
                "  Price: $%.2f | Time: %s (Hour: %s, Peak: %s) | Status: %s",
                stationName, city, network, locationType,
                utilizationRate * 100, portsAvailable, portsTotal, waitTime,
                currentPrice, timestamp, hour, isPeakHour, stationStatus
            );
        }
    }
    
    /**
     * Main execution method
     */
    public static void main(String[] args) {
        System.out.println("=================================================================");
        System.out.println("HBase Java API Demo: High Utilization Station Finder");
        System.out.println("Application: EV Charging Station Availability Analytics");
        System.out.println("=================================================================\n");
        
        Configuration config = HBaseConfiguration.create();
        
        // Optional: Configure HBase connection properties
        // config.set("hbase.zookeeper.quorum", "localhost");
        // config.set("hbase.zookeeper.property.clientPort", "2181");
        
        try (Connection connection = ConnectionFactory.createConnection(config)) {
            System.out.println("✓ Connected to HBase successfully\n");
            
            // Execute different analysis methods
            findHighUtilizationStations(connection);
            
            System.out.println("\n--- Additional Analysis Options ---\n");
            findPeakHourCongestion(connection);
            findStationsByCity(connection, "Los Angeles");
            
        } catch (IOException e) {
            System.err.println("ERROR: Failed to connect to HBase");
            e.printStackTrace();
        }
        
        System.out.println("\n=================================================================");
        System.out.println("Analysis Complete");
        System.out.println("=================================================================");
    }
    
    /**
     * Find stations with utilization rate above threshold
     */
    private static void findHighUtilizationStations(Connection connection) throws IOException {
        System.out.println("--- Analysis 1: High Utilization Stations ---");
        System.out.println("Threshold: " + (UTILIZATION_THRESHOLD * 100) + "%");
        System.out.println("Business Use Case: Identify stations needing capacity expansion\n");
        
        Table table = connection.getTable(TableName.valueOf(TABLE_NAME));
        
        // Create filter for utilization_rate > 0.8
        SingleColumnValueFilter filter = new SingleColumnValueFilter(
            CF_METRICS,
            COL_UTILIZATION_RATE,
            CompareFilter.CompareOp.GREATER,
            Bytes.toBytes(String.valueOf(UTILIZATION_THRESHOLD))
        );
        filter.setFilterIfMissing(true);
        
        // Create scan with filter
        Scan scan = new Scan();
        scan.setFilter(filter);
        scan.setCaching(100); // Optimize performance
        
        // Add column families to retrieve
        scan.addFamily(CF_STATION);
        scan.addFamily(CF_METRICS);
        scan.addFamily(CF_PRICING);
        scan.addFamily(CF_TEMPORAL);
        
        ResultScanner scanner = table.getScanner(scan);
        
        List<StationRecord> highUtilizationStations = new ArrayList<>();
        int count = 0;
        int maxResults = 20; // Limit results for demo
        
        for (Result result : scanner) {
            if (count >= maxResults) break;
            
            StationRecord record = parseResult(result);
            if (record != null) {
                highUtilizationStations.add(record);
                count++;
            }
        }
        
        scanner.close();
        table.close();
        
        // Display results
        System.out.println("Found " + count + " high-utilization records:\n");
        for (int i = 0; i < highUtilizationStations.size(); i++) {
            System.out.println("Record " + (i + 1) + ":");
            System.out.println(highUtilizationStations.get(i));
            System.out.println();
        }
        
        // Calculate statistics
        calculateStatistics(highUtilizationStations);
    }
    
    /**
     * Find high utilization during peak hours
     */
    private static void findPeakHourCongestion(Connection connection) throws IOException {
        System.out.println("--- Analysis 2: Peak Hour Congestion ---");
        System.out.println("Finding high utilization during peak hours (7-9 AM, 5-8 PM)\n");
        
        Table table = connection.getTable(TableName.valueOf(TABLE_NAME));
        
        // Create filter list with AND logic
        FilterList filterList = new FilterList(FilterList.Operator.MUST_PASS_ALL);
        
        // Filter 1: High utilization
        SingleColumnValueFilter utilizationFilter = new SingleColumnValueFilter(
            CF_METRICS,
            COL_UTILIZATION_RATE,
            CompareFilter.CompareOp.GREATER,
            Bytes.toBytes("0.7")
        );
        utilizationFilter.setFilterIfMissing(true);
        
        // Filter 2: Peak hour
        SingleColumnValueFilter peakHourFilter = new SingleColumnValueFilter(
            CF_TEMPORAL,
            COL_IS_PEAK_HOUR,
            CompareFilter.CompareOp.EQUAL,
            Bytes.toBytes("True")
        );
        peakHourFilter.setFilterIfMissing(true);
        
        filterList.addFilter(utilizationFilter);
        filterList.addFilter(peakHourFilter);
        
        Scan scan = new Scan();
        scan.setFilter(filterList);
        scan.addFamily(CF_STATION);
        scan.addFamily(CF_METRICS);
        scan.addFamily(CF_TEMPORAL);
        
        ResultScanner scanner = table.getScanner(scan);
        
        int count = 0;
        int maxResults = 10;
        
        for (Result result : scanner) {
            if (count >= maxResults) break;
            
            StationRecord record = parseResult(result);
            if (record != null) {
                System.out.println("Peak Hour Congestion #" + (count + 1) + ":");
                System.out.println(record);
                System.out.println();
                count++;
            }
        }
        
        scanner.close();
        table.close();
        
        System.out.println("Found " + count + " congested stations during peak hours");
    }
    
    /**
     * Find stations in a specific city
     */
    private static void findStationsByCity(Connection connection, String cityName) throws IOException {
        System.out.println("\n--- Analysis 3: Stations in " + cityName + " ---");
        
        Table table = connection.getTable(TableName.valueOf(TABLE_NAME));
        
        // Filter by city
        SingleColumnValueFilter cityFilter = new SingleColumnValueFilter(
            CF_STATION,
            COL_CITY,
            CompareFilter.CompareOp.EQUAL,
            Bytes.toBytes(cityName)
        );
        cityFilter.setFilterIfMissing(true);
        
        Scan scan = new Scan();
        scan.setFilter(cityFilter);
        scan.addFamily(CF_STATION);
        scan.addFamily(CF_METRICS);
        
        ResultScanner scanner = table.getScanner(scan);
        
        int count = 0;
        int maxResults = 5;
        double totalUtilization = 0;
        
        for (Result result : scanner) {
            if (count >= maxResults) break;
            
            StationRecord record = parseResult(result);
            if (record != null) {
                System.out.println(record.stationName + " - Utilization: " + 
                                   String.format("%.1f%%", record.utilizationRate * 100));
                totalUtilization += record.utilizationRate;
                count++;
            }
        }
        
        scanner.close();
        table.close();
        
        if (count > 0) {
            System.out.println("\nAverage Utilization in " + cityName + ": " + 
                               String.format("%.1f%%", (totalUtilization / count) * 100));
        }
    }
    
    /**
     * Parse HBase Result into StationRecord object
     */
    private static StationRecord parseResult(Result result) {
        if (result == null || result.isEmpty()) {
            return null;
        }
        
        StationRecord record = new StationRecord();
        
        try {
            record.rowKey = Bytes.toString(result.getRow());
            
            // Station info
            record.stationName = getStringValue(result, CF_STATION, COL_NAME);
            record.city = getStringValue(result, CF_STATION, COL_CITY);
            record.network = getStringValue(result, CF_STATION, COL_NETWORK);
            record.locationType = getStringValue(result, CF_STATION, COL_LOCATION_TYPE);
            
            // Metrics
            record.utilizationRate = getDoubleValue(result, CF_METRICS, COL_UTILIZATION_RATE);
            record.portsAvailable = getIntValue(result, CF_METRICS, COL_PORTS_AVAILABLE);
            record.portsTotal = getIntValue(result, CF_METRICS, COL_PORTS_TOTAL);
            record.waitTime = getIntValue(result, CF_METRICS, COL_WAIT_TIME);
            record.stationStatus = getStringValue(result, CF_METRICS, COL_STATION_STATUS);
            
            // Pricing
            record.currentPrice = getDoubleValue(result, CF_PRICING, COL_CURRENT_PRICE);
            
            // Temporal
            record.timestamp = getStringValue(result, CF_TEMPORAL, COL_TIMESTAMP);
            record.hour = getStringValue(result, CF_TEMPORAL, COL_HOUR);
            String isPeak = getStringValue(result, CF_TEMPORAL, COL_IS_PEAK_HOUR);
            record.isPeakHour = "True".equals(isPeak) || "true".equals(isPeak);
            
            return record;
            
        } catch (Exception e) {
            System.err.println("Error parsing result: " + e.getMessage());
            return null;
        }
    }
    
    /**
     * Helper method to get string value from result
     */
    private static String getStringValue(Result result, byte[] family, byte[] qualifier) {
        byte[] value = result.getValue(family, qualifier);
        return value != null ? Bytes.toString(value) : "N/A";
    }
    
    /**
     * Helper method to get double value from result
     */
    private static double getDoubleValue(Result result, byte[] family, byte[] qualifier) {
        String value = getStringValue(result, family, qualifier);
        try {
            return "N/A".equals(value) ? 0.0 : Double.parseDouble(value);
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }
    
    /**
     * Helper method to get integer value from result
     */
    private static int getIntValue(Result result, byte[] family, byte[] qualifier) {
        String value = getStringValue(result, family, qualifier);
        try {
            return "N/A".equals(value) ? 0 : Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return 0;
        }
    }
    
    /**
     * Calculate and display statistics
     */
    private static void calculateStatistics(List<StationRecord> stations) {
        if (stations.isEmpty()) {
            System.out.println("No data for statistics calculation");
            return;
        }
        
        System.out.println("--- Statistical Analysis ---\n");
        
        // Calculate average utilization
        double avgUtilization = stations.stream()
            .mapToDouble(s -> s.utilizationRate)
            .average()
            .orElse(0.0);
        
        // Calculate average wait time
        double avgWaitTime = stations.stream()
            .mapToInt(s -> s.waitTime)
            .average()
            .orElse(0.0);
        
        // Calculate average price
        double avgPrice = stations.stream()
            .mapToDouble(s -> s.currentPrice)
            .average()
            .orElse(0.0);
        
        // Count peak hour records
        long peakHourCount = stations.stream()
            .filter(s -> s.isPeakHour)
            .count();
        
        // Count by city
        Map<String, Long> cityDistribution = new HashMap<>();
        for (StationRecord station : stations) {
            cityDistribution.put(station.city, 
                cityDistribution.getOrDefault(station.city, 0L) + 1);
        }
        
        // Count by network
        Map<String, Long> networkDistribution = new HashMap<>();
        for (StationRecord station : stations) {
            networkDistribution.put(station.network, 
                networkDistribution.getOrDefault(station.network, 0L) + 1);
        }
        
        // Display statistics
        System.out.println("Total High-Utilization Records: " + stations.size());
        System.out.printf("Average Utilization Rate: %.1f%%\n", avgUtilization * 100);
        System.out.printf("Average Wait Time: %.1f minutes\n", avgWaitTime);
        System.out.printf("Average Price: $%.2f per kWh\n", avgPrice);
        System.out.printf("Peak Hour Records: %d (%.1f%%)\n", 
            peakHourCount, (peakHourCount * 100.0 / stations.size()));
        
        System.out.println("\nDistribution by City:");
        cityDistribution.entrySet().stream()
            .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
            .forEach(entry -> System.out.printf("  %s: %d records\n", entry.getKey(), entry.getValue()));
        
        System.out.println("\nDistribution by Network:");
        networkDistribution.entrySet().stream()
            .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
            .forEach(entry -> System.out.printf("  %s: %d records\n", entry.getKey(), entry.getValue()));
        
        System.out.println("\nBusiness Insights:");
        System.out.println("  • Stations with utilization > 80% need capacity expansion");
        System.out.println("  • High wait times indicate customer dissatisfaction risk");
        System.out.println("  • Peak hour congestion suggests need for dynamic pricing");
        System.out.println("  • City-wise distribution helps in regional planning");
    }
}
