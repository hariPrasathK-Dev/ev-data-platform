#!/usr/bin/env python3
"""
EV Charging Station Data Inspection and Preprocessing Script
Analyzes the dataset, checks for data quality issues, and produces a cleaned version for Hadoop/Hive
"""

import pandas as pd
import numpy as np
from datetime import datetime

def inspect_dataset(filepath):
    """Load and inspect the EV charging station dataset"""
    print("="*80)
    print("EV CHARGING STATION DATASET INSPECTION")
    print("="*80)
    
    # Load dataset
    print(f"\n1. Loading dataset from: {filepath}")
    df = pd.read_csv(filepath)
    
    # Basic info
    print(f"\n2. BASIC INFORMATION")
    print(f"   Total rows: {len(df):,}")
    print(f"   Total columns: {len(df.columns)}")
    print(f"   Memory usage: {df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    # Column list
    print(f"\n3. COLUMNS ({len(df.columns)} total):")
    for i, col in enumerate(df.columns, 1):
        print(f"   {i:2d}. {col}")
    
    # Data types
    print(f"\n4. DATA TYPES:")
    for col in df.columns:
        print(f"   {col:35s} : {str(df[col].dtype)}")
    
    # Missing values
    print(f"\n5. MISSING VALUES:")
    missing = df.isnull().sum()
    missing_pct = (missing / len(df) * 100).round(2)
    has_missing = missing[missing > 0]
    
    if len(has_missing) > 0:
        for col in has_missing.index:
            print(f"   {col:35s} : {missing[col]:,} ({missing_pct[col]}%)")
    else:
        print("   No missing values detected!")
    
    # Duplicates
    print(f"\n6. DUPLICATE ROWS:")
    duplicates = df.duplicated().sum()
    print(f"   Total duplicate rows: {duplicates:,} ({duplicates/len(df)*100:.2f}%)")
    
    # Unique values for key columns
    print(f"\n7. UNIQUE VALUE COUNTS (Key Columns):")
    key_cols = ['station_id', 'station_name', 'network', 'city', 'state', 
                'charger_type', 'station_status', 'weather_condition']
    for col in key_cols:
        if col in df.columns:
            print(f"   {col:35s} : {df[col].nunique():,} unique values")
    
    # Numeric column statistics
    print(f"\n8. NUMERIC COLUMNS - BASIC STATISTICS:")
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    for col in numeric_cols:
        print(f"\n   {col}:")
        print(f"      Min    : {df[col].min()}")
        print(f"      Max    : {df[col].max()}")
        print(f"      Mean   : {df[col].mean():.2f}")
        print(f"      Median : {df[col].median():.2f}")
        print(f"      Std Dev: {df[col].std():.2f}")
    
    # Categorical column value counts (top 10)
    print(f"\n9. CATEGORICAL COLUMNS - TOP VALUES:")
    categorical_cols = ['network', 'state', 'charger_type', 'station_status', 
                       'weather_condition', 'pricing_type', 'location_type']
    for col in categorical_cols:
        if col in df.columns:
            print(f"\n   {col}:")
            top_values = df[col].value_counts().head(10)
            for val, count in top_values.items():
                print(f"      {str(val):30s} : {count:,} ({count/len(df)*100:.2f}%)")
    
    # Sample records
    print(f"\n10. SAMPLE RECORDS (First 5 rows):")
    print(df.head().to_string())
    
    return df


def preprocess_dataset(df):
    """Clean and preprocess the dataset for Hadoop/Hive"""
    print("\n" + "="*80)
    print("DATA PREPROCESSING")
    print("="*80)
    
    df_clean = df.copy()
    issues_fixed = []
    
    # 1. Handle timestamp
    print("\n1. Processing timestamp column...")
    if 'timestamp' in df_clean.columns:
        try:
            df_clean['timestamp'] = pd.to_datetime(df_clean['timestamp'])
            print("   ✓ Timestamp column converted to datetime")
        except Exception as e:
            print(f"   ✗ Error converting timestamp: {e}")
            issues_fixed.append("timestamp_conversion_failed")
    
    # 2. Handle missing values
    print("\n2. Handling missing values...")
    missing_before = df_clean.isnull().sum().sum()
    
    # Fill numeric nulls with median or 0
    numeric_cols = df_clean.select_dtypes(include=[np.number]).columns
    for col in numeric_cols:
        if df_clean[col].isnull().any():
            median_val = df_clean[col].median()
            df_clean[col].fillna(median_val, inplace=True)
            print(f"   ✓ Filled {col} nulls with median: {median_val}")
            issues_fixed.append(f"filled_nulls_{col}")
    
    # Fill categorical nulls with 'unknown'
    categorical_cols = df_clean.select_dtypes(include=['object']).columns
    for col in categorical_cols:
        if col != 'timestamp' and df_clean[col].isnull().any():
            df_clean[col].fillna('unknown', inplace=True)
            print(f"   ✓ Filled {col} nulls with 'unknown'")
            issues_fixed.append(f"filled_nulls_{col}")
    
    missing_after = df_clean.isnull().sum().sum()
    print(f"   Missing values: {missing_before} → {missing_after}")
    
    # 3. Remove duplicates
    print("\n3. Removing duplicate rows...")
    duplicates_before = df_clean.duplicated().sum()
    df_clean.drop_duplicates(inplace=True)
    duplicates_after = df_clean.duplicated().sum()
    print(f"   Duplicates removed: {duplicates_before}")
    print(f"   Rows remaining: {len(df_clean):,}")
    if duplicates_before > 0:
        issues_fixed.append(f"removed_{duplicates_before}_duplicates")
    
    # 4. Data validation
    print("\n4. Validating data constraints...")
    
    # Utilization rate should be between 0 and 1
    if 'utilization_rate' in df_clean.columns:
        invalid_util = ((df_clean['utilization_rate'] < 0) | 
                       (df_clean['utilization_rate'] > 1)).sum()
        if invalid_util > 0:
            df_clean['utilization_rate'] = df_clean['utilization_rate'].clip(0, 1)
            print(f"   ✓ Clipped {invalid_util} invalid utilization_rate values to [0, 1]")
            issues_fixed.append(f"clipped_utilization_rate")
    
    # Ports validation
    port_cols = ['ports_total', 'ports_available', 'ports_occupied', 'ports_out_of_service']
    if all(col in df_clean.columns for col in port_cols):
        # Negative ports don't make sense
        for col in port_cols:
            negative_count = (df_clean[col] < 0).sum()
            if negative_count > 0:
                df_clean[col] = df_clean[col].clip(lower=0)
                print(f"   ✓ Fixed {negative_count} negative values in {col}")
                issues_fixed.append(f"fixed_negative_{col}")
    
    # 5. Sort by timestamp and station_id
    print("\n5. Sorting data...")
    if 'timestamp' in df_clean.columns and 'station_id' in df_clean.columns:
        df_clean.sort_values(by=['station_id', 'timestamp'], inplace=True)
        print("   ✓ Sorted by station_id and timestamp")
    
    print(f"\n6. PREPROCESSING SUMMARY:")
    print(f"   Original rows: {len(df):,}")
    print(f"   Cleaned rows:  {len(df_clean):,}")
    print(f"   Rows removed:  {len(df) - len(df_clean):,}")
    print(f"   Issues fixed:  {len(issues_fixed)}")
    if issues_fixed:
        for issue in issues_fixed[:10]:  # Show first 10
            print(f"      - {issue}")
    
    return df_clean


def save_cleaned_data(df, output_path):
    """Save cleaned dataset to CSV for HDFS upload"""
    print(f"\n7. Saving cleaned data to: {output_path}")
    df.to_csv(output_path, index=False)
    print(f"   ✓ Saved {len(df):,} rows to {output_path}")
    
    # File size
    import os
    size_mb = os.path.getsize(output_path) / 1024**2
    print(f"   ✓ File size: {size_mb:.2f} MB")


def main():
    input_file = 'ev_charging_station_data.csv'
    output_file = 'ev_charging_station_data_cleaned.csv'
    
    # Inspect
    df = inspect_dataset(input_file)
    
    # Preprocess
    df_clean = preprocess_dataset(df)
    
    # Save
    save_cleaned_data(df_clean, output_file)
    
    print("\n" + "="*80)
    print("INSPECTION AND PREPROCESSING COMPLETE")
    print("="*80)
    print(f"\nCleaned dataset ready for HDFS upload: {output_file}")
    print("\nNext steps:")
    print("  1. Upload to HDFS: hdfs dfs -put ev_charging_station_data_cleaned.csv /home/hduser/Hive_Assignment/")
    print("  2. Verify upload:   hdfs dfs -ls /home/hduser/Hive_Assignment/")
    print("  3. Check content:   hdfs dfs -cat /home/hduser/Hive_Assignment/ev_charging_station_data_cleaned.csv | head -20")


if __name__ == "__main__":
    main()
