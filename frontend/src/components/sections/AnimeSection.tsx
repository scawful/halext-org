import { useState } from 'react'
import './Section.css'

type AnimeCharacter = {
  id: number
  name: string
  imageUrl: string
  series: string
}

export const AnimeSection = () => {
  const [characters] = useState<AnimeCharacter[]>([
    {
      id: 1,
      name: 'Sample Character',
      imageUrl: 'https://via.placeholder.com/300x400?text=Anime+Character+1',
      series: 'Sample Series',
    },
    {
      id: 2,
      name: 'Sample Character 2',
      imageUrl: 'https://via.placeholder.com/300x400?text=Anime+Character+2',
      series: 'Sample Series 2',
    },
  ])

  return (
    <div className="section-container">
      <div className="section-header">
        <h2>Anime Girls Collection</h2>
        <p className="muted">Your anime character gallery</p>
      </div>

      <div className="anime-grid">
        {characters.map((character) => (
          <div key={character.id} className="anime-card">
            <div className="anime-image">
              <img src={character.imageUrl} alt={character.name} />
            </div>
            <div className="anime-info">
              <h3>{character.name}</h3>
              <p className="muted">{character.series}</p>
            </div>
          </div>
        ))}
        <div className="anime-card add-card">
          <button className="add-character-btn">+ Add Character</button>
        </div>
      </div>
    </div>
  )
}
