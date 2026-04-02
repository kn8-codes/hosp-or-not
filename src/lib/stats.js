import { supabase } from './supabase.js';

export async function getStats() {
	const [{ count: totalPosts }, { count: totalVotes }, { data: closed }] = await Promise.all([
		supabase.from('posts').select('*', { count: 'exact', head: true }),
		supabase.from('votes').select('*', { count: 'exact', head: true }),
		supabase
			.from('posts')
			.select('id, outcome, votes(vote)')
			.eq('status', 'closed')
			.not('outcome', 'is', null)
	]);

	// Crowd accuracy: did the majority vote match the outcome?
	// We infer the "correct" answer from the outcome text — not possible without
	// structured data, so we track how many closed posts have an outcome reported.
	// For v1, accuracy = closed posts with outcome / total closed posts.
	let accuracyPct = null;
	let closedWithOutcome = 0;
	let closedTotal = 0;
	let correctPredictions = 0;

	if (closed && closed.length > 0) {
		closedTotal = closed.length;
		closedWithOutcome = closed.filter((p) => p.outcome).length;

		// Heuristic: if outcome mentions "ER", "hospital", "broke", "fracture", "stitches" → HOSP was right
		// if outcome mentions "fine", "home", "better", "healed" → NOT was right
		const hospWords = /\b(er|hospital|hosp|broke|broken|fracture|stitches|surgery|admitted|xray|x-ray)\b/i;
		const notWords = /\b(fine|home|better|healed|nothing|okay|ok|recovered|minor)\b/i;

		for (const post of closed) {
			if (!post.outcome || !post.votes?.length) continue;
			const votes = post.votes;
			const yesCount = votes.filter((v) => v.vote).length;
			const majority = yesCount > votes.length / 2 ? 'hosp' : 'not';

			const wasHosp = hospWords.test(post.outcome);
			const wasNot = notWords.test(post.outcome);
			if (!wasHosp && !wasNot) continue;

			const actual = wasHosp ? 'hosp' : 'not';
			if (majority === actual) correctPredictions++;
		}

		const scoreable = closed.filter((p) => {
			if (!p.outcome || !p.votes?.length) return false;
			return hospWords.test(p.outcome) || notWords.test(p.outcome);
		}).length;

		accuracyPct = scoreable > 0 ? Math.round((correctPredictions / scoreable) * 100) : null;
	}

	return {
		totalPosts: totalPosts ?? 0,
		totalVotes: totalVotes ?? 0,
		closedTotal,
		closedWithOutcome,
		accuracyPct
	};
}
