<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import StatCard from '$lib/components/stats/StatCard.svelte';
	import { formatDate, formatPercent } from '$lib/utils/formatting';
	import { placementLabel } from '$lib/utils/scoring';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>{data.team.name} — Mondiale</title>
</svelte:head>

<div class="page">
	<header>
		<TeamFlag emoji={data.team.flag_emoji} url={data.team.flag_url} size={48} />
		<div>
			<h1>{data.team.name}</h1>
			{#if data.position}<p class="pos">Posizione #{data.position} in classifica</p>{/if}
		</div>
	</header>

	{#if data.stats}
		<div class="stats-grid">
			<StatCard label="Punti totali" value={data.stats.total_points} />
			<StatCard label="Tornei giocati" value={data.stats.tournaments_played} />
			<StatCard label="Tornei vinti" value={data.stats.first_places} />
			<StatCard label="Podi" value={data.stats.podiums} />
			<StatCard label="Partite vinte" value={data.stats.matches_won} />
			<StatCard label="Partite perse" value={data.stats.matches_lost} />
			<StatCard label="% vittorie" value={formatPercent(data.stats.win_rate)} />
			<StatCard label="Punti bonus" value={data.stats.bonus_points} />
		</div>
	{:else}
		<p class="empty">Questa squadra non ha ancora disputato tornei.</p>
	{/if}

	{#if data.history.length > 0}
		<h2>Storico tornei</h2>
		<ul class="history">
			{#each data.history as h (h.tournament.id)}
				<li>
					<a href="/tournaments/{h.tournament.id}">
						<strong>{h.tournament.name}</strong>
						<span class="meta">{formatDate(h.tournament.completed_at)}</span>
						{#if h.finalPosition}
							<span class="placement">{placementLabel(h.finalPosition)} · {h.placementPoints} pt piazzamento</span>
						{/if}
					</a>
				</li>
			{/each}
		</ul>
	{/if}
</div>

<style>
	.page {
		max-width: 560px;
		margin: 0 auto;
		padding: 20px 16px 40px;
	}
	header {
		display: flex;
		align-items: center;
		gap: 14px;
		margin-bottom: 20px;
	}
	h1 {
		margin: 0;
		color: var(--color-primary-dark);
		font-size: 22px;
	}
	.pos {
		margin: 2px 0 0;
		color: var(--color-text-secondary);
		font-size: 13px;
	}
	.stats-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 10px;
	}
	.empty {
		color: var(--color-text-secondary);
	}
	h2 {
		font-size: 15px;
		color: var(--color-text-secondary);
		margin: 24px 0 8px;
	}
	.history {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	.history a {
		display: flex;
		flex-direction: column;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 14px;
		padding: 12px 14px;
		text-decoration: none;
		color: var(--color-text);
		gap: 2px;
	}
	.meta {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.placement {
		font-size: 12px;
		color: var(--color-primary);
		font-weight: 600;
	}
</style>
