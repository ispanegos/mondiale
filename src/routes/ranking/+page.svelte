<script lang="ts">
	import RankingList from '$lib/components/stats/RankingList.svelte';
	import EmptyState from '$lib/components/EmptyState.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	// Filtri predisposti; "Generale" e' l'unico implementato in questa versione,
	// gli altri restano pronti per un filtro temporale successivo.
	let segment = $state<'general' | 'last5' | 'year'>('general');
</script>

<svelte:head>
	<title>Classifica — Mondiale</title>
</svelte:head>

<div class="page">
	<h1>Classifica generale</h1>

	<div class="segments">
		<button type="button" class:active={segment === 'general'} onclick={() => (segment = 'general')}>Generale</button>
		<button type="button" class:active={segment === 'last5'} disabled onclick={() => (segment = 'last5')}>
			Ultimi 5 tornei
		</button>
		<button type="button" class:active={segment === 'year'} disabled onclick={() => (segment = 'year')}>
			Anno corrente
		</button>
	</div>

	{#if data.ranking.length === 0}
		<EmptyState title="Classifica vuota" description="Completa il tuo primo torneo per vedere la classifica." />
	{:else}
		<RankingList entries={data.ranking} />
	{/if}
</div>

<style>
	.page {
		max-width: 560px;
		margin: 0 auto;
		padding: 20px 16px 40px;
	}
	h1 {
		color: var(--color-primary-dark);
		margin: 0 0 16px;
	}
	.segments {
		display: flex;
		gap: 8px;
		margin-bottom: 16px;
		overflow-x: auto;
	}
	.segments button {
		border: 1px solid var(--color-border);
		background: var(--color-surface);
		border-radius: 999px;
		padding: 8px 14px;
		font-size: 13px;
		font-weight: 600;
		white-space: nowrap;
		min-height: 36px;
		color: var(--color-text-secondary);
	}
	.segments button.active {
		background: var(--color-primary);
		border-color: var(--color-primary);
		color: white;
	}
	.segments button:disabled {
		opacity: 0.4;
	}
</style>
