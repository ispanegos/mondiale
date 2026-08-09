<script lang="ts">
	import { enhance } from '$app/forms';
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import { validateTournamentName } from '$lib/utils/validation';
	import { pickRandomTeams, pickBestTeams } from '$lib/utils/bracket';
	import type { PageData, ActionData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	let step = $state(1);
	let name = $state('');
	let size = $state<8 | 16 | 32 | 64 | null>(null);
	let selected = $state<Set<string>>(new Set());
	let drawMode = $state<'random' | 'manual'>('random');
	let search = $state('');
	let submitting = $state(false);

	const nameError = $derived(name.length > 0 ? validateTournamentName(name) : null);

	const filteredTeams = $derived(
		data.teams.filter((t) => t.name.toLowerCase().includes(search.toLowerCase()))
	);

	function toggleTeam(id: string) {
		const next = new Set(selected);
		if (next.has(id)) next.delete(id);
		else next.add(id);
		selected = next;
	}

	function selectRandom() {
		if (!size) return;
		selected = new Set(pickRandomTeams(data.teams, size).map((t) => t.id));
	}

	function selectBest() {
		if (!size) return;
		const withStrength = data.teams.map((t) => ({
			...t,
			seed_strength: data.rankedStrength[t.id] ?? t.seed_strength
		}));
		selected = new Set(pickBestTeams(withStrength, size).map((t) => t.id));
	}

	function deselectAll() {
		selected = new Set();
	}

	function canGoNext(): boolean {
		if (step === 1) return !nameError && name.trim().length >= 2;
		if (step === 2) return size !== null;
		if (step === 3) return size !== null && selected.size === size;
		return true;
	}
</script>

<svelte:head>
	<title>Nuovo torneo — Mondiale</title>
</svelte:head>

<div class="page">
	<div class="steps-indicator">
		{#each [1, 2, 3, 4, 5] as s (s)}
			<span class:active={s === step} class:done={s < step}></span>
		{/each}
	</div>

	{#if step === 1}
		<section>
			<h1>Nome del torneo</h1>
			<input
				type="text"
				placeholder="Es. Mondiale di Casa"
				bind:value={name}
				maxlength="60"
			/>
			{#if nameError}<p class="error">{nameError}</p>{/if}
		</section>
	{:else if step === 2}
		<section>
			<h1>Numero di squadre</h1>
			<div class="size-cards">
				<button type="button" class:selected={size === 8} onclick={() => (size = 8)}>
					<strong>8</strong>
					<span>squadre</span>
				</button>
				<button type="button" class:selected={size === 16} onclick={() => (size = 16)}>
					<strong>16</strong>
					<span>squadre</span>
				</button>
				<button type="button" class:selected={size === 32} onclick={() => (size = 32)}>
					<strong>32</strong>
					<span>squadre</span>
				</button>
				<button type="button" class:selected={size === 64} onclick={() => (size = 64)}>
					<strong>64</strong>
					<span>squadre</span>
				</button>
			</div>
		</section>
	{:else if step === 3 && size}
		<section>
			<h1>Seleziona le squadre</h1>
			<p class="counter">{selected.size} di {size} selezionate</p>
			<input type="search" placeholder="Cerca nazionale…" bind:value={search} class="search" />
			<div class="quick-actions">
				<button type="button" onclick={selectRandom}>🎲 Casuale</button>
				<button type="button" onclick={selectBest}>⭐ Le migliori</button>
				<button type="button" onclick={deselectAll}>✖️ Deseleziona tutte</button>
			</div>
			<ul class="team-list">
				{#each filteredTeams as team (team.id)}
					<li>
						<label>
							<input
								type="checkbox"
								checked={selected.has(team.id)}
								disabled={!selected.has(team.id) && selected.size >= size}
								onchange={() => toggleTeam(team.id)}
							/>
							<TeamFlag emoji={team.flag_emoji} url={team.flag_url} size={22} />
							<span>{team.name}</span>
						</label>
					</li>
				{/each}
			</ul>
		</section>
	{:else if step === 4}
		<section>
			<h1>Ordine del tabellone</h1>
			<div class="draw-options">
				<button type="button" class:selected={drawMode === 'random'} onclick={() => (drawMode = 'random')}>
					🎲 Sorteggio casuale
				</button>
				<button type="button" class:selected={drawMode === 'manual'} onclick={() => (drawMode = 'manual')}>
					✋ Ordine manuale (ordine di selezione)
				</button>
			</div>
			{#if drawMode === 'manual'}
				<p class="hint">Verranno usate nell'ordine in cui le hai selezionate al passaggio precedente.</p>
			{/if}
		</section>
	{:else if step === 5 && size}
		<section>
			<h1>Riepilogo</h1>
			<dl class="summary">
				<dt>Nome</dt>
				<dd>{name}</dd>
				<dt>Squadre</dt>
				<dd>{size}</dd>
				<dt>Sorteggio</dt>
				<dd>{drawMode === 'random' ? 'Casuale' : 'Manuale'}</dd>
			</dl>

			{#if form?.error}
				<p class="error" role="alert">{form.error}</p>
			{/if}

			<form
				method="POST"
				action="?/create"
				use:enhance={() => {
					submitting = true;
					return async ({ update }) => {
						await update();
						submitting = false;
					};
				}}
			>
				<input type="hidden" name="name" value={name} />
				<input type="hidden" name="size" value={size} />
				<input type="hidden" name="draw_mode" value={drawMode} />
				{#each selected as id (id)}
					<input type="hidden" name="team_id" value={id} />
				{/each}
				<button type="submit" class="primary" disabled={submitting}>
					{submitting ? 'Creazione in corso…' : 'Crea torneo'}
				</button>
			</form>
		</section>
	{/if}

	<div class="nav-buttons">
		{#if step > 1}
			<button type="button" class="ghost" onclick={() => (step -= 1)}>Indietro</button>
		{/if}
		{#if step < 5}
			<button type="button" class="primary" disabled={!canGoNext()} onclick={() => (step += 1)}>Avanti</button>
		{/if}
	</div>
</div>

<style>
	.page {
		max-width: 560px;
		margin: 0 auto;
		padding: 20px 16px calc(140px + env(safe-area-inset-bottom));
	}
	.steps-indicator {
		display: flex;
		gap: 6px;
		margin-bottom: 24px;
	}
	.steps-indicator span {
		flex: 1;
		height: 4px;
		border-radius: 4px;
		background: var(--color-border);
	}
	.steps-indicator span.active,
	.steps-indicator span.done {
		background: var(--color-primary);
	}
	h1 {
		color: var(--color-primary-dark);
		font-size: 20px;
		margin: 0 0 16px;
	}
	input[type='text'],
	input.search {
		width: 100%;
		border: 1px solid var(--color-border);
		border-radius: 12px;
		padding: 14px;
		font-size: 16px;
		min-height: 48px;
	}
	.error {
		color: #b3261e;
		font-size: 14px;
	}
	.size-cards {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 12px;
	}
	.size-cards button {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 4px;
		padding: 20px;
		border: 2px solid var(--color-border);
		border-radius: 16px;
		background: var(--color-surface);
		cursor: pointer;
		min-height: 44px;
	}
	.size-cards button.selected {
		border-color: var(--color-primary);
		background: #eaf4fb;
	}
	.size-cards strong {
		font-size: 28px;
		color: var(--color-primary-dark);
	}
	.counter {
		color: var(--color-text-secondary);
		font-size: 14px;
		margin: 0 0 12px;
	}
	.quick-actions {
		display: flex;
		gap: 8px;
		margin: 12px 0;
		flex-wrap: wrap;
	}
	.quick-actions button {
		border: 1px solid var(--color-border);
		background: var(--color-surface);
		border-radius: 999px;
		padding: 8px 14px;
		font-size: 13px;
		min-height: 36px;
		cursor: pointer;
	}
	.team-list {
		list-style: none;
		margin: 0;
		padding: 0;
		max-height: 50vh;
		overflow-y: auto;
		border: 1px solid var(--color-border);
		border-radius: 16px;
		background: var(--color-surface);
	}
	.team-list li {
		border-bottom: 1px solid var(--color-border);
	}
	.team-list li:last-child {
		border-bottom: none;
	}
	.team-list label {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 12px 14px;
		min-height: 44px;
		cursor: pointer;
	}
	.draw-options {
		display: flex;
		flex-direction: column;
		gap: 10px;
	}
	.draw-options button {
		text-align: left;
		border: 2px solid var(--color-border);
		border-radius: 14px;
		padding: 16px;
		background: var(--color-surface);
		font-size: 15px;
		cursor: pointer;
		min-height: 44px;
	}
	.draw-options button.selected {
		border-color: var(--color-primary);
		background: #eaf4fb;
	}
	.hint {
		color: var(--color-text-secondary);
		font-size: 13px;
	}
	.summary {
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		padding: 16px;
		margin: 0 0 16px;
	}
	.summary dt {
		color: var(--color-text-secondary);
		font-size: 12px;
	}
	.summary dd {
		margin: 0 0 12px;
		font-weight: 700;
	}
	.nav-buttons {
		position: fixed;
		bottom: calc(66px + env(safe-area-inset-bottom));
		left: 0;
		right: 0;
		display: flex;
		gap: 10px;
		padding: 12px 16px;
		background: var(--color-surface);
		border-top: 1px solid var(--color-border);
		box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.06);
		z-index: 15;
	}
	button.primary {
		flex: 1;
		background: var(--color-primary);
		color: white;
		border: none;
		border-radius: 14px;
		padding: 14px;
		font-weight: 700;
		font-size: 15px;
		min-height: 48px;
		cursor: pointer;
	}
	button.primary:disabled {
		opacity: 0.5;
		cursor: default;
	}
	button.ghost {
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 14px;
		padding: 14px 20px;
		font-weight: 600;
		min-height: 48px;
		cursor: pointer;
	}
</style>
