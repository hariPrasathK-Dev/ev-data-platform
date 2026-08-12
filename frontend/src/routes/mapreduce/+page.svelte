<script>
	import { onMount, onDestroy } from 'svelte';
	import { mapreduce, hdfs } from '$lib/api.js';

	// State management
	let loading = false;
	let jobs = [];
	let selectedJob = null;
	let jobResults = null;
	let currentPage = 1;
	let itemsPerPage = 10;
	let searchQuery = '';
	let sortBy = 'date';
	let sortOrder = 'desc';
	
	// Real-time progress
	let liveJobId = null;
	let progressInterval = null;

	onMount(async () => {
		await loadJobs();
		// Auto-refresh jobs every 5 seconds
		progressInterval = setInterval(loadJobs, 5000);
	});

	onDestroy(() => {
		if (progressInterval) clearInterval(progressInterval);
	});

	async function loadJobs() {
		try {
			const data = await mapreduce.listJobs(100);
			jobs = data.jobs || [];
		} catch (error) {
			console.error('Failed to load jobs:', error);
		}
	}

	async function viewJobResults(job) {
		loading = true;
		selectedJob = job;
		
		try {
			const data = await mapreduce.getResults(job.id);
			jobResults = data.results || [];
			currentPage = 1;
		} catch (error) {
			console.error('Failed to load results:', error);
			jobResults = null;
		} finally {
			loading = false;
		}
	}

	function closeResults() {
		selectedJob = null;
		jobResults = null;
		currentPage = 1;
	}

	// Pagination logic
	$: filteredResults = jobResults ? jobResults.filter(item => 
		JSON.stringify(item).toLowerCase().includes(searchQuery.toLowerCase())
	) : [];
	
	$: totalPages = Math.ceil(filteredResults.length / itemsPerPage);
	$: paginatedResults = filteredResults.slice(
		(currentPage - 1) * itemsPerPage,
		currentPage * itemsPerPage
	);

	function nextPage() {
		if (currentPage < totalPages) currentPage++;
	}

	function prevPage() {
		if (currentPage > 1) currentPage--;
	}

	function goToPage(page) {
		currentPage = page;
	}

	// Get status badge color
	function getStatusColor(status) {
		const statusMap = {
			'SUCCEEDED': 'success',
			'RUNNING': 'warning',
			'FAILED': 'error',
			'KILLED': 'error',
			'SUBMITTED': 'info'
		};
		return statusMap[status] || 'default';
	}

	// Format duration
	function formatDuration(ms) {
		if (!ms) return 'N/A';
		const seconds = Math.floor(ms / 1000);
		const minutes = Math.floor(seconds / 60);
		if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
		return `${seconds}s`;
	}
</script>

<div class="mapreduce-page">
	<div class="page-header">
		<div class="header-content">
			<div class="title-section">
				<h1> MapReduce Jobs</h1>
				<p>Monitor and manage Hadoop MapReduce job executions</p>
			</div>
			<button class="refresh-btn" on:click={loadJobs}>
				<span class="icon"></span>
				Refresh
			</button>
		</div>
	</div>

	{#if !selectedJob}
		<!-- Jobs List View -->
		<div class="jobs-container">
			<div class="jobs-stats">
				<div class="stat-card">
					<div class="stat-icon"></div>
					<div class="stat-info">
						<div class="stat-value">{jobs.length}</div>
						<div class="stat-label">Total Jobs</div>
					</div>
				</div>
				<div class="stat-card">
					<div class="stat-icon"></div>
					<div class="stat-info">
						<div class="stat-value">{jobs.filter(j => j.state === 'SUCCEEDED').length}</div>
						<div class="stat-label">Completed</div>
					</div>
				</div>
				<div class="stat-card">
					<div class="stat-icon"></div>
					<div class="stat-info">
						<div class="stat-value">{jobs.filter(j => j.state === 'RUNNING').length}</div>
						<div class="stat-label">Running</div>
					</div>
				</div>
				<div class="stat-card">
					<div class="stat-icon"></div>
					<div class="stat-info">
						<div class="stat-value">{jobs.filter(j => j.state === 'FAILED').length}</div>
						<div class="stat-label">Failed</div>
					</div>
				</div>
			</div>

			<div class="jobs-list">
				<div class="list-header">
					<h2>Recent Job Executions</h2>
					<div class="list-actions">
						<select bind:value={sortBy}>
							<option value="date">Sort by Date</option>
							<option value="name">Sort by Name</option>
							<option value="status">Sort by Status</option>
						</select>
					</div>
				</div>

				{#if jobs.length === 0}
					<div class="empty-state">
						<div class="empty-icon"></div>
						<h3>No MapReduce Jobs Found</h3>
						<p>Jobs will appear here once they are executed</p>
					</div>
				{:else}
					<div class="jobs-grid">
						{#each jobs as job}
							<div class="job-card" class:running={job.state === 'RUNNING'}>
								<div class="job-header">
									<div class="job-title">
										<h3>{job.name || job.id}</h3>
										<span class="job-id">{job.id}</span>
									</div>
									<span class="status-badge {getStatusColor(job.state)}">
										{job.state}
									</span>
								</div>

								<div class="job-details">
									<div class="detail-row">
										<span class="label">Started:</span>
										<span class="value">{new Date(job.startTime).toLocaleString()}</span>
									</div>
									{#if job.finishTime}
										<div class="detail-row">
											<span class="label">Duration:</span>
											<span class="value">{formatDuration(job.finishTime - job.startTime)}</span>
										</div>
									{/if}
									{#if job.progress !== undefined}
										<div class="detail-row">
											<span class="label">Progress:</span>
											<div class="progress-bar">
												<div class="progress-fill" style="width: {job.progress}%"></div>
												<span class="progress-text">{job.progress}%</span>
											</div>
										</div>
									{/if}
								</div>

								<div class="job-actions">
									{#if job.state === 'SUCCEEDED'}
										<button class="btn btn-primary" on:click={() => viewJobResults(job)}>
											<span class="icon"></span>
											View Results
										</button>
									{/if}
									{#if job.state === 'RUNNING'}
										<button class="btn btn-secondary" disabled>
											<span class="spinner"></span>
											Running...
										</button>
									{/if}
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	{:else}
		<!-- Results View with Pagination -->
		<div class="results-container">
			<div class="results-header">
				<button class="back-btn" on:click={closeResults}>
					<span class="icon"></span>
					Back to Jobs
				</button>
				<div class="results-title">
					<h2>{selectedJob.name || 'Job Results'}</h2>
					<span class="job-id">{selectedJob.id}</span>
				</div>
			</div>

			<div class="results-controls">
				<div class="search-box">
					<span class="search-icon"></span>
					<input
						type="text"
						placeholder="Search results..."
						bind:value={searchQuery}
					/>
				</div>
				<div class="results-info">
					Showing {(currentPage - 1) * itemsPerPage + 1}-{Math.min(currentPage * itemsPerPage, filteredResults.length)} of {filteredResults.length} results
				</div>
			</div>

			{#if loading}
				<div class="loading-state">
					<div class="spinner large"></div>
					<p>Loading results...</p>
				</div>
			{:else if paginatedResults.length === 0}
				<div class="empty-state">
					<div class="empty-icon"></div>
					<h3>No Results Found</h3>
					<p>Try adjusting your search</p>
				</div>
			{:else}
				<div class="results-table">
					<table>
						<thead>
							<tr>
								{#each Object.keys(paginatedResults[0]) as key}
									<th>{key}</th>
								{/each}
							</tr>
						</thead>
						<tbody>
							{#each paginatedResults as row, index}
								<tr class:even={index % 2 === 0}>
									{#each Object.values(row) as value}
										<td>{value}</td>
									{/each}
								</tr>
							{/each}
						</tbody>
					</table>
				</div>

				{#if totalPages > 1}
					<div class="pagination">
						<button
							class="page-btn"
							on:click={prevPage}
							disabled={currentPage === 1}
						>
							 Previous
						</button>

						<div class="page-numbers">
							{#each Array(totalPages) as _, i}
								{#if i + 1 === 1 || i + 1 === totalPages || Math.abs(i + 1 - currentPage) <= 2}
									<button
										class="page-num"
										class:active={currentPage === i + 1}
										on:click={() => goToPage(i + 1)}
									>
										{i + 1}
									</button>
								{:else if i + 1 === 2 || i + 1 === totalPages - 1}
									<span class="page-ellipsis">...</span>
								{/if}
							{/each}
						</div>

						<button
							class="page-btn"
							on:click={nextPage}
							disabled={currentPage === totalPages}
						>
							Next →
						</button>
					</div>
				{/if}
			{/if}
		</div}
	{/if}
</div>

<style>
	.mapreduce-page {
		max-width: 1400px;
		margin: 0 auto;
	}

	.page-header {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		padding: 2rem;
		border-radius: 12px;
		margin-bottom: 2rem;
		box-shadow: 0 4px 20px rgba(102, 126, 234, 0.3);
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
		font-size: 1rem;
	}

	.refresh-btn {
		background: rgba(255, 255, 255, 0.2);
		border: 2px solid white;
		color: white;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		transition: all 0.3s;
	}

	.refresh-btn:hover {
		background: white;
		color: #667eea;
	}

	.jobs-stats {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1.5rem;
		margin-bottom: 2rem;
	}

	.stat-card {
		background: white;
		padding: 1.5rem;
		border-radius: 12px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
		display: flex;
		align-items: center;
		gap: 1rem;
		transition: transform 0.2s;
	}

	.stat-card:hover {
		transform: translateY(-4px);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
	}

	.stat-icon {
		font-size: 2.5rem;
	}

	.stat-value {
		font-size: 2rem;
		font-weight: 700;
		color: #1f2937;
	}

	.stat-label {
		font-size: 0.875rem;
		color: #6b7280;
	}

	.jobs-list {
		background: white;
		border-radius: 12px;
		padding: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	.list-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.5rem;
		padding-bottom: 1rem;
		border-bottom: 2px solid #e5e7eb;
	}

	.list-header h2 {
		margin: 0;
		font-size: 1.5rem;
		color: #1f2937;
	}

	.list-actions select {
		padding: 0.5rem 1rem;
		border: 2px solid #e5e7eb;
		border-radius: 8px;
		font-size: 0.875rem;
		cursor: pointer;
	}

	.jobs-grid {
		display: grid;
		gap: 1.5rem;
	}

	.job-card {
		border: 2px solid #e5e7eb;
		border-radius: 12px;
		padding: 1.5rem;
		transition: all 0.3s;
	}

	.job-card:hover {
		border-color: #667eea;
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
	}

	.job-card.running {
		background: linear-gradient(to right, #fff, #fef3c7);
		border-color: #f59e0b;
	}

	.job-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: 1rem;
	}

	.job-title h3 {
		margin: 0 0 0.25rem 0;
		font-size: 1.25rem;
		color: #1f2937;
	}

	.job-id {
		font-size: 0.75rem;
		color: #6b7280;
		font-family: monospace;
	}

	.status-badge {
		padding: 0.375rem 0.875rem;
		border-radius: 20px;
		font-size: 0.75rem;
		font-weight: 600;
		text-transform: uppercase;
	}

	.status-badge.success { background: #d1fae5; color: #065f46; }
	.status-badge.warning { background: #fef3c7; color: #92400e; }
	.status-badge.error { background: #fee2e2; color: #991b1b; }
	.status-badge.info { background: #dbeafe; color: #1e40af; }

	.job-details {
		margin: 1rem 0;
	}

	.detail-row {
		display: flex;
		justify-content: space-between;
		padding: 0.5rem 0;
		border-bottom: 1px solid #f3f4f6;
	}

	.detail-row .label {
		font-weight: 600;
		color: #6b7280;
	}

	.detail-row .value {
		color: #1f2937;
	}

	.progress-bar {
		flex: 1;
		height: 24px;
		background: #e5e7eb;
		border-radius: 12px;
		position: relative;
		overflow: hidden;
		margin-left: 1rem;
	}

	.progress-fill {
		height: 100%;
		background: linear-gradient(90deg, #667eea, #764ba2);
		transition: width 0.5s ease;
	}

	.progress-text {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		font-size: 0.75rem;
		font-weight: 700;
		color: white;
		mix-blend-mode: difference;
	}

	.job-actions {
		display: flex;
		gap: 0.75rem;
		margin-top: 1rem;
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
		background: linear-gradient(135deg, #667eea, #764ba2);
		color: white;
	}

	.btn-primary:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
	}

	.btn-secondary {
		background: #f3f4f6;
		color: #6b7280;
	}

	.btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.spinner {
		width: 16px;
		height: 16px;
		border: 2px solid #f3f4f6;
		border-top-color: #6b7280;
		border-radius: 50%;
		animation: spin 0.6s linear infinite;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	.results-container {
		background: white;
		border-radius: 12px;
		padding: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	.results-header {
		display: flex;
		align-items: center;
		gap: 1rem;
		margin-bottom: 2rem;
		padding-bottom: 1rem;
		border-bottom: 2px solid #e5e7eb;
	}

	.back-btn {
		background: #f3f4f6;
		border: none;
		padding: 0.75rem 1rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		transition: all 0.3s;
	}

	.back-btn:hover {
		background: #e5e7eb;
	}

	.results-title h2 {
		margin: 0;
		font-size: 1.5rem;
		color: #1f2937;
	}

	.results-controls {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.5rem;
	}

	.search-box {
		position: relative;
		flex: 1;
		max-width: 400px;
	}

	.search-icon {
		position: absolute;
		left: 1rem;
		top: 50%;
		transform: translateY(-50%);
	}

	.search-box input {
		width: 100%;
		padding: 0.75rem 1rem 0.75rem 3rem;
		border: 2px solid #e5e7eb;
		border-radius: 8px;
		font-size: 1rem;
	}

	.search-box input:focus {
		outline: none;
		border-color: #667eea;
	}

	.results-info {
		color: #6b7280;
		font-size: 0.875rem;
	}

	.results-table {
		overflow-x: auto;
		margin-bottom: 1.5rem;
	}

	table {
		width: 100%;
		border-collapse: collapse;
	}

	thead {
		background: #f9fafb;
	}

	th {
		padding: 1rem;
		text-align: left;
		font-weight: 600;
		color: #374151;
		border-bottom: 2px solid #e5e7eb;
		text-transform: uppercase;
		font-size: 0.75rem;
	}

	td {
		padding: 1rem;
		border-bottom: 1px solid #f3f4f6;
		color: #1f2937;
	}

	tr.even {
		background: #f9fafb;
	}

	tbody tr:hover {
		background: #f3f4f6;
	}

	.pagination {
		display: flex;
		justify-content: center;
		align-items: center;
		gap: 0.5rem;
	}

	.page-btn {
		padding: 0.75rem 1.5rem;
		border: 2px solid #e5e7eb;
		background: white;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s;
	}

	.page-btn:hover:not(:disabled) {
		border-color: #667eea;
		color: #667eea;
	}

	.page-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.page-numbers {
		display: flex;
		gap: 0.5rem;
	}

	.page-num {
		width: 40px;
		height: 40px;
		border: 2px solid #e5e7eb;
		background: white;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s;
	}

	.page-num:hover {
		border-color: #667eea;
		color: #667eea;
	}

	.page-num.active {
		background: linear-gradient(135deg, #667eea, #764ba2);
		color: white;
		border-color: transparent;
	}

	.page-ellipsis {
		display: flex;
		align-items: center;
		padding: 0 0.5rem;
		color: #6b7280;
	}

	.empty-state {
		text-align: center;
		padding: 4rem 2rem;
	}

	.empty-icon {
		font-size: 4rem;
		margin-bottom: 1rem;
	}

	.empty-state h3 {
		color: #1f2937;
		margin: 0 0 0.5rem 0;
	}

	.empty-state p {
		color: #6b7280;
		margin: 0;
	}

	.loading-state {
		text-align: center;
		padding: 4rem 2rem;
	}

	.spinner.large {
		width: 48px;
		height: 48px;
		border-width: 4px;
		margin: 0 auto 1rem;
	}

	@media (max-width: 768px) {
		.page-header {
			padding: 1.5rem;
		}

		.header-content {
			flex-direction: column;
			gap: 1rem;
		}

		.jobs-stats {
			grid-template-columns: 1fr;
		}

		.results-controls {
			flex-direction: column;
			align-items: stretch;
			gap: 1rem;
		}

		.search-box {
			max-width: none;
		}

		.pagination {
			flex-wrap: wrap;
		}
	}
</style>
