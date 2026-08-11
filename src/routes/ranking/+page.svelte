<script lang="ts">
	import RankingList from '$lib/components/stats/RankingList.svelte';
	import EmptyState from '$lib/components/EmptyState.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>Classifica — Mondiale</title>
</svelte:head>

<div class="page">
	<h1>Classifica generale</h1>

	{#if data.ranking.length === 0}
		<EmptyState title="Classifica vuota" description="Completa il tuo primo torneo per vedere la classifica." />
	{:else}
		<RankingList entries={data.ranking} />
	{/if}
</div>

<style>
	.page {
		max-width: 720px;
		margin: 0 auto;
		padding: 20px 16px 40px;
	}
	h1 {
		color: var(--color-primary-dark);
		margin: 0 0 16px;
	}
</style>
