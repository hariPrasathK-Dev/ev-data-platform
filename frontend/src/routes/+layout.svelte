<script>
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { health } from '$lib/api.js';

	let healthStatus = null;
	let navOpen = false;

	// Check API health on mount
	onMount(async () => {
		try {
			healthStatus = await health.check();
		} catch (error) {
			console.error('Health check failed:', error);
			healthStatus = { status: 'unhealthy', error: error.message };
		}
	});

	const navItems = [
		{ path: '/', label: 'Dashboard', icon: '' },
		{ path: '/stations', label: 'Stations', icon: '' },
		{ path: '/analytics', label: 'Analytics', icon: '' },
		{ path: '/spark', label: 'Spark RDD', icon: '' },
		{ path: '/ml-model', label: 'ML Model', icon: '' },
		{ path: '/predict', label: 'Predict', icon: '' },
		{ path: '/hdfs', label: 'HDFS', icon: '' },
		{ path: '/mapreduce', label: 'MapReduce', icon: '' },
		{ path: '/hive', label: 'Hive', icon: '' }
	];
</script>

<div class="app">
	<header>
		<div class="header-content">
			<button class="menu-toggle" on:click={() => navOpen = !navOpen}>
				☰
			</button>
			<h1>EV Charging Analytics</h1>
			<div class="health-indicator">
				{#if healthStatus}
					<span class="status-badge {healthStatus.status}">
						{healthStatus.status}
					</span>
				{:else}
					<span class="status-badge loading">checking</span>
				{/if}
			</div>
		</div>
	</header>

	<div class="layout">
		<nav class="sidebar" class:open={navOpen}>
			<div class="nav-header">
				<h2>Navigation</h2>
				<button class="close-btn" on:click={() => navOpen = false}>✕</button>
			</div>
			<ul>
				{#each navItems as item}
					<li>
						<a 
							href={item.path} 
							class:active={$page.url.pathname === item.path}
							on:click={() => navOpen = false}
						>
							<span class="icon">{item.icon}</span>
							<span class="label">{item.label}</span>
						</a>
					</li>
				{/each}
			</ul>
			
			<div class="sidebar-footer">
				<p class="project-info">
					<strong>Big Data Analytics</strong><br>
					Course: 23CSE352<br>
					Project Review 1
				</p>
			</div>
		</nav>

		<main>
			<slot />
		</main>
	</div>
</div>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
		background: #0B0D0C;
		color: #F3F6F4;
	}

	:global(*) {
		box-sizing: border-box;
	}

	.app {
		display: flex;
		flex-direction: column;
		height: 100vh;
	}

	header {
		background: #101311;
		color: #F3F6F4;
		padding: 0;
		border-bottom: 1px solid #292F2B;
		position: sticky;
		top: 0;
		z-index: 100;
	}

	.header-content {
		max-width: 1400px;
		margin: 0 auto;
		padding: 1rem 1.5rem;
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	h1 {
		margin: 0;
		font-size: 1.5rem;
		font-weight: 600;
		flex: 1;
	}

	.menu-toggle {
		display: none;
		background: rgba(255,255,255,0.2);
		border: none;
		color: white;
		font-size: 1.5rem;
		padding: 0.5rem 0.75rem;
		cursor: pointer;
		border-radius: 4px;
	}

	.health-indicator {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.status-badge {
		background: rgba(255,255,255,0.2);
		padding: 0.25rem 0.75rem;
		border-radius: 20px;
		font-size: 0.875rem;
		font-weight: 500;
		text-transform: capitalize;
	}

	.status-badge.healthy {
		background: #10b981;
	}

	.status-badge.degraded {
		background: #f59e0b;
	}

	.status-badge.unhealthy {
		background: #ef4444;
	}

	.layout {
		display: flex;
		flex: 1;
		overflow: hidden;
	}

	.sidebar {
		width: 250px;
		background: #101311;
		border-right: 1px solid #292F2B;
		display: flex;
		flex-direction: column;
		overflow-y: auto;
	}

	.nav-header {
		padding: 1.5rem 1rem 1rem;
		border-bottom: 1px solid #292F2B;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.nav-header h2 {
		margin: 0;
		font-size: 1.1rem;
		color: #929B95;
	}

	.close-btn {
		display: none;
		background: none;
		border: none;
		font-size: 1.5rem;
		cursor: pointer;
		color: #6b7280;
	}

	.sidebar ul {
		list-style: none;
		margin: 0;
		padding: 0.5rem 0;
		flex: 1;
	}

	.sidebar li {
		margin: 0;
	}

	.sidebar a {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 0.875rem 1.5rem;
		text-decoration: none;
		color: #929B95;
		transition: all 0.2s;
		border-left: 3px solid transparent;
	}

	.sidebar a:hover {
		background: #151816;
		color: #F3F6F4;
	}

	.sidebar a.active {
		background: #151816;
		color: #35E6A1;
		font-weight: 600;
		border-left: 3px solid #35E6A1;
	}

	.sidebar a .icon {
		font-size: 1.25rem;
	}

	.sidebar-footer {
		padding: 1rem;
		border-top: 1px solid #292F2B;
		background: #0B0D0C;
	}

	.project-info {
		margin: 0;
		font-size: 0.75rem;
		line-height: 1.5;
		color: #929B95;
	}

	main {
		flex: 1;
		overflow-y: auto;
		padding: 2rem;
		background: #0B0D0C;
	}

	/* Mobile responsive */
	@media (max-width: 768px) {
		.menu-toggle {
			display: block;
		}

		.sidebar {
			position: fixed;
			left: -250px;
			top: 0;
			bottom: 0;
			z-index: 200;
			transition: left 0.3s;
			box-shadow: 2px 0 8px rgba(0,0,0,0.1);
		}

		.sidebar.open {
			left: 0;
		}

		.close-btn {
			display: block;
		}

		main {
			padding: 1rem;
		}
	}
</style>
