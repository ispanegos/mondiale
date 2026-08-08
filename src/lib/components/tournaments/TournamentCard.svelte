<script lang="ts">
	import type { TournamentRow } from '$lib/types/database';
	import { formatDate } from '$lib/utils/formatting';

	let {
		tournament,
		onRename,
		onDelete
	}: {
		tournament: TournamentRow;
		onRename: () => void;
		onDelete: () => void;
	} = $props();

	const statusLabel: Record<string, string> = {
		draft: 'Bozza',
		active: 'In corso',
		completed: 'Completato'
	};

	let menuOpen = $state(false);
</script>

<div class="card">
	<a class="card-link" href="/tournaments/{tournament.id}">
		<div class="row">
			<h3>{tournament.name}</h3>
			<span class="badge {tournament.status}">{statusLabel[tournament.status]}</span>
		</div>
		<p class="meta">{tournament.size} squadre · {formatDate(tournament.completed_at ?? tournament.created_at)}</p>
	</a>

	<div class="actions">
		<button type="button" class="menu-btn" aria-label="Azioni torneo" onclick={() => (menuOpen = !menuOpen)}>
			⋯
		</button>
		{#if menuOpen}
			<div class="menu">
				<button
					type="button"
					onclick={() => {
						menuOpen = false;
						onRename();
					}}
				>
					✏️ Rinomina
				</button>
				<button
					type="button"
					class="danger"
					onclick={() => {
						menuOpen = false;
						onDelete();
					}}
				>
					🗑️ Elimina
				</button>
			</div>
		{/if}
	</div>
</div>

<style>
	.card {
		position: relative;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		box-shadow: 0 1px 4px rgba(11, 49, 87, 0.04);
	}
	.card-link {
		display: block;
		padding: 16px 48px 16px 16px;
		text-decoration: none;
		color: inherit;
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
	.actions {
		position: absolute;
		top: 8px;
		right: 4px;
	}
	.menu-btn {
		background: transparent;
		border: none;
		font-size: 20px;
		color: var(--color-text-secondary);
		width: 40px;
		height: 40px;
		cursor: pointer;
		border-radius: 10px;
	}
	.menu {
		position: absolute;
		top: 40px;
		right: 4px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 12px;
		box-shadow: 0 4px 16px rgba(11, 49, 87, 0.12);
		display: flex;
		flex-direction: column;
		min-width: 140px;
		overflow: hidden;
		z-index: 5;
	}
	.menu button {
		text-align: left;
		background: none;
		border: none;
		padding: 12px 14px;
		font-size: 14px;
		cursor: pointer;
		min-height: 44px;
		color: var(--color-text);
	}
	.menu button.danger {
		color: #b3261e;
	}
	.menu button:hover {
		background: var(--color-bg);
	}
</style>
