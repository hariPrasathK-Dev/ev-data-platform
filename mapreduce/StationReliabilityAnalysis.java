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
 * StationReliabilityAnalysis - MapReduce Program #3
 * 
 * Business Question: Which stations have the best/worst reliability (uptime)?
 * Analyzes operational vs downtime status for each station
 */
public class StationReliabilityAnalysis {

    public static class ReliabilityMapper extends Mapper<LongWritable, Text, Text, Text> {
        
        private Text outputKey = new Text();
        private Text outputValue = new Text();
        
        @Override
        public void map(LongWritable key, Text value, Context context) 
                throws IOException, InterruptedException {
            
            String line = value.toString();
            if (line.startsWith("timestamp")) {
                return;
            }
            
            try {
                String[] fields = line.split(",");
                
                if (fields.length < 33) {
                    context.getCounter("ReliabilityMapper", "MALFORMED_RECORDS").increment(1);
                    return;
                }
                
                String stationId = fields[1].trim();
                String stationName = fields[2].trim();
                String network = fields[3].trim();
                String stationStatus = fields[17].trim();
                
                if (stationId.isEmpty() || stationStatus.isEmpty()) {
                    context.getCounter("ReliabilityMapper", "INCOMPLETE_RECORDS").increment(1);
                    return;
                }
                
                // Emit: Key = station_id,station_name,network, Value = status
                outputKey.set(stationId + "|" + stationName + "|" + network);
                outputValue.set(stationStatus);
                
                context.write(outputKey, outputValue);
                context.getCounter("ReliabilityMapper", "VALID_RECORDS_PROCESSED").increment(1);
                
            } catch (Exception e) {
                context.getCounter("ReliabilityMapper", "PARSING_ERRORS").increment(1);
            }
        }
    }

    public static class ReliabilityReducer extends Reducer<Text, Text, Text, Text> {
        
        private Text result = new Text();
        
        @Override
        public void reduce(Text key, Iterable<Text> values, Context context) 
                throws IOException, InterruptedException {
            
            long totalCount = 0;
            long operationalCount = 0;
            long offlineCount = 0;
            long maintenanceCount = 0;
            long partialOutageCount = 0;
            
            for (Text value : values) {
                String status = value.toString();
                totalCount++;
                
                switch (status) {
                    case "operational":
                        operationalCount++;
                        break;
                    case "offline":
                        offlineCount++;
                        break;
                    case "under_maintenance":
                        maintenanceCount++;
                        break;
                    case "partial_outage":
                        partialOutageCount++;
                        break;
                }
            }
            
            if (totalCount > 0) {
                double uptimePercentage = (operationalCount * 100.0) / totalCount;
                double downtimePercentage = 100.0 - uptimePercentage;
                
                String output = String.format("%d,%d,%d,%d,%d,%.2f,%.2f", 
                    totalCount, operationalCount, offlineCount, 
                    maintenanceCount, partialOutageCount,
                    uptimePercentage, downtimePercentage
                );
                
                result.set(output);
                context.write(key, result);
                context.getCounter("ReliabilityReducer", "OUTPUT_RECORDS").increment(1);
            }
        }
    }

    public static void main(String[] args) throws Exception {
        
        if (args.length != 2) {
            System.err.println("Usage: StationReliabilityAnalysis <input path> <output path>");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "EV Station Reliability Analysis");
        
        job.setJarByClass(StationReliabilityAnalysis.class);
        job.setMapperClass(ReliabilityMapper.class);
        job.setReducerClass(ReliabilityReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        System.out.println("==========================================================");
        System.out.println("EV Station Reliability Analysis - MapReduce Job");
        System.out.println("==========================================================");
        
        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}
