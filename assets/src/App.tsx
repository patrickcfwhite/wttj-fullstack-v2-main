import { createTheme, WuiProvider } from '@welcome-ui/core'
import { createBrowserRouter, RouterProvider } from 'react-router-dom'
import JobIndex from './pages/JobIndex'
import Layout from './components/Layout'
import JobShow from './pages/JobShow'
import { PhoenixProvider } from './providers/PhoenixWebsocketProvider'

const theme = createTheme()

const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      { path: '', element: <JobIndex /> },
      { path: 'jobs/:jobId', element: <JobShow /> },
    ],
  },
])

function App() {
  return (
    <WuiProvider theme={theme}>
      <PhoenixProvider>
        <RouterProvider router={router} />
      </PhoenixProvider>
    </WuiProvider>
  )
}

export default App
