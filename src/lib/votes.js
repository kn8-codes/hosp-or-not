import { supabase } from './supabase.js';

const STORAGE_KEY = 'hosp_votes';
const GUEST_KEY = 'hosp_guest_id';

function requireSupabase() {
	if (!supabase) throw new Error('Supabase env vars are not configured');
	return supabase;
}

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

export function getGuestId() {
	let guestId = localStorage.getItem(GUEST_KEY);
	if (!guestId) {
		guestId = crypto.randomUUID();
		localStorage.setItem(GUEST_KEY, guestId);
	}
	return guestId;
}

async function ensureGuestActor(guestId) {
	const { error } = await requireSupabase().rpc('get_or_create_guest_actor', {
		p_guest_id: guestId
	});

	if (error) throw error;
}

export async function castVote(postId, vote, blurb) {
	if (hasVoted(postId)) throw new Error('Already voted on this post');

	const guestId = getGuestId();
	await ensureGuestActor(guestId);

	const { data, error } = await requireSupabase().rpc('submit_vote', {
		p_post_id: postId,
		p_vote: vote,
		p_blurb: blurb || null,
		p_guest_id: guestId
	});

	if (error) throw error;

	const voted = getVotedPosts();
	voted[postId] = vote;
	localStorage.setItem(STORAGE_KEY, JSON.stringify(voted));

	return data;
}

export async function updateVoteBlurb(postId, blurb) {
	const guestId = getGuestId();
	await ensureGuestActor(guestId);

	const { data, error } = await requireSupabase().rpc('update_vote_blurb', {
		p_post_id: postId,
		p_blurb: blurb,
		p_guest_id: guestId
	});

	if (error) throw error;
	return data;
}

export function tallyVotes(votes) {
	const yes = votes.filter((v) => v.vote).length;
	const no = votes.length - yes;
	return { yes, no, total: votes.length };
}
