<script lang="ts">
	import TournamentCard from '$lib/components/tournaments/TournamentCard.svelte';
	import EmptyState from '$lib/components/EmptyState.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>Tornei — Mondiale</title>
</svelte:head>

<div class="page">
	<div class="header">
		<h1>Tornei</h1>
		<a class="new-btn" href="/tournaments/new">➕ Nuovo</a>
	</div>

	{#if data.tournaments.length === 0}
		<EmptyState
			title="Nessun torneo ancora"
			description="Crea il tuo primo torneo per iniziare a giocare."
			actionHref="/tournaments/new"
			actionLabel="Crea torneo"
		/>
	{:else}
		<div class="list">
			{#each data.tournaments as tournament (tournament.id)}
				<TournamentCard {tournament} />
			{/each}
		</div>
	{/if}
</div>

<style>
	.page {
		max-width: 560px;
		margin: 0 auto;
		padding: 20px 16px 40px;
	}
	.header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 16px;
	}
	h1 {
		color: var(--color-primary-dark);
		margin: 0;
	}
	.new-btn {
		background: var(--color-primary);
		color: white;
		font-weight: 700;
		padding: 10px 16px;
		border-radius: 12px;
		text-decoration: none;
		font-size: 14px;
	}
	.list {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}
</style>
