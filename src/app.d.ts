import type { Session, User } from '@supabase/supabase-js';
import type { createSupabaseServerClient } from '$lib/server/supabase';

declare global {
	namespace App {
		interface Locals {
			supabase: ReturnType<typeof createSupabaseServerClient>;
			safeGetSession: () => Promise<{ session: Session | null; user: User | null }>;
			session: Session | null;
			user: User | null;
		}
		interface PageData {
			session: Session | null;
		}
		// interface Error {}
		// interface Platform {}
	}
}

export {};
