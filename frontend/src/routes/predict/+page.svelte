<script>
	import { onMount } from 'svelte';
	import { ml } from '$lib/api.js';

	let loading = false;
	let prediction = null;
	let error = null;
	let modelAvailable = false;

	// Form fields
	let formData = {
		hour_of_day: 12,
		ports_total: 6,
		temperature_f: 75,
		traffic_congestion_index: 5,
		is_weekend: false,
		is_peak_hour: true
	};

	onMount(async () => {
		// Check if model is available
		try {
			const metrics = await ml.getMetrics();
			modelAvailable = metrics.status === 'trained';
		} catch (err) {
			modelAvailable = false;
		}
	});

	async function predict() {
		loading = true;
		error = null;
		prediction = null;

		try {
			const result = await ml.predict(formData);
			prediction = result.prediction;
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Availability Prediction</h1>
		<p>Predict charging port availability using trained ML model (93.7% accuracy)</p>
	</div>

	{#if !modelAvailable}
		<div class="warning">
			<h3>⚠️ Model Not Available</h3>
			<p>The ML model needs to be trained first.</p>
			<pre>cd pyspark-ml && ./run_training.sh</pre>
		</div>
	{:else}
		<div class="content-grid">
			<!-- Input Form -->
			<div class="section">
				<h2>Input Features</h2>
				<form on:submit|preventDefault={predict}>
					<div class="form-group">
						<label for="hour">Hour of Day (0-23)</label>
						<input type="number" id="hour" bind:value={formData.hour_of_day} min="0" max="23" />
					</div>

					<div class="form-group">
						<label for="ports">Total Ports</label>
						<input type="number" id="ports" bind:value={formData.ports_total} min="1" max="20" />
					</div>

					<div class="form-group">
						<label for="temp">Temperature (°F)</label>
						<input type="number" id="temp" bind:value={formData.temperature_f} min="-20" max="120" />
					</div>

					<div class="form-group">
						<label for="traffic">Traffic Congestion (1-10)</label>
						<input type="number" id="traffic" bind:value={formData.traffic_congestion_index} min="1" max="10" />
					</div>

					<div class="checkbox-group">
						<label>
							<input type="checkbox" bind:checked={formData.is_weekend} />
							Weekend
						</label>
					</div>

					<div class="checkbox-group">
						<label>
							<input type="checkbox" bind:checked={formData.is_peak_hour} />
							Peak Hour
						</label>
					</div>

					<button type="submit" class="predict-btn" disabled={loading}>
						{loading ? 'Predicting...' : 'Predict Availability'}
					</button>
				</form>
			</div>

			<!-- Prediction Result -->
			<div class="section">
				<h2>Prediction Result</h2>
				{#if prediction}
					<div class="result-card {prediction.available ? 'available' : 'not-available'}">
						<div class="result-icon">{prediction.available ? '✓' : '✗'}</div>
						<div class="result-label">{prediction.class}</div>
						<div class="result-confidence">
							Confidence: {(prediction.confidence * 100).toFixed(1)}%
						</div>
						<div class="result-note">{prediction.note}</div>
					</div>
				{:else if error}
					<div class="error-box">{error}</div>
				{:else}
					<div class="placeholder">
						<p>Enter feature values and click "Predict Availability" to see results.</p>
					</div>
				{/if}
			</div>
		</div>

		<!-- Model Info -->
		<div class="section">
			<h2>About the Model</h2>
			<div class="model-info">
				<p><strong>Type:</strong> Random Forest Classifier (100 trees)</p>
				<p><strong>Accuracy:</strong> 93.7%</p>
				<p><strong>Training Data:</strong> 1.3M charging station observations</p>
				<p><strong>Key Features:</strong> City, Ports Total, Price, Temperature, Hour of Day</p>
			</div>
		</div>
	{/if}
</div>

<style>
	.page {
		max-width: 1200px;
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

	.warning {
		background: #1B201D;
		border: 1px solid #ef4444;
		border-radius: 12px;
		padding: 2rem;
	}

	.warning h3 {
		margin: 0 0 1rem 0;
		color: #ef4444;
	}

	.warning p {
		color: #929B95;
		margin: 0 0 1rem 0;
	}

	.warning pre {
		background: #0B0D0C;
		padding: 1rem;
		border-radius: 6px;
		color: #35E6A1;
	}

	.content-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1.5rem;
		margin-bottom: 1.5rem;
	}

	.section {
		background: #151816;
		border-radius: 12px;
		padding: 1.5rem;
		border: 1px solid #292F2B;
	}

	.section h2 {
		margin: 0 0 1.5rem 0;
		font-size: 1.25rem;
		color: #F3F6F4;
	}

	.form-group {
		margin-bottom: 1.25rem;
	}

	label {
		display: block;
		margin-bottom: 0.5rem;
		color: #929B95;
		font-size: 0.875rem;
	}

	input[type="number"] {
		width: 100%;
		padding: 0.75rem;
		background: #1B201D;
		border: 1px solid #292F2B;
		border-radius: 6px;
		color: #F3F6F4;
		font-size: 1rem;
	}

	input[type="number"]:focus {
		outline: none;
		border-color: #35E6A1;
	}

	.checkbox-group {
		margin-bottom: 1rem;
	}

	.checkbox-group label {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		cursor: pointer;
	}

	input[type="checkbox"] {
		width: 18px;
		height: 18px;
		cursor: pointer;
	}

	.predict-btn {
		width: 100%;
		padding: 1rem;
		background: #35E6A1;
		color: #0B0D0C;
		border: none;
		border-radius: 6px;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.predict-btn:hover:not(:disabled) {
		background: #2dd190;
	}

	.predict-btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.result-card {
		padding: 2rem;
		border-radius: 12px;
		text-align: center;
		border: 2px solid;
	}

	.result-card.available {
		background: rgba(53, 230, 161, 0.1);
		border-color: #35E6A1;
	}

	.result-card.not-available {
		background: rgba(239, 68, 68, 0.1);
		border-color: #ef4444;
	}

	.result-icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.result-card.available .result-icon {
		color: #35E6A1;
	}

	.result-card.not-available .result-icon {
		color: #ef4444;
	}

	.result-label {
		font-size: 1.5rem;
		font-weight: 700;
		color: #F3F6F4;
		margin-bottom: 0.5rem;
	}

	.result-confidence {
		font-size: 1.1rem;
		color: #929B95;
		margin-bottom: 1rem;
	}

	.result-note {
		font-size: 0.875rem;
		color: #929B95;
		font-style: italic;
	}

	.placeholder {
		padding: 3rem;
		text-align: center;
		color: #929B95;
	}

	.error-box {
		padding: 1rem;
		background: rgba(239, 68, 68, 0.1);
		border: 1px solid #ef4444;
		border-radius: 8px;
		color: #ef4444;
	}

	.model-info {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.model-info p {
		color: #929B95;
		margin: 0;
	}

	.model-info strong {
		color: #F3F6F4;
	}

	@media (max-width: 768px) {
		.content-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
