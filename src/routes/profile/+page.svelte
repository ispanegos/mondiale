<script lang="ts">
	import { enhance } from '$app/forms';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	let confirmLogoutOpen = $state(false);
	let logoutFormEl: HTMLFormElement | undefined = $state();
</script>

<svelte:head>
	<title>Profilo — Mondiale</title>
</svelte:head>

<div class="page">
	<h1>Profilo</h1>
	<div class="card">
		<p class="label">Account</p>
		<p class="value">{data.user?.email}</p>
	</div>

	<button type="button" class="logout-btn" onclick={() => (confirmLogoutOpen = true)}>Esci</button>

	<form bind:this={logoutFormEl} method="POST" action="?/logout" use:enhance style="display: none">
	</form>

	<ConfirmDialog
		open={confirmLogoutOpen}
		title="Uscire dall'account?"
		message="Dovrai accedere di nuovo per gestire i tuoi tornei."
		confirmLabel="Esci"
		onConfirm={() => logoutFormEl?.requestSubmit()}
		onCancel={() => (confirmLogoutOpen = false)}
	/>
</div>

<style>
	.page {
		max-width: 560px;
		margin: 0 auto;
		padding: 20px 16px 40px;
	}
	h1 {
		color: var(--color-primary-dark);
		margin: 0 0 16px;
	}
	.card {
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		padding: 16px;
		margin-bottom: 20px;
	}
	.label {
		margin: 0;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.value {
		margin: 4px 0 0;
		font-weight: 700;
	}
	.logout-btn {
		width: 100%;
		background: #fdecea;
		color: #b3261e;
		border: none;
		border-radius: 14px;
		padding: 14px;
		font-weight: 700;
		min-height: 44px;
		cursor: pointer;
	}
</style>
