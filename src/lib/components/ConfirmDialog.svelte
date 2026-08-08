<script lang="ts">
	let {
		open,
		title,
		message,
		confirmLabel = 'Conferma',
		cancelLabel = 'Annulla',
		onConfirm,
		onCancel
	}: {
		open: boolean;
		title: string;
		message: string;
		confirmLabel?: string;
		cancelLabel?: string;
		onConfirm: () => void;
		onCancel: () => void;
	} = $props();

	let dialogEl: HTMLDialogElement | undefined = $state();

	$effect(() => {
		if (!dialogEl) return;
		if (open && !dialogEl.open) dialogEl.showModal();
		if (!open && dialogEl.open) dialogEl.close();
	});
</script>

<dialog bind:this={dialogEl} onclose={onCancel} aria-labelledby="confirm-title">
	<h2 id="confirm-title">{title}</h2>
	<p>{message}</p>
	<div class="actions">
		<button type="button" class="ghost" onclick={onCancel}>{cancelLabel}</button>
		<button type="button" class="primary" onclick={onConfirm}>{confirmLabel}</button>
	</div>
</dialog>

<style>
	dialog {
		border: none;
		border-radius: 18px;
		padding: 24px;
		max-width: 340px;
		width: calc(100% - 48px);
		box-shadow: 0 12px 32px rgba(11, 49, 87, 0.2);
	}
	dialog::backdrop {
		background: rgba(11, 49, 87, 0.4);
	}
	h2 {
		margin: 0 0 8px;
		font-size: 17px;
		color: var(--color-primary-dark, #0b3157);
	}
	p {
		margin: 0 0 20px;
		color: var(--color-text-secondary, #64748b);
		font-size: 14px;
	}
	.actions {
		display: flex;
		gap: 10px;
	}
	button {
		flex: 1;
		min-height: 44px;
		border-radius: 12px;
		font-weight: 700;
		cursor: pointer;
	}
	.ghost {
		background: white;
		border: 1px solid var(--color-border, #dce6ef);
	}
	.primary {
		background: var(--color-primary, #1261a6);
		color: white;
		border: none;
	}
</style>
