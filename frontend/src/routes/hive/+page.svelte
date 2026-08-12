<script>
	import { onMount } from 'svelte';
	import { hive } from '$lib/api.js';

	let loading = false;
	let queryResults = null;
	let error = null;
	let customQuery = '';
	let selectedPredefined = null;

	const predefinedQueries = [
		{ id: 'q1', name: 'Top 10 Most Utilized Stations', description: 'Stations with highest average utilization rate' },
		{ id: 'q2', name: 'Charging Sessions by Network', description: 'Total sessions per charging network' },
		{ id: 'q3', name: 'Peak Usage Hours', description: 'Hour-by-hour usage patterns' },
		{ id: 'q4', name: 'Station Reliability Analysis', description: 'Stations with lowest downtime' },
		{ id: 'q5', name: 'Geographic Distribution', description: 'Sessions by state and city' }
	];

	async function executePredefinedQuery(queryId) {
		loading = true;
		error = null;
		selectedPredefined = queryId;
		
		try {
			const data = await hive.executePredefined(queryId);
			queryResults = data.results || [];
		} catch (e) {
			const errorMsg = e.message || 'Unknown error';
			if (errorMsg.includes('503') || errorMsg.includes('not initialized')) {
				error = 'Hive is not initialized. Please run: schematool -dbType derby -initSchema';
			} else {
				error = `Query execution failed: ${errorMsg}`;
			}
			queryResults = null;
		} finally {
			loading = false;
		}
	}

	async function executeCustomQuery() {
		if (!customQuery.trim()) {
			error = 'Please enter a query';
			return;
		}

		loading = true;
		error = null;
		selectedPredefined = null;
		
		try {
			const data = await hive.executeQuery(customQuery);
			queryResults = data.results || [];
		} catch (e) {
			const errorMsg = e.message || 'Unknown error';
			if (errorMsg.includes('503') || errorMsg.includes('not initialized')) {
				error = 'Hive is not initialized. Please run: schematool -dbType derby -initSchema';
			} else {
				error = `Query execution failed: ${errorMsg}`;
			}
			queryResults = null;
		} finally {
			loading = false;
		}
	}

	function clearResults() {
		queryResults = null;
		error = null;
		selectedPredefined = null;
	}
</script>

<div class="hive-page">
	<div class="page-header">
		<div class="header-content">
			<div class="title-section">
				<h1> Hive Queries</h1>
				<p>Execute SQL queries on 1.3M+ EV charging records</p>
			</div>
		</div>
	</div>

	{#if error}
		<div class="error-banner">
			<span class="error-icon"></span>
			<span>{error}</span>
			<button class="dismiss-btn" on:click={() => error = null}></button>
		</div>
	{/if}

	<div class="query-container">
		<!-- Predefined Queries -->
		<div class="section">
			<h2>📋 Predefined Analytical Queries</h2>
			<div class="queries-grid">
				{#each predefinedQueries as query}
					<div 
						class="query-card"
						class:selected={selectedPredefined === query.id}
						on:click={() => executePredefinedQuery(query.id)}
					>
						<h3>{query.name}</h3>
						<p>{query.description}</p>
						<button class="execute-btn">
							<span class="icon"></span>
							Execute
						</button>
					</div>
				{/each}
			</div>
		</div>

		<!-- Custom Query Editor -->
		<div class="section">
			<h2> Custom Query Editor</h2>
			<div class="editor-container">
				<textarea
					bind:value={customQuery}
					placeholder="Enter your HiveQL query here...

Example:
SELECT station_id, AVG(utilization_rate) as avg_util
FROM ev_charging_stations
GROUP BY station_id
ORDER BY avg_util DESC
LIMIT 10;"
					rows="10"
				></textarea>
				<div class="editor-actions">
					<button class="btn btn-primary" on:click={executeCustomQuery} disabled={loading}>
						<span class="icon"></span>
						{loading ? 'Executing...' : 'Execute Query'}
					</button>
					<button class="btn btn-secondary" on:click={() => customQuery = ''}>
						<span class="icon"></span>
						Clear
					</button>
				</div>
			</div>
		</div>

		<!-- Results Section -->
		{#if loading}
			<div class="results-section">
				<div class="loading-state">
					<div class="spinner large"></div>
					<p>Executing query...</p>
					<small>This may take a few moments for large datasets</small>
				</div>
			</div>
		{:else if queryResults}
			<div class="results-section">
				<div class="results-header">
					<h2> Query Results</h2>
					<div class="results-actions">
						<span class="results-count">{queryResults.length} rows returned</span>
						<button class="btn btn-secondary btn-sm" on:click={clearResults}>
							<span class="icon"></span>
							Clear Results
						</button>
					</div>
				</div>

				{#if queryResults.length === 0}
					<div class="empty-results">
						<div class="empty-icon"></div>
						<h3>No Results</h3>
						<p>The query executed successfully but returned no rows</p>
					</div>
				{:else}
					<div class="results-table-container">
						<table class="results-table">
							<thead>
								<tr>
									{#each Object.keys(queryResults[0]) as column}
										<th>{column}</th>
									{/each}
								</tr>
							</thead>
							<tbody>
								{#each queryResults as row, index}
									<tr class:even={index % 2 === 0}>
										{#each Object.values(row) as value}
											<td>{value}</td>
										{/each}
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				{/if}
			</div>
		{/if}

		<!-- Info Section -->
		<div class="info-section">
			<div class="info-card">
				<h3> Query Tips</h3>
				<ul>
					<li>Use <code>LIMIT</code> clause to restrict result size for faster execution</li>
					<li>Available table: <code>ev_charging_stations</code></li>
					<li>For large aggregations, consider using MapReduce instead</li>
					<li>Check the table schema in the sidebar for available columns</li>
				</ul>
			</div>
			<div class="info-card">
				<h3> Sample Columns</h3>
				<ul>
					<li><code>station_id</code> - Unique station identifier</li>
					<li><code>network</code> - Charging network name</li>
					<li><code>state</code> - US state location</li>
					<li><code>utilization_rate</code> - Station usage percentage</li>
					<li><code>session_date</code> - Date of charging session</li>
				</ul>
			</div>
		</div>
	</div>
</div>

<style>
	.hive-page {
		max-width: 1400px;
		margin: 0 auto;
	}

	.page-header {
		background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
		padding: 2rem;
		border-radius: 12px;
		margin-bottom: 2rem;
		box-shadow: 0 4px 20px rgba(245, 158, 11, 0.3);
	}

	.header-content {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.title-section h1 {
		color: white;
		margin: 0 0 0.5rem 0;
		font-size: 2rem;
		font-weight: 700;
	}

	.title-section p {
		color: rgba(255, 255, 255, 0.9);
		margin: 0;
	}

	.error-banner {
		background: #fee2e2;
		border: 2px solid #ef4444;
		color: #991b1b;
		padding: 1rem 1.5rem;
		border-radius: 8px;
		margin-bottom: 1.5rem;
		display: flex;
		align-items: center;
		gap: 0.75rem;
		font-weight: 500;
	}

	.error-icon {
		font-size: 1.5rem;
	}

	.dismiss-btn {
		margin-left: auto;
		background: none;
		border: none;
		font-size: 1.25rem;
		cursor: pointer;
		color: #991b1b;
		font-weight: bold;
	}

	.query-container {
		display: flex;
		flex-direction: column;
		gap: 2rem;
	}

	.section {
		background: white;
		border-radius: 12px;
		padding: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	.section h2 {
		margin: 0 0 1.5rem 0;
		color: #1f2937;
		font-size: 1.5rem;
	}

	.queries-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: 1rem;
	}

	.query-card {
		border: 2px solid #e5e7eb;
		border-radius: 8px;
		padding: 1.5rem;
		cursor: pointer;
		transition: all 0.3s;
	}

	.query-card:hover {
		border-color: #f59e0b;
		background: #fffbeb;
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(245, 158, 11, 0.2);
	}

	.query-card.selected {
		border-color: #f59e0b;
		background: #fef3c7;
	}

	.query-card h3 {
		margin: 0 0 0.5rem 0;
		color: #1f2937;
		font-size: 1.125rem;
	}

	.query-card p {
		margin: 0 0 1rem 0;
		color: #6b7280;
		font-size: 0.875rem;
		line-height: 1.5;
	}

	.execute-btn {
		background: linear-gradient(135deg, #f59e0b, #d97706);
		color: white;
		border: none;
		padding: 0.5rem 1rem;
		border-radius: 6px;
		font-weight: 600;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		transition: all 0.2s;
	}

	.execute-btn:hover {
		transform: translateY(-2px);
		box-shadow: 0 2px 8px rgba(245, 158, 11, 0.3);
	}

	.editor-container {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	textarea {
		width: 100%;
		padding: 1rem;
		border: 2px solid #e5e7eb;
		border-radius: 8px;
		font-family: 'Courier New', monospace;
		font-size: 0.875rem;
		line-height: 1.6;
		resize: vertical;
	}

	textarea:focus {
		outline: none;
		border-color: #f59e0b;
	}

	.editor-actions {
		display: flex;
		gap: 1rem;
	}

	.btn {
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		border: none;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		transition: all 0.3s;
	}

	.btn-primary {
		background: linear-gradient(135deg, #f59e0b, #d97706);
		color: white;
	}

	.btn-primary:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(245, 158, 11, 0.4);
	}

	.btn-primary:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.btn-secondary {
		background: #f3f4f6;
		color: #4b5563;
	}

	.btn-secondary:hover {
		background: #e5e7eb;
	}

	.btn-sm {
		padding: 0.5rem 1rem;
		font-size: 0.875rem;
	}

	.results-section {
		background: white;
		border-radius: 12px;
		padding: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	.results-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.5rem;
		padding-bottom: 1rem;
		border-bottom: 2px solid #e5e7eb;
	}

	.results-header h2 {
		margin: 0;
		color: #1f2937;
		font-size: 1.5rem;
	}

	.results-actions {
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	.results-count {
		color: #6b7280;
		font-size: 0.875rem;
		font-weight: 600;
	}

	.loading-state {
		text-align: center;
		padding: 4rem 2rem;
	}

	.spinner {
		width: 16px;
		height: 16px;
		border: 2px solid #f3f4f6;
		border-top-color: #f59e0b;
		border-radius: 50%;
		animation: spin 0.6s linear infinite;
	}

	.spinner.large {
		width: 48px;
		height: 48px;
		border-width: 4px;
		margin: 0 auto 1rem;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	.loading-state small {
		color: #9ca3af;
		font-size: 0.875rem;
	}

	.empty-results {
		text-align: center;
		padding: 4rem 2rem;
	}

	.empty-icon {
		font-size: 4rem;
		margin-bottom: 1rem;
	}

	.empty-results h3 {
		color: #1f2937;
		margin: 0 0 0.5rem 0;
	}

	.empty-results p {
		color: #6b7280;
		margin: 0;
	}

	.results-table-container {
		overflow-x: auto;
	}

	.results-table {
		width: 100%;
		border-collapse: collapse;
	}

	.results-table thead {
		background: #f9fafb;
	}

	.results-table th {
		padding: 1rem;
		text-align: left;
		font-weight: 600;
		color: #374151;
		border-bottom: 2px solid #e5e7eb;
		text-transform: uppercase;
		font-size: 0.75rem;
	}

	.results-table td {
		padding: 1rem;
		border-bottom: 1px solid #f3f4f6;
		color: #1f2937;
	}

	.results-table tr.even {
		background: #f9fafb;
	}

	.results-table tbody tr:hover {
		background: #f3f4f6;
	}

	.info-section {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: 1.5rem;
	}

	.info-card {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	.info-card h3 {
		margin: 0 0 1rem 0;
		color: #1f2937;
		font-size: 1.125rem;
	}

	.info-card ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.info-card li {
		padding: 0.5rem 0;
		color: #4b5563;
		line-height: 1.6;
	}

	.info-card code {
		background: #f3f4f6;
		padding: 0.125rem 0.375rem;
		border-radius: 4px;
		font-family: 'Courier New', monospace;
		font-size: 0.875rem;
		color: #f59e0b;
	}

	@media (max-width: 768px) {
		.queries-grid {
			grid-template-columns: 1fr;
		}

		.results-header {
			flex-direction: column;
			align-items: flex-start;
			gap: 1rem;
		}

		.results-actions {
			width: 100%;
			justify-content: space-between;
		}

		.info-section {
			grid-template-columns: 1fr;
		}
	}
</style>
