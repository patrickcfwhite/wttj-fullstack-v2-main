import { createContext, useEffect, useState } from 'react'
import { Socket } from 'phoenix'

const PhoenixContext = createContext<{ websocket: Socket | null }>({ websocket: null })

const PhoenixProvider = ({ children }: { children: React.ReactNode }) => {
  const [websocket, setWebsocket] = useState<Socket | null>(null)

  useEffect(() => {
    const socket = new Socket('/socket')

    socket.connect()
    setWebsocket(socket)
  }, [])

  return <PhoenixContext.Provider value={{ websocket }}>{children}</PhoenixContext.Provider>
}

export { PhoenixContext, PhoenixProvider }
