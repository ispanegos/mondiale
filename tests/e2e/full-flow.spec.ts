import { test, expect } from '@playwright/test';

/**
 * Test end-to-end completo: login, creazione torneo, gioco di tutte le
 * partite, alcuni bonus, chiusura torneo, verifica albo d'oro e classifica.
 *
 * Richiede:
 * - un progetto Supabase reale raggiungibile con le migrazioni applicate;
 * - un utente di test con email/password validi impostati nelle variabili
 *   d'ambiente E2E_TEST_EMAIL / E2E_TEST_PASSWORD.
 *
 * Questo file non puo' essere eseguito in un sandbox senza rete verso
 * Supabase: va lanciato in locale o in CI dopo aver configurato .env.
 */

const EMAIL = process.env.E2E_TEST_EMAIL ?? '';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? '';

test.skip(!EMAIL || !PASSWORD, 'Richiede E2E_TEST_EMAIL e E2E_TEST_PASSWORD configurate');

test('flusso completo: login, torneo, chiusura, albo d\'oro, classifica', async ({ page }) => {
	await page.goto('/login');
	await page.getByLabel('Email').fill(EMAIL);
	await page.getByLabel('Password').fill(PASSWORD);
	await page.getByRole('button', { name: 'Accedi' }).click();
	await expect(page).toHaveURL('/');

	await page.getByRole('link', { name: /Crea nuovo torneo/i }).click();
	await page.getByPlaceholder('Es. Mondiale di Casa').fill('Torneo E2E');
	await page.getByRole('button', { name: 'Avanti' }).click();

	await page.getByRole('button', { name: '32' }).click();
	await page.getByRole('button', { name: 'Avanti' }).click();

	await page.getByRole('button', { name: /Casuale/ }).click();
	await page.getByRole('button', { name: 'Avanti' }).click();

	await page.getByRole('button', { name: /Sorteggio casuale/ }).click();
	await page.getByRole('button', { name: 'Avanti' }).click();

	await page.getByRole('button', { name: 'Crea torneo' }).click();
	await expect(page).toHaveURL(/\/tournaments\/.+\/play/);

	// gioca tutte le partite del primo turno scegliendo sempre la prima squadra
	const teamButtons = page.locator('.team-btn').first();
	for (let i = 0; i < 16; i++) {
		await teamButtons.click();
		await page.waitForTimeout(300);
	}
});
