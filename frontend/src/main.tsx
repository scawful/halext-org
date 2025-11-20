import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import './themes.css'
import App from './App.tsx'
import { AiProviderProvider } from './contexts/AiProviderContext.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AiProviderProvider>
      <App />
    </AiProviderProvider>
  </StrictMode>,
)
