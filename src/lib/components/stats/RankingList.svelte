<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import { formatPercent } from '$lib/utils/formatting';
	import type { RankedTeam } from '$lib/server/ranking';

	type SortKey = 'total_points' | 'first_places' | 'podiums' | 'win_rate' | 'bonus_points';

	let { entries, sortBy = 'total_points' }: { entries: RankedTeam[]; sortBy?: SortKey } = $props();

	// Criteri di spareggio a parità sul valore ordinante scelto (definiscono solo
	// l'ordine di visualizzazione tra pari merito: la posizione resta la stessa).
	const tiebreakers: Record<SortKey, SortKey[]> = {
		total_points: ['win_rate'],
		first_places: ['total_points', 'win_rate'],
		podiums: ['total_points', 'win_rate'],
		win_rate: ['total_points'],
		bonus_points: ['total_points', 'win_rate']
	};

	const sorted = $derived(
		[...entries].sort((a, b) => {
			if (b[sortBy] !== a[sortBy]) return b[sortBy] - a[sortBy];
			for (const key of tiebreakers[sortBy]) {
				if (b[key] !== a[key]) return b[key] - a[key];
			}
			return a.team.name.localeCompare(b.team.name, 'it');
		})
	);

	// Stessa posizione in caso di parità sul valore ordinante (ranking standard: 1,1,3,...).
	const positioned = $derived(
		sorted.map((entry, i) => ({
			entry,
			position: i > 0 && sorted[i - 1][sortBy] === entry[sortBy] ? null : i + 1
		}))
	);

	function positionFor(index: number): number {
		for (let j = index; j >= 0; j -= 1) {
			if (positioned[j].position !== null) return positioned[j].position as number;
		}
		return index + 1;
	}
</script>

<ul class="ranking-list">
	{#each positioned as { entry }, i (entry.team.id)}
		<li>
			<a href="/teams/{entry.team.id}">
				<span class="pos">{positionFor(i)}</span>
				<TeamFlag emoji={entry.team.flag_emoji} url={entry.team.flag_url} size={24} />
				<span class="name">{entry.team.name}</span>
				{#if sortBy === 'total_points'}
					<span class="points">{entry.total_points} pt</span>
				{:else if sortBy === 'first_places'}
					<span class="points">{entry.first_places} 🏆</span>
				{:else if sortBy === 'podiums'}
					<span class="stat">1° {entry.first_places} · 2° {entry.second_places} · 3° {entry.third_places}</span>
					<span class="points">{entry.podiums} 🏅</span>
				{:else if sortBy === 'win_rate'}
					<span class="points">{formatPercent(entry.win_rate)}</span>
				{:else if sortBy === 'bonus_points'}
					<span class="points">{entry.bonus_points} ⭐</span>
				{/if}
			</a>
		</li>
	{/each}
</ul>

<style>
	.ranking-list {
		list-style: none;
		margin: 0;
		padding: 0;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		overflow: hidden;
	}
	li {
		border-bottom: 1px solid var(--color-border);
	}
	li:last-child {
		border-bottom: none;
	}
	a {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 12px 14px;
		text-decoration: none;
		color: var(--color-text);
		min-height: 44px;
	}
	.pos {
		font-weight: 800;
		color: var(--color-primary);
		width: 20px;
		font-size: 13px;
	}
	.name {
		flex: 1;
		min-width: 0;
		font-weight: 600;
		font-size: 14px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.stat {
		font-size: 11px;
		color: var(--color-text-secondary);
		white-space: nowrap;
	}
	.points {
		font-weight: 700;
		color: var(--color-primary-dark);
		font-size: 13px;
	}
</style>
