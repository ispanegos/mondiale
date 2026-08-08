<script lang="ts">
	import BottomNavigation from '$lib/components/BottomNavigation.svelte';
	import AppHeader from '$lib/components/AppHeader.svelte';
	import { page } from '$app/stores';
	import '../app.css';

	let { children, data } = $props();
	const isLogin = $derived($page.url.pathname === '/login');
</script>

<div class="app-shell">
	{#if !isLogin && data.session}
		<AppHeader />
	{/if}
	<main class:with-nav={!isLogin}>
		{@render children?.()}
	</main>
	{#if !isLogin && data.session}
		<BottomNavigation />
	{/if}
</div>

<style>
	.app-shell {
		min-height: 100dvh;
		background: #f7fafc;
	}
	main.with-nav {
		padding-bottom: 76px;
	}
</style>
