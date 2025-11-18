import { useState, useRef, useEffect } from 'react'
import { sendChatMessage, streamChatMessage } from '../../utils/aiApi'
import type { AiChatMessage } from '../../utils/aiApi'

interface AiChatWidgetProps {
  token: string
}

export const AiChatWidget = ({ token }: AiChatWidgetProps) => {
  const [messages, setMessages] = useState<AiChatMessage[]>([])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [streaming, setStreaming] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const [streamingMessage, setStreamingMessage] = useState('')

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages, streamingMessage])

  const sendMessage = async () => {
    if (!input.trim() || loading) return

    const userMessage: AiChatMessage = { role: 'user', content: input.trim() }
    setMessages((prev) => [...prev, userMessage])
    setInput('')
    setLoading(true)
    setStreaming(true)
    setStreamingMessage('')

    try {
      // Use streaming for better UX
      let fullResponse = ''

      for await (const chunk of streamChatMessage(token, userMessage.content, messages)) {
        fullResponse += chunk
        setStreamingMessage(fullResponse)
      }

      const assistantMessage: AiChatMessage = { role: 'assistant', content: fullResponse }
      setMessages((prev) => [...prev, assistantMessage])
      setStreamingMessage('')
    } catch (error) {
      console.error('Chat error:', error)
      const errorMessage: AiChatMessage = {
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
      }
      setMessages((prev) => [...prev, errorMessage])
    } finally {
      setLoading(false)
      setStreaming(false)
    }
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage()
    }
  }

  return (
    <div className="flex flex-col h-full">
      {/* Chat Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && (
          <div className="text-center text-gray-400 mt-8">
            <p className="text-sm">👋 Hi! I'm your AI assistant.</p>
            <p className="text-xs mt-2">Ask me anything about your tasks, events, or notes!</p>
          </div>
        )}

        {messages.map((message, index) => (
          <div
            key={index}
            className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-[80%] p-3 rounded-lg ${
                message.role === 'user'
                  ? 'bg-purple-600 text-white'
                  : 'bg-white/10 backdrop-blur-sm text-gray-200 border border-white/10'
              }`}
            >
              <p className="text-sm whitespace-pre-wrap">{message.content}</p>
            </div>
          </div>
        ))}

        {streaming && streamingMessage && (
          <div className="flex justify-start">
            <div className="max-w-[80%] p-3 rounded-lg bg-white/10 backdrop-blur-sm text-gray-200 border border-white/10">
              <p className="text-sm whitespace-pre-wrap">{streamingMessage}</p>
              <span className="inline-block w-2 h-4 bg-purple-400 animate-pulse ml-1" />
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="p-4 border-t border-white/10">
        <div className="flex gap-2">
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Type your message... (Shift+Enter for new line)"
            disabled={loading}
            className="flex-1 px-3 py-2 bg-white/10 border border-white/20 rounded resize-none focus:outline-none focus:border-purple-500 disabled:opacity-50 text-sm"
            rows={2}
          />
          <button
            onClick={sendMessage}
            disabled={loading || !input.trim()}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed rounded transition-colors text-sm font-medium"
          >
            {loading ? '...' : 'Send'}
          </button>
        </div>
        <p className="text-xs text-gray-400 mt-2">
          Press Enter to send, Shift+Enter for new line
        </p>
      </div>
    </div>
  )
}
