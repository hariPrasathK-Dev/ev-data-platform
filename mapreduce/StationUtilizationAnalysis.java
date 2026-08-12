import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/**
 * StationUtilizationAnalysis - Hadoop MapReduce Program
 * 
 * Business Question:
 * Analyze EV charging station utilization patterns by calculating average utilization rate,
 * wait time, and session duration grouped by network and hour of day.
 * 
 * This helps identify:
 * - Peak demand hours for each charging network
 * - Network-specific utilization patterns
 * - Optimal times for station maintenance
 * - Infrastructure planning insights
 * 
 * Input: ev_charging_station_data_cleaned.csv (1.3M+ records, 33 columns)
 * Output: Aggregated statistics by network and hour
 */
public class StationUtilizationAnalysis {

    /**
     * Mapper Class
     * 
     * Input: CSV record from EV charging dataset
     * Output: Key = "network,hour_of_day", Value = "utilization_rate,wait_time,session_duration"
     * 
     * CSV Schema (columns 0-32):
     * 0:timestamp, 1:station_id, 2:station_name, 3:network, 4:city, 5:state,
     * 6:latitude, 7:longitude, 8:location_type, 9:charger_type, 10:power_output_kw,
     * 11:amenities_nearby, 12:ports_total, 13:ports_available, 14:ports_occupied,
     * 15:ports_out_of_service, 16:utilization_rate, 17:station_status,
     * 18:estimated_wait_time_mins, 19:avg_session_duration_mins, 20:current_price,
     * 21:pricing_type, 22:temperature_f, 23:precipitation_mm, 24:weather_condition,
     * 25:gas_price_per_gallon, 26:traffic_congestion_index, 27:local_event,
     * 28:is_weekend, 29:is_peak_hour, 30:hour_of_day, 31:day_of_week, 32:month
     */
    public static class UtilizationMapper extends Mapper<LongWritable, Text, Text, Text> {
        
        private Text outputKey = new Text();
        private Text outputValue = new Text();
        
        @Override
        public void map(LongWritable key, Text value, Context context) 
                throws IOException, InterruptedException {
            
            // Skip header row
            String line = value.toString();
            if (line.startsWith("timestamp")) {
                return;
            }
            
            try {
                // Parse CSV line
                String[] fields = line.split(",");
                
                // Validate record has all required fields
                if (fields.length < 33) {
                    context.getCounter("UtilizationMapper", "MALFORMED_RECORDS").increment(1);
                    return;
                }
                
                // Extract relevant fields
                String network = fields[3].trim();
                String hourOfDay = fields[30].trim();
                String utilizationRate = fields[16].trim();
                String waitTime = fields[18].trim();
                String sessionDuration = fields[19].trim();
                String stationStatus = fields[17].trim();
                
                // Skip records with invalid or missing data
                if (network.isEmpty() || hourOfDay.isEmpty() || 
                    utilizationRate.isEmpty() || waitTime.isEmpty() || sessionDuration.isEmpty()) {
                    context.getCounter("UtilizationMapper", "INCOMPLETE_RECORDS").increment(1);
                    return;
                }
                
                // Only process operational stations for accurate utilization metrics
                if (!stationStatus.equals("operational")) {
                    context.getCounter("UtilizationMapper", "NON_OPERATIONAL_SKIPPED").increment(1);
                    return;
                }
                
                // Emit: Key = "network,hour", Value = "utilization,wait,session"
                outputKey.set(network + "," + hourOfDay);
                outputValue.set(utilizationRate + "," + waitTime + "," + sessionDuration);
                
                context.write(outputKey, outputValue);
                context.getCounter("UtilizationMapper", "VALID_RECORDS_PROCESSED").increment(1);
                
            } catch (Exception e) {
                // Log parsing errors
                context.getCounter("UtilizationMapper", "PARSING_ERRORS").increment(1);
            }
        }
    }

    /**
     * Reducer Class
     * 
     * Input: Key = "network,hour_of_day", Values = List of "utilization,wait,session"
     * Output: Key = "network,hour", Value = "count,avg_utilization,avg_wait,avg_session,min_util,max_util"
     * 
     * Computes aggregated statistics for each network-hour combination
     */
    public static class UtilizationReducer extends Reducer<Text, Text, Text, Text> {
        
        private Text result = new Text();
        
        @Override
        public void reduce(Text key, Iterable<Text> values, Context context) 
                throws IOException, InterruptedException {
            
            long count = 0;
            double sumUtilization = 0.0;
            double sumWaitTime = 0.0;
            double sumSessionDuration = 0.0;
            double minUtilization = Double.MAX_VALUE;
            double maxUtilization = Double.MIN_VALUE;
            
            // Aggregate all values for this key
            for (Text value : values) {
                try {
                    String[] metrics = value.toString().split(",");
                    
                    if (metrics.length >= 3) {
                        double utilization = Double.parseDouble(metrics[0]);
                        double waitTime = Double.parseDouble(metrics[1]);
                        double sessionDuration = Double.parseDouble(metrics[2]);
                        
                        sumUtilization += utilization;
                        sumWaitTime += waitTime;
                        sumSessionDuration += sessionDuration;
                        
                        minUtilization = Math.min(minUtilization, utilization);
                        maxUtilization = Math.max(maxUtilization, utilization);
                        
                        count++;
                    }
                } catch (NumberFormatException e) {
                    context.getCounter("UtilizationReducer", "VALUE_PARSING_ERRORS").increment(1);
                }
            }
            
            // Calculate averages
            if (count > 0) {
                double avgUtilization = sumUtilization / count;
                double avgWaitTime = sumWaitTime / count;
                double avgSessionDuration = sumSessionDuration / count;
                
                // Format output: count,avg_util,avg_wait,avg_session,min_util,max_util
                String output = String.format("%d,%.4f,%.2f,%.2f,%.4f,%.4f", 
                    count, 
                    avgUtilization, 
                    avgWaitTime, 
                    avgSessionDuration,
                    minUtilization,
                    maxUtilization
                );
                
                result.set(output);
                context.write(key, result);
                context.getCounter("UtilizationReducer", "OUTPUT_RECORDS").increment(1);
            }
        }
    }

    /**
     * Main Driver
     * 
     * Configures and executes the MapReduce job
     */
    public static void main(String[] args) throws Exception {
        
        if (args.length != 2) {
            System.err.println("Usage: StationUtilizationAnalysis <input path> <output path>");
            System.err.println("Example: hadoop jar StationUtilizationAnalysis.jar StationUtilizationAnalysis " +
                             "/home/hduser/Hive_Assignment/ev_charging_station_data_cleaned.csv " +
                             "/home/hduser/Hive_Assignment/output/utilization_analysis");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        
        // Create job
        Job job = Job.getInstance(conf, "EV Station Utilization Analysis");
        job.setJarByClass(StationUtilizationAnalysis.class);
        
        // Set Mapper and Reducer classes
        job.setMapperClass(UtilizationMapper.class);
        job.setReducerClass(UtilizationReducer.class);
        
        // Set output key and value types
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        // Set input and output paths
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        // Print job configuration
        System.out.println("==========================================================");
        System.out.println("EV Charging Station Utilization Analysis - MapReduce Job");
        System.out.println("==========================================================");
        System.out.println("Input:  " + args[0]);
        System.out.println("Output: " + args[1]);
        System.out.println("==========================================================");
        
        // Execute job and wait for completion
        boolean success = job.waitForCompletion(true);
        
        if (success) {
            System.out.println("==========================================================");
            System.out.println("Job completed successfully!");
            System.out.println("==========================================================");
            System.out.println("Check results in HDFS:");
            System.out.println("  hdfs dfs -cat " + args[1] + "/part-r-00000 | head -20");
            System.out.println("==========================================================");
        } else {
            System.err.println("Job failed!");
        }
        
        System.exit(success ? 0 : 1);
    }
}
