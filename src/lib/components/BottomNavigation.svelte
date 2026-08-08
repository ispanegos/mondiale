<script lang="ts">
	import { page } from '$app/stores';

	const items = [
		{ href: '/tournaments', label: 'Tornei', icon: '🏆' },
		{ href: '/ranking', label: 'Classifica', icon: '📊' },
		{ href: '/hall-of-fame', label: "Albo d'oro", icon: '⭐' }
	];

	function isActive(href: string) {
		return $page.url.pathname.startsWith(href);
	}
</script>

<nav class="bottom-nav" aria-label="Navigazione principale">
	{#each items as item (item.href)}
		<a href={item.href} class:active={isActive(item.href)} aria-current={isActive(item.href) ? 'page' : undefined}>
			<span class="icon" aria-hidden="true">{item.icon}</span>
			<span class="label">{item.label}</span>
		</a>
	{/each}
</nav>

<style>
	.bottom-nav {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		display: flex;
		background: #ffffff;
		border-top: 1px solid #dce6ef;
		padding: 6px 4px calc(6px + env(safe-area-inset-bottom));
		z-index: 20;
	}
	a {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 2px;
		padding: 8px 4px;
		min-height: 44px;
		color: #64748b;
		text-decoration: none;
		border-radius: 12px;
		font-size: 12px;
		font-weight: 600;
		touch-action: manipulation;
	}
	a.active {
		color: #1261a6;
		background: #eaf4fb;
	}
	.icon {
		font-size: 22px;
	}
</style>
