import { useState } from 'react'
import './Section.css'

interface ImageGenerationSectionProps {
  token: string
}

export const ImageGenerationSection = ({ token }: ImageGenerationSectionProps) => {
  const [prompt, setPrompt] = useState('')
  const [generatedImages, setGeneratedImages] = useState<string[]>([])
  const [isGenerating, setIsGenerating] = useState(false)

  const handleGenerate = async () => {
    if (!prompt.trim() || !token) return
    setIsGenerating(true)

    try {
      const response = await fetch(`/api/v1/images/generate?prompt=${encodeURIComponent(prompt)}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        throw new Error('Image generation failed')
      }

      const imageBlob = await response.blob()
      const imageUrl = URL.createObjectURL(imageBlob)

      setGeneratedImages((prev) => [imageUrl, ...prev])
      setPrompt('')
    } catch (error) {
      console.error(error)
      // You might want to show an error message to the user
    } finally {
      setIsGenerating(false)
    }
  }

  return (
    <div className="section-container">
      <div className="section-header">
        <h2>Image Generation</h2>
        <p className="muted">Generate images using AI models</p>
      </div>

      <div className="generation-panel">
        <div className="prompt-area">
          <textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Describe the image you want to generate..."
            rows={4}
          />
          <button onClick={handleGenerate} disabled={isGenerating || !prompt.trim()}>
            {isGenerating ? 'Generating...' : 'Generate Image'}
          </button>
        </div>

        <div className="images-grid">
          {generatedImages.length === 0 && (
            <div className="empty-state">
              <p className="muted">No images generated yet. Enter a prompt to get started!</p>
            </div>
          )}
          {generatedImages.map((url, index) => (
            <div key={index} className="image-card">
              <img src={url} alt={`Generated ${index}`} />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
