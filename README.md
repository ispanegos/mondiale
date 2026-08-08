# Mondiale — Tornei a eliminazione diretta tra nazionali

App privata e familiare per simulare tornei a eliminazione diretta tra
nazionali di calcio, senza inserire risultati numerici: si tocca la squadra
vincitrice e lei avanza al turno successivo. Gestisce podio, quarto posto,
albo d'oro e classifica generale storica.

Stack: **SvelteKit + Svelte 5 + TypeScript + Supabase (Postgres, Auth, RLS) +
Vercel**.

## 1. Prerequisiti

- Node.js 20+
- Un account [Supabase](https://supabase.com) (piano gratuito sufficiente)
- Un account [Vercel](https://vercel.com) (per il deploy)
- La [Supabase CLI](https://supabase.com/docs/guides/cli) per applicare le
  migrazioni (`npm install -g supabase` oppure `brew install supabase/tap/supabase`)

## 2. Installazione

```bash
npm install
```

## 3. Creazione progetto Supabase

1. Vai su [supabase.com/dashboard](https://supabase.com/dashboard) e crea un
   nuovo progetto.
2. Annota **Project URL** e **anon/publishable key** (Project Settings → API).
3. Collega il progetto locale:
   ```bash
   supabase login
   supabase link --project-ref <il-tuo-project-ref>
   ```

## 4. Applicazione delle migrazioni

Le migrazioni sono in `supabase/migrations/`, in ordine:

1. `0001_schema.sql` — tabelle
2. `0002_rls.sql` — Row Level Security
3. `0003_functions.sql` — funzioni RPC (creazione torneo, avanzamento, bonus, chiusura, riapertura)
4. `0004_stats_view.sql` — view classifica calcolata

Applicale con:

```bash
supabase db push
```

## 5. Esecuzione del seed

Il seed delle 64 nazionali (dati condivisi, non modificabili da frontend) è
in `supabase/seed.sql`:

```bash
psql "$(supabase db url)" -f supabase/seed.sql
```

(oppure incolla il contenuto nel SQL Editor della dashboard Supabase)

Verifica che siano state inserite esattamente 64 righe, inclusa **San Marino**.

### Dati demo (solo sviluppo)

`supabase/seed_demo.sql` crea un torneo demo attivo e uno completato per un
utente di test. **Non eseguirlo in produzione.** Richiede un `user_id` reale:

```bash
psql "$(supabase db url)" \
  -v demo_user_id="'<uuid-utente-di-test>'" \
  -f supabase/seed_demo.sql
```

## 6. Configurazione `.env`

Copia `.env.example` in `.env` e compila:

```bash
cp .env.example .env
```

```
PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
PUBLIC_SUPABASE_PUBLISHABLE_KEY=<anon-key-dal-dashboard>
SUPABASE_SECRET_KEY=<service-role-key-solo-se-necessaria>
```

La `SUPABASE_SECRET_KEY` non è usata dal codice attuale: tutte le operazioni
sensibili passano per RPC protette da RLS + `auth.uid()`. Tienila comunque a
disposizione per eventuali estensioni amministrative future, e **non
committarla mai**.

## 7. Avvio locale

```bash
npm run dev
```

Apri http://localhost:5173

## 8. Creazione di un utente

Nella dashboard Supabase → Authentication → Users → "Add user", oppure via
SQL Editor con `supabase.auth.admin.createUser`. La prima versione dell'app
prevede login semplice email/password, senza registrazione self-service da
frontend (è un'app familiare, gli account si creano manualmente).

## 9. Esecuzione dei test

Test unitari (logica pura, nessuna dipendenza da Supabase):

```bash
npm run test
```

Test end-to-end (richiede un progetto Supabase reale con migrazioni e seed
applicati, e un utente di test):

```bash
E2E_TEST_EMAIL=test@example.com E2E_TEST_PASSWORD=... npm run test:e2e
```

## 10. Collegamento a GitHub

```bash
git init
git add .
git commit -m "Mondiale: setup iniziale"
git remote add origin <url-del-tuo-repo>
git push -u origin main
```

## 11. Deploy su Vercel

1. Importa il repository su [vercel.com/new](https://vercel.com/new).
2. Vercel rileva SvelteKit automaticamente (adapter Vercel già configurato in
   `svelte.config.js`).
3. Configura le variabili d'ambiente (vedi punto 12).
4. Deploy.

## 12. Variabili d'ambiente su Vercel

In Project Settings → Environment Variables, aggiungi:

- `PUBLIC_SUPABASE_URL`
- `PUBLIC_SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SECRET_KEY` (se in futuro serve lato server)

## Comandi

```bash
npm install
npm run dev       # sviluppo locale
npm run check     # type-check (svelte-check)
npm run test      # test unitari (vitest)
npm run test:e2e  # test end-to-end (playwright, richiede Supabase reale)
npm run build     # build di produzione
```

## Decisioni tecniche prese

- **Ordine semi/finalina non gestito da `next_match_id`**: le sconfitte
  semifinaliste vengono instradate alla finale 3°/4° posto da logica
  esplicita dentro `select_match_winner` (la tabella `matches` modella solo
  la propagazione dei vincitori; la finalina viene riconosciuta come "il
  turno successivo alla semifinale è la finale").
- **Correzione risultati**: implementata come invalidazione ricorsiva a
  cascata (`clear_match_result` / `clear_third_place_slot`) invece di una
  singola funzione `recalculate_tournament_from_match` separata, per evitare
  logica duplicata tra "correggi" e "ricalcola".
- **Classifica**: mai un campo `total_points` modificabile — sempre dalla
  view `team_global_stats`, con `security_invoker = true` per rispettare le
  RLS per-utente.
- **Filtri temporali classifica** ("Ultimi 5 tornei", "Anno corrente"): UI
  già predisposta ma disabilitata nella v1, come da specifica (punto 14).
- **Interazioni di gioco**: implementate con SvelteKit form actions +
  `use:enhance` (niente reload di pagina, dati sempre coerenti col server,
  pulsanti disabilitati durante l'invio) invece di chiamate dirette al
  client Supabase dal browser.

## Risultati verificati in fase di sviluppo

- `npm install`: ✅ riuscito
- `npm run test` (vitest): ✅ **18/18 test passati**
- `npm run check` (svelte-check): ✅ **0 errori, 0 warning**
- `npm run build`: ✅ **build di produzione riuscito** con adapter Vercel

> Nota: queste verifiche sono state eseguite in un ambiente sandbox senza
> accesso di rete a un progetto Supabase reale né a Vercel. Type-check,
> build e test unitari (logica pura) sono stati quindi eseguiti ed sono
> verdi; i test end-to-end e il deploy vanno verificati con un progetto
> Supabase/Vercel reale collegato, seguendo i passaggi 3–12 sopra.

## Criteri di accettazione — stato

- [x] Parte con `npm run dev` (struttura verificata, richiede `.env` reale)
- [x] Nessun errore TypeScript (`svelte-check`: 0 errori)
- [x] Build di produzione riuscito
- [ ] Funziona su smartphone reale — da verificare dopo il deploy
- [ ] Autenticazione — da verificare con progetto Supabase reale
- [x] 64 nazionali presenti nel seed, San Marino incluso
- [x] Tornei da 32 o 64 (validati in RPC e in UI)
- [x] Vincitore avanza con un tocco, nessun punteggio numerico richiesto
- [x] 3 punti per vittoria, 1 punto per bonus checkbox (test unitari)
- [x] 7/5/1/0 punti piazzamento (test unitari)
- [x] Finalina 3°/4° obbligatoria per chiudere il torneo (test unitari + RPC)
- [x] Classifica generale calcolata da view, non manomettibile
- [x] Albo d'oro implementato
- [ ] Persistenza dopo refresh, isolamento utenti, RLS — da verificare con
      progetto Supabase reale (le policy sono scritte e testabili via SQL,
      ma non eseguibili in questo sandbox)
- [x] Correzione di un risultato passato ricalcola a cascata (logica scritta
      nella RPC `select_match_winner` + `clear_match_result`)
- [ ] Deploy Vercel — da eseguire seguendo i passaggi 11–12
