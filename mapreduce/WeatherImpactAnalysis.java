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
 * WeatherImpactAnalysis - MapReduce Program #2
 * 
 * Business Question: How does weather affect EV charging station utilization?
 * Analyzes correlation between weather conditions and charging demand
 */
public class WeatherImpactAnalysis {

    public static class WeatherMapper extends Mapper<LongWritable, Text, Text, Text> {
        
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
                    context.getCounter("WeatherMapper", "MALFORMED_RECORDS").increment(1);
                    return;
                }
                
                String weatherCondition = fields[24].trim();
                String temperatureF = fields[22].trim();
                String utilizationRate = fields[16].trim();
                String stationStatus = fields[17].trim();
                
                if (weatherCondition.isEmpty() || temperatureF.isEmpty() || 
                    utilizationRate.isEmpty()) {
                    context.getCounter("WeatherMapper", "INCOMPLETE_RECORDS").increment(1);
                    return;
                }
                
                if (!stationStatus.equals("operational")) {
                    context.getCounter("WeatherMapper", "NON_OPERATIONAL_SKIPPED").increment(1);
                    return;
                }
                
                // Emit: Key = weather_condition, Value = utilization,temperature
                outputKey.set(weatherCondition);
                outputValue.set(utilizationRate + "," + temperatureF);
                
                context.write(outputKey, outputValue);
                context.getCounter("WeatherMapper", "VALID_RECORDS_PROCESSED").increment(1);
                
            } catch (Exception e) {
                context.getCounter("WeatherMapper", "PARSING_ERRORS").increment(1);
            }
        }
    }

    public static class WeatherReducer extends Reducer<Text, Text, Text, Text> {
        
        private Text result = new Text();
        
        @Override
        public void reduce(Text key, Iterable<Text> values, Context context) 
                throws IOException, InterruptedException {
            
            long count = 0;
            double sumUtilization = 0.0;
            double sumTemperature = 0.0;
            double minUtilization = Double.MAX_VALUE;
            double maxUtilization = Double.MIN_VALUE;
            
            for (Text value : values) {
                try {
                    String[] metrics = value.toString().split(",");
                    
                    if (metrics.length >= 2) {
                        double utilization = Double.parseDouble(metrics[0]);
                        double temperature = Double.parseDouble(metrics[1]);
                        
                        sumUtilization += utilization;
                        sumTemperature += temperature;
                        
                        minUtilization = Math.min(minUtilization, utilization);
                        maxUtilization = Math.max(maxUtilization, utilization);
                        
                        count++;
                    }
                } catch (NumberFormatException e) {
                    context.getCounter("WeatherReducer", "VALUE_PARSING_ERRORS").increment(1);
                }
            }
            
            if (count > 0) {
                double avgUtilization = sumUtilization / count;
                double avgTemperature = sumTemperature / count;
                
                String output = String.format("%d,%.4f,%.2f,%.4f,%.4f", 
                    count, avgUtilization, avgTemperature, minUtilization, maxUtilization
                );
                
                result.set(output);
                context.write(key, result);
                context.getCounter("WeatherReducer", "OUTPUT_RECORDS").increment(1);
            }
        }
    }

    public static void main(String[] args) throws Exception {
        
        if (args.length != 2) {
            System.err.println("Usage: WeatherImpactAnalysis <input path> <output path>");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "EV Weather Impact Analysis");
        
        job.setJarByClass(WeatherImpactAnalysis.class);
        job.setMapperClass(WeatherMapper.class);
        job.setReducerClass(WeatherReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        System.out.println("==========================================================");
        System.out.println("EV Weather Impact Analysis - MapReduce Job");
        System.out.println("==========================================================");
        
        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}
