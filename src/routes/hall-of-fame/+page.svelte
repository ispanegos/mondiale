<script lang="ts">
	import HallOfFameCard from '$lib/components/stats/HallOfFameCard.svelte';
	import StatCard from '$lib/components/stats/StatCard.svelte';
	import EmptyState from '$lib/components/EmptyState.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	const teamsById = $derived(data.teamsById as Record<string, any>);
</script>

<svelte:head>
	<title>Albo d'oro — Mondiale</title>
</svelte:head>

<div class="page">
	<h1>Albo d'oro</h1>

	{#if data.tournaments.length === 0}
		<EmptyState title="Ancora nessun torneo completato" description="Concludi un torneo per iniziare l'albo d'oro." />
	{:else}
		<div class="highlights">
			{#if data.mostTitled}
				<StatCard label="Più titoli" value="{data.mostTitled.team.name} ({data.mostTitled.titles})" />
			{/if}
			{#if data.mostPodiums}
				<StatCard label="Più podi" value="{data.mostPodiums.team.name} ({data.mostPodiums.podiums})" />
			{/if}
		</div>

		<div class="list">
			{#each data.tournaments as tournament (tournament.id)}
				<HallOfFameCard
					{tournament}
					champion={tournament.champion_team_id ? teamsById[tournament.champion_team_id] : null}
					runnerUp={tournament.runner_up_team_id ? teamsById[tournament.runner_up_team_id] : null}
					third={tournament.third_team_id ? teamsById[tournament.third_team_id] : null}
					fourth={tournament.fourth_team_id ? teamsById[tournament.fourth_team_id] : null}
				/>
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
	h1 {
		color: var(--color-primary-dark);
		margin: 0 0 16px;
	}
	.highlights {
		display: flex;
		gap: 12px;
		margin-bottom: 20px;
	}
	.list {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}
</style>
