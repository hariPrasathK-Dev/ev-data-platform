<script>
	import { onMount } from 'svelte';
	import { stations } from '$lib/api.js';

	let loading = true;
	let error = null;
	let stationList = [];
	let pagination = {};

	onMount(async () => {
		await loadStations();
	});

	async function loadStations(page = 1) {
		loading = true;
		error = null;
		
		try {
			const response = await stations.list({ page, limit: 20 });
			stationList = response.stations;
			pagination = response.pagination;
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Charging Stations</h1>
		<p>Browse {pagination.total || '---'} charging stations</p>
	</div>

	{#if loading}
		<div class="loading">
			<div class="spinner"></div>
			<p>Loading stations...</p>
		</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else}
		<div class="station-grid">
			{#each stationList as station}
			<div class="station-card">
				<h3>{station.station_name}</h3>
				<p class="network">{station.network}</p>
				<p class="location">{station.city}, {station.state}</p>
				<p class="status status-{station.station_status}">{station.station_status}</p>
				<p class="ports">{station.ports_total} ports | {station.charger_type}</p>
			</div>
			{/each}
		</div>

		{#if pagination.total_pages > 1}
		<div class="pagination">
			{#if pagination.page > 1}
				<button on:click={() => loadStations(pagination.page - 1)}>Previous</button>
			{/if}
			<span>Page {pagination.page} of {pagination.total_pages}</span>
			{#if pagination.page < pagination.total_pages}
				<button on:click={() => loadStations(pagination.page + 1)}>Next</button>
			{/if}
		</div>
		{/if}
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
		margin: 0;
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

	.error {
		background: #fee2e2;
		padding: 1rem;
		border-radius: 8px;
		color: #991b1b;
	}

	.station-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: 1.5rem;
		margin-top: 2rem;
	}

	.station-card {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		box-shadow: 0 2px 8px rgba(0,0,0,0.08);
		transition: transform 0.2s;
	}

	.station-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
	}

	.station-card h3 {
		margin: 0 0 0.5rem 0;
		font-size: 1.1rem;
		color: #1f2937;
	}

	.network {
		color: #667eea;
		font-weight: 600;
		margin: 0 0 0.5rem 0;
	}

	.location {
		color: #6b7280;
		font-size: 0.875rem;
		margin: 0 0 0.5rem 0;
	}

	.status {
		display: inline-block;
		padding: 0.25rem 0.75rem;
		border-radius: 20px;
		font-size: 0.75rem;
		font-weight: 600;
		margin: 0 0 0.5rem 0;
	}

	.status-operational {
		background: #d1fae5;
		color: #065f46;
	}

	.status-under_maintenance {
		background: #fed7aa;
		color: #92400e;
	}

	.status-offline {
		background: #fee2e2;
		color: #991b1b;
	}

	.ports {
		color: #6b7280;
		font-size: 0.875rem;
		margin: 0;
	}

	.pagination {
		display: flex;
		justify-content: center;
		align-items: center;
		gap: 1rem;
		margin-top: 2rem;
		padding: 1rem;
	}

	.pagination button {
		background: #667eea;
		color: white;
		border: none;
		padding: 0.5rem 1rem;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 500;
	}

	.pagination button:hover {
		background: #5568d3;
	}
</style>
