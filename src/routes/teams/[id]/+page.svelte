<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import StatCard from '$lib/components/stats/StatCard.svelte';
	import { formatPercent } from '$lib/utils/formatting';
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

	{#if data.opponentStats}
		<h2>Avversarie</h2>
		<ul class="opponents">
			{#if data.opponentStats.mostFaced}
				<li>
					<TeamFlag emoji={data.opponentStats.mostFaced.team.flag_emoji} url={data.opponentStats.mostFaced.team.flag_url} size={28} />
					<div class="opp-info">
						<span class="opp-label">Più affrontata</span>
						<span class="opp-name">{data.opponentStats.mostFaced.team.name}</span>
					</div>
					<span class="opp-count">{data.opponentStats.mostFaced.count}</span>
				</li>
			{/if}
			{#if data.opponentStats.mostWinsAgainst}
				<li>
					<TeamFlag emoji={data.opponentStats.mostWinsAgainst.team.flag_emoji} url={data.opponentStats.mostWinsAgainst.team.flag_url} size={28} />
					<div class="opp-info">
						<span class="opp-label">Più vittorie contro</span>
						<span class="opp-name">{data.opponentStats.mostWinsAgainst.team.name}</span>
					</div>
					<span class="opp-count win">{data.opponentStats.mostWinsAgainst.count}</span>
				</li>
			{/if}
			{#if data.opponentStats.mostLossesAgainst}
				<li>
					<TeamFlag emoji={data.opponentStats.mostLossesAgainst.team.flag_emoji} url={data.opponentStats.mostLossesAgainst.team.flag_url} size={28} />
					<div class="opp-info">
						<span class="opp-label">Più sconfitte contro</span>
						<span class="opp-name">{data.opponentStats.mostLossesAgainst.team.name}</span>
					</div>
					<span class="opp-count loss">{data.opponentStats.mostLossesAgainst.count}</span>
				</li>
			{/if}
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
	.opponents {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	.opponents li {
		display: flex;
		align-items: center;
		gap: 12px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 14px;
		padding: 12px 14px;
	}
	.opp-info {
		display: flex;
		flex-direction: column;
		gap: 2px;
		flex: 1;
		min-width: 0;
	}
	.opp-label {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.opp-name {
		font-size: 15px;
		font-weight: 600;
		color: var(--color-text);
	}
	.opp-count {
		font-size: 18px;
		font-weight: 700;
		color: var(--color-primary);
		flex-shrink: 0;
	}
	.opp-count.win {
		color: #1a8a4a;
	}
	.opp-count.loss {
		color: #c0392b;
	}
</style>
