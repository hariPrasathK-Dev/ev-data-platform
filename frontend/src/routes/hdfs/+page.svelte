<script>
	import { onMount } from 'svelte';
	import { hdfs } from '$lib/api.js';

	let loading = false;
	let currentPath = '/home/hduser/Hive_Assignment';
	let contents = [];
	let error = null;
	let selectedFile = null;
	let filePreview = null;

	onMount(async () => {
		await loadDirectory(currentPath);
	});

	async function loadDirectory(path) {
		loading = true;
		error = null;
		try {
			const data = await hdfs.list(path);
			contents = data.contents || [];
			currentPath = data.path || path;
		} catch (e) {
			error = e.message;
			console.error('Failed to load directory:', e);
		} finally {
			loading = false;
		}
	}

	async function navigateTo(path) {
		await loadDirectory(path);
		selectedFile = null;
		filePreview = null;
	}

	async function viewFile(file) {
		if (!file.is_file) return;
		
		selectedFile = file;
		loading = true;
		try {
			const data = await hdfs.read(file.path, 20);
			filePreview = data.content || '';
		} catch (e) {
			error = `Failed to read file: ${e.message}`;
			filePreview = null;
		} finally {
			loading = false;
		}
	}

	function closePreview() {
		selectedFile = null;
		filePreview = null;
	}

	function formatSize(bytes) {
		if (bytes === 0) return '0 B';
		const k = 1024;
		const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
		const i = Math.floor(Math.log(bytes) / Math.log(k));
		return (bytes / Math.pow(k, i)).toFixed(2) + ' ' + sizes[i];
	}

	function getFileIcon(item) {
		if (item.is_directory) return '';
		const ext = item.name.split('.').pop().toLowerCase();
		const iconMap = {
			'csv': '',
			'txt': '📄',
			'log': '📋',
			'json': '📋',
			'xml': '📋',
			'jar': '☕',
			'java': '☕',
			'py': '🐍',
			'sh': '🔧',
		};
		return iconMap[ext] || '📄';
	}

	function goUp() {
		const parts = currentPath.split('/').filter(p => p);
		if (parts.length > 0) {
			parts.pop();
			const parentPath = '/' + parts.join('/');
			navigateTo(parentPath || '/');
		}
	}
</script>

<div class="hdfs-page">
	<div class="page-header">
		<div class="header-content">
			<div class="title-section">
				<h1> HDFS Browser</h1>
				<p>Navigate and manage Hadoop distributed file system</p>
			</div>
			<button class="refresh-btn" on:click={() => loadDirectory(currentPath)}>
				<span class="icon"></span>
				Refresh
			</button>
		</div>
	</div>

	{#if error}
		<div class="error-banner">
			<span class="error-icon"></span>
			<span>{error}</span>
		</div>
	{/if}

	<div class="browser-container">
		<!-- Path Navigation -->
		<div class="path-bar">
			<button class="back-btn" on:click={goUp} disabled={currentPath === '/'}>
				<span class="icon"></span>
				Back
			</button>
			<div class="current-path">
				<span class="path-icon">📂</span>
				<span class="path-text">{currentPath}</span>
			</div>
		</div>

		<!-- File List -->
		<div class="file-list">
			{#if loading && !selectedFile}
				<div class="loading-state">
					<div class="spinner large"></div>
					<p>Loading directory...</p>
				</div>
			{:else if contents.length === 0}
				<div class="empty-state">
					<div class="empty-icon"></div>
					<h3>Directory is Empty</h3>
					<p>No files or folders found</p>
				</div>
			{:else}
				<div class="files-grid">
					{#each contents as item}
						<div 
							class="file-item" 
							class:directory={item.is_directory}
							class:selected={selectedFile?.path === item.path}
							on:click={() => item.is_directory ? navigateTo(item.path) : viewFile(item)}
						>
							<div class="file-icon">{getFileIcon(item)}</div>
							<div class="file-details">
								<div class="file-name">{item.name}</div>
								<div class="file-meta">
									{#if item.is_file}
										<span class="meta-item">
											<span class="meta-label">Size:</span>
											{item.size_human}
										</span>
									{/if}
									<span class="meta-item">
										<span class="meta-label">Modified:</span>
										{item.modified_date} {item.modified_time}
									</span>
								</div>
							</div>
							{#if item.is_directory}
								<div class="nav-arrow">→</div>
							{/if}
						</div>
					{/each}
				</div>
			{/if}
		</div>
	</div>

	<!-- File Preview Modal -->
	{#if selectedFile && filePreview !== null}
		<div class="modal-overlay" on:click={closePreview}>
			<div class="modal-content" on:click|stopPropagation>
				<div class="modal-header">
					<div class="modal-title">
						<span class="file-icon-large">{getFileIcon(selectedFile)}</span>
						<div>
							<h3>{selectedFile.name}</h3>
							<p class="file-path">{selectedFile.path}</p>
						</div>
					</div>
					<button class="close-modal-btn" on:click={closePreview}></button>
				</div>

				<div class="modal-body">
					<div class="file-info">
						<div class="info-item">
							<span class="info-label">Size:</span>
							<span class="info-value">{selectedFile.size_human}</span>
						</div>
						<div class="info-item">
							<span class="info-label">Owner:</span>
							<span class="info-value">{selectedFile.owner}</span>
						</div>
						<div class="info-item">
							<span class="info-label">Group:</span>
							<span class="info-value">{selectedFile.group}</span>
						</div>
						<div class="info-item">
							<span class="info-label">Permissions:</span>
							<span class="info-value">{selectedFile.permissions}</span>
						</div>
					</div>

					<div class="preview-section">
						<h4>File Preview (First 20 lines)</h4>
						<pre class="code-preview">{filePreview}</pre>
					</div>

					<div class="modal-actions">
						<a 
							href={hdfs.getDownloadUrl(selectedFile.path)} 
							class="btn btn-primary"
							download
						>
							<span class="icon"></span>
							Download File
						</a>
						<button class="btn btn-secondary" on:click={closePreview}>Close</button>
					</div>
				</div>
			</div>
		</div>
	{/if}
</div>

<style>
	.hdfs-page {
		max-width: 1400px;
		margin: 0 auto;
	}

	.page-header {
		background: linear-gradient(135deg, #10b981 0%, #059669 100%);
		padding: 2rem;
		border-radius: 12px;
		margin-bottom: 2rem;
		box-shadow: 0 4px 20px rgba(16, 185, 129, 0.3);
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
		color: #10b981;
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

	.browser-container {
		background: white;
		border-radius: 12px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
		overflow: hidden;
	}

	.path-bar {
		display: flex;
		align-items: center;
		gap: 1rem;
		padding: 1.5rem;
		border-bottom: 2px solid #e5e7eb;
		background: #f9fafb;
	}

	.back-btn {
		background: white;
		border: 2px solid #e5e7eb;
		padding: 0.5rem 1rem;
		border-radius: 6px;
		font-weight: 600;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		transition: all 0.2s;
	}

	.back-btn:hover:not(:disabled) {
		border-color: #10b981;
		color: #10b981;
	}

	.back-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.current-path {
		flex: 1;
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 0.5rem 1rem;
		background: white;
		border-radius: 6px;
		border: 2px solid #e5e7eb;
	}

	.path-icon {
		font-size: 1.25rem;
	}

	.path-text {
		font-family: monospace;
		color: #1f2937;
		font-weight: 500;
	}

	.file-list {
		padding: 1.5rem;
		min-height: 400px;
	}

	.files-grid {
		display: grid;
		gap: 0.75rem;
	}

	.file-item {
		display: flex;
		align-items: center;
		gap: 1rem;
		padding: 1rem;
		border: 2px solid #e5e7eb;
		border-radius: 8px;
		cursor: pointer;
		transition: all 0.2s;
	}

	.file-item:hover {
		border-color: #10b981;
		background: #f0fdf4;
		transform: translateX(4px);
	}

	.file-item.selected {
		border-color: #10b981;
		background: #d1fae5;
	}

	.file-item.directory {
		background: #f9fafb;
	}

	.file-item.directory:hover {
		background: #f0fdf4;
	}

	.file-icon {
		font-size: 2rem;
	}

	.file-details {
		flex: 1;
	}

	.file-name {
		font-weight: 600;
		color: #1f2937;
		margin-bottom: 0.25rem;
	}

	.file-meta {
		display: flex;
		gap: 1.5rem;
		font-size: 0.75rem;
		color: #6b7280;
	}

	.meta-item {
		display: flex;
		gap: 0.25rem;
	}

	.meta-label {
		font-weight: 600;
	}

	.nav-arrow {
		font-size: 1.5rem;
		color: #10b981;
		font-weight: bold;
	}

	.loading-state {
		text-align: center;
		padding: 4rem 2rem;
	}

	.spinner {
		width: 16px;
		height: 16px;
		border: 2px solid #f3f4f6;
		border-top-color: #10b981;
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

	.modal-overlay {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0.7);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 1000;
		padding: 2rem;
	}

	.modal-content {
		background: white;
		border-radius: 12px;
		max-width: 900px;
		width: 100%;
		max-height: 90vh;
		overflow-y: auto;
		box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
	}

	.modal-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		padding: 2rem;
		border-bottom: 2px solid #e5e7eb;
	}

	.modal-title {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
	}

	.file-icon-large {
		font-size: 3rem;
	}

	.modal-title h3 {
		margin: 0 0 0.25rem 0;
		font-size: 1.5rem;
		color: #1f2937;
	}

	.file-path {
		margin: 0;
		font-size: 0.875rem;
		color: #6b7280;
		font-family: monospace;
	}

	.close-modal-btn {
		background: #f3f4f6;
		border: none;
		font-size: 1.5rem;
		width: 40px;
		height: 40px;
		border-radius: 50%;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s;
	}

	.close-modal-btn:hover {
		background: #e5e7eb;
	}

	.modal-body {
		padding: 2rem;
	}

	.file-info {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1rem;
		margin-bottom: 2rem;
		padding: 1.5rem;
		background: #f9fafb;
		border-radius: 8px;
	}

	.info-item {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.info-label {
		font-size: 0.75rem;
		color: #6b7280;
		font-weight: 600;
		text-transform: uppercase;
	}

	.info-value {
		font-size: 0.875rem;
		color: #1f2937;
		font-family: monospace;
	}

	.preview-section h4 {
		margin: 0 0 1rem 0;
		color: #1f2937;
		font-size: 1.125rem;
	}

	.code-preview {
		background: #1f2937;
		color: #e5e7eb;
		padding: 1.5rem;
		border-radius: 8px;
		overflow-x: auto;
		font-family: 'Courier New', monospace;
		font-size: 0.875rem;
		line-height: 1.6;
		max-height: 400px;
		overflow-y: auto;
	}

	.modal-actions {
		display: flex;
		gap: 1rem;
		margin-top: 2rem;
		justify-content: flex-end;
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
		text-decoration: none;
	}

	.btn-primary {
		background: linear-gradient(135deg, #10b981, #059669);
		color: white;
	}

	.btn-primary:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);
	}

	.btn-secondary {
		background: #f3f4f6;
		color: #4b5563;
	}

	.btn-secondary:hover {
		background: #e5e7eb;
	}

	@media (max-width: 768px) {
		.header-content {
			flex-direction: column;
			gap: 1rem;
		}

		.path-bar {
			flex-direction: column;
			align-items: stretch;
		}

		.modal-overlay {
			padding: 1rem;
		}

		.modal-content {
			max-height: 95vh;
		}

		.file-info {
			grid-template-columns: 1fr;
		}
	}
</style>
