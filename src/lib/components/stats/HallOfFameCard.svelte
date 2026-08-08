<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import { formatDate } from '$lib/utils/formatting';
	import type { TeamRow, TournamentRow } from '$lib/types/database';

	let {
		tournament,
		champion,
		runnerUp,
		third,
		fourth
	}: {
		tournament: TournamentRow;
		champion?: TeamRow | null;
		runnerUp?: TeamRow | null;
		third?: TeamRow | null;
		fourth?: TeamRow | null;
	} = $props();
</script>

<a class="hof-card" href="/tournaments/{tournament.id}">
	<div class="header">
		<strong>{tournament.name}</strong>
		<span class="date">{formatDate(tournament.completed_at)}</span>
	</div>
	<p class="meta">{tournament.size} squadre</p>
	<div class="podium-row">
		{#if champion}
			<span class="entry gold"><TeamFlag emoji={champion.flag_emoji} url={champion.flag_url} size={18} /> {champion.name}</span>
		{/if}
		{#if runnerUp}
			<span class="entry silver"><TeamFlag emoji={runnerUp.flag_emoji} url={runnerUp.flag_url} size={16} /> {runnerUp.name}</span>
		{/if}
		{#if third}
			<span class="entry bronze"><TeamFlag emoji={third.flag_emoji} url={third.flag_url} size={16} /> {third.name}</span>
		{/if}
		{#if fourth}
			<span class="entry fourth"><TeamFlag emoji={fourth.flag_emoji} url={fourth.flag_url} size={16} /> {fourth.name}</span>
		{/if}
	</div>
</a>

<style>
	.hof-card {
		display: block;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		padding: 16px;
		text-decoration: none;
		color: var(--color-text);
	}
	.header {
		display: flex;
		justify-content: space-between;
		gap: 8px;
	}
	.date {
		font-size: 12px;
		color: var(--color-text-secondary);
		white-space: nowrap;
	}
	.meta {
		margin: 2px 0 10px;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.podium-row {
		display: flex;
		flex-wrap: wrap;
		gap: 8px;
	}
	.entry {
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 12px;
		font-weight: 600;
		padding: 4px 8px;
		border-radius: 999px;
		background: #f1f4f8;
	}
	.entry.gold {
		background: #fbf1da;
		color: var(--color-gold);
	}
	.entry.silver {
		background: #f1f2f4;
		color: var(--color-silver);
	}
	.entry.bronze {
		background: #f7ece3;
		color: var(--color-bronze);
	}
	.entry.fourth {
		color: var(--color-text-secondary);
	}
</style>
