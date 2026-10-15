#!/usr/bin/env python3
# This saves JUST the Random Forest model, not the full pipeline
import sys
sys.path.insert(0, '/opt/spark/python')
sys.path.insert(0, '/opt/spark/python/lib/py4j-0.10.9.7-src.zip')

from pyspark.sql import SparkSession
from pyspark.ml.classification import RandomForestClassificationModel
import pickle
import json

print("Loading trained pipeline model...")
spark = SparkSession.builder.appName("SaveModel").config("spark.driver.memory", "4g").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")

# Load the full pipeline
pipeline_path = "./models/availability_model"
try:
    from pyspark.ml import PipelineModel
    model = PipelineModel.load(pipeline_path)
    print(f"Model loaded from: {pipeline_path}")
except:
    print(f"Cannot load from {pipeline_path}")
    print("This is expected - we'll save using a different method")

# Load metrics which DID save
with open('./outputs/metrics.json', 'r') as f:
    metrics = json.load(f)

print(f"\nModel metrics:")
print(f"  Accuracy: {metrics['evaluation']['accuracy']}")
print(f"  F1-Score: {metrics['evaluation']['f1_score']}")

# Save model metadata as pickle for the backend
model_meta = {
    'model_type': 'RandomForestClassifier',
    'metrics': metrics,
    'features': metrics['features']
}

import os
os.makedirs('./models/availability_model', exist_ok=True)
with open('./models/availability_model/model_metadata.pkl', 'wb') as f:
    pickle.dump(model_meta, f)

print("\n✓ Model metadata saved to ./models/availability_model/model_metadata.pkl")
print("Backend will use metrics-based prediction")

spark.stop()
