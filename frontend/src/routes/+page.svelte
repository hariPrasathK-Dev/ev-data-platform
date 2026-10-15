<script>
	import { onMount } from 'svelte';
	import { overview, analytics, stations } from '$lib/api.js';

	let loading = true;
	let error = null;
	let overviewData = null;
	let networkData = [];
	let stationList = [];
	let mapReady = false;

	onMount(async () => {
		await loadDashboardData();
		loadMap();
	});

	async function loadDashboardData() {
		loading = true;
		error = null;
		
		try {
			const overviewResponse = await overview.get();
			overviewData = overviewResponse.overview;
			
			const networkResponse = await analytics.byNetwork();
			networkData = networkResponse.networks.slice(0, 6);
			
			const stationsResponse = await stations.list({ limit: 50 });
			stationList = stationsResponse.stations.filter(s => s.latitude && s.longitude);
			
		} catch (err) {
			console.error('Dashboard load error:', err);
			error = err.message || 'Failed to load dashboard data';
		} finally {
			loading = false;
		}
	}
	
	function loadMap() {
		// Add Leaflet CSS
		const link = document.createElement('link');
		link.rel = 'stylesheet';
		link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
		document.head.appendChild(link);
		
		// Add Leaflet JS
		const script = document.createElement('script');
		script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
		script.onload = () => {
			mapReady = true;
			setTimeout(initMap, 100);
		};
		document.head.appendChild(script);
	}
	
	function initMap() {
		if (!window.L || stationList.length === 0) return;
		
		try {
			const map = window.L.map('map').setView([37.7749, -95.7129], 4);
			
			window.L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
				attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
				maxZoom: 19
			}).addTo(map);
			
			const icon = window.L.divIcon({
				className: 'custom-marker',
				html: '<div style="background: #35E6A1; width: 12px; height: 12px; border-radius: 50%; border: 2px solid #0B0D0C; box-shadow: 0 0 10px #35E6A1;"></div>',
				iconSize: [12, 12]
			});
			
			stationList.forEach(station => {
				window.L.marker([station.latitude, station.longitude], { icon })
					.bindPopup(`<strong>${station.station_name}</strong><br>${station.city}, ${station.state}`)
					.addTo(map);
			});
		} catch (e) {
			console.error('Map error:', e);
		}
	}
	
	function formatNumber(num) {
		return new Intl.NumberFormat().format(num);
	}
	
	function formatPercent(num) {
		return (num * 100).toFixed(1) + '%';
	}
</script>

<div class="dashboard">
	<div class="page-header">
		<h1>Stations</h1>
		<div class="location">New York, United States of America</div>
	</div>

	{#if loading}
		<div class="loading">
			<div class="spinner"></div>
			<p>Loading dashboard...</p>
		</div>
	{:else if error}
		<div class="error-banner">
			<h3>Connection Error</h3>
			<p>{error}</p>
			<button on:click={loadDashboardData} class="retry-btn">Retry</button>
		</div>
	{:else if overviewData}
		<div class="grid-layout">
			<!-- Map Section -->
			<div class="map-section">
				<div id="map" class="map-container"></div>
			</div>

			<!-- Stats Panel -->
			<div class="stats-panel">
				<div class="vehicle-stats">
					<img src="/image.png" alt="Electric Vehicle" class="ev-image" />
					<div class="stat-row">
						<div class="stat-item">
							<div class="stat-label">Model</div>
							<div class="stat-value">Tesla X</div>
						</div>
						<div class="stat-item">
							<div class="stat-label">Battery</div>
							<div class="stat-value">{formatPercent(overviewData.avg_utilization * 2.5)}</div>
						</div>
					</div>
					<div class="stat-row">
						<div class="stat-item">
							<div class="stat-label">Range</div>
							<div class="stat-value">340 mi</div>
						</div>
						<div class="stat-item">
							<div class="stat-label">Temp</div>
							<div class="stat-value">75°F</div>
						</div>
					</div>
				</div>

				<!-- KPI Cards -->
				<div class="kpi-small">
					<div class="kpi-label">Total Stations</div>
					<div class="kpi-big">{formatNumber(overviewData.total_stations)}</div>
				</div>
				<div class="kpi-small">
					<div class="kpi-label">Networks</div>
					<div class="kpi-big">{overviewData.total_networks}</div>
				</div>
				<div class="kpi-small">
					<div class="kpi-label">Avg Usage</div>
					<div class="kpi-big">{formatPercent(overviewData.avg_utilization)}</div>
				</div>
			</div>

			<!-- Station Cards -->
			<div class="stations-section">
				<h2>Nearby Stations</h2>
				<div class="station-grid">
					{#each networkData as network}
					<div class="station-card">
						<div class="station-header">
							<h3>{network.network}</h3>
							<span class="status-dot available"></span>
						</div>
						<div class="station-info">
							<div class="info-row">
								<span class="label">Type</span>
								<span class="value">DC</span>
							</div>
							<div class="info-row">
								<span class="label">Distance</span>
								<span class="value">1.5 mi</span>
							</div>
							<div class="info-row">
								<span class="label">Price</span>
								<span class="value">$0.28 kW</span>
							</div>
							<div class="info-row">
								<span class="label">Ports</span>
								<span class="value">{formatPercent(network.avg_utilization)} used</span>
							</div>
						</div>
					</div>
					{/each}
				</div>
			</div>
		</div>
	{/if}
</div>

<style>
	.dashboard {
		max-width: 1600px;
		margin: 0 auto;
		padding: 0;
	}

	.page-header {
		margin-bottom: 2rem;
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	.page-header h1 {
		margin: 0;
		font-size: 1.75rem;
		color: #F3F6F4;
		font-weight: 700;
	}

	.location {
		color: #35E6A1;
		font-size: 0.875rem;
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.location::before {
		content: "📍";
		font-size: 1rem;
	}

	.loading {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 4rem;
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

	.error-banner {
		background: #1B201D;
		border: 1px solid #ef4444;
		border-radius: 12px;
		padding: 1.5rem;
		margin-bottom: 2rem;
	}

	.error-banner h3 {
		margin: 0 0 0.5rem 0;
		color: #ef4444;
	}

	.error-banner p {
		margin: 0 0 1rem 0;
		color: #929B95;
	}

	.retry-btn {
		background: #35E6A1;
		color: #0B0D0C;
		border: none;
		padding: 0.5rem 1rem;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 600;
	}

	.retry-btn:hover {
		background: #2dd190;
	}

	.grid-layout {
		display: grid;
		grid-template-columns: 1fr 350px;
		grid-template-rows: 400px auto;
		gap: 1.5rem;
	}

	.map-section {
		background: #151816;
		border-radius: 16px;
		overflow: hidden;
		grid-row: 1 / 3;
	}

	.map-container {
		width: 100%;
		height: 100%;
		min-height: 500px;
	}

	.stats-panel {
		background: #151816;
		border-radius: 16px;
		padding: 1.5rem;
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.vehicle-stats {
		background: #1B201D;
		border-radius: 12px;
		padding: 1.5rem;
	}

	.ev-image {
		width: 100%;
		height: auto;
		margin-bottom: 1rem;
	}

	.stat-row {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1rem;
		margin-bottom: 0.75rem;
	}

	.stat-item {
		display: flex;
		flex-direction: column;
	}

	.stat-label {
		font-size: 0.75rem;
		color: #929B95;
		margin-bottom: 0.25rem;
	}

	.stat-value {
		font-size: 1rem;
		color: #F3F6F4;
		font-weight: 600;
	}

	.kpi-small {
		background: #1B201D;
		border-radius: 12px;
		padding: 1rem;
	}

	.kpi-label {
		font-size: 0.75rem;
		color: #929B95;
		margin-bottom: 0.5rem;
	}

	.kpi-big {
		font-size: 1.75rem;
		color: #35E6A1;
		font-weight: 700;
	}

	.stations-section {
		grid-column: 1 / -1;
	}

	.stations-section h2 {
		margin: 0 0 1rem 0;
		font-size: 1.25rem;
		color: #F3F6F4;
	}

	.station-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
		gap: 1rem;
	}

	.station-card {
		background: #151816;
		border-radius: 12px;
		padding: 1.25rem;
		border: 1px solid #292F2B;
		transition: all 0.2s;
	}

	.station-card:hover {
		border-color: #35E6A1;
		transform: translateY(-2px);
	}

	.station-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.station-header h3 {
		margin: 0;
		font-size: 1rem;
		color: #F3F6F4;
		font-weight: 600;
	}

	.status-dot {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		background: #929B95;
	}

	.status-dot.available {
		background: #35E6A1;
		box-shadow: 0 0 10px #35E6A1;
	}

	.station-info {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.info-row {
		display: flex;
		justify-content: space-between;
		font-size: 0.875rem;
	}

	.info-row .label {
		color: #929B95;
	}

	.info-row .value {
		color: #F3F6F4;
		font-weight: 500;
	}

	@media (max-width: 1200px) {
		.grid-layout {
			grid-template-columns: 1fr;
			grid-template-rows: 400px auto auto;
		}

		.map-section {
			grid-row: 1;
		}
	}
</style>
