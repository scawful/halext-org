import { useEffect, useState } from 'react'
import { MdCelebration, MdPeople, MdFavorite, MdChatBubble, MdQrCode, MdAutorenew } from 'react-icons/md'
import {
  createSocialCircle,
  getCirclePulses,
  getSocialCircles,
  joinCircleWithCode,
  shareCirclePulse,
  type SocialCircle,
  type SocialPulse,
} from '../../utils/socialApi'
import './SocialSection.css'

interface SocialSectionProps {
  token: string
}

const moods = ['sparkles', 'sunset', 'neon', 'forest', 'cloud']

export const SocialSection = ({ token }: SocialSectionProps) => {
  const [circles, setCircles] = useState<SocialCircle[]>([])
  const [selectedCircle, setSelectedCircle] = useState<number | null>(null)
  const [pulses, setPulses] = useState<SocialPulse[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [circleForm, setCircleForm] = useState({
    name: 'Cafe Crew',
    description: 'Late-night synthwave chats',
    emoji: '🌙',
    theme_color: '#A855F7',
  })
  const [inviteCode, setInviteCode] = useState('')
  const [pulseMessage, setPulseMessage] = useState('dropping new playlists + vibes ✨')

  useEffect(() => {
    refreshCircles()
  }, [token])

  const refreshCircles = async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await getSocialCircles(token)
      setCircles(result)
      if (result.length > 0) {
        const target = selectedCircle ?? result[0].id
        setSelectedCircle(target)
        await loadPulses(target)
      } else {
        setPulses([])
        setSelectedCircle(null)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not load social circles')
    } finally {
      setLoading(false)
    }
  }

  const loadPulses = async (circleId: number) => {
    try {
      const vibe = await getCirclePulses(token, circleId)
      setPulses(vibe)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not fetch vibes')
    }
  }

  const handleCreateCircle = async () => {
    if (!circleForm.name.trim()) return
    try {
      await createSocialCircle(token, circleForm)
      setCircleForm({ ...circleForm, name: 'Star Club', description: 'stargazing + stories' })
      await refreshCircles()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not create circle')
    }
  }

  const handleJoinCircle = async () => {
    if (!inviteCode.trim()) return
    try {
      await joinCircleWithCode(token, inviteCode)
      setInviteCode('')
      await refreshCircles()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Invalid invite')
    }
  }

  const handleSharePulse = async () => {
    if (!selectedCircle || !pulseMessage.trim()) return
    try {
      const mood = moods[Math.floor(Math.random() * moods.length)]
      await shareCirclePulse(token, selectedCircle, { message: pulseMessage, mood })
      setPulseMessage('sending sparkly encouragement! ✨')
      await loadPulses(selectedCircle)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not share pulse')
    }
  }

  return (
    <div className="social-section">
      <header>
        <div>
          <p className="eyebrow">Tiny communities, big vibes</p>
          <h2>
            <span className="emoji">💫</span> Social Circles
          </h2>
        </div>
        <button className="outline" onClick={refreshCircles} disabled={loading}>
          <MdAutorenew />
          Refresh
        </button>
      </header>

      {error && <div className="social-error">{error}</div>}

      <section className="circle-strip">
        {circles.map((circle) => (
          <button
            key={circle.id}
            className={`circle-pill ${circle.id === selectedCircle ? 'active' : ''}`}
            onClick={() => {
              setSelectedCircle(circle.id)
              loadPulses(circle.id)
            }}
          >
            <span className="icon" style={{ background: circle.theme_color || '#a855f7' }}>
              {circle.emoji || '✨'}
            </span>
            <div>
              <p>{circle.name}</p>
              <small>{circle.member_count} friends</small>
            </div>
          </button>
        ))}
        {circles.length === 0 && <p className="empty-note">Create your first cozy circle!</p>}
      </section>

      <section className="social-grid">
        <div className="panel">
          <h3>
            <MdPeople /> Start a circle
          </h3>
          <input
            type="text"
            placeholder="Circle name"
            value={circleForm.name}
            onChange={(e) => setCircleForm({ ...circleForm, name: e.target.value })}
          />
          <textarea
            placeholder="What adventures live here?"
            value={circleForm.description}
            onChange={(e) => setCircleForm({ ...circleForm, description: e.target.value })}
            rows={3}
          />
          <input
            type="text"
            placeholder="Emoji"
            value={circleForm.emoji}
            onChange={(e) => setCircleForm({ ...circleForm, emoji: e.target.value })}
          />
          <button onClick={handleCreateCircle}>
            <MdCelebration /> Create
          </button>
        </div>

        <div className="panel">
          <h3>
            <MdQrCode /> Join with a code
          </h3>
          <input
            type="text"
            placeholder="ABC123"
            value={inviteCode}
            onChange={(e) => setInviteCode(e.target.value.toUpperCase())}
          />
          <button onClick={handleJoinCircle}>
            <MdFavorite /> Join cozy chat
          </button>
          {selectedCircle && (
            <div className="invite-card">
              <p>Invite friends with:</p>
              <strong>{circles.find((c) => c.id === selectedCircle)?.invite_code}</strong>
            </div>
          )}
        </div>

        <div className="panel pulses">
          <div className="pulses-header">
            <h3>
              <MdChatBubble /> Circle pulses
            </h3>
            {selectedCircle && (
              <span className="muted">{pulses.length} shimmering notes</span>
            )}
          </div>
          <div className="pulse-feed">
            {pulses.map((pulse) => (
              <div key={pulse.id} className="pulse-row">
                <div className="pulse-emoji">{pulse.mood ? `:${pulse.mood}:` : '✨'}</div>
                <div>
                  <p>{pulse.message}</p>
                  <small>
                    {pulse.author_name} • {new Date(pulse.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </small>
                </div>
              </div>
            ))}
            {pulses.length === 0 && <p className="empty-note">No updates yet. Leave the first sparkle!</p>}
          </div>
          <textarea
            placeholder="Share a cozy update"
            value={pulseMessage}
            onChange={(e) => setPulseMessage(e.target.value)}
            rows={2}
          />
          <button onClick={handleSharePulse} disabled={!selectedCircle}>
            Send sparkle
          </button>
        </div>
      </section>
    </div>
  )
}
