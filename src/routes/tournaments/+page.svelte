<script lang="ts">
	import { enhance } from '$app/forms';
	import TournamentCard from '$lib/components/tournaments/TournamentCard.svelte';
	import EmptyState from '$lib/components/EmptyState.svelte';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import { validateTournamentName } from '$lib/utils/validation';
	import type { PageData, ActionData } from './$types';
	import type { TournamentRow } from '$lib/types/database';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	let renameTarget = $state<TournamentRow | null>(null);
	let renameValue = $state('');
	let renameFormEl: HTMLFormElement | undefined = $state();
	const renameError = $derived(renameValue.length > 0 ? validateTournamentName(renameValue) : null);

	let deleteTarget = $state<TournamentRow | null>(null);
	let deleteFormEl: HTMLFormElement | undefined = $state();

	function openRename(t: TournamentRow) {
		renameTarget = t;
		renameValue = t.name;
	}
</script>

<svelte:head>
	<title>Tornei — Mondiale</title>
</svelte:head>

<div class="page">
	<div class="header">
		<h1>Tornei</h1>
		<a class="new-btn" href="/tournaments/new">➕ Nuovo</a>
	</div>

	{#if form?.error}
		<p class="error" role="alert">{form.error}</p>
	{/if}

	{#if data.tournaments.length === 0}
		<EmptyState
			title="Nessun torneo ancora"
			description="Crea il tuo primo torneo per iniziare a giocare."
			actionHref="/tournaments/new"
			actionLabel="Crea torneo"
		/>
	{:else}
		<div class="list">
			{#each data.tournaments as tournament (tournament.id)}
				<TournamentCard {tournament} onRename={() => openRename(tournament)} onDelete={() => (deleteTarget = tournament)} />
			{/each}
		</div>
	{/if}
</div>

<!-- Dialogo rinomina -->
{#if renameTarget}
	<div
		class="overlay"
		role="button"
		tabindex="0"
		aria-label="Chiudi"
		onclick={() => (renameTarget = null)}
		onkeydown={(e) => e.key === 'Escape' && (renameTarget = null)}
	>
		<div class="dialog" role="dialog" aria-labelledby="rename-title" onclick={(e) => e.stopPropagation()}>
			<h2 id="rename-title">Rinomina torneo</h2>
			<form
				bind:this={renameFormEl}
				method="POST"
				action="?/rename"
				use:enhance={() => {
					return async ({ update }) => {
						await update();
						renameTarget = null;
					};
				}}
			>
				<input type="hidden" name="tournament_id" value={renameTarget.id} />
				<input type="text" name="name" bind:value={renameValue} maxlength="60" />
				{#if renameError}<p class="field-error">{renameError}</p>{/if}
				<div class="dialog-actions">
					<button type="button" class="ghost" onclick={() => (renameTarget = null)}>Annulla</button>
					<button type="submit" class="primary" disabled={!!renameError || renameValue.trim().length < 2}>
						Salva
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<!-- Conferma eliminazione -->
{#if deleteTarget}
	<form bind:this={deleteFormEl} method="POST" action="?/delete" use:enhance style="display: none">
		<input type="hidden" name="tournament_id" value={deleteTarget.id} />
	</form>
	<ConfirmDialog
		open={!!deleteTarget}
		title="Eliminare questo torneo?"
		message="'{deleteTarget.name}' e tutti i suoi risultati verranno cancellati per sempre. Non si può annullare."
		confirmLabel="Elimina"
		cancelLabel="Annulla"
		onConfirm={() => deleteFormEl?.requestSubmit()}
		onCancel={() => (deleteTarget = null)}
	/>
{/if}

<style>
	.page {
		max-width: 560px;
		margin: 0 auto;
		padding: 20px 16px 40px;
	}
	.header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 16px;
	}
	h1 {
		color: var(--color-primary-dark);
		margin: 0;
	}
	.new-btn {
		background: var(--color-primary);
		color: white;
		font-weight: 700;
		padding: 10px 16px;
		border-radius: 12px;
		text-decoration: none;
		font-size: 14px;
	}
	.list {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}
	.error {
		color: #b3261e;
		background: #fdecea;
		border-radius: 12px;
		padding: 10px 14px;
		font-size: 14px;
		margin-bottom: 16px;
	}
	.overlay {
		position: fixed;
		inset: 0;
		background: rgba(11, 49, 87, 0.4);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 30;
		padding: 24px;
	}
	.dialog {
		background: white;
		border-radius: 18px;
		padding: 24px;
		max-width: 340px;
		width: 100%;
		box-shadow: 0 12px 32px rgba(11, 49, 87, 0.2);
	}
	.dialog h2 {
		margin: 0 0 16px;
		font-size: 17px;
		color: var(--color-primary-dark);
	}
	.dialog input[type='text'] {
		width: 100%;
		border: 1px solid var(--color-border);
		border-radius: 12px;
		padding: 12px 14px;
		font-size: 16px;
		min-height: 44px;
	}
	.field-error {
		color: #b3261e;
		font-size: 13px;
		margin: 6px 0 0;
	}
	.dialog-actions {
		display: flex;
		gap: 10px;
		margin-top: 16px;
	}
	.dialog-actions button {
		flex: 1;
		min-height: 44px;
		border-radius: 12px;
		font-weight: 700;
		cursor: pointer;
	}
	.dialog-actions .ghost {
		background: white;
		border: 1px solid var(--color-border);
	}
	.dialog-actions .primary {
		background: var(--color-primary);
		color: white;
		border: none;
	}
	.dialog-actions .primary:disabled {
		opacity: 0.5;
	}
</style>
