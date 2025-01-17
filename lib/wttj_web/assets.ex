defmodule WttjWeb.Assets do
  use WttjWeb, :html

  if Mix.env() == :prod do
    def get(assigns) do
      ~H"""
      <script type="module" src={~p"/js/assets/index.js"}>
      </script>
      """
    end
  else
    def get(assigns) do
      assigns = Map.put(assigns, :port_vite, 5173)

      ~H"""
      <script type="module">
        import RefreshRuntime from 'http://localhost:<%= @port_vite %>/@react-refresh'
        RefreshRuntime.injectIntoGlobalHook(window)
        window.$RefreshReg$ = () => {}
        window.$RefreshSig$ = () => (type) => type
        window.__vite_plugin_react_preamble_installed__ = true
      </script>
      <script type="module" src={"http://localhost:#{@port_vite}/@vite/client"}>
      </script>
      <script type="module" src={"http://localhost:#{@port_vite}/src/main.tsx"}>
      </script>
      """
    end
  end
end
