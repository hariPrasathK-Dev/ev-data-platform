<script>
	import { onMount } from 'svelte';
	import { analytics } from '$lib/api.js';

	let loading = true;
	let networkData = [];
	let hourlyData = [];
	let weatherData = [];

	onMount(async () => {
		await loadAnalytics();
	});

	async function loadAnalytics() {
		loading = true;
		
		try {
			const [networkResp, hourlyResp, weatherResp] = await Promise.all([
				analytics.byNetwork(),
				analytics.hourly(),
				analytics.weather()
			]);
			
			networkData = networkResp.networks;
			hourlyData = hourlyResp.hourly_patterns;
			weatherData = weatherResp.weather_impact;
		} catch (err) {
			console.error('Analytics error:', err);
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
		<h1>Analytics Dashboard</h1>
		<p>Detailed analysis of charging patterns and demand</p>
	</div>

	{#if loading}
		<div class="loading">
			<div class="spinner"></div>
			<p>Loading analytics...</p>
		</div>
	{:else}
		<div class="section">
			<h2>Network Performance</h2>
			<div class="table-container">
				<table>
					<thead>
						<tr>
							<th>Network</th>
							<th>Observations</th>
							<th>Avg Utilization</th>
						</tr>
					</thead>
					<tbody>
						{#each networkData as network}
						<tr>
							<td><strong>{network.network}</strong></td>
							<td>{formatNumber(network.observations)}</td>
							<td class="utilization">{formatPercent(network.avg_utilization)}</td>
						</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</div>

		<div class="section">
			<h2>Hourly Demand Patterns</h2>
			<div class="chart-container">
				<div class="bar-chart">
					{#each hourlyData as hour}
					<div class="bar-wrapper">
						<div class="bar" style="height: {hour.avg_utilization * 100}%"></div>
						<span class="bar-label">{hour.hour}h</span>
					</div>
					{/each}
				</div>
			</div>
		</div>

		<div class="section">
			<h2>Weather Impact</h2>
			<div class="weather-grid">
				{#each weatherData as weather}
				<div class="weather-card">
					<h4>{weather.weather.replace(/_/g, ' ')}</h4>
					<p class="weather-util">{formatPercent(weather.avg_utilization)}</p>
					<p class="weather-obs">{formatNumber(weather.observations)} observations</p>
				</div>
				{/each}
			</div>
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
		color: #1f2937;
		font-weight: 700;
	}

	.page-header p {
		margin: 0 0 2rem 0;
		color: #6b7280;
	}

	.loading {
		display: flex;
		flex-direction: column;
		align-items: center;
		padding: 3rem;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #e5e7eb;
		border-top-color: #667eea;
		border-radius: 50%;
		animation: spin 0.8s linear infinite;
		margin-bottom: 1rem;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	.section {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		margin-bottom: 1.5rem;
		box-shadow: 0 2px 8px rgba(0,0,0,0.08);
	}

	.section h2 {
		margin: 0 0 1rem 0;
		font-size: 1.25rem;
		color: #1f2937;
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
		background: #f9fafb;
		color: #6b7280;
		font-size: 0.875rem;
		font-weight: 600;
	}

	tbody td {
		padding: 0.75rem;
		border-top: 1px solid #e5e7eb;
		color: #1f2937;
	}

	.utilization {
		color: #667eea;
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
		background: linear-gradient(180deg, #667eea 0%, #764ba2 100%);
		border-radius: 4px 4px 0 0;
		min-height: 10px;
	}

	.bar-label {
		margin-top: 0.5rem;
		font-size: 0.75rem;
		color: #6b7280;
	}

	.weather-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
		gap: 1rem;
	}

	.weather-card {
		background: #f9fafb;
		border-radius: 8px;
		padding: 1rem;
		text-align: center;
	}

	.weather-card h4 {
		margin: 0 0 0.5rem 0;
		font-size: 0.875rem;
		color: #4b5563;
		text-transform: capitalize;
	}

	.weather-util {
		font-size: 1.5rem;
		font-weight: 700;
		color: #10b981;
		margin: 0;
	}

	.weather-obs {
		font-size: 0.75rem;
		color: #9ca3af;
		margin: 0;
	}
</style>
