import { getStats } from '$lib/stats.js';

export async function load() {
	const stats = await getStats();
	return { stats };
}
