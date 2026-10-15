<script>
	import { onMount } from 'svelte';
	import { spark } from '$lib/api.js';

	let loading = true;
	let sparkData = null;
	let error = null;

	onMount(async () => {
		await loadSparkData();
	});

	async function loadSparkData() {
		loading = true;
		error = null;
		
		try {
			sparkData = await spark.getStatus();
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}

	function formatNumber(num) {
		return new Intl.NumberFormat().format(num);
	}

	function formatPercent(num) {
		return (num * 100).toFixed(1) + '%';
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Spark RDD Processing</h1>
		<p>Scala + Spark distributed data processing results</p>
	</div>

	{#if loading}
		<div class="loading">
			<div class="spinner"></div>
			<p>Loading Spark results...</p>
		</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if sparkData && sparkData.status === 'completed'}
		<!-- Summary -->
		<div class="section">
			<h2>Processing Summary</h2>
			<div class="stats-grid">
				<div class="stat-box">
					<div class="stat-label">Total Records</div>
					<div class="stat-value">{formatNumber(sparkData.summary.total_records)}</div>
				</div>
				<div class="stat-box">
					<div class="stat-label">Operational Records</div>
					<div class="stat-value">{formatNumber(sparkData.summary.operational_records)}</div>
				</div>
				<div class="stat-box">
					<div class="stat-label">Avg Utilization</div>
					<div class="stat-value">{formatPercent(sparkData.summary.avg_utilization)}</div>
				</div>
				<div class="stat-box">
					<div class="stat-label">Partitions</div>
					<div class="stat-value">{sparkData.summary.partitions}</div>
				</div>
			</div>
		</div>

		<!-- RDD Features -->
		<div class="section">
			<h2>RDD Operations Demonstrated</h2>
			<div class="features-grid">
				<div class="feature-card">
					<h3>Transformations</h3>
					<ul>
						{#each sparkData.rdd_features.transformations as trans}
						<li><code>{trans}()</code></li>
						{/each}
					</ul>
				</div>
				<div class="feature-card">
					<h3>Actions</h3>
					<ul>
						{#each sparkData.rdd_features.actions as action}
						<li><code>{action}()</code></li>
						{/each}
					</ul>
				</div>
				<div class="feature-card">
					<h3>Key-Value Operations</h3>
					<ul>
						{#each sparkData.rdd_features.key_value_ops as op}
						<li><code>{op}()</code></li>
						{/each}
					</ul>
				</div>
				<div class="feature-card">
					<h3>Advanced Features</h3>
					<ul>
						<li>Caching: {sparkData.rdd_features.cached ? '✓ Enabled' : '✗ Disabled'}</li>
						<li>Partitions: {sparkData.rdd_features.partitions}</li>
						<li>Shuffle Ops: {sparkData.rdd_features.shuffle_operations.join(', ')}</li>
					</ul>
				</div>
			</div>
		</div>

		<!-- Network Stats -->
		<div class="section">
			<h2>Network Performance (RDD Analysis)</h2>
			<div class="table-container">
				<table>
					<thead>
						<tr>
							<th>Network</th>
							<th>Avg Utilization</th>
							<th>Observations</th>
						</tr>
					</thead>
					<tbody>
						{#each sparkData.network_stats as network}
						<tr>
							<td><strong>{network.network}</strong></td>
							<td class="utilization">{formatPercent(network.avg_utilization)}</td>
							<td>{formatNumber(network.observations)}</td>
						</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</div>

		<!-- Hourly Patterns -->
		<div class="section">
			<h2>Hourly Demand (reduceByKey)</h2>
			<div class="chart-container">
				<div class="bar-chart">
					{#each sparkData.hourly_stats as hour}
					<div class="bar-wrapper">
						<div class="bar" style="height: {hour.avg_utilization * 100}%"></div>
						<span class="bar-label">{hour.hour}h</span>
					</div>
					{/each}
				</div>
			</div>
		</div>

		<!-- City Stats -->
		<div class="section">
			<h2>Top Cities by Utilization</h2>
			<div class="city-grid">
				{#each sparkData.city_stats as city}
				<div class="city-card">
					<h3>{city.city}</h3>
					<p class="city-util">{formatPercent(city.avg_utilization)}</p>
					<p class="city-obs">{formatNumber(city.observations)} obs</p>
				</div>
				{/each}
			</div>
		</div>
	{:else}
		<div class="not-run">
			<h2>Spark Processing Not Run</h2>
			<p>Run the Scala Spark RDD analysis to see results here.</p>
			<pre>cd spark-scala && ./run.sh</pre>
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

	.error, .not-run {
		background: #151816;
		padding: 2rem;
		border-radius: 12px;
		border: 1px solid #292F2B;
		color: #929B95;
	}

	.not-run h2 {
		color: #F3F6F4;
		margin: 0 0 1rem 0;
	}

	.not-run pre {
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
		margin: 0 0 1rem 0;
		font-size: 1.25rem;
		color: #F3F6F4;
	}

	.stats-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1rem;
	}

	.stat-box {
		background: #1B201D;
		padding: 1rem;
		border-radius: 8px;
	}

	.stat-label {
		font-size: 0.75rem;
		color: #929B95;
		margin-bottom: 0.5rem;
	}

	.stat-value {
		font-size: 1.75rem;
		color: #35E6A1;
		font-weight: 700;
	}

	.features-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 1rem;
	}

	.feature-card {
		background: #1B201D;
		padding: 1rem;
		border-radius: 8px;
	}

	.feature-card h3 {
		margin: 0 0 0.75rem 0;
		font-size: 1rem;
		color: #F3F6F4;
	}

	.feature-card ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.feature-card li {
		color: #929B95;
		padding: 0.25rem 0;
		font-size: 0.875rem;
	}

	.feature-card code {
		color: #35E6A1;
		font-family: monospace;
	}

	.table-container {
		overflow-x: auto;
	}

	table {
		width: 100%;
		border-collapse: collapse;
	}

	thead th {
		text-align: left;
		padding: 0.75rem;
		background: #1B201D;
		color: #929B95;
		font-size: 0.875rem;
		font-weight: 600;
	}

	tbody td {
		padding: 0.75rem;
		border-top: 1px solid #292F2B;
		color: #F3F6F4;
	}

	.utilization {
		color: #35E6A1;
		font-weight: 600;
	}

	.chart-container {
		padding: 1rem 0;
	}

	.bar-chart {
		display: flex;
		align-items: flex-end;
		gap: 0.5rem;
		height: 200px;
	}

	.bar-wrapper {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: flex-end;
		height: 100%;
	}

	.bar {
		width: 100%;
		background: linear-gradient(180deg, #35E6A1 0%, #2dd190 100%);
		border-radius: 4px 4px 0 0;
		min-height: 10px;
	}

	.bar-label {
		margin-top: 0.5rem;
		font-size: 0.75rem;
		color: #929B95;
	}

	.city-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
		gap: 1rem;
	}

	.city-card {
		background: #1B201D;
		border-radius: 8px;
		padding: 1rem;
		text-align: center;
	}

	.city-card h3 {
		margin: 0 0 0.5rem 0;
		font-size: 0.875rem;
		color: #F3F6F4;
	}

	.city-util {
		font-size: 1.5rem;
		font-weight: 700;
		color: #35E6A1;
		margin: 0;
	}

	.city-obs {
		font-size: 0.75rem;
		color: #929B95;
		margin: 0;
	}
</style>
