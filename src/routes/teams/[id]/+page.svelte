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
		<div class="opp-sections">
			{#if data.opponentStats.mostFaced.length > 0}
				<div class="opp-section">
					<p class="opp-label">Più affrontata{data.opponentStats.mostFaced.length > 1 ? 'e' : ''}</p>
					<ul class="opponents">
						{#each data.opponentStats.mostFaced as o (o.team.id)}
							<li>
								<TeamFlag emoji={o.team.flag_emoji} url={o.team.flag_url} size={28} />
								<span class="opp-name">{o.team.name}</span>
								<span class="opp-count">{o.count}</span>
							</li>
						{/each}
					</ul>
				</div>
			{/if}
			{#if data.opponentStats.mostWinsAgainst.length > 0}
				<div class="opp-section">
					<p class="opp-label">Più vittorie contro</p>
					<ul class="opponents">
						{#each data.opponentStats.mostWinsAgainst as o (o.team.id)}
							<li>
								<TeamFlag emoji={o.team.flag_emoji} url={o.team.flag_url} size={28} />
								<span class="opp-name">{o.team.name}</span>
								<span class="opp-count win">{o.count}</span>
							</li>
						{/each}
					</ul>
				</div>
			{/if}
			{#if data.opponentStats.mostLossesAgainst.length > 0}
				<div class="opp-section">
					<p class="opp-label">Più sconfitte contro</p>
					<ul class="opponents">
						{#each data.opponentStats.mostLossesAgainst as o (o.team.id)}
							<li>
								<TeamFlag emoji={o.team.flag_emoji} url={o.team.flag_url} size={28} />
								<span class="opp-name">{o.team.name}</span>
								<span class="opp-count loss">{o.count}</span>
							</li>
						{/each}
					</ul>
				</div>
			{/if}
		</div>
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
	.opp-sections {
		display: flex;
		flex-direction: column;
		gap: 16px;
	}
	.opp-section {
		display: flex;
		flex-direction: column;
		gap: 6px;
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
	.opp-label {
		margin: 0;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.opp-name {
		flex: 1;
		min-width: 0;
		font-size: 15px;
		font-weight: 600;
		color: var(--color-text);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
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
