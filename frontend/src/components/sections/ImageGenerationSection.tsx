import { useState } from 'react'
import './Section.css'

export const ImageGenerationSection = () => {
  const [prompt, setPrompt] = useState('')
  const [generatedImages, setGeneratedImages] = useState<string[]>([])
  const [isGenerating, setIsGenerating] = useState(false)

  const handleGenerate = async () => {
    if (!prompt.trim()) return
    setIsGenerating(true)

    // TODO: Integrate with actual image generation API
    setTimeout(() => {
      setGeneratedImages((prev) => [
        `https://via.placeholder.com/512x512?text=${encodeURIComponent(prompt)}`,
        ...prev,
      ])
      setIsGenerating(false)
      setPrompt('')
    }, 2000)
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
