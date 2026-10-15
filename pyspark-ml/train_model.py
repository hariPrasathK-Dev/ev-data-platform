#!/usr/bin/env python3
"""
PySpark ML Pipeline - EV Charging Port Availability Prediction

Predicts whether at least one charging port is available based on:
- Station characteristics
- Time features (hour, day, weekend)
- Weather conditions
- Traffic patterns
- Pricing

Target: is_available = 1 if ports_available > 0, else 0
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when, hour, dayofweek, month
from pyspark.sql.types import DoubleType, IntegerType
from pyspark.ml.feature import StringIndexer, VectorAssembler, StandardScaler
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.evaluation import BinaryClassificationEvaluator, MulticlassClassificationEvaluator
from pyspark.ml import Pipeline
import json
import os
from datetime import datetime

print("=" * 80)
print("EV CHARGING PORT AVAILABILITY PREDICTION - ML TRAINING")
print("=" * 80)

# Initialize Spark
print("\n[1] Initializing Spark...")
spark = SparkSession.builder \
    .appName("EV Charging ML Training") \
    .config("spark.driver.memory", "4g") \
    .config("spark.executor.memory", "4g") \
    .config("spark.sql.shuffle.partitions", "8") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")
print(f"    Spark version: {spark.version}")
print(f"    Driver memory: 4g")

# Paths
CSV_PATH = "file:///home/hduser/ev-charging-station-availability-analytics/ev_charging_station_data_cleaned.csv"
MODEL_PATH = "./models/availability_model"
METRICS_PATH = "./outputs/metrics.json"
FEATURES_PATH = "./outputs/feature_importance.json"
CONFUSION_PATH = "./outputs/confusion_matrix.json"

print(f"\n[2] Loading dataset...")
print(f"    Path: {CSV_PATH}")

# Load CSV
df = spark.read.csv(CSV_PATH, header=True, inferSchema=True)
print(f"    Total records: {df.count():,}")
print(f"    Columns: {len(df.columns)}")

# ============================================================================
# 3. CREATE TARGET VARIABLE
# ============================================================================
print("\n[3] Creating target variable...")
print("    Target: is_available = 1 if ports_available > 0, else 0")

df = df.withColumn(
    "is_available",
    when(col("ports_available") > 0, 1).otherwise(0)
)

# Check class distribution
class_dist = df.groupBy("is_available").count().collect()
print("    Class distribution:")
for row in class_dist:
    label = "Available" if row["is_available"] == 1 else "Not Available"
    print(f"      {label}: {row['count']:,}")

# ============================================================================
# 4. FEATURE ENGINEERING - NO TARGET LEAKAGE
# ============================================================================
print("\n[4] Feature engineering...")
print("    Excluding target-leaking features:")
print("      ✗ ports_available (direct target)")
print("      ✗ ports_occupied (reveals availability)")
print("      ✗ utilization_rate (calculated from target)")
print("      ✗ estimated_wait_time_mins (reveals availability)")

# Select features (NO LEAKAGE)
feature_columns = [
    # Station characteristics
    'ports_total',
    'power_output_kw',
    
    # Time features (already extracted)
    'hour_of_day',
    'day_of_week',
    'month',
    'is_weekend',
    'is_peak_hour',
    
    # Weather
    'temperature_f',
    'precipitation_mm',
    
    # Context
    'traffic_congestion_index',
    'current_price',
    'gas_price_per_gallon',
    
    # Categorical (will be indexed)
    'network',
    'city',
    'state',
    'location_type',
    'charger_type',
    'pricing_type',
    'weather_condition'
]

print(f"    Selected {len(feature_columns)} features")

# Handle missing values
print("\n[5] Handling missing values...")
for col_name in feature_columns:
    null_count = df.filter(col(col_name).isNull()).count()
    if null_count > 0:
        print(f"      {col_name}: {null_count} nulls")
        # Fill numeric with median, categorical with 'unknown'
        if df.schema[col_name].dataType in [DoubleType(), IntegerType()]:
            median_val = df.approxQuantile(col_name, [0.5], 0.01)[0]
            df = df.fillna({col_name: median_val})
        else:
            df = df.fillna({col_name: 'unknown'})

# ============================================================================
# 6. ENCODE CATEGORICAL FEATURES
# ============================================================================
print("\n[6] Encoding categorical features...")
categorical_cols = ['network', 'city', 'state', 'location_type', 'charger_type', 
                   'pricing_type', 'weather_condition']
indexers = []
indexed_cols = []

for cat_col in categorical_cols:
    indexer = StringIndexer(inputCol=cat_col, outputCol=f"{cat_col}_indexed", handleInvalid="keep")
    indexers.append(indexer)
    indexed_cols.append(f"{cat_col}_indexed")
    unique_count = df.select(cat_col).distinct().count()
    print(f"    {cat_col}: {unique_count} unique values")

# ============================================================================
# 7. CHRONOLOGICAL TRAIN/TEST SPLIT
# ============================================================================
print("\n[7] Splitting data chronologically...")
print("    Train: First 70% of records (by time)")
print("    Test: Last 30% of records (by time)")

# Add row number based on timestamp
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number, monotonically_increasing_id

df = df.withColumn("row_id", monotonically_increasing_id())
total_rows = df.count()
train_cutoff = int(total_rows * 0.7)

train_df = df.filter(col("row_id") < train_cutoff)
test_df = df.filter(col("row_id") >= train_cutoff)

print(f"    Training records: {train_df.count():,}")
print(f"    Test records: {test_df.count():,}")

# ============================================================================
# 8. BUILD ML PIPELINE
# ============================================================================
print("\n[8] Building ML pipeline...")

# Numeric features
numeric_features = ['ports_total', 'power_output_kw', 'hour_of_day', 'day_of_week',
                   'month', 'is_weekend', 'is_peak_hour', 'temperature_f', 
                   'precipitation_mm', 'traffic_congestion_index', 
                   'current_price', 'gas_price_per_gallon']

# All features for vector assembler
all_features = numeric_features + indexed_cols

# Assemble features
assembler = VectorAssembler(inputCols=all_features, outputCol="features_raw")

# Scale features
scaler = StandardScaler(inputCol="features_raw", outputCol="features")

# Random Forest Classifier
rf = RandomForestClassifier(
    featuresCol="features",
    labelCol="is_available",
    numTrees=100,
    maxDepth=10,
    minInstancesPerNode=5,
    seed=42
)

# Build pipeline
pipeline = Pipeline(stages=indexers + [assembler, scaler, rf])

print("    Pipeline stages:")
print(f"      1-{len(indexers)}: String indexers for categorical features")
print(f"      {len(indexers)+1}: Vector assembler ({len(all_features)} features)")
print(f"      {len(indexers)+2}: Standard scaler")
print(f"      {len(indexers)+3}: Random Forest (100 trees, max depth 10)")

# ============================================================================
# 9. TRAIN MODEL
# ============================================================================
print("\n[9] Training model...")
print("    This may take several minutes for 1.3M records...")

start_time = datetime.now()
model = pipeline.fit(train_df)
end_time = datetime.now()
training_time = (end_time - start_time).total_seconds()

print(f"    ✓ Training complete in {training_time:.1f} seconds")

# ============================================================================
# 10. EVALUATE MODEL
# ============================================================================
print("\n[10] Evaluating model on test set...")

predictions = model.transform(test_df)

# Binary classification metrics
binary_evaluator = BinaryClassificationEvaluator(
    labelCol="is_available",
    rawPredictionCol="rawPrediction",
    metricName="areaUnderROC"
)

roc_auc = binary_evaluator.evaluate(predictions)
print(f"    ROC-AUC: {roc_auc:.4f}")

# Multiclass metrics
mc_evaluator = MulticlassClassificationEvaluator(
    labelCol="is_available",
    predictionCol="prediction"
)

accuracy = mc_evaluator.evaluate(predictions, {mc_evaluator.metricName: "accuracy"})
precision = mc_evaluator.evaluate(predictions, {mc_evaluator.metricName: "weightedPrecision"})
recall = mc_evaluator.evaluate(predictions, {mc_evaluator.metricName: "weightedRecall"})
f1 = mc_evaluator.evaluate(predictions, {mc_evaluator.metricName: "f1"})

print(f"    Accuracy:  {accuracy:.4f}")
print(f"    Precision: {precision:.4f}")
print(f"    Recall:    {recall:.4f}")
print(f"    F1-Score:  {f1:.4f}")

# Confusion matrix
confusion = predictions.groupBy("is_available", "prediction").count().collect()
print("\n    Confusion Matrix:")
print("    " + "-" * 40)
conf_matrix = {}
for row in confusion:
    actual = "Available" if row["is_available"] == 1 else "Not Available"
    pred = "Available" if row["prediction"] == 1.0 else "Not Available"
    count = row["count"]
    print(f"      Actual: {actual:15s} | Predicted: {pred:15s} | {count:,}")
    conf_matrix[f"actual_{row['is_available']}_pred_{int(row['prediction'])}"] = count

# ============================================================================
# 11. FEATURE IMPORTANCE
# ============================================================================
print("\n[11] Extracting feature importance...")

rf_model = model.stages[-1]
feature_importance = rf_model.featureImportances.toArray()

# Map to feature names
feature_importance_dict = {}
for idx, importance in enumerate(feature_importance):
    if idx < len(all_features):
        feature_name = all_features[idx]
        feature_importance_dict[feature_name] = float(importance)

# Sort by importance
sorted_features = sorted(feature_importance_dict.items(), key=lambda x: x[1], reverse=True)
print("    Top 10 features:")
for feature, importance in sorted_features[:10]:
    print(f"      {feature:30s}: {importance:.4f}")

# ============================================================================
# 12. SAVE MODEL AND METRICS
# ============================================================================
print("\n[12] Saving model and metrics...")

# Save model
try:
    # Ensure models directory exists and is writable
    import os
    model_dir = os.path.dirname(MODEL_PATH)
    if not os.path.exists(model_dir):
        os.makedirs(model_dir, exist_ok=True)
        print(f"    Created directory: {model_dir}")
    
    # Check write permissions
    if not os.access(model_dir, os.W_OK):
        raise PermissionError(f"Cannot write to {model_dir} - permission denied")
    
    print(f"    Saving model to: {os.path.abspath(MODEL_PATH)}")
    model.write().overwrite().save(MODEL_PATH)
    
    # Verify model was actually saved
    if os.path.exists(MODEL_PATH) and os.listdir(MODEL_PATH):
        file_count = len([f for f in os.listdir(MODEL_PATH) if not f.startswith('.')])
        print(f"    ✓ Model saved successfully: {MODEL_PATH}")
        print(f"    ✓ Model contains {file_count} files/directories")
    else:
        raise Exception(f"Model directory exists but is empty: {MODEL_PATH}")
        
except Exception as e:
    print(f"    ✗ ERROR saving model: {e}")
    print(f"    Directory permissions:")
    import subprocess
    result = subprocess.run(['ls', '-la', model_dir], capture_output=True, text=True)
    print(f"    {result.stdout}")
    raise

# Save metrics
metrics = {
    "model_type": "RandomForestClassifier",
    "training_date": datetime.now().isoformat(),
    "training_time_seconds": training_time,
    "dataset_size": {
        "total_records": total_rows,
        "train_records": train_df.count(),
        "test_records": test_df.count()
    },
    "class_distribution": {
        "available": class_dist[1]["count"] if len(class_dist) > 1 else 0,
        "not_available": class_dist[0]["count"]
    },
    "features": {
        "count": len(all_features),
        "numeric": numeric_features,
        "categorical": categorical_cols
    },
    "hyperparameters": {
        "num_trees": 100,
        "max_depth": 10,
        "min_instances_per_node": 5
    },
    "evaluation": {
        "roc_auc": round(roc_auc, 4),
        "accuracy": round(accuracy, 4),
        "precision": round(precision, 4),
        "recall": round(recall, 4),
        "f1_score": round(f1, 4)
    },
    "confusion_matrix": conf_matrix
}

with open(METRICS_PATH, 'w') as f:
    json.dump(metrics, f, indent=2)
print(f"    ✓ Metrics saved: {METRICS_PATH}")

# Save feature importance
with open(FEATURES_PATH, 'w') as f:
    json.dump(dict(sorted_features), f, indent=2)
print(f"    ✓ Feature importance saved: {FEATURES_PATH}")

# Save confusion matrix separately
with open(CONFUSION_PATH, 'w') as f:
    json.dump(conf_matrix, f, indent=2)
print(f"    ✓ Confusion matrix saved: {CONFUSION_PATH}")

# ============================================================================
# 13. TEST PREDICTIONS
# ============================================================================
print("\n[13] Testing predictions on sample data...")

sample_predictions = predictions.select(
    "station_id", "station_name", "hour_of_day", "weather_condition",
    "is_available", "prediction", "probability"
).limit(5).collect()

print("    Sample predictions:")
for pred in sample_predictions:
    actual = "Available" if pred["is_available"] == 1 else "Not Available"
    predicted = "Available" if pred["prediction"] == 1.0 else "Not Available"
    confidence = pred["probability"][int(pred["prediction"])] * 100
    print(f"      {pred['station_name'][:30]:30s} | Hour: {pred['hour_of_day']:2d} | "
          f"Actual: {actual:15s} | Predicted: {predicted:15s} ({confidence:.1f}%)")

print("\n" + "=" * 80)
print("TRAINING COMPLETE!")
print("=" * 80)
print(f"\nModel saved to: {MODEL_PATH}")
print(f"Metrics saved to: {METRICS_PATH}")
print("\nNext steps:")
print("  1. Check metrics.json for detailed evaluation")
print("  2. Use predict.py to make predictions on new data")
print("  3. Backend API will load this model for /api/ml/predict endpoint")
print("=" * 80)

spark.stop()
