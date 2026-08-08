<script lang="ts">
	let { emoji, url, size = 28 }: { emoji: string; url?: string | null; size?: number } = $props();
	let broken = $state(false);
</script>

{#if url && !broken}
	<img src={url} alt="" width={size} height={size * 0.75} style="object-fit: cover; border-radius: 3px;" onerror={() => (broken = true)} />
{:else}
	<span style="font-size: {size}px; line-height: 1;">{emoji}</span>
{/if}
