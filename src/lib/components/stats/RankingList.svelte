<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import { formatPercent } from '$lib/utils/formatting';
	import type { RankedTeam } from '$lib/server/ranking';

	type SortKey = 'total_points' | 'first_places' | 'podiums' | 'matches_won' | 'win_rate' | 'bonus_points';

	let { entries }: { entries: RankedTeam[] } = $props();

	// Ordine di colonna = ordine di priorità nello spareggio, fisso e sempre lo
	// stesso qualunque colonna venga cliccata per ordinare: Punti > Titoli >
	// Podi > Vittorie > Win rate > Bonus. Garantisce che due squadre non siano
	// mai a pari posizione: la posizione e' sempre un numero unico da 1 a 64.
	const columns: { key: SortKey; label: string; short: string }[] = [
		{ key: 'total_points', label: 'Punti', short: 'Pt' },
		{ key: 'first_places', label: 'Titoli', short: '🏆' },
		{ key: 'podiums', label: 'Podi', short: '🏅' },
		{ key: 'matches_won', label: 'Vittorie', short: 'V' },
		{ key: 'win_rate', label: 'Win rate', short: 'W%' },
		{ key: 'bonus_points', label: 'Bonus', short: 'B' }
	];

	const priorityOrder: SortKey[] = columns.map((c) => c.key);

	let sortBy = $state<SortKey>('total_points');

	function setSort(key: SortKey) {
		sortBy = key;
	}

	// Catena di spareggio per la colonna scelta: prima il criterio cliccato,
	// poi gli altri nell'ordine di priorità fisso (senza ripetere quello gia'
	// usato), infine il nome squadra come ultimissima garanzia di unicita'.
	const tiebreakChain = $derived([sortBy, ...priorityOrder.filter((k) => k !== sortBy)]);

	const sorted = $derived(
		[...entries].sort((a, b) => {
			for (const key of tiebreakChain) {
				if (b[key] !== a[key]) return b[key] - a[key];
			}
			return a.team.name.localeCompare(b.team.name, 'it');
		})
	);

	// Il criterio secondario evidenziato: il primo della catena dopo quello scelto.
	const highlightKey = $derived(tiebreakChain[1]);

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
			{#each sorted as entry, i (entry.team.id)}
				<tr>
					<td class="col-pos">{i + 1}</td>
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
