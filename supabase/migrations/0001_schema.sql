-- 0001_schema.sql
-- Schema base: teams, tournaments, tournament_teams, matches, match_bonuses, point_events, profiles

create extension if not exists "pgcrypto";

-- ==========================================================
-- teams
-- ==========================================================
create table teams (
	id uuid primary key default gen_random_uuid(),
	name text not null unique,
	slug text not null unique,
	iso_code text not null unique,
	flag_emoji text not null,
	flag_url text null,
	seed_strength integer not null default 50,
	is_active boolean not null default true,
	created_at timestamptz not null default now()
);

-- ==========================================================
-- tournaments
-- ==========================================================
create table tournaments (
	id uuid primary key default gen_random_uuid(),
	user_id uuid not null references auth.users(id) on delete cascade,
	name text not null check (char_length(name) between 2 and 60),
	size integer not null check (size in (32, 64)),
	status text not null default 'draft' check (status in ('draft', 'active', 'completed')),
	draw_mode text not null check (draw_mode in ('random', 'manual')),
	champion_team_id uuid null references teams(id),
	runner_up_team_id uuid null references teams(id),
	third_team_id uuid null references teams(id),
	fourth_team_id uuid null references teams(id),
	created_at timestamptz not null default now(),
	started_at timestamptz null,
	completed_at timestamptz null,
	updated_at timestamptz not null default now()
);

create index tournaments_user_id_idx on tournaments(user_id);
create index tournaments_status_idx on tournaments(status);

-- ==========================================================
-- tournament_teams
-- ==========================================================
create table tournament_teams (
	id uuid primary key default gen_random_uuid(),
	tournament_id uuid not null references tournaments(id) on delete cascade,
	team_id uuid not null references teams(id),
	seed_position integer not null,
	final_position integer null check (final_position between 1 and 4 or final_position is null),
	placement_points integer not null default 0,
	created_at timestamptz not null default now(),
	unique (tournament_id, team_id),
	unique (tournament_id, seed_position)
);

create index tournament_teams_tournament_id_idx on tournament_teams(tournament_id);

-- ==========================================================
-- matches
-- ==========================================================
create table matches (
	id uuid primary key default gen_random_uuid(),
	tournament_id uuid not null references tournaments(id) on delete cascade,
	round_number integer not null,
	round_name text not null,
	match_number integer not null,
	bracket_type text not null check (bracket_type in ('main', 'third_place')),
	team_a_id uuid null references teams(id),
	team_b_id uuid null references teams(id),
	winner_team_id uuid null references teams(id),
	loser_team_id uuid null references teams(id),
	next_match_id uuid null references matches(id),
	next_match_slot text null check (next_match_slot in ('A', 'B')),
	status text not null default 'pending' check (status in ('pending', 'ready', 'completed')),
	played_at timestamptz null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (tournament_id, bracket_type, round_number, match_number)
);

create index matches_tournament_id_idx on matches(tournament_id);
create index matches_next_match_id_idx on matches(next_match_id);
create index matches_status_idx on matches(status);

-- ==========================================================
-- match_bonuses
-- ==========================================================
create table match_bonuses (
	id uuid primary key default gen_random_uuid(),
	match_id uuid not null references matches(id) on delete cascade,
	team_id uuid not null references teams(id),
	points integer not null default 1 check (points = 1),
	created_at timestamptz not null default now(),
	unique (match_id, team_id)
);

-- ==========================================================
-- point_events  (fonte verificabile di tutti i punti)
-- ==========================================================
create table point_events (
	id uuid primary key default gen_random_uuid(),
	user_id uuid not null references auth.users(id) on delete cascade,
	tournament_id uuid not null references tournaments(id) on delete cascade,
	team_id uuid not null references teams(id),
	match_id uuid null references matches(id) on delete cascade,
	event_type text not null check (event_type in ('match_win', 'match_bonus', 'placement_bonus')),
	points integer not null,
	metadata jsonb not null default '{}'::jsonb,
	created_at timestamptz not null default now()
);

create index point_events_user_id_idx on point_events(user_id);
create index point_events_tournament_id_idx on point_events(tournament_id);
create index point_events_team_id_idx on point_events(team_id);

-- Vincoli anti-duplicazione: una sola vittoria/bonus per squadra+partita,
-- un solo bonus piazzamento per squadra+torneo.
create unique index point_events_unique_match_win
	on point_events(match_id, team_id)
	where event_type = 'match_win';

create unique index point_events_unique_match_bonus
	on point_events(match_id, team_id)
	where event_type = 'match_bonus';

create unique index point_events_unique_placement
	on point_events(tournament_id, team_id)
	where event_type = 'placement_bonus';

-- ==========================================================
-- profiles
-- ==========================================================
create table profiles (
	id uuid primary key references auth.users(id) on delete cascade,
	display_name text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

-- updated_at automatico su tournaments e matches
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
	new.updated_at = now();
	return new;
end;
$$;

create trigger tournaments_set_updated_at
	before update on tournaments
	for each row execute function set_updated_at();

create trigger matches_set_updated_at
	before update on matches
	for each row execute function set_updated_at();

create trigger profiles_set_updated_at
	before update on profiles
	for each row execute function set_updated_at();
