<script>
	import { onMount } from 'svelte';
	import { ml } from '$lib/api.js';

	let loading = true;
	let mlData = null;
	let error = null;

	onMount(async () => {
		await loadMLData();
	});

	async function loadMLData() {
		loading = true;
		error = null;
		
		try {
			mlData = await ml.getMetrics();
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}

	function formatPercent(num) {
		return (num * 100).toFixed(1) + '%';
	}

	function formatNumber(num) {
		return new Intl.NumberFormat().format(num);
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Machine Learning Model</h1>
		<p>Random Forest Classifier for Port Availability Prediction</p>
	</div>

	{#if loading}
		<div class="loading">
			<div class="spinner"></div>
			<p>Loading model metrics...</p>
		</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if mlData && mlData.status === 'trained'}
		<!-- Model Info -->
		<div class="section">
			<h2>Model Information</h2>
			<div class="info-grid">
				<div class="info-card">
					<div class="label">Model Type</div>
					<div class="value">{mlData.metrics.model_type}</div>
				</div>
				<div class="info-card">
					<div class="label">Training Date</div>
					<div class="value">{new Date(mlData.metrics.training_date).toLocaleDateString()}</div>
				</div>
				<div class="info-card">
					<div class="label">Training Time</div>
					<div class="value">{Math.round(mlData.metrics.training_time_seconds)} seconds</div>
				</div>
				<div class="info-card">
					<div class="label">Features</div>
					<div class="value">{mlData.metrics.features.count} features</div>
				</div>
			</div>
		</div>

		<!-- Performance Metrics -->
		<div class="section">
			<h2>Model Performance</h2>
			<div class="metrics-grid">
				<div class="metric-card">
					<div class="metric-value accuracy">{formatPercent(mlData.metrics.evaluation.accuracy)}</div>
					<div class="metric-label">Accuracy</div>
				</div>
				<div class="metric-card">
					<div class="metric-value">{formatPercent(mlData.metrics.evaluation.precision)}</div>
					<div class="metric-label">Precision</div>
				</div>
				<div class="metric-card">
					<div class="metric-value">{formatPercent(mlData.metrics.evaluation.recall)}</div>
					<div class="metric-label">Recall</div>
				</div>
				<div class="metric-card">
					<div class="metric-value">{formatPercent(mlData.metrics.evaluation.f1_score)}</div>
					<div class="metric-label">F1-Score</div>
				</div>
				<div class="metric-card">
					<div class="metric-value">{mlData.metrics.evaluation.roc_auc.toFixed(4)}</div>
					<div class="metric-label">ROC-AUC</div>
				</div>
			</div>
		</div>

		<!-- Dataset Info -->
		<div class="section">
			<h2>Training Dataset</h2>
			<div class="dataset-grid">
				<div class="dataset-card">
					<div class="dataset-label">Total Records</div>
					<div class="dataset-value">{formatNumber(mlData.metrics.dataset_size.total_records)}</div>
				</div>
				<div class="dataset-card">
					<div class="dataset-label">Training Records</div>
					<div class="dataset-value">{formatNumber(mlData.metrics.dataset_size.train_records)}</div>
				</div>
				<div class="dataset-card">
					<div class="dataset-label">Test Records</div>
					<div class="dataset-value">{formatNumber(mlData.metrics.dataset_size.test_records)}</div>
				</div>
			</div>
		</div>

		<!-- Feature Importance -->
		<div class="section">
			<h2>Top 10 Most Important Features</h2>
			<div class="features-container">
				{#each mlData.top_features as feature, i}
				<div class="feature-row">
					<div class="feature-rank">{i + 1}</div>
					<div class="feature-name">{feature.feature}</div>
					<div class="feature-bar-container">
						<div class="feature-bar" style="width: {feature.importance * 100}%"></div>
					</div>
					<div class="feature-importance">{formatPercent(feature.importance)}</div>
				</div>
				{/each}
			</div>
		</div>

		<!-- Hyperparameters -->
		<div class="section">
			<h2>Model Configuration</h2>
			<div class="config-grid">
				<div class="config-item">
					<span class="config-label">Number of Trees:</span>
					<span class="config-value">{mlData.metrics.hyperparameters.num_trees}</span>
				</div>
				<div class="config-item">
					<span class="config-label">Max Depth:</span>
					<span class="config-value">{mlData.metrics.hyperparameters.max_depth}</span>
				</div>
				<div class="config-item">
					<span class="config-label">Min Instances Per Node:</span>
					<span class="config-value">{mlData.metrics.hyperparameters.min_instances_per_node}</span>
				</div>
			</div>
		</div>

		<!-- Class Distribution -->
		<div class="section">
			<h2>Class Distribution</h2>
			<div class="class-grid">
				<div class="class-card available">
					<div class="class-label">Available</div>
					<div class="class-value">{formatNumber(mlData.metrics.class_distribution.available)}</div>
					<div class="class-percent">
						{formatPercent(mlData.metrics.class_distribution.available / mlData.metrics.dataset_size.total_records)}
					</div>
				</div>
				<div class="class-card not-available">
					<div class="class-label">Not Available</div>
					<div class="class-value">{formatNumber(mlData.metrics.class_distribution.not_available)}</div>
					<div class="class-percent">
						{formatPercent(mlData.metrics.class_distribution.not_available / mlData.metrics.dataset_size.total_records)}
					</div>
				</div>
			</div>
		</div>
	{:else}
		<div class="not-trained">
			<h2>Model Not Trained</h2>
			<p>Train the ML model to see metrics here.</p>
			<pre>cd pyspark-ml && ./run_training.sh</pre>
		</div>
	{/if}
</div>

<style>
	.page {
		max-width: 1400px;
		margin: 0 auto;
	}

	.page-header h1 {
		margin: 0 0 0.5rem 0;
		font-size: 2rem;
		color: #F3F6F4;
		font-weight: 700;
	}

	.page-header p {
		margin: 0 0 2rem 0;
		color: #929B95;
	}

	.loading {
		display: flex;
		flex-direction: column;
		align-items: center;
		padding: 3rem;
		color: #929B95;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #292F2B;
		border-top-color: #35E6A1;
		border-radius: 50%;
		animation: spin 0.8s linear infinite;
		margin-bottom: 1rem;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	.error, .not-trained {
		background: #151816;
		padding: 2rem;
		border-radius: 12px;
		border: 1px solid #292F2B;
		color: #929B95;
	}

	.not-trained h2 {
		color: #F3F6F4;
		margin: 0 0 1rem 0;
	}

	.not-trained pre {
		background: #0B0D0C;
		padding: 1rem;
		border-radius: 6px;
		color: #35E6A1;
		margin-top: 1rem;
	}

	.section {
		background: #151816;
		border-radius: 12px;
		padding: 1.5rem;
		margin-bottom: 1.5rem;
		border: 1px solid #292F2B;
	}

	.section h2 {
		margin: 0 0 1.5rem 0;
		font-size: 1.25rem;
		color: #F3F6F4;
	}

	.info-grid, .dataset-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1rem;
	}

	.info-card, .dataset-card {
		background: #1B201D;
		padding: 1rem;
		border-radius: 8px;
	}

	.label, .dataset-label {
		font-size: 0.75rem;
		color: #929B95;
		margin-bottom: 0.5rem;
	}

	.value, .dataset-value {
		font-size: 1.1rem;
		color: #F3F6F4;
		font-weight: 600;
	}

	.metrics-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
		gap: 1rem;
	}

	.metric-card {
		background: #1B201D;
		padding: 1.5rem;
		border-radius: 8px;
		text-align: center;
	}

	.metric-value {
		font-size: 2rem;
		color: #35E6A1;
		font-weight: 700;
		margin-bottom: 0.5rem;
	}

	.metric-value.accuracy {
		font-size: 2.5rem;
	}

	.metric-label {
		font-size: 0.875rem;
		color: #929B95;
	}

	.features-container {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.feature-row {
		display: grid;
		grid-template-columns: 40px 200px 1fr 80px;
		gap: 1rem;
		align-items: center;
		background: #1B201D;
		padding: 1rem;
		border-radius: 8px;
	}

	.feature-rank {
		font-weight: 700;
		color: #35E6A1;
		font-size: 1.25rem;
	}

	.feature-name {
		color: #F3F6F4;
		font-size: 0.9rem;
	}

	.feature-bar-container {
		background: #0B0D0C;
		height: 8px;
		border-radius: 4px;
		overflow: hidden;
	}

	.feature-bar {
		height: 100%;
		background: linear-gradient(90deg, #35E6A1, #2dd190);
		border-radius: 4px;
	}

	.feature-importance {
		color: #929B95;
		font-size: 0.875rem;
		text-align: right;
	}

	.config-grid {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.config-item {
		display: flex;
		justify-content: space-between;
		padding: 0.75rem;
		background: #1B201D;
		border-radius: 8px;
	}

	.config-label {
		color: #929B95;
	}

	.config-value {
		color: #35E6A1;
		font-weight: 600;
	}

	.class-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1rem;
	}

	.class-card {
		background: #1B201D;
		padding: 1.5rem;
		border-radius: 8px;
		text-align: center;
	}

	.class-label {
		font-size: 0.875rem;
		color: #929B95;
		margin-bottom: 0.5rem;
	}

	.class-value {
		font-size: 1.75rem;
		font-weight: 700;
		margin-bottom: 0.25rem;
	}

	.class-card.available .class-value {
		color: #35E6A1;
	}

	.class-card.not-available .class-value {
		color: #ef4444;
	}

	.class-percent {
		font-size: 0.875rem;
		color: #929B95;
	}
</style>
