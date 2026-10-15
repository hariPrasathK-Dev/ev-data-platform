import org.apache.spark.{SparkConf, SparkContext}
import org.apache.spark.rdd.RDD
import java.io.PrintWriter

object EVChargingRDDAnalysis {
  
  def main(args: Array[String]): Unit = {
    // Initialize Spark
    val conf = new SparkConf()
      .setAppName("EV Charging Station RDD Analysis")
      .setMaster("local[*]")
    
    val sc = new SparkContext(conf)
    sc.setLogLevel("WARN")
    
    println("=" * 80)
    println("EV CHARGING STATION RDD ANALYSIS")
    println("=" * 80)
    
    val csvPath = if (args.length > 0) args(0) else "../ev_charging_station_data_cleaned.csv"
    val outputPath = if (args.length > 1) args(1) else "../data/processed/spark"
    
    println(s"\nInput: $csvPath")
    println(s"Output: $outputPath")
    
    // ========================================================================
    // 1. RDD CREATION
    // ========================================================================
    println("\n[1] Creating RDD from CSV...")
    val rawRDD = sc.textFile(csvPath)
    val header = rawRDD.first()
    
    // Remove header and parse CSV
    val dataRDD: RDD[Array[String]] = rawRDD
      .filter(line => line != header)
      .map(line => parseCSVLine(line))
      .filter(_.length >= 33) // Valid records only
    
    // Cache for reuse
    dataRDD.cache()
    
    val totalRecords = dataRDD.count()
    println(s"   Total records: $totalRecords")
    println(s"   Partitions: ${dataRDD.getNumPartitions}")
    
    // ========================================================================
    // 2. TRANSFORMATIONS - Map, Filter, FlatMap
    // ========================================================================
    println("\n[2] Applying Transformations...")
    
    // Transformation 1: MAP - Extract key fields
    println("   - map(): Extracting (network, utilization, city)")
    val networkUtilRDD: RDD[(String, Double, String)] = dataRDD.map { fields =>
      val network = fields(3)
      val city = fields(4)
      val utilization = try { fields(16).toDouble } catch { case _: Exception => 0.0 }
      (network, utilization, city)
    }
    
    // Transformation 2: FILTER - Only operational stations
    println("   - filter(): Keeping only operational stations")
    val operationalRDD = dataRDD.filter { fields =>
      fields(17) == "operational"
    }
    
    // Transformation 3: FLATMAP - Extract all weather conditions
    println("   - flatMap(): Extracting weather conditions")
    val weatherRDD: RDD[String] = dataRDD.flatMap { fields =>
      val weather = fields(24)
      if (weather.nonEmpty) Some(weather) else None
    }
    
    // ========================================================================
    // 3. ACTIONS - Count, Take, Reduce
    // ========================================================================
    println("\n[3] Executing Actions...")
    
    // Action 1: COUNT
    val operationalCount = operationalRDD.count()
    println(s"   - count(): Operational stations = $operationalCount")
    
    // Action 2: TAKE - Sample records
    println("   - take(3): First 3 operational stations:")
    operationalRDD.take(3).foreach { fields =>
      println(s"      ${fields(2)} in ${fields(4)}, ${fields(5)}")
    }
    
    // Action 3: REDUCE - Sum all utilization rates
    val totalUtilization = networkUtilRDD.map(_._2).reduce(_ + _)
    val avgUtilization = totalUtilization / totalRecords
    println(f"   - reduce(): Average utilization = $avgUtilization%.3f")
    
    // ========================================================================
    // 4. KEY-VALUE OPERATIONS - ReduceByKey
    // ========================================================================
    println("\n[4] Key-Value Operations (reduceByKey)...")
    
    // Network utilization analysis
    val networkPairRDD: RDD[(String, (Double, Int))] = networkUtilRDD.map { case (network, util, _) =>
      (network, (util, 1))
    }
    
    val networkStats: RDD[(String, (Double, Int))] = networkPairRDD.reduceByKey { 
      case ((util1, count1), (util2, count2)) =>
        (util1 + util2, count1 + count2)
    }
    
    val networkAvgUtilization = networkStats.map { case (network, (totalUtil, count)) =>
      (network, totalUtil / count, count)
    }.sortBy(_._2, ascending = false)
    
    println("   Network Performance:")
    networkAvgUtilization.collect().foreach { case (network, avgUtil, count) =>
      println(f"      $network%-20s: $avgUtil%.3f ($count observations)")
    }
    
    // City analysis
    val cityPairRDD: RDD[(String, (Double, Int))] = networkUtilRDD.map { case (_, util, city) =>
      (city, (util, 1))
    }
    
    val cityStats = cityPairRDD.reduceByKey { 
      case ((util1, count1), (util2, count2)) =>
        (util1 + util2, count1 + count2)
    }
    
    val cityAvgUtilization = cityStats.map { case (city, (totalUtil, count)) =>
      (city, totalUtil / count, count)
    }.sortBy(_._2, ascending = false)
    
    // Hourly utilization
    val hourlyPairRDD: RDD[(Int, (Double, Int))] = dataRDD.map { fields =>
      val hour = try { fields(30).toInt } catch { case _: Exception => -1 }
      val util = try { fields(16).toDouble } catch { case _: Exception => 0.0 }
      (hour, (util, 1))
    }.filter(_._1 >= 0)
    
    val hourlyStats = hourlyPairRDD.reduceByKey {
      case ((util1, count1), (util2, count2)) =>
        (util1 + util2, count1 + count2)
    }
    
    val hourlyAvgUtilization = hourlyStats.map { case (hour, (totalUtil, count)) =>
      (hour, totalUtil / count, count)
    }.sortBy(_._1)
    
    // ========================================================================
    // 5. CACHE AND PERSIST
    // ========================================================================
    println("\n[5] Demonstrating Cache/Persist...")
    println(s"   - dataRDD is cached: ${dataRDD.getStorageLevel}")
    println(s"   - Reusing cached RDD for multiple operations")
    
    val statusDistribution = dataRDD.map(_(17)).countByValue()
    println("   Status distribution (from cached RDD):")
    statusDistribution.foreach { case (status, count) =>
      println(f"      $status%-20s: $count")
    }
    
    // ========================================================================
    // 6. RDD LINEAGE
    // ========================================================================
    println("\n[6] RDD Lineage and DAG...")
    println("   Lineage for networkStats RDD:")
    println(networkStats.toDebugString)
    
    println("\n   DAG Explanation:")
    println("   1. textFile() -> creates HadoopRDD (narrow)")
    println("   2. filter() -> removes header (narrow)")
    println("   3. map() -> parses CSV (narrow)")
    println("   4. map() -> creates key-value pairs (narrow)")
    println("   5. reduceByKey() -> aggregates by key (SHUFFLE - wide transformation)")
    println("   6. map() -> calculates averages (narrow)")
    println("   7. sortBy() -> sorts results (SHUFFLE - wide transformation)")
    println("\n   Shuffle boundaries occur at reduceByKey and sortBy")
    
    // ========================================================================
    // 7. SAVE OUTPUTS
    // ========================================================================
    println("\n[7] Saving Outputs...")
    
    import java.io.File
    val outputDir = new File(outputPath)
    if (!outputDir.exists()) {
      outputDir.mkdirs()
      println(s"   Created output directory: $outputPath")
    }
    
    // Save network stats
    val networkFile = new PrintWriter(s"$outputPath/network_stats.json")
    networkFile.println("[")
    val networkResults = networkAvgUtilization.collect()
    networkResults.zipWithIndex.foreach { case ((network, avgUtil, count), idx) =>
      val comma = if (idx < networkResults.length - 1) "," else ""
      networkFile.println(s"""  {"network": "$network", "avg_utilization": $avgUtil, "observations": $count}$comma""")
    }
    networkFile.println("]")
    networkFile.close()
    println(s"   ✓ Saved: $outputPath/network_stats.json")
    
    // Save city stats
    val cityFile = new PrintWriter(s"$outputPath/city_stats.json")
    cityFile.println("[")
    val cityResults = cityAvgUtilization.collect()
    cityResults.zipWithIndex.foreach { case ((city, avgUtil, count), idx) =>
      val comma = if (idx < cityResults.length - 1) "," else ""
      cityFile.println(s"""  {"city": "$city", "avg_utilization": $avgUtil, "observations": $count}$comma""")
    }
    cityFile.println("]")
    cityFile.close()
    println(s"   ✓ Saved: $outputPath/city_stats.json")
    
    // Save hourly stats
    val hourlyFile = new PrintWriter(s"$outputPath/hourly_stats.json")
    hourlyFile.println("[")
    val hourlyResults = hourlyAvgUtilization.collect()
    hourlyResults.zipWithIndex.foreach { case ((hour, avgUtil, count), idx) =>
      val comma = if (idx < hourlyResults.length - 1) "," else ""
      hourlyFile.println(s"""  {"hour": $hour, "avg_utilization": $avgUtil, "observations": $count}$comma""")
    }
    hourlyFile.println("]")
    hourlyFile.close()
    println(s"   ✓ Saved: $outputPath/hourly_stats.json")
    
    // Save summary
    val summaryFile = new PrintWriter(s"$outputPath/summary.json")
    summaryFile.println("{")
    summaryFile.println(s"""  "total_records": $totalRecords,""")
    summaryFile.println(s"""  "operational_records": $operationalCount,""")
    summaryFile.println(f"""  "avg_utilization": $avgUtilization%.3f,""")
    summaryFile.println(s"""  "partitions": ${dataRDD.getNumPartitions},""")
    summaryFile.println(s"""  "cached": true""")
    summaryFile.println("}")
    summaryFile.close()
    println(s"   ✓ Saved: $outputPath/summary.json")
    
    println("\n" + "=" * 80)
    println("ANALYSIS COMPLETE!")
    println("=" * 80)
    
    sc.stop()
  }
  
  // CSV parser handling quoted fields
  def parseCSVLine(line: String): Array[String] = {
    val regex = ",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)"
    line.split(regex).map(_.trim.replaceAll("^\"|\"$", ""))
  }
}
