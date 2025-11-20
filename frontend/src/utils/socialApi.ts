import { API_BASE_URL } from './helpers'

export interface SocialCircle {
  id: number
  name: string
  description?: string | null
  emoji?: string | null
  theme_color?: string | null
  vibe?: string | null
  invite_code: string
  member_count: number
}

export interface SocialCircleCreate {
  name: string
  description?: string
  emoji?: string
  theme_color?: string
  vibe?: string
}

export interface SocialPulse {
  id: number
  circle_id: number
  author_id: number
  author_name?: string | null
  message: string
  mood?: string | null
  attachments: string[]
  created_at: string
}

export interface SocialPulseCreate {
  message: string
  mood?: string
  attachments?: string[]
}

const authHeaders = (token: string) => ({
  Authorization: `Bearer ${token}`,
  'Content-Type': 'application/json',
})

export async function getSocialCircles(token: string): Promise<SocialCircle[]> {
  const response = await fetch(`${API_BASE_URL}/social/circles`, {
    headers: authHeaders(token),
  })
  if (!response.ok) throw new Error('Failed to load circles')
  return response.json()
}

export async function createSocialCircle(token: string, payload: SocialCircleCreate) {
  const response = await fetch(`${API_BASE_URL}/social/circles`, {
    method: 'POST',
    headers: authHeaders(token),
    body: JSON.stringify(payload),
  })
  if (!response.ok) throw new Error('Failed to create circle')
  return response.json()
}

export async function joinCircleWithCode(token: string, inviteCode: string) {
  const params = new URLSearchParams({ invite_code: inviteCode })
  const response = await fetch(`${API_BASE_URL}/social/circles/join?${params.toString()}`, {
    method: 'POST',
    headers: authHeaders(token),
  })
  if (!response.ok) throw new Error('Invalid invite code')
  return response.json()
}

export async function getCirclePulses(token: string, circleId: number): Promise<SocialPulse[]> {
  const response = await fetch(`${API_BASE_URL}/social/circles/${circleId}/pulses`, {
    headers: authHeaders(token),
  })
  if (!response.ok) throw new Error('Failed to load vibes')
  return response.json()
}

export async function shareCirclePulse(token: string, circleId: number, payload: SocialPulseCreate) {
  const response = await fetch(`${API_BASE_URL}/social/circles/${circleId}/pulses`, {
    method: 'POST',
    headers: authHeaders(token),
    body: JSON.stringify({
      ...payload,
      attachments: payload.attachments ?? [],
    }),
  })
  if (!response.ok) throw new Error('Failed to post vibe')
  return response.json()
}
