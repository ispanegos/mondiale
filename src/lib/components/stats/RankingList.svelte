<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import { formatPercent } from '$lib/utils/formatting';
	import type { RankedTeam } from '$lib/server/ranking';

	type SortKey =
		| 'total_points'
		| 'matches_played'
		| 'matches_won'
		| 'first_places'
		| 'podiums'
		| 'win_rate'
		| 'bonus_points';

	let { entries }: { entries: RankedTeam[] } = $props();

	const columns: { key: SortKey; label: string; short: string }[] = [
		{ key: 'total_points', label: 'Punti', short: 'Pt' },
		{ key: 'matches_played', label: 'Partite giocate', short: 'PG' },
		{ key: 'matches_won', label: 'Vittorie', short: 'V' },
		{ key: 'first_places', label: 'Titoli', short: 'T' },
		{ key: 'podiums', label: 'Podi', short: 'Po' },
		{ key: 'win_rate', label: 'Win rate', short: 'W%' },
		{ key: 'bonus_points', label: 'Bonus', short: 'B' }
	];

	// Criteri di spareggio a parità sul valore ordinante scelto. Il primo della
	// lista e' il criterio secondario evidenziato in tabella; gli altri sono
	// spareggi successivi scelti per dare un ordinamento sempre deterministico.
	const tiebreakers: Record<SortKey, SortKey[]> = {
		total_points: ['win_rate', 'matches_won'],
		matches_played: ['matches_won', 'win_rate'],
		matches_won: ['win_rate', 'total_points'],
		// Stile medagliere: a parità di titoli (1°), conta chi ha più 2° posti,
		// poi chi ha più 3° posti (spareggio gestito a parte, vedi compareSecondPlaces).
		first_places: ['total_points', 'win_rate'],
		podiums: ['total_points', 'win_rate'],
		win_rate: ['total_points', 'matches_won'],
		bonus_points: ['total_points', 'win_rate']
	};

	let sortBy = $state<SortKey>('total_points');

	function compareSecondPlaces(a: RankedTeam, b: RankedTeam): number {
		if (b.second_places !== a.second_places) return b.second_places - a.second_places;
		return b.third_places - a.third_places;
	}

	function compareBy(key: SortKey, a: RankedTeam, b: RankedTeam): number {
		return b[key] - a[key];
	}

	const sorted = $derived(
		[...entries].sort((a, b) => {
			if (b[sortBy] !== a[sortBy]) return b[sortBy] - a[sortBy];

			if (sortBy === 'first_places') {
				const medalCompare = compareSecondPlaces(a, b);
				if (medalCompare !== 0) return medalCompare;
			}

			for (const key of tiebreakers[sortBy]) {
				const cmp = compareBy(key, a, b);
				if (cmp !== 0) return cmp;
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

	function setSort(key: SortKey) {
		sortBy = key;
	}

	// Il criterio secondario evidenziato per la colonna attualmente ordinata.
	const highlightKey = $derived(sortBy === 'first_places' ? 'podiums' : tiebreakers[sortBy][0]);

	function cellValue(entry: RankedTeam, key: SortKey): string {
		if (key === 'win_rate') return formatPercent(entry.win_rate);
		return String(entry[key]);
	}
</script>

<div class="table-wrap">
	<table class="ranking-table">
		<thead>
			<tr>
				<th class="col-pos">#</th>
				<th class="col-flag" aria-hidden="true"></th>
				<th class="col-name">Squadra</th>
				{#each columns as col (col.key)}
					<th
						class="col-stat"
						class:sorted={sortBy === col.key}
						class:highlight={highlightKey === col.key}
					>
						<button type="button" onclick={() => setSort(col.key)} title={col.label}>
							{col.short}
							{#if sortBy === col.key}<span class="arrow">▼</span>{/if}
						</button>
					</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each positioned as { entry }, i (entry.team.id)}
				<tr>
					<td class="col-pos">{positionFor(i)}</td>
					<td class="col-flag">
						<a href="/teams/{entry.team.id}">
							<TeamFlag emoji={entry.team.flag_emoji} url={entry.team.flag_url} size={22} />
						</a>
					</td>
					<td class="col-name">
						<a href="/teams/{entry.team.id}">{entry.team.name}</a>
					</td>
					{#each columns as col (col.key)}
						<td class="col-stat" class:sorted={sortBy === col.key} class:highlight={highlightKey === col.key}>
							{cellValue(entry, col.key)}
						</td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>

<style>
	.table-wrap {
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		overflow-x: auto;
	}
	.ranking-table {
		border-collapse: collapse;
		width: 100%;
		font-size: 13px;
	}
	thead th {
		position: sticky;
		top: 0;
		background: var(--color-surface);
		border-bottom: 2px solid var(--color-border);
		z-index: 1;
	}
	th,
	td {
		padding: 10px 8px;
		text-align: center;
		white-space: nowrap;
	}
	.col-pos {
		width: 28px;
		font-weight: 800;
		color: var(--color-primary);
		font-size: 12px;
	}
	.col-flag {
		width: 32px;
		padding-left: 4px;
		padding-right: 2px;
	}
	.col-flag a {
		display: flex;
	}
	.col-name {
		text-align: left;
		font-weight: 600;
		min-width: 110px;
	}
	.col-name a {
		color: var(--color-text);
		text-decoration: none;
	}
	.col-stat {
		min-width: 44px;
		color: var(--color-text-secondary);
	}
	td.col-stat.sorted {
		font-weight: 800;
		color: var(--color-primary-dark);
	}
	td.col-stat.highlight {
		font-weight: 700;
		color: var(--color-primary);
		background: #eaf4fb;
	}
	th.col-stat button {
		background: none;
		border: none;
		font: inherit;
		font-weight: 700;
		color: var(--color-text-secondary);
		cursor: pointer;
		padding: 4px 6px;
		border-radius: 8px;
		min-height: 32px;
		display: flex;
		align-items: center;
		gap: 3px;
	}
	th.col-stat.sorted button {
		color: var(--color-primary-dark);
	}
	th.col-stat.highlight button {
		color: var(--color-primary);
		background: #eaf4fb;
	}
	.arrow {
		font-size: 8px;
	}
	tbody tr {
		border-top: 1px solid var(--color-border);
	}
	tbody tr:first-child {
		border-top: none;
	}
</style>
