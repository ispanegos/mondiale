<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import type { RankedTeam } from '$lib/server/ranking';

	type SortKey = 'total_points' | 'first_places' | 'podiums' | 'win_rate' | 'bonus_points';

	let { entries, sortBy = 'total_points' }: { entries: RankedTeam[]; sortBy?: SortKey } = $props();

	const sorted = $derived(
		[...entries].sort((a, b) => {
			if (b[sortBy] !== a[sortBy]) return b[sortBy] - a[sortBy];
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
				<span class="stat">{entry.tournaments_played}🏟️</span>
				<span class="stat">{entry.podiums}🏅</span>
				<span class="points">{entry.total_points} pt</span>
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
		font-weight: 600;
		font-size: 14px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.stat {
		font-size: 11px;
		color: var(--color-text-secondary);
	}
	.points {
		font-weight: 700;
		color: var(--color-primary-dark);
		font-size: 13px;
	}
</style>
