import type { OpenWebUiStatus } from '../../types/models'
import './Widget.css'

type OpenWebUIWidgetProps = {
  openwebui: OpenWebUiStatus | null
}

export const OpenWebUIWidget = ({ openwebui }: OpenWebUIWidgetProps) => {
  if (!openwebui?.enabled || !openwebui.url) {
    return (
      <div className="widget-body">
        <p className="muted">OpenWebUI is not running. Start it to unlock this panel.</p>
      </div>
    )
  }

  return (
    <div className="widget-body iframe-container">
      <iframe title="OpenWebUI" src={openwebui.url} />
    </div>
  )
}
