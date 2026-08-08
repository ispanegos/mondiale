<script lang="ts">
	import type { TournamentRow } from '$lib/types/database';
	import { formatDate } from '$lib/utils/formatting';

	let { tournament }: { tournament: TournamentRow } = $props();

	const statusLabel: Record<string, string> = {
		draft: 'Bozza',
		active: 'In corso',
		completed: 'Completato'
	};
</script>

<a class="card" href="/tournaments/{tournament.id}">
	<div class="row">
		<h3>{tournament.name}</h3>
		<span class="badge {tournament.status}">{statusLabel[tournament.status]}</span>
	</div>
	<p class="meta">{tournament.size} squadre · {formatDate(tournament.completed_at ?? tournament.created_at)}</p>
</a>

<style>
	.card {
		display: block;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		padding: 16px;
		text-decoration: none;
		color: inherit;
		box-shadow: 0 1px 4px rgba(11, 49, 87, 0.04);
	}
	.row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 8px;
	}
	h3 {
		margin: 0;
		font-size: 16px;
		color: var(--color-text);
	}
	.meta {
		margin: 6px 0 0;
		color: var(--color-text-secondary);
		font-size: 13px;
	}
	.badge {
		font-size: 11px;
		font-weight: 700;
		padding: 4px 10px;
		border-radius: 999px;
		white-space: nowrap;
	}
	.badge.active {
		background: #eaf4fb;
		color: var(--color-primary);
	}
	.badge.completed {
		background: #eafaf3;
		color: var(--color-success);
	}
	.badge.draft {
		background: #f1f4f8;
		color: var(--color-text-secondary);
	}
</style>
