import { AiChatWidget } from '../ai/AiChatWidget'

interface ChatSectionProps {
  token: string
}

export const ChatSection = ({ token }: ChatSectionProps) => {
  return (
    <div className="h-full flex flex-col">
      <div className="p-6 border-b border-white/10">
        <h2 className="text-2xl font-bold text-purple-300">AI Chat Assistant</h2>
        <p className="text-sm text-gray-400 mt-1">
          Ask questions about your tasks, get suggestions, or chat about anything
        </p>
      </div>
      <div className="flex-1 overflow-hidden">
        <AiChatWidget token={token} />
      </div>
    </div>
  )
}
