import { supabase } from './supabase.js';

const STORAGE_KEY = 'hosp_votes';

function getVotedPosts() {
	try {
		return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
	} catch {
		return {};
	}
}

export function hasVoted(postId) {
	return postId in getVotedPosts();
}

export async function castVote(postId, vote, blurb) {
	if (hasVoted(postId)) throw new Error('Already voted on this post');

	const { data, error } = await supabase
		.from('votes')
		.insert({ post_id: postId, vote, blurb: blurb || null })
		.select('id')
		.single();

	if (error) throw error;

	const voted = getVotedPosts();
	voted[postId] = vote;
	localStorage.setItem(STORAGE_KEY, JSON.stringify(voted));

	return data.id;
}

export function tallyVotes(votes) {
	const yes = votes.filter((v) => v.vote).length;
	const no = votes.length - yes;
	return { yes, no, total: votes.length };
}
